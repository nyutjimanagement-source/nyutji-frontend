import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/nyutji_distance.dart';
import '../../../core/utils/nyutji_parser.dart';
import '../../../core/widgets/nyutji_pickup_picker.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../providers/order_provider.dart';
import 'customer_wallet_screen.dart';
import '../../../data/services/api_service.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomerDryCleanScreen extends ConsumerStatefulWidget {
  const CustomerDryCleanScreen({super.key});

  @override ConsumerState<CustomerDryCleanScreen> createState() => _CustomerDryCleanScreenState();
}

class _CustomerDryCleanScreenState extends ConsumerState<CustomerDryCleanScreen> {
  final Color primaryTeal = const Color(0xFF403600);
  final Color accentGold = const Color(0xFFDAC66F);
  final Color darkBg = const Color(0xFF131109);

  String _selectedPayment = "Dompet Nyutji";
  bool _isVAExpanded = false;
  bool _isEWalletExpanded = false;

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

  int _currentStep = 1; // 1: Select Package & Treatments, 2: Select Mitra & Details, 3: Confirm & Pay
  Map<String, dynamic>? _selectedPackage;
  Map<String, dynamic>? _selectedDryCleanService;

  // LIVE DATABASE MITRA MATCHING
  List<dynamic> _matchingMitras = [];
  bool _isLoadingMitras = false;
  Map<String, dynamic>? _selectedMitra;

  // CONFIGURATION STATES
  double _basePrice = 35000.0;
  final Map<String, bool> _selectedTreatments = {
    'Pelarut Organik': true, // Rekomendasi ramah lingkungan
    'Steam Press': true, // Rekomendasi bentuk presisi
    'Anti Jamur': false,
  };

  final Map<String, int> _treatmentPrices = {
    'Pelarut Organik': 10000,
    'Steam Press': 8000,
    'Anti Jamur': 5000,
  };

  // PHOTO POW STATE (Check-in pakaian)
  XFile? _selectedPhoto;
  final ImagePicker _picker = ImagePicker();

  // LOCATION & ADDRESS STATES
  String _pickupAddress = 'Jl. Kebayoran No 12, Jakarta';
  String _pickupNote = '';
  String _selectedDistrict = '';
  String _selectedCity = '';
  double? _selectedLat;
  double? _selectedLng;
  IconData _locationIcon = LucideIcons.mapPin;

  // DELIVERY OPTIONS
  String _deliveryType = 'pickup'; // 'pickup' or 'drop'
  String _returnMethod = 'self'; // 'self' or 'courier'
  String _serviceSpeed = 'regular'; // 'regular' or 'fast'

  // SYSTEM PRICING ONGKIR
  double _calculatedDistance = 0.0;
  int _dynamicCourierFee = 15000;
  bool _isLoadingPrice = false;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _dryCleanPackages = [
    {
      'id': 'formal_suits',
      'name': 'Jas & Tuxedo (Pakaian Formal)',
      'desc': 'Jas, blazer, furing asetat, celana formal, gaun kerja. Dry clean menjaga interlining dada & pundak tetap tegap gagah.',
      'icon': LucideIcons.userCheck,
    //  'base_price': 35000,
      'example': 'Jas Pria, Tuxedo Pernikahan, Blazer Kantoran, Furing Jas'
    },
    {
      'id': 'silk_kebaya',
      'name': 'Sutra, Kebaya & Gaun Payet',
      'desc': 'Gaun malam, kebaya brokat berpayet rumit, sutra murni. Menggunakan solvent lembut menjaga kilau dan kekokohan payet.',
      'icon': LucideIcons.sparkles,
    //  'base_price': 45000,
      'example': 'Kebaya Wisuda/Pengantin, Gaun Malam Sutra, Selendang Sutra'
    },
    {
      'id': 'wool_cashmere',
      'name': 'Wol & Cashmere Premium',
      'desc': 'Mantel wol, sweater rajut cashmere premium. Mencegah penyusutan benang (felting) serta menjaga tekstur bulu halus.',
      'icon': LucideIcons.heart,
    //  'base_price': 40000,
      'example': 'Wool Winter Coat, Cashmere Cardigan, Syal Wol'
    },
    {
      'id': 'leather_suede',
      'name': 'Kulit Asli (Leather) & Suede',
      'desc': 'Jaket kulit, mantel suede asli. Pelarut bebas air menjaga minyak alami kulit agar tidak retak, kaku, ataupun luntur.',
      'icon': LucideIcons.shield,
    //  'base_price': 65000,
      'example': 'Jaket Kulit Motor, Blazer Suede, Rompi Kulit'
    },
  ];

