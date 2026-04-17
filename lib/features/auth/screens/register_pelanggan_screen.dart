import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class RegisterPelangganScreen extends StatefulWidget {
  const RegisterPelangganScreen({super.key});

  @override
  State<RegisterPelangganScreen> createState() => _RegisterPelangganScreenState();
}

class _RegisterPelangganScreenState extends State<RegisterPelangganScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  final Map<String, dynamic> t = {
    'id': {
      'title': 'Daftar Pelanggan',
      'subtitle': 'Nikmati kemudahan laundry dalam genggaman',
      'info_personal': 'Info Personal',
      'name_hint': 'Nama Lengkap',
      'email_hint': 'Alamat Email',
      'phone_hint': 'Nomor Handphone',
      'pass_hint': 'Kata Sandi',
      'button': 'DAFTAR SEKARANG',
      'success_msg': 'Pendaftaran Berhasil! Silakan Login.',
    },
    'en': {
      'title': 'Customer Registration',
      'subtitle': 'Enjoy laundry convenience at your fingertips',
      'info_personal': 'Personal Info',
      'name_hint': 'Full Name',
      'email_hint': 'Email Address',
      'phone_hint': 'Phone Number',
      'pass_hint': 'Password',
      'button': 'REGISTER NOW',
      'success_msg': 'Registration Successful! Please Login.',
    }
  };
  void _handleRegister() async {
    if (nameController.text.isEmpty || phoneController.text.isEmpty || districtController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama, Nomor HP, dan Kecamatan wajib diisi!'), backgroundColor: Colors.red),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await auth.register({
      'name': nameController.text,
      'email': emailController.text,
      'phone_number': phoneController.text,
      'password': passController.text,
      'role': 'PL',
      'districtName': districtController.text,
      'cityName': cityController.text.isEmpty ? 'Tasikmalaya' : cityController.text,
    });

    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pendaftaran Berhasil! Menunggu Approval Admin.'), backgroundColor: Color(0xFF286B6A)),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal Mendaftarkan Akun. Email mungkin sudah terdaftar.'), backgroundColor: Colors.red),
      );
    }
}

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentT = t[auth.lang];
    const tealRetro = Color(0xFF286B6A);

    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: const BoxDecoration(
            color: Color(0xFFE8F5E9), // Softer light green
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
                          icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF2E7D32)), // Dark Green
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.2), width: 2),
                      ),
                      child: const Icon(LucideIcons.user, size: 40, color: Color(0xFF2E7D32)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      currentT['title'],
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentT['subtitle'],
                      style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 30)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(currentT['info_personal']),
                          _buildTextField(nameController, currentT['name_hint'], LucideIcons.user, tealRetro),
                          const SizedBox(height: 16),
                          _buildTextField(emailController, currentT['email_hint'], LucideIcons.mail, tealRetro, isEmail: true),
                          const SizedBox(height: 16),
                          _buildTextField(phoneController, currentT['phone_hint'], LucideIcons.phone, tealRetro),
                          const SizedBox(height: 16),
                          _buildTextField(districtController, 'Nama Kecamatan', LucideIcons.mapPin, tealRetro),
                          const SizedBox(height: 16),
                          _buildTextField(cityController, 'Nama Kota (Default: Tasikmalaya)', LucideIcons.map, tealRetro),
                          const SizedBox(height: 16),
                          _buildTextField(passController, currentT['pass_hint'], LucideIcons.lock, tealRetro, isPass: true),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tealRetro,
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: auth.isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, Color color, {bool isPass = false, bool isEmail = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      style: const TextStyle(color: Colors.black87),
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}
