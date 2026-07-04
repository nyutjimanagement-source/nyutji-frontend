import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/nyutji_theme.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

class MitraInventoryScreen extends ConsumerStatefulWidget {
  final VoidCallback onBackTap;
  const MitraInventoryScreen({super.key, required this.onBackTap});

  @override ConsumerState<MitraInventoryScreen> createState() => _MitraInventoryScreenState();
}

class _MitraInventoryScreenState extends ConsumerState<MitraInventoryScreen> {
  final Set<int> _expandedIndices = {};

  final List<Map<String, dynamic>> _inventoryData = [
    {
      "category": "Bahan Kimia & Kebersihan (Consumables)",
      "desc": "Stok yang dipantau mingguan (penggunaan tinggi)",
      "icon": LucideIcons.droplets,
      "items": [
        {"name": "Deterjen", "detail": "Bubuk dan cair (khusus mesin matik)"},
        {"name": "Pelembut & Pewangi", "detail": "Berbagai varian aroma (Softener)"},
        {"name": "Parfum Laundry", "detail": "Water-based atau alcohol-based"},
        {"name": "Pembersih Noda", "detail": "Darah, minyak, tinta, dan jamur"},
        {"name": "Pemutih (Bleach)", "detail": "Khusus pakaian putih"},
        {"name": "Penyerap Lembap", "detail": "Silica Gel (packing bed cover)"},
      ]
    },
    {
      "category": "Peralatan Operasional (Hardware)",
      "desc": "Barang investasi dengan maintenance rutin",
      "icon": LucideIcons.settings,
      "items": [
        {"name": "Mesin Cuci", "detail": "Front loading atau top loading"},
        {"name": "Mesin Pengering", "detail": "Dryer Gas atau Listrik"},
        {"name": "Setrika", "detail": "Uap Boiler atau Setrika Listrik"},
        {"name": "Meja Setrika", "detail": "Vacum table atau meja datar"},
        {"name": "Timbangan", "detail": "Timbangan Digital (satuan kg)"},
      ]
    },
    {
      "category": "Media Penyimpanan & Logistik",
      "desc": "Alat bantu pemindahan dan pemisahan pakaian",
      "icon": LucideIcons.truck,
      "items": [
        {"name": "Keranjang Pakaian", "detail": "Warna beda kotor/bersih"},
        {"name": "Hanger", "detail": "Gantungan baju dewasa/anak"},
        {"name": "Rak Sortir", "detail": "Pemisah antar pelanggan"},
        {"name": "Jemuran/Gawangan", "detail": "Untuk bahan sutra/karet"},
        {"name": "Tagging Gun & Label", "detail": "Penanda baju (nomor nota)"},
      ]
    },
    {
      "category": "Pengemasan (Packaging)",
      "desc": "Kebutuhan finishing dan packing",
      "icon": LucideIcons.package,
      "items": [
        {"name": "Plastik Packing", "detail": "Kecil, sedang, besar, bed cover"},
        {"name": "Tas Spunbond", "detail": "Opsi ramah lingkungan"},
        {"name": "Isolasi & Dispenser", "detail": "Penutup packing plastik"},
        {"name": "Nota/Kwitansi", "detail": "Manual atau Printer Thermal"},
      ]
    },
    {
      "category": "Perlengkapan Pendukung (Maintenance)",
      "desc": "Suplai pendukung operasional harian",
      "icon": LucideIcons.wrench,
      "items": [
        {"name": "Kelistrikan Ruangan Operasional", "detail": "Stabilitas daya listrik untuk Kebutuhan Mesin dan Keamanan sirkuit Power"},
        {"name": "Tabung Gas", "detail": "Untuk dryer/boiler gas"},
        {"name": "Tandon & Pompa", "detail": "Stabilitas suplai air"},
        {"name": "Filter Air", "detail": "Mencegah air kuning/berkerak"},
        {"name": "Sikat Pakaian", "detail": "Berbagai tingkat kekasaran"},
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        widget.onBackTap();
      },
      child: Column(
        children: [
          // HEADER SIMPLE (TEXT BASED)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: Colors.white,
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onBackTap,
                  child: const Row(
                    children: [
                      Icon(LucideIcons.arrowLeft, size: 24, color: NyutjiTheme.mlPrimary),
                      SizedBox(width: 4),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  "INVENTORY LAUNDRY",
                  style: NyutjiTheme.h2(NyutjiTheme.darkText).copyWith(fontSize: 13, letterSpacing: 0.5),
                ),
                const Spacer(),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ..._inventoryData.asMap().entries.map((entry) => _buildCategorySection(entry.value, entry.key)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(Map<String, dynamic> cat, int index) {
    final bool isExpanded = _expandedIndices.contains(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: NyutjiTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedIndices.remove(index);
                } else {
                  _expandedIndices.add(index);
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: NyutjiTheme.mlPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(cat['icon'], color: NyutjiTheme.mlPrimary, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat['category'],
                          style: GoogleFonts.montserrat(
                            fontSize: 13, 
                            fontWeight: FontWeight.w800, 
                            color: NyutjiTheme.darkText
                          ),
                        ),
                        Text(
                          cat['desc'],
                          style: NyutjiTheme.detail(NyutjiTheme.textGrey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, 
                    size: 18, 
                    color: NyutjiTheme.mlPrimary
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isExpanded ? SizedBox(
              width: double.infinity,
              child: Column(
              children: [
                const Divider(height: 1),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cat['items'].length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[50], indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final item = cat['items'][index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        item['name'],
                        style: NyutjiTheme.h3(NyutjiTheme.darkText).copyWith(fontSize: 13),
                      ),
                      subtitle: Text(
                        item['detail'],
                        style: NyutjiTheme.body(NyutjiTheme.textGrey).copyWith(fontSize: 11),
                      ),
                      trailing: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "UPDATE",
                          style: NyutjiTheme.actionLabel(NyutjiTheme.mlPrimary),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            )) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
