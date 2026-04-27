import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/simulasi_provider.dart';
import '../../../core/utils/formatters.dart';

class MitraWalletScreen extends StatelessWidget {
  const MitraWalletScreen({super.key});

  static const Color primaryTeal = Color(0xFF1E5655);
  static const Color darkText = Color(0xFF111827);
  static const Color bgColor = Color(0xFFF3F4F6);

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
    return Consumer<SimulasiProvider>(
      builder: (context, sim, _) => Container(
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
                    IconButton(
                      icon: const Icon(LucideIcons.rotateCcw, size: 16, color: Colors.white70),
                      onPressed: () => sim.resetSimulasi(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: Text("AKTIF", style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.greenAccent))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(Formatters.currencyIdr(sim.saldoML), style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
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
    return Consumer<SimulasiProvider>(
      builder: (context, sim, _) => Padding(
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
              if (sim.mutasiML.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text("Belum ada mutasi simulasi", style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey)),
                  ),
                )
              else
                ...sim.mutasiML.map((m) => _buildLogItem(
                      m['title'],
                      m['date'],
                      "${m['type'] == 'debit' ? '-' : '+'} ${Formatters.currencyIdr((m['amount'] as num).abs().toDouble())}",
                      m['type'] == 'debit' ? Colors.red : Colors.green,
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogItem(String title, String rid, String amt, Color c) {
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
                Text("Ref: $rid", style: GoogleFonts.montserrat(fontSize: 8, color: Colors.grey[500])),
              ],
            ),
          ),
          Text(amt, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: c)),
        ],
      ),
    );
  }
}
