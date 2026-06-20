import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../core/widgets/nyutji_location_picker.dart';
import '../../../core/widgets/nyutji_image_picker.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/services/api_service.dart';

class RegisterMitraScreen extends ConsumerStatefulWidget {
  const RegisterMitraScreen({super.key});

  @override ConsumerState<RegisterMitraScreen> createState() => _RegisterMitraScreenState();
}

class _RegisterMitraScreenState extends ConsumerState<RegisterMitraScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Pink elegant color for Mitra
  static const Color primaryColor = Color(0xFFC3312E);

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
  final FocusNode _phoneFocusNode = FocusNode();
  final TextEditingController passController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();
  final TextEditingController businessAddressController = TextEditingController();
  String businessDistrict = "";
  String businessCity = "";
  double? businessLat;
  double? businessLng;

  // Step 3: Segmen & Kategori
  String selectedSegment = 'PRIBADI';
  String selectedCategory = 'KECIL';
  String selectedOperationalHours = '10 Jam';
  String? selectedWasherBrand;
  final TextEditingController washerTypeController = TextEditingController();
  Map<String, List<dynamic>> groupedServices = {};
  Set<String> checkedCategories = {};
  Set<String> checkedServices = {};
  bool _isLoadingServices = false;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
    _phoneFocusNode.addListener(() {
      if (!_phoneFocusNode.hasFocus && phoneController.text.isNotEmpty) {
        _checkPhoneNumber();
      }
    });
  }

  @override
  void dispose() {
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkPhoneNumber() async {
    final phone = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isEmpty) return;
    try {
      final dio = ApiService().dio;
      final response = await dio.post('${ApiConstants.baseUrl}/check-phone', data: {'phone_number': phone});
      if (response.data['success'] && response.data['exists']) {
        if (!mounted) return;
        NyutjiNotif.showError(context, "Nomor handphone ini sudah terdaftar. Silakan gunakan nomor lain.");
        phoneController.clear();
      }
    } catch (e) {
      debugPrint("Gagal check phone: $e");
    }
  }

  Future<void> _fetchServices() async {
    setState(() => _isLoadingServices = true);
    try {
      final dio = ApiService().dio;
      final response = await dio.get('${ApiConstants.baseUrl}/services/dlaundry', queryParameters: {
        'category': selectedCategory
      });
      if (response.data['success']) {
        if (!mounted) return;
        setState(() {
          final allData = response.data['data'] as List;
          groupedServices.clear();
          checkedCategories.clear();
          checkedServices.clear();
          for (var item in allData) {
            final cat = item['category'].toString();
            if (!groupedServices.containsKey(cat)) {
              groupedServices[cat] = [];
            }
            groupedServices[cat]!.add(item);
          }
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
          businessLat = result.lat;
          businessLng = result.lng;
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
      final dio = ApiService().dio;
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
        'membership_tier': selectedOperationalHours,
        'washer_brand': selectedWasherBrand ?? '',
        'washer_type': washerTypeController.text.trim(),
        'selected_services': checkedServices.toList().join(','),
        'lat': businessLat?.toString() ?? '',
        'lng': businessLng?.toString() ?? '',
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
        final errText = ((e.response?.data is Map ? e.response?.data['message'] : null)?.toString() ?? '') + ((e.response?.data is Map ? e.response?.data['error'] : null)?.toString() ?? '');
        if (errText.toLowerCase().contains('phone_number') || errText.toLowerCase().contains('unique')) {
          errMsg = "Registrasi Gagal: No Handphone sudah digunakan Mitra lain";
        } else {
          errMsg = (e.response?.data is Map ? e.response?.data['message'] : null) ?? (e.response?.data is Map ? e.response?.data['error'] : null) ?? errMsg;
        }
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
      backgroundColor: const Color(0xFFFDF0F0),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top + 20),
                    // Header: Akun Baru Nyutji
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.chevronLeft, color: primaryColor),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          Text(
                            "Akun Baru Nyutji",
                            style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
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
                        border: Border.all(color: primaryColor.withValues(alpha: 0.1), width: 2),
                      ),
                      child: const Icon(LucideIcons.store, size: 50, color: primaryColor),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Registrasi Mitra",
                      style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Bangun bisnis laundry Anda bersama\nNyutji Management",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ];
          },
          body: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFDF0F0),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 8,
                      bottom: MediaQuery.of(context).padding.bottom + 4,
                    ),
                    child: Column(
                      children: [
                        // Horizontal Tabs
                        Row(
                          children: [
                            _buildTabItem("Info Pemilik", 0),
                            _buildTabItem("Info Bisnis", 1),
                            _buildTabItem("Segmen Usaha", 2),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Content
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _buildCurrentStepContent(),
                        ),
                        const SizedBox(height: 32),
                        // Action Buttons
                        Row(
                          children: [
                            if (_currentStep > 0)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() => _currentStep -= 1);
                                    },
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
                              ),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : () {
                                  if (_currentStep == 0) {
                                    if (nameController.text.isEmpty || ktpFile == null) {
                                      NyutjiNotif.showError(context, "Nama dan KTP wajib diisi");
                                      return;
                                    }
                                  } else if (_currentStep == 1) {
                                    if (phoneController.text.isEmpty || passController.text.isEmpty || confirmPassController.text.isEmpty || businessAddressController.text.isEmpty) {
                                      NyutjiNotif.showError(context, "Lengkapi data bisnis");
                                      return;
                                    }
                                    if (passController.text != confirmPassController.text) {
                                      NyutjiNotif.showError(context, "Kata Sandi dan Konfirmasi Kata Sandi tidak cocok");
                                      return;
                                    }
                                  } else if (_currentStep == 2) {
                                    _submitRegistration();
                                    return;
                                  }
                                  setState(() => _currentStep += 1);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: const StadiumBorder(),
                                  elevation: 0,
                                ),
                                child: _isLoading && _currentStep == 2
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text(
                                        _currentStep == 2 ? "DAFTAR" : "LANJUT",
                                        style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildCurrentStepContent() {
    if (_currentStep == 0) {
      return _buildGroupContainer(
        key: const ValueKey(0),
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
      );
    } else if (_currentStep == 1) {
      return _buildGroupContainer(
        key: const ValueKey(1),
        children: [
          _buildTextField(businessNameController, "Nama Laundry", LucideIcons.store),
          const SizedBox(height: 16),
          _buildLocationField(businessAddressController, "Lokasi Wilayah Operasional", false),
          const SizedBox(height: 16),
          _buildTextField(phoneController, "Nomor Handphone Bisnis", LucideIcons.phone, isNumber: true, focusNode: _phoneFocusNode),
          const SizedBox(height: 16),
          _buildPasswordField(passController, "Kata Sandi", _obscurePassword, () => setState(() => _obscurePassword = !_obscurePassword)),
          const SizedBox(height: 16),
          _buildPasswordField(confirmPassController, "Konfirmasi Kata Sandi", _obscureConfirmPassword, () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
          const SizedBox(height: 20),
          Text("Jam Operasional", style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildChoiceChipCenter('10 Jam', '10 Jam', selectedOperationalHours, (v) => setState(() => selectedOperationalHours = v))),
              const SizedBox(width: 8),
              Expanded(child: _buildChoiceChipCenter('12 Jam', '12 Jam', selectedOperationalHours, (v) => setState(() => selectedOperationalHours = v))),
              const SizedBox(width: 8),
              Expanded(child: _buildChoiceChipCenter('24 Jam', '24 Jam', selectedOperationalHours, (v) => setState(() => selectedOperationalHours = v))),
            ],
          ),
        ],
      );
    } else {
      return _buildGroupContainer(
        key: const ValueKey(2),
        children: [
          Text("Segmen Usaha", style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey[700])),
          const SizedBox(height: 8),
          _buildGridChoices([
            _buildChoiceChip('PRIBADI', 'Pribadi', selectedSegment, (v) => setState(() => selectedSegment = v)),
            _buildChoiceChip('BADAN', 'Badan Usaha', selectedSegment, (v) => setState(() => selectedSegment = v)),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              selectedSegment == 'PRIBADI' ? "Bisnis dikelola Perorangan, dikelola mandiri" : "Entitas hukum (PT/CV), operasional tim",
              style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 20),
          Text("Kategori Mitra", style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey[700])),
          const SizedBox(height: 8),
          _buildGridChoices([
            _buildChoiceChip('KECIL', 'Kecil', selectedCategory, (v) { setState(() => selectedCategory = v); _fetchServices(); }),
            _buildChoiceChip('MENENGAH', 'Menengah', selectedCategory, (v) { setState(() => selectedCategory = v); _fetchServices(); }),
            _buildChoiceChip('BESAR', 'Besar', selectedCategory, (v) { setState(() => selectedCategory = v); _fetchServices(); }),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              selectedCategory == 'KECIL' ? "Kapasitas < 50 kg/hari" : selectedCategory == 'MENENGAH' ? "Kapasitas 50-200 kg/hari" : "Kapasitas > 200 kg/hari",
              style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 20),
          Text("Merk dan Type Mesin Cuci", style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey[700])),
          const SizedBox(height: 8),
          _buildGridChoices([
            _buildChoiceChip('Samsung', 'Samsung', selectedWasherBrand ?? '', (v) => setState(() => selectedWasherBrand = v)),
            _buildChoiceChip('LG', 'LG', selectedWasherBrand ?? '', (v) => setState(() => selectedWasherBrand = v)),
            _buildChoiceChip('Sharp', 'Sharp', selectedWasherBrand ?? '', (v) => setState(() => selectedWasherBrand = v)),
            _buildChoiceChip('Electrolux', 'Electrolux', selectedWasherBrand ?? '', (v) => setState(() => selectedWasherBrand = v)),
            _buildChoiceChip('IPSO/Speed Queen', 'IPSO/Speed Queen', selectedWasherBrand ?? '', (v) => setState(() => selectedWasherBrand = v)),
          ]),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildTextField(washerTypeController, "Type Washer", LucideIcons.settings),
            ),
            crossFadeState: selectedWasherBrand != null ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
          const SizedBox(height: 20),
          Text("Daftar Layanan Tersedia:", style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey[700])),
          const SizedBox(height: 8),
          _isLoadingServices
              ? const Center(child: CircularProgressIndicator(color: primaryColor))
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: groupedServices.keys.map((catName) {
                      final isChecked = checkedCategories.contains(catName);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (isChecked) {
                                  checkedCategories.remove(catName);
                                  for (var s in groupedServices[catName]!) {
                                    checkedServices.remove(s['id'].toString());
                                  }
                                } else {
                                  checkedCategories.add(catName);
                                  for (var s in groupedServices[catName]!) {
                                    checkedServices.add(s['id'].toString());
                                  }
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    isChecked ? LucideIcons.checkSquare : LucideIcons.square,
                                    color: isChecked ? primaryColor : Colors.grey[400],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      catName,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 14,
                                        fontWeight: isChecked ? FontWeight.w700 : FontWeight.w500,
                                        color: isChecked ? primaryColor : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    isChecked ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                    color: isChecked ? primaryColor : Colors.grey[400],
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AnimatedCrossFade(
                            firstChild: const SizedBox(width: double.infinity, height: 0),
                            secondChild: Padding(
                              padding: const EdgeInsets.only(left: 32, top: 4, bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: groupedServices[catName]!.map((svc) {
                                  final svcId = svc['id'].toString();
                                  final isSvcChecked = checkedServices.contains(svcId);
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        if (isSvcChecked) {
                                          checkedServices.remove(svcId);
                                        } else {
                                          checkedServices.add(svcId);
                                        }
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isSvcChecked ? LucideIcons.checkSquare : LucideIcons.square,
                                            color: isSvcChecked ? primaryColor : Colors.grey[400],
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              svc['name_service'].toString(),
                                              style: GoogleFonts.montserrat(fontSize: 13, color: isSvcChecked ? primaryColor : Colors.grey[700], fontWeight: isSvcChecked ? FontWeight.w600 : FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            crossFadeState: isChecked ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 200),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ],
      );
    }
  }

  Widget _buildTabItem(String title, int step) {
    final isActive = _currentStep == step;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (step < _currentStep) {
            setState(() => _currentStep = step);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? primaryColor : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? primaryColor : Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupContainer({Key? key, required List<Widget> children}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false, bool isEmail = false, FocusNode? focusNode}) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
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

  Widget _buildPasswordField(TextEditingController controller, String hint, bool isObscure, VoidCallback onToggle) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[400]),
        prefixIcon: Icon(LucideIcons.lock, size: 20, color: Colors.grey[500]),
        suffixIcon: IconButton(
          icon: Icon(isObscure ? LucideIcons.eyeOff : LucideIcons.eye, size: 20, color: Colors.grey[400]),
          onPressed: onToggle,
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

  Widget _buildGridChoices(List<Widget> choices) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: choices.map((c) => SizedBox(width: itemWidth, child: c)).toList(),
        );
      },
    );
  }

  Widget _buildChoiceChip(String value, String label, String groupValue, Function(String) onSelected) {
    final isSelected = value == groupValue;
    return ChoiceChip(
      label: Container(
        width: double.infinity,
        alignment: Alignment.centerLeft,
        child: Text(label),
      ),
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
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSelected ? primaryColor : Colors.grey[300]!),
      ),
    );
  }

  Widget _buildChoiceChipCenter(String value, String label, String groupValue, Function(String) onSelected) {
    final isSelected = value == groupValue;
    return ChoiceChip(
      label: Container(
        width: double.infinity,
        alignment: Alignment.center,
        child: Text(label),
      ),
      selected: isSelected,
      onSelected: (b) {
        if (b) onSelected(value);
      },
      labelStyle: GoogleFonts.montserrat(
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : Colors.grey[700],
        fontSize: 12,
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
