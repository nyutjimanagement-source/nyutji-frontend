import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../core/utils/nyutji_parser.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../data/services/api_service.dart';

class CourierProfileScreen extends ConsumerWidget {
  const CourierProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const Color textDark = Color(0xFF2D2A26);
    const Color textGrey = Color(0xFF78716C);
    
    final auth = ref.watch(authProvider);

    final Map<String, dynamic> t = {
      'id': {
        'active_vehicle': 'KENDARAAN AKTIF',
        'perf_title': 'PERFORMA MINGGU INI',
        'perf_completion': 'Penyelesaian',
        'perf_rating': 'Rating',
        'perf_average': 'Rata-rata',
        'settings': 'Pengaturan Akun',
        'security': 'Keamanan Server',
        'help': 'Pusat Bantuan',
        'about': 'Tentang Nyutji KL',
        'logout': 'Logout',
      }
    };

    final currentT = t['id'];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildVehicleCard(textDark, textGrey, currentT),
                const SizedBox(height: 24),
                _buildPerformanceSection(context, auth, textDark, textGrey, currentT),
                const SizedBox(height: 24),
                _buildMenuSection(context, ref, auth, textDark, currentT),
                SizedBox(height: 40 + MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Color textDark, Color textGrey, Map<String, dynamic> currentT) {
    return Container(
      padding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(16)),
            child: Icon(LucideIcons.bike, color: Colors.blue[700], size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(currentT['active_vehicle'], style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: textGrey, letterSpacing: 1)),
                Text(
                  "Honda Beat (B 3821 NYC)", 
                  style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey[300]),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection(BuildContext context, AuthProvider auth, Color textDark, Color textGrey, Map<String, dynamic> currentT) {
    final String rating = auth.user?['rating']?.toString() ?? "0.0";
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(currentT['perf_title'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: textDark, letterSpacing: 1)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _perfCounter("98%", currentT['perf_completion'], Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _perfCounter(rating, currentT['perf_rating'], Colors.amber[700]!, onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => _RatingReviewBottomSheet(auth: auth),
              );
            })),
            const SizedBox(width: 12),
            Expanded(child: _perfCounter("12min", currentT['perf_average'], Colors.blue)),
          ],
        ),
      ],
    );
  }

  Widget _perfCounter(String value, String label, Color color, {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Text(value, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
                const SizedBox(height: 4),
                Text(label, style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, WidgetRef ref, AuthProvider auth, Color textDark, Map<String, dynamic> currentT) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            _ExpandableSettingsMenu(currentT: currentT, auth: auth, textDark: textDark),
          const Divider(height: 1),
          _menuItem(LucideIcons.shield, currentT['security'], textDark),
          const Divider(height: 1),
          _menuItem(LucideIcons.headphones, currentT['help'], textDark),
          const Divider(height: 1),
          _menuItem(LucideIcons.info, currentT['about'], textDark),
          const Divider(height: 1),
          ListTile(
            onTap: () async {
              // 1. Mantra penghancur (Rule II.6) untuk memori cache transaksi.
              // Harus dieksekusi SEBELUM navigasi agar ref masih valid (mencegah StateError).
              ref.invalidate(orderProvider);
              ref.invalidate(walletProvider);
              
              // 2. Proses logout di auth (state direset eksplisit dengan delay 500ms internal
              //    agar mencegah flash glitch "Abang Kurir").
              await auth.logout();
              
              // 3. Navigasi kembali ke halaman login
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            leading: const Icon(LucideIcons.logOut, color: Colors.red, size: 18),
            title: Text(currentT['logout'], style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.red)),
            trailing: const Icon(LucideIcons.chevronRight, size: 14, color: Colors.grey),
          ),
        ],
      ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, Color textDark) {
    return ListTile(
      leading: Icon(icon, color: textDark, size: 18),
      title: Text(label, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: textDark)),
      trailing: const Icon(LucideIcons.chevronRight, size: 14, color: Colors.grey),
    );
  }
}

class _ExpandableSettingsMenu extends StatefulWidget {
  final Map<String, dynamic> currentT;
  final AuthProvider auth;
  final Color textDark;

  const _ExpandableSettingsMenu({
    required this.currentT,
    required this.auth,
    required this.textDark,
  });

