import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/widgets/marquee_widget.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../core/theme/theme_util.dart'; // Import RetroRoute
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
  
  bool isPhoneVerified = true;
  bool _obscurePassword = true;

  final Map<String, dynamic> t = {
    'id': {
      'welcome': "Selamat Datang!",
      'subtitle': "Masuk ke akun Anda untuk mulai laundry",
      'phone': "Nomor Handphone",
      'login': "Masuk",
      'register': "Daftar Sekarang",
      'register_as': "Daftar Sebagai",
      'roles': {'PL': 'Pelanggan', 'KL': 'Kurir', 'ML': 'Mitra'},
      'phone_label': "Nomor Handphone",
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
      'welcome': "Welcome Back!",
      'subtitle': "Sign in to start your laundry",
      'phone': "Phone Number",
      'login': "Sign In",
      'register': "Register Now",
      'register_as': "Register As",
      'roles': {'PL': 'Customer', 'KL': 'Courier', 'ML': 'Partner'},
      'phone_label': "Phone Number",
      'help': "Helpdesk",
      'promo': "Promos & Services",
      'about': "About Nyutji Management",
      'marquee': "••• Nyutji Management Partnership Progress: 5 New Branches Opened This Month! Join Us as a Partner ••• 10% Discount Promo for Complete Wash •••",
      'aboutDesc': "Learn more about our partnership system and professional laundry management.",
      'products': [
        { 'title': "Complete Wash", 'desc': "Clean & Fresh 24h", 'img': "https://images.unsplash.com/photo-1635274605638-d44babc08a4f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080" },
        { 'title': "Premium Wash", 'desc': "Premium Care", 'img': "https://images.unsplash.com/photo-1604176354204-9268737828e4?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080" },
        { 'title': "Ironing Only", 'desc': "Neat & Ready", 'img': "https://images.unsplash.com/photo-1489274495757-95c7c837b101?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080" }
      ],
      'err_no_reg': "Nomor tidak terdaftar! Periksa kembali atau daftar baru.",
      'err_pass': "Kata sandi yang Anda masukkan salah.",
    }
  };

  void _handleAction() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // LOGIKA BYPASS UNTUK SOFT LAUNCH
    // Mengizinkan identifier kosong dan auto-infer dari password di provider
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
      NyutjiNotif.showError(
        context, 
        auth.lang == 'id' ? 'Kredensial Salah!' : 'Invalid Credentials!'
      );
    }
  }


  void _resetPhone() {
    setState(() {
      isPhoneVerified = false;
      passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentT = t[auth.lang];

    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: const BoxDecoration(
            color: Color(0xFFF8F4E6),
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 10))],
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () => auth.setLanguage(auth.lang == 'id' ? 'en' : 'id'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE5E5E5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.globe, size: 16, color: Color(0xFF286B6A)),
                                  const SizedBox(width: 8),
                                  Text(
                                    auth.lang.toUpperCase(),
                                    style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF286B6A)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF286B6A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.headphones, size: 16, color: Color(0xFF286B6A)),
                                const SizedBox(width: 8),
                                Text(
                                  currentT['help'],
                                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF286B6A)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Column(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                          ),
                          child: ClipOval(
                            child: Image.asset('assets/images/logo_nyutji.png', fit: BoxFit.contain),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ny. Utji Laundry',
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFC3312E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentT['welcome'],
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.black.withOpacity(0.05)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 30, offset: const Offset(0, 8))
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                width: 8,
                                child: Container(color: const Color(0xFF286B6A)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(24).copyWith(left: 32),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                  Text(
                                    currentT['login'],
                                    style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF286B6A)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentT['subtitle'],
                                    style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[500]),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    currentT['phone'],
                                    style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      hintText: "0812 3456 7890",
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Kolom Password Dinamis
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (Widget child, Animation<double> animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0, -0.2),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: isPhoneVerified 
                                      ? Column(
                                          key: const ValueKey('passwordField'),
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                              Text(
                                                auth.lang == 'id' ? "Kata Sandi" : "Password",
                                                style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                                              ),
                                            const SizedBox(height: 8),
                                            TextField(
                                              controller: passwordController,
                                              focusNode: passwordFocusNode,
                                              obscureText: _obscurePassword,
                                              decoration: InputDecoration(
                                                hintText: "••••••••",
                                                filled: true,
                                                fillColor: Colors.grey[50],
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                                    size: 20,
                                                    color: Colors.grey,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _obscurePassword = !_obscurePassword;
                                                    });
                                                  },
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                          ],
                                        )
                                      : const SizedBox(key: ValueKey('none')),
                                  ),
                                  
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _handleAction,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFC3312E),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        elevation: 4,
                                      ),
                                      child: Text(
                                        isPhoneVerified ? currentT['login'] : (auth.lang == 'id' ? 'Lanjut' : 'Continue'), 
                                        style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Center(
                                    child: Text(
                                      currentT['register_as'],
                                      style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildRoleItem(
                                        context,
                                        label: currentT['roles']['PL'],
                                        icon: LucideIcons.user,
                                        color: const Color(0xFF286B6A),
                                        onTap: () => Navigator.push(context, RetroRoute(page: const RegisterPelangganScreen())),
                                      ),
                                      _buildRoleItem(
                                        context,
                                        label: currentT['roles']['KL'],
                                        icon: LucideIcons.truck,
                                        color: const Color(0xFFD35400),
                                        onTap: () => Navigator.push(context, RetroRoute(page: const RegisterKurirScreen())),
                                      ),
                                      _buildRoleItem(
                                        context,
                                        label: currentT['roles']['ML'],
                                        icon: LucideIcons.store,
                                        color: const Color(0xFF27AE60),
                                        onTap: () => Navigator.push(context, RetroRoute(page: const RegisterMitraScreen())),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.tag, size: 16, color: Color(0xFFC3312E)),
                          const SizedBox(width: 8),
                          Text(currentT['promo'], style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(left: 24, right: 8),
                        scrollDirection: Axis.horizontal,
                        itemCount: currentT['products'].length,
                        itemBuilder: (context, index) {
                          final prod = currentT['products'][index];
                          return Container(
                            width: 165,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.black.withOpacity(0.05)),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                  child: Stack(
                                    children: [
                                      Image.network(
                                        prod['img'],
                                        height: 110,
                                        width: 165,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: Colors.grey[200],
                                          child: const Center(child: Icon(LucideIcons.imagePlus, color: Colors.grey, size: 30)),
                                        ),
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF286B6A)));
                                        },
                                      ),
                                      Container(
                                        height: 110,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        left: 12,
                                        child: Text(
                                          prod['title'],
                                          style: GoogleFonts.montserrat(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    prod['desc'],
                                    style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF286B6A),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [BoxShadow(color: const Color(0xFF286B6A).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.shieldCheck, color: Color(0xFFF8F4E6), size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        currentT['about'],
                                        style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currentT['aboutDesc'],
                                    style: GoogleFonts.montserrat(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                              child: const Icon(LucideIcons.chevronRight, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 40,
                  color: const Color(0xFFC3312E),
                  child: MarqueeWidget(text: currentT['marquee']),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleItem(BuildContext context, {required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.2), width: 1.5),
              boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

