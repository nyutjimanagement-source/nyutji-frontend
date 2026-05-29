import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/widgets/marquee_widget.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../core/theme/theme_util.dart';
import 'register_kurir_screen.dart';
import 'register_mitra_screen.dart';
import 'register_pelanggan_screen.dart';
import '../../admin_ad/screens/admin_tentang_nyutji.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode passwordFocusNode = FocusNode();
  
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  final Map<String, dynamic> t = {
    'id': {
      'welcome': "Selamat Datang!",
      'subtitle': "Masuk untuk Nyuci. Belum punya akun ? ",
      'phone': "Nomor Handphone",
      'login': "Masuk",
      'register': "Daftar disini",
      'register_as': "Daftar Sebagai",
      'roles': {'PL': 'Pelanggan', 'KL': 'Kurir', 'ML': 'Mitra'},
      'help': "Bantuan",
      'promo': "Promo & Layanan Kami",
      'about': "Tentang Nyutji Management",
      'marquee': "••• Progress Kemitraan Nyutji Management: 5 Cabang Baru Dibuka di Bulan Ini! Bergabunglah Menjadi Mitra Kami ••• Promo Diskon 10% untuk Cuci Komplit •••",
      'aboutDesc': "Pelajari lebih lanjut tentang sistem kemitraan dan manajemen laundry profesional kami.",
      'products': [
        { 'title': "Cuci Komplit", 'desc': "Bersih & Wangi 24 Jam", 'img': "assets/images/cuci_komplit.jpg" },
        { 'title': "Cuci Satuan", 'desc': "Perawatan Premium", 'img': "assets/images/cuci_satuan.jpg" },
        { 'title': "Setrika Saja", 'desc': "Rapi & Siap Pakai", 'img': "assets/images/setrika_saja.jpg" },
        { 'title': "Cuci Kesayangan", 'desc': "Harum Pakaian Anak", 'img': "assets/images/cucian_anak.jpg" },
        { 'title': "Cuci Khusus", 'desc': "Refreshing Kesayangan", 'img': "assets/images/stroller.jpg" },
        { 'title': "Antar Jemput Kurir", 'desc': "Cucian Sampai Depan Rumah", 'img': "assets/images/kurir_service.jpg" }
      ]
    },
    'en': {
      'welcome': "Welcome!",
      'subtitle': "Sign in to start. No account ? ",
      'phone': "Phone Number",
      'login': "Sign In",
      'register': "Register here",
      'register_as': "Register As",
      'roles': {'PL': 'Customer', 'KL': 'Courier', 'ML': 'Partner'},
      'help': "Help",
      'promo': "Promos & Services",
      'about': "About Nyutji Management",
      'marquee': "••• Nyutji Management Partnership Progress: 5 New Branches Opened This Month! Join Us as a Partner ••• 10% Discount Promo for Complete Wash •••",
      'aboutDesc': "Learn more about our partnership system and professional laundry management.",
      'products': [
        { 'title': "Complete Wash", 'desc': "Clean & Fresh 24h", 'img': "assets/images/cuci_komplit.jpg" },
        { 'title': "Premium Wash", 'desc': "Premium Care", 'img': "assets/images/cuci_satuan.jpg" },
        { 'title': "Ironing Only", 'desc': "Neat & Ready", 'img': "assets/images/setrika_saja.jpg" },
        { 'title': "Beloved Care", 'desc': "Kids Clothes Wash", 'img': "assets/images/cucian_anak.jpg" },
        { 'title': "Special Wash", 'desc': "Stroller & Helmet", 'img': "assets/images/stroller.jpg" },
        { 'title': "Courier Pickup", 'desc': "Delivery to Your Door", 'img': "assets/images/kurir_service.jpg" }
      ],
    }
  };

  void _handleAction() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool success = await auth.login(phoneController.text, passwordController.text);
    
    if (success) {
      if (!mounted) return;
      String targetRoute = '/customer_main';
      switch (auth.role) {
        case 'PL': targetRoute = '/customer_main'; break;
        case 'ML': targetRoute = '/mitra_home'; break;
        case 'KL': targetRoute = '/courier_main'; break;
        case 'AD': targetRoute = '/admin_main'; break;
      }
      Navigator.pushReplacementNamed(context, targetRoute);
    } else {
      if (!mounted) return;
      String errorMsg = auth.lastErrorMessage ?? "";
      if (errorMsg.contains("PENDING")) {
        NyutjiNotif.showInfo(context, "Mohon Bersabar Ya, Akun Anda sedang Menunggu Approval.");
      } else {
        NyutjiNotif.showError(context, errorMsg.isNotEmpty ? errorMsg : "Kredensial Salah!");
      }
    }
  }

  void _showRegisterOptions() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentT = t[auth.lang] ?? t['id'];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50, height: 5,
                margin: const EdgeInsets.only(bottom: 32),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
              Text(currentT['register_as'], style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 20, color: const Color(0xFF286B6A))),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildRoleItem(
                    context,
                    label: currentT['roles']['PL'],
                    icon: LucideIcons.user,
                    color: const Color(0xFF286B6A),
                    onTap: () { Navigator.pop(context); Navigator.push(context, RetroRoute(page: const RegisterPelangganScreen())); },
                  ),
                  _buildRoleItem(
                    context,
                    label: currentT['roles']['KL'],
                    icon: LucideIcons.truck,
                    color: const Color(0xFFD35400),
                    onTap: () { Navigator.pop(context); Navigator.push(context, RetroRoute(page: const RegisterKurirScreen())); },
                  ),
                  _buildRoleItem(
                    context,
                    label: currentT['roles']['ML'],
                    icon: LucideIcons.store,
                    color: const Color(0xFFC3312E),
                    onTap: () { Navigator.pop(context); Navigator.push(context, RetroRoute(page: const RegisterMitraScreen())); },
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentT = t[auth.lang] ?? t['id'];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFDF7EA), Color(0xFFE8F4F4)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Header: ID & Bantuan
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _glassButton(
                          onTap: () => auth.setLanguage(auth.lang == 'id' ? 'en' : 'id'),
                          icon: LucideIcons.globe,
                          label: auth.lang.toUpperCase(),
                        ),
                        _glassButton(
                          onTap: () {},
                          icon: LucideIcons.headphones,
                          label: currentT['help'],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Logo & Title
                  Column(
                    children: [
                      SizedBox(
                        width: 100, height: 100,
                        child: Image.asset('assets/images/logo_nyutji.png', fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ny Utji Laundry',
                        style: GoogleFonts.montserrat(fontSize: 26, fontWeight: FontWeight.w900, color: const Color(0xFF286B6A), letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentT['welcome'],
                        style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF4B4B4B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Masuk Card (Glassmorphism)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 10))],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Masuk", style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF286B6A))),
                                const SizedBox(height: 4),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(currentT['subtitle'], style: GoogleFonts.montserrat(fontSize: 12, color: Colors.black54)),
                                    GestureDetector(
                                      onTap: _showRegisterOptions,
                                      child: Text(currentT['register'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFC3312E))),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _inputLabel(currentT['phone']),
                                const SizedBox(height: 8),
                                _textField(controller: phoneController, hint: "0812 3456 7890", keyboardType: TextInputType.phone, icon: LucideIcons.phone),
                                const SizedBox(height: 16),
                                _inputLabel(auth.lang == 'id' ? "Kata Sandi" : "Password"),
                                const SizedBox(height: 8),
                                _textField(
                                  controller: passwordController,
                                  hint: "••••••••",
                                  obscureText: _obscurePassword,
                                  icon: LucideIcons.lock,
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 20, color: Colors.grey),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _handleAction,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF286B6A),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      elevation: 0,
                                    ),
                                    child: Text(currentT['login'], style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 15)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Promo Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFD35400).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(LucideIcons.sparkles, size: 18, color: Color(0xFFD35400)),
                        ),
                        const SizedBox(width: 12),
                        Text(currentT['promo'], style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF286B6A))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(left: 24, right: 8),
                      scrollDirection: Axis.horizontal,
                      itemCount: currentT['products'].length,
                      itemBuilder: (context, index) {
                        final prod = currentT['products'][index];
                        return _productCard(prod);
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Banner About (Tap Navigates to AdminTentangNyutjiScreen)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(context, RetroRoute(page: const AdminTentangNyutjiScreen()));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFC3312E), Color(0xFFE74C3C)]),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [BoxShadow(color: const Color(0xFFC3312E).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                              child: const Icon(LucideIcons.info, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(currentT['about'], style: GoogleFonts.montserrat(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 6),
                                  Text(currentT['aboutDesc'], style: GoogleFonts.montserrat(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, height: 1.4)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(LucideIcons.chevronRight, color: Colors.white, size: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text("Version 1.5.4", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black26)),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 40 + MediaQuery.of(context).padding.bottom,
        color: const Color(0xFF286B6A),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: MarqueeWidget(text: currentT['marquee']),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _glassButton({required VoidCallback onTap, required IconData icon, required String label}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF4B4B4B)),
                const SizedBox(width: 8),
                Text(label, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF4B4B4B))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputLabel(String label) {
    return Text(label, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF286B6A)));
  }

  Widget _textField({required TextEditingController controller, String? hint, bool obscureText = false, Widget? suffixIcon, TextInputType? keyboardType, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF286B6A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(fontSize: 15, color: Colors.grey[400], fontWeight: FontWeight.normal),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF286B6A), width: 1.5)),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> prod) {
    final String imgSrc = prod['img'] ?? '';
    final bool isNetwork = imgSrc.startsWith('http');

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Stack(
              children: [
                isNetwork 
                    ? Image.network(imgSrc, height: 140, width: 200, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(height: 140, color: Colors.grey[300], child: const Icon(Icons.image_not_supported)))
                    : Image.asset(imgSrc, height: 140, width: 200, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(height: 140, color: Colors.grey[300], child: const Icon(Icons.image_not_supported))),
                Container(
                  height: 140,
                  decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)])),
                ),
                Positioned(bottom: 16, left: 16, right: 16, child: Text(prod['title'], style: GoogleFonts.montserrat(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(prod['desc'], style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleItem(BuildContext context, {required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 12),
          Text(label, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}
