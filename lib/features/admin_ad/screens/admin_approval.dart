import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/widgets/nyutji_notif.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
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
    
    if (!mounted) {
      return;
    }

    if (success) {
      NyutjiNotif.showSuccess(context, '$name berhasil disetujui!');
      _loadPending();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text('Antrean Approval User', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
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
          Icon(LucideIcons.shieldCheck, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Antrean approval kosong', style: GoogleFonts.montserrat(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildUserCard(dynamic user) {
    final bool isKL = user['role'] == 'KL';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildRoleBadge(user['role']),
                const Spacer(),
                Text(
                  'ID: ${user['identifier'] ?? '-'}',
                  style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(user['name'], style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF1A1A1A))),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(LucideIcons.mapPin, size: 14, color: Colors.teal),
                const SizedBox(width: 4),
                Text(user['district']?['name'] ?? 'Wilayah -', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const Divider(height: 32),
            _buildInfoTile(LucideIcons.mail, 'EMail', user['email'] ?? '-'),
            _buildInfoTile(LucideIcons.phone, 'Kontak', user['phone_number'] ?? '-'),
            const SizedBox(height: 24),
            
            if (isKL)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Icon(LucideIcons.info, size: 16, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(child: Text('Menunggu approval dari Mitra Laundry terkait.', style: TextStyle(fontSize: 11, color: Colors.brown))),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleAction(user['id'], 'APPROVED', user['name']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Terima Akun', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color = Colors.blue;
    String label = 'Pelanggan';
    if (role == 'ML') { color = Colors.purple; label = 'Mitra'; }
    if (role == 'KL') { color = Colors.orange; label = 'Kurir'; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
            ],
          )
        ],
      ),
    );
  }
}
