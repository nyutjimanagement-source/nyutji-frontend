import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/nyutji_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/nyutji_parser.dart';
import '../../../core/widgets/nyutji_pickup_picker.dart';
import '../../../providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'customer_payment_screen.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/cache_service.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../core/utils/nyutji_distance.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../providers/order_provider.dart';

class CustomerOrderScreen extends ConsumerStatefulWidget {
  final String orderType;
  final Map<String, dynamic>? preselectedMitra;

  const CustomerOrderScreen({
    super.key,
    this.orderType = 'pickup',
    this.preselectedMitra,
  });

  @override ConsumerState<CustomerOrderScreen> createState() => _CustomerOrderScreenState();
}

class _CustomerOrderScreenState extends ConsumerState<CustomerOrderScreen> {
  String _pickupAddress = 'Jl. Kebayoran No 12, Jakarta';
  String _pickupNote = '';
  String _serviceSpeed = 'regular';
  String _returnMethod = 'self'; // 'self' atau 'courier'
  
  // STATE UNTUK PESANAN (Item ID/Identifier -> Count)
  final Map<dynamic, int> _itemCounts = {};
  File? _orderImage;
  
  // STATE UNTUK MAPS & LOKASI
  double? _selectedLat;
  double? _selectedLng;
  String _selectedDistrict = '';
  String _selectedCity = '';
  
  // STATE MITRA & ITEMS (LIVE DATABASE)
  Map<String, dynamic>? _selectedMitra;
  List<Map<String, dynamic>> _mitras = [];
  bool _isLoadingMitras = true;
  bool _isConnectionError = false;

  // ANTI-RACE-CONDITION: Counter generasi load. Setiap pemanggilan baru menaikkan counter.
  // Hasil dari request lama (generasi lama) akan dibuang otomatis.
  int _loadGeneration = 0;

  final Map<String, int> _categoryPages = {};

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    if (auth.user != null) {
      final uLat = double.tryParse(auth.user!['lat']?.toString() ?? '');
      final uLng = double.tryParse(auth.user!['lng']?.toString() ?? '');
      if (uLat != null && uLng != null && uLat != 0.0 && uLng != 0.0) {
        _selectedLat = uLat;
        _selectedLng = uLng;
        _selectedCity = auth.user!['city_name'] ?? '';
        _selectedDistrict = auth.user!['district_name'] ?? '';
      }
    }
    
    if (widget.preselectedMitra != null) {
      _selectedMitra = widget.preselectedMitra;
    }
    
