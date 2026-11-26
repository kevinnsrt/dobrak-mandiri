import 'package:flutter/material.dart';

/// Tema visual konsisten & aksesibel (WCAG AA) untuk PT. Dobrak Mandiri POS & Inventaris.
class AppTheme {
  AppTheme._();

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color lightGreenBg = Color(0xFFE8F5E9);
  static const Color lightGreenAccent = Color(0xFFC8E6C9);
  static const Color surfaceBg = Color(0xFFF5F6F8);
  static const Color infoBlue = Color(0xFF1565C0);

  /// Oranye tua dengan rasio kontras >= 5.4:1 terhadap latar terang dan putih.
  static const Color warningOrange = Color(0xFFBF360C);
  static const Color warningBg = Color(0xFFFFF3E0);

  /// Merah tua dengan rasio kontras >= 5.6:1 terhadap latar terang.
  static const Color dangerRed = Color(0xFFC62828);
  static const Color dangerBg = Color(0xFFFFEBEE);

  /// Teks sekunder abu-abu gelap dengan rasio kontras >= 5.3:1 terhadap permukaan terang.
  static const Color mutedText = Color(0xFF616161);

  /// Teks sekunder terang di atas AppBar / kartu berwarna primaryGreen (>= 4.5:1).
  static const Color onPrimaryMuted = Color(0xFFE8F5E9);

  static const Color purpleAccent = Color(0xFF7B1FA2);
  static const Color tealAccent = Color(0xFF00796B);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryGreen,
      primary: primaryGreen,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceBg,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
      ),
    );
  }
}
