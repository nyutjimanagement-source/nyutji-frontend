import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../core/utils/formatters.dart';
import 'mitra_wallet_screen.dart';
import 'mitra_courier_management_screen.dart';
import 'mitra_approval_kl_screen.dart';
import 'mitra_order_screen.dart';

class MitraHomeScreen extends StatefulWidget {
  const MitraHomeScreen({Key? key}) : super(key: key);

  @override
  State<MitraHomeScreen> createState() => _MitraHomeScreenState();
}

class _MitraHomeScreenState extends State<MitraHomeScreen> {
  static const primaryTeal = Color(0xFF1E5655); // Denser, more executive teal
  static const secondaryTeal = Color(0xFF14403F);
  static const accentGold = Color(0xFFF59E0B);
  static const bgColor = Color(0xFFF3F4F6);
  static const darkText = Color(0xFF111827);
  static const textGrey = Color(0xFF6B7280);

  int _selectedIndex = 0;
  late PageController _pageController;
  bool isShopOpen = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallet();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> t = {
      'id': {'logout': 'Keluar Akun'},
    };
    final currentT = t['id']; 

    final List<Widget> _tabs = [
      _buildHomeTab(currentT),
      const MitraOrderScreen(),
      const MitraWalletScreen(),
      _buildProfileTab(currentT),
    ];

