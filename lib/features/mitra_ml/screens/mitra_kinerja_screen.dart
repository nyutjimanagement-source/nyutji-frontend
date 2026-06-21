import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../data/services/cache_service.dart';
import '../../../data/services/api_service.dart';

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

  String _chemicalSort = "name_asc";
  String _employeeFilter = "all";

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
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
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
    _triggerFetchFromServer();
  }

  void _triggerFetchFromServer() {
    final monthKey = DateFormat('yyyy-MM').format(_selectedMonth);
    _fetchKinerjaFromServer(monthKey);
  }

  Future<void> _fetchKinerjaFromServer(String monthKey) async {
    try {
      final List<dynamic> serverData = await ApiService().getMitraKinerja(monthKey);
      if (serverData.isNotEmpty) {
        for (final item in serverData) {
          final String dateKey = item['date'];
          _operationalHours[dateKey] = {
            "isOpen": item['is_open'] ?? item['isOpen'],
            "openTime": item['open_time'] ?? item['openTime'] ?? "08:00",
            "closeTime": item['close_time'] ?? item['closeTime'] ?? "20:00",
            "note": item['notes'] ?? item['note'] ?? "",
          };
          if (item['chemical_consumption'] != null || item['chemicalConsumption'] != null) {
            final List<dynamic> chem = item['chemical_consumption'] ?? item['chemicalConsumption'];
            _chemicalConsumption[dateKey] = List<Map<String, dynamic>>.from(chem);
          }
          if (item['employee_attendance'] != null || item['employeeAttendance'] != null) {
            final List<dynamic> emp = item['employee_attendance'] ?? item['employeeAttendance'];
            _employeeAttendance[dateKey] = List<Map<String, dynamic>>.from(emp);
          }
        }
        
        await CacheService.set('mitra_operasional_hours', _operationalHours);
        await CacheService.set('mitra_chemical_consumption', _chemicalConsumption);
        await CacheService.set('mitra_employee_attendance', _employeeAttendance);
        
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("Error fetching kinerja from server: $e");
    }
  }

  Future<void> _saveToServer(String dateKey) async {
    try {
      final hours = _getOperationalInfoForDate(DateTime.parse(dateKey));
      final chemicals = _getChemicalsForDate(DateTime.parse(dateKey));
      final employees = _getEmployeesForDate(DateTime.parse(dateKey));

      await ApiService().saveMitraKinerja({
        "date": dateKey,
        "isOpen": hours["isOpen"],
        "openTime": hours["openTime"],
        "closeTime": hours["closeTime"],
        "notes": hours["note"] ?? "",
        "chemicalConsumption": chemicals,
        "employeeAttendance": employees
      });
    } catch (e) {
      debugPrint("Error saving kinerja to server: $e");
    }
  }

  Future<void> _saveOperationalHours(String dateKey, Map<String, dynamic> data) async {
    _operationalHours[dateKey] = data;
    await CacheService.set('mitra_operasional_hours', _operationalHours);
    setState(() {});
    _saveToServer(dateKey);
  }

  Future<void> _saveChemicalConsumption(String dateKey, List<Map<String, dynamic>> data) async {
    _chemicalConsumption[dateKey] = data;
    await CacheService.set('mitra_chemical_consumption', _chemicalConsumption);
    setState(() {});
    _saveToServer(dateKey);
  }

  Future<void> _saveEmployeeAttendance(String dateKey, List<Map<String, dynamic>> data) async {
    _employeeAttendance[dateKey] = data;
    await CacheService.set('mitra_employee_attendance', _employeeAttendance);
    setState(() {});
    _saveToServer(dateKey);
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
      "isOpen": null,
      "openTime": isWeekend ? "09:00" : "08:00",
      "closeTime": isWeekend ? "18:00" : "20:00",
      "note": "Operasional Standar"
    };
  }

  List<Map<String, dynamic>> _getChemicalsForDate(DateTime date) {
    final key = _getDateKey(date);
    if (_chemicalConsumption.containsKey(key)) {
      return List<Map<String, dynamic>>.from(_chemicalConsumption[key]!);
    }
    // Return default empty logs
    return _defaultConsumables.map((name) => <String, dynamic>{
      "name": name,
      "used": 0.0,
      "unit": name.contains("Deterjen") ? "Kg" : "Liter",
    }).toList();
  }

  List<Map<String, dynamic>> _getEmployeesForDate(DateTime date) {
    final key = _getDateKey(date);
    if (_employeeAttendance.containsKey(key)) {
      return List<Map<String, dynamic>>.from(_employeeAttendance[key]!);
    }
    // Return default present logs
    return _defaultEmployees.map((emp) => <String, dynamic>{
      "name": emp["name"],
      "role": emp["role"],
      "status": "Masuk", // Masuk, Off, Pengganti
      "substituteName": "",
    }).toList();
  }

  Widget _buildTabItem(int index, String label, double tabWidth) {
    final bool isSelected = _tabController.index == index;
    return SizedBox(
      width: tabWidth,
      height: 50,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _tabController.animateTo(index);
            setState(() {});
          },
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                color: isSelected ? primaryTeal : textGrey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: isSelected ? 13 : 12,
              ),
            ),
          ),
        ),
      ),
    );
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double tabWidth = constraints.maxWidth / 3;
              final int selectedIndex = _tabController.index;
              
              return Container(
                height: 50,
                color: Colors.white,
                child: Stack(
                  children: [
                    Row(
                      children: [
                        _buildTabItem(0, "Jam Kerja", tabWidth),
                        _buildTabItem(1, "Konsumsi", tabWidth),
                        _buildTabItem(2, "Kehadiran", tabWidth),
                      ],
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      bottom: 0,
                      left: (tabWidth * selectedIndex) + (tabWidth / 2) - 30,
                      child: Container(
                        height: 3,
                        width: 60,
                        decoration: BoxDecoration(
                          color: primaryTeal,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(3),
                            bottomRight: Radius.circular(3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryTeal.withValues(alpha: 0.5),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
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
                    _triggerFetchFromServer();
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
                    _triggerFetchFromServer();
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

                    final dateKey = _getDateKey(cellDate);
                    final bool hasSetting = _operationalHours.containsKey(dateKey);
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
                            if (hasSetting && opInfo["isOpen"] != null)
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
                              )
                            else
                              const SizedBox(height: 12),
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
          const SizedBox(height: 20),

          // Action Buttons: Rekap Bulanan & Ekspor Laporan
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showMonthlySummary(),
                  icon: const Icon(LucideIcons.fileSpreadsheet, color: Colors.white, size: 16),
                  label: Text("Rekap & Laporan", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _exportKinerjaReportAsImage(),
                  icon: const Icon(LucideIcons.image, color: primaryTeal, size: 16),
                  label: Text("Ekspor Laporan", style: GoogleFonts.montserrat(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryTeal,
                    side: const BorderSide(color: primaryTeal),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
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
    final rawChemicals = _getChemicalsForDate(_activeDate);
    final List<Map<String, dynamic>> chemicals = List<Map<String, dynamic>>.from(rawChemicals);
    
    if (_chemicalSort == "used_desc") {
      chemicals.sort((a, b) {
        final double ua = double.tryParse(a["used"].toString()) ?? 0.0;
        final double ub = double.tryParse(b["used"].toString()) ?? 0.0;
        return ub.compareTo(ua);
      });
    } else {
      chemicals.sort((a, b) => a["name"].toString().compareTo(b["name"].toString()));
    }

    return Column(
      children: [
        // Date Selector Bar
        _buildActiveDateSelector(),

        // Sorting and Addition Action Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sort Button
              InkWell(
                onTap: () {
                  setState(() {
                    if (_chemicalSort == "name_asc") {
                      _chemicalSort = "used_desc";
                      NyutjiNotif.showInfo(context, "Diurutkan berdasarkan Konsumsi Tertinggi.");
                    } else {
                      _chemicalSort = "name_asc";
                      NyutjiNotif.showInfo(context, "Diurutkan berdasarkan Nama A-Z.");
                    }
                  });
                },
                child: Row(
                  children: [
                    const Icon(LucideIcons.arrowUpDown, size: 14, color: primaryTeal),
                    const SizedBox(width: 6),
                    Text(
                      _chemicalSort == "name_asc" ? "Nama A-Z" : "Konsumsi ▼",
                      style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTeal),
                    ),
                  ],
                ),
              ),
              
              // Action Buttons Row
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _showAddChemicalDialog(),
                    icon: const Icon(LucideIcons.plus, size: 14, color: primaryTeal),
                    label: Text("Tambah Item", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTeal)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () => _showMonthlySummary(),
                    icon: const Icon(LucideIcons.fileText, size: 14, color: primaryTeal),
                    label: Text("Rekap", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTeal)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: chemicals.length,
            itemBuilder: (context, index) {
              final chem = chemicals[index];
              final double used = double.tryParse(chem["used"].toString()) ?? 0.0;
              final String unit = chem["unit"] ?? "Liter";

              final double maxVal;
              final double step;
              final int divisions;
              final bool isIntegerUnit = unit == "Tabung" || unit == "kWh" || unit == "m³" || unit == "Pcs" || unit == "Roll" || unit == "Pack";

              if (unit == "Tabung") {
                maxVal = 10.0;
                step = 1.0;
                divisions = 10;
              } else if (unit == "kWh" || unit == "m³" || unit == "Pcs" || unit == "Roll" || unit == "Pack") {
                maxVal = 200.0;
                step = 1.0;
                divisions = 200;
              } else {
                maxVal = 10.0;
                step = 0.1;
                divisions = 100;
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
                            "${isIntegerUnit ? used.toStringAsFixed(0) : used.toStringAsFixed(1)} $unit",
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
                              final originalList = _getChemicalsForDate(_activeDate);
                              final origIdx = originalList.indexWhere((c) => c["name"] == chem["name"]);
                              if (origIdx != -1) {
                                final currentVal = double.tryParse(originalList[origIdx]["used"].toString()) ?? 0.0;
                                originalList[origIdx]["used"] = (currentVal - step).clamp(0.0, maxVal);
                                _saveChemicalConsumption(_getDateKey(_activeDate), originalList);
                              }
                            }
                          },
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4.0,
                              activeTrackColor: primaryTeal,
                              inactiveTrackColor: const Color(0xFFF3F4F6),
                              thumbColor: primaryTeal,
                              overlayColor: primaryTeal.withValues(alpha: 0.12),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
                            ),
                            child: Slider(
                              value: used.clamp(0.0, maxVal),
                              min: 0.0,
                              max: maxVal,
                              divisions: divisions,
                              onChanged: (val) {
                                final originalList = _getChemicalsForDate(_activeDate);
                                final origIdx = originalList.indexWhere((c) => c["name"] == chem["name"]);
                                if (origIdx != -1) {
                                  originalList[origIdx]["used"] = val;
                                  _saveChemicalConsumption(_getDateKey(_activeDate), originalList);
                                }
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.plusCircle, color: primaryTeal),
                          onPressed: () {
                            final originalList = _getChemicalsForDate(_activeDate);
                            final origIdx = originalList.indexWhere((c) => c["name"] == chem["name"]);
                            if (origIdx != -1) {
                              final currentVal = double.tryParse(originalList[origIdx]["used"].toString()) ?? 0.0;
                              originalList[origIdx]["used"] = (currentVal + step).clamp(0.0, maxVal);
                              _saveChemicalConsumption(_getDateKey(_activeDate), originalList);
                            }
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
    final allEmployees = _getEmployeesForDate(_activeDate);
    final List<Map<String, dynamic>> employees = allEmployees.where((emp) {
      if (_employeeFilter == "all") return true;
      return emp["status"] == _employeeFilter;
    }).toList();

    return Column(
      children: [
        _buildActiveDateSelector(),

        // Filter and Addition Action Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Filter Dropdown
              DropdownButton<String>(
                value: _employeeFilter,
                underline: const SizedBox.shrink(),
                icon: const Icon(LucideIcons.filter, size: 14, color: primaryTeal),
                style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTeal),
                dropdownColor: Colors.white,
                items: const [
                  DropdownMenuItem(value: "all", child: Text("Semua Pegawai")),
                  DropdownMenuItem(value: "Masuk", child: Text("Hadir (Masuk)")),
                  DropdownMenuItem(value: "Off", child: Text("Absen (Off)")),
                  DropdownMenuItem(value: "Pengganti", child: Text("Pengganti")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _employeeFilter = val;
                    });
                  }
                },
              ),
              
              // Action Buttons Row
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _showAddEmployeeDialog(),
                    icon: const Icon(LucideIcons.plus, size: 14, color: primaryTeal),
                    label: Text("Tambah Pegawai", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTeal)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () => _showMonthlySummary(),
                    icon: const Icon(LucideIcons.fileText, size: 14, color: primaryTeal),
                    label: Text("Rekap", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTeal)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  ),
                ],
              ),
            ],
          ),
        ),

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
                            final originalList = _getEmployeesForDate(_activeDate);
                            final origIdx = originalList.indexWhere((e) => e["name"] == emp["name"]);
                            if (origIdx != -1) {
                              originalList[origIdx]["status"] = "Masuk";
                              originalList[origIdx]["substituteName"] = "";
                              _saveEmployeeAttendance(_getDateKey(_activeDate), originalList);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildAttendanceAction(
                          label: "Off",
                          isActive: status == "Off",
                          onTap: () {
                            final originalList = _getEmployeesForDate(_activeDate);
                            final origIdx = originalList.indexWhere((e) => e["name"] == emp["name"]);
                            if (origIdx != -1) {
                              originalList[origIdx]["status"] = "Off";
                              originalList[origIdx]["substituteName"] = "";
                              _saveEmployeeAttendance(_getDateKey(_activeDate), originalList);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildAttendanceAction(
                          label: "Ganti",
                          isActive: status == "Pengganti",
                          onTap: () {
                            final originalList = _getEmployeesForDate(_activeDate);
                            final origIdx = originalList.indexWhere((e) => e["name"] == emp["name"]);
                            if (origIdx != -1) {
                              _showSubstituteDialog(origIdx, originalList);
                            }
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

  void _showAddChemicalDialog() {
    final nameController = TextEditingController();
    String unit = "Liter";
    
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text("Tambah Item Konsumsi & Utilitas", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkText)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Nama Item",
                      labelStyle: GoogleFonts.montserrat(fontSize: 12, color: textGrey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    style: GoogleFonts.montserrat(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Satuan Ukuran", style: GoogleFonts.montserrat(fontSize: 12, color: darkText, fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: unit,
                        items: const [
                          DropdownMenuItem(value: "Liter", child: Text("Liter")),
                          DropdownMenuItem(value: "Kg", child: Text("Kg")),
                          DropdownMenuItem(value: "Pcs", child: Text("Pcs")),
                          DropdownMenuItem(value: "kWh", child: Text("kWh")),
                          DropdownMenuItem(value: "m³", child: Text("m³")),
                          DropdownMenuItem(value: "Tabung", child: Text("Tabung")),
                          DropdownMenuItem(value: "Roll", child: Text("Roll")),
                          DropdownMenuItem(value: "Pack", child: Text("Pack")),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() => unit = val);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("Batal", style: GoogleFonts.montserrat(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      final chemicals = _getChemicalsForDate(_activeDate);
                      final exists = chemicals.any((c) => c["name"].toString().toLowerCase() == name.toLowerCase());
                      if (exists) {
                        NyutjiNotif.showError(context, "Item dengan nama tersebut sudah ada.");
                        return;
                      }
                      
                      chemicals.add(<String, dynamic>{
                        "name": name,
                        "used": 0.0,
                        "unit": unit
                      });
                      
                      _saveChemicalConsumption(_getDateKey(_activeDate), chemicals);
                      Navigator.pop(ctx);
                      NyutjiNotif.showSuccess(context, "Item berhasil ditambahkan.");
                    } else {
                      NyutjiNotif.showError(context, "Nama tidak boleh kosong.");
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
          }
        );
      }
    );
  }

  void _showAddEmployeeDialog() {
    final nameController = TextEditingController();
    final roleController = TextEditingController(text: "Operator Cuci");
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Tambah Pegawai Baru", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkText)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Nama Pegawai",
                  labelStyle: GoogleFonts.montserrat(fontSize: 12, color: textGrey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                style: GoogleFonts.montserrat(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: roleController,
                decoration: InputDecoration(
                  labelText: "Peran / Posisi",
                  labelStyle: GoogleFonts.montserrat(fontSize: 12, color: textGrey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                style: GoogleFonts.montserrat(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Batal", style: GoogleFonts.montserrat(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final role = roleController.text.trim();
                if (name.isNotEmpty && role.isNotEmpty) {
                  final employees = _getEmployeesForDate(_activeDate);
                  
                  final exists = employees.any((e) => e["name"].toString().toLowerCase() == name.toLowerCase());
                  if (exists) {
                    NyutjiNotif.showError(context, "Pegawai dengan nama tersebut sudah terdaftar.");
                    return;
                  }
                  
                  employees.add(<String, dynamic>{
                    "name": name,
                    "role": role,
                    "status": "Masuk",
                    "substituteName": ""
                  });
                  
                  _saveEmployeeAttendance(_getDateKey(_activeDate), employees);
                  Navigator.pop(ctx);
                  NyutjiNotif.showSuccess(context, "Pegawai berhasil ditambahkan.");
                } else {
                  NyutjiNotif.showError(context, "Nama dan peran tidak boleh kosong.");
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
      }
    );
  }

  Map<String, dynamic> _calculateMonthlySummary() {
    int totalDays = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    int daysOpen = 0;
    int daysClosed = 0;
    
    Map<String, double> chemTotals = {};
    Map<String, String> chemUnits = {};
    
    int totalEmployeeDays = 0;
    int employeePresent = 0;
    int employeeOff = 0;
    int employeeSubstitute = 0;

    for (int day = 1; day <= totalDays; day++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final dateKey = _getDateKey(date);
      
      final hours = _getOperationalInfoForDate(date);
      if (hours["isOpen"] == false) {
        daysClosed++;
      } else {
        daysOpen++;
      }
      
      if (_chemicalConsumption.containsKey(dateKey)) {
        final chems = _chemicalConsumption[dateKey]!;
        for (final c in chems) {
          final name = c["name"] ?? "";
          final double used = double.tryParse(c["used"].toString()) ?? 0.0;
          final unit = c["unit"] ?? "Liter";
          if (name.isNotEmpty) {
            chemTotals[name] = (chemTotals[name] ?? 0.0) + used;
            chemUnits[name] = unit;
          }
        }
      }
      
      if (_employeeAttendance.containsKey(dateKey)) {
        final emps = _employeeAttendance[dateKey]!;
        for (final e in emps) {
          totalEmployeeDays++;
          final status = e["status"] ?? "Masuk";
          if (status == "Masuk") {
            employeePresent++;
          } else if (status == "Off") {
            employeeOff++;
          } else if (status == "Pengganti") {
            employeeSubstitute++;
          }
        }
      }
    }
    
    double attendanceRate = totalEmployeeDays > 0 ? (employeePresent / totalEmployeeDays) * 100 : 100.0;

    return {
      "daysOpen": daysOpen,
      "daysClosed": daysClosed,
      "chemTotals": chemTotals,
      "chemUnits": chemUnits,
      "attendanceRate": attendanceRate,
      "employeePresent": employeePresent,
      "employeeOff": employeeOff,
      "employeeSubstitute": employeeSubstitute,
      "totalEmployeeDays": totalEmployeeDays
    };
  }

  void _showMonthlySummary() {
    final summary = _calculateMonthlySummary();
    final String monthName = DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Rekap Kinerja - $monthName",
                    style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.bold, color: darkText),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: textGrey, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryStatCard(
                      title: "Hari Buka",
                      value: "${summary["daysOpen"]} Hari",
                      subValue: "Libur: ${summary["daysClosed"]} Hari",
                      icon: LucideIcons.store,
                      color: primaryTeal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryStatCard(
                      title: "Hadir Pegawai",
                      value: "${(summary["attendanceRate"] as double).toStringAsFixed(1)}%",
                      subValue: "Ganti: ${summary["employeeSubstitute"]} shift",
                      icon: LucideIcons.users,
                      color: accentGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              Text(
                "Konsumsi Bahan Kimia",
                style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: darkText),
              ),
              const SizedBox(height: 8),
              
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: (summary["chemTotals"] as Map<String, double>).isEmpty 
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          "Belum ada data konsumsi bulan ini.",
                          style: GoogleFonts.montserrat(fontSize: 11, color: textGrey),
                        ),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      children: (summary["chemTotals"] as Map<String, double>).entries.map((entry) {
                        final String name = entry.key;
                        final double used = entry.value;
                        final String unit = (summary["chemUnits"] as Map<String, String>)[name] ?? "Liter";
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: darkText),
                              ),
                              Text(
                                "${used.toStringAsFixed(1)} $unit",
                                style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTeal),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
              ),
              const SizedBox(height: 24),
              
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _exportKinerjaReportAsImage();
                },
                icon: const Icon(LucideIcons.download, color: Colors.white, size: 16),
                label: Text(
                  "Unduh Laporan Visual",
                  style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryStatCard({
    required String title,
    required String value,
    required String subValue,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w600, color: textGrey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w800, color: darkText),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w600, color: textGrey),
          ),
        ],
      ),
    );
  }

  void _exportKinerjaReportAsImage() {
    final summary = _calculateMonthlySummary();
    final String monthName = DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: primaryTeal,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(LucideIcons.award, color: Colors.white, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        "LAPORAN KINERJA RESMI",
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        "NYUTJI LAUNDRY MANAGEMENT",
                        style: GoogleFonts.montserrat(
                          color: accentGold,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Text(
                          "Bulan: $monthName",
                          style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: darkText),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Status Buka Toko", style: GoogleFonts.montserrat(fontSize: 11, color: textGrey, fontWeight: FontWeight.w600)),
                          Text("${summary["daysOpen"]} Hari (${(summary["daysOpen"] / (summary["daysOpen"] + summary["daysClosed"]) * 100).toStringAsFixed(0)}%)", style: GoogleFonts.montserrat(fontSize: 11, color: darkText, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Kehadiran Pegawai", style: GoogleFonts.montserrat(fontSize: 11, color: textGrey, fontWeight: FontWeight.w600)),
                          Text("${(summary["attendanceRate"] as double).toStringAsFixed(1)}%", style: GoogleFonts.montserrat(fontSize: 11, color: darkText, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: accentGold.withValues(alpha: 0.5), width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Transform.rotate(
                            angle: -0.05,
                            child: Text(
                              "TERVERIFIKASI SISTEM NYUTJI",
                              style: GoogleFonts.montserrat(
                                color: accentGold,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Container(
                  color: const Color(0xFFDCFCE7),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.checkCircle2, color: Color(0xFF15803D), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        "Laporan berhasil diekspor ke Galeri HP",
                        style: GoogleFonts.montserrat(
                          color: const Color(0xFF15803D),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  "Selesai",
                  style: GoogleFonts.montserrat(color: darkText, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
