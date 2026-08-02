import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/nyutji_theme.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'dart:async';
import 'dart:math' show cos, sqrt, asin;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/nyutji_scroll_physics.dart';
import '../../../providers/wallet_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../core/utils/formatters.dart';
import 'customer_order_screen.dart';
import 'customer_status_screen.dart';
import 'customer_cuci_khusus.dart';
import 'customer_cuci_sepatu.dart';
import 'customer_pakaian_bayi.dart';
import 'customer_dryclean.dart';
import '../../../core/utils/status_helper.dart';
import '../../../core/widgets/animated_status_ticker.dart';
import 'customer_wallet_screen.dart';
import 'customer_main_screen.dart';
import 'customer_scheduler_screen.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'customer_payment_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/customer_theme_provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:hive/hive.dart';
import '../../../core/widgets/nyutji_coach_mark.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  final GlobalKey? keyStatusTab;
  final GlobalKey? keyProfileTab;

  const CustomerHomeScreen({
    super.key,
    this.keyStatusTab,
    this.keyProfileTab,
  });

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _promoController = ScrollController();
  bool _showBackToTop = false;
  bool _sortClosest = true;
  double? _currentLat;
  double? _currentLng;

  final GlobalKey _keyTracking = GlobalKey();
  final GlobalKey _keyDompet = GlobalKey();
  final GlobalKey _keyPickUp = GlobalKey();
  final GlobalKey _keySepatu = GlobalKey();
  final GlobalKey _keyPromo = GlobalKey();
  final GlobalKey _keyMitra = GlobalKey();
  bool _tutorialTriggered = false;

  @override
  void initState() {
    super.initState();
    _mainScrollController.addListener(() {
      if (_mainScrollController.offset > 500) {
        if (!_showBackToTop) setState(() => _showBackToTop = true);
      } else {
        if (_showBackToTop) setState(() => _showBackToTop = false);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider).fetchWallet();
      ref.read(orderProvider).fetchOrders();
      ref.read(orderProvider).fetchDraftOrders();
      _fetchMitrasByLocation();
      // _startPromoMarquee(); // Disabled marquee
    });
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  Future<void> _fetchMitrasByLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) ref.read(orderProvider).fetchRecommendedMitras();
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) ref.read(orderProvider).fetchRecommendedMitras();
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) ref.read(orderProvider).fetchRecommendedMitras();
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
      });

      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}');
      final response =
          await http.get(url, headers: {'User-Agent': 'nyutjimanagement/1.0'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        String? city = address['city'] ??
            address['county'] ??
            address['town'] ??
            address['state'];

        if (city != null) {
          city =
              city.replaceAll('Kota ', '').replaceAll('Kabupaten ', '').trim();
          if (!mounted) return;
          ref.read(orderProvider).fetchRecommendedMitras(cityName: city);
        } else {
          if (mounted) ref.read(orderProvider).fetchRecommendedMitras();
        }
      } else {
        if (mounted) ref.read(orderProvider).fetchRecommendedMitras();
      }
    } catch (e) {
      if (mounted) ref.read(orderProvider).fetchRecommendedMitras();
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final theme = ref.watch(customerThemeProvider);
    final Map<String, dynamic> t = {
      'id': {
        'greeting': 'Pelanggan Pamulang',
        'sub_greeting': 'Pamulang, Tangerang Selatan',
        'pay_label': 'Dompet Nyutji',
        'points_label': 'Poin',
        'voucher_label': 'Voucher',
        'active_text': 'Aktif',
        'main_services': 'Layanan Utama',
      },
      'en': {
        'greeting': 'Pamulang Customer',
        'sub_greeting': 'Pamulang, South Tangerang',
        'pay_label': 'Nyutji Wallet',
        'points_label': 'Points',
        'voucher_label': 'Voucher',
        'active_text': 'Active',
        'main_services': 'Main Services',
      }
    };
    final currentT = t[auth.lang] ?? t['id'];

    final orderProv = ref.watch(orderProvider);
    if (orderProv.isFirstFetchDone && !orderProv.isLoading && !_tutorialTriggered) {
      _tutorialTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final hasSeen = Hive.box('nyutji_cache').get('tutorial_customer_home', defaultValue: false);
        if (!hasSeen) {
           Future.delayed(const Duration(milliseconds: 1200), () {
             if (mounted) _showTutorialCoachMark();
           });
        }
      });
    }

    return Scaffold(
      backgroundColor: theme.bg,
      floatingActionButton: _showBackToTop
          ? FloatingActionButton(
              mini: true,
              backgroundColor: theme.primary,
              onPressed: () => _mainScrollController.animateTo(0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut),
              child:
                  const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(walletProvider).fetchWallet(force: true),
            ref.read(orderProvider).fetchOrders(force: true),
            ref.read(orderProvider).fetchDraftOrders(),
            _fetchMitrasByLocation(),
          ]);
        },
        color: theme.primary,
        child: SingleChildScrollView(
          controller: _mainScrollController,
          physics: const AlwaysScrollableScrollPhysics(
              parent: NyutjiScrollPhysics()),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildHeader(currentT, auth),
                  Positioned(
                    bottom: -15,
                    left: 16,
                    right: 16,
                    child: Container(key: _keyTracking, child: _buildActiveTrackingBanner(currentT)),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Container(key: _keyDompet, child: _buildFinancialStrip(currentT)),
              const SizedBox(height: 20),
              _buildDenseServicesGrid(currentT),
              const SizedBox(height: 24),
              Container(key: _keyPromo, child: _buildPromoSection(currentT)),
              const SizedBox(height: 24),
              Container(key: _keyMitra, child: _buildMitraSection(currentT, auth)),
              SizedBox(height: 80 + MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> currentT, AuthProvider auth) {
    final theme = ref.watch(customerThemeProvider);
    final district = auth.user?['owner_district_name'] ??
        auth.user?['district_name'] ??
        'Pamulang';

    final hour = DateTime.now().hour;
    String timeGreeting = 'Selamat Pagi';
    if (hour >= 11 && hour < 15) {
      timeGreeting = 'Selamat Siang';
    } else if (hour >= 15 && hour < 18) {
      timeGreeting = 'Selamat Sore';
    } else if (hour >= 18 || hour < 4) {
      timeGreeting = 'Selamat Malam';
    }

    return ClipPath(
      clipper: HeaderClipper(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 70),
        decoration: theme.mode == CustomerThemeMode.gold
            ? const BoxDecoration(color: Color(0xFF403600))
            : BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primary, theme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(timeGreeting,
                      style: NyutjiTheme.detail(Colors.white70).copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(auth.user?['name'] ?? currentT['greeting'],
                      style:
                          NyutjiTheme.h2(Colors.white).copyWith(fontSize: 20)),
                  const SizedBox(height: 2),
                  Text(district,
                      style: NyutjiTheme.detail(Colors.white70)
                          .copyWith(fontSize: 13)),
                ],
              ),
            ),
            IconButton(
              icon:
                  const Icon(LucideIcons.search, color: Colors.white, size: 24),
              onPressed: () => _showGlobalSearchSheet(context),
            ),
            Consumer(builder: (context, ref, _) {
              final orderProv = ref.watch(orderProvider);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  const IconButton(
                    icon: Icon(LucideIcons.bell, color: Colors.white, size: 24),
                    onPressed: null, // Disabled tap per user request
                  ),
                  if (orderProv.activeOrders.isNotEmpty)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC3312E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFF403600), width: 1.5),
                        ),
                        child: Text(
                          '${orderProv.activeOrders.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTrackingBanner(Map<String, dynamic> currentT) {
    return Consumer(
      builder: (context, ref, _) {
        final orderProv = ref.watch(orderProvider);
        final activeOrders = orderProv.activeOrders
            .where((o) => (o['status'] ?? o['order_status'] ?? '')
                    .toString()
                    .toUpperCase() !=
                'DRAFT')
            .toList();

        final bool hasOrder = activeOrders.isNotEmpty;

        // Kumpulkan semua status aktif dalam Bahasa Indonesia
        final List<String> activeStatuses = hasOrder
            ? activeOrders.map((o) {
                final raw = (o['status'] ?? o['order_status'] ?? '')
                    .toString();
                final rawUp = raw.toUpperCase();
                final rawDel = (o['deliveryType'] ?? o['delivery_type'] ?? '')
                    .toString()
                    .toUpperCase();
                final isSelfDrop = rawDel == 'SELF_DROP' ||
                    rawDel == 'SELFDROP_SELFDELIVERY' ||
                    rawDel == 'SELF_SERVICE';
                final displayStatus =
                    (isSelfDrop && (rawUp == 'WAITING_DROPOFF' || rawUp == 'SEARCHING'))
                        ? 'WEIGHING'
                        : raw;
                return StatusHelper.getLabel(displayStatus, 'PL');
              }).toList()
            : ['Belum ada pesanan aktif'];

        final String headerLabel =
            hasOrder ? 'LACAK PROGRESS CUCIAN' : 'Ayo Cuci Sekarang';

        return GestureDetector(
          onTap: () {
            if (hasOrder) {
              final mainState =
                  context.findAncestorStateOfType<CustomerMainScreenState>();
              if (mainState != null) {
                mainState.switchToTab(1);
              } else {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CustomerStatusScreen()));
              }
            } else {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const CustomerOrderScreen(orderType: 'pickup')));
            }
          },
          child: Builder(
            builder: (context) {
              final theme = ref.watch(customerThemeProvider);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.border, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                          hasOrder ? LucideIcons.loader : LucideIcons.shoppingBag,
                          size: 22,
                          color: theme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            headerLabel,
                            style: GoogleFonts.montserrat(
                                color: theme.primary,
                                fontWeight: FontWeight.w900, fontSize: 11),
                          ),
                          if (hasOrder)
                            AnimatedStatusTicker(
                              statuses: activeStatuses,
                              style: GoogleFonts.montserrat(
                                  color: theme.text,
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            )
                          else
                            Text(
                              'Order Nyutji Yuks !!',
                              style: GoogleFonts.montserrat(
                                  color: theme.text,
                                  fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: theme.primary),
                  ],
                ),
              );
            }
          ),
        );
      },
    );
  }

  Widget _buildFinancialStrip(Map<String, dynamic> currentT) {
    final theme = ref.watch(customerThemeProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.primary.withValues(alpha: 0.25),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Consumer(builder: (context, ref, _) {
                final wallet = ref.watch(walletProvider);
                return _buildFinItem(
                    Icons.account_balance_wallet,
                    currentT['pay_label'],
                    Formatters.currencyIdr(wallet.balance));
              }),
            ),
            Container(width: 1, height: 40, color: Colors.white24),
            Expanded(
              child: _buildFinItem(
                  Icons.star_border, currentT['points_label'], "2.400"),
            ),
            Container(width: 1, height: 40, color: Colors.white24),
            Expanded(
              child: _buildFinItem(Icons.confirmation_number_outlined,
                  currentT['voucher_label'], "4 ${currentT['active_text']}"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Text(label, style: NyutjiTheme.detail(Colors.white70)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value,
            style:
                NyutjiTheme.h2(const Color(0xFFDAC66F)).copyWith(fontSize: 16)),
      ],
    );
  }

  Widget _buildDenseServicesGrid(Map<String, dynamic> currentT) {
    final draftsCount = ref.watch(orderProvider).draftOrders.length;

    final theme = ref.watch(customerThemeProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(currentT['main_services'],
              style: NyutjiTheme.h2(theme.text)
                  .copyWith(fontSize: 22)),
          const SizedBox(height: 16),
          MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 8,
              childAspectRatio: 0.65,
              children: [
                // Baris 1
                Container(
                  key: _keyPickUp,
                  child: _buildServiceItem("Pick Up\nKurir", "icon_pickup.png",
                      hasPromo: true,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CustomerOrderScreen(
                                  orderType: 'pickup')))),
                ),
                _buildServiceItem("Antar\nSendiri", "icon_dropoff.png",
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const CustomerOrderScreen(orderType: 'drop')))),
                _buildServiceItem("Nyutji\nCoin", "icon_coin.png", onTap: () {
                  NyutjiNotif.showInfo(
                      context, "Fitur Nyutji Coin akan segera hadir");
                }),
                _buildServiceItem("Top-Up", "icon_topup.png", onTap: () {
                  final mainState = context
                      .findAncestorStateOfType<CustomerMainScreenState>();
                  if (mainState != null) {
                    mainState.switchToTab(2);
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CustomerWalletScreen()));
                  }
                }),
                // Baris 2
                _buildServiceItem("Cuci\nKhusus", "baby_stroller.png",
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CustomerCuciKhususScreen()))),
                _buildServiceItem("Dry\nClean", "icon_dryclean.png",
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CustomerDryCleanScreen()))),
                Container(
                  key: _keySepatu,
                  child: _buildServiceItem("Cuci\nSepatu", "icon_sepatu.png",
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CustomerCuciSepatuScreen()))),
                ),
                _buildServiceItem("Pakaian\nBayi", "icon_bayi.png",
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const CustomerPakaianBayiScreen()))),
                // Baris 3
                _buildServiceItem("Jadwal", "icon_jadwal.png",
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CustomerSchedulerScreen()))),
                _buildServiceItem("Cek Status", "icon_status.png", onTap: () {
                  final mainState = context
                      .findAncestorStateOfType<CustomerMainScreenState>();
                  if (mainState != null) {
                    mainState.switchToTab(1);
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CustomerStatusScreen()));
                  }
                }),
                _buildServiceItem("Keranjang", "icon_keranjang.png",
                    badgeCount: draftsCount, onTap: () {
                  _showKeranjangDraftBottomSheet();
                }),
                _buildServiceItem("Bantuan", "icon_bantuan.png",
                    onTap: () => _showBantuanBottomSheet()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBantuanBottomSheet() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          final bottomPadding = MediaQuery.of(ctx).padding.bottom;
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
            padding:
                EdgeInsets.only(bottom: bottomPadding > 0 ? bottomPadding : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Image.asset('assets/icons/app_icon.png',
                      width: 60, height: 60),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    "Bantuan dari Ny Utji",
                    style: NyutjiTheme.h2(const Color(0xFF131109))
                        .copyWith(fontSize: 22),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFaqItem(
                            "Apakah cucian saya akan dicampur dengan milik pelanggan lain?",
                            "Sama sekali tidak. Nyutji menerapkan standar ketat 1 pelanggan = 1 mesin cuci & 1 mesin pengering. Higienitas dan keamanan pakaian Anda adalah prioritas utama kami."),
                        _buildFaqItem(
                            "Bagaimana jika ada pakaian saya yang tertukar atau rusak?",
                            "Nyutji memberikan Garansi Layanan. Jika terdapat pakaian yang tertukar atau rusak akibat kelalaian operasional kami, segera laporkan ke admin outlet dalam waktu maksimal 24 jam setelah pakaian diterima dengan membawa struk digital Anda. Kami akan melakukan investigasi dan memberikan ganti rugi sesuai ketentuan yang berlaku."),
                        _buildFaqItem(
                            "Berapa lama batas waktu maksimal pengambilan pakaian yang sudah selesai?",
                            "Pakaian yang telah selesai diproses wajib diambil dalam waktu 14 hari kalender. Kehilangan atau kerusakan pada pakaian yang tidak diambil lebih dari 30 hari di luar tanggung jawab Nyutji Laundry."),
                        _buildFaqItem(
                            "Metode pembayaran apa saja yang didukung?",
                            "Kami menerima pembayaran tunai di kasir, Transfer Bank, serta pembayaran non-tunai praktis menggunakan QRIS (GoPay, OVO, Dana, ShopeePay, LinkAja, dan Mobile Banking)."),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF403600).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFF556B2F)
                                    .withValues(alpha: 0.2),
                                width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Punya saran, kritik, atau keluhan yang belum terselesaikan?",
                                style: NyutjiTheme.h2(const Color(0xFF403600))
                                    .copyWith(fontSize: 15),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Hubungi Customer Care Nyutji via WhatsApp di 0812-3456-7890 atau email nyutji-care@nyutji.com.\n\nKritik Anda membantu kami tumbuh lebih bersih dan profesional!",
                                style: NyutjiTheme.body(const Color(0xFF131109))
                                    .copyWith(fontSize: 13, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  Widget _buildFaqItem(String question, String answer) {
    final theme = ref.watch(customerThemeProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border, width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: theme.primary,
          collapsedIconColor: theme.primary,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            question,
            style: NyutjiTheme.h2(theme.text)
                .copyWith(fontSize: 14, height: 1.4),
          ),
          children: [
            Text(
              answer,
              style: NyutjiTheme.body(theme.subtext)
                  .copyWith(fontSize: 13, height: 1.6),
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _showKeranjangDraftBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final orderProv = ref.watch(orderProvider);
            final drafts = orderProv.draftOrders;
            final bottomPadding = MediaQuery.of(context).padding.bottom;
            const Color primaryTeal = Color(0xFF403600);
            const Color accentGold = Color(0xFFF59E0B);

            return Container(
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30)),
              ),
              padding: EdgeInsets.only(
                  bottom: bottomPadding > 0 ? bottomPadding : 0),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  // ── Stack tunggal: gambar di belakang, header di depan ──
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Kolom pemberi ukuran: ruang header + divider
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 64), // ≈ tinggi header
                          Divider(height: 1),
                        ],
                      ),
                      // Gambar karakter — menabrak ke atas divider (di belakang header)
                      if (drafts.isEmpty)
                        Positioned(
                          top: -95,
                          right: 0,
                          child: IgnorePointer(
                            child: Image.asset(
                              'assets/images/546597.webp',
                              width: 310,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      // Header — anak TERAKHIR = dilukis paling depan (bring to front)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.shoppingBag,
                                  color: primaryTeal),
                              const SizedBox(width: 12),
                              Text(
                                "Draft Pesanan",
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF131109),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: drafts.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 32),
                              Text(
                                "Belum ada order Nyutji.",
                                style: GoogleFonts.montserrat(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(ctx);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const CustomerOrderScreen()),
                                  );
                                },
                                child: Text(
                                  "Pesan Sekarang",
                                  style: GoogleFonts.montserrat(
                                    color: const Color(0xFF403600),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                    decorationColor: const Color(0xFF403600),
                                    decorationThickness: 2,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            physics: const BouncingScrollPhysics(),
                            itemCount: drafts.length,
                            itemBuilder: (context, index) {
                              final draft = drafts[index];
                              final mitraName =
                                  draft['mitra']?['name'] ?? 'Mitra';
                              final date = draft['createdAt'] != null
                                  ? DateTime.parse(draft['createdAt'])
                                      .toLocal()
                                      .toString()
                                      .split(' ')[0]
                                  : '';
                              final orderIdStr = (draft['orderNumber'] ??
                                      draft['order_number'] ??
                                      draft['id'] ??
                                      index)
                                  .toString();

                              return Dismissible(
                                key: Key(orderIdStr),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.red[100]!),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        "Hapus cucian ?",
                                        style: GoogleFonts.montserrat(
                                          color: Colors.red[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(LucideIcons.trash2,
                                          color: Colors.red, size: 20),
                                    ],
                                  ),
                                ),
                                onDismissed: (direction) {
                                  orderProv.deleteDraft(orderIdStr);
                                },
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _resumeDraft(draft);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border:
                                          Border.all(color: Colors.grey[200]!),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.02),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: accentGold.withValues(
                                                alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                              LucideIcons.fileText,
                                              color: accentGold,
                                              size: 20),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                mitraName,
                                                style: GoogleFonts.montserrat(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w800),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "Draft: $date",
                                                style: GoogleFonts.montserrat(
                                                    fontSize: 11,
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(LucideIcons.chevronRight,
                                            color: Colors.grey, size: 18),
                                      ],
                                    ),
                                  ),
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
      },
    );
  }

  void _resumeDraft(Map<String, dynamic> draft) {
    // 1. Ekstrak data
    final draftItems = draft['items'] as List?;
    if (draftItems == null || draftItems.isEmpty) return;

    final mitra = draft['mitra'];
    if (mitra == null) return;

    final String mitraIdStr =
        (draft['mitraId'] ?? draft['mitra_id']).toString();
    final String districtName =
        mitra['district_name'] ?? mitra['owner_district_name'] ?? '';
    final String cityName =
        mitra['city_name'] ?? mitra['owner_city_name'] ?? '';
    final String districtCode = draft['district_code'] ?? 'NYJ';

    // 2. Ambil harga terbaru mitra dari recommendedMitras (jika ada)
    final recommendedMitras = ref.read(orderProvider).recommendedMitras;
    final currentMitra = recommendedMitras.firstWhere(
      (m) => m is Map && m['id'].toString() == mitraIdStr,
      orElse: () => mitra,
    );

    List<Map<String, dynamic>> updatedItems = [];
    double newTotalPrice = 0.0;
    int newTotalItems = 0;

    final List? liveItems = currentMitra['items'] as List?;

    for (var dItem in draftItems) {
      if (dItem is! Map) continue;
      // Cari item di live data untuk harga terbaru
      final liveItem = liveItems?.firstWhere(
          (i) => i is Map && i['name'] == dItem['itemName'],
          orElse: () => null);

      bool isFast = draft['serviceType'] == 'SAME_DAY';
      double pricePerUnit =
          double.tryParse(dItem['pricePerUnit']?.toString() ?? '0') ?? 0.0;

      // Update dengan harga baru jika ada
      if (liveItem != null) {
        double pReg = double.tryParse(liveItem['price_regular']?.toString() ??
                liveItem['price']?.toString() ??
                '0') ??
            0.0;
        double? pFastRaw =
            double.tryParse(liveItem['price_fast']?.toString() ?? '');
        double pFast = (pFastRaw == null || pFastRaw == 0) ? pReg : pFastRaw;
        pricePerUnit = isFast ? pFast : pReg;
      }

      final qty = int.tryParse(dItem['qty']?.toString() ?? '1') ?? 1;
      updatedItems.add({
        'name': dItem['itemName'],
        'count': qty,
        'unit': dItem['unit'],
        'price': pricePerUnit,
        'category': dItem['category'],
      });

      newTotalPrice += (pricePerUnit * qty);
      newTotalItems += qty;
    }

    final double lat =
        double.tryParse(draft['pickupLat']?.toString() ?? '0') ?? 0.0;
    final double lng =
        double.tryParse(draft['pickupLng']?.toString() ?? '0') ?? 0.0;

    double mitraLat = 0.0;
    if (mitra['lat'] != null) {
      mitraLat = double.tryParse(mitra['lat'].toString()) ?? 0.0;
    }
    double mitraLng = 0.0;
    if (mitra['lng'] != null) {
      mitraLng = double.tryParse(mitra['lng'].toString()) ?? 0.0;
    }

    final isPickup = draft['deliveryType'] == 'PICKUP';

    final String orderIdStr =
        (draft['orderNumber'] ?? draft['order_number'] ?? draft['id'] ?? '')
            .toString();

    double distanceVal = 0.0;
    if (draft['distance'] != null) {
      distanceVal = double.tryParse(draft['distance'].toString()) ?? 0.0;
    }

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CustomerPaymentScreen(
                  totalPrice: newTotalPrice.toInt(),
                  totalItems: newTotalItems,
                  address: draft['address'] ?? '',
                  isPickup: isPickup,
                  mitraId: mitraIdStr,
                  mitraName: mitra['name'] ?? 'Mitra',
                  orderType: isPickup ? 'pickup' : 'drop',
                  speed:
                      draft['serviceType'] == 'SAME_DAY' ? 'fast' : 'regular',
                  distance: distanceVal,
                  dropMethod: isPickup
                      ? ''
                      : (draft['deliveryType'] == 'SELFDROP_SELFDELIVERY'
                          ? 'self'
                          : 'courier'),
                  selectedItemsList: updatedItems,
                  districtName: districtName,
                  districtCode: districtCode,
                  cityName: cityName,
                  lat: lat,
                  lng: lng,
                  mitraLat: mitraLat,
                  mitraLng: mitraLng,
                  pickupNote: draft['pickupNote'] ?? '',
                  mitraAddress: mitra['address'] ?? '',
                  mitraDistrict: districtName,
                  draftOrderNumber: orderIdStr,
                )));
  }

  Widget _buildServiceItem(String label, String iconPath,
      {bool hasPromo = false, int badgeCount = 0, VoidCallback? onTap}) {
    final theme = ref.watch(customerThemeProvider);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset("assets/icons/$iconPath",
                  width: 70,
                  height: 70,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image, size: 50)),
              if (hasPromo)
                Positioned(
                  top: 0,
                  right: -5,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                        color: const Color(0xFFC3312E),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text("PROMO",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              if (badgeCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Color(0xFFC3312E), shape: BoxShape.circle),
                    constraints:
                        const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Center(
                      child: Text(
                        badgeCount.toString(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label,
                textAlign: TextAlign.center,
                style: NyutjiTheme.body(theme.text)
                    .copyWith(fontSize: 13, height: 1.1)),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoSection(Map<String, dynamic> currentT) {
    final theme = ref.watch(customerThemeProvider);
    final promoItems = [
      {
        'title': 'NyutjiPay Special',
        'tag': 'Cashback Kece',
        'img': '${ApiConstants.rootUrl}/storage/1.webp',
        'narration':
            'Top Up Sekarang Dapatkan Cashback Instan Untuk Transaksi Laundry Pertama Anda'
      },
      {
        'title': 'Cuci Kilat 6 Jam',
        'tag': 'Ekspres',
        'img': '${ApiConstants.rootUrl}/storage/2.webp',
        'narration':
            'Waktu Sangat Berharga Biarkan Kami Menyelesaikan Cucian Anda Dalam Waktu Singkat'
      },
      {
        'title': 'Voucher Berkah',
        'tag': 'Limited',
        'img': '${ApiConstants.rootUrl}/storage/3.webp',
        'narration':
            'Berbagi Kebaikan Dengan Voucher Potongan Harga Spesial Untuk Pelanggan Setia Nyutji'
      },
      {
        'title': 'Member Platinum',
        'tag': 'Premium',
        'img': '${ApiConstants.rootUrl}/storage/4.webp',
        'narration':
            'Nikmati Layanan Prioritas Dan Antrean Khusus Untuk Member Platinum Terpilih Nyutji'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text("Promo & Diskon Spesial",
                    style: NyutjiTheme.h2(theme.text)
                        .copyWith(fontSize: 20)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showPromoBottomSheet(),
                child: Text("Lihat Semua",
                    style: NyutjiTheme.body(theme.primary)
                        .copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            controller: _promoController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: promoItems.length,
            itemBuilder: (context, index) {
              final item = promoItems[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildPromoCard(item['title']!, item['tag']!,
                    item['img']!, item['narration']!),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showPromoBottomSheet() {
    final allPromos = [
      {
        'title': 'NyutjiPay Special',
        'tag': 'Cashback Kece',
        'img': '${ApiConstants.rootUrl}/storage/1.webp',
        'narration':
            'Top Up Sekarang Dapatkan Cashback Instan Untuk Transaksi Laundry Pertama Anda'
      },
      {
        'title': 'Cuci Kilat 6 Jam',
        'tag': 'Ekspres',
        'img': '${ApiConstants.rootUrl}/storage/2.webp',
        'narration':
            'Waktu Sangat Berharga Biarkan Kami Menyelesaikan Cucian Anda Dalam Waktu Singkat'
      },
      {
        'title': 'Voucher Berkah',
        'tag': 'Limited',
        'img': '${ApiConstants.rootUrl}/storage/3.webp',
        'narration':
            'Berbagi Kebaikan Dengan Voucher Potongan Harga Spesial Untuk Pelanggan Setia Nyutji'
      },
      {
        'title': 'Member Platinum',
        'tag': 'Premium',
        'img': '${ApiConstants.rootUrl}/storage/4.webp',
        'narration':
            'Nikmati Layanan Prioritas Dan Antrean Khusus Untuk Member Platinum Terpilih Nyutji'
      },
      {
        'title': 'Gratis Antar Jemput',
        'tag': 'Transport',
        'img': '${ApiConstants.rootUrl}/storage/5.webp',
        'narration': 'Layanan antar jemput gratis untuk radius 5km'
      },
      {
        'title': 'Diskon Akhir Pekan',
        'tag': 'Weekend',
        'img': '${ApiConstants.rootUrl}/storage/6.webp',
        'narration': 'Potongan 20% untuk semua layanan di hari Sabtu dan Minggu'
      },
      {
        'title': 'Paket Keluarga',
        'tag': 'Hemat',
        'img': '${ApiConstants.rootUrl}/storage/7.webp',
        'narration': 'Cuci lebih banyak lebih hemat dengan paket keluarga'
      },
      {
        'title': 'Cuci Sepatu Premium',
        'tag': 'Shoes',
        'img': '${ApiConstants.rootUrl}/storage/8.webp',
        'narration': 'Perawatan khusus untuk sepatu kesayangan Anda'
      },
    ];

    List<Widget> leftCol = [];
    List<Widget> rightCol = [];
    for (int i = 0; i < allPromos.length; i++) {
      Widget card = _buildVerticalPromoCard(
          allPromos[i]['title']!,
          allPromos[i]['tag']!,
          allPromos[i]['img']!,
          allPromos[i]['narration']!);
      if (i % 2 == 0) {
        leftCol.add(card);
      } else {
        rightCol.add(card);
      }
    }

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                    child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text("Promo Nyutji Bulan Ini",
                      style: NyutjiTheme.h2(const Color(0xFF131109))
                          .copyWith(fontSize: 22)),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Column(children: leftCol)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(children: rightCol)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  Widget _buildVerticalPromoCard(
      String title, String tag, String img, String narration) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
            image: CachedNetworkImageProvider(img), fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.8),
                Colors.transparent
              ]),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 80),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFC3312E),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(tag,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Text(title,
                style: NyutjiTheme.h2(Colors.white).copyWith(fontSize: 15),
                textAlign: TextAlign.right),
            const SizedBox(height: 4),
            Text(
              narration,
              style: NyutjiTheme.detail(Colors.white.withValues(alpha: 0.9))
                  .copyWith(fontSize: 9, fontStyle: FontStyle.italic),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCard(
      String title, String tag, String img, String narration) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        image: DecorationImage(
            image: CachedNetworkImageProvider(img), fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.8),
                Colors.transparent
              ]),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFC3312E),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(tag,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Text(title,
                style: NyutjiTheme.h2(Colors.white).copyWith(fontSize: 18),
                textAlign: TextAlign.right),
            const SizedBox(height: 4),
            Text(narration,
                style: NyutjiTheme.detail(Colors.white.withValues(alpha: 0.9))
                    .copyWith(fontSize: 10, fontStyle: FontStyle.italic),
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildMitraSection(Map<String, dynamic> currentT, AuthProvider auth) {
    final theme = ref.watch(customerThemeProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text("Mitra Terdekat Nyutji",
                    style: NyutjiTheme.h2(theme.text)
                        .copyWith(fontSize: 20)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  if (_currentLat == null || _currentLng == null) {
                    NyutjiNotif.showError(
                        context, "Lokasi tidak tersedia, pastikan GPS aktif");
                    return;
                  }
                  setState(() {
                    _sortClosest = !_sortClosest;
                  });
                  NyutjiNotif.showSuccess(
                      context,
                      _sortClosest
                          ? "Urut dari Terdekat"
                          : "Urut dari Terjauh");
                },
                child: Icon(LucideIcons.arrowUpDown,
                    color: theme.text, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer(
            builder: (context, ref, _) {
              final orderProv = ref.watch(orderProvider);
              if (orderProv.recommendedMitras.isEmpty) {
                return Center(
                    child: Text("Sedang memuat mitra...",
                        style: NyutjiTheme.detail(Colors.grey)));
              }

              List<Map<String, dynamic>> displayMitras =
                  List<Map<String, dynamic>>.from(orderProv.recommendedMitras);

              if (displayMitras.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text(
                          "Belum ada Mitra Laundry Nyutji diwilayah Anda saat ini.",
                          style: NyutjiTheme.detail(Colors.grey),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CustomerOrderScreen(
                                    orderType: 'pickup'))),
                        child: Text("Order Sekarang",
                            style: NyutjiTheme.h3(const Color(0xFF556B2F))
                                .copyWith(
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 4),
                      Text("sesuai Alamat yang tersimpan",
                          style: NyutjiTheme.detail(Colors.grey),
                          textAlign: TextAlign.center),
                    ],
                  ),
                );
              }

              for (var m in displayMitras) {
                double distance = 0.5;
                if (_currentLat != null && _currentLng != null) {
                  final mLat = double.tryParse(m['lat']?.toString() ?? '');
                  final mLng = double.tryParse(m['lng']?.toString() ?? '');
                  if (mLat != null && mLng != null) {
                    distance = _calculateDistance(
                        _currentLat!, _currentLng!, mLat, mLng);
                  }
                } else {
                  final userLat =
                      double.tryParse(auth.user?['lat']?.toString() ?? '');
                  final userLng =
                      double.tryParse(auth.user?['lng']?.toString() ?? '');
                  final mLat = double.tryParse(m['lat']?.toString() ?? '');
                  final mLng = double.tryParse(m['lng']?.toString() ?? '');
                  if (userLat != null &&
                      userLng != null &&
                      mLat != null &&
                      mLng != null) {
                    distance = _calculateDistance(userLat, userLng, mLat, mLng);
                  }
                }
                m['_calc_dist'] = distance;
              }

              displayMitras.sort((a, b) {
                final dA = a['_calc_dist'] as double;
                final dB = b['_calc_dist'] as double;
                return _sortClosest ? dA.compareTo(dB) : dB.compareTo(dA);
              });

              if (displayMitras.length > 5) {
                displayMitras = displayMitras.sublist(0, 5);
              }

              return Column(
                children: List.generate(displayMitras.length, (index) {
                  final m = displayMitras[index];
                  double distance = m['_calc_dist'] as double;
                  if (distance < 0.2) distance += (index * 0.15);

                  return GestureDetector(
                    onTap: () {
                      _showMitraActionSheet(context, m);
                    },
                    child: _buildMitraRow(
                        m['name'] ?? 'Mitra Nyutji',
                        "${distance.toStringAsFixed(1)} km",
                        (m['rating'] ?? '4.5').toString(),
                        m['is_top'] ?? true,
                        m['is_open'] ?? true,
                        m['image'] ?? m['profile_photo']),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMitraRow(String name, String dist, String rating, bool isTop,
      bool isBuka, dynamic photoUrl) {
    final theme = ref.watch(customerThemeProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: theme.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.white,
              image: (photoUrl != null && photoUrl.toString().isNotEmpty)
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(
                          ApiConstants.profilePhotoUrl(photoUrl)),
                      fit: BoxFit.cover)
                  : const DecorationImage(
                      image: AssetImage("assets/icons/icon_ML.png"),
                      fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: NyutjiTheme.h2(theme.text)
                              .copyWith(fontSize: 18)),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.check_circle,
                        size: 16, color: Colors.green),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("$dist \u2022 ",
                        style: NyutjiTheme.detail(Colors.grey)
                            .copyWith(fontSize: 13)),
                    Text(isBuka ? "Buka Sekarang" : "Tutup",
                        style: NyutjiTheme.detail(
                                isBuka ? const Color(0xFF556B2F) : Colors.red)
                            .copyWith(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    const Icon(Icons.star, size: 14, color: Color(0xFFDAC66F)),
                    const SizedBox(width: 2),
                    Text(rating,
                        style: NyutjiTheme.detail(theme.text)
                            .copyWith(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showGlobalSearchSheet(BuildContext context) {
    final orderProv = ref.read(orderProvider);
    String searchQuery = "";
    Timer? debounceTimer;
    String? expandedMitraId;

    // Reset search state
    orderProv.searchGlobal("");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) =>
          StatefulBuilder(builder: (sbContext, setModalState) {
        final queryClean =
            searchQuery.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        List<dynamic> filteredOrders = [];

        if (queryClean.isNotEmpty) {
          final allOrders = [
            ...orderProv.activeOrders,
            ...orderProv.historyOrders
          ];
          filteredOrders = allOrders.where((o) {
            final orderNum = (o['order_number'] ?? '')
                .toString()
                .toLowerCase()
                .replaceAll(RegExp(r'[^a-z0-9]'), '');
            final status = (o['order_status'] ?? o['status'] ?? '')
                .toString()
                .toLowerCase()
                .replaceAll(RegExp(r'[^a-z0-9]'), '');
            final service = (o['service_name'] ?? '')
                .toString()
                .toLowerCase()
                .replaceAll(RegExp(r'[^a-z0-9]'), '');
            return orderNum.contains(queryClean) ||
                status.contains(queryClean) ||
                service.contains(queryClean);
          }).toList();
        }

        return Consumer(builder: (context, ref, child) {
          final provider = ref.watch(orderProvider);
          final filteredMitras = provider.searchedMitras;
          final isLoading = provider.isLoading;

          return Container(
            height: MediaQuery.of(sbContext).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF9ED),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color:
                                const Color(0xFF403600).withValues(alpha: 0.1),
                            shape: BoxShape.circle),
                        child: const Icon(LucideIcons.search,
                            color: Color(0xFF403600), size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Pencarian Nyutji",
                                style: NyutjiTheme.h2(const Color(0xFF131109))
                                    .copyWith(fontSize: 18)),
                            Text("Temukan Mitra, Pesanan, Layanan",
                                style: NyutjiTheme.detail(Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ]),
                    child: TextField(
                      autofocus: true,
                      onChanged: (val) {
                        setModalState(() => searchQuery = val);
                        if (debounceTimer?.isActive ?? false) {
                          debounceTimer!.cancel();
                        }
                        debounceTimer =
                            Timer(const Duration(milliseconds: 500), () {
                          provider.searchGlobal(val);
                        });
                      },
                      style: NyutjiTheme.body(const Color(0xFF131109))
                          .copyWith(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        icon: const Icon(LucideIcons.search,
                            size: 20, color: Color(0xFF556B2F)),
                        hintText: "Ketik apa saja... (mis: Cuci Sepatu)",
                        hintStyle: NyutjiTheme.detail(Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: searchQuery.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.zap,
                                  size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text("Cari secepat kilat!",
                                  style: NyutjiTheme.h3(Colors.grey)),
                            ],
                          ),
                        )
                      : isLoading
                          ? ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 8),
                              physics: const BouncingScrollPhysics(),
                              itemCount: 3,
                              itemBuilder: (context, index) => const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: ShimmerLoading(
                                    height: 80, borderRadius: 16),
                              ),
                            )
                          : (filteredMitras.isEmpty && filteredOrders.isEmpty)
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(LucideIcons.searchX,
                                          size: 64, color: Colors.grey[300]),
                                      const SizedBox(height: 16),
                                      Text("Oops! Tidak menemukan apapun.",
                                          style: NyutjiTheme.h3(Colors.grey)),
                                      Text("Coba kata kunci lain atau typo?",
                                          style:
                                              NyutjiTheme.detail(Colors.grey)),
                                    ],
                                  ),
                                )
                              : ListView(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 8),
                                  physics: const BouncingScrollPhysics(),
                                  children: [
                                    if (filteredOrders.isNotEmpty) ...[
                                      Text("Riwayat Pesanan",
                                          style: NyutjiTheme.h3(
                                                  const Color(0xFF131109))
                                              .copyWith(
                                                  fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 12),
                                      ...filteredOrders.map((o) =>
                                          _buildSearchOrderCard(sbContext, o)),
                                      const SizedBox(height: 24),
                                    ],
                                    if (filteredMitras.isNotEmpty) ...[
                                      Text("Hasil Pencarian Mitra",
                                          style: NyutjiTheme.h3(
                                                  const Color(0xFF131109))
                                              .copyWith(
                                                  fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 12),
                                      ...filteredMitras.map((m) {
                                        final id = (m['id'] ?? m['identifier'])
                                            ?.toString();
                                        return _buildSearchMitraCard(
                                            sbContext, m,
                                            isExpanded: id != null &&
                                                expandedMitraId == id,
                                            onTap: () {
                                          if (id == null) return;
                                          setModalState(() {
                                            expandedMitraId =
                                                (expandedMitraId == id)
                                                    ? null
                                                    : id;
                                          });
                                        });
                                      }),
                                    ]
                                  ],
                                ),
                ),
              ],
            ),
          );
        });
      });
    });
  }

  void _showTutorialCoachMark() {
    final targets = <TargetFocus>[];
    
    // 1. Lacak Progress
    targets.add(
      TargetFocus(
        identify: "tracking",
        keyTarget: _keyTracking,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => NyutjiCoachMark.buildTutorialCard(
              step: "1 / 8",
              title: "Lacak Progress Cucian",
              description: "Pantau pesanan Anda secara real-time dari saat diambil kurir hingga selesai dicuci.",
              icon: LucideIcons.truck,
              onNext: () {
                _mainScrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                controller.next();
              },
              onSkip: () => controller.skip(),
            ),
          )
        ],
      ),
    );

    // 2. Dompet Nyutji
    targets.add(
      TargetFocus(
        identify: "dompet",
        keyTarget: _keyDompet,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => NyutjiCoachMark.buildTutorialCard(
              step: "2 / 8",
              title: "Dompet Nyutji",
              description: "Saldo dompet digital Anda untuk pembayaran yang lebih cepat, aman, dan dapatkan promo cashback.",
              icon: LucideIcons.wallet,
              onNext: () {
                _mainScrollController.animateTo(200, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                controller.next();
              },
              onSkip: () => controller.skip(),
            ),
          )
        ],
      ),
    );

    // 3. Pick Up Kurir
    targets.add(
      TargetFocus(
        identify: "pickup",
        keyTarget: _keyPickUp,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => NyutjiCoachMark.buildTutorialCard(
              step: "3 / 8",
              title: "Layanan Pick Up Kurir",
              description: "Pesan layanan antar-jemput cucian langsung ke rumah Anda. Praktis tanpa ribet!",
              icon: LucideIcons.packagePlus,
              onNext: () => controller.next(),
              onSkip: () => controller.skip(),
            ),
          )
        ],
      ),
    );

    // 4. Cuci Sepatu
    targets.add(
      TargetFocus(
        identify: "sepatu",
        keyTarget: _keySepatu,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => NyutjiCoachMark.buildTutorialCard(
              step: "4 / 8",
              title: "Cuci Sepatu Spesial",
              description: "Jangan lupa cobain layanan cuci sepatu kami. Ditangani oleh tenaga ahli untuk hasil maksimal.",
              icon: LucideIcons.footprints,
              onNext: () => controller.next(),
              onSkip: () => controller.skip(),
            ),
          )
        ],
      ),
    );

    // 5. Status Tab
    if (widget.keyStatusTab != null) {
      targets.add(
        TargetFocus(
          identify: "status_tab",
          keyTarget: widget.keyStatusTab!,
          shape: ShapeLightFocus.Circle,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) => NyutjiCoachMark.buildTutorialCard(
                step: "5 / 8",
                title: "Status Pesanan",
                description: "Lihat rincian lengkap riwayat dan status setiap pesanan cucian Anda di sini.",
                icon: LucideIcons.package,
                onNext: () {
                  _mainScrollController.animateTo(500, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                  controller.next();
                },
                onSkip: () => controller.skip(),
              ),
            )
          ],
        ),
      );
    }

    // 6. Profile Tab
    if (widget.keyProfileTab != null) {
      targets.add(
        TargetFocus(
          identify: "profile_tab",
          keyTarget: widget.keyProfileTab!,
          shape: ShapeLightFocus.Circle,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) => NyutjiCoachMark.buildTutorialCard(
                step: "6 / 8",
                title: "Pengaturan Profil",
                description: "Lengkapi alamat, nomor telepon, dan atur tema warna aplikasi kesukaan Anda di Profil.",
                icon: LucideIcons.user,
                onNext: () => controller.next(),
                onSkip: () => controller.skip(),
              ),
            )
          ],
        ),
      );
    }

    // 7. Promo
    targets.add(
      TargetFocus(
        identify: "promo",
        keyTarget: _keyPromo,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => NyutjiCoachMark.buildTutorialCard(
              step: "7 / 8",
              title: "Promo & Diskon Spesial",
              description: "Cek berbagai voucher dan diskon menarik yang tersedia khusus untuk Anda.",
              icon: LucideIcons.ticket,
              onNext: () {
                _mainScrollController.animateTo(_mainScrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
                controller.next();
              },
              onSkip: () => controller.skip(),
            ),
          )
        ],
      ),
    );

    // 8. Mitra Terdekat
    targets.add(
      TargetFocus(
        identify: "mitra",
        keyTarget: _keyMitra,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => NyutjiCoachMark.buildTutorialCard(
              step: "8 / 8",
              title: "Mitra Terdekat Nyutji",
              description: "Pilih mitra laundry dengan rating terbaik dan lokasi terdekat dari tempat Anda berada.",
              icon: LucideIcons.store,
              isLast: true,
              onNext: () => controller.next(),
              onSkip: () => controller.skip(),
            ),
          )
        ],
      ),
    );

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      textSkip: "LEWATI",
      paddingFocus: 10,
      opacityShadow: 0.85,
      hideSkip: true,
      onFinish: () {
        Hive.box('nyutji_cache').put('tutorial_customer_home', true);
      },
      onSkip: () {
        Hive.box('nyutji_cache').put('tutorial_customer_home', true);
        return true;
      },
    ).show(context: context);
  }

  Widget _buildSearchOrderCard(BuildContext context, dynamic o) {
    final num = o['order_number'] ?? '-';
    final status = o['order_status'] ?? o['status'] ?? '-';
    final service = o['service_name'] ?? 'Layanan Laundry';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)
          ]),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: const Color(0xFF556B2F).withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: const Icon(LucideIcons.receipt,
                color: Color(0xFF556B2F), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(num,
                    style: NyutjiTheme.body(const Color(0xFF131109))
                        .copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(service,
                    style: NyutjiTheme.detail(Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(status,
                  style: NyutjiTheme.detail(Colors.orange)
                      .copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchMitraCard(BuildContext context, dynamic m,
      {required bool isExpanded, required VoidCallback onTap}) {
    final name = m['name'] ?? 'Mitra Nyutji';
    final city = m['city'] ?? m['city_name'] ?? m['owner_city_name'] ?? '';
    final isTop = m['is_top'] ?? true;

    var services = (m['services'] as List<dynamic>?) ?? [];
    if (services.isEmpty &&
        m['services_text'] != null &&
        m['services_text'].toString().trim().isNotEmpty) {
      services = m['services_text']
          .toString()
          .split(',')
          .map((s) => {'name': s.trim()})
          .toList();
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)
            ]),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      image: m['profile_photo'] != null
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(
                                  ApiConstants.profilePhotoUrl(
                                      m['profile_photo'])),
                              fit: BoxFit.cover)
                          : null),
                  child: m['profile_photo'] == null
                      ? const Icon(LucideIcons.store, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isTop) ...[
                            const Icon(LucideIcons.medal,
                                color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                              child: Text(name,
                                  style:
                                      NyutjiTheme.body(const Color(0xFF131109))
                                          .copyWith(
                                              fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(city, style: NyutjiTheme.detail(Colors.grey)),
                    ],
                  ),
                ),
                Icon(
                    isExpanded
                        ? LucideIcons.chevronDown
                        : LucideIcons.chevronRight,
                    size: 18,
                    color: Colors.grey),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Column(
                      children: [
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFF0F0F0)),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Layanan Tersedia:",
                              style: NyutjiTheme.detail(const Color(0xFF131109))
                                  .copyWith(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 8),
                        if (services.isEmpty)
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Belum ada layanan.",
                                  style: NyutjiTheme.detail(Colors.grey)))
                        else
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: services.map((s) {
                                final svcName = s['name'] ?? '-';
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF556B2F)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(svcName,
                                      style: NyutjiTheme.detail(
                                              const Color(0xFF556B2F))
                                          .copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10)),
                                );
                              }).toList(),
                            ),
                          ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF403600),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _showMitraActionSheet(context, m),
                            child: Text("Pilih Mitra Ini",
                                style: NyutjiTheme.detail(Colors.white)
                                    .copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  void _showMitraActionSheet(BuildContext context, dynamic mitra) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF9ED),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      image: (mitra['image'] != null ||
                              mitra['profile_photo'] != null)
                          ? DecorationImage(
                              image: CachedNetworkImageProvider((mitra[
                                              'image'] ??
                                          mitra['profile_photo'])
                                      .toString()
                                      .startsWith('http')
                                  ? (mitra['image'] ?? mitra['profile_photo'])
                                  : "${ApiConstants.rootUrl}/${mitra['image'] ?? mitra['profile_photo']}"),
                              fit: BoxFit.cover)
                          : const DecorationImage(
                              image: AssetImage("assets/icons/icon_ML.png"),
                              fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Pesan di",
                            style: NyutjiTheme.detail(Colors.grey)
                                .copyWith(fontWeight: FontWeight.bold)),
                        Text(mitra['name'] ?? 'Mitra Nyutji',
                            style: NyutjiTheme.h2(const Color(0xFF131109))
                                .copyWith(fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text("Pilih Metode Layanan",
                  style: NyutjiTheme.h3(const Color(0xFF131109))
                      .copyWith(fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: LucideIcons.truck,
                      title: "Jemput\nKurir",
                      color: const Color(0xFF556B2F),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => CustomerOrderScreen(
                                    orderType: 'pickup',
                                    preselectedMitra: mitra)));
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      icon: LucideIcons.user,
                      title: "Antar\nSendiri",
                      color: const Color(0xFF403600),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => CustomerOrderScreen(
                                    orderType: 'drop',
                                    preselectedMitra: mitra)));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionCard(
      {required IconData icon,
      required String title,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: NyutjiTheme.h3(color).copyWith(
                    fontWeight: FontWeight.bold, fontSize: 14, height: 1.2)),
          ],
        ),
      ),
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    path.quadraticBezierTo(
        size.width / 2, size.height - 40, size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
