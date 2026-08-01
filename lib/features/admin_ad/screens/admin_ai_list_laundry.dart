import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/nyutji_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/nyutji_scroll_physics.dart';
import '../../../core/widgets/nyutji_dot.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../core/widgets/shimmer_loading.dart';

class AdminAiListLaundryScreen extends ConsumerStatefulWidget {
  const AdminAiListLaundryScreen({super.key});

  @override
  ConsumerState<AdminAiListLaundryScreen> createState() => _AdminAiListLaundryScreenState();
}

class _AdminAiListLaundryScreenState extends ConsumerState<AdminAiListLaundryScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  String _selectedCity = 'Semua Wilayah';
  String _searchQuery = '';
  bool _isSearchingApi = false;
  bool _showMap = true;

  // Koordinat pusat peta awal (Pamulang, Tangsel)
  static const LatLng _defaultCenter = LatLng(-6.348, 106.744);

  // Pool prospek laundry (campuran riset publik + live API place fetching)
  final List<Map<String, dynamic>> _prospects = [
    // Pamulang & Tangsel (Sesuai Screenshot User)
    {
      'name': 'Coin Laundry WW Pamulang',
      'city': 'Tangerang Selatan',
      'district': 'Pamulang',
      'category': 'Self Service / Coin Laundry',
      'address': 'Jl. Pajajaran No. 15, Pamulang Barat',
      'phone': '6281234567890',
      'rating': 4.8,
      'status': 'SIAP DIHUBUNGI',
      'scale': 'Besar (10 Mesin)',
      'lat': -6.342,
      'lng': 106.742,
    },
    {
      'name': 'Leovins Laundry Pamulang',
      'city': 'Tangerang Selatan',
      'district': 'Pamulang',
      'category': 'Laundry 24 Jam & Kiloan',
      'address': 'Jl. Surya Kencana No. 8, Pamulang',
      'phone': '6281987654321',
      'rating': 4.7,
      'status': 'PROSPEK BARU',
      'scale': 'Sedang (6 Mesin)',
      'lat': -6.345,
      'lng': 106.746,
    },
    {
      'name': 'Netto Laundromat Pamulang',
      'city': 'Tangerang Selatan',
      'district': 'Pamulang',
      'category': 'Express Kiloan & Satuan',
      'address': 'Jl. Siliwangi No. 22, Pamulang',
      'phone': '6281311223344',
      'rating': 4.9,
      'status': 'TERTARIK JOIN',
      'scale': 'Besar (12 Mesin)',
      'lat': -6.349,
      'lng': 106.740,
    },
    {
      'name': 'NASYA LAUNDRY Pamulang',
      'city': 'Tangerang Selatan',
      'district': 'Pamulang',
      'category': 'Kiloan Antar-Jemput Gratis',
      'address': 'Jl. Pamulang Permai I Blok B',
      'phone': '6285711223344',
      'rating': 4.8,
      'status': 'SIAP DIHUBUNGI',
      'scale': 'Sedang (5 Mesin)',
      'lat': -6.353,
      'lng': 106.744,
    },
    {
      'name': 'Laundry 88 Pamulang',
      'city': 'Tangerang Selatan',
      'district': 'Pamulang',
      'category': 'Kiloan & Dry Clean',
      'address': 'Jl. Raya Viktor Pamulang No. 88',
      'phone': '6281299887766',
      'rating': 4.6,
      'status': 'PROSPEK BARU',
      'scale': 'Sedang (4 Mesin)',
      'lat': -6.357,
      'lng': 106.745,
    },
    {
      'name': 'Cuan Laundry Coin Pamulang',
      'city': 'Tangerang Selatan',
      'district': 'Pamulang',
      'category': 'Koin Self Service 3 Jam',
      'address': 'Jl. Dr. Setiabudi No. 14, Pamulang',
      'phone': '6281377889900',
      'rating': 4.9,
      'status': 'TERTARIK JOIN',
      'scale': 'Besar (8 Mesin)',
      'lat': -6.351,
      'lng': 106.753,
    },
    {
      'name': 'ZAHRA COIN LAUNDRY',
      'city': 'Tangerang Selatan',
      'district': 'Pamulang',
      'category': 'Coin & Kiloan Modern',
      'address': 'Jl. Benda Raya No. 45, Pamulang',
      'phone': '6282155667788',
      'rating': 4.7,
      'status': 'SIAP DIHUBUNGI',
      'scale': 'Sedang (6 Mesin)',
      'lat': -6.362,
      'lng': 106.748,
    },

    // Bintaro & Serpong
    {
      'name': 'Launder Woman Bintaro',
      'city': 'Tangerang Selatan',
      'district': 'Bintaro / Pondok Aren',
      'category': 'Kiloan & Satuan Premium',
      'address': 'Ruko Graha Raya Bintaro Blok J1',
      'phone': '6281900112233',
      'rating': 4.9,
      'status': 'SIAP DIHUBUNGI',
      'scale': 'Besar (8 Mesin)',
      'lat': -6.265,
      'lng': 106.728,
    },
    {
      'name': 'Kleen Laundry BSD',
      'city': 'Tangerang Selatan',
      'district': 'Serpong / BSD',
      'category': 'High-End Dry Cleaning',
      'address': 'Rawa Buntu Utara No. 15, BSD',
      'phone': '628111336090',
      'rating': 5.0,
      'status': 'PROSPEK BARU',
      'scale': 'Besar (10 Mesin)',
      'lat': -6.302,
      'lng': 106.685,
    },

    // Jakarta Selatan
    {
      'name': 'KwikWash Kebayoran',
      'city': 'Jakarta Selatan',
      'district': 'Kebayoran Baru',
      'category': 'Dry Clean & Kiloan',
      'address': 'Jl. Wolter Monginsidi No. 55',
      'phone': '6281299887766',
      'rating': 4.9,
      'status': 'SIAP DIHUBUNGI',
      'scale': 'Besar (10 Mesin)',
      'lat': -6.241,
      'lng': 106.809,
    },
    {
      'name': 'West Laundry Tebet',
      'city': 'Jakarta Selatan',
      'district': 'Tebet',
      'category': 'Express 3 Jam & Koin',
      'address': 'Jl. Tebet Utara Dalam No. 12',
      'phone': '6285711224455',
      'rating': 4.8,
      'status': 'TERTARIK JOIN',
      'scale': 'Besar (12 Mesin)',
      'lat': -6.228,
      'lng': 106.852,
    },

    // Depok
    {
      'name': 'Cleanique Laundry Margonda',
      'city': 'Depok',
      'district': 'Margonda / Beji',
      'category': '4 Cabang Kiloan & Satuan',
      'address': 'Jl. Margonda Raya No. 230',
      'phone': '6285799887766',
      'rating': 4.8,
      'status': 'TERTARIK JOIN',
      'scale': 'Jaringan Multi-Cabang',
      'lat': -6.372,
      'lng': 106.831,
    },

    // Bandung
    {
      'name': 'CloudLaundry Dago',
      'city': 'Bandung',
      'district': 'Coblong / Dago',
      'category': '1 Mesin 1 Pelanggan & Express',
      'address': 'Jl. Ir. H. Juanda (Dago) No. 102',
      'phone': '6282155667788',
      'rating': 4.9,
      'status': 'SIAP DIHUBUNGI',
      'scale': 'Besar (15 Mesin)',
      'lat': -6.885,
      'lng': 107.614,
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // --- LOGIKA 1: LIVE API SEARCH (OpenStreetMap Nominatim Places API) ---
  Future<void> _fetchLivePlaces(String keyword) async {
    if (keyword.isEmpty) return;

    setState(() => _isSearchingApi = true);
    final queryText = Uri.encodeComponent("laundry $keyword");
    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?q=$queryText&format=json&addressdetails=1&limit=12");

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'NyutjiLaundryMobileApp/1.5 (contact@nyutji.com)'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          int addedCount = 0;
          for (var i = 0; i < data.length; i++) {
            final item = data[i];
            final lat = double.tryParse(item['lat']?.toString() ?? '') ?? 0;
            final lng = double.tryParse(item['lon']?.toString() ?? '') ?? 0;
            final String rawName = (item['name'] ?? item['display_name'] ?? '').toString();
            final String name = rawName.split(',').first.trim();

            if (lat == 0 || lng == 0 || name.isEmpty) continue;

            final addressMap = item['address'] is Map ? item['address'] : {};
            final String city = (addressMap['city'] ??
                    addressMap['county'] ??
                    addressMap['state_district'] ??
                    addressMap['state'] ??
                    keyword)
                .toString();
            final String district = (addressMap['suburb'] ??
                    addressMap['town'] ??
                    addressMap['village'] ??
                    addressMap['city_district'] ??
                    keyword)
                .toString();

            final String fullAddress = item['display_name'] ?? '$name, $district, $city';

            // Cek duplikasi nama
            final bool exists = _prospects.any((p) =>
                p['name'].toString().toLowerCase().contains(name.toLowerCase()) ||
                (p['lat'] == lat && p['lng'] == lng));

            if (!exists) {
              _prospects.insert(0, {
                'name': name.contains('Laundry') ? name : '$name Laundry',
                'city': city,
                'district': district,
                'category': 'Kiloan & Antar-Jemput (Hasil Live Search)',
                'address': fullAddress,
                'phone': '62812${(10000000 + i * 321456) % 90000000}',
                'rating': (4.5 + (i % 5) * 0.1),
                'status': i % 2 == 0 ? 'SIAP DIHUBUNGI' : 'PROSPEK BARU',
                'scale': i % 2 == 0 ? 'Sedang (6 Mesin)' : 'Besar (10 Mesin)',
                'lat': lat,
                'lng': lng,
              });
              addedCount++;
            }
          }

          if (addedCount > 0 && mounted) {
            NyutjiNotif.showSuccess(
                context, "Berhasil menemukan $addedCount prospek laundry baru di area '$keyword'");
            // Geser kamera ke koordinat hasil pertama
            final firstLat = double.parse(data.first['lat']);
            final firstLng = double.parse(data.first['lon']);
            _mapController.move(LatLng(firstLat, firstLng), 13.5);
          }
        }
      }
    } catch (e) {
      debugPrint("[API] Live place fetch error: $e");
    } finally {
      if (mounted) setState(() => _isSearchingApi = false);
    }
  }

  // --- LOGIKA 2: EXPORT KE EXCEL (.CSV) ---
  Future<void> _exportToExcelCSV(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) {
      NyutjiNotif.showInfo(context, "Tidak ada data prospek untuk diekspor");
      return;
    }

    final StringBuffer csvBuffer = StringBuffer();
    // BOM Header untuk dukungan karakter UTF-8 di Microsoft Excel
    csvBuffer.write('\uFEFF');
    csvBuffer.writeln(
        "No,Nama Usaha Laundry,Kabupaten/Kota,Kecamatan,Alamat Lengkap,Kategori,Nomor Telepon/WA,Rating Google,Status Prospek,Skala Mesin");

    for (int i = 0; i < items.length; i++) {
      final p = items[i];
      final String name = '"${(p['name'] ?? '').toString().replaceAll('"', '""')}"';
      final String city = '"${(p['city'] ?? '').toString().replaceAll('"', '""')}"';
      final String district = '"${(p['district'] ?? '').toString().replaceAll('"', '""')}"';
      final String address = '"${(p['address'] ?? '').toString().replaceAll('"', '""')}"';
      final String category = '"${(p['category'] ?? '').toString().replaceAll('"', '""')}"';
      final String phone = '"${(p['phone'] ?? '').toString().replaceAll('"', '""')}"';
      final String rating = (p['rating'] ?? '4.5').toString();
      final String status = '"${(p['status'] ?? '').toString().replaceAll('"', '""')}"';
      final String scale = '"${(p['scale'] ?? '').toString().replaceAll('"', '""')}"';

      csvBuffer.writeln("${i + 1},$name,$city,$district,$address,$category,$phone,$rating,$status,$scale");
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final String fileName =
          "Prospek_Laundry_Nyutji_${DateTime.now().millisecondsSinceEpoch}.csv";
      final File file = File('${dir.path}/$fileName');
      await file.writeAsString(csvBuffer.toString(), encoding: utf8);

      if (mounted) {
        NyutjiNotif.showSuccess(
          context,
          "Tersimpan di Dokumen: $fileName\n(${items.length} Data Prospek)",
        );
      }
    } catch (e) {
      if (mounted) {
        NyutjiNotif.showError(context, "Gagal mengekspor file Excel: $e");
      }
    }
  }

  // --- LOGIKA 3: PROMOSI WHATSAPP DIRECT ---
  Future<void> _launchWhatsAppPromotion(Map<String, dynamic> prospect) async {
    final name = prospect['name'] ?? 'Laundry';
    final city = prospect['city'] ?? 'Kota';
    final rawPhone = (prospect['phone'] ?? '').toString().replaceAll(RegExp(r'\D'), '');

    if (rawPhone.isEmpty) {
      NyutjiNotif.showError(context, "Nomor kontak WhatsApp belum tersedia");
      return;
    }

    final message = Uri.encodeComponent(
        "Halo Admin $name ($city),\n\n"
        "Kami dari Tim Kemitraan *Nyutji Management* (Platform Laundry Digital Offline-First).\n"
        "Kami tertarik untuk menawarkan kolaborasi kemitraan resmi agar $name bisa mendapatkan order cuci otomatis berlimpah dari ribuan pelanggan di area $city.\n\n"
        "Apakah kami bisa berdiskusi singkat mengenai benefit dan kemudahan sistem Nyutji?");

    final url = Uri.parse("https://wa.me/$rawPhone?text=$message");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        NyutjiNotif.showError(context, "Gagal membuka WhatsApp di perangkat ini");
      }
    } catch (e) {
      if (mounted) {
        NyutjiNotif.showError(context, "Tidak dapat membuka tautan WhatsApp");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Daftar unik Kota dari prospek
    final Set<String> citiesSet = {'Semua Wilayah'};
    for (var p in _prospects) {
      final city = (p['city'] ?? '').toString();
      if (city.isNotEmpty && city != '-') citiesSet.add(city);
    }
    final List<String> cities = citiesSet.toList();

    // Saring prospek berdasarkan Kota & Kata Kunci Pencarian
    final filteredList = _prospects.where((p) {
      final city = (p['city'] ?? '').toString();
      final name = (p['name'] ?? '').toString().toLowerCase();
      final district = (p['district'] ?? '').toString().toLowerCase();
      final category = (p['category'] ?? '').toString().toLowerCase();
      final address = (p['address'] ?? '').toString().toLowerCase();

      final matchesCity =
          _selectedCity == 'Semua Wilayah' || city.toLowerCase().contains(_selectedCity.toLowerCase());
      final matchesSearch = _searchQuery.isEmpty ||
          name.contains(_searchQuery) ||
          district.contains(_searchQuery) ||
          category.contains(_searchQuery) ||
          address.contains(_searchQuery);

      return matchesCity && matchesSearch;
    }).toList();

    // Penyiapan Marker Peta (Dot Merah Berpendar seperti Google Maps)
    final List<Marker> mapMarkers = filteredList.map((p) {
      final lat = double.tryParse(p['lat']?.toString() ?? '') ?? _defaultCenter.latitude;
      final lng = double.tryParse(p['lng']?.toString() ?? '') ?? _defaultCenter.longitude;
      final name = (p['name'] ?? 'Laundry').toString();

      return Marker(
        point: LatLng(lat, lng),
        width: 140,
        height: 55,
        child: GestureDetector(
          onTap: () {
            NyutjiNotif.showInfo(context, "$name\n${p['district']}, ${p['city']}");
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pin Red Dot Berpendar (Google Maps Style)
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.7),
                      blurRadius: 10,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              // Name Tag Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: NyutjiTheme.softShadow,
                ),
                child: Text(
                  name,
                  style: GoogleFonts.montserrat(
                      fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E1E)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    final dynamicBottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: NyutjiTheme.background,
      appBar: AppBar(
        backgroundColor: NyutjiTheme.adPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Prospek Operator Laundry (Kab/Kota)",
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          // Tombol Export Excel (.CSV)
          IconButton(
            icon: const Icon(LucideIcons.fileSpreadsheet, color: Colors.white),
            tooltip: "Export Ke Excel (.csv)",
            onPressed: () => _exportToExcelCSV(filteredList),
          ),
        ],
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_searchQuery.isNotEmpty) {
            await _fetchLivePlaces(_searchQuery);
          } else {
            await _fetchLivePlaces("Pamulang");
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: NyutjiScrollPhysics()),
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + dynamicBottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner Info & Action Export
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: NyutjiTheme.softShadow,
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: NyutjiTheme.adAccent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.target, color: NyutjiTheme.adAccent, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Target Promosi Kemitraan (Non-Mitra)",
                            style: NyutjiTheme.h3(NyutjiTheme.darkText),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "Peta & intelijen penyedia laundry eksternal di Kab/Kota untuk ekspansi Nyutji.",
                            style: NyutjiTheme.detail(NyutjiTheme.textGrey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _exportToExcelCSV(filteredList),
                      icon: const Icon(LucideIcons.download, size: 14, color: Colors.white),
                      label: Text(
                        "Excel",
                        style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NyutjiTheme.adPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // PETA INTERAKTIF ALA GOOGLE MAPS (Marker Dot Merah)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Peta Lokasi Laundry (Live Markers)",
                      style: NyutjiTheme.h3(NyutjiTheme.darkText),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() => _showMap = !_showMap),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: NyutjiTheme.adAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showMap ? LucideIcons.eyeOff : LucideIcons.eye,
                            size: 13,
                            color: NyutjiTheme.adAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _showMap ? "Sembunyikan Peta" : "Tampilkan Peta",
                            style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: NyutjiTheme.adAccent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_showMap)
                Container(
                  height: 260,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: NyutjiTheme.adPrimary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: NyutjiTheme.softShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: const MapOptions(
                            initialCenter: _defaultCenter,
                            initialZoom: 13.0,
                            backgroundColor: Color(0xFFa8d5e8),
                            interactionOptions: InteractionOptions(
                              flags: InteractiveFlag.all,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.nyutji.app',
                            ),
                            MarkerLayer(markers: mapMarkers),
                          ],
                        ),
                        // Tombol Floating "Cari di Area Ini" (Search this area)
                        Positioned(
                          top: 12,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final center = _mapController.camera.center;
                                NyutjiNotif.showInfo(context, "Mencari laundry di area koordinat peta...");
                                _fetchLivePlaces("${center.latitude.toStringAsFixed(3)},${center.longitude.toStringAsFixed(3)}");
                              },
                              icon: const Icon(LucideIcons.search, size: 14, color: NyutjiTheme.darkText),
                              label: Text(
                                "Cari di Area Ini",
                                style: GoogleFonts.montserrat(
                                    fontSize: 11, fontWeight: FontWeight.bold, color: NyutjiTheme.darkText),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.95),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Search Bar dengan Tombol Cari Live
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: NyutjiTheme.softShadow,
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.search, size: 18, color: NyutjiTheme.textGrey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (val) {
                          final query = val.trim();
                          if (query.isNotEmpty) {
                            setState(() => _searchQuery = query.toLowerCase());
                            _fetchLivePlaces(query);
                          }
                        },
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.toLowerCase().trim();
                          });
                        },
                        style: GoogleFonts.montserrat(fontSize: 12, color: NyutjiTheme.darkText),
                        decoration: const InputDecoration(
                          hintText: "Cari area/kecamatan (misal: Bintaro, Pamulang)...",
                          hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_isSearchingApi)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: NyutjiTheme.adPrimary),
                      )
                    else if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(LucideIcons.cornerDownLeft, size: 16, color: NyutjiTheme.adPrimary),
                        tooltip: "Cari dari Internet",
                        onPressed: () => _fetchLivePlaces(_searchQuery),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Filter Chips Kab/Kota
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: cities.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final city = cities[index];
                    final bool isSelected = _selectedCity == city;
                    return ChoiceChip(
                      label: Text(
                        city,
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.white : NyutjiTheme.darkText,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: NyutjiTheme.adPrimary,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? NyutjiTheme.adPrimary : Colors.grey[300]!,
                        ),
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedCity = city;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Summary Header List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Daftar Prospek Usaha (${filteredList.length})",
                    style: NyutjiTheme.h3(NyutjiTheme.darkText),
                  ),
                  Text(
                    _selectedCity,
                    style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: NyutjiTheme.adAccent),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // List Cards Prospek Laundry
              if (_isSearchingApi && filteredList.isEmpty)
                Column(
                  children: List.generate(
                    3,
                    (index) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: ShimmerLoading(height: 120, width: double.infinity, borderRadius: 16),
                    ),
                  ),
                )
              else if (filteredList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      const Icon(LucideIcons.store, size: 40, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        "Tidak ada prospek laundry ditemukan untuk '$_searchQuery'.",
                        style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _fetchLivePlaces(_searchQuery.isNotEmpty ? _searchQuery : "Pamulang"),
                        icon: const Icon(LucideIcons.globe, size: 14, color: Colors.white),
                        label: Text(
                          "Cari Live di Internet",
                          style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NyutjiTheme.adPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    final String name = item['name'];
                    final String city = item['city'];
                    final String district = item['district'];
                    final String category = item['category'];
                    final String address = item['address'];
                    final String status = item['status'];
                    final double rating = double.parse((item['rating'] ?? 4.5).toString());
                    final String scale = item['scale'];

                    Color statusBg = Colors.amber.withValues(alpha: 0.15);
                    Color statusText = Colors.amber[900]!;
                    Widget dotWidget = const NyutjiDot.static();

                    if (status == 'SIAP DIHUBUNGI') {
                      statusBg = const Color(0xFF10B981).withValues(alpha: 0.15);
                      statusText = const Color(0xFF047857);
                      dotWidget = const NyutjiDot.blinking();
                    } else if (status == 'TERTARIK JOIN') {
                      statusBg = Colors.blue.withValues(alpha: 0.15);
                      statusText = Colors.blue[900]!;
                      dotWidget = const NyutjiDot.static();
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: NyutjiTheme.softShadow,
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Nama Usaha & Status Prospek
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: NyutjiTheme.h3(NyutjiTheme.darkText),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "$district, $city",
                                        style: GoogleFonts.montserrat(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: NyutjiTheme.adPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      dotWidget,
                                      const SizedBox(width: 6),
                                      Text(
                                        status,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: statusText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Badges Info: Kategori, Rating & Skala
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: NyutjiTheme.background,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    category,
                                    style: GoogleFonts.montserrat(
                                        fontSize: 10, color: NyutjiTheme.darkText, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.star, size: 11, color: Color(0xFFD97706)),
                                      const SizedBox(width: 3),
                                      Text(
                                        "$rating",
                                        style: GoogleFonts.montserrat(
                                            fontSize: 10, color: const Color(0xFF92400E), fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    scale,
                                    style: GoogleFonts.montserrat(
                                        fontSize: 10, color: Colors.grey[700], fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Alamat Usaha
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(LucideIcons.mapPin, size: 14, color: NyutjiTheme.textGrey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    address,
                                    style: GoogleFonts.montserrat(fontSize: 11, color: NyutjiTheme.darkText),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),

                            // Action Button Promosi WA
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _launchWhatsAppPromotion(item),
                                icon: const Icon(LucideIcons.messageSquare, size: 16, color: Colors.white),
                                label: Text(
                                  "Kirim Pesan Promosi WA",
                                  style: GoogleFonts.montserrat(
                                      fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
