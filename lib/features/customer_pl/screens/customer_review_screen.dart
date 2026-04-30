import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/order_provider.dart';
import '../../../core/widgets/nyutji_notif.dart';

class CustomerReviewScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const CustomerReviewScreen({super.key, required this.order});

  @override
  State<CustomerReviewScreen> createState() => _CustomerReviewScreenState();
}

class _CustomerReviewScreenState extends State<CustomerReviewScreen> {
  final Color primaryTeal = const Color(0xFF1E5655);
  final Color accentGreen = const Color(0xFF22C55E);
  final Color darkBg = const Color(0xFF0F172A);

  int _ratingML = 5;
  int _ratingKL = 5;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _submitReview() {
    // Simulasi pengiriman review
    NyutjiNotif.showSuccess(context, "Terima kasih atas ulasan Anda!");
    
    // Bersihkan tracking state
    context.read<OrderProvider>().clearTracking();
    
    // Kembali ke layar utama (refresh/restart tab)
    Navigator.pushNamedAndRemoveUntil(context, '/customer_main', (route) => false);
  }

  Widget _buildStarRating(String title, int currentRating, Function(int) onRatingChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: darkBg)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < currentRating ? LucideIcons.star : LucideIcons.star,
                color: index < currentRating ? Colors.orange : Colors.grey[300],
                size: 32,
              ),
              onPressed: () => onRatingChanged(index + 1),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mitraName = widget.order['mitra'] ?? 'Mitra Laundry';
    final courierName = widget.order['courier'] ?? 'Kurir Laundry';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.x, color: darkBg),
          onPressed: _submitReview, // Bypass review
        ),
        title: Text("Penilaian Pesanan",
            style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, color: darkBg)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryTeal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.checkCircle, size: 64, color: primaryTeal),
            ),
            const SizedBox(height: 24),
            Text("Cucian Selesai!",
                style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w900, color: primaryTeal)),
            const SizedBox(height: 8),
            Text("Dana telah otomatis diteruskan ke Mitra dan Kurir. Bagaimana pelayanan mereka?",
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[600], height: 1.5)),
            const SizedBox(height: 40),

            // Rating Mitra
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildStarRating("Beri Nilai untuk $mitraName", _ratingML, (val) => setState(() => _ratingML = val)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Rating Kurir
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildStarRating("Beri Nilai untuk $courierName", _ratingKL, (val) => setState(() => _ratingKL = val)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Input Ulasan
            TextField(
              controller: _reviewController,
              maxLines: 4,
              style: GoogleFonts.montserrat(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Tuliskan pengalaman Anda...",
                hintStyle: GoogleFonts.montserrat(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: primaryTeal),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: primaryTeal.withValues(alpha: 0.4),
              ),
              child: Text("KIRIM ULASAN", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
