import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/order_provider.dart';
import 'customer_order_screen.dart';
import '../../../core/utils/status_helper.dart';

class CustomerStatusScreen extends StatefulWidget {
  const CustomerStatusScreen({super.key});

  @override
  State<CustomerStatusScreen> createState() => _CustomerStatusScreenState();
}

class _CustomerStatusScreenState extends State<CustomerStatusScreen> {
  final Color primaryTeal = const Color(0xFF403600);
  final Color accentGreen = const Color(0xFF22C55E);
  final Color darkBg = const Color(0xFF131109);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrderProvider>().fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    if (orderProvider.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF9ED),
        body: Column(
          children: [
            _buildPremiumHeader("Status Pesanan"),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }

    if (orderProvider.activeOrders.isNotEmpty) {
      return _buildActiveOrdersList(orderProvider.activeOrders);
    }

    return _buildEmptyState();
  }

  Widget _buildPremiumHeader(String title, {bool showBack = true, String? subtitle}) {
    return ClipPath(
      clipper: HeaderClipper(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 50, 16, 70),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF403600), Color(0xFF5A4D00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showBack)
              IconButton(
                icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/customer_main', (route) => false),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle,
                        style: GoogleFonts.montserrat(fontSize: 14, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9ED),
      body: Column(
        children: [
          _buildPremiumHeader("Status Pesanan"),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: primaryTeal.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.package, size: 56, color: primaryTeal.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(height: 28),
                    Text("Belum Ada Pesanan Aktif",
                      style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, color: darkBg)),
                    const SizedBox(height: 10),
                    Text(
                      "Buat pesanan laundry pertamamu\ndan pantau statusnya di sini secara real-time.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600], height: 1.6),
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CustomerOrderScreen(orderType: 'pickup')),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        decoration: BoxDecoration(
                          color: primaryTeal,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [BoxShadow(color: primaryTeal.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
                        ),
                        child: Text("Buat Pesanan",
                          style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersList(List<dynamic> orders) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9ED),
      body: Column(
        children: [
          _buildPremiumHeader(
            "Status Pesanan",
            subtitle: "Ada ${orders.length} Pesanan Milik Anda"
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              physics: const BouncingScrollPhysics(),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                debugPrint("Nyutji Debug Order [$index]: ${order['order_number'] ?? order['orderNumber']} -> Keys: ${order.keys.toList()}");
                return PremiumOrderCard(order: order);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// PREMIUM ORDER CARD
// ─────────────────────────────────────────
class PremiumOrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  const PremiumOrderCard({super.key, required this.order});

  @override
  State<PremiumOrderCard> createState() => _PremiumOrderCardState();
}

class _PremiumOrderCardState extends State<PremiumOrderCard> {
  bool isExpanded = false;



  String _formatNyutjiDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == "-") return "-";
    try {
      DateTime? dt;
      if (dateStr.contains('T')) {
        dt = DateTime.tryParse(dateStr);
      } else if (dateStr.contains('/')) {
        final p = dateStr.split('/');
        dt = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
      } else if (dateStr.contains('-')) {
        final p = dateStr.split('-');
        if (p[0].length == 4) {
          dt = DateTime.tryParse(dateStr);
        } else {
          dt = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
        }
      }
      if (dt == null) return dateStr;
      final months = ['JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN', 'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES'];
      return "${dt.day.toString().padLeft(2, '0')}-${months[dt.month - 1]}";
    } catch (e) {
      return dateStr;
    }
  }

  String _getCourierStatusText(Map<String, dynamic> order) {
    final rawCourier = order['courier_name'] ?? order['courier'] ?? order['petugas_kurir'];
    if (rawCourier == null || rawCourier.toString().isEmpty || rawCourier.toString() == "null") {
      final status = (order['order_status'] ?? order['status'] ?? '').toString().toUpperCase();
      if (status.contains('SEARCHING')) return "Sedang Mencari Kurir";
      if (status.contains('WASH') || status.contains('PACK')) return "Kurir Tugas Lain";
      if (status.contains('PICKUP')) return "Kurir Menuju Ke Lokasi Anda";
      if (status.contains('DELIVERY')) return "Kurir Sedang Mengantar Cucian";
      return "Sedang Mencari Kurir";
    }
    // Parse format {name: ..., identifier: ...}
    final courierStr = rawCourier.toString();
    if (courierStr.contains('name:')) {
      try {
        final parts = courierStr.split('name:');
        if (parts.length > 1) {
          return parts[1].split(',')[0].replaceAll(RegExp(r'[{}]'), '').trim();
        }
      } catch (e) {
        return courierStr.replaceAll(RegExp(r'[{}]'), '').trim();
      }
    }
    return courierStr;
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isFastTrack = (order['is_fast_track'] ?? false).toString() == 'true' || 
                        order['service_type']?.toString().toLowerCase().contains('fast') == true;

    // 1. Logic totalQty & Unit (Genius Mapping)
    double totalQty = 0;
    String unit = "Kg";
    // Cek berbagai kemungkinan key dari backend (camelCase vs snake_case)
    final items = order['orderItems'] as List? ?? order['order_items'] as List? ?? order['items'] as List?;
    
    if (items != null && items.isNotEmpty) {
      for (var it in items) {
        totalQty += double.tryParse(it['qty']?.toString() ?? '0') ?? 0;
      }
      unit = items.first['unit']?.toString() ?? 'Kg';
    } else {
      totalQty = double.tryParse(order['total_qty']?.toString() ?? order['qty']?.toString() ?? '0') ?? 0;
      unit = order['unit']?.toString() ?? 'Kg';
    }

    // 2. Logic orderDate (Tgl Masuk)
    // Utamakan createdAt dari order, fallback ke items
    final rawDate = order['createdAt'] ?? order['created_at'] ?? (items != null && items.isNotEmpty ? items.first['created_at'] : null);
    final String orderDate = rawDate?.toString() ?? "-";

    // 3. Logic Tgl Selesai (done_at)
    final completionDate = order['done_at']?.toString() ?? order['doneAt']?.toString() ?? order['tgl_selesai']?.toString() ?? "-";

    // 4. Logic mitraName (Relasi Mitra)
    // Backend baru mengirimkan objek mitra: { name: "..." }
    final mitraName = (order['mitra'] is Map ? order['mitra']['name'] : null) ?? 
                      order['mitra_name'] ?? 
                      order['courier_name'] ?? 
                      order['petugas_kurir'] ?? "-";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3DCCF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF403600).withValues(alpha: 0.06), 
            blurRadius: 15, 
            offset: const Offset(0, 6)
          )
        ],
      ),
      child: Column(
        children: [
          // COLLAPSED
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isFastTrack 
                        ? [const Color(0xFFEF4444).withValues(alpha: 0.1), const Color(0xFFEF4444).withValues(alpha: 0.05)]
                        : [const Color(0xFF22C55E).withValues(alpha: 0.1), const Color(0xFF22C55E).withValues(alpha: 0.05)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Image.asset('assets/icons/icon_keranjang.png'),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${totalQty.toStringAsFixed(totalQty == totalQty.toInt() ? 0 : 1)} $unit - ${_formatNyutjiDate(orderDate)}",
                        style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF131109), letterSpacing: 0.3)
                      ),
                      const SizedBox(height: 4),
                      Text(
                        StatusHelper.getLabel(order['order_status'] ?? order['status'] ?? 'PROSES', 'PL'),
                        style: GoogleFonts.montserrat(fontSize: 16, color: const Color(0xFF403600), fontWeight: FontWeight.w500, letterSpacing: 1.0)
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatNyutjiDate(completionDate),
                      style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF403600))
                    ),
                    Text("EST. SELESAI", style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.grey[400], letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 20, color: const Color(0xFF403600).withValues(alpha: 0.5)),
                  onPressed: () => setState(() => isExpanded = !isExpanded),
                ),
              ],
            ),
          ),

          // EXPANDED
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Color(0xFFF3F0E9)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _detailCol("Tgl Masuk", _formatNyutjiDate(orderDate))),
                      const SizedBox(width: 10),
                      Expanded(child: _detailCol("Mitra Laundry", mitraName)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _detailCol("Tgl Selesai", _formatNyutjiDate(completionDate))),
                      const SizedBox(width: 10),
                      Expanded(child: _detailCol("Petugas Kurir", _getCourierStatusText(order))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // PROGRESS HEADER
                  Row(
                    children: [
                      Text("Progress Layanan", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF403600).withValues(alpha: 0.8))),
                      const SizedBox(width: 12),
                      const Expanded(child: Divider(color: Color(0xFFF3F0E9), thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // PROGRESS ICONS (Mewah & Clean)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildModernProgress("PickUp", LucideIcons.truck, true),
                      _buildModernProgress("Timbangan", LucideIcons.scale, false),
                      _buildModernProgress("Cuci", LucideIcons.droplets, false),
                      _buildModernProgress("Packing", LucideIcons.package, false),
                      _buildModernProgress("Kirim", LucideIcons.navigation, false),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernProgress(String label, IconData icon, bool isActive) {
    const Color activeColor = Color(0xFF403600);
    const Color inactiveColor = Color(0xFFE3DCCF);

    return Column(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? activeColor : inactiveColor, width: 1.5),
            boxShadow: isActive ? [BoxShadow(color: activeColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : null,
          ),
          child: Icon(icon, size: 18, color: isActive ? Colors.white : inactiveColor),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: isActive ? FontWeight.w900 : FontWeight.w600, color: isActive ? activeColor : Colors.grey[400])),
      ],
    );
  }

  Widget _detailCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF131109)), softWrap: true),
      ],
    );
  }
}

// ─────────────────────────────────────────
// HEADER CLIPPER
// ─────────────────────────────────────────
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    path.quadraticBezierTo(size.width / 2, size.height - 40, size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
