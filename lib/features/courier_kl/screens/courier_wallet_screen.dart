import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/simulasi_provider.dart';
import '../../../core/utils/formatters.dart';

class CourierWalletScreen extends StatelessWidget {
  const CourierWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF286B6A);
    const Color bgColor = Color(0xFFF8F4E6);
    const Color textDark = Color(0xFF2D2A26);
    const Color textGrey = Color(0xFF78716C);
    
    final auth = Provider.of<AuthProvider>(context);

    final Map<String, dynamic> t = {
      'id': {
        'wallet_title': 'Dompet Kurir',
        'active_balance': 'Saldo Aktif',
        'total_income': 'Total Pendapatan',
        'total_withdraw': 'Total Withdraw',
        'topup': 'Topup Saldo',
        'withdraw_btn': 'Tarik Saldo',
        'payout_status': 'STATUS PENCAIRAN',
        'processing': 'PROSES',
        'recent_transactions': 'TRANSAKSI TERBARU',
        'see_all': 'Liat Semua',
        'payout_est': 'Estimasi cair: Jumat, 15:00 WIB',
      },
      'en': {
        'wallet_title': 'Courier Wallet',
        'active_balance': 'Active Balance',
        'total_income': 'Total Earnings',
        'total_withdraw': 'Total Withdraw',
        'topup': 'Top-up Balance',
        'withdraw_btn': 'Withdraw Funds',
        'payout_status': 'PAYOUT STATUS',
        'processing': 'PROCESSING',
        'recent_transactions': 'RECENT TRANSACTIONS',
        'see_all': 'See All',
        'payout_est': 'Estimated: Friday, 15:00 WIB',
      },
    };

    final currentT = t[auth.lang] ?? t['id'];

    return Container(
      color: bgColor,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.rotateCcw, size: 18, color: Colors.red),
                      onPressed: () => context.read<SimulasiProvider>().resetSimulasi(),
                      tooltip: "Reset Simulasi",
                    ),
                  ],
                ),
                _buildBalanceCard(primaryTeal, currentT),
                const SizedBox(height: 16),
                _buildActionButtons(currentT, primaryTeal),
                const SizedBox(height: 24),
                _buildWithdrawStatusCard(currentT),
                const SizedBox(height: 24),
                _buildRecentTransactionsSection(textDark, textGrey, primaryTeal, currentT),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );
    }

  Widget _buildBalanceCard(Color primaryTeal, Map<String, dynamic> currentT) {
    return Consumer<SimulasiProvider>(
      builder: (context, sim, _) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: primaryTeal,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: primaryTeal.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currentT['active_balance'], style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(Formatters.currencyIdr(sim.saldoKL), style: GoogleFonts.montserrat(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> currentT, Color primaryTeal) {
    return Row(
      children: [
        Expanded(
          child: _actionBtn(LucideIcons.plusCircle, currentT['topup'], primaryTeal),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionBtn(LucideIcons.download, currentT['withdraw_btn'], const Color(0xFF10B981)),
        ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildWithdrawStatusCard(Map<String, dynamic> currentT) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(currentT['payout_status'], style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(8)),
                child: Text(currentT['processing'], style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.amber[900])),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(LucideIcons.clock, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Text(currentT['payout_est'], style: GoogleFonts.montserrat(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection(Color textDark, Color textGrey, Color primaryTeal, Map<String, dynamic> currentT) {
    return Consumer<SimulasiProvider>(
      builder: (context, sim, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(currentT['recent_transactions'], style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 12, color: textDark, letterSpacing: 1)),
              Text(currentT['see_all'], style: GoogleFonts.montserrat(fontSize: 11, color: primaryTeal, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          if (sim.mutasiKL.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text("Belum ada mutasi simulasi", style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey)),
            ))
          else
            ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: sim.mutasiKL.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final m = sim.mutasiKL[index];
                return _transactionCard(
                  m['title'],
                  m['date'],
                  "${m['type'] == 'debit' ? '-' : '+'} ${Formatters.currencyIdr((m['amount'] as num).abs().toDouble())}",
                  m['type'] == 'debit',
                  textDark, textGrey, primaryTeal
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _transactionCard(String title, String date, String amount, bool isOut, Color textDark, Color textGrey, Color primaryTeal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isOut ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOut ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft,
              color: isOut ? Colors.red : Colors.green,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 12, color: textDark),
                ),
                Text(
                  date,
                  style: GoogleFonts.montserrat(fontSize: 9, color: textGrey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w900, 
              fontSize: 12, 
              color: isOut ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
