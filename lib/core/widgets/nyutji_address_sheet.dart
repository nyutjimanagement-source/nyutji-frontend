import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'nyutji_location_picker.dart';
import 'nyutji_notif.dart';

class NyutjiAddressSheet extends StatefulWidget {
  const NyutjiAddressSheet({super.key});

  @override
  State<NyutjiAddressSheet> createState() => _NyutjiAddressSheetState();
}

class _NyutjiAddressSheetState extends State<NyutjiAddressSheet> {
  final TextEditingController _detailController = TextEditingController();

  Future<void> _pickHomeAddress(AuthProvider auth) async {
    final result = await showModalBottomSheet<NyutjiLocationResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NyutjiLocationPicker(),
    );

    if (result != null) {
      // Tampilkan dialog untuk input Nomor Rumah / Gang
      _detailController.text = "";
      if (!mounted) return;
      bool? saved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Detail Tambahan", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
          content: TextField(
            controller: _detailController,
            decoration: InputDecoration(
              hintText: "Contoh: No. 12, Gang Mawar",
              hintStyle: GoogleFonts.montserrat(fontSize: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E5655), foregroundColor: Colors.white),
              child: const Text("Simpan"),
            ),
          ],
        ),
      );

      if (saved == true) {
        final success = await auth.saveHomeAddress({
          'lat': result.lat,
          'lng': result.lng,
          'address': result.address,
          'detail': _detailController.text,
          'district_name': result.subdistrict, // Gunakan Kecamatan sebagai rujukan District di DB
          'city_name': result.city,
          'village': result.district, // Kelurahan masuk ke info tambahan
          'street': result.street,
        });

        if (success && mounted) {
          NyutjiNotif.showSuccess(context, "Alamat Rumah Berhasil Disimpan & Diperbarui!");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final home = auth.homeAddress;
    final history = auth.addressHistory;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 24),
          Text("Alamat Tersimpan", style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF1E5655))),
          const SizedBox(height: 24),
          
          // RUMAH SENDIRI
          _header("Rumah Sendiri", LucideIcons.home),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[100]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: home != null 
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Rumah Utama", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text("${home['detail'] ?? ''} ${home['street'] ?? ''}", style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[800])),
                          Text("${home['subdistrict']}, ${home['city']}", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[500])),
                        ],
                      )
                    : Text("Belum ada alamat rumah diset", style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[400], fontStyle: FontStyle.italic)),
                ),
                IconButton(
                  onPressed: () => _pickHomeAddress(auth),
                  icon: Icon(home != null ? LucideIcons.edit3 : LucideIcons.plus, color: const Color(0xFF1E5655)),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF1E5655).withValues(alpha: 0.05)),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // HISTORY
          _header("History Alamat Penjemputan", LucideIcons.history),
          const SizedBox(height: 12),
          Expanded(
            child: history.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.mapPin, size: 40, color: Colors.grey[200]),
                      const SizedBox(height: 12),
                      Text("Belum Ada Alamat Penjemputan Lain", style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[400])),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: history.length,
                  separatorBuilder: (context, index) => const Divider(height: 24, color: Color(0xFFF3F4F6)),
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey[50], shape: BoxShape.circle), child: const Icon(LucideIcons.mapPin, size: 14, color: Colors.grey)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['street'] ?? 'Lokasi Terpilih', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(item['address'] ?? '', style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[500]), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        )
                      ],
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _header(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1E5655)),
        const SizedBox(width: 12),
        Text(title, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87)),
      ],
    );
  }
}
