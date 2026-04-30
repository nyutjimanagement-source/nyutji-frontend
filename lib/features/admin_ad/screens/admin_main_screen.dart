import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import 'admin_users_screen.dart';
import 'admin_ai_opinion_screen.dart';
import 'admin_issues_screen.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/wallet_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/issue_provider.dart';
import '../../../providers/sentiment_provider.dart';
import '../../../providers/simulasi_provider.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallet();
      context.read<OrderProvider>().fetchOrders();
      context.read<IssueProvider>().fetchIssues();
      context.read<SentimentProvider>().fetchSentiments();
      context.read<AuthProvider>().fetchPendingApprovals(); // Tarik antrean pendaftar
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
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
    return Container(
      color: lightGray,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDenseHeader(),
            _buildSystemStatusStrip(),
            const SizedBox(height: 12),
            _buildDenseSummaryGrid(),
            const SizedBox(height: 16),
            _buildMiniLiveChart(),
            const SizedBox(height: 16),
            _buildTwoColStats(),
            const SizedBox(height: 16),
            _buildCompactActivityLog(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
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
            child: Icon(LucideIcons.globe, size: 140, color: Colors.white.withOpacity(0.05)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: accentGold.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: Icon(LucideIcons.shieldCheck, color: accentGold, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) => Text(
                          auth.user?['name']?.toUpperCase() ?? "GLOBAL COMMAND", 
                          style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)
                        ),
                      ),
                      Text("SuperAdmin • Induk Semang", style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: secondaryDark,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text("SEMUA SISTEM BERJALAN NORMAL", style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.greenAccent, letterSpacing: 0.5)),
            ],
          ),
          Text("Last sync: Just now", style: GoogleFonts.montserrat(fontSize: 9, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildDenseSummaryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Ringkasan Eksekutif", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkGray)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey[300]!)),
                child: Row(
                  children: [
                    Text("Hari Ini", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: primaryTeal)),
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.chevronDown, size: 12),
                  ],
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
              Consumer<SimulasiProvider>(
                builder: (context, sim, _) => _buildKPIBox("Omzet Platform", Formatters.currencyIdr(sim.saldoPlatform), "+12.5%", true),
              ),
              Consumer<OrderProvider>(
                builder: (context, order, _) => _buildKPIBox(
                  "Total Pesanan", 
                  (order.activeOrders.length + order.historyOrders.length).toString(), 
                  "+5.2%", 
                  true,
                  onTap: () => _showOrderListModal(context, order)
                ),
              ),
              _buildKPIBox("User Aktif", "15", "+0%", true),
              _buildKPIBox("Mitra Online", "8", "+0%", true),
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
          Text(title, style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(val, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: darkGray, letterSpacing: -0.5)),
              const Spacer(),
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
          )
        ],
      ),
    ),
    );
  }

  void _showOrderListModal(BuildContext context, OrderProvider orderProv) {
    final allOrders = [...orderProv.activeOrders, ...orderProv.historyOrders];
    allOrders.sort((a, b) {
      double totalA = double.tryParse(a['total']?.toString() ?? '0') ?? 0.0;
      double totalB = double.tryParse(b['total']?.toString() ?? '0') ?? 0.0;
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, spreadRadius: 10)],
            border: Border(top: BorderSide(color: accentGold.withOpacity(0.3), width: 1)),
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
                      decoration: BoxDecoration(color: accentGold.withOpacity(0.15), shape: BoxShape.circle),
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
                            Icon(LucideIcons.inbox, size: 64, color: Colors.white24),
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
                          final id = o['id']?.toString() ?? 'N/A';
                          final total = double.tryParse(o['total']?.toString() ?? '0') ?? 0.0;
                          final mitraId = o['mitra_identifier']?.toString() ?? o['mitra_id']?.toString() ?? '-';
                          final status = o['status']?.toString() ?? 'Pending';

                          // Tentukan warna status
                          Color statusColor = Colors.grey;
                          if (status.toLowerCase().contains('selesai')) statusColor = Colors.greenAccent;
                          else if (status.toLowerCase().contains('batal')) statusColor = Colors.redAccent;
                          else statusColor = Colors.blueAccent;

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: secondaryDark,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Row(
                              children: [
                                // Nominal & ID
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(id, style: GoogleFonts.montserrat(fontSize: 12, color: accentGold, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                                      const SizedBox(height: 4),
                                      Text(Formatters.currencyIdr(total), style: GoogleFonts.montserrat(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                // Mitra ID & Status
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(LucideIcons.store, size: 12, color: Colors.grey[500]),
                                        const SizedBox(width: 4),
                                        Text("ML: $mitraId", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[400], fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: statusColor.withOpacity(0.3)),
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

  Widget _buildMiniLiveChart() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: primaryTeal, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: primaryTeal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Grafik Omzet Real-time", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
                const Icon(LucideIcons.barChart2, size: 14, color: Colors.white),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(20, (index) {
                // Fake histogram values
                final heights = [10, 15, 20, 25, 40, 30, 25, 50, 45, 60, 55, 70, 65, 80, 75, 90, 85, 100, 95, 120];
                return Container(
                  width: 8,
                  height: heights[index] * 0.4,
                  decoration: BoxDecoration(color: index == 19 ? accentGold : Colors.white24, borderRadius: BorderRadius.circular(2)),
                );
              }),
            )
          ],
        ),
      ),
    );
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Log Transaksi Live", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: darkGray)),
                const Icon(LucideIcons.activity, size: 14, color: Colors.blue),
              ],
            ),
            const SizedBox(height: 12),
            _buildLogEntry("Order KBY-0402 Selesai", "Rp 85.000", "Just now", Colors.green),
            _buildLogEntry("Mitra Baru Mendaftar (BDO)", "Verifikasi", "2 mnt lalu", accentGold),
            _buildLogEntry("Penarikan Dana ML-291", "-Rp 1.2M", "5 mnt lalu", accentRed),
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
                    child: Icon(LucideIcons.shieldCheck, size: 140, color: Colors.white.withOpacity(0.05)),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: accentGold.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(LucideIcons.user, size: 32, color: accentGold),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("SuperAdmin Nyutji", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                          Text("ID: AD-CORE-001", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w600)),
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
                  _buildMenuItem(LucideIcons.server, "Database / AWS Server", false),
                  const Divider(height: 1),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) => GestureDetector(
                      onTap: () async {
                        await auth.logout();
                        if (mounted) Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: _buildMenuItem(LucideIcons.logOut, "Tutup Sesi (Logout)", true),
                    ),
                  )
                ],
              ),
            )
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
      decoration: BoxDecoration(color: darkGray, border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05)))),
      child: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(LucideIcons.barChart, size: 18), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.brain, size: 18), label: "AI Opini"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.alertCircle, size: 18), label: "Kendala"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.users, size: 18), label: "Users"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.terminal, size: 18), label: "Sistem"),
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
    );
  }
}
