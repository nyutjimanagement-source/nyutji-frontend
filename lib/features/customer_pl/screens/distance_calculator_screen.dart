import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/nyutji_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/widgets/nyutji_location_picker.dart';
import '../../../core/utils/nyutji_distance.dart';
import '../../../providers/customer_theme_provider.dart';

class DistanceCalculatorScreen extends ConsumerStatefulWidget {
  const DistanceCalculatorScreen({super.key});

  @override ConsumerState<DistanceCalculatorScreen> createState() => _DistanceCalculatorScreenState();
}

class _DistanceCalculatorScreenState extends ConsumerState<DistanceCalculatorScreen> {
  
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
    final theme = ref.watch(customerThemeProvider);

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        title: Text("Distance Calculator", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16, color: theme.text)),
        backgroundColor: theme.cardBg,
        foregroundColor: theme.primary,
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
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.map, color: theme.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Jarak Garis Lurus", style: GoogleFonts.montserrat(color: theme.text.withValues(alpha: 0.6), fontSize: 12)),
                        Text("${_calculatedDistance.toStringAsFixed(1)} KM", style: GoogleFonts.montserrat(color: theme.primary, fontWeight: FontWeight.bold, fontSize: 24)),
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
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: theme.cardBg,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primary.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Text("NYUTJI ROAD DISTANCE (NRCF)", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: theme.primary, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    Text(
                      NyutjiDistance.formatDistance(NyutjiDistance.calculateRoadDistance(_calculatedDistance)),
                      style: GoogleFonts.montserrat(fontSize: 48, fontWeight: FontWeight.w900, color: theme.text),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Garis Lurus: ${NyutjiDistance.formatDistance(_calculatedDistance)}",
                      style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: theme.text.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(height: 24),
                    Divider(color: theme.text.withValues(alpha: 0.1)),
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
    final theme = ref.watch(customerThemeProvider);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: theme.primary, letterSpacing: 1)),
    );
  }

  Widget _buildLocationSelector({required String address, required VoidCallback onTap}) {
    final theme = ref.watch(customerThemeProvider);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.mapPin, size: 18, color: theme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                address.isNotEmpty ? address : "Ketuk untuk pilih lokasi...",
                style: GoogleFonts.montserrat(fontSize: 12, color: address.isNotEmpty ? theme.text : theme.text.withValues(alpha: 0.5)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: theme.primary.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    final theme = ref.watch(customerThemeProvider);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, color: theme.text.withValues(alpha: 0.5))),
              Text(value.isNotEmpty ? value : "Pilih Lokasi...", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: theme.text), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        )
      ],
    );
  }
}
