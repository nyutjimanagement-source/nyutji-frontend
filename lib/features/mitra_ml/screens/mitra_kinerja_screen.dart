import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../data/services/cache_service.dart';

class MitraKinerjaScreen extends ConsumerStatefulWidget {
  const MitraKinerjaScreen({super.key});

  @override
  ConsumerState<MitraKinerjaScreen> createState() => _MitraKinerjaScreenState();
}

class _MitraKinerjaScreenState extends ConsumerState<MitraKinerjaScreen> with SingleTickerProviderStateMixin {
  static const Color primaryTeal = Color(0xFF1E5655);
  static const Color accentGold = Color(0xFFD69E2E);
  static const Color darkText = Color(0xFF111827);
  static const Color textGrey = Color(0xFF6B7280);

  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  DateTime _activeDate = DateTime.now();

  // State caches
  Map<String, Map<String, dynamic>> _operationalHours = {};
  Map<String, List<Map<String, dynamic>>> _chemicalConsumption = {};
  Map<String, List<Map<String, dynamic>>> _employeeAttendance = {};

  final List<String> _defaultConsumables = [
    "Deterjen Cair Matic",
    "Softener Sakura Premium",
    "Parfum Laundry Blue Ocean",
    "Pemutih Pakaian (Bleach)",
    "Pembersih Noda Darah/Minyak",
  ];

