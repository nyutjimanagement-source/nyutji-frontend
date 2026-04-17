import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../providers/issue_provider.dart';

class AdminIssuesScreen extends StatelessWidget {
  const AdminIssuesScreen({Key? key}) : super(key: key);

  static const Color darkGray = Color(0xFF111827);
  static const Color bgColor = Color(0xFFF3F4F6);


  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IssueProvider>();

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildDenseHeader(),
            _buildMapSection(),
            const SizedBox(height: 24),
            _buildLiveIssuesSection(provider),
            const SizedBox(height: 24),
            _buildOperationalReferences(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDenseHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
      width: double.infinity,
      color: darkGray,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "OPERATIONAL ISSUES",
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Manajemen Kendala Teknis dari Mitra (ML)",
            style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: darkGray,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        image: DecorationImage(
          image: NetworkImage("https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800&q=80"),
          fit: BoxFit.cover,
          opacity: 0.4,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sebaran Mitra (ML)",
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Peta interaktif seluruh Indonesia",
                  style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[300]),
                ),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Column(
                children: [
                  _buildMapControl(LucideIcons.zoomIn),
                  const SizedBox(height: 8),
                  _buildMapControl(LucideIcons.zoomOut),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMapControl(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
      ),
      child: Icon(icon, color: darkGray, size: 20),
    );
  }

  Widget _buildLiveIssuesSection(IssueProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Kendala & Gangguan ML",
                style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkGray),
              ),
              Text(
                "Lihat Semua",
                style: GoogleFonts.montserrat(fontSize: 11, color: Colors.red[600], fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFeaturedIssueCard(
            "Mesin Cuci Rusak (Area Depok)",
            "Berdampak pada 45 order reguler telat",
            LucideIcons.alertOctagon,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedIssueCard(String title, String desc, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red[900]),
                ),
                Text(
                  desc,
                  style: GoogleFonts.montserrat(fontSize: 10, color: Colors.red[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalReferences() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Referensi Operasional (ML/KL)",
            style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkGray),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _buildRefCard("SOP Kendala KL", LucideIcons.truck, Colors.blue),
              _buildRefCard("Panduan ML", LucideIcons.store, Colors.teal),
              _buildRefCard("Kontak Darurat", LucideIcons.phoneCall, Colors.orange),
              _buildRefCard("Log Bantuan", LucideIcons.clipboardList, Colors.indigo),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefCard(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: darkGray),
          ),
        ],
      ),
    );
  }
}
