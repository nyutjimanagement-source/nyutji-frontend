import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/widgets/nyutji_location_picker.dart';
import '../../../core/utils/nyutji_distance.dart';

class DistanceCalculatorScreen extends StatefulWidget {
  const DistanceCalculatorScreen({super.key});

  @override
  State<DistanceCalculatorScreen> createState() => _DistanceCalculatorScreenState();
}

class _DistanceCalculatorScreenState extends State<DistanceCalculatorScreen> {
  final Color primaryTeal = const Color(0xFF1E5655);
  
  // State Lokasi Jemput
  String _pickupAddress = "";
  double _pickupLat = 0.0;
  double _pickupLng = 0.0;
  
  // State Lokasi Mitra
  String _mitraAddress = "";
  double _mitraLat = 0.0;
  double _mitraLng = 0.0;

  double _calculatedDistance = 0.0;

  void _updateDistance() {
    setState(() {
      _calculatedDistance = NyutjiDistance.calculateDistance(
        _pickupLat, _pickupLng, _mitraLat, _mitraLng
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text("Distance Calculator", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: primaryTeal,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primaryTeal, const Color(0xFF2D7A78)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.gauge, color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Simulasi Jarak", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text("Ukur jarak jemput vs lokasi Mitra secara presisi.", style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // PICKUP LOCATION
            _buildSectionTitle("LOKASI JEMPUT (PL)"),
            _buildLocationSelector(
              address: _pickupAddress,
              onTap: () async {
                final result = await showModalBottomSheet<NyutjiLocationResult>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const NyutjiLocationPicker(),
                );
                if (result != null) {
                  setState(() {
                    _pickupAddress = result.address;
                    _pickupLat = result.lat;
                    _pickupLng = result.lng;
                  });
                  _updateDistance();
                }
              },
            ),
            
            const SizedBox(height: 20),
            
            // MITRA LOCATION
            _buildSectionTitle("LOKASI MITRA (ML)"),
            _buildLocationSelector(
              address: _mitraAddress,
              onTap: () async {
                final result = await showModalBottomSheet<NyutjiLocationResult>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const NyutjiLocationPicker(),
                );
                if (result != null) {
                  setState(() {
                    _mitraAddress = result.address;
                    _mitraLat = result.lat;
                    _mitraLng = result.lng;
                  });
                  _updateDistance();
                }
              },
            ),
            
            const SizedBox(height: 32),
            
            // RESULT CARD
            Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: primaryTeal.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 10))],
                ),
                child: Column(
                  children: [
                    Text("ESTIMASI JARAK", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 2)),
                    const SizedBox(height: 12),
                    Text(
                      NyutjiDistance.formatDistance(_calculatedDistance),
                      style: GoogleFonts.montserrat(fontSize: 48, fontWeight: FontWeight.w900, color: primaryTeal),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildSummaryRow(LucideIcons.mapPin, "Dari", _pickupAddress),
                    const SizedBox(height: 12),
                    _buildSummaryRow(LucideIcons.store, "Ke", _mitraAddress),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: primaryTeal, letterSpacing: 1)),
    );
  }

  Widget _buildLocationSelector({required String address, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryTeal.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.mapPin, size: 18, color: primaryTeal),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                address.isNotEmpty ? address : "Ketuk untuk pilih lokasi...",
                style: GoogleFonts.montserrat(fontSize: 12, color: address.isNotEmpty ? Colors.black87 : Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: primaryTeal.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: primaryTeal),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
              Text(value.isNotEmpty ? value : "Pilih Lokasi...", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        )
      ],
    );
  }
}
