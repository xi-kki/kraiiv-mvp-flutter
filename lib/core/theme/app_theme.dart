import 'package:flutter/material.dart';

/// Kraiiv brand theme — matches the video prototype (light, clean, green CTAs).
class AppTheme {
  static const Color primaryGreen = Color(0xFF3A5A40);
  static const Color primaryGreenDark = Color(0xFF2E4A35);
  static const Color sageLight = Color(0xFFEBF2EB);
  static const Color gold = Color(0xFFC4A265);
  static const Color goldDim = Color(0x80C4A265); // ~50% opacity
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
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textDark,
          side: const BorderSide(color: border, width: 1.5),
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textDark, fontSize: 32, fontWeight: FontWeight.w800, height: 1.15),
        displayMedium: TextStyle(
          color: textDark, fontSize: 28, fontWeight: FontWeight.w800, height: 1.2),
        headlineLarge: TextStyle(
          color: textDark, fontSize: 24, fontWeight: FontWeight.w700, height: 1.25),
        headlineMedium: TextStyle(
          color: textDark, fontSize: 20, fontWeight: FontWeight.w700, height: 1.3),
        titleLarge: TextStyle(
          color: textDark, fontSize: 18, fontWeight: FontWeight.w700, height: 1.3),
        titleMedium: TextStyle(
          color: textDark, fontSize: 16, fontWeight: FontWeight.w600, height: 1.35),
        bodyLarge: TextStyle(
          color: textBody, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(
          color: textBody, fontSize: 14, height: 1.5),
        bodySmall: TextStyle(
          color: textMuted, fontSize: 13, height: 1.4),
        labelLarge: TextStyle(
          color: textDark, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted),
        labelStyle: const TextStyle(color: textBody),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(color: textDark, fontWeight: FontWeight.w600),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreen,
        linearTrackColor: border,
      ),
    );

    return base;
  }
}
