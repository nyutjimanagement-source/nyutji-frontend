import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/widgets/nyutji_location_picker.dart';
import '../../../core/constants/api_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/widgets/nyutji_image_picker.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'mitra_keamanan_pin.dart';

class MitraProfileScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? currentT;
  const MitraProfileScreen({super.key, this.currentT});

  @override ConsumerState<MitraProfileScreen> createState() => _MitraProfileScreenState();
}

class _MitraProfileScreenState extends ConsumerState<MitraProfileScreen> {
  static const primaryTeal = Color(0xFF1E5655); 
  static const darkText = Color(0xFF111827);
  static const textGrey = Color(0xFF6B7280);

  bool _isCourierMenuExpanded = false;
  bool _isAddressExpanded = false;
  bool _isAccountExpanded = false;

  final TextEditingController _fullAddressController = TextEditingController();
  String _selectedDistrict = "";
  String _selectedCity = "";
  double _selectedLat = 0.0;
  double _selectedLng = 0.0;
  bool _isUpdatingLocation = false;
  bool _hasUnsavedLocationChanges = false;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _fbController = TextEditingController();
  final TextEditingController _igController = TextEditingController();
  
  bool _isUpdatingAccount = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (auth.user != null && mounted) {
        setState(() {
          _fullAddressController.text = auth.user!['address'] ?? '';
          _selectedDistrict = auth.user!['owner_district_name'] ?? auth.user!['district_name'] ?? '';
          _selectedCity = auth.user!['owner_city_name'] ?? auth.user!['city_name'] ?? '';
          _selectedLat = double.tryParse(auth.user!['lat']?.toString() ?? '0.0') ?? 0.0;
          _selectedLng = double.tryParse(auth.user!['lng']?.toString() ?? '0.0') ?? 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _fullAddressController.dispose();
    _phoneController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _accountNameController.dispose();
    _fbController.dispose();
    _igController.dispose();
    super.dispose();
  }

  void _showBeautifulNotif(String message, bool success) {
    if (success) {
      NyutjiNotif.showSuccess(context, message);
    } else {
      NyutjiNotif.showError(context, message);
    }
  }

  void _pickImage(AuthProvider auth) {
    NyutjiImagePicker.show(
      context,
      title: "Ganti Foto Profil (Mitra)",
      onImagePicked: (fileSource) async {
        final success = await auth.updateProfilePhoto(fileSource);
        if (success && mounted) {
          _showBeautifulNotif("Foto profil berhasil diperbarui!", true);
        } else if (mounted) {
          _showBeautifulNotif("Gagal upload foto. Coba lagi.", false);
        }
      },
    );
  }

  Widget _buildProfileImage(AuthProvider auth, dynamic photoUrl, String? localPhoto) {
    if (localPhoto == null && auth.temporaryWebBytes == null && (photoUrl == null || photoUrl.toString().isEmpty)) {
      return const Icon(LucideIcons.store, color: Colors.white, size: 20);
    }
    
    if (kIsWeb) {
      if (auth.temporaryWebBytes != null) {
        return Image.memory(auth.temporaryWebBytes!, fit: BoxFit.cover, gaplessPlayback: true);
      }
    } else {
      if (localPhoto != null) {
        return Image.file(File(localPhoto), fit: BoxFit.cover, gaplessPlayback: true);
      }
    }
    
    final url = photoUrl.toString().startsWith('http') 
        ? photoUrl.toString()
        : "${ApiConstants.rootUrl}/$photoUrl";
        
    return Image.network(
      url, 
      fit: BoxFit.cover, 
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const Icon(LucideIcons.store, color: Colors.white, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Consumer(
              builder: (context, ref, _) {
final auth = ref.watch(authProvider);
                final photoUrl = auth.user?['profile_photo'];
                final localPhoto = auth.temporaryLocalPhoto;
                final district = auth.user?['owner_district_name'] ?? auth.user?['district_name'] ?? "Kecamatan";
                final city = auth.user?['owner_city_name'] ?? auth.user?['city_name'] ?? "Kota/Kabupaten";
                
                return Row(
                  children: [
                    GestureDetector(
                      onTap: () => _pickImage(auth),
                      child: Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: primaryTeal.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: _buildProfileImage(auth, photoUrl, localPhoto),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(auth.user?['name'] ?? "Berkah Laundry", style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: darkText)),
                          Text("ID: ${auth.user?['identifier'] ?? '-'}", style: GoogleFonts.montserrat(fontSize: 13, color: textGrey, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text("$district - $city", style: GoogleFonts.montserrat(fontSize: 12, color: primaryTeal, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  ],
                );
              }
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Column(
              children: [
                _buildExpandableAddressMenu(auth),
                const Divider(height: 1),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const MitraKeamananPinScreen(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.easeOutCubic;
                          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                          return SlideTransition(position: animation.drive(tween), child: child);
                        },
                      ),
                    );
                  },
                  child: _buildMenuItem(LucideIcons.shieldAlert, "Keamanan PIN", false),
                ),
                const Divider(height: 1),
                _buildExpandableCourierMenu(),
                const Divider(height: 1),
                _buildExpandableAccountMenu(auth),
                const Divider(height: 1),
                Consumer(
                  builder: (context, ref, _) {
final auth = ref.watch(authProvider);
return GestureDetector(
                    onTap: () async {
                      try {
                        await auth.logout();
                        if (!context.mounted) return;
                        Navigator.pushReplacementNamed(context, '/login');
                      } catch (e) {
                        if (!context.mounted) return;
                      }
                    },
                    child: _buildMenuItem(LucideIcons.logOut, widget.currentT?['logout'] ?? 'Keluar Akun', true),
                  );
})
              ],
            ),
            ), // Closing Material
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildExpandableAddressMenu(AuthProvider auth) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isAddressExpanded = !_isAddressExpanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(LucideIcons.mapPin, size: 20, color: darkText),
                const SizedBox(width: 12),
                Text("Lokasi Operasional Laundry", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: darkText)),
                const Spacer(),
                Icon(_isAddressExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isAddressExpanded
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Alamat Lengkap", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: textGrey, letterSpacing: 0.5)),
                          InkWell(
                            onTap: () => _showLocationPicker(auth),
                            child: Text("Ubah Alamat ?", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      auth.isLoading 
                          ? const ShimmerLoading(height: 60, borderRadius: 12)
                          : TextField(
                              controller: _fullAddressController,
                              onChanged: (_) {
                                if (!_hasUnsavedLocationChanges) setState(() => _hasUnsavedLocationChanges = true);
                              },
                              maxLines: 2,
                              style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: "Masukkan Alamat Lengkap (Jl, No, Gang, dsb)",
                                hintStyle: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[400]),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryTeal)),
                              ),
                            ),
                      const SizedBox(height: 16),
                      Text("Kecamatan dan Kab/Kota", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: textGrey, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      auth.isLoading 
                          ? const ShimmerLoading(height: 50, borderRadius: 12)
                          : TextField(
                              controller: TextEditingController(text: _selectedDistrict.isEmpty ? "Belum Set Lokasi" : "$_selectedDistrict, $_selectedCity"),
                              readOnly: true,
                              style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                              ),
                            ),
                      const SizedBox(height: 16),
                      Text("Latitude / Longitude", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: textGrey, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      auth.isLoading 
                          ? const ShimmerLoading(height: 50, borderRadius: 12)
                          : TextField(
                              controller: TextEditingController(text: _selectedLat == 0.0 ? "Belum Set Lokasi" : "$_selectedLat, $_selectedLng"),
                              readOnly: true,
                              style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                              ),
                            ),
                      const SizedBox(height: 20),
                      if (_hasUnsavedLocationChanges)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isUpdatingLocation ? null : () => _handleUpdateLocation(auth),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryTeal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                              shadowColor: primaryTeal.withValues(alpha: 0.3),
                            ),
                            child: _isUpdatingLocation 
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text("Save Update", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
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

  Widget _buildExpandableCourierMenu() {
    return Consumer(
      builder: (context, ref, _) {
final auth = ref.watch(authProvider);
        final pendingUsers = auth.pendingApprovals;
        final activeCouriers = List.from(auth.couriers);
        activeCouriers.sort((a, b) => (a['name']?.toString() ?? '').compareTo(b['name']?.toString() ?? ''));

        return Column(
          children: [
            InkWell(
              onTap: () => setState(() => _isCourierMenuExpanded = !_isCourierMenuExpanded),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(LucideIcons.users, size: 18, color: darkText),
                    const SizedBox(width: 12),
                    Text("Kelola Kurir Laundry", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: darkText)),
                    if (pendingUsers.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFC3312E), borderRadius: BorderRadius.circular(10)),
                        child: Text(pendingUsers.length.toString(), style: GoogleFonts.montserrat(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                    const Spacer(),
                    Icon(_isCourierMenuExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 16, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isCourierMenuExpanded
                  ? Container(
                      color: Colors.grey[50],
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (pendingUsers.isNotEmpty) ...[
                            Text("Antrean Pendaftaran (${pendingUsers.length})", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: primaryTeal)),
                            const SizedBox(height: 8),
                            ...pendingUsers.map((u) => _buildCompactPendingCard(u, auth)),
                            const SizedBox(height: 12),
                          ],
                          Text("Daftar Anggota Aktif (${activeCouriers.length})", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: darkText)),
                          const SizedBox(height: 8),
                          if (activeCouriers.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text("Belum ada anggota kurir", style: GoogleFonts.montserrat(fontSize: 11, color: textGrey, fontStyle: FontStyle.italic)),
                            )
                          else
                            ...activeCouriers.map((u) => _buildCompactActiveCard(u)),
                          const SizedBox(height: 8),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            )
          ],
        );
      }
    );
  }

  Widget _buildExpandableAccountMenu(AuthProvider auth) {
    final hasBank = (auth.user?['bank_name'] != null && auth.user!['bank_name'].toString().isNotEmpty) && 
                    (auth.user?['bank_account'] != null && auth.user!['bank_account'].toString().isNotEmpty) && 
                    (auth.user?['account_name'] != null && auth.user!['account_name'].toString().isNotEmpty);
    
    final hasSocial = (auth.user?['facebook'] != null && auth.user!['facebook'].toString().isNotEmpty) && 
                      (auth.user?['instagram'] != null && auth.user!['instagram'].toString().isNotEmpty);

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isAccountExpanded = !_isAccountExpanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(LucideIcons.settings, size: 18, color: darkText),
                const SizedBox(width: 12),
                Text("Pengaturan Akun", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: darkText)),
                const Spacer(),
                Icon(_isAccountExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isAccountExpanded
              ? Container(
                  color: Colors.grey[50],
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const SizedBox(height: 12),
                      
                      // AKUN LAMA
                      Text("Akun Lama", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: darkText)),
                      const SizedBox(height: 12),
                      _buildReadOnlyField("Nomor Handphone Lama", auth.user?['phone_number'] ?? '-'),
                      const SizedBox(height: 12),
                      _buildReadOnlyField("Kata Sandi Lama", "********"),
                      const SizedBox(height: 12),
                      _buildReadOnlyField("Email", auth.user?['email'] ?? '-'),
                      
                      if (hasBank) ...[
                        const SizedBox(height: 12),
                        _buildReadOnlyField("Informasi Bank", "${auth.user!['bank_name']} - ${auth.user!['bank_account']}\na.n ${auth.user!['account_name']}"),
                      ],
                      if (hasSocial) ...[
                        const SizedBox(height: 12),
                        _buildReadOnlyField("Facebook", auth.user!['facebook']),
                        const SizedBox(height: 12),
                        _buildReadOnlyField("Instagram", auth.user!['instagram']),
                      ],
                      
                      const SizedBox(height: 24),

                      // UPDATE AKUN
                      Text("Update Akun", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: darkText)),
                      const SizedBox(height: 12),
                      _buildInputField("Nomor Handphone Baru", _phoneController, hint: "contoh: 08123456789", isNumber: true),
                      const SizedBox(height: 12),
                      _buildPasswordField("Kata Sandi Lama", _oldPasswordController, _obscureOld, () => setState(() => _obscureOld = !_obscureOld)),
                      const SizedBox(height: 12),
                      _buildPasswordField("Kata Sandi Baru", _newPasswordController, _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
                      const SizedBox(height: 12),
                      _buildPasswordField("Kata Sandi Konfirmasi", _confirmPasswordController, _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
                      const SizedBox(height: 12),
                      _buildInputField("Email Baru", _emailController, hint: "contoh: nama@email.com"),
                      const SizedBox(height: 24),

                      if (!hasBank) ...[
                        // INFORMASI BANK
                        Text("Informasi Bank", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: darkText)),
                        const SizedBox(height: 12),
                        _buildInputField("Nama Bank", _bankNameController, hint: "contoh: BCA / BNI / MANDIRI"),
                        const SizedBox(height: 12),
                        _buildInputField("Nomor Rekening", _bankAccountController, hint: "contoh: 1234567890", isNumber: true),
                        const SizedBox(height: 12),
                        _buildInputField("Nama Pemilik (Sesuai Rekening)", _accountNameController, hint: "contoh: Budi Santoso"),
                        const SizedBox(height: 24),
                      ],

                      if (!hasSocial) ...[
                        // SOCIAL MEDIA
                        Text("Social Media Account", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: darkText)),
                        const SizedBox(height: 12),
                        _buildInputField("Facebook", _fbController, hint: "URL profil Facebook"),
                        const SizedBox(height: 12),
                        _buildInputField("Instagram", _igController, hint: "@username"),
                        const SizedBox(height: 24),
                      ],

                      // CATATAN
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(LucideIcons.info, size: 14, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text("Catatan Penting:", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _buildBulletNote("Gunakan format nomor handphone 08xyz (tanpa +62) agar saat aktivasi PIN tidak terjadi kegagalan"),
                            _buildBulletNote("Nomor handphone sekaligus No WA aktif untuk pengiriman Notifikasi"),
                            _buildBulletNote("Email akan digunakan mengirim Laporan Transaksi Bulanan"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isUpdatingAccount ? null : () => _handleUpdateAccount(auth),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                            shadowColor: primaryTeal.withValues(alpha: 0.3),
                          ),
                          child: _isUpdatingAccount 
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text("UPDATE AKUN", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
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

  Widget _buildBulletNote(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 12, color: Colors.blue)),
          Expanded(child: Text(text, style: GoogleFonts.montserrat(fontSize: 10, color: Colors.blueGrey))),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700, color: textGrey)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
          child: Text(value, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
        ),
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {String hint = "", bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700, color: darkText)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
          style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryTeal)),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool isObscure, VoidCallback toggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700, color: darkText)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isObscure,
          style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: "minimal 6 digit",
            hintStyle: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryTeal)),
            suffixIcon: IconButton(
              icon: Icon(isObscure ? LucideIcons.eyeOff : LucideIcons.eye, color: Colors.grey.shade600, size: 20),
              onPressed: toggle,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleUpdateAccount(AuthProvider auth) async {
    final phone = _phoneController.text.trim();
    final oldPass = _oldPasswordController.text;
    final newPass = _newPasswordController.text;
    final confPass = _confirmPasswordController.text;
    final email = _emailController.text.trim();
    final bankName = _bankNameController.text.trim();
    final bankAcc = _bankAccountController.text.trim();
    final accountName = _accountNameController.text.trim();
    final fb = _fbController.text.trim();
    final ig = _igController.text.trim();

    if (phone.isEmpty && newPass.isEmpty && email.isEmpty && bankName.isEmpty && bankAcc.isEmpty && accountName.isEmpty && fb.isEmpty && ig.isEmpty) {
      _showBeautifulNotif("Tidak ada perubahan yang dilakukan", false);
      return;
    }

    if (newPass.isNotEmpty) {
      if (newPass.length < 6) {
        _showBeautifulNotif("Kata Sandi Baru minimal 6 digit!", false);
        return;
      }
      if (newPass != confPass) {
        _showBeautifulNotif("Konfirmasi Kata Sandi tidak cocok!", false);
        return;
      }
      if (oldPass.isEmpty) {
        _showBeautifulNotif("Harap isi Kata Sandi Lama untuk mengubah sandi!", false);
        return;
      }
    }

    setState(() => _isUpdatingAccount = true);

    Map<String, dynamic> payload = {};
    if (phone.isNotEmpty) payload['phone_number'] = phone;
    if (email.isNotEmpty) payload['email'] = email;
    if (newPass.isNotEmpty) {
      payload['old_password'] = oldPass;
      payload['new_password'] = newPass;
    }
    if (bankName.isNotEmpty) payload['bank_name'] = bankName;
    if (bankAcc.isNotEmpty) payload['bank_account'] = bankAcc;
    if (accountName.isNotEmpty) payload['account_name'] = accountName;
    if (fb.isNotEmpty) payload['facebook'] = fb;
    if (ig.isNotEmpty) payload['instagram'] = ig;

    final success = await auth.updateProfile(payload);
    
    if (mounted) {
      setState(() => _isUpdatingAccount = false);
      if (success) {
        _showBeautifulNotif("Akun berhasil diperbarui!", true);
        _phoneController.clear();
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _emailController.clear();
        _bankNameController.clear();
        _bankAccountController.clear();
        _accountNameController.clear();
        _fbController.clear();
        _igController.clear();
        setState(() => _isAccountExpanded = false);
      } else {
        _showBeautifulNotif(auth.lastErrorMessage ?? "Gagal memperbarui akun", false);
      }
    }
  }

  Widget _buildCompactPendingCard(dynamic user, AuthProvider auth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: primaryTeal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: (user['profile_photo'] != null && user['profile_photo'].toString().isNotEmpty)
                ? Image.network(
                    user['profile_photo'].toString().startsWith('http') 
                      ? user['profile_photo'].toString() 
                      : "${ApiConstants.rootUrl}/${user['profile_photo']}",
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(LucideIcons.user, size: 14, color: primaryTeal),
                  )
                : const Icon(LucideIcons.user, size: 14, color: primaryTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name'] ?? 'Tanpa Nama', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: darkText)),
                Text(user['phone_number'] ?? '-', style: GoogleFonts.montserrat(fontSize: 10, color: textGrey)),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => _handleApproval(user['identifier'], 'REJECTED', user['name'] ?? 'Pendaftar', auth),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFFC3312E).withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.x, size: 14, color: Color(0xFFC3312E)),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _handleApproval(user['identifier'], 'APPROVED', user['name'] ?? 'Pendaftar', auth),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.check, size: 14, color: primaryTeal),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCompactActiveCard(dynamic user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: (user['profile_photo'] != null && user['profile_photo'].toString().isNotEmpty)
                ? Image.network(
                    user['profile_photo'].toString().startsWith('http') 
                      ? user['profile_photo'].toString() 
                      : "${ApiConstants.rootUrl}/${user['profile_photo']}",
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(LucideIcons.user, size: 14, color: textGrey),
                  )
                : const Icon(LucideIcons.user, size: 14, color: textGrey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name'] ?? 'Tanpa Nama', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: darkText)),
                Text(user['phone_number'] ?? '-', style: GoogleFonts.montserrat(fontSize: 10, color: textGrey)),
              ],
            ),
          ),
          Row(
            children: [
              Icon(LucideIcons.star, size: 12, color: Colors.orange[400]),
              const SizedBox(width: 4),
              Text("5.0", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: darkText)),
            ],
          )
        ],
      ),
    );
  }

  Future<void> _handleApproval(dynamic identifier, String action, String name, AuthProvider auth) async {
    final success = await auth.processUserApproval(identifier, action);
    if (success && mounted) {
      if (action == 'APPROVED') {
        _showBeautifulNotif('$name berhasil di-approve!', true);
      } else {
        _showBeautifulNotif('$name telah ditolak.', false);
      }
      await Future.wait([
        auth.fetchPendingApprovals(),
        auth.fetchCouriers(),
      ]);
    }
  }

  void _showLocationPicker(AuthProvider auth) async {
    final result = await showModalBottomSheet<NyutjiLocationResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NyutjiLocationPicker(
        initialLat: _selectedLat,
        initialLng: _selectedLng,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedDistrict = result.subdistrict;
        _selectedCity = result.city;
        _selectedLat = result.lat;
        _selectedLng = result.lng;
        _fullAddressController.text = result.address;
        _hasUnsavedLocationChanges = true;
      });
      if(mounted) _showBeautifulNotif("Lokasi GPS terpilih: $_selectedDistrict", true);
    }
  }

  Future<void> _handleUpdateLocation(AuthProvider auth) async {
    if (_fullAddressController.text.isEmpty || _selectedDistrict.isEmpty) {
      _showBeautifulNotif("Mohon isi Alamat dan Set Lokasi GPS!", false);
      return;
    }

    setState(() => _isUpdatingLocation = true);
    
    final success = await auth.updateLocation({
      'address': _fullAddressController.text,
      'district_name': _selectedDistrict,
      'city_name': _selectedCity,
      'lat': _selectedLat,
      'lng': _selectedLng,
    });

    if (mounted) {
      setState(() => _isUpdatingLocation = false);
      if (success) {
        _showBeautifulNotif("Data Lokasi Mitra berhasil diperbarui!", true);
        setState(() {
          _isAddressExpanded = false;
          _hasUnsavedLocationChanges = false;
        });
      } else {
        _showBeautifulNotif("Gagal memperbarui data lokasi.", false);
      }
    }
  }

  Widget _buildMenuItem(IconData icon, String title, bool isLogout) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isLogout ? Colors.red : darkText),
          const SizedBox(width: 12),
          Text(title, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: isLogout ? Colors.red : darkText)),
          const Spacer(),
          Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }
}
