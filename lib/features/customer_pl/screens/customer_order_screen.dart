import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/nyutji_parser.dart';
import '../../../core/widgets/nyutji_pickup_picker.dart';
import '../../../providers/auth_provider.dart';
import 'customer_payment_screen.dart';
import '../../../data/services/api_service.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../core/utils/nyutji_distance.dart';

class CustomerOrderScreen extends StatefulWidget {
  final String orderType;

  const CustomerOrderScreen({
    super.key,
    this.orderType = 'pickup',
  });

  @override
  State<CustomerOrderScreen> createState() => _CustomerOrderScreenState();
}

class _CustomerOrderScreenState extends State<CustomerOrderScreen> {
  String _pickupAddress = 'Jl. Kebayoran No 12, Jakarta';
  String _pickupNote = '';
  String _serviceSpeed = 'regular';
  String _returnMethod = 'self'; // 'self' atau 'courier'
  
  // STATE UNTUK PESANAN (Item ID/Identifier -> Count)
  final Map<dynamic, int> _itemCounts = {};
  
  // STATE UNTUK MAPS & LOKASI
  double? _selectedLat;
  double? _selectedLng;
  String _selectedDistrict = '';
  String _selectedCity = '';
  
  // STATE MITRA & ITEMS (LIVE DATABASE)
  Map<String, dynamic>? _selectedMitra;
  List<Map<String, dynamic>> _mitras = [];
  bool _isLoadingMitras = true;

  int _kiloanPage = 0;
  int _satuanPage = 0;

  @override
  void initState() {
    super.initState();
    _loadLiveMitras();
  }