    _loadLiveMitras();
    Future.microtask(() => ref.read(orderProvider).fetchDraftOrders());
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _orderImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      NyutjiNotif.showError(context, "Gagal mengambil foto: $e");
    }
  }

  void _showImageSourceSheet() {
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
                title: Text("Ambil Foto Pakaian", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.black)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.image, color: Color(0xFF403600)),
                title: Text("Pilih dari Galeri", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.black)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }






  Future<void> _loadLiveMitras({String? forcedCity}) async {
    // Naikkan generasi — request lama yang masih berjalan akan dibuang
    final int myGeneration = ++_loadGeneration;

    final targetCity = forcedCity ?? _selectedCity;
    final cacheKey = 'recommended_mitras_${targetCity.isEmpty ? "default" : targetCity}';

    // 1. Coba baca dari cache dulu agar UI ter-render instan
    final cached = CacheService.get(cacheKey);
    if (cached != null && cached is List) {
      _processMappedMitras(cached, myGeneration);
      _isLoadingMitras = false;
      if (mounted) setState(() {});
    } else {
      setState(() {
        _isLoadingMitras = true;
        _isConnectionError = false;
      });
    }

    try {
      final api = ApiService();
      final data = await api.getRecommendedMitras(cityName: targetCity);

      if (myGeneration != _loadGeneration) return;

      _processMappedMitras(data, myGeneration);

      _recalculateDistances();
      if (mounted) {
        setState(() {
          _isLoadingMitras = false;
        });
      }

      // Fetch harga tiap mitra di background
      for (var m in _mitras) {
        _fetchMitraItems(m['id']);
      }
    } catch (e) {
      debugPrint("Gagal mengambil live mitras dari API: $e");
      if (myGeneration != _loadGeneration) return;
      if (_mitras.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoadingMitras = false;
            _isConnectionError = true;
          });
          NyutjiNotif.showError(context, "Koneksi terkendala. Cek internet Anda.");
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingMitras = false;
          });
        }
      }
    }
  }

  void _processMappedMitras(List<dynamic> rawData, int myGeneration) {
    List<Map<String, dynamic>> mapped = rawData.map((m) {
      final Map<String, dynamic> item = Map<String, dynamic>.from(m);
      return {
        'id': item['identifier'] ?? item['id'] ?? '-',
        'name': item['name'] ?? item['brand_name'] ?? 'Mitra Nyutji',
        'rating': NyutjiParser.toDouble(item['rating'] ?? 5.0),
        'distance': NyutjiParser.toDouble(item['distance'] ?? 0.1),
        'address': item['address'] ?? '-',
        'district': item['district_name'] ?? item['owner_district_name'] ?? item['district'] ?? '-',
        'image': item['image'] ?? item['profile_photo'] ?? item['photo'],
        'lat': NyutjiParser.toDouble(item['lat']),
        'lng': NyutjiParser.toDouble(item['lng']),
        'items': item['items'] ?? [],
        'items_loaded': false,
      };
    }).toList();

    if (!mounted || myGeneration != _loadGeneration) return;

    // INJECT PRESELECTED MITRA JIKA TIDAK ADA DI HASIL API
    if (_selectedMitra != null) {
      bool exists = mapped.any((m) => m['id'].toString() == _selectedMitra!['id'].toString());
      if (!exists) {
        final normalizedMitra = {
          'id': _selectedMitra!['id'] ?? _selectedMitra!['identifier'] ?? '-',
          'name': _selectedMitra!['name'] ?? _selectedMitra!['brand_name'] ?? 'Mitra Nyutji',
          'rating': NyutjiParser.toDouble(_selectedMitra!['rating'] ?? 5.0),
          'distance': NyutjiParser.toDouble(_selectedMitra!['distance'] ?? 0.1),
          'address': _selectedMitra!['address'] ?? '-',
          'district': _selectedMitra!['district_name'] ?? _selectedMitra!['owner_district_name'] ?? _selectedMitra!['district'] ?? '-',
          'image': _selectedMitra!['image'] ?? _selectedMitra!['profile_photo'] ?? _selectedMitra!['photo'],
          'lat': NyutjiParser.toDouble(_selectedMitra!['lat']),
          'lng': NyutjiParser.toDouble(_selectedMitra!['lng']),
          'items': _selectedMitra!['items'] ?? [],
          'items_loaded': false,
        };
        mapped.insert(0, normalizedMitra);
      }
    }

    _mitras = mapped;
    
    // Sinkronkan referensi _selectedMitra dengan object di _mitras agar UI Daftar Harga langsung update
    if (_selectedMitra != null) {
      try {
        _selectedMitra = _mitras.firstWhere((m) => m['id'].toString() == _selectedMitra!['id'].toString());
      } catch (_) {}
    }
  }

  void _recalculateDistances() {
    if (_selectedLat == null || _selectedLng == null || _mitras.isEmpty) return;

    for (var m in _mitras) {
      final double mLat = m['lat'] ?? 0;
      final double mLng = m['lng'] ?? 0;
      
      if (mLat != 0 && mLng != 0) {
        double rawDist = NyutjiDistance.calculateDistance(_selectedLat!, _selectedLng!, mLat, mLng);
        m['distance'] = NyutjiDistance.calculateRoadDistance(rawDist);
      } else {
        // Jika koordinat mitra 0, beri jarak default tapi jangan 0 biar gak aneh
        m['distance'] = 0.5; 
      }
    }

    // SORTING GENIUS: Prioritas Jarak, lalu Rating sebagai penentu jika jarak mirip
    _mitras.sort((a, b) {
      double distA = a['distance'];
      double distB = b['distance'];
      double rateA = a['rating'] ?? 0.0;
      double rateB = b['rating'] ?? 0.0;

      // Jika selisih jarak kurang dari 500 meter (0.5 km), prioritaskan Rating
      if ((distA - distB).abs() < 0.5) {
        return rateB.compareTo(rateA); // Rating tinggi di depan
      }
      
      // Jika selisih jarak signifikan, prioritaskan Jarak terdekat
      return distA.compareTo(distB);
    });
    
    setState(() {}); // Refresh UI
  }



  String _getSmartAddress(String fullAddress) {
    if (fullAddress.isEmpty || fullAddress == 'Jl. Kebayoran No 12, Jakarta') return fullAddress;
    
    // LOGIKA SMART: Pisahkan koma, buang yang tidak perlu
    List<String> parts = fullAddress.split(',').map((e) => e.trim()).toList();
    
    // Keyword yang dibuang (Propinsi & Negara)
    List<String> unwanted = [
      'Indonesia', 'Banten', 'Jawa Barat', 'DKI Jakarta', 'Jawa Tengah', 
      'Jawa Timur', 'DI Yogyakarta', 'Bali', 'Sumatera', 'Kalimantan', 'Sulawesi'
    ];
    
    // Filter parts yang tidak mengandung unwanted keywords
    List<String> filtered = parts.where((p) {
      return !unwanted.any((u) => p.toLowerCase().contains(u.toLowerCase()));
    }).toList();
    
    // Gabungkan kembali (Maksimal 3-4 bagian awal: Jalan, Kec, Kota, Pos)
    if (filtered.length > 4) {
      return filtered.sublist(0, 4).join(', ');
    }
    return filtered.join(', ');
  }



  Future<void> _fetchMitraItems(dynamic mitraId) async {
    try {
      final api = ApiService();
      // Set timeout 10 detik sesuai instruksi
      final items = await api.getMitraItems(mitraId).timeout(const Duration(seconds: 10)); 
      
      if (mounted) {
        setState(() {
          int idx = _mitras.indexWhere((m) => m['id'] == mitraId);
          if (idx != -1) {
            _mitras[idx]['items'] = items;
            _mitras[idx]['items_loaded'] = true;
            if (_selectedMitra != null && _selectedMitra!['id'] == mitraId) {
              _selectedMitra!['items'] = items;
              _selectedMitra!['items_loaded'] = true;
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching items for mitra $mitraId: $e");
      if (mounted) {
        setState(() {
          int idx = _mitras.indexWhere((m) => m['id'] == mitraId);
          if (idx != -1) {
            _mitras[idx]['items_loaded'] = true; // Tetap tandai selesai meski gagal agar UI terganti
            if (_selectedMitra != null && _selectedMitra!['id'] == mitraId) {
              _selectedMitra!['items_loaded'] = true;
            }
          }
        });
      }
    }
  }


  // STATE SOURCE LOKASI UNTUK ICON
  IconData _locationIcon = LucideIcons.mapPin;

  final Color primaryTeal = NyutjiTheme.m3Primary;
  final Color primaryRed = NyutjiTheme.m3Error;
  final Color bgColor = NyutjiTheme.m3Surface;

  int get _totalItems => _itemCounts.values.fold(0, (a, b) => a + b);
  int get _totalPrice {
    if (_selectedMitra == null) return 0;
    double baseTotal = 0;
    
    final allPossibleItems = (_selectedMitra!['items'] as List<dynamic>?) ?? [];
    bool isFast = _serviceSpeed == 'fast';
    
    _itemCounts.forEach((itemId, count) {
      if (count > 0) {
        try {
          // Cari item dengan perbandingan String untuk keamanan
          var item = allPossibleItems.firstWhere(
            (i) => i['id'].toString() == itemId.toString(),
            orElse: () => null
          );
          
          if (item != null) {
            // Pastikan parsing ke double agar tidak error saat perkalian
            double pReg = double.tryParse(item['price_regular']?.toString() ?? item['price']?.toString() ?? '0') ?? 0;
            
            // JIKA Fast Track dipilih, tapi harga pFast kosong/nol, maka pakai pReg (Instruksi Boss)
            double? pFastRaw = double.tryParse(item['price_fast']?.toString() ?? '');
            double pFast = (pFastRaw == null || pFastRaw == 0) ? pReg : pFastRaw;
            
            double selectedPrice = isFast ? pFast : pReg;
            baseTotal += (count * selectedPrice);
          }
        } catch (e) {
          debugPrint("Error calculating price for item $itemId: $e");
        }
      }
    });
    return baseTotal.toInt();
  }

  void _updateItemCount(dynamic itemId, int delta) {
    setState(() {
      _itemCounts[itemId] = (_itemCounts[itemId] ?? 0) + delta;
      if (_itemCounts[itemId]! < 0) _itemCounts[itemId] = 0;
    });
  }

  void _setItemCount(dynamic itemId, int value) {
    setState(() {
      _itemCounts[itemId] = value;
      if (_itemCounts[itemId]! < 0) _itemCounts[itemId] = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan try-catch di level tertinggi build untuk menangkap error gaib di mode Release
    try {
      final auth = ref.watch(authProvider);
      
      // Sinkronisasi alamat dari AuthProvider jika tersedia (Hanya sekali saat awal)
      if (auth.user != null && (_pickupAddress == 'Jl. Kebayoran No 12, Jakarta' || _selectedDistrict.isEmpty)) {
         final district = auth.user?['district_name'] ?? auth.user?['owner_district_name'];
         final city = auth.user?['city_name'] ?? auth.user?['owner_city_name'];
         final address = auth.user?['address'] ?? auth.user?['address_detail'];
         
         if (district != null) {
           WidgetsBinding.instance.addPostFrameCallback((_) {
             setState(() {
               _selectedDistrict = district.toString();
               _selectedCity = city?.toString() ?? '';
               _pickupAddress = address?.toString() ?? "$district, ${city ?? ''}";
             });
             // LANGSUNG TEMBAK MITRA BEGITU DISTRICT KETEMU
             _loadLiveMitras();
           });
         }
      }

      final Map<String, dynamic> t = {
      'id': {
        'title_pickup': 'Penjemputan Kurir',
        'title_drop': 'Antar ke Laundry',
        'loc_pickup': 'Lokasi Penjemputan',
        'loc_drop': 'Lokasi Laundry',
        'opt_home': 'Rumah Saya',
        'opt_gps': 'Lokasi Saat Ini (GPS)',
        'opt_gps_desc': 'Gunakan posisi GPS perangkat Anda',
        'opt_map': 'Pilih via Peta',
        'opt_map_desc': 'Geser pin ke lokasi yang tepat',
        'recom_mitra': 'Mitra Laundry Rekomendasi',
        'items_title': 'Pilih Item Cucian',
        'speed_reg': 'Reguler',
        'speed_reg_desc': '2-3 Hari Kerja',
        'speed_fast': 'Fast Track',
        'speed_fast_desc': 'Selesai di hari yang sama',
        'speed_label': 'Kecepatan Layanan',
        'total': 'Total Estimasi',
        'btn_confirm': 'KONFIRMASI',
      },
      'en': {
        'title_pickup': 'Courier Pickup',
        'title_drop': 'Drop to Laundry',
        'loc_pickup': 'Pickup Location',
        'loc_drop': 'Laundry Location',
        'opt_home': 'My Home',
        'opt_gps': 'Current Location (GPS)',
        'opt_gps_desc': 'Use your device\'s GPS position',
        'opt_map': 'Pick on Map',
        'opt_map_desc': 'Manually drag the pin to location',
        'recom_mitra': 'Recommended Laundry Mitra',
        'items_title': 'Select Laundry Items',
        'speed_reg': 'Regular',
        'speed_reg_desc': '2-3 Working Days',
        'speed_fast': 'Fast Track',
        'speed_fast_desc': 'Same Day Service',
        'speed_label': 'Service Speed',
        'total': 'Total Estimation',
        'btn_confirm': 'CONFIRM',
      }
    };
    
    final cT = t['id']; // Default to Indonesian

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
          _buildCompactAppbar(cT),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // JIKA DROP: Rekomendasi Paling Atas + Opsi Pengembalian
                  if (widget.orderType == 'drop') ...[
                    _buildEliteDropHeader(cT),
                    const SizedBox(height: 24),
                  ] else ...[
                    // JIKA PICKUP: Alamat Penjemputan di Atas
                    _buildAddressSection(cT, auth),
                    const SizedBox(height: 24),
                    Text(cT['recom_mitra'], style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black87)),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: _isLoadingMitras 
              ? SizedBox(
                  height: 170,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(left: 20, right: 4),
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (context, index) => Container(
                      width: 180,
                      margin: const EdgeInsets.only(right: 16, bottom: 10, top: 4),
                      child: const ShimmerLoading(height: 170, borderRadius: 22),
                    ),
                  ),
                )
              : _mitras.isEmpty 
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(LucideIcons.ghost, size: 40, color: Colors.grey[200]),
                          const SizedBox(height: 12),
                          Text("Belum ada Mitra APPROVED di radar.", 
                            style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[400], fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("Pastikan status Mitra sudah 'APPROVED' di Dashboard Admin", 
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[400])),
                        ],
                      ),
                    ),
                  )
                : SizedBox(
                    height: 170,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(left: 20, right: 4),
                      scrollDirection: Axis.horizontal,
                      itemCount: _mitras.length,
                      itemBuilder: (context, index) => _buildHorizontalMitraCard(_mitras[index]),
                    ),
                  ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cT['speed_label'], style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black87)),
                  const SizedBox(height: 12),
                  _buildDenseSpeedSelector(cT),
                  const SizedBox(height: 24),
                  _buildDenseItemList(cT),
                  const SizedBox(height: 24),
                  

                  const SizedBox(height: 100), // Ruang agar tidak tertutup footer
                ],
              ),
            ),
          )
        ],
      ),
      if (_isConnectionError)
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.6),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Icon(LucideIcons.wifiOff, size: 48, color: primaryRed),
                        const SizedBox(height: 16),
                        Text("Koneksi Bermasalah", style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text("Paket data atau internet Anda\nsedang tidak stabil.", textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => _loadLiveMitras(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryTeal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)
                          ),
                          child: Text("Coba Lagi", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.white)),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
      ),
      bottomSheet: _buildCompactFooter(cT, auth),
    );
    } catch (e) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text("Maaf, terjadi kesalahan tampilan. Sedang memulihkan... \n\nDetail: $e", 
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 12, color: Colors.red),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildCompactAppbar(Map<String, dynamic> cT) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: primaryTeal,
      elevation: 0,
      leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: Colors.white), onPressed: () => Navigator.pop(context)),
      title: Text(widget.orderType == 'pickup' ? cT['title_pickup'] : cT['title_drop'], style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      centerTitle: true,
    );
  }

  Widget _buildAddressSection(Map<String, dynamic> cT, AuthProvider auth) {
    // HANYA UNTUK PICKUP — Mode Drop ditangani oleh _buildEliteDropHeader
    if (widget.orderType == 'drop') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_locationIcon, size: 16, color: primaryTeal),
              const SizedBox(width: 8),
              Text(cT['loc_pickup'], style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.bold)),
              const Spacer(),
              _pillButton("Ubah", () => _showPickupPicker(title: "Pilih Lokasi Penjemputan")),
            ],
          ),
          const SizedBox(height: 12),
          Text(_getSmartAddress(_pickupAddress), style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (_pickupNote.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_pickupNote, style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const Divider(height: 24),
          Row(
            children: [
              const Icon(LucideIcons.messageSquare, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: Text(_pickupNote.isEmpty ? "Tambahkan catatan penjemputan" : _pickupNote, style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[400]), maxLines: 1, overflow: TextOverflow.ellipsis)),
              _pillButton("Tambahan Info", () => _showNoteDialog()),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildEliteDropHeader(Map<String, dynamic> cT) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. SETELAH SELESAI (Sekarang di paling atas)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Setelah Selesai, Cucian:", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _returnOption("Diambil Sendiri", "self", LucideIcons.user, _returnMethod == 'self')),
                  const SizedBox(width: 12),
                  Expanded(child: _returnOption("Diantar Kurir", "courier", LucideIcons.truck, _returnMethod == 'courier')),
                ],
              ),
              
              // 2. EXPAND LOKASI PENGIRIMAN (Hanya jika Diantar Kurir)
              if (_returnMethod == 'courier') ...[
                const Divider(height: 32),
                Row(
                  children: [
                    Icon(LucideIcons.mapPin, size: 16, color: primaryRed),
                    const SizedBox(width: 8),
                    Text("Lokasi Pengiriman", style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.bold)),
                    const Spacer(),
                    _pillButton("Ubah", () => _showPickupPicker(title: "Pilih Lokasi Pengiriman")),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_getSmartAddress(_pickupAddress), style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
              ] else ...[
                const SizedBox(height: 16),
              ],
              
              // Tampilkan selalu form Catatan Pelanggan
              Row(
                children: [
                  const Icon(LucideIcons.messageSquare, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_pickupNote.isEmpty ? "Tambahan info untuk Mitra" : _pickupNote, style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[400]))),
                  _pillButton("Tambahan Info", () => _showNoteDialog()),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 3. REKOMENDASI MITRA (Sekarang di bawah)
        Text(cT['recom_mitra'], style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black87)),
      ],
    );
  }

  Widget _returnOption(String label, String value, IconData icon, bool isSel) {
    return GestureDetector(
      onTap: () {
        if (_returnMethod == value) return; // Tidak ada perubahan, skip
        setState(() => _returnMethod = value);
        // Filter Mitra berdasarkan kota: aktif untuk semua pilihan di mode drop
        _loadLiveMitras();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? primaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSel ? primaryTeal : Colors.grey[200]!)
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

  Widget _pillButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTeal)),
      ),
    );
  }

  Widget _buildHorizontalMitraCard(Map<String, dynamic> mitra) {
    bool isSelected = _selectedMitra?['id'] == mitra['id'];
    return GestureDetector(
      onTap: () {
        // 1. INSTANT FEEDBACK: Centang & Selection langsung aktif tanpa delay
        setState(() {
          _selectedMitra = mitra;
          _itemCounts.clear();
          _categoryPages.clear();
        });

        // 2. BACKGROUND FETCH: Ambil harga di belakang layar (tanpa await)
        if (mitra['items'] == null || (mitra['items'] as List).isEmpty) {
          _fetchMitraItems(mitra['id']);
        }
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16, bottom: 10, top: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          // BORDER HIJAU NYUTJI saat terpilih
          border: isSelected ? Border.all(color: primaryTeal, width: 2) : Border.all(color: Colors.transparent, width: 2),
          boxShadow: [
            BoxShadow(
              color: isSelected ? primaryTeal.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.08),
              blurRadius: 12, offset: const Offset(0, 6)
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: Builder(
                  builder: (context) {
                    final imgValue = mitra['image']?.toString();
                    
                    // Jika data kosong, "null", atau mengandung "unsplash" (data dummy), tampilkan placeholder
                    bool isDummy = imgValue?.contains("unsplash.com") ?? false;

                    if (imgValue != null && imgValue.isNotEmpty && imgValue != "null" && !isDummy) {
                      final fullUrl = imgValue.startsWith('http') 
                          ? imgValue 
                          : '${ApiConstants.rootUrl}/$imgValue';
                      return CachedNetworkImage(
                        imageUrl: fullUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => _buildPlaceholderImage(),
                      );
                    } else {
                      return _buildPlaceholderImage();
                    }
                  }
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      // GRADASI SUPER MEWAH: Transisi sangat halus dari Kanan (Gelap) ke Kiri (Clear)
                      colors: [
                        Colors.black.withValues(alpha: 0.85), 
                        Colors.black.withValues(alpha: 0.5),
                        Colors.black.withValues(alpha: 0.1),
                        Colors.transparent
                      ],
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      stops: const [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      mitra['name'] ?? 'Mitra Laundry',
                      style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.2),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(LucideIcons.mapPin, size: 10, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(NyutjiDistance.formatDistance(mitra['distance'] ?? 0.1), 
                          style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              // RATING: POJOK KIRI ATAS (Desain Mewah Request Boss)
              Positioned(
                top: 12, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)]
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("${mitra['rating'] ?? '5.0'}", style: GoogleFonts.montserrat(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900)),
                      const SizedBox(width: 4),
                      const Icon(LucideIcons.star, size: 12, color: Colors.red),
                    ],
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  bottom: 12, left: 12, // Pindah ke kiri bawah agar tidak tabrakan dengan rating
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(LucideIcons.check, size: 12, color: primaryTeal),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: const Color(0xFFD1D5DB), // Abu-abu yang sedikit lebih tegas
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Text(
          "Profile Mitra Laundry",
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Colors.white, // Putih agar kontras dengan gradasi hitam
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  void _showNoteDialog() {
    final TextEditingController noteCtrl = TextEditingController(text: _pickupNote);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Keterangan Tambahan", style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF131109))),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Contoh: Baju Putih, Hati-hati kelunturan",
                hintStyle: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("Batal", style: GoogleFonts.montserrat(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF403600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    setState(() => _pickupNote = noteCtrl.text);
                    Navigator.pop(ctx);
                  },
                  child: Text("Simpan", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
      // SINKRONISASI ULANG MITRA BERDASARKAN KECAMATAN BARU
      _loadLiveMitras();
      // JIKA KECAMATAN SAMA, TETAP HITUNG ULANG JARAK BERDASARKAN LAT/LNG BARU
      _recalculateDistances();
    }
  }



  Widget _buildDenseSpeedSelector(Map<String, dynamic> cT) {
    return Row(
      children: [
        Expanded(child: _speedPill(cT['speed_reg'], cT['speed_reg_desc'], 'regular', const Color(0xFF403600), LucideIcons.clock)),
        const SizedBox(width: 12),
        Expanded(child: _speedPill(cT['speed_fast'], cT['speed_fast_desc'], 'fast', const Color(0xFF403600), LucideIcons.zap)),
      ],
    );
  }

  Widget _speedPill(String title, String desc, String id, Color activeC, IconData icon) {
    bool isSel = _serviceSpeed == id;
    return GestureDetector(
      onTap: () => setState(() => _serviceSpeed = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFEFECE5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSel ? const Color(0xFFDAC66F) : const Color(0xFFE3DCCF), width: 1.5),
          boxShadow: isSel ? [] : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isSel ? activeC : Colors.grey[400]),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: isSel ? activeC : Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(desc, style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w600, color: isSel ? activeC.withValues(alpha: 0.6) : Colors.grey[400]), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDenseItemList(Map<String, dynamic> cT) {
    if (_selectedMitra == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Center(
          child: Column(
            children: [
              Icon(LucideIcons.store, size: 40, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text("Silakan Pilih Mitra Laundry Terlebih Dahulu", style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    final allItems = (_selectedMitra?['items'] as List<dynamic>?) ?? [];
    final bool isLoaded = _selectedMitra?['items_loaded'] == true;

    if (allItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            if (!isLoaded) ...[
              const ShimmerLoading(height: 14, width: 150, borderRadius: 4),
              const SizedBox(height: 8),
              const ShimmerLoading(height: 14, width: 100, borderRadius: 4),
            ] else ...[
              Icon(LucideIcons.fileX, size: 30, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text("Daftar Harga Masih Kosong", style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.bold)),
            ]
          ],
        ),
      );
    }

    // Group items dynamically by category
    final Map<String, List<dynamic>> groupedItems = {};
    for (var item in allItems) {
      String category = item['category'] ?? 'Kiloan';
      if (!groupedItems.containsKey(category)) {
        groupedItems[category] = [];
      }
      groupedItems[category]!.add(item);
    }

    List<Widget> children = [];
    groupedItems.forEach((category, items) {
      bool isKiloan = category.toLowerCase().contains("kiloan");
      
      Widget? actionWidget;
      if (isKiloan) {
        actionWidget = GestureDetector(
          onTap: _showImageSourceSheet,
          child: Text(
            "Unggah Foto", 
            style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF403600), decoration: TextDecoration.underline, decorationColor: const Color(0xFF403600)),
          ),
        );
      }

      final Widget catCard = _buildCategoryCardWithVerticalItems(
        items, 
        category, 
        isKiloan ? LucideIcons.layers : LucideIcons.shirt, 
        isKiloan, 
        actionWidget: actionWidget,
      );

      if (catCard is! SizedBox) {
        children.add(catCard);
      }
    });

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildCategoryCardWithVerticalItems(
    List<dynamic> items, 
    String title, 
    IconData icon, 
    bool isKiloan, 
    {Widget? actionWidget}
  ) {
    // 4. buat smart dinamis daftar harga, ketika harga Rp 0, tidak usah ditampilkan
    final validItems = items.where((item) {
      final double priceReg = double.tryParse(item['price_regular']?.toString() ?? item['price']?.toString() ?? '0') ?? 0;
      return priceReg > 0;
    }).toList();

    if (validItems.isEmpty) return const SizedBox.shrink();

    return Container(
      width: 320, // fixed width agar proporsional sejajar kiri-kanan
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Category
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: primaryTeal),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title, 
                    style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (actionWidget != null) actionWidget,
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          // Vertical List of Items inside this category card!
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: validItems.map((item) {
                return _buildVerticalItemRow(item as Map<String, dynamic>, isKiloan);
              }).toList(),
            ),
          ),
          
          // Image preview untuk Kiloan
          if (isKiloan && _orderImage != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(_orderImage!, height: 120, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text("Estimasi Berat 5Kg", style: GoogleFonts.montserrat(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _orderImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.x, color: Colors.white, size: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerticalItemRow(Map<String, dynamic> item, bool isKiloan) {
    final double priceReg = double.tryParse(item['price_regular']?.toString() ?? item['price']?.toString() ?? '0') ?? 0;
    final double? pFastRaw = double.tryParse(item['price_fast']?.toString() ?? '');
    final double priceFast = (pFastRaw == null || pFastRaw == 0) ? priceReg : pFastRaw;
    String itemId = item['id']?.toString() ?? '0';
    int count = _itemCounts[itemId] ?? 0;
    String unit = isKiloan ? 'Kg' : 'Pcs';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row for Name & Badge count
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item['name'] ?? '',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: count > 0 ? primaryTeal.withValues(alpha: 0.1) : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$count $unit",
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: count > 0 ? primaryTeal : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Price Info
          if (isKiloan) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Reguler:",
                  style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                Text(
                  "Rp ${NumberFormat.decimalPattern('id_ID').format(priceReg)} /Kg",
                  style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTeal),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Fast Track:",
                  style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                Text(
                  "Rp ${NumberFormat.decimalPattern('id_ID').format(priceFast)} /Kg",
                  style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFD97706)),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Harga:",
                  style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                Text(
                  "Rp ${NumberFormat.decimalPattern('id_ID').format(priceReg)} /Pcs",
                  style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTeal),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          // Slider Counter Hybrid
          _buildHybridCounter(
            itemId: itemId,
            count: count,
            onIncrement: () => _updateItemCount(itemId, 1),
            onDecrement: () => _updateItemCount(itemId, -1),
            onSliderChanged: (val) => _setItemCount(itemId, val.toInt()),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
        ],
      ),
    );
  }

  Widget _buildHybridCounter({
    required String itemId,
    required int count,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required ValueChanged<double> onSliderChanged,
  }) {
    return Row(
      children: [
        GestureDetector(
          onTap: onDecrement,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.minus, size: 14, color: Colors.black54),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4.0,
              activeTrackColor: primaryTeal,
              inactiveTrackColor: const Color(0xFFF3F4F6),
              thumbColor: primaryTeal,
              overlayColor: primaryTeal.withValues(alpha: 0.12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
            ),
            child: Slider(
              value: count.toDouble(),
              min: 0,
              max: 20,
              divisions: 20,
              onChanged: onSliderChanged,
            ),
          ),
        ),
        GestureDetector(
          onTap: onIncrement,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.plus, size: 14, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactFooter(Map<String, dynamic> cT, AuthProvider auth) {
    // SMART DYNAMIC PADDING: Deteksi tinggi navigasi sistem Android secara otomatis
    final double systemBottomPadding = MediaQuery.of(context).padding.bottom;
    final double finalBottomPadding = systemBottomPadding > 0 ? systemBottomPadding + 12 : 24;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, finalBottomPadding),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9ED), 
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]
      ),
      child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cT['total'], style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_totalPrice), style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: primaryTeal)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_totalItems > 0 && _selectedMitra != null) {
                  final String addr = _pickupAddress;
                  final String note = _pickupNote;
                  final double lat = _selectedLat ?? 0.0;
                  final double lng = _selectedLng ?? 0.0;

                  auth.addToAddressHistory({'address': addr, 'detail': note, 'lat': lat, 'lng': lng});
                  
                  // 1. Ambil data Mitra tersegar dari list (untuk dapet items terbaru)
                  final currentMitra = _mitras.firstWhere(
                    (m) => m['id'].toString() == (_selectedMitra?['id']?.toString() ?? ''),
                    orElse: () => _selectedMitra ?? {},
                  );

                  List<Map<String, dynamic>> selectedItems = [];
                  final List? mItems = currentMitra['items'] as List?;
                  
                  if (mItems != null && mItems.isNotEmpty) {
                    _itemCounts.forEach((itemId, count) {
                      if (count > 0) {
                        try {
                          // FORCE STRING COMPARISON: Pastikan ID cocok walau beda tipe (int vs string)
                          var item = mItems.firstWhere(
                            (i) => i['id'].toString() == itemId.toString(), 
                            orElse: () => null
                          );
                          if (item != null) {
                            bool isFast = _serviceSpeed == 'fast';
                            double pReg = double.tryParse(item['price_regular']?.toString() ?? item['price']?.toString() ?? '0') ?? 0;
                            double? pFastRaw = double.tryParse(item['price_fast']?.toString() ?? '');
                            double pFast = (pFastRaw == null || pFastRaw == 0) ? pReg : pFastRaw;

                            String cat = (item['category'] ?? '').toString().toLowerCase();
                            String unitDisplay = cat.contains('kilo') ? 'Kg' : 'Pcs';
                            
                            selectedItems.add({
                              'name': item['name'] ?? item['item_name'] ?? 'Item', 
                              'count': count, 
                              'unit': unitDisplay,
                              'price': isFast ? pFast : pReg,
                              'category': item['category'] ?? 'Umum',
                            });
                          }
                        } catch (e) {
                          debugPrint("Nyutji Error Mapping: $e");
                        }
                      }
                    });
                  }

                  // Ambil district & city: prioritas dari location picker, fallback dari auth profile
                  final String districtName = _selectedDistrict.isNotEmpty
                      ? _selectedDistrict
                      : (auth.user?['district_name']?.toString() ?? '');
                  
                  // Cari District Code dari ID Mitra (ML-PMU-001 -> PMU)
                  String districtCode = 'NYJ'; 
                  if (_selectedMitra != null && _selectedMitra!['id'] != null) {
                    final mId = _selectedMitra!['id'].toString();
                    final parts = mId.split('-');
                    if (parts.length >= 2) {
                      districtCode = parts[1].toUpperCase();
                    }
                  }

                  final String cityName = _selectedCity.isNotEmpty
                      ? _selectedCity
                      : (auth.user?['city_name']?.toString() ?? '');

                  // VALIDASI: Kecamatan wajib ada sebelum lanjut ke pembayaran
                  if (districtName.isEmpty) {
                    NyutjiNotif.showError(context, 'Pilih Lokasi Penjemputan terlebih dahulu agar Kecamatan terisi.');
                    return;
                  }


                  Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerPaymentScreen(
                    totalPrice: _totalPrice, 
                    totalItems: _totalItems, 
                    address: addr, 
                    isPickup: widget.orderType == 'pickup',
                    mitraId: _selectedMitra!['id'],
                    mitraName: _selectedMitra!['name'],
                    orderType: widget.orderType,
                    speed: _serviceSpeed,
                    distance: (_selectedMitra?['distance'] as num?)?.toDouble() ?? 0.1,
                    dropMethod: _returnMethod,
                    selectedItemsList: selectedItems,
                    districtName: districtName,
                    districtCode: districtCode,
                    cityName: cityName,
                    lat: _selectedLat ?? double.tryParse(auth.user?['lat']?.toString() ?? '') ?? 0.0,
                    lng: _selectedLng ?? double.tryParse(auth.user?['lng']?.toString() ?? '') ?? 0.0,
                    mitraLat: NyutjiParser.toDouble(_selectedMitra?['lat']),
                    mitraLng: NyutjiParser.toDouble(_selectedMitra?['lng']),
                    pickupNote: note,
                    mitraAddress: _selectedMitra?['address']?.toString() ?? '',
                    mitraDistrict: _selectedMitra?['district']?.toString() ?? '',
                  )));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
              child: Text(cT['btn_confirm'], style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ],
        ),
    );
  }
}
