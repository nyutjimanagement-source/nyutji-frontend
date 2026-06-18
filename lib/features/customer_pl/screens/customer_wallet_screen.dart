import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lucide_icons/lucide_icons.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/nyutji_theme.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../providers/order_provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomerWalletScreen extends ConsumerStatefulWidget {
  const CustomerWalletScreen({super.key});

  @override ConsumerState<CustomerWalletScreen> createState() => _CustomerWalletScreenState();
}

class _CustomerWalletScreenState extends ConsumerState<CustomerWalletScreen> {
  String _historyFilter = 'Bulan';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider).fetchWallet();
      ref.read(orderProvider).fetchOrders();
    });
  }

  Map<String, List<dynamic>> _getGroupedMutasi(List<dynamic> mutasi) {
    Map<String, List<dynamic>> grouped = {};
    for (var m in mutasi) {
      DateTime date = DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now();
      String key;
      if (_historyFilter == 'Minggu') {
        int week = ((date.toLocal().day - 1) / 7).floor() + 1;
        key = "Minggu ke-$week ${DateFormat('MMMM yyyy', 'id_ID').format(date.toLocal())}";
      } else if (_historyFilter == 'Tahun') {
        key = DateFormat('yyyy', 'id_ID').format(date.toLocal());
      } else {
        key = DateFormat('MMMM yyyy', 'id_ID').format(date.toLocal());
      }

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(m);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final Map<String, dynamic> t = {
      'id': {
        'title': 'Dompet Nyutji',
        'active_balance': 'Saldo Aktif',
        'topup': 'Top Up',
        'history': 'Riwayat Terakhir',
        'pay_wash': 'Bayar Cuci',
        'cash_flow': 'Arus Kas (1 Tahun)',
      },
      'en': {
        'title': 'Nyutji Wallet',
        'active_balance': 'Active Balance',
        'topup': 'Top Up',
        'history': 'Recent History',
        'pay_wash': 'Laundry Payment',
        'cash_flow': 'Cash Flow (1 Year)',
      }
    };
    final currentT = t[auth.lang] ?? t['id'];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9ED),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(walletProvider).fetchWallet(force: true),
            ref.read(orderProvider).fetchOrders(force: true),
          ]);
        },
        color: const Color(0xFF403600),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildPremiumHeader(currentT['title']),
            const SizedBox(height: 12),
            // CARD SALDO
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Consumer(
                builder: (context, ref, _) {
final wallet = ref.watch(walletProvider);
return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF403600), 
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: const Color(0xFF403600).withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))]
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(currentT['active_balance'], style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          wallet.isLoading
                          ? const Padding(padding: EdgeInsets.only(top: 8), child: ShimmerLoading(height: 24, width: 120, borderRadius: 8))
                          : Text(Formatters.currencyIdr(wallet.balance), style: GoogleFonts.montserrat(color: const Color(0xFFDAC66F), fontSize: 24, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: wallet.isLoading ? null : () => _showTopUpSheet(context, wallet),
                        icon: wallet.isLoading 
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF403600)))
                          : const Icon(LucideIcons.plus, size: 14),
                        label: Text(currentT['topup'], style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDAC66F), 
                          foregroundColor: const Color(0xFF403600), 
                          elevation: 0, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                        ),
                      )
                    ],
                  ),
                );
}),
            ),
            const SizedBox(height: 16),

            // MINI ANALYTICS CHART
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Consumer(
                builder: (context, ref, _) {
final wallet = ref.watch(walletProvider);
return _buildAnalyticsCard(currentT, wallet);
}),
            ),
            const SizedBox(height: 16),

            // RIWAYAT TRANSAKSI
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Consumer(
                builder: (context, ref, _) {
final wallet = ref.watch(walletProvider);
                  final grouped = _getGroupedMutasi(wallet.mutasiList);
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: const Color(0xFFE3DCCF), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(currentT['history'], style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF131109))),
                        const SizedBox(height: 12),
                        Row(
                          children: ['Minggu', 'Bulan', 'Tahun'].map((f) {
                            bool isSelected = _historyFilter == f;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text(f),
                                backgroundColor: isSelected ? const Color(0xFF403600) : Colors.grey[100],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                                labelStyle: GoogleFonts.montserrat(color: isSelected ? Colors.white : Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold),
                                onPressed: () => setState(() => _historyFilter = f),
                              ),
                            );
                          }).toList(),
                        ),
                        const Divider(height: 32, color: Color(0xFFE3DCCF)),
                        if (wallet.isLoading)
                          Column(
                            children: List.generate(3, (index) => const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: ShimmerLoading(height: 50, borderRadius: 12),
                            )),
                          )
                        else if (wallet.mutasiList.isEmpty)
                          Center(child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(LucideIcons.history, size: 40, color: Colors.grey[200]),
                                const SizedBox(height: 12),
                                Text("Belum ada riwayat transaksi", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[400])),
                              ],
                            ),
                          ))
                        else
                          ...grouped.entries.toList().asMap().entries.map((mapEntry) {
                            int idx = mapEntry.key;
                            var entry = mapEntry.value;
                            bool isInitialExpanded;
                            if (_historyFilter == 'Minggu') {
                              final now = DateTime.now();
                              int currentWeek = ((now.day - 1) / 7).floor() + 1;
                              String currentMonthYear = DateFormat('MMMM yyyy', 'id_ID').format(now);
                              bool isCurrentMonth = entry.key.contains(currentMonthYear);
                              if (isCurrentMonth) {
                                int? groupWeek;
                                final match = RegExp(r'Minggu ke-(\d+)').firstMatch(entry.key);
                                if (match != null) {
                                  groupWeek = int.tryParse(match.group(1) ?? '');
                                }
                                if (groupWeek != null && groupWeek != currentWeek) {
                                  isInitialExpanded = false;
                                } else {
                                  isInitialExpanded = idx == 0;
                                }
                              } else {
                                isInitialExpanded = idx == 0;
                              }
                            } else {
                              isInitialExpanded = idx == 0;
                            }
                            return _HistoryGroupItem(
                              title: entry.key,
                              items: entry.value,
                              isInitialExpanded: isInitialExpanded,
                            );
                          }),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildPremiumHeader(String title) {
    return ClipPath(
      clipper: WalletHeaderClipper(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 60),
        decoration: const BoxDecoration(color: Color(0xFF403600)),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushNamedAndRemoveUntil(context, '/customer_main', (route) => false);
                }
              },
            ),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            const SizedBox(width: 48), // Balancing
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(Map<String, dynamic> cT, WalletProvider wallet) {
    double totalIn = 0;
    double totalOut = 0;
    for (var m in wallet.mutasiList) {
      double amt = double.tryParse(m['amount'].toString()) ?? 0.0;
      final txType = (m['transaction_type'] ?? m['type'] ?? '').toString().toUpperCase();
      final isOut = txType == 'PAYMENT' || txType == 'WITHDRAW' || txType == 'FEE_PLATFORM' || txType == 'DEBIT' || amt < 0;
      
      if (isOut) {
        totalOut += amt.abs();
      } else {
        totalIn += amt;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE3DCCF), width: 1.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50, height: 50,
            child: CustomPaint(painter: MiniPiePainter(totalIn, totalOut)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cT['cash_flow'], style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _chartLegend(const Color(0xFF10B981), "Masuk"),
                    const SizedBox(width: 16),
                    _chartLegend(const Color(0xFFC3312E), "Keluar"),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _chartLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.montserrat(fontSize: 10, color: const Color(0xFF131109), fontWeight: FontWeight.w700)),
      ],
    );
  }

  void _showTopUpSheet(BuildContext context, WalletProvider wallet) {
    final List<int> amounts = [50000, 100000, 200000, 300000, 500000, 1000000];
    int selectedAmount = amounts[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext stCtx, StateSetter setState) {
            final itemWidth = (MediaQuery.of(ctx).size.width - 48 - 12) / 2;
            final bottomPadding = MediaQuery.of(ctx).padding.bottom;

            return Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + (bottomPadding > 0 ? bottomPadding : 24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pilih Nominal Top Up", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF131109))),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: amounts.map((amount) {
                      bool isSelected = selectedAmount == amount;
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => selectedAmount = amount),
                        child: Container(
                          width: itemWidth,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? NyutjiTheme.m3Primary : const Color(0xFFFFF9ED),
                            border: Border.all(color: isSelected ? NyutjiTheme.m3Primary : const Color(0xFFDAC66F), width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            Formatters.currencyIdr(amount),
                            style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, color: isSelected ? Colors.white : const Color(0xFF403600), fontSize: 13),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  
                  // Link Payment Gateway (Midtrans Snap)
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showMidtransSnapSimulation(context, selectedAmount);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: NyutjiTheme.m3Primary, width: 1.5),
                      ),
                      child: Center(
                        child: Text("Payment Gateway (Midtrans Snap)", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: NyutjiTheme.m3Primary, fontSize: 12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Link Simulasi Instan
                  InkWell(
                    onTap: () async {
                      Navigator.pop(ctx);
                      final ok = await wallet.forceTopup(selectedAmount.toDouble());
                      if (ok && context.mounted) {
                        NyutjiNotif.showSuccess(context, 'Top Up ${Formatters.currencyIdr(selectedAmount)} Berhasil!');
                      }
                    },
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text("Topup Instant (Simulasi)", style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: Colors.grey[600], fontSize: 12, decoration: TextDecoration.underline)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showMidtransSnapSimulation(BuildContext context, int amount) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Midtrans",
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Midtrans Sandbox", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.black87)),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(LucideIcons.x, size: 20, color: Colors.black87), 
                          onPressed: () => Navigator.pop(context)
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.smartphone, size: 60, color: NyutjiTheme.m3Primary),
                          const SizedBox(height: 16),
                          Text("Pop-up Midtrans Snap", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text("Tagihan: ${Formatters.currencyIdr(amount)}", style: GoogleFonts.montserrat(color: Colors.grey[600], fontSize: 14)),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.symmetric(horizontal: 30),
                            decoration: BoxDecoration(
                              color: NyutjiTheme.m3Primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Nantinya layar ini akan memuat Webview SDK resmi dari Midtrans untuk memilih metode pembayaran (VA, QRIS, e-Wallet).", 
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(fontSize: 11, color: NyutjiTheme.m3Primary, height: 1.5)
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      }
    );
  }

// Removed _buildHistoryRow, moved to _HistoryRowItem
}

class WalletHeaderClipper extends CustomClipper<Path> {
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

class MiniPiePainter extends CustomPainter {
  final double income;
  final double expense;
  MiniPiePainter(this.income, this.expense);

  @override
  void paint(Canvas canvas, Size size) {
    double total = income + expense;
    if (total == 0) {
      canvas.drawCircle(size.center(Offset.zero), size.width / 2, Paint()..color = Colors.grey[200]!);
      return;
    }

    double incomeAngle = (income / total) * 2 * 3.1415926535;
    double expenseAngle = (expense / total) * 2 * 3.1415926535;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(rect, -3.1415926535 / 2, incomeAngle, true, Paint()..color = const Color(0xFF10B981));
    canvas.drawArc(rect, -3.1415926535 / 2 + incomeAngle, expenseAngle, true, Paint()..color = const Color(0xFFC3312E));
    
    canvas.drawCircle(size.center(Offset.zero), size.width / 3.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─────────────────────────────────────────
// EXPANDABLE HISTORY ROW
// ─────────────────────────────────────────
class _HistoryRowItem extends ConsumerStatefulWidget {
  final dynamic transaction;
  const _HistoryRowItem({required this.transaction});

  @override ConsumerState<_HistoryRowItem> createState() => _HistoryRowItemState();
}

class _HistoryRowItemState extends ConsumerState<_HistoryRowItem> {
  bool isExpanded = false;

  void _showPowImage(BuildContext context, String imageUrl, String title, Map<String, dynamic> order, dynamic proofData) {
    final String orderId = (order['order_number'] ?? order['orderNumber'] ?? order['identifier'] ?? order['id'] ?? '-').toString();
    final String uploaderRole = (proofData['uploader_role'] ?? 'PL').toString();
    final String uploaderLabel = uploaderRole == 'ML' ? 'Mitra Laundry'
        : uploaderRole == 'KL' ? 'Kurir'
        : 'Pelanggan';
    String uploadedAt = '-';
    try {
      final dt = DateTime.tryParse(proofData['createdAt']?.toString() ?? '');
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
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text("Bukti $title", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF403600))),
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
                SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.55,
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.8,
                    maxScale: 5.0,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
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
                        // Watermark 2 — tengah
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
                        // Info overlay
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

  @override
  Widget build(BuildContext context) {
    final m = widget.transaction;
    final amt = double.tryParse(m['amount'].toString()) ?? 0.0;
    final txType = (m['transaction_type'] ?? m['type'] ?? '').toString().toUpperCase();
    final isOut = txType == 'PAYMENT' || txType == 'WITHDRAW' || txType == 'FEE_PLATFORM' || txType == 'DEBIT' || amt < 0;
    final title = (m['description'] ?? m['title'] ?? txType).toString();
    final val = "${isOut ? '-' : '+'} ${Formatters.currencyIdr(amt.abs())}";
    final c = isOut ? const Color(0xFFC3312E) : const Color(0xFF10B981);
    final dateStr = (m['createdAt'] ?? m['date'] ?? '-').toString();
    
    String formattedDate = "-";
    try {
      DateTime dt = DateTime.tryParse(dateStr) ?? DateTime.now();
      formattedDate = DateFormat('dd MMM, HH:mm', 'id_ID').format(dt.toLocal());
    } catch (_) {}

    final orderProv = ref.read(orderProvider);
    final allOrders = [...orderProv.activeOrders, ...orderProv.historyOrders];
    final String refId = (m['reference_id'] ?? m['order_id'] ?? '').toString();
    
    Map<String, dynamic>? order;
    for (var o in allOrders) {
      final String oNum = (o['order_number'] ?? o['orderNumber'] ?? '').toString();
      if (oNum.isNotEmpty && (title.contains(oNum) || refId == oNum)) {
        order = o; break;
      }
      final String oId = (o['id'] ?? o['identifier'] ?? '').toString();
      if (oId.isNotEmpty && (refId == oId || title.contains(oId))) {
        order = o; break;
      }
    }

    final bool isSelesai = order != null && ['DONE', 'PAID'].contains((order['status'] ?? order['order_status'] ?? '').toString().toUpperCase());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: isSelesai ? () => setState(() => isExpanded = !isExpanded) : null,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10), 
                        decoration: BoxDecoration(color: c.withValues(alpha: 0.1), shape: BoxShape.circle), 
                        child: Icon(isOut ? LucideIcons.arrowUp : LucideIcons.arrowDown, size: 14, color: c)
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF131109)))),
                                const SizedBox(width: 8),
                                Row(
                                  children: [
                                    Text(val, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: c)),
                                    if (isSelesai) ...[
                                      const SizedBox(width: 4),
                                      Icon(isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 16, color: Colors.grey[400]),
                                    ]
                                  ]
                                )
                              ]
                            ),
                            const SizedBox(height: 2),
                            Text(formattedDate, style: GoogleFonts.montserrat(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: (isExpanded && isSelesai)
              ? _buildOrderDetails(order)
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }

  Widget _buildOrderDetails(Map<String, dynamic> order) {
    final orderId = (order['order_number'] ?? order['orderNumber'] ?? order['identifier'] ?? order['id'] ?? '-').toString();
    final mitraName = (order['mitra'] is Map ? order['mitra']['name'] : null) ?? order['mitra_name'] ?? 'Mitra Nyutji';
    final courierName = (order['courier'] is Map ? order['courier']['name'] : null) ?? order['courier_name'] ?? order['petugas_kurir'];
    
    DateTime orderDate;
    try {
      final orderDateRaw = order['createdAt'] ?? order['created_at'];
      orderDate = orderDateRaw != null ? DateTime.parse(orderDateRaw.toString()).toLocal() : DateTime.now();
    } catch (e) { orderDate = DateTime.now(); }

    DateTime? finishDate;
    try {
      final finishDateRaw = order['doneAt'] ?? order['done_at'] ?? order['completedAt'] ?? order['completed_at'] ?? order['updatedAt'] ?? order['updated_at'];
      if (finishDateRaw != null) {
        finishDate = DateTime.parse(finishDateRaw.toString()).toLocal();
      }
    } catch (e) {
      // ignore empty catch
    }

    final List<dynamic> proofs = order['proofs'] ?? [];
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

    return Container(
      margin: const EdgeInsets.only(bottom: 24, top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3DCCF), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.receipt, size: 16, color: Color(0xFF403600)),
              const SizedBox(width: 8),
              Text("Detail Order Selesai", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF403600))),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF3F0E9)),
          _buildDetailSearchRow("Nomor Order", orderId),
          const SizedBox(height: 8),
          _buildDetailSearchRow("Mitra Laundry", mitraName),
          if (courierName != null && courierName.toString().isNotEmpty && courierName.toString() != "null") ...[
            const SizedBox(height: 8),
            _buildDetailSearchRow("Kurir", courierName.toString()),
          ],
          const SizedBox(height: 8),
          _buildDetailSearchRow("Tgl Order", DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(orderDate)),
          if (finishDate != null) ...[
            const SizedBox(height: 8),
            _buildDetailSearchRow("Tgl Selesai", DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(finishDate)),
          ],
          const SizedBox(height: 16),
          Text("Items:", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[600])),
          const SizedBox(height: 8),
          _buildDetailPesanan(order),
          
          if (existingProofs.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text("Galeri POW:", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[600])),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.0
              ),
              itemCount: existingProofs.length,
              itemBuilder: (context, index) {
                final pDef = existingProofs[index];
                final pData = proofMap[pDef['step']];
                final String path = pData['file_url'].toString().replaceAll('\\', '/').replaceAll(RegExp(r'^/+'), '');
                final imageUrl = path.startsWith('http') ? path : "${ApiConstants.rootUrl}/$path";
                
                return GestureDetector(
                  onTap: () => _showPowImage(context, imageUrl, pDef['title'].toString(), order, pData),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE3DCCF)),
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
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(12))
                          ),
                          child: Text(
                            pDef['title'].toString(),
                            style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF403600)),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailSearchRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: Text(label, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[600]))),
        Expanded(flex: 3, child: Text(value, textAlign: TextAlign.right, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF131109)))),
      ],
    );
  }

  Widget _buildDetailPesanan(Map<String, dynamic> order) {
    final items = order['orderItems'] as List? ?? order['order_items'] as List? ?? order['items'] as List? ?? [];
    if (items.isEmpty) {
      return Text("-", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF131109)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map<Widget>((it) {
        final name = (it['itemName'] ?? it['item_name'] ?? it['name'] ?? '').toString();
        final qty = double.tryParse(it['qty']?.toString() ?? '1') ?? 1.0;
        final unitText = (it['unit'] ?? 'Pcs').toString();
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(name, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF131109)))),
              Text("${qty.toStringAsFixed(qty == qty.toInt() ? 0 : 1)} $unitText", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF403600))),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _HistoryGroupItem extends ConsumerStatefulWidget {
  final String title;
  final List<dynamic> items;
  final bool isInitialExpanded;
  
  const _HistoryGroupItem({required this.title, required this.items, required this.isInitialExpanded});

  @override ConsumerState<_HistoryGroupItem> createState() => _HistoryGroupItemState();
}

class _HistoryGroupItemState extends ConsumerState<_HistoryGroupItem> {
  late bool isExpanded;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.isInitialExpanded;
  }

  @override
  void didUpdateWidget(covariant _HistoryGroupItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isInitialExpanded != widget.isInitialExpanded) {
      isExpanded = widget.isInitialExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => isExpanded = !isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title, style: GoogleFonts.montserrat(fontSize: 10, color: const Color(0xFF403600), fontWeight: FontWeight.w900)),
                Icon(isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 16, color: const Color(0xFF403600)),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isExpanded
              ? Column(
                  children: widget.items.map((m) => _HistoryRowItem(transaction: m)).toList(),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
