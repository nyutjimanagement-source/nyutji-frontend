import 'package:flutter/material.dart';
import '../../../core/theme/nyutji_theme.dart';
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
  final Color primaryTeal = NyutjiTheme.m3Primary;
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

  bool _isSubmitting = false;

  void _submitReview() async {
    if (_isSubmitting) return;
    final orderId = (widget.order['orderNumber'] ?? widget.order['order_number'] ?? widget.order['id'] ?? '').toString();
    final orderProvider = context.read<OrderProvider>();
    final navigator = Navigator.of(context);

    setState(() => _isSubmitting = true);

    if (orderId.isNotEmpty) {
      await orderProvider.submitReview(
        orderId, 
        _ratingML, 
        _ratingKL, 
        _reviewController.text,
      );
    }

    if (!mounted) return;

    NyutjiNotif.showSuccess(context, "Terima kasih atas ulasan Anda!");
    
    // Bersihkan tracking state
    orderProvider.clearTracking();
    
    // Kembali ke layar utama (refresh/restart tab)
    navigator.pushNamedAndRemoveUntil('/customer_main', (route) => false);
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
                index < currentRating ? Icons.star : Icons.star_border,
                color: index < currentRating ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                size: 36,
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
    // Parser Nama Mitra
    final rawMitra = widget.order['mitra'];
    String mitraName = 'Mitra Laundry';
    if (rawMitra is Map) {
      mitraName = (rawMitra['name'] ?? rawMitra['nama'] ?? 'Mitra Laundry').toString();
    } else if (rawMitra != null && rawMitra.toString().isNotEmpty && rawMitra.toString() != "null") {
      mitraName = rawMitra.toString();
    } else {
      mitraName = (widget.order['mitra_name'] ?? 'Mitra Laundry').toString();
    }

    // Parser Nama Kurir
    final rawCourier = widget.order['courier'] ?? widget.order['courier_name'] ?? widget.order['petugas_kurir'];
    String courierName = 'Kurir Laundry';
    bool hasCourier = false;
    
    if (rawCourier is Map) {
      courierName = (rawCourier['name'] ?? rawCourier['nama'] ?? 'Kurir Laundry').toString();
      hasCourier = courierName != 'Kurir Laundry';
    } else if (rawCourier != null && rawCourier.toString().isNotEmpty && rawCourier.toString() != "null" && rawCourier.toString() != "-") {
      final courierStr = rawCourier.toString();
      if (courierStr.contains('name:')) {
        try {
          final parts = courierStr.split('name:');
          if (parts.length > 1) {
            courierName = parts[1].split(',')[0].replaceAll(RegExp(r'[{}]'), '').trim();
          } else {
            courierName = courierStr.replaceAll(RegExp(r'[{}]'), '').trim();
          }
        } catch (e) {
          courierName = courierStr.replaceAll(RegExp(r'[{}]'), '').trim();
        }
      } else {
        courierName = courierStr;
      }
      hasCourier = courierName.isNotEmpty;
    }

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
            Text("Bagaimana pelayanan mereka?",
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
                  _buildStarRating("Beri Nilai Mitra Laundry $mitraName", _ratingML, (val) => setState(() => _ratingML = val)),
                ],
              ),
            ),
            
            if (hasCourier) ...[
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
                    _buildStarRating("Beri Nilai Kurir $courierName", _ratingKL, (val) => setState(() => _ratingKL = val)),
                  ],
                ),
              ),
            ],
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
