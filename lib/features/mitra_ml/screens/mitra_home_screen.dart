// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/widgets/nyutji_location_picker.dart';
import '../../../core/constants/api_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../core/utils/formatters.dart';
import 'mitra_wallet_screen.dart';
import 'mitra_order_screen.dart';
import 'mitra_pricing_screen.dart';

class MitraHomeScreen extends StatefulWidget {
  const MitraHomeScreen({super.key});

  @override
  State<MitraHomeScreen> createState() => _MitraHomeScreenState();
}

class _MitraHomeScreenState extends State<MitraHomeScreen> {
  static const primaryTeal = Color(0xFF1E5655); // Denser, more executive teal
  static const bgColor = Color(0xFFF3F4F6);
  static const darkText = Color(0xFF111827);
  static const textGrey = Color(0xFF6B7280);
  bool _isCourierMenuExpanded = false;
  bool _isAddressExpanded = false;

  // LOCATION UPDATE STATE
  final TextEditingController _fullAddressController = TextEditingController();
  String _selectedDistrict = "";
  String _selectedCity = "";
  double _selectedLat = 0.0;
  double _selectedLng = 0.0;
  bool _isUpdatingLocation = false;

  final ImagePicker _picker = ImagePicker();

  int _selectedIndex = 0;
  late PageController _pageController;
  bool isShopOpen = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<WalletProvider>().fetchWallet();
      auth.fetchCouriers();
      auth.fetchPendingApprovals();

