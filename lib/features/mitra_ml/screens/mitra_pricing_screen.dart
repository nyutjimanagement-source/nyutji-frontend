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
  
  final PageController _kiloanController = PageController();
  final PageController _satuanController = PageController();
  int _kiloanPage = 0;
  int _satuanPage = 0;
  
  bool _isSwipeForward = true;
  bool _isEditingKiloan = false;
  bool _isEditingSatuan = false;
  bool _isInitialLoading = true;
  bool _isSaving = false;

  final TextEditingController _newKiloanSvc = TextEditingController();
  final TextEditingController _newKiloanReg = TextEditingController();
  final TextEditingController _newKiloanFast = TextEditingController();
  final TextEditingController _newSatuanName = TextEditingController();
  final TextEditingController _newSatuanPrice = TextEditingController();

  final Set<String> _selectedForEdit = {};
  final Map<String, TextEditingController> _editControllers = {};
  final Map<String, int> _selectedItems = {};

  late List<Map<String, String>> kiloanData;
  late List<Map<String, String>> satuanData;
  String? _currentMitraKey;

  @override
  void initState() {
    super.initState();
    if (widget.initialSelected != null) {
      widget.initialSelected!.forEach((key, value) {
        _selectedItems[key.toString()] = value;
      });
    }
  }

  Future<void> _loadPricingFromApi() async {
    setState(() => _isInitialLoading = true);
    try {
      final auth = ref.read(authProvider);
      // Deteksi MitraId: Prioritas identifier user, fallback ke mitra_id (untuk Admin/Kurir view)
      final mitraId = auth.user?['identifier'] ?? '0000';
      if (mitraId == null) {
        debugPrint("Error: MitraId tidak ditemukan di AuthProvider");
        return;
      }

      final api = ApiService();
      final items = await api.getMitraItems(mitraId);

      // FIX: Selalu update data walaupun kosong agar 'hantu' hilang jika dihapus di backend
      setState(() {
        int parseSafe(dynamic val) {
          if (val == null) return 0;
          // Genius Fix: Tangani kemungkinan "4000.00" dari database
          String s = val.toString();
          if (s.contains('.')) {
            // Jika ada titik, kita cek: apakah itu desimal (di akhir) atau ribuan?
            // Cara paling aman: parse ke double dulu, lalu buang desimalnya
            double? d = double.tryParse(s);
            if (d != null) return d.toInt();
            
            // Jika double gagal (mungkin karena ada titik ribuan), buang semua titiknya
            s = s.replaceAll('.', '');
          }
          return int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        }

        // FILTER DIPERBAIKI: Gunakan limit 10 Juta (sama dengan validasi simpan) agar tidak ada item tersembunyi
        kiloanData = items
          .where((i) => i['category'] == 'Kiloan' || i['category'] == 'Layanan Kiloan')
          .where((i) => parseSafe(i['price_regular']) < 10000000)
          .map<Map<String, String>>((i) => {
          "id": i['id'].toString(),
          "svc": i['name']?.toString() ?? "",
          "reg": i['price_regular']?.toString() ?? "0",
          "fast": i['price_fast']?.toString() ?? "0",
        }).toList();

        satuanData = items
          .where((i) => i['category'] != 'Kiloan' && i['category'] != 'Layanan Kiloan')
          .where((i) => parseSafe(i['price_regular']) < 10000000)
          .map<Map<String, String>>((i) => {
          "id": i['id'].toString(),
          "name": i['name']?.toString() ?? "",
          "price": i['price_regular']?.toString() ?? "0",
        }).toList();
        
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
    
    // JANGAN PAKAI DUMMY (Hantu)! Inisialisasi kosong dan ambil langsung dari Database
    kiloanData = [];
    satuanData = [];
    _isInitialLoading = true;
    
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPricingFromApi());
  }

  // _formatPrice LOKAL DIHAPUS - SEKARANG PAKE Formatters.formatPrice UNTUK DISPLAY TAPI RAW UNTUK EDIT

  Future<void> _syncPricingToBackend() async {
    setState(() => _isSaving = true);
    try {
      final auth = ref.read(authProvider);
      final mitraId = auth.user?['identifier']; 
      if (mitraId == null) {
        throw "ID Mitra (Identifier) tidak ditemukan. Pastikan Anda sudah Login dengan benar.";
      }

      final api = ApiService();
      // VALIDASI CERDAS: Cek apakah ada harga yang tidak masuk akal (Terlalu Mahal)
      const maxPrice = 10000000; // Batas 10 Juta
      bool tooExpensive = false;

      // Fungsi pembantu untuk membersihkan string dari karakter non-angka
      int cleanParse(dynamic val) {
        if (val == null) return 0;
        String s = val.toString();
        // Jika input dari UI (biasanya ada titik ribuan), buang titiknya
        // Tapi jika ada desimal ".00" dari DB, kita handle secara double
        if (s.contains('.')) {
          double? d = double.tryParse(s);
          if (d != null) return d.toInt();
          s = s.replaceAll('.', '');
        }
        return int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      }

      for (var item in kiloanData) {
        if (cleanParse(item['reg']) > maxPrice || cleanParse(item['fast']) > maxPrice) {
          tooExpensive = true;
          break;
        }
      }
      
      if (!tooExpensive) {
        for (var item in satuanData) {
          if (cleanParse(item['price']) > maxPrice) {
            tooExpensive = true;
            break;
          }
        }
      }

      if (tooExpensive) {
        if (mounted) {
          NyutjiNotif.showError(context, "Harga Terlalu Mahal! Maksimal Rp 10.000.000");
        }
        return;
      }

      List<Map<String, dynamic>> payload = [];
      
      for (var item in kiloanData) {
        payload.add({
          "id": item['id'],
          "name": item['svc'],
          "price_regular": cleanParse(item['reg']).toInt(),
          "price_fast": cleanParse(item['fast']).toInt(),
          "category": "Kiloan"
        });
      }
      
      for (var item in satuanData) {
        payload.add({
          "id": item['id'],
          "name": item['name'],
          "price_regular": cleanParse(item['price']).toInt(),
          "category": "Satuan"
        });
      }

      await api.updateMitraPricing(mitraId, payload);
      if (mounted) NyutjiNotif.showSuccess(context, "Harga berhasil disimpan ke database!");
    } catch (e) {
      if (mounted) NyutjiNotif.showError(context, "Gagal menyimpan ke database: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _saveKiloan() async {
    setState(() {
      if (_newKiloanSvc.text.isNotEmpty) {
        kiloanData.insert(0, {
          "id": DateTime.now().millisecondsSinceEpoch.toString(),
          "svc": _newKiloanSvc.text,
          "reg": _newKiloanReg.text.replaceAll(RegExp(r'[^0-9]'), ""),
          "fast": _newKiloanFast.text.replaceAll(RegExp(r'[^0-9]'), ""),
        });
        _newKiloanSvc.clear();
        _newKiloanReg.clear();
        _newKiloanFast.clear();
      }
      
      List<String> idsToRemove = [];
      for (int index = 0; index < kiloanData.length; index++) {
        final String id = kiloanData[index]['id']!;
        if (!_selectedForEdit.contains(id)) continue;

        final ctrlName = _editControllers["$id-1"];
        final ctrlReg = _editControllers["$id-2"];
        final ctrlFast = _editControllers["$id-3"];

        if (ctrlName != null) {
          if (ctrlName.text.trim().isEmpty) {
            idsToRemove.add(id);
          } else {
            kiloanData[index]['svc'] = ctrlName.text;
            if (ctrlReg != null) kiloanData[index]['reg'] = ctrlReg.text.replaceAll(RegExp(r'[^0-9]'), "");
            if (ctrlFast != null) kiloanData[index]['fast'] = ctrlFast.text.replaceAll(RegExp(r'[^0-9]'), "");
          }
        }
      }
      
      for (var id in idsToRemove) {
        kiloanData.removeWhere((item) => item['id'] == id);
      }
      
      _isEditingKiloan = false;
      _selectedForEdit.clear();
      _editControllers.forEach((k, v) => v.dispose());
      _editControllers.clear();
    });
    await _syncPricingToBackend();
  }

  void _saveSatuan() async {
    setState(() {
      if (_newSatuanName.text.isNotEmpty) {
        satuanData.insert(0, {
          "id": DateTime.now().millisecondsSinceEpoch.toString(),
          "name": _newSatuanName.text,
          "price": _newSatuanPrice.text.replaceAll(RegExp(r'[^0-9.]'), ""),
        });
        _newSatuanName.clear();
        _newSatuanPrice.clear();
      }

      List<String> idsToRemove = [];
      for (int index = 0; index < satuanData.length; index++) {
        final String id = satuanData[index]['id']!;
        if (!_selectedForEdit.contains(id)) continue;

        final ctrlName = _editControllers["$id-1"];
        final ctrlPrice = _editControllers["$id-2"];

        if (ctrlName != null) {
          if (ctrlName.text.trim().isEmpty) {
            idsToRemove.add(id);
          } else {
            satuanData[index]['name'] = ctrlName.text;
            if (ctrlPrice != null) satuanData[index]['price'] = ctrlPrice.text.replaceAll(RegExp(r'[^0-9]'), "");
          }
        }
      }

      for (var id in idsToRemove) {
        satuanData.removeWhere((item) => item['id'] == id);
      }

      _isEditingSatuan = false;
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
                          _buildSectionHeader("Laundry Kiloan", LucideIcons.layers, isEditing: _isEditingKiloan, 
                            onEdit: () {
                              setState(() => _isEditingKiloan = true);
                            },
                            onSave: () {
                              _saveKiloan();
                            },
                            onCancel: () {
                              setState(() {
                                _isEditingKiloan = false;
                                _selectedForEdit.clear();
                              });
                            }
                          ),
                          const SizedBox(height: 12),
                          _buildTableWrapper(_kiloanController, _kiloanPage, (idx) {
                            setState(() => _kiloanPage = idx);
                          }, kiloanData, true),
                          _buildPageIndicator(_kiloanPage, (kiloanData.length / (_isEditingKiloan ? 4 : 5)).ceil()),
                          const SizedBox(height: 24),
                          
                          _buildSectionHeader("Laundry Satuan", LucideIcons.shirt, hasSearch: true, isEditing: _isEditingSatuan, 
                            onEdit: () {
                              setState(() => _isEditingSatuan = true);
                            },
                            onSave: () {
                              _saveSatuan();
                            },
                            onCancel: () {
                              setState(() {
                                _isEditingSatuan = false;
                                _selectedForEdit.clear();
                              });
                            }
                          ),
                          const SizedBox(height: 12),
                          _buildTableWrapper(_satuanController, _satuanPage, (idx) {
                            setState(() => _satuanPage = idx);
                          }, satuanData, false),
                          _buildPageIndicator(_satuanPage, (satuanData.length / (_isEditingSatuan ? 4 : 5)).ceil()),
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

  Widget _buildSectionHeader(String title, IconData icon, {bool hasSearch = false, bool isEditing = false, VoidCallback? onEdit, VoidCallback? onSave, VoidCallback? onCancel}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: primaryTeal),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w800, color: darkBg)),
            if (title == "Laundry Satuan") ...[
              const SizedBox(width: 6),
              Tooltip(
                message: "Untuk jenis Laundry per Meter atau per M2, bisa ditulis untuk Jenis Service. Contoh: Gordyn per Meter",
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: darkBg, borderRadius: BorderRadius.circular(8)),
                textStyle: GoogleFonts.montserrat(fontSize: 10, color: Colors.white),
                showDuration: const Duration(seconds: 4),
                triggerMode: TooltipTriggerMode.tap,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey[400]!)),
                  child: Icon(LucideIcons.info, size: 14, color: Colors.grey[600]),
                ),
              )
            ]
          ],
        ),
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

  Widget _buildTableWrapper(PageController controller, int currentPage, Function(int) onPageChanged, List<Map<String, String>> data, bool isKiloan) {
    bool editing = isKiloan ? _isEditingKiloan : _isEditingSatuan;
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
            setState(() => _isSwipeForward = true);
            onPageChanged(currentPage + 1);
          }
        } else if (details.primaryVelocity! > 0) {
          if (currentPage > 0) {
            setState(() => _isSwipeForward = false);
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
              
              // ANIMATED SWITCHER FOR SMOOTH SWIPE
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final offset = _isSwipeForward 
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
                      return isKiloan 
                        ? _buildKiloanRow(id, item, editing)
                        : _buildSatuanRow(id, item, editing);
                    }),
                    if (editing) _buildAddRowButton(isKiloan),
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

  Widget _buildAddRowButton(bool isKiloan) {
    return InkWell(
      onTap: () {
        setState(() {
          final newId = DateTime.now().millisecondsSinceEpoch.toString();
          if (isKiloan) {
            kiloanData.add({"id": newId, "svc": "", "reg": "", "fast": ""});
          } else {
            satuanData.add({"id": newId, "name": "", "price": ""});
          }
          _selectedForEdit.add(newId);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: primaryTeal.withValues(alpha: 0.05),
          border: Border(top: BorderSide(color: Colors.grey[100]!)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.plusCircle, size: 16, color: primaryTeal),
            const SizedBox(width: 8),
            Text(
              isKiloan ? "Tambah Layanan Baru" : "Tambah Barang Baru",
              style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTeal),
            ),
          ],
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
            flex: isCheck ? 0 : (t == "Service" || t == "Service" ? 2 : 1),
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
        onChanged: (v) {
          // FORMAT OTOMATIS SAAT NGETIK DIHAPUS BIAR GAK BUG
        },
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
      // JANGAN DI-FORMAT PAS EDIT (BIAR RAW ANGKA SAJA)
      // subId 1 adalah NAMA, subId > 1 adalah HARGA
      String text = (subId > 1) ? initialText.replaceAll(RegExp(r'[^0-9]'), '') : initialText;
      _editControllers[key] = TextEditingController(text: text);
    }
    return _editControllers[key]!;
  }

  Widget _buildKiloanRow(String id, Map<String, String> item, bool editing) {
    bool isSelected = (_selectedItems[id] ?? 0) > 0;
    bool isBeingEdited = _selectedForEdit.contains(id);

    return Container(
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
            : Text("Rp ${Formatters.formatPrice(item['reg']!)}", textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w800, color: primaryTeal))),
          const SizedBox(width: 4),
          Expanded(child: isBeingEdited
            ? _buildSmallField(_getEditController(id, 3, item['fast']!), "", isCenter: true)
            : Text("Rp ${Formatters.formatPrice(item['fast']!)}", textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w800, color: accentGold))),
        ],
      ),
    );
  }

  Widget _buildSatuanRow(String id, Map<String, String> item, bool editing) {
    bool isSelected = (_selectedItems[id] ?? 0) > 0;
    bool isBeingEdited = _selectedForEdit.contains(id);

    return Container(
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
            ? _buildSmallField(_getEditController(id, 1, item['name']!), "", isAuto: true)
            : Text(item['name']!, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: darkBg))),
          const SizedBox(width: 8),
          Expanded(
            child: isBeingEdited
            ? _buildSmallField(_getEditController(id, 2, item['price']!), "", isCenter: true)
            : Text(
                "Rp ${Formatters.formatPrice(item['price']!)}", 
                textAlign: TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: primaryTeal)
              )
          ),
        ],
      ),
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
