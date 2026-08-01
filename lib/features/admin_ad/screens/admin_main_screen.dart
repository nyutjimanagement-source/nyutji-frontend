import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'dart:async';
import '../../../data/services/api_service.dart';
import '../../../providers/auth_provider.dart';
import 'admin_users_screen.dart';
import 'admin_ai_opinion_screen.dart';
import 'admin_issues_screen.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/nyutji_scroll_physics.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/wallet_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/issue_provider.dart';
import '../../../providers/sentiment_provider.dart';
// ignore: unused_import
import '../../../providers/simulasi_provider.dart';
import 'admin_revenue_split_screen.dart';

class AdminMainScreen extends ConsumerStatefulWidget {
  const AdminMainScreen({super.key});

  @override ConsumerState<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends ConsumerState<AdminMainScreen> with SingleTickerProviderStateMixin {
  final Color primaryTeal = const Color(0xFF1E5655);
  final Color darkGray = const Color(0xFF111827);
  final Color secondaryDark = const Color(0xFF1F2937); 
  final Color lightGray = const Color(0xFFF3F4F6);
  final Color accentGold = const Color(0xFFF59E0B);
  final Color accentRed = const Color(0xFFEF4444);
  final Color accentBlue = const Color(0xFF3B82F6);

  String selectedPeriod = "Hari Ini";
  int _selectedIndex = 0;
  late PageController _pageController;

  // SYSTEM STATUS LOGIC
  Map<String, dynamic>? _systemStatus;
  final bool _isCheckingStatus = false;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  Timer? _statusTimer;
  String _lastSyncStr = "Just now";

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    
    // Setup Blink Animation
    _blinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _blinkAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(_blinkController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAdminData();
      _fetchSystemStatus();
      // Auto-reload dihapus sesuai Aturan Pelarangan Polling Agresif (Rule 4)
    });
  }

  void _loadAdminData() {
    ref.read(walletProvider).fetchWallet();
    ref.read(orderProvider).fetchAdminOrders();
    ref.read(issueProvider).fetchIssues();
    ref.read(sentimentProvider).fetchSentiments();
    ref.read(authProvider).fetchPendingApprovals();
    ref.read(authProvider).fetchAllUsers(); // Tarik semua user
  }

  Future<void> _fetchSystemStatus() async {
    if (_isCheckingStatus) return;
    try {
      final res = await ApiService().getSystemStatus();
      if (mounted) {
        setState(() {
          _systemStatus = res;
          _lastSyncStr = "Last sync: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}";
        });
      }
    } catch (e) {
      debugPrint("Gagal fetch status sistem: $e");
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _blinkController.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final Map<String, dynamic> t = {
      'id': {
        'logout': 'Keluar Akun',
      },
      'en': {
        'logout': 'Log Out',
      }
    };
    final currentT = t[auth.lang] ?? t['id'];
    
    final List<Widget> tabs = [
      _buildHomeTab(),
      const AdminAiOpinionScreen(),
      const AdminIssuesScreen(),
      const AdminUsersScreen(),
      _buildProfileTab(currentT),
    ];

    return Scaffold(
      backgroundColor: darkGray,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _selectedIndex = index);
                },
                children: tabs,
              ),
            ),
            _buildAdminNavbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    final orderProv = ref.watch(orderProvider);
    final authProv = ref.watch(authProvider);
    final walletProv = ref.watch(walletProvider);
    final allOrders = [...orderProv.activeOrders, ...orderProv.historyOrders];

    return Container(
      color: lightGray,
      child: RefreshIndicator(
        color: primaryTeal,
        onRefresh: () async {
          await Future.wait([
            ref.read(walletProvider).fetchWallet(force: true),
            ref.read(authProvider).fetchPendingApprovals(force: true),
            ref.read(authProvider).fetchAllUsers(force: true),
          ]);
          ref.read(orderProvider).fetchAdminOrders();
          ref.read(issueProvider).fetchIssues();
          ref.read(sentimentProvider).fetchSentiments();
          _fetchSystemStatus();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: NyutjiScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDenseHeader(),
              _buildSystemStatusStrip(),
              const SizedBox(height: 12),
              _buildDenseSummaryGrid(allOrders, authProv, walletProv),
              const SizedBox(height: 16),
              _buildMiniLiveChart(allOrders),
              const SizedBox(height: 16),
              _buildTwoColStats(),
              const SizedBox(height: 16),
              _buildCompactActivityLog(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).padding.bottom;
        return Container(
          padding: EdgeInsets.only(bottom: bottomPadding > 0 ? bottomPadding : 16, top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ["Hari Ini", "Bulanan", "Tahunan"].map((String choice) {
              return ListTile(
                title: Text(choice, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                trailing: selectedPeriod == choice ? const Icon(LucideIcons.check, color: Color(0xFF1E5655)) : null,
                onTap: () {
                  setState(() => selectedPeriod = choice);
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        );
      }
    );
  }

  bool _isDateInPeriod(String? dateStr, String period) {
    if (dateStr == null || dateStr.isEmpty) return false; // Default if no date
    DateTime date;
    try {
      date = DateTime.parse(dateStr).toLocal();
    } catch (e) {
      return false;
    }
    final now = DateTime.now();
    if (period == "Hari Ini") {
      return date.year == now.year && date.month == now.month && date.day == now.day;
    } else if (period == "Bulanan") {
      return date.year == now.year && date.month == now.month;
    } else if (period == "Tahunan") {
      return date.year == now.year;
    }
    return true;
  }

  String? _getDate(dynamic item) {
    return (item['created_at'] ?? item['createdAt'] ?? item['order_date'] ?? item['orderDate'])?.toString();
  }

  double _getPrice(dynamic o) {
    return double.tryParse((o['total_price'] ?? o['totalPrice'] ?? '0').toString()) ?? 0.0;
  }

  Widget _buildDenseHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
      decoration: BoxDecoration(
        color: darkGray,
        gradient: LinearGradient(
          colors: [darkGray, const Color(0xFF1F2937)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -30, top: -20,
            child: Icon(LucideIcons.globe, size: 140, color: Colors.white.withValues(alpha: 0.05)),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width - 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: accentGold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                        child: Icon(LucideIcons.shieldCheck, color: accentGold, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Consumer(
                              builder: (context, ref, _) {
final auth = ref.watch(authProvider);
return Text(
                                auth.user?['name']?.toUpperCase() ?? "GLOBAL COMMAND", 
                                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              );
}),
                            Text("SuperAdmin • Induk Semang", style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis, maxLines: 1),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _buildControlIcon(LucideIcons.search),
                    const SizedBox(width: 10),
                    Stack(
                      children: [
                        _buildControlIcon(LucideIcons.bell),
                        Positioned(right: 0, top: 0, child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: Colors.black, width: 2)))))
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: secondaryDark, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }

  Widget _buildSystemStatusStrip() {
    bool isDbOk = _systemStatus?['database'] == 'Connected';
    bool isSysOk = _systemStatus?['status'] == 'OK';
    
    Color dotColor = Colors.greenAccent;
    String statusText = "SEMUA SISTEM BERJALAN NORMAL";
    
    if (!isDbOk && _systemStatus != null) {
      dotColor = Colors.redAccent;
      statusText = "DATABASE TERPUTUS - PERIKSA SEGERA";
    } else if (!isSysOk && _systemStatus != null) {
      dotColor = Colors.orangeAccent;
      statusText = "GANGGUAN LAYANAN TERDETEKSI";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: secondaryDark,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              FadeTransition(
                opacity: _blinkAnimation,
                child: Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: dotColor.withValues(alpha: 0.5), blurRadius: 4)])),
              ),
              const SizedBox(width: 8),
              Text(statusText, style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, color: dotColor, letterSpacing: 0.5)),
            ],
          ),
          Text(_lastSyncStr, style: GoogleFonts.montserrat(fontSize: 9, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildDenseSummaryGrid(List<dynamic> allOrders, AuthProvider auth, WalletProvider wallet) {
    final filteredOrders = allOrders.where((o) => _isDateInPeriod(_getDate(o), selectedPeriod)).toList();
    final totalOmzet = filteredOrders.fold(0.0, (sum, o) => sum + _getPrice(o));
    
    // Asumsikan data user memiliki created_at, jika tidak kita hitung seluruhnya untuk demo
    final activeUsers = auth.allUsers.where((u) => u['role'] != 'AD');
    final filteredUsers = activeUsers.where((u) => _isDateInPeriod(_getDate(u), selectedPeriod)).toList();
    final totalUsersToDisplay = filteredUsers.isNotEmpty ? filteredUsers.length : activeUsers.length;

    final mitras = auth.allUsers.where((u) => u['role'] == 'ML');
    final filteredMitras = mitras.where((u) => _isDateInPeriod(_getDate(u), selectedPeriod)).toList();
    final totalMitrasToDisplay = filteredMitras.isNotEmpty ? filteredMitras.length : mitras.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Ringkasan Eksekutif", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkGray)),
              GestureDetector(
                onTap: _showFilterSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey[300]!)),
                  child: Row(
                    children: [
                      Text(selectedPeriod, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: primaryTeal)),
                      const SizedBox(width: 4),
                      const Icon(LucideIcons.chevronDown, size: 12),
                    ],
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _buildKPIBox("Omzet Platform", Formatters.currencyIdr(totalOmzet), "+12.5%", true),
              _buildKPIBox(
                "Total Pesanan", 
                filteredOrders.length.toString(), 
                "+5.2%", 
                true,
                onTap: () => _showOrderListModal(context, ref.read(orderProvider))
              ),
              _buildKPIBox(
                "User Aktif", 
                totalUsersToDisplay.toString(), 
                "+${auth.pendingApprovals.length} baru", 
                true,
              ),
              _buildKPIBox("Mitra Online", totalMitrasToDisplay.toString(), "+0%", true),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildKPIBox(String title, String val, String percent, bool isUp, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(color: isUp ? Colors.green[50] : Colors.red[50], borderRadius: BorderRadius.circular(4)),
                  child: Row(
                    children: [
                      Icon(isUp ? LucideIcons.trendingUp : LucideIcons.trendingDown, size: 8, color: isUp ? Colors.green[700] : Colors.red[700]),
                      const SizedBox(width: 2),
                      Text(percent, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.bold, color: isUp ? Colors.green[700] : Colors.red[700])),
                    ],
                  ),
                )
              ],
            ),
            const Spacer(),
            Text(val, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: darkGray, letterSpacing: -0.5), overflow: TextOverflow.ellipsis, maxLines: 1),
          ],
        ),
      ),
    );
  }

  void _showOrderListModal(BuildContext context, OrderProvider orderProv) {
    final allOrders = [...orderProv.activeOrders, ...orderProv.historyOrders];
    allOrders.sort((a, b) {
      final priceA = (a['total_price'] ?? a['totalPrice'] ?? '0').toString();
      final priceB = (b['total_price'] ?? b['totalPrice'] ?? '0').toString();
      double totalA = double.tryParse(priceA) ?? 0.0;
      double totalB = double.tryParse(priceB) ?? 0.0;
      return totalB.compareTo(totalA); // Highest first
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: darkGray,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 10)],
            border: Border(top: BorderSide(color: accentGold.withValues(alpha: 0.3), width: 1)),
          ),
          child: Column(
            children: [
              // Handle Bar
              Container(
                margin: const EdgeInsets.only(top: 16, bottom: 24),
                width: 50,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10)),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: accentGold.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Icon(LucideIcons.listOrdered, color: accentGold, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Rekap Total Pesanan", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text("Diurutkan berdasarkan nominal tertinggi", style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[400])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white10, height: 1),

              // Content List
              Expanded(
                child: allOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.inbox, size: 64, color: Colors.white24),
                            const SizedBox(height: 16),
                            Text(
                              "Nyutji Management - Tidak ada order",
                              style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[400], fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        physics: const BouncingScrollPhysics(),
                        itemCount: allOrders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final o = allOrders[index];
                          // SUPER-SMART MAPPING: Mendukung CamelCase & SnakeCase
                          final orderNo = (o['order_number'] ?? o['orderNumber'] ?? o['identifier'] ?? o['id'] ?? '-').toString();
                          final customerId = (o['customer_id'] ?? o['customerId'] ?? o['customer_identifier'] ?? '-').toString();
                          final mitraId = (o['mitra_id'] ?? o['mitraId'] ?? o['mitra_identifier'] ?? '-').toString();
                          final totalPrice = double.tryParse((o['total_price'] ?? o['totalPrice'] ?? '0').toString()) ?? 0.0;
                          final status = (o['order_status'] ?? o['status'] ?? 'Pending').toString();

                          // Tentukan warna status
                          Color statusColor = Colors.grey;
                          if (status.toLowerCase().contains('selesai')) {
                            statusColor = Colors.greenAccent;
                          } else if (status.toLowerCase().contains('batal')) {
                            statusColor = Colors.redAccent;
                          } else {
                            statusColor = Colors.blueAccent;
                          }

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: secondaryDark,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: Row(
                              children: [
                                // Nominal & ID
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(orderNo, style: GoogleFonts.montserrat(fontSize: 12, color: accentGold, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                                      const SizedBox(height: 4),
                                      Text(Formatters.currencyIdr(totalPrice), style: GoogleFonts.montserrat(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                // Mitra ID & Status
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(LucideIcons.user, size: 10, color: Colors.grey[500]),
                                        const SizedBox(width: 4),
                                        Text("PL: $customerId", style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(LucideIcons.store, size: 10, color: Colors.grey[500]),
                                        const SizedBox(width: 4),
                                        Text("ML: $mitraId", style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.5),
                                      ),
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
          ),
        );
      },
    );
  }

  Widget _buildMiniLiveChart(List<dynamic> allOrders) {
    String chartTitle = "Grafik Omzet Real-time";
    final now = DateTime.now();
    List<double> values = [];
    int expectedLength = 20;

    if (selectedPeriod == "Hari Ini") {
      chartTitle = "Grafik Omzet - Hari Ini";
      expectedLength = 24;
      values = List.filled(24, 0.0);
      final todayOrders = allOrders.where((o) => _isDateInPeriod(_getDate(o), "Hari Ini"));
      for (var o in todayOrders) {
        final d = _parseDate(_getDate(o));
        if (d != null) values[d.hour] += _getPrice(o);
      }
    } else if (selectedPeriod == "Bulanan") {
      final monthNames = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Ags", "Sep", "Okt", "Nov", "Des"];
      chartTitle = "Grafik Omzet - Bulan ${monthNames[now.month - 1]} ${now.year}";
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      expectedLength = daysInMonth;
      values = List.filled(daysInMonth, 0.0);
      final monthOrders = allOrders.where((o) => _isDateInPeriod(_getDate(o), "Bulanan"));
      for (var o in monthOrders) {
        final d = _parseDate(_getDate(o));
        if (d != null) values[d.day - 1] += _getPrice(o);
      }
    } else if (selectedPeriod == "Tahunan") {
      chartTitle = "Grafik Omzet - Tahun ${now.year}";
      expectedLength = 12;
      values = List.filled(12, 0.0);
      final yearOrders = allOrders.where((o) => _isDateInPeriod(_getDate(o), "Tahunan"));
      for (var o in yearOrders) {
        final d = _parseDate(_getDate(o));
        if (d != null) values[d.month - 1] += _getPrice(o);
      }
    }

    double maxVal = values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 0;
    if (maxVal == 0) maxVal = 1; // Prevent division by zero if no orders

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 135,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: primaryTeal, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: primaryTeal.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(chartTitle, style: GoogleFonts.montserrat(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
                const Icon(LucideIcons.barChart2, size: 14, color: Colors.white),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(expectedLength, (index) {
                final heightRatio = values[index] / maxVal;
                final barHeight = heightRatio * 50; // Max height 50
                
                bool isCurrent = false;
                String label = "";
                if (selectedPeriod == "Hari Ini") {
                  isCurrent = index == now.hour;
                  if (index % 4 == 0 || index == 23) label = index.toString().padLeft(2, '0');
                } else if (selectedPeriod == "Bulanan") {
                  isCurrent = index == (now.day - 1);
                  if ((index + 1) % 5 == 0 || index == 0 || index == expectedLength - 1) label = (index + 1).toString();
                } else if (selectedPeriod == "Tahunan") {
                  isCurrent = index == (now.month - 1);
                  const months = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Ags", "Sep", "Okt", "Nov", "Des"];
                  label = months[index];
                }

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        height: barHeight == 0 ? 2 : barHeight,
                        decoration: BoxDecoration(color: isCurrent ? accentGold : Colors.white24, borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: GoogleFonts.montserrat(fontSize: 7, color: Colors.white70, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal),
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }),
            )
          ],
        ),
      ),
    );
  }

  DateTime? _parseDate(String? d) {
    if (d == null) return null;
    try { return DateTime.parse(d).toLocal(); } catch (e) { return null; }
  }

  Widget _buildTwoColStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Col 1: Distribusi Layanan
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Distribusi", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: darkGray)),
                  const SizedBox(height: 12),
                  _buildStatBar("Cuci Komplit", 0.6, primaryTeal),
                  _buildStatBar("Satuan", 0.25, accentBlue),
                  _buildStatBar("Setrika", 0.15, accentGold),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Col 2: Top Regional
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Top Region", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: darkGray)),
                  const SizedBox(height: 12),
                  _buildListRow("1. Jak-Sel", "42%"),
                  _buildListRow("2. Bandung", "28%"),
                  _buildListRow("3. Surabaya", "15%"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBar(String label, double val, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.montserrat(fontSize: 9, color: Colors.grey[600], fontWeight: FontWeight.w600)),
              Text("${(val * 100).toInt()}%", style: GoogleFonts.montserrat(fontSize: 9, color: darkGray, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: val, backgroundColor: Colors.grey[100], valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 4, borderRadius: BorderRadius.circular(2)),
        ],
      ),
    );
  }

  Widget _buildListRow(String title, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          Text(val, style: GoogleFonts.montserrat(fontSize: 10, color: darkGray, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCompactActivityLog() {
    final orderProv = ref.watch(orderProvider);
    final activeOrders = orderProv.activeOrders.where((o) {
      if (o is! Map) return false;
      final status = (o['order_status'] ?? o['status'] ?? '').toString().toLowerCase();
      return status != 'done' &&
          status != 'paid' &&
          status != 'selesai' &&
          status != 'completed' &&
          status != 'batal' &&
          status != 'cancelled' &&
          status != 'draft';
    }).toList();

    // Mapping per identifier ML & KL
    final Map<String, List<dynamic>> mlOrders = {};
    final Map<String, List<dynamic>> klOrders = {};

    for (var raw in activeOrders) {
      if (raw is! Map) continue;
      final o = Map<String, dynamic>.from(raw);

      final String? mlId = (o['mitra_identifier'] ??
              o['mitra_id'] ??
              o['mitraId'] ??
              (o['mitra'] is Map ? o['mitra']['identifier'] : null))
          ?.toString();

      final String? klId = (o['kurir_identifier'] ??
              o['courier_identifier'] ??
              o['kurir_id'] ??
              o['kurirId'] ??
              o['courier_id'] ??
              o['courierId'] ??
              (o['kurir'] is Map ? o['kurir']['identifier'] : (o['courier'] is Map ? o['courier']['identifier'] : null)))
          ?.toString();

      if (mlId != null && mlId.isNotEmpty && mlId != 'null' && mlId != '-') {
        mlOrders.putIfAbsent(mlId, () => []).add(o);
      }
      if (klId != null && klId.isNotEmpty && klId != 'null' && klId != '-') {
        klOrders.putIfAbsent(klId, () => []).add(o);
      }

      if ((mlId == null || mlId.isEmpty || mlId == 'null' || mlId == '-') &&
          (klId == null || klId.isEmpty || klId == 'null' || klId == '-')) {
        final fallbackId = (o['order_number'] ?? o['orderNumber'] ?? o['identifier'] ?? o['id'] ?? 'ML-PML-001').toString();
        if (fallbackId.toUpperCase().startsWith('KL')) {
          klOrders.putIfAbsent(fallbackId, () => []).add(o);
        } else {
          mlOrders.putIfAbsent(fallbackId, () => []).add(o);
        }
      }
    }

    final List<Widget> logItems = [];

    // Order ML (Warna Hijau)
    mlOrders.forEach((ident, orders) {
      final count = orders.length;
      final String msg = count > 1
          ? "Order sedang di $ident $count order"
          : "Order sedang di $ident";
      logItems.add(_buildLogEntry(msg, "Proses", "Live", const Color(0xFF10B981)));
    });

    // Order KL (Warna Orange)
    klOrders.forEach((ident, orders) {
      final count = orders.length;
      final String msg = count > 1
          ? "Order sedang di $ident $count order"
          : "Order sedang di $ident";
      logItems.add(_buildLogEntry(msg, "Antar", "Live", accentGold));
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Log Transaksi Live",
                  style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: darkGray),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "LIVE",
                      style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 6),
                    const Icon(LucideIcons.activity, size: 14, color: Colors.blue),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (logItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Belum ada order berjalan saat ini.",
                  style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[500], fontStyle: FontStyle.italic),
                ),
              )
            else
              ...logItems,
          ],
        ),
      ),
    );
  }

  Widget _buildLogEntry(String msg, String val, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: GoogleFonts.montserrat(fontSize: 10, color: darkGray))),
          Text(val, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 8),
          Text(time, style: GoogleFonts.montserrat(fontSize: 8, color: Colors.grey[400])),
        ],
      ),
    );
  }

  // === DENSE PROFILE TAB ===
  Widget _buildProfileTab(Map<String, dynamic> cT) {
    return Container(
      color: lightGray,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
              decoration: BoxDecoration(
                color: darkGray,
                gradient: LinearGradient(
                  colors: [darkGray, const Color(0xFF1F2937)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: -20, top: -20,
                    child: Icon(LucideIcons.shieldCheck, size: 140, color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: accentGold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(LucideIcons.user, size: 32, color: accentGold),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("SuperAdmin Nyutji", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                          Text("ID: AD-CORE-001", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
              child: Column(
                children: [
                  _buildMenuItem(LucideIcons.settings, "Konfigurasi Sistem Global", false),
                  const Divider(height: 1),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminRevenueSplitScreen()));
                    },
                    child: _buildMenuItem(LucideIcons.splitSquareHorizontal, "Laporan Pembagian Pendapatan", false),
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(LucideIcons.server, "Database / AWS Server", false),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
              child: Consumer(
                builder: (context, ref, _) {
                  final auth = ref.watch(authProvider);
                  return GestureDetector(
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      ref.invalidate(orderProvider);
                      ref.invalidate(walletProvider);
                      await auth.logout();
                      if (!mounted) return;
                      navigator.pushReplacementNamed('/login');
                    },
                    child: _buildMenuItem(LucideIcons.logOut, "Logout", true),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, bool isDanger) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDanger ? accentRed : darkGray),
          const SizedBox(width: 12),
          Text(title, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: isDanger ? accentRed : darkGray)),
          const Spacer(),
          Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }

  // === BOTTOM NAV ===
  Widget _buildAdminNavbar() {
    return Container(
      decoration: BoxDecoration(color: darkGray, border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 5;
          return Stack(
            children: [
              BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(icon: Icon(LucideIcons.barChart, size: 18), activeIcon: Icon(LucideIcons.barChart, size: 18), label: "Beranda"),
                  BottomNavigationBarItem(icon: Icon(LucideIcons.brain, size: 18), activeIcon: Icon(LucideIcons.brain, size: 18), label: "AI Opini"),
                  BottomNavigationBarItem(icon: Icon(LucideIcons.alertCircle, size: 18), activeIcon: Icon(LucideIcons.alertCircle, size: 18), label: "Kendala"),
                  BottomNavigationBarItem(icon: Icon(LucideIcons.users, size: 18), activeIcon: Icon(LucideIcons.users, size: 18), label: "Users"),
                  BottomNavigationBarItem(icon: Icon(LucideIcons.terminal, size: 18), activeIcon: Icon(LucideIcons.terminal, size: 18), label: "Sistem"),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: accentGold,
                unselectedItemColor: Colors.grey[500],
                showUnselectedLabels: true,
                onTap: (index) {
                  _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                },
                backgroundColor: darkGray,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 10),
                unselectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 9),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: 0,
                left: (tabWidth * _selectedIndex) + (tabWidth / 2) - 30,
                child: Container(
                  height: 3,
                  width: 60,
                  decoration: BoxDecoration(
                    color: accentGold,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(3),
                      bottomRight: Radius.circular(3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentGold.withValues(alpha: 0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      )
                    ]
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}
