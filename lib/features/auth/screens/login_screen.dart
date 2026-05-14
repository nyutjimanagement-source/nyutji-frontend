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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode passwordFocusNode = FocusNode();
  
  bool _obscurePassword = true;

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
        { 'title': "Cuci Komplit", 'desc': "Bersih & Wangi 24 Jam", 'img': "https://images.unsplash.com/photo-1635274605638-d44babc08a4f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080" },
        { 'title': "Cuci Satuan", 'desc': "Perawatan Premium", 'img': "https://images.unsplash.com/photo-1604176354204-9268737828e4?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080" },
        { 'title': "Setrika Saja", 'desc': "Rapi & Siap Pakai", 'img': "https://images.unsplash.com/photo-1489274495757-95c7c837b101?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080" }
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
        { 'title': "Complete Wash", 'desc': "Clean & Fresh 24h", 'img': "https://images.unsplash.com/photo-1635274605638-d44babc08a4f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080" },
        { 'title': "Premium Wash", 'desc': "Premium Care", 'img': "https://images.unsplash.com/photo-1604176354204-9268737828e4?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080" },
        { 'title': "Ironing Only", 'desc': "Neat & Ready", 'img': "https://images.unsplash.com/photo-1489274495757-95c7c837b101?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080" }
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            Text(currentT['register_as'], style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentT = t[auth.lang] ?? t['id'];

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7EA), // Cream Background sesuai gambar
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 50),
            // Header: ID & Bantuan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _topButton(
                    onTap: () => auth.setLanguage(auth.lang == 'id' ? 'en' : 'id'),
                    icon: LucideIcons.globe,
                    label: auth.lang.toUpperCase(),
                  ),
                  _topButton(
                    onTap: () {},
                    icon: LucideIcons.headphones,
                    label: currentT['help'],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Logo & Title
            Column(
              children: [
                SizedBox(
                  width: 100, height: 100,
                  child: Image.asset('assets/images/logo_nyutji.png', fit: BoxFit.contain),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ny Utji Laundry',
                  style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFFC3312E)),
                ),
                const SizedBox(height: 4),
                Text(
                  currentT['welcome'],
                  style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF4B4B4B)),
                ),
              ],
            ),
            const SizedBox(height: 40),
            // Masuk Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 10))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Stack(
                    children: [
                      // Left Teal Border
                      Positioned(left: 0, top: 0, bottom: 0, width: 8, child: Container(color: const Color(0xFF286B6A))),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 24, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Masuk", style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF286B6A))),
                            const SizedBox(height: 4),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(currentT['subtitle'], style: GoogleFonts.montserrat(fontSize: 12, color: Colors.black45)),
                                GestureDetector(
                                  onTap: _showRegisterOptions,
                                  child: Text(currentT['register'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF286B6A))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            _inputLabel(currentT['phone']),
                            const SizedBox(height: 8),
                            _textField(controller: phoneController, hint: "0812 3456 7890", keyboardType: TextInputType.phone),
                            const SizedBox(height: 16),
                            _inputLabel(auth.lang == 'id' ? "Kata Sandi" : "Password"),
                            const SizedBox(height: 8),
                            _textField(
                              controller: passwordController,
                              hint: "••••••••",
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 20, color: Colors.grey),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _handleAction,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC3312E),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  elevation: 8,
                                  shadowColor: const Color(0xFFC3312E).withValues(alpha: 0.4),
                                ),
                                child: Text(currentT['login'], style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Promo Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(LucideIcons.tag, size: 18, color: Color(0xFFC3312E)),
                  const SizedBox(width: 8),
                  Text(currentT['promo'], style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 24, right: 8),
                scrollDirection: Axis.horizontal,
                itemCount: currentT['products'].length,
                itemBuilder: (context, index) {
                  final prod = currentT['products'][index];
                  return _productCard(prod);
                },
              ),
            ),
            const SizedBox(height: 32),
            // Banner About
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF286B6A),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: const Color(0xFF286B6A).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.shieldCheck, color: Color(0xFFF8F4E6), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(currentT['about'], style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(currentT['aboutDesc'], style: GoogleFonts.montserrat(color: Colors.white.withValues(alpha: 0.9), fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: const Icon(LucideIcons.chevronRight, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text("Version 1.5.4", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF286B6A).withValues(alpha: 0.5))),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 40 + MediaQuery.of(context).padding.bottom,
        color: const Color(0xFFC3312E),
        child: Column(
          children: [
            Expanded(child: MarqueeWidget(text: currentT['marquee'])),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _topButton({required VoidCallback onTap, required IconData icon, required String label}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF286B6A)),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF286B6A))),
          ],
        ),
      ),
    );
  }

  Widget _inputLabel(String label) {
    return Text(label, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _textField({required TextEditingController controller, String? hint, bool obscureText = false, Widget? suffixIcon, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(fontSize: 15, color: Colors.grey[400], fontWeight: FontWeight.normal),
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E5E5))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E5E5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF286B6A), width: 1.5)),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> prod) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(
              children: [
                Image.network(prod['img'], height: 120, width: 180, fit: BoxFit.cover),
                Container(
                  height: 120,
                  decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)])),
                ),
                Positioned(bottom: 12, left: 16, child: Text(prod['title'], style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(prod['desc'], style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }
  Widget _buildRoleItem(BuildContext context, {required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
