import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class MitraPricingScreen extends StatefulWidget {
  final bool isReadOnly;
  final String? customName;

  const MitraPricingScreen({
    super.key, 
    this.isReadOnly = false,
    this.customName,
  });

  @override
  State<MitraPricingScreen> createState() => _MitraPricingScreenState();
}

class _MitraPricingScreenState extends State<MitraPricingScreen> {
  static const Color primaryTeal = Color(0xFF1E5655);
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color darkBg = Color(0xFF111827);
  
  final PageController _kiloanController = PageController();
  final PageController _satuanController = PageController();
  int _kiloanPage = 0;
  int _satuanPage = 0;

  // DUMMY DATA YANG LEBIH BANYAK UNTUK SIMULASI PAGING
  final List<Map<String, String>> kiloanData = [
    {"svc": "Cuci dan Setrika", "reg": "Rp 6.500/Kg", "fast": "Rp 15.000/Kg"},
    {"svc": "Cuci dan Lipat", "reg": "Rp 3.500/Kg", "fast": "Rp 10.000/Kg"},
    {"svc": "Setrika Wangi", "reg": "Rp 3.500/Kg", "fast": "Rp 15.000/Kg"},
    {"svc": "Express Kilat", "reg": "Rp 20.000/Kg", "fast": "Rp 35.000/Kg"},
    {"svc": "Tunggu", "reg": "Rp 10.000/Kg", "fast": "Rp 25.000/Kg"},
    {"svc": "Hanya Cuci", "reg": "Rp 2.500/Kg", "fast": "Rp 8.000/Kg"},
    {"svc": "Cuci Selimut", "reg": "Rp 15.000/Kg", "fast": "Rp 25.000/Kg"},
  ];

  final List<Map<String, String>> satuanData = [
    {"name": "Baju Anak", "price": "Rp 10.000/Pcs"},
    {"name": "Jas Formal", "price": "Rp 35.000/Pcs"},
    {"name": "Boneka Kecil 0-25cm", "price": "Rp 10.000/Pcs"},
    {"name": "Gordyn Tebal", "price": "Rp 10.000/Meter"},
    {"name": "Sneaker Dewasa", "price": "Rp 123.000/Pasang"},
    {"name": "Helm Retro", "price": "Rp 25.000/Pcs"},
    {"name": "Karpet Masjid", "price": "Rp 15.000/Meter"},
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final mitraName = widget.customName ?? (auth.user?['name'] ?? "Nyutji Mitra");

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildElegantHeader(mitraName),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Laundry Kiloan", LucideIcons.layers),
                  const SizedBox(height: 12),
                  _buildTableWrapper(_kiloanController, (idx) => setState(() => _kiloanPage = idx), kiloanData, true),
                  _buildPageIndicator(_kiloanPage, (kiloanData.length / 5).ceil()),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader("Laundry Satuan / Meteran", LucideIcons.shirt, hasSearch: true),
                  const SizedBox(height: 12),
                  _buildTableWrapper(_satuanController, (idx) => setState(() => _satuanPage = idx), satuanData, false),
                  _buildPageIndicator(_satuanPage, (satuanData.length / 5).ceil()),
                  const SizedBox(height: 32),
                  
                  _buildActionButtons(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildElegantHeader(String name) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: primaryTeal,
      leading: IconButton(
        icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "DAFTAR HARGA",
              style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white.withOpacity(0.9), letterSpacing: 1.5),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                name.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryTeal, Color(0xFF2D807E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {bool hasSearch = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: primaryTeal),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w800, color: darkBg)),
          ],
        ),
        Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (hasSearch) 
                IconButton(onPressed: () {}, icon: const Icon(LucideIcons.search, size: 18, color: Colors.grey), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              if (hasSearch) const SizedBox(width: 4),
              if (!widget.isReadOnly)
                IconButton(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.edit, size: 18, color: primaryTeal),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTableWrapper(PageController controller, Function(int) onPageChanged, List<Map<String, String>> data, bool isKiloan) {
    int totalPages = (data.length / 5).ceil();
    
    return Container(
      height: 235, // Adjusted for tighter rows - NO EMPTY SPACE
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: PageView.builder(
        controller: controller,
        onPageChanged: onPageChanged,
        itemCount: totalPages,
        itemBuilder: (context, pageIdx) {
          int start = pageIdx * 5;
          int end = (start + 5 > data.length) ? data.length : start + 5;
          List<Map<String, String>> pageData = data.sublist(start, end);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTableHeader(isKiloan ? ["Service", "Regular", "Fast Track"] : ["Nama Barang", "Harga"]),
              ...pageData.map((item) => isKiloan 
                ? _buildKiloanRow(item['svc']!, item['reg']!, item['fast']!)
                : _buildSatuanRow(item['name']!, item['price']!)
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTableHeader(List<String> titles) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
      child: Row(
        children: titles.map((t) => Expanded(
          flex: t == "Service" || t == "Nama Barang" ? 2 : 1,
          child: Text(
            t.toUpperCase(), 
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey[700], letterSpacing: 0.8)
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildKiloanRow(String svc, String reg, String fast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(svc, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: darkBg))),
          Expanded(child: Text(reg, textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: primaryTeal))),
          Expanded(child: Text(fast, textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: accentGold))),
        ],
      ),
    );
  }

  Widget _buildSatuanRow(String name, String price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(name, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: darkBg))),
          Expanded(
            child: Text(
              price, 
              textAlign: TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: primaryTeal)
            )
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int current, int count) {
    if (count <= 1) return const SizedBox(height: 12);
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (idx) => Container(
          width: 6, height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(color: current == idx ? primaryTeal : Colors.grey[300], shape: BoxShape.circle),
        )),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (widget.isReadOnly) return const SizedBox.shrink();
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildLuxuryButton("Upload XLS", LucideIcons.uploadCloud, primaryTeal)),
            const SizedBox(width: 12),
            Expanded(child: _buildLuxuryButton("Template", LucideIcons.download, Colors.blueGrey)),
          ],
        ),
        const SizedBox(height: 12),
        _buildLuxuryButton("Pamflet Promosi Discount", LucideIcons.megaphone, accentGold),
      ],
    );
  }

  Widget _buildLuxuryButton(String title, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 18),
        label: Text(title, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
