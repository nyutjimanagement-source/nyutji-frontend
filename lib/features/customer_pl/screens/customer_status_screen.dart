import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../providers/order_provider.dart';
import 'customer_order_screen.dart';
import 'customer_review_screen.dart';
import '../../../core/utils/status_helper.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomerStatusScreen extends ConsumerStatefulWidget {
  const CustomerStatusScreen({super.key});

  @override ConsumerState<CustomerStatusScreen> createState() => _CustomerStatusScreenState();
}

class _CustomerStatusScreenState extends ConsumerState<CustomerStatusScreen> {
  final Color primaryTeal = const Color(0xFF403600);
  final Color accentGreen = const Color(0xFF22C55E);
  final Color darkBg = const Color(0xFF131109);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final provider = ref.read(orderProvider);
        await provider.fetchOrders();
        await provider.markAllPLOrdersAsSeen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = ref.watch(orderProvider);

    if (orderProv.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF9ED),
        body: Column(
          children: [
            _buildPremiumHeader("Status Pesanan"),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE3DCCF), width: 1.2),
                      boxShadow: [BoxShadow(color: const Color(0xFF403600).withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ShimmerLoading(height: 52, width: 52, borderRadius: 18),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerLoading(height: 14, width: 150, borderRadius: 4),
                              SizedBox(height: 8),
                              ShimmerLoading(height: 18, width: 100, borderRadius: 4),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ShimmerLoading(height: 14, width: 60, borderRadius: 4),
                            SizedBox(height: 4),
                            ShimmerLoading(height: 10, width: 80, borderRadius: 2),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    if (orderProv.activeOrders.isNotEmpty) {
      return _buildActiveOrdersList(orderProv.activeOrders);
    }

    return _buildEmptyState();
  }

  Widget _buildPremiumHeader(String title, {bool showBack = true, String? subtitle}) {
    return ClipPath(
      clipper: HeaderClipper(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 50, 16, 70),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF403600), Color(0xFF5A4D00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showBack)
              IconButton(
                icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/customer_main', (route) => false),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle,
                        style: GoogleFonts.montserrat(fontSize: 14, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9ED),
      body: Column(
        children: [
          _buildPremiumHeader("Status Pesanan"),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: primaryTeal.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.package, size: 56, color: primaryTeal.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(height: 28),
                    Text("Belum Ada Pesanan Aktif",
                      style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, color: darkBg)),
                    const SizedBox(height: 10),
                    Text(
                      "Buat pesanan laundry pertamamu\ndan pantau statusnya di sini secara real-time.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600], height: 1.6),
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CustomerOrderScreen(orderType: 'pickup')),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        decoration: BoxDecoration(
                          color: primaryTeal,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [BoxShadow(color: primaryTeal.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
                        ),
                        child: Text("Buat Pesanan",
                          style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersList(List<dynamic> orders) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9ED),
      body: Column(
        children: [
          _buildPremiumHeader(
            "Status Pesanan",
            subtitle: "Ada ${orders.length} Pesanan Milik Anda"
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              physics: const BouncingScrollPhysics(),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                debugPrint("Nyutji Debug Order [$index]: ${order['order_number'] ?? order['orderNumber']} -> Keys: ${order.keys.toList()}");
                return PremiumOrderCard(order: order);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// PREMIUM ORDER CARD
// ─────────────────────────────────────────
class PremiumOrderCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> order;
  const PremiumOrderCard({super.key, required this.order});

  @override ConsumerState<PremiumOrderCard> createState() => _PremiumOrderCardState();
}

class _PremiumOrderCardState extends ConsumerState<PremiumOrderCard> {
  bool isExpanded = false;
  bool _isFirstBuild = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isFirstBuild = false;
        });
      }
    });
  }



  String _formatNyutjiDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == "-") return "-";
    try {
      DateTime? dt;
      if (dateStr.contains('T')) {
        dt = DateTime.tryParse(dateStr);
      } else if (dateStr.contains('/')) {
        final p = dateStr.split('/');
        dt = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
      } else if (dateStr.contains('-')) {
        final p = dateStr.split('-');
        if (p[0].length == 4) {
          dt = DateTime.tryParse(dateStr);
        } else {
          dt = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
        }
      }
      if (dt == null) return dateStr;
      final dtLocal = dt.toLocal(); // konversi UTC → WIB
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return "${dtLocal.day} ${months[dtLocal.month - 1]}";
    } catch (e) {
      return dateStr;
    }
  }

  String _resolveOrderIconPath(Map<String, dynamic> order, List? items) {
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
      return 'assets/icons/icon_sepatu.png';
    }
    if (textToScan.contains('dryclean') || textToScan.contains('dry clean') || textToScan.contains('jas') || textToScan.contains('kebaya') || textToScan.contains('gaun')) {
      return 'assets/icons/icon_dryclean.png';
    }
    if (textToScan.contains('bayi') || textToScan.contains('baby') || textToScan.contains('pakaian bayi')) {
      return 'assets/icons/icon_bayi.png';
    }
    if (textToScan.contains('khusus') || textToScan.contains('stroller') || textToScan.contains('cuci khusus')) {
      return 'assets/icons/baby_stroller.png';
    }
    
    return 'assets/icons/icon_keranjang.png';
  }

