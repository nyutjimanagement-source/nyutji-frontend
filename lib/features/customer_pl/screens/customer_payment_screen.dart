import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/nyutji_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../data/services/api_service.dart';
import '../../../core/utils/nyutji_distance.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/theme/theme_util.dart';
import 'customer_ok_bayar.dart';
import 'customer_wallet_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomerPaymentScreen extends ConsumerStatefulWidget {
  final int totalPrice;
  final int totalItems;
  final String address;
  final bool isPickup;
  final dynamic mitraId;
  final String mitraName;
  final String orderType; // 'pickup' or 'drop'
  final String speed;
  final double distance;
  final String dropMethod; // 'courier' or 'self' (return method)
  final List<Map<String, dynamic>> selectedItemsList;
  final String districtName;
  final String districtCode;
  final String cityName;
  final double lat;
  final double lng;
  final double mitraLat;
  final double mitraLng;
  final String pickupNote;
  final String mitraAddress;
  final String mitraDistrict;

  const CustomerPaymentScreen({
    super.key,
    required this.totalPrice,
    required this.totalItems,
    required this.address,
    required this.isPickup,
    required this.mitraId,
    required this.mitraName,
    required this.orderType,
    required this.speed,
    required this.distance,
    required this.dropMethod,
    required this.selectedItemsList,
    required this.districtName,
    required this.cityName,
    required this.lat,
    required this.lng,
    this.districtCode = 'NYJ',
    this.mitraLat = 0.0,
    this.mitraLng = 0.0,
    this.pickupNote = '',
    this.mitraAddress = '',
    this.mitraDistrict = '',
  });

  @override ConsumerState<CustomerPaymentScreen> createState() => _CustomerPaymentScreenState();
}

class _CustomerPaymentScreenState extends ConsumerState<CustomerPaymentScreen> {
  final Color primaryTeal = NyutjiTheme.m3Primary;
  final Color primaryRed = const Color(0xFFC3312E);
  final Color bgColor = NyutjiTheme.m3Surface;
  
  String _selectedPayment = "Dompet Nyutji";
  bool _isVAExpanded = false;
  bool _isEWalletExpanded = false;
  bool _isSubmitting = false;

