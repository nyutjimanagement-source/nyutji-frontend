import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/nyutji_location_picker.dart';
import '../../../providers/auth_provider.dart';
import 'customer_payment_screen.dart';
import '../../../data/services/api_service.dart';

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
  
  // STATE UNTUK PESANAN (Item ID -> Count)
  final Map<int, int> _itemCounts = {};
  
  // STATE UNTUK MAPS & LOKASI
  double? _selectedLat;
  double? _selectedLng;  
  
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

  Future<void> _loadLiveMitras() async {
    setState(() => _isLoadingMitras = true);
    try {
      final api = ApiService();
      final data = await api.getRecommendedMitras(); 
      
      final List<dynamic> rawData = data;
      _mitras = rawData.map((m) {
        final Map<String, dynamic> item = Map<String, dynamic>.from(m);
        return {
          'id': item['id'] ?? item['mitra_id'] ?? 0,
          'name': item['name'] ?? item['brand_name'] ?? item['full_name'] ?? item['mitra_name'] ?? 'Mitra Nyutji',
          'rating': (item['rating'] ?? 5.0).toDouble(),
          'distance': (item['distance'] ?? 0.1).toDouble(),
          'address': item['address'] ?? 'Alamat tidak tersedia',
          'district': item['district'] ?? '',
          'image': item['image'] ?? item['profile_photo'] ?? item['photo'],
          'items': item['items'] ?? [],
        };
      }).toList();
    } catch (e) {
      debugPrint("API Error, switching to fallback: $e");
    } finally {
      if (_mitras.isEmpty) {
        _mitras = [
          { 'id': 1, 'name': 'Input ML Fatmawati', 'rating': 5.0, 'distance': 0.8, 'address': 'Cipete Utara', 'district': 'Cipete Utara', 'image': null, 'items': [] },
          { 'id': 99, 'name': 'Mitra Auto Laundry Code', 'rating': 5.0, 'distance': 1.2, 'address': 'Serpong', 'district': 'Serpong', 'image': null, 'items': [] },
          { 'id': 3, 'name': 'Laundry Code 01', 'rating': 4.9, 'distance': 2.5, 'address': 'Pamulang', 'district': 'Pamulang', 'image': null, 'items': [] },
          { 'id': 4, 'name': 'Laundry Code', 'rating': 4.8, 'distance': 3.1, 'address': 'Pamulang', 'district': 'Pamulang', 'image': null, 'items': [] },
        ];
      }
      if (mounted) {
        setState(() => _isLoadingMitras = false);
        // CURI START: Pre-fetch semua item mitra di background agar saat diklik langsung 'Instan'
        for (var m in _mitras) {
          _fetchMitraItems(m['id']);
        }
      }
    }
  }

  Future<void> _fetchMitraItems(int mitraId) async {
    try {
      final api = ApiService();
      // Set timeout manual untuk simulasi kilat
      final items = await api.getMitraItems(mitraId).timeout(const Duration(seconds: 3)); 
      
      if (mounted) {
        setState(() {
          int idx = _mitras.indexWhere((m) => m['id'] == mitraId);
          if (idx != -1) {
            _mitras[idx]['items'] = (items.isEmpty) ? _getDefaultSimulationItems(mitraId) : items;
            if (_selectedMitra != null && _selectedMitra!['id'] == mitraId) {
              _selectedMitra!['items'] = _mitras[idx]['items'];
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          int idx = _mitras.indexWhere((m) => m['id'] == mitraId);
          if (idx != -1 && (_mitras[idx]['items'] == null || (_mitras[idx]['items'] as List).isEmpty)) {
            _mitras[idx]['items'] = _getDefaultSimulationItems(mitraId);
            if (_selectedMitra != null && _selectedMitra!['id'] == mitraId) {
              _selectedMitra!['items'] = _mitras[idx]['items'];
            }
          }
        });
      }
    }
  }

  List<dynamic> _getDefaultSimulationItems(int id) {
    if (id == 1) return [{ 'id': 999, 'name': 'Paket EKSPRES 6 JAM', 'price': 15000, 'unit': 'Kg' }, { 'id': 101, 'name': 'Cuci Setrika Reguler', 'price': 7000, 'unit': 'Kg' }];
    return [{ 'id': 101, 'name': 'Cuci Setrika Reguler', 'price': 7000, 'unit': 'Kg' }, { 'id': 102, 'name': 'Cuci Lipat Reguler', 'price': 5000, 'unit': 'Kg' }];
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

  void _updateItemCount(int itemId, int delta) {
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
      
      // Sinkronisasi alamat dari AuthProvider jika tersedia
      if (auth.user != null && _pickupAddress == 'Jl. Kebayoran No 12, Jakarta') {
         final district = auth.user?['district_name'];
         final city = auth.user?['city_name'];
         if (district != null) _pickupAddress = "$district, ${city ?? ''}";
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
                  Text(cT['recom_mitra'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black87)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: _isLoadingMitras 
              ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_locationIcon, size: 16, color: primaryTeal),
              const SizedBox(width: 8),
              Text(cT['loc_pickup'], style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
              const Spacer(),
              _pillButton("Ubah", () => _showLocationPicker(cT, auth)),
            ],
          ),
          const SizedBox(height: 12),
          Text(_pickupAddress, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
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
        decoration: BoxDecoration(color: primaryTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
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
              color: isSelected ? primaryTeal.withOpacity(0.3) : Colors.black.withOpacity(0.08),
              blurRadius: 12, offset: const Offset(0, 6)
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
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
                      // GRADASI ELEGAN: Dari Kanan (Hitam) ke Kiri (Transparan) - Sesuai Request Boss
                      colors: [Colors.black.withOpacity(0.9), Colors.black.withOpacity(0.4), Colors.transparent],
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end, // Kembalikan ke Bawah sesuai Request Boss
                  crossAxisAlignment: CrossAxisAlignment.end, // Tetap di Kanan agar pas dengan gradasi gelapnya
                  children: [
                    Text(
                      mitra['name'] ?? 'Mitra Laundry',
                      style: GoogleFonts.montserrat(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.2),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right, // Teks rata kanan agar makin rapi
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end, // Ikon & Rating juga rata kanan
                      children: [
                        const Icon(LucideIcons.star, size: 10, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                        Text("${mitra['rating'] ?? '5.0'}", style: GoogleFonts.montserrat(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8), // Beri jarak sedikit
                        const Icon(LucideIcons.mapPin, size: 10, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text("${mitra['distance'] ?? '0.1'} km", style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 10, right: 10,
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

  void _showLocationPicker(Map<String, dynamic> cT, AuthProvider auth) {
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cT['loc_pickup'], style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              Text("Silakan pilih cara penentuan lokasi penjemputan:", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[600])),
              const SizedBox(height: 20),
              _locOption(cT['opt_home'], auth.homeAddress != null ? "${auth.homeAddress!['detail']} ${auth.homeAddress!['address']}" : "Belum Set Alamat Rumah", LucideIcons.home, () {
                if (auth.homeAddress != null) {
                  setState(() {
                    _pickupAddress = auth.homeAddress!['address'];
                    _pickupNote = auth.homeAddress!['detail'] ?? "";
                    _locationIcon = LucideIcons.home;
                  });
                }
                Navigator.pop(context);
              }),
              _locOption(cT['opt_gps'], cT['opt_gps_desc'], LucideIcons.crosshair, () async {
                Navigator.pop(context); 
                _launchMapPicker(LucideIcons.crosshair);
              }),
              _locOption(cT['opt_map'], cT['opt_map_desc'], LucideIcons.map, () async {
                Navigator.pop(context); 
                _launchMapPicker(LucideIcons.map);
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _launchMapPicker(IconData targetIcon) async {
    final NyutjiLocationResult? result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NyutjiLocationPicker(),
    );
    if (result != null) {
      setState(() {
        _pickupAddress = result.address;
        _selectedLat = result.lat;
        _selectedLng = result.lng;
        _locationIcon = targetIcon;
      });
    }
  }

  Widget _locOption(String title, String desc, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
              child: Icon(icon, size: 16, color: primaryTeal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text(desc, style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[500])),
                ],
              ),
            )
          ],
        ),
      ),
    );
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
        decoration: BoxDecoration(color: isSel ? activeC.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(title, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? activeC : Colors.grey[400])),
            Text(desc, style: GoogleFonts.montserrat(fontSize: 9, color: isSel ? activeC.withOpacity(0.8) : Colors.grey[400])),
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
            SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryTeal.withOpacity(0.5))),
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
    // Pecah items menjadi chunk per 5 item
    List<List<dynamic>> chunks = [];
    for (var i = 0; i < items.length; i += 5) {
      chunks.add(items.sublist(i, i + 5 > items.length ? items.length : i + 5));
    }

    int itemsRemaining = items.length - (currentPage * 5);
    int currentItemsCount = itemsRemaining > 5 ? 5 : (itemsRemaining < 0 ? 0 : itemsRemaining);
    double hHeader = 40.0;
    double hPageIndicator = chunks.length > 1 ? 25.0 : 0.0;
    double tableHeight = (currentItemsCount * (isKiloan ? 46.0 : 42.0)) + hHeader + hPageIndicator;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)]),
      child: Column(
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
          
          // PAGE VIEW UNTUK SWIPE PER 5 ITEM
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: tableHeight,
            child: PageView.builder(
              onPageChanged: onPageChanged,
              itemCount: chunks.length,
              itemBuilder: (context, pageIdx) {
                final pageItems = chunks[pageIdx];
                return Column(
                  children: pageItems.map((item) => isKiloan ? _buildKiloanRow(item) : _buildSatuanRow(item)).toList(),
                );
              },
            ),
          ),
          
          // INDIKATOR TITIK (Kalo lebih dari 1 halaman)
          if (chunks.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(chunks.length, (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6, height: 6,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: currentPage == index ? primaryTeal : primaryTeal.withOpacity(0.3)),
                )),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildKiloanRow(Map<String, dynamic> item) {
    final double priceReg = double.tryParse(item['price_regular']?.toString() ?? item['price']?.toString() ?? '0') ?? 0;
    final double? pFastRaw = double.tryParse(item['price_fast']?.toString() ?? '');
    final double priceFast = (pFastRaw == null || pFastRaw == 0) ? priceReg : pFastRaw;
    int itemId = int.tryParse(item['id']?.toString() ?? '0') ?? 0;
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
                      Text("Rp ${NumberFormat.decimalPattern('id_ID').format(priceReg)}", style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: primaryTeal)),
                      Text("Rp ${NumberFormat.decimalPattern('id_ID').format(priceFast)}", style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFFD97706))),
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
    int itemId = int.tryParse(item['id']?.toString() ?? '0') ?? 0;
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
                  child: Text("Rp ${NumberFormat.decimalPattern('id_ID').format(price)}", 
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
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
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
                
                List<Map<String, dynamic>> selectedItems = [];
                final List? mItems = _selectedMitra?['items'] as List?;
                if (mItems != null) {
                  _itemCounts.forEach((itemId, count) {
                    if (count > 0) {
                      try {
                        var item = mItems.firstWhere((i) => i['id'] == itemId, orElse: () => null);
                        if (item != null) {
                          selectedItems.add({'name': item['name'], 'count': count, 'unit': item['unit']});
                        }
                      } catch (e) {
                        debugPrint("Error processing item $itemId: $e");
                      }
                    }
                  });
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
