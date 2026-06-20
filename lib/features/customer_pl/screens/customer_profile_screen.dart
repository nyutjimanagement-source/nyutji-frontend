import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/nyutji_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/wallet_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/nyutji_location_picker.dart';
import '../../../core/widgets/nyutji_image_picker.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  bool _isAddressExpanded = false;
  bool _isSettingsExpanded = false;
  late TextEditingController _addressDetailController;
  String _imageVersion = "";

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
    final auth = ref.watch(authProvider);
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
              _settingRow(LucideIcons.heart, currentT['favorit'], onTap: () {
                NyutjiNotif.showInfo(context, "Layanan Mitra Favorit akan Segera Hadir");
              }),
            ]),
            _buildSettingsGroup([
              _buildExpandableSettingsRow(currentT, auth),
              _settingRow(LucideIcons.bell, currentT['notif'], onTap: () {
                NyutjiNotif.showInfo(context, "Layanan Notifikasi akan Segera Hadir");
              }),
              _settingRow(LucideIcons.headphones, currentT['help'], onTap: () {
                _showHelpPopup();
              }),
            ]),
            _buildSettingsGroup([
              _settingRow(LucideIcons.logOut, currentT['logout'], isDanger: true, onTap: () async {
                ref.invalidate(orderProvider);
                ref.invalidate(walletProvider);
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

  void _showHelpPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Butuh Bantuan Nyutji ?",
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF403600),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Tim Nyutji siap membantu kendala operasional, transaksi, atau aplikasi Anda. Hubungi kami melalui:",
                    style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[800], height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Email: support@nyutji.com",
                    style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Untuk pertanyaan umum, kendala teknis aplikasi, kemitraan, atau pengajuan keluhan tertulis",
                    style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600], height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "WhatsApp Darurat: 0812-3456-7890",
                    style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green[700]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Butuh bantuan cepat terkait pakaian tertukar, pembatalan darurat, atau konfirmasi antar-jemput kritis",
                    style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600], height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Aktif setiap hari pkl 08.00 - 22.00 WIB. Mohon siapkan Nomor Nota Anda saat menghubungi kami.",
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF403600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text("Tutup", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
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
      final String versionQuery = _imageVersion.isNotEmpty ? "?v=$_imageVersion" : "";
      finalUrl = path.startsWith('http') ? "$path$versionQuery" : "${ApiConstants.rootUrl}/$path$versionQuery";
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
                          : (finalUrl != null) ? DecorationImage(image: CachedNetworkImageProvider(finalUrl), fit: BoxFit.cover) : null)
                      : (localPhoto != null
                          ? DecorationImage(image: FileImage(File(localPhoto)), fit: BoxFit.cover)
                          : (finalUrl != null) ? DecorationImage(image: CachedNetworkImageProvider(finalUrl), fit: BoxFit.cover) : null),
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
                   auth.isLoading 
                    ? const ShimmerLoading(height: 24, width: 150, borderRadius: 4)
                    : Text(
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
                        child: auth.isLoading
                        ? const ShimmerLoading(height: 14, width: 120, borderRadius: 4)
                        : Text(
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text("Edit", style: NyutjiTheme.detail(Colors.blueAccent).copyWith(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    auth.isLoading
                    ? const ShimmerLoading(height: 18, width: 250, borderRadius: 4)
                    : Text(mainAddress, style: NyutjiTheme.body(NyutjiTheme.darkText).copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                    if (addressDetail.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      auth.isLoading
                      ? const ShimmerLoading(height: 14, width: 200, borderRadius: 4)
                      : Text(addressDetail, style: NyutjiTheme.detail(Colors.grey[600]!)),
                    ],
                    const SizedBox(height: 8),
                    auth.isLoading
                    ? const ShimmerLoading(height: 14, width: 150, borderRadius: 4)
                    : Text("$district, $city", style: NyutjiTheme.detail(Colors.grey[400]!).copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                         NyutjiNotif.showInfo(context, "Fitur Tambah Alamat akan segera hadir");
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text("+ Tambah Alamat", style: NyutjiTheme.body(Colors.grey[600]!).copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildExpandableSettingsRow(Map<String, dynamic> currentT, AuthProvider auth) {
    final user = auth.user;
    final name = user?['name']?.toString() ?? '-';
    final phone = user?['phone']?.toString() ?? user?['no_hp']?.toString() ?? '-';
    final email = user?['email']?.toString() ?? '-';
    final tier = currentT['tier'] ?? 'VIP Member';

    return Column(
      children: [
        _settingRow(
          LucideIcons.settings, 
          currentT['settings'], 
          onTap: () => setState(() => _isSettingsExpanded = !_isSettingsExpanded),
          trailing: Icon(
            _isSettingsExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight, 
            size: 16, color: Colors.grey[400]
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isSettingsExpanded 
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(56, 0, 20, 20),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReadOnlyTextField("Nama", name),
                    _buildReadOnlyTextField("No Handphone", phone),
                    _buildReadOnlyTextField("Email", email),
                    _buildReadOnlyTextField("Membership", tier, suffix: Tooltip(
                      message: "Kategori Membership terkait jumlah walletNyutji tersimpan dan Layanan Prima Nyutji",
                      triggerMode: TooltipTriggerMode.tap,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: NyutjiTheme.detail(Colors.white).copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                      showDuration: const Duration(seconds: 4),
                      child: const Icon(LucideIcons.helpCircle, size: 16, color: Colors.grey),
                    )),
                  ],
                ),
              )
            : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildReadOnlyTextField(String label, String value, {Widget? suffix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: NyutjiTheme.detail(Colors.grey[600]!).copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(value, style: NyutjiTheme.body(NyutjiTheme.darkText).copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
                ),
                if (suffix != null) suffix,
              ],
            ),
          ),
        ],
      ),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
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
