import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../core/theme/nyutji_theme.dart';
import '../../mitra_ml/screens/mitra_wallet_screen.dart';

class CourierWalletScreen extends StatefulWidget {
  const CourierWalletScreen({super.key});

  @override
  State<CourierWalletScreen> createState() => _CourierWalletScreenState();
}

class _CourierWalletScreenState extends State<CourierWalletScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallet();
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF286B6A);
    const Color bgColor = Color(0xFFF3F4F6);
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
                const SizedBox(height: 20),
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
    return Consumer<WalletProvider>(
      builder: (context, wallet, _) => Container(
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
            wallet.isLoading && wallet.balance == 0
                ? const SizedBox(
                    height: 32,
                    width: 32,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  )
                : Text(Formatters.currencyIdr(wallet.balance), style: GoogleFonts.montserrat(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> currentT, Color primaryTeal) {
    return Consumer<WalletProvider>(
      builder: (context, wallet, _) => Row(
        children: [
          Expanded(
            child: _actionBtn(LucideIcons.plusCircle, currentT['topup'], primaryTeal, onTap: () => _showTopUpSheet(context, wallet)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionBtn(LucideIcons.download, currentT['withdraw_btn'], const Color(0xFF10B981), onTap: () => _showTarikDanaModal(context, wallet)),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
      ),
    );
  }

  void _showTopUpSheet(BuildContext context, WalletProvider wallet) {
    final List<int> amounts = [50000, 100000, 200000, 300000, 500000, 1000000];
    int selectedAmount = amounts[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final itemWidth = (MediaQuery.of(ctx).size.width - 48 - 12) / 2;

            return Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pilih Nominal Top Up", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF131109))),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: amounts.map((amount) {
                      bool isSelected = selectedAmount == amount;
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => selectedAmount = amount),
                        child: Container(
                          width: itemWidth,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? NyutjiTheme.m3Primary : const Color(0xFFFFF9ED),
                            border: Border.all(color: isSelected ? NyutjiTheme.m3Primary : const Color(0xFFDAC66F), width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            Formatters.currencyIdr(amount),
                            style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, color: isSelected ? Colors.white : const Color(0xFF403600), fontSize: 13),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  
                  // Link Payment Gateway (Midtrans Snap)
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showMidtransSnapSimulation(context, selectedAmount);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: NyutjiTheme.m3Primary, width: 1.5),
                      ),
                      child: Center(
                        child: Text("Payment Gateway (Midtrans Snap)", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: NyutjiTheme.m3Primary, fontSize: 12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Link Simulasi Instan
                  InkWell(
                    onTap: () async {
                      Navigator.pop(ctx);
                      final ok = await wallet.forceTopup(selectedAmount.toDouble());
                      if (ok && context.mounted) {
                        NyutjiNotif.showSuccess(context, 'Top Up ${Formatters.currencyIdr(selectedAmount)} Berhasil!');
                      }
                    },
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text("Topup Instant (Simulasi)", style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: Colors.grey[600], fontSize: 12, decoration: TextDecoration.underline)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showMidtransSnapSimulation(BuildContext context, int amount) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Midtrans",
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Midtrans Sandbox", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.black87)),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(LucideIcons.x, size: 20, color: Colors.black87), 
                          onPressed: () => Navigator.pop(context)
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.smartphone, size: 60, color: NyutjiTheme.m3Primary),
                          const SizedBox(height: 16),
                          Text("Pop-up Midtrans Snap", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text("Tagihan: ${Formatters.currencyIdr(amount)}", style: GoogleFonts.montserrat(color: Colors.grey[600], fontSize: 14)),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.symmetric(horizontal: 30),
                            decoration: BoxDecoration(
                              color: NyutjiTheme.m3Primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Nantinya layar ini akan memuat Webview SDK resmi dari Midtrans untuk memilih metode pembayaran (VA, QRIS, e-Wallet).", 
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(fontSize: 11, color: NyutjiTheme.m3Primary, height: 1.5)
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  void _showTarikDanaModal(BuildContext context, WalletProvider wallet) {
    final auth = context.read<AuthProvider>();
    final userName = auth.user?['name'] ?? "Kurir";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TarikDanaModal(
        laundryName: userName,
        maxBalance: wallet.balance,
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
    return Consumer<WalletProvider>(
      builder: (context, wallet, _) => Column(
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
          if (wallet.isLoading && wallet.mutasiList.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(),
            ))
          else if (wallet.mutasiList.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text("Belum ada riwayat transaksi", style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey)),
            ))
          else
            ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: wallet.mutasiList.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final m = wallet.mutasiList[index];
                
                final amt = double.tryParse(m['amount'].toString()) ?? 0.0;
                final type = (m['transaction_type'] ?? m['type'] ?? '').toString().toUpperCase();
                final isOut = type == 'PAYMENT' || type == 'WITHDRAW' || type == 'FEE_PLATFORM' || type == 'DEBIT' || amt < 0;
                
                String formattedDate = "-";
                try {
                  DateTime dt = DateTime.tryParse(m['createdAt'] ?? m['date'] ?? '') ?? DateTime.now();
                  formattedDate = DateFormat('dd MMM, HH:mm').format(dt.toLocal());
                } catch (_) {}

                return _transactionCard(
                  m['description'] ?? m['title'] ?? type,
                  formattedDate,
                  "${isOut ? '-' : '+'} ${Formatters.currencyIdr(amt.abs())}",
                  isOut,
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
