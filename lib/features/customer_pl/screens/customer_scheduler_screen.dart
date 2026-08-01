import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:intl/intl.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/scheduler_provider.dart';
import '../../../data/services/api_service.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../core/widgets/nyutji_scroll_physics.dart';
import '../../../core/widgets/nyutji_location_picker.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../providers/customer_theme_provider.dart';

class CustomerSchedulerScreen extends ConsumerStatefulWidget {
  const CustomerSchedulerScreen({super.key});

  @override ConsumerState<CustomerSchedulerScreen> createState() => _CustomerSchedulerScreenState();
}

class _CustomerSchedulerScreenState extends ConsumerState<CustomerSchedulerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      final city = auth.user?['city_name'] ?? 'Tangerang Selatan';
      ref.read(schedulerProvider.notifier).fetchSchedules(cityName: city);
    });
  }

  void _showAddScheduleSheet() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController pickupController = TextEditingController();
    final TextEditingController dropController = TextEditingController();

    String selectedInterval = 'Mingguan';
    Map<String, dynamic>? selectedMitra;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedService = 'Antar-Jemput Kurir';
    String selectedPayment = 'Auto Debit';
    bool isDropSameAsPickup = true;

    // Set default pickup/drop from user profile
    final auth = ref.read(authProvider);
    final userAddress = auth.user?['address']?.toString() ?? '';
    pickupController.text = userAddress;
    dropController.text = userAddress;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            final bottomPadding = MediaQuery.of(ctx).viewInsets.bottom;
            
            return Container(
              margin: EdgeInsets.only(top: MediaQuery.of(ctx).padding.top + 40),
              padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPadding + 24),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF9ED),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Buat Jadwal Baru", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF403600))),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(LucideIcons.x, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Nama Jadwal
                          _buildLabel("Nama Jadwal"),
                          _buildTextField(nameController, "Contoh: Cuci Seragam Mingguan", LucideIcons.calendar),
                          
                          const SizedBox(height: 20),
                          
                          // 2. Siklus Jadwal
                          _buildLabel("Siklus Jadwal"),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: ['Mingguan', 'Dwi Mingguan', 'Bulanan'].map((interval) {
                              final isSelected = selectedInterval == interval;
                              return GestureDetector(
                                onTap: () => setModalState(() => selectedInterval = interval),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF403600) : Colors.white,
                                    border: Border.all(color: isSelected ? const Color(0xFF403600) : Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF403600).withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
                                  ),
                                  child: Text(
                                    interval,
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isSelected ? Colors.white : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          
                          const SizedBox(height: 20),

                          // 3. Efektif Jadwal
                          _buildLabel("Mulai Efektif Pada"),
                          GestureDetector(
                            onTap: () async {
                              FocusScope.of(context).unfocus();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFF403600), // header background color
                                        onPrimary: Colors.white, // header text color
                                        onSurface: Colors.black87, // body text color
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setModalState(() => selectedDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.calendarDays, color: Colors.grey, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(selectedDate),
                                    style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF403600)),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 4. Memilih Mitra
                          _buildLabel("Pilih Mitra Laundry"),
                          Autocomplete<Map<String, dynamic>>(
                            optionsBuilder: (TextEditingValue textEditingValue) async {
                              final availableMitras = ref.read(schedulerProvider).availableMitras;
                              if (textEditingValue.text.isEmpty) {
                                return availableMitras;
                              }
                              try {
                                final api = ApiService();
                                final results = await api.searchMitras(textEditingValue.text);
                                return List<Map<String, dynamic>>.from(results);
                              } catch (e) {
                                return availableMitras.where((m) {
                                  final name = (m['name'] ?? m['brand_name'] ?? '').toString().toLowerCase();
                                  return name.contains(textEditingValue.text.toLowerCase());
                                });
                              }
                            },
                            displayStringForOption: (option) => (option['name'] ?? option['brand_name'] ?? '').toString(),
                            onSelected: (option) {
                              setModalState(() {
                                selectedMitra = option;
                              });
                            },
                            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                              return _buildTextField(controller, "Ketik nama mitra...", LucideIcons.store, focusNode: focusNode);
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4.0,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: MediaQuery.of(context).size.width - 48,
                                    constraints: const BoxConstraints(maxHeight: 200),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                                    child: ListView.builder(
                                      padding: const EdgeInsets.all(8),
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: options.length,

                                      itemBuilder: (context, index) {
                                        final option = options.elementAt(index);
                                        return ListTile(
                                          title: Text((option['name'] ?? option['brand_name'] ?? '').toString(), style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold)),
                                          subtitle: Text((option['address'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.montserrat(fontSize: 11)),
                                          onTap: () => onSelected(option),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          // 5. Tipe Layanan
                          _buildLabel("Tipe Layanan"),
                          Row(
                            children: [
                              Expanded(
                                child: _buildRadioOption("Antar-Jemput Kurir", selectedService, (val) => setModalState(() => selectedService = val)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildRadioOption("Antar Sendiri", selectedService, (val) => setModalState(() => selectedService = val)),
                              ),
                            ],
                          ),

                          if (selectedService == 'Antar-Jemput Kurir') ...[
                            const SizedBox(height: 16),
                            _buildLabel("Tempat Pickup"),
                            _buildLocationField(context, pickupController, "Alamat Pickup"),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: isDropSameAsPickup,
                                    onChanged: (val) {
                                      setModalState(() {
                                        isDropSameAsPickup = val ?? true;
                                      });
                                    },
                                    activeColor: const Color(0xFF286B6A),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text("Tempat Drop sama dengan Pickup", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                              ],
                            ),
                            if (!isDropSameAsPickup) ...[
                              const SizedBox(height: 16),
                              _buildLabel("Tempat Drop"),
                              _buildLocationField(context, dropController, "Alamat Drop"),
                            ],
                          ],

                          const SizedBox(height: 20),

                          // 6. Metode Pembayaran
                          _buildLabel("Metode Pembayaran"),
                          Row(
                            children: [
                              Expanded(
                                child: _buildRadioOption("Auto Debit", selectedPayment, (val) => setModalState(() => selectedPayment = val)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildRadioOption("Tagihan", selectedPayment, (val) => setModalState(() => selectedPayment = val)),
                              ),
                            ],
                          ),
                          
                           SizedBox(height: 40 + MediaQuery.of(context).padding.bottom),
                         ],

                      ),
                    ),
                  ),

                  // 7. Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            if (nameController.text.isEmpty) {
                              NyutjiNotif.showError(context, "Nama Jadwal harus diisi");
                              return;
                            }
                            if (selectedService == 'Antar-Jemput Kurir' && isDropSameAsPickup) {
                              dropController.text = pickupController.text;
                            }
                            _saveSchedule({
                              'name': nameController.text,
                              'interval': selectedInterval,
                              'mitra_identifier': selectedMitra?['identifier'] ?? selectedMitra?['id'] ?? '-',
                              'start_date': selectedDate.toIso8601String(),
                              'service_type': selectedService,
                              'payment_method': selectedPayment,
                              'pickup_address': selectedService == 'Antar-Jemput Kurir' ? pickupController.text : '-',
                              'drop_address': selectedService == 'Antar-Jemput Kurir' ? dropController.text : '-',
                              'status': 'DRAFT',
                            });
                            Navigator.pop(ctx);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey[400]!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text("Simpan Draft", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.grey[600])),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (nameController.text.isEmpty) {
                              NyutjiNotif.showError(context, "Nama Jadwal harus diisi");
                              return;
                            }
                            if (selectedMitra == null) {
                              NyutjiNotif.showError(context, "Pilih Mitra terlebih dahulu");
                              return;
                            }
                            if (selectedService == 'Antar-Jemput Kurir' && isDropSameAsPickup) {
                              dropController.text = pickupController.text;
                            }
                            _saveSchedule({
                              'name': nameController.text,
                              'interval': selectedInterval,
                              'mitra_identifier': selectedMitra?['identifier'] ?? selectedMitra?['id'] ?? '-',
                              'start_date': selectedDate.toIso8601String(),
                              'service_type': selectedService,
                              'payment_method': selectedPayment,
                              'pickup_address': selectedService == 'Antar-Jemput Kurir' ? pickupController.text : '-',
                              'drop_address': selectedService == 'Antar-Jemput Kurir' ? dropController.text : '-',
                              'status': 'ACTIVE',
                            });
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF286B6A),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text("Save", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Future<void> _saveSchedule(Map<String, dynamic> data) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: Color(0xFF403600), strokeWidth: 3),
          ),
        ),
      ),
    );


    try {
      await ref.read(schedulerProvider.notifier).createSchedule(data);
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (data['status'] == 'DRAFT') {
          NyutjiNotif.showInfo(context, "Jadwal disimpan sebagai Draft");
        } else {
          NyutjiNotif.showSuccess(context, "Jadwal Otomatis Berhasil Diaktifkan!");
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        NyutjiNotif.showError(context, "Gagal menyimpan jadwal: $e");
      }
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {FocusNode? focusNode}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[400]),
          prefixIcon: Icon(icon, size: 18, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildLocationField(BuildContext context, TextEditingController controller, String hint) {
    return GestureDetector(
      onTap: () async {
        FocusScope.of(context).unfocus();
        final result = await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => const NyutjiLocationPicker(),
        );
        if (result != null) {
          controller.text = result.address;
        }
      },
      child: AbsorbPointer(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
            maxLines: null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[400]),
              prefixIcon: const Icon(LucideIcons.mapPin, size: 18, color: Colors.grey),
              suffixIcon: const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption(String label, String groupValue, Function(String) onChanged) {
    final isSelected = groupValue == label;
    return GestureDetector(
      onTap: () => onChanged(label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF403600).withValues(alpha: 0.05) : Colors.white,
          border: Border.all(color: isSelected ? const Color(0xFF403600) : Colors.grey[300]!, width: isSelected ? 1.5 : 1.0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 16, color: isSelected ? const Color(0xFF403600) : Colors.grey),
            const SizedBox(width: 8),
            Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? const Color(0xFF403600) : Colors.grey[600]))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduler = ref.watch(schedulerProvider);
    final schedules = scheduler.schedules;
    final isLoading = scheduler.isLoading;
    final theme = ref.watch(customerThemeProvider);

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: theme.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text("Jadwal Assistent Nyutji", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final auth = ref.read(authProvider);
          final city = auth.user?['city_name'] ?? 'Tangerang Selatan';
          await ref.read(schedulerProvider.notifier).fetchSchedules(cityName: city);
        },
        color: theme.primary,
        child: isLoading && schedules.isEmpty
            ? _buildShimmerLoading()
            : schedules.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height - 200,
                      child: _buildEmptyState(),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    physics: const AlwaysScrollableScrollPhysics(parent: NyutjiScrollPhysics()),
                    itemCount: schedules.length,
                    itemBuilder: (ctx, idx) => _buildScheduleCard(schedules[idx]),
                  ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScheduleSheet,
        backgroundColor: const Color(0xFF286B6A),
        child: const Icon(LucideIcons.plus, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (ctx, idx) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerLoading(width: 60, height: 20),
                  ShimmerLoading(width: 24, height: 24, borderRadius: 12),
                ],
              ),
              SizedBox(height: 12),
              ShimmerLoading(width: 150, height: 20),
              SizedBox(height: 8),
              ShimmerLoading(width: 100, height: 16),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: ShimmerLoading(height: 50, borderRadius: 12)),
                  SizedBox(width: 12),
                  Expanded(child: ShimmerLoading(height: 50, borderRadius: 12)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF403600).withValues(alpha: 0.05), shape: BoxShape.circle),
              child: const Icon(LucideIcons.calendarClock, size: 60, color: Color(0xFF403600)),
            ),
            const SizedBox(height: 24),
            Text("Belum Ada Jadwal", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF403600))),
            const SizedBox(height: 8),
            Text(
              "Buat jadwal cuci rutin Anda dan biarkan Nyutji yang mengurus sisanya secara otomatis.",
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final bool isActive = schedule['status'] == 'ACTIVE';
    final date = DateTime.tryParse(schedule['start_date']?.toString() ?? '') ?? DateTime.now();
    final mitraName = schedule['mitra'] != null ? (schedule['mitra']['brand_name'] ?? schedule['mitra']['name'] ?? '-') : '-';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3DCCF), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'AKTIF' : 'DRAFT',
                  style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: isActive ? const Color(0xFF10B981) : Colors.grey[600]),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(LucideIcons.moreVertical, size: 20, color: Colors.grey[600]),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) async {
                  if (value == 'edit') {
                    if (mounted) {
                      NyutjiNotif.showInfo(context, "Fitur Edit akan segera hadir!");
                    }
                  } else if (value == 'delete') {
                    try {
                      await ref.read(schedulerProvider.notifier).deleteSchedule(schedule['id'].toString());
                      if (mounted) {
                        NyutjiNotif.showSuccess(context, "Jadwal berhasil dihapus");
                      }
                    } catch (e) {
                      if (mounted) {
                        NyutjiNotif.showError(context, "Gagal menghapus jadwal");
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(LucideIcons.edit2, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text("Edit", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Text("Delete Jadwal", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(schedule['name'] ?? '', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF131109)), maxLines: 1, overflow: TextOverflow.ellipsis),

          const SizedBox(height: 16),
          _buildSimpleRow(LucideIcons.repeat, "Periode Jadwal", schedule['interval'] ?? ''),
          const SizedBox(height: 12),
          _buildSimpleRow(LucideIcons.store, "Mitra Laundry", mitraName),
          const Divider(height: 32, color: Color(0xFFE3DCCF)),
          _buildSimpleRow(LucideIcons.calendar, "Efektif Jadwal", DateFormat('dd MMM yyyy', 'id_ID').format(date)),
          const SizedBox(height: 12),
          _buildSimpleRow(LucideIcons.wallet, "Metode Pembayaran", schedule['payment_method'] ?? ''),
          const Divider(height: 32, color: Color(0xFFE3DCCF)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.truck, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(schedule['service_type'] ?? '', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF403600))),
                    const SizedBox(height: 4),
                    Text(schedule['pickup_address'] ?? '-', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),

                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "$title : $value",
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF403600)),
          ),
        ),
      ],
    );
  }
}
