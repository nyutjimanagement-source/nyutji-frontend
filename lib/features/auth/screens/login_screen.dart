import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/widgets/marquee_widget.dart';
import '../../../core/widgets/nyutji_notif.dart';
import '../../../core/theme/theme_util.dart';
import 'register_kurir_screen.dart';
import 'register_mitra_screen.dart';
import 'register_pelanggan_screen.dart';
import '../../admin_ad/screens/admin_tentang_nyutji.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
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
      'marquee': "••• Progress Kemitraan Nyutji Management: 5 Cabang Baru Dibuka di Bulan Ini! Bergabunglah Menjadi Mitra Kami ••• Promo Diskon 10% untuk Cuci Komplit ••• Gratis Antar Jemput untuk Pelanggan Baru",
      'aboutDesc': "Pelajari lebih lanjut tentang sistem kemitraan dan manajemen laundry profesional kami.",
      'products': [
        {
          'title': "Cuci Komplit", 'desc': "Bersih & Wangi 24 Jam", 'img': "assets/images/cuci_komplit.jpg",
          'details': [
            "Cuci Komplit adalah layanan andalan Nyutji yang mencuci, mengeringkan, dan melipat pakaian Anda secara menyeluruh dalam satu paket hemat. Proses dicuci menggunakan deterjen premium yang ramah kulit.",
            "Layanan ini cocok untuk kebutuhan sehari-hari keluarga. Cukup masukkan pakaian ke kantong, dan biarkan Kurir Nyutji menjemputnya langsung di depan pintu rumah Anda tanpa biaya tambahan.",
            "Dijamin selesai dalam 24 jam dan dikembalikan dalam kondisi rapi, harum, dan siap pakai. Harga terjangkau mulai dari Rp 7.000 per kilogram."
          ],
          'mitraContoh': ["One Laundry  •  Tangerang Selatan", "Mutiara Laundry  •  Kab. Sleman", "Leo Laundry  •  Depok"]
        },
        {
          'title': "Cuci Satuan", 'desc': "Perawatan Premium", 'img': "assets/images/cuci_satuan.jpg",
          'details': [
            "Cuci Satuan adalah layanan premium Nyutji yang dirancang untuk pakaian bervalue tinggi seperti kemeja kerja, blazer, dress, dan baju favorit Anda. Setiap item dicuci secara terpisah dengan penanganan khusus.",
            "Proses pencucian menggunakan mesin khusus berkapasitas kecil agar warna tetap cerah dan serat kain tidak mudah rusak. Setiap pakaian dikemas dengan plastik pelindung sebelum diantarkan kembali.",
            "Ideal untuk Anda yang menghargai kualitas dan keawetan pakaian. Harga dihitung per item mulai dari Rp 5.000 saja."
          ],
          'mitraContoh': ["Kece Laundry  •  Kota Surabaya", "Aneka Laundry  •  Kota Bandung", "Perkasa Laundry  •  Semarang"]
        },
        {
          'title': "Setrika Saja", 'desc': "Rapi & Siap Pakai", 'img': "assets/images/setrika_saja.jpg",
          'details': [
            "Layanan Setrika Saja dari Nyutji memastikan pakaian Anda kembali rapi tanpa kerutan hanya dalam hitungan jam. Cocok untuk Anda yang sudah mencuci sendiri namun tidak memiliki waktu untuk menyetrika.",
            "Tim Mitra Nyutji menggunakan setrika uap profesional yang menjaga kelembutan dan bentuk kain. Proses ini juga sekaligus membantu menghilangkan kuman yang tersisa pada pakaian Anda.",
            "Layanan tersedia untuk semua jenis pakaian, termasuk kemeja formal, baju batik, dan gaun. Harga mulai Rp 2.000 per potong saja."
          ],
          'mitraContoh': ["Kilat Laundry  •  Jakarta Selatan", "Cemerlang Laundry  •  Kota Bogor", "Cepat Laundry  •  Bekasi"]
        },
        {
          'title': "Cuci Kesayangan", 'desc': "Harum Pakaian Anak", 'img': "assets/images/cucian_anak.jpg",
          'details': [
            "Cuci Kesayangan adalah layanan khusus untuk pakaian bayi dan anak-anak yang menggunakan deterjen hypoallergenic bebas pewangi buatan dan bahan kimia keras. Aman untuk kulit sensitif si Kecil.",
            "Setiap cucian dicuci secara terpisah dari laundry dewasa, menggunakan air bersih dan prosedur higienitas ketat. Hasilnya bersih maksimal, lembut, dan bebas dari residu deterjen yang berpotensi memicu iritasi.",
            "Pakaian dikembalikan dalam keadaan terlipat rapi di dalam kantong khusus anti-bakteri. Layanan ini memberikan ketenangan pikiran bagi para orang tua yang peduli terhadap kesehatan buah hati."
          ],
          'mitraContoh': ["Bidadari Laundry  •  Jakarta Timur", "Mungil Laundry  •  Kab. Bantul", "Pelangi Laundry  •  Kota Malang"]
        },
        {
          'title': "Cuci Khusus", 'desc': "Refreshing Kesayangan", 'img': "assets/images/stroller.jpg",
          'details': [
            "Cuci Khusus dari Nyutji menangani barang-barang non-pakaian yang membutuhkan pencucian cermat seperti stroller, car seat, tas ransel, sepatu kulit, helm, dan boneka besar.",
            "Setiap item ditangani oleh Mitra terlatih dengan metode pembersihan yang disesuaikan berdasarkan material bahan. Kami memastikan hasil bersih hingga ke celah-celah yang tersembunyi.",
            "Barang dijemput dan diantarkan kembali dengan aman menggunakan perlindungan bubble wrap. Harga bervariasi sesuai jenis dan ukuran barang, konfirmasi harga sebelum proses dimulai."
          ],
          'mitraContoh': ["Spesial Laundry  •  Jakarta Pusat", "Istimewa Laundry  •  Kota Solo", "Hebat Laundry  •  Sidoarjo"]
        },
        {
          'title': "Antar Jemput Kurir", 'desc': "Cucian Sampai Depan Rumah", 'img': "assets/images/kurir_service.jpg",
          'details': [
            "Layanan Antar Jemput Kurir Nyutji hadir untuk memastikan cucian Anda diproses tanpa perlu meninggalkan rumah. Kurir Nyutji terlatih dan terpercaya siap menjemput cucian kapan pun Anda minta.",
            "Sistem pemesanan berbasis aplikasi memudahkan Anda melacak posisi Kurir secara real-time, dari saat penjemputan hingga pengantaran kembali. Notifikasi status otomatis dikirimkan di setiap tahap proses.",
            "Gratis antar jemput untuk area yang sudah bermitra dengan Nyutji. Cukup pesan melalui aplikasi dan nikmati kenyamanan cucian bersih tanpa repot."
          ],
          'mitraContoh': ["Lancar Laundry  •  Kota Yogyakarta", "Ceria Laundry  •  Kab. Sleman", "Karya Laundry  •  Jakarta Selatan"]
        },
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
        {
          'title': "Complete Wash", 'desc': "Clean & Fresh 24h", 'img': "assets/images/cuci_komplit.jpg",
          'details': [
            "Complete Wash is Nyutji's signature service that washes, dries, and folds your clothes thoroughly in one affordable package. Premium skin-friendly detergent is used for every wash.",
            "This service is perfect for everyday family needs. Simply pack your clothes in the bag, and let Nyutji's courier pick it up right from your doorstep at no extra charge.",
            "Guaranteed to be done in 24 hours and returned in a neat, fragrant, and ready-to-wear condition. Affordable price starting from Rp 7,000 per kilogram."
          ],
          'mitraContoh': ["One Laundry  •  Tangerang Selatan", "Mutiara Laundry  •  Kab. Sleman", "Leo Laundry  •  Depok"]
        },
        {
          'title': "Premium Wash", 'desc': "Premium Care", 'img': "assets/images/cuci_satuan.jpg",
          'details': [
            "Premium Wash is Nyutji's high-end service designed for valuable clothes like work shirts, blazers, dresses, and your favourite outfits. Each item is washed separately with special care.",
            "The washing process uses specially-sized machines to keep colours bright and fabric fibres intact. Each garment is wrapped in a protective plastic bag before being returned.",
            "Ideal for those who value quality and clothing longevity. Prices are charged per item starting from just Rp 5,000."
          ],
          'mitraContoh': ["Kece Laundry  •  Kota Surabaya", "Aneka Laundry  •  Kota Bandung", "Perkasa Laundry  •  Semarang"]
        },
        {
          'title': "Ironing Only", 'desc': "Neat & Ready", 'img': "assets/images/setrika_saja.jpg",
          'details': [
            "Nyutji's Ironing Only service ensures your clothes return crisp and wrinkle-free within hours. Perfect for those who wash their own clothes but don't have time to iron them.",
            "Nyutji Partner staff use professional steam irons that maintain fabric softness and shape. The process also helps eliminate remaining germs on your clothes.",
            "Available for all types of clothing including formal shirts, batik wear, and dresses. Prices start from just Rp 2,000 per piece."
          ],
          'mitraContoh': ["Kilat Laundry  •  Jakarta Selatan", "Cemerlang Laundry  •  Kota Bogor", "Cepat Laundry  •  Bekasi"]
        },
        {
          'title': "Beloved Care", 'desc': "Kids Clothes Wash", 'img': "assets/images/cucian_anak.jpg",
          'details': [
            "Beloved Care is a special service for baby and children's clothing that uses hypoallergenic detergent free from artificial fragrances and harsh chemicals. Safe for sensitive skin.",
            "Each load is washed separately from adult laundry, using clean water and strict hygiene procedures. The result is maximally clean, soft, and free from detergent residues.",
            "Clothes are returned neatly folded in special anti-bacterial bags. This service gives peace of mind to parents who care about their child's health."
          ],
          'mitraContoh': ["Bidadari Laundry  •  Jakarta Timur", "Mungil Laundry  •  Kab. Bantul", "Pelangi Laundry  •  Kota Malang"]
        },
        {
          'title': "Special Wash", 'desc': "Stroller & Helmet", 'img': "assets/images/stroller.jpg",
          'details': [
            "Nyutji's Special Wash handles non-clothing items requiring careful cleaning such as strollers, car seats, backpacks, leather shoes, helmets, and large stuffed toys.",
            "Each item is handled by trained Partners with cleaning methods tailored to the material. We ensure thorough cleaning down to the hidden crevices.",
            "Items are picked up and returned safely with bubble wrap protection. Prices vary by item type and size; price confirmation is provided before processing begins."
          ],
          'mitraContoh': ["Spesial Laundry  •  Jakarta Pusat", "Istimewa Laundry  •  Kota Solo", "Hebat Laundry  •  Sidoarjo"]
        },
        {
          'title': "Courier Pickup", 'desc': "Delivery to Your Door", 'img': "assets/images/kurir_service.jpg",
          'details': [
            "Nyutji's Courier Pickup & Delivery service ensures your laundry is processed without leaving home. Trusted and trained Nyutji couriers are ready to pick up your laundry whenever you need.",
            "The app-based ordering system lets you track the courier's location in real-time, from pickup to return delivery. Automatic status notifications are sent at every stage of the process.",
            "Free pickup and delivery for areas partnered with Nyutji. Simply order through the app and enjoy the convenience of clean laundry without any hassle."
          ],
          'mitraContoh': ["Lancar Laundry  •  Kota Yogyakarta", "Ceria Laundry  •  Kab. Sleman", "Karya Laundry  •  Jakarta Selatan"]
        },
      ],
    }
  };

  void _handleAction() async {
    HapticFeedback.mediumImpact();
    final auth = ref.read(authProvider);
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
    final auth = ref.read(authProvider);
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
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Daftarkan Diri Anda", style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 22, color: const Color(0xFF286B6A))),
              ),
              const SizedBox(height: 24),
              Column(
                children: [
                  _buildRoleItem(
                    context,
                    label: currentT['roles']['PL'] ?? "Pelanggan",
                    description: "Manfaatkan layanan Nyutji Bersama menjadi gaya hidup urban ketika baju kesayangan Anda otomatis bersih dan sampai didepan pintu rumah dalam kondisi harum dan rapi",
                    icon: LucideIcons.user,
                    color: const Color(0xFF286B6A),
                    onTap: () { Navigator.pop(context); Navigator.push(context, RetroRoute(page: const RegisterPelangganScreen())); },
                  ),
                  const SizedBox(height: 16),
                  _buildRoleItem(
                    context,
                    label: currentT['roles']['ML'] ?? "Mitra",
                    description: "Kemitraan bersama Nyutji Bersama akan mendapatkan dukungan secara profesional dan pelayanan terbaik bagi Pelanggan adalah sebagai standart utama",
                    icon: LucideIcons.store,
                    color: const Color(0xFFC3312E),
                    onTap: () { Navigator.pop(context); Navigator.push(context, RetroRoute(page: const RegisterMitraScreen())); },
                  ),
                  const SizedBox(height: 16),
                  _buildRoleItem(
                    context,
                    label: currentT['roles']['KL'] ?? "Kurir",
                    description: "Jadilah bagian Nyutji Bersama untuk mengirimkan pakaian harum serta rapi Pelanggan dari Mitra secara efisien dan menguntungkan",
                    icon: LucideIcons.truck,
                    color: const Color(0xFFD35400),
                    onTap: () { Navigator.pop(context); Navigator.push(context, RetroRoute(page: const RegisterKurirScreen())); },
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
    final auth = ref.watch(authProvider);
    final currentT = t[auth.lang] ?? t['id'];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Adjust based on your light background
      ),
      child: Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFDF7EA), Color(0xFFE8F4F4)],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 60),
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
                      Hero(
                        tag: 'hero_logo_nyutji',
                        child: SizedBox(
                          width: 100, height: 100,
                          child: Image.asset('assets/images/logo_nyutji.png', fit: BoxFit.contain),
                        ),
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
                          gradient: const LinearGradient(colors: [Color(0xFFD35400), Color(0xFFE67E22)]),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [BoxShadow(color: const Color(0xFFD35400).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
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

  void _showProductDetail(BuildContext context, Map<String, dynamic> prod) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => _ProductDetailDialog(
        prod: prod,
        onRegisterTap: _showRegisterOptions,
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> prod) {
    final String imgSrc = prod['img'] ?? '';
    final bool isNetwork = imgSrc.startsWith('http');

    return GestureDetector(
      onTap: () => _showProductDetail(context, prod),
      child: Container(
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
                    ? CachedNetworkImage(imageUrl: imgSrc, height: 140, width: 200, fit: BoxFit.cover, errorWidget: (c,e,s) => Container(height: 140, color: Colors.grey[300], child: const Icon(Icons.image_not_supported)))
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
    ),
    );
  }

  Widget _buildRoleItem(BuildContext context, {required String label, required String description, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
                  const SizedBox(height: 6),
                  Text(description, style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[700], height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Wavy image clipper ──────────────────────────────────────────────────────
class _WaveImageClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const r = 28.0;
    return Path()
      ..moveTo(r, 0)
      ..lineTo(size.width - r, 0)
      ..quadraticBezierTo(size.width, 0, size.width, r)
      ..lineTo(size.width, size.height - 18)
      ..quadraticBezierTo(size.width * 0.75, size.height - 52, size.width * 0.5, size.height - 24)
      ..quadraticBezierTo(size.width * 0.25, size.height + 6, 0, size.height - 34)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..close();
  }

  @override
  bool shouldReclip(_WaveImageClipper old) => false;
}

// ── Sparkle glitter painter ─────────────────────────────────────────────────
class _SparklePainter extends CustomPainter {
  final double t;
  _SparklePainter(this.t);

  static const _pos = [
    Offset(0.14, 0.22), Offset(0.82, 0.16), Offset(0.47, 0.58),
    Offset(0.11, 0.68), Offset(0.76, 0.52), Offset(0.56, 0.11),
    Offset(0.32, 0.82), Offset(0.63, 0.35),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _pos.length; i++) {
      final phase = (t + i / _pos.length) % 1.0;
      final opacity = (math.sin(phase * 2 * math.pi) * 0.5 + 0.5);
      final scale = 0.55 + (math.sin(phase * 2 * math.pi) * 0.5 + 0.5) * 0.45;
      final center = Offset(_pos[i].dx * size.width, _pos[i].dy * size.height);
      // Outer glow
      canvas.drawCircle(center, 5.0 * scale, Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      // Core sparkle
      canvas.drawCircle(center, 2.5 * scale, Paint()
        ..color = Colors.white.withValues(alpha: opacity.clamp(0, 1)));
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.t != t;
}

// ── Product detail dialog (StatefulWidget for sparkle animation) ─────────────
class _ProductDetailDialog extends StatefulWidget {
  final Map<String, dynamic> prod;
  final VoidCallback? onRegisterTap;
  const _ProductDetailDialog({required this.prod, this.onRegisterTap});

  @override
  State<_ProductDetailDialog> createState() => _ProductDetailDialogState();
}

class _ProductDetailDialogState extends State<_ProductDetailDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sparkle;

  static const List<String> _mitraIcons = [
    'assets/icons/icon_ML.png',
    'assets/icons/icon_dryclean.png',
    'assets/icons/icon_dropoff.png',
    'assets/icons/icon_iron.png',
    'assets/icons/icon_pickup.png',
    'assets/icons/icon_sepatu.png',
    'assets/icons/dicuci.png',
    'assets/icons/disetrika.png',
    'assets/icons/dipacking.png',
    'assets/icons/icon_bayi.png',
    'assets/icons/baby_stroller.png',
  ];

  @override
  void initState() {
    super.initState();
    _sparkle = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _sparkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prod = widget.prod;
    final String imgSrc = prod['img'] ?? '';
    final bool isNetwork = imgSrc.startsWith('http');
    final List<String> details = List<String>.from(prod['details'] ?? []);
    final List<String> mitraList = List<String>.from(prod['mitraContoh'] ?? []);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main card
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 40, offset: const Offset(0, 16)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero image — wavy bottom cut + sparkle
                    ClipPath(
                      clipper: _WaveImageClipper(),
                      child: SizedBox(
                        height: 205,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            isNetwork
                                ? CachedNetworkImage(imageUrl: imgSrc, fit: BoxFit.cover,
                                    errorWidget: (c, e, s) => Container(color: const Color(0xFFE8F4F4)))
                                : Image.asset(imgSrc, fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(color: const Color(0xFFE8F4F4))),
                            // Gradient
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.78)],
                                ),
                              ),
                            ),
                            // Sparkle animation layer
                            AnimatedBuilder(
                              animation: _sparkle,
                              builder: (_, __) => CustomPaint(
                                painter: _SparklePainter(_sparkle.value),
                              ),
                            ),
                            // Title
                            Positioned(
                              bottom: 34, left: 20, right: 56,
                              child: Text(
                                prod['title'] ?? '',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900,
                                  shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10)],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Description paragraphs
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < details.length; i++) ...[
                            Text(
                              details[i],
                              style: GoogleFonts.montserrat(fontSize: 12.5, color: const Color(0xFF3A3A3A), height: 1.6),
                            ),
                            if (i < details.length - 1) const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
                    // Mitra Laundry Aktif label
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF286B6A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.store, size: 13, color: Color(0xFF286B6A)),
                            const SizedBox(width: 6),
                            Text('Mitra Laundry Aktif', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF286B6A))),
                          ],
                        ),
                      ),
                    ),
                    // Mitra horizontal scroll
                    SizedBox(
                      height: 68,
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                        itemCount: mitraList.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (ctx, i) {
                          final itemStr = mitraList[i];
                          final parts = itemStr.split(' • ');
                          final namaML = parts[0].trim();
                          final kabKota = parts.length > 1 ? parts[1].trim() : '';
                          final iconPath = _mitraIcons[i % _mitraIcons.length];

                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              widget.onRegisterTap?.call();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF286B6A).withValues(alpha: 0.20)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF286B6A).withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF286B6A).withValues(alpha: 0.08),
                                      border: Border.all(color: const Color(0xFF286B6A).withValues(alpha: 0.15)),
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        iconPath,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => const Icon(LucideIcons.store, size: 16, color: Color(0xFF286B6A)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        namaML,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1E293B),
                                        ),
                                      ),
                                      if (kabKota.isNotEmpty) ...[
                                        const SizedBox(height: 1),
                                        Text(
                                          kabKota,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF286B6A),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
          // Floating X button
          Positioned(
            top: -14, right: -14,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: const Icon(LucideIcons.x, size: 18, color: Color(0xFF286B6A)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
