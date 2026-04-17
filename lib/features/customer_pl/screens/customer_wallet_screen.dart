import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class CustomerWalletScreen extends StatefulWidget {
  const CustomerWalletScreen({super.key});

  @override
  State<CustomerWalletScreen> createState() => _CustomerWalletScreenState();
}

class _CustomerWalletScreenState extends State<CustomerWalletScreen> {
  final Color primaryTeal = const Color(0xFF1E5655);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final Map<String, dynamic> t = {
      'id': {
        'title': 'Dompet Nyutji',
        'active_balance': 'Saldo Aktif',
        'topup': 'Top Up',
        'history': 'Riwayat Terakhir',
        'pay_wash': 'Bayar Cuci',
      },
      'en': {
        'title': 'Nyutji Wallet',
        'active_balance': 'Active Balance',
        'topup': 'Top Up',
        'history': 'Recent History',
        'pay_wash': 'Laundry Payment',
      }
    };
    final currentT = t[auth.lang] ?? t['id'];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(currentT['title'], style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: primaryTeal, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentT['active_balance'], style: GoogleFonts.montserrat(fontSize: 11, color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text("Rp 245.500", style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.plus, size: 14),
                    label: Text(currentT['topup'], style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black87, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currentT['history'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold)),
                  const Divider(height: 24),
                  _buildHistoryRow("${currentT['pay_wash']} KBY-001", "- Rp 45.000", Colors.red),
                  _buildHistoryRow("${currentT['topup']} BCA", "+ Rp 100.000", Colors.green),
                  _buildHistoryRow("${currentT['pay_wash']} KBY-000", "- Rp 20.000", Colors.red),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryRow(String title, String val, Color c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle), child: Icon(c == Colors.green ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight, size: 14, color: c)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text("12 Apr 2026", style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[500])),
                ],
              ),
            ],
          ),
          Text(val, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: c)),
        ],
      ),
    );
  }
}
