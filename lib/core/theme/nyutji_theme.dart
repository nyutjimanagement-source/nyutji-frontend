import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MASTER DESIGN SYSTEM NYUTJI
/// Optimized for: Low-End to High-End Devices
/// Focus: Consistency, Memory Efficiency, Premium Aesthetics
class NyutjiTheme {
  // === CORE PALETTE (VINTAGE PREMIUM) ===
  static const Color background = Color(0xFFF7EBE1);
  static const Color cardWhite = Colors.white;
  static const Color darkText = Color(0xFF111827);
  static const Color textGrey = Color(0xFF6B7280);

  // --- PL (Pelanggan Laundry) ---
  static const Color plPrimary = Color(0xFF3A6361);
  static const Color plAccent = Color(0xFFE2A955);
  static const Color plLight = Color(0xFFE8F1F1);

  // --- ML (Mitra Laundry) ---
  static const Color mlPrimary = Color(0xFF527E78);
  static const Color mlAccent = Color(0xFFE9A15A);
  static const Color mlLight = Color(0xFFF1F5F4);

  // --- KL (Kurir Laundry) ---
  static const Color klPrimary = Color(0xFFD66A5A);
  static const Color klAccent = Color(0xFFF5B041);
  static const Color klLight = Color(0xFFFBEEE6);

  // --- AD (Admin Laundry) ---
  static const Color adPrimary = Color(0xFF4A3428);
  static const Color adAccent = Color(0xFFD97A4A);
  static const Color adLight = Color(0xFFEFEBE9);

  // === SHAPES & ELEVATION (MEMORY EFFICIENT) ===
  static const BorderRadius radiusMedium = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusLarge = BorderRadius.all(Radius.circular(24));
  
  static final List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // === TYPOGRAPHY (MONTSERRAT SLIM) ===
  // Menggunakan static method agar tidak menyimpan instance di memori jika tidak dipanggil
  static TextStyle h1(Color color) => GoogleFonts.montserrat(
    fontSize: 22, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5);
    
  static TextStyle h2(Color color) => GoogleFonts.montserrat(
    fontSize: 18, fontWeight: FontWeight.w800, color: color);
    
  static TextStyle h3(Color color) => GoogleFonts.montserrat(
    fontSize: 14, fontWeight: FontWeight.w800, color: color);
    
  static TextStyle body(Color color) => GoogleFonts.montserrat(
    fontSize: 12, fontWeight: FontWeight.w600, color: color);
    
  static TextStyle detail(Color color) => GoogleFonts.montserrat(
    fontSize: 10, fontWeight: FontWeight.w500, color: color);

  static TextStyle actionLabel(Color color) => GoogleFonts.montserrat(
    fontSize: 11, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.8);

  // === COMMON COMPONENTS HELPERS ===
  static BoxDecoration cardDecoration() => BoxDecoration(
    color: cardWhite,
    borderRadius: radiusMedium,
    boxShadow: softShadow,
  );

  // === MATERIAL 3 CONSTANTS (For UI Replacement) ===
  static const Color m3Primary = Color(0xFF403600);
  static const Color m3Error = Color(0xFF740006);
  static const Color m3Surface = Color(0xFFFFF9ED);

  // === MATERIAL 3 REFERENCE SCHEMES (From UI Design) ===
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF403600),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF7C6D1E),
    onPrimaryContainer: Color(0xFFFFFFFF),
    secondary: Color(0xFF3C361B),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF756D4E),
    onSecondaryContainer: Color(0xFFFFFFFF),
    tertiary: Color(0xFF1A3D28),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF51755D),
    onTertiaryContainer: Color(0xFFFFFFFF),
    error: Color(0xFF740006),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFCF2C27),
    onErrorContainer: Color(0xFFFFFFFF),
    surface: Color(0xFFFFF9ED),
    onSurface: Color(0xFF131109),
    onSurfaceVariant: Color(0xFF3A3629),
    outline: Color(0xFF575244),
    outlineVariant: Color(0xFF726D5E),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF333027),
    onInverseSurface: Color(0xFFF7F0E2),
    inversePrimary: Color(0xFFDAC66F),
    surfaceContainerHighest: Color(0xFFD7D1C4),
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFDAC66F), // Fixed from visual yellow
    onPrimary: Color(0xFF3B2F00),
    primaryContainer: Color(0xFF554500),
    onPrimaryContainer: Color(0xFFFCE186),
    secondary: Color(0xFFD3C6A1), // Fixed from visual beige
    onSecondary: Color(0xFF383016),
    secondaryContainer: Color(0xFF4F462A),
    onSecondaryContainer: Color(0xFFF0E2BB),
    tertiary: Color(0xFFABD0B0), // Fixed from visual light green
    onTertiary: Color(0xFF173721),
    tertiaryContainer: Color(0xFF2E4E36),
    onTertiaryContainer: Color(0xFFC6ECCB),
    error: Color(0xFFFFB4AB), // Fixed from visual pink
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF16130B),
    onSurface: Color(0xFFE9E2D4),
    onSurfaceVariant: Color(0xFFCEC6B4),
    outline: Color(0xFF979080),
    outlineVariant: Color(0xFF4B4639),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE9E2D4),
    onInverseSurface: Color(0xFF333027),
    inversePrimary: Color(0xFF705D0D),
    surfaceContainerHighest: Color(0xFF38342B),
  );
}
