import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../theme/app_theme.dart';

/// Kraiiv wordmark + "Be intentional with every bite" tagline, centered.
/// Mirrors the prototype's header on onboarding screens.
class BrandHeader extends StatelessWidget {
  final double scale;

  const BrandHeader({super.key, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.leaf, color: AppTheme.primaryGreen, size: 22),
            const SizedBox(width: 8),
            Text(
              'Kraiiv',
              style: TextStyle(
                fontSize: 26 * scale,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Be intentional with every bite',
          style: TextStyle(
            fontSize: 12.5 * scale,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
