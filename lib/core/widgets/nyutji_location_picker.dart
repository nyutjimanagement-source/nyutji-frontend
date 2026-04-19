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
  final String district; // Kelurahan / Desa
  final String subdistrict; // Kecamatan
  final String city; // Kota / Kabupaten
  final String street;
  final String address; // Alamat Lengkap

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
  LatLng _currentLatLng = const LatLng(-6.2088, 106.8456); // Default Jakarta
  final MapController _mapController = MapController();
  bool _isLoading = true;
  String _addressInfo = "Mencari lokasi...";
  
  // Data detail untuk disimpan ke backend
  String _road = "";
  String _houseNumber = "";
  String _village = ""; // Kelurahan
  String _subdistrict = ""; // Kecamatan
  String _city = "";
  String _fullAddress = "";

  // Search variables
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLatLng = LatLng(pos.latitude, pos.longitude);
      _isLoading = false;
    });
    _mapController.move(_currentLatLng, 16.0); // OTOMATIS PINDAH KE LOKASI BARU
    _reverseGeocode(_currentLatLng);
  }

  Future<void> _reverseGeocode(LatLng point) async {
    try {
      final url = Uri.parse("https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1");
      final response = await http.get(url, headers: {'User-Agent': 'NyutjiApp'});
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        
        // Ekstraksi data mendetail dari Nominatim
        _road = address['road'] ?? "";
        _houseNumber = address['house_number'] ?? "";
        _village = address['village'] ?? address['suburb'] ?? address['neighbourhood'] ?? address['hamlet'] ?? "";
        _subdistrict = address['subdistrict'] ?? address['city_district'] ?? "";
        _city = address['city'] ?? address['regency'] ?? address['county'] ?? "";
        _fullAddress = data['display_name'] ?? "";

        setState(() {
          // Tampilkan Alamat lebih lengkap di UI preview
          String displayKec = _subdistrict.isNotEmpty ? 'Kec. $_subdistrict' : '';
          _addressInfo = "${_village.isNotEmpty ? '$_village, ' : ''}$displayKec, $_city";
        });
      }
    } catch (e) {
      debugPrint("Geocoding Error: $e");
    }
  }

  Future<void> _searchLocations(String query) async {
    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }

    try {
      final url = Uri.parse("https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&addressdetails=1&countrycodes=id");
      final response = await http.get(url, headers: {'User-Agent': 'NyutjiApp'});
      
      if (response.statusCode == 200) {
        setState(() {
          _searchResults = json.decode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Search Error: $e");
    }
  }

  void _selectLocation(dynamic location) {
    final lat = double.parse(location['lat']);
    final lon = double.parse(location['lon']);
    final newPos = LatLng(lat, lon);

    setState(() {
      _currentLatLng = newPos;
      _searchResults = [];
      _searchController.clear();
      _isSearching = false;
    });

    _mapController.move(newPos, 16.0);
    _reverseGeocode(newPos);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag Handle
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
                      Text("Pilih Lokasi Alamat", style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 18, color: const Color(0xFF1E5655))),
                      Text("Cari atau geser peta untuk menentukan titik", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[500])),
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
                // MAP (OSM)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLatLng,
                      initialZoom: 16.0,
                      onPositionChanged: (pos, hasGesture) {
                        if (hasGesture) {
                          _currentLatLng = pos.center!;
                        }
                      },
                      onMapEvent: (event) {
                        if (event is MapEventMoveEnd) {
                          _reverseGeocode(_currentLatLng);
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.nyutji.app',
                      ),
                    ],
                  ),
                ),

                // SEARCH BAR OVERLAY
                Positioned(
                  top: 16, left: 16, right: 16,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => _searchLocations(val),
                          decoration: InputDecoration(
                            hintText: "Cari lokasi atau nama jalan...",
                            hintStyle: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey),
                            prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF1E5655)),
                            suffixIcon: _searchController.text.isNotEmpty 
                              ? IconButton(icon: const Icon(LucideIcons.xCircle, size: 18), onPressed: () { _searchController.clear(); setState(() => _searchResults = []); }) 
                              : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      if (_searchResults.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _searchResults.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
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
                
                // Overlay Loading
                if (_isLoading)
                  Container(
                    color: Colors.white,
                    child: const Center(child: CircularProgressIndicator(color: Color(0xFF1E5655))),
                  ),
                
                // Custom Pin Marker
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))]),
                        child: const Icon(LucideIcons.mapPin, color: Colors.white, size: 30),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                
                // Info Card
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, -10))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFF1E5655).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(LucideIcons.navigation, size: 16, color: Color(0xFF1E5655)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text("Lokasi Terdeteksi:", style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 0.5))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(_addressInfo, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87)),
                        if (_road.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text("${_road} ${_houseNumber}", style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600])),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF286B6A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.pop(context, NyutjiLocationResult(
                                lat: _currentLatLng.latitude,
                                lng: _currentLatLng.longitude,
                                district: _village,
                                subdistrict: _subdistrict,
                                city: _city,
                                street: "${_road} ${_houseNumber}".trim(),
                                address: _fullAddress,
                              ));
                            },
                            child: const Text("KONFIRMASI LOKASI", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