      // Inisialisasi controller dengan alamat user saat ini
      if (auth.user != null) {
        _fullAddressController.text = auth.user?['address']?.toString() ?? "";
        _selectedDistrict = auth.user?['district_name']?.toString() ?? "";
        _selectedCity = auth.user?['city_name']?.toString() ?? "";
        _selectedLat = double.tryParse(auth.user?['lat']?.toString() ?? '0') ?? 0.0;
        _selectedLng = double.tryParse(auth.user?['lng']?.toString() ?? '0') ?? 0.0;
      }
    });

    // Auto-refresh data kurir tiap 5 detik
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        context.read<AuthProvider>().fetchPendingApprovals();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> t = {
      'id': {'logout': 'Keluar Akun'},
    };
    final currentT = t['id']; 

    final List<Widget> tabs = [
      _buildHomeTab(currentT),
      const MitraOrderScreen(),
      const MitraWalletScreen(),
      _buildProfileTab(currentT),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _selectedIndex = index);
                },
                children: tabs,
              ),
            ),
            _buildBottomNav(primaryTeal),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(AuthProvider auth) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Pilih Foto Profil Toko", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(LucideIcons.camera, color: primaryTeal),
              title: Text("Ambil Foto Kamera", style: GoogleFonts.montserrat()),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
                if (photo != null) {
                  final success = await auth.updateProfilePhoto(photo);
                  if (mounted) _showBeautifulNotif(success ? "Foto profil berhasil diperbarui" : "Gagal mengunggah foto", success);
                }
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.image, color: primaryTeal),
              title: Text("Pilih dari Galeri", style: GoogleFonts.montserrat()),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                if (image != null) {
                  final success = await auth.updateProfilePhoto(image);
                  if (mounted) _showBeautifulNotif(success ? "Foto profil berhasil diperbarui" : "Gagal mengunggah foto", success);
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
              color: success ? primaryTeal : const Color(0xFFC3312E),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
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
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  // === DENSE HOME TAB (COMMAND CENTER) ===
  Widget _buildHomeTab(Map<String, dynamic>? currentT) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDenseHeader(),
          _buildLiveStatusStrip(),
          const SizedBox(height: 12),
          _buildCommandMetrics(),
          const SizedBox(height: 16),
          _buildQuickActionsGrid(),
          const SizedBox(height: 16),
          _buildLiveQueueMachine(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileImage(AuthProvider auth, dynamic photoUrl, String? localPhoto) {
    if (localPhoto == null && auth.temporaryWebBytes == null && (photoUrl == null || photoUrl.toString().isEmpty)) {
      return const Icon(LucideIcons.store, color: Colors.white, size: 20);
    }
    
    if (kIsWeb) {
      if (auth.temporaryWebBytes != null) {
        return Image.memory(auth.temporaryWebBytes!, fit: BoxFit.cover, gaplessPlayback: true);
      }
    } else {
      if (localPhoto != null) {
        return Image.file(File(localPhoto), fit: BoxFit.cover, gaplessPlayback: true);
      }
    }
    
    final url = photoUrl.toString().startsWith('http') 
        ? photoUrl.toString()
        : "${ApiConstants.rootUrl}/$photoUrl";
        
    return Image.network(
      url, 
      fit: BoxFit.cover, 
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const Icon(LucideIcons.store, color: Colors.white, size: 20),
    );
  }

  Widget _buildDenseHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    final photoUrl = auth.user?['profile_photo'];
                    final localPhoto = auth.temporaryLocalPhoto;
                    return GestureDetector(
                      onTap: () => _pickImage(auth),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: primaryTeal,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _buildProfileImage(auth, photoUrl, localPhoto),
                        ),
                      ),
                    );
                  }
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Consumer<AuthProvider>(
                              builder: (context, auth, _) => Text(
                                auth.user?['name'] ?? "Mitra Nyutji", 
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: darkText)
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, size: 14, color: Colors.blue),
                        ],
                      ),
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          final district = auth.user?['district_name'] ?? "Kecamatan";
                          final city = auth.user?['city_name'] ?? "Kota";
                          final id = auth.user?['identifier'] ?? auth.user?['id'] ?? '0000';
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(4)),
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.star, size: 10, color: Colors.amber),
                                        const SizedBox(width: 2),
                                        Text("4.9", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber[900])),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text("ID: ${Formatters.nyutjiId('ML', id, district, districtCode: auth.user?['district_code'])}", style: GoogleFonts.montserrat(fontSize: 11, color: primaryTeal, fontWeight: FontWeight.w700)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text("$district - $city", style: GoogleFonts.montserrat(fontSize: 11, color: textGrey, fontWeight: FontWeight.w600)),
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
          const SizedBox(width: 12),
          Row(
            children: [
              IconButton(onPressed: () {}, icon: const Icon(LucideIcons.search, color: darkText, size: 22), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 10),
              Consumer<OrderProvider>(
                builder: (context, orderProv, _) => Stack(
                  children: [
                    IconButton(
                      onPressed: () => orderProv.resetNotif('ML'), 
                      icon: const Icon(LucideIcons.bell, color: darkText, size: 22), 
                      padding: EdgeInsets.zero, 
                      constraints: const BoxConstraints()
                    ),
                    if (orderProv.notifCountML > 0)
                      Positioned(
                        right: 0, top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                          child: Text(
                            orderProv.notifCountML > 9 ? "9+" : orderProv.notifCountML.toString(), 
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)
                          ),
                        ),
                      )
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLiveStatusStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: isShopOpen ? Colors.green[50] : Colors.red[50], border: Border(bottom: BorderSide(color: isShopOpen ? Colors.green[200]! : Colors.red[200]!))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: isShopOpen ? Colors.green : Colors.red, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(isShopOpen ? "Toko Buka - Menerima Order Penuh" : "Toko Tutup", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: isShopOpen ? Colors.green[700] : Colors.red[700])),
            ],
          ),
          Switch(
            value: isShopOpen, 
            onChanged: (val) => setState(() => isShopOpen = val), 
            activeThumbColor: Colors.green, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          )
        ],
      ),
    );
  }

  Widget _buildCommandMetrics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: primaryTeal, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: primaryTeal.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Consumer<WalletProvider>(
          builder: (context, wallet, _) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem("HARI INI", Formatters.currencyIdr(wallet.balance), LucideIcons.trendingUp, Colors.greenAccent),
              Container(width: 1, height: 35, color: Colors.white24),
              _buildMetricItem("ANTREAN", "18", LucideIcons.layers, Colors.orangeAccent),
              Container(width: 1, height: 35, color: Colors.white24),
              _buildMetricItem("SELESAI", "45", LucideIcons.checkSquare, Colors.blueAccent),
              Container(width: 1, height: 35, color: Colors.white24),
              _buildMetricItem("KENDALA", "0", LucideIcons.alertTriangle, Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.montserrat(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Aksi Cepat", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: darkText)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
            children: [
              _buildGridAction("Pesanan", LucideIcons.packagePlus, Colors.blue, () {
                _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              }),
              _buildGridAction("Kasir / POS", LucideIcons.calculator, Colors.indigo, (){}),
              _buildGridAction("Dompet", LucideIcons.wallet, Colors.green, () {
                _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              }),
              _buildGridAction("Kinerja", LucideIcons.pieChart, Colors.orange, (){}),
              _buildGridAction("Harga & Promosi", LucideIcons.banknote, Colors.red, () {
                Navigator.push(context, PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const MitraPricingScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return SlideTransition(position: animation.drive(tween), child: child);
                  },
                ));
              }),
              _buildGridAction("Mesin", LucideIcons.cpu, Colors.cyan, (){}),
              _buildGridAction("Pegawai", LucideIcons.users, Colors.purple, (){}),
              _buildGridAction("Kendala", LucideIcons.alertTriangle, Colors.amber, () {
                Navigator.pushNamed(context, '/mitra_report_issue');
              }),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildGridAction(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: darkText)),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveQueueMachine() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text("Live Mesin Operasional", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: darkText)),
               Text("Lihat Semua", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTeal)),
             ],
           ),
           const SizedBox(height: 12),
           _buildMachineRow("Mesin Cuci #1", "Mencuci - KBY-001", 0.6, Colors.blue),
           _buildMachineRow("Mesin Cuci #2", "Standby", 0.0, Colors.grey),
           _buildMachineRow("Mesin Pengering #1", "Mengeringkan - KBY-002", 0.8, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildMachineRow(String mName, String pStatus, double progress, Color mColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        children: [
          Icon(LucideIcons.disc, size: 24, color: mColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(mName, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: darkText)),
                    Text(progress > 0 ? "${(progress*100).toInt()}%" : "0%", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: mColor)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(pStatus, style: GoogleFonts.montserrat(fontSize: 10, color: textGrey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress, 
                  backgroundColor: Colors.grey[100],
                  valueColor: AlwaysStoppedAnimation<Color>(mColor),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // === PROFILE TAB (DENSE) ===
  Widget _buildProfileTab(Map<String, dynamic>? currentT) {
    final auth = context.watch<AuthProvider>();
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final photoUrl = auth.user?['profile_photo'];
                final localPhoto = auth.temporaryLocalPhoto;
                final district = auth.user?['district_name'] ?? "Kecamatan";
                final city = auth.user?['city_name'] ?? "Kota/Kabupaten";
                
                return Row(
                  children: [
                    GestureDetector(
                      onTap: () => _pickImage(auth),
                      child: Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: primaryTeal.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: _buildProfileImage(auth, photoUrl, localPhoto),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(auth.user?['name'] ?? "Berkah Laundry", style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: darkText)),
                          Text("ID: ${Formatters.nyutjiId('ML', auth.user?['identifier'] ?? auth.user?['id'], district, districtCode: auth.user?['district_code'])}", style: GoogleFonts.montserrat(fontSize: 13, color: textGrey, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text("$district - $city", style: GoogleFonts.montserrat(fontSize: 12, color: primaryTeal, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  ],
                );
              }
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
            child: Column(
              children: [
                _buildExpandableAddressMenu(auth),
                const Divider(height: 1),
                _buildMenuItem(LucideIcons.shieldAlert, "Keamanan PIN", false),
                const Divider(height: 1),
                _buildExpandableCourierMenu(),
                const Divider(height: 1),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) => GestureDetector(
                    onTap: () async {
                      try {
                        await auth.logout();
                        if (!context.mounted) return;
                        Navigator.pushReplacementNamed(context, '/login');
                      } catch (e) {
                        if (!context.mounted) return;
                      }
                    },
                    child: _buildMenuItem(LucideIcons.logOut, currentT!['logout'], true),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableAddressMenu(AuthProvider auth) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isAddressExpanded = !_isAddressExpanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(LucideIcons.mapPin, size: 20, color: darkText),
                const SizedBox(width: 12),
                Text("Lokasi Operasional Laundry", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: darkText)),
                const Spacer(),
                Icon(_isAddressExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isAddressExpanded
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const SizedBox(height: 8),
                      // TEXT FIELD ALAMAT LENGKAP
                      Text("Alamat Lengkap", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: textGrey, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _fullAddressController,
                        maxLines: 2,
                        style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: "Masukkan Alamat Lengkap (Jl, No, Gang, dsb)",
                          hintStyle: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryTeal)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // INFO WILAYAH DARI GPS
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("WILAYAH (GPS)", style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, color: textGrey)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.navigation, size: 12, color: primaryTeal),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _selectedDistrict.isEmpty ? "Belum Set Lokasi" : "$_selectedDistrict, $_selectedCity", 
                                        style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: primaryTeal),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showLocationPicker(auth),
                            icon: const Icon(LucideIcons.locateFixed, size: 12),
                            label: Text("UBAH GPS", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryTeal,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // TOMBOL UPDATE
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isUpdatingLocation ? null : () => _handleUpdateLocation(auth),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                            shadowColor: Colors.orange.withValues(alpha: 0.3),
                          ),
                          child: _isUpdatingLocation 
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text("UPDATE DATA LOKASI", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildExpandableCourierMenu() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final pendingUsers = auth.pendingApprovals;
        final activeCouriers = List.from(auth.couriers);
        activeCouriers.sort((a, b) => (a['name']?.toString() ?? '').compareTo(b['name']?.toString() ?? ''));

        return Column(
          children: [
            InkWell(
              onTap: () => setState(() => _isCourierMenuExpanded = !_isCourierMenuExpanded),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(LucideIcons.users, size: 18, color: darkText),
                    const SizedBox(width: 12),
                    Text("Kelola Kurir Laundry", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: darkText)),
                    if (pendingUsers.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFC3312E), borderRadius: BorderRadius.circular(10)),
                        child: Text(pendingUsers.length.toString(), style: GoogleFonts.montserrat(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                    const Spacer(),
                    Icon(_isCourierMenuExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 16, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
            if (_isCourierMenuExpanded)
              Container(
                color: Colors.grey[50],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pendingUsers.isNotEmpty) ...[
                      Text("Antrean Pendaftaran (${pendingUsers.length})", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: primaryTeal)),
                      const SizedBox(height: 8),
                      ...pendingUsers.map((u) => _buildCompactPendingCard(u, auth)),
                      const SizedBox(height: 12),
                    ],
                    Text("Daftar Anggota Aktif (${activeCouriers.length})", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: darkText)),
                    const SizedBox(height: 8),
                    if (activeCouriers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text("Belum ada anggota kurir", style: GoogleFonts.montserrat(fontSize: 11, color: textGrey, fontStyle: FontStyle.italic)),
                      )
                    else
                      ...activeCouriers.map((u) => _buildCompactActiveCard(u)),
                    const SizedBox(height: 8),
                  ],
                ),
              )
          ],
        );
      }
    );
  }

  Widget _buildCompactPendingCard(dynamic user, AuthProvider auth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: primaryTeal.withValues(alpha: 0.1),
            child: const Icon(LucideIcons.user, size: 14, color: primaryTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name'] ?? 'Tanpa Nama', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: darkText)),
                Text(user['phone_number'] ?? '-', style: GoogleFonts.montserrat(fontSize: 10, color: textGrey)),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => _handleApproval(user['identifier'], 'REJECTED', user['name'] ?? 'Pendaftar', auth),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFFC3312E).withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.x, size: 14, color: Color(0xFFC3312E)),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _handleApproval(user['identifier'], 'APPROVED', user['name'] ?? 'Pendaftar', auth),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.check, size: 14, color: primaryTeal),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCompactActiveCard(dynamic user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[100],
            child: const Icon(LucideIcons.user, size: 14, color: textGrey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name'] ?? 'Tanpa Nama', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: darkText)),
                Text(user['phone_number'] ?? '-', style: GoogleFonts.montserrat(fontSize: 10, color: textGrey)),
              ],
            ),
          ),
          Row(
            children: [
              Icon(LucideIcons.star, size: 12, color: Colors.orange[400]),
              const SizedBox(width: 4),
              Text("5.0", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: darkText)),
            ],
          )
        ],
      ),
    );
  }

  Future<void> _handleApproval(dynamic identifier, String action, String name, AuthProvider auth) async {
    final success = await auth.processUserApproval(identifier, action);
    if (success && mounted) {
      if (action == 'APPROVED') {
        _showBeautifulNotif('$name berhasil di-approve!', true);
      } else {
        _showBeautifulNotif('$name telah ditolak.', false);
      }
      await Future.wait([
        auth.fetchPendingApprovals(),
        auth.fetchCouriers(),
      ]);
    }
  }

  // --- LOGIKA UPDATE LOKASI MITRA ---
  void _showLocationPicker(AuthProvider auth) async {
    final result = await showModalBottomSheet<NyutjiLocationResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NyutjiLocationPicker(),
    );

    if (result != null) {
      setState(() {
        _selectedDistrict = result.subdistrict;
        _selectedCity = result.city;
        _selectedLat = result.lat;
        _selectedLng = result.lng;
        // Opsional: Jika user belum isi alamat manual, kita bantu isi dari geocoder
        if (_fullAddressController.text.isEmpty) {
          _fullAddressController.text = result.address;
        }
      });
      if(mounted) _showBeautifulNotif("Lokasi GPS terpilih: $_selectedDistrict", true);
    }
  }

  Future<void> _handleUpdateLocation(AuthProvider auth) async {
    if (_fullAddressController.text.isEmpty || _selectedDistrict.isEmpty) {
      _showBeautifulNotif("Mohon isi Alamat dan Set Lokasi GPS!", false);
      return;
    }

    setState(() => _isUpdatingLocation = true);
    
    final success = await auth.updateLocation({
      'address': _fullAddressController.text,
      'district_name': _selectedDistrict,
      'city_name': _selectedCity,
      'lat': _selectedLat,
      'lng': _selectedLng,
    });

    if (mounted) {
      setState(() => _isUpdatingLocation = false);
      if (success) {
        _showBeautifulNotif("Data Lokasi Mitra berhasil diperbarui!", true);
        setState(() => _isAddressExpanded = false); // Tutup menu setelah sukses
      } else {
        _showBeautifulNotif("Gagal memperbarui data lokasi.", false);
      }
    }
  }

  Widget _buildMenuItem(IconData icon, String title, bool isLogout) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isLogout ? Colors.red : darkText),
          const SizedBox(width: 12),
          Text(title, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: isLogout ? Colors.red : darkText)),
          const Spacer(),
          Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }

  // === BOTTOM NAV ===
  Widget _buildBottomNav(Color activeColor) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05))), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))]),
      child: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(LucideIcons.layoutDashboard, size: 20), activeIcon: Icon(LucideIcons.layoutDashboard, size: 20), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.clipboardList, size: 20), activeIcon: Icon(LucideIcons.clipboardList, size: 20), label: "Pesanan"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.wallet, size: 20), activeIcon: Icon(LucideIcons.wallet, size: 20), label: "Dompet"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.store, size: 20), activeIcon: Icon(LucideIcons.store, size: 20), label: "Toko"),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: activeColor,
        unselectedItemColor: textGrey.withValues(alpha: 0.6),
        showUnselectedLabels: true,
        onTap: (index) {
          _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
        backgroundColor: Colors.white,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 10),
        unselectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 9),
      ),
    );
  }
}
