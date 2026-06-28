import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../auth/screens/register_mitra_screen.dart';
import '../../auth/screens/register_kurir_screen.dart';
import '../../../core/theme/theme_util.dart';

class AdminTentangNyutjiScreen extends ConsumerWidget {
  const AdminTentangNyutjiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7EA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF4B4B4B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tentang Nyutji',
          style: GoogleFonts.montserrat(
            color: const Color(0xFF4B4B4B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: "System Kemitraan Laundry",
              icon: LucideIcons.store,
              color: const Color(0xFFC3312E),
              content: "Nyutji menyediakan sistem kemitraan laundry yang terintegrasi secara profesional. Mitra akan mendapatkan dukungan sistem manajemen, pelatihan, serta perlengkapan yang terstandarisasi untuk memberikan pelayanan terbaik bagi pelanggan.",
              linkText: "DAFTAR MITRA LAUNDRY",
              onLinkTap: () {
                Navigator.push(context, RetroRoute(page: const RegisterMitraScreen()));
              },
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: "System Kemitraan Kurir",
              icon: LucideIcons.truck,
              color: const Color(0xFFD35400),
              content: "Bergabunglah sebagai mitra kurir Nyutji dan jadilah bagian dari armada pengiriman kami yang efisien. Kami menawarkan fleksibilitas waktu kerja dan bagi hasil yang menguntungkan.",
              linkText: "DAFTAR MITRA KURIR",
              onLinkTap: () {
                Navigator.push(context, RetroRoute(page: const RegisterKurirScreen()));
              },
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: "System Nyuci Bersama:\nNyutji Management",
              icon: LucideIcons.users,
              color: const Color(0xFF286B6A),
              content: "Ekosistem Nyutji menyatukan pelanggan, mitra laundry, dan mitra kurir dalam satu platform manajemen terpadu yang transparan, mudah digunakan, dan memastikan kualitas layanan yang prima setiap saat.",
            ),
            const SizedBox(height: 40),
            Center(
              child: SizedBox(
                width: 120,
                child: Image.asset(
                  'assets/images/logo_nyutji.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.imageOff, size: 80, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Ny Utji Laundry v1.5.4',
                style: GoogleFonts.montserrat(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required Color color, required String content, String? linkText, VoidCallback? onLinkTap}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          if (linkText != null && onLinkTap != null) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: onLinkTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        linkText,
                        style: GoogleFonts.montserrat(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(LucideIcons.arrowRight, color: color, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