  final List<Map<String, dynamic>> _defaultEmployees = [
    {"name": "Andi Wijaya", "role": "Operator Cuci"},
    {"name": "Siti Rahma", "role": "Finishing & Packing"},
    {"name": "Rian Hidayat", "role": "Kurir Outlet"},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllKinerjaData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- LOCAL CACHE OPERATIONS ---
  void _loadAllKinerjaData() {
    // 1. Load Operational Hours
    final hoursCache = CacheService.get('mitra_operasional_hours');
    if (hoursCache != null && hoursCache is Map) {
      _operationalHours = Map<String, Map<String, dynamic>>.from(
        hoursCache.map((key, value) => MapEntry(key.toString(), Map<String, dynamic>.from(value))),
      );
    }

    // 2. Load Consumables
    final chemCache = CacheService.get('mitra_chemical_consumption');
    if (chemCache != null && chemCache is Map) {
      _chemicalConsumption = Map<String, List<Map<String, dynamic>>>.from(
        chemCache.map((key, value) => MapEntry(key.toString(), List<Map<String, dynamic>>.from(value))),
      );
    }

    // 3. Load Employee Attendance
    final empCache = CacheService.get('mitra_employee_attendance');
    if (empCache != null && empCache is Map) {
      _employeeAttendance = Map<String, List<Map<String, dynamic>>>.from(
        empCache.map((key, value) => MapEntry(key.toString(), List<Map<String, dynamic>>.from(value))),
      );
    }

    setState(() {});
  }

  Future<void> _saveOperationalHours(String dateKey, Map<String, dynamic> data) async {
    _operationalHours[dateKey] = data;
    await CacheService.set('mitra_operasional_hours', _operationalHours);
    setState(() {});
  }

  Future<void> _saveChemicalConsumption(String dateKey, List<Map<String, dynamic>> data) async {
    _chemicalConsumption[dateKey] = data;
    await CacheService.set('mitra_chemical_consumption', _chemicalConsumption);
    setState(() {});
  }

  Future<void> _saveEmployeeAttendance(String dateKey, List<Map<String, dynamic>> data) async {
    _employeeAttendance[dateKey] = data;
    await CacheService.set('mitra_employee_attendance', _employeeAttendance);
    setState(() {});
  }

  // --- HELPERS ---
  String _getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Map<String, dynamic> _getOperationalInfoForDate(DateTime date) {
    final key = _getDateKey(date);
    if (_operationalHours.containsKey(key)) {
      return _operationalHours[key]!;
    }
    // Default hours depending on weekday (Sunday = 7)
    final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    return {
      "isOpen": true,
      "openTime": isWeekend ? "09:00" : "08:00",
      "closeTime": isWeekend ? "18:00" : "20:00",
      "note": "Operasional Standar"
    };
  }

  List<Map<String, dynamic>> _getChemicalsForDate(DateTime date) {
    final key = _getDateKey(date);
    if (_chemicalConsumption.containsKey(key)) {
      return _chemicalConsumption[key]!;
    }
    // Return default empty logs
    return _defaultConsumables.map((name) => {
      "name": name,
      "used": 0.0,
      "unit": name.contains("Deterjen") ? "Kg" : "Liter",
    }).toList();
  }

  List<Map<String, dynamic>> _getEmployeesForDate(DateTime date) {
    final key = _getDateKey(date);
    if (_employeeAttendance.containsKey(key)) {
      return _employeeAttendance[key]!;
    }
    // Return default present logs
    return _defaultEmployees.map((emp) => {
      "name": emp["name"],
      "role": emp["role"],
      "status": "Masuk", // Masuk, Off, Pengganti
      "substituteName": "",
    }).toList();
  }

  // --- WIDGET BUILDERS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: primaryTeal,
        title: Text(
          "Kinerja Operasional",
          style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: primaryTeal,
              labelColor: primaryTeal,
              unselectedLabelColor: textGrey,
              labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 12),
              tabs: const [
                Tab(text: "Jam Kerja"),
                Tab(text: "Konsumsi"),
                Tab(text: "Kehadiran"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildJamKerjaTab(),
          _buildKonsumsiTab(),
          _buildKehadiranTab(),
        ],
      ),
    );
  }

  // === 1. TAB JAM OPERASIONAL (CALENDAR VIEW) ===
  Widget _buildJamKerjaTab() {
    final int year = _selectedMonth.year;
    final int month = _selectedMonth.month;

    // Calendar details
    final DateTime firstDayOfMonth = DateTime(year, month, 1);
    final int startWeekday = firstDayOfMonth.weekday; // 1=Mon, 7=Sun
    final int offset = (startWeekday == 7) ? 0 : startWeekday; 
    final int daysInMonth = DateUtils.getDaysInMonth(year, month);

    final List<String> weekdays = ["Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Month Selector Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.chevronLeft, color: primaryTeal),
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                    });
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth),
                  style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.bold, color: darkText),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.chevronRight, color: primaryTeal),
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Calendar Grid Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 8))
              ],
            ),
            child: Column(
              children: [
                // Weekday Header
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: 7,
                  itemBuilder: (context, idx) {
                    final isSunday = idx == 0;
                    return Center(
                      child: Text(
                        weekdays[idx],
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSunday ? const Color(0xFFC3312E) : textGrey,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 16),

                // Days Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: offset + daysInMonth,
                  itemBuilder: (context, index) {
                    if (index < offset) {
                      return const SizedBox.shrink();
                    }

                    final int day = index - offset + 1;
                    final DateTime cellDate = DateTime(year, month, day);
                    final isToday = cellDate.year == DateTime.now().year &&
                        cellDate.month == DateTime.now().month &&
                        cellDate.day == DateTime.now().day;

                    final opInfo = _getOperationalInfoForDate(cellDate);
                    final bool isOpen = opInfo["isOpen"] ?? true;

                    return GestureDetector(
                      onTap: () => _showJamKerjaDialog(cellDate, opInfo),
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isToday ? primaryTeal.withValues(alpha: 0.08) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isToday ? primaryTeal : Colors.grey[100]!,
                            width: isToday ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              day.toString(),
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isToday ? primaryTeal : darkText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: isOpen ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isOpen ? "Buka" : "Tutup",
                                style: GoogleFonts.montserrat(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: isOpen ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Operational Notes Info Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.info, color: primaryTeal, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "Keterangan Jam Kerja",
                      style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: darkText),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Sentuh pada sel tanggal untuk mengubah status operasional (buka/tutup) atau menyesuaikan jam kerja pada hari tersebut.",
                  style: GoogleFonts.montserrat(fontSize: 11, color: textGrey, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dialog untuk Input Jam Kerja Harian
  void _showJamKerjaDialog(DateTime date, Map<String, dynamic> info) {
    bool isOpen = info["isOpen"] ?? true;
    String openTime = info["openTime"] ?? "08:00";
    String closeTime = info["closeTime"] ?? "20:00";
    final noteController = TextEditingController(text: info["note"] ?? "");

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Column(
                children: [
                  const Icon(LucideIcons.calendarRange, color: primaryTeal, size: 36),
                  const SizedBox(height: 10),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: darkText),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Toko Buka / Libur Switcher
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Status Operasional",
                          style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: darkText),
                        ),
                        Switch(
                          value: isOpen,
                          activeThumbColor: primaryTeal,
                          onChanged: (val) {
                            setStateDialog(() => isOpen = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (isOpen) ...[
                      // Jam Buka Picker
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(LucideIcons.clock, color: primaryTeal, size: 20),
                        title: Text("Jam Buka", style: GoogleFonts.montserrat(fontSize: 12, color: textGrey)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            openTime,
                            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: darkText),
                          ),
                        ),
                        onTap: () async {
                          final tod = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: int.parse(openTime.split(':')[0]),
                              minute: int.parse(openTime.split(':')[1]),
                            ),
                          );
                          if (tod != null) {
                            setStateDialog(() {
                              openTime = "${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}";
                            });
                          }
                        },
                      ),

                      // Jam Tutup Picker
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(LucideIcons.clock, color: primaryTeal, size: 20),
                        title: Text("Jam Tutup", style: GoogleFonts.montserrat(fontSize: 12, color: textGrey)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            closeTime,
                            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: darkText),
                          ),
                        ),
                        onTap: () async {
                          final tod = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: int.parse(closeTime.split(':')[0]),
                              minute: int.parse(closeTime.split(':')[1]),
                            ),
                          );
                          if (tod != null) {
                            setStateDialog(() {
                              closeTime = "${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}";
                            });
                          }
                        },
                      ),
                    ],

                    const SizedBox(height: 12),
                    // Catatan
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: "Catatan Harian",
                        labelStyle: GoogleFonts.montserrat(fontSize: 11, color: textGrey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      style: GoogleFonts.montserrat(fontSize: 12),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("Batal", style: GoogleFonts.montserrat(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final dateKey = _getDateKey(date);
                    _saveOperationalHours(dateKey, {
                      "isOpen": isOpen,
                      "openTime": openTime,
                      "closeTime": closeTime,
                      "note": noteController.text.trim(),
                    });
                    Navigator.pop(ctx);
                    NyutjiNotif.showSuccess(context, "Jam operasional berhasil disimpan.");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text("Simpan", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // === 2. TAB KONSUMSI OPERASIONAL ===
  Widget _buildKonsumsiTab() {
    final chemicals = _getChemicalsForDate(_activeDate);

    return Column(
      children: [
        // Date Selector Bar
        _buildActiveDateSelector(),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: chemicals.length,
            itemBuilder: (context, index) {
              final chem = chemicals[index];
              final double used = double.tryParse(chem["used"].toString()) ?? 0.0;
              final String unit = chem["unit"] ?? "Liter";

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            chem["name"],
                            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: darkText),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryTeal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${used.toStringAsFixed(1)} $unit",
                            style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: primaryTeal),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.minusCircle, color: textGrey),
                          onPressed: () {
                            if (used > 0) {
                              chemicals[index]["used"] = used - 0.1;
                              _saveChemicalConsumption(_getDateKey(_activeDate), chemicals);
                            }
                          },
                        ),
                        Expanded(
                          child: Slider(
                            value: used.clamp(0.0, 10.0),
                            min: 0.0,
                            max: 10.0,
                            divisions: 100,
                            activeColor: primaryTeal,
                            inactiveColor: Colors.grey[100],
                            onChanged: (val) {
                              chemicals[index]["used"] = val;
                              _saveChemicalConsumption(_getDateKey(_activeDate), chemicals);
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.plusCircle, color: primaryTeal),
                          onPressed: () {
                            chemicals[index]["used"] = used + 0.1;
                            _saveChemicalConsumption(_getDateKey(_activeDate), chemicals);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // === 3. TAB KEHADIRAN PEGAWAI ===
  Widget _buildKehadiranTab() {
    final employees = _getEmployeesForDate(_activeDate);

    return Column(
      children: [
        _buildActiveDateSelector(),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final emp = employees[index];
              final String status = emp["status"] ?? "Masuk";
              final String subName = emp["substituteName"] ?? "";

              Color badgeColor = const Color(0xFFDCFCE7);
              Color textColor = const Color(0xFF15803D);

              if (status == "Off") {
                badgeColor = const Color(0xFFFEE2E2);
                textColor = const Color(0xFFB91C1C);
              } else if (status == "Pengganti") {
                badgeColor = const Color(0xFFFEF3C7);
                textColor = const Color(0xFFD97706);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.user, color: textGrey, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                emp["name"],
                                style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: darkText),
                              ),
                              Text(
                                emp["role"],
                                style: GoogleFonts.montserrat(fontSize: 10, color: textGrey),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: textColor),
                          ),
                        ),
                      ],
                    ),
                    if (status == "Pengganti" && subName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        "Pengganti: $subName",
                        style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: accentGold),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Action Buttons to change status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildAttendanceAction(
                          label: "Masuk",
                          isActive: status == "Masuk",
                          onTap: () {
                            employees[index]["status"] = "Masuk";
                            employees[index]["substituteName"] = "";
                            _saveEmployeeAttendance(_getDateKey(_activeDate), employees);
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildAttendanceAction(
                          label: "Off",
                          isActive: status == "Off",
                          onTap: () {
                            employees[index]["status"] = "Off";
                            employees[index]["substituteName"] = "";
                            _saveEmployeeAttendance(_getDateKey(_activeDate), employees);
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildAttendanceAction(
                          label: "Ganti",
                          isActive: status == "Pengganti",
                          onTap: () => _showSubstituteDialog(index, employees),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceAction({required String label, required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? primaryTeal : Colors.transparent,
          border: Border.all(color: isActive ? primaryTeal : Colors.grey[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : textGrey,
          ),
        ),
      ),
    );
  }

  void _showSubstituteDialog(int index, List<Map<String, dynamic>> employees) {
    final controller = TextEditingController(text: employees[index]["substituteName"] ?? "");
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Masukkan Nama Pengganti",
            style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkText),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: "Nama Pegawai Pengganti",
              labelStyle: GoogleFonts.montserrat(fontSize: 11, color: textGrey),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            style: GoogleFonts.montserrat(fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Batal", style: GoogleFonts.montserrat(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  employees[index]["status"] = "Pengganti";
                  employees[index]["substituteName"] = name;
                  _saveEmployeeAttendance(_getDateKey(_activeDate), employees);
                  Navigator.pop(ctx);
                  NyutjiNotif.showSuccess(context, "Status kehadiran berhasil diubah.");
                } else {
                  NyutjiNotif.showError(context, "Nama pengganti tidak boleh kosong.");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Simpan", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // === GENERAL DATE SELECTOR WIDGET FOR TAB 2 & 3 ===
  Widget _buildActiveDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: primaryTeal, size: 20),
            onPressed: () {
              setState(() {
                _activeDate = _activeDate.subtract(const Duration(days: 1));
              });
            },
          ),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _activeDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() {
                  _activeDate = picked;
                });
              }
            },
            child: Row(
              children: [
                const Icon(LucideIcons.calendar, color: primaryTeal, size: 18),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, d MMM yyyy', 'id_ID').format(_activeDate),
                  style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: darkText),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.chevronRight, color: primaryTeal, size: 20),
            onPressed: () {
              setState(() {
                _activeDate = _activeDate.add(const Duration(days: 1));
              });
            },
          ),
        ],
      ),
    );
  }
}
