import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../core/utils/status_helper.dart';

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

  String currentFilter = "Semua";
  final Set<String> _expandedIds = {};
  late PageController _pageController;
  int _currentPage = 0;
  final Map<String, List<bool>> _uploadedSteps = {};
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrderProvider>().fetchOrders();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
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

  Future<void> _onUploadStep(String orderId, int stepIndex, int totalSteps) async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file == null || !mounted) return;
    setState(() {
      _uploadedSteps.putIfAbsent(orderId, () => List.filled(totalSteps, false));
      _uploadedSteps[orderId]![stepIndex] = true;
    });
    _showNotif("Foto progress berhasil diupload", true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppbar(),
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
            if (currentFilter == "Semua") return true;
            if (currentFilter == "Baru") return status == 'SEARCHING' || status == 'WAITING_DROPOFF';
            if (currentFilter == "Same Day") return isFast || serviceType.contains('SAME');
            if (currentFilter == "Reguler") return serviceType.contains('REGULER') || serviceType.contains('BIASA');
            return true;
          }).toList();

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: _buildListContent(filtered, orderProv.isLoading, hasNewOrders),
          );
        },
      ),
    );
  }

  Widget _buildListContent(List<dynamic> filtered, bool isLoading, bool hasNewOrders) {
    if (isLoading && filtered.isEmpty) {
      return const Center(key: ValueKey('loading'), child: CircularProgressIndicator(color: primaryTeal));
    }
    if (filtered.isEmpty) {
      return ListView(
        key: ValueKey('empty_$currentFilter'),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.28),
          Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(LucideIcons.clipboardList, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text("Tidak ada pesanan", style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text("Tarik ke bawah untuk memuat ulang", style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[400])),
            ]),
          ),
        ],
      );
    }

    final List<List<dynamic>> pages = [];
    for (var i = 0; i < filtered.length; i += 5) {
      pages.add(filtered.sublist(i, i + 5 > filtered.length ? filtered.length : i + 5));
    }

    return Column(
      key: ValueKey('list_$currentFilter'),
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
            padding: const EdgeInsets.only(bottom: 100, top: 10),
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
          const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildOrderCard(dynamic o) {
    final status = (o['status'] ?? o['order_status'] ?? 'UNKNOWN').toString();
    final statusUp = status.toUpperCase();
    final price = double.tryParse((o['total_price'] ?? o['totalPrice'] ?? o['grand_total'] ?? o['total'] ?? '0').toString()) ?? 0.0;
    final orderId = (o['order_number'] ?? o['orderNumber'] ?? o['identifier'] ?? o['id'] ?? '-').toString();
    final customerName = o['customer']?['name']?.toString() ?? o['customer_name']?.toString() ?? 'Pelanggan';
    final courierName = o['courier']?['name']?.toString() ?? o['courier_name']?.toString() ?? 'Belum Ada';
    final bool isFast = o['is_fast_track'] == true || o['is_fast_track'] == 1 || o['isFastTrack'] == true || o['service_type'] == 'SAME_DAY';
    final Color accentColor = isFast ? Colors.orange : primaryTeal;

    DateTime createdAt;
    try { createdAt = o['created_at'] != null ? DateTime.parse(o['created_at'].toString()) : DateTime.now(); }
    catch (e) { createdAt = DateTime.now(); }

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
                onTap: () => setState(() {
                  if (isExpanded) { _expandedIds.remove(orderId); } else { _expandedIds.add(orderId); }
                }),
                child: Padding(
                  padding: EdgeInsets.only(left: isExpanded ? 8 : 0),
                  child: isExpanded
                      ? _buildExpandedCard(o, orderId, status, statusUp, price, customerName, courierName, isFast, createdAt, accentColor)
                      : _buildCollapsedCard(status, price, createdAt),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── COLLAPSED ──────────────────────────────────────
  Widget _buildCollapsedCard(String status, double price, DateTime createdAt) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(width: 32, height: 32,
          decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.08), shape: BoxShape.circle),
          child: const Icon(LucideIcons.user, color: primaryTeal, size: 16)),
        const SizedBox(width: 12),
        Expanded(child: Text(
          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price),
          style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: darkText))),
        Text(DateFormat('dd MMM').format(createdAt),
          style: GoogleFonts.montserrat(fontSize: 10, color: textGrey, fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        _buildStatusChip(status),
      ]),
    );
  }

  // ── EXPANDED ──────────────────────────────────────
  Widget _buildExpandedCard(dynamic o, String orderId, String status, String statusUp,
      double price, String customerName, String courierName, bool isFast,
      DateTime createdAt, Color accentColor) {

    final bool needsCourier = statusUp == 'SEARCHING' || statusUp == 'WAITING_DROPOFF';
    final bool needsUpdate = !needsCourier && statusUp != 'DONE' && statusUp != 'PAID';

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Top row: info kiri + chips kanan ──
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Kiri: order number + date + avatar + nama + harga
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(orderId, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: textGrey, letterSpacing: 0.4)),
              Text(DateFormat('dd MMM yyyy, HH:mm').format(createdAt),
                style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[400], fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Container(width: 40, height: 40,
                  decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.user, color: primaryTeal, size: 20)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(customerName, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: darkText)),
                  Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price),
                    style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: accentColor)),
                ])),
              ]),
            ]),
          ),
          const SizedBox(width: 12),
          // Kanan: Status + Services + Petugas
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text("Status :", style: GoogleFonts.montserrat(fontSize: 13, color: textGrey, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              _buildStatusChip(status),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Text("Services :", style: GoogleFonts.montserrat(fontSize: 13, color: textGrey, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              _buildServiceChip(isFast, accentColor),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Icon(LucideIcons.truck, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("KURIR", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[400])),
                Text(courierName,
                  style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700,
                    color: courierName == "Belum Ada" ? Colors.orange : darkText)),
              ]),
            ]),
          ]),
        ]),

        const SizedBox(height: 16),
        const Divider(height: 1, color: Color(0xFFF3F0E9)),
        const SizedBox(height: 14),

        // ── Progress Cucian ──
        _buildProgressCucian(orderId, status, accentColor, o),

        // ── Action Buttons ──
        if (needsCourier || needsUpdate) ...[
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            if (needsCourier)
              _buildActionBtn("ASSIGN KURIR", Colors.orange[700]!, () => _showCourierPicker(orderId))
            else if (needsUpdate)
              _buildActionBtn("UPDATE STATUS", primaryTeal, () => _showStatusUpdater(orderId, status)),
          ]),
        ],
      ]),
    );
  }

  // ── Progress Bar ──────────────────────────────────
  // Steps disesuaikan 3 jenis layanan:
  // PICKUP → 4 steps (ada Kirim)
  // SELF_DROP + kurir → 4 steps (ada Kirim)
  // SELF_DROP tanpa kurir → 3 steps (no Kirim = Ambil Mandiri)
  Widget _buildProgressCucian(String orderId, String status, Color accentColor, dynamic o) {
    final int step = _getProgressStep(status);
    
    // LOGIKA AKTIVASI STEP (Cascade sesuai PL)
    bool isStep1 = true; // Minimal sudah masuk sistem
    bool isStep2 = step >= 2;
    bool isStep3 = step >= 3;
    bool isStep4 = step >= 4;
    bool isStep5 = step >= 5;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text("Progress Cucian", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w800, color: darkText)),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: Color(0xFFE5E7EB), thickness: 1)),
      ]),
      const SizedBox(height: 20),
      // PROGRESS ICONS (Sync dengan PL)
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildModernProgress("PickUp", LucideIcons.truck, isStep1),
          _buildModernProgress("Timbangan", LucideIcons.scale, isStep2),
          _buildModernProgress("Cuci", LucideIcons.droplets, isStep3),
          _buildModernProgress("Packing", LucideIcons.package, isStep4),
          _buildModernProgress("Kirim", LucideIcons.navigation, isStep5),
        ],
      ),
    ]);
  }

  Widget _buildModernProgress(String label, IconData icon, bool isActive) {
    const Color activeColor = Color(0xFF1E5655);
    const Color inactiveColor = Color(0xFFE5E7EB);

    return Column(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? activeColor : inactiveColor, width: 1.5),
            boxShadow: isActive ? [BoxShadow(color: activeColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : null,
          ),
          child: Icon(icon, size: 18, color: isActive ? Colors.white : inactiveColor),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: isActive ? FontWeight.w900 : FontWeight.w600, color: isActive ? activeColor : Colors.grey[400])),
      ],
    );
  }


  // ── Chips ─────────────────────────────────────────
  Widget _buildStatusChip(String status) {
    final Color color = StatusHelper.getColor(status);
    final String label = StatusHelper.getLabel(status, 'ML');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.2),
      ),
      child: Text(label, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
    );
  }

  Widget _buildServiceChip(bool isFast, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(20)),
      child: Text(isFast ? "SAME DAY" : "REGULAIR",
        style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }

  // ── Action Button ─────────────────────────────────
  Widget _buildActionBtn(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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

  void _showStatusUpdater(String orderId, String currentStatus) {
    final stages = ['WAITING_DROPOFF', 'WEIGHING', 'WASH_START', 'IRONING', 'PACKING', 'DELIVERING', 'DONE'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Update Status Pesanan", style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 18, color: darkText)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: stages.map((s) {
              bool isCurrent = s == currentStatus;
              return ActionChip(
                label: Text(s.replaceAll('_', ' ')),
                backgroundColor: isCurrent ? primaryTeal : Colors.grey[100],
                labelStyle: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: isCurrent ? Colors.white : textGrey),
                onPressed: () async {
                  final provider = context.read<OrderProvider>();
                  Navigator.pop(context);
                  final success = await provider.updateOrderStatus(orderId, s);
                  if (!mounted) return;
                  if (success) _showNotif("Status diperbarui ke $s", true);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  void _showNotif(String msg, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isSuccess ? LucideIcons.checkCircle : LucideIcons.alertCircle, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Text(msg, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
      backgroundColor: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── AppBar ────────────────────────────────────────
  PreferredSizeWidget _buildAppbar() {
    return AppBar(
      backgroundColor: Colors.white, elevation: 0,
      automaticallyImplyLeading: false,
      title: Text("Manajemen Pesanan", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900, color: darkText)),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          height: 50, color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Consumer<OrderProvider>(
            builder: (context, orderProv, _) {
              final bool hasNew = orderProv.activeOrders.any((o) {
                final s = (o['status'] ?? o['order_status'] ?? '').toString().toUpperCase();
                return s == 'SEARCHING' || s == 'WAITING_DROPOFF';
              });
              return ListView(
                scrollDirection: Axis.horizontal,
                children: ["Semua", "Baru", "Same Day", "Reguler"].map((f) => _buildFilterPill(f, hasNew)).toList(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, bool showDot) {
    final bool isSel = currentFilter == label;
    final bool needsDot = label == "Baru" && showDot;
    return GestureDetector(
      onTap: () {
        if (currentFilter != label) {
          setState(() { currentFilter = label; _currentPage = 0; });
          if (_pageController.hasClients) _pageController.jumpToPage(0);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSel ? primaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSel ? primaryTeal : Colors.grey[300]!),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: isSel ? FontWeight.w900 : FontWeight.w600, color: isSel ? Colors.white : textGrey)),
          if (needsDot) ...[
            const SizedBox(width: 4),
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
          ],
        ]),
      ),
    );
  }
}
