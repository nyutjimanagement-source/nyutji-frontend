import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../providers/auth_provider.dart';

import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/constants/api_constants.dart';
import 'courier_history_screen.dart';
import 'courier_wallet_screen.dart';
import 'courier_profile_screen.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/wallet_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../core/widgets/nyutji_image_picker.dart';
import '../../../core/widgets/nyutji_loading_overlay.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../core/widgets/nyutji_dot.dart';
import '../../chat/screens/chat_screen.dart';
import '../../chat/utils/chat_utils.dart';

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
class CourierMainScreen extends ConsumerStatefulWidget {
  const CourierMainScreen({super.key});

  @override
  ConsumerState<CourierMainScreen> createState() => _CourierMainScreenState();
}

class _CourierMainScreenState extends ConsumerState<CourierMainScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _taskSectionKey = GlobalKey();
  bool isOnline = true;
  int _selectedNavIndex = 0;
  Timer? _refreshTimer;
  final Map<String, File?> _taskCapturedImages = {};
  final Map<String, bool?> _simulatedCorrectLocation = {};
  bool _isUploading = false;
  String _gpsLocationText = "Mendeteksi lokasi...";
  bool _hasDoneAutoSelect = false;

  // Clean Emerald Glass Palette
  final Color primaryTeal = const Color(0xFF0F766E); // Deep Emerald Teal
  final Color accentGreen = const Color(0xFF10B981); // Bright Emerald
  final Color bgColor = const Color(0xFFF9FAFB); // Off-White
  final Color darkText = const Color(0xFF111827); // Almost Black
  final Color textGrey = const Color(0xFF6B7280); // Muted Grey
  final Color amberGold = const Color(0xFFF59E0B); // Amber/Gold for actions

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
      'available_orders': 'ORDER TERSEDIA',
      'current_tasks': 'Antrean Tugas',
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
      _refreshData();
      _fetchRealLocation();
      // Auto-set tab default ke Jemput jika ada pickup (Rule: default Jemput jika keduanya ada)
      _autoSelectTab();
    });
    // Auto-reload dihapus sesuai Aturan Pelarangan Polling Agresif (Rule 4)
  }

  void _autoSelectTab() {
    final activeOrders = ref.read(orderProvider).activeOrders;
    final hasPickup = activeOrders.any((o) {
      final String rawDel = (o['deliveryType'] ?? o['delivery_type'] ?? '')
          .toString()
          .toUpperCase();
      final isSelfDrop = rawDel == 'SELF_DROP' ||
          rawDel == 'SELFDROP_SELFDELIVERY' ||
          rawDel == 'SELF_SERVICE';
      if (isSelfDrop) return false;
      final s =
          (o['status'] ?? o['order_status'] ?? '').toString().toUpperCase();
      return s == 'WAITING_DROPOFF' ||
          s == 'COURIER_ACCEPTED' ||
          s == 'PICKING_UP';
    });
    final hasDelivery = activeOrders.any((o) {
      final s =
          (o['status'] ?? o['order_status'] ?? '').toString().toUpperCase();
      return s == 'PACKING' || s == 'DELIVERING';
    });
    // Default: Jemput jika ada, atau Antar jika hanya delivery yang ada
    final targetTab = (hasPickup || (!hasPickup && !hasDelivery)) ? 0 : 1;
    if (_tabController.index != targetTab) {
      setState(() => _tabController.index = targetTab);
      _tabController.animateTo(targetTab);
    }
  }

  Future<void> _fetchRealLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _gpsLocationText = "GPS Tidak Aktif");
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _gpsLocationText = "Izin GPS Ditolak");
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _gpsLocationText = "GPS Diblokir");
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final url = Uri.parse(
          "https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}&zoom=18&addressdetails=1");
      final response =
          await http.get(url, headers: {'User-Agent': 'NyutjiApp/1.0'});
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        final address = data['address'] ?? {};
        String kelurahan = address['village'] ??
            address['suburb'] ??
            address['neighbourhood'] ??
            "";
        String kecamatan =
            address['subdistrict'] ?? address['city_district'] ?? "";
        String city =
            address['city'] ?? address['regency'] ?? address['county'] ?? "";

        kecamatan = kecamatan
            .replaceAll(RegExp(r'^kecamatan\s+', caseSensitive: false), '')
            .trim();
        if (kecamatan.isEmpty && kelurahan.isNotEmpty) kecamatan = kelurahan;

        if (city.toLowerCase().startsWith('kabupaten ')) {
          city = city.replaceAll(
              RegExp(r'^kabupaten\s+', caseSensitive: false), 'Kab. ');
        } else if (!city.toLowerCase().startsWith('kota ') &&
            !city.toLowerCase().startsWith('kab.')) {
          city = "Kota $city";
        }

        String locStr = "";
        if (kelurahan.isNotEmpty &&
            kecamatan.isNotEmpty &&
            kelurahan != kecamatan) {
          locStr = "$kelurahan/$kecamatan - $city";
        } else if (kecamatan.isNotEmpty) {
          locStr = "$kecamatan - $city";
        } else {
          locStr = city;
        }

        setState(() {
          _gpsLocationText = locStr;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _gpsLocationText = "Gagal memuat GPS");
    }
  }

  Future<void> _refreshData({bool force = false}) async {
    if (!mounted || !isOnline) return;

    setState(() {
      _hasDoneAutoSelect = false;
    });

    ref.read(walletProvider).fetchWallet(force: force);
    ref.read(orderProvider).fetchOrders(force: force);

    // Fetch order tersedia di KL (Marketplace)
    final auth = ref.read(authProvider);
    final district = auth.user?['district_name']?.toString() ?? '';
    ref.read(orderProvider).fetchAvailableOrders(district);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
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
    final url =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _pickImage(AuthProvider auth) async {
    NyutjiImagePicker.show(
      context,
      title: "Pilih Foto Profil Kurir",
      primaryColor: primaryTeal,
      currentImageUrl: auth.user?['profile_photo'],
      onImagePicked: (XFile file) async {
        final success = await auth.updateProfilePhoto(file);
        if (mounted) {
          if (success) {
            NyutjiNotif.showSuccess(context, "Foto profil berhasil diperbarui");
          } else {
            NyutjiNotif.showError(context, "Gagal mengunggah foto");
          }
        }
      },
    );
  }

  Future<void> _captureTaskPhoto(
      String orderId, dynamic task, bool isDelivery) async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 50);

    if (photo != null) {
      if (mounted) {
        NyutjiLoadingOverlay.show(context, message: "Mengompresi WebP...");
      }
      final compressed = await NyutjiImagePicker.compressToWebP(photo);
      if (mounted) {
        NyutjiLoadingOverlay.hide(context);
        NyutjiLoadingOverlay.show(context,
            message: "Mengambil Koordinat GPS & Mengunggah...");
      }

      double? capturedLat;
      double? capturedLng;
      try {
        final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        capturedLat = pos.latitude;
        capturedLng = pos.longitude;
      } catch (e) {
        capturedLat = -6.3456;
        capturedLng = 106.7423;
      }

      final provider = ref.read(orderProvider);
      final step = isDelivery ? 'DONE' : 'PICKING_UP';
      final uploadSuccess = await provider.uploadPOWImage(
        orderId,
        XFile(compressed?.path ?? photo.path),
        step,
        lat: capturedLat,
        lng: capturedLng,
      );

      if (mounted) NyutjiLoadingOverlay.hide(context);

      if (!uploadSuccess) {
        if (mounted) {
          NyutjiNotif.showError(
              context, provider.errorMessage ?? "Gagal mengunggah foto POW");
        }
        return;
      }

      if (mounted) {
        setState(() {
          _taskCapturedImages[orderId] = File(compressed?.path ?? photo.path);
        });

        if (isDelivery) {
          _showSimulationBottomSheet(orderId, task);
        } else {
          NyutjiNotif.showSuccess(
              context, "Foto berhasil diunggah & disimpan.");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
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
                    ? const ColorFilter.mode(
                        Colors.transparent, BlendMode.multiply)
                    : const ColorFilter.matrix(<double>[
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ]),
                child: PageView(
                  controller: _pageController,
                  physics: isOnline
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) =>
                      setState(() => _selectedNavIndex = index),
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
      return Consumer(builder: (context, ref, _) {
        final auth = ref.watch(authProvider);
        return _buildPageTitleHeader(
            "Riwayat Tugas ${auth.user?['name'] ?? ''}", LucideIcons.history,
            auth: auth, forceIcon: true);
      });
    } else if (_selectedNavIndex == 2) {
      return Consumer(builder: (context, ref, _) {
        final auth = ref.watch(authProvider);
        return _buildPageTitleHeader(
            "Dompet ${auth.user?['name'] ?? ''}", LucideIcons.wallet,
            auth: auth, forceIcon: true);
      });
    } else {
      return Consumer(builder: (context, ref, _) {
        final auth = ref.watch(authProvider);
        return _buildPageTitleHeader(
            auth.user?['name'] ?? "Profil Kurir", LucideIcons.user,
            auth: auth, forceIcon: false);
      });
    }
  }

  Widget _buildPageTitleHeader(String title, IconData icon,
      {AuthProvider? auth, bool forceIcon = false}) {
    final photoUrl = auth?.user?['profile_photo'];
    final localPhoto = auth?.temporaryLocalPhoto;
    final district = auth?.user?['owner_district_name'] ??
        auth?.user?['district_name'] ??
        auth?.user?['district_code'] ??
        "";
    final city =
        auth?.user?['owner_city_name'] ?? auth?.user?['city_name'] ?? "";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (auth != null && !forceIcon) _pickImage(auth);
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryTeal.withValues(alpha: 0.1),
                border: Border.all(color: Colors.grey[300]!, width: 1.5),
                image: !forceIcon
                    ? (kIsWeb
                        ? (auth?.temporaryWebBytes != null
                            ? DecorationImage(
                                image: MemoryImage(auth!.temporaryWebBytes),
                                fit: BoxFit.cover)
                            : (photoUrl != null &&
                                    photoUrl.toString().isNotEmpty)
                                ? DecorationImage(
                                    image: CachedNetworkImageProvider(
                                        ApiConstants.profilePhotoUrl(photoUrl)),
                                    fit: BoxFit.cover)
                                : null)
                        : (localPhoto != null
                            ? DecorationImage(
                                image: FileImage(File(localPhoto)),
                                fit: BoxFit.cover)
                            : (photoUrl != null &&
                                    photoUrl.toString().isNotEmpty)
                                ? DecorationImage(
                                    image: CachedNetworkImageProvider(
                                        ApiConstants.profilePhotoUrl(photoUrl)),
                                    fit: BoxFit.cover)
                                : null))
                    : null,
              ),
              child: (forceIcon ||
                      (localPhoto == null &&
                          auth?.temporaryWebBytes == null &&
                          (photoUrl == null || photoUrl.toString().isEmpty)))
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
                  auth != null
                      ? (auth.user?['name'] ?? "Abang Kurir")
                      : "Abang Kurir Jago",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: darkText,
                      letterSpacing: 0.2),
                ),
                Text(
                  auth != null
                      ? "ID: ${auth.user?['identifier'] ?? '-'} \u2022 $district${city.isNotEmpty ? ' - $city' : ''}"
                      : "Nyutji Logistics Team",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                      fontSize: 10,
                      color: textGrey,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === HOME TAB (DENSE) ===
  Widget _buildHomeTab(Map<String, dynamic> currentT) {
    return RefreshIndicator(
      onRefresh: () => _refreshData(force: true),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // CARD ORDER TERSEDIA — paling atas, background putih
            _buildAvailableOrdersCard(),
            const SizedBox(height: 16),
            // GPS STRIP — ditukar ke atas
            _buildGpsLocationStrip(),
            const SizedBox(height: 16),
            _buildDenseTaskSection(currentT),
            const SizedBox(height: 16),
            // STATS PANEL — ditukar ke bawah
            _buildCompactStatsPanel(),
            SizedBox(height: 24 + MediaQuery.of(context).padding.bottom),
          ],
        ),
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
                Consumer(
                  builder: (context, ref, _) {
                    final auth = ref.watch(authProvider);
                    final photoUrl = auth.user?['profile_photo'];
                    final localPhoto = auth.temporaryLocalPhoto;
                    return GestureDetector(
                      onTap: () => _pickImage(auth),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryTeal.withValues(alpha: 0.1),
                          border:
                              Border.all(color: Colors.grey[300]!, width: 1.5),
                        ),
                        child: kIsWeb
                            ? (auth.temporaryWebBytes != null
                                ? Container(
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                            image: MemoryImage(
                                                auth.temporaryWebBytes),
                                            fit: BoxFit.cover)))
                                : (photoUrl != null &&
                                        photoUrl.toString().isNotEmpty)
                                    ? Container(
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                                image:
                                                    CachedNetworkImageProvider(
                                                  ApiConstants.profilePhotoUrl(
                                                      photoUrl),
                                                ),
                                                fit: BoxFit.cover)),
                                      )
                                    : Icon(LucideIcons.user,
                                        color: primaryTeal, size: 20))
                            : (localPhoto != null
                                ? Container(
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                            image: FileImage(File(localPhoto)),
                                            fit: BoxFit.cover)))
                                : (photoUrl != null &&
                                        photoUrl.toString().isNotEmpty)
                                    ? Container(
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                                image:
                                                    CachedNetworkImageProvider(
                                                        ApiConstants
                                                            .profilePhotoUrl(
                                                                photoUrl)),
                                                fit: BoxFit.cover)),
                                      )
                                    : Icon(LucideIcons.user,
                                        color: primaryTeal, size: 20)),
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
                      Consumer(builder: (context, ref, _) {
                        final auth = ref.watch(authProvider);
                        final district = auth.user?['owner_district_name'] ??
                            auth.user?['district_name'] ??
                            auth.user?['district_code'] ??
                            "";
                        final city = auth.user?['owner_city_name'] ??
                            auth.user?['city_name'] ??
                            "";
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(auth.user?['name'] ?? "Abang Kurir",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: darkText)),
                            Text(
                              "ID: ${auth.user?['identifier'] ?? '-'} \u2022 $district${city.isNotEmpty ? ' - $city' : ''}",
                              style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  color: textGrey,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        );
                      }),
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

  // GPS STRIP — paling bawah layar

  Widget _buildGpsLocationStrip() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.mapPin,
                size: 14, color: Color(0xFF0284C7)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Anda sekarang berada di",
                  style: GoogleFonts.montserrat(
                      fontSize: 10,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500),
                ),
                Text(
                  _gpsLocationText.isEmpty
                      ? "Mendeteksi lokasi..."
                      : _gpsLocationText,
                  style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatsPanel() {
    return Consumer(builder: (context, ref, _) {
      final orderProv = ref.watch(orderProvider);
      final history = orderProv.historyOrders;
      final today = DateTime.now();

      final todayOrders = history.where((o) {
        if (o['updatedAt'] == null && o['updated_at'] == null) return false;
        final dt = DateTime.tryParse(
            o['updatedAt']?.toString() ?? o['updated_at']?.toString() ?? '');
        if (dt == null) return false;
        final localDt = dt.toLocal();
        return localDt.year == today.year &&
            localDt.month == today.month &&
            localDt.day == today.day;
      }).toList();

      final int completedTasks = todayOrders.length;
      double totalDistance = 0.0;
      for (var o in todayOrders) {
        totalDistance += double.tryParse(
                (o['distance'] ?? o['distance_km'] ?? '0').toString()) ??
            0.0;
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryTeal.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                  color: primaryTeal.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Consumer(builder: (context, ref, _) {
                final wallet = ref.watch(walletProvider);
                return _buildStatCol(
                    "Pendapatan",
                    Formatters.currencyIdr(wallet.balance),
                    LucideIcons.wallet,
                    Colors.green[700]!);
              }),
              Container(width: 1, height: 30, color: Colors.grey[200]),
              _buildStatCol("Selesai", "$completedTasks Tugas",
                  LucideIcons.checkSquare, primaryTeal),
              Container(width: 1, height: 30, color: Colors.grey[200]),
              _buildStatCol(
                  "Jarak Tempuh",
                  "${totalDistance.toStringAsFixed(1).replaceAll('.0', '')} Km",
                  LucideIcons.navigation,
                  Colors.blue[700]!),
            ],
          ),
        ),
      );
    });
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
                border:
                    Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Icon(icon, size: 12, color: color),
            ),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: textGrey,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        Text(value,
            style: GoogleFonts.montserrat(
                fontSize: 13, fontWeight: FontWeight.w900, color: darkText)),
      ],
    );
  }

  // ============================================================
  // === HELPER UNTUK ALAMAT ====================================
  // ============================================================
  String _simplifyAddress(String fullAddress) {
    if (fullAddress.isEmpty || fullAddress == '-') return fullAddress;
    final parts = fullAddress.split(',');
    if (parts.length <= 2) return fullAddress;

    String jalan = parts[0].trim();
    String kecamatan = "";

    for (var part in parts) {
      if (part.toLowerCase().contains('kec.') ||
          part.toLowerCase().contains('kecamatan')) {
        kecamatan = part.trim();
        break;
      }
    }

    if (kecamatan.isNotEmpty) {
      return "$jalan, $kecamatan";
    }

    return "${parts[0].trim()}, ${parts[1].trim()}";
  }

  // ============================================================
  // === CARD ORDER TERSEDIA (PREMIUM MARKETPLACE) — PUTIH ======
  // ============================================================
  Widget _buildAvailableOrdersCard() {
    return Consumer(
      builder: (context, ref, _) {
        final orderProv = ref.watch(orderProvider);
        final displayOrders = orderProv.availableOrders;
        if (displayOrders.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryTeal.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                    color: primaryTeal.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8)),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.zap,
                            size: 18, color: Colors.black),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Order Tersedia",
                              style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: darkText,
                                  letterSpacing: 0.8),
                            ),
                            Text(
                              "${displayOrders.length} pesanan menunggu kurir",
                              style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  color: textGrey,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade100),

                // LIST ORDER
                ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayOrders.length,
                  separatorBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Colors.grey.shade100),
                  ),
                  itemBuilder: (ctx, index) {
                    final order = displayOrders[index];
                    final orderId = (order['order_number'] ??
                            order['orderNumber'] ??
                            order['identifier'] ??
                            order['id'] ??
                            '-')
                        .toString();
                    final price = double.tryParse((order['delivery_fee'] ??
                                order['deliveryFee'] ??
                                '0')
                            .toString()) ??
                        0.0;
                    final pickupRaw = order['address']?.toString() ??
                        order['customer']?['address']?.toString() ??
                        '-';
                    final shortPickupAddr = _simplifyAddress(pickupRaw);
                    final note = order['pickup_note']?.toString() ??
                        order['pickupNote']?.toString() ??
                        '';
                    final pickup = note.isNotEmpty
                        ? "$shortPickupAddr\nCatatan: $note"
                        : shortPickupAddr;
                    final mitraName = (order['mitra']?['name'] ??
                            order['mitra_name'] ??
                            'Mitra')
                        .toString();
                    final mitraAddrRaw = (order['mitra']?['address'] ??
                            order['mitra_address'] ??
                            '-')
                        .toString();
                    final mitraAddr = _simplifyAddress(mitraAddrRaw);
                    final isFast = order['is_fast_track'] == true ||
                        order['is_fast_track'] == 1 ||
                        order['isFastTrack'] == true;
                    final distance = double.tryParse(
                            (order['distance'] ?? order['distance_km'] ?? '0')
                                .toString()) ??
                        0.0;
                    final serviceType = (order['service_type'] ??
                            order['serviceType'] ??
                            'Reguler')
                        .toString();

                    final isDeliveryTask = order['status']?.toString().toUpperCase() == 'DELIVERING' ||
                        order['order_status']?.toString().toUpperCase() == 'DELIVERING';

                    return _buildAvailableOrderItem(
                      ctx: ctx,
                      orderId: orderId,
                      price: price,
                      pickup: pickup,
                      mitraName: mitraName,
                      mitraAddr: mitraAddr,
                      isFast: isFast,
                      distance: distance,
                      serviceType: serviceType,
                      isDeliveryTask: isDeliveryTask,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvailableOrderItem({
    required BuildContext ctx,
    required String orderId,
    required double price,
    required String pickup,
    required String mitraName,
    required String mitraAddr,
    required bool isFast,
    required double distance,
    required String serviceType,
    bool isDeliveryTask = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. JASA ANTAR — font 20px bold
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                isDeliveryTask
                    ? "Jasa Antar Balik: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price)}"
                    : "Jasa Jemput: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price)}",
                style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: primaryTeal),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 2. Order Number
        _buildInfoRow(LucideIcons.hash, "Order", orderId, Colors.black),
        const SizedBox(height: 8),

        // 3. Lokasi Jemput
        _buildInfoRow(
            LucideIcons.mapPin,
            isDeliveryTask ? "Jemput dari" : "Jemput di",
            isDeliveryTask ? "$mitraName ($mitraAddr)" : pickup,
            Colors.black),
        const SizedBox(height: 8),

        // 4. Lokasi Antar
        _buildRichInfoRow(
            isDeliveryTask ? LucideIcons.user : LucideIcons.store,
            isDeliveryTask ? "Kirim ke" : "Antar ke",
            TextSpan(
              children: [
                TextSpan(
                    text: isDeliveryTask ? "Pelanggan — " : "$mitraName — ",
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                TextSpan(
                    text: isDeliveryTask ? pickup : mitraAddr,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            Colors.black),
        const SizedBox(height: 8),

        // 5. Jarak
        _buildInfoRow(
            LucideIcons.navigation2,
            "Jarak",
            "${distance > 0 ? distance.toStringAsFixed(1) : '~'} km",
            Colors.black),
        const SizedBox(height: 8),

        // 6. Jenis Layanan
        _buildInfoRow(LucideIcons.layers, "Layanan", serviceType, Colors.black),
        const SizedBox(height: 16),

        // 7. SLIDER KONFIRMASI "MAU AMBIL"
        _buildSlideToConfirm(orderId),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        SizedBox(
          width: 75,
          child: Text(label,
              style: GoogleFonts.montserrat(
                  fontSize: 13, fontWeight: FontWeight.w600, color: textGrey)),
        ),
        Text(": ",
            style: GoogleFonts.montserrat(
                fontSize: 13, fontWeight: FontWeight.w600, color: textGrey)),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.montserrat(
                fontSize: 13, fontWeight: FontWeight.w700, color: darkText),
          ),
        ),
      ],
    );
  }

  Widget _buildRichInfoRow(
      IconData icon, String label, InlineSpan valueSpan, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        SizedBox(
          width: 75,
          child: Text(label,
              style: GoogleFonts.montserrat(
                  fontSize: 13, fontWeight: FontWeight.w600, color: textGrey)),
        ),
        Text(": ",
            style: GoogleFonts.montserrat(
                fontSize: 13, fontWeight: FontWeight.w600, color: textGrey)),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.montserrat(fontSize: 13, color: darkText),
              children: [valueSpan],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlideToConfirm(String orderId) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        const containerHeight = 52.0;
        const thumbSize = 42.0;
        const margin = 5.0;
        const maxSlide = 1.0;
        double val = 0.0;

        return StatefulBuilder(
          builder: (_, setState) {
            final thumbOffset =
                margin + val * (trackWidth - thumbSize - 2 * margin);
            final isDone = val >= 0.85;

            return GestureDetector(
              onHorizontalDragUpdate: (d) {
                final newVal =
                    (val + d.delta.dx / (trackWidth - thumbSize - 2 * margin))
                        .clamp(0.0, maxSlide);
                setState(() => val = newVal);
              },
              onHorizontalDragEnd: (_) {
                if (val >= 0.85) {
                  // Konfirmasi ambil order
                  _doAcceptOrder(orderId);
                } else {
                  // Snap kembali jika belum cukup
                  setState(() => val = 0.0);
                }
              },
              child: Container(
                height: containerHeight,
                decoration: BoxDecoration(
                  color: isDone
                      ? primaryTeal.withValues(alpha: 0.15)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(containerHeight / 2),
                  border: Border.all(
                    color: isDone
                        ? primaryTeal.withValues(alpha: 0.4)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Stack(
                  children: [
                    // Progress fill
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 50),
                      width: thumbOffset + thumbSize + margin,
                      decoration: BoxDecoration(
                        color:
                            primaryTeal.withValues(alpha: isDone ? 0.18 : 0.08),
                        borderRadius:
                            BorderRadius.circular(containerHeight / 2),
                      ),
                    ),
                    // Label teks di belakang
                    Center(
                      child: Opacity(
                        opacity: (1.0 - val * 2).clamp(0.0, 1.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.chevronsRight,
                                size: 18, color: textGrey),
                            const SizedBox(width: 4),
                            Text(
                              "Mau Ambil",
                              style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textGrey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Thumb
                    Positioned(
                      left: thumbOffset,
                      top: margin,
                      child: Container(
                        width: thumbSize,
                        height: thumbSize,
                        decoration: BoxDecoration(
                          color: isDone ? primaryTeal : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryTeal.withValues(
                                  alpha: isDone ? 0.4 : 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isDone ? LucideIcons.check : LucideIcons.chevronRight,
                          size: 20,
                          color: isDone ? Colors.white : primaryTeal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _doAcceptOrder(String orderId) async {
    final provider = ref.read(orderProvider);
    final success = await provider.acceptOrder(orderId);
    if (!mounted) return;
    if (success) {
      NyutjiNotif.showSuccess(context, "Order #$orderId berhasil diambil!");
      _scrollToTasks();
      _refreshData();
    } else {
      NyutjiNotif.showError(
          context, provider.errorMessage ?? "Gagal mengambil order");
    }
  }

  Widget _buildDenseTaskSection(Map<String, dynamic> currentT) {
    final activeOrders = ref.watch(orderProvider).activeOrders;
    final pickupCount = activeOrders.where((o) {
      final String rawDel = (o['deliveryType'] ?? o['delivery_type'] ?? '')
          .toString()
          .toUpperCase();
      final isSelfDrop = rawDel == 'SELF_DROP' ||
          rawDel == 'SELFDROP_SELFDELIVERY' ||
          rawDel == 'SELF_SERVICE';
      if (isSelfDrop) return false;
      final s =
          (o['status'] ?? o['order_status'] ?? '').toString().toUpperCase();
      return s == 'SEARCHING' ||
          s == 'WAITING_DROPOFF' ||
          s == 'COURIER_ACCEPTED' ||
          s == 'PICKING_UP' ||
          s == 'WEIGHING' ||
          s == 'WASH_START' ||
          s == 'IN_PROGRESS' ||
          s == 'PACKING';
    }).length;
    final deliveryCount = activeOrders.where((o) {
      final s =
          (o['status'] ?? o['order_status'] ?? '').toString().toUpperCase();
      return s == 'DELIVERING';
    }).length;

    // Auto-switch tab: jika data baru muncul dan tab saat ini belum dipilih/auto-selected
    if (!_hasDoneAutoSelect && activeOrders.isNotEmpty) {
      _hasDoneAutoSelect = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final hasPickup = pickupCount > 0;
        final hasDelivery = deliveryCount > 0;
        int target = 0;
        if (hasPickup && hasDelivery) {
          target = 0; // Prioritaskan Jemput (Pickup) jika kedua-duanya ada
        } else if (hasDelivery) {
          target = 1; // Antar (Delivery)
        } else {
          target = 0; // Jemput
        }
        if (_tabController.index != target) {
          setState(() => _tabController.index = target);
          _tabController.animateTo(target);
        }
      });
    }

    return Container(
      key: _taskSectionKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(currentT['current_tasks'],
                style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                    letterSpacing: 1.0)),
          ),
          const SizedBox(height: 12),

          // Modern Pill Segmented Control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 52,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(26),
              ),
              child: LayoutBuilder(builder: (context, constraints) {
                final halfWidth = constraints.maxWidth / 2;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      left: _tabController.index == 0 ? 0 : halfWidth,
                      right: _tabController.index == 0 ? halfWidth : 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              setState(() => _tabController.index = 0);
                              _tabController.animateTo(0);
                            },
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.arrowDownToLine,
                                      size: 14,
                                      color: _tabController.index == 0
                                          ? primaryTeal
                                          : textGrey),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Jemput (Pickup)",
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: _tabController.index == 0
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: _tabController.index == 0
                                          ? primaryTeal
                                          : textGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              setState(() => _tabController.index = 1);
                              _tabController.animateTo(1);
                            },
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.send,
                                      size: 14,
                                      color: _tabController.index == 1
                                          ? primaryTeal
                                          : textGrey),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Antar (Delivery)",
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: _tabController.index == 1
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: _tabController.index == 1
                                          ? primaryTeal
                                          : textGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // Dense List View (Real Data)
          Consumer(
            builder: (context, ref, _) {
              final orderProv = ref.watch(orderProvider);
              final activeOrders = orderProv.activeOrders;
              bool isPickupTab = _tabController.index == 0;

              final filtered = activeOrders.where((o) {
                // Sesuai Tabel Database: menggunakan kolom 'status'
                final s = (o['status'] ?? o['order_status'] ?? '')
                    .toString()
                    .toUpperCase();
                if (isPickupTab) {
                  final String rawDel =
                      (o['deliveryType'] ?? o['delivery_type'] ?? '')
                          .toString()
                          .toUpperCase();
                  final isSelfDrop = rawDel == 'SELF_DROP' ||
                      rawDel == 'SELFDROP_SELFDELIVERY' ||
                      rawDel == 'SELF_SERVICE';
                  if (isSelfDrop) return false;

                  // Pickup tasks are: WAITING_DROPOFF, COURIER_ACCEPTED, PICKING_UP, WEIGHING, WASH_START, IN_PROGRESS, PACKING
                  return s == 'SEARCHING' ||
                      s == 'WAITING_DROPOFF' ||
                      s == 'COURIER_ACCEPTED' ||
                      s == 'PICKING_UP' ||
                      s == 'WEIGHING' ||
                      s == 'WASH_START' ||
                      s == 'IN_PROGRESS' ||
                      s == 'PACKING';
                } else {
                  // Delivery tasks are: DELIVERING
                  return s == 'DELIVERING';
                }
              }).toList();

              if (filtered.isEmpty) {
                return Container(
                  height: 220,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/u8dtu3u.webp',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Tidak ada antrean tugas",
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
    final String orderId = (task['order_number'] ??
            task['orderNumber'] ??
            task['identifier'] ??
            task['id'] ??
            '-')
        .toString();
    final String customerName = task['customer']?['name']?.toString() ??
        task['customer_name']?.toString() ??
        'Pelanggan';

    // KL HANYA BOLEH LIHAT DELIVERY FEE (Jemput & Antar masing-masing 50%)
    final double rawPrice = double.tryParse((task['delivery_fee'] ??
                task['deliveryFee'] ??
                task['total_price'] ??
                '0')
            .toString()) ??
        0.0;
    final double price = rawPrice * 0.5;
    final bool isFast = task['is_fast_track'] == true ||
        task['is_fast_track'] == 1 ||
        task['isFastTrack'] == true;

    // Alamat & Pickup Note (MENGGUNAKAN WARNA MERAH SEBAGAI REMINDER)
    String addressRaw = task['address']?.toString() ??
        task['customer']?['address']?.toString() ??
        "Jl. Salak Raya No.23, Pd. Benda, Kec. Pamulang, Kota Tangerang Selatan, Banten 15416";
    if (addressRaw != "-" &&
        addressRaw.isNotEmpty &&
        addressRaw != "Alamat Pelanggan") {
      final parts = addressRaw.split(',');
      if (parts.length > 2) {
        addressRaw =
            "${parts[0].trim()}, ${parts[1].trim()}, ${parts[2].trim()}";
      } else if (parts.length > 1) {
        addressRaw = "${parts[0].trim()}, ${parts[1].trim()}";
      }
    }

    final String pickupNote =
        task['pickup_note']?.toString() ?? task['pickupNote']?.toString() ?? "";
    final String address = pickupNote.isNotEmpty
        ? "$addressRaw\nCatatan: $pickupNote"
        : addressRaw;

    // Status Order untuk membedakan Jemput vs Antar
    final String orderStatus =
        (task['status'] ?? task['order_status'] ?? '').toString().toUpperCase();
    final bool isDelivery = orderStatus == 'DELIVERING';
    final bool isPickupCompleted = orderStatus == 'WEIGHING' ||
        orderStatus == 'WASH_START' ||
        orderStatus == 'IN_PROGRESS' ||
        orderStatus == 'PACKING';

    final String priceText =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
            .format(price);
    final String laundryName = task['mitra']?['name']?.toString() ??
        task['mitra_name']?.toString() ??
        'Mitra Laundry';
    final String laundryAddress = task['mitra']?['address']?.toString() ??
        task['mitra_address']?.toString() ??
        'Alamat Laundry';

    // Temukan proof DELIVERING dan PICKING_UP jika ada
    final proofs = task['proofs'] as List?;
    dynamic deliveringProof;
    dynamic pickupProof;
    if (proofs != null) {
      for (var proof in proofs) {
        final step =
            (proof['step'] ?? proof['stage'] ?? '').toString().toUpperCase();
        if (step == 'DELIVERING') {
          deliveringProof = proof;
        } else if (step == 'PICKING_UP' || step == 'PICK_UP') {
          pickupProof = proof;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryTeal.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
              color: primaryTeal.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pitch sebelah kiri warna primaryTeal / merah untuk Fast Track
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: isFast ? Colors.red : primaryTeal,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
            // Isi Konten Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row Jasa Jemput/Antar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isDelivery
                              ? "Jasa Antar: $priceText"
                              : "Jasa Jemput: $priceText",
                          style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: primaryTeal),
                        ),
                        if (isFast)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6)),
                            child: Text("FAST TRACK",
                                style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.red)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Row Order Number
                    Row(
                      children: [
                        const Icon(LucideIcons.hash,
                            size: 14, color: Colors.black),
                        const SizedBox(width: 6),
                        Text(
                          "Order: $orderId",
                          style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textGrey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Row Nama Pelanggan
                    Row(
                      children: [
                        const Icon(LucideIcons.user,
                            size: 14, color: Colors.black),
                        const SizedBox(width: 6),
                        Text(
                          "Pelanggan: $customerName",
                          style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: darkText),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(
                        color: Color(0xFFE5E7EB),
                        height: 1,
                        thickness: 1), // Partisi abu-abu
                    const SizedBox(height: 12),

                    if (isDelivery) ...[
                      // Ambil dari (Laundry Mitra)
                      _buildLinkedStepRow(
                        label: "Ambil dari",
                        title: laundryName,
                        address: laundryAddress,
                        icon: LucideIcons.store,
                      ),
                      if (deliveringProof != null) ...[
                        const SizedBox(height: 8),
                        _buildNetworkPowPreview(
                            deliveringProof,
                            "Foto Cucian yang Diambil",
                            "Pengiriman Mitra",
                            "DELIVERING"),
                      ],
                      const SizedBox(height: 12),

                      // Antar ke (Alamat Pelanggan)
                      _buildLinkedStepRow(
                        label: "Antar ke",
                        title: customerName,
                        address: address,
                        icon: LucideIcons.mapPin,
                      ),
                      // Row POW Kurir (Jemput dari DB + Antar dari local/captured file)
                      _buildCourierPowsRow(pickupProof, orderId),
                    ] else ...[
                      // Jemput di (Alamat Pelanggan)
                      _buildLinkedStepRow(
                        label: "Jemput di",
                        title: customerName,
                        address: address,
                        icon: LucideIcons.mapPin,
                      ),
                      // Row POW Kurir (Jemput dari DB + local captured file)
                      _buildCourierPowsRow(pickupProof, orderId),
                      const SizedBox(height: 12),

                      // Antar ke (Laundry Mitra)
                      _buildLinkedStepRow(
                        label: "Antar ke",
                        title: laundryName,
                        address: laundryAddress,
                        icon: LucideIcons.store,
                      ),
                    ],
                    const SizedBox(height: 14),

                    // ── Chat & Call Buttons ──
                    _buildChatCallButtons(task, isDelivery),
                    const SizedBox(height: 14),

                    // Upload Foto Cucian
                    _buildUploadPhotoSection(
                      orderId,
                      task,
                      isDelivery,
                      isClickable: isDelivery ? true : !isPickupCompleted,
                    ),

                    // Action Button Selesai Jemput/Antar (Kapsul)
                    const SizedBox(height: 14),
                    _buildActionButton(
                      text: isDelivery ? "Selesai Antar" : "Selesai Jemput",
                      isEnabled: isDelivery
                          ? (_taskCapturedImages[orderId] != null &&
                              _simulatedCorrectLocation[orderId] == true &&
                              !_isUploading)
                          : (!isPickupCompleted &&
                              _taskCapturedImages[orderId] != null &&
                              !_isUploading),
                      onPressed: () => _completeTask(orderId, isDelivery),
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

  Widget _buildChatCallButtons(dynamic order, bool isDelivery) {
    final orderNumber =
        (order['order_number'] ?? order['orderNumber'] ?? '').toString();
    final customerName = ChatUtils.extractName(
        order['customer_name'] ?? order['customer'],
        fallback: 'Pelanggan');
    final customerPhoto =
        ChatUtils.extractPhoto(order['customer_name'] ?? order['customer']);
    final mitraName = ChatUtils.extractName(
        order['mitra_name'] ?? order['mitra'],
        fallback: 'Mitra');
    final mitraPhoto =
        ChatUtils.extractPhoto(order['mitra_name'] ?? order['mitra']);

    return Row(
      children: [
        // Chat dengan Mitra
        Expanded(
          child: _chatCallBtn(
            icon: LucideIcons.store,
            label: 'Chat Mitra',
            color: const Color(0xFF0D9488),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  orderNumber: orderNumber,
                  channel: 'ML_KL', // Channel is Courier-Mitra
                  partnerName: mitraName,
                  partnerRole: 'ML',
                  partnerPhoto: mitraPhoto,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Chat dengan Pelanggan
        Expanded(
          child: _chatCallBtn(
            icon: LucideIcons.user,
            label: 'Chat Pelanggan',
            color: const Color(0xFF7C3AED),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  orderNumber: orderNumber,
                  channel: 'PL_KL', // Channel is Courier-Customer
                  partnerName: customerName,
                  partnerRole: 'PL',
                  partnerPhoto: customerPhoto,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chatCallBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === BOTTOM NAV ===
  Widget _buildBottomNav(Map<String, dynamic> currentT) {
    return Consumer(
      builder: (context, ref, _) {
        final orderProv = ref.watch(orderProvider);
        final bool hasAlert = orderProv.availableOrders.isNotEmpty ||
            orderProv.activeOrders.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
                top: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5))
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / 4;
              return Stack(
                children: [
                  BottomNavigationBar(
                    items: <BottomNavigationBarItem>[
                      BottomNavigationBarItem(
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(LucideIcons.clipboardList, size: 22),
                            if (hasAlert)
                              const Positioned(
                                right: -4,
                                top: -4,
                                child: NyutjiDot.static(),
                              ),
                          ],
                        ),
                        activeIcon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(LucideIcons.clipboardList, size: 22),
                            if (hasAlert)
                              const Positioned(
                                right: -4,
                                top: -4,
                                child: NyutjiDot.static(),
                              ),
                          ],
                        ),
                        label: currentT['home'],
                      ),
                      BottomNavigationBarItem(
                          icon: const Icon(LucideIcons.history, size: 22),
                          activeIcon: const Icon(LucideIcons.history, size: 22),
                          label: currentT['history']),
                      BottomNavigationBarItem(
                          icon: const Icon(LucideIcons.wallet, size: 22),
                          activeIcon: const Icon(LucideIcons.wallet, size: 22),
                          label: currentT['wallet']),
                      BottomNavigationBarItem(
                          icon: const Icon(LucideIcons.user, size: 22),
                          activeIcon: const Icon(LucideIcons.user, size: 22),
                          label: currentT['profile']),
                    ],
                    currentIndex: _selectedNavIndex,
                    selectedItemColor: primaryTeal,
                    unselectedItemColor: textGrey.withValues(alpha: 0.6),
                    showUnselectedLabels: true,
                    onTap: (index) {
                      if (!isOnline && index != 0) return;
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutQuint,
                      );
                    },
                    backgroundColor: Colors.white,
                    elevation: 0,
                    type: BottomNavigationBarType.fixed,
                    selectedLabelStyle: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w800, fontSize: 10),
                    unselectedLabelStyle: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700, fontSize: 9),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutQuint,
                    top: 0,
                    left: (tabWidth * _selectedNavIndex) + (tabWidth / 2) - 30,
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
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLinkedStepRow({
    required String label,
    required String title,
    required String address,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label:",
          style: GoogleFonts.montserrat(
              fontSize: 12, fontWeight: FontWeight.w600, color: textGrey),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _openMap(address),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 16, color: const Color(0xFF0284C7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0284C7),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        address,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: darkText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(LucideIcons.externalLink,
                    size: 14, color: Color(0xFF0284C7)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkPowPreview(
      dynamic proof, String label, String title, String stage) {
    final String path =
        (proof['file_url'] ?? proof['imageUrl'] ?? proof['image_url'] ?? '')
            .toString()
            .replaceAll(RegExp(r'^/+'), '');
    if (path.isEmpty) return const SizedBox.shrink();
    final imageUrl =
        path.startsWith('http') ? path : "${ApiConstants.rootUrl}/$path";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
              fontSize: 11, fontWeight: FontWeight.w600, color: textGrey),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _showPowDialog([proof], [stage], title),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: Colors.teal),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image,
                      size: 24,
                      color: Colors.grey),
                ),
                // Security Watermarks (Rule II.12)
                Positioned(
                  top: 10,
                  left: -5,
                  child: IgnorePointer(
                    child: Transform.rotate(
                      angle: -0.785,
                      child: const Text(
                        'Nyutji',
                        style: TextStyle(
                          fontSize: 6,
                          fontWeight: FontWeight.bold,
                          color: Colors.white24,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Align(
                      alignment: Alignment.center,
                      child: Transform.rotate(
                        angle: -0.785,
                        child: const Text(
                          'Nyutji',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            color: Colors.white30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: -5,
                  child: IgnorePointer(
                    child: Transform.rotate(
                      angle: -0.785,
                      child: const Text(
                        'Nyutji',
                        style: TextStyle(
                          fontSize: 6,
                          fontWeight: FontWeight.bold,
                          color: Colors.white24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourierPowsRow(dynamic pickupProof, String orderId) {
    final hasPickup = pickupProof != null;
    final localDeliveryFile = _taskCapturedImages[orderId];
    final hasDelivery = localDeliveryFile != null;

    if (!hasPickup && !hasDelivery) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          "Foto Bukti Kurir:",
          style: GoogleFonts.montserrat(
              fontSize: 11, fontWeight: FontWeight.w600, color: textGrey),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (hasPickup) ...[
              GestureDetector(
                onTap: () => _showPowDialog(
                    [pickupProof], ['PICKING_UP', 'PICK_UP'], "Jemput Kurir"),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: (pickupProof['file_url'] ?? '')
                                .toString()
                                .startsWith('http')
                            ? (pickupProof['file_url'] ?? '').toString()
                            : "${ApiConstants.rootUrl}/${(pickupProof['file_url'] ?? '').toString().replaceAll(RegExp(r'^/+'), '')}",
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5, color: Colors.teal),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                            Icons.broken_image,
                            size: 24,
                            color: Colors.grey),
                      ),
                      // Watermarks
                      Positioned(
                        top: 10,
                        left: -5,
                        child: IgnorePointer(
                          child: Transform.rotate(
                            angle: -0.785,
                            child: const Text('Nyutji',
                                style: TextStyle(
                                    fontSize: 6,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white24)),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment.center,
                            child: Transform.rotate(
                              angle: -0.785,
                              child: const Text('Nyutji',
                                  style: TextStyle(
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white30)),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: -5,
                        child: IgnorePointer(
                          child: Transform.rotate(
                            angle: -0.785,
                            child: const Text('Nyutji',
                                style: TextStyle(
                                    fontSize: 6,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white24)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            if (hasDelivery) ...[
              GestureDetector(
                onTap: () => _showLocalPowDialog(localDeliveryFile, orderId),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        localDeliveryFile,
                        fit: BoxFit.cover,
                      ),
                      // Watermarks
                      Positioned(
                        top: 10,
                        left: -5,
                        child: IgnorePointer(
                          child: Transform.rotate(
                            angle: -0.785,
                            child: const Text('Nyutji',
                                style: TextStyle(
                                    fontSize: 6,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white24)),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment.center,
                            child: Transform.rotate(
                              angle: -0.785,
                              child: const Text('Nyutji',
                                  style: TextStyle(
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white30)),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: -5,
                        child: IgnorePointer(
                          child: Transform.rotate(
                            angle: -0.785,
                            child: const Text('Nyutji',
                                style: TextStyle(
                                    fontSize: 6,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white24)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _showPowDialog(
      List<dynamic>? proofs, List<String> targetStages, String title) {
    if (proofs == null || proofs.isEmpty) return;

    dynamic foundProof;
    for (var proof in proofs.reversed) {
      final step =
          (proof['step'] ?? proof['stage'] ?? '').toString().toUpperCase();
      if (targetStages.contains(step)) {
        foundProof = proof;
        break;
      }
    }

    if (foundProof == null) return;

    final String path = (foundProof['file_url'] ??
            foundProof['imageUrl'] ??
            foundProof['image_url'] ??
            '')
        .toString()
        .replaceAll(RegExp(r'^/+'), '');
    final imageUrl =
        path.startsWith('http') ? path : "${ApiConstants.rootUrl}/$path";

    final String orderId =
        (foundProof['orderId'] ?? foundProof['order_id'] ?? '-').toString();
    final String uploaderRole =
        (foundProof['uploader_role'] ?? foundProof['uploaderRole'] ?? 'PL')
            .toString()
            .toUpperCase();
    final String uploaderLabel = uploaderRole == 'ML'
        ? 'Mitra Laundry'
        : uploaderRole == 'KL'
            ? 'Kurir'
            : 'Pelanggan';
    String uploadedAt = '-';
    try {
      final dt = DateTime.tryParse(foundProof['createdAt']?.toString() ?? '');
      if (dt != null) {
        final local = dt.toLocal();
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'Mei',
          'Jun',
          'Jul',
          'Agu',
          'Sep',
          'Okt',
          'Nov',
          'Des'
        ];
        uploadedAt = '${local.day} ${months[local.month - 1]}, '
            '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} WIB';
      }
    } catch (_) {}

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        final screenH = MediaQuery.of(ctx).size.height;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Bukti $title",
                          style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: darkText),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                              color: Colors.grey[100], shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              size: 18, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
                // Foto + Watermarks
                SizedBox(
                  height: screenH * 0.55,
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.8,
                    maxScale: 5.0,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned.fill(
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.teal),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(Icons.broken_image_outlined,
                                  size: 52, color: Colors.grey),
                            ),
                          ),
                        ),
                        // Watermark 1
                        Positioned(
                          top: 40,
                          left: -10,
                          child: IgnorePointer(
                            child: Transform.rotate(
                              angle: -0.785,
                              child: Text(
                                'Nyutji Management',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white.withValues(alpha: 0.38),
                                  letterSpacing: 1.0,
                                  shadows: [
                                    const Shadow(
                                        color: Colors.black38, blurRadius: 4)
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Watermark 2
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Align(
                              alignment: const Alignment(0.2, 0.0),
                              child: Transform.rotate(
                                angle: -0.785,
                                child: Text(
                                  'Nyutji Management',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white.withValues(alpha: 0.42),
                                    letterSpacing: 1.2,
                                    shadows: [
                                      const Shadow(
                                          color: Colors.black38, blurRadius: 4)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Watermark 3
                        Positioned(
                          bottom: 60,
                          right: -10,
                          child: IgnorePointer(
                            child: Transform.rotate(
                              angle: -0.785,
                              child: Text(
                                'Nyutji Management',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white.withValues(alpha: 0.35),
                                  letterSpacing: 1.0,
                                  shadows: [
                                    const Shadow(
                                        color: Colors.black38, blurRadius: 4)
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Info overlay (No Order, Timestamp, Uploader)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 32, 16, 14),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black54, Colors.transparent],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(orderId,
                                    style: GoogleFonts.montserrat(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                                Text(uploadedAt,
                                    style: GoogleFonts.montserrat(
                                        fontSize: 10, color: Colors.white70)),
                                Text('oleh: $uploaderLabel',
                                    style: GoogleFonts.montserrat(
                                        fontSize: 10, color: Colors.white70)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLocalPowDialog(File file, String orderId) {
    const String uploaderLabel = 'Kurir';
    String uploadedAt = '-';
    try {
      final dt = DateTime.now();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];
      uploadedAt = '${dt.day} ${months[dt.month - 1]}, '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WIB';
    } catch (_) {}

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        final screenH = MediaQuery.of(ctx).size.height;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Bukti Foto Kurir",
                          style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: darkText),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                              color: Colors.grey[100], shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              size: 18, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
                // Foto + Watermarks
                SizedBox(
                  height: screenH * 0.55,
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.8,
                    maxScale: 5.0,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned.fill(
                          child: Image.file(
                            file,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Watermark 1
                        Positioned(
                          top: 40,
                          left: -10,
                          child: IgnorePointer(
                            child: Transform.rotate(
                              angle: -0.785,
                              child: Text(
                                'Nyutji Management',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white.withValues(alpha: 0.38),
                                  letterSpacing: 1.0,
                                  shadows: [
                                    const Shadow(
                                        color: Colors.black38, blurRadius: 4)
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Watermark 2
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Align(
                              alignment: const Alignment(0.2, 0.0),
                              child: Transform.rotate(
                                angle: -0.785,
                                child: Text(
                                  'Nyutji Management',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white.withValues(alpha: 0.42),
                                    letterSpacing: 1.2,
                                    shadows: [
                                      const Shadow(
                                          color: Colors.black38, blurRadius: 4)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Watermark 3
                        Positioned(
                          bottom: 60,
                          right: -10,
                          child: IgnorePointer(
                            child: Transform.rotate(
                              angle: -0.785,
                              child: Text(
                                'Nyutji Management',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white.withValues(alpha: 0.35),
                                  letterSpacing: 1.0,
                                  shadows: [
                                    const Shadow(
                                        color: Colors.black38, blurRadius: 4)
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Info overlay (No Order, Timestamp, Uploader)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 32, 16, 14),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black54, Colors.transparent],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(orderId,
                                    style: GoogleFonts.montserrat(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                                Text(uploadedAt,
                                    style: GoogleFonts.montserrat(
                                        fontSize: 10, color: Colors.white70)),
                                Text('oleh: $uploaderLabel',
                                    style: GoogleFonts.montserrat(
                                        fontSize: 10, color: Colors.white70)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUploadPhotoSection(String orderId, dynamic task, bool isDelivery,
      {bool isClickable = true}) {
    final hasImage = _taskCapturedImages[orderId] != null;
    final bool isSuccessGreen = isClickable &&
        (isDelivery
            ? (hasImage && _simulatedCorrectLocation[orderId] == true)
            : hasImage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: (isClickable && !isSuccessGreen)
              ? () => _captureTaskPhoto(orderId, task, isDelivery)
              : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSuccessGreen
                  ? Colors.green.shade50
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isSuccessGreen
                      ? Colors.green.shade200
                      : Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.camera,
                  size: 16,
                  color:
                      isSuccessGreen ? Colors.green.shade700 : Colors.black87,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Upload Foto Cucian",
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSuccessGreen
                          ? Colors.green.shade700
                          : Colors.black87,
                    ),
                  ),
                ),
                if (isSuccessGreen)
                  Icon(LucideIcons.checkCircle2,
                      size: 16, color: Colors.green.shade700)
                else
                  const Icon(LucideIcons.chevronRight,
                      size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String text,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    final Color btnColor = isEnabled ? primaryTeal : Colors.grey.shade400;
    final Color txtColor = isEnabled ? Colors.white : Colors.white70;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          foregroundColor: txtColor,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade500,
          elevation: isEnabled ? 2 : 0,
          shadowColor: primaryTeal.withValues(alpha: 0.2),
          shape: const StadiumBorder(),
        ),
        child: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(
                text.toUpperCase(),
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
      ),
    );
  }

  Future<void> _completeTask(String orderId, bool isDelivery) async {
    if (_taskCapturedImages[orderId] == null) {
      NyutjiNotif.showError(context, "Wajib upload foto sebelum Selesai!");
      return;
    }

    setState(() => _isUploading = true);
    final provider = ref.read(orderProvider);

    final String nextStatus = isDelivery ? 'DONE' : 'WEIGHING';
    final success = await provider.updateOrderStatus(orderId, nextStatus);

    if (mounted) {
      setState(() => _isUploading = false);
      if (success) {
        _taskCapturedImages.remove(orderId);
        _simulatedCorrectLocation.remove(orderId);
        if (isDelivery) {
          NyutjiNotif.showSuccess(
              context, "Tugas Selesai! Cucian telah diterima pelanggan.");
        } else {
          NyutjiNotif.showSuccess(context,
              "Tugas Selesai! Pesanan diteruskan ke Mitra (Timbangan).");
        }
        _refreshData();
      } else {
        NyutjiNotif.showError(
            context, provider.errorMessage ?? "Gagal memperbarui status");
      }
    }
  }

  void _showSimulationBottomSheet(String orderId, dynamic task) {
    final double destLat = double.tryParse((task['pickupLat'] ??
                task['pickup_lat'] ??
                task['lat'] ??
                task['latitude'] ??
                '-6.34789')
            .toString()) ??
        -6.34789;
    final double destLng = double.tryParse((task['pickupLng'] ??
                task['pickup_lng'] ??
                task['lng'] ??
                task['longitude'] ??
                '106.74012')
            .toString()) ??
        106.74012;

    final double wrongLat = destLat + 0.00456;
    final double wrongLng = destLng - 0.00512;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          clipBehavior: Clip.antiAlias,
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 20),
              Text(
                "Simulasi Verifikasi GPS",
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Pilih lokasi pengiriman kurir untuk memverifikasi apakah koordinat Anda sesuai dengan alamat antar pelanggan.",
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              _buildSimOptionCard(
                title: "Lokasi Kurir Sesuai Alamat Antar (Benar)",
                coords: "Lat: $destLat, Lng: $destLng",
                isCorrect: true,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _simulatedCorrectLocation[orderId] = true;
                  });
                  NyutjiNotif.showSuccess(this.context,
                      "Verifikasi Lokasi Berhasil! Koordinat kurir cocok dengan alamat antar.");
                },
              ),
              const SizedBox(height: 12),
              _buildSimOptionCard(
                title: "Lokasi Kurir di Luar Radius Antar (Salah)",
                coords: "Lat: $wrongLat, Lng: $wrongLng",
                isCorrect: false,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _simulatedCorrectLocation[orderId] = false;
                  });
                  _showWrongLocationDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimOptionCard({
    required String title,
    required String coords,
    required bool isCorrect,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isCorrect ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCorrect
                    ? const Color(0xFFD1FAE5)
                    : const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCorrect ? LucideIcons.check : LucideIcons.x,
                color: isCorrect
                    ? const Color(0xFF065F46)
                    : const Color(0xFF991B1B),
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    coords,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: textGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWrongLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.alertTriangle,
                    color: Color(0xFFDC2626),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  "Lokasi Antar Salah",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Cek kembali Lokasi Alamat Antar sesuai koordinat Map",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: darkText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "OK",
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