    return Scaffold(
      backgroundColor: bgColor,
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
                children: _tabs,
              ),
            ),
            _buildBottomNav(primaryTeal),
          ],
        ),
      ),
    );
  }

  // === DENSE HOME TAB (COMMAND CENTER) ===
  Widget _buildHomeTab(Map<String, dynamic>? currentT) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDenseHeader(),
          _buildLiveStatusStrip(),
          const SizedBox(height: 12),
          _buildCommandMetrics(),
          const SizedBox(height: 16),
          _buildQuickActionsGrid(),
          const SizedBox(height: 16),
          _buildLiveQueueMachine(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDenseHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: primaryTeal,
                  borderRadius: BorderRadius.circular(10),
                  image: const DecorationImage(image: NetworkImage("https://images.unsplash.com/photo-1545173168-9f1947eebb7f?w=150&q=80"), fit: BoxFit.cover)
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) => Text(
                          auth.user?['name'] ?? "Mitra Nyutji", 
                          style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: darkText)
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, size: 14, color: Colors.blue),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.star, size: 10, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text("4.9", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber[900])),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text("Kebayoran Baru", style: GoogleFonts.montserrat(fontSize: 11, color: textGrey, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Stack(
            children: [
              IconButton(onPressed: () {}, icon: Icon(LucideIcons.bell, color: darkText, size: 22), constraints: const BoxConstraints(), padding: EdgeInsets.zero),
              Positioned(
                right: 0, top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  child: const Text("5", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLiveStatusStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: isShopOpen ? Colors.green[50] : Colors.red[50], border: Border(bottom: BorderSide(color: isShopOpen ? Colors.green[200]! : Colors.red[200]!))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: isShopOpen ? Colors.green : Colors.red, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(isShopOpen ? "Toko Buka - Menerima Order Penuh" : "Toko Tutup", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: isShopOpen ? Colors.green[700] : Colors.red[700])),
            ],
          ),
          Switch(
            value: isShopOpen, 
            onChanged: (val) => setState(() => isShopOpen = val), 
            activeColor: Colors.green, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          )
        ],
      ),
    );
  }

  Widget _buildCommandMetrics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: primaryTeal, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: primaryTeal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Consumer<WalletProvider>(
          builder: (context, wallet, _) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem("HARI INI", Formatters.currencyIdr(wallet.balance), LucideIcons.trendingUp, Colors.greenAccent),
              Container(width: 1, height: 35, color: Colors.white24),
              _buildMetricItem("ANTREAN", "18", LucideIcons.layers, Colors.orangeAccent),
              Container(width: 1, height: 35, color: Colors.white24),
              _buildMetricItem("SELESAI", "45", LucideIcons.checkSquare, Colors.blueAccent),
              Container(width: 1, height: 35, color: Colors.white24),
              _buildMetricItem("KENDALA", "0", LucideIcons.alertTriangle, Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.montserrat(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Aksi Cepat", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: darkText)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
            children: [
              _buildGridAction("Pesanan", LucideIcons.packagePlus, Colors.blue, () {
                _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              }),
              _buildGridAction("Kasir / POS", LucideIcons.calculator, Colors.indigo, (){}),
              _buildGridAction("Dompet", LucideIcons.wallet, Colors.green, () {
                _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              }),
              _buildGridAction("Kinerja", LucideIcons.pieChart, Colors.orange, (){}),
              _buildGridAction("Promo", LucideIcons.tags, Colors.red, (){}),
              _buildGridAction("Mesin", LucideIcons.cpu, Colors.cyan, (){}),
              _buildGridAction("Pegawai", LucideIcons.users, Colors.purple, (){}),
              _buildGridAction("Kendala", LucideIcons.alertTriangle, Colors.amber, () {
                Navigator.pushNamed(context, '/mitra_report_issue');
              }),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildGridAction(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: darkText)),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveQueueMachine() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text("Live Mesin Operasional", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: darkText)),
               Text("Lihat Semua", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTeal)),
             ],
           ),
           const SizedBox(height: 12),
           _buildMachineRow("Mesin Cuci #1", "Mencuci - KBY-001", 0.6, Colors.blue),
           _buildMachineRow("Mesin Cuci #2", "Standby", 0.0, Colors.grey),
           _buildMachineRow("Mesin Pengering #1", "Mengeringkan - KBY-002", 0.8, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildMachineRow(String mName, String pStatus, double progress, Color mColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        children: [
          Icon(LucideIcons.disc, size: 24, color: mColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(mName, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: darkText)),
                    Text(progress > 0 ? "${(progress*100).toInt()}%" : "0%", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: mColor)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(pStatus, style: GoogleFonts.montserrat(fontSize: 10, color: textGrey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress, 
                  backgroundColor: Colors.grey[100],
                  valueColor: AlwaysStoppedAnimation<Color>(mColor),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // === PROFILE TAB (DENSE) ===
  Widget _buildProfileTab(Map<String, dynamic>? currentT) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                const CircleAvatar(radius: 30, backgroundImage: NetworkImage("https://images.unsplash.com/photo-1545173168-9f1947eebb7f?w=150&q=80")),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Berkah Laundry", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: darkText)),
                    Text("ID: ML-KBY-0911", style: GoogleFonts.montserrat(fontSize: 11, color: textGrey, fontWeight: FontWeight.w600)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
            child: Column(
              children: [
                _buildMenuItem(LucideIcons.userCheck, "Informasi KYC Eksekutif", false),
                const Divider(height: 1),
                _buildMenuItem(LucideIcons.shieldAlert, "Keamanan PIN", false),
                const Divider(height: 1),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MitraApprovalKlScreen())),
                  child: _buildMenuItem(LucideIcons.users, "Kelola Kurir Laundry", false),
                ),
                const Divider(height: 1),
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: _buildMenuItem(LucideIcons.logOut, currentT!['logout'], true),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, bool isLogout) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isLogout ? Colors.red : darkText),
          const SizedBox(width: 12),
          Text(title, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: isLogout ? Colors.red : darkText)),
          const Spacer(),
          Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }

  // === BOTTOM NAV ===
  Widget _buildBottomNav(Color activeColor) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]),
      child: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(LucideIcons.layoutDashboard, size: 20), activeIcon: Icon(LucideIcons.layoutDashboard, size: 20), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.clipboardList, size: 20), activeIcon: Icon(LucideIcons.clipboardList, size: 20), label: "Pesanan"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.wallet, size: 20), activeIcon: Icon(LucideIcons.wallet, size: 20), label: "Dompet"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.store, size: 20), activeIcon: Icon(LucideIcons.store, size: 20), label: "Toko"),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: activeColor,
        unselectedItemColor: textGrey.withOpacity(0.6),
        showUnselectedLabels: true,
        onTap: (index) {
          _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
