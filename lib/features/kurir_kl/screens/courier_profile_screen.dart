import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/wallet_provider.dart';

class CourierProfileScreen extends ConsumerWidget {
  const CourierProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const Color textDark = Color(0xFF2D2A26);
    const Color textGrey = Color(0xFF78716C);
    
    final auth = ref.watch(authProvider);

    final Map<String, dynamic> t = {
      'id': {
        'active_vehicle': 'KENDARAAN AKTIF',
        'perf_title': 'PERFORMA MINGGU INI',
        'perf_completion': 'Penyelesaian',
        'perf_rating': 'Rating',
        'perf_average': 'Rata-rata',
        'settings': 'Pengaturan Akun',
        'security': 'Keamanan Server',
        'help': 'Pusat Bantuan',
        'about': 'Tentang Nyutji KL',
        'logout': 'Logout',
      }
    };

    final currentT = t['id'];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildVehicleCard(textDark, textGrey, currentT),
                const SizedBox(height: 24),
                _buildPerformanceSection(textDark, textGrey, currentT),
                const SizedBox(height: 24),
                _buildMenuSection(context, ref, auth, textDark, currentT),
                SizedBox(height: 40 + MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Color textDark, Color textGrey, Map<String, dynamic> currentT) {
    return Container(
      padding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(16)),
            child: Icon(LucideIcons.bike, color: Colors.blue[700], size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(currentT['active_vehicle'], style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: textGrey, letterSpacing: 1)),
                Text(
                  "Honda Beat (B 3821 NYC)", 
                  style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey[300]),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection(Color textDark, Color textGrey, Map<String, dynamic> currentT) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(currentT['perf_title'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: textDark, letterSpacing: 1)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _perfCounter("98%", currentT['perf_completion'], Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _perfCounter("4.9", currentT['perf_rating'], Colors.amber[700]!)),
            const SizedBox(width: 12),
            Expanded(child: _perfCounter("12min", currentT['perf_average'], Colors.blue)),
          ],
        ),
      ],
    );
  }

  Widget _perfCounter(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, WidgetRef ref, AuthProvider auth, Color textDark, Map<String, dynamic> currentT) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            _ExpandableSettingsMenu(currentT: currentT, auth: auth, textDark: textDark),
          const Divider(height: 1),
          _menuItem(LucideIcons.shield, currentT['security'], textDark),
          const Divider(height: 1),
          _menuItem(LucideIcons.headphones, currentT['help'], textDark),
          const Divider(height: 1),
          _menuItem(LucideIcons.info, currentT['about'], textDark),
          const Divider(height: 1),
          ListTile(
            onTap: () async {
              // 1. Mantra penghancur (Rule II.6) untuk memori cache transaksi.
              // Harus dieksekusi SEBELUM navigasi agar ref masih valid (mencegah StateError).
              ref.invalidate(orderProvider);
              ref.invalidate(walletProvider);
              
              // 2. Proses logout di auth (state direset eksplisit dengan delay 500ms internal
              //    agar mencegah flash glitch "Abang Kurir").
              await auth.logout();
              
              // 3. Navigasi kembali ke halaman login
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            leading: const Icon(LucideIcons.logOut, color: Colors.red, size: 18),
            title: Text(currentT['logout'], style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.red)),
            trailing: const Icon(LucideIcons.chevronRight, size: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, Color textDark) {
    return ListTile(
      leading: Icon(icon, color: textDark, size: 18),
      title: Text(label, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: textDark)),
      trailing: const Icon(LucideIcons.chevronRight, size: 14, color: Colors.grey),
    );
  }
}

class _ExpandableSettingsMenu extends StatefulWidget {
  final Map<String, dynamic> currentT;
  final AuthProvider auth;
  final Color textDark;

  const _ExpandableSettingsMenu({
    required this.currentT,
    required this.auth,
    required this.textDark,
  });

  @override
  State<_ExpandableSettingsMenu> createState() => _ExpandableSettingsMenuState();
}

class _ExpandableSettingsMenuState extends State<_ExpandableSettingsMenu> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.auth.user;
    final String identifier = user?['identifier'] ?? '-';
    // Gunakan fallback cerdas jika data dinamis belum tersedia (tanpa perlu re-login)
    final String rating = user?['rating']?.toString() ?? "4.9"; 
    final String level = user?['level'] ?? "Senior"; 
    
    String partner = user?['mitra_recommendation']?.toString() ?? "";
    if (partner.isEmpty && user?['mitra_ref_id'] != null) {
      final mitraRefId = user!['mitra_ref_id'];
      try {
        final foundMitra = widget.auth.mitras.firstWhere(
          (m) => m['identifier'] == mitraRefId, 
          orElse: () => null
        );
        if (foundMitra != null) {
          partner = foundMitra['name'] ?? mitraRefId;
        } else {
          partner = mitraRefId;
        }
      } catch (_) {
        partner = mitraRefId;
      }
    }
    if (partner.isEmpty) partner = "Belum Ada Mitra";
    
    return Column(
      children: [
        ListTile(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          leading: Icon(LucideIcons.settings, color: widget.textDark, size: 18),
          title: Text(widget.currentT['settings'], style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: widget.textDark)),
          trailing: Icon(
            _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
            size: 14,
            color: Colors.grey,
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isExpanded
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(left: 52, right: 20, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow("ID Kurir", identifier),
                      const SizedBox(height: 8),
                      _buildDetailRow("Rating", "$rating \u2605"),
                      const SizedBox(height: 8),
                      _buildDetailRow("Level", level),
                      const SizedBox(height: 8),
                      _buildDetailRow("Mitra Utama", partner),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        const Text(" : ", style: TextStyle(fontSize: 11, color: Colors.grey)),
        Expanded(
          flex: 6,
          child: Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: widget.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
