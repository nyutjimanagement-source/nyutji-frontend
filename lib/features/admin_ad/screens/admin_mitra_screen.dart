import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminMitraScreen extends StatelessWidget {
  const AdminMitraScreen({super.key});

  static const Color primaryTeal = Color(0xFF286B6A);
  static const Color darkGray = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMapHeader(),
          const SizedBox(height: 24),
          _buildCategoryLevelling(),
          const SizedBox(height: 24),
          _buildGlobalRanking(),
          const SizedBox(height: 24),
          _buildIssueBoard(),
          const SizedBox(height: 24),
          _buildSocialCrawling(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMapHeader() {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: darkGray,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
        image: DecorationImage(
          image: NetworkImage("https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800&q=80"),
          fit: BoxFit.cover,
          opacity: 0.4,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Sebaran Mitra (ML)", style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              Text("Peta interaktif seluruh Indonesia", style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[400])),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Column(
                  children: [
                    FloatingActionButton.small(heroTag: "zoom_in", onPressed: () {}, backgroundColor: Colors.white, child: const Icon(LucideIcons.zoomIn, color: darkGray)),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(heroTag: "zoom_out", onPressed: () {}, backgroundColor: Colors.white, child: const Icon(LucideIcons.zoomOut, color: darkGray)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryLevelling() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber[200]!)),
              child: Column(
                children: [
                  const Icon(LucideIcons.barChart, color: Colors.amber, size: 28),
                  const SizedBox(height: 8),
                  Text("Leveling ML", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber[800])),
                  Text("Atur KPI & Syarat Naik Kelas", textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 9, color: Colors.amber[900]?.withValues(alpha: 0.8))),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue[200]!)),
              child: Column(
                children: [
                  const Icon(LucideIcons.tags, color: Colors.blue, size: 28),
                  const SizedBox(height: 8),
                  Text("Kategori ML", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                  Text("Kecil, Menengah, Enterprise", textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 9, color: Colors.blue[900]?.withValues(alpha: 0.8))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalRanking() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Ranking Performa Nasional", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkGray)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey[200]!)),
            child: Column(
              children: [
                _buildRankRow("Revenue Tertinggi", "Mitra Sudirman (Rp45M)", LucideIcons.trendingUp, Colors.green),
                const Divider(height: 24),
                _buildRankRow("Order Terbanyak", "Mitra Kebayoran (8,410)", LucideIcons.shoppingBag, Colors.orange),
                const Divider(height: 24),
                _buildRankRow("Proses Cuci Tercepat", "Mitra Tebet (1j 20m Avg)", LucideIcons.zap, Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankRow(String title, String val, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            Text(val, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: darkGray)),
          ],
        )
      ],
    );
  }

  Widget _buildIssueBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Kendala & Gangguan ML", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkGray)),
              Text("Lihat Semua", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.red[600], fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red[100]!)),
            child: Row(
              children: [
                const Icon(LucideIcons.alertOctagon, color: Colors.red, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Mesin Cuci Rusak (Area Depok)", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red[900])),
                      Text("Berdampak pada 45 order reguler telat", style: GoogleFonts.montserrat(fontSize: 10, color: Colors.red[700])),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSocialCrawling() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Sentimen Sosial (Crawling AI)", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkGray)),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildCrawlCard("Trending TWT", "Pujian untuk CS Nyutji Management", "Positif", Colors.green),
                const SizedBox(width: 12),
                _buildCrawlCard("Berita Online", "Revolusi Bisnis Laundry lewat ML", "Netral", Colors.blue),
                const SizedBox(width: 12),
                _buildCrawlCard("Laporan IG", "Kurir nyasar di area Bekasi Utama", "Negatif", Colors.orange),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCrawlCard(String source, String desc, String sentiment, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(source, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                child: Text(sentiment, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(desc, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: darkGray), maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
