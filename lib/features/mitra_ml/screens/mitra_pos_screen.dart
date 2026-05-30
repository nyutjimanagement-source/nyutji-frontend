import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../core/constants/api_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/services/api_service.dart';

const Color primaryTeal = Color(0xFF1E5655);

class MitraPosScreen extends StatefulWidget {
  const MitraPosScreen({super.key});

  @override
  State<MitraPosScreen> createState() => _MitraPosScreenState();
}

class _MitraPosScreenState extends State<MitraPosScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, List<dynamic>> _groupedItems = {};
  // Cache-busting per item: itemId -> timestamp
  final Map<dynamic, int> _photoVersions = {};

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final mitraId = auth.user?['identifier'];
      if (mitraId == null) throw Exception("Mitra ID tidak ditemukan");

      final items = await _api.getMitraItems(mitraId);
      
      Map<String, List<dynamic>> grouped = {};
      for (var item in items) {
        final cat = item['category'] ?? 'Lainnya';
        if (!grouped.containsKey(cat)) grouped[cat] = [];
        grouped[cat]!.add(item);
      }

      setState(() {
        _groupedItems = grouped;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return "Rp 0";
    final num = int.tryParse(amount.toString()) ?? 0;
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(num);
  }

  Future<void> _showEditBottomSheet(BuildContext context, dynamic item) async {
    File? selectedImage;
    bool isUploading = false;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 24, right: 24, top: 24
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Text("Update Foto Layanan", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(item['name'] ?? 'Layanan', style: GoogleFonts.montserrat(fontSize: 14, color: primaryTeal, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  
                  // Textbox ReadOnly Harga
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Harga Reguler", style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600])),
                            Text(_formatCurrency(item['price_regular'] ?? item['reg'] ?? 0), style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Harga Ekspres", style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600])),
                            Text(_formatCurrency(item['price_fast'] ?? item['fast'] ?? 0), style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Image Preview
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
                      if (picked != null) {
                        setModalState(() => selectedImage = File(picked.path));
                      }
                    },
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryTeal.withValues(alpha: 0.3), width: 1.5, style: BorderStyle.solid),
                      ),
                      child: selectedImage != null 
                        ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(selectedImage!, fit: BoxFit.cover))
                        : (item['url_photo'] != null)
                          ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network("${ApiConstants.baseUrl}${item['url_photo']}", fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(Icons.broken_image, color: Colors.grey[400], size: 40)))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_outlined, size: 40, color: primaryTeal.withValues(alpha: 0.6)),
                                const SizedBox(height: 8),
                                Text("Ketuk untuk Ambil Foto", style: GoogleFonts.montserrat(color: primaryTeal, fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  ElevatedButton(
                    onPressed: isUploading ? null : () async {
                      if (selectedImage == null) {
                        NyutjiNotif.showError(context, "Pilih foto terlebih dahulu");
                        return;
                      }
                      
                      setModalState(() => isUploading = true);
                      try {
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        final token = auth.token;
                        if (token == null) throw Exception("Sesi telah habis");
                        
                        var request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.baseUrl}/mitras/items/${item['id']}/photo'));
                        request.headers.addAll({ 'Authorization': 'Bearer $token' });
                        request.files.add(await http.MultipartFile.fromPath('image', selectedImage!.path));
                        
                        final streamedResponse = await request.send();
                        if (streamedResponse.statusCode == 200) {
                          // Evict cache Flutter untuk URL lama
                          final oldFileName = item['url_photo'];
                          if (oldFileName != null) {
                            final oldVer = _photoVersions[item['id']] ?? 0;
                            final oldFullUrl = "${ApiConstants.baseUrl}/nyutji-storage/uploads/inventory/$oldFileName?v=$oldVer";
                            await NetworkImage(oldFullUrl).evict();
                          }
                          // Update versi item ini → trigger rebuild dengan URL baru
                          if (mounted) {
                            setState(() {
                              _photoVersions[item['id']] = DateTime.now().millisecondsSinceEpoch;
                            });
                          }
                          await _fetchItems();
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            NyutjiNotif.showSuccess(ctx, "Foto layanan berhasil diperbarui!");
                          }
                        } else {
                          throw Exception("Gagal mengunggah foto. Code: ${streamedResponse.statusCode}");
                        }
                      } catch (e) {
                        if (ctx.mounted) NyutjiNotif.showError(ctx, e.toString());
                      } finally {
                        if (mounted) setModalState(() => isUploading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: isUploading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text("Simpan Foto", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Point of Sales", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryTeal))
        : _groupedItems.isEmpty
          ? Center(child: Text("Belum ada layanan.", style: GoogleFonts.montserrat(color: Colors.grey)))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: _groupedItems.entries.map((entry) {
                final category = entry.key;
                final items = entry.value;

                return SliverMainAxisGroup(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          category,
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 0,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.65, // Taller cells to accommodate staggered padding
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = items[index];
                            final categoryItem = item['category']?.toString() ?? '';
                            final unit = (categoryItem.toLowerCase() == 'satuan') 
                                ? 'Pcs' 
                                : (item['unit'] ?? 'Kg');
                            final hasPhoto = item['url_photo'] != null;
                            final priceReg = _formatCurrency(item['price_regular'] ?? item['reg'] ?? 0);
                            final priceFast = _formatCurrency(item['price_fast'] ?? item['fast'] ?? 0);
                            
                            final isOdd = index % 2 != 0;

                            return Padding(
                              padding: EdgeInsets.only(
                                top: isOdd ? 32.0 : 0.0,
                                bottom: isOdd ? 0.0 : 32.0,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    )
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Area atas: foto atau ikon
                                        Expanded(
                                          flex: 3,
                                          child: ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                // Background gradient teal (selalu ada)
                                                Container(
                                                  decoration: const BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                      colors: [primaryTeal, Color(0xFF2D7A78)],
                                                    ),
                                                  ),
                                                ),
                                                // Foto jika ada, ikon jika tidak
                                                if (hasPhoto)
                                                  Image.network(
                                                    key: ValueKey('${item['url_photo']}_${_photoVersions[item['id']] ?? 0}'),
                                                    "${ApiConstants.baseUrl}/nyutji-storage/uploads/inventory/${item['url_photo']}?v=${_photoVersions[item['id']] ?? 0}",
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 40),
                                                  )
                                                else
                                                  Center(
                                                    child: Icon(
                                                      Icons.dry_cleaning,
                                                      color: Colors.white.withValues(alpha: 0.25),
                                                      size: 56,
                                                    ),
                                                  ),
                                                // Overlay harga (selalu di atas)
                                                Positioned(
                                                  bottom: 0,
                                                  left: 0,
                                                  right: 0,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin: Alignment.topCenter,
                                                        end: Alignment.bottomCenter,
                                                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                                                      ),
                                                    ),
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          margin: const EdgeInsets.symmetric(horizontal: 8),
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white.withValues(alpha: hasPhoto ? 0.85 : 0.15),
                                                            borderRadius: BorderRadius.circular(8),
                                                            border: Border.all(color: Colors.white30, width: 1),
                                                          ),
                                                          child: Text(
                                                            "$priceReg / $unit",
                                                            style: GoogleFonts.montserrat(
                                                              color: hasPhoto ? primaryTeal : Colors.white,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                        if ((item['price_fast'] ?? 0) > 0) ...[
                                                          const SizedBox(height: 4),
                                                          Container(
                                                            margin: const EdgeInsets.symmetric(horizontal: 8),
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                            decoration: BoxDecoration(
                                                              color: Colors.orange.withValues(alpha: 0.9),
                                                              borderRadius: BorderRadius.circular(8),
                                                              border: Border.all(color: Colors.white30, width: 1),
                                                            ),
                                                            child: Text(
                                                              "Ekspres: $priceFast / $unit",
                                                              style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                                            ),
                                                          ),
                                                        ]
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Nama Layanan di bagian bawah
                                        Expanded(
                                          flex: 1,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            child: Center(
                                              child: Text(
                                                item['name'] ?? 'Layanan',
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.black87,
                                                  height: 1.3,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Chip Add / Edit
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: GestureDetector(
                                        onTap: () => _showEditBottomSheet(context, item),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: hasPhoto ? Colors.white : primaryTeal,
                                            borderRadius: BorderRadius.circular(20),
                                            border: hasPhoto ? Border.all(color: primaryTeal, width: 1.2) : null,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.12),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            hasPhoto ? "Edit" : "Add",
                                            style: GoogleFonts.montserrat(
                                              color: hasPhoto ? primaryTeal : Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: items.length,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
    );
  }
}
