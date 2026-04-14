import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class RegisterKurirScreen extends StatefulWidget {
  const RegisterKurirScreen({Key? key}) : super(key: key);

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

  String? selectedKecamatan;
  String? selectedMitra;

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
                          _buildTextField(passController, currentT['pass_hint'], LucideIcons.lock, orangeRetro, isPass: true),
                          
                          const SizedBox(height: 30),
                          _buildLabel(currentT['location']),
                          _buildSearchField(searchKecController, currentT['search_kec'], LucideIcons.mapPin, orangeRetro),
                          const SizedBox(height: 12),
                          // Mockup Map Image
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                              image: const DecorationImage(
                                image: NetworkImage('https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=MnwxfDB8MXxyYW5kb218MHx8bWFwfHx8fHx8MTcwMTI0NTY3OA&ixlib=rb-4.0.3&q=80&w=1080'),
                                fit: BoxFit.cover,
                                opacity: 0.8,
                              ),
                            ),
                            child: const Center(
                              child: Icon(LucideIcons.map, color: orangeRetro, size: 40),
                            ),
                          ),
                          
                          const SizedBox(height: 30),
                          _buildLabel(currentT['mitra_ref']),
                          _buildSearchField(searchMitraController, currentT['search_mitra'], LucideIcons.briefcase, orangeRetro),
                          
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(currentT['success_msg']), backgroundColor: orangeRetro),
                                );
                                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: orangeRetro,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                              ),
                              child: Text(currentT['button'], style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, Color color, {bool isPass = false, bool isEmail = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: color),
        filled: true,
        fillColor: color.withOpacity(0.05),
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
