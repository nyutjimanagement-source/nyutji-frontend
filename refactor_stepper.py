import re
import sys

with open(r'c:\0905NyutjiDev\frontend\lib\features\auth\screens\register_mitra_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Define the new Tab structure
new_structure = """              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
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
                    const SizedBox(height: 40),
                  ],
                ),
              ),"""

start_idx = content.find('child: Stepper(')
if start_idx == -1:
    print("Stepper not found")
    sys.exit(1)

end_idx = content.find('isActive: _currentStep >= 2,', start_idx)
end_idx = content.find('),', end_idx) # end of Step
end_idx = content.find('],', end_idx) # end of steps array
end_idx = content.find('),', end_idx) + 2 # end of Stepper

new_content = content[:start_idx] + new_structure + content[end_idx:]

old_group = """  Widget _buildGroupContainer({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),"""

new_group = """  Widget _buildGroupContainer({Key? key, required List<Widget> children}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),"""

new_content = new_content.replace(old_group, new_group)

build_end = new_content.find('  Widget _buildGroupContainer')

extra_methods = """  Widget _buildCurrentStepContent() {
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
          _buildTextField(phoneController, "Nomor Handphone Bisnis", LucideIcons.phone, isNumber: true),
          const SizedBox(height: 16),
          _buildPasswordField(passController, "Kata Sandi", _obscurePassword, () => setState(() => _obscurePassword = !_obscurePassword)),
          const SizedBox(height: 16),
          _buildPasswordField(confirmPassController, "Konfirmasi Kata Sandi", _obscureConfirmPassword, () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
        ],
      );
    } else {
      return _buildGroupContainer(
        key: const ValueKey(2),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChoiceChip('KECIL', 'Kecil', selectedCategory, (v) { setState(() => selectedCategory = v); _fetchServices(); }),
              _buildChoiceChip('MENENGAH', 'Menengah', selectedCategory, (v) { setState(() => selectedCategory = v); _fetchServices(); }),
              _buildChoiceChip('BESAR', 'Besar', selectedCategory, (v) { setState(() => selectedCategory = v); _fetchServices(); }),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              selectedCategory == 'KECIL' ? "Kapasitas < 50 kg/hari" : selectedCategory == 'MENENGAH' ? "Kapasitas 50-200 kg/hari" : "Kapasitas > 200 kg/hari",
              style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 20),
          Text("Daftar Layanan Tersedia:", style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 13, color: primaryColor)),
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

"""
new_content = new_content[:build_end] + extra_methods + new_content[build_end:]

with open(r'c:\0905NyutjiDev\frontend\lib\features\auth\screens\register_mitra_screen.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)

print("Refactor completed successfully!")
