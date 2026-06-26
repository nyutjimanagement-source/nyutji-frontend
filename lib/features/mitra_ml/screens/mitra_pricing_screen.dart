import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../providers/auth_provider.dart';

import '../../../core/utils/formatters.dart';

import '../../../data/services/api_service.dart';
import '../../../data/services/cache_service.dart';
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
  String? _selectedCategory;

  // Dynamic States
  final Map<String, List<Map<String, String>>> _groupedData = {};
  final Map<String, bool> _editModes = {};
  
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
    for (var ctrl in _editControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPricingFromApi() async {
    final auth = ref.read(authProvider);
    final mitraId = auth.user?['identifier'] ?? '0000';
    if (mitraId == null) return;

    final cacheKey = 'mitra_items_$mitraId';
    // 1. Coba baca dari cache dulu agar UI ter-render instan
    final cached = CacheService.get(cacheKey);
    if (cached != null && cached is List) {
      _processPricingData(cached);
      _isInitialLoading = false;
      if (mounted) setState(() {});
    } else {
      setState(() => _isInitialLoading = true);
    }

    try {
      final api = ApiService();
      final items = await api.getMitraItems(mitraId);
      _processPricingData(items);
    } catch (e) {
      debugPrint("Gagal mengambil data dari API: $e");
    } finally {
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  void _processPricingData(List<dynamic> items) {
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

    _groupedData.clear();
    _editModes.clear();

    for (var i in items) {
      if (parseSafe(i['price_regular']) >= 10000000) continue;
      
      String cat = i['category']?.toString() ?? "Lainnya";
      
      if (!_groupedData.containsKey(cat)) {
        _groupedData[cat] = [];
        _editModes[cat] = false;
      }
      
      _groupedData[cat]!.add({
        "id": i['id'].toString(),
        "svc": i['name']?.toString() ?? "",
        "reg": i['price_regular']?.toString() ?? "0",
        "fast": i['price_fast']?.toString() ?? "0",
        "category": cat,
      });
    }

    if (_groupedData.isNotEmpty) {
      if (_selectedCategory == null || !_groupedData.containsKey(_selectedCategory)) {
        _selectedCategory = _groupedData.keys.first;
      }
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
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            backgroundColor: primaryTeal,
            elevation: 0,
            title: Text(
              "Daftar Harga",
              style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: _isInitialLoading
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      ShimmerLoading(height: 70, borderRadius: 12),
                      SizedBox(height: 16),
                      ShimmerLoading(height: 70, borderRadius: 12),
                      SizedBox(height: 16),
                      ShimmerLoading(height: 70, borderRadius: 12),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCategorySelector(),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedCategory != null &&
                                (_groupedData[_selectedCategory]!.isNotEmpty || _editModes[_selectedCategory] == true))
                              _buildCategorySection(_selectedCategory!),
                            const SizedBox(height: 12),
                            _buildSimulasiSection(),
                            const SizedBox(height: 20),
                            _buildActionButtons(),
                            if (widget.isSelectionMode) _buildSelectionConfirmButton(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
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

  Widget _buildCategorySelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _groupedData.keys.map((cat) {
            bool isSelected = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () {
                  setState(() => _selectedCategory = cat);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryTeal : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? primaryTeal : Colors.grey[200]!,
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains("kilo")) return LucideIcons.layers;
    if (lower.contains("satu") || lower.contains("baju") || lower.contains("pakaian")) return LucideIcons.shirt;
    if (lower.contains("bed") || lower.contains("selimut")) return LucideIcons.cloud;
    if (lower.contains("sepatu") || lower.contains("tas")) return LucideIcons.shoppingBag;
    if (lower.contains("karpet")) return LucideIcons.layoutGrid;
    if (lower.contains("setrika") || lower.contains("gosok")) return LucideIcons.wind;
    return LucideIcons.tag;
  }

  Widget _buildCategorySection(String category) {
    bool isKiloan = _isKiloanCategory(category);
    bool isEditing = _editModes[category] ?? false;
    List<Map<String, String>> data = _groupedData[category] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          category, 
          _getCategoryIcon(category), 
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
        _buildTableWrapper(category, data, isKiloan),
        const SizedBox(height: 24),
      ],
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

  Widget _buildTableWrapper(String category, List<Map<String, String>> data, bool isKiloan) {
    bool editing = _editModes[category] ?? false;

    return AnimatedSize(
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
            if (!editing) _buildTableHeader(isKiloan ? ["", "Service", "Reguler", "Fast Track"] : ["", "Service", "Harga"], editing),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...data.map((item) {
                  String id = item['id']?.toString() ?? "";
                  return _buildDynamicRow(category, id, item, editing, isKiloan);
                }),
                if (editing) _buildAddRowButton(category, isKiloan),
              ],
            ),
            const SizedBox(height: 8), 
          ],
        ),
      ),
    );
  }

  Widget _buildAddRowButton(String category, bool isKiloan) {
    return Container(
      decoration: BoxDecoration(
        color: primaryTeal.withValues(alpha: 0.05),
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
      ),
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.plusCircle, size: 16, color: primaryTeal),
              const SizedBox(width: 8),
              Text(
                "Tambah Baru",
                style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: primaryTeal),
              ),
            ],
          ),
        ),
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
                t, 
                textAlign: isCheck ? TextAlign.left : TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])
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
            Text("Daftar Harga Dihapus", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(width: 8),
            const Icon(LucideIcons.trash2, color: Colors.white),
          ],
        ),
      ),
      child: rowContent,
    );
  }

  Widget _buildSimulasiSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1E5655).withValues(alpha: 0.05), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E5655).withValues(alpha: 0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E5655).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.calculator, size: 18, color: Color(0xFF1E5655)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Simulasi Harga Kiloan dan Satuan",
                  style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Simulasi perhitungan Harga Pokok Penjualan (HPP) untuk operasional laundry, baik untuk sistem Kiloan maupun Satuan (Premium/Dry Cleaning)\n\nKunci utama dalam menghitung HPP laundry yang akurat adalah memisahkan dengan tegas antara Biaya Langsung (Variabel) yang menempel pada baju yang dicuci, dengan Biaya Tetap (Overhead) seperti sewa ruko atau gaji pokok karyawan.",
            style: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF4B5563), height: 1.5, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              NyutjiNotif.showInfo(context, "Fitur Simulasi akan segera hadir");
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                "Mulai Simulasi",
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return const SizedBox.shrink();
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