  @override
  State<_ExpandableSettingsMenu> createState() => _ExpandableSettingsMenuState();
}

class _ExpandableSettingsMenuState extends State<_ExpandableSettingsMenu> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.auth.user;
    final String identifier = user?['identifier'] ?? '-';
    // Gunakan fallback cerdas jika data dinamis belum tersedia (tanpa perlu re-login)
    final String rating = user?['rating']?.toString() ?? "4.9"; 
    final String level = user?['level'] ?? "Senior"; 
    
    String partner = user?['mitra_recommendation']?.toString() ?? "";
    if (partner.isEmpty && user?['mitra_ref_id'] != null) {
      final mitraRefId = user!['mitra_ref_id'];
      try {
        final foundMitra = widget.auth.mitras.firstWhere(
          (m) => m['identifier'] == mitraRefId, 
          orElse: () => null
        );
        if (foundMitra != null) {
          partner = foundMitra['name'] ?? mitraRefId;
        } else {
          partner = mitraRefId;
        }
      } catch (_) {
        partner = mitraRefId;
      }
    }
    if (partner.isEmpty) partner = "Belum Ada Mitra";
    
    return Column(
      children: [
        ListTile(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          leading: Icon(LucideIcons.settings, color: widget.textDark, size: 18),
          title: Text(widget.currentT['settings'], style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: widget.textDark)),
          trailing: Icon(
            _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
            size: 14,
            color: Colors.grey,
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isExpanded
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(left: 52, right: 20, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow("ID Kurir", identifier),
                      const SizedBox(height: 8),
                      _buildDetailRow("Rating", "$rating \u2605"),
                      const SizedBox(height: 8),
                      _buildDetailRow("Level", level),
                      const SizedBox(height: 8),
                      _buildDetailRow("Mitra Utama", partner),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        const Text(" : ", style: TextStyle(fontSize: 11, color: Colors.grey)),
        Expanded(
          flex: 6,
          child: Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: widget.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
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
                      height: 380, // Ditingkatkan agar 3 item + tombol "Baca selengkapnya" muat
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
                              final int ratingVal = NyutjiParser.toDouble(rev['ratingCourier'] ?? rev['ratingMitra']).toInt();

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
                                          _ExpandableReviewText(
                                            text: rev['comment'] ?? 'Tidak ada komentar',
                                            customerName: customerName,
                                            ratingVal: ratingVal,
                                            parsedDate: parsedDate,
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
      children: List.generate(3, (index) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerLoading(width: 40, height: 40, borderRadius: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoading(width: 120, height: 16, borderRadius: 4),
                  SizedBox(height: 8),
                  ShimmerLoading(width: 80, height: 12, borderRadius: 4),
                  SizedBox(height: 12),
                  ShimmerLoading(width: double.infinity, height: 14, borderRadius: 4),
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
class _ExpandableReviewText extends StatelessWidget {
  final String text;
  final String customerName;
  final int ratingVal;
  final String parsedDate;

  const _ExpandableReviewText({
    required this.text,
    required this.customerName,
    required this.ratingVal,
    required this.parsedDate,
  });

  @override
  Widget build(BuildContext context) {
    if (text == 'Tidak ada komentar' || text.isEmpty) {
      return Text(
        text.isEmpty ? 'Tidak ada komentar' : text,
        style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF4B5563)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final style = GoogleFonts.montserrat(
          fontSize: 12, 
          fontWeight: FontWeight.w500, 
          color: const Color(0xFF4B5563),
        );
        final span = TextSpan(text: text, style: style);
        final tp = TextPainter(
          text: span,
          maxLines: 2,
          textDirection: TextDirection.ltr,
        );
        tp.layout(maxWidth: constraints.maxWidth);

        final bool isOverflowing = tp.didExceedMaxLines;

        if (!isOverflowing) {
          return Text(
            text,
            style: style,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );
        }

        return GestureDetector(
          onTap: () => _showReviewPopup(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: style,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                "Baca selengkapnya",
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReviewPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          elevation: 0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 16, right: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                              Text(
                                customerName,
                                style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1F2937)),
                              ),
                              const SizedBox(height: 4),
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      parsedDate,
                      style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          text,
                          style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF4B5563), height: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(LucideIcons.x, size: 18, color: Colors.red[700]),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
