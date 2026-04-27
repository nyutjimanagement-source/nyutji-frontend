import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/widgets/nyutji_notif.dart';

class MitraApprovalKlScreen extends StatefulWidget {
  const MitraApprovalKlScreen({super.key});

  @override
  State<MitraApprovalKlScreen> createState() => _MitraApprovalKlScreenState();
}

class _MitraApprovalKlScreenState extends State<MitraApprovalKlScreen> {
  List<dynamic> pendingUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    await Future.wait([
      auth.fetchPendingApprovals(),
      auth.fetchCouriers(),
    ]);
    if (mounted) {
      setState(() {
        pendingUsers = auth.pendingApprovals;
        isLoading = false;
      });
    }
  }

  Future<void> _handleAction(int id, String action, String name) async {
    final auth = context.read<AuthProvider>();
    final success = await auth.processUserApproval(id, action);
    
    if (success) {
      if (action == 'APPROVED') {
        NyutjiNotif.showSuccess(context, '$name berhasil di-approve!');
      } else {
        NyutjiNotif.showError(context, '$name telah ditolak.');
      }
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final activeCouriers = List.from(auth.couriers);
    // Sort Ascending by Name
    activeCouriers.sort((a, b) => (a['name']?.toString() ?? '').compareTo(b['name']?.toString() ?? ''));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Kelola Kurir Laundry', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E5655),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E5655)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF1E5655),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // SECTION 1: APPROVALS
                  _buildSectionHeader("Antrean Pendaftaran (${pendingUsers.length})"),
                  const SizedBox(height: 12),
                  if (pendingUsers.isEmpty)
                    _buildEmptyBox("Tidak ada pendaftar baru")
                  else
                    ...pendingUsers.map((u) => _buildApprovalCard(u)).toList(),

                  const SizedBox(height: 24),

                  // SECTION 2: MEMBERS
                  _buildSectionHeader("Daftar Anggota Aktif (${activeCouriers.length})"),
                  const SizedBox(height: 12),
                  if (activeCouriers.isEmpty)
                    _buildEmptyBox("Belum ada anggota kurir")
                  else
                    ...activeCouriers.map((u) => _buildMemberCard(u)).toList(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1E5655)));
  }

  Widget _buildEmptyBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
      child: Center(child: Text(msg, style: GoogleFonts.montserrat(color: Colors.grey, fontSize: 12))),
    );
  }

  Widget _buildApprovalCard(dynamic user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: Colors.orange.withOpacity(0.1), child: const Icon(LucideIcons.userPlus, color: Colors.orange, size: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'] ?? 'User', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(user['email'] ?? '-', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(LucideIcons.phone, user['phone_number'] ?? '-'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleAction(user['id'], 'REJECTED', user['name']),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red, side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAction(user['id'], 'APPROVED', user['name']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, foregroundColor: Colors.white,
                      elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(dynamic user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[100]!)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(backgroundColor: const Color(0xFF1E5655).withOpacity(0.1), child: const Icon(LucideIcons.truck, color: Color(0xFF1E5655), size: 18)),
        title: Text(user['name'] ?? 'Kurir', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(LucideIcons.phone, size: 12, color: Colors.grey),
                const SizedBox(width: 6),
                Text(user['phone_number'] ?? '-', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.star, size: 12, color: Colors.amber),
              const SizedBox(width: 4),
              Text("5.0", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber[900])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
