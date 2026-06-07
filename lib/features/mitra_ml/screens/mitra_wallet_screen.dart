import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../providers/wallet_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/screens/pin_screen.dart' as pin_screen;
import 'mitra_profile_screen.dart';

class MitraWalletScreen extends StatefulWidget {
  const MitraWalletScreen({super.key});

  @override
  State<MitraWalletScreen> createState() => _MitraWalletScreenState();
}

class _MitraWalletScreenState extends State<MitraWalletScreen> {
  static const Color primaryTeal = Color(0xFF1E5655);
  static const Color darkText = Color(0xFF111827);
  static const Color bgColor = Color(0xFFF3F4F6);

  String _selectedFilter = 'Mingguan'; 
  final List<String> _filters = ['Harian', 'Mingguan', 'Bulanan', 'Tahunan'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallet();
      context.read<OrderProvider>().fetchOrders();
    });
  }

  // --- CALCULATIONS ---

  double _calculateTotalCash(List<dynamic> logs, String type) {
    double total = 0.0;
    for (var m in logs) {
      final tType = (m['type'] ?? m['transaction_type'] ?? '').toString().toUpperCase();
      if (tType == type.toUpperCase()) {
        total += double.tryParse(m['amount']?.toString() ?? '0') ?? 0.0;
      }
    }
    return total;
  }

  double _calculateWIP(List<dynamic> activeOrders) {
    double total = 0.0;
    for (var o in activeOrders) {
      total += double.tryParse((o['servicePrice'] ?? o['service_price'] ?? o['total_price'] ?? o['totalPrice'] ?? '0').toString()) ?? 0.0;
    }
    return total;
  }

  double _calculateTotalKg(List<dynamic> allOrders) {
    double total = 0.0;
    for (var o in allOrders) {
      final items = o['orderItems'] ?? o['order_items'] ?? o['items'] ?? [];
      if (items is List) {
        for (var it in items) {
          final String unit = (it['unit']?.toString() ?? '').toUpperCase();
          if (unit == 'KG' || unit.contains('KILO')) {
            total += double.tryParse(it['qty']?.toString() ?? '0') ?? 0.0;
          }
        }
      }
    }
    return total;
  }

  double _calculateAverageRating(List<dynamic> historyOrders) {
    double totalRating = 0.0;
    int count = 0;
    for (var o in historyOrders) {
      final reviews = o['reviews'] ?? o['review'];
      if (reviews != null) {
        if (reviews is List && reviews.isNotEmpty) {
          final rating = double.tryParse((reviews.first['rating_mitra'] ?? reviews.first['ratingMitra'])?.toString() ?? '0') ?? 0.0;
          if (rating > 0) {
            totalRating += rating;
            count++;
          }
        } else if (reviews is Map) {
          final rating = double.tryParse((reviews['rating_mitra'] ?? reviews['ratingMitra'])?.toString() ?? '0') ?? 0.0;
          if (rating > 0) {
            totalRating += rating;
            count++;
          }
        }
      } else {
        final rating = double.tryParse((o['rating_mitra'] ?? o['ratingMitra'])?.toString() ?? '0') ?? 0.0;
        if (rating > 0) {
          totalRating += rating;
          count++;
        }
      }
    }
    return count > 0 ? totalRating / count : 0.0;
  }

  // --- FILTER LOGIC ---
  List<Map<String, dynamic>> _generateFilteredData(List<dynamic> logs, List<dynamic> orders) {
    Map<String, Map<String, dynamic>> grouped = {};

    // Group Orders
    for (var o in orders) {
      DateTime dt;
      try {
        final raw = o['createdAt'] ?? o['created_at'] ?? o['order_date'] ?? o['orderDate'];
        dt = raw != null ? DateTime.parse(raw.toString()).toLocal() : DateTime.now();
      } catch (_) { dt = DateTime.now(); }

      String key = _getGroupKey(dt);
      if (!grouped.containsKey(key)) grouped[key] = {'orders': 0, 'revenue': 0.0, 'sortDate': dt};
      grouped[key]!['orders'] = (grouped[key]!['orders'] as int) + 1;
      if (dt.isBefore(grouped[key]!['sortDate'])) grouped[key]!['sortDate'] = dt;
    }

    // Group Revenues
    for (var m in logs) {
      final tType = (m['type'] ?? m['transaction_type'] ?? '').toString().toUpperCase();
      if (tType != 'CREDIT' && tType != 'REVENUE') continue;
      
      DateTime dt;
      try {
        final raw = m['createdAt'] ?? m['created_at'] ?? m['date'];
        dt = raw != null ? DateTime.parse(raw.toString()).toLocal() : DateTime.now();
      } catch (_) { dt = DateTime.now(); }

      String key = _getGroupKey(dt);
      if (!grouped.containsKey(key)) grouped[key] = {'orders': 0, 'revenue': 0.0, 'sortDate': dt};
      
      final amt = double.tryParse(m['amount']?.toString() ?? '0') ?? 0.0;
      grouped[key]!['revenue'] = (grouped[key]!['revenue'] as double) + amt;
      if (dt.isBefore(grouped[key]!['sortDate'])) grouped[key]!['sortDate'] = dt;
    }

    List<Map<String, dynamic>> result = [];
    grouped.forEach((key, data) {
      result.add({'label': key, 'orders': data['orders'], 'revenue': data['revenue'], 'sortDate': data['sortDate']});
    });

    result.sort((a, b) => (b['sortDate'] as DateTime).compareTo(a['sortDate'] as DateTime));
    return result;
  }

  String _getGroupKey(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    switch (_selectedFilter) {
      case 'Harian':
        return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
      case 'Mingguan':
        int week = ((dt.day - 1) / 7).floor() + 1;
        return "W$week ${months[dt.month - 1]} ${dt.year}";
      case 'Tahunan':
        return "${months[dt.month - 1]} ${dt.year}";
      case 'Bulanan':
      default:
        return "${months[dt.month - 1]} ${dt.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Consumer2<WalletProvider, OrderProvider>(
        builder: (context, wallet, order, _) {
          final allOrders = [...order.activeOrders, ...order.historyOrders];
          final isLoading = wallet.isLoading || order.isLoading;
          
          final double totalCashIn = _calculateTotalCash(wallet.mutasiList, 'CREDIT');
          final double totalCashOut = _calculateTotalCash(wallet.mutasiList, 'DEBIT');
          final double wip = _calculateWIP(order.activeOrders);
          final double totalKg = _calculateTotalKg(allOrders);
          final double avgRating = _calculateAverageRating(order.historyOrders);
          
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(context, wallet.balance, isLoading),
                const SizedBox(height: 16),
                _buildRankAndQuickAction(context, avgRating, wallet, order.historyOrders),
                const SizedBox(height: 16),
                _buildCashInOutCard(totalCashIn, totalCashOut, isLoading),
                const SizedBox(height: 24),
                _buildExecutiveReport(wallet.mutasiList.length, totalCashOut, totalCashIn, wip, allOrders.length, totalKg, isLoading),
                const SizedBox(height: 8),
                _buildMutationFilterAndList(wallet.mutasiList, allOrders, isLoading),
                const SizedBox(height: 40),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double balance, bool isLoading) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2DD4BF), Color(0xFF134E4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Dompet Utama Mitra", style: GoogleFonts.montserrat(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)), 
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text("AKTIF", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text("Total Kredit Tersedia", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.white60)),
          const SizedBox(height: 4),
          isLoading
              ? const ShimmerLoading(height: 40, width: 200, borderRadius: 8, baseColor: Colors.white24, highlightColor: Colors.white54)
              : Text(Formatters.currencyIdr(balance), style: GoogleFonts.montserrat(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.5)),
        ],
      ),
    );
  }

  Widget _buildRankAndQuickAction(BuildContext context, double avgRating, WalletProvider wallet, List<dynamic> historyOrders) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(16), 
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMiniAction(LucideIcons.arrowDownToLine, "Tarik", Colors.blue, onTap: () => _showTarikDanaModal(context, wallet)),
                    _buildMiniAction(LucideIcons.plusCircle, "Top-Up", Colors.green),
                    _buildMiniAction(LucideIcons.history, "Mutasi", Colors.orange),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: GestureDetector(
                onTap: () => _showReviewBottomSheet(context, historyOrders, avgRating),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFD4AF37)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16), 
                    boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.trophy, size: 24, color: Colors.white),
                      const SizedBox(height: 6),
                      Text(avgRating > 0 ? "Rating ${avgRating.toStringAsFixed(1)}" : "Belum Ada", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showReviewBottomSheet(BuildContext context, List<dynamic> historyOrders, double avgRating) {
    final auth = context.read<AuthProvider>();
    final laundryName = auth.user?['name'] ?? "Mitra Laundry";

    // Kumpulkan data review
    List<Map<String, dynamic>> validReviews = [];
    for (var o in historyOrders) {
      final reviews = o['reviews'] ?? o['review'];
      double rating = 0;
      String comment = '';
      
      if (reviews != null) {
        if (reviews is List && reviews.isNotEmpty) {
          rating = double.tryParse((reviews.first['rating_mitra'] ?? reviews.first['ratingMitra'])?.toString() ?? '0') ?? 0.0;
          comment = (reviews.first['comment'] ?? reviews.first['comment_mitra'] ?? reviews.first['commentMitra'])?.toString() ?? '';
        } else if (reviews is Map) {
          rating = double.tryParse((reviews['rating_mitra'] ?? reviews['ratingMitra'])?.toString() ?? '0') ?? 0.0;
          comment = (reviews['comment'] ?? reviews['comment_mitra'] ?? reviews['commentMitra'])?.toString() ?? '';
        }
      } else {
        rating = double.tryParse((o['rating_mitra'] ?? o['ratingMitra'])?.toString() ?? '0') ?? 0.0;
        comment = (o['comment'] ?? o['comment_mitra'] ?? o['commentMitra'])?.toString() ?? '';
      }

      if (rating > 0) {
        String customerName = "Pelanggan";
        final cust = o['customer'];
        if (cust is Map && cust['name'] != null) {
          customerName = cust['name'].toString();
        } else if (o['customer_name'] != null) {
          customerName = o['customer_name'].toString();
        }

        DateTime dt;
        try {
          final raw = o['createdAt'] ?? o['created_at'] ?? o['orderDate'] ?? o['order_date'];
          dt = raw != null ? DateTime.parse(raw.toString()).toLocal() : DateTime.now();
        } catch (_) { dt = DateTime.now(); }

        validReviews.add({
          'customerName': customerName,
          'rating': rating,
          'comment': comment.isEmpty ? 'Tidak ada komentar' : comment,
          'date': dt,
        });
      }
    }

    // Sort descending by date
    validReviews.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    
    // Ambil 3 terbaru
    final top3 = validReviews.take(3).toList();
    final totalReviews = validReviews.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).padding.bottom + 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              Text("Review dan Rating", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(laundryName, style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900, color: darkText), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(avgRating.toStringAsFixed(1), style: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.w900, color: darkText)),
                  const SizedBox(width: 8),
                  const Icon(Icons.star, color: Color(0xFFF59E0B), size: 28),
                  const SizedBox(width: 8),
                  Text("Penilaian Layanan ($totalReviews)", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                ],
              ),
              const SizedBox(height: 32),
              
              if (top3.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text("Belum ada review.", style: GoogleFonts.montserrat(color: Colors.grey)),
                )
              else
                ...top3.map((rv) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(rv['customerName'], style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkText)),
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < rv['rating'] ? Icons.star : Icons.star_border,
                                  color: index < rv['rating'] ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                                  size: 14,
                                );
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(rv['comment'], style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[700], height: 1.5)),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  void _showTarikDanaModal(BuildContext context, WalletProvider wallet) {
    final auth = context.read<AuthProvider>();
    final laundryName = auth.user?['name'] ?? "Berkah Laundry";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TarikDanaModal(
        laundryName: laundryName,
        maxBalance: wallet.balance,
      ),
    );
  }

  Widget _buildMiniAction(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: darkText)),
        ],
      ),
    );
  }

  Widget _buildCashInOutCard(double cashIn, double cashOut, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ringkasan Arus Kas", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkText)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: isLoading 
                      ? const ShimmerLoading(height: 40, borderRadius: 8) 
                      : _buildCashItem("Total CashIn", cashIn, Colors.green, LucideIcons.arrowDownLeft)
                ),
                Container(width: 1, height: 40, color: Colors.grey[200]),
                Expanded(
                  child: isLoading 
                      ? const Padding(padding: EdgeInsets.only(left: 8.0), child: ShimmerLoading(height: 40, borderRadius: 8))
                      : _buildCashItem("Total Cashout", cashOut, Colors.red, LucideIcons.arrowUpRight)
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCashItem(String label, double amount, Color color, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(Formatters.currencyIdr(amount), style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: darkText), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildExecutiveReport(int totalMutasi, double totalTarikan, double nominalSelesai, double wip, int totalOrder, double totalKg, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Laporan Keuangan Eksekutif", style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w800, color: darkText)),
          const SizedBox(height: 3),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
            children: [
               _buildStatPill("Total Transaksi", isLoading ? "-" : "$totalMutasi", Colors.blue),
               _buildStatPill("Total Tarikan", isLoading ? "-" : Formatters.currencyIdr(totalTarikan), Colors.red),
               _buildStatPill("Nominal Selesai", isLoading ? "-" : Formatters.currencyIdr(nominalSelesai), Colors.green),
               _buildStatPill("Nilai WIP", isLoading ? "-" : "~${Formatters.currencyIdr(wip)}", Colors.orange),
               _buildStatPill("Total Order", isLoading ? "-" : "$totalOrder", primaryTeal),
               _buildStatPill("Total Kg", isLoading ? "-" : "${totalKg.toStringAsFixed(1)} Kg", Colors.indigo),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatPill(String title, String val, Color c) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Flexible(child: Text(title, style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w700), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const Spacer(),
          Text(val, style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w900, color: darkText, letterSpacing: -0.5), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildMutationFilterAndList(List<dynamic> logs, List<dynamic> orders, bool isLoading) {
    final filteredData = _generateFilteredData(logs, orders);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(16), 
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Mutasi Log", style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.bold, color: darkText)),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryTeal : bgColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected ? [BoxShadow(color: primaryTeal.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                        border: Border.all(color: isSelected ? primaryTeal : Colors.grey[300]!),
                      ),
                      child: Text(
                        filter,
                        style: GoogleFonts.montserrat(
                          fontSize: 12, 
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600, 
                          color: isSelected ? Colors.white : Colors.grey[600]
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            
            if (isLoading)
              ...List.generate(3, (_) => const Padding(padding: EdgeInsets.only(bottom: 12.0), child: ShimmerLoading(height: 60, borderRadius: 10)))
            else if (filteredData.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Center(child: Text("Belum ada mutasi / order", style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey))),
              )
            else
              ...filteredData.map((data) => _buildDynamicRow(data['label'], data['orders'], data['revenue'])),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicRow(String label, int orders, double revenue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(LucideIcons.calendarDays, size: 16, color: primaryTeal),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: darkText)),
                  const SizedBox(height: 2),
                  Text("$orders Total Order", style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("Total Revenue", style: GoogleFonts.montserrat(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(Formatters.currencyIdr(revenue), style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.green)),
            ],
          )
        ],
      ),
    );
  }
}

