import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/auth_provider.dart';

class MitraPricingScreen extends StatefulWidget {
  final bool isReadOnly;
  final bool isSelectionMode;
  final String? customName;
  final List<Map<String, dynamic>>? items; 
  final Map<int, int>? initialSelected; 

  const MitraPricingScreen({
    super.key, 
    this.isReadOnly = false,
    this.isSelectionMode = false,
    this.customName,
    this.items,
    this.initialSelected,
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

  // DATA STANDAR MITRA AUTO LAUNDRY CODE (SAMA DENGAN DATABASE/PL)
  final List<Map<String, String>> kiloanData = [
    {"svc": "Cuci dan Setrika", "reg": "Rp 7.000/Kg", "fast": "Rp 15.000/Kg"},
    {"svc": "Cuci dan Lipat", "reg": "Rp 4.000/Kg", "fast": "Rp 10.000/Kg"},
    {"svc": "Setrika Wangi", "reg": "Rp 4.000/Kg", "fast": "Rp 15.000/Kg"},
    {"svc": "Cuci Selimut Reguler", "reg": "Rp 15.000/Kg", "fast": "Rp 25.000/Kg"},
    {"svc": "Cuci Boneka Kiloan", "reg": "Rp 10.000/Kg", "fast": "Rp 25.000/Kg"},
  ];

  final List<Map<String, String>> satuanData = [
    {"name": "Jas Formal", "price": "Rp 45.000/Pcs"},
    {"name": "Bedcover King Size", "price": "Rp 50.000/Pcs"},
    {"name": "Sneaker Dewasa", "price": "Rp 35.000/Pasang"},
    {"name": "Gordyn Tebal", "price": "Rp 15.000/Meter"},
    {"name": "Baju Anak", "price": "Rp 10.000/Pcs"},
    {"name": "Tas Kulit", "price": "Rp 85.000/Pcs"},
    {"name": "Helm Full Face", "price": "Rp 30.000/Pcs"},
    {"name": "Karpet Masjid", "price": "Rp 15.000/Meter"},
    {"name": "Bantal Kepala Large", "price": "Rp 12.000/Pcs"},
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
                  _buildTableWrapper(_kiloanController, _kiloanPage, (idx) => setState(() => _kiloanPage = idx), _kiloanList, true),
                  _buildPageIndicator(_kiloanPage, (_kiloanList.length / 5).ceil()),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader("Laundry Satuan / Meteran", LucideIcons.shirt, hasSearch: true),
                  const SizedBox(height: 12),
                  _buildTableWrapper(_satuanController, _satuanPage, (idx) => setState(() => _satuanPage = idx), _satuanList, false),
                  _buildPageIndicator(_satuanPage, (_satuanList.length / 5).ceil()),
                  const SizedBox(height: 32),
                  
                  _buildActionButtons(),
                  if (widget.isSelectionMode) _buildSelectionConfirmButton(),
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

  List<Map<String, String>> get _kiloanList {
    if (widget.items != null) {
      return widget.items!
          .where((i) => i['category'] == 'Kiloan')
          .map((i) => {
                "id": i['id'].toString(),
                "svc": i['name'].toString(),
                "reg": "Rp ${i['price']}/Kg",
                "fast": "Rp ${(i['price'] * 1.5).round()}/Kg",
              })
          .toList();
    }
    return kiloanData;
  }

  List<Map<String, String>> get _satuanList {
    if (widget.items != null) {
       return widget.items!
          .where((i) => i['category'] == 'Satuan' || i['category'] == 'Express')
          .map((i) => {
                "id": i['id'].toString(),
                "name": i['name'].toString(),
                "price": "Rp ${i['price']}/${i['unit']}",
              })
          .toList();
    }
    return satuanData;
  }

  Widget _buildTableWrapper(PageController controller, int currentPage, Function(int) onPageChanged, List<Map<String, String>> data, bool isKiloan) {
    if (data.isEmpty) return const SizedBox(height: 100, child: Center(child: Text("Belum ada layanan")));
    int totalPages = (data.length / 5).ceil();
    
    // Fit the height perfectly dynamically for the CURRENT page
    int itemsRemaining = data.length - (currentPage * 5);
    int currentItemsCount = itemsRemaining > 5 ? 5 : (itemsRemaining < 0 ? 0 : itemsRemaining);
    // Asumsi height: Header ~40px, Row ~40-45px
    double tableHeight = (currentItemsCount * (isKiloan ? 46.0 : 42.0)) + 40.0;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: tableHeight,
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
              _buildTableHeader(isKiloan ? ["Pilih", "Service", "Regular", "Fast Track"] : ["Pilih", "Nama Barang", "Harga"]),
              ...pageData.asMap().entries.map((entry) {
                int itemId = int.tryParse(entry.value['id'] ?? "0") ?? 0;
                if (itemId == 0) {
                  int idx = start + entry.key;
                  itemId = isKiloan ? (1000 + idx) : (2000 + idx);
                }
                return isKiloan 
                  ? _buildKiloanRow(itemId, entry.value['svc']!, entry.value['reg']!, entry.value['fast']!)
                  : _buildSatuanRow(itemId, entry.value['name']!, entry.value['price']!);
              }),
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
        children: titles.map((t) {
          bool isCheck = t == "Pilih";
          if (isCheck && !widget.isSelectionMode) return const SizedBox.shrink();
          return Expanded(
            flex: isCheck ? 0 : (t == "Service" || t == "Nama Barang" ? 2 : 1),
            child: Container(
              width: isCheck ? 40 : null,
              alignment: isCheck ? Alignment.centerLeft : null,
              child: Text(
                isCheck ? "" : t.toUpperCase(), 
                textAlign: isCheck ? TextAlign.left : TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey[700], letterSpacing: 0.8)
              ),
            )
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKiloanRow(int id, String svc, String reg, String fast) {
    bool isSelected = (_selectedItems[id] ?? 0) > 0;
    return InkWell(
      onTap: widget.isSelectionMode ? () {
        setState(() => _selectedItems[id] = isSelected ? 0 : 1);
      } : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
        child: Row(
          children: [
            if (widget.isSelectionMode)
              SizedBox(
                width: 40,
                child: Checkbox(
                  value: isSelected,
                  activeColor: primaryTeal,
                  onChanged: (v) => setState(() => _selectedItems[id] = v! ? 1 : 0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            Expanded(flex: 2, child: Text(svc, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: darkBg))),
            Expanded(child: Text(reg, textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: primaryTeal))),
            Expanded(child: Text(fast, textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: accentGold))),
          ],
        ),
      ),
    );
  }

  Widget _buildSatuanRow(int id, String name, String price) {
    bool isSelected = (_selectedItems[id] ?? 0) > 0;
    return InkWell(
      onTap: widget.isSelectionMode ? () {
        setState(() => _selectedItems[id] = isSelected ? 0 : 1);
      } : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
        child: Row(
          children: [
            if (widget.isSelectionMode)
              SizedBox(
                width: 40,
                child: Checkbox(
                  value: isSelected,
                  activeColor: primaryTeal,
                  onChanged: (v) => setState(() => _selectedItems[id] = v! ? 1 : 0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
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
            Expanded(child: _buildLuxuryButton("Upload XLS", LucideIcons.uploadCloud, primaryTeal, () {})),
            const SizedBox(width: 12),
            Expanded(child: _buildLuxuryButton("Template", LucideIcons.download, Colors.blueGrey, () async {
              final url = Uri.parse('https://api.nyutji.com/storage/templates/Template_Layanan_Mitra.xlsx');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            })),
          ],
        ),
        const SizedBox(height: 12),
        _buildLuxuryButton("Pamflet Promosi Discount", LucideIcons.megaphone, accentGold, () {}),
      ],
    );
  }

  Widget _buildLuxuryButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
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

  // LOGIKA CONFIRMATION (REUSE)
  final Map<int, int> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialSelected != null) {
      _selectedItems.addAll(widget.initialSelected!);
    }
  }

  Widget _buildSelectionConfirmButton() {
    int total = _selectedItems.values.where((v) => v > 0).length;
    return Container(
      margin: const EdgeInsets.only(top: 20),
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context, _selectedItems),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        child: Text("Konfirmasi $total Item Dipilih", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
