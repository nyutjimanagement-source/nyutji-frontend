import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

// --- MODELS ---

enum OrderStatus { diterima, cuci, setrika, packing, kirim, selesai }

class OrderItem {
  final String name;
  final double qty;
  final String unit;

  OrderItem({required this.name, required this.qty, required this.unit});
}

enum CustomerTier { vip, gold, reguler }

class Order {
  final String id;
  final String customer;
  final CustomerTier tier;
  final String type;
  OrderStatus status;
  final double price;
  final List<OrderItem> items;
  final String notes;
  final String courier;
  final DateTime deadline;

  Order({
    required this.id,
    required this.customer,
    required this.tier,
    required this.type,
    required this.status,
    required this.price,
    required this.items,
    this.notes = "",
    required this.courier,
    required this.deadline,
  });
}

// --- DUMMY DATA ---
final List<Order> orders = [
  Order(
    id: "KBY-040426-001",
    customer: "Ibu Rahmawati",
    tier: CustomerTier.vip,
    type: "Same Day",
    status: OrderStatus.cuci,
    items: [OrderItem(name: "Kemeja", qty: 3, unit: "pcs"), OrderItem(name: "Bed Cover", qty: 1, unit: "pcs")],
    notes: "Tolong lipat rapi",
    price: 85000,
    courier: "Joko",
    deadline: DateTime.now().add(const Duration(hours: 4)),
  ),
  Order(
    id: "KBY-040426-002",
    customer: "Bpk Santoso",
    tier: CustomerTier.gold,
    type: "Same Day",
    status: OrderStatus.setrika,
    items: [OrderItem(name: "Pakaian", qty: 2.5, unit: "kg")],
    notes: "Merah dipisah",
    price: 45000,
    courier: "Anton",
    deadline: DateTime.now().add(const Duration(hours: 6)),
  ),
  Order(
    id: "KBY-040426-003",
    customer: "Tiara",
    tier: CustomerTier.reguler,
    type: "Reguler",
    status: OrderStatus.diterima,
    items: [OrderItem(name: "Gorden", qty: 2, unit: "m")],
    notes: "",
    price: 120000,
    courier: "Agus",
    deadline: DateTime.now().add(const Duration(days: 2)),
  )
];

// --- MAIN SCREEN ---
class MitraOrderScreen extends StatefulWidget {
  const MitraOrderScreen({super.key});

  @override
  _MitraOrderScreenState createState() => _MitraOrderScreenState();
}

class _MitraOrderScreenState extends State<MitraOrderScreen> {
  static const Color primaryTeal = Color(0xFF1E5655);
  static const Color bgColor = Color(0xFFF3F4F6);
  static const Color darkText = Color(0xFF111827);
  static const Color textGrey = Color(0xFF6B7280);
  
  String currentFilter = "Semua";

  void _advanceOrder(Order order) {
    int nextIdx = OrderStatus.values.indexOf(order.status) + 1;
    if (nextIdx < OrderStatus.values.length) {
      setState(() {
        order.status = OrderStatus.values[nextIdx];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = orders.where((o) => currentFilter == "Semua" || o.type == currentFilter || (currentFilter == "Baru" && o.status == OrderStatus.diterima)).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildCompactAppbar(),
      body: Column(
        children: [
          _buildCompactFilterStrip(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              itemCount: filteredOrders.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, idx) => _buildDenseOrderRow(filteredOrders[idx]),
            ),
          )
        ],
      ),
    );
  }

