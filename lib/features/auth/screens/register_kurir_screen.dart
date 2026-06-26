import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../core/widgets/nyutji_location_picker.dart';

class RegisterKurirScreen extends ConsumerStatefulWidget {
  const RegisterKurirScreen({super.key});

  @override ConsumerState<RegisterKurirScreen> createState() => _RegisterKurirScreenState();
}

class _RegisterKurirScreenState extends ConsumerState<RegisterKurirScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController searchKecController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController searchMitraController = TextEditingController();

  String? selectedMitraIdentifier;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider).fetchMitras();
    });
  }

  void _showLocationPicker() async {
    final NyutjiLocationResult? result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NyutjiLocationPicker(),
    );

    if (result != null) {
      setState(() {
        searchKecController.text = result.subdistrict;
        cityController.text = result.city;
      });
      if (!mounted) return;
      NyutjiNotif.showSuccess(context, "Lokasi terdeteksi: ${result.subdistrict}");
    }
  }

  final Map<String, dynamic> t = {
    'id': {
      'title': 'Registrasi Kurir',
      'subtitle': 'Mulai perjalanan karir Anda bersama Nyutji',
      'location': 'Lokasi Penugasan',
      'mitra_ref': 'Referensi Mitra Laundry',
      'search_kec': 'Pilih Kecamatan',
      'search_mitra': 'Pilih Mitra Laundry',
      'info_personal': 'Info Personal',
      'name_hint': 'Nama Lengkap',
      'email_hint': 'Alamat Email',
      'phone_hint': 'Nomor Handphone',
      'pass_hint': 'Kata Sandi',
      'button': 'DAFTAR SEKARANG',
    },
    'en': {
      'title': 'Courier Registration',
      'subtitle': 'Start your career path with Nyutji',
      'location': 'Assigned Location',
      'mitra_ref': 'Mitra Laundry Reference',
      'search_kec': 'Select District',
      'search_mitra': 'Select Mitra Laundry',
      'info_personal': 'Personal Info',
      'name_hint': 'Full Name',
      'email_hint': 'Email Address',
      'phone_hint': 'Phone Number',
      'pass_hint': 'Password',
      'button': 'REGISTER NOW',
    }
  };

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final currentT = t[auth.lang] ?? t['id'];
    const primaryOrange = Color(0xFFD35400);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Header: Akun Baru Nyutji
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.chevronLeft, color: primaryOrange),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    "Akun Baru Nyutji",
                    style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold, color: primaryOrange),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // To balance the IconButton
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Profile Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: primaryOrange.withValues(alpha: 0.1), width: 2),
              ),
              child: const Icon(LucideIcons.truck, size: 50, color: primaryOrange),
            ),
            const SizedBox(height: 24),
            Text(
              currentT['title'],
              style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color: primaryOrange),
            ),
            const SizedBox(height: 8),
            Text(
              currentT['subtitle'],
              style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            // Form Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 30, offset: const Offset(0, 10))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(currentT['info_personal'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400])),
                    const SizedBox(height: 16),
                    _textField(nameController, currentT['name_hint'], LucideIcons.user, primaryOrange),
                    const SizedBox(height: 16),
                    _textField(emailController, currentT['email_hint'], LucideIcons.mail, primaryOrange),
                    const SizedBox(height: 16),
                    _textField(phoneController, currentT['phone_hint'], LucideIcons.phone, primaryOrange, keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _textField(
                      passController, 
                      currentT['pass_hint'], 
                      LucideIcons.lock,
                      primaryOrange,
                      obscure: _obscurePassword,
                      suffix: IconButton(
                        icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 20, color: Colors.grey[300]),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(currentT['location'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400])),
                    const SizedBox(height: 16),
                    _textField(
                      searchKecController, 
                      currentT['search_kec'], 
                      LucideIcons.mapPin, 
                      primaryOrange,
                      suffix: IconButton(
                        icon: const Icon(LucideIcons.map, size: 20, color: primaryOrange),
                        onPressed: _showLocationPicker,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _textField(cityController, 'Nama Kota/Kabupaten', LucideIcons.map, primaryOrange),
                    const SizedBox(height: 32),
                    Text(currentT['mitra_ref'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400])),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _showMitraPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.briefcase, size: 20, color: primaryOrange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                searchMitraController.text.isEmpty ? currentT['search_mitra'] : searchMitraController.text,
                                style: GoogleFonts.montserrat(
                                  fontSize: 15, 
                                  fontWeight: searchMitraController.text.isEmpty ? FontWeight.normal : FontWeight.w600,
                                  color: searchMitraController.text.isEmpty ? Colors.grey[300] : Colors.black87,
                                ),
                              ),
                            ),
                            const Icon(LucideIcons.chevronDown, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: auth.isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(currentT['button'], style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _textField(TextEditingController controller, String hint, IconData icon, Color color, {bool obscure = false, Widget? suffix, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(fontSize: 15, color: Colors.grey[300], fontWeight: FontWeight.normal),
        prefixIcon: Icon(icon, size: 20, color: color),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  void _handleAction() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final pass = passController.text.trim();
    final district = searchKecController.text.trim();

    if (name.isEmpty || district.isEmpty || selectedMitraIdentifier == null || phone.isEmpty || pass.isEmpty) {
      NyutjiNotif.showError(context, 'Mohon lengkapi semua data wajib!');
      return;
    }

    final auth = ref.read(authProvider);
    final errorMsg = await auth.register({
      'name': name,
      'email': emailController.text.trim(),
      'phone_number': phone,
      'password': pass,
      'role': 'KL',
      'districtName': district,
      'district_code': Formatters.generateDistrictCode(district),
      'cityName': cityController.text.isEmpty ? 'Tasikmalaya' : cityController.text,
      'mitraRefName': searchMitraController.text,
      'mitra_id': selectedMitraIdentifier,
      'mitra_ref_id': selectedMitraIdentifier,
      'mitra_ref_identifier': selectedMitraIdentifier,
    });

    if (!mounted) return;
    if (errorMsg == null) {
      NyutjiNotif.showSuccess(context, 'Registrasi Berhasil! Hubungi Mitra untuk Approval.');
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } else {
      NyutjiNotif.showError(context, errorMsg);
    }
  }

  void _showMitraPicker() {
    if (searchKecController.text.isEmpty) {
      NyutjiNotif.showError(context, "Silakan pilih Lokasi terlebih dahulu");
      return;
    }

    final auth = ref.read(authProvider);
    final targetKec = searchKecController.text
      .replaceAll(RegExp(r'^kecamatan\s+', caseSensitive: false), '')
      .replaceAll(RegExp(r'^kec\.\s*', caseSensitive: false), '')
      .trim().toLowerCase();
    
    final filteredMitras = auth.mitras.where((m) {
      final mDist1 = m['district_name']?.toString().trim().toLowerCase();
      final mDist2 = m['district']?['name']?.toString().trim().toLowerCase();
      return mDist1 == targetKec || mDist2 == targetKec || mDist1 == '000';
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
            ),
            Text("Pilih Mitra di $targetKec", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            if (filteredMitras.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(child: Text("Tidak ada Mitra terdaftar di kecamatan ini.", style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey))),
              )
            else
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: filteredMitras.length,
                  itemBuilder: (context, index) {
                    final m = filteredMitras[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(backgroundColor: const Color(0xFFD35400).withValues(alpha: 0.1), child: const Icon(LucideIcons.store, color: Color(0xFFD35400), size: 18)),
                      title: Text(m['name'] ?? "Mitra Laundry", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: Text("ID: ${m['identifier'] ?? '-'}", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey)),
                      onTap: () {
                        setState(() {
                          searchMitraController.text = m['name'];
                          selectedMitraIdentifier = m['identifier'];
                        });
                        Navigator.pop(context);
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
}

