import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CustomerThemeMode {
  gold,   // 🌟 Executive Luxury Gold (Default Warm Gold & Cream)
  ocean,  // 💎 Royal Sapphire / Vibrant Ocean
  teal,   // 🌿 Deep Emerald Teal
  dark,   // 🌙 Modern Dark Glassmorphism
}

class CustomerThemeData {
  final CustomerThemeMode mode;
  final String name;
  final String subtitle;
  final String emoji;
  final Color primary;
  final Color accent;
  final Color bg;
  final Color cardBg;
  final Color text;
  final Color subtext;
  final Color border;
  final bool isDark;

  const CustomerThemeData({
    required this.mode,
    required this.name,
    required this.subtitle,
    required this.emoji,
    required this.primary,
    required this.accent,
    required this.bg,
    required this.cardBg,
    required this.text,
    required this.subtext,
    required this.border,
    this.isDark = false,
  });
}

class CustomerThemes {
  static const CustomerThemeData gold = CustomerThemeData(
    mode: CustomerThemeMode.gold,
    name: 'Executive Luxury Gold',
    subtitle: 'Kesan mewah, hangat, dan ramah',
    emoji: '🌟',
    primary: Color(0xFF403600),
    accent: Color(0xFF403600),
    bg: Color(0xFFFFF9ED),
    cardBg: Colors.white,
    text: Color(0xFF1E1A00),
    subtext: Color(0xFF665800),
    border: Color(0xFFE3DCCF),
    isDark: false,
  );

  static const CustomerThemeData ocean = CustomerThemeData(
    mode: CustomerThemeMode.ocean,
    name: 'Royal Sapphire / Vibrant Ocean',
    subtitle: 'Kesan bersih, segar, dan modern',
    emoji: '💎',
    primary: Color(0xFF0284C7),
    accent: Color(0xFF38BDF8),
    bg: Color(0xFFF0F9FF),
    cardBg: Colors.white,
    text: Color(0xFF0F172A),
    subtext: Color(0xFF0369A1),
    border: Color(0xFFBAE6FD),
    isDark: false,
  );

  static const CustomerThemeData teal = CustomerThemeData(
    mode: CustomerThemeMode.teal,
    name: 'Deep Emerald Teal',
    subtitle: 'Konsisten dengan warna brand Nyutji',
    emoji: '🌿',
    primary: Color(0xFF286B6A),
    accent: Color(0xFF1E5655),
    bg: Color(0xFFF0FDF4),
    cardBg: Colors.white,
    text: Color(0xFF064E3B),
    subtext: Color(0xFF047857),
    border: Color(0xFFA7F3D0),
    isDark: false,
  );

  static const CustomerThemeData dark = CustomerThemeData(
    mode: CustomerThemeMode.dark,
    name: 'Modern Dark Glassmorphism',
    subtitle: 'Mode gelap eksklusif efek kaca',
    emoji: '🌙',
    primary: Color(0xFF38BDF8),
    accent: Color(0xFF818CF8),
    bg: Color(0xFF0F172A),
    cardBg: Color(0xFF1E293B),
    text: Colors.white,
    subtext: Color(0xFF94A3B8),
    border: Color(0xFF334155),
    isDark: true,
  );

  static const List<CustomerThemeData> allThemes = [
    gold,
    ocean,
    teal,
    dark,
  ];

  static CustomerThemeData getTheme(CustomerThemeMode mode) {
    switch (mode) {
      case CustomerThemeMode.gold: return gold;
      case CustomerThemeMode.ocean: return ocean;
      case CustomerThemeMode.teal: return teal;
      case CustomerThemeMode.dark: return dark;
    }
  }
}

class CustomerThemeNotifier extends StateNotifier<CustomerThemeData> {
  static const _key = 'customer_theme_mode';

  CustomerThemeNotifier() : super(CustomerThemes.gold) {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString(_key);
      if (savedStr != null) {
        final mode = CustomerThemeMode.values.firstWhere(
          (e) => e.name == savedStr,
          orElse: () => CustomerThemeMode.gold,
        );
        state = CustomerThemes.getTheme(mode);
      }
    } catch (_) {}
  }

  Future<void> setTheme(CustomerThemeMode mode) async {
    state = CustomerThemes.getTheme(mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {}
  }
}

final customerThemeProvider =
    StateNotifierProvider<CustomerThemeNotifier, CustomerThemeData>((ref) {
  return CustomerThemeNotifier();
});
