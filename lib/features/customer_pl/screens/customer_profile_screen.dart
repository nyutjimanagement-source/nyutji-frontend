import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/constants/api_constants.dart';


class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  
  // STATE UNTUK ALAMAT DINAMIS
  bool _isAddressExpanded = false;
  bool _isEditingAddress = false;
  late TextEditingController _addressDetailController;
  
  // FIX FLICKER: Gunakan timestamp tetap yang hanya berubah saat upload
  String _imageVersion = DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    _addressDetailController = TextEditingController();
  }

  @override
  void dispose() {
    _addressDetailController.dispose();
    super.dispose();
  }

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
                final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50, maxWidth: 800);
                if (photo != null) {
                  final success = await auth.updateProfilePhoto(photo);
                  if (success && context.mounted) {
                    setState(() => _imageVersion = DateTime.now().millisecondsSinceEpoch.toString());
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
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800);
                if (image != null) {
                  final success = await auth.updateProfilePhoto(image);
                  if (success && context.mounted) {
                    setState(() => _imageVersion = DateTime.now().millisecondsSinceEpoch.toString());
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
                        
                        // FIX URL & 404: Pastikan path lengkap dan versi stabil (anti-flicker)
                        String? finalUrl;
                        if (photoUrl != null && photoUrl.toString().isNotEmpty) {
                          String path = photoUrl.toString();
                          // Jika path tidak mengandung folder upload, tambahkan (untuk fix 404)
                          if (!path.startsWith('http') && !path.contains('uploads/')) {
                            path = "uploads/profiles/$path";
                          }
                          
                          finalUrl = path.startsWith('http') 
                            ? "$path?v=$_imageVersion"
                            : "${ApiConstants.rootUrl}/$path?v=$_imageVersion";
                        }

                        return CircleAvatar(
                          radius: 28, 
                          backgroundColor: Colors.amber[100], 
                          backgroundImage: kIsWeb 
                              ? (auth.temporaryWebBytes != null 
                                  ? MemoryImage(auth.temporaryWebBytes) as ImageProvider
                                  : (finalUrl != null)
                                      ? NetworkImage(finalUrl)
                                      : null)
                              : (localPhoto != null
                                  ? FileImage(File(localPhoto)) as ImageProvider
                                  : (finalUrl != null) 
                                      ? NetworkImage(finalUrl) 
                                      : null),
                          child: (localPhoto == null && auth.temporaryWebBytes == null && finalUrl == null) 
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
              Consumer<AuthProvider>(
                builder: (context, auth, _) => _buildExpandableAddressRow(currentT, auth),
              ),
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

  Widget _buildExpandableAddressRow(Map<String, dynamic> currentT, AuthProvider auth) {
    // FIX DISPLAY: Ambil data paling seger dari Provider
    final user = auth.user;
    final addressDetail = user?['address_detail']?.toString() ?? '';
    final district = user?['district_name']?.toString() ?? user?['owner_district_name']?.toString() ?? '-';
    final city = user?['city_name']?.toString() ?? user?['owner_city_name']?.toString() ?? '-';
    
    // Sinkronkan controller hanya jika TIDAK sedang mengetik
    if (!_isEditingAddress && _addressDetailController.text != addressDetail) {
      _addressDetailController.text = addressDetail;
    }

    return Column(
      children: [
        _settingRow(
          LucideIcons.mapPin, 
          currentT['address'], 
          onTap: () => setState(() => _isAddressExpanded = !_isAddressExpanded),
          trailing: Icon(
            _isAddressExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight, 
            size: 16, color: Colors.grey[400]
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isAddressExpanded 
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(56, 0, 20, 20),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[100]!))
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.home, size: 14, color: Color(0xFF1E5655)),
                        const SizedBox(width: 8),
                        Text("Rumah Sendiri", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E5655))),
                        const Spacer(),
                        if (!_isEditingAddress)
                          GestureDetector(
                            onTap: () => setState(() => _isEditingAddress = true),
                            child: const Icon(LucideIcons.edit3, size: 16, color: Colors.blueAccent),
                          )
                        else
                          GestureDetector(
                            onTap: () async {
                              final success = await auth.updateLocation({
                                'address': user?['address'],
                                'address_detail': _addressDetailController.text,
                                'district_name': district,
                                'city_name': city,
                                'lat': user?['lat'],
                                'lng': user?['lng'],
                              });
                              if (success && mounted) {
                                NyutjiNotif.showSuccess(context, "Alamat Rumah Telah Disimpan");
                                setState(() => _isEditingAddress = false);
                              }
                            },
                            child: Text("SAVE", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isEditingAddress)
                      TextField(
                        controller: _addressDetailController,
                        style: GoogleFonts.montserrat(fontSize: 12, color: Colors.black87),
                        maxLines: 2,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: "Masukkan detail alamat...",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                          contentPadding: const EdgeInsets.all(10),
                        ),
                      )
                    else
                      Text(addressDetail.isEmpty ? "Belum ada detail alamat" : addressDetail, style: GoogleFonts.montserrat(fontSize: 12, color: Colors.black87)),
                    
                    const SizedBox(height: 8),
                    Text("$district, $city", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[400], fontWeight: FontWeight.w500)),
                  ],
                ),
              )
            : const SizedBox.shrink(),
        ),
      ],
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

  Widget _settingRow(IconData icon, String title, {bool isDanger = false, VoidCallback? onTap, Widget? trailing}) {
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
            trailing ?? Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
