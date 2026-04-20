import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import 'admin_approval.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  static const Color primaryTeal = Color(0xFF1E5655);
  static const Color bgColor = Color(0xFFF3F4F6);
  static const Color darkGray = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildApprovalSection(context),
            const SizedBox(height: 24),
            _buildAdminStatsGrid(context),
            const SizedBox(height: 24),
            _buildUserManagementGrid(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
      decoration: const BoxDecoration(
        color: darkGray,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Manajemen Users", style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          Text("Kelola PL, ML, KL & Sistem", style: GoogleFonts.montserrat(fontSize: 12, color: Colors.white.withOpacity(0.7))),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(LucideIcons.search, color: Colors.white70, size: 18),
                const SizedBox(width: 12),
                Text("Cari ID/Nama User...", style: GoogleFonts.montserrat(fontSize: 13, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildActionBtn("Tambah\nKecamatan", LucideIcons.mapPin, Colors.orange),
          const SizedBox(width: 12),
          _buildActionBtn("Lihat\nSaldo", LucideIcons.wallet, Colors.green),
          const SizedBox(width: 12),
          _buildActionBtn("Reset\nPassword", LucideIcons.key, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String title, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: darkGray)),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final pending = auth.pendingApprovals;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Antrean Persetujuan (Approval) [${pending.length}]", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkGray)),
              const SizedBox(height: 12),
              if (pending.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Text("Tidak ada antrean pendaftar baru.", textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey)),
                )
              else
                ...pending.map((user) => _buildApprovalItem(
                      context,
                      user['role'] == 'ML' ? "Mitra (ML)" : "Pelanggan (PL)",
                      user['name'] ?? "Nama Tidak Ada",
                      user['district']?['name'] ?? "Wilayah -",
                      "Baru saja",
                    )),
            ],
          );
        },
      ),
    );
  }
  Widget _buildApprovalItem(BuildContext context, String role, String name, String loc, String time) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminApprovalScreen())),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: primaryTeal.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(LucideIcons.userCheck, color: primaryTeal, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: darkGray)),
                  Text("$role • $loc", style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[600])),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF286B6A).withOpacity(0.8), borderRadius: BorderRadius.circular(8)),
              child: Text("Review", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminStatsGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCard("Leveling ML", "Atur KPI & Syarat Naik Kelas", LucideIcons.barChart, Colors.orange[50]!, Colors.orange),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _showUserListSheet(context),
                child: _buildStatCard("Kategori ML", "Kecil, Menengah, Enterprise", LucideIcons.tags, Colors.blue[50]!, Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard("Top ML Rate", "4.9 / 5.0", LucideIcons.star, Colors.amber[50]!, Colors.amber),
              const SizedBox(width: 12),
              _buildStatCard("Top KL Rate", "4.8 / 5.0", LucideIcons.bike, Colors.blue[50]!, Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  void _showUserListSheet(BuildContext context) {
    final auth = context.read<AuthProvider>();
    
    // Trigger fetch data
    auth.fetchAllUsers();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Icon(LucideIcons.users, color: darkGray),
                  const SizedBox(width: 12),
                  Text("Daftar Anggota Ekosistem", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: darkGray)),
                ],
              ),
            ),
            Expanded(
              child: Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (auth.allUsers.isEmpty && auth.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: primaryTeal));
                  }
                  
                  if (auth.allUsers.isEmpty) {
                    return Center(child: Text("Data user tidak ditemukan", style: GoogleFonts.montserrat(color: Colors.grey)));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: auth.allUsers.length,
                    separatorBuilder: (context, index) => Divider(color: Colors.grey[100]),
                    itemBuilder: (context, index) {
                      final u = auth.allUsers[index];
                      final name = u['name'] ?? 'No Name';
                      final role = u['role'] ?? '-';
                      final district = u['district']?['name'] ?? 'Luar Area';
                      final identifier = u['identifier'] ?? '-';
                      final status = u['registration_status'] ?? 'PENDING';
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: role == 'ML' ? Colors.blue.withOpacity(0.1) : (role == 'KL' ? Colors.orange.withOpacity(0.1) : Colors.teal.withOpacity(0.1)),
                                shape: BoxShape.circle
                              ),
                              child: Center(child: Text(role, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: role == 'ML' ? Colors.blue : (role == 'KL' ? Colors.orange : Colors.teal)))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: darkGray)),
                                  Text("$identifier | $district", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: status == 'APPROVED' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6)
                              ),
                              child: Text(
                                status, 
                                style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, color: status == 'APPROVED' ? Colors.green : Colors.red)
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String desc, IconData icon, Color bg, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(title, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: color[900]!)),
            const SizedBox(height: 2),
            Text(desc, textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 9, color: color[800]!.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManagementGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Kelola Akun Tersistem", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkGray)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.8,
            children: [
              _buildManageBtn("Blokir / Suspend", LucideIcons.ban, Colors.red[600]!),
              _buildManageBtn("Hapus User", LucideIcons.trash2, Colors.red[800]!),
              _buildManageBtn("Set Limit Saldo", LucideIcons.sliders, Colors.indigo),
              _buildManageBtn("Review KYC", LucideIcons.fileCheck, Colors.teal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManageBtn(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: darkGray)),
        ],
      ),
    );
  }
}
