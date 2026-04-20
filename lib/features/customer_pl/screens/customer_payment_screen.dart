import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class CustomerPaymentScreen extends StatefulWidget {
  final int totalPrice;
  final int totalItems;
  final String address;
  final bool isPickup;
  final int mitraId;
  final String mitraName;
  final String speed;
  final double distance;
  final String dropMethod;
  final List<Map<String, dynamic>> selectedItemsList;

  const CustomerPaymentScreen({
    super.key,
    required this.totalPrice,
    required this.totalItems,
    required this.address,
    required this.isPickup,
    required this.mitraId,
    required this.mitraName,
    required this.speed,
    required this.distance,
    required this.dropMethod,
    required this.selectedItemsList,
  });

  @override
  State<CustomerPaymentScreen> createState() => _CustomerPaymentScreenState();
}

class _CustomerPaymentScreenState extends State<CustomerPaymentScreen> {
  final Color primaryTeal = const Color(0xFF1E5655);
  final Color primaryRed = const Color(0xFFC3312E);
  final Color bgColor = const Color(0xFFF3F4F6);
  
  String _selectedPayment = "Dompet Nyutji";
  bool _isVAExpanded = false;
  bool _isEWalletExpanded = false;

  final List<Map<String, String>> _vaBanks = [
    {'name': 'Bank BCA', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Bank_Central_Asia.svg/512px-Bank_Central_Asia.svg.png'},
    {'name': 'Bank Mandiri', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/Bank_Mandiri_logo_2016.svg/512px-Bank_Mandiri_logo_2016.svg.png'},
    {'name': 'Bank BNI', 'logo': 'https://upload.wikimedia.org/wikipedia/id/thumb/5/55/BNI_logo.svg/512px-BNI_logo.svg.png'},
    {'name': 'Bank BRI', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2e/BRI_Logo.svg/512px-BRI_Logo.svg.png'},
    {'name': 'CIMB NIAGA', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/43/CIMB_Niaga_logo.svg/512px-CIMB_Niaga_logo.svg.png'},
    {'name': 'Others', 'logo': ''},
  ];

  final List<Map<String, String>> _eWallets = [
    {'name': 'Gopay', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/86/Gopay_logo.svg/512px-Gopay_logo.svg.png'},
    {'name': 'OVO', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/eb/Logo_ovo_purple.svg/512px-Logo_ovo_purple.svg.png'},
    {'name': 'DANA', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/72/Logo_dana_blue.svg/512px-Logo_dana_blue.svg.png'},
    {'name': 'LinkAja', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/85/LinkAja.svg/512px-LinkAja.svg.png'},
    {'name': 'Others', 'logo': ''},
  ];

  void _showBeautifulNotif(String message, bool success) {
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: success ? primaryTeal : primaryRed,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Row(
              children: [
                Icon(success ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(message, style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool needsCourier = widget.isPickup || widget.dropMethod == 'courier';
    int courierFee = needsCourier ? 15000 : 0;
    int grandTotal = widget.totalPrice + courierFee;
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Pembayaran", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDenseInvoice(courierFee, grandTotal),
                const SizedBox(height: 16),
                _buildPaymentMenu(),
              ],
            ),
          ),
          _buildBottomButton(grandTotal),
        ],
      ),
    );
  }

  Widget _buildDenseInvoice(int courierFee, int grandTotal) {
    String invoiceTitle = widget.isPickup ? "Ringkasan Transaksi Pickup Kurir" : "Ringkasan Transaksi Antar Sendiri";
    String speedLabel = widget.speed == 'fast' ? "Fast Track (Same Day)" : "Regular (2-3 Hari)";
    
    String courierServiceName = "Self Drop-off (Gratis)";
    if (widget.isPickup) {
      courierServiceName = "Same Day Pickup Kurir";
    } else if (widget.dropMethod == 'courier') {
      courierServiceName = "Drop Sendiri Antar Kurir";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(invoiceTitle, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black87)),
          const Divider(height: 32),
          
          // Section a: Layanan Laundry
          _invoiceSectionHeader(LucideIcons.shirt, "Layanan Laundry - ${widget.mitraName}"),
          const SizedBox(height: 12),
          _invoiceDetailRow("Jenis Kecepatan", speedLabel),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: widget.selectedItemsList.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("• ${item['name']}", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[700])),
                    Text("${item['count']} ${item['unit']}", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                  ],
                ),
              )).toList(),
            ),
          ),
          
          _invoiceDetailRow("Subtotal Laundry", NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(widget.totalPrice), isBold: true),
          
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF0F0F0))),
          
          // Section b: Layanan Kurir
          _invoiceSectionHeader(LucideIcons.truck, "Layanan Kurir - Menunggu Penugasan Kurir"),
          const SizedBox(height: 12),
          _invoiceDetailRow("Layanan Kurir", courierServiceName),
          _invoiceDetailRow("Jarak Antar", "${widget.distance} Km"),
          _invoiceDetailRow("Biaya Kurir", NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(courierFee), isBold: true),
          
          const Divider(height: 40),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Estimasi Tagihan", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
              Text(
                NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(grandTotal), 
                style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: primaryTeal)
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _invoiceSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 14, color: primaryTeal),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTeal, letterSpacing: 0.5), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _invoiceDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[600])),
          Text(value, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildPaymentMenu() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text("Metode Pembayaran", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900)),
          ),
          
          _paymentParentOption("Dompet Nyutji", "Saldo: Rp 250.000", LucideIcons.wallet, null, isSelected: _selectedPayment == "Dompet Nyutji"),
          
          _paymentParentOption("Virtual Account", "BCA, Mandiri, BNI, dll", LucideIcons.building, () {
            setState(() => _isVAExpanded = !_isVAExpanded);
          }, isExpanded: _isVAExpanded),
          if (_isVAExpanded) 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(children: _vaBanks.map((bank) => _paymentSubOption(bank['name']!, bank['logo']!)).toList()),
            ),
            
          _paymentParentOption("e-Wallet", "Gopay, OVO, DANA, dll", LucideIcons.smartphone, () {
            setState(() => _isEWalletExpanded = !_isEWalletExpanded);
          }, isExpanded: _isEWalletExpanded),
          if (_isEWalletExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(children: _eWallets.map((wallet) => _paymentSubOption(wallet['name']!, wallet['logo']!)).toList()),
            ),
          
          _paymentParentOption("QRIS", "Scan dari aplikasi apa saja", LucideIcons.qrCode, null, isSelected: _selectedPayment == "QRIS"),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _paymentParentOption(String title, String desc, IconData icon, VoidCallback? onTap, {bool isSelected = false, bool isExpanded = false}) {
    bool actuallySelected = isSelected || (_selectedPayment.contains(title) && !isExpanded);
    return InkWell(
      onTap: onTap ?? () => setState(() => _selectedPayment = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!, width: 0.5))),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: actuallySelected ? primaryTeal : bgColor, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: actuallySelected ? Colors.white : Colors.grey[600]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(desc, style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[500])),
                ],
              ),
            ),
            if (onTap != null)
              Icon(isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 16, color: Colors.grey)
            else if (actuallySelected)
              Icon(LucideIcons.checkCircle, size: 18, color: primaryTeal)
          ],
        ),
      ),
    );
  }

  Widget _paymentSubOption(String name, String logoUrl) {
    bool isSel = _selectedPayment == name;
    return InkWell(
      onTap: () => setState(() => _selectedPayment = name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? primaryTeal.withOpacity(0.05) : bgColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSel ? primaryTeal : Colors.transparent),
        ),
        child: Row(
          children: [
            if (logoUrl.isNotEmpty) 
              Image.network(logoUrl, width: 30, height: 20, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(LucideIcons.image, size: 14))
            else
              const Icon(LucideIcons.moreHorizontal, size: 14),
            const SizedBox(width: 12),
            Text(name, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.w500)),
            const Spacer(),
            if (isSel) Icon(LucideIcons.checkCircle, size: 14, color: primaryTeal),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(int grandTotal) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: ElevatedButton(
          onPressed: () {
            _showBeautifulNotif("Pesanan Berhasil Dikonfirmasi!", true);
            Future.delayed(const Duration(seconds: 2), () {
              Navigator.popUntil(context, (route) => route.isFirst);
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryTeal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 0,
          ),
          child: Text("KONFIRMASI PESANAN", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ),
    );
  }
}
