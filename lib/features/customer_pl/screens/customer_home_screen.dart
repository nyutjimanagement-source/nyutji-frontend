import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../providers/wallet_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../core/utils/formatters.dart';
import 'customer_order_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  // Enterprise/Super-App Colors (Tighter, Denser Feel)
  final Color bgColor = const Color(0xFFF4F6F9); // cooler, professional grey-white
  final Color primaryTeal = const Color(0xFF1E5655); // darker, executive teal
  final Color accentYellow = const Color(0xFFF59E0B);
  final Color primaryRed = const Color(0xFFC3312E);
  final Color textDark = const Color(0xFF111827);
  final Color textGrey = const Color(0xFF6B7280);

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(AuthProvider auth) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Pilih Foto Profil", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(LucideIcons.camera, color: Color(0xFF1E5655)),
              title: Text("Ambil Foto Kamera", style: GoogleFonts.montserrat()),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
                if (photo != null) {
                  final success = await auth.updateProfilePhoto(photo.path);
                  if (mounted) {
                    _showBeautifulNotif(success ? "Foto profil berhasil diperbarui" : "Gagal mengunggah foto", success);
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.image, color: Color(0xFF1E5655)),
              title: Text("Pilih dari Galeri", style: GoogleFonts.montserrat()),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                if (image != null) {
                  final success = await auth.updateProfilePhoto(image.path);
                  if (mounted) {
                    _showBeautifulNotif(success ? "Foto profil berhasil diperbarui" : "Gagal mengunggah foto", success);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBeautifulNotif(String message, bool success) {
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: success ? primaryTeal : primaryRed,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Row(
              children: [
                Icon(success ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(message, style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    
    // Hilangkan otomatis setelah 3 detik
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallet();
      context.read<OrderProvider>().fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final Map<String, dynamic> t = {
      'id': {
        'greeting': 'Selamat Pagi',
        'tracking_msg': 'Kurir sedang menuju lokasimu...',
        'pay_label': 'Dompet Nyutji',
        'points_label': 'Poin',
        'voucher_label': 'Voucher',
        'active_text': 'Aktif',
        'main_services': 'Layanan Utama',
        'service_pickup': 'Pick Up Kurir',
        'service_dropoff': 'Antar Sendiri',
        'service_unit': 'Cuci Satuan',
        'service_iron': 'Setrika Khusus',
        'service_dryclean': 'Dry Clean',
        'service_more': 'Lainnya',
        'promo_title': 'Promo & Diskon Spesial',
        'nearest_mitra': 'Mitra Terdekat Nyutji',
        'see_all': 'Lihat Semua',
        'is_open': 'Buka Sekarang',
        'is_closed': 'Tutup',
      },
      'en': {
        'greeting': 'Good Morning',
        'tracking_msg': 'Courier is on the way...',
        'pay_label': 'NyutjiPay',
        'points_label': 'Points',
        'voucher_label': 'Voucher',
        'active_text': 'Active',
        'main_services': 'Main Services',
        'service_pickup': 'Courier Pick Up',
        'service_dropoff': 'Self Drop-off',
        'service_unit': 'Unit Wash',
        'service_iron': 'Special Ironing',
        'service_dryclean': 'Dry Clean',
        'service_more': 'More Services',
        'promo_title': 'Special Promos & Discounts',
        'nearest_mitra': 'Nearest Nyutji Partners',
        'see_all': 'See All',
        'is_open': 'Open Now',
        'is_closed': 'Closed',
      }
    };
    final currentT = t[auth.lang] ?? t['id'];

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompactHeader(currentT),
            _buildActiveTrackingBanner(currentT),
            const SizedBox(height: 12),
            _buildFinancialStrip(currentT),
            const SizedBox(height: 16),
            _buildDenseServicesGrid(currentT),
            const SizedBox(height: 16),
            _buildMiniPromos(currentT),
            const SizedBox(height: 16),
            _buildCompactMitraList(currentT),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // --- 1. COMPACT HEADER ---
  Widget _buildCompactHeader(Map<String, dynamic> currentT) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded( // Menambahkan Expanded utama
            child: Row(
              children: [
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    final photoUrl = auth.user?['profile_photo'];
                    final localPhoto = auth.temporaryLocalPhoto;
                    return GestureDetector(
                      onTap: () => _pickImage(auth),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, 
                          color: primaryTeal.withOpacity(0.1),
                          image: localPhoto != null
                              ? DecorationImage(image: FileImage(File(localPhoto)), fit: BoxFit.cover)
                              : (photoUrl != null && photoUrl.toString().isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage("http://nyutji.com/$photoUrl?v=${DateTime.now().millisecondsSinceEpoch}"), 
                                      fit: BoxFit.cover
                                    ) 
                                  : null,
                        ),
                        child: (localPhoto == null && (photoUrl == null || photoUrl.toString().isEmpty)) 
                            ? Icon(LucideIcons.user, color: primaryTeal, size: 20) 
                            : null,
                      ),
                    );
                  }
                ),
                const SizedBox(width: 12),
                Expanded( // Menambahkan Expanded agar Column tahu batasnya
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          return Text(
                            auth.user?['name'] ?? "Pelanggan", 
                            maxLines: 2, // Maksimal 2 baris
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: textDark)
                          );
                        }
                      ),
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          final district = auth.user?['district_name'];
                          final city = auth.user?['city_name'];
                          final location = (district != null && city != null)
                              ? "$district, $city"
                              : district ?? city ?? "Lokasi tidak diset";
                          return Row(
                            children: [
                              Icon(LucideIcons.mapPin, size: 10, color: primaryRed),
                              const SizedBox(width: 4),
                              Expanded( // Lokasi juga kita buat expanded agar aman
                                child: Text(
                                  location, 
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.montserrat(fontSize: 11, color: textGrey)
                                ),
                              ),
                            ],
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12), // Jarak aman ke icon
          Row(
            children: [
              _buildIconBtn(LucideIcons.search),
              const SizedBox(width: 8),
              _buildIconBtn(LucideIcons.bell),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildIconBtn(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 18, color: textDark),
    );
  }

  // --- 2. THE TICKER (ACTIVE TRACKING) ---
  Widget _buildActiveTrackingBanner(Map<String, dynamic> currentT) {
    return Consumer<OrderProvider>(
      builder: (context, orderProv, _) {
        if (orderProv.activeOrders.isEmpty) return const SizedBox.shrink();
        
        final latestOrder = orderProv.activeOrders.first;
        String statusMsg = "Pesanan ${latestOrder['id']} : ${latestOrder['status']}";
        
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue[100]!)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.blue[600], shape: BoxShape.circle),
                child: const Icon(LucideIcons.truck, size: 10, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(statusMsg, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue[900]), overflow: TextOverflow.ellipsis),
              ),
              Icon(LucideIcons.chevronRight, size: 14, color: Colors.blue[800])
            ],
          ),
        );
      }
    );
  }

  // --- 3. HIGH DENSITY FINANCIAL STRIP ---
  Widget _buildFinancialStrip(Map<String, dynamic> currentT) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primaryTeal,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: primaryTeal.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.wallet, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(currentT['pay_label'], style: GoogleFonts.montserrat(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Consumer<WalletProvider>(
                  builder: (context, wallet, _) {
                    return Text(
                      Formatters.currencyIdr(wallet.balance), 
                      style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)
                    );
                  }
                ),
              ],
            ),
            Container(width: 1, height: 35, color: Colors.white24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(currentT['points_label'], style: GoogleFonts.montserrat(fontSize: 11, color: Colors.white70)),
                 const SizedBox(height: 4),
                 Row(
                   children: [
                     Icon(LucideIcons.star, size: 12, color: accentYellow),
                     const SizedBox(width: 4),
                     Text("2.400", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                   ],
                 ),
              ],
            ),
            Container(width: 1, height: 35, color: Colors.white24),
             Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(currentT['voucher_label'], style: GoogleFonts.montserrat(fontSize: 11, color: Colors.white70)),
                 const SizedBox(height: 4),
                 Row(
                   children: [
                     const Icon(LucideIcons.ticket, size: 12, color: Colors.greenAccent),
                     const SizedBox(width: 4),
                     Text("4 ${currentT['active_text']}", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                   ],
                 ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. DENSE GRID SERVICES ---
  Widget _buildDenseServicesGrid(Map<String, dynamic> currentT) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(currentT['main_services'], style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: textDark)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0, 
            children: [
              _buildServiceGridItem(currentT['service_pickup'], LucideIcons.truck, primaryTeal, true, currentT),
              _buildServiceGridItem(currentT['service_dropoff'], LucideIcons.footprints, primaryRed, false, currentT),
              _buildServiceGridItem(currentT['service_unit'], LucideIcons.shirt, Colors.indigo, false, currentT),
              _buildServiceGridItem(currentT['service_iron'], LucideIcons.wind, Colors.orange, false, currentT),
              _buildServiceGridItem(currentT['service_dryclean'], LucideIcons.sprayCan, Colors.purple, false, currentT),
              _buildServiceGridItem(currentT['service_more'], LucideIcons.layoutGrid, textGrey, false, currentT),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildServiceGridItem(String title, IconData icon, Color color, bool isPromo, Map<String, dynamic> currentT) {
    return GestureDetector(
      onTap: () {
        if(title == currentT['service_pickup'] || title == currentT['service_dropoff']) {
           Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerOrderScreen(orderType: title == currentT['service_pickup'] ? 'pickup' : 'drop')));
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)]
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Container(
                   padding: const EdgeInsets.all(10),
                   decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                   child: Icon(icon, color: color, size: 22),
                 ),
                 const SizedBox(height: 8),
                 Text(title, textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: textDark, height: 1.2)),
              ],
            ),
          ),
          if (isPromo) 
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: primaryRed, borderRadius: BorderRadius.circular(8)),
                child: Text("PROMO", style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
              )
            )
        ],
      ),
    );
  }

  // --- 5. COMPACT HORIZONTAL PROMOS ---
  Widget _buildMiniPromos(Map<String, dynamic> currentT) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
                Text(currentT['promo_title'], style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: textDark)),
                Text(currentT['see_all'], style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTeal)),
             ],
           ),
           const SizedBox(height: 12),
           SizedBox(
             height: 110,
             child: ListView(
               scrollDirection: Axis.horizontal,
               physics: const BouncingScrollPhysics(),
               children: [
                 _buildPromoStrip("Diskon 20%", "Dry Clean Pesta", Colors.red[700]!, "https://images.unsplash.com/photo-1635274605638-d44babc08a4f?w=400&q=80", currentT),
                 const SizedBox(width: 12),
                 _buildPromoStrip("Cashback Koin", "NyutjiPay 50%", accentYellow, "https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=400&q=80", currentT),
                 const SizedBox(width: 12),
                 _buildPromoStrip("Gratis Ongkir", "Antar Jemput", Colors.blue[700]!, "https://images.unsplash.com/photo-1604176354204-9268737828e4?w=400&q=80", currentT),
               ],
             ),
           )
        ],
      ),
    );
  }

  Widget _buildPromoStrip(String tag, String title, Color color, String imgUrl, Map<String, dynamic> currentT) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(image: NetworkImage(imgUrl), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken))
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            child: Text(tag, style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(height: 6),
          Text(title, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
        ],
      ),
    );
  }

  // --- 6. VERTICAL COMPACT MITRA ACCORDION STYLE ---
  Widget _buildCompactMitraList(Map<String, dynamic> currentT) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text(currentT['nearest_mitra'], style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: textDark)),
               const Icon(LucideIcons.listFilter, size: 16, color: Colors.grey)
             ],
           ),
           const SizedBox(height: 12),
           _buildMitraRow("Berkah Laundry", "0.8 km", "Menengah", "4.9", true, true, currentT),
           _buildMitraRow("Maju Jaya Wash", "1.2 km", "Kecil", "4.7", false, false, currentT),
           _buildMitraRow("Klin Klin Kemang", "2.1 km", "Kecil", "4.6", false, false, currentT),
        ],
      ),
    );
  }

  Widget _buildMitraRow(String name, String dist, String type, String rating, bool isTop, bool isBuka, Map<String, dynamic> currentT) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4)]
      ),
      child: Row(
        children: [
           Container(
             width: 42, height: 42,
             decoration: BoxDecoration(color: primaryTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
             child: ClipRRect(
               borderRadius: BorderRadius.circular(10),
               child: Image.network("https://images.unsplash.com/photo-1545173168-9f1947eebb7f?w=150&q=80", fit: BoxFit.cover,
                 errorBuilder: (context, _, __) => Icon(LucideIcons.store, color: primaryTeal, size: 20),
               )
             )
           ),
           const SizedBox(width: 12),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(
                   children: [
                     Text(name, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: textDark)),
                     if (isTop) ...[
                       const SizedBox(width: 4),
                       const Icon(Icons.verified, size: 14, color: Colors.blue)
                     ]
                   ],
                 ),
                 const SizedBox(height: 2),
                 Row(
                   children: [
                     Icon(LucideIcons.mapPin, size: 10, color: textGrey),
                     const SizedBox(width: 4),
                     Text("$dist • ", style: GoogleFonts.montserrat(fontSize: 10, color: textGrey, fontWeight: FontWeight.w600)),
                     Text(isBuka ? currentT['is_open'] : currentT['is_closed'], style: GoogleFonts.montserrat(fontSize: 10, color: isBuka ? Colors.green[700] : Colors.red, fontWeight: FontWeight.bold)),
                   ],
                 )
               ],
             ),
           ),
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
             decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(8)),
             child: Row(
               children: [
                 const Icon(LucideIcons.star, size: 12, color: Colors.amber),
                 const SizedBox(width: 4),
                 Text(rating, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber[800])),
               ],
             ),
           )
        ],
      ),
    );
  }
}