  PreferredSizeWidget _buildCompactAppbar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.arrowLeft, color: darkText, size: 20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: primaryTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: const Icon(LucideIcons.listChecks, color: primaryTeal, size: 16),
          ),
          const SizedBox(width: 8),
          Text("Manajemen Pesanan", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: darkText)),
        ],
      ),
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(LucideIcons.search, color: darkText, size: 18)),
        IconButton(onPressed: () {}, icon: const Icon(LucideIcons.slidersHorizontal, color: darkText, size: 18)),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: Colors.grey[200])),
    );
  }

  Widget _buildCompactFilterStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(child: _buildFilterPill("Semua")),
          const SizedBox(width: 8),
          Expanded(child: _buildFilterPill("Baru")),
          const SizedBox(width: 8),
          Expanded(child: _buildFilterPill("Same Day")),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey[300]!)),
            child: const Icon(LucideIcons.calendar, size: 14, color: textGrey),
          )
        ],
      ),
    );
  }

  Widget _buildFilterPill(String label) {
    bool isSel = currentFilter == label;
    return GestureDetector(
      onTap: () => setState(() => currentFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: isSel ? primaryTeal : Colors.grey[100], borderRadius: BorderRadius.circular(6), border: Border.all(color: isSel ? primaryTeal : Colors.grey[300]!)),
        child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.w600, color: isSel ? Colors.white : textGrey)),
      ),
    );
  }

  Widget _buildDenseOrderRow(Order o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Color Bar
            Container(width: 6, decoration: BoxDecoration(color: _getStatusColor(o.status), borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ROW 1: Meta
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(o.id, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: textGrey)),
                            const SizedBox(width: 6),
                            if(o.tier == CustomerTier.vip) _buildBadge("VIP", Colors.amber),
                            if(o.type == "Same Day") ...[const SizedBox(width: 4), _buildBadge("STORM", Colors.red)],
                          ],
                        ),
                        Text(NumberFormat.currency(locale:'id_ID', symbol:'Rp', decimalDigits:0).format(o.price), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: primaryTeal)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // ROW 2: Customer & Time
                    Row(
                      children: [
                        const Icon(LucideIcons.user, size: 12, color: textGrey),
                        const SizedBox(width: 4),
                        Expanded(child: Text(o.customer, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: darkText))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(4)),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.clock, size: 10, color: Colors.red),
                              const SizedBox(width: 4),
                              Text("Sisa: ${_getRemainingTime(o.deadline)}", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red)),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 6),
                    // ROW 2.5: Courier Info
                    Row(
                      children: [
                        const Icon(LucideIcons.truck, size: 11, color: textGrey),
                        const SizedBox(width: 6),
                        Text("Kurir KL: ", style: GoogleFonts.inter(fontSize: 10, color: textGrey)),
                        Text(o.courier, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: primaryTeal)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // ROW 3: Dense Items List
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(6)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: o.items.map((i) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Container(width: 4, height: 4, decoration: const BoxDecoration(color: primaryTeal, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text("${i.name} - ${i.qty.toStringAsFixed(i.qty.truncateToDouble() == i.qty ? 0 : 1)} ${i.unit}", style: GoogleFonts.inter(fontSize: 10, color: darkText, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                    if(o.notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(LucideIcons.info, size: 10, color: Colors.orange),
                          const SizedBox(width: 4),
                          Expanded(child: Text('Catatan: "${o.notes}"', style: GoogleFonts.inter(fontSize: 9, fontStyle: FontStyle.italic, color: Colors.orange[800]))),
                        ],
                      )
                    ],
                    const SizedBox(height: 12),
                    // ROW 4: Action / Progress Tracker
                    _buildRowActionTracker(o),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowActionTracker(Order o) {
    if(o.status == OrderStatus.selesai) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
        child: Center(child: Text("SELESAI (Menunggu Pick-up Kurir)", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: textGrey))),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 28,
            decoration: BoxDecoration(color: _getStatusColor(o.status).withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: _getStatusColor(o.status).withOpacity(0.3))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_getStatusIcon(o.status), size: 12, color: _getStatusColor(o.status)),
                const SizedBox(width: 6),
                Text("STATUS: ${_getStatusName(o.status)}", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: _getStatusColor(o.status))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _advanceOrder(o),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryTeal, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            minimumSize: const Size(0, 28),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: Row(
            children: [
              Text("PROSES", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              const Icon(LucideIcons.chevronRight, size: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String txt, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(color: color[100], borderRadius: BorderRadius.circular(4), border: Border.all(color: color[400]!)),
      child: Text(txt, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: color[800], letterSpacing: 0.5)),
    );
  }

  Color _getStatusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.diterima: return Colors.orange;
      case OrderStatus.cuci: return Colors.blue;
      case OrderStatus.setrika: return Colors.indigo;
      case OrderStatus.packing: return Colors.purple;
      case OrderStatus.kirim: return Colors.teal;
      case OrderStatus.selesai: return Colors.green;
    }
  }

  String _getStatusName(OrderStatus s) {
    return s.toString().split('.').last.toUpperCase();
  }

  IconData _getStatusIcon(OrderStatus s) {
    switch (s) {
      case OrderStatus.diterima: return LucideIcons.inbox;
      case OrderStatus.cuci: return LucideIcons.droplets;
      case OrderStatus.setrika: return LucideIcons.sun;
      case OrderStatus.packing: return LucideIcons.package;
      case OrderStatus.kirim: return LucideIcons.truck;
      case OrderStatus.selesai: return LucideIcons.checkCircle;
    }
  }

  String _getRemainingTime(DateTime dl) {
    final diff = dl.difference(DateTime.now());
    if (diff.isNegative) return "Terlambat";
    if (diff.inHours > 24) return "${diff.inDays} Hari";
    return "${diff.inHours} Jam ${diff.inMinutes % 60} Menit";
  }
}
