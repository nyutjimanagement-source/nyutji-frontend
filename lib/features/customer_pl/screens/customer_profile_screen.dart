import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/widgets/nyutji_address_sheet.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(AuthProvider auth) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Pilih Foto Profil", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(LucideIcons.camera, color: Color(0xFF1E5655)),
              title: Text("Ambil Foto Kamera", style: GoogleFonts.montserrat()),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
                if (photo != null) {
                  final success = await auth.updateProfilePhoto(photo.path);
                  if (success && mounted) {
                    NyutjiNotif.showSuccess(context, "Foto Profile Berhasil Diganti");
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.image, color: Color(0xFF1E5655)),
              title: Text("Pilih dari Galeri", style: GoogleFonts.montserrat()),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                if (image != null) {
                  final success = await auth.updateProfilePhoto(image.path);
                  if (success && mounted) {
                    NyutjiNotif.showSuccess(context, "Foto Profile Berhasil Diganti");
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

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
                  GestureDetector(
                    onTap: () => _pickImage(auth),
                    child: Builder(
                      builder: (context) {
                        final photoUrl = auth.user?['profile_photo'];
                        final localPhoto = auth.temporaryLocalPhoto;
                        return CircleAvatar(
                          radius: 28, 
                          backgroundColor: Colors.amber[100], 
                          backgroundImage: localPhoto != null
                              ? FileImage(File(localPhoto)) as ImageProvider
                              : (photoUrl != null && photoUrl.toString().isNotEmpty) 
                                  ? NetworkImage("http://nyutji.com/$photoUrl?v=${DateTime.now().millisecondsSinceEpoch}") 
                                  : null,
                          child: (localPhoto == null && (photoUrl == null || photoUrl.toString().isEmpty)) 
                              ? const Icon(LucideIcons.user, size: 28, color: Colors.amber) 
                              : null
                        );
                      }
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(auth.user?['name'] ?? "Pelanggan", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis, maxLines: 2),
                        const SizedBox(height: 2),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(4)), child: Text(currentT['tier'], style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber[900]))),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingsGroup([
              _settingRow(LucideIcons.mapPin, currentT['address'], onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const NyutjiAddressSheet(),
                );
              }),
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
