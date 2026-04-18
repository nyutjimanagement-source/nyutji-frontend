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
    _loadPending();
  }

  Future<void> _loadPending() async {
    final auth = context.read<AuthProvider>();
    final data = await auth.fetchPendingApprovals();
    setState(() {
      pendingUsers = data;
      isLoading = false;
    });
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
      _loadPending();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Antrean Kurir Baru', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF740006),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF740006)))
          : pendingUsers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pendingUsers.length,
                  itemBuilder: (context, index) {
                    final user = pendingUsers[index];
                    return _buildUserCard(user);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.userX, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Tidak ada pendaftar kurir baru', style: GoogleFonts.montserrat(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildUserCard(dynamic user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF740006).withOpacity(0.1),
                  child: const Icon(LucideIcons.truck, color: Color(0xFF740006), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'], style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(user['identifier'] ?? 'NO-ID', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(LucideIcons.mapPin, 'Kecamatan', user['district']?['name'] ?? '-'),
            _buildInfoRow(LucideIcons.phone, 'Handphone', user['phone_number'] ?? '-'),
            _buildInfoRow(LucideIcons.mail, 'Email', user['email'] ?? '-'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleAction(user['id'], 'REJECTED', user['name']),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAction(user['id'], 'APPROVED', user['name']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