  double _calculatedDistance = 0.0;
  int _dynamicCourierFee = 15000;
  bool _isLoadingPrice = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPaymentData();
    });
  }

  Future<void> _initPaymentData() async {
    // 1. Hitung Jarak Real & Apply NRCF Multiplier
    double straightDist = NyutjiDistance.calculateDistance(widget.lat, widget.lng, widget.mitraLat, widget.mitraLng);
    double roadDist = NyutjiDistance.calculateRoadDistance(straightDist);
    if (roadDist < 0.1) roadDist = 0.1; 

    setState(() {
      _calculatedDistance = roadDist; // Simpan Jarak Jalan untuk Ongkir
    });

    // 2. Refresh Saldo Dompet Nyutji
    final walletProv = ref.read(walletProvider);
    await walletProv.fetchWallet();

    // 3. Ambil Biaya Kurir Dinamis
    try {
      String currentOrderType = widget.isPickup 
          ? 'pickup' 
          : (widget.dropMethod == 'courier' ? 'delivery' : 'mandiri');

      final api = ApiService();
      final quote = await api.getPriceQuote(
        _calculatedDistance, 
        widget.speed == 'fast',
        widget.lat,
        widget.lng,
        currentOrderType
      );
      
      if (quote['status'] == 'success') {
        if (!mounted) return;
        setState(() {
          _dynamicCourierFee = (quote['data']?['deliveryFee'] as num? ?? quote['data']?['delivery_fee'] as num? ?? 0).toInt();
          _isLoadingPrice = false;
        });
      } else {
        // FALLBACK RUMUS GENIUS (Jarak x Rp/Km) - Jika API Gagal/Null
        _applyFallbackPricing();
      }
    } catch (e) {
      debugPrint("Gagal sinkronisasi harga kurir: $e");
      _applyFallbackPricing();
    }
  }

  void _applyFallbackPricing() {
    // Rumus Wajar: Rp 5.000 (Base) + (Jarak x Rp 2.500/Km)
    double baseFee = 5000;
    double perKm = 2500;
    double calculated = baseFee + (_calculatedDistance * perKm);
    
    // Faktor Fast Track (Tambah 5rb jika Same Day)
    if (widget.speed == 'fast') calculated += 5000;

    if (!mounted) return;
    setState(() {
      _dynamicCourierFee = calculated.toInt();
      _isLoadingPrice = false;
    });
  }

  final List<Map<String, String>> _vaBanks = [
    {'name': 'Bank BCA', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Bank_Central_Asia.svg/512px-Bank_Central_Asia.svg.png'},
    {'name': 'Bank Mandiri', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/Bank_Mandiri_logo_2016.svg/512px-Bank_Mandiri_logo_2016.svg.png'},
    {'name': 'Bank BNI', 'logo': 'https://upload.wikimedia.org/wikipedia/id/thumb/5/55/BNI_logo.svg/512px-BNI_logo.svg.png'},
    {'name': 'Bank BRI', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2e/BRI_Logo.svg/512px-BRI_Logo.svg.png'},
    {'name': 'CIMB NIAGA', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/43/CIMB_Niaga_logo.svg/512px-CIMB_Niaga_logo.svg.png'},
    {'name': 'Others', 'logo': ''},
  ];

  final List<Map<String, String>> _eWallets = [
    {'name': 'Gopay', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/86/Gopay_logo.svg/512px-Gopay_logo.svg.png'},
    {'name': 'OVO', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/eb/Logo_ovo_purple.svg/512px-Logo_ovo_purple.svg.png'},
    {'name': 'DANA', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/72/Logo_dana_blue.svg/512px-Logo_dana_blue.svg.png'},
    {'name': 'LinkAja', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/85/LinkAja.svg/512px-LinkAja.svg.png'},
    {'name': 'Others', 'logo': ''},
  ];

  Future<void> _handleConfirmOrder(int grandTotal) async {
    Navigator.push(
      context,
      RetroRoute(
        page: CustomerOkBayarScreen(
          grandTotal: grandTotal,
          orderType: widget.orderType,
          dropMethod: widget.dropMethod,
          districtCode: widget.districtCode,
          speed: widget.speed,
          address: widget.address,
          districtName: widget.districtName,
          mitraName: widget.mitraName,
          totalItems: widget.totalItems,
          isPickup: widget.isPickup,
          selectedPayment: _selectedPayment,
          onPay: (finishDate) {
            _processPayment(grandTotal, finishDate);
          },
        ),
      ),
    );
  }

  Future<void> _processPayment(int grandTotal, DateTime finishDate) async {
    if (_isSubmitting) return;

    final walletProv = ref.read(walletProvider);
    final auth = ref.read(authProvider);
    final orderProv = ref.read(orderProvider);

    // 1. Validasi Saldo (INSTRUKSI JENDERAL)
    if (walletProv.balance < grandTotal) {
      NyutjiNotif.showError(context, "Saldo Anda Kurang, Lakukan Top Up");
      return;
    }

    // 2. Validasi Metode Pembayaran
    if (_selectedPayment != "Dompet Nyutji") {
      NyutjiNotif.showError(context, "Saat ini hanya Dompet Nyutji yang tersedia.");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Bangun payload item sesuai format backend
      final items = widget.selectedItemsList.map((item) => {
        'category': item['category'] ?? 'Umum',
        'item_name': item['name'] ?? '',
        'qty': item['count'] ?? 1,
        'unit': item['unit'] ?? 'pcs',
        'price_per_unit': item['price'] ?? 0,
        'notes': '',
      }).toList();

      final isFastTrack = widget.speed == 'fast';
      final deliveryFee = (widget.isPickup || widget.dropMethod == 'courier') ? _dynamicCourierFee : 0;
      final deliveryType = widget.isPickup 
          ? 'PICKUP' 
          : (widget.dropMethod == 'courier' ? 'SELF_DROP' : 'SELFDROP_SELFDELIVERY');

      final payload = {
        'address': widget.address,
        'pickupNote': widget.pickupNote,
        'districtName': widget.districtName,
        'cityName': widget.cityName.isNotEmpty ? widget.cityName : 'Tasikmalaya',
        'items': items,
        'lat': widget.lat != 0.0 ? widget.lat : (double.tryParse(auth.user?['lat']?.toString() ?? '') ?? 0.0),
        'lng': widget.lng != 0.0 ? widget.lng : (double.tryParse(auth.user?['lng']?.toString() ?? '') ?? 0.0),
        'is_fast_track': isFastTrack,
        'isFastTrack': isFastTrack,
        'service_type': isFastTrack ? 'SAME_DAY' : 'REGULER',
        'serviceType': isFastTrack ? 'SAME_DAY' : 'REGULER',
        'service_price': widget.totalPrice,
        'servicePrice': widget.totalPrice,
        'delivery_fee': deliveryFee,
        'deliveryFee': deliveryFee,
        'delivery_type': deliveryType,
        'deliveryType': deliveryType,
        'customer_id': auth.user?['identifier'],
        'mitra_id': widget.mitraId,
        'mitraId': widget.mitraId,
        'distance': _calculatedDistance.isNaN ? 0.1 : _calculatedDistance,
        'done_at': finishDate.toIso8601String(), // Mengirimkan estimasi selesai
      };

      final success = await orderProv.createOrder(payload);

      if (!mounted) return;

      if (success) {
        _showMerpatiSuccess();
      } else {
        NyutjiNotif.showError(context, orderProv.errorMessage ?? "Gagal membuat pesanan. Coba lagi.");
      }
    } catch (e) {
      if (mounted) NyutjiNotif.showError(context, "Terjadi kesalahan: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleSimpanDraft(int grandTotal) async {
    if (_isSubmitting) return;

    final auth = ref.read(authProvider);
    final orderProv = ref.read(orderProvider);
    setState(() => _isSubmitting = true);

    try {
      final items = widget.selectedItemsList.map((item) => {
        'category': item['category'] ?? 'Umum',
        'item_name': item['name'] ?? item['item_name'] ?? '',
        'qty': item['count'] ?? item['qty'] ?? 1,
        'unit': item['unit'] ?? 'pcs',
        'price_per_unit': item['price'] ?? item['pricePerUnit'] ?? 0,
        'notes': '',
      }).toList();

      final isFastTrack = widget.speed == 'fast';
      final deliveryFee = (widget.isPickup || widget.dropMethod == 'courier') ? _dynamicCourierFee : 0;
      final deliveryType = widget.isPickup 
          ? 'PICKUP' 
          : (widget.dropMethod == 'courier' ? 'SELF_DROP' : 'SELFDROP_SELFDELIVERY');

      final payload = {
        'isDraft': true,
        'address': widget.address,
        'pickupNote': widget.pickupNote,
        'districtName': widget.districtName,
        'cityName': widget.cityName.isNotEmpty ? widget.cityName : 'Tasikmalaya',
        'items': items,
        'lat': widget.lat != 0.0 ? widget.lat : (double.tryParse(auth.user?['lat']?.toString() ?? '') ?? 0.0),
        'lng': widget.lng != 0.0 ? widget.lng : (double.tryParse(auth.user?['lng']?.toString() ?? '') ?? 0.0),
        'is_fast_track': isFastTrack,
        'isFastTrack': isFastTrack,
        'service_type': isFastTrack ? 'SAME_DAY' : 'REGULER',
        'serviceType': isFastTrack ? 'SAME_DAY' : 'REGULER',
        'service_price': widget.totalPrice,
        'servicePrice': widget.totalPrice,
        'delivery_fee': deliveryFee,
        'deliveryFee': deliveryFee,
        'delivery_type': deliveryType,
        'deliveryType': deliveryType,
        'customer_id': auth.user?['identifier'],
        'mitra_id': widget.mitraId,
        'mitraId': widget.mitraId,
        'distance': _calculatedDistance.isNaN ? 0.1 : _calculatedDistance,
        'district_code': widget.districtCode,
      };

      final success = await orderProv.createOrder(payload);
      if (!mounted) return;
      if (success) {
        await orderProv.fetchDraftOrders();
        if (!mounted) return;
        NyutjiNotif.showSuccess(context, 'Draft berhasil disimpan!');
      } else {
        NyutjiNotif.showError(context, orderProv.errorMessage ?? "Gagal menyimpan draft");
      }
    } catch (e) {
      if (mounted) NyutjiNotif.showError(context, "Terjadi kesalahan: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMerpatiSuccess() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: primaryTeal.withValues(alpha: 0.95),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ANIMASI MERPATI TERBANG (MOCK WITH ICON & ANIMATION)
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(seconds: 2),
                  builder: (context, double val, child) {
                    return Transform.translate(
                      offset: Offset(val * 10, -val * 100),
                      child: Opacity(
                        opacity: 1 - (val * 0.5),
                        child: const Icon(LucideIcons.bird, color: Colors.white, size: 80),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text("Cucian Anda Sedang Diterbangkan!", 
                  style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 8),
                Text("Merpati Nyutji sedang menuju lokasi Anda...", 
                  style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        );
      },
    );

    // Otomatis kembali ke Home setelah 3 detik
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    bool needsCourier = widget.isPickup || widget.dropMethod == 'courier';
    int courierFee = needsCourier ? _dynamicCourierFee : 0;
    int grandTotal = widget.totalPrice + courierFee;
    
    final walletProv = ref.watch(walletProvider);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Pembayaran", style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 90),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDenseInvoice(courierFee, grandTotal),
                const SizedBox(height: 16),
                _buildPaymentMenu(walletProv.balance, grandTotal),
              ],
            ),
          ),
          _buildBottomButton(grandTotal),
        ],
      ),
    );
  }

  Widget _buildDenseInvoice(int courierFee, int grandTotal) {
    String invoiceTitle = widget.isPickup 
        ? "Ringkasan Transaksi PickUp Kurir" 
        : widget.dropMethod == 'courier'
            ? "Ringkasan Transaksi Drop - Diantar Kurir"
            : "Ringkasan Transaksi Drop - Diambil Sendiri";
    String speedLabel = widget.speed == 'fast' ? "Fast Track (Same Day)" : "Regular (2-3 Hari)";
    
    String courierServiceName = "Self Drop-off (Gratis)";
    bool isFast = widget.speed == 'fast';

    if (widget.isPickup) {
      courierServiceName = isFast ? "Same Day Pickup Kurir" : "Regular Pickup Kurir";
    } else if (widget.dropMethod == 'courier') {
      courierServiceName = isFast ? "Same Day Delivery Kurir" : "Regular Delivery Kurir";
    }

    // Pangkas alamat panjang GPS — ambil hanya bagian pertama (nama jalan)
    String shortAddress = widget.address.contains(',')
        ? widget.address.split(',').first.trim()
        : widget.address;

    // Buat label lokasi penjemputan
    final pickupParts = [
      shortAddress,
      if (widget.districtName.isNotEmpty) widget.districtName,
    ];
    final mitraParts = [
      if (widget.mitraAddress.isNotEmpty) widget.mitraAddress,
      if (widget.mitraDistrict.isNotEmpty) widget.mitraDistrict,
    ];
    final pickupLabel = pickupParts.join(' · ');
    final mitraLabel = mitraParts.isNotEmpty ? mitraParts.join(' · ') : widget.mitraName;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(invoiceTitle, style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.black87)),
          const SizedBox(height: 12),

          // --- BLOK LOKASI ELEGAN ---
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7F7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: NyutjiTheme.m3Primary.withValues(alpha: 0.12)),
            ),
            child: Column(
              children: [
                if (!widget.isPickup && widget.dropMethod == 'courier') ...[
                  _locationRow(LucideIcons.store, "Lokasi Laundry", mitraLabel),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Color(0xFFDDEEEE)),
                  ),
                  _locationRow(LucideIcons.mapPin, "Lokasi Pengantaran", pickupLabel),
                ] else if (!widget.isPickup && widget.dropMethod == 'self') ...[
                  _locationRow(LucideIcons.store, "Lokasi Laundry", mitraLabel),
                ] else ...[
                  _locationRow(LucideIcons.mapPin, "Lokasi Penjemputan", pickupLabel),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Color(0xFFDDEEEE)),
                  ),
                  _locationRow(LucideIcons.store, "Lokasi Laundry", mitraLabel),
                ],
              ],
            ),
          ),
          const Divider(height: 32),
          
          // Section a: Layanan Laundry
          _invoiceSectionHeader(LucideIcons.shirt, "Layanan Laundry - ${widget.mitraName}"),
          const SizedBox(height: 12),
          _invoiceDetailRow("Jenis Kecepatan", speedLabel),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: widget.selectedItemsList.isEmpty 
              ? Text("Item tidak terbaca, silakan kembali.", style: GoogleFonts.montserrat(fontSize: 13, color: Colors.red))
              : Column(
                  children: widget.selectedItemsList.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text("• ${item['name'] ?? item['item_name'] ?? 'Item'}", style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[700]), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 12),
                        Text("${item['count'] ?? item['qty'] ?? 0} ${item['unit'] ?? ''}", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                  )).toList(),
                ),
          ),
          
          _invoiceDetailRow("Subtotal Laundry", NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(widget.totalPrice), isBold: true),
          
          if (widget.pickupNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Catatan Pelanggan", style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(widget.pickupNote, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
          
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF0F0F0))),
          
          if (widget.isPickup || (!widget.isPickup && widget.dropMethod == 'courier')) ...[
            // Section b: Layanan Kurir
            _invoiceSectionHeader(LucideIcons.truck, "Layanan Kurir - Menunggu Penugasan Kurir"),
            const SizedBox(height: 12),
            _invoiceDetailRow("Layanan Kurir", courierServiceName),
            _invoiceDetailRow("Jarak Antar", "${_calculatedDistance.toStringAsFixed(1)} Km"),
            _invoiceDetailRow("Biaya Kurir", NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(courierFee), isBold: true, isLoading: _isLoadingPrice),
            
            const Divider(height: 40),
          ] else ...[
            const Divider(height: 40),
          ],
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Estimasi Tagihan", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
              Text(
                NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(grandTotal), 
                style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: primaryTeal)
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _invoiceSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 14, color: primaryTeal),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTeal, letterSpacing: 0.5), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _locationRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryTeal.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12, color: primaryTeal),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: primaryTeal, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value.isNotEmpty ? value : '-', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87), overflow: TextOverflow.ellipsis, maxLines: 2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _invoiceDetailRow(String label, String value, {bool isBold = false, bool isLoading = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600])),
          isLoading 
            ? const ShimmerLoading(height: 16, width: 80, borderRadius: 4)
            : Text(value, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildPaymentMenu(double balance, int grandTotal) {
    bool isInsufficient = balance < grandTotal;
    String balanceStr = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(balance);

    Widget dompetDesc = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(
          "Saldo: $balanceStr", 
          style: GoogleFonts.montserrat(
            fontSize: 13, 
            fontWeight: isInsufficient ? FontWeight.bold : FontWeight.normal,
            color: isInsufficient ? primaryRed : Colors.grey[500]
          )
        ),
        if (isInsufficient)
          InkWell(
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomerWalletScreen()));
            },
            child: Text(
              "Update Saldo", 
              style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTeal, decoration: TextDecoration.underline)
            ),
          )
      ]
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text("Metode Pembayaran", style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w900)),
          ),
          
          _paymentParentOption("Dompet Nyutji", "", LucideIcons.wallet, null, isSelected: _selectedPayment == "Dompet Nyutji", customDesc: dompetDesc, isWarning: isInsufficient),
          
          _paymentParentOption("Virtual Account", "BCA, Mandiri, BNI, dll", LucideIcons.building, () {
            setState(() => _isVAExpanded = !_isVAExpanded);
          }, isExpanded: _isVAExpanded),
          if (_isVAExpanded) 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(children: _vaBanks.map((bank) => _paymentSubOption(bank['name']!, bank['logo']!)).toList()),
            ),
            
          _paymentParentOption("e-Wallet", "Gopay, OVO, DANA, dll", LucideIcons.smartphone, () {
            setState(() => _isEWalletExpanded = !_isEWalletExpanded);
          }, isExpanded: _isEWalletExpanded),
          if (_isEWalletExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(children: _eWallets.map((wallet) => _paymentSubOption(wallet['name']!, wallet['logo']!)).toList()),
            ),
          
          _paymentParentOption("QRIS", "Scan dari aplikasi apa saja", LucideIcons.qrCode, null, isSelected: _selectedPayment == "QRIS"),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _paymentParentOption(String title, String desc, IconData icon, VoidCallback? onTap, {bool isSelected = false, bool isExpanded = false, Widget? customDesc, bool isWarning = false}) {
    bool actuallySelected = isSelected || (_selectedPayment.contains(title) && !isExpanded);
    return InkWell(
      onTap: onTap ?? () => setState(() => _selectedPayment = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!, width: 0.5))),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isWarning 
                    ? Colors.red.withValues(alpha: 0.1) 
                    : (actuallySelected ? primaryTeal : bgColor), 
                borderRadius: BorderRadius.circular(10)
              ),
              child: Icon(
                icon, 
                size: 18, 
                color: isWarning 
                    ? Colors.red 
                    : (actuallySelected ? Colors.white : Colors.grey[600])
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold)),
                  if (customDesc != null) customDesc else Text(desc, style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[500])),
                ],
              ),
            ),
            if (onTap != null)
              Icon(isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 16, color: Colors.grey)
            else if (actuallySelected)
              Icon(LucideIcons.checkCircle, size: 18, color: primaryTeal)
          ],
        ),
      ),
    );
  }

  Widget _paymentSubOption(String name, String logoUrl) {
    bool isSel = _selectedPayment == name;
    return InkWell(
      onTap: () => setState(() => _selectedPayment = name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? primaryTeal.withValues(alpha: 0.05) : bgColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSel ? primaryTeal : Colors.transparent),
        ),
        child: Row(
          children: [
            if (logoUrl.isNotEmpty) 
              CachedNetworkImage(
                imageUrl: logoUrl,
                width: 30,
                height: 20,
                fit: BoxFit.contain,
                placeholder: (c, u) => const SizedBox(width: 30, height: 20),
                errorWidget: (c, u, e) => const Icon(LucideIcons.image, size: 14),
              )
            else
              const Icon(LucideIcons.moreHorizontal, size: 14),
            const SizedBox(width: 12),
            Text(name, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: isSel ? FontWeight.bold : FontWeight.w500)),
            const Spacer(),
            if (isSel) Icon(LucideIcons.checkCircle, size: 14, color: primaryTeal),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(int grandTotal) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            OutlinedButton(
              onPressed: _isSubmitting ? null : () => _handleSimpanDraft(grandTotal),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryTeal, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              child: Text("Simpan Draft ?", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: primaryTeal)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () => _handleConfirmOrder(grandTotal),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: primaryTeal.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text("KONFIRMASI PESANAN", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
