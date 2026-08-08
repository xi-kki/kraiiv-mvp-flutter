import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../theme/app_theme.dart';

/// Persistent bottom navigation shell matching the prototype:
/// Home · Chat · Rewards Hub · Profile.
///
/// Each tab keeps its own navigation stack (indexedStack), so switching tabs
/// preserves scroll position and in-progress state.
class KraiivShell extends StatelessWidget {
  const KraiivShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        indicatorColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
        backgroundColor: AppTheme.background,
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.house, color: AppTheme.textMuted),
            selectedIcon:
                Icon(LucideIcons.house, color: AppTheme.primaryGreenDark),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.messageCircle, color: AppTheme.textMuted),
            selectedIcon: Icon(LucideIcons.messageCircle,
                color: AppTheme.primaryGreenDark),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.coins, color: AppTheme.textMuted),
            selectedIcon:
                Icon(LucideIcons.coins, color: AppTheme.primaryGreenDark),
            label: 'Rewards',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.user, color: AppTheme.textMuted),
            selectedIcon:
                Icon(LucideIcons.user, color: AppTheme.primaryGreenDark),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
