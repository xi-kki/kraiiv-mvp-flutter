import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../theme/app_theme.dart';

/// Kraiiv wordmark + "Be intentional with every bite" tagline, centered.
/// Matches the prototype's header on onboarding screens.
/// Uses Playfair Display for the wordmark (headline font per prototype).
class BrandHeader extends StatelessWidget {
  final double scale;
  final bool showTagline;

  const BrandHeader({
    super.key,
    this.scale = 1.0,
    this.showTagline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.leaf,
              color: AppTheme.primary,
              size: 22 * scale,
            ),
            const SizedBox(width: 8),
            Text(
              'Kraiiv',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28 * scale,
                fontWeight: FontWeight.w700,
                color: AppTheme.foreground,
                letterSpacing: -0.5,
                height: 1.15,
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 6),
          Text(
            'Be intentional with every bite',
            style: GoogleFonts.inter(
              fontSize: 13 * scale,
              color: AppTheme.mutedForeground,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact brand header for app bars
class CompactBrandHeader extends StatelessWidget {
  const CompactBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(LucideIcons.leaf, color: AppTheme.primary, size: 22),
        const SizedBox(width: 6),
        Text(
          'Kraiiv',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.foreground,
            letterSpacing: -0.3,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}