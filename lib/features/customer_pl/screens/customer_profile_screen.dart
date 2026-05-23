import 'package:flutter/material.dart';
import '../../../core/theme/nyutji_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/nyutji_location_picker.dart';
import '../../../core/widgets/nyutji_image_picker.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  bool _isAddressExpanded = false;
  late TextEditingController _addressDetailController;
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
    NyutjiImagePicker.show(
      context,
      title: "Pilih Foto Profil",
      primaryColor: const Color(0xFF403600),
      currentImageUrl: auth.user?['profile_photo'],
      onImagePicked: (XFile file) async {
        final success = await auth.updateProfilePhoto(file);
        if (success && mounted) {
          setState(() => _imageVersion = DateTime.now().millisecondsSinceEpoch.toString());
          NyutjiNotif.showSuccess(context, "Foto Profil Diperbarui");
        }
      },
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
      backgroundColor: const Color(0xFFFFF9ED),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildPremiumHeader(currentT, auth),
            const SizedBox(height: 8),
            _buildSettingsGroup([
              _buildExpandableAddressRow(currentT, auth),
              _settingRow(LucideIcons.heart, currentT['favorit']),
            ]),
            _buildSettingsGroup([
              _settingRow(LucideIcons.settings, currentT['settings']),
              _settingRow(LucideIcons.bell, currentT['notif']),
              _settingRow(LucideIcons.headphones, currentT['help']),
            ]),
            _buildSettingsGroup([
              _settingRow(LucideIcons.logOut, currentT['logout'], isDanger: true, onTap: () async {
                await auth.logout();
                if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
              }),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(Map<String, dynamic> currentT, AuthProvider auth) {
    final photoUrl = auth.user?['profile_photo'];
    final localPhoto = auth.temporaryLocalPhoto;
    final district = auth.user?['owner_district_name'] ?? auth.user?['district_name'] ?? 'Pamulang';
    final city = auth.user?['owner_city_name'] ?? auth.user?['city_name'] ?? 'Tangerang Selatan';

    String? finalUrl;
    if (photoUrl != null && photoUrl.toString().isNotEmpty) {
      String path = photoUrl.toString();
      if (!path.startsWith('http') && !path.contains('uploads/')) {
        path = "uploads/profiles/$path";
      }
      finalUrl = path.startsWith('http') ? "$path?v=$_imageVersion" : "${ApiConstants.rootUrl}/$path?v=$_imageVersion";
    }

    return ClipPath(
      clipper: ProfileHeaderClipper(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 80),
        decoration: const BoxDecoration(color: Color(0xFF403600)),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _pickImage(auth),
              child: Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                  color: Colors.white10,
                  image: kIsWeb
                      ? (auth.temporaryWebBytes != null
                          ? DecorationImage(image: MemoryImage(auth.temporaryWebBytes!), fit: BoxFit.cover)
                          : (finalUrl != null) ? DecorationImage(image: NetworkImage(finalUrl), fit: BoxFit.cover) : null)
                      : (localPhoto != null
                          ? DecorationImage(image: FileImage(File(localPhoto)), fit: BoxFit.cover)
                          : (finalUrl != null) ? DecorationImage(image: NetworkImage(finalUrl), fit: BoxFit.cover) : null),
                ),
                child: (localPhoto == null && auth.temporaryWebBytes == null && finalUrl == null)
                    ? const Icon(LucideIcons.user, color: Colors.white70, size: 35)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    auth.user?['name'] ?? "Pelanggan",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NyutjiTheme.h2(Colors.white).copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, size: 12, color: Colors.white70),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "$district, $city",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: NyutjiTheme.detail(Colors.white70).copyWith(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFDAC66F), borderRadius: BorderRadius.circular(4)),
                    child: Text(currentT['tier'], style: const TextStyle(color: Color(0xFF403600), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableAddressRow(Map<String, dynamic> currentT, AuthProvider auth) {
    final user = auth.user;
    final mainAddress = user?['address']?.toString() ?? 'Pilih Lokasi Rumah';
    final addressDetail = user?['address_detail']?.toString() ?? '';
    final district = user?['district_name']?.toString() ?? user?['owner_district_name']?.toString() ?? '-';
    final city = user?['city_name']?.toString() ?? user?['owner_city_name']?.toString() ?? '-';
    
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
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.home, size: 14, color: Color(0xFF403600)),
                        const SizedBox(width: 8),
                        Text("Rumah Sendiri", style: NyutjiTheme.h3(const Color(0xFF403600)).copyWith(fontSize: 12)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () async {
                            final result = await showModalBottomSheet<NyutjiLocationResult>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const NyutjiLocationPicker(),
                            );
                            if (result != null && mounted) {
                              final success = await auth.updateLocation({
                                'address': result.address,
                                'district_name': result.subdistrict,
                                'city_name': result.city,
                                'lat': result.lat,
                                'lng': result.lng,
                                'address_detail': addressDetail,
                              });
                              if (success && mounted) {
                                NyutjiNotif.showSuccess(context, "Alamat Rumah Telah Disimpan");
                              }
                            }
                          },
                          child: const Icon(LucideIcons.edit3, size: 16, color: Colors.blueAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(mainAddress, style: NyutjiTheme.body(NyutjiTheme.darkText).copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                    if (addressDetail.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(addressDetail, style: NyutjiTheme.detail(Colors.grey[600]!)),
                    ],
                    const SizedBox(height: 8),
                    Text("$district, $city", style: NyutjiTheme.detail(Colors.grey[400]!).copyWith(fontWeight: FontWeight.w500)),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3DCCF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(children: children),
      ),
    );
  }

  Widget _settingRow(IconData icon, String title, {bool isDanger = false, VoidCallback? onTap, Widget? trailing}) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[50]!, width: 1))
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDanger ? Colors.red.withValues(alpha: 0.05) : const Color(0xFF403600).withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: isDanger ? Colors.red : const Color(0xFF403600)),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: NyutjiTheme.body(isDanger ? Colors.red : NyutjiTheme.darkText).copyWith(fontSize: 13, fontWeight: FontWeight.w700))),
            trailing ?? Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}

class ProfileHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    path.quadraticBezierTo(size.width / 2, size.height - 40, size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
