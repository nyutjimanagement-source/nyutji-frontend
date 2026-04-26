import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../core/utils/formatters.dart';

class CustomerStatusScreen extends StatefulWidget {
  const CustomerStatusScreen({super.key});

  @override
  State<CustomerStatusScreen> createState() => _CustomerStatusScreenState();
}

class _CustomerStatusScreenState extends State<CustomerStatusScreen> {
  final Color primaryTeal = const Color(0xFF1E5655);
  final Color accentGreen = const Color(0xFF22C55E);
  final Color darkBg = const Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    // Memulai simulasi saat layar dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().startTrackingSimulation("KBY-040426-001");
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final order = orderProvider.trackingOrder;

    if (order == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildPremiumAppBar(order['id']),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  _buildMainStatusCard(order),
                  const SizedBox(height: 24),
                  _buildLiveTracker(order['progress']),
                  const SizedBox(height: 24),
                  _buildCourierCard(order),
                  const SizedBox(height: 24),
                  _buildOrderSummary(order),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumAppBar(String orderId) {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: Icon(LucideIcons.chevronLeft, color: darkBg),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "Lacak Pesanan #$orderId",
        style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: darkBg),
      ),
      centerTitle: true,
    );
  }

  Widget _buildMainStatusCard(Map<String, dynamic> order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryTeal,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: primaryTeal.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
        gradient: LinearGradient(
          colors: [primaryTeal, const Color(0xFF13413F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(LucideIcons.packageCheck, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            order['status'].toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            "Update terakhir: Baru saja",
            style: GoogleFonts.montserrat(fontSize: 12, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTracker(int currentProgress) {
    final List<Map<String, dynamic>> steps = [
      {'label': 'Dijemput', 'icon': LucideIcons.truck},
      {'label': 'Cuci', 'icon': LucideIcons.droplets},
      {'label': 'Jemur', 'icon': LucideIcons.sun},
      {'label': 'Setrika', 'icon': LucideIcons.wind},
      {'label': 'Kirim', 'icon': LucideIcons.navigation},
      {'label': 'Selesai', 'icon': LucideIcons.checkCircle},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text("Progres Laundry", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: darkBg)),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (index) {
              // Mapping 9 status simulation to 6 icons
              // 0-1: Dijemput, 2-3: Cuci, 4: Jemur, 5: Setrika, 6: Packing, 7: Kirim, 8: Selesai
              int mappedProgress = 0;
              if (currentProgress >= 8) mappedProgress = 5;
              else if (currentProgress >= 7) mappedProgress = 4;
              else if (currentProgress >= 5) mappedProgress = 3;
              else if (currentProgress >= 4) mappedProgress = 2;
              else if (currentProgress >= 3) mappedProgress = 1;
              else mappedProgress = 0;

              bool isDone = index <= mappedProgress;
              bool isActive = index == mappedProgress;
              
              return Expanded(
                child: Row(
                  children: [
                    _stepItem(steps[index]['label'], steps[index]['icon'], isDone, isActive),
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index < mappedProgress ? accentGreen : Colors.grey[100],
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _stepItem(String label, IconData icon, bool isDone, bool isActive) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDone ? accentGreen : Colors.grey[50],
            shape: BoxShape.circle,
            boxShadow: isActive ? [BoxShadow(color: accentGreen.withOpacity(0.4), blurRadius: 10, spreadRadius: 2)] : [],
          ),
          child: Icon(icon, size: 18, color: isDone ? Colors.white : Colors.grey[300]),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 9,
            fontWeight: isDone ? FontWeight.w800 : FontWeight.w500,
            color: isDone ? darkBg : Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildCourierCard(Map<String, dynamic> order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
            child: Icon(LucideIcons.user, color: primaryTeal),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order['courier'], style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: darkBg)),
                Text(order['plate'], style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: primaryTeal.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(LucideIcons.phone, size: 20, color: primaryTeal),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(Map<String, dynamic> order) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Detail Pesanan", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: darkBg)),
          const SizedBox(height: 16),
          _receiptRow(order['items'], Formatters.currencyIdr(order['total'])),
          _receiptRow("Biaya Pengantaran", "Rp 5.000"),
          const Divider(height: 32),
          _receiptRow("Total Pembayaran", Formatters.currencyIdr(order['total'] + 5000), isTotal: true),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500, color: isTotal ? darkBg : Colors.grey[600])),
          Text(value, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: isTotal ? accentGreen : darkBg)),
        ],
      ),
    );
  }
}
