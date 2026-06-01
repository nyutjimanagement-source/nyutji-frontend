// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/widgets/forecast_weather.dart';
import '../../../core/constants/api_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../core/utils/formatters.dart';
import 'mitra_wallet_screen.dart';
import 'mitra_order_screen.dart';
import 'mitra_pricing_screen.dart';
import 'mitra_inventory_screen.dart';
import 'mitra_pos_screen.dart';
import '../../../core/widgets/nyutji_image_picker.dart';
import 'mitra_profile_screen.dart';
import 'mitra_mesin.dart';

class MitraHomeScreen extends StatefulWidget {
  const MitraHomeScreen({super.key});

  @override
  State<MitraHomeScreen> createState() => _MitraHomeScreenState();
}

class _MitraHomeScreenState extends State<MitraHomeScreen> {
  static const primaryTeal = Color(0xFF1E5655); // Denser, more executive teal
  static const bgColor = Color(0xFFF3F4F6);
  static const darkText = Color(0xFF111827);
  static const textGrey = Color(0xFF6B7280);
  String _homeSubPage = "main"; // "main" atau "inventory"


  int _selectedIndex = 0;
  late PageController _pageController;
  bool isShopOpen = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<WalletProvider>().fetchWallet();
      context.read<OrderProvider>().fetchOrders();
      auth.fetchCouriers();
      auth.fetchPendingApprovals();


    });

    // Auto-refresh data kurir tiap 5 detik
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        context.read<AuthProvider>().fetchPendingApprovals();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> t = {
      'id': {'logout': 'Keluar Akun'},
    };
    final currentT = t['id']; 

    final List<Widget> tabs = [
      _buildHomeTab(currentT),
      const MitraOrderScreen(),
      const MitraWalletScreen(),
      MitraProfileScreen(currentT: currentT),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _selectedIndex = index);
              },
              children: [
                SafeArea(bottom: false, child: tabs[0]),
                tabs[1], // MitraOrderScreen
                tabs[2], // MitraWalletScreen
                SafeArea(bottom: false, child: tabs[3]),
              ],
            ),
          ),
          SafeArea(top: false, child: _buildBottomNav(primaryTeal)),
        ],
      ),
    );
  }

  Future<void> _pickImage(AuthProvider auth) async {
    NyutjiImagePicker.show(
      context,
      title: "Pilih Foto Profil Toko",
      primaryColor: primaryTeal,
      currentImageUrl: auth.user?['profile_photo'],
      onImagePicked: (XFile file) async {
        final success = await auth.updateProfilePhoto(file);
        if (mounted) _showBeautifulNotif(success ? "Foto profil berhasil diperbarui" : "Gagal mengunggah foto", success);
      },
    );
  }

  void _showBeautifulNotif(String message, bool success) {
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: success ? primaryTeal : const Color(0xFFC3312E),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Row(
              children: [
                Icon(success ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(message, style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  // === DENSE HOME TAB (COMMAND CENTER) ===
  Widget _buildHomeTab(Map<String, dynamic>? currentT) {
    if (_homeSubPage == "inventory") {
      return MitraInventoryScreen(onBackTap: () => setState(() => _homeSubPage = "main"));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDenseHeader(),
          _buildCommandMetrics(),
          const SizedBox(height: 12),
          const ForecastWeather(),
          const SizedBox(height: 16),
          _buildQuickActionsGrid(),
          const SizedBox(height: 16),
          _buildLiveQueueMachine(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileImage(AuthProvider auth, dynamic photoUrl, String? localPhoto) {
    if (localPhoto == null && auth.temporaryWebBytes == null && (photoUrl == null || photoUrl.toString().isEmpty)) {
      return const Icon(LucideIcons.store, color: Colors.white, size: 20);
    }
    
    if (kIsWeb) {
      if (auth.temporaryWebBytes != null) {
        return Image.memory(auth.temporaryWebBytes!, fit: BoxFit.cover, gaplessPlayback: true);
      }
    } else {
      if (localPhoto != null) {
        return Image.file(File(localPhoto), fit: BoxFit.cover, gaplessPlayback: true);
      }
    }
    
    final url = photoUrl.toString().startsWith('http') 
        ? photoUrl.toString()
        : "${ApiConstants.rootUrl}/$photoUrl";
        
    return Image.network(
      url, 
      fit: BoxFit.cover, 
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const Icon(LucideIcons.store, color: Colors.white, size: 20),
    );
  }

  Widget _buildDenseHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    final photoUrl = auth.user?['profile_photo'];
                    final localPhoto = auth.temporaryLocalPhoto;
                    return GestureDetector(
                      onTap: () => _pickImage(auth),
                      child: Container(
                        width: 60, height: 60,
                        decoration: const BoxDecoration(
                          color: primaryTeal,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: _buildProfileImage(auth, photoUrl, localPhoto),
                        ),
                      ),
                    );
                  }
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) => Text(
                          auth.user?['name'] ?? "Berkah Laundry", 
                          style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: darkText)
                        ),
                      ),
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) => Text(
                          "ID: ${auth.user?['identifier'] ?? '-'}", 
                          style: GoogleFonts.montserrat(fontSize: 13, color: textGrey, fontWeight: FontWeight.w600)
                        ),
                      ),
                      const SizedBox(height: 2),
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          final district = auth.user?['owner_district_name'] ?? auth.user?['district_name'] ?? "-";
                          final city = auth.user?['owner_city_name'] ?? auth.user?['city_name'] ?? "-";
                          return Text(
                            "$district - $city", 
                            style: GoogleFonts.montserrat(fontSize: 12, color: primaryTeal, fontWeight: FontWeight.bold)
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTodayRevenue(List<dynamic> mutasiList) {
    if (mutasiList.isEmpty) return 0.0;
    double todayTotal = 0.0;
    final now = DateTime.now();
    
    for (var m in mutasiList) {
      final amt = double.tryParse(m['amount']?.toString() ?? '0') ?? 0.0;
      final type = (m['transaction_type'] ?? '').toString().toUpperCase();
      
      // Hitung yang masuk saja (revenue)
      if (amt > 0 && type != 'TOPUP') {
        try {
          DateTime dt = DateTime.tryParse(m['createdAt'] ?? m['date'] ?? '')?.toLocal() ?? DateTime.now();
          if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
            todayTotal += amt;
          }
        } catch (_) {}
      }
    }
    return todayTotal;
  }

  double _calculateWIP(List<dynamic> activeOrders) {
    double total = 0.0;
    for (var o in activeOrders) {
      total += double.tryParse((o['servicePrice'] ?? o['service_price'] ?? o['total_price'] ?? o['totalPrice'] ?? '0').toString()) ?? 0.0;
    }
    return total;
  }

  Widget _buildCommandMetrics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Consumer2<WalletProvider, OrderProvider>(
        builder: (context, wallet, orderProv, _) {
          final todayRevenue = _calculateTodayRevenue(wallet.mutasiList);
          final activeOrders = orderProv.activeOrders;
          final wipValue = _calculateWIP(activeOrders);
          final activeOrderCount = activeOrders.length;
          final auth = context.read<AuthProvider>();
          final couriersCount = auth.couriers.length;
          final withdrawable = wallet.balance;

          return Column(
            children: [
              // Baris 1: Revenue & Antrean (Font Besar)
              Row(
                children: [
                  Expanded(
                    child: _buildBigMetricCard(
                      "Revenue Hari Ini", 
                      Formatters.currencyIdr(todayRevenue), 
                      LucideIcons.trendingUp, 
                      Colors.green
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBigMetricCard(
                      "Antrean Berlangsung", 
                      "${Formatters.currencyIdr(wipValue)}\n($activeOrderCount Order)", 
                      LucideIcons.loader, 
                      Colors.orange,
                      onTap: () {
                        _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      }
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Baris 2: Rupiah Bisa Ditarik, Layanan, Kurir, Washer
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.85,
                children: [
                  _buildSmallMetricCard("Rupiah\nDitarik", Formatters.currencyIdr(withdrawable), LucideIcons.wallet, primaryTeal, () {
                    _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  }),
                  _buildSmallMetricCard("Layanan", "0", LucideIcons.tags, Colors.blue, () {}),
                  _buildSmallMetricCard("Kurir", "$couriersCount", LucideIcons.bike, Colors.indigo, () {}),
                  _buildSmallMetricCard("Washer", "0", LucideIcons.users, Colors.purple, () {}),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBigMetricCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.grey[200]!)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(child: Text(title, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600]), maxLines: 2)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value, 
              style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w900, color: darkText, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallMetricCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
          border: Border.all(color: Colors.grey[100]!)
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: darkText), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(title, style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey[600], height: 1.1), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
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
            childAspectRatio: 0.75,
            children: [
              _buildGridAction("Pesanan", LucideIcons.packagePlus, Colors.blue, () {
                _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              }),
              _buildGridAction("Kasir/POS", LucideIcons.calculator, Colors.indigo, () {
                Navigator.push(context, PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const MitraPosScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOutCubic;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return SlideTransition(position: animation.drive(tween), child: child);
                  },
                ));
              }),
              _buildGridAction("Dompet", LucideIcons.wallet, Colors.green, () {
                _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              }),
              _buildGridAction("Kinerja", LucideIcons.pieChart, Colors.orange, (){}),
              _buildGridAction("Harga & Promosi", LucideIcons.banknote, Colors.red, () {
                Navigator.push(context, PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const MitraPricingScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return SlideTransition(position: animation.drive(tween), child: child);
                  },
                ));
              }),
              _buildGridAction("Mesin", LucideIcons.cpu, Colors.cyan, () {
                Navigator.push(context, PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const MitraMesinScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOutCubic;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return SlideTransition(position: animation.drive(tween), child: child);
                  },
                ));
              }),
              _buildGridAction("Inventory", LucideIcons.boxes, Colors.purple, () {
                setState(() => _homeSubPage = "inventory");
              }),
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
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 8),
            Text(
              title, 
              textAlign: TextAlign.center, 
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: darkText, height: 1.1)
            ),
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
          Icon(LucideIcons.disc, size: 13, color: mColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(mName, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: darkText)),
                    Text(progress > 0 ? "${(progress*100).toInt()}%" : "0%", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: mColor)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(pStatus, style: GoogleFonts.montserrat(fontSize: 13, color: textGrey, fontWeight: FontWeight.w600)),
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



  // === BOTTOM NAV ===
  Widget _buildBottomNav(Color activeColor) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05))), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))]),
      child: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(LucideIcons.layoutDashboard, size: 20), activeIcon: Icon(LucideIcons.layoutDashboard, size: 20), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.clipboardList, size: 20), activeIcon: Icon(LucideIcons.clipboardList, size: 20), label: "Pesanan"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.wallet, size: 20), activeIcon: Icon(LucideIcons.wallet, size: 20), label: "Dompet"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.store, size: 20), activeIcon: Icon(LucideIcons.store, size: 20), label: "Toko"),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: activeColor,
        unselectedItemColor: textGrey.withValues(alpha: 0.6),
        showUnselectedLabels: true,
        onTap: (index) {
          if (index == 0 && _selectedIndex == 0) {
            setState(() => _homeSubPage = "main");
          }
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
