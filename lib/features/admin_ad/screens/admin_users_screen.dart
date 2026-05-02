// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../core/widgets/nyutji_location_picker.dart';
import '../../../core/utils/nyutji_distance.dart';
import 'admin_approval.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  static const Color primaryTeal = Color(0xFF1E5655);
  static const Color bgColor = Color(0xFFF3F4F6);
  static const Color darkGray = Color(0xFF111827);

  bool _isPricingExpanded = false;
  bool _isEditingPricing = false;
  bool _isLoadingPricing = false;
  final List<Map<String, dynamic>> _courierPricings = [
    {
      'id': 'dummy1',
      'sessionName': 'Pagi',
      'basePrice': 5000.0,
      'multiplier': 1.0,
      'dayType': 'WEEKDAY',
      'isActive': true,
    },
    {
      'id': 'dummy2',
      'sessionName': 'Malam',
      'basePrice': 7500.0,
      'multiplier': 1.2,
      'dayType': 'WEEKDAY',
      'isActive': true,
    }
  ];
  
  // NRCF Calculator State
  String _pickupAddress = "";
  double _pickupLat = 0.0;
  double _pickupLng = 0.0;
  String _mitraAddress = "";
  double _mitraLat = 0.0;
  double _mitraLng = 0.0;
  double _rawDistance = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchCourierPricing();
  }

  Future<void> _fetchCourierPricing() async {
    // Mode Dummy: Tidak memanggil server
    setState(() {
      _isLoadingPricing = false;
    });
  }

  Future<void> _saveCourierPricing() async {
    setState(() => _isLoadingPricing = true);
    // Mode Dummy: Hanya simulasi simpan
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isEditingPricing = false;
      _isLoadingPricing = false;
    });
    NyutjiNotif.showSuccess(context, "Harga kurir (Dummy) berhasil disimpan");
  }

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
            _buildCourierPricingCard(),
            const SizedBox(height: 24),
            _buildNRCFSimulator(),
            const SizedBox(height: 24),
            _buildUserManagementGrid(context),
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
        gradient: LinearGradient(
          colors: [darkGray, Color(0xFF1F2937)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20, top: -20,
            child: Icon(LucideIcons.users, size: 140, color: Colors.white.withOpacity(0.05)),
          ),
          Column(
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
              Expanded(child: _buildStatCard("Leveling ML", "Atur KPI & Syarat Naik Kelas", LucideIcons.barChart, Colors.orange[50]!, Colors.orange)),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showUserListSheet(context),
                  child: _buildStatCard("Kategori ML", "Kecil, Menengah, Enterprise", LucideIcons.tags, Colors.blue[50]!, Colors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard("Top ML Rate", "4.9 / 5.0", LucideIcons.star, Colors.amber[50]!, Colors.amber)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard("Top KL Rate", "4.8 / 5.0", LucideIcons.bike, Colors.blue[50]!, Colors.blue)),
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

  void _showDeleteUserSheet(BuildContext context) {
    final auth = context.read<AuthProvider>();
    auth.fetchAllUsers();
    final Set<String> selectedIdentifiers = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sbContext, setModalState) {
          return Container(
            height: MediaQuery.of(sbContext).size.height * 0.75,
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
                      const Icon(LucideIcons.trash2, color: Colors.red),
                      const SizedBox(width: 12),
                      Text("Hapus User", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: darkGray)),
                      const Spacer(),
                      if (selectedIdentifiers.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            final usersToDelete = auth.allUsers
                                .where((u) {
                                  final ident = u['identifier']?.toString() ?? '';
                                  return selectedIdentifiers.contains(ident);
                                })
                                .map((u) => u['name']?.toString() ?? 'No Name')
                                .toList();
                            
                            _showConfirmDeleteDialog(sbContext, usersToDelete, () async {
                              final nav = Navigator.of(sbContext);
                              final success = await auth.bulkDeleteUsers(selectedIdentifiers.toList());
                              if (success) {
                                nav.pop(); // Close sheet
                                try {
                                  NyutjiNotif.showSuccess(sbContext, "Berhasil menghapus ${selectedIdentifiers.length} user");
                                } catch (e) {
                                  debugPrint("Notif Error: $e");
                                }
                              }
                            });
                          },
                          child: Text("Hapus", style: GoogleFonts.montserrat(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Consumer<AuthProvider>(
                    builder: (cContext, authData, _) {
                      if (authData.allUsers.isEmpty && authData.isLoading) {
                        return const Center(child: CircularProgressIndicator(color: primaryTeal));
                      }
                      
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: authData.allUsers.length,
                        separatorBuilder: (lvContext, index) => Divider(color: Colors.grey[100]),
                        itemBuilder: (itemContext, index) {
                          final u = authData.allUsers[index];
                          final String identifier = u['identifier']?.toString() ?? '-';
                          final name = u['name'] ?? 'No Name';
                          final role = u['role'] ?? '-';
                          
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(name, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: darkGray)),
                            subtitle: Text("$role | $identifier", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[600])),
                            secondary: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(color: primaryTeal.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Center(child: Icon(LucideIcons.user, size: 16, color: primaryTeal)),
                            ),
                            value: selectedIdentifiers.contains(identifier),
                            activeColor: primaryTeal,
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  selectedIdentifiers.add(identifier);
                                } else {
                                  selectedIdentifiers.remove(identifier);
                                }
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showConfirmDeleteDialog(BuildContext context, List<String> names, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(LucideIcons.alertCircle, color: Colors.red, size: 20),
            const SizedBox(width: 12),
            Text("Konfirmasi Hapus", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Apakah Anda yakin ingin menghapus user berikut?", style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: names.length,
                separatorBuilder: (context, index) => const Divider(height: 8, color: Colors.transparent),
                itemBuilder: (context, index) => Text("• ${names[index]}", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red[800])),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("Batal", style: GoogleFonts.montserrat(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              onConfirm();
            },
            child: Text("OK, Hapus", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String desc, IconData icon, Color bg, MaterialColor color) {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(title, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: color[900]!)),
            const SizedBox(height: 2),
            Text(desc, textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 9, color: color[800]!.withOpacity(0.8))),
          ],
        ),
      );
  }

  Widget _buildUserManagementGrid(BuildContext context) {
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
              GestureDetector(
                onTap: () => _showDeleteUserSheet(context),
                child: _buildManageBtn("Hapus User", LucideIcons.trash2, Colors.red[800]!)
              ),
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

  Widget _buildCourierPricingCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _isPricingExpanded = !_isPricingExpanded),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.orange[50], shape: BoxShape.circle),
                      child: const Icon(LucideIcons.truck, color: Colors.orange, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Harga per Km Kurir", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkGray)),
                          Text("Atur tarif dinamis sistem", style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                    if (_isEditingPricing)
                      IconButton(
                        icon: const Icon(LucideIcons.save, color: Colors.green, size: 20),
                        onPressed: _saveCourierPricing,
                      )
                    else
                      IconButton(
                        icon: const Icon(LucideIcons.edit, color: primaryTeal, size: 20),
                        onPressed: () => setState(() => _isEditingPricing = true),
                      ),
                    Icon(_isPricingExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isPricingExpanded
                  ? Column(
                      children: [
                        const Divider(height: 1),
                        if (_isLoadingPricing)
                          const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: primaryTeal))
                        else if (_courierPricings.isEmpty)
                          _buildEmptyPricingState()
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _courierPricings.length,
                            itemBuilder: (context, index) {
                              return _buildPricingRow(_courierPricings[index], index);
                            },
                          ),
                        _buildAddPricingBtn(),
                        const SizedBox(height: 16),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPricingState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text("Belum ada aturan harga.", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildAddPricingBtn() {
    if (!_isEditingPricing) return const SizedBox.shrink();
    return InkWell(
      onTap: () {
        setState(() {
          _courierPricings.add({
            'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
            'sessionName': 'Pagi',
            'basePrice': 5000,
            'multiplier': 1.0,
            'dayType': 'WEEKDAY',
            'isActive': true,
          });
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(color: primaryTeal.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: primaryTeal.withOpacity(0.1))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.plusCircle, size: 16, color: primaryTeal),
            const SizedBox(width: 8),
            Text("Tambah Aturan Harga", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTeal)),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingRow(Map<String, dynamic> item, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[50]!))),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _isEditingPricing
                ? DropdownButton<String>(
                    value: item['sessionName'],
                    isDense: true,
                    style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: darkGray),
                    underline: const SizedBox(),
                    items: ['Pagi', 'Siang', 'Sore', 'Malam'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => item['sessionName'] = val),
                  )
                : Text(item['sessionName'], style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: darkGray)),
          ),
          Expanded(
            flex: 2,
            child: _isEditingPricing
                ? TextFormField(
                    initialValue: item['basePrice'].toString(),
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTeal),
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none, prefixText: 'Rp '),
                    onChanged: (val) => item['basePrice'] = double.tryParse(val) ?? 0,
                  )
                : Text("Rp ${item['basePrice']}", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTeal)),
          ),
          Expanded(
            flex: 2,
            child: _isEditingPricing
                ? DropdownButton<String>(
                    value: item['dayType'],
                    isDense: true,
                    style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                    underline: const SizedBox(),
                    items: ['WEEKDAY', 'WEEKEND', 'HOLIDAY'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => item['dayType'] = val),
                  )
                : Text(item['dayType'], style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[600])),
          ),
          if (_isEditingPricing)
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 16),
              onPressed: () {
                setState(() {
                  _courierPricings.removeAt(index);
                });
              },
            )
        ],
      ),
    );
  }

  // --- NRCF SIMULATOR CARD ---
  Widget _buildNRCFSimulator() {
    final roadDist = NyutjiDistance.calculateRoadDistance(_rawDistance);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.gauge, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Text("Simulator Jarak & NRCF", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkGray)),
              ],
            ),
            const SizedBox(height: 16),
            _buildMiniLocationSelector("Asal (PL)", _pickupAddress, () async {
              final result = await showModalBottomSheet<NyutjiLocationResult>(
                context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                builder: (context) => const NyutjiLocationPicker(),
              );
              if (result != null) {
                setState(() {
                  _pickupAddress = result.address;
                  _pickupLat = result.lat;
                  _pickupLng = result.lng;
                  _rawDistance = NyutjiDistance.calculateDistance(_pickupLat, _pickupLng, _mitraLat, _mitraLng);
                });
              }
            }),
            const SizedBox(height: 8),
            _buildMiniLocationSelector("Tujuan (ML)", _mitraAddress, () async {
              final result = await showModalBottomSheet<NyutjiLocationResult>(
                context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                builder: (context) => const NyutjiLocationPicker(),
              );
              if (result != null) {
                setState(() {
                  _mitraAddress = result.address;
                  _mitraLat = result.lat;
                  _mitraLng = result.lng;
                  _rawDistance = NyutjiDistance.calculateDistance(_pickupLat, _pickupLng, _mitraLat, _mitraLng);
                });
              }
            }),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: primaryTeal.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ESTIMASI NRCF", style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: primaryTeal, letterSpacing: 1)),
                      Text(NyutjiDistance.formatDistance(roadDist), style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: primaryTeal)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("GARIS LURUS", style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1)),
                      Text(NyutjiDistance.formatDistance(_rawDistance), style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMiniLocationSelector(String label, String address, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Text("$label: ", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            Expanded(child: Text(address.isNotEmpty ? address : "Pilih Lokasi...", style: GoogleFonts.montserrat(fontSize: 11, color: address.isNotEmpty ? darkGray : Colors.grey[400]), overflow: TextOverflow.ellipsis)),
            const Icon(LucideIcons.chevronRight, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
