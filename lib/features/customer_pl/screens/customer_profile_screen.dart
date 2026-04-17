import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final Map<String, dynamic> t = {
      'id': {
        'title': 'Akun Saya',
        'tier': 'Member VIP',
        'address': 'Alamat Tersimpan',
        'favorit': 'Mitra Favorit',
        'settings': 'Pengaturan Akun',
        'notif': 'Notifikasi',
        'help': 'Pusat Bantuan',
        'logout': 'Keluar',
      },
      'en': {
        'title': 'My Account',
        'tier': 'VIP Member',
        'address': 'Saved Addresses',
        'favorit': 'Favorite Partners',
        'settings': 'Account Settings',
        'notif': 'Notifications',
        'help': 'Help Center',
        'logout': 'Log Out',
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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  CircleAvatar(radius: 28, backgroundColor: Colors.amber[100], child: const Icon(LucideIcons.user, size: 28, color: Colors.amber)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Ny. Rahmawati", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(4)), child: Text(currentT['tier'], style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber[900]))),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingsGroup([
              _settingRow(LucideIcons.mapPin, currentT['address']),
              _settingRow(LucideIcons.heart, currentT['favorit']),
            ]),
            const SizedBox(height: 12),
            _buildSettingsGroup([
              _settingRow(LucideIcons.settings, currentT['settings']),
              _settingRow(LucideIcons.bell, currentT['notif']),
              _settingRow(LucideIcons.headphones, currentT['help']),
            ]),
            const SizedBox(height: 12),
            _buildSettingsGroup([
              _settingRow(LucideIcons.logOut, currentT['logout'], isDanger: true, onTap: () async {
                await auth.logout();
                if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
              }),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      color: Colors.white,
      child: Column(
        children: children,
      ),
    );
  }

  Widget _settingRow(IconData icon, String title, {bool isDanger = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isDanger ? Colors.red : Colors.grey[700]),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: isDanger ? Colors.red : Colors.black87))),
            Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
