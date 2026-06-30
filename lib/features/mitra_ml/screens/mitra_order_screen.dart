import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../core/utils/status_helper.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/nyutji_image_picker.dart';
import '../../../core/widgets/nyutji_loading_overlay.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../core/widgets/nyutji_dot.dart';
import '../../chat/screens/chat_screen.dart';
import '../../chat/utils/chat_utils.dart';

class MitraOrderScreen extends ConsumerStatefulWidget {
  const MitraOrderScreen({super.key});
  @override ConsumerState<MitraOrderScreen> createState() => _MitraOrderScreenState();
}

class _MitraOrderScreenState extends ConsumerState<MitraOrderScreen> {
  static const Color primaryTeal = Color(0xFF1E5655);
  static const Color bgColor = Color(0xFFF3F4F6);
  static const Color darkText = Color(0xFF111827);
  static const Color textGrey = Color(0xFF6B7280);

  String currentFilter = "Reguler";
  final Set<String> _expandedIds = {};
  late PageController _pageController;
  late ScrollController _summaryScrollController;
  late ScrollController _pillScrollController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _summaryScrollController = ScrollController();
    _pillScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(orderProvider).fetchOrders();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _summaryScrollController.dispose();
    _pillScrollController.dispose();
    super.dispose();
  }

  bool _isFromSpecialMenus(dynamic o) {
    final items = o['orderItems'] as List? ?? o['order_items'] as List? ?? o['items'] as List?;
    if (items != null && items.isNotEmpty) {
      for (var it in items) {
        if (it is Map) {
          final note = (it['notes'] ?? '').toString().toLowerCase();
          if (note.contains('cuci khusus premium') ||
              note.contains('shoecare premium') ||
              note.contains('dry cleaning premium') ||
              note.contains('baby care laundry premium')) {
            return true;
          }
        }
      }
    }
    return false;
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
      final step = (proof['step'] ?? '').toString().toUpperCase();
      if (targetStages.contains(step)) {
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
                  fit: StackFit.expand,
                  children: [
                    // Gambar
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => const SizedBox(
                          height: 260,
                          child: Center(child: CircularProgressIndicator(color: primaryTeal)),
                        ),
                        errorWidget: (context, url, error) => const SizedBox(
                          height: 260,
                          child: Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50)),
                        ),
                      ),
                    ),
                    // Watermark 1 — kiri atas
                    Positioned(
                      top: 40, left: -10,
                      child: IgnorePointer(
                        child: Transform.rotate(
                          angle: -0.785,
                          child: Text(
                            'Nyutji Management',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white.withValues(alpha: 0.45),
                              letterSpacing: 1.2,
                              shadows: [const Shadow(color: Colors.black38, blurRadius: 4)],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Watermark 2 — tengah (sedikit geser kanan)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Align(
                          alignment: const Alignment(0.2, 0.0),
                          child: Transform.rotate(
                            angle: -0.785,
                            child: Text(
                              'Nyutji Management',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
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
                    // Watermark 3 — kanan bawah
                    Positioned(
                      bottom: 60, right: -10,
                      child: IgnorePointer(
                        child: Transform.rotate(
                          angle: -0.785,
                          child: Text(
                            'Nyutji Management',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.white.withValues(alpha: 0.45),
                              letterSpacing: 1.2,
                              shadows: [const Shadow(color: Colors.black38, blurRadius: 4)],
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
    NyutjiNotif.showInfo(context, "Foto bukti belum tersedia untuk tahapan ini");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Consumer(
        builder: (context, ref, _) {
final orderProv = ref.watch(orderProvider);
          final List<dynamic> baseOrders = (currentFilter == "Baru")
              ? orderProv.activeOrders
              : [...orderProv.activeOrders, ...orderProv.historyOrders];

          final bool hasNewOrders = orderProv.activeOrders.any((o) {
            final s = (o['status'] ?? o['order_status'] ?? '').toString().toUpperCase();
            return s == 'SEARCHING' || s == 'WAITING_DROPOFF';
          });

          final filtered = baseOrders.where((o) {
            final status = (o['status'] ?? o['order_status'] ?? '').toString().toUpperCase();
            if (status == 'DRAFT') return false;
            final isFast = o['is_fast_track'] == true || o['is_fast_track'] == 1 || o['isFastTrack'] == true;
            final serviceType = (o['service_type'] ?? o['serviceType'] ?? '').toString().toUpperCase();
            if (currentFilter == "Baru") return status == 'SEARCHING' || status == 'WAITING_DROPOFF';
            if (currentFilter == "Same Day") return (isFast || serviceType.contains('SAME')) && status != 'DONE' && status != 'PAID';
            if (currentFilter == "Reguler") return (serviceType.contains('REGULER') || serviceType.contains('BIASA')) && status != 'DONE' && status != 'PAID';
            if (currentFilter == "Selesai") return status == 'DONE' || status == 'PAID';
            return false;
          }).toList();

          filtered.sort((a, b) {
            DateTime getParsedDate(dynamic o) {
              dynamic val;
              if (currentFilter == "Selesai") {
                val = o['doneAt'] ?? o['done_at'] ?? o['updated_at'] ?? o['updatedAt'] ?? o['createdAt'] ?? o['created_at'];
              } else {
                val = o['createdAt'] ?? o['created_at'] ?? o['updated_at'] ?? o['updatedAt'];
              }
              if (val == null) return DateTime.fromMillisecondsSinceEpoch(0);
              return DateTime.tryParse(val.toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
            }
            return getParsedDate(b).compareTo(getParsedDate(a));
          });

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
                controller: _pillScrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  ...["Reguler", "Same Day", "Selesai"].map((f) {
                    int count = 0;
                    final allList = [...orderProv.activeOrders, ...orderProv.historyOrders];
                    for (var o in allList) {
                      final s = (o['status'] ?? o['order_status'] ?? '').toString().toUpperCase();
                      if (s == 'DRAFT') continue;
                      final isFast = o['is_fast_track'] == true || o['is_fast_track'] == 1 || o['isFastTrack'] == true;
                      final serviceType = (o['service_type'] ?? o['serviceType'] ?? '').toString().toUpperCase();
                      
                      if (f == "Same Day" && (isFast || serviceType.contains('SAME')) && s != 'DONE' && s != 'PAID') {
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
    final bool hasCount = count > 0 && label != "Selesai";
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
            NyutjiDot.badge(count: count),
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
              onRefresh: () => ref.read(orderProvider).fetchOrders(force: true),
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

  void _animateScrolls(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_summaryScrollController.hasClients) {
        double targetOffset = index * 274.0;
        final maxScroll = _summaryScrollController.position.maxScrollExtent;
        if (targetOffset > maxScroll) targetOffset = maxScroll;
        if (targetOffset < 0) targetOffset = 0;
        _summaryScrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
      if (_pillScrollController.hasClients) {
        double targetOffset = index * 100.0;
        final maxScroll = _pillScrollController.position.maxScrollExtent;
        if (targetOffset > maxScroll) targetOffset = maxScroll;
        if (targetOffset < 0) targetOffset = 0;
        _pillScrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _animateSummaryScrollForFilter(String filter) {
    if (filter == "Reguler") {
      _animateScrolls(0);
    } else if (filter == "Same Day") {
      _animateScrolls(1);
    } else if (filter == "Selesai") {
      _animateScrolls(2);
    }
  }

  Widget _buildSummaryCards(OrderProvider orderProv) {
    final allOrders = [...orderProv.activeOrders, ...orderProv.historyOrders];
    
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
      
      if (status == 'DRAFT') continue;

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
            label: "Reguler",
            value: "${currencyFormatter.format(totalReguler)} | $countReguler",
            isActive: currentFilter == "Reguler",
            activeColor: const Color(0xFF2563EB),
            icon: LucideIcons.calendar,
            onTap: () {
              _animateScrolls(0);
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
            label: "Same Day",
            value: "${currencyFormatter.format(totalSameDay)} | $countSameDay",
            isActive: currentFilter == "Same Day",
            activeColor: const Color(0xFFEA580C),
            icon: LucideIcons.zap,
            onTap: () {
              _animateScrolls(1);
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
            label: "Selesai",
            value: "${currencyFormatter.format(totalSelesai)} | $countSelesai",
            isActive: currentFilter == "Selesai",
            activeColor: const Color(0xFF10B981),
            icon: LucideIcons.checkCircle,
            onTap: () {
              _animateScrolls(2);
              if (currentFilter != "Selesai") {
                setState(() {
                  currentFilter = "Selesai";
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
            onRefresh: () => ref.read(orderProvider).fetchOrders(force: true),
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
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        customerName,
                        maxLines: 1, 
                        style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w900, color: darkText, letterSpacing: -0.3)
                      ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
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
                          const SizedBox(width: 8),
                          Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey[400], shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(DateFormat('dd MMM', 'id_ID').format(doneAt),
                            style: GoogleFonts.montserrat(fontSize: 11, color: textGrey, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildStatusChip(status, o),
                ],
              ),
            ],
          )
        ),
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
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            customerName,
                            maxLines: 1, 
                            style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: darkText, letterSpacing: -0.3)
                          ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Container(
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
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildStatusChip(status, o),
                    ],
                  ),
                ],
              ),
            ),
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
                  _buildDetailInfoItem("Tanggal Selesai", DateFormat('dd MMM, HH:mm', 'id_ID').format(doneAt), LucideIcons.calendar),
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

        const SizedBox(height: 24),
        
        // ── Chat & Call Buttons ──
        _buildChatCallButtons(o, status),

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
                  _showStatusUpdater(orderId, status, deliveryType, o);
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

  Widget _buildChatCallButtons(dynamic order, String status) {
    final orderNumber = (order['order_number'] ?? order['orderNumber'] ?? '').toString();
    final customerName = (order['customer'] is Map ? order['customer']['name'] : null) ??
        order['customer_name'] ?? 'Pelanggan';
    final customerPhoto = ChatUtils.extractPhoto(order['customer_name'] ?? order['customer']);
        
    // Parse Courier Name using ChatUtils
    final courierName = ChatUtils.extractName(order['courier_name'] ?? order['courier']);
    final courierPhoto = ChatUtils.extractPhoto(order['courier_name'] ?? order['courier']);
    
    final rawDel = (order['deliveryType'] ?? order['delivery_type'] ?? '').toString();
    final isCourierNeeded = ChatUtils.isCourierNeeded(rawDel, status);
    
    final hasCourier = isCourierNeeded && courierName.isNotEmpty && courierName != 'null' && courierName != '-' && courierName != 'Belum Ada' && courierName != 'Kurir';

    return Row(
      children: [
        // Chat dengan Pelanggan
        Expanded(
          child: _chatCallBtn(
            icon: LucideIcons.messageCircle,
            label: 'Chat Pelanggan',
            color: const Color(0xFF0D9488),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  orderNumber: orderNumber,
                  channel: 'PL_ML', // Channel is Customer-Mitra
                  partnerName: customerName,
                  partnerRole: 'PL',
                  partnerPhoto: customerPhoto,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Chat dengan Kurir (hanya jika kurir sudah assigned)
        if (hasCourier) ...[
          Expanded(
            child: _chatCallBtn(
              icon: LucideIcons.messageSquare,
              label: 'Chat Kurir',
              color: const Color(0xFF7C3AED),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    orderNumber: orderNumber,
                    channel: 'KL_ML', // Channel is Courier-Mitra
                    partnerName: courierName,
                    partnerRole: 'KL',
                    partnerPhoto: courierPhoto,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _chatCallBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
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
    
    String? orderNote;
    if (items != null && items.isNotEmpty) {
      for (var it in items) {
        final notes = (it['notes'] ?? '').toString().trim();
        if (notes.isNotEmpty) {
          orderNote = notes;
          break;
        }
      }
    }

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
              children: [
                ...items.map<Widget>((it) {
                  final name = (it['itemName'] ?? it['item_name'] ?? it['name'] ?? 'Layanan Laundry').toString();
                  final qty = double.tryParse(it['qty']?.toString() ?? '1') ?? 1.0;
                  final unitText = (it['unit'] ?? 'Pcs').toString();
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
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
                  );
                }),
                if (orderNote != null && orderNote.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  const Divider(color: Color(0xFFE5E7EB), height: 16, thickness: 1),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      (orderNote.toLowerCase().contains('timbangan') || orderNote.toLowerCase().contains('berat'))
                          ? Image.asset(
                              'assets/icons/scale.png',
                              width: 16,
                              height: 16,
                              color: primaryTeal,
                            )
                          : const Icon(
                              LucideIcons.info,
                              color: primaryTeal,
                              size: 16,
                            ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          orderNote,
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
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
    final int step = StatusHelper.getProgressStep(status);
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
              "onTap": () {
                if (status.toUpperCase() == 'WAITING_DROPOFF') {
                  NyutjiNotif.showInfo(context, "Pesanan masih dalam status WAITING_DROPOFF (Menunggu Drop-off). Penimbangan baru bisa dilakukan setelah cucian diterima.");
                } else {
                  _showPowDialog(o['proofs'], ['WEIGHING', 'SEARCHING', 'WAITING_DROPOFF'], isPremium ? "Diterima" : "Timbang");
                }
              }
            },
            {
              "label": "Cuci", 
              "icon": LucideIcons.droplets, 
              "active": isStep2,
              "onTap": () => _showPowDialog(o['proofs'], ['WASH_START', 'IN_PROGRESS'], "Cuci")
            },
            {
              "label": "Packing", 
              "icon": LucideIcons.package, 
              "active": isStep3,
              "onTap": () => _showPowDialog(o['proofs'], ['IRONING', 'PACKING'], "Packing")
            },
            {
              "label": "Selesai", 
              "icon": LucideIcons.checkCircle, 
              "active": isStep5,
              "onTap": () => _showPowDialog(o['proofs'], ['DONE'], "Selesai")
            },
          ]
        : [
            {
              "label": isPremium ? "Diterima" : "Timbang", 
              "icon": isPremium ? LucideIcons.packageCheck : 'assets/icons/scale.png', 
              "active": isStep1,
              "onTap": () {
                if (status.toUpperCase() == 'WAITING_DROPOFF') {
                  NyutjiNotif.showInfo(context, "Pesanan masih dalam status WAITING_DROPOFF (Menunggu Drop-off). Penimbangan baru bisa dilakukan setelah cucian diterima.");
                } else {
                  _showPowDialog(o['proofs'], ['WEIGHING', 'SEARCHING', 'WAITING_DROPOFF'], isPremium ? "Diterima" : "Timbang");
                }
              }
            },
            {
              "label": "Cuci", 
              "icon": LucideIcons.droplets, 
              "active": isStep2,
              "onTap": () => _showPowDialog(o['proofs'], ['WASH_START', 'IN_PROGRESS'], "Cuci")
            },
            {
              "label": "Packing", 
              "icon": LucideIcons.package, 
              "active": isStep3,
              "onTap": () => _showPowDialog(o['proofs'], ['IRONING', 'PACKING'], "Packing")
            },
            {
              "label": "Kirim", 
              "icon": LucideIcons.navigation, 
              "active": isStep4,
              "onTap": () => _showPowDialog(o['proofs'], ['DELIVERING'], "Kirim")
            },
            {
              "label": "Selesai", 
              "icon": LucideIcons.checkCircle, 
              "active": isStep5,
              "onTap": () => _showPowDialog(o['proofs'], ['DONE'], "Selesai")
            },
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
            return const Expanded(child: SizedBox());
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
            width: 44, height: 44,
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
          MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: isActive ? FontWeight.w800 : FontWeight.w600, color: isActive ? activeColor : Colors.grey[400])),
            ),
          ),
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
    
    // Convert to Title Case (First Letter of Each Word is Uppercase)
    labelText = labelText.toLowerCase().split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
    
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
        child: Consumer(
          builder: (context, ref, _) {
final auth = ref.watch(authProvider);
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
                          final provider = ref.read(orderProvider);
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

  void _showStatusUpdater(String orderId, String currentStatus, String deliveryType, dynamic o) async {
    bool isSelfDrop = ['SELF_DROP', 'SELFDROP_SELFDELIVERY', 'SELF_SERVICE'].contains(deliveryType.toUpperCase());
    final List<String> stages = isSelfDrop 
        ? ['WAITING_DROPOFF', 'WEIGHING', 'WASH_START', 'IRONING', 'PACKING', 'DONE'] 
        : ['WAITING_DROPOFF', 'WEIGHING', 'WASH_START', 'IRONING', 'PACKING', 'DELIVERING', 'DONE'];

    if (_isFromSpecialMenus(o)) {
      stages.remove('WEIGHING');
    }

    final proofs = o['proofs'] as List? ?? [];
    final bool hasWeighingProofByML = proofs.any((p) {
      if (p is! Map) return false;
      final stepVal = (p['step'] ?? '').toString().toUpperCase();
      final uploaderRoleVal = (p['uploader_role'] ?? p['uploaderRole'] ?? '').toString().toUpperCase();
      return stepVal == 'WEIGHING' && uploaderRoleVal == 'ML';
    });

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StatusUpdaterSheet(
        orderId: orderId,
        currentStatus: currentStatus,
        stages: stages,
        hasWeighingProofByML: hasWeighingProofByML,
      ),
    );

    if (result != null && result is Map) {
      if (context.mounted) {
        _showNotif(result['msg'], result['success']);
      }
    }
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
                  
                  String dateStr = '';
                  try {
                    final dtRaw = o['createdAt'] ?? o['created_at'] ?? o['doneAt'] ?? o['done_at'];
                    if (dtRaw != null) {
                      final dt = DateTime.parse(dtRaw.toString()).toLocal();
                      final months = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
                      final shortMonths = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
                      dateStr = '${dt.day} ${months[dt.month - 1]} ${dt.year} ${dt.day} ${shortMonths[dt.month - 1]} ${dt.year} ${dt.day}-${dt.month}-${dt.year} ${dt.day}/${dt.month}/${dt.year}'.toLowerCase();
                    }
                  } catch (_) {}

                  return orderId.contains(q) || customerName.contains(q) || address.contains(q) || itemMatch || dateStr.contains(q);
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
                        _buildDetailSearchRow("Layanan", serviceType.isNotEmpty ? serviceType.replaceAll('_', ' ').toLowerCase().split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ') : 'Reguler'),
                        const Divider(height: 20),
                        _buildDetailSearchRow("Tgl Order", DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(orderDate)),
                        if (finishDate != null) ...[
                          const Divider(height: 20),
                          _buildDetailSearchRow("Tgl Selesai", DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(finishDate)),
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
                                      child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover, errorWidget: (_,__,___) => const Center(child: Icon(LucideIcons.imageOff, color: Colors.grey))),
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

class _StatusUpdaterSheet extends ConsumerStatefulWidget {
  final String orderId;
  final String currentStatus;
  final List<String> stages;
  final bool hasWeighingProofByML;

  const _StatusUpdaterSheet({
    required this.orderId,
    required this.currentStatus,
    required this.stages,
    required this.hasWeighingProofByML,
  });

  @override
  ConsumerState<_StatusUpdaterSheet> createState() => _StatusUpdaterSheetState();
}

class _StatusUpdaterSheetState extends ConsumerState<_StatusUpdaterSheet> {
  static const Color primaryTeal = Color(0xFF1E5655);
  static const Color darkText = Color(0xFF111827);
  static const Color textGrey = Color(0xFF6B7280);

  XFile? powImage;
  bool isUploading = false;
  String? selectedStage;
  late final TextEditingController noteController;

  @override
  void initState() {
    super.initState();
    noteController = TextEditingController(text: "Berat timbangan cucian ... kg");
    if (widget.stages.contains('WEIGHING') && widget.currentStatus == 'WEIGHING' && !widget.hasWeighingProofByML) {
      selectedStage = 'WEIGHING';
    }
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  void _showNotif(String msg, bool isSuccess) {
    if (isSuccess) {
      NyutjiNotif.showSuccess(context, msg);
    } else {
      NyutjiNotif.showError(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardPadding),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
        padding: EdgeInsets.fromLTRB(24, 24, 24, keyboardPadding > 0 ? 16 : bottomPadding + 24),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Update Status Pesanan", 
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 18, color: darkText)
              ),
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
                        Text(
                          "Foto Progress Nyutji", 
                          style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkText)
                        ),
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
              Text(
                "Pilih Tahapan Baru:", 
                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13, color: textGrey)
              ),
              const SizedBox(height: 12),
              if (isUploading)
                const Center(child: CircularProgressIndicator(color: primaryTeal))
              else
                Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 3.5,
                      ),
                      itemCount: widget.stages.length,
                      itemBuilder: (ctx, index) {
                        final s = widget.stages[index];
                        final bool isCurrent = s == selectedStage;
                        final bool isPast = s == 'WEIGHING'
                            ? (widget.hasWeighingProofByML || StatusHelper.getProgressStep(s) < StatusHelper.getProgressStep(widget.currentStatus))
                            : StatusHelper.getProgressStep(s) <= StatusHelper.getProgressStep(widget.currentStatus);
                        final Map<String, String> statusLabels = {
                          'WAITING_DROPOFF': 'Drop Off',
                          'WEIGHING': 'Penimbangan',
                          'WASH_START': 'Proses Cuci',
                          'IRONING': 'Proses Setrika',
                          'PACKING': 'Packing',
                          'DELIVERING': 'Pengiriman',
                          'DONE': 'Selesai',
                        };
                        final Map<String, String> statusEmojis = {
                          'WAITING_DROPOFF': '🕒',
                          'WEIGHING': '📋',
                          'WASH_START': '▶️',
                          'IRONING': '💨',
                          'PACKING': '📦',
                          'DELIVERING': '🚚',
                          'DONE': '☑️',
                        };
                        String label = statusLabels[s] ?? s.replaceAll('_', ' ');

                        return InkWell(
                          onTap: isPast ? null : () async {
                            if (powImage == null) {
                              _showNotif("Wajib ambil foto progress sebelum update status!", false);
                              return;
                            }

                            if (s == 'WEIGHING') {
                              setState(() { selectedStage = 'WEIGHING'; });
                              return;
                            }

                            setState(() { isUploading = true; });
                            final provider = ref.read(orderProvider);
                            
                            // 1. Upload POW
                            final uploadSuccess = await provider.uploadPOWImage(widget.orderId, powImage!, s);
                            
                            if (!uploadSuccess) {
                              setState(() { isUploading = false; });
                              _showNotif(provider.errorMessage ?? "Gagal unggah foto", false);
                              return;
                            }

                            // 2. Update Status
                            final success = await provider.updateOrderStatus(widget.orderId, s);
                            
                            if (mounted) {
                              if (success) {
                                NyutjiNotif.showSuccess(this.context, "Status diperbarui $label");
                                Navigator.pop(this.context);
                              } else {
                                setState(() { isUploading = false; });
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isCurrent ? primaryTeal : (isPast ? Colors.grey[300] : Colors.grey[100]),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isCurrent ? primaryTeal : (isPast ? Colors.grey[400]! : Colors.grey[300]!)),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  statusEmojis[s] ?? '✨',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isPast ? Colors.grey[500] : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    label,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold, 
                                      color: isCurrent ? Colors.white : (isPast ? Colors.grey[500] : darkText)
                                    ),
                                    textAlign: TextAlign.left,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: selectedStage == 'WEIGHING'
                          ? Container(
                              key: const ValueKey('weighing_note_box'),
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDFBF7),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE3DCCF), width: 1.5),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.scale, color: primaryTeal, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Konfirmasi Berat Timbangan Kg",
                                        style: GoogleFonts.montserrat(
                                          fontSize: 12, 
                                          fontWeight: FontWeight.w800, 
                                          color: darkText
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: noteController,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12, 
                                      fontWeight: FontWeight.w600, 
                                      color: darkText
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: primaryTeal, width: 1.5),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: InkWell(
                                      onTap: () async {
                                        if (powImage == null) {
                                          _showNotif("Wajib ambil foto progress sebelum menyimpan timbangan!", false);
                                          return;
                                        }
                                        setState(() { isUploading = true; });
                                        final provider = ref.read(orderProvider);
                                        
                                        // 1. Simpan notes ke database
                                        final saveNotesSuccess = await provider.saveOrderNotes(widget.orderId, noteController.text);
                                        if (!saveNotesSuccess) {
                                          setState(() { isUploading = false; });
                                          _showNotif(provider.errorMessage ?? "Gagal menyimpan notes", false);
                                          return;
                                        }

                                        // 2. Upload POW
                                        final uploadSuccess = await provider.uploadPOWImage(widget.orderId, powImage!, 'WEIGHING');
                                        if (!uploadSuccess) {
                                          setState(() { isUploading = false; });
                                          _showNotif(provider.errorMessage ?? "Gagal unggah foto", false);
                                          return;
                                        }

                                        // 3. Update Status ke WEIGHING
                                        final statusSuccess = await provider.updateOrderStatus(widget.orderId, 'WEIGHING');
                                        
                                        if (mounted) {
                                          if (statusSuccess) {
                                            NyutjiNotif.showSuccess(this.context, "Status diperbarui Penimbangan & Notes Disimpan");
                                            Navigator.pop(this.context);
                                          } else {
                                            setState(() { isUploading = false; });
                                          }
                                        }
                                      },
                                      child: Text(
                                        "Simpan Notes",
                                        style: GoogleFonts.montserrat(
                                          fontSize: 12, 
                                          fontWeight: FontWeight.w900, 
                                          color: primaryTeal,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
