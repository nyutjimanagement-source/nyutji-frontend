import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/simulasi_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../core/utils/formatters.dart';
import 'package:intl/intl.dart';

class CustomerWalletScreen extends StatefulWidget {
  const CustomerWalletScreen({super.key});

  @override
  State<CustomerWalletScreen> createState() => _CustomerWalletScreenState();
}

class _CustomerWalletScreenState extends State<CustomerWalletScreen> {
  final Color primaryTeal = const Color(0xFF1E5655);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallet();
    });
  }

  // HELPER: Mengelompokkan mutasi berdasarkan bulan
  Map<String, List<dynamic>> _getGroupedMutasi(List<dynamic> mutasi) {
    Map<String, List<dynamic>> grouped = {};
    for (var m in mutasi) {
      DateTime date = DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now();
      String monthKey = DateFormat('MMMM yyyy', 'id_ID').format(date);
      if (!grouped.containsKey(monthKey)) grouped[monthKey] = [];
      grouped[monthKey]!.add(m);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final Map<String, dynamic> t = {
      'id': {
        'title': 'Dompet Nyutji',
        'active_balance': 'Saldo Aktif',
        'topup': 'Top Up',
        'history': 'Riwayat Terakhir',
        'pay_wash': 'Bayar Cuci',
        'cash_flow': 'Arus Kas (1 Tahun)',
      },
      'en': {
        'title': 'Nyutji Wallet',
        'active_balance': 'Active Balance',
        'topup': 'Top Up',
        'history': 'Recent History',
        'pay_wash': 'Laundry Payment',
        'cash_flow': 'Cash Flow (1 Year)',
      }
    };
    final currentT = t[auth.lang] ?? t['id'];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(currentT['title'], style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // CARD SALDO
            Consumer<WalletProvider>(
              builder: (context, wallet, _) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryTeal, 
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: primaryTeal.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))]
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(currentT['active_balance'], style: GoogleFonts.montserrat(fontSize: 11, color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(Formatters.currencyIdr(wallet.balance), style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: wallet.isLoading ? null : () async {
                        final ok = await wallet.forceTopup(1000000);
                        if(ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Topup Berhasil (Simulation)'), behavior: SnackBarBehavior.floating)
                          );
                        }
                      },
                      icon: wallet.isLoading 
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Icon(LucideIcons.plus, size: 14),
                      label: Text(currentT['topup'], style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black87, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // MINI ANALYTICS CHART
            Consumer<WalletProvider>(
              builder: (context, wallet, _) => _buildAnalyticsCard(currentT, wallet),
            ),
            const SizedBox(height: 16),

            // RIWAYAT TRANSAKSI
            Consumer<WalletProvider>(
              builder: (context, wallet, _) {
                final grouped = _getGroupedMutasi(wallet.mutasiList);
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentT['history'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold)),
                      const Divider(height: 24),
                      if (wallet.mutasiList.isEmpty)
                        Center(child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text("Belum ada riwayat transaksi", style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey)),
                        ))
                      else
                        ...grouped.entries.map((entry) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(entry.key, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: primaryTeal)),
                            ),
                            ...entry.value.map((m) => _buildHistoryRow(
                                  m['description'] ?? m['title'] ?? 'Transaksi',
                                  "${m['type'] == 'debit' ? '-' : '+'} ${Formatters.currencyIdr(double.tryParse(m['amount'].toString()) ?? 0.0)}",
                                  m['type'] == 'debit' ? Colors.red : Colors.green,
                                  m['createdAt'] ?? m['date'] ?? '-',
                                )),
                            const SizedBox(height: 8),
                          ],
                        )).toList(),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(Map<String, dynamic> cT, WalletProvider wallet) {
    double totalIn = 0;
    double totalOut = 0;
    for (var m in wallet.mutasiList) {
      double amt = double.tryParse(m['amount'].toString()) ?? 0.0;
      if (m['type'] == 'debit') totalOut += amt;
      else totalIn += amt;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        children: [
          SizedBox(
            width: 50, height: 50,
            child: CustomPaint(painter: MiniPiePainter(totalIn, totalOut)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cT['cash_flow'], style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _chartLegend(Colors.green, "Masuk"),
                    const SizedBox(width: 12),
                    _chartLegend(Colors.red, "Keluar"),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _chartLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54)),
      ],
    );
  }

  Widget _buildHistoryRow(String title, String val, Color c, String date) {
    final bool isOut = c == Colors.red;
    String formattedDate = "-";
    try {
      DateTime dt = DateTime.tryParse(date) ?? DateTime.now();
      formattedDate = DateFormat('dd MMM, HH:mm').format(dt);
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8), 
                decoration: BoxDecoration(color: c.withValues(alpha: 0.1), shape: BoxShape.circle), 
                child: Icon(isOut ? LucideIcons.arrowUp : LucideIcons.arrowDown, size: 14, color: c)
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87)),
                  Text(formattedDate, style: GoogleFonts.montserrat(fontSize: 9, color: Colors.grey[500])),
                ],
              ),
            ],
          ),
          Text(val, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: c)),
        ],
      ),
    );
  }
}

class MiniPiePainter extends CustomPainter {
  final double income;
  final double expense;
  MiniPiePainter(this.income, this.expense);

  @override
  void paint(Canvas canvas, Size size) {
    double total = income + expense;
    if (total == 0) {
      canvas.drawCircle(size.center(Offset.zero), size.width / 2, Paint()..color = Colors.grey[200]!);
      return;
    }

    double incomeAngle = (income / total) * 2 * 3.1415926535;
    double expenseAngle = (expense / total) * 2 * 3.1415926535;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(rect, -3.1415926535 / 2, incomeAngle, true, Paint()..color = Colors.green);
    canvas.drawArc(rect, -3.1415926535 / 2 + incomeAngle, expenseAngle, true, Paint()..color = Colors.red);
    
    // Draw hole for donut style
    canvas.drawCircle(size.center(Offset.zero), size.width / 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

