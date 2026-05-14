import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/formatters.dart';
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
  
  final TextEditingController ownerAddressController = TextEditingController();
  final TextEditingController ownerDetailController = TextEditingController();
  String ownerDistrict = "";
  String ownerCity = "";

  final TextEditingController opKecController = TextEditingController();
  final TextEditingController opCityController = TextEditingController();
  bool isSameLocation = false;

  String selectedSegment = 'PRIBADI';
  String selectedCategory = 'KECIL';
  bool _obscurePassword = true;

  void _showLocationPicker(bool isOwner) async {
    final NyutjiLocationResult? result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NyutjiLocationPicker(),
    );

    if (result != null) {
      setState(() {
        if (isOwner) {
          ownerAddressController.text = result.address;
          ownerDistrict = result.subdistrict;
          ownerCity = result.city;
          if (isSameLocation) {
            opKecController.text = ownerDistrict;
            opCityController.text = ownerCity;
          }
        } else {
          opKecController.text = result.subdistrict;
          opCityController.text = result.city;
        }
      });
      if (!mounted) return;
      NyutjiNotif.showSuccess(context, "Lokasi terdeteksi: ${result.subdistrict}");
    }
  }

  final Map<String, dynamic> t = {
    'id': {
      'title': 'Registrasi Mitra',
      'subtitle': 'Bangun bisnis laundry Anda bersama Nyutji Managemen',
      'segment': 'Segmen Usaha',
      'category': 'Kategori Mitra',
      'location': 'Lokasi Wilayah Operasional',
      'search_kec': 'Alamat Sesuai KTP',
      'segments': {'PRIBADI': 'Pribadi', 'BADAN': 'Badan Usaha'},
      'categories': {'KECIL': 'Kecil', 'SEDANG': 'Sedang', 'BESAR': 'Besar', 'SELF_SERVICE': 'Self Service'},
      'info_owner': 'Info Bisnis & Pemilik',
      'name_hint': 'Nama Lengkap Pemilik',
      'email_hint': 'Alamat Email',
      'phone_hint': 'Nomor Handphone Bisnis',
      'pass_hint': 'Kata Sandi',
      'button': 'DAFTAR SEKARANG',
      'seg_desc': {
        'PRIBADI': 'Bisnis perorangan, dikelola mandiri.',
        'BADAN': 'Entitas hukum (PT/CV), operasional tim.',
      },
      'cat_desc': {
        'KECIL': 'Kapasitas < 50kg/hari.',
        'SEDANG': 'Kapasitas 50-200kg/hari.',
        'BESAR': 'Kapasitas > 200kg/hari.',
        'SELF_SERVICE': 'Pelanggan cuci mandiri.',
      },
    },
    'en': {
      'title': 'Mitra Registration',
      'subtitle': 'Build your laundry business with Nyutji Management',
      'segment': 'Business Segment',
      'category': 'Mitra Category',
      'location': 'Operational District',
      'search_kec': 'Full Address (ID Card)',
      'segments': {'PRIBADI': 'Personal', 'BADAN': 'Business Entity'},
      'categories': {'KECIL': 'Small', 'SEDANG': 'Medium', 'BESAR': 'Large', 'SELF_SERVICE': 'Self Service'},
      'info_owner': 'Business & Owner Info',
      'name_hint': "Owner's Full Name",
      'email_hint': 'Email Address',
      'phone_hint': 'Business Phone Number',
      'pass_hint': 'Password',
      'button': 'REGISTER NOW',
      'seg_desc': {
        'PRIBADI': 'Personal business, managed individually.',
        'BADAN': 'Legal entity (PT/CV), team operations.',
      },
      'cat_desc': {
        'KECIL': 'Capacity < 50kg/day.',
        'SEDANG': 'Capacity 50-200kg/day.',
        'BESAR': 'Capacity > 200kg/day.',
        'SELF_SERVICE': 'Customers wash themselves.',
      },
    }
  };

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentT = t[auth.lang] ?? t['id'];
    const primaryMaroon = Color(0xFF740006);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.chevronLeft, color: primaryMaroon),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    "Akun Baru Nyutji",
                    style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold, color: primaryMaroon),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // To balance the IconButton
                ],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: primaryMaroon.withValues(alpha: 0.1), width: 2),
              ),
              child: const Icon(LucideIcons.store, size: 50, color: primaryMaroon),
            ),
            const SizedBox(height: 24),
            Text(
              currentT['title'],
              style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color: primaryMaroon),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                currentT['subtitle'],
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 40),
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
                    Text(currentT['info_owner'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400])),
                    const SizedBox(height: 16),
                    _textField(nameController, currentT['name_hint'], LucideIcons.user, primaryMaroon),
                    const SizedBox(height: 16),
                    _textField(
                      ownerAddressController, 
                      currentT['search_kec'], 
                      LucideIcons.mapPin, 
                      primaryMaroon,
                      suffix: IconButton(
                        icon: const Icon(LucideIcons.map, size: 20, color: primaryMaroon),
                        onPressed: () => _showLocationPicker(true),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _textField(ownerDetailController, 'Detail Alamat (Gang, Blok, No Rumah)', LucideIcons.home, primaryMaroon),
                    const SizedBox(height: 16),
                    _textField(emailController, currentT['email_hint'], LucideIcons.mail, primaryMaroon),
                    const SizedBox(height: 16),
                    _textField(phoneController, currentT['phone_hint'], LucideIcons.phone, primaryMaroon, keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _textField(
                      passController, 
                      currentT['pass_hint'], 
                      LucideIcons.lock,
                      primaryMaroon,
                      obscure: _obscurePassword,
                      suffix: IconButton(
                        icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 20, color: Colors.grey[300]),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(currentT['segment'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400])),
                    const SizedBox(height: 16),
                    _buildChoiceItem(
                      title: currentT['segments']['PRIBADI'],
                      desc: currentT['seg_desc']['PRIBADI'],
                      icon: LucideIcons.user,
                      primaryColor: primaryMaroon,
                      isSelected: selectedSegment == 'PRIBADI',
                      onTap: () => setState(() => selectedSegment = 'PRIBADI'),
                    ),
                    const SizedBox(height: 12),
                    _buildChoiceItem(
                      title: currentT['segments']['BADAN'],
                      desc: currentT['seg_desc']['BADAN'],
                      icon: LucideIcons.building,
                      primaryColor: primaryMaroon,
                      isSelected: selectedSegment == 'BADAN',
                      onTap: () => setState(() => selectedSegment = 'BADAN'),
                    ),
                    const SizedBox(height: 32),
                    Text(currentT['location'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400])),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: isSameLocation,
                          activeColor: primaryMaroon,
                          onChanged: (val) {
                            setState(() {
                              isSameLocation = val ?? false;
                              if (isSameLocation && ownerDistrict.isNotEmpty) {
                                opKecController.text = ownerDistrict;
                                opCityController.text = ownerCity;
                              }
                            });
                          },
                        ),
                        Expanded(child: Text("Alamat Usaha sama dengan KTP", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[600]))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _textField(
                      opKecController, 
                      'Kecamatan Operasional', 
                      LucideIcons.mapPin, 
                      primaryMaroon,
                      suffix: IconButton(
                        icon: const Icon(LucideIcons.map, size: 20, color: primaryMaroon),
                        onPressed: isSameLocation ? null : () => _showLocationPicker(false),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _textField(opCityController, 'Kota Operasional', LucideIcons.map, primaryMaroon),
                    const SizedBox(height: 32),
                    Text(currentT['category'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400])),
                    const SizedBox(height: 16),
                    Column(
                      children: currentT['categories'].keys.map<Widget>((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildChoiceItem(
                            title: currentT['categories'][cat],
                            desc: currentT['cat_desc'][cat],
                            icon: cat == 'KECIL' ? LucideIcons.home : cat == 'SEDANG' ? LucideIcons.store : cat == 'BESAR' ? LucideIcons.factory : LucideIcons.droplets,
                            primaryColor: primaryMaroon,
                            isSelected: selectedCategory == cat,
                            onTap: () => setState(() => selectedCategory = cat),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryMaroon,
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

  Widget _buildChoiceItem({required String title, required String desc, required IconData icon, required Color primaryColor, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.05) : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? primaryColor : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: isSelected ? primaryColor : Colors.grey[200], shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: isSelected ? Colors.white : Colors.grey[500]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? primaryColor : Colors.black87)),
                  Text(desc, style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
            if (isSelected) Icon(LucideIcons.checkCircle, size: 20, color: primaryColor),
          ],
        ),
      ),
    );
  }

  void _handleAction() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final pass = passController.text.trim();
    final address = ownerAddressController.text.trim();
    final district = opKecController.text.trim();

    if (name.isEmpty || address.isEmpty || district.isEmpty || phone.isEmpty || pass.isEmpty) {
      NyutjiNotif.showError(context, 'Mohon lengkapi semua data wajib!');
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final errorMsg = await auth.register({
      'name': name,
      'email': emailController.text.trim(),
      'phone_number': phone,
      'password': pass,
      'role': 'ML',
      'owner_address': '${ownerAddressController.text}${ownerDetailController.text.isNotEmpty ? ', ${ownerDetailController.text}' : ''}',
      'owner_district_name': ownerDistrict,
      'owner_city_name': ownerCity,
      'districtName': district,
      'district_code': Formatters.generateDistrictCode(district),
      'cityName': opCityController.text.isEmpty ? 'Tasikmalaya' : opCityController.text,
      'business_type': selectedSegment,
      'mitra_category': selectedCategory,
    });

    if (!mounted) return;
    if (errorMsg == null) {
      NyutjiNotif.showSuccess(context, 'Registrasi Berhasil! Menunggu Approval Admin.');
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } else {
      NyutjiNotif.showError(context, errorMsg);
    }
  }
}
