import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/nyutji_theme.dart';
import '../../../providers/auth_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../data/services/api_service.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/widgets/nyutji_notif.dart';

class CustomerOkBayarScreen extends ConsumerStatefulWidget {
  final int grandTotal;
  final String orderType;
  final String dropMethod;
  final String districtCode;
  final String speed;
  final String address;
  final String districtName;
  final dynamic mitraId;
  final String mitraName;
  final int totalItems;
  final bool isPickup;
  final String selectedPayment;
  final String pickupNote;
  final void Function(DateTime finishDate) onPay;

  const CustomerOkBayarScreen({
    super.key,
    required this.grandTotal,
    required this.orderType,
    required this.dropMethod,
    required this.districtCode,
    required this.speed,
    required this.address,
    required this.districtName,
    required this.mitraId,
    required this.mitraName,
    required this.totalItems,
    required this.isPickup,
    required this.selectedPayment,
    this.pickupNote = '',
    required this.onPay,
  });

  @override
  ConsumerState<CustomerOkBayarScreen> createState() => _CustomerOkBayarScreenState();
}

class _CustomerOkBayarScreenState extends ConsumerState<CustomerOkBayarScreen> {
  bool _isLoadingQris = false;
  String? _qrisPayload;
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.selectedPayment == 'QRIS') {
      _loadMitraQris();
    }
  }

  Future<void> _loadMitraQris() async {
    setState(() {
      _isLoadingQris = true;
    });
    try {
      final api = ApiService();
      final qris = await api.getMitraQris(widget.mitraId);
      if (mounted) {
        setState(() {
          _qrisPayload = qris;
          _isLoadingQris = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading Mitra QRIS: $e");
      if (mounted) {
        setState(() {
          _isLoadingQris = false;
        });
      }
    }
  }

  Future<void> _captureAndSaveReceipt() async {
    // 1. Tampilkan dialog konfirmasi terlebih dahulu
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Simpan Nota", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text("Apakah Anda ingin menyimpan Nota Estimasi Transaksi ini sebagai gambar di penyimpanan lokal?", style: GoogleFonts.montserrat(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Batal", style: GoogleFonts.montserrat(color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: NyutjiTheme.m3Primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("Simpan", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Berikan sedikit delay agar painting frame selesai (mencegah error !debugNeedsPaint)
      await Future.delayed(const Duration(milliseconds: 50));

      final RenderRepaintBoundary? boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) {
          NyutjiNotif.showError(context, "Gagal menangkap layar nota.");
        }
        return;
      }
      
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (mounted) {
          NyutjiNotif.showError(context, "Gagal memproses gambar.");
        }
        return;
      }
      
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      
      Directory? directory;
      String folderName = "Dokumen";
      
      try {
        if (Platform.isAndroid) {
          // Cari folder Downloads publik
          directory = await getDownloadsDirectory();
          folderName = "Downloads";
        } else if (Platform.isIOS) {
          directory = await getApplicationDocumentsDirectory();
          folderName = "Documents (Files)";
        }
      } catch (e) {
        debugPrint("Gagal mendeteksi folder khusus: $e");
      }
      
      // Fallback ke Application Documents jika null
      directory ??= await getApplicationDocumentsDirectory();
      
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = '${directory.path}/nota_$timestamp.png';
      
      final File imgFile = File(filePath);
      await imgFile.writeAsBytes(pngBytes);
      
      if (mounted) {
        NyutjiNotif.showSuccess(
          context, 
          "Nota berhasil disimpan ke folder $folderName handphone Anda!\n(Nama file: nota_$timestamp.png)"
        );
      }
    } catch (e) {
      debugPrint("Gagal menyimpan gambar: $e");
      if (mounted) {
        NyutjiNotif.showError(context, "Gagal menyimpan gambar: $e");
      }
    }
  }

  String _getShortenedAddress(String fullAddress) {
    if (fullAddress.isEmpty) return "";
    List<String> parts = fullAddress.split(',');
    
    int stopIndex = -1;
    for (int i = 0; i < parts.length; i++) {
      String partLower = parts[i].toLowerCase();
      if (partLower.contains('kota') || 
          partLower.contains('kab.') || 
          partLower.contains('kabupaten')) {
        stopIndex = i;
        break;
      }
    }
    
    if (stopIndex != -1) {
      return parts.sublist(0, stopIndex + 1).map((e) => e.trim()).join(', ');
    }
    
    if (parts.length > 2) {
      return parts.sublist(0, parts.length - 2).map((e) => e.trim()).join(', ');
    }
    
    return fullAddress.trim();
  }

  Widget _notaRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label, 
              style: GoogleFonts.montserrat(
                fontSize: 13, 
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value, 
              textAlign: TextAlign.left,
              style: GoogleFonts.montserrat(
                fontSize: 13, 
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600, 
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final now = DateTime.now();

    // JENIS NOTA & JUDUL
    String notaTitle = "Nota Estimasi Transaksi";
    String notaSubtitle = "Jemput & Antar Kurir";
    
    if (widget.orderType == 'drop') {
      notaTitle = "Nota Transaksi";
      if (widget.dropMethod == 'self') {
        notaSubtitle = "Drop & Ambil Mandiri";
      } else {
        notaSubtitle = "Drop Mandiri & Antar Kurir";
      }
    }
    
    // FORMAT JENDERAL: KODE_KECAMATAN-YYYYMMDD-counting
    final stringkatBtn = widget.districtCode.toUpperCase();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final counting = now.millisecondsSinceEpoch.toString().substring(9);
    final orderNo = "$stringkatBtn-$dateStr-$counting";
    
    final finishDate = widget.speed == 'fast' 
        ? now.add(const Duration(days: 1)) 
        : now.add(const Duration(days: 3));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: NyutjiTheme.m3Primary,
        title: Text("Konfirmasi Pembayaran", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: RepaintBoundary(
          key: _boundaryKey,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Nota
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notaTitle, 
                              style: GoogleFonts.montserrat(
                                color: Colors.black87, 
                                fontWeight: FontWeight.w900, 
                                fontSize: 16,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notaSubtitle, 
                              style: GoogleFonts.montserrat(
                                color: Colors.grey[600], 
                                fontSize: 12, 
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(
                          LucideIcons.fileText, 
                          color: NyutjiTheme.m3Primary.withValues(alpha: 0.8), 
                          size: 28,
                        ),
                        tooltip: "Simpan Gambar",
                        onPressed: _captureAndSaveReceipt,
                      ),
                    ],
                  ),
                ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
              
              // Isi Nota
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _notaRow("No Nota", "$orderNo / ${widget.speed.toUpperCase()}"),
                    _notaRow("Nama", auth.user?['name'] ?? 'Pelanggan Nyutji'),
                    
                    // SMART SUMMARY LOGIC
                    if (widget.orderType == 'pickup') ...[
                      _notaRow("Alamat Pickup", "${_getShortenedAddress(widget.address)}, ${widget.districtName}"),
                      _notaRow("Mitra Laundry", widget.mitraName),
                      _notaRow("Pengantaran", "Kurir Antar ke Alamat Pelanggan"),
                    ] else ...[
                      _notaRow("Lokasi Laundry", widget.mitraName),
                      _notaRow("Metode Antar", "Mandiri oleh Pelanggan"),
                      if (widget.dropMethod == 'courier')
                        _notaRow("Alamat Pengiriman", _getShortenedAddress(widget.address))
                      else
                        _notaRow("Pengambilan", "Diambil Sendiri oleh Pelanggan"),
                    ],

                    _notaRow("Tgl Pesan", DateFormat('dd MMM yyyy, HH:mm').format(now)),
                    _notaRow("Est. Selesai", DateFormat('dd MMM yyyy').format(finishDate)),
                    const Divider(height: 24, thickness: 1, color: Color(0xFFF3F4F6)),
                    _notaRow("Items Cucian", "${widget.totalItems} Items (Kiloan & Satuan)"),
                    if (widget.pickupNote.trim().isNotEmpty)
                      _notaRow("Notes Pelanggan", widget.pickupNote.trim()),
                    _notaRow(widget.isPickup ? "Est. Total Biaya" : "Total Biaya", NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(widget.grandTotal), isBold: true),
                    _notaRow("Metode Bayar", widget.selectedPayment, isBold: true),
                  ],
                ),
              ),

              if (widget.selectedPayment == 'QRIS')
                Padding(
                  padding: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
                  child: Column(
                    children: [
                      Text(
                        "Scan QR Code di bawah ini:", 
                        style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (_isLoadingQris)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_qrisPayload != null && _qrisPayload!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[200]!, width: 1.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: QrImageView(
                            data: _qrisPayload!,
                            version: QrVersions.auto,
                            size: 160.0,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black87,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black87,
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            "Mitra Laundry belum mengaktifkan pembayaran QRIS.",
                            style: GoogleFonts.montserrat(
                              fontSize: 12, 
                              color: Colors.red[600], 
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onPay(finishDate);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NyutjiTheme.m3Primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4,
            ),
            child: Text("BAYAR SEKARANG", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
