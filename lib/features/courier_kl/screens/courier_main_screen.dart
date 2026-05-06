import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/constants/api_constants.dart';
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

// Model: Order tersedia di kecamatan KL
class AvailableOrder {
  final String id;
  final int totalPrice;
  final String pickupAddress;
  final String mitraName;
  final String mitraAddress;
  final bool isFastTrack;
  final double distanceKm;

  AvailableOrder({
    required this.id,
    required this.totalPrice,
    required this.pickupAddress,
    required this.mitraName,
    required this.mitraAddress,
    required this.isFastTrack,
    required this.distanceKm,
  });
}

  // Models for available orders are kept as they are used for parsing available orders API
  // but we will use dynamic Maps for tasks
  
// --- SCREEN ---
class CourierMainScreen extends StatefulWidget {
  const CourierMainScreen({super.key});

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

  // Enterprise/Super-App Colors for Courier
  final Color primaryTeal = const Color(0xFF286B6A);
  final Color accentGreen = const Color(0xFF10B981);
  final Color bgColor = const Color(0xFFF3F4F6); // Cooler gray-white
  final Color darkText = const Color(0xFF111827);
  final Color textGrey = const Color(0xFF6B7280);
  final ImagePicker _picker = ImagePicker();

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
      // Fetch order tersedia di kecamatan KL
      final auth = context.read<AuthProvider>();
      final district = auth.user?['district_name']?.toString() ?? '';
      if (district.isNotEmpty) {
        context.read<OrderProvider>().fetchAvailableOrders(district);
      }
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

