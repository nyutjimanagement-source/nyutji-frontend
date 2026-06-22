import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/nyutji_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'customer_home_screen.dart';

import 'customer_wallet_screen.dart';
import 'customer_profile_screen.dart';
import 'customer_status_screen.dart';
import '../../../providers/auth_provider.dart';

class CustomerMainScreen extends ConsumerStatefulWidget {
  const CustomerMainScreen({super.key});

  @override ConsumerState<CustomerMainScreen> createState() => CustomerMainScreenState();
}

class CustomerMainScreenState extends ConsumerState<CustomerMainScreen> {
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

  void switchToTab(int index) {
    _onItemTapped(index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    
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

    final user = auth.user;
    final hasAddress = user?['address'] != null && 
                       user!['address'].toString().isNotEmpty && 
                       user['address'].toString() != 'Pilih Lokasi Rumah' &&
                       user['district_name'] != null &&
                       user['district_name'].toString().isNotEmpty &&
                       ((double.tryParse(user['lat']?.toString() ?? '0.0') ?? 0.0) != 0.0) &&
                       ((double.tryParse(user['lng']?.toString() ?? '0.0') ?? 0.0) != 0.0);

    final hasName = user?['name'] != null && user!['name'].toString().isNotEmpty && user['name'].toString() != '-';
    final hasPhone = (user?['phone'] != null && user!['phone'].toString().isNotEmpty && user['phone'].toString() != '-') ||
                      (user?['phone_number'] != null && user!['phone_number'].toString().isNotEmpty && user['phone_number'].toString() != '-');
    final hasEmail = user?['email'] != null && user!['email'].toString().isNotEmpty && user['email'].toString() != '-';
    final hasSettings = hasName && hasPhone && hasEmail;

    final showProfileRedDot = !hasAddress || !hasSettings;

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / 4;
            return Stack(
              children: [
                BottomNavigationBar(
                  items: <BottomNavigationBarItem>[
                    BottomNavigationBarItem(icon: const Icon(LucideIcons.home, size: 22), activeIcon: const Icon(LucideIcons.home, size: 22), label: currentT['home']),
                    BottomNavigationBarItem(icon: const Icon(LucideIcons.package, size: 22), activeIcon: const Icon(LucideIcons.package, size: 22), label: currentT['status']),
                    BottomNavigationBarItem(icon: const Icon(LucideIcons.wallet, size: 22), activeIcon: const Icon(LucideIcons.wallet, size: 22), label: currentT['wallet']),
                    BottomNavigationBarItem(
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(LucideIcons.user, size: 22),
                          if (showProfileRedDot)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      activeIcon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(LucideIcons.user, size: 22),
                          if (showProfileRedDot)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
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
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: 0,
                  left: (tabWidth * _selectedIndex) + (tabWidth / 2) - 30,
                  child: Container(
                    height: 3,
                    width: 60,
                    decoration: BoxDecoration(
                      color: NyutjiTheme.plPrimary,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(3),
                        bottomRight: Radius.circular(3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: NyutjiTheme.plPrimary.withValues(alpha: 0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        )
                      ]
                    ),
                  ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }
}
