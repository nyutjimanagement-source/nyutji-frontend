import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'courier_history_screen.dart';
import 'courier_wallet_screen.dart';
import 'courier_profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/wallet_provider.dart';
import '../../../providers/order_provider.dart';

// --- MODELS ---
enum CourierTaskType { pickup, delivery }
enum CourierTaskStatus { assigned, onTheWay, arrived, completed }

class CourierTask {
  final String id;
  final String customerName;
  final String address;
  final CourierTaskType type;
  final String serviceName;
  final bool isUrgent;
  final int price; 
  CourierTaskStatus status;

  CourierTask({
    required this.id,
    required this.customerName,
    required this.address,
    required this.type,
    required this.serviceName,
    required this.isUrgent,
    required this.price,
    this.status = CourierTaskStatus.assigned,
  });
}

// --- SCREEN ---
class CourierMainScreen extends StatefulWidget {
  const CourierMainScreen({Key? key}) : super(key: key);

  @override
  State<CourierMainScreen> createState() => _CourierMainScreenState();
}

class _CourierMainScreenState extends State<CourierMainScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _taskSectionKey = GlobalKey(); 
  bool isOnline = true;
  int _selectedNavIndex = 0;
  int _notificationCount = 3;

  // Enterprise/Super-App Colors for Courier
  final Color primaryTeal = const Color(0xFF286B6A);
  final Color accentGreen = const Color(0xFF10B981);
  final Color bgColor = const Color(0xFFF3F4F6); // Cooler gray-white
  final Color darkText = const Color(0xFF111827);
  final Color textGrey = const Color(0xFF6B7280);

  List<CourierTask> tasks = [
    CourierTask(
      id: "KBY-09042026-001",
      customerName: "Budi Santoso",
      address: "Jl. Melati No. 12, Kebayoran Baru",
      type: CourierTaskType.pickup,
      serviceName: "Cuci Komplit",
      isUrgent: true,
      price: 45000,
    ),
    CourierTask(
      id: "SMN-09042026-002",
      customerName: "Siti Aminah",
      address: "Apartemen Semanggi Tower A-12",
      type: CourierTaskType.pickup,
      serviceName: "Setrika Saja",
      isUrgent: false,
      price: 25000,
    ),
    CourierTask(
      id: "SUD-09042026-003",
      customerName: "Robert Downey",
      address: "Jl. Sudirman Kav 52, Jakarta",
      type: CourierTaskType.delivery,
      serviceName: "Cuci Satuan",
      isUrgent: false,
      price: 120000,
    ),
    CourierTask(
      id: "TSR-09042026-004",
      customerName: "Tony Stark",
      address: "Avengers Tower, Tanah Sereal",
      type: CourierTaskType.delivery,
      serviceName: "Cuci Premium",
      isUrgent: true,
      price: 250000,
    ),
  ];

  final Map<String, dynamic> t = {
    'id': {
      'welcome': 'Shift Aktif',
      'status_online': 'Online',
      'status_offline': 'Offline',
      'go': 'Telp',
      'update': 'Selesai',
      'home': 'Tugas',
      'history': 'Histori',
      'wallet': 'Dompet',
      'profile': 'Profile',
      'current_tasks': 'ANTREAN TUGAS',
      'acc_settings': 'Pengaturan Akun',
      'logout_text': 'Keluar Server',
    },
    'en': {
      'welcome': 'Active Shift',
      'status_online': 'Online',
      'status_offline': 'Offline',
      'go': 'Call',
      'update': 'Finish',
      'home': 'Tasks',
      'history': 'History',
      'wallet': 'Wallet',
      'profile': 'System',
      'current_tasks': 'TASK QUEUE',
      'acc_settings': 'Account Settings',
      'logout_text': 'Disconnect',
    }
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallet();
      context.read<OrderProvider>().fetchOrders();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTasks() {
    final context = _taskSectionKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOutQuart,
      );
    }
  }

  Future<void> _openMap(String address) async {
    final query = Uri.encodeComponent(address);
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentT = t[auth.lang] ?? t['id'];

    final List<Widget> tabs = [
      _buildHomeTab(currentT),
      const CourierHistoryScreen(),
      const CourierWalletScreen(),
      const CourierProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildDynamicHeader(currentT),
            const SizedBox(height: 8),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) => setState(() => _selectedNavIndex = index),
                children: tabs,
              ),
            ),
            _buildBottomNav(currentT),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicHeader(Map<String, dynamic> currentT) {
    if (_selectedNavIndex == 0) {
      return Column(
        children: [
            _buildCompactHeader(currentT),
            const SizedBox(height: 12),
            _buildActiveTrackingStrip(),
            const SizedBox(height: 16),
            _buildCompactStatsPanel(),
            const SizedBox(height: 16),
        ],
      );
    } else if (_selectedNavIndex == 1) {
      return _buildPageTitleHeader("Riwayat Tugas", LucideIcons.history);
    } else if (_selectedNavIndex == 2) {
      return _buildPageTitleHeader("Dompet Kurir", LucideIcons.wallet);
    } else {
      return _buildPageTitleHeader("Profil Kurir", LucideIcons.user);
    }
  }

  Widget _buildPageTitleHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: primaryTeal, size: 18),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: darkText, letterSpacing: 0.2),
              ),
              Text(
                "Abang Kurir Jago",
                style: GoogleFonts.montserrat(fontSize: 10, color: textGrey, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: Icon(LucideIcons.bell, color: textGrey, size: 20),
          )
        ],
      ),
    );
  }

  // === HOME TAB (DENSE) ===
  Widget _buildHomeTab(Map<String, dynamic> currentT) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildDenseTaskSection(currentT),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCompactHeader(Map<String, dynamic> currentT) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, 
                  border: Border.all(color: Colors.grey[300]!, width: 1.5),
                  image: const DecorationImage(image: NetworkImage('https://i.pravatar.cc/150?u=kurirnyutji'), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currentT['welcome'], style: GoogleFonts.montserrat(fontSize: 10, color: textGrey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) => Text(
                      auth.user?['name'] ?? "Kurir Nyutji", 
                      style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w900, color: darkText)
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              // Small online toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: isOnline ? accentGreen.withOpacity(0.1) : Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(LucideIcons.radio, size: 12, color: isOnline ? accentGreen : textGrey),
                    const SizedBox(width: 4),
                    Switch(
                      value: isOnline,
                      onChanged: (val) => setState(() => isOnline = val),
                      activeColor: accentGreen,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Stack(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _scrollToTasks,
                    icon: Icon(LucideIcons.bell, color: darkText, size: 22),
                  ),
                  if (_notificationCount > 0)
                    Positioned(
                      right: 0, top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(color: primaryTeal, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                        child: Text(_notificationCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTrackingStrip() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue[100]!)),
      child: Row(
        children: [
          Icon(LucideIcons.mapPin, size: 14, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(child: Text("GPS Lock: Akurasi Tinggi (3m) • Area Kebayoran", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.blue[900]))),
          Icon(LucideIcons.signal, size: 14, color: Colors.blue[800])
        ],
      ),
    );
  }

  Widget _buildCompactStatsPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Consumer<WalletProvider>(
              builder: (context, wallet, _) => _buildStatCol("Pendapatan", Formatters.currencyIdr(wallet.balance), LucideIcons.wallet, Colors.green[700]!),
            ),
            Container(width: 1, height: 30, color: Colors.grey[200]),
            _buildStatCol("Selesai", "8 Tugas", LucideIcons.checkSquare, primaryTeal),
            Container(width: 1, height: 30, color: Colors.grey[200]),
            _buildStatCol("Jarak Tempuh", "24 Km", LucideIcons.navigation, Colors.blue[700]!),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCol(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.montserrat(fontSize: 10, color: textGrey, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: darkText)),
      ],
    );
  }

  Widget _buildDenseTaskSection(Map<String, dynamic> currentT) {
    return Container(
      key: _taskSectionKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(currentT['current_tasks'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: darkText, letterSpacing: 1.0)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.filter, size: 12),
                      const SizedBox(width: 4),
                      Text("Filter", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Modern Pill Segmented Control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _tabController.index = 0);
                        _tabController.animateTo(0);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          color: _tabController.index == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _tabController.index == 0 ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))] : [],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_tabController.index == 0) ...[
                                Icon(LucideIcons.arrowDownToLine, size: 14, color: primaryTeal),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                "Jemput (Pickup)",
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: _tabController.index == 0 ? FontWeight.w800 : FontWeight.w600,
                                  color: _tabController.index == 0 ? primaryTeal : textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _tabController.index = 1);
                        _tabController.animateTo(1);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          color: _tabController.index == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _tabController.index == 1 ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))] : [],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_tabController.index == 1) ...[
                                Icon(LucideIcons.send, size: 14, color: primaryTeal),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                "Antar (Delivery)",
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: _tabController.index == 1 ? FontWeight.w800 : FontWeight.w600,
                                  color: _tabController.index == 1 ? primaryTeal : textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Dense List View
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              bool isPickupType = _tabController.index == 0;
              if (isPickupType && task.type != CourierTaskType.pickup) return const SizedBox();
              if (!isPickupType && task.type != CourierTaskType.delivery) return const SizedBox();

              return _buildDenseTaskCard(task, currentT);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDenseTaskCard(CourierTask task, Map<String, dynamic> currentT) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4)],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Strip Indicator
            Container(
              width: 8,
              decoration: BoxDecoration(color: task.isUrgent ? Colors.red : primaryTeal, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16))),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ROW 1: ID & BADGE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(task.id, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w800, color: textGrey)),
                        if (task.isUrgent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(4)),
                            child: Text("FAST TRACK", style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.red)),
                          )
                      ],
                    ),
                    const SizedBox(height: 6),
                    // ROW 2: NAME & PRICE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(task.customerName, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: darkText)),
                        Text(
                          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(task.price),
                          style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 13, color: primaryTeal),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // ROW 3: ADDRESS
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.mapPin, size: 14, color: primaryTeal),
                        const SizedBox(width: 6),
                        Expanded(child: Text(task.address, style: GoogleFonts.montserrat(fontSize: 11, color: textGrey, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _openMap(task.address),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(6)),
                            child: Icon(LucideIcons.navigation, size: 14, color: Colors.blue[700]),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    // ROW 4: COMPACT ACTIONS
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: darkText,
                              side: BorderSide(color: Colors.grey[300]!),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              minimumSize: const Size(0, 32),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.phone, size: 12, color: darkText),
                                const SizedBox(width: 4),
                                Text(currentT['go'], style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryTeal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              minimumSize: const Size(0, 32),
                            ),
                            child: Text(currentT['update'], style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // === BOTTOM NAV ===
  Widget _buildBottomNav(Map<String, dynamic> currentT) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: const Icon(LucideIcons.clipboardList, size: 22), activeIcon: const Icon(LucideIcons.clipboardList, size: 22), label: currentT['home']),
          BottomNavigationBarItem(icon: const Icon(LucideIcons.history, size: 22), activeIcon: const Icon(LucideIcons.history, size: 22), label: currentT['history']),
          BottomNavigationBarItem(icon: const Icon(LucideIcons.wallet, size: 22), activeIcon: const Icon(LucideIcons.wallet, size: 22), label: currentT['wallet']),
          BottomNavigationBarItem(icon: const Icon(LucideIcons.user, size: 22), activeIcon: const Icon(LucideIcons.user, size: 22), label: currentT['profile']),
        ],
        currentIndex: _selectedNavIndex,
        selectedItemColor: primaryTeal,
        unselectedItemColor: textGrey.withValues(alpha: 0.6),
        showUnselectedLabels: true,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutQuint,
          );
        },
        backgroundColor: Colors.white,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 10),
        unselectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 9),
      ),
    );
  }

}
