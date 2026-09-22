import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kraiiv brand theme — matches the prototype video exactly.
/// 
/// Prototype color system (HSL):
/// - Background: 45 30% 95% (warm off-white)
/// - Foreground: 20 20% 15% (deep brown)
/// - Primary: 25 60% 35% (warm sage/green)
/// - Accent: 85 35% 45% (olive)
/// - Card: 45 25% 92% (warm card)
/// - Muted: 40 20% 85%
/// - Border: 40 15% 80%
/// - Gold: #C4A265
/// 
/// Fonts: Inter (UI) + Playfair Display (headlines)

class AppTheme {
  // HSL to Color helper
  static Color _hsl(double h, double s, double l, [double a = 1.0]) {
    return HSLColor.fromAHSL(a, h, s, l).toColor();
  }

  // Static const colors for const expressions (pre-computed from HSL)
  static const Color primary = Color(0xFF3A5A40);       // hsl(25, 60%, 35%)
  static const Color primaryDark = Color(0xFF2E4A35);   // hsl(25, 60%, 25%)
  static const Color primaryLight = Color(0xFFEBF2EB);  // hsl(25, 30%, 95%)
  static const Color background = Color(0xFFF5F0E8);    // hsl(45, 30%, 95%)
  static const Color foreground = Color(0xFF1A1208);    // hsl(20, 20%, 15%)
  static const Color card = Color(0xFFF0ECE5);          // hsl(45, 25%, 92%)
  static const Color cardForeground = Color(0xFF1A1208);
  static const Color popover = Color(0xFFF0ECE5);
  static const Color popoverForeground = Color(0xFF1A1208);
  static const Color secondary = Color(0xFFA68A5A);     // hsl(35, 25%, 65%)
  static const Color secondaryForeground = Color(0xFF1A1208);
  static const Color muted = Color(0xFFE5DFD5);         // hsl(40, 20%, 85%)
  static const Color mutedForeground = Color(0xFF9A9284); // hsl(25, 15%, 45%)
  static const Color accent = Color(0xFF7A9E3A);        // hsl(85, 35%, 45%)
  static const Color accentForeground = Color(0xFFF5F0E8);
  static const Color primaryForeground = Color(0xFFF5F0E8);
  static const Color destructive = Color(0xFFEF4444);
  static const Color destructiveForeground = Color(0xFFF5F0E8);
  static const Color border = Color(0xFFD9D1C5);        // hsl(40, 15%, 80%)
  static const Color input = Color(0xFFD9D1C5);
  static const Color ring = Color(0xFF3A5A40);

  // Radius
  static const double radius = 8.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusFull = 9999.0;

  // Semantic colors from prototype
  static const Color gold = Color(0xFFC4A265);
  static const Color goldDim = Color(0x80C4A265);
  static const Color danger = Color(0xFFEF4444);
  static const Color orange = Color(0xFFF97316);
  static const Color blue = Color(0xFF3B82F6);
  static const Color sageLight = Color(0xFFEBF2EB);
  static TextStyle _displayLarge({Color? color, FontWeight? weight, double? height}) =>
      GoogleFonts.playfairDisplay(
        color: color ?? foreground,
        fontSize: 32,
        fontWeight: weight ?? FontWeight.w700,
        height: height ?? 1.15,
        letterSpacing: -0.5,
      );

  static TextStyle _displayMedium({Color? color, FontWeight? weight, double? height}) =>
      GoogleFonts.playfairDisplay(
        color: color ?? foreground,
        fontSize: 28,
        fontWeight: weight ?? FontWeight.w700,
        height: height ?? 1.2,
        letterSpacing: -0.3,
      );

  static TextStyle _headlineLarge({Color? color, FontWeight? weight, double? height}) =>
      GoogleFonts.playfairDisplay(
        color: color ?? foreground,
        fontSize: 24,
        fontWeight: weight ?? FontWeight.w700,
        height: height ?? 1.25,
        letterSpacing: -0.2,
      );

  static TextStyle _headlineMedium({Color? color, FontWeight? weight, double? height}) =>
      GoogleFonts.playfairDisplay(
        color: color ?? foreground,
        fontSize: 20,
        fontWeight: weight ?? FontWeight.w700,
        height: height ?? 1.3,
      );

  static TextStyle _titleLarge({Color? color, FontWeight? weight, double? height}) =>
      GoogleFonts.inter(
        color: color ?? foreground,
        fontSize: 18,
        fontWeight: weight ?? FontWeight.w700,
        height: height ?? 1.3,
      );

  static TextStyle _titleMedium({Color? color, FontWeight? weight, double? height}) =>
      GoogleFonts.inter(
        color: color ?? foreground,
        fontSize: 16,
        fontWeight: weight ?? FontWeight.w600,
        height: height ?? 1.35,
      );

  static TextStyle _bodyLarge({Color? color, FontWeight? weight, double? height}) =>
      GoogleFonts.inter(
        color: color ?? _hsl(25, 0.15, 0.35), // textBody equivalent
        fontSize: 16,
        fontWeight: weight ?? FontWeight.w400,
        height: height ?? 1.5,
      );

  static TextStyle _bodyMedium({Color? color, FontWeight? weight, double? height}) =>
      GoogleFonts.inter(
        color: color ?? _hsl(25, 0.15, 0.35),
        fontSize: 14,
        fontWeight: weight ?? FontWeight.w400,
        height: height ?? 1.5,
      );

