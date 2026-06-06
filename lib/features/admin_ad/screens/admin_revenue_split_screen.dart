import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../../providers/revenue_split_provider.dart';
import '../../../core/utils/formatters.dart';

class AdminRevenueSplitScreen extends StatefulWidget {
  const AdminRevenueSplitScreen({super.key});

  @override
  State<AdminRevenueSplitScreen> createState() => _AdminRevenueSplitScreenState();
}

class _AdminRevenueSplitScreenState extends State<AdminRevenueSplitScreen> {
  final Color primaryTeal = const Color(0xFF1E5655);
  final Color darkGray = const Color(0xFF111827);
  final Color secondaryDark = const Color(0xFF1F2937);
  final Color accentGold = const Color(0xFFF59E0B);
  final Color accentBlue = const Color(0xFF3B82F6);
  final Color accentGreen = const Color(0xFF10B981);

  String _selectedPeriod = 'Harian';
  bool _isRiwayatExpanded = false;

  bool _isDateInPeriod(String? dateStr, String period) {
    if (dateStr == null || dateStr.isEmpty) return false;
    DateTime date;
    try {
      date = DateTime.parse(dateStr).toLocal();
    } catch (e) {
      return false;
    }
    final now = DateTime.now();
    if (period == "Harian") {
      return date.year == now.year && date.month == now.month && date.day == now.day;
    } else if (period == "Bulanan") {
      return date.year == now.year && date.month == now.month;
    } else if (period == "Tahunan") {
      return date.year == now.year;
    }
    return true;
  }

  String? _getDate(dynamic item) {
    return (item['doneAt'] ?? item['done_at'] ?? item['created_at'] ?? item['createdAt'])?.toString();
  }

  String _getMonthName(int month) {
    const months = ["Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember"];
    return months[month - 1];
  }