class TarikDanaModal extends StatefulWidget {
  final String laundryName;
  final double maxBalance;

  const TarikDanaModal({
    super.key,
    required this.laundryName,
    required this.maxBalance,
  });

  @override
  State<TarikDanaModal> createState() => _TarikDanaModalState();
}

class _TarikDanaModalState extends State<TarikDanaModal> {
  double _amount = 0;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final double withdrawableMax = (widget.maxBalance ~/ 100000) * 100000.0;
    
    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            final user = auth.user;
            final hasBank = user != null && 
                            user['bank_name'] != null && user['bank_name'].toString().isNotEmpty && 
                            user['bank_account'] != null && user['bank_account'].toString().isNotEmpty && 
                            user['account_name'] != null && user['account_name'].toString().isNotEmpty;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 24),
                Text("Konfirmasi Tarik Dana Laundry", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF111827))),
                const SizedBox(height: 24),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildDetailRow("Nama Laundry", widget.laundryName),
                      const Divider(height: 32),
                      _buildDetailRow("Sumber Dana", "Wallet Nyutji", value2: "Saldo: ${Formatters.currencyIdr(widget.maxBalance)}", highlight2: true),
                      const Divider(height: 32),
                      hasBank 
                          ? _buildDetailRow("Rekening Penerima", user['account_name'] ?? '-', value2: "${user['bank_name']} - ${user['bank_account']}")
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Rekening Penerima", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                                InkWell(
                                  onTap: () {
                                    final nav = Navigator.of(context);
                                    nav.pop();
                                    nav.push(MaterialPageRoute(builder: (_) => Scaffold(
                                      appBar: AppBar(
                                        title: Text("Pengaturan Akun", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                        backgroundColor: const Color(0xFF1E5655),
                                        iconTheme: const IconThemeData(color: Colors.white),
                                      ),
                                      body: const MitraProfileScreen(),
                                    )));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.alertCircle, size: 12, color: Colors.red),
                                        const SizedBox(width: 4),
                                        Text("Setup Rekening", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                    ],
                  ),
                ),
            
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Nominal Tarik Dana", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                      Text(Formatters.currencyIdr(_amount), style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1E5655))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFF1E5655),
                      inactiveTrackColor: const Color(0xFF1E5655).withValues(alpha: 0.1),
                      thumbColor: const Color(0xFF2DD4BF),
                      overlayColor: const Color(0xFF2DD4BF).withValues(alpha: 0.2),
                      trackHeight: 8,
                    ),
                    child: Slider(
                      value: _amount,
                      min: 0,
                      max: withdrawableMax > 0 ? withdrawableMax : 100,
                      divisions: withdrawableMax > 0 ? (withdrawableMax ~/ 100000) : null,
                      onChanged: withdrawableMax > 0 ? (val) {
                        setState(() {
                          _amount = val;
                        });
                      } : null,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Rp 0", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
                      Text("Maks: ${Formatters.currencyIdr(withdrawableMax)}", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: !hasBank 
                      ? () {
                          final nav = Navigator.of(context);
                          nav.pop();
                          nav.push(MaterialPageRoute(builder: (_) => Scaffold(
                            appBar: AppBar(
                              title: Text("Pengaturan Akun", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              backgroundColor: const Color(0xFF1E5655),
                              iconTheme: const IconThemeData(color: Colors.white),
                            ),
                            body: const MitraProfileScreen(),
                          )));
                        }
                      : (_amount > 0 ? () {
                          final nav = Navigator.of(context);
                          nav.pop();
                          nav.push(MaterialPageRoute(
                            builder: (context) => pin_screen.PinScreen(amountToWithdraw: _amount)
                          ));
                        } : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !hasBank ? Colors.red : const Color(0xFF1E5655),
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: (!hasBank || _amount > 0) ? 8 : 0,
                    shadowColor: (!hasBank ? Colors.red : const Color(0xFF1E5655)).withValues(alpha: 0.4),
                  ),
                  child: Text(
                    !hasBank ? "Setup Rekening Dulu" : (_amount > 0 ? "Tarik Dana  >  ${Formatters.currencyIdr(_amount)}" : "Tentukan Nominal"),
                    style: GoogleFonts.montserrat(
                      fontSize: 14, 
                      fontWeight: FontWeight.bold, 
                      color: (!hasBank || _amount > 0) ? Colors.white : Colors.grey[600]
                    )
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        );
        },
      ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {String? value2, bool highlight2 = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[600])),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
            if (value2 != null) ...[
              const SizedBox(height: 4),
              Text(value2, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: highlight2 ? const Color(0xFF1E5655) : Colors.grey[500])),
            ],
          ],
        )
      ],
    );
  }
}
