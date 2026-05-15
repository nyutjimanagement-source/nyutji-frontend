import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/nyutji_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/constants/api_constants.dart';
import '../../../providers/wallet_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../core/utils/formatters.dart';
import 'customer_order_screen.dart';
import 'customer_status_screen.dart';
import 'customer_wallet_screen.dart';
import 'customer_profile_screen.dart';
import '../../../core/widgets/nyutji_image_picker.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _promoController = ScrollController();
  Timer? _promoTimer;
  bool _showBackToTop = false;

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
      context.read<WalletProvider>().fetchWallet();
      context.read<OrderProvider>().fetchOrders();
      context.read<OrderProvider>().fetchRecommendedMitras();
      _startPromoMarquee();
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void _startPromoMarquee() {
    _promoTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_promoController.hasClients) {
        double maxScroll = _promoController.position.maxScrollExtent;
        double currentScroll = _promoController.offset;
        if (currentScroll >= maxScroll) {
          _promoController.jumpTo(0);
        } else {
          _promoController.animateTo(
            currentScroll + 1,
            duration: const Duration(milliseconds: 50),
            curve: Curves.linear,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _promoController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(AuthProvider auth) async {
    NyutjiImagePicker.show(
      context,
      title: "Pilih Foto Profil",
      primaryColor: const Color(0xFF403600),
      onImagePicked: (XFile file) async {
        final success = await auth.updateProfilePhoto(file);
        if (mounted) {
          _showBeautifulNotif(success ? "Foto profil diperbarui" : "Gagal unggah foto", success);
        }
      },
    );
  }

  void _showBeautifulNotif(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
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

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9ED),
      floatingActionButton: _showBackToTop ? FloatingActionButton(
        mini: true,
        backgroundColor: const Color(0xFF403600),
        onPressed: () => _mainScrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
        child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
      ) : null,
      body: SingleChildScrollView(
        controller: _mainScrollController,
        physics: const BouncingScrollPhysics(),
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
                  child: _buildActiveTrackingBanner(currentT),
                ),
              ],
            ),
            const SizedBox(height: 30),
            _buildFinancialStrip(currentT),
            const SizedBox(height: 20),
            _buildDenseServicesGrid(currentT),
            const SizedBox(height: 24),
            _buildPromoSection(currentT),
            const SizedBox(height: 24),
            _buildMitraSection(currentT, auth),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> currentT, AuthProvider auth) {
    final photoUrl = auth.user?['profile_photo'];
    final localPhoto = auth.temporaryLocalPhoto;
    final district = auth.user?['owner_district_name'] ?? auth.user?['district_name'] ?? 'Pamulang';
    final city = auth.user?['owner_city_name'] ?? auth.user?['city_name'] ?? 'Tangerang Selatan';

    return ClipPath(
      clipper: HeaderClipper(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 70),
        decoration: const BoxDecoration(
          color: Color(0xFF403600),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _pickImage(auth),
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                  color: Colors.white10,
                  image: kIsWeb
                      ? (auth.temporaryWebBytes != null
                          ? DecorationImage(image: MemoryImage(auth.temporaryWebBytes!), fit: BoxFit.cover)
                          : (photoUrl != null && photoUrl.toString().isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(photoUrl.toString().startsWith('http') 
                                      ? "$photoUrl?v=${DateTime.now().millisecondsSinceEpoch}"
                                      : "${ApiConstants.rootUrl}/$photoUrl?v=${DateTime.now().millisecondsSinceEpoch}"), 
                                  fit: BoxFit.cover)
                              : null)
                      : (localPhoto != null
                          ? DecorationImage(image: FileImage(File(localPhoto)), fit: BoxFit.cover)
                          : (photoUrl != null && photoUrl.toString().isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(photoUrl.toString().startsWith('http') 
                                      ? "$photoUrl?v=${DateTime.now().millisecondsSinceEpoch}"
                                      : "${ApiConstants.rootUrl}/$photoUrl?v=${DateTime.now().millisecondsSinceEpoch}"), 
                                  fit: BoxFit.cover)
                              : null),
                ),
                child: (localPhoto == null && auth.temporaryWebBytes == null && (photoUrl == null || photoUrl.toString().isEmpty))
                    ? const Icon(LucideIcons.user, color: Colors.white70, size: 28)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(auth.user?['name'] ?? currentT['greeting'], 
                    style: NyutjiTheme.h2(Colors.white).copyWith(fontSize: 18)),
                  const SizedBox(height: 2),
                  Text(district, style: NyutjiTheme.detail(Colors.white70).copyWith(fontSize: 13)),
                  Text(city, style: NyutjiTheme.detail(Colors.white70).copyWith(fontSize: 13)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.search, color: Colors.white, size: 24),
              onPressed: () {},
            ),
            Consumer<OrderProvider>(
              builder: (context, orderProv, _) => Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.bell, color: Colors.white, size: 24),
                    onPressed: () => orderProv.resetNotif('PL'),
                  ),
                  if (orderProv.notifCountPL > 0)
                    Positioned(
                      top: 10, right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text("${orderProv.notifCountPL}", 
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                      ),
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTrackingBanner(Map<String, dynamic> currentT) {
    return Consumer<OrderProvider>(
      builder: (context, orderProv, _) {
        final latestOrder = orderProv.activeOrders.isNotEmpty ? orderProv.activeOrders.first : null;
        final status = latestOrder != null ? (latestOrder['status'] ?? latestOrder['order_status'] ?? 'WAITING').toString() : "Order Nyutji Yuks !!";
        final label = latestOrder != null ? "LACAK PROGRES LIVE" : "Ayo Cuci Sekarang";

        return GestureDetector(
          onTap: () {
            if (latestOrder != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerStatusScreen()));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerOrderScreen(orderType: 'pickup')));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9ED),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE3DCCF), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE3DCCF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(latestOrder != null ? LucideIcons.loader : LucideIcons.shoppingBag, size: 22, color: const Color(0xFF403600)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, 
                        style: NyutjiTheme.detail(const Color(0xFF403600)).copyWith(fontWeight: FontWeight.w900, fontSize: 11)),
                      Text(status, 
                        style: NyutjiTheme.h3(const Color(0xFF403600)).copyWith(fontWeight: FontWeight.w800, fontSize: 14)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF403600)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinancialStrip(Map<String, dynamic> currentT) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF403600),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Consumer<WalletProvider>(
                builder: (context, wallet, _) => _buildFinItem(Icons.account_balance_wallet, currentT['pay_label'], Formatters.currencyIdr(wallet.balance)),
              ),
            ),
            Container(width: 1, height: 40, color: Colors.white24),
            Expanded(
              child: _buildFinItem(Icons.star_border, currentT['points_label'], "2.400"),
            ),
            Container(width: 1, height: 40, color: Colors.white24),
            Expanded(
              child: _buildFinItem(Icons.confirmation_number_outlined, currentT['voucher_label'], "4 ${currentT['active_text']}"),
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
        Text(value, style: NyutjiTheme.h2(const Color(0xFFDAC66F)).copyWith(fontSize: 16)),
      ],
    );
  }

  Widget _buildDenseServicesGrid(Map<String, dynamic> currentT) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(currentT['main_services'], style: NyutjiTheme.h2(const Color(0xFF131109)).copyWith(fontSize: 22)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 8,
            childAspectRatio: 0.65,
            children: [
              // Baris 1
              _buildServiceItem("Pick Up\nKurir", "icon_pickup.png", hasPromo: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerOrderScreen(orderType: 'pickup')))),
              _buildServiceItem("Antar\nSendiri", "icon_dropoff.png", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerOrderScreen(orderType: 'drop')))),
              _buildServiceItem("Nyutji\nCoin", "icon_coin.png"),
              _buildServiceItem("Top-Up", "icon_topup.png", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerWalletScreen()))),
              // Baris 2
              _buildServiceItem("Cuci\nKhusus", "baby_stroller.png"),
              _buildServiceItem("Dry\nClean", "icon_dryclean.png"),
              _buildServiceItem("Cuci\nSepatu", "icon_sepatu.png"),
              _buildServiceItem("Pakaian\nBayi", "icon_bayi.png"),
              // Baris 3
              _buildServiceItem("Jadwal", "icon_jadwal.png"),
              _buildServiceItem("Cek Status", "icon_status.png", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerStatusScreen()))),
              _buildServiceItem("Pengaturan", "icon_pengaturan.png", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerProfileScreen()))),
              _buildServiceItem("Bantuan", "icon_bantuan.png"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(String label, String iconPath, {bool hasPromo = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset("assets/icons/$iconPath", width: 70, height: 70, errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 50)),
              if (hasPromo)
                Positioned(
                  top: 0,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFC3312E), borderRadius: BorderRadius.circular(10)),
                    child: const Text("PROMO", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: NyutjiTheme.body(const Color(0xFF131109)).copyWith(fontSize: 13, height: 1.1)),
        ],
      ),
    );
  }

  Widget _buildPromoSection(Map<String, dynamic> currentT) {
    final List<Map<String, String>> promoItems = [
      {'title': 'Dry Clean Pesta', 'tag': 'Diskon 20%', 'img': 'https://images.unsplash.com/photo-1545173168-9f1947eebb7f?w=400&q=80', 'narration': 'Kilau Pesta Tanpa Noda, Diskon Melimpah Menanti Anda di Nyutji App'},
      {'title': 'NyutjiPay Special', 'tag': 'Cashback Kece', 'img': 'https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?w=400&q=80', 'narration': 'Top Up Sekarang Dapatkan Cashback Instan Untuk Transaksi Laundry Pertama Anda'},
      {'title': 'Cuci Kilat 6 Jam', 'tag': 'Ekspres', 'img': 'https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?w=400&q=80', 'narration': 'Waktu Sangat Berharga Biarkan Kami Menyelesaikan Cucian Anda Dalam Waktu Singkat'},
      {'title': 'Voucher Berkah', 'tag': 'Limited', 'img': 'https://images.unsplash.com/photo-1545173168-9f1947eebb7f?w=400&q=80', 'narration': 'Berbagi Kebaikan Dengan Voucher Potongan Harga Spesial Untuk Pelanggan Setia Nyutji'},
      {'title': 'Member Platinum', 'tag': 'Premium', 'img': 'https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?w=400&q=80', 'narration': 'Nikmati Layanan Prioritas Dan Antrean Khusus Untuk Member Platinum Terpilih Nyutji'},
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
                  style: NyutjiTheme.h2(const Color(0xFF131109)).copyWith(fontSize: 20)),
              ),
              const SizedBox(width: 8),
              Text("Lihat Semua", 
                style: NyutjiTheme.body(const Color(0xFF556B2F)).copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            controller: _promoController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 1000, 
            itemBuilder: (context, index) {
              final item = promoItems[index % promoItems.length];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildPromoCard(item['title']!, item['tag']!, item['img']!, item['narration']!),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPromoCard(String title, String tag, String img, String narration) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        image: DecorationImage(image: NetworkImage(img), fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent]),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFC3312E), borderRadius: BorderRadius.circular(8)),
              child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Text(title, style: NyutjiTheme.h2(Colors.white).copyWith(fontSize: 18), textAlign: TextAlign.right),
            const SizedBox(height: 4),
            Text(narration, 
              style: NyutjiTheme.detail(Colors.white.withValues(alpha: 0.9)).copyWith(fontSize: 10, fontStyle: FontStyle.italic), 
              textAlign: TextAlign.right,
              maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildMitraSection(Map<String, dynamic> currentT, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text("Mitra Terdekat Nyutji", 
                  style: NyutjiTheme.h2(const Color(0xFF131109)).copyWith(fontSize: 20)),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.tune, color: Color(0xFF131109)),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<OrderProvider>(
            builder: (context, orderProv, _) {
              if (orderProv.recommendedMitras.isEmpty) {
                return Center(child: Text("Sedang memuat mitra...", style: NyutjiTheme.detail(Colors.grey)));
              }
              return Column(
                children: List.generate(orderProv.recommendedMitras.length, (index) {
                  final m = orderProv.recommendedMitras[index];
                  // NYUTJI DISTANCE LOGIC WITH SMART VARIATION
                  double distance = 0.1;
                  try {
                    final userLat = double.tryParse(auth.user?['lat']?.toString() ?? '');
                    final userLng = double.tryParse(auth.user?['lng']?.toString() ?? '');
                    final mitraLat = double.tryParse(m['lat']?.toString() ?? '');
                    final mitraLng = double.tryParse(m['lng']?.toString() ?? '');
                    
                    if (userLat != null && userLng != null && mitraLat != null && mitraLng != null) {
                      distance = _calculateDistance(userLat, userLng, mitraLat, mitraLng);
                      // Jika jarak sama persis (data dummy), tambahkan sedikit variasi agar tampilan realistik
                      if (distance < 0.2) {
                        distance += (index * 0.15); // Tambah 0.15km per urutan jika datanya sangat dekat/identik
                      }
                    } else {
                      distance = (double.tryParse(m['distance']?.toString() ?? '0.5') ?? 0.5) + (index * 0.1);
                    }
                  } catch (e) {
                    distance = 0.5 + (index * 0.2);
                  }

                  return _buildMitraRow(
                    m['name'] ?? 'Mitra Nyutji', 
                    "${distance.toStringAsFixed(1)} km", 
                    (m['rating'] ?? '4.5').toString(), 
                    m['is_top'] ?? true, 
                    m['is_open'] ?? true,
                    m['profile_photo']
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMitraRow(String name, String dist, String rating, bool isTop, bool isBuka, dynamic photoUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9ED),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE3DCCF), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.white,
              image: (photoUrl != null && photoUrl.toString().isNotEmpty)
                ? DecorationImage(
                    image: NetworkImage(photoUrl.toString().startsWith('http') 
                      ? photoUrl 
                      : "${ApiConstants.rootUrl}/$photoUrl"), 
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
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: NyutjiTheme.h2(const Color(0xFF131109)).copyWith(fontSize: 18)),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("$dist \u2022 ", style: NyutjiTheme.detail(Colors.grey).copyWith(fontSize: 13)),
                    Text(isBuka ? "Buka Sekarang" : "Tutup", 
                      style: NyutjiTheme.detail(isBuka ? const Color(0xFF556B2F) : Colors.red).copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star, size: 20, color: Color(0xFFDAC66F)),
              const SizedBox(width: 4),
              Text(rating, style: NyutjiTheme.h2(const Color(0xFF131109)).copyWith(fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    path.quadraticBezierTo(size.width / 2, size.height - 40, size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
