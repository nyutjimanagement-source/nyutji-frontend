import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/nyutji_theme.dart';
import '../../../providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomerOkBayarScreen extends ConsumerStatefulWidget {
  final int grandTotal;
  final String orderType;
  final String dropMethod;
  final String districtCode;
  final String speed;
  final String address;
  final String districtName;
  final String mitraName;
  final int totalItems;
  final bool isPickup;
  final String selectedPayment;
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
    required this.mitraName,
    required this.totalItems,
    required this.isPickup,
    required this.selectedPayment,
    required this.onPay,
  });

  @override
  ConsumerState<CustomerOkBayarScreen> createState() => _CustomerOkBayarScreenState();
}

class _CustomerOkBayarScreenState extends ConsumerState<CustomerOkBayarScreen> {
  Widget _notaRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 105, child: Text(label, style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600]))),
          const Text(" :  ", style: TextStyle(fontSize: 13, color: Colors.grey)),
          Expanded(child: Text(value, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: Colors.black87))),
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
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 5)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Nota
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: NyutjiTheme.m3Primary.withValues(alpha: 0.9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Column(
                  children: [
                    const Icon(LucideIcons.fileText, color: Colors.white, size: 30),
                    const SizedBox(height: 8),
                    Text(notaTitle, style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(notaSubtitle, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              
              // Isi Nota
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _notaRow("No Nota", "$orderNo / ${widget.speed.toUpperCase()}"),
                    _notaRow("Nama", auth.user?['name'] ?? 'Pelanggan Nyutji'),
                    
                    // SMART SUMMARY LOGIC
                    if (widget.orderType == 'pickup') ...[
                      _notaRow("Alamat Pickup", "${widget.address}, ${widget.districtName}"),
                      _notaRow("Mitra Laundry", widget.mitraName),
                      _notaRow("Pengantaran", "Kurir Antar ke Alamat Pelanggan"),
                    ] else ...[
                      _notaRow("Lokasi Laundry", widget.mitraName),
                      _notaRow("Metode Antar", "Mandiri oleh Pelanggan"),
                      if (widget.dropMethod == 'courier')
                        _notaRow("Alamat Pengiriman", widget.address)
                      else
                        _notaRow("Pengambilan", "Diambil Sendiri oleh Pelanggan"),
                    ],

                    _notaRow("Tgl Pesan", DateFormat('dd MMM yyyy, HH:mm').format(now)),
                    _notaRow("Est. Selesai", DateFormat('dd MMM yyyy').format(finishDate)),
                    const Divider(height: 24),
                    _notaRow("Items Cucian", "${widget.totalItems} Items (Kiloan & Satuan)"),
                    _notaRow(widget.isPickup ? "Est. Total Biaya" : "Total Biaya", NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(widget.grandTotal), isBold: true),
                    _notaRow("Metode Bayar", widget.selectedPayment, isBold: true),
                  ],
                ),
              ),

              if (widget.selectedPayment == 'QRIS')
                Padding(
                  padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                  child: Column(
                    children: [
                      Text("Scan QR Code di bawah ini:", style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/QR_code_for_mobile_English_Wikipedia.svg/300px-QR_code_for_mobile_English_Wikipedia.svg.png',
                          width: 150,
                          height: 150,
                          errorWidget: (_, __, ___) => const Icon(LucideIcons.qrCode, size: 150, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
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
