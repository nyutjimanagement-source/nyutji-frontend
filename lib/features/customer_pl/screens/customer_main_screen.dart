import 'package:flutter/material.dart';
import '../../../core/theme/nyutji_theme.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'customer_home_screen.dart';

import 'customer_wallet_screen.dart';
import 'customer_profile_screen.dart';
import 'customer_status_screen.dart';
import '../../../providers/auth_provider.dart';

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

  static const List<Widget> _widgetOptions = <Widget>[
    CustomerHomeScreen(),
    CustomerStatusScreen(),
    CustomerWalletScreen(),
    CustomerProfileScreen(),
  ];

  void _onItemTapped(int index) {
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
      backgroundColor: NyutjiTheme.background,
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
          color: const Color(0xFFFFF9ED),
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
          selectedItemColor: NyutjiTheme.plPrimary,
          unselectedItemColor: NyutjiTheme.textGrey.withValues(alpha: 0.5),
          showUnselectedLabels: true,
          onTap: _onItemTapped,
          backgroundColor: const Color(0xFFFFF9ED),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: NyutjiTheme.body(NyutjiTheme.plPrimary).copyWith(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: NyutjiTheme.body(NyutjiTheme.textGrey).copyWith(fontSize: 10),
        ),
      ),
    );
  }
}
