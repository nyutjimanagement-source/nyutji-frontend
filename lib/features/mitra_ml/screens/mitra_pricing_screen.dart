import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../providers/auth_provider.dart';

import '../../../core/utils/formatters.dart';

import '../../../data/services/api_service.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../core/widgets/shimmer_loading.dart';

class MitraPricingScreen extends ConsumerStatefulWidget {
  final bool isReadOnly;
  final bool isSelectionMode;
  final String? customName;
  final List<Map<String, dynamic>>? items; 
  final Map<dynamic, int>? initialSelected; 

  const MitraPricingScreen({
    super.key, 
    this.isReadOnly = false,
    this.isSelectionMode = false,
    this.customName,
    this.items,
    this.initialSelected,
  });

  @override ConsumerState<MitraPricingScreen> createState() => _MitraPricingScreenState();
}

class _MitraPricingScreenState extends ConsumerState<MitraPricingScreen> {
  static const Color primaryTeal = Color(0xFF1E5655);
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color darkBg = Color(0xFF111827);
  
  bool _isInitialLoading = true;
  bool _isSaving = false;
  String? _currentMitraKey;

  // Dynamic States
  final Map<String, List<Map<String, String>>> _groupedData = {};
  final Map<String, PageController> _pageControllers = {};
  final Map<String, int> _pages = {};
  final Map<String, bool> _editModes = {};
  final Map<String, bool> _swipeForward = {};
  
