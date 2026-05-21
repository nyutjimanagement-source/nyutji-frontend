import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/wallet_provider.dart';
import '../../../core/utils/formatters.dart';

class MitraWalletScreen extends StatefulWidget {
  const MitraWalletScreen({super.key});

  @override
  State<MitraWalletScreen> createState() => _MitraWalletScreenState();
}

class _MitraWalletScreenState extends State<MitraWalletScreen> {
  static const Color primaryTeal = Color(0xFF1E5655);
  static const Color darkText = Color(0xFF111827);
  static const Color bgColor = Color(0xFFF3F4F6);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildDenseHeader(context),
            const SizedBox(height: 16),
            _buildQuickActionAndRankRow(),
            const SizedBox(height: 16),
            _buildDenseStatsGrid(),
            const SizedBox(height: 16),
            _buildTransactionLogs(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDenseHeader(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, wallet, _) => Container(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
        decoration: const BoxDecoration(color: primaryTeal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Dompet Utama Mitra", style: GoogleFonts.montserrat(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)), child: Text("AKTIF", style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.greenAccent))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                wallet.isLoading && wallet.balance == 0
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                      )
                    : Text(Formatters.currencyIdr(wallet.balance), style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
                Text("Total Kredit", style: GoogleFonts.montserrat(fontSize: 10, color: Colors.white54)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionAndRankRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniAction(LucideIcons.arrowDownToLine, "Tarik", Colors.blue),
                  _buildMiniAction(LucideIcons.plusCircle, "Top-Up", Colors.green),
                  _buildMiniAction(LucideIcons.history, "Mutasi", Colors.orange),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber[200]!)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.trophy, size: 16, color: Colors.amber[700]),
                  const SizedBox(height: 4),
                  Text("Rank #4", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber[900])),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMiniAction(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, color: darkText)),
      ],
    );
  }

  Widget _buildDenseStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text("Laporan Keuangan Eksekutif", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: darkText)),
           const SizedBox(height: 12),
           GridView.count(
             crossAxisCount: 3,
             shrinkWrap: true,
             physics: const NeverScrollableScrollPhysics(),
             mainAxisSpacing: 8,
             crossAxisSpacing: 8,
             childAspectRatio: 1.4,
             children: [
                _buildStatPill("Total Transaksi", "Rp 12.5M", Colors.blue),
                _buildStatPill("Total Tarikan", "Rp 2.1M", Colors.red),
                _buildStatPill("Nominal Selesai", "Rp 10.4M", Colors.green),
                _buildStatPill("Nilai WIP", "Rp 850Rb", Colors.orange),
                _buildStatPill("Total Order", "145", primaryTeal),
                _buildStatPill("Total Kg", "420 Kg", Colors.indigo),
             ],
           )
        ],
      ),
    );
  }

  Widget _buildStatPill(String title, String val, Color c) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(width: 4, height: 4, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Expanded(child: Text(title, style: GoogleFonts.montserrat(fontSize: 8, color: Colors.grey[600], fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const Spacer(),
          Text(val, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: darkText, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _buildTransactionLogs() {
    return Consumer<WalletProvider>(
      builder: (context, wallet, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Mutasi Log", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: darkText)),
                  const Icon(LucideIcons.list, size: 14, color: Colors.blue),
                ],
              ),
              const Divider(),
              if (wallet.isLoading && wallet.mutasiList.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (wallet.mutasiList.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text("Belum ada mutasi transaksi", style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey)),
                  ),
                )
              else
                ...wallet.mutasiList.map((m) {
                  final amt = double.tryParse(m['amount'].toString()) ?? 0.0;
                  final type = (m['transaction_type'] ?? '').toString().toUpperCase();
                  final isOut = type == 'PAYMENT' || type == 'WITHDRAW' || type == 'FEE_PLATFORM' || amt < 0;
                  
                  String formattedDate = "-";
                  try {
                    DateTime dt = DateTime.tryParse(m['createdAt'] ?? m['date'] ?? '') ?? DateTime.now();
                    formattedDate = DateFormat('dd MMM, HH:mm').format(dt);
                  } catch (_) {}

                  return _buildLogItem(
                    m['description'] ?? m['title'] ?? type,
                    formattedDate,
                    "${isOut ? '-' : '+'} ${Formatters.currencyIdr(amt.abs())}",
                    isOut ? Colors.red : Colors.green,
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogItem(String title, String date, String amt, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: darkText)),
                Text(date, style: GoogleFonts.montserrat(fontSize: 8, color: Colors.grey[500])),
              ],
            ),
          ),
          Text(amt, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: c)),
        ],
      ),
    );
  }
}