  static TextStyle _bodySmall({Color? color, FontWeight? weight, double? height}) =>
      GoogleFonts.inter(
        color: color ?? _hsl(25, 0.15, 0.35, 0.6), // textMuted equivalent
        fontSize: 13,
        fontWeight: weight ?? FontWeight.w400,
        height: height ?? 1.4,
      );

  static TextStyle _labelLarge({Color? color, FontWeight? weight}) =>
      GoogleFonts.inter(
        color: color ?? foreground,
        fontSize: 14,
        fontWeight: weight ?? FontWeight.w600,
      );

  // Prototype effects
  static LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary.withValues(alpha: 0.95),
          primary.withValues(alpha: 0.80),
          accent.withValues(alpha: 0.70),
        ],
      );

  static BoxDecoration get textureOverlay => BoxDecoration(
        backgroundBlendMode: BlendMode.overlay,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.transparent,
            primary.withValues(alpha: 0.03),
            Colors.transparent,
          ],
        ),
      );

  static BoxShadow get glowEffect => BoxShadow(
        color: primary.withValues(alpha: 0.2),
        blurRadius: 30,
        spreadRadius: 0,
      );

  static BoxShadow get cardShadow => BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      );

  static BoxShadow get elevatedShadow => BoxShadow(
        color: primary.withValues(alpha: 0.15),
        blurRadius: 20,
        offset: const Offset(0, 8),
      );

  // Main theme
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: primaryForeground,
        secondary: accent,
        onSecondary: accentForeground,
        surface: card,
        onSurface: cardForeground,
        error: destructive,
        onError: destructiveForeground,
        outline: border,
        shadow: Colors.black.withValues(alpha: 0.08),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: foreground, size: 22),
        titleTextStyle: _headlineMedium(color: foreground, weight: FontWeight.w700),
      ),
      // Pill buttons (9999 radius, 52h) like Coinbase/Kraken per prototype
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          textStyle: _labelLarge(weight: FontWeight.w700).copyWith(letterSpacing: -0.2),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return primary.withValues(alpha: 0.8);
            }
            if (states.contains(WidgetState.hovered)) {
              return primary.withValues(alpha: 0.9);
            }
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          backgroundColor: Colors.transparent,
          side: BorderSide(color: border, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          textStyle: _labelLarge(weight: FontWeight.w700),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return primary.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.hovered)) {
              return primary.withValues(alpha: 0.04);
            }
            return null;
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: _labelLarge(weight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return primary.withValues(alpha: 0.1);
            }
            if (states.contains(WidgetState.hovered)) {
              return primary.withValues(alpha: 0.06);
            }
            return null;
          }),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: _displayLarge(),
        displayMedium: _displayMedium(),
        headlineLarge: _headlineLarge(),
        headlineMedium: _headlineMedium(),
        titleLarge: _titleLarge(),
        titleMedium: _titleMedium(),
        bodyLarge: _bodyLarge(),
        bodyMedium: _bodyMedium(),
        bodySmall: _bodySmall(),
        labelLarge: _labelLarge(),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: BorderSide(color: destructive, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: BorderSide(color: destructive, width: 1.5),
        ),
        hintStyle: _bodyMedium(color: mutedForeground),
        labelStyle: _bodyMedium(color: _hsl(25, 0.15, 0.35)),
        floatingLabelStyle: TextStyle(color: primary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        labelStyle: _labelLarge(color: foreground),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: border,
        circularTrackColor: border,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: 0.12),
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return _labelLarge(
            color: selected ? primary : mutedForeground,
            weight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? primary : mutedForeground,
            size: 22,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        modalBackgroundColor: background,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          side: BorderSide(color: border),
        ),
        titleTextStyle: _headlineMedium(color: foreground),
        contentTextStyle: _bodyMedium(color: _hsl(25, 0.15, 0.35)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: foreground,
        contentTextStyle: _bodyMedium(color: primaryForeground),
        actionTextColor: gold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
        elevation: 8,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: primaryForeground,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusFull)),
      ),
    );
    return base;
  }
}

// Extension for easy access to prototype colors
extension AppThemeColors on BuildContext {
  Color get bg => AppTheme.background;
  Color get fg => AppTheme.foreground;
  Color get primary => AppTheme.primary;
  Color get primaryFg => AppTheme.primaryForeground;
  Color get accent => AppTheme.accent;
  Color get card => AppTheme.card;
  Color get border => AppTheme.border;
  Color get muted => AppTheme.muted;
  Color get mutedFg => AppTheme.mutedForeground;
  Color get gold => AppTheme.gold;
  Color get danger => AppTheme.danger;
  Color get orange => AppTheme.orange;
  Color get blue => AppTheme.blue;
}

// Extension for prototype text styles
extension AppThemeText on BuildContext {
  TextStyle get displayLarge => AppTheme._displayLarge();
  TextStyle get displayMedium => AppTheme._displayMedium();
  TextStyle get headlineLarge => AppTheme._headlineLarge();
  TextStyle get headlineMedium => AppTheme._headlineMedium();
  TextStyle get titleLarge => AppTheme._titleLarge();
  TextStyle get titleMedium => AppTheme._titleMedium();
  TextStyle get bodyLarge => AppTheme._bodyLarge();
  TextStyle get bodyMedium => AppTheme._bodyMedium();
  TextStyle get bodySmall => AppTheme._bodySmall();
  TextStyle get labelLarge => AppTheme._labelLarge();
}