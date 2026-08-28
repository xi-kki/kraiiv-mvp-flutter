import 'package:flutter/material.dart';

// ignore_for_file: prefer_const_constructors

/// Kraiiv brand theme — matches the video prototype (light, clean, green CTAs).
/// Crypto-aligned: pill buttons (9999 radius, 52h, shadow) like Coinbase/Kraken,
/// 20-radius cards, sage #3A5A40.
class AppTheme {
  static const Color primaryGreen = Color(0xFF3A5A40);
  static const Color primaryGreenDark = Color(0xFF2E4A35);
  static const Color sageLight = Color(0xFFEBF2EB);
  static const Color gold = Color(0xFFC4A265);
  static const Color goldDim = Color(0x80C4A265);
  // Surfaces
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F7F4);
  static const Color border = Color(0xFFEFEDE8);

  // Text
  static const Color textDark = Color(0xFF1A1208);
  static const Color textBody = Color(0xFF5C564C);
  static const Color textMuted = Color(0xFF9A9284);

  // Semantic
  static const Color danger = Color(0xFFEF4444);
  static const Color orange = Color(0xFFF97316);
  static const Color blue = Color(0xFF3B82F6);

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        onPrimary: Colors.white,
        secondary: gold,
        onSecondary: textDark,
        surface: background,
        onSurface: textDark,
        error: danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: const Color(0x443A5A40),
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
          textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textDark,
          backgroundColor: Colors.white,
          side: BorderSide(color: border, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
          textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textDark, fontSize: 32, fontWeight: FontWeight.w800, height: 1.15),
        displayMedium: TextStyle(color: textDark, fontSize: 28, fontWeight: FontWeight.w800, height: 1.2),
        headlineLarge: TextStyle(color: textDark, fontSize: 24, fontWeight: FontWeight.w700, height: 1.25),
        headlineMedium: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w700, height: 1.3),
        titleLarge: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.w700, height: 1.3),
        titleMedium: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w600, height: 1.35),
        bodyLarge: TextStyle(color: textBody, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: textBody, fontSize: 14, height: 1.5),
        bodySmall: TextStyle(color: textMuted, fontSize: 13, height: 1.4),
        labelLarge: TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shadowColor: const Color(0x0A000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryGreen, width: 1.5),
        ),
        hintStyle: TextStyle(color: textMuted),
        labelStyle: TextStyle(color: textBody),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: TextStyle(color: textDark, fontWeight: FontWeight.w600),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreen,
        linearTrackColor: border,
      ),
    );
    return base;
  }
}