  final Set<String> _selectedForEdit = {};
  final Map<String, TextEditingController> _editControllers = {};
  final Map<String, int> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialSelected != null) {
      widget.initialSelected!.forEach((key, value) {
        _selectedItems[key.toString()] = value;
      });
    }
  }

  @override
  void dispose() {
    for (var ctrl in _pageControllers.values) {
      ctrl.dispose();
    }
    for (var ctrl in _editControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPricingFromApi() async {
    setState(() => _isInitialLoading = true);
    try {
      final auth = ref.read(authProvider);
      final mitraId = auth.user?['identifier'] ?? '0000';
      if (mitraId == null) return;

      final api = ApiService();
      final items = await api.getMitraItems(mitraId);

      setState(() {
        _groupedData.clear();
        _pageControllers.clear();
        _pages.clear();
        _editModes.clear();
        _swipeForward.clear();

        int parseSafe(dynamic val) {
          if (val == null) return 0;
          String s = val.toString();
          if (s.contains('.')) {
            double? d = double.tryParse(s);
            if (d != null) return d.toInt();
            s = s.replaceAll('.', '');
          }
          return int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        }

        for (var i in items) {
          if (parseSafe(i['price_regular']) >= 10000000) continue;
          
          String cat = i['category']?.toString() ?? "Lainnya";
          
          if (!_groupedData.containsKey(cat)) {
            _groupedData[cat] = [];
            _pageControllers[cat] = PageController();
            _pages[cat] = 0;
            _editModes[cat] = false;
            _swipeForward[cat] = true;
          }
          
          _groupedData[cat]!.add({
            "id": i['id'].toString(),
            "svc": i['name']?.toString() ?? "",
            "reg": i['price_regular']?.toString() ?? "0",
            "fast": i['price_fast']?.toString() ?? "0",
            "category": cat,
          });
        }
      });
    } catch (e) {
      debugPrint("Gagal mengambil data dari API: $e");
    } finally {
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  void _initializeData(String mitraKey) {
    if (_currentMitraKey == mitraKey) return; 
    _currentMitraKey = mitraKey;
    _groupedData.clear();
    _isInitialLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPricingFromApi());
  }

  bool _isKiloanCategory(String cat) {
    return cat.toLowerCase().contains("kiloan");
  }

  Future<void> _syncPricingToBackend() async {
    setState(() => _isSaving = true);
    try {
      final auth = ref.read(authProvider);
      final mitraId = auth.user?['identifier']; 
      if (mitraId == null) throw "ID Mitra tidak ditemukan.";

      final api = ApiService();
      const maxPrice = 10000000;
      bool tooExpensive = false;

      int cleanParse(dynamic val) {
        if (val == null) return 0;
        String s = val.toString();
        if (s.contains('.')) {
          double? d = double.tryParse(s);
          if (d != null) return d.toInt();
          s = s.replaceAll('.', '');
        }
        return int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      }

      List<Map<String, dynamic>> payload = [];

      for (var cat in _groupedData.keys) {
        for (var item in _groupedData[cat]!) {
          int reg = cleanParse(item['reg']);
          int fast = cleanParse(item['fast']);
          
          if (reg > maxPrice || fast > maxPrice) {
            tooExpensive = true;
            break;
          }
          
          payload.add({
            "id": item['id'],
            "name": item['svc'],
            "price_regular": reg,
            "price_fast": fast,
            "category": item['category'] ?? cat
          });
        }
        if (tooExpensive) break;
      }

      if (tooExpensive) {
        if (mounted) NyutjiNotif.showError(context, "Harga Terlalu Mahal! Maksimal Rp 10.000.000");
        return;
      }

      await api.updateMitraPricing(mitraId, payload);
      if (mounted) NyutjiNotif.showSuccess(context, "Harga berhasil disimpan ke database!");
    } catch (e) {
      if (mounted) NyutjiNotif.showError(context, "Gagal menyimpan ke database: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _saveCategory(String category) async {
    setState(() {
      List<String> idsToRemove = [];
      for (int index = 0; index < _groupedData[category]!.length; index++) {
        final item = _groupedData[category]![index];
        final id = item['id']!;
        if (!_selectedForEdit.contains(id)) continue;

        final ctrlName = _editControllers["$id-1"];
        final ctrlReg = _editControllers["$id-2"];
        final ctrlFast = _editControllers["$id-3"];

        if (ctrlName != null && ctrlName.text.isEmpty) {
          idsToRemove.add(id);
        } else {
          item['svc'] = ctrlName?.text ?? item['svc']!;
          if (ctrlReg != null) item['reg'] = ctrlReg.text.replaceAll(RegExp(r'[^0-9]'), "");
          if (ctrlFast != null) item['fast'] = ctrlFast.text.replaceAll(RegExp(r'[^0-9]'), "");
        }
      }

      for (var id in idsToRemove) {
        _groupedData[category]!.removeWhere((item) => item['id'] == id);
      }

      _editModes[category] = false;
      _selectedForEdit.clear();
      _editControllers.forEach((k, v) => v.dispose());
      _editControllers.clear();
    });
    await _syncPricingToBackend();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = ref.watch(authProvider);
    final mitraName = widget.customName ?? (auth.user?['name'] ?? "Nyutji Mitra");
    _initializeData(mitraName);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final mitraName = widget.customName ?? (auth.user?['name'] ?? "Nyutji Mitra");
    
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildElegantHeader(mitraName),
              if (_isInitialLoading)
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: ShimmerLoading(height: 70, borderRadius: 12),
                      ),
                      childCount: 6,
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._groupedData.keys.where((k) => _groupedData[k]!.isNotEmpty || _editModes[k] == true).map((category) {
                          return _buildCategorySection(category);
                        }),
                        const SizedBox(height: 32),
                        _buildActionButtons(),
                        if (widget.isSelectionMode) _buildSelectionConfirmButton(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                )
            ],
          ),
        ),
        if (_isSaving)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(
              child: CircularProgressIndicator(color: primaryTeal),
            ),
          ),
      ],
    );
  }

  Widget _buildCategorySection(String category) {
    bool isKiloan = _isKiloanCategory(category);
    bool isEditing = _editModes[category] ?? false;
    List<Map<String, String>> data = _groupedData[category] ?? [];
    int currentPage = _pages[category] ?? 0;
    PageController controller = _pageControllers[category] ?? PageController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          category, 
          isKiloan ? LucideIcons.layers : LucideIcons.shirt, 
          isEditing: isEditing, 
          onEdit: () {
            setState(() => _editModes[category] = true);
          },
          onSave: () {
            _saveCategory(category);
          },
          onCancel: () {
            setState(() {
              _editModes[category] = false;
              _selectedForEdit.clear();
            });
          }
        ),
        const SizedBox(height: 12),
        _buildTableWrapper(category, controller, currentPage, (idx) {
          setState(() => _pages[category] = idx);
        }, data, isKiloan),
        _buildPageIndicator(currentPage, (data.length / (isEditing ? 4 : 5)).ceil()),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildElegantHeader(String name) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: primaryTeal,
      leading: IconButton(
        icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "DAFTAR HARGA",
              style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.9), letterSpacing: 1.5),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                name.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryTeal, Color(0xFF2D807E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {bool isEditing = false, VoidCallback? onEdit, VoidCallback? onSave, VoidCallback? onCancel}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(icon, size: 18, color: primaryTeal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title, 
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis, 
                  style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w800, color: darkBg)
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (!widget.isReadOnly)
          isEditing
              ? Row(
                  children: [
                    GestureDetector(
                      onTap: onCancel,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text("Cancel", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onSave,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text("Save", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: primaryTeal)),
                      ),
                    ),
                  ],
                )
              : GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text("Add/Edit", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: primaryTeal)),
                  ),
                ),
      ],
    );
  }

  Widget _buildTableWrapper(String category, PageController controller, int currentPage, Function(int) onPageChanged, List<Map<String, String>> data, bool isKiloan) {
    bool editing = _editModes[category] ?? false;
    int itemsPerPage = editing ? 4 : 5;
    int totalPages = (data.length / itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    int start = currentPage * itemsPerPage;
    int end = (start + itemsPerPage > data.length) ? data.length : start + itemsPerPage;
    List<Map<String, String>> pageData = data.isNotEmpty ? data.sublist(start, end) : [];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < 0) {
          if (currentPage < totalPages - 1) {
            setState(() => _swipeForward[category] = true);
            onPageChanged(currentPage + 1);
          }
        } else if (details.primaryVelocity! > 0) {
          if (currentPage > 0) {
            setState(() => _swipeForward[category] = false);
            onPageChanged(currentPage - 1);
          }
        }
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!editing) _buildTableHeader(isKiloan ? ["", "Service", "Regular", "Fast Track"] : ["", "Service", "Harga"], editing),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  bool isFwd = _swipeForward[category] ?? true;
                  final offset = isFwd 
                    ? (child.key == ValueKey(currentPage) ? const Offset(0.2, 0) : const Offset(-0.2, 0))
                    : (child.key == ValueKey(currentPage) ? const Offset(-0.2, 0) : const Offset(0.2, 0));
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: offset, end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  key: ValueKey(currentPage), 
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...pageData.map((item) {
                      String id = item['id']?.toString() ?? "";
                      return _buildDynamicRow(category, id, item, editing, isKiloan);
                    }),
                    if (editing) _buildAddRowButton(category, isKiloan, currentPage, totalPages, onPageChanged),
                  ],
                ),
              ),
              const SizedBox(height: 8), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddRowButton(String category, bool isKiloan, int currentPage, int totalPages, Function(int) onPageChanged) {
    return Container(
      decoration: BoxDecoration(
        color: primaryTeal.withValues(alpha: 0.05),
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        children: [
          if (totalPages > 1)
            IconButton(
              icon: const Icon(LucideIcons.chevronLeft, size: 20),
              color: currentPage > 0 ? primaryTeal : Colors.grey[400],
              onPressed: currentPage > 0 ? () {
                setState(() => _swipeForward[category] = false);
                onPageChanged(currentPage - 1);
              } : null,
            )
          else
            const SizedBox(width: 48),

          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  final newId = DateTime.now().millisecondsSinceEpoch.toString();
                  if (_groupedData[category] == null) _groupedData[category] = [];
                  _groupedData[category]!.add({
                    "id": newId, 
                    "svc": "", 
                    "reg": "", 
                    "fast": "", 
                    "category": category
                  });
                  _selectedForEdit.add(newId);
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.plusCircle, size: 16, color: primaryTeal),
                    const SizedBox(width: 8),
                    Text(
                      "Tambah Baru",
                      style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTeal),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (totalPages > 1)
            IconButton(
              icon: const Icon(LucideIcons.chevronRight, size: 20),
              color: currentPage < totalPages - 1 ? primaryTeal : Colors.grey[400],
              onPressed: currentPage < totalPages - 1 ? () {
                setState(() => _swipeForward[category] = true);
                onPageChanged(currentPage + 1);
              } : null,
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTableHeader(List<String> titles, bool editing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
      child: Row(
        children: titles.map((t) {
          bool isCheck = t == "";
          if (isCheck && !widget.isSelectionMode && !editing) return const SizedBox.shrink();
          return Expanded(
            flex: isCheck ? 0 : (t == "Service" ? 2 : 1),
            child: SizedBox(
              width: isCheck ? 30 : null,
              child: Text(
                t.toUpperCase(), 
                textAlign: isCheck ? TextAlign.left : TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey[500], letterSpacing: 0.8)
              ),
            )
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSmallField(TextEditingController ctrl, String hint, {bool isCenter = false, bool isAuto = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: ctrl,
        textAlign: isCenter ? TextAlign.center : TextAlign.left,
        autofocus: isAuto,
        keyboardType: isCenter ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: isAuto ? const UnderlineInputBorder(borderSide: BorderSide(color: primaryTeal)) : InputBorder.none,
        ),
      ),
    );
  }

  TextEditingController _getEditController(String id, int subId, String initialText) {
    String key = "$id-$subId";
    if (!_editControllers.containsKey(key)) {
      String text = (subId > 1) ? initialText.replaceAll(RegExp(r'[^0-9]'), '') : initialText;
      _editControllers[key] = TextEditingController(text: text);
    }
    return _editControllers[key]!;
  }

  Widget _buildDynamicRow(String category, String id, Map<String, String> item, bool editing, bool isKiloan) {
    bool isSelected = (_selectedItems[id] ?? 0) > 0;
    bool isBeingEdited = _selectedForEdit.contains(id);
    bool canDelete = editing && !isBeingEdited;

    Widget rowContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
      child: Row(
        children: [
          if (widget.isSelectionMode || editing)
            SizedBox(
              width: 30,
              child: Checkbox(
                value: editing ? isBeingEdited : isSelected,
                activeColor: primaryTeal,
                onChanged: (v) {
                  setState(() {
                    if (editing) {
                      if (v!) {
                        _selectedForEdit.add(id);
                      } else {
                        _selectedForEdit.remove(id);
                      }
                    } else {
                      _selectedItems[id] = v! ? 1 : 0;
                    }
                  });
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
          Expanded(flex: 2, child: isBeingEdited 
            ? _buildSmallField(_getEditController(id, 1, item['svc']!), "", isAuto: true) 
            : Text(item['svc']!, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: darkBg))),
          const SizedBox(width: 4),
          Expanded(child: isBeingEdited 
            ? _buildSmallField(_getEditController(id, 2, item['reg']!), "", isCenter: true)
            : Text("Rp ${Formatters.formatPrice(item['reg']!)}", textAlign: isKiloan ? TextAlign.center : TextAlign.left, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.montserrat(fontSize: isKiloan ? 11 : 12, fontWeight: FontWeight.w800, color: primaryTeal))),
          if (isKiloan) ...[
            const SizedBox(width: 4),
            Expanded(child: isBeingEdited
              ? _buildSmallField(_getEditController(id, 3, item['fast']!), "", isCenter: true)
              : Text("Rp ${Formatters.formatPrice(item['fast']!)}", textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w800, color: accentGold))),
          ]
        ],
      ),
    );

    if (!canDelete) return rowContent;

    return Dismissible(
      key: ValueKey("row-$id"),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        setState(() {
          _groupedData[category]!.removeWhere((element) => element['id'] == id);
          _selectedForEdit.remove(id);
          _selectedItems.remove(id);
        });
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Dihapus", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(width: 8),
            const Icon(LucideIcons.trash2, color: Colors.white),
          ],
        ),
      ),
      child: rowContent,
    );
  }

  Widget _buildPageIndicator(int current, int count) {
    if (count <= 1) return const SizedBox(height: 12);
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: current == i ? 12 : 6, 
          height: 6,
          decoration: BoxDecoration(
            color: current == i ? primaryTeal : Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
        )),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (widget.isReadOnly) return const SizedBox.shrink();
    return Column(
      children: [
        _buildLuxuryButton("Pamflet Promosi Discount", LucideIcons.megaphone, accentGold, () {}),
      ],
    );
  }

  Widget _buildLuxuryButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(title, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildSelectionConfirmButton() {
    int total = _selectedItems.values.where((v) => v > 0).length;
    return Container(
      margin: const EdgeInsets.only(top: 20),
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context, _selectedItems),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        child: Text("Konfirmasi $total Item Dipilih", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
