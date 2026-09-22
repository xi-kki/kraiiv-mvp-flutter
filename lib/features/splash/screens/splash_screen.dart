import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import 'package:kraiiv/core/services/data_service.dart';
import 'package:kraiiv/core/widgets/brand_header.dart';
import 'package:kraiiv/core/theme/app_theme.dart';

/// Splash screen matching the prototype:
/// Fade + scale animation, brand header with Playfair Display
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleUp;
  late Animation<double> _leafRotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleUp = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _leafRotation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();

    // Navigate after animation
    Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      final String destination;
      if (!DataService.isOnboardingComplete) {
        destination = '/onboarding';
      } else if (!DataService.isLoggedIn) {
        destination = '/login';
      } else {
        destination = '/home';
      }
      context.go(destination);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _scaleUp,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _leafRotation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _leafRotation.value,
                      child: Icon(
                        LucideIcons.leaf,
                        color: AppTheme.primary,
                        size: 48,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Kraiiv',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.foreground,
                    letterSpacing: -0.8,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be intentional with every bite',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.mutedForeground,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    backgroundColor: AppTheme.border,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}