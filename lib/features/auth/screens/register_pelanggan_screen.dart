import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/widgets/nyutji_notif.dart';

class RegisterPelangganScreen extends ConsumerStatefulWidget {
  const RegisterPelangganScreen({super.key});

  @override ConsumerState<RegisterPelangganScreen> createState() => _RegisterPelangganScreenState();
}

class _RegisterPelangganScreenState extends ConsumerState<RegisterPelangganScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  bool _obscurePassword = true;

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
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final pass = passController.text.trim();

    if (name.isEmpty || phone.isEmpty || pass.isEmpty) {
      NyutjiNotif.showError(context, 'Nama, No HP, dan Password wajib diisi!');
      return;
    }

    final auth = ref.read(authProvider);
    final errorMsg = await auth.register({
      'name': name,
      'email': emailController.text.trim(),
      'phone_number': phone,
      'password': pass,
      'role': 'PL',
    });

    if (!mounted) return;
    if (errorMsg == null) {
      NyutjiNotif.showSuccess(context, 'Pendaftaran Berhasil! Menunggu Approval.');
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } else {
      NyutjiNotif.showError(context, errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final currentT = t[auth.lang] ?? t['id'];
    const primaryGreen = Color(0xFF286B6A);

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
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
                    icon: const Icon(LucideIcons.chevronLeft, color: primaryGreen),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    "Akun Baru Nyutji",
                    style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold, color: primaryGreen),
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
                border: Border.all(color: primaryGreen.withValues(alpha: 0.1), width: 2),
              ),
              child: const Icon(LucideIcons.user, size: 50, color: primaryGreen),
            ),
            const SizedBox(height: 24),
            Text(
              currentT['title'],
              style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color: primaryGreen),
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
                    _textField(nameController, currentT['name_hint'], LucideIcons.user),
                    const SizedBox(height: 16),
                    _textField(emailController, currentT['email_hint'], LucideIcons.mail),
                    const SizedBox(height: 16),
                    _textField(phoneController, currentT['phone_hint'], LucideIcons.phone, keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _textField(
                      passController, 
                      currentT['pass_hint'], 
                      LucideIcons.lock,
                      obscure: _obscurePassword,
                      suffix: IconButton(
                        icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 20, color: Colors.grey[300]),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
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

  Widget _textField(TextEditingController controller, String hint, IconData icon, {bool obscure = false, Widget? suffix, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(fontSize: 15, color: Colors.grey[300], fontWeight: FontWeight.normal),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF286B6A)),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}

