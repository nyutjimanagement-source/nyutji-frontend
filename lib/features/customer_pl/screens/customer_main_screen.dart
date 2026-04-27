import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'customer_home_screen.dart';

import 'customer_wallet_screen.dart';
import 'customer_profile_screen.dart';
import 'customer_status_screen.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Retro Color Palette
  final Color bgColor = const Color(0xFFF8F4E6);
  final Color primaryTeal = const Color(0xFF286B6A);
  final Color primaryRed = const Color(0xFFC3312E);
  final Color textDark = const Color(0xFF2D2A26);
  final Color textGrey = const Color(0xFF78716C);

  static const List<Widget> _widgetOptions = <Widget>[
    CustomerHomeScreen(),
    CustomerStatusScreen(),
    CustomerWalletScreen(),
    CustomerProfileScreen(),
  ];

  void _onItemTapped(int index) {
    // Saat tap Tab Status, langsung mulai simulasi tracking jika ada pesanan aktif
    if (index == 1) {
      final orderProv = context.read<OrderProvider>();
      if (orderProv.activeOrders.isNotEmpty && orderProv.trackingOrder == null) {
        final orderId = orderProv.activeOrders.first['id']?.toString() ?? 'NYJ-001';
        orderProv.startTrackingSimulation(orderId);
      }
    }
    _pageController.animateToPage(
      index, 
      duration: const Duration(milliseconds: 500), 
      curve: Curves.fastOutSlowIn
    );
  }



  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    final Map<String, dynamic> t = {
      'id': {
        'role': 'PELANGGAN',
        'home': 'Beranda',
        'status': 'Status',
        'wallet': 'Dompet',
        'profile': 'Profil',
      },
      'en': {
        'role': 'CUSTOMER',
        'home': 'Home',
        'status': 'Status',
        'wallet': 'Wallet',
        'profile': 'Profile',
      },
    };

    final currentT = t[auth.lang] ?? t['id'];

    return Scaffold(
      backgroundColor: bgColor,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        physics: const BouncingScrollPhysics(),
        children: _widgetOptions,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(LucideIcons.home, size: 22),
              activeIcon: const Icon(LucideIcons.home, size: 22),
              label: currentT['home'],
            ),
            BottomNavigationBarItem(
              icon: const Icon(LucideIcons.package, size: 22),
              activeIcon: const Icon(LucideIcons.package, size: 22),
              label: currentT['status'],
            ),
            BottomNavigationBarItem(
              icon: const Icon(LucideIcons.wallet, size: 22),
              activeIcon: const Icon(LucideIcons.wallet, size: 22),
              label: currentT['wallet'],
            ),
            BottomNavigationBarItem(
              icon: const Icon(LucideIcons.user, size: 22),
              activeIcon: const Icon(LucideIcons.user, size: 22),
              label: currentT['profile'],
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: primaryTeal,
          unselectedItemColor: textGrey.withValues(alpha: 0.5),
          showUnselectedLabels: true,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 10),
        ),
      ),
    );
  }
}
