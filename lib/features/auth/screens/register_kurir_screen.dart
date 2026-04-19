import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../core/widgets/nyutji_location_picker.dart';

class RegisterKurirScreen extends StatefulWidget {
  const RegisterKurirScreen({super.key});

  @override
  State<RegisterKurirScreen> createState() => _RegisterKurirScreenState();
}

class _RegisterKurirScreenState extends State<RegisterKurirScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController searchKecController = TextEditingController();
  final TextEditingController searchMitraController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  String? selectedKecamatan;
  String? selectedMitra;
  bool _obscurePassword = true;

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
      NyutjiNotif.showSuccess(context, "Lokasi terdeteksi: ${result.subdistrict}");
    }
  }

  final Map<String, dynamic> t = {
    'id': {
      'title': 'Registrasi Kurir',
      'subtitle': 'Mulai perjalanan karir Anda bersama Nyutji',
      'location': 'Lokasi Penugasan (Kecamatan)',
      'mitra_ref': 'Referensi Mitra Laundry',
      'search_kec': 'Cari Kecamatan...',
      'search_mitra': 'Cari Nama Mitra...',
      'info_personal': 'Info Personal',
      'name_hint': 'Nama Lengkap',
      'email_hint': 'Alamat Email',
      'phone_hint': 'Nomor Handphone',
      'pass_hint': 'Kata Sandi',
      'success_msg': 'Registrasi Kurir Berhasil!',
      'button': 'DAFTAR SEKARANG',
    },
    'en': {
      'title': 'Courier Registration',
      'subtitle': 'Start your career path with Nyutji',
      'location': 'Assigned Location (District)',
      'mitra_ref': 'Mitra Laundry Reference',
      'search_kec': 'Search District...',
      'search_mitra': 'Search Mitra Name...',
      'info_personal': 'Personal Info',
      'name_hint': 'Full Name',
      'email_hint': 'Email Address',
      'phone_hint': 'Phone Number',
      'pass_hint': 'Password',
      'success_msg': 'Courier Registration Successful!',
      'button': 'REGISTER NOW',
    }
  };

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentT = t[auth.lang];
    const orangeRetro = Color(0xFFD35400);

    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF5E1), // Retro Cream/Orange hint
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 10))],
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.chevronLeft, color: orangeRetro),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: orangeRetro.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: orangeRetro.withOpacity(0.2), width: 2),
                      ),
                      child: const Icon(LucideIcons.truck, size: 40, color: orangeRetro),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      currentT['title'],
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: orangeRetro,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentT['subtitle'],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 30),
                    
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: orangeRetro.withOpacity(0.2)),
                        boxShadow: [BoxShadow(color: orangeRetro.withOpacity(0.05), blurRadius: 20)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(currentT['info_personal']),
                          _buildTextField(nameController, currentT['name_hint'], LucideIcons.user, orangeRetro),
                          const SizedBox(height: 16),
                          _buildTextField(emailController, currentT['email_hint'], LucideIcons.mail, orangeRetro, isEmail: true),
                          const SizedBox(height: 16),
                          _buildTextField(phoneController, currentT['phone_hint'], LucideIcons.phone, orangeRetro),
                          const SizedBox(height: 16),
                          _buildTextField(passController, currentT['pass_hint'], LucideIcons.lock, orangeRetro, isPass: true, obscure: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword)),
                          
                          const SizedBox(height: 30),
                           _buildLabel(currentT['location']),
                           _buildTextField(searchKecController, currentT['search_kec'], LucideIcons.mapPin, orangeRetro, 
                            suffix: IconButton(
                              icon: const Icon(LucideIcons.map, size: 20, color: Color(0xFFD35400)),
                              onPressed: _showLocationPicker,
                            )
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(cityController, 'Nama Kota/Kabupaten', LucideIcons.map, orangeRetro),
                          const SizedBox(height: 12),

                          
                          const SizedBox(height: 30),
                          _buildLabel(currentT['mitra_ref']),
                          _buildSearchField(searchMitraController, currentT['search_mitra'], LucideIcons.briefcase, orangeRetro),
                          
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : () async {
                                if (nameController.text.isEmpty || searchKecController.text.isEmpty || searchMitraController.text.isEmpty) {
                                  NyutjiNotif.showError(context, 'Nama, Kecamatan, dan Referensi Mitra wajib diisi!');
                                  return;
                                }

                                final success = await auth.register({
                                  'name': nameController.text,
                                  'email': emailController.text,
                                  'phone_number': phoneController.text,
                                  'password': passController.text,
                                  'role': 'KL',
                                  'districtName': searchKecController.text,
                                  'cityName': cityController.text.isEmpty ? 'Tasikmalaya' : cityController.text,
                                  'mitraRefName': searchMitraController.text,
                                });

                                if (!mounted) return;
                                if (success) {
                                  NyutjiNotif.showSuccess(context, 'Registrasi Berhasil! Hubungi Mitra untuk Approval.');
                                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                                } else {
                                  NyutjiNotif.showError(context, 'Gagal Registrasi Kurir. Silakan coba lagi.');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: orangeRetro,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                              ),
                              child: auth.isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                                : Text(currentT['button'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.grey)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, Color color, {bool isPass = false, bool isEmail = false, bool obscure = false, VoidCallback? onToggle, Widget? suffix}) {
    return TextField(
      controller: controller,
      obscureText: isPass ? obscure : false,
      style: const TextStyle(color: Colors.black87),
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFFD35400)),
        suffixIcon: suffix ?? (isPass ? IconButton(
          icon: Icon(obscure ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: Colors.grey),
          onPressed: onToggle,
        ) : null),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSearchField(TextEditingController controller, String hint, IconData icon, Color color) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: const Icon(LucideIcons.search, size: 18),
        prefixIcon: Icon(icon, size: 18, color: color),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color, width: 2)),
      ),
    );
  }
}