  final List<Map<String, dynamic>> _sopSteps = [
    {
      'step': '01',
      'title': 'Inspeksi & Tagging',
      'desc': 'Pemeriksaan saku dari uang/barang, kancing longgar, robekan, dan pelabelan barcode agar baju tidak tertukar.'
    },
    {
      'step': '02',
      'title': 'Prapembersihan Noda',
      'desc': 'Noda membandel (minyak/tinta) diolesi formula kimia khusus dan disikat lembut sebelum masuk mesin utama.'
    },
    {
      'step': '03',
      'title': 'Mesin Solvent Wash',
      'desc': 'Pakaian diputar lembut dalam mesin tertutup menggunakan pelarut solvent premium tanpa setetes air pun.'
    },
    {
      'step': '04',
      'title': 'Rinsing & Penguapan',
      'desc': 'Mesin membilas dengan solvent murni baru, dilanjutkan pemanasan bertahap menguapkan sisa solvent closed-loop.'
    },
    {
      'step': '05',
      'title': 'Finishing Steam Press',
      'desc': 'Pakaian tidak disetrika panas biasa, melainkan dibentuk ulang menggunakan steam presser & manekin angin.'
    },
    {
      'step': '06',
      'title': 'Inspeksi Akhir Kualitas',
      'desc': 'Quality control ketat memastikan noda telah hilang sempurna, serat kain mengembang alami, dan wangi mewah.'
    },
    {
      'step': '07',
      'title': 'Kemasan Gantung Steril',
      'desc': 'Pakaian digantung rapi dibungkus sarung plastik transparan anti debu agar aman steril selama pengiriman.'
    },
  ];

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    if (auth.user != null) {
      _selectedLat = double.tryParse(auth.user!['lat']?.toString() ?? '');
      _selectedLng = double.tryParse(auth.user!['lng']?.toString() ?? '');
      _selectedCity = auth.user!['city_name'] ?? '';
      _selectedDistrict = auth.user!['district_name'] ?? '';
      _pickupAddress = auth.user!['address'] ?? auth.user!['address_detail'] ?? "$_selectedDistrict, $_selectedCity";
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(walletProvider).fetchWallet();
      }
    });
  }

  double get _totalDryCleanPrice {
    double total = _basePrice;
    _selectedTreatments.forEach((key, val) {
      if (val) {
        total += (_treatmentPrices[key] ?? 0);
      }
    });
    return total;
  }

  Future<void> _loadMitrasForDryClean() async {
    setState(() {
      _isLoadingMitras = true;
      _matchingMitras = [];
      _selectedMitra = null;
    });

    try {
      final api = ApiService();
      // Mengambil mitras yang melayani dry clean. Jika kosong, gunakan pencarian global 'laundry' sebagai fallback.
      List<dynamic> mitras = await api.searchMitras('dry');
      if (mitras.isEmpty) {
        mitras = await api.searchMitras('laundry');
      }
      if (mitras.isEmpty) {
        mitras = await api.searchMitras('cuci');
      }

      List<Map<String, dynamic>> mapped = [];
      for (var m in mitras) {
        final Map<String, dynamic> item = Map<String, dynamic>.from(m);
        
        // FILTER: Tampilkan list ML satu Kab/Kota saja
        if (_selectedCity.isNotEmpty) {
          final String mAddr = (item['address'] ?? '').toString().toLowerCase();
          final String userCity = _selectedCity.toLowerCase();
          if (!mAddr.contains(userCity)) {
            continue; // Lewati jika tidak satu Kab/Kota
          }
        }

        double dist = 0.5;

        if (_selectedLat != null && _selectedLng != null) {
          final mLat = NyutjiParser.toDouble(item['lat']);
          final mLng = NyutjiParser.toDouble(item['lng']);
          if (mLat != 0.0 && mLng != 0.0) {
            double straightDist = NyutjiDistance.calculateDistance(_selectedLat!, _selectedLng!, mLat, mLng);
            dist = NyutjiDistance.calculateRoadDistance(straightDist);
          }
        }

        mapped.add({
          'id': item['id'] ?? '-',
          'name': item['name'] ?? 'Mitra Nyutji',
          'rating': NyutjiParser.toDouble(item['rating'] ?? 5.0),
          'distance': dist,
          'address': item['address'] ?? '-',
          'district': item['district'] ?? '-',
          'image': item['image'],
          'lat': NyutjiParser.toDouble(item['lat']),
          'lng': NyutjiParser.toDouble(item['lng']),
          'services': item['services'] ?? [],
        });
      }

      mapped.sort((a, b) => a['distance'].compareTo(b['distance']));

      setState(() {
        _matchingMitras = mapped;
        _isLoadingMitras = false;
      });
    } catch (e) {
      debugPrint("Error finding mitras for dryclean: $e");
      setState(() => _isLoadingMitras = false);
      if (mounted) NyutjiNotif.showError(context, "Gagal memuat daftar Mitra Dry Clean.");
    }
  }

  bool _isServiceMatching(String serviceName, String packageId) {
    final nameLower = serviceName.toLowerCase();
    if (packageId == 'formal_suits') {
      return nameLower.contains('jas') || nameLower.contains('tuxedo') || nameLower.contains('blazer') || nameLower.contains('formal');
    }
    if (packageId == 'silk_kebaya') {
      return nameLower.contains('sutra') || nameLower.contains('silk') || nameLower.contains('kebaya') || nameLower.contains('gaun') || nameLower.contains('payet');
    }
    if (packageId == 'wool_cashmere') {
      return nameLower.contains('wool') || nameLower.contains('wol') || nameLower.contains('cashmere') || nameLower.contains('mantel');
    }
    if (packageId == 'leather_suede') {
      return nameLower.contains('kulit') || nameLower.contains('leather') || nameLower.contains('suede') || nameLower.contains('jaket kulit');
    }
    return false;
  }

  List<Map<String, dynamic>> _getMatchingServicesForMitra(Map<String, dynamic> mitra) {
    final services = mitra['services'] as List?;
    if (services == null || services.isEmpty) return [];
    final pkgId = _selectedPackage?['id']?.toString() ?? '';
    if (pkgId.isEmpty) return [];
    
    List<Map<String, dynamic>> results = [];
    for (var s in services) {
      final sMap = Map<String, dynamic>.from(s);
      if (_isServiceMatching(sMap['name']?.toString() ?? '', pkgId)) {
        results.add(sMap);
      }
    }
    
    // FALLBACK: Jika tidak ada service yang cocok dengan keyword spesifik (misal nama service Mitra cuma "Dry Clean Satuan"),
    // Tampilkan semua service yang mengandung kata 'dry' atau 'satuan'
    if (results.isEmpty) {
      for (var s in services) {
        final sMap = Map<String, dynamic>.from(s);
        final nameLower = (sMap['name'] ?? '').toString().toLowerCase();
        bool isExclude = nameLower.contains('sepatu') || nameLower.contains('tas') || nameLower.contains('karpet') || nameLower.contains('helm') || nameLower.contains('kiloan') || nameLower.contains('stroller');
        if (!isExclude && (nameLower.contains('dry') || nameLower.contains('satuan') || nameLower.contains('jas') || nameLower.contains('gaun'))) {
          results.add(sMap);
        }
      }
    }
    
    // FALLBACK 2: Jika masih kosong, tampilkan saja semua layanannya agar customer tetap bisa memilih harga (mencegah Rp 0)
    if (results.isEmpty) {
      for (var s in services) {
        results.add(Map<String, dynamic>.from(s));
      }
    }
    
    return results;
  }

  Future<void> _initDeliveryPricing() async {
    if (_selectedMitra == null) return;
    setState(() => _isLoadingPrice = true);

    double straightDist = NyutjiDistance.calculateDistance(
      _selectedLat ?? 0.0,
      _selectedLng ?? 0.0,
      _selectedMitra!['lat'] ?? 0.0,
      _selectedMitra!['lng'] ?? 0.0
    );
    double roadDist = NyutjiDistance.calculateRoadDistance(straightDist);
    if (roadDist < 0.1) roadDist = 0.1;
    _calculatedDistance = roadDist;

    try {
      String type = _deliveryType == 'pickup'
          ? 'pickup'
          : (_returnMethod == 'courier' ? 'delivery' : 'mandiri');

      final api = ApiService();
      final quote = await api.getPriceQuote(
        _calculatedDistance,
        _serviceSpeed == 'fast',
        _selectedLat ?? 0.0,
        _selectedLng ?? 0.0,
        type
      );

      if (quote['status'] == 'success') {
        setState(() {
          _dynamicCourierFee = (quote['data']?['deliveryFee'] as num? ?? quote['data']?['delivery_fee'] as num? ?? 0).toInt();
          _isLoadingPrice = false;
        });
      } else {
        _applyFallbackPricing();
      }
    } catch (e) {
      debugPrint("Gagal quote harga kurir: $e");
      _applyFallbackPricing();
    }
  }

  void _applyFallbackPricing() {
    double baseFee = 5000;
    double perKm = 2500;
    double calculated = baseFee + (_calculatedDistance * perKm);
    if (_serviceSpeed == 'fast') calculated += 5000;
    setState(() {
      _dynamicCourierFee = calculated.toInt();
      _isLoadingPrice = false;
    });
  }

  void _showPickupPicker({String? title}) async {
    final result = await showModalBottomSheet<NyutjiPickupResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NyutjiPickupPicker(title: title),
    );

    if (result != null && mounted) {
      setState(() {
        _pickupAddress = result.address;
        _pickupNote = result.pickupNote;
        _selectedDistrict = result.district;
        _selectedCity = result.city;
        _selectedLat = result.lat;
        _selectedLng = result.lng;
        _locationIcon = LucideIcons.mapPin;
      });
      _initDeliveryPricing();
    }
  }

  Future<void> _pickPOWImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).padding.bottom;
        return Container(
          padding: EdgeInsets.only(bottom: bottomPadding > 0 ? bottomPadding : 16),
          child: Wrap(
            children: [
            ListTile(
              leading: const Icon(LucideIcons.camera, color: Color(0xFF403600)),
              title: Text("Ambil Foto Pakaian", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                if (image != null) setState(() => _selectedPhoto = image);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.image, color: Color(0xFF403600)),
              title: Text("Pilih dari Galeri", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                if (image != null) setState(() => _selectedPhoto = image);
              },
            ),
          ],
        ),
      );
    },
    );
  }

  Future<void> _submitOrderAndPay() async {
    if (_isSubmitting) return;

    final walletProv = ref.read(walletProvider);
    final auth = ref.read(authProvider);
    final orderProv = ref.read(orderProvider);

    bool needsCourier = _deliveryType == 'pickup' || _returnMethod == 'courier';
    int courierFee = needsCourier ? _dynamicCourierFee : 0;
    int grandTotal = _totalDryCleanPrice.toInt() + courierFee;

    if (_selectedPayment != "Dompet Nyutji") {
      if (mounted) NyutjiNotif.showError(context, "Saat ini hanya Dompet Nyutji yang tersedia.");
      return;
    }

    if (walletProv.balance < grandTotal) {
      if (mounted) NyutjiNotif.showError(context, "Saldo Anda Kurang, Silakan Lakukan Top Up");
      return;
    }

    if (_selectedPhoto == null) {
      if (mounted) NyutjiNotif.showError(context, "Foto Pakaian Anda wajib diunggah sebagai lampiran bukti check-in.");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final isFastTrack = _serviceSpeed == 'fast';
      final deliveryType = _deliveryType == 'pickup'
          ? 'PICKUP'
          : (_returnMethod == 'courier' ? 'SELF_DROP' : 'SELFDROP_SELFDELIVERY');

      final selectedTreatmentsList = [];
      _selectedTreatments.forEach((k, v) {
        if (v) selectedTreatmentsList.add(k);
      });
      final String noteTreatment = selectedTreatmentsList.isNotEmpty
          ? " (Dry Clean: ${selectedTreatmentsList.join(', ')})"
          : "";

      final items = [
        {
          'category': 'Satuan',
          'item_name': _selectedDryCleanService != null 
              ? "${_selectedDryCleanService!['name']}$noteTreatment" 
              : "${_selectedPackage!['name']}$noteTreatment",
          'qty': 1,
          'unit': 'Pcs',
          'price_per_unit': _totalDryCleanPrice.toInt(),
          'notes': 'Dry Cleaning Premium Professional',
        }
      ];

      String districtCode = 'NYJ';
      if (_selectedMitra != null && _selectedMitra!['id'] != null) {
        final mId = _selectedMitra!['id'].toString();
        final parts = mId.split('-');
        if (parts.length >= 2) {
          districtCode = parts[1].toUpperCase();
        }
      }

      final now = DateTime.now();
      final finishDate = isFastTrack ? now.add(const Duration(days: 1)) : now.add(const Duration(days: 3));

      final payload = {
        'address': _pickupAddress,
        'pickupNote': _pickupNote,
        'districtName': _selectedDistrict.isNotEmpty ? _selectedDistrict : (auth.user?['district_name']?.toString() ?? ''),
        'cityName': _selectedCity.isNotEmpty ? _selectedCity : (auth.user?['city_name']?.toString() ?? 'Tasikmalaya'),
        'items': items,
        'lat': _selectedLat ?? double.tryParse(auth.user?['lat']?.toString() ?? '') ?? 0.0,
        'lng': _selectedLng ?? double.tryParse(auth.user?['lng']?.toString() ?? '') ?? 0.0,
        'is_fast_track': isFastTrack,
        'service_price': _totalDryCleanPrice.toInt(),
        'servicePrice': _totalDryCleanPrice.toInt(),
        'delivery_fee': courierFee,
        'delivery_type': deliveryType,
        'customer_id': auth.user?['identifier'],
        'mitra_id': _selectedMitra!['id'],
        'distance': _calculatedDistance.isNaN ? 0.1 : _calculatedDistance,
        'district_code': districtCode,
        'done_at': finishDate.toIso8601String(),
        'doneAt': finishDate.toIso8601String(),
      };

      final success = await orderProv.createOrder(payload);

      if (success) {
        await orderProv.fetchOrders();
        final newOrder = orderProv.activeOrders.isNotEmpty ? orderProv.activeOrders.first : null;
        final orderNo = newOrder?['order_number']?.toString() ?? newOrder?['orderNumber']?.toString();
        if (orderNo != null) {
          // Upload foto pakaian fisik pelanggan
          await orderProv.uploadPOWImage(orderNo, _selectedPhoto!, 'WEIGHING');
        }

        _showMerpatiSuccess();
      } else {
        if (mounted) NyutjiNotif.showError(context, orderProv.errorMessage ?? "Gagal membuat pesanan.");
      }
    } catch (e) {
      if (mounted) NyutjiNotif.showError(context, "Terjadi kesalahan sistem: ${e.toString()}");
    } finally {
      setState(() => _isSubmitting = false);
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
                Text("Pakaian Anda Sedang Diterbangkan!", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 8),
                Text("Merpati Nyutji sedang menuju lokasi Anda...", style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9ED),
      appBar: AppBar(
        backgroundColor: primaryTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _currentStep == 1
              ? "Premium Dry Cleaning"
              : (_currentStep == 2 ? "List Mitra dan Opsional Pengantaran" : "Konfirmasi Pembayaran"),
          style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (_currentStep == 1) _buildStep1PackageSelection(),
          if (_currentStep == 2) _buildStep2MitraConfig(),
          if (_currentStep == 3) _buildStep3PaymentSummary(),
          if (_isSubmitting)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator(color: Color(0xFF403600))),
            )
        ],
      ),
    );
  }

  // --- STEP 1: SELECT PACKAGE & REGULATION TREATMENTS ---
  Widget _buildStep1PackageSelection() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        // Title banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primaryTeal.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Premium Dry Cleaning & Care", style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w900, color: primaryTeal)),
              const SizedBox(height: 4),
              Text("Pencucian khusus tanpa air menggunakan cairan pelarut (solvent) organik. Sangat direkomendasikan untuk wol, sutra, kebaya, jas tegap, dan bahan kulit asli agar tidak menyusut atau berubah bentuk.", style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600])),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Text("1. Pilih Jenis Pakaian / Bahan Dry Clean:", style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.65,
          children: _dryCleanPackages.map((pkg) {
            bool isSel = _selectedPackage?['id'] == pkg['id'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPackage = pkg;
                  _basePrice = NyutjiParser.toDouble(pkg['base_price']);
                  _selectedDryCleanService = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSel ? primaryTeal : const Color(0xFFE3DCCF), width: isSel ? 2 : 1),
                  boxShadow: [BoxShadow(color: isSel ? primaryTeal.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.01), blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSel ? primaryTeal : primaryTeal.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(pkg['icon'], color: isSel ? Colors.white : primaryTeal, size: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      pkg['name'],
                      style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: darkBg),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pkg['desc'],
                              style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600], height: 1.3),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Contoh: ${pkg['example']}",
                              style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[400], fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),
        Text("2. Tambahan Layanan Perawatan Khusus:", style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 12),

        _treatmentCheckbox("Pelarut Organik", "Cairan solvent organik ramah lingkungan & hypoallergenic bagi kulit sensitif.", 10000),
        _treatmentCheckbox("Steam Press", "Penyetrikaan uap presisi dengan manekin angin menjaga kelurusan lipatan jas.", 8000),
        _treatmentCheckbox("Anti Jamur", "Semprotan anti jamur & pelembap furing khusus untuk wol, cashmere, & kulit.", 5000),

        const SizedBox(height: 28),
        Text("3. Alur Proses Dry Cleaning:", style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 12),

        // HORIZONTAL SCROLL OF SOP FOR LUXURY FEELING - FULL PARAGRAPHS NO TRUNCATION
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _sopSteps.length,
            itemBuilder: (context, index) {
              final step = _sopSteps[index];
              return Container(
                width: 220,
                margin: const EdgeInsets.only(right: 12, bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE3DCCF)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryTeal.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            step['step'],
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: primaryTeal,
                            ),
                          ),
                        ),
                        Icon(LucideIcons.checkCircle, color: primaryTeal.withValues(alpha: 0.3), size: 14),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      step['title'],
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: darkBg,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        step['desc'],
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 36),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedPackage == null ? Colors.grey : primaryTeal,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _selectedPackage == null
              ? null
              : () {
                  setState(() => _currentStep = 2);
                  _loadMitrasForDryClean();
                },
          child: Text(
            _selectedPackage == null ? "PILIH LAYANAN DRY CLEAN" : "PILIH MITRA LAUNDRY",
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _treatmentCheckbox(String name, String desc, int price) {
    String key = name.contains("Pelarut")
        ? "Pelarut Organik"
        : (name.contains("Steam") ? "Steam Press" : "Anti Jamur");
    bool isSel = _selectedTreatments[key] ?? false;

    return GestureDetector(
      onTap: () => setState(() => _selectedTreatments[key] = !isSel),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSel ? primaryTeal : const Color(0xFFE3DCCF)),
        ),
        child: Row(
          children: [
            Icon(isSel ? LucideIcons.checkSquare : LucideIcons.square, color: isSel ? primaryTeal : Colors.grey, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: darkBg)),
                  Text(desc, style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[500])),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text("+Rp ${NumberFormat.decimalPattern('id_ID').format(price)}", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTeal)),
          ],
        ),
      ),
    );
  }

  // --- STEP 2: MITRA SELECTION & CONFIGURATION ---
  Widget _buildStep2MitraConfig() {
    return Column(
      children: [
        // Summary of Selected Package & Treatments
        Container(
          padding: const EdgeInsets.all(16),
          color: primaryTeal.withValues(alpha: 0.03),
          child: Row(
            children: [
              Icon(_selectedPackage!['icon'], color: primaryTeal, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedDryCleanService != null ? _selectedDryCleanService!['name'] : _selectedPackage!['name'], style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: primaryTeal)),
                    Text("Total Estimasi: Rp ${NumberFormat.decimalPattern('id_ID').format(_totalDryCleanPrice)}", style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _currentStep = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text("Ubah", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTeal)),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoadingMitras
              ? ListView.builder(
                  itemCount: 3,
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: ShimmerLoading(height: 72, width: double.infinity, borderRadius: 16),
                  ),

                )
              : _matchingMitras.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.store, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text("Belum ada Mitra laundry yang melayani", style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text("layanan dry cleaning di sekitar Anda.", style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        Text("Pilih Mitra Laundry Terdekat:", style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                        const SizedBox(height: 12),
                        ..._matchingMitras.map((m) {
                          bool isSel = _selectedMitra?['id'] == m['id'];
                          final matchingServices = _getMatchingServicesForMitra(m);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMitra = m;
                                if (matchingServices.isNotEmpty) {
                                  _selectedDryCleanService = matchingServices.first;
                                  _basePrice = NyutjiParser.toDouble(_selectedDryCleanService!['price_regular'] ?? _selectedDryCleanService!['price']);
                                } else {
                                  _selectedDryCleanService = null;
                                  _basePrice = 0.0;
                                }
                              });
                              _initDeliveryPricing();
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isSel ? primaryTeal : const Color(0xFFE3DCCF), width: isSel ? 2 : 1),
                                boxShadow: [BoxShadow(color: isSel ? primaryTeal.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.01), blurRadius: 6)],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 44, height: 44,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(10),
                                          image: m['image'] != null ? DecorationImage(image: CachedNetworkImageProvider(m['image'].toString().startsWith('http') ? m['image'] : "${ApiConstants.rootUrl}/${m['image']}"), fit: BoxFit.cover) : null,
                                        ),
                                        child: m['image'] == null ? const Icon(LucideIcons.store, color: Colors.grey) : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(m['name'], style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: darkBg)),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                const Icon(LucideIcons.star, color: Colors.amber, size: 10),
                                                const SizedBox(width: 4),
                                                Text(m['rating'].toString(), style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                                                const SizedBox(width: 8),
                                                const Icon(LucideIcons.mapPin, color: Colors.grey, size: 10),
                                                const SizedBox(width: 4),
                                                Text(NyutjiDistance.formatDistance(m['distance'] ?? 0.1), style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600])),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSel)
                                        Icon(LucideIcons.checkCircle, color: primaryTeal, size: 18),
                                    ],
                                  ),
                                  if (isSel && matchingServices.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    const Divider(color: Color(0xFFE3DCCF)),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Daftar Harga Layanan:",
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...matchingServices.map((service) {
                                      final double sPrice = NyutjiParser.toDouble(service['price_regular'] ?? service['price']);
                                      final bool isServiceSel = 
                                          _selectedDryCleanService?['mitra_id'] == service['mitra_id'] &&
                                          _selectedDryCleanService?['name'] == service['name'];
                                      
                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            _selectedDryCleanService = service;
                                            _basePrice = sPrice;
                                          });
                                          _initDeliveryPricing();
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  "${service['name']}",
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 12,
                                                    fontWeight: isServiceSel ? FontWeight.bold : FontWeight.normal,
                                                    color: darkBg,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Rp ${NumberFormat('#,###', 'id_ID').format(sPrice)}",
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 12,
                                                  fontWeight: isServiceSel ? FontWeight.bold : FontWeight.normal,
                                                  color: isServiceSel ? primaryTeal : Colors.grey[700],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Icon(
                                                isServiceSel ? LucideIcons.checkCircle2 : LucideIcons.circle,
                                                size: 16,
                                                color: isServiceSel ? primaryTeal : Colors.grey[300],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),

                        if (_selectedMitra != null) ...[
                          const SizedBox(height: 24),
                          const Divider(height: 1, color: Color(0xFFE3DCCF)),
                          const SizedBox(height: 24),

                          // DELIVERY OPTION Choice
                          Text("Metode Pengantaran:", style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _deliveryCard(
                                  "PickUp Kurir",
                                  "Antar jemput kurir",
                                  LucideIcons.truck,
                                  _deliveryType == 'pickup',
                                  () {
                                    setState(() => _deliveryType = 'pickup');
                                    _initDeliveryPricing();
                                  }
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _deliveryCard(
                                  "Antar Sendiri",
                                  "Drop-off ke Laundry",
                                  LucideIcons.user,
                                  _deliveryType == 'drop',
                                  () {
                                    setState(() => _deliveryType = 'drop');
                                    _initDeliveryPricing();
                                  }
                                ),
                              ),
                            ],
                          ),

                          if (_deliveryType == 'drop') ...[
                            const SizedBox(height: 16),
                            Text("Metode Pengembalian:", style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _returnOption("Diambil Sendiri", "self", LucideIcons.user, _returnMethod == 'self')),
                                const SizedBox(width: 12),
                                Expanded(child: _returnOption("Diantar Kurir", "courier", LucideIcons.truck, _returnMethod == 'courier')),
                              ],
                            ),
                          ],

                          const SizedBox(height: 24),
                          // SPEED choice
                          Text("Kecepatan Layanan:", style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE3DCCF))),
                            child: Row(
                              children: [
                                Expanded(child: _speedPill("Reguler", "2-3 Hari Kerja", _serviceSpeed == 'regular', () {
                                  setState(() => _serviceSpeed = 'regular');
                                  _initDeliveryPricing();
                                })),
                                Expanded(child: _speedPill("Fast Track", "Selesai Hari Sama", _serviceSpeed == 'fast', () {
                                  setState(() => _serviceSpeed = 'fast');
                                  _initDeliveryPricing();
                                })),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryTeal,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () => setState(() => _currentStep = 3),
                            child: Text("LANJUTKAN KE DETAIL", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                          const SizedBox(height: 40),
                        ]
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _deliveryCard(String title, String desc, IconData icon, bool isSel, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSel ? primaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSel ? primaryTeal : const Color(0xFFE3DCCF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: isSel ? Colors.white : primaryTeal),
            const SizedBox(height: 8),
            Text(title, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: isSel ? Colors.white : darkBg)),
            Text(desc, style: GoogleFonts.montserrat(fontSize: 13, color: isSel ? Colors.white70 : Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _returnOption(String label, String value, IconData icon, bool isSel) {
    return GestureDetector(
      onTap: () {
        setState(() => _returnMethod = value);
        _initDeliveryPricing();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? primaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSel ? primaryTeal : const Color(0xFFE3DCCF))
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isSel ? Colors.white : Colors.grey),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: isSel ? Colors.white : Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _speedPill(String title, String desc, bool isSel, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: isSel ? primaryTeal.withValues(alpha: 0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(title, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: isSel ? primaryTeal : Colors.grey[400])),
            Text(desc, style: GoogleFonts.montserrat(fontSize: 13, color: isSel ? primaryTeal.withValues(alpha: 0.8) : Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  // --- STEP 3: PHOTO UPLOAD POW, ADDRESS INFO, nota TRANSACTION SUMMARY ---
  Widget _buildStep3PaymentSummary() {
    final walletProv = ref.watch(walletProvider);
    bool needsCourier = _deliveryType == 'pickup' || _returnMethod == 'courier';
    int courierFee = needsCourier ? _dynamicCourierFee : 0;
    int grandTotal = _totalDryCleanPrice.toInt() + courierFee;
    bool isInsufficient = walletProv.balance < grandTotal;

    final selectedTreatmentsList = [];
    _selectedTreatments.forEach((k, v) {
      if (v) selectedTreatmentsList.add(k);
    });

    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. DOKUMENTASI AWAL PAKAIAN (CHECK-IN)
        Text("1. Foto Pakaian Anda (Wajib)", style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickPOWImage,
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE3DCCF), width: 1.2),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10)],
            ),
            clipBehavior: Clip.antiAlias,
            child: _selectedPhoto == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.camera, size: 36, color: primaryTeal.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      Text("Tekan untuk Unggah Foto", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTeal)),
                    ],
                  )
                : Stack(
                    children: [
                      Positioned.fill(
                        child: Image.file(File(_selectedPhoto!.path), fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 8, right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPhoto = null),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(LucideIcons.x, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 24),
        // 2. ALAMAT PENJEMPUTAN / LOKASI PENGIRIMAN
        Text(
          _deliveryType == 'pickup'
              ? "2. Lokasi Penjemputan"
              : (_returnMethod == 'courier' ? "2. Lokasi Pengiriman" : "2. Informasi Pengantaran"),
          style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[700]),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE3DCCF))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (needsCourier) ...[
                Row(
                  children: [
                    Icon(_locationIcon, size: 16, color: primaryTeal),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_pickupAddress, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: darkBg), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showPickupPicker(title: "Pilih Alamat"),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: Text("Ubah", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTeal)),
                      ),
                    ),
                  ],
                ),
                if (_pickupNote.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_pickupNote, style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600])),
                ],
              ] else ...[
                Row(
                  children: [
                    Icon(LucideIcons.store, size: 16, color: primaryTeal),
                    const SizedBox(width: 8),
                    Expanded(child: Text("Anda mengantar & mengambil pakaian secara mandiri ke Lokasi Laundry Mitra terpilih.", style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600]))),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),
        // 3. NOTA ESTIMASI INVOICE
        Text("3. Nota Estimasi Dry Clean", style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE3DCCF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_selectedDryCleanService != null ? _selectedDryCleanService!['name'] : _selectedPackage!['name'], style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: darkBg)),
              Text("Mitra: ${_selectedMitra!['name']}", style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[500])),
              const SizedBox(height: 12),
              _invoiceRow("Kecepatan Layanan", _serviceSpeed == 'fast' ? "Fast Track (Same Day)" : "Regular (2-3 Hari)"),
              _invoiceRow("Nomor Resi", () {
                String districtCode = 'NYJ';
                if (_selectedMitra != null && _selectedMitra!['id'] != null) {
                  final mId = _selectedMitra!['id'].toString();
                  final parts = mId.split('-');
                  if (parts.length >= 2) {
                    districtCode = parts[1].toUpperCase();
                  }
                }
                final todayStr = DateFormat('yyyyMMdd').format(DateTime.now());
                return "$districtCode-$todayStr-XXXX";
              }()),
              _invoiceRow("Est. Tanggal Selesai", _serviceSpeed == 'fast'
                  ? "${DateFormat('dd MMM yyyy').format(DateTime.now())} (Same Day)"
                  : "${DateFormat('dd MMM yyyy').format(DateTime.now().add(const Duration(days: 3)))} (3 Hari)"),
              _invoiceRow("Biaya Dry Clean Utama", "Rp ${NumberFormat.decimalPattern('id_ID').format(_basePrice)}"),
              if (selectedTreatmentsList.isNotEmpty)
                _invoiceRow("Treatment Tambahan", selectedTreatmentsList.join(', ')),
              if (needsCourier) ...[
                _invoiceRow("Biaya Kurir Nyutji", _isLoadingPrice ? "Menghitung..." : "Rp ${NumberFormat.decimalPattern('id_ID').format(courierFee)}"),
                _invoiceRow("Jarak Lokasi", "${_calculatedDistance.toStringAsFixed(1)} Km"),
              ],
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Pembayaran", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: darkBg)),
                  Text("Rp ${NumberFormat.decimalPattern('id_ID').format(grandTotal)}", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: primaryTeal)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        // 4. Metode Pembayaran
        Text("4. Metode Pembayaran", style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20)],
            border: Border.all(color: const Color(0xFFE3DCCF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _paymentParentOption(
                "Dompet Nyutji", 
                "", 
                LucideIcons.wallet, 
                null, 
                isSelected: _selectedPayment == "Dompet Nyutji", 
                customDesc: Row(
                  children: [
                    Text(
                      "Saldo Anda: Rp ${NumberFormat.decimalPattern('id_ID').format(walletProv.balance)}", 
                      style: GoogleFonts.montserrat(
                        fontSize: 13, 
                        fontWeight: isInsufficient ? FontWeight.bold : FontWeight.normal,
                        color: isInsufficient ? Colors.red : Colors.grey[500]
                      )
                    ),
                    if (isInsufficient) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CustomerWalletScreen()),
                          );
                        },
                        child: Text(
                          "Top-Up", 
                          style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTeal, decoration: TextDecoration.underline)
                        ),
                      )
                    ]
                  ]
                ),
                isWarning: isInsufficient,
              ),
              
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
        ),

        const SizedBox(height: 32),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: (_selectedPayment == "Dompet Nyutji" && isInsufficient) ? Colors.grey : primaryTeal,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: (_selectedPayment == "Dompet Nyutji" && isInsufficient) ? null : _submitOrderAndPay,
          child: Text(
            (_selectedPayment == "Dompet Nyutji" && isInsufficient) 
                ? "SALDO TIDAK CUKUP" 
                : "BAYAR PESANAN (Rp ${NumberFormat.decimalPattern('id_ID').format(grandTotal)})",
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)
          ),
        ),
        SizedBox(height: 40 + MediaQuery.of(context).padding.bottom),
      ],
    );
  }

  Widget _invoiceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: darkBg),
              textAlign: TextAlign.right,
            ),
          ),
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
                    : (actuallySelected ? primaryTeal : const Color(0xFFF7F5F0)), 
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
          color: isSel ? primaryTeal.withValues(alpha: 0.05) : const Color(0xFFF7F5F0).withValues(alpha: 0.5),
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
            Expanded(child: Text(name, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600))),
            if (isSel) Icon(LucideIcons.checkCircle, size: 16, color: primaryTeal),
          ],
        ),
      ),
    );
  }
}
