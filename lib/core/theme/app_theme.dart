import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color warmBrown = Color(0xFF8C6A4A);
  static const Color lightWarmBrown = Color(0xFFA67B5B);
  static const Color supportiveGreen = Color(0xFF5A9A6F);
  static const Color lightSupportiveGreen = Color(0xFF6FBF8A);
  
  // Backgrounds & Surfaces
  static const Color backgroundBeige = Color(0xFFF8F4ED);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  
  // Typography Colors
  static const Color headingBrown = Color(0xFF3F2A1E);
  static const Color textBody = Color(0xFF5A4A42);
  static const Color textPositiveGreen = Color(0xFF2C5F45);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundBeige,
      colorScheme: ColorScheme.fromSeed(
        seedColor: supportiveGreen,
        primary: supportiveGreen,
        secondary: warmBrown,
        background: backgroundBeige,
        surface: surfaceWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundBeige,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: headingBrown),
        titleTextStyle: TextStyle(
          color: headingBrown,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: supportiveGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: warmBrown,
          side: const BorderSide(color: warmBrown, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: headingBrown, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: headingBrown, fontSize: 28, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: headingBrown, fontSize: 24, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: headingBrown, fontSize: 20, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textBody, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: textBody, fontSize: 14, height: 1.5),
      ),
    );
  }
}