  String _getDynamicSummaryTitle() {
    final now = DateTime.now();
    if (_selectedPeriod == "Harian") {
      return "Ringkasan Pendapatan - ${now.day} ${_getMonthName(now.month)}";
    } else if (_selectedPeriod == "Bulanan") {
      return "Ringkasan Pendapatan - ${_getMonthName(now.month)}";
    } else {
      return "Ringkasan Pendapatan - ${now.year}";
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RevenueSplitProvider>().fetchRevenueData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Revenue Split",
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Consumer<RevenueSplitProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
          }

          final splits = provider.revenueSplits;
          final filteredSplits = splits.where((o) => _isDateInPeriod(_getDate(o), _selectedPeriod)).toList();

          return RefreshIndicator(
            color: accentGold,
            backgroundColor: secondaryDark,
            onRefresh: () => provider.fetchRevenueData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterCapsule(),
                  const SizedBox(height: 16),
                  _buildSummaryHeader(filteredSplits),
                  const SizedBox(height: 16),
                  _buildTopMitras(filteredSplits),
                  _buildTopCustomers(filteredSplits),
                  _buildTopKurirs(filteredSplits),
                  const SizedBox(height: 24),
                  _buildCollapsibleSplitsList(filteredSplits),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterCapsule() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: secondaryDark.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: ["Harian", "Bulanan", "Tahunan"].map((String period) {
            final isSelected = _selectedPeriod == period;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedPeriod = period),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? accentGold : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      period,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? darkGray : Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(List<dynamic> splits) {
    final totalOrders = splits.length;
    double adminRev = 0;
    double mitraRev = 0;
    double kurirRev = 0;
    for (var s in splits) {
      adminRev += double.tryParse(s['splits']?['admin']?.toString() ?? '0') ?? 0.0;
      mitraRev += double.tryParse(s['splits']?['mitra']?.toString() ?? '0') ?? 0.0;
      kurirRev += double.tryParse(s['splits']?['kurir']?.toString() ?? '0') ?? 0.0;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getDynamicSummaryTitle(),
            style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _buildGlassCard("Total Order", totalOrders.toString(), LucideIcons.shoppingBag, accentBlue),
              _buildGlassCard("Admin (Nyutji)", Formatters.currencyIdr(adminRev), LucideIcons.building, accentGold),
              _buildGlassCard("Mitra (ML)", Formatters.currencyIdr(mitraRev), LucideIcons.store, accentGreen),
              _buildGlassCard("Kurir (KL)", Formatters.currencyIdr(kurirRev), LucideIcons.bike, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(String title, String val, IconData icon, Color accentColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                val,
                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopMitras(List<dynamic> splits) {
    Map<String, Map<String, dynamic>> map = {};
    for (var s in splits) {
      final name = (s['mitra']?['name'] ?? 'Unknown').toString();
      if (name == 'Unknown' || name == '-') continue;
      const city = '-'; // Data kab/kota tidak diekspos backend secara default
      final rev = double.tryParse(s['splits']?['mitra']?.toString() ?? '0') ?? 0.0;
      if (!map.containsKey(name)) map[name] = {'name': name, 'city': city, 'rev': 0.0};
      map[name]!['rev'] += rev;
    }
    final list = map.values.toList();
    list.sort((a, b) => b['rev'].compareTo(a['rev']));
    final top5 = list.take(5).toList();
    if (top5.isEmpty) return const SizedBox.shrink();
    return _buildTopList("5 Top Revenue Mitra Laundry", top5, showRp: true, icon: LucideIcons.store);
  }

  Widget _buildTopCustomers(List<dynamic> splits) {
    Map<String, Map<String, dynamic>> map = {};
    for (var s in splits) {
      final name = (s['customer']?['name'] ?? 'Unknown').toString();
      if (name == 'Unknown' || name == '-') continue;
      const city = '-';
      final admin = double.tryParse(s['splits']?['admin']?.toString() ?? '0') ?? 0.0;
      final mitra = double.tryParse(s['splits']?['mitra']?.toString() ?? '0') ?? 0.0;
      final kurir = double.tryParse(s['splits']?['kurir']?.toString() ?? '0') ?? 0.0;
      final rev = (s['totalPrice'] != null) ? (double.tryParse(s['totalPrice'].toString()) ?? 0.0) : (admin + mitra + kurir);
      if (!map.containsKey(name)) map[name] = {'name': name, 'city': city, 'rev': 0.0};
      map[name]!['rev'] += rev;
    }
    final list = map.values.toList();
    list.sort((a, b) => b['rev'].compareTo(a['rev']));
    final top5 = list.take(5).toList();
    if (top5.isEmpty) return const SizedBox.shrink();
    return _buildTopList("5 Top Kontributor Customer", top5, showRp: false, icon: LucideIcons.users);
  }

  Widget _buildTopKurirs(List<dynamic> splits) {
    Map<String, Map<String, dynamic>> map = {};
    for (var s in splits) {
      final name = (s['courier']?['name'] ?? 'Unknown').toString();
      if (name == 'Unknown' || name == '-') continue;
      const city = '-';
      final rev = double.tryParse(s['splits']?['kurir']?.toString() ?? '0') ?? 0.0;
      if (!map.containsKey(name)) map[name] = {'name': name, 'city': city, 'rev': 0.0};
      map[name]!['rev'] += rev;
    }
    final list = map.values.toList();
    list.sort((a, b) => b['rev'].compareTo(a['rev']));
    final top5 = list.take(5).toList();
    if (top5.isEmpty) return const SizedBox.shrink();
    return _buildTopList("5 Top Revenue Mitra Kurir", top5, showRp: true, icon: LucideIcons.bike);
  }

  Widget _buildTopList(String title, List<Map<String, dynamic>> items, {bool showRp = true, IconData icon = LucideIcons.medal}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: secondaryDark.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: accentGold),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(items.length, (index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    SizedBox(width: 24, child: Text("${index + 1}.", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: accentGold))),
                    Expanded(
                      flex: 6,
                      child: Text(item['name'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(item['city'], style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[400]), overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      flex: 4,
                      child: showRp
                          ? Text(Formatters.currencyIdr(item['rev'] as double), textAlign: TextAlign.right, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: accentGreen))
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleSplitsList(List<dynamic> splits) {
    bool isSearchVisible = false;
    String searchQuery = '';

    return StatefulBuilder(
      builder: (context, setStateLocal) {
        final searchedSplits = searchQuery.isEmpty
            ? splits
            : splits.where((s) {
                final orderNo = (s['order_number'] ?? s['orderNumber'] ?? s['orderId'] ?? '').toString().toLowerCase();
                return orderNo.contains(searchQuery.toLowerCase());
              }).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isRiwayatExpanded = !_isRiwayatExpanded),
                    child: Text(
                      "Riwayat Split (Per Order)",
                      style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (!_isRiwayatExpanded) {
                            setState(() => _isRiwayatExpanded = true);
                          }
                          setStateLocal(() {
                            isSearchVisible = !isSearchVisible;
                            if (!isSearchVisible) searchQuery = '';
                          });
                        },
                        child: Icon(LucideIcons.search, color: accentGold, size: 20),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => setState(() => _isRiwayatExpanded = !_isRiwayatExpanded),
                        child: Icon(
                          _isRiwayatExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                          color: accentGold,
                          size: 20,
                        ),
                      ),
                    ],
                  )
                ],
              ),
              if (_isRiwayatExpanded && isSearchVisible) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: TextField(
                    style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Cari nomor order...",
                      hintStyle: GoogleFonts.montserrat(color: Colors.grey[500], fontSize: 14),
                      icon: Icon(LucideIcons.search, size: 16, color: Colors.grey[400]),
                    ),
                    onChanged: (val) {
                      setStateLocal(() {
                        searchQuery = val;
                      });
                    },
                  ),
                ),
              ],
              if (_isRiwayatExpanded) ...[
                const SizedBox(height: 12),
                if (searchedSplits.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(LucideIcons.inbox, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.isNotEmpty ? "Order tidak ditemukan" : "Belum ada data revenue split",
                            style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: searchedSplits.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final split = searchedSplits[index];
                      final orderNo = split['order_number'] ?? split['orderNumber'] ?? split['orderId'] ?? '-';
                      final orderRp = Formatters.currencyIdr(double.tryParse(split['totalPrice']?.toString() ?? '0') ?? 0.0);
                      
                      final adminAmount = double.tryParse(split['splits']?['admin']?.toString() ?? '0') ?? 0.0;
                      final mitraAmount = double.tryParse(split['splits']?['mitra']?.toString() ?? '0') ?? 0.0;
                      final kurirAmount = double.tryParse(split['splits']?['kurir']?.toString() ?? '0') ?? 0.0;

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: secondaryDark.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Order: $orderNo",
                                            style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: accentGold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Order Rupiah: $orderRp",
                                            style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[300]),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: primaryTeal.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "Split",
                                        style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: primaryTeal),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(child: _buildSplitRow("Admin", adminAmount, accentGold)),
                                    Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.1)),
                                    Expanded(child: _buildSplitRow("Mitra", mitraAmount, accentGreen)),
                                    Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.1)),
                                    Expanded(child: _buildSplitRow("Kurir", kurirAmount, Colors.orange)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSplitRow(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[400]),
        ),
        const SizedBox(height: 4),
        Text(
          Formatters.currencyIdr(amount),
          style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
