import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../core/widgets/nyutji_location_picker.dart';
import '../../../core/widgets/nyutji_image_picker.dart';
import '../../../core/constants/api_constants.dart';

class RegisterMitraScreen extends StatefulWidget {
  const RegisterMitraScreen({super.key});

  @override
  State<RegisterMitraScreen> createState() => _RegisterMitraScreenState();
}

class _RegisterMitraScreenState extends State<RegisterMitraScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Pink elegant color for Mitra
  static const Color primaryColor = Color(0xFFD81B60);

  // Step 1: Info Pemilik
  final TextEditingController nameController = TextEditingController();
  final TextEditingController identityController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController ownerAddressController = TextEditingController();
  final TextEditingController ownerDetailController = TextEditingController();
  String ownerDistrict = "";
  String ownerCity = "";
  XFile? ktpFile;

  // Step 2: Info Bisnis
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController businessAddressController = TextEditingController();
  String businessDistrict = "";
  String businessCity = "";

  // Step 3: Segmen & Kategori
  String selectedSegment = 'PRIBADI';
  String selectedCategory = 'KECIL';
  List<String> dlaundryServices = [];
  bool _isLoadingServices = false;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() => _isLoadingServices = true);
    try {
      final dio = Dio();
      final response = await dio.get('${ApiConstants.baseUrl}/services/dlaundry', queryParameters: {
        'category': selectedCategory
      });
      if (response.data['success']) {
        if (!mounted) return;
        setState(() {
          final allData = response.data['data'] as List;
          dlaundryServices = allData.map((e) => e['category'].toString()).toSet().toList();
        });
      }
    } catch (e) {
      debugPrint("Gagal fetch services: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingServices = false);
      }
    }
  }

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
        } else {
          businessAddressController.text = result.address;
          businessDistrict = result.subdistrict;
          businessCity = result.city;
        }
      });
      if (!mounted) return;
      NyutjiNotif.showSuccess(context, "Lokasi terdeteksi: ${result.subdistrict}");
    }
  }

  void _pickKtp() {
    NyutjiImagePicker.show(
      context,
      title: "Unggah Foto KTP",
      primaryColor: primaryColor,
      onImagePicked: (file) {
        setState(() => ktpFile = file);
        NyutjiNotif.showSuccess(context, "KTP berhasil dipilih");
      },
    );
  }

  Future<void> _submitRegistration() async {
    if (nameController.text.isEmpty || identityController.text.isEmpty || phoneController.text.isEmpty || passController.text.isEmpty) {
      NyutjiNotif.showError(context, "Harap lengkapi semua field yang wajib");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'name': nameController.text.trim(),
        'owner_identity': identityController.text.trim(),
        'email': emailController.text.trim(),
        'owner_address': "${ownerAddressController.text.trim()} ${ownerDetailController.text.trim()}",
        'owner_district_name': ownerDistrict,
        'owner_city_name': ownerCity,
        'business_name': businessNameController.text.trim(),
        'phone_number': phoneController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        'password': passController.text,
        'business_address': businessAddressController.text.trim(),
        'business_district_name': businessDistrict,
        'business_city_name': businessCity,
        'business_type': selectedSegment,
        'mitra_category': selectedCategory,
      });

      if (ktpFile != null) {
        formData.files.add(MapEntry(
          'ktp',
          await MultipartFile.fromFile(ktpFile!.path, filename: 'ktp.webp'),
        ));
      }

      final response = await dio.post('${ApiConstants.baseUrl}/register-mitra-komplit', data: formData);

      if (response.statusCode == 201) {
        if (!mounted) return;
        NyutjiNotif.showSuccess(context, response.data['message'] ?? "Registrasi Berhasil");
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      String errMsg = "Gagal Registrasi";
      if (e is DioException && e.response != null) {
        errMsg = e.response?.data['message'] ?? e.response?.data['error'] ?? errMsg;
      }
      NyutjiNotif.showError(context, errMsg);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Registrasi Mitra",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: const Color(0xFF111827),
          ),
        ),
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        physics: const BouncingScrollPhysics(),
        onStepTapped: (step) {
          // Allow expanding previously completed steps to view read-only info
          if (step < _currentStep) {
            setState(() => _currentStep = step);
          }
        },
        onStepContinue: () {
          if (_currentStep == 0) {
            // Validasi step 1
            if (nameController.text.isEmpty || ktpFile == null) {
              NyutjiNotif.showError(context, "Nama dan KTP wajib diisi");
              return;
            }
          } else if (_currentStep == 1) {
            // Validasi step 2
            if (phoneController.text.isEmpty || passController.text.isEmpty || businessAddressController.text.isEmpty) {
              NyutjiNotif.showError(context, "Lengkapi data bisnis");
              return;
            }
          } else if (_currentStep == 2) {
            _submitRegistration();
            return;
          }
          setState(() => _currentStep += 1);
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          } else {
            Navigator.pop(context);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: _isLoading && _currentStep == 2
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            _currentStep == 2 ? "KIRIM PENDAFTARAN" : "LANJUT",
                            style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                          ),
                  ),
                ),
                if (_currentStep > 0) const SizedBox(width: 12),
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const StadiumBorder(),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        "KEMBALI",
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF4B5563)),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: Text("Info Pemilik", style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: _currentStep == 0 ? primaryColor : Colors.black87)),
            subtitle: _currentStep > 0
                ? Text("${nameController.text}\nNIK: ${identityController.text}", style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]))
                : null,
            content: _buildGroupContainer(
              children: [
                _buildTextField(nameController, "Nama Sesuai KTP", LucideIcons.user),
                const SizedBox(height: 16),
                _buildTextField(identityController, "Nomor KTP (NIK)", LucideIcons.creditCard, isNumber: true),
                const SizedBox(height: 16),
                _buildTextField(emailController, "Email Pribadi", LucideIcons.mail, isEmail: true),
                const SizedBox(height: 16),
                _buildLocationField(ownerAddressController, "Alamat Sesuai KTP", true),
                const SizedBox(height: 16),
                _buildTextField(ownerDetailController, "Detail Alamat Rumah", LucideIcons.mapPin),
                const SizedBox(height: 16),
                _buildKtpUpload(),
              ],
            ),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: Text("Info Bisnis", style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: _currentStep == 1 ? primaryColor : Colors.black87)),
            subtitle: _currentStep > 1
                ? Text("${businessNameController.text.isNotEmpty ? businessNameController.text : 'Laundry Tanpa Nama'}\n${phoneController.text}", style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]))
                : null,
            content: _buildGroupContainer(
              children: [
                _buildTextField(businessNameController, "Nama Laundry (Opsional)", LucideIcons.store),
                const SizedBox(height: 16),
                _buildLocationField(businessAddressController, "Lokasi Wilayah Operasional", false),
                const SizedBox(height: 16),
                _buildTextField(phoneController, "Nomor Handphone Bisnis", LucideIcons.phone, isNumber: true),
                const SizedBox(height: 16),
                _buildPasswordField(),
              ],
            ),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: Text("Segmen Usaha", style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: _currentStep == 2 ? primaryColor : Colors.black87)),
            content: _buildGroupContainer(
              children: [
                Text("Segmen Usaha", style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey[700])),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildChoiceChip('PRIBADI', 'Pribadi', selectedSegment, (v) => setState(() => selectedSegment = v))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildChoiceChip('BADAN', 'Badan Usaha', selectedSegment, (v) => setState(() => selectedSegment = v))),
                  ],
                ),
                const SizedBox(height: 20),
                Text("Kategori Mitra", style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey[700])),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChoiceChip('KECIL', 'Kecil', selectedCategory, (v) { setState(() => selectedCategory = v); _fetchServices(); }),
                    _buildChoiceChip('MENENGAH', 'Menengah', selectedCategory, (v) { setState(() => selectedCategory = v); _fetchServices(); }),
                    _buildChoiceChip('BESAR', 'Besar', selectedCategory, (v) { setState(() => selectedCategory = v); _fetchServices(); }),
                  ],
                ),
                const SizedBox(height: 20),
                Text("Daftar Layanan Tersedia:", style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 13, color: primaryColor)),
                const SizedBox(height: 8),
                _isLoadingServices
                    ? const Center(child: CircularProgressIndicator(color: primaryColor))
                    : Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          children: dlaundryServices.map((catName) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.checkCircle2, color: primaryColor, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      catName,
                                      style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
              ],
            ),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupContainer({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false, bool isEmail = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : (isEmail ? TextInputType.emailAddress : TextInputType.text),
      style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[400]),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildLocationField(TextEditingController controller, String hint, bool isOwner) {
    return GestureDetector(
      onTap: () => _showLocationPicker(isOwner),
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500),
          maxLines: null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[400]),
            prefixIcon: Icon(LucideIcons.map, size: 20, color: Colors.grey[500]),
            suffixIcon: Icon(LucideIcons.chevronRight, size: 20, color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: passController,
      obscureText: _obscurePassword,
      style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: "Kata Sandi",
        hintStyle: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[400]),
        prefixIcon: Icon(LucideIcons.lock, size: 20, color: Colors.grey[500]),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 20, color: Colors.grey[400]),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildKtpUpload() {
    return GestureDetector(
      onTap: _pickKtp,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: ktpFile != null ? 8 : 24, horizontal: 8),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primaryColor.withValues(alpha: 0.3), style: BorderStyle.solid),
        ),
        child: ktpFile != null
            ? Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(ktpFile!.path), height: 140, width: double.infinity, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.refreshCw, size: 14, color: primaryColor),
                      const SizedBox(width: 6),
                      Text("Ganti Foto KTP", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: primaryColor)),
                    ],
                  ),
                ],
              )
            : Column(
                children: [
                  const Icon(LucideIcons.uploadCloud, size: 32, color: primaryColor),
                  const SizedBox(height: 8),
                  Text(
                    "Unggah Foto KTP",
                    style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: primaryColor),
                  ),
                  Text(
                    "Ambil dari Kamera atau Galeri",
                    style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildChoiceChip(String value, String label, String groupValue, Function(String) onSelected) {
    final isSelected = value == groupValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (b) {
        if (b) onSelected(value);
      },
      labelStyle: GoogleFonts.montserrat(
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : Colors.grey[700],
        fontSize: 13,
      ),
      backgroundColor: Colors.white,
      selectedColor: primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isSelected ? primaryColor : Colors.grey[300]!),
      ),
      showCheckmark: false,
    );
  }
}
