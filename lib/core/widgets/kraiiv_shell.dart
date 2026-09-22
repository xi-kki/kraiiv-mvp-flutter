import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../theme/app_theme.dart';

/// Persistent bottom navigation shell matching the video prototype:
/// 5 Tabs: House · Scan · Rewards · Chat · Profile.
///
/// Selected tab displays a filled circular green background with white icon,
/// matching the prototype video exactly.
class KraiivShell extends StatelessWidget {
  const KraiivShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _PrototypeBottomNav(navigationShell: navigationShell),
    );
  }
}

class _PrototypeBottomNav extends StatelessWidget {
  const _PrototypeBottomNav({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    final items = [
      (LucideIcons.home, 'House'),
      (LucideIcons.camera, 'Scan'),
      (LucideIcons.gift, 'Rewards'),
      (LucideIcons.messageSquare, 'Chat'),
      (LucideIcons.user, 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.border.withValues(alpha: 0.5), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final selected = currentIndex == index;
              final (icon, label) = items[index];

              return InkWell(
                onTap: () => navigationShell.goBranch(
                  index,
                  initialLocation: index == currentIndex,
                ),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.primary : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: 20,
                          color: selected ? Colors.white : AppTheme.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected ? AppTheme.primary : AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}