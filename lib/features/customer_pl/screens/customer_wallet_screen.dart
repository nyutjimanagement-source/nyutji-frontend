import 'package:flutter/material.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../core/utils/formatters.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomerWalletScreen extends StatefulWidget {
  const CustomerWalletScreen({super.key});

  @override
  State<CustomerWalletScreen> createState() => _CustomerWalletScreenState();
}

class _CustomerWalletScreenState extends State<CustomerWalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallet();
    });
  }

  Map<String, List<dynamic>> _getGroupedMutasi(List<dynamic> mutasi) {
    Map<String, List<dynamic>> grouped = {};
    for (var m in mutasi) {
      DateTime date = DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now();
      String monthKey = DateFormat('MMMM yyyy', 'id_ID').format(date);
      if (!grouped.containsKey(monthKey)) {
        grouped[monthKey] = [];
      }
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
      backgroundColor: const Color(0xFFFFF9ED),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildPremiumHeader(currentT['title']),
            const SizedBox(height: 12),
            // CARD SALDO
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Consumer<WalletProvider>(
                builder: (context, wallet, _) => Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF403600), 
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: const Color(0xFF403600).withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))]
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(currentT['active_balance'], style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(Formatters.currencyIdr(wallet.balance), style: GoogleFonts.montserrat(color: const Color(0xFFDAC66F), fontSize: 24, fontWeight: FontWeight.w900)),
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
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF403600)))
                          : const Icon(LucideIcons.plus, size: 14),
                        label: Text(currentT['topup'], style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDAC66F), 
                          foregroundColor: const Color(0xFF403600), 
                          elevation: 0, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // MINI ANALYTICS CHART
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Consumer<WalletProvider>(
                builder: (context, wallet, _) => _buildAnalyticsCard(currentT, wallet),
              ),
            ),
            const SizedBox(height: 16),

            // RIWAYAT TRANSAKSI
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Consumer<WalletProvider>(
                builder: (context, wallet, _) {
                  final grouped = _getGroupedMutasi(wallet.mutasiList);
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: const Color(0xFFE3DCCF), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(currentT['history'], style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF131109))),
                        const Divider(height: 32, color: Color(0xFFE3DCCF)),
                        if (wallet.mutasiList.isEmpty)
                          Center(child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(LucideIcons.history, size: 40, color: Colors.grey[200]),
                                const SizedBox(height: 12),
                                Text("Belum ada riwayat transaksi", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[400])),
                              ],
                            ),
                          ))
                        else
                          ...grouped.entries.map((entry) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(entry.key, style: GoogleFonts.montserrat(fontSize: 10, color: const Color(0xFF403600), fontWeight: FontWeight.w900)),
                              ),
                              ...entry.value.map((m) {
                                    final amt = double.tryParse(m['amount'].toString()) ?? 0.0;
                                    final type = (m['transaction_type'] ?? '').toString().toUpperCase();
                                    final isOut = type == 'PAYMENT' || type == 'WITHDRAW' || type == 'FEE_PLATFORM' || amt < 0;
                                    
                                    return _buildHistoryRow(
                                      m['description'] ?? m['title'] ?? type,
                                      "${isOut ? '-' : '+'} ${Formatters.currencyIdr(amt.abs())}",
                                      isOut ? const Color(0xFFC3312E) : const Color(0xFF10B981),
                                      m['createdAt'] ?? m['date'] ?? '-',
                                    );
                                  }),
                              const SizedBox(height: 12),
                            ],
                          )),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(String title) {
    return ClipPath(
      clipper: WalletHeaderClipper(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 60),
        decoration: const BoxDecoration(color: Color(0xFF403600)),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            const SizedBox(width: 48), // Balancing
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
      final type = (m['transaction_type'] ?? '').toString().toUpperCase();
      final isOut = type == 'PAYMENT' || type == 'WITHDRAW' || type == 'FEE_PLATFORM' || amt < 0;
      
      if (isOut) {
        totalOut += amt.abs();
      } else {
        totalIn += amt;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE3DCCF), width: 1.5),
      ),
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
                Text(cT['cash_flow'], style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _chartLegend(const Color(0xFF10B981), "Masuk"),
                    const SizedBox(width: 16),
                    _chartLegend(const Color(0xFFC3312E), "Keluar"),
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
        Text(label, style: GoogleFonts.montserrat(fontSize: 10, color: const Color(0xFF131109), fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildHistoryRow(String title, String val, Color c, String date) {
    final bool isOut = val.startsWith('-');
    String formattedDate = "-";
    try {
      DateTime dt = DateTime.tryParse(date) ?? DateTime.now();
      formattedDate = DateFormat('dd MMM, HH:mm').format(dt);
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10), 
                decoration: BoxDecoration(color: c.withValues(alpha: 0.1), shape: BoxShape.circle), 
                child: Icon(isOut ? LucideIcons.arrowUp : LucideIcons.arrowDown, size: 14, color: c)
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF131109))),
                  Text(formattedDate, style: GoogleFonts.montserrat(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          Text(val, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: c)),
        ],
      ),
    );
  }
}

class WalletHeaderClipper extends CustomClipper<Path> {
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
    canvas.drawArc(rect, -3.1415926535 / 2, incomeAngle, true, Paint()..color = const Color(0xFF10B981));
    canvas.drawArc(rect, -3.1415926535 / 2 + incomeAngle, expenseAngle, true, Paint()..color = const Color(0xFFC3312E));
    
    canvas.drawCircle(size.center(Offset.zero), size.width / 3.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
