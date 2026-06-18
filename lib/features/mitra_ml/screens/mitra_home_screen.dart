// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/widgets/forecast_weather.dart';
import '../../../core/widgets/shimmer_loading.dart';
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
import 'dart:math';
import '../../../data/services/api_service.dart';
import '../../../data/services/cache_service.dart';

class MitraHomeScreen extends ConsumerStatefulWidget {
  const MitraHomeScreen({super.key});

  @override ConsumerState<MitraHomeScreen> createState() => _MitraHomeScreenState();
}

class _MitraHomeScreenState extends ConsumerState<MitraHomeScreen> {
  static const primaryTeal = Color(0xFF1E5655); // Denser, more executive teal
  static const bgColor = Color(0xFFF3F4F6);
  static const darkText = Color(0xFF111827);
  static const textGrey = Color(0xFF6B7280);
  String _homeSubPage = "main"; // "main" atau "inventory"

  int _selectedIndex = 0;
  late PageController _pageController;
  String? _randomPosImage;
  bool isShopOpen = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _fetchMitraItemsData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      ref.read(walletProvider).fetchWallet();
      ref.read(orderProvider).fetchOrders();
      auth.fetchCouriers();
      auth.fetchPendingApprovals();
    });
  }

  int _servicesCount = 0;

  Future<void> _fetchMitraItemsData() async {
    final auth = ref.read(authProvider);
    final mitraId = auth.user?['identifier'] ?? auth.user?['id'];
    if (mitraId == null) return;

    final cacheKey = 'mitra_items_$mitraId';
    // 1. Coba baca dari cache dulu agar UI ter-render instan
    final cached = CacheService.get(cacheKey);
    if (cached != null && cached is List) {
      _processMitraItems(cached);
    }

    try {
      final api = ApiService();
      final items = await api.getMitraItems(mitraId);
      _processMitraItems(items);
    } catch (e) {
      debugPrint("Error fetching mitra items data: $e");
    }
  }

  void _processMitraItems(List<dynamic> items) {
    if (mounted) {
      setState(() {
        _servicesCount = items.length;
        final itemsWithPhoto = items.where((i) => i['url_photo'] != null).toList();
        if (itemsWithPhoto.isNotEmpty) {
          final random = Random();
          final randomItem = itemsWithPhoto[random.nextInt(itemsWithPhoto.length)];
          _randomPosImage = randomItem['url_photo'];
        }
      });
    }
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

    return RefreshIndicator(
      onRefresh: () async {
        final auth = ref.read(authProvider);
        await Future.wait([
          ref.read(walletProvider).fetchWallet(force: true),
          ref.read(orderProvider).fetchOrders(force: true),
          auth.fetchCouriers(force: true),
          auth.fetchPendingApprovals(force: true),
          _fetchMitraItemsData(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDenseHeader(),
            _buildAntreanCucianCard(),
            const SizedBox(height: 24),
            _buildQuickActionsGrid(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text("Informasi Laundry", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: darkText)),
            ),
            const SizedBox(height: 12),
            _buildDanaSiapDitarikGrid(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text("Cuaca Hari Ini", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: darkText)),
            ),
            const SizedBox(height: 12),
            const ForecastWeather(),
            const SizedBox(height: 24),
            _buildLiveQueueMachine(),
            const SizedBox(height: 40),
          ],
        ),
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
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Consumer(
                  builder: (context, ref, _) {
final auth = ref.watch(authProvider);
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
                      Consumer(
                        builder: (context, ref, _) {
final auth = ref.watch(authProvider);
return Text(
                          auth.user?['name'] ?? "Berkah Laundry", 
                          style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: darkText)
                        );
}),
                      Consumer(
                        builder: (context, ref, _) {
final auth = ref.watch(authProvider);
return Text(
                          "ID: ${auth.user?['identifier'] ?? '-'}", 
                          style: GoogleFonts.montserrat(fontSize: 13, color: textGrey, fontWeight: FontWeight.w600)
                        );
}),
                      const SizedBox(height: 2),
                      Consumer(
                        builder: (context, ref, _) {
final auth = ref.watch(authProvider);
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

  double _calculateWIP(List<dynamic> activeOrders) {
    double total = 0.0;
    for (var o in activeOrders) {
      total += double.tryParse((o['servicePrice'] ?? o['service_price'] ?? o['total_price'] ?? o['totalPrice'] ?? '0').toString()) ?? 0.0;
    }
    return total;
  }

  Widget _buildAntreanCucianCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Consumer(
      builder: (context, ref, _) {
        final wallet = ref.watch(walletProvider);
        final orderProv = ref.watch(orderProvider);

          final activeOrders = orderProv.activeOrders.where((o) => (o['status'] ?? o['order_status'] ?? '').toString().toUpperCase() != 'DRAFT').toList();
          final wipValue = _calculateWIP(activeOrders);
          final activeOrderCount = activeOrders.length;
          final bool hasOrder = activeOrderCount > 0;

          if (wallet.isLoading || orderProv.isLoading) {
            return const ShimmerLoading(height: 110, borderRadius: 16);
          }

          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Background Image or Grey color
                    Positioned.fill(
                      child: _randomPosImage != null
                          ? Image.network(
                              "${ApiConstants.rootUrl}/nyutji-storage/uploads/inventory/$_randomPosImage",
                              fit: BoxFit.cover,
                              alignment: Alignment.centerRight,
                              errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
                            )
                          : Container(color: Colors.grey[200]),
                    ),
                    // Large transparent icon if no image
                    if (_randomPosImage == null)
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Icon(
                          LucideIcons.loader,
                          size: 140,
                          color: Colors.black.withValues(alpha: 0.04),
                        ),
                      ),
                    // White gradient fading to the left
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.white.withValues(alpha: 1.0),
                              Colors.white.withValues(alpha: 0.8),
                              Colors.white.withValues(alpha: 0.1),
                            ],
                            stops: const [0.3, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Foreground Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.loader, size: 18, color: hasOrder ? Colors.orange : Colors.grey[400]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Row(
                                  children: [
                                    Text("Antrean Cucian Sekarang", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[600]), maxLines: 1),
                                    if (hasOrder) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 6, height: 6,
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      ),
                                    ]
                                  ],
                                )
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (hasOrder) ...[
                            Text("$activeOrderCount Order", style: GoogleFonts.montserrat(fontSize: 30, fontWeight: FontWeight.w900, color: darkText, height: 1.1)),
                            Text("Sedang dicuci", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                            const SizedBox(height: 16),
                            Text(Formatters.currencyIdr(wipValue), style: GoogleFonts.montserrat(fontSize: 30, fontWeight: FontWeight.w900, color: primaryTeal, height: 1.1)),
                            Text("Nilai Revenue", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                          ] else ...[
                            Text("Belum ada order cucian", style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[400])),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDanaSiapDitarikGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Consumer(
      builder: (context, ref, _) {
        final wallet = ref.watch(walletProvider);
        final auth = ref.watch(authProvider);

          final couriersCount = auth.couriers.length;
          final withdrawableDisplay = ((wallet.balance ~/ 100000) * 100000).toDouble();

          if (wallet.isLoading || auth.isLoading) {
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.1,
              children: List.generate(4, (_) => const ShimmerLoading(height: 70, borderRadius: 12)),
            );
          }

          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.1,
            children: [
              _buildSmallMetricCard("Dana Siap Ditarik", Formatters.currencyIdr(withdrawableDisplay), LucideIcons.wallet, primaryTeal, () {
                _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              }),
              _buildSmallMetricCard("Layanan", "$_servicesCount", LucideIcons.tags, Colors.blue, () {}),
              _buildSmallMetricCard("Kurir", "$couriersCount", LucideIcons.bike, Colors.indigo, () {}),
              _buildSmallMetricCard("Mesin Cuci", "0", LucideIcons.disc, Colors.purple, () {}),
            ],
          );
        }
      ),
    );
  }

  Widget _buildSmallMetricCard(String title, String value, IconData icon, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey[600], height: 1.1), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(value, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: darkText), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Consumer(
      builder: (context, ref, _) {
final orderProv = ref.watch(orderProvider);
        final activeOrderCount = orderProv.activeOrders.where((o) => (o['status'] ?? o['order_status'] ?? '').toString().toUpperCase() != 'DRAFT').length;

        final List<Widget> primaryActions = [
          _buildGridAction("Pesanan", LucideIcons.packagePlus, Colors.blue, () {
            _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          }, badgeCount: activeOrderCount),
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
    ];

    final List<Widget> secondaryActions = [
      _buildGridAction("Dompet", LucideIcons.wallet, Colors.green, () {
        _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }),
      _buildGridAction("Kinerja", LucideIcons.pieChart, Colors.orange, (){}),
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
    ];

    List<Widget> displayedActions = [
      ...primaryActions,
      ...secondaryActions,
    ];

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
            children: displayedActions,
          )
        ],
      ),
    );
      },
    );
  }

  Widget _buildGridAction(String title, IconData icon, Color color, VoidCallback onTap, {int badgeCount = 0}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 30),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount.toString(),
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 4;
          return Stack(
            children: [
              BottomNavigationBar(
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
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: 0,
                left: (tabWidth * _selectedIndex) + (tabWidth / 2) - 30,
                child: Container(
                  height: 3,
                  width: 60,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(3),
                      bottomRight: Radius.circular(3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.5),
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
