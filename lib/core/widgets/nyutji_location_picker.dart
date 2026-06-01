// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

class NyutjiLocationResult {
  final double lat;
  final double lng;
  final String district;
  final String subdistrict;
  final String city;
  final String street;
  final String address;

  NyutjiLocationResult({
    required this.lat,
    required this.lng,
    required this.district,
    required this.subdistrict,
    required this.city,
    required this.street,
    required this.address,
  });
}

class NyutjiLocationPicker extends StatefulWidget {
  const NyutjiLocationPicker({super.key});

  @override
  State<NyutjiLocationPicker> createState() => _NyutjiLocationPickerState();
}

class _NyutjiLocationPickerState extends State<NyutjiLocationPicker> {
  // FIX #3: Gunakan nullable LatLng agar jelas kapan koordinat belum diset
  LatLng _currentLatLng = const LatLng(-6.2088, 106.8456); // Default Jakarta
  bool _hasValidLocation = false; // FIX #2: flag koordinat valid (bukan default)

  final MapController _mapController = MapController();
  bool _isLoading = true;
  bool _isGeocoding = false;
  String _addressInfo = "Mencari lokasi GPS...";

  String _road = "";
  String _houseNumber = "";
  String _village = "";
  String _subdistrict = "";
  String _city = "";

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addressDetailController = TextEditingController(); // editable street detail
  List<dynamic> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _addressDetailController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // FIX #1: Selalu set _isLoading = false di setiap exit point
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _addressInfo = "GPS tidak aktif. Geser peta ke lokasi Anda.";
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _addressInfo = "Izin GPS ditolak. Geser peta ke lokasi Anda.";
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _addressInfo = "GPS diblokir permanen. Geser peta ke lokasi Anda.";
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      final gpsLatLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentLatLng = gpsLatLng;
        _hasValidLocation = true; // FIX #2: GPS berhasil → koordinat valid
        _isLoading = false;
      });

      _mapController.move(gpsLatLng, 16.0);
      _reverseGeocode(gpsLatLng);
    } catch (e) {
      // FIX #1: Tangkap semua error agar _isLoading tidak stuck
      if (mounted) {
        setState(() {
          _isLoading = false;
          _addressInfo = "GPS error. Geser peta ke lokasi Anda.";
        });
      }
      debugPrint("GPS Error: $e");
    }
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _isGeocoding = true);
    try {
      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/reverse"
        "?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1",
      );
      final response = await http.get(url, headers: {'User-Agent': 'NyutjiApp/1.0'});

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] ?? {};
        final String displayName = data['display_name'] ?? "";

        _road = address['road'] ?? "";
        _houseNumber = address['house_number'] ?? "";
        _village = address['village'] ?? address['suburb'] ?? address['neighbourhood'] ?? address['hamlet'] ?? "";

        // Normalisasi Kota
        String rawCity = address['city'] ?? "";
        String rawRegency = address['regency'] ?? address['county'] ?? "";
        if (rawCity.isNotEmpty) {
          _city = rawCity.toLowerCase().startsWith('kota ') ? rawCity : "Kota $rawCity";
        } else if (rawRegency.isNotEmpty) {
          _city = rawRegency.toLowerCase().startsWith('kabupaten ')
              ? rawRegency.replaceAll(RegExp(r'^kabupaten\s+', caseSensitive: false), 'Kab. ')
              : rawRegency.toLowerCase().startsWith('kab. ')
                  ? rawRegency
                  : "Kab. $rawRegency";
        } else {
          _city = "";
        }

        // Normalisasi Kecamatan
        _subdistrict = address['subdistrict'] ?? address['city_district'] ?? "";
        _subdistrict = _subdistrict
            .replaceAll(RegExp(r'^kecamatan\s+', caseSensitive: false), '')
            .replaceAll(RegExp(r'^kec\.\s*', caseSensitive: false), '')
            .trim();

        // GENIUS FALLBACK: Jika kecamatan kosong dari OSM, gunakan Kelurahan sebagai Kecamatan
        if (_subdistrict.isEmpty && _village.isNotEmpty) {
          _subdistrict = _village;
        }

        // Pre-fill address detail box dengan info jalan yang terdeteksi
        final detectedStreet = "$_road $_houseNumber".trim();
        _addressDetailController.text = detectedStreet;

        setState(() {
          // LOGIKA CERDAS: Hindari duplikasi jika Kelurahan == Kecamatan
          String vilPart = _village.isNotEmpty ? "$_village, " : "";
          if (_subdistrict.toLowerCase() == _village.toLowerCase()) {
            vilPart = ""; // Cukup tampilkan Kecamatan saja
          }
          
          final displayKec = _subdistrict.isNotEmpty ? 'Kec. $_subdistrict' : '';
          final generatedInfo = "$vilPart$displayKec, $_city"
              .replaceAll(RegExp(r'^,\s*'), '')
              .replaceAll(RegExp(r',\s*$'), '')
              .trim();
          
          // FALLBACK: Jika rangkaian manual gagal, pakai displayName (Alamat Lengkap)
          if (generatedInfo.length < 5 && displayName.isNotEmpty) {
            _addressInfo = displayName.split(',').take(3).join(',').trim();
          } else {
            _addressInfo = generatedInfo.isEmpty ? "Alamat tidak ditemukan" : generatedInfo;
          }
          
          _isGeocoding = false;
        });
      } else {
        setState(() => _isGeocoding = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isGeocoding = false);
      debugPrint("Geocoding Error: $e");
    }
  }

  Future<void> _searchLocations(String query) async {
    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    try {
      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search"
        "?q=$query&format=json&limit=5&addressdetails=1&countrycodes=id",
      );
      final response = await http.get(url, headers: {'User-Agent': 'NyutjiApp/1.0'});
      if (mounted && response.statusCode == 200) {
        setState(() => _searchResults = json.decode(response.body));
      }
    } catch (e) {
      debugPrint("Search Error: $e");
    }
  }

  void _selectLocation(dynamic location) {
    final lat = double.tryParse(location['lat'].toString()) ?? 0;
    final lon = double.tryParse(location['lon'].toString()) ?? 0;
    if (lat == 0 || lon == 0) return;

    final newPos = LatLng(lat, lon);
    setState(() {
      _currentLatLng = newPos;
      _hasValidLocation = true; // FIX #2: search berhasil → koordinat valid
      _searchResults = [];
      _searchController.clear();
    });
    _mapController.move(newPos, 16.0);
    _reverseGeocode(newPos);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    const primaryTeal = Color(0xFF286B6A);
    const darkTeal = Color(0xFF1E5655);
    
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Pilih Lokasi Alamat", style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 18, color: darkTeal)),
                      Text("Sentuh peta untuk meletakkan pin lokasi Anda", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(LucideIcons.x, size: 22, color: Colors.grey[400]),
                  style: IconButton.styleFrom(backgroundColor: Colors.grey[50]),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLatLng,
                      initialZoom: 16.0,
                      backgroundColor: const Color(0xFFa8d5e8),
                      onTap: (tapPosition, point) {
                        setState(() {
                          _currentLatLng = point;
                          _hasValidLocation = true;
                        });
                        _mapController.move(point, _mapController.camera.zoom);
                        _reverseGeocode(point);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.nyutji.app',
                      ),
                      if (!_isLoading && _hasValidLocation)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentLatLng,
                              width: 28,
                              height: 28,
                              alignment: Alignment.topCenter,
                              child: const Icon(Icons.location_on, color: primaryTeal, size: 28),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: 16, left: 16, right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _searchLocations,
                          decoration: InputDecoration(
                            hintText: "Cari lokasi atau nama jalan...",
                            hintStyle: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey),
                            prefixIcon: const Icon(LucideIcons.search, size: 18, color: darkTeal),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(LucideIcons.xCircle, size: 18),
                                    onPressed: () { _searchController.clear(); setState(() => _searchResults = []); })
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),

                      if (_searchResults.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final loc = _searchResults[index];
                              return ListTile(
                                leading: const Icon(LucideIcons.mapPin, size: 18, color: Colors.grey),
                                title: Text(loc['display_name'], style: GoogleFonts.montserrat(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                onTap: () => _selectLocation(loc),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                
                if (!_isLoading)
                  Positioned(
                    bottom: 16 + MediaQuery.of(context).padding.bottom, left: 16, right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 10))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: darkTeal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: _isGeocoding
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: darkTeal))
                                    : const Icon(LucideIcons.compass, size: 20, color: darkTeal),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Alamat Terdeteksi", style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                                    const SizedBox(height: 4),
                                    Text(_addressInfo, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87, height: 1.3)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _addressDetailController,
                            style: GoogleFonts.montserrat(fontSize: 13, color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: "Detail tambahan: Blok, No Rumah, Patokan...",
                              hintStyle: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[400]),
                              prefixIcon: const Icon(Icons.edit_outlined, size: 16, color: darkTeal),
                              filled: true,
                              fillColor: const Color(0xFFF5F5F5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _hasValidLocation ? primaryTeal : Colors.grey[400],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                              ),
                              onPressed: _hasValidLocation
                                  ? () {
                                      Navigator.pop(context, NyutjiLocationResult(
                                        lat: _currentLatLng.latitude,
                                        lng: _currentLatLng.longitude,
                                        district: _village,
                                        subdistrict: _subdistrict,
                                        city: _city,
                                        street: _addressDetailController.text.trim(),
                                        address: "${_addressDetailController.text.trim()}, $_addressInfo".replaceAll(RegExp(r'^,\s*'), ''),
                                      ));
                                    }
                                  : null,
                              child: Text(
                                _hasValidLocation ? "KONFIRMASI LOKASI" : "Menunggu Koordinat...",
                                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.9),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: darkTeal),
                          const SizedBox(height: 16),
                          Text("Mendeteksi lokasi GPS...", style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}
