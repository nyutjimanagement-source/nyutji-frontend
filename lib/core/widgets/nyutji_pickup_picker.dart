import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import 'nyutji_location_picker.dart';

/// Data hasil pilih lokasi penjemputan — sudah lengkap untuk dikirim ke backend
class NyutjiPickupResult {
  final String address;   // Alamat jalan (nama jalan saja)
  final String pickupNote;      // Sesuai kolom <orders.pickup_note>
  final String district;  // Kecamatan
  final String city;      // Kab/Kota
  final double lat;
  final double lng;

  const NyutjiPickupResult({
    required this.address,
    required this.pickupNote,
    required this.district,
    required this.city,
    required this.lat,
    required this.lng,
  });
}

/// Bottom sheet untuk memilih lokasi penjemputan.
/// Mengembalikan [NyutjiPickupResult] via Navigator.pop.
class NyutjiPickupPicker extends ConsumerStatefulWidget {
  final String? title;
  const NyutjiPickupPicker({super.key, this.title});

  @override ConsumerState<NyutjiPickupPicker> createState() => _NyutjiPickupPickerState();
}

class _NyutjiPickupPickerState extends ConsumerState<NyutjiPickupPicker> {
  static const _teal = Color(0xFF1E5655);

  Future<void> _pickFromMap(AuthProvider auth) async {
    // Buka peta DI ATAS sheet yang masih terbuka — JANGAN pop dulu
    final result = await showModalBottomSheet<NyutjiLocationResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NyutjiLocationPicker(),
    );

    if (result == null || !mounted) return;

    // Ambil nama jalan saja (potong sebelum koma pertama)
    final shortAddress = result.address.contains(',')
        ? result.address.split(',').first.trim()
        : result.address;

    // Pop sheet ini sekarang setelah data dari peta siap
    Navigator.pop(context, NyutjiPickupResult(
      address: shortAddress,
      pickupNote: result.street, // result.street adalah input ketikan user di peta
      district: result.subdistrict,
      city: result.city,
      lat: result.lat,
      lng: result.lng,
    ));
  }

  void _useHomeAddress(AuthProvider auth) {
    final home = auth.homeAddress;
    if (home == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada alamat rumah. Pilih via peta dulu.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    Navigator.pop(context, NyutjiPickupResult(
      address: home['street'] ?? home['address'] ?? '',
      pickupNote: home['detail'] ?? '',
      district: home['subdistrict'] ?? auth.user?['district_name']?.toString() ?? '',
      city: home['city'] ?? auth.user?['city_name']?.toString() ?? '',
      lat: double.tryParse(home['lat']?.toString() ?? '') ?? 0.0,
      lng: double.tryParse(home['lng']?.toString() ?? '') ?? 0.0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final home = auth.homeAddress;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 20),
          Text(widget.title ?? 'Pilih Lokasi Penjemputan', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: _teal)),
          const SizedBox(height: 20),

          // --- OPSI 1: Rumah Saya ---
          _optionTile(
            icon: LucideIcons.home,
            title: 'Rumah Saya',
            subtitle: home != null
                ? '${home['detail'] ?? ''} ${home['street'] ?? ''} · ${home['subdistrict'] ?? ''}'.trim()
                : 'Belum ada alamat rumah tersimpan',
            enabled: home != null,
            onTap: () => _useHomeAddress(auth),
          ),

          const Divider(height: 24),

          // --- OPSI 2: Pilih via Peta ---
          _optionTile(
            icon: LucideIcons.map,
            title: 'Pilih via Peta / GPS',
            subtitle: 'Geser pin ke lokasi yang tepat',
            enabled: true,
            onTap: () => _pickFromMap(auth),
          ),
        ],
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF0F7F7) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: enabled ? _teal.withValues(alpha: 0.15) : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: enabled ? _teal.withValues(alpha: 0.1) : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: enabled ? _teal : Colors.grey[400]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: enabled ? Colors.black87 : Colors.grey[400])),
                  const SizedBox(height: 3),
                  Text(subtitle, style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[500]), overflow: TextOverflow.ellipsis, maxLines: 1),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: enabled ? _teal : Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}
