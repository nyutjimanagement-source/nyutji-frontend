import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MitraCourierManagementScreen extends StatefulWidget {
  const MitraCourierManagementScreen({Key? key}) : super(key: key);

  @override
  State<MitraCourierManagementScreen> createState() => _MitraCourierManagementScreenState();
}

class _MitraCourierManagementScreenState extends State<MitraCourierManagementScreen> {
  final Color primaryTeal = const Color(0xFF1E5655);
  final Color darkText = const Color(0xFF111827);
  final Color bgColor = const Color(0xFFF3F4F6);

  // Mock Data untuk simulasi soft launch
  final List<Map<String, dynamic>> activeCouriers = [
    {'id': 'KL-001', 'name': 'Budi Santoso', 'status': 'Aktif', 'rating': '4.8'},
    {'id': 'KL-005', 'name': 'Agus Prayogo', 'status': 'Aktif', 'rating': '4.9'},
  ];

  final List<Map<String, dynamic>> pendingApprovals = [
    {'id': 'KL-REQ-99', 'name': 'Siti Aminah', 'loc': 'Kebayoran', 'time': '1 jam lalu'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Kelola Kurir Laundry", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: darkText,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildApprovalSection(),
            const SizedBox(height: 16),
            _buildActiveSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              const Icon(LucideIcons.userPlus, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text("Permintaan Bergabung (KL)", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkText)),
            ],
          ),
        ),
        if (pendingApprovals.isEmpty)
           const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Tidak ada permintaan baru"))),
        ...pendingApprovals.map((kl) => _buildApprovalCard(kl)).toList(),
      ],
    );
  }

  Widget _buildApprovalCard(Map<String, dynamic> kl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(backgroundColor: Color(0xFFF3F4F6), child: Icon(LucideIcons.user, size: 20, color: Colors.grey)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kl['name'], style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkText)),
                    Text("${kl['id']} • ${kl['loc']} • ${kl['time']}", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text("Tolak", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Setujui", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActiveSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              const Icon(LucideIcons.truck, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Text("Kurir Aktif Milik ML-KBY-0911", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkText)),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activeCouriers.length,
          itemBuilder: (context, index) {
            final kl = activeCouriers[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[100]!)),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFF3F4F6), child: Icon(LucideIcons.user, size: 18, color: Colors.teal)),
                title: Text(kl['name'], style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text("${kl['id']} • Rating: ${kl['rating']}", style: GoogleFonts.montserrat(fontSize: 11)),
                trailing: const Icon(LucideIcons.moreVertical, size: 16),
              ),
            );
          },
        )
      ],
    );
  }
}
