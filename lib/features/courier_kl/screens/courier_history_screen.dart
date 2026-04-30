import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class CourierHistoryScreen extends StatefulWidget {
  const CourierHistoryScreen({super.key});

  @override
  State<CourierHistoryScreen> createState() => _CourierHistoryScreenState();
}

class _CourierHistoryScreenState extends State<CourierHistoryScreen> {
  final Color primaryTeal = const Color(0xFF286B6A);
  final Color bgColor = const Color(0xFFF3F4F6);
  final Color textDark = const Color(0xFF2D2A26);
  final Color textGrey = const Color(0xFF78716C);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    final Map<String, dynamic> t = {
      'id': {
        'history_title': 'Riwayat Tugas',
        'income': 'Total Pendapatan',
        'orders': 'Total Order',
        'rating': 'Rating',
        'pickup': 'Jemputan',
        'delivery': 'Antaran',
        'weekly_target': 'TARGET MINGGUAN',
        'today_summary': 'RINGKASAN HARI INI',
        'recent_logs': 'LOG AKTIVITAS TERBARU',
        'received': 'Diterima',
      },
      'en': {
        'history_title': 'Task History',
        'income': 'Total Earnings',
        'orders': 'Total Orders',
        'rating': 'Rating',
        'pickup': 'Pickups',
        'delivery': 'Deliveries',
        'weekly_target': 'WEEKLY TARGET',
        'today_summary': 'TODAY SUMMARY',
        'recent_logs': 'RECENT ACTIVITY LOGS',
        'received': 'Received',
      },
    };

    final currentT = t[auth.lang] ?? t['id'];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHistorySummaryCard(currentT),
                const SizedBox(height: 16),
                _buildWeeklyProgressCard(currentT),
                const SizedBox(height: 24),
                _buildHistoryActionButtons(currentT),
                const SizedBox(height: 24),
                _buildTodaySummaryCard(currentT),
                const SizedBox(height: 24),
                _buildRecentTasksSection(currentT),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySummaryCard(Map<String, dynamic> currentT) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryTeal, const Color(0xFF3B8E8C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: primaryTeal.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(currentT['income'], style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
              Text("Rp 8.200.000", style: GoogleFonts.montserrat(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
          Container(width: 1, height: 24, color: Colors.white24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(currentT['rating'], style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
              Text("4.9 / 5.0", style: GoogleFonts.montserrat(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressCard(Map<String, dynamic> currentT) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(currentT['weekly_target'], style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: textGrey, letterSpacing: 1)),
              Text("75%", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: primaryTeal)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: 0.75, backgroundColor: bgColor, valueColor: AlwaysStoppedAnimation(primaryTeal), minHeight: 8),
          ),
          const SizedBox(height: 12),
          Text("Selesai: 154 / 200 Order", style: GoogleFonts.montserrat(fontSize: 10, color: textGrey, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTodaySummaryCard(Map<String, dynamic> currentT) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(currentT['today_summary'], style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.white70, letterSpacing: 1.5)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _todayStatItem("12", "Regular", Colors.blue),
              _todayStatItem("5", "Flash", const Color(0xFFC3312E)),
              _todayStatItem("3", "VIP", Colors.amber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _todayStatItem(String count, String label, Color color) {
    return Column(
      children: [
        Text(count, style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 20, color: color)),
        Text(label, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 10, color: Colors.white38)),
      ],
    );
  }

  Widget _buildHistoryActionButtons(Map<String, dynamic> currentT) {
    return Row(
      children: [
        Expanded(child: _actionBtn(LucideIcons.package, currentT['pickup'], primaryTeal)),
        const SizedBox(width: 12),
        Expanded(child: _actionBtn(LucideIcons.truck, currentT['delivery'], primaryTeal.withValues(alpha: 0.6))),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18),
      label: Text(label, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    );
  }

  Widget _buildRecentTasksSection(Map<String, dynamic> currentT) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(currentT['recent_logs'], style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 12, color: textDark, letterSpacing: 1)),
            Icon(LucideIcons.listFilter, size: 16, color: textGrey),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return _buildHistoryCard(index, index % 2 == 0 ? 'pickup' : 'delivery', currentT);
          },
        ),
      ],
    );
  }

  Widget _buildHistoryCard(int index, String type, Map<String, dynamic> currentT) {
    bool isPickup = type == 'pickup';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPickup ? primaryTeal.withValues(alpha: 0.05) : Colors.blue.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPickup ? LucideIcons.package : LucideIcons.truck,
              color: isPickup ? primaryTeal : Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFFF8C42).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    "${index % 3 == 0 ? 'KBY' : index % 3 == 1 ? 'PLM' : 'JKT'}-09042026-00${index + 1}", 
                    style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFD35400))
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Customer Name ${index + 1}",
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 15, color: textDark),
                ),
                Text(
                  "09 April 2026 • 08:30",
                  style: GoogleFonts.montserrat(fontSize: 10, color: textGrey, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  "Rp 25.000",
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 13, color: const Color(0xFFD35400)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
            child: Text(currentT['received'], style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)),
          ),
        ],
      ),
    );
  }
}