  String _getPremiumServiceName(Map<String, dynamic> order, List? items) {
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

  String _getCourierStatusText(Map<String, dynamic> order) {
    final rawCourier = order['courier_name'] ?? order['courier'] ?? order['petugas_kurir'];
    if (rawCourier == null || rawCourier.toString().isEmpty || rawCourier.toString() == "null") {
      final status = (order['order_status'] ?? order['status'] ?? '').toString().toUpperCase();
      if (status.contains('SEARCHING')) return "Sedang Mencari Kurir";
      if (status.contains('WASH') || status.contains('PACK')) return "Kurir Tugas Lain";
      if (status.contains('PICKUP')) return "Kurir Menuju Ke Lokasi Anda";
      if (status.contains('DELIVERY')) return "Kurir Sedang Mengantar Cucian";
      return "Sedang Mencari Kurir";
    }
    // Parse format {name: ..., identifier: ...}
    final courierStr = rawCourier.toString();
    if (courierStr.contains('name:')) {
      try {
        final parts = courierStr.split('name:');
        if (parts.length > 1) {
          return parts[1].split(',')[0].replaceAll(RegExp(r'[{}]'), '').trim();
        }
      } catch (e) {
        return courierStr.replaceAll(RegExp(r'[{}]'), '').trim();
      }
    }
    return courierStr;
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

    final String path = foundProof['file_url'].toString().replaceAll(RegExp(r'^/+'), '');
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
                          style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF403600)),
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
                                child: Center(child: CircularProgressIndicator(color: Color(0xFF403600))),
                            ),
                            errorWidget: (context, url, error) => const SizedBox(
                                height: 220,
                                child: Center(child: Icon(Icons.broken_image_outlined, size: 52, color: Colors.grey)),
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
                                  color: Colors.white.withValues(alpha: 0.38),
                                  letterSpacing: 1.0,
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
                                    color: Colors.white.withValues(alpha: 0.42),
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
                                  color: Colors.white.withValues(alpha: 0.35),
                                  letterSpacing: 1.0,
                                  shadows: [const Shadow(color: Colors.black38, blurRadius: 4)],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Gradient + Info overlay bawah
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
                    ),
                  ),
                ),
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
    final order = widget.order;
    final String s = (order['status'] ?? order['order_status'] ?? '').toString().toUpperCase();
    final bool isFinished = s == 'DONE' || s == 'PAID';
    final bool isDraft = s == 'DRAFT';
    final bool showExpanded = (!isFinished && !isDraft) || isExpanded;

    final String rawDel = (order['deliveryType'] ?? order['delivery_type'] ?? '').toString().toUpperCase();
    final isFastTrack = (order['is_fast_track'] ?? false).toString() == 'true' || 
                        (order['isFastTrack'] ?? false).toString() == 'true' ||
                        order['service_type']?.toString().toLowerCase().contains('fast') == true ||
                        order['serviceType']?.toString().toLowerCase().contains('fast') == true ||
                        order['service_type']?.toString().toLowerCase().contains('same') == true ||
                        order['serviceType']?.toString().toLowerCase().contains('same') == true;

    // 1. Logic totalQty & Unit (Genius Mapping)
    double totalQty = 0;
    String unit = "Kg";
    // Cek berbagai kemungkinan key dari backend (camelCase vs snake_case)
    final items = order['orderItems'] as List? ?? order['order_items'] as List? ?? order['items'] as List?;
    
    if (items != null && items.isNotEmpty) {
      for (var it in items) {
        totalQty += double.tryParse(it['qty']?.toString() ?? '0') ?? 0;
      }
      unit = items.first['unit']?.toString() ?? 'Kg';
    } else {
      totalQty = double.tryParse(order['total_qty']?.toString() ?? order['qty']?.toString() ?? '0') ?? 0;
      unit = order['unit']?.toString() ?? 'Kg';
    }

    // 2. Logic orderDate (Tgl Masuk)
    // Utamakan createdAt dari order, fallback ke items
    final rawDate = order['createdAt'] ?? order['created_at'] ?? (items != null && items.isNotEmpty ? items.first['created_at'] : null);
    final String orderDate = rawDate?.toString() ?? "-";

    // 3. Logic Tgl Selesai (done_at) dengan Fallback Estimasi Dinamis (Genius & Robust)
    String completionDate = order['done_at']?.toString() ?? order['doneAt']?.toString() ?? order['tgl_selesai']?.toString() ?? "-";
    if (completionDate == "-" || completionDate == "null" || completionDate.trim().isEmpty) {
      final sUpper = (order['status'] ?? order['order_status'] ?? '').toString().toUpperCase();
      if (sUpper == 'DONE' || sUpper == 'PAID') {
        completionDate = order['updatedAt']?.toString() ?? order['updated_at']?.toString() ?? "-";
      } else {
        if (rawDate != null && rawDate.toString() != "-") {
          final parsedDate = DateTime.tryParse(rawDate.toString());
          if (parsedDate != null) {
            final estDate = isFastTrack ? parsedDate.add(const Duration(days: 1)) : parsedDate.add(const Duration(days: 3));
            completionDate = estDate.toIso8601String();
          }
        }
      }
    }

    // 4. Logic mitraName (Relasi Mitra)
    // Backend baru mengirimkan objek mitra: { name: "..." }
    final mitraName = (order['mitra'] is Map ? order['mitra']['name'] : null) ?? 
                      order['mitra_name'] ?? 
                      order['courier_name'] ?? 
                      order['petugas_kurir'] ?? "-";

    return AnimatedSize(
      duration: _isFirstBuild ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE3DCCF), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF403600).withValues(alpha: 0.06), 
              blurRadius: 15, 
              offset: const Offset(0, 6)
            )
          ],
        ),
        child: Column(
          children: [
            // COLLAPSED
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isFastTrack 
                          ? [const Color(0xFFEF4444).withValues(alpha: 0.1), const Color(0xFFEF4444).withValues(alpha: 0.05)]
                          : [const Color(0xFF22C55E).withValues(alpha: 0.1), const Color(0xFF22C55E).withValues(alpha: 0.05)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Image.asset(_resolveOrderIconPath(order, items)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${totalQty.toStringAsFixed(totalQty == totalQty.toInt() ? 0 : 1)} $unit - ${_formatNyutjiDate(orderDate)}",
                          style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF131109), letterSpacing: 0.3)
                        ),
                        const SizedBox(height: 4),
                        Builder(
                          builder: (context) {
                            final rawDel = (order['deliveryType'] ?? order['delivery_type'] ?? '').toString().toUpperCase();
                            final isSelfDrop = rawDel == 'SELF_DROP' || rawDel == 'SELFDROP_SELFDELIVERY' || rawDel == 'SELF_SERVICE';
                            final rawStatus = (order['order_status'] ?? order['status'] ?? 'PROSES').toString().toUpperCase();
                            final displayStatus = (isSelfDrop && (rawStatus == 'WAITING_DROPOFF' || rawStatus == 'SEARCHING')) ? 'WEIGHING' : rawStatus;
                            
                            // Deteksi jika pesanan premium untuk menampilkan nama layanan & tahap progress dinamis
                            final pName = _getPremiumServiceName(order, items);
                            if (pName.isNotEmpty) {
                              final pStatus = _getPremiumProgressLabel(rawStatus);
                              return Text(
                                "$pName - $pStatus",
                                style: GoogleFonts.montserrat(fontSize: 13, color: const Color(0xFF403600), fontWeight: FontWeight.w700, letterSpacing: 0.5)
                              );
                            }

                            return Text(
                              StatusHelper.getLabel(displayStatus, 'PL'),
                              style: GoogleFonts.montserrat(fontSize: 13, color: const Color(0xFF403600), fontWeight: FontWeight.w600, letterSpacing: 1.0)
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatNyutjiDate(completionDate),
                        style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF403600))
                      ),
                      Text("EST. SELESAI", style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.grey[400], letterSpacing: 0.5)),
                    ],
                  ),
                  if (isFinished || isDraft) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 20, color: const Color(0xFF403600).withValues(alpha: 0.5)),
                      onPressed: () => setState(() => isExpanded = !isExpanded),
                    ),
                  ],
                ],
              ),
            ),

            // EXPANDED
            if (showExpanded)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: Color(0xFFF3F0E9)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _detailCol("Tgl Masuk", _formatNyutjiDate(orderDate))),
                        const SizedBox(width: 10),
                        Expanded(child: _detailCol("Mitra Laundry", mitraName)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _detailCol("Tgl Selesai", _formatNyutjiDate(completionDate))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: rawDel == 'SELFDROP_SELFDELIVERY' 
                              ? const SizedBox.shrink() 
                              : _detailCol("Petugas Kurir", _getCourierStatusText(order)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Detail Pesanan Section (Mewah & Elegance)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Detail Pesanan", style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey)),
                        const SizedBox(height: 6),
                        if (items != null && items.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFDF9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFF3F0E9), width: 1),
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
                                              style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF131109)),
                                            ),
                                          ),
                                          Text(
                                            "${qty.toStringAsFixed(qty == qty.toInt() ? 0 : 1)} $unitText",
                                            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF403600)),
                                          ),
                                        ],
                                      ),
                                      if (notes.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2.0),
                                          child: Text(
                                            notes,
                                            style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          )
                        else
                          Text(
                            "-",
                            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF131109)),
                          ),
                      ],
                    ),
                    if (!isDraft) ...[
                      const SizedBox(height: 24),
                      // PROGRESS HEADER
                      Row(
                        children: [
                          Text("Progress Layanan", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF403600).withValues(alpha: 0.8))),
                          const SizedBox(width: 12),
                          const Expanded(child: Divider(color: Color(0xFFF3F0E9), thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // PROGRESS ICONS (Mewah & Dinamis)
                      Builder(
                        builder: (context) {
                        final s = (order['status'] ?? order['order_status'] ?? '').toString().toUpperCase();
                        final rawDel = (order['deliveryType'] ?? order['delivery_type'] ?? '').toString().toUpperCase();
                        final orderType = (order['orderType'] ?? order['order_type'] ?? '').toString().toLowerCase();
                        
                        bool hasPickup = orderType == 'pickup';
                        // Keep exactly the old logic for Kirim (Delivery) to avoid hiding it unintentionally
                        bool isSelfDropPickup = rawDel == 'SELFDROP_SELFDELIVERY' || 
                            (rawDel == 'SELF_DROP' && (double.tryParse(order['deliveryFee']?.toString() ?? '0') ?? 0.0) == 0);
                        bool hasDelivery = !isSelfDropPickup;

                        // Deteksi apakah pesanan premium (Cuci Sepatu, Dry Clean, Pakaian Bayi, Cuci Khusus)
                        bool isPremium = false;
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
                        
                        isPremium = textToScan.contains('sepatu') || 
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

                        // LOGIKA AKTIVASI STEP
                        bool isStep1 = ['SEARCHING', 'WAITING_PICKUP', 'PICKING_UP', 'ARRIVED', 'WEIGHING', 'WASH_START', 'IN_PROGRESS', 'IRONING', 'PACKING', 'DELIVERING', 'DONE', 'PAID'].contains(s);
                        bool isStep2 = ['WEIGHING', 'WASH_START', 'IN_PROGRESS', 'IRONING', 'PACKING', 'DELIVERING', 'DONE', 'PAID'].contains(s) || (s == 'WAITING_DROPOFF');
                        bool isStep3 = ['WASH_START', 'IN_PROGRESS', 'IRONING', 'PACKING', 'DELIVERING', 'DONE', 'PAID'].contains(s);
                        bool isStep4 = ['PACKING', 'DELIVERING', 'DONE', 'PAID'].contains(s);
                        bool isStep5 = ['DELIVERING', 'DONE', 'PAID'].contains(s);
                        bool isStep6 = ['DONE', 'PAID'].contains(s);

                        List<Widget> progressWidgets = [];

                        // 1. JEMPUT (Optional)
                        if (hasPickup) {
                          progressWidgets.add(Expanded(child: _buildModernProgress("Kurir", LucideIcons.truck, isStep1, onTap: () => _showPowDialog(order['proofs'], ['SEARCHING', 'WAITING_PICKUP', 'PICKING_UP'], "Kurir"))));
                        }

                        // 2. TIMBANG / DITERIMA
                        if (isPremium) {
                          progressWidgets.add(Expanded(child: _buildModernProgress("Diterima", LucideIcons.packageCheck, isStep2, onTap: () => _showPowDialog(order['proofs'], ['WEIGHING'], "Diterima"))));
                        } else {
                          progressWidgets.add(Expanded(child: _buildModernProgress("Timbang", 'assets/icons/scale.png', isStep2, onTap: () => _showPowDialog(order['proofs'], ['WEIGHING'], "Timbang"))));
                        }

                        // 3. CUCI
                        progressWidgets.add(Expanded(child: _buildModernProgress("Cuci", LucideIcons.droplets, isStep3, onTap: () => _showPowDialog(order['proofs'], ['WASH_START', 'IN_PROGRESS', 'IRONING'], "Cuci"))));

                        // 4. PACKING
                        progressWidgets.add(Expanded(child: _buildModernProgress("Packing", LucideIcons.package, isStep4, onTap: () => _showPowDialog(order['proofs'], ['PACKING'], "Packing"))));

                        // 5. KIRIM (Optional)
                        if (hasDelivery) {
                          progressWidgets.add(Expanded(child: _buildModernProgress("Kirim", LucideIcons.navigation, isStep5, onTap: () => _showPowDialog(order['proofs'], ['DELIVERING'], "Kirim"))));
                        }

                        // 6. SELESAI
                        progressWidgets.add(Expanded(child: _buildModernProgress("Selesai", LucideIcons.checkCircle, isStep6, onTap: () => _showPowDialog(order['proofs'], ['DONE', 'PAID'], "Selesai"))));

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: progressWidgets,
                            ),
                            if (s == 'DONE') ...[
                              const SizedBox(height: 20),
                              const Divider(color: Color(0xFFF3F0E9), thickness: 1),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CustomerReviewScreen(order: order),
                                    ),
                                  );
                                },
                                icon: const Icon(LucideIcons.checkSquare, size: 18),
                                label: Text("Selesai Diterima", style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF403600),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ]
                          ],
                        );
                      },
                    ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernProgress(String label, dynamic icon, bool isActive, {VoidCallback? onTap}) {
    const Color activeColor = Color(0xFF403600);
    const Color inactiveColor = Color(0xFFE3DCCF);
    final Color iconColor = isActive ? Colors.white : inactiveColor;

    Widget iconWidget;
    if (icon is IconData) {
      iconWidget = Icon(icon, size: 16, color: iconColor);
    } else if (icon is String) {
      iconWidget = Image.asset(
        icon,
        width: 16,
        height: 16,
        color: iconColor,
      );
    } else {
      iconWidget = const SizedBox.shrink();
    }

    Widget content = Column(
      children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? activeColor : inactiveColor, width: 1.5),
            boxShadow: isActive ? [BoxShadow(color: activeColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : null,
          ),
          child: Center(child: iconWidget),
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: isActive ? FontWeight.w900 : FontWeight.w600, color: isActive ? activeColor : Colors.grey[400])),
      ],
    );

    if (isActive && onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }

  Widget _detailCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF131109)), softWrap: true),
      ],
    );
  }
}

// ─────────────────────────────────────────
// HEADER CLIPPER
// ─────────────────────────────────────────
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    path.quadraticBezierTo(size.width / 2, size.height - 40, size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
