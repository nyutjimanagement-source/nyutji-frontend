import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../core/widgets/nyutji_location_picker.dart';

class RegisterMitraScreen extends StatefulWidget {
  const RegisterMitraScreen({super.key});

  @override
  State<RegisterMitraScreen> createState() => _RegisterMitraScreenState();
}

class _RegisterMitraScreenState extends State<RegisterMitraScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController searchKecController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  String selectedSegment = 'PRIBADI';
  String selectedCategory = 'KECIL';
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
      'title': 'Registrasi Mitra',
      'subtitle': 'Bangun bisnis laundry Anda bersama Manajemen Nyutji',
      'segment': 'Segmen Usaha',
      'category': 'Kategori Mitra',
      'location': 'Lokasi Wilayah Operasional',
      'search_kec': 'Cari Kecamatan...',
      'segments': {'PRIBADI': 'Pribadi', 'BADAN': 'Badan Usaha'},
      'categories': {'KECIL': 'Kecil', 'SEDANG': 'Sedang', 'BESAR': 'Besar'},
      'info_owner': 'Info Bisnis & Pemilik',
      'name_hint': 'Nama Lengkap Pemilik',
      'email_hint': 'Alamat Email',
      'phone_hint': 'Nomor Handphone Bisnis',
      'pass_hint': 'Kata Sandi',
      'success_msg': 'Registrasi Mitra Berhasil! Tunggu tim kami menghubungi Anda.',
      'seg_desc': {
        'PRIBADI': 'Bisnis perorangan, dikelola mandiri.',
        'BADAN': 'Entitas hukum (PT/CV), operasional tim.',
      },
      'cat_desc': {
        'KECIL': 'Kapasitas < 50kg/hari.',
        'SEDANG': 'Kapasitas 50-200kg/hari.',
        'BESAR': 'Kapasitas > 200kg/hari.',
      },
      'button': 'DAFTAR SEKARANG',
    },
    'en': {
      'title': 'Mitra Registration',
      'subtitle': 'Build your laundry business with Nyutji Management',
      'segment': 'Business Segment',
      'category': 'Mitra Category',
      'location': 'Operational District',
      'search_kec': 'Search District...',
      'segments': {'PRIBADI': 'Personal', 'BADAN': 'Business Entity'},
      'categories': {'KECIL': 'Small', 'SEDANG': 'Medium', 'BESAR': 'Large'},
      'info_owner': 'Business & Owner Info',
      'name_hint': "Owner's Full Name",
      'email_hint': 'Email Address',
      'phone_hint': 'Business Phone Number',
      'pass_hint': 'Password',
      'success_msg': 'Partner Registration Successful! Our team will contact you shortly.',
      'button': 'REGISTER NOW',
      'seg_desc': {
        'PRIBADI': 'Personal business, managed individually.',
        'BADAN': 'Legal entity (PT/CV), team operations.',
      },
      'cat_desc': {
        'KECIL': 'Capacity < 50kg/day.',
        'SEDANG': 'Capacity 50-200kg/day.',
        'BESAR': 'Capacity > 200kg/day.',
      },
    }
  };

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentT = t[auth.lang];
    const greenRetro = Color(0xFF27AE60);

    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: const BoxDecoration(
            color: Color(0xFFFFEBEE), // Softer light maroon/pink cream
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
                          icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF740006)), // Maroon accent
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF740006).withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF740006).withOpacity(0.1), width: 2),
                      ),
                      child: const Icon(LucideIcons.store, size: 40, color: Color(0xFF740006)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      currentT['title'],
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF740006),
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
                        border: Border.all(color: const Color(0xFF740006).withOpacity(0.1)),
                        boxShadow: [BoxShadow(color: const Color(0xFF740006).withOpacity(0.02), blurRadius: 20)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(currentT['info_owner']),
                          _buildTextField(nameController, currentT['name_hint'], LucideIcons.user, greenRetro),
                          const SizedBox(height: 12),
                          _buildTextField(searchKecController, currentT['search_kec'], LucideIcons.mapPin, greenRetro, 
                            suffix: IconButton(
                              icon: const Icon(LucideIcons.map, size: 20, color: Color(0xFF740006)),
                              onPressed: _showLocationPicker,
                            )
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(cityController, 'Nama Kota/Kabupaten', LucideIcons.map, greenRetro),
                          const SizedBox(height: 16),
                          _buildTextField(emailController, currentT['email_hint'], LucideIcons.mail, greenRetro, isEmail: true),
                          const SizedBox(height: 16),
                          _buildTextField(phoneController, currentT['phone_hint'], LucideIcons.phone, greenRetro),
                          const SizedBox(height: 16),
                          _buildTextField(passController, currentT['pass_hint'], LucideIcons.lock, greenRetro, isPass: true, obscure: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword)),
                          
                          const SizedBox(height: 30),
                          _buildLabel(currentT['segment']),
                          Column(
                            children: [
                              _buildChoiceItem(
                                title: currentT['segments']['PRIBADI'],
                                desc: currentT['seg_desc']['PRIBADI'],
                                icon: LucideIcons.user,
                                color: greenRetro,
                                isSelected: selectedSegment == 'PRIBADI',
                                onTap: () => setState(() => selectedSegment = 'PRIBADI'),
                              ),
                              const SizedBox(height: 12),
                              _buildChoiceItem(
                                title: currentT['segments']['BADAN'],
                                desc: currentT['seg_desc']['BADAN'],
                                icon: LucideIcons.building,
                                color: greenRetro,
                                isSelected: selectedSegment == 'BADAN',
                                onTap: () => setState(() => selectedSegment = 'BADAN'),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 30),
                           _buildLabel(currentT['location']),
                           _buildSearchField(searchKecController, currentT['search_kec'], LucideIcons.mapPin, greenRetro),
                           const SizedBox(height: 12),
                           _buildSearchField(cityController, 'Nama Kota (Default: Tasikmalaya)', LucideIcons.map, greenRetro),
                           const SizedBox(height: 12),

                          
                          const SizedBox(height: 30),
                          _buildLabel(currentT['category']),
                          Column(
                            children: [
                              _buildChoiceItem(
                                title: currentT['categories']['KECIL'],
                                desc: currentT['cat_desc']['KECIL'],
                                icon: LucideIcons.home,
                                color: greenRetro,
                                isSelected: selectedCategory == 'KECIL',
                                onTap: () => setState(() => selectedCategory = 'KECIL'),
                              ),
                              const SizedBox(height: 12),
                              _buildChoiceItem(
                                title: currentT['categories']['SEDANG'],
                                desc: currentT['cat_desc']['SEDANG'],
                                icon: LucideIcons.store,
                                color: greenRetro,
                                isSelected: selectedCategory == 'SEDANG',
                                onTap: () => setState(() => selectedCategory = 'SEDANG'),
                              ),
                              const SizedBox(height: 12),
                              _buildChoiceItem(
                                title: currentT['categories']['BESAR'],
                                desc: currentT['cat_desc']['BESAR'],
                                icon: LucideIcons.factory,
                                color: greenRetro,
                                isSelected: selectedCategory == 'BESAR',
                                onTap: () => setState(() => selectedCategory = 'BESAR'),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : () async {
                                if (nameController.text.isEmpty || searchKecController.text.isEmpty) {
                                  NyutjiNotif.showError(context, 'Nama dan Kecamatan wajib diisi!');
                                  return;
                                }

                                final success = await auth.register({
                                  'name': nameController.text,
                                  'email': emailController.text,
                                  'phone_number': phoneController.text,
                                  'password': passController.text,
                                  'role': 'ML',
                                  'districtName': searchKecController.text,
                                  'cityName': cityController.text.isEmpty ? 'Tasikmalaya' : cityController.text,
                                  'business_type': selectedSegment,
                                  'mitra_category': selectedCategory,
                                });

                                if (!mounted) return;
                                if (success) {
                                  NyutjiNotif.showSuccess(context, 'Registrasi Berhasil! Menunggu Approval Admin.');
                                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                                } else {
                                  NyutjiNotif.showError(context, 'Gagal Registrasi. Coba lagi atau hubungi IT.');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF740006),
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
      child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.grey)),
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
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF740006)),
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

  Widget _buildChoiceItem({required String title, required String desc, required IconData icon, required Color color, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF740006).withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF740006) : Colors.grey[200]!, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: isSelected ? const Color(0xFF740006) : Colors.grey[100], shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: isSelected ? Colors.white : Colors.grey[600]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? const Color(0xFF740006) : Colors.black87)),
                  Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ),
            if (isSelected) const Icon(LucideIcons.checkCircle, size: 20, color: Color(0xFF740006)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(TextEditingController controller, String hint, IconData icon, Color color) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
        suffixIcon: Icon(LucideIcons.search, size: 18, color: Colors.grey.withOpacity(0.5)),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF740006)),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF740006).withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF740006), width: 2)),
      ),
    );
  }
}