  Future<void> _pickImage(AuthProvider auth) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Pilih Foto Profil Kurir", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(LucideIcons.camera, color: primaryTeal),
              title: Text("Ambil Foto Kamera", style: GoogleFonts.montserrat()),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
                if (photo != null) {
                  final success = await auth.updateProfilePhoto(photo);
                  if (mounted) _showBeautifulNotif(success ? "Foto profil berhasil diperbarui" : "Gagal mengunggah foto", success);
                }
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.image, color: primaryTeal),
              title: Text("Pilih dari Galeri", style: GoogleFonts.montserrat()),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                if (image != null) {
                  final success = await auth.updateProfilePhoto(image);
                  if (mounted) _showBeautifulNotif(success ? "Foto profil berhasil diperbarui" : "Gagal mengunggah foto", success);
                }
              },
            ),
          ],
        ),
      ),
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
              child: ColorFiltered(
                colorFilter: isOnline 
                  ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                  : const ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0,      0,      0,      1, 0,
                    ]),
                child: PageView(
                  controller: _pageController,
                  physics: isOnline ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => setState(() => _selectedNavIndex = index),
                  children: tabs,
                ),
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
      return _buildCompactHeader(currentT);
    } else if (_selectedNavIndex == 1) {
      return Consumer<AuthProvider>(
        builder: (context, auth, _) => _buildPageTitleHeader("Riwayat Tugas ${auth.user?['name'] ?? ''}", LucideIcons.history, auth: auth, forceIcon: true),
      );
    } else if (_selectedNavIndex == 2) {
      return Consumer<AuthProvider>(
        builder: (context, auth, _) => _buildPageTitleHeader("Dompet ${auth.user?['name'] ?? ''}", LucideIcons.wallet, auth: auth, forceIcon: true),
      );
    } else {
      return Consumer<AuthProvider>(
        builder: (context, auth, _) => _buildPageTitleHeader(auth.user?['name'] ?? "Profil Kurir", LucideIcons.user, auth: auth, forceIcon: false),
      );
    }
  }

  Widget _buildPageTitleHeader(String title, IconData icon, {AuthProvider? auth, bool forceIcon = false}) {
    final photoUrl = auth?.user?['profile_photo'];
    final localPhoto = auth?.temporaryLocalPhoto;
    final district = auth?.user?['owner_district_name'] ?? auth?.user?['district_name'] ?? auth?.user?['district_code'] ?? "";
    final city = auth?.user?['owner_city_name'] ?? auth?.user?['city_name'] ?? "";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () { if (auth != null && !forceIcon) _pickImage(auth); },
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                color: primaryTeal.withValues(alpha: 0.1),
                border: Border.all(color: Colors.grey[300]!, width: 1.5),
                image: !forceIcon ? (kIsWeb
                  ? (auth?.temporaryWebBytes != null
                      ? DecorationImage(image: MemoryImage(auth!.temporaryWebBytes), fit: BoxFit.cover)
                      : (photoUrl != null && photoUrl.toString().isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(
                                photoUrl.toString().startsWith('http') 
                                  ? "$photoUrl?v=${DateTime.now().millisecondsSinceEpoch}"
                                  : "${ApiConstants.rootUrl}/$photoUrl?v=${DateTime.now().millisecondsSinceEpoch}"
                              ), 
                              fit: BoxFit.cover
                            ) 
                          : null)
                  : (localPhoto != null
                    ? DecorationImage(image: FileImage(File(localPhoto)), fit: BoxFit.cover)
                    : (photoUrl != null && photoUrl.toString().isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(
                              photoUrl.toString().startsWith('http') 
                                ? "$photoUrl?v=${DateTime.now().millisecondsSinceEpoch}"
                                : "${ApiConstants.rootUrl}/$photoUrl?v=${DateTime.now().millisecondsSinceEpoch}"
                            ), 
                            fit: BoxFit.cover
                          ) 
                        : null)) : null,
              ),
              child: (forceIcon || (localPhoto == null && auth?.temporaryWebBytes == null && (photoUrl == null || photoUrl.toString().isEmpty))) 
                ? Icon(icon, color: primaryTeal, size: 18) 
                : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
              Text(
                auth != null ? (auth.user?['name'] ?? "Abang Kurir") : "Abang Kurir Jago",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: darkText, letterSpacing: 0.2),
              ),
              Text(
                auth != null ? "ID: ${auth.user?['identifier'] ?? '-'} \u2022 $district${city.isNotEmpty ? ' - $city' : ''}" : "Nyutji Logistics Team",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(fontSize: 10, color: textGrey, fontWeight: FontWeight.w600),
              ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Consumer<OrderProvider>(
            builder: (context, orderProv, _) => Stack(
              children: [
                IconButton(
                  onPressed: () => orderProv.resetNotif('KL'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(LucideIcons.bell, color: textGrey, size: 20),
                ),
                if (orderProv.notifCountKL > 0)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                      child: Text(
                        orderProv.notifCountKL > 9 ? "9+" : orderProv.notifCountKL.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
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
          _buildActiveTrackingStrip(),
          const SizedBox(height: 12),
          _buildCompactStatsPanel(),
          const SizedBox(height: 16),
          _buildAvailableOrdersCard(),
          const SizedBox(height: 16),
          _buildDenseTaskSection(currentT),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCompactHeader(Map<String, dynamic> currentT) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, 
                          color: primaryTeal.withValues(alpha: 0.1),
                          border: Border.all(color: Colors.grey[300]!, width: 1.5),
                        ),
                        child: kIsWeb
                            ? (auth.temporaryWebBytes != null
                                ? Container(decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: MemoryImage(auth.temporaryWebBytes), fit: BoxFit.cover)))
                                : (photoUrl != null && photoUrl.toString().isNotEmpty)
                                    ? Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: DecorationImage(
                                              image: NetworkImage(
                                                photoUrl.toString().startsWith('http') 
                                                  ? "$photoUrl?v=${DateTime.now().millisecondsSinceEpoch}"
                                                  : "${ApiConstants.rootUrl}/$photoUrl?v=${DateTime.now().millisecondsSinceEpoch}"
                                              ), 
                                              fit: BoxFit.cover
                                            )
                                          ),
                                      ) 
                                    : Icon(LucideIcons.user, color: primaryTeal, size: 20))
                            : (localPhoto != null
                              ? Container(decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: FileImage(File(localPhoto)), fit: BoxFit.cover)))
                              : (photoUrl != null && photoUrl.toString().isNotEmpty)
                                  ? Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                            image: NetworkImage(
                                              photoUrl.toString().startsWith('http') 
                                                ? "$photoUrl?v=${DateTime.now().millisecondsSinceEpoch}"
                                                : "${ApiConstants.rootUrl}/$photoUrl?v=${DateTime.now().millisecondsSinceEpoch}"
                                            ), 
                                            fit: BoxFit.cover
                                          )
                                        ),
                                    ) 
                                  : Icon(LucideIcons.user, color: primaryTeal, size: 20)),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentT['welcome'], style: GoogleFonts.montserrat(fontSize: 10, color: textGrey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          final district = auth.user?['owner_district_name'] ?? auth.user?['district_name'] ?? auth.user?['district_code'] ?? "";
                          final city = auth.user?['owner_city_name'] ?? auth.user?['city_name'] ?? "";
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.user?['name'] ?? "Abang Kurir", 
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: darkText)
                              ),
                              Text(
                                "ID: ${auth.user?['identifier'] ?? '-'} \u2022 $district${city.isNotEmpty ? ' - $city' : ''}",
                                style: GoogleFonts.montserrat(fontSize: 10, color: textGrey, fontWeight: FontWeight.w600),
                              ),
                            ],
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("ON-OFF KURIR", style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.bold, color: textGrey)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                decoration: BoxDecoration(
                  color: isOnline ? accentGreen.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1), 
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.radio, size: 10, color: isOnline ? accentGreen : Colors.red),
                    Transform.scale(
                      scale: 0.7,
                      child: Switch(
                        value: isOnline,
                        onChanged: (val) => setState(() => isOnline = val),
                        activeThumbColor: accentGreen,
                        activeTrackColor: accentGreen.withValues(alpha: 0.3),
                        inactiveThumbColor: Colors.red,
                        inactiveTrackColor: Colors.red.withValues(alpha: 0.3),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Consumer<OrderProvider>(
            builder: (context, orderProv, _) => Stack(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    _scrollToTasks();
                    orderProv.resetNotif('KL');
                  },
                  icon: Icon(LucideIcons.bell, color: darkText, size: 22),
                ),
                if (orderProv.notifCountKL > 0)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                      child: Text(
                        orderProv.notifCountKL > 9 ? "9+" : orderProv.notifCountKL.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
              ],
            ),
          )
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
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
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Icon(icon, size: 12, color: color),
            ),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.montserrat(fontSize: 10, color: textGrey, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: darkText)),
      ],
    );
  }

  // ============================================================
  // === CARD ORDER TERSEDIA (PREMIUM MARKETPLACE) ==============
  // ============================================================
  Widget _buildAvailableOrdersCard() {
    return Consumer2<OrderProvider, AuthProvider>(
      builder: (context, orderProv, auth, _) {
        // Gunakan data live jika ada, fallback ke dummy jika kosong
        final liveOrders = orderProv.availableOrders;
        final displayOrders = liveOrders;

        final district = auth.user?['district_name'] ?? 'Wilayahmu';
        final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: const Color(0xFF286B6A).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.zap, size: 16, color: Color(0xFFFFD700)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("ORDER TERSEDIA",
                              style: GoogleFonts.montserrat(
                                fontSize: 11, fontWeight: FontWeight.w900,
                                color: const Color(0xFFFFD700), letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              "Kec. $district \u2022 ${displayOrders.length} pesanan",
                              style: GoogleFonts.montserrat(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text(liveOrders.isNotEmpty ? "LIVE" : "DEMO",
                              style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900,
                                color: liveOrders.isNotEmpty ? const Color(0xFF10B981) : Colors.orange)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // LIST ORDER
                Container(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    shrinkWrap: true,
                    itemCount: displayOrders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final order = displayOrders[index];
                      final isTop = index == 0;
                      
                      // SUPER-SMART MAPPING: Mendukung CamelCase & SnakeCase
                      final orderId = (order['order_number'] ?? order['orderNumber'] ?? order['identifier'] ?? order['id'] ?? '-').toString();
                      
                      // KL HANYA BOLEH LIHAT DELIVERY FEE (Sesuai instruksi Jenderal)
                      final price = double.tryParse((order['delivery_fee'] ?? order['deliveryFee'] ?? '0').toString()) ?? 0.0;
                      
                      // Alamat Jemput (Prioritas: address dari database)
                      final pickup = order['address']?.toString() ?? order['customer']?['address']?.toString() ?? '-';
                      
                      final mitraName = (order['mitra']?['name'] ?? order['mitra_name'] ?? 'Mitra').toString();
                      final mitraAddr = (order['mitra']?['address'] ?? order['mitra_address'] ?? '-').toString();
                      
                      final isFast = order['is_fast_track'] == true || order['is_fast_track'] == 1 || order['isFastTrack'] == true;
                      
                      // JARAK STATIS DARI DATABASE (Sesuai instruksi Jenderal)
                      final distance = double.tryParse((order['distance'] ?? order['distance_km'] ?? '0').toString()) ?? 0.0;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isTop ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isTop ? const Color(0xFFFFD700).withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.1),
                            width: isTop ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(fmt.format(price),
                                  style: GoogleFonts.montserrat(
                                    fontSize: isTop ? 22 : 18, fontWeight: FontWeight.w900,
                                    color: isTop ? const Color(0xFFFFD700) : Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                isFast
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF4500)]),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text("\u26a1 FAST", style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white)),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.white24),
                                      ),
                                      child: Text("REGULER", style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white70)),
                                    ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(LucideIcons.mapPin, size: 11, color: Color(0xFF10B981)),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(pickup,
                                    style: GoogleFonts.montserrat(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(LucideIcons.store, size: 11, color: Color(0xFF60A5FA)),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text("$mitraName \u2013 $mitraAddr",
                                    style: GoogleFonts.montserrat(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.w500),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(LucideIcons.navigation2, size: 11, color: Colors.white38),
                                const SizedBox(width: 4),
                                Text("${distance > 0 ? distance.toStringAsFixed(1) : '~'} km",
                                  style: GoogleFonts.montserrat(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.w700),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () async {
                                    final provider = context.read<OrderProvider>();
                                    final success = await provider.acceptOrder(orderId);
                                    if (!mounted) return;
                                    if (success) {
                                      _showBeautifulNotif("Order #$orderId berhasil diambil!", true);
                                    } else {
                                      final error = provider.errorMessage;
                                      _showBeautifulNotif(error ?? "Gagal mengambil order", false);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3)),
                                      ],
                                    ),
                                    child: Text("AMBIL",
                                      style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                                    ),
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
          ),
        );
      },
    );
  }


  Widget _buildDenseTaskSection(Map<String, dynamic> currentT) {
    final activeOrders = context.watch<OrderProvider>().activeOrders;
    final pickupCount = activeOrders.where((o) {
      final s = (o['status'] ?? o['order_status'] ?? '').toString().toUpperCase();
      return s == 'SEARCHING' || s == 'WAITING_DROPOFF' || s == 'COURIER_ACCEPTED' || s == 'PICKING_UP';
    }).length;
    final deliveryCount = activeOrders.where((o) {
      final s = (o['status'] ?? o['order_status'] ?? '').toString().toUpperCase();
      return s == 'PACKING' || s == 'DELIVERING';
    }).length;

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
                          color: _tabController.index == 0 
                              ? const Color(0xFF286B6A).withValues(alpha: 0.1) 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: _tabController.index == 0 ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))] : [],
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
                              if (pickupCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(left: 4, bottom: 8),
                                  width: 6, height: 6,
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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
                          color: _tabController.index == 1 
                              ? const Color(0xFF286B6A).withValues(alpha: 0.1) 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: _tabController.index == 1 ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))] : [],
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
                              if (deliveryCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(left: 4, bottom: 8),
                                  width: 6, height: 6,
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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
          
          // Dense List View (Real Data)
          Consumer<OrderProvider>(
            builder: (context, orderProv, _) {
              final activeOrders = orderProv.activeOrders;
              bool isPickupTab = _tabController.index == 0;
              
              final filtered = activeOrders.where((o) {
                // Sesuai Tabel Database: menggunakan kolom 'status'
                final s = (o['status'] ?? o['order_status'] ?? '').toString().toUpperCase();
                if (isPickupTab) {
                    // Pickup tasks are biasanya SEARCHING, WAITING_DROPOFF, COURIER_ACCEPTED, PICKING_UP
                  return s == 'SEARCHING' || s == 'WAITING_DROPOFF' || s == 'COURIER_ACCEPTED' || s == 'PICKING_UP';
                } else {
                  // Delivery tasks are biasanya PACKING, DELIVERING
                  return s == 'PACKING' || s == 'DELIVERING';
                }
              }).toList();

              if (orderProv.isLoading && filtered.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      Icon(LucideIcons.clipboardCheck, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text("Tidak ada antrean tugas", style: GoogleFonts.montserrat(fontSize: 12, color: textGrey, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return _buildDenseTaskCard(filtered[index], currentT);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDenseTaskCard(dynamic task, Map<String, dynamic> currentT) {
    // Sinkronisasi Super-Smart: Mendukung SnakeCase & CamelCase dari Database
    final String orderId = (task['order_number'] ?? task['orderNumber'] ?? task['identifier'] ?? task['id'] ?? '-').toString();
    final String customerName = task['customer']?['name']?.toString() ?? task['customer_name']?.toString() ?? 'Pelanggan';
    final String status = (task['status'] ?? task['order_status'] ?? 'UNKNOWN').toString().toUpperCase();
    
    // KL HANYA BOLEH LIHAT DELIVERY FEE
    final double price = double.tryParse((task['delivery_fee'] ?? task['deliveryFee'] ?? task['total_price'] ?? '0').toString()) ?? 0.0;
    final bool isFast = task['is_fast_track'] == true || task['is_fast_track'] == 1 || task['isFastTrack'] == true;
    
    // Alamat (MENGGUNAKAN WARNA MERAH SEBAGAI REMINDER)
    final String address = task['address']?.toString() ?? task['customer']?['address']?.toString() ?? "Jl. Salak Raya No.23, Pd. Benda, Kec. Pamulang, Kota Tangerang Selatan, Banten 15416"; 
    final double distance = double.tryParse((task['distance'] ?? task['distance_km'] ?? '0').toString()) ?? 0.0;
    final String serviceType = (task['service_type'] ?? task['serviceType'] ?? 'Reguler').toString().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Strip Indicator
            Container(
              width: 8,
              decoration: BoxDecoration(color: isFast ? Colors.red : primaryTeal, borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20))),
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
                        Text(orderId, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w800, color: textGrey)),
                        if (isFast)
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
                        Text(customerName, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: darkText)),
                        Text(
                          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                () {
                                  if (address == "-" || address.isEmpty || address == "Alamat Pelanggan") return address;
                                  final parts = address.split(',');
                                  if (parts.length > 2) return "${parts[0].trim()}, ${parts[1].trim()}, ${parts[2].trim()}";
                                  if (parts.length > 1) return "${parts[0].trim()}, ${parts[1].trim()}";
                                  return address;
                                }(),
                                style: GoogleFonts.montserrat(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w700),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text("${distance.toStringAsFixed(1)} Km \u2022 $serviceType", style: GoogleFonts.montserrat(fontSize: 9, color: primaryTeal, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _openMap(address),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.15), shape: BoxShape.circle),
                                child: Icon(LucideIcons.navigation, color: primaryTeal, size: 24),
                              ),
                              const SizedBox(height: 4),
                              Text("Tekan Menuju Lokasi", 
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(fontSize: 7, color: primaryTeal, fontWeight: FontWeight.w900, letterSpacing: -0.2)
                              ),
                            ],
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
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final provider = context.read<OrderProvider>();
                              String nextStatus = 'DONE';
                              if (status == 'COURIER_ACCEPTED' || status == 'SEARCHING') {
                                nextStatus = 'PICKING_UP';
                              } else if (status == 'PICKING_UP') {
                                nextStatus = 'WAITING_DROPOFF';
                              } else if (status == 'DELIVERING') {
                                nextStatus = 'DONE';
                              }
                              
                              final success = await provider.updateOrderStatus(orderId, nextStatus);
                              if (mounted) {
                                if (success) {
                                  _showBeautifulNotif("Status diperbarui ke $nextStatus", true);
                                } else {
                                  _showBeautifulNotif(provider.errorMessage ?? "Gagal", false);
                                }
                              }
                            },
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
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
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
          if (!isOnline && index != 0) return; // Disable other tabs when offline
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
