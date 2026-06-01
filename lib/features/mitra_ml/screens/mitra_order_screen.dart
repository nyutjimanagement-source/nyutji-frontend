import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../core/utils/status_helper.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/nyutji_image_picker.dart';
import '../../../core/widgets/nyutji_loading_overlay.dart';
import '../../../core/widgets/nyutji_notif.dart';

class MitraOrderScreen extends StatefulWidget {
  const MitraOrderScreen({super.key});
  @override
  State<MitraOrderScreen> createState() => _MitraOrderScreenState();
}

class _MitraOrderScreenState extends State<MitraOrderScreen> {
  static const Color primaryTeal = Color(0xFF1E5655);
  static const Color bgColor = Color(0xFFF3F4F6);
  static const Color darkText = Color(0xFF111827);
  static const Color textGrey = Color(0xFF6B7280);

  String currentFilter = "Baru";
  final Set<String> _expandedIds = {};
  late PageController _pageController;
  late ScrollController _summaryScrollController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _summaryScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrderProvider>().fetchOrders();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _summaryScrollController.dispose();
    super.dispose();
  }

  // Progress step: 1=PickUp, 2=Timbang, 3=Cuci, 4=Packing, 5=Kirim, 6=Done
  int _getProgressStep(String status) {
    switch (status.toUpperCase()) {
      case 'SEARCHING':
      case 'COURIER_ACCEPTED':
      case 'WAITING_DROPOFF':
      case 'PICKING_UP': return 1;
      case 'WEIGHING': return 2;
      case 'WASH_START':
      case 'IRONING': return 3;
      case 'PACKING': return 4;
      case 'DELIVERING': return 5;
      case 'DONE':
      case 'PAID': return 6;
      default: return 1;
    }
  }

  bool _isPremiumOrder(dynamic o) {
    final items = o['orderItems'] as List? ?? o['order_items'] as List? ?? o['items'] as List?;
    String textToScan = "";
    if (items != null && items.isNotEmpty) {
      for (var it in items) {
        if (it is Map) {
          textToScan += " ${(it['itemName'] ?? it['item_name'] ?? it['name'] ?? '').toString().toLowerCase()}";
          textToScan += " ${(it['notes'] ?? '').toString().toLowerCase()}";
        }
      }
    }
    textToScan += " ${(o['notes'] ?? '').toString().toLowerCase()}";
    textToScan += " ${(o['pickupNote'] ?? '').toString().toLowerCase()}";
    
    return textToScan.contains('sepatu') || 
           textToScan.contains('shoecare') || 
           textToScan.contains('dryclean') || 
           textToScan.contains('dry clean') || 
           textToScan.contains('jas') || 
           textToScan.contains('kebaya') || 
           textToScan.contains('gaun') ||
           textToScan.contains('bayi') || 
           textToScan.contains('baby') || 
           textToScan.contains('pakaian bayi') ||
           textToScan.contains('khusus') || 
           textToScan.contains('stroller') || 
           textToScan.contains('cuci khusus');
  }

  String _getPremiumServiceName(dynamic order) {
    final items = order['orderItems'] as List? ?? order['order_items'] as List? ?? order['items'] as List?;
    String textToScan = "";
    if (items != null && items.isNotEmpty) {
      for (var it in items) {
        if (it is Map) {
          textToScan += " ${(it['itemName'] ?? it['item_name'] ?? it['name'] ?? '').toString().toLowerCase()}";
          textToScan += " ${(it['notes'] ?? '').toString().toLowerCase()}";
        }
      }
    }
    textToScan += " ${(order['notes'] ?? '').toString().toLowerCase()}";
    textToScan += " ${(order['pickupNote'] ?? '').toString().toLowerCase()}";
    
    if (textToScan.contains('sepatu') || textToScan.contains('shoecare') || textToScan.contains('pasang')) {
      return 'Shoecare';
    }
    if (textToScan.contains('dryclean') || textToScan.contains('dry clean') || textToScan.contains('jas') || textToScan.contains('kebaya') || textToScan.contains('gaun')) {
      return 'Dry Clean';
    }
    if (textToScan.contains('bayi') || textToScan.contains('baby') || textToScan.contains('pakaian bayi')) {
      return 'Baby Care';
    }
    if (textToScan.contains('khusus') || textToScan.contains('stroller') || textToScan.contains('cuci khusus')) {
      return 'Special Care';
    }
    return '';
  }

  String _getPremiumProgressLabel(String status) {
    final s = status.toUpperCase();
    if (s == 'DONE' || s == 'PAID') return "Selesai";
    if (s == 'PACKING' || s == 'DELIVERING') return "Packing";
    if (s == 'WASH_START' || s == 'IN_PROGRESS' || s == 'IRONING') return "Cuci";
    return "Diterima";
  }

  void _showPowDialog(List<dynamic>? proofs, List<String> targetStages, String title) {
    if (proofs == null || proofs.isEmpty) {
      _showNoPowToast();
      return;
    }

    dynamic foundProof;
    for (var proof in proofs.reversed) {
      if (targetStages.contains(proof['step'])) {
        foundProof = proof;
        break;
      }
    }

    if (foundProof == null) {
      _showNoPowToast();
      return;
    }

    final String path = foundProof['file_url'].toString().replaceAll('\\', '/').replaceAll(RegExp(r'^/+'), '');
    final imageUrl = path.startsWith('http') ? path : "${ApiConstants.rootUrl}/$path";

    // Info overlay
    final String orderId = (foundProof['orderId'] ?? foundProof['order_id'] ?? '-').toString();
    final String uploaderRole = (foundProof['uploader_role'] ?? 'PL').toString();
    final String uploaderLabel = uploaderRole == 'ML' ? 'Mitra Laundry'
        : uploaderRole == 'KL' ? 'Kurir'
        : 'Pelanggan';
    String uploadedAt = '-';
    try {
      final dt = DateTime.tryParse(foundProof['createdAt']?.toString() ?? '');
      if (dt != null) {
        final local = dt.toLocal();
        final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
        uploadedAt = '${local.day} ${months[local.month - 1]}, '
            '${local.hour.toString().padLeft(2,'0')}:${local.minute.toString().padLeft(2,'0')} WIB';
      }
    } catch (_) {}

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        final screenH = MediaQuery.of(ctx).size.height;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Bukti $title",
                        style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, color: primaryTeal),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 18, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
              // Foto + Watermark + Info
              SizedBox(
                height: screenH * 0.55,
                child: InteractiveViewer(
                  panEnabled: true,
                minScale: 0.8,
                maxScale: 5.0,
                child: Stack(
                  children: [
                    // Gambar
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          height: 260,
                          child: Center(child: CircularProgressIndicator(color: primaryTeal)),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const SizedBox(
                        height: 220,
                        child: Center(child: Icon(Icons.broken_image_outlined, size: 52, color: Colors.grey)),
                      ),
                    ),
                    // Watermark diagonal
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: Transform.rotate(
                            angle: -0.5,
                            child: Text(
                              'Properti Nyutji Management',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white.withValues(alpha: 0.45),
                                letterSpacing: 1.2,
                                shadows: [const Shadow(color: Colors.black38, blurRadius: 4)],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Gradient + Info overlay bawah kanan
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 32, 16, 14),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black54, Colors.transparent],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(orderId, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                            Text(uploadedAt, style: GoogleFonts.montserrat(fontSize: 10, color: Colors.white70)),
                            Text('oleh: $uploaderLabel', style: GoogleFonts.montserrat(fontSize: 10, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ), // end Stack
              ),   // end InteractiveViewer
              ),   // end SizedBox
            ],
          ),
        ),
      );
      },
    );
  }

  void _showNoPowToast() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Foto bukti belum tersedia untuk tahapan ini", style: GoogleFonts.montserrat(fontSize: 12)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.black87,
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height - 150,
        left: 16,
        right: 16,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      dismissDirection: DismissDirection.up,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Consumer<OrderProvider>(
        builder: (context, orderProv, _) {
          final List<dynamic> baseOrders = (currentFilter == "Baru")
              ? orderProv.activeOrders
              : [...orderProv.activeOrders, ...orderProv.historyOrders];

          final bool hasNewOrders = orderProv.activeOrders.any((o) {
            final s = (o['status'] ?? o['order_status'] ?? '').toString().toUpperCase();
            return s == 'SEARCHING' || s == 'WAITING_DROPOFF';
          });

          final filtered = baseOrders.where((o) {
            final status = (o['status'] ?? o['order_status'] ?? '').toString().toUpperCase();
            final isFast = o['is_fast_track'] == true || o['is_fast_track'] == 1 || o['isFastTrack'] == true;
            final serviceType = (o['service_type'] ?? o['serviceType'] ?? '').toString().toUpperCase();
            if (currentFilter == "Baru") return status == 'SEARCHING' || status == 'WAITING_DROPOFF';
            if (currentFilter == "Same Day") return (isFast || serviceType.contains('SAME')) && status != 'DONE' && status != 'PAID';
            if (currentFilter == "Reguler") return (serviceType.contains('REGULER') || serviceType.contains('BIASA')) && status != 'DONE' && status != 'PAID';
            if (currentFilter == "SELESAI") return status == 'DONE' || status == 'PAID';
            return false;
          }).toList();

          return Column(
            children: [
              _buildTopSection(orderProv),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                  child: _buildListContent(filtered, orderProv.isLoading, hasNewOrders),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopSection(OrderProvider orderProv) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF134E4A), Color(0xFF1E5655), Color(0xFF2DD4BF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: Text(
                "Manajemen Pesanan",
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  ...["Baru", "Same Day", "Reguler", "SELESAI"].map((f) {
                    int count = 0;
                    final allList = [...orderProv.activeOrders, ...orderProv.historyOrders];
                    for (var o in allList) {
                      final s = (o['status'] ?? o['order_status'] ?? '').toString().toUpperCase();
                      final isFast = o['is_fast_track'] == true || o['is_fast_track'] == 1 || o['isFastTrack'] == true;
                      final serviceType = (o['service_type'] ?? o['serviceType'] ?? '').toString().toUpperCase();
                      
                      if (f == "Baru" && (s == 'SEARCHING' || s == 'WAITING_DROPOFF')) {
                        count++;
                      } else if (f == "Same Day" && (isFast || serviceType.contains('SAME')) && s != 'DONE' && s != 'PAID') {
                        count++;
                      } else if (f == "Reguler" && (serviceType.contains('REGULER') || serviceType.contains('BIASA')) && s != 'DONE' && s != 'PAID') {
                        count++;
                      }
                    }
                    return _buildFilterPill(f, count);
                  }),
                  _buildSearchButton(orderProv),
                ],
              ),
            ),
            _buildSummaryCards(orderProv),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, int count) {
    final bool isSel = currentFilter == label;
    final bool hasCount = count > 0 && label != "SELESAI";
    return GestureDetector(
      onTap: () {
        if (currentFilter != label) {
          setState(() { currentFilter = label; _currentPage = 0; });
          if (_pageController.hasClients) _pageController.jumpToPage(0);
          _animateSummaryScrollForFilter(label);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSel ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSel ? Colors.transparent : Colors.white.withValues(alpha: 0.3)),
          boxShadow: isSel ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: GoogleFonts.montserrat(
            fontSize: 12, 
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600, 
            color: isSel ? primaryTeal : Colors.white,
          )),
          if (hasCount) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildListContent(List<dynamic> filtered, bool isLoading, bool hasNewOrders) {
    if (isLoading && filtered.isEmpty) {
      return ListView.separated(
        key: const ValueKey('loading'),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, __) => const ShimmerLoading(height: 180, borderRadius: 16),
      );
    }

    return AnimatedSwitcher(
      key: ValueKey('content_$currentFilter'),
      duration: const Duration(milliseconds: 300),
      child: filtered.isEmpty
          ? RefreshIndicator(
              onRefresh: () => context.read<OrderProvider>().fetchOrders(),
              color: primaryTeal,
              child: ListView(
                key: ValueKey('empty_$currentFilter'),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.clipboardList, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text("Tidak ada pesanan", style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text("Tarik ke bawah untuk memuat ulang", style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[400])),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : _buildPaginatedList(filtered),
    );
  }

  void _animateSummaryScroll(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_summaryScrollController.hasClients) {
        double targetOffset = index * 274.0;
        final maxScroll = _summaryScrollController.position.maxScrollExtent;
        if (targetOffset > maxScroll) {
          targetOffset = maxScroll;
        }
        if (targetOffset < 0) {
          targetOffset = 0;
        }
        _summaryScrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _animateSummaryScrollForFilter(String filter) {
    if (filter == "Baru") {
      _animateSummaryScroll(0);
    } else if (filter == "Same Day") {
      _animateSummaryScroll(1);
    } else if (filter == "Reguler") {
      _animateSummaryScroll(2);
    } else if (filter == "SELESAI") {
      _animateSummaryScroll(3);
    }
  }

  Widget _buildSummaryCards(OrderProvider orderProv) {
    final allOrders = [...orderProv.activeOrders, ...orderProv.historyOrders];
    
    double totalBaru = 0;
    int countBaru = 0;
    double totalSameDay = 0;
    int countSameDay = 0;
    double totalReguler = 0;
    int countReguler = 0;
    double totalSelesai = 0;
    int countSelesai = 0;

    for (var o in allOrders) {
      final price = double.tryParse((o['servicePrice'] ?? o['service_price'] ?? o['total_price'] ?? o['totalPrice'] ?? '0').toString()) ?? 0.0;
      final isFast = o['is_fast_track'] == true || o['is_fast_track'] == 1 || o['isFastTrack'] == true;
      final serviceType = (o['service_type'] ?? o['serviceType'] ?? '').toString().toUpperCase();
      final status = (o['status'] ?? o['order_status'] ?? '').toString().toUpperCase();
      
      // Baru
      if (status == 'SEARCHING' || status == 'WAITING_DROPOFF') {
        totalBaru += price;
        countBaru++;
      }
      
      // Same Day
      if ((isFast || serviceType.contains('SAME')) && status != 'DONE' && status != 'PAID') {
        totalSameDay += price;
        countSameDay++;
      }
      
      // Reguler
      if ((serviceType.contains('REGULER') || serviceType.contains('BIASA')) && status != 'DONE' && status != 'PAID') {
        totalReguler += price;
        countReguler++;
      }
      
      // Selesai
      if (status == 'DONE' || status == 'PAID') {
        totalSelesai += price;
        countSelesai++;
      }
    }

    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return SingleChildScrollView(
      controller: _summaryScrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 4, 8),
      child: Row(
        children: [
          _buildSummaryCard(
            label: "Baru",
            value: "${currencyFormatter.format(totalBaru)} | $countBaru",
            isActive: currentFilter == "Baru",
            activeColor: primaryTeal,
            icon: LucideIcons.sparkles,
            onTap: () {
              _animateSummaryScroll(0);
              if (currentFilter != "Baru") {
                setState(() {
                  currentFilter = "Baru";
                  _currentPage = 0;
                });
                if (_pageController.hasClients) _pageController.jumpToPage(0);
              }
            },
          ),
          _buildSummaryCard(
            label: "Same Day",
            value: "${currencyFormatter.format(totalSameDay)} | $countSameDay",
            isActive: currentFilter == "Same Day",
            activeColor: const Color(0xFFEA580C),
            icon: LucideIcons.zap,
            onTap: () {
              _animateSummaryScroll(1);
              if (currentFilter != "Same Day") {
                setState(() {
                  currentFilter = "Same Day";
                  _currentPage = 0;
                });
                if (_pageController.hasClients) _pageController.jumpToPage(0);
              }
            },
          ),
          _buildSummaryCard(
            label: "Reguler",
            value: "${currencyFormatter.format(totalReguler)} | $countReguler",
            isActive: currentFilter == "Reguler",
            activeColor: const Color(0xFF2563EB),
            icon: LucideIcons.calendar,
            onTap: () {
              _animateSummaryScroll(2);
              if (currentFilter != "Reguler") {
                setState(() {
                  currentFilter = "Reguler";
                  _currentPage = 0;
                });
                if (_pageController.hasClients) _pageController.jumpToPage(0);
              }
            },
          ),
          _buildSummaryCard(
            label: "SELESAI",
            value: "${currencyFormatter.format(totalSelesai)} | $countSelesai",
            isActive: currentFilter == "SELESAI",
            activeColor: const Color(0xFF10B981),
            icon: LucideIcons.checkCircle,
            onTap: () {
              _animateSummaryScroll(3);
              if (currentFilter != "SELESAI") {
                setState(() {
                  currentFilter = "SELESAI";
                  _currentPage = 0;
                });
                if (_pageController.hasClients) _pageController.jumpToPage(0);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required bool isActive,
    required VoidCallback onTap,
    required Color activeColor,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 260,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          boxShadow: isActive ? [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 8))
          ] : [],
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isActive ? activeColor.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive ? activeColor.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isActive ? activeColor : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isActive ? darkText : Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginatedList(List<dynamic> filtered) {
    final List<List<dynamic>> pages = [];
    for (var i = 0; i < filtered.length; i += 6) {
      pages.add(filtered.sublist(i, i + 6 > filtered.length ? filtered.length : i + 6));
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<OrderProvider>().fetchOrders(),
            color: primaryTeal,
            child: PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, pIdx) => ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                itemCount: pages[pIdx].length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, iIdx) => _buildOrderCard(pages[pIdx][iIdx]),
              ),
            ),
          ),
        ),
        if (pages.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == i ? 12 : 6, height: 6,
                decoration: BoxDecoration(
                  color: _currentPage == i ? primaryTeal : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              )),
            ),
          )
        else
          const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOrderCard(dynamic o) {
    final status = (o['status'] ?? o['order_status'] ?? 'UNKNOWN').toString();
    final statusUp = status.toUpperCase();
    final servicePrice = double.tryParse((o['servicePrice'] ?? o['service_price'] ?? o['total_price'] ?? o['totalPrice'] ?? '0').toString()) ?? 0.0;
    final orderId = (o['order_number'] ?? o['orderNumber'] ?? o['identifier'] ?? o['id'] ?? '-').toString();
    final customerName = o['customer']?['name']?.toString() ?? o['customer_name']?.toString() ?? 'Pelanggan';
    final customerPhoto = o['customer']?['profile_photo']?.toString() ?? 
                          o['customer']?['photo_url']?.toString() ?? 
                          o['customer']?['photo']?.toString() ?? 
                          o['customer_photo']?.toString() ??
                          o['customerPhoto']?.toString();
    final courierName = o['courier']?['name']?.toString() ?? o['courier_name']?.toString() ?? 'Belum Ada';
    final bool isFast = o['is_fast_track'] == true || o['is_fast_track'] == 1 || o['isFastTrack'] == true || o['service_type'] == 'SAME_DAY';
    final Color accentColor = isFast ? Colors.orange : primaryTeal;

    DateTime doneAt;
    try {
      final doneAtRaw = o['doneAt'] ?? o['done_at'] ?? o['createdAt'] ?? o['created_at'];
      doneAt = doneAtRaw != null ? DateTime.parse(doneAtRaw.toString()).toLocal() : DateTime.now();
    } catch (e) {
      doneAt = DateTime.now();
    }

    final bool isExpanded = _expandedIds.contains(orderId);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border.all(color: isExpanded ? accentColor.withValues(alpha: 0.1) : Colors.grey[100]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            if (isExpanded)
              Positioned(
                left: 0, top: 0, bottom: 0,
                width: 8,
                child: Container(color: accentColor),
              ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                splashColor: accentColor.withValues(alpha: 0.12),
                highlightColor: accentColor.withValues(alpha: 0.05),
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (isExpanded) { _expandedIds.remove(orderId); } else { _expandedIds.add(orderId); }
                  });
                },
                child: Padding(
                  padding: EdgeInsets.only(left: isExpanded ? 8 : 0),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: isExpanded
                        ? _buildExpandedCard(o, orderId, status, statusUp, servicePrice, customerName, courierName, isFast, doneAt, accentColor, customerPhoto)
                        : _buildCollapsedCard(status, servicePrice, doneAt, o, customerName, customerPhoto),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── COLLAPSED ──────────────────────────────────────
  Widget _buildCollapsedCard(String status, double servicePrice, DateTime doneAt, dynamic o, String customerName, String? customerPhoto) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(children: [
        _buildCustomerAvatar(customerPhoto, 46),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      customerName,
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w900, color: darkText, letterSpacing: -0.3)
                    ),
                  ),
                  if (_isPremiumOrder(o))
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "PREMIUM",
                        style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(servicePrice),
                      style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: primaryTeal)
                    ),
                  ),
                  Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey[400], shape: BoxShape.circle)),
                  Text(DateFormat('dd MMM, HH:mm', 'id_ID').format(doneAt),
                    style: GoogleFonts.montserrat(fontSize: 11, color: textGrey, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          )
        ),
        const SizedBox(width: 10),
        _buildStatusChip(status, o),
      ]),
    );
  }

  // ── EXPANDED ──────────────────────────────────────
  Widget _buildExpandedCard(dynamic o, String orderId, String status, String statusUp,
      double servicePrice, String customerName, String courierName, bool isFast,
      DateTime doneAt, Color accentColor, String? customerPhoto) {

    final String rawDel = (o['deliveryType'] ?? o['delivery_type'] ?? '').toString().toUpperCase();
    final bool isSelfDrop = rawDel == 'SELF_DROP' || rawDel == 'SELFDROP_SELFDELIVERY' || rawDel == 'SELF_SERVICE';
    final bool needsCourier = (statusUp == 'SEARCHING' || statusUp == 'WAITING_DROPOFF') && !isSelfDrop;
    final bool needsUpdate = !needsCourier && statusUp != 'DONE' && statusUp != 'PAID';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Top section: Avatar, Customer Name, and Price Pill
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildCustomerAvatar(customerPhoto, 50),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customerName,
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: darkText, letterSpacing: -0.3)
                        ),
                      ),
                      if (_isPremiumOrder(o))
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "PREMIUM",
                            style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(servicePrice),
                      style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: primaryTeal)
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusChip(status, o),
          ],
        ),

        const SizedBox(height: 20),

        // Information Grid (Order ID, Date, Service, Courier)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
            border: Border.all(color: Colors.grey[100]!),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDetailInfoItem("Order ID", orderId, LucideIcons.hash),
                  _buildDetailInfoItem("Tanggal", DateFormat('dd MMM, HH:mm', 'id_ID').format(doneAt), LucideIcons.calendar),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Color(0xFFF3F4F6), height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDetailInfoItem("Layanan", isFast ? "Same Day" : "Reguler", LucideIcons.zap, valueColor: isFast ? Colors.orange : darkText),
                  if (rawDel != 'SELFDROP_SELFDELIVERY') 
                    _buildDetailInfoItem("Kurir", courierName, LucideIcons.truck, valueColor: courierName == "Belum Ada" ? Colors.orange : darkText)
                  else
                    _buildDetailInfoItem("Kurir", "Ambil Sendiri", LucideIcons.store),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Detail Pesanan ──
        _buildDetailPesanan(o),

        const SizedBox(height: 24),

        // ── Progress Cucian ──
        _buildProgressCucian(orderId, status, accentColor, o),

        // ── Action Buttons ──
        if (needsCourier || needsUpdate) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (needsCourier) {
                  _showCourierPicker(orderId);
                } else if (needsUpdate) {
                  final deliveryType = (o['delivery_type'] ?? o['deliveryType'] ?? '').toString();
                  _showStatusUpdater(orderId, status, deliveryType);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: needsCourier ? Colors.orange[700] : primaryTeal, 
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 4,
                shadowColor: (needsCourier ? Colors.orange[700]! : primaryTeal).withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(needsCourier ? LucideIcons.userPlus : LucideIcons.refreshCw, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    needsCourier ? "ASSIGN KURIR" : "UPDATE STATUS", 
                    style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                  ),
                ],
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildDetailInfoItem(String label, String value, IconData icon, {Color? valueColor}) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[200]!)
            ),
            child: Icon(icon, size: 14, color: Colors.grey[500]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey[400])),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: valueColor ?? darkText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerAvatar(String? photoUrl, double size) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      final String cleanPath = photoUrl.replaceAll('\\', '/').replaceAll(RegExp(r'^/+'), '');
      // Jika hanya nama file (tidak ada '/'), tambahkan folder uploads/profiles/
      final String resolvedPath = (!cleanPath.startsWith('http') && !cleanPath.contains('/'))
          ? 'uploads/profiles/$cleanPath'
          : cleanPath;
      final String fullUrl = resolvedPath.startsWith('http') ? resolvedPath : "${ApiConstants.rootUrl}/$resolvedPath";
      return Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: primaryTeal.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
          image: DecorationImage(image: NetworkImage(fullUrl), fit: BoxFit.cover),
        ),
      );
    }
    
    // Fallback gradient avatar
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2DD4BF), Color(0xFF134E4A)], 
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight
        ),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: primaryTeal.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Center(child: Icon(LucideIcons.user, color: Colors.white, size: size * 0.45)),
    );
  }

  Widget _buildDetailPesanan(dynamic o) {
    final items = o['orderItems'] as List? ?? o['order_items'] as List? ?? o['items'] as List?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("Detail Pesanan", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: darkText)),
            const SizedBox(width: 12),
            const Expanded(child: Divider(color: Color(0xFFF3F4F6), thickness: 1.5)),
          ],
        ),
        const SizedBox(height: 10),
        if (items != null && items.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map<Widget>((it) {
                final name = (it['itemName'] ?? it['item_name'] ?? it['name'] ?? 'Layanan Laundry').toString();
                final qty = double.tryParse(it['qty']?.toString() ?? '1') ?? 1.0;
                final unitText = (it['unit'] ?? 'Pcs').toString();
                final notes = (it['notes'] ?? '').toString();
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: darkText),
                            ),
                          ),
                          Text(
                            "${qty.toStringAsFixed(qty == qty.toInt() ? 0 : 1)} $unitText",
                            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: primaryTeal),
                          ),
                        ],
                      ),
                      if (notes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3.0),
                          child: Text(
                            notes,
                            style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: textGrey),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              "-",
              style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: darkText),
            ),
          ),
      ],
    );
  }

  // ── Progress Bar ──────────────────────────────────
  // Steps disesuaikan 3 jenis layanan:
  // PICKUP → 4 steps (ada Kirim)
  // SELF_DROP + kurir → 4 steps (ada Kirim)
  // SELF_DROP tanpa kurir → 3 steps (no Kirim = Ambil Mandiri)
  Widget _buildProgressCucian(String orderId, String status, Color accentColor, dynamic o) {
    final int step = _getProgressStep(status);
    final String rawDel = (o['deliveryType'] ?? o['delivery_type'] ?? '').toString().toUpperCase();
    final bool isSelfDrop = rawDel == 'SELF_DROP' || rawDel == 'SELFDROP_SELFDELIVERY' || rawDel == 'SELF_SERVICE';
    final isSelfDropPickup = rawDel == 'SELFDROP_SELFDELIVERY' || 
        (rawDel == 'SELF_DROP' && (double.tryParse(o['deliveryFee']?.toString() ?? '0') ?? 0.0) == 0);
    
    bool isStep1 = step >= 2 || (isSelfDrop && status.toUpperCase() == 'WAITING_DROPOFF');
    bool isStep2 = step >= 3;
    bool isStep3 = step >= 4;
    bool isStep4 = step >= 5;
    bool isStep5 = step >= 6;

    final bool isPremium = _isPremiumOrder(o);

    List<Map<String, dynamic>> steps = isSelfDropPickup 
        ? [
            {
              "label": isPremium ? "Diterima" : "Timbang", 
              "icon": isPremium ? LucideIcons.packageCheck : 'assets/icons/scale.png', 
              "active": isStep1,
              "onTap": isPremium ? () => _showPowDialog(o['proofs'], ['WEIGHING'], "Diterima") : null
            },
            {"label": "Cuci", "icon": LucideIcons.droplets, "active": isStep2},
            {"label": "Packing", "icon": LucideIcons.package, "active": isStep3},
            {"label": "Selesai", "icon": LucideIcons.checkCircle, "active": isStep5},
          ]
        : [
            {
              "label": isPremium ? "Diterima" : "Timbang", 
              "icon": isPremium ? LucideIcons.packageCheck : 'assets/icons/scale.png', 
              "active": isStep1,
              "onTap": isPremium ? () => _showPowDialog(o['proofs'], ['WEIGHING'], "Diterima") : null
            },
            {"label": "Cuci", "icon": LucideIcons.droplets, "active": isStep2},
            {"label": "Packing", "icon": LucideIcons.package, "active": isStep3},
            {"label": "Kirim", "icon": LucideIcons.navigation, "active": isStep4},
            {"label": "Selesai", "icon": LucideIcons.checkCircle, "active": isStep5},
          ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text("Progress Cucian", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: darkText)),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: Color(0xFFF3F4F6), thickness: 1.5)),
      ]),
      const SizedBox(height: 20),
      Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isEven) {
            int stepIndex = index ~/ 2;
            return _buildModernProgress(
              steps[stepIndex]["label"], 
              steps[stepIndex]["icon"], 
              steps[stepIndex]["active"],
              onTap: steps[stepIndex]["onTap"],
            );
          } else {
            int prevStepIndex = (index - 1) ~/ 2;
            bool isLineActive = steps[prevStepIndex]["active"] && steps[prevStepIndex + 1]["active"];
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: isLineActive ? primaryTeal : const Color(0xFFE5E7EB),
                ),
              ),
            );
          }
        }),
      ),
    ]);
  }

  Widget _buildModernProgress(String label, dynamic iconOrPath, bool isActive, {VoidCallback? onTap}) {
    const Color activeColor = Color(0xFF1E5655);
    const Color inactiveColor = Color(0xFFE5E7EB);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isActive ? activeColor : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: isActive ? activeColor : inactiveColor, width: 2),
              boxShadow: isActive ? [BoxShadow(color: activeColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))] : null,
            ),
            child: Center(
              child: iconOrPath is String 
                  ? Image.asset(iconOrPath, width: 20, height: 20, color: isActive ? Colors.white : Colors.grey[400])
                  : Icon(iconOrPath as IconData, size: 18, color: isActive ? Colors.white : Colors.grey[400]),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.montserrat(fontSize: 9, fontWeight: isActive ? FontWeight.w800 : FontWeight.w600, color: isActive ? activeColor : Colors.grey[400])),
        ],
      ),
    );
  }


  // ── Chips ─────────────────────────────────────────
  Widget _buildStatusChip(String status, dynamic o) {
    final String rawDel = (o['deliveryType'] ?? o['delivery_type'] ?? '').toString().toUpperCase();
    final bool isSelfDrop = rawDel == 'SELF_DROP' || rawDel == 'SELFDROP_SELFDELIVERY' || rawDel == 'SELF_SERVICE';
    final rawStatus = status.toUpperCase();
    final displayStatus = (isSelfDrop && (rawStatus == 'WAITING_DROPOFF' || rawStatus == 'SEARCHING')) ? 'WEIGHING' : rawStatus;
    
    final pName = _getPremiumServiceName(o);
    final bool isPremium = pName.isNotEmpty;
    final Color color = isPremium ? const Color(0xFFBE123C) : StatusHelper.getColor(displayStatus);
    
    String labelText;
    if (isPremium) {
      labelText = _getPremiumProgressLabel(rawStatus);
    } else {
      labelText = StatusHelper.getLabel(displayStatus, 'ML');
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Text(labelText, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
    );
  }





  // ── Bottom Sheets ─────────────────────────────────
  void _showCourierPicker(String orderId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            final couriers = auth.couriers;
            return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text("Tunjuk Kurir", style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 18, color: darkText)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x, size: 20)),
              ]),
              const SizedBox(height: 8),
              Text("Pilih kurir anggota untuk langsung mengambil tugas ini.", style: GoogleFonts.montserrat(fontSize: 12, color: textGrey)),
              const SizedBox(height: 20),
              if (couriers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text("Belum ada kurir.", style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500))),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: couriers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final k = couriers[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        tileColor: Colors.grey[50],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
                        leading: CircleAvatar(backgroundColor: primaryTeal.withValues(alpha: 0.1), child: const Icon(LucideIcons.user, color: primaryTeal, size: 18)),
                        title: Text(k['name'] ?? "Kurir", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkText)),
                        trailing: const Icon(LucideIcons.chevronRight, size: 16, color: textGrey),
                        onTap: () async {
                          final provider = context.read<OrderProvider>();
                          Navigator.pop(context);
                          final success = await provider.assignCourier(orderId, k['identifier'] ?? k['id']);
                          if (!mounted) return;
                          _showNotif(success ? "Berhasil menunjuk kurir!" : (provider.errorMessage ?? "Gagal"), success);
                        },
                      );
                    },
                  ),
                ),
            ]);
          },
        ),
      ),
    );
  }

  void _showStatusUpdater(String orderId, String currentStatus, String deliveryType) {
    bool isSelfDrop = ['SELF_DROP', 'SELFDROP_SELFDELIVERY', 'SELF_SERVICE'].contains(deliveryType.toUpperCase());
    final stages = isSelfDrop 
        ? ['WAITING_DROPOFF', 'WEIGHING', 'WASH_START', 'IRONING', 'PACKING', 'DONE'] 
        : ['WAITING_DROPOFF', 'WEIGHING', 'WASH_START', 'IRONING', 'PACKING', 'DELIVERING', 'DONE'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildStatusUpdaterSheet(orderId, currentStatus, stages),
    );
  }

  Widget _buildStatusUpdaterSheet(String orderId, String currentStatus, List<String> stages) {
    XFile? powImage;
    bool isUploading = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Update Status Pesanan", style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 18, color: darkText)),
            const SizedBox(height: 20),
            
            // POW Capture section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.camera, size: 18, color: primaryTeal),
                      const SizedBox(width: 8),
                      Text("Foto Bukti Kerja (POW)", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkText)),
                      const Spacer(),
                      if (powImage != null)
                        const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 18),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (powImage != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(powImage!.path),
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
                        if (image != null) {
                          if (context.mounted) {
                            NyutjiLoadingOverlay.show(context, message: "Mengompresi WebP...");
                          }
                          final compressed = await NyutjiImagePicker.compressToWebP(image);
                          if (context.mounted) {
                            NyutjiLoadingOverlay.hide(context);
                            setState(() { powImage = compressed ?? image; });
                          }
                        }
                      },
                      icon: const Icon(LucideIcons.camera, size: 16),
                      label: Text(powImage == null ? "Ambil Foto" : "Ganti Foto"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryTeal,
                        side: const BorderSide(color: primaryTeal),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stages Chips
            Text("Pilih Tahapan Baru:", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13, color: textGrey)),
            const SizedBox(height: 12),
            isUploading 
              ? const Center(child: CircularProgressIndicator())
              : Wrap(
                  spacing: 10, runSpacing: 10,
                  children: stages.map((s) {
                    bool isCurrent = s == currentStatus;
                    return ActionChip(
                      label: Text(s.replaceAll('_', ' ')),
                      backgroundColor: isCurrent ? primaryTeal : Colors.grey[100],
                      labelStyle: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: isCurrent ? Colors.white : textGrey),
                      onPressed: () async {
                        if (powImage == null) {
                          _showNotif("Wajib ambil foto bukti kerja sebelum update status!", false);
                          return;
                        }

                        setState(() { isUploading = true; });
                        final provider = context.read<OrderProvider>();
                        
                        // 1. Upload POW
                        final uploadSuccess = await provider.uploadPOWImage(orderId, powImage!, s);
                        
                        if (!uploadSuccess) {
                          setState(() { isUploading = false; });
                          _showNotif(provider.errorMessage ?? "Gagal unggah foto", false);
                          return;
                        }

                        // 2. Update Status
                        final success = await provider.updateOrderStatus(orderId, s);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        if (success) _showNotif("Status diperbarui ke $s", true);
                      },
                    );
                  }).toList(),
                ),
            const SizedBox(height: 20),
          ]),
        );
      }
    );
  }

  void _showNotif(String msg, bool isSuccess) {
    if (isSuccess) {
      NyutjiNotif.showSuccess(context, msg);
    } else {
      NyutjiNotif.showError(context, msg);
    }
  }

  // ── Search & Detail Feature ───────────────────────
  Widget _buildSearchButton(OrderProvider orderProv) {
    return GestureDetector(
      onTap: () => _showSearchModal(context, orderProv),
      child: Container(
        margin: const EdgeInsets.only(left: 4, right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: const Icon(LucideIcons.search, color: Colors.white, size: 18),
      ),
    );
  }

  void _showSearchModal(BuildContext context, OrderProvider orderProv) {
    final allOrders = [...orderProv.activeOrders, ...orderProv.historyOrders];
    String searchQuery = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final filtered = searchQuery.isEmpty 
              ? [] 
              : allOrders.where((o) {
                  final q = searchQuery.toLowerCase();
                  final orderId = (o['order_number'] ?? o['orderNumber'] ?? o['identifier'] ?? o['id'] ?? '').toString().toLowerCase();
                  final customerName = (o['customer']?['name'] ?? o['customer_name'] ?? '').toString().toLowerCase();
                  final address = (o['address'] ?? o['customer_address'] ?? '').toString().toLowerCase();
                  final items = o['orderItems'] as List? ?? o['order_items'] as List? ?? o['items'] as List? ?? [];
                  bool itemMatch = items.any((it) => (it['itemName'] ?? it['item_name'] ?? it['name'] ?? '').toString().toLowerCase().contains(q));
                  
                  return orderId.contains(q) || customerName.contains(q) || address.contains(q) || itemMatch;
                }).toList();

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.9,
            decoration: const BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          autofocus: true,
                          style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: darkText),
                          decoration: InputDecoration(
                            hintText: "Cari nomor order, nama, resi...",
                            hintStyle: GoogleFonts.montserrat(fontSize: 13, color: textGrey),
                            prefixIcon: const Icon(LucideIcons.search, color: primaryTeal, size: 20),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(LucideIcons.x, size: 18, color: textGrey),
                                    onPressed: () => setState(() => searchQuery = ""),
                                  )
                                : null,
                            filled: true,
                            fillColor: bgColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onChanged: (val) => setState(() => searchQuery = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Text("Batal", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(searchQuery.isEmpty ? LucideIcons.search : LucideIcons.fileQuestion, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                searchQuery.isEmpty ? "Mulai pencarian" : "Tidak ada hasil ditemukan",
                                style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final o = filtered[index];
                            final orderId = (o['order_number'] ?? o['orderNumber'] ?? o['identifier'] ?? o['id'] ?? '-').toString();
                            final customerName = o['customer']?['name']?.toString() ?? o['customer_name']?.toString() ?? 'Pelanggan';
                            final status = (o['status'] ?? o['order_status'] ?? 'UNKNOWN').toString();
                            
                            DateTime doneAt;
                            try {
                              final doneAtRaw = o['doneAt'] ?? o['done_at'] ?? o['createdAt'] ?? o['created_at'];
                              doneAt = doneAtRaw != null ? DateTime.parse(doneAtRaw.toString()).toLocal() : DateTime.now();
                            } catch (e) {
                              doneAt = DateTime.now();
                            }

                            return GestureDetector(
                              onTap: () {
                                Navigator.pop(ctx);
                                _showOrderDetailSearch(context, o);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[100]!),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), shape: BoxShape.circle),
                                      child: const Icon(LucideIcons.package, color: primaryTeal, size: 20),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(orderId, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: primaryTeal)),
                                          const SizedBox(height: 4),
                                          Text(customerName, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkText)),
                                          const SizedBox(height: 4),
                                          Text(DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(doneAt), style: GoogleFonts.montserrat(fontSize: 11, color: textGrey)),
                                        ],
                                      ),
                                    ),
                                    _buildStatusChip(status, o),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showOrderDetailSearch(BuildContext context, dynamic o) {
    final orderId = (o['order_number'] ?? o['orderNumber'] ?? o['identifier'] ?? o['id'] ?? '-').toString();
    final customerName = o['customer']?['name']?.toString() ?? o['customer_name']?.toString() ?? 'Pelanggan';
    final customerAddress = o['address']?.toString() ?? o['customer_address']?.toString() ?? o['customer']?['address']?.toString() ?? '-';
    final courierName = o['courier']?['name']?.toString() ?? o['courier_name']?.toString() ?? 'Belum Ada';
    final serviceType = (o['service_type'] ?? o['serviceType'] ?? '').toString();
    final status = (o['status'] ?? o['order_status'] ?? 'UNKNOWN').toString();
    
    DateTime orderDate;
    try {
      final orderDateRaw = o['createdAt'] ?? o['created_at'];
      orderDate = orderDateRaw != null ? DateTime.parse(orderDateRaw.toString()).toLocal() : DateTime.now();
    } catch (e) { orderDate = DateTime.now(); }

    DateTime? finishDate;
    try {
      final finishDateRaw = o['doneAt'] ?? o['done_at'] ?? o['completedAt'] ?? o['completed_at'];
      if (finishDateRaw != null) {
        finishDate = DateTime.parse(finishDateRaw.toString()).toLocal();
      }
    } catch (e) {
      // Ignore parse error
    }

    final List<dynamic> proofs = o['proofs'] ?? [];
    final Map<String, dynamic> proofMap = {};
    for (var p in proofs) {
      final s = p['step']?.toString() ?? '';
      if (s.isNotEmpty) proofMap[s] = p;
    }

    final proofSteps = [
      {'step': 'WEIGHING', 'title': 'Timbang'},
      {'step': 'WASH_START', 'title': 'Cuci'},
      {'step': 'IRONING', 'title': 'Setrika'},
      {'step': 'PACKING', 'title': 'Packing'},
      {'step': 'DONE', 'title': 'Selesai'},
    ];
    final existingProofs = proofSteps.where((p) => proofMap.containsKey(p['step'])).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Expanded(child: Text("Detail Pesanan", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: darkText))),
                  IconButton(icon: const Icon(LucideIcons.x, size: 20), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                physics: const BouncingScrollPhysics(),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailSearchRow("Nomor Order", orderId),
                        const Divider(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Pelanggan", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: textGrey)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    customerName, 
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: darkText),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    customerAddress,
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w500, color: textGrey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _buildDetailSearchRow("Kurir", courierName),
                        const Divider(height: 20),
                        _buildDetailSearchRow("Layanan", serviceType.isNotEmpty ? serviceType : 'Reguler'),
                        const Divider(height: 20),
                        _buildDetailSearchRow("Tgl Order", DateFormat('dd MMM yyyy, HH:mm').format(orderDate)),
                        if (finishDate != null) ...[
                          const Divider(height: 20),
                          _buildDetailSearchRow("Tgl Selesai", DateFormat('dd MMM yyyy, HH:mm').format(finishDate)),
                        ],
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Status", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: textGrey)),
                            _buildStatusChip(status, o),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text("Items", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: darkText)),
                  const SizedBox(height: 12),
                  _buildDetailPesanan(o),
                  const SizedBox(height: 24),

                  Text("Dokumentasi Proses", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: darkText)),
                  const SizedBox(height: 12),
                  existingProofs.isEmpty 
                    ? Text("Tidak ada gambar dokumentasi", style: GoogleFonts.montserrat(fontSize: 13, color: textGrey, fontStyle: FontStyle.italic))
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85
                        ),
                        itemCount: existingProofs.length,
                        itemBuilder: (context, index) {
                          final pDef = existingProofs[index];
                          final pData = proofMap[pDef['step']];
                          
                          final String path = pData['file_url'].toString().replaceAll('\\', '/').replaceAll(RegExp(r'^/+'), '');
                          final imageUrl = path.startsWith('http') ? path : "${ApiConstants.rootUrl}/$path";
                          
                          return GestureDetector(
                            onTap: () => _showPowDialog([pData], [pDef['step'].toString()], pDef['title'].toString()),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0,2))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                      child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Center(child: Icon(LucideIcons.imageOff, color: Colors.grey))),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(12))
                                    ),
                                    child: Text(
                                      pDef['title'].toString(),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w800, color: primaryTeal),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSearchRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: textGrey)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value, 
            textAlign: TextAlign.right,
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: darkText),
          ),
        ),
      ],
    );
  }
}
