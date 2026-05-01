import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';

// --- MAIN SCREEN ---
class MitraOrderScreen extends StatefulWidget {
  const MitraOrderScreen({super.key});

  @override
  State<MitraOrderScreen> createState() => _MitraOrderScreenState();
}

class _MitraOrderScreenState extends State<MitraOrderScreen> {
  static const Color primaryTeal = Color(0xFF1E5655);
  static const Color bgColor = Color(0xFFF3F4F6);
  static const Color darkText = Color(0xFF111827);
  static const Color textGrey = Color(0xFF6B7280);
  
  String currentFilter = "Semua";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildCompactAppbar(),
      body: Consumer<OrderProvider>(
        builder: (context, orderProv, _) {
          final liveOrders = orderProv.activeOrders;
          
          // Filter logic
          final filtered = liveOrders.where((o) {
            if (currentFilter == "Semua") return true;
            if (currentFilter == "Baru") return o['status'] == 'SEARCHING' || o['status'] == 'WAITING_DROPOFF';
            if (currentFilter == "Same Day") return o['is_fast_track'] == true || o['serviceType'] == 'SAME_DAY';
            return true;
          }).toList();

          if (orderProv.isLoading && filtered.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: primaryTeal));
          }

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.clipboardList, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("Tidak ada pesanan", style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => orderProv.fetchOrders(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: filtered.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, idx) => _buildPremiumOrderCard(filtered[idx]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumOrderCard(dynamic o) {
    final status = o['status']?.toString() ?? 'UNKNOWN';
    final price = (o['total'] as num?)?.toDouble() ?? 0.0;
    final orderId = o['id']?.toString() ?? '-';
    final customerName = o['customer_name']?.toString() ?? 'Pelanggan';
    final courierName = o['courier_name']?.toString() ?? 'Belum Ada';
    final isFast = o['is_fast_track'] == true || o['service_type'] == 'SAME_DAY';
    final createdAt = o['created_at'] != null ? DateTime.parse(o['created_at']) : DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          // Header: ID & Status
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(orderId, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: textGrey, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(DateFormat('dd MMM yyyy, HH:mm').format(createdAt), style: GoogleFonts.montserrat(fontSize: 9, color: Colors.grey[400], fontWeight: FontWeight.w500)),
                  ],
                ),
                _buildStatusChip(status),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[50]),
          // Body: Customer & Items
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.user, color: primaryTeal, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(customerName, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: darkText))),
                          if (isFast) _buildBadge("FAST TRACK", Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(price),
                        style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: primaryTeal),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Footer: Courier & Actions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(LucideIcons.truck, size: 14, color: textGrey),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("KURIR KL", style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey[400])),
                          Text(courierName, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700, color: courierName == "Belum Ada" ? Colors.orange : darkText)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (status == 'SEARCHING' || status == 'WAITING_DROPOFF')
                  _buildActionButton(
                    "ASSIGN KURIR", 
                    Colors.orange[700]!, 
                    () => _showCourierPicker(orderId)
                  )
                else if (status != 'DONE' && status != 'selesai')
                  _buildActionButton(
                    "UPDATE STATUS", 
                    primaryTeal, 
                    () => _showStatusUpdater(orderId, status)
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.grey;
    String label = status;

    switch (status.toUpperCase()) {
      case 'SEARCHING': color = Colors.orange; label = "MENCARI KURIR"; break;
      case 'WAITING_DROPOFF': color = Colors.blue; label = "MENUNGGU DROP"; break;
      case 'COURIER_ACCEPTED': color = Colors.indigo; label = "KURIR DIAMBIL"; break;
      case 'PICKING_UP': color = Colors.teal; label = "DIJEMPUT"; break;
      case 'WASH_START': color = Colors.blue; label = "DICUCI"; break;
      case 'IN_PROGRESS': color = Colors.indigo; label = "PROSES"; break;
      case 'PACKING': color = Colors.purple; label = "PACKING"; break;
      case 'DELIVERING': color = Colors.teal; label = "DIANTAR"; break;
      case 'DONE': case 'PAID': color = Colors.green; label = "SELESAI"; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label, style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  void _showCourierPicker(String orderId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            final couriers = auth.couriers;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Tunjuk Kurir (Fast Track)", style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 18, color: darkText)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x, size: 20)),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Pilih kurir anggota untuk langsung mengambil tugas ini.", style: GoogleFonts.montserrat(fontSize: 12, color: textGrey)),
                const SizedBox(height: 20),
                if (couriers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text("Belum ada kurir yang bergabung.", style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500))),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: couriers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final k = couriers[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          tileColor: Colors.grey[50],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
                          leading: CircleAvatar(backgroundColor: primaryTeal.withValues(alpha: 0.1), child: const Icon(LucideIcons.user, color: primaryTeal, size: 18)),
                          title: Text(k['name'] ?? "Kurir", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkText)),
                          trailing: const Icon(LucideIcons.chevronRight, size: 16, color: textGrey),
                          onTap: () async {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            final provider = context.read<OrderProvider>();
                            Navigator.pop(context);
                            
                            final success = await provider.assignCourier(orderId, k['id']);
                            if (!mounted) return;
                            
                            if (success) {
                              _showBeautifulNotif("Berhasil menunjuk kurir!", true);
                            } else {
                              _showBeautifulNotif(provider.errorMessage ?? "Gagal", false);
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showStatusUpdater(String orderId, String currentStatus) {
    final stages = [
      'WAITING_DROPOFF', 'WASH_START', 'IN_PROGRESS', 'PACKING', 'DELIVERING', 'DONE'
    ];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Update Status Pesanan", style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 18, color: darkText)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: stages.map((s) {
                bool isCurrent = s == currentStatus;
                return ActionChip(
                  label: Text(s.replaceAll('_', ' ')),
                  backgroundColor: isCurrent ? primaryTeal : Colors.grey[100],
                  labelStyle: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: isCurrent ? Colors.white : textGrey),
                  onPressed: () async {
                    final provider = context.read<OrderProvider>();
                    Navigator.pop(context);
                    final success = await provider.updateOrderStatus(orderId, s);
                    if (!mounted) return;
                    if (success) {
                      _showBeautifulNotif("Status diperbarui ke $s", true);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showBeautifulNotif(String msg, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isSuccess ? LucideIcons.checkCircle : LucideIcons.alertCircle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(msg, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildBadge(String txt, MaterialColor color) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color[50], borderRadius: BorderRadius.circular(4), border: Border.all(color: color[200]!)),
      child: Text(txt, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: color[800], letterSpacing: 0.5)),
    );
  }

  PreferredSizeWidget _buildCompactAppbar() {
    return AppBar(
      backgroundColor: Colors.white, elevation: 0,
      automaticallyImplyLeading: false,
      title: Text("Manajemen Pesanan", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: darkText)),
      actions: [
        IconButton(onPressed: () => context.read<OrderProvider>().fetchOrders(), icon: const Icon(LucideIcons.refreshCw, size: 18, color: primaryTeal)),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          height: 50, color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ["Semua", "Baru", "Same Day"].map((f) => _buildFilterPill(f)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label) {
    bool isSel = currentFilter == label;
    return GestureDetector(
      onTap: () => setState(() => currentFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: isSel ? primaryTeal : Colors.grey[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: isSel ? primaryTeal : Colors.grey[200]!)),
        child: Text(label, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: isSel ? FontWeight.w900 : FontWeight.w600, color: isSel ? Colors.white : textGrey)),
      ),
    );
  }
}
