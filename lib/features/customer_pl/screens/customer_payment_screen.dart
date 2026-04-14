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

  const CustomerPaymentScreen({
    Key? key,
    required this.totalPrice,
    required this.totalItems,
    required this.address,
    required this.isPickup,
  }) : super(key: key);

  @override
  State<CustomerPaymentScreen> createState() => _CustomerPaymentScreenState();
}

class _CustomerPaymentScreenState extends State<CustomerPaymentScreen> {
  final Color primaryTeal = const Color(0xFF1E5655);
  final Color bgColor = const Color(0xFFF3F4F6);
  String _selectedPayment = "Virtual Account BCA";

  @override
  Widget build(BuildContext context) {
    int fee = widget.isPickup ? 15000 : 0;
    int grandTotal = widget.totalPrice + fee;
    
    final auth = Provider.of<AuthProvider>(context);
    final Map<String, dynamic> t = {
      'id': {
        'title': 'Pembayaran',
        'summary': 'Ringkasan Transaksi',
        'laundry': 'Layanan Cuci',
        'fee': 'Biaya Pickup/Antar KL',
        'total': 'Total Tagihan',
        'method': 'Metode Pembayaran',
        'pay_now': 'BAYAR SEKARANG',
        'success': 'Pembayaran Berhasil!',
        'wallet': 'Dompet Nyutji',
        'wallet_desc': 'Saldo: Rp 250.000',
        'va': 'Virtual Account BCA',
        'va_desc': 'Proses Otomatis',
        'ewallet': 'Gopay / OVO',
        'ewallet_desc': 'E-Wallet',
      },
      'en': {
        'title': 'Payment',
        'summary': 'Transaction Summary',
        'laundry': 'Laundry Service',
        'fee': 'KL Pickup/Delivery Fee',
        'total': 'Total Bill',
        'method': 'Payment Method',
        'pay_now': 'PAY NOW',
        'success': 'Payment Successful!',
        'wallet': 'Nyutji Wallet',
        'wallet_desc': 'Balance: Rp 250.000',
        'va': 'BCA Virtual Account',
        'va_desc': 'Auto Process',
        'ewallet': 'Gopay / OVO',
        'ewallet_desc': 'E-Wallet',
      }
    };
    final currentT = t[auth.lang] ?? t['id'];

    if (_selectedPayment == "Virtual Account BCA" && auth.lang == 'en') _selectedPayment = "BCA Virtual Account";
    if (_selectedPayment == "BCA Virtual Account" && auth.lang == 'id') _selectedPayment = "Virtual Account BCA";
    if (_selectedPayment == "Dompet Nyutji" && auth.lang == 'en') _selectedPayment = "Nyutji Wallet";
    if (_selectedPayment == "Nyutji Wallet" && auth.lang == 'id') _selectedPayment = "Dompet Nyutji";

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(currentT['title'], style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDenseInvoice(fee, grandTotal, currentT),
                const SizedBox(height: 16),
                _buildDensePaymentMethods(currentT),
              ],
            ),
          ),
          _buildPayButton(grandTotal, currentT),
        ],
      ),
    );
  }

  Widget _buildDenseInvoice(int fee, int grandTotal, Map<String, dynamic> cT) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cT['summary'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          _invoiceRow("${cT['laundry']} (${widget.totalItems} Item)", widget.totalPrice),
          if (widget.isPickup) _invoiceRow(cT['fee'], fee),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(cT['total'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold)),
              Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(grandTotal), style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900, color: primaryTeal)),
            ],
          )
        ],
      ),
    );
  }

  Widget _invoiceRow(String label, int val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600])),
          Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(val), style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildDensePaymentMethods(Map<String, dynamic> cT) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(cT['method'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 0),
          _payOption(cT['wallet'], cT['wallet_desc'], LucideIcons.wallet),
          const Divider(height: 0),
          _payOption(cT['va'], cT['va_desc'], LucideIcons.building),
          const Divider(height: 0),
          _payOption(cT['ewallet'], cT['ewallet_desc'], LucideIcons.smartphone),
        ],
      ),
    );
  }

  Widget _payOption(String title, String desc, IconData icon) {
    bool isSel = _selectedPayment == title;
    return InkWell(
      onTap: () => setState(() => _selectedPayment = title),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: isSel ? primaryTeal.withOpacity(0.05) : Colors.transparent,
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSel ? primaryTeal : Colors.grey[500]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
                  Text(desc, style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[500])),
                ],
              ),
            ),
            if (isSel) Icon(LucideIcons.checkCircle, size: 18, color: primaryTeal)
          ],
        ),
      ),
    );
  }

  Widget _buildPayButton(int grand, Map<String, dynamic> cT) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0,-5))]),
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${cT['success']} ($_selectedPayment)")));
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: Text(cT['pay_now'], style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
