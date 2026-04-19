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
        _village = address['village'] ?? address['suburb'] ?? address['neighbourhood'] ?? "";
        _subdistrict = address['subdistrict'] ?? address['city_district'] ?? "";
        _city = address['city'] ?? address['regency'] ?? address['county'] ?? "";
        _fullAddress = data['display_name'] ?? "";

        setState(() {
          // Hanya tampilkan Kelurahan & Kota di UI agar elegan
          _addressInfo = "${_village.isNotEmpty ? '$_village, ' : ''}$_city";
        });
      }
    } catch (e) {
      debugPrint("Geocoding Error: $e");
    }
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
                      Text("Geser peta untuk menentukan titik presisi", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[500])),
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
                // MAP DENGAN STYLE POSITRON (CLEAN & ELEGANT)
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
                        urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.nyutji.app',
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
                
                // Custom Pin Marker (Elegant Design)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))]),
                        child: const Icon(LucideIcons.mapPin, color: Colors.white, size: 30),
                      ),
                      const SizedBox(height: 40), // Offset for pin point
                    ],
                  ),
                ),
                
                // Elegant Info Card
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
                        Text(_addressInfo, style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
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
                              backgroundColor: const Color(0xFF1E5655),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              elevation: 10,
                              shadowColor: const Color(0xFF1E5655).withOpacity(0.4),
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
                            child: Text("KONFIRMASI LOKASI", style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, letterSpacing: 1)),
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
