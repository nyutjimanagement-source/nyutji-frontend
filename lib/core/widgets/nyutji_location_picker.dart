import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

class NyutjiLocationResult {
  final double lat;
  final double lng;
  final String district;
  final String city;

  NyutjiLocationResult({required this.lat, required this.lng, required this.district, required this.city});
}

class NyutjiLocationPicker extends StatefulWidget {
  const NyutjiLocationPicker({super.key});

  @override
  State<NyutjiLocationPicker> createState() => _NyutjiLocationPickerState();
}

class _NyutjiLocationPickerState extends State<NyutjiLocationPicker> {
  LatLng _currentLatLng = const LatLng(-6.2088, 106.8456); // Default Jakarta
  bool _isLoading = true;
  String _addressInfo = "Mencari lokasi...";
  String _currentDistrict = "";
  String _currentCity = "";

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
    _reverseGeocode(_currentLatLng);
  }

  Future<void> _reverseGeocode(LatLng point) async {
    try {
      final url = Uri.parse("https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1");
      final response = await http.get(url, headers: {'User-Agent': 'NyutjiApp'});
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        
        // Ekstraksi Kecamatan & Kota (Nominatim punya banyak field tergantung wilayah)
        String dist = address['subdistrict'] ?? address['village'] ?? address['suburb'] ?? "";
        String city = address['city'] ?? address['city_district'] ?? address['regency'] ?? "";

        setState(() {
          _currentDistrict = dist;
          _currentCity = city;
          _addressInfo = "$dist, $city";
        });
      }
    } catch (e) {
      debugPrint("Geocoding Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Pilih Lokasi Laundry", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x, size: 20)),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _currentLatLng,
                    initialZoom: 15.0,
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
                if (_isLoading)
                  Container(
                    color: Colors.white,
                    child: const Center(child: CircularProgressIndicator(color: Color(0xFF286B6A))),
                  ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 35),
                    child: Icon(LucideIcons.mapPin, color: Color(0xFFC3312E), size: 40),
                  ),
                ),
                Positioned(
                  bottom: 20, left: 20, right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Kecamatan & Kota Terpilih:", style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_addressInfo, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF286B6A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              Navigator.pop(context, NyutjiLocationResult(
                                lat: _currentLatLng.latitude,
                                lng: _currentLatLng.longitude,
                                district: _currentDistrict,
                                city: _currentCity
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
