import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class CourierProfileScreen extends StatelessWidget {
  const CourierProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF2D2A26);
    const Color textGrey = Color(0xFF78716C);
    
    final auth = Provider.of<AuthProvider>(context);

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
        'logout': 'Logout dari Server',
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
                _buildMenuSection(context, auth, textDark, currentT),
                const SizedBox(height: 40),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
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
                Text("Honda Beat (B 3821 NYC)", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: textDark)),
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
        border: Border.all(color: Colors.black.withOpacity(0.05)),
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

  Widget _buildMenuSection(BuildContext context, AuthProvider auth, Color textDark, Map<String, dynamic> currentT) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _menuItem(LucideIcons.settings, currentT['settings'], textDark),
          const Divider(height: 1),
          _menuItem(LucideIcons.shield, currentT['security'], textDark),
          const Divider(height: 1),
          _menuItem(LucideIcons.headphones, currentT['help'], textDark),
          const Divider(height: 1),
          _menuItem(LucideIcons.info, currentT['about'], textDark),
          const Divider(height: 1),
          ListTile(
            onTap: () async {
              await auth.logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
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
