import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class CustomerStatusScreen extends StatelessWidget {
  const CustomerStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF1E5655);
    const Color bgColor = Color(0xFFF3F4F6);
    
    final auth = Provider.of<AuthProvider>(context);
    final Map<String, dynamic> t = {
      'id': {
        'title': 'Status Pesanan',
        'status_wash': 'DICUCI',
        'step_pickup': 'Jemput',
        'step_wash': 'Cuci',
        'step_send': 'Kirim',
        'step_done': 'Selesai',
        'courier': 'Kurir Budi',
        'receipt': 'Rincian Cucian',
        'item': 'Baju/Celana (2 Kg)',
        'fee': 'Biaya Layanan',
        'total': 'Total Dibayar',
      },
      'en': {
        'title': 'Order Status',
        'status_wash': 'WASHING',
        'step_pickup': 'Pickup',
        'step_wash': 'Wash',
        'step_send': 'Send',
        'step_done': 'Done',
        'courier': 'Courier Budi',
        'receipt': 'Laundry Receipt',
        'item': 'Clothes (2 Kg)',
        'fee': 'Service Fee',
        'total': 'Total Paid',
      }
    };
    final currentT = t[auth.lang] ?? t['id'];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(currentT['title'], style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDenseTracker(primaryTeal, currentT),
            const SizedBox(height: 16),
            _buildCourierRow(primaryTeal, currentT),
            const SizedBox(height: 16),
            _buildDenseReceipt(currentT),
          ],
        ),
      ),
    );
  }

  Widget _buildDenseTracker(Color teal, Map<String, dynamic> cT) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("ID: KBY-040426-001", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)), child: Text(cT['status_wash'], style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _trackStep(cT['step_pickup'], LucideIcons.truck, true, teal),
              _trackLine(true, teal),
              _trackStep(cT['step_wash'], LucideIcons.droplets, true, teal),
              _trackLine(false, teal),
              _trackStep(cT['step_send'], LucideIcons.send, false, teal),
              _trackLine(false, teal),
              _trackStep(cT['step_done'], LucideIcons.checkCircle, false, teal),
            ],
          )
        ],
      ),
    );
  }

  Widget _trackStep(String label, IconData icon, bool done, Color teal) {
    return Column(
      children: [
        Icon(icon, size: 20, color: done ? teal : Colors.grey[400]),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: done ? FontWeight.bold : FontWeight.w600, color: done ? Colors.black87 : Colors.grey[400])),
      ],
    );
  }

  Widget _trackLine(bool done, Color teal) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        color: done ? teal : Colors.grey[200],
      ),
    );
  }

  Widget _buildCourierRow(Color teal, Map<String, dynamic> cT) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        children: [
          CircleAvatar(radius: 16, backgroundColor: Colors.grey[200], child: Icon(LucideIcons.user, size: 16, color: Colors.grey[600])),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cT['courier'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold)),
                Text("B 3912 XYZ", style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[500])),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: Icon(LucideIcons.phone, size: 18, color: teal), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ],
      ),
    );
  }

  Widget _buildDenseReceipt(Map<String, dynamic> cT) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cT['receipt'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold)),
          const Divider(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(cT['item'], style: GoogleFonts.montserrat(fontSize: 11)), Text("Rp 16.000", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(cT['fee'], style: GoogleFonts.montserrat(fontSize: 11)), Text("Rp 5.000", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold))]),
          const Divider(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(cT['total'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold)), Text("Rp 21.000", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green))]),
        ],
      ),
    );
  }
}
