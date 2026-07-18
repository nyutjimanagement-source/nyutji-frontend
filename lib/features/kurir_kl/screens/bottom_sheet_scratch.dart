import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyutjimanagement/core/widgets/nyutji_dot.dart';
import 'package:nyutjimanagement/data/services/api_service.dart';
import 'package:nyutjimanagement/data/providers/auth_provider.dart';
import 'package:nyutjimanagement/core/widgets/nyutji_notif.dart';
import 'package:nyutjimanagement/core/widgets/shimmer_loading.dart';
import 'package:nyutjimanagement/core/utils/nyutji_parser.dart';

class _RatingReviewBottomSheet extends StatefulWidget {
  final AuthProvider auth;
  const _RatingReviewBottomSheet({required this.auth});

  @override
  State<_RatingReviewBottomSheet> createState() => _RatingReviewBottomSheetState();
}

class _RatingReviewBottomSheetState extends State<_RatingReviewBottomSheet> {
  bool _isLoading = true;
  List<dynamic> _reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    try {
      final reviews = await ApiService().getMyReviews();
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        NyutjiNotif.showError(context, "Gagal memuat review");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final String rating = widget.auth.user?['rating']?.toString() ?? "0.0";

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(top: 24, bottom: bottomPadding == 0 ? 24 : bottomPadding, left: 24, right: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(LucideIcons.star, color: Colors.amber[700], size: 28),
              const SizedBox(width: 12),
              Text(
                "Rating dan Review ($rating)",
                style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1F2937)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _isLoading
              ? _buildShimmer()
              : _reviews.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          "Belum ada review untuk Anda.",
                          style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 320, // Approx height for 3 items
                      child: PageView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: (_reviews.length / 3).ceil(),
                        itemBuilder: (context, pageIndex) {
                          final int startIndex = pageIndex * 3;
                          final int endIndex = (startIndex + 3 > _reviews.length) ? _reviews.length : startIndex + 3;
                          final List<dynamic> currentReviews = _reviews.sublist(startIndex, endIndex);

                          return ListView.separated(
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: currentReviews.length,
                            separatorBuilder: (context, index) => const Divider(height: 16),
                            itemBuilder: (context, index) {
                              final rev = currentReviews[index];
                              final customerName = rev['customer']?['name'] ?? 'Pelanggan';
                              final String dateRaw = rev['createdAt'] ?? '';
                              final String parsedDate = dateRaw.isNotEmpty 
                                ? _formatDate(dateRaw) 
                                : '';
                              final int ratingVal = NyutjiParser.toInt(rev['ratingCourier']);

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.blue[50],
                                      child: Text(
                                        customerName.substring(0, 1).toUpperCase(),
                                        style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.blue[700]),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  customerName,
                                                  style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1F2937)),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Row(
                                                children: List.generate(
                                                  5,
                                                  (starIdx) => Icon(
                                                    LucideIcons.star,
                                                    size: 14,
                                                    color: starIdx < ratingVal ? Colors.amber[700] : Colors.grey[300],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            parsedDate,
                                            style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            rev['comment'] ?? 'Tidak ada komentar',
                                            style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF4B5563)),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Column(
      children: List.generate(3, (index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerLoading(width: 40, height: 40, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerLoading(width: 120, height: 16, radius: 4),
                  const SizedBox(height: 8),
                  const ShimmerLoading(width: 80, height: 12, radius: 4),
                  const SizedBox(height: 12),
                  const ShimmerLoading(width: double.infinity, height: 14, radius: 4),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateStr;
    }
  }
}