  Future<void> _loadLiveMitras({String? forcedDistrict}) async {
    setState(() => _isLoadingMitras = true);
    try {
      final api = ApiService();
      final targetDistrict = forcedDistrict ?? _selectedDistrict;
      
      // 1. Ambil data dari server (MODE PROFESSIONAL: Dengan Filter Kecamatan)
      final data = await api.getRecommendedMitras(districtName: targetDistrict); 
      
      final List<dynamic> rawData = data;
      
      // 2. Mapping baris per baris dengan proteksi null
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
        };
      }).toList();

      _mitras = mapped;
      _recalculateDistances(); // HITUNG JARAK SETELAH LOAD

      // 3. Update State
      if (mounted) {
        setState(() {
          _isLoadingMitras = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMitras = false);
        NyutjiNotif.showError(context, "Gagal memuat Mitra: $e");
      }
      debugPrint("Nyutji Error: $e");
    } finally {
      if (mounted) {
        for (var m in _mitras) {
          _fetchMitraItems(m['id']);
        }
      }
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

  void _showSearchMitra() {
    final TextEditingController searchCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Cari Nama Mitra Laundry", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: searchCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Masukkan nama ML...",
            hintStyle: GoogleFonts.montserrat(fontSize: 12),
            prefixIcon: const Icon(LucideIcons.search, size: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (val) => _performSearch(val),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => _performSearch(searchCtrl.text),
            child: const Text("CARI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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

  void _performSearch(String query) {
    if (query.isEmpty) return;
    Navigator.pop(context);
    
    // SMART SEARCH: Cari berdasarkan Nama ATAU Kecamatan
    final found = _mitras.indexWhere((m) {
      final nameMatch = m['name'].toString().toLowerCase().contains(query.toLowerCase());
      final districtMatch = m['district'].toString().toLowerCase().contains(query.toLowerCase());
      return nameMatch || districtMatch;
    });

    if (found != -1) {
      setState(() {
        _selectedMitra = _mitras[found];
        _itemCounts.clear();
      });
      if (mounted) NyutjiNotif.showSuccess(context, "Mitra '${_mitras[found]['name']}' dipilih!");
    } else {
      // Jika tidak ketemu di list lokal, coba panggil API untuk kecamatan tersebut secara paksa
      _loadLiveMitras(forcedDistrict: query);
    }
  }

  Future<void> _fetchMitraItems(dynamic mitraId) async {
    try {
      final api = ApiService();
      // Set timeout manual untuk simulasi kilat
      final items = await api.getMitraItems(mitraId).timeout(const Duration(seconds: 3)); 
      
      if (mounted) {
        setState(() {
          int idx = _mitras.indexWhere((m) => m['id'] == mitraId);
          if (idx != -1) {
            // JANGAN PAKAI DUMMY! Jika kosong, biarkan kosong agar user tahu Mitra belum set harga.
            _mitras[idx]['items'] = items;
            if (_selectedMitra != null && _selectedMitra!['id'] == mitraId) {
              _selectedMitra!['items'] = items;
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching items for mitra $mitraId: $e");
    }
  }


  // STATE SOURCE LOKASI UNTUK ICON
  IconData _locationIcon = LucideIcons.mapPin;

  final Color primaryTeal = const Color(0xFF1E5655);
  final Color bgColor = const Color(0xFFF3F4F6);

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

  @override
  Widget build(BuildContext context) {
    // Gunakan try-catch di level tertinggi build untuk menangkap error gaib di mode Release
    try {
      final auth = Provider.of<AuthProvider>(context);
      
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
      body: CustomScrollView(
        slivers: [
          _buildCompactAppbar(cT),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAddressSection(cT, auth),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(cT['recom_mitra'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black87)),
                      GestureDetector(
                        onTap: () => _showSearchMitra(),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: Icon(LucideIcons.search, size: 16, color: primaryTeal),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: _isLoadingMitras 
              ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              : _mitras.isEmpty 
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(LucideIcons.ghost, size: 40, color: Colors.grey[200]),
                          const SizedBox(height: 12),
                          Text("Belum ada Mitra APPROVED di radar.", 
                            style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("Pastikan status Mitra sudah 'APPROVED' di Dashboard Admin", 
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[400])),
                        ],
                      ),
                    ),
                  )
                : SizedBox(
                    height: 170,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  Text(cT['speed_label'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black87)),
                  const SizedBox(height: 12),
                  _buildDenseSpeedSelector(cT),
                  const SizedBox(height: 24),
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
      leading: IconButton(icon: const Icon(LucideIcons.chevronLeft, color: Colors.white), onPressed: () => Navigator.pop(context)),
      title: Text(widget.orderType == 'pickup' ? cT['title_pickup'] : cT['title_drop'], style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      centerTitle: true,
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(icon: const Icon(LucideIcons.shoppingBag, color: Colors.white, size: 20), onPressed: () {}),
            Positioned(
              right: 8, top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                child: Text('$_totalItems', style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
            )
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAddressSection(Map<String, dynamic> cT, AuthProvider auth) {
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
              Text(widget.orderType == 'pickup' ? cT['loc_pickup'] : cT['loc_drop'], style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
              const Spacer(),
              _pillButton("Ubah", () => _showPickupPicker()),
            ],
          ),
          const SizedBox(height: 12),
          Text(_getSmartAddress(_pickupAddress), style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (_pickupNote.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_pickupNote, style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[600])),
          ],
          const Divider(height: 24),
          Row(
            children: [
              const Icon(LucideIcons.messageSquare, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: Text(_pickupNote.isEmpty ? "Tambahkan catatan penjemputan" : _pickupNote, style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[400]))),
              _pillButton("Catat", () => _showNoteDialog()),
            ],
          ),
          
          // LOGIKA ANTAR SENDIRI: Pilihan Pengembalian (Hanya jika orderType == drop)
          if (widget.orderType == 'drop') ...[
            const Divider(height: 32),
            Text("Setelah Selesai, Cucian:", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _returnOption(
                    "Diambil Sendiri", 
                    "self", 
                    LucideIcons.user,
                    _returnMethod == 'self'
                  )
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _returnOption(
                    "Diantar Kurir", 
                    "courier", 
                    LucideIcons.truck,
                    _returnMethod == 'courier'
                  )
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _returnOption(String label, String value, IconData icon, bool isSel) {
    return GestureDetector(
      onTap: () => setState(() => _returnMethod = value),
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
            Text(label, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: isSel ? Colors.white : Colors.grey[600])),
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
        child: Text(label, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: primaryTeal)),
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
          _kiloanPage = 0;
          _satuanPage = 0;
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
                          
                      return Image.network(
                        fullUrl, // Hapus timestamp agar tidak flicker/loading ulang saat setState
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
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
                          style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
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
                      Text("${mitra['rating'] ?? '5.0'}", style: GoogleFonts.montserrat(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900)),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Keterangan Tambahan", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: noteCtrl,
          decoration: const InputDecoration(
            hintText: "Contoh: No 12, Gang Mawar, Samping Alfamart",
            hintStyle: TextStyle(fontSize: 12),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
            onPressed: () {
              setState(() => _pickupNote = noteCtrl.text);
              Navigator.pop(context);
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPickupPicker() async {
    final result = await showModalBottomSheet<NyutjiPickupResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NyutjiPickupPicker(),
    );

    if (result != null && mounted) {
      setState(() {
        _pickupAddress = result.address;
        _pickupNote = result.note;
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        children: [
          Expanded(child: _speedPill(cT['speed_reg'], cT['speed_reg_desc'], 'regular', primaryTeal)),
          Expanded(child: _speedPill(cT['speed_fast'], cT['speed_fast_desc'], 'fast', Colors.red)),
        ],
      ),
    );
  }

  Widget _speedPill(String title, String desc, String id, Color activeC) {
    bool isSel = _serviceSpeed == id;
    return GestureDetector(
      onTap: () => setState(() => _serviceSpeed = id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: isSel ? activeC.withValues(alpha: 0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(title, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? activeC : Colors.grey[400])),
            Text(desc, style: GoogleFonts.montserrat(fontSize: 9, color: isSel ? activeC.withValues(alpha: 0.8) : Colors.grey[400])),
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
              Text("Silakan Pilih Mitra Laundry Terlebih Dahulu", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    final allItems = (_selectedMitra?['items'] as List<dynamic>?) ?? [];
    if (allItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryTeal.withValues(alpha: 0.5))),
            const SizedBox(height: 16),
            Text("Sedang mengambil daftar harga...", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey)),
          ],
        ),
      );
    }

    // Pisahkan Kiloan dan Satuan
    final kiloanItems = allItems.where((i) => i['category'] == 'Kiloan' || i['category'] == null).toList();
    final satuanItems = allItems.where((i) => i['category'] == 'Satuan').toList();

    return Column(
      children: [
        if (kiloanItems.isNotEmpty) _buildPaginatedTable(kiloanItems, "Laundry Kiloan", LucideIcons.layers, true, _kiloanPage, (idx) => setState(() => _kiloanPage = idx)),
        const SizedBox(height: 24),
        if (satuanItems.isNotEmpty) _buildPaginatedTable(satuanItems, "Laundry Satuan / Meteran", LucideIcons.shirt, false, _satuanPage, (idx) => setState(() => _satuanPage = idx)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPaginatedTable(List<dynamic> items, String title, IconData icon, bool isKiloan, int currentPage, Function(int) onPageChanged) {
    const int perPage = 5;
    List<List<dynamic>> chunks = [];
    for (var i = 0; i < items.length; i += perPage) {
      chunks.add(items.sublist(i, i + perPage > items.length ? items.length : i + perPage));
    }
    final pageItems = chunks.isNotEmpty ? chunks[currentPage.clamp(0, chunks.length - 1)] : [];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < 0 && currentPage < chunks.length - 1) {
          onPageChanged(currentPage + 1);
        } else if (details.primaryVelocity! > 0 && currentPage > 0) {
          onPageChanged(currentPage - 1);
        }
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20)]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: primaryTeal),
                    const SizedBox(width: 12),
                    Text(title, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    if (chunks.length > 1)
                      Text("Slide untuk lainnya", style: GoogleFonts.montserrat(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: const Color(0xFFF9FAFB),
                child: Row(
                  children: isKiloan ? [
                    Expanded(flex: 3, child: Text("SERVICE", style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey[500]))),
                    Expanded(flex: 4, child: Center(child: Text("REGULAR / FAST", style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey[500])))),
                  ] : [
                    Expanded(flex: 3, child: Text("NAMA BARANG", style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey[500]))),
                    Expanded(flex: 2, child: Center(child: Text("HARGA", style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey[500])))),
                  ],
                ),
              ),
              // ANIMATEDSIZE + ANIMATEDSWITCHER: identik dengan ML Pricing Screen
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.15, 0), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                child: Column(
                  key: ValueKey(currentPage),
                  mainAxisSize: MainAxisSize.min,
                  children: pageItems.map((item) => isKiloan ? _buildKiloanRow(item as Map<String, dynamic>) : _buildSatuanRow(item as Map<String, dynamic>)).toList(),
                ),
              ),
              // INDIKATOR TITIK
              if (chunks.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(chunks.length, (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 6, height: 6,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: currentPage == index ? primaryTeal : primaryTeal.withValues(alpha: 0.3)),
                    )),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildKiloanRow(Map<String, dynamic> item) {
    final double priceReg = double.tryParse(item['price_regular']?.toString() ?? item['price']?.toString() ?? '0') ?? 0;
    final double? pFastRaw = double.tryParse(item['price_fast']?.toString() ?? '');
    final double priceFast = (pFastRaw == null || pFastRaw == 0) ? priceReg : pFastRaw;
    String itemId = item['id']?.toString() ?? '0';
    int count = _itemCounts[itemId] ?? 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
      child: Row(
        children: [
          Expanded(
            flex: 3, 
            child: Text(item['name'], style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87))
          ),
          Expanded(
            flex: 5, // Perbesar flex agar muat harga jutaan + counter
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible( // Gunakan Flexible agar teks harga tidak memaksakan ruang jika terlalu panjang
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Rp ${NumberFormat.decimalPattern('id_ID').format(priceReg)} /Kg", style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: primaryTeal)),
                      Text("Rp ${NumberFormat.decimalPattern('id_ID').format(priceFast)} /Kg", style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFFD97706))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // TOMBOL COUNTING
                Container(
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ctrBtn(LucideIcons.minus, () => _updateItemCount(itemId, -1)),
                      SizedBox(width: 22, child: Center(child: Text("$count", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: primaryTeal)))),
                      _ctrBtn(LucideIcons.plus, () => _updateItemCount(itemId, 1)),
                    ],
                  ),
                )
              ],
            )
          ),
        ],
      ),
    );
  }

  Widget _buildSatuanRow(Map<String, dynamic> item) {
    final double price = double.tryParse(item['price_regular']?.toString() ?? item['price']?.toString() ?? '0') ?? 0;
    String itemId = item['id']?.toString() ?? '0';
    int count = _itemCounts[itemId] ?? 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
      child: Row(
        children: [
          Expanded(
            flex: 3, 
            child: Text(item['name'], style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87))
          ),
          Expanded(
            flex: 4, 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text("Rp ${NumberFormat.decimalPattern('id_ID').format(price)} /Pcs", 
                    style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: primaryTeal),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // TOMBOL COUNTING
                Container(
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ctrBtn(LucideIcons.minus, () => _updateItemCount(itemId, -1)),
                      SizedBox(width: 22, child: Center(child: Text("$count", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: primaryTeal)))),
                      _ctrBtn(LucideIcons.plus, () => _updateItemCount(itemId, 1)),
                    ],
                  ),
                )
              ],
            )
          ),
        ],
      ),
    );
  }

  Widget _ctrBtn(IconData icon, VoidCallback onTap) {
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 14, color: Colors.black54)));
  }

  Widget _buildCompactFooter(Map<String, dynamic> cT, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(cT['total'], style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500)),
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
                          String unitDisplay = (cat == 'satuan' || cat == 'iron' || cat == 'dry clean') ? 'Pcs' : 'Kg';
                          
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
                
                // Cari District Code dari list districts (PMU, CIP, dll)
                String districtCode = 'NYJ'; 
                if (districtName.isNotEmpty) {
                  try {
                    final dData = _districts.firstWhere(
                      (d) => d['name'].toString().toLowerCase() == districtName.toLowerCase(),
                      orElse: () => {},
                    );
                    if (dData.isNotEmpty && dData['code'] != null) {
                      districtCode = dData['code'].toString().toUpperCase();
                    } else if (auth.user?['identifier'] != null) {
                      // Fallback: Ambil dari identifier PL (PL-PMU-001 -> PMU)
                      final parts = auth.user!['identifier'].toString().split('-');
                      if (parts.length >= 2) districtCode = parts[1];
                    }
                  } catch (e) {
                    debugPrint("Gagal dapet kode kecamatan: $e");
                  }
                }

                final String cityName = _selectedCity.isNotEmpty
                    ? _selectedCity
                    : (auth.user?['city_name']?.toString() ?? '');

                // VALIDASI: Kecamatan wajib ada sebelum lanjut ke pembayaran
                if (districtName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Pilih Lokasi Penjemputan terlebih dahulu agar Kecamatan terisi.'),
                      backgroundColor: Colors.red[700],
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerPaymentScreen(
                  totalPrice: _totalPrice, 
                  totalItems: _totalItems, 
                  address: addr, 
                  isPickup: widget.orderType == 'pickup',
                  mitraId: _selectedMitra?['id'] ?? 0,
                  mitraName: _selectedMitra?['name'] ?? 'Mitra Laundry',
                  speed: _serviceSpeed,
                  distance: (_selectedMitra?['distance'] as num?)?.toDouble() ?? 0.1,
                  dropMethod: _returnMethod,
                  selectedItemsList: selectedItems,
                  districtName: districtName,
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
            child: Text(cT['btn_confirm'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
