import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/screens/splash_screen.dart';
import '../../features/onboarding/screens/hook_screen.dart';
import '../../features/onboarding/screens/goal_screen.dart';
import '../../features/onboarding/screens/commitment_screen.dart';
import '../../features/layout/screens/main_layout.dart';
import '../../features/logging/screens/meal_logging_screen.dart';
import '../../features/logging/screens/feedback_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/celebration/screens/celebration_screen.dart';
import '../../features/rewards/screens/rewards_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/hook',
        builder: (context, state) => const HookScreen(),
      ),
      GoRoute(
        path: '/goal',
        builder: (context, state) => const GoalScreen(),
      ),
      GoRoute(
        path: '/commitment',
        builder: (context, state) => const CommitmentScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainLayout(),
      ),
      GoRoute(
        path: '/logging',
        builder: (context, state) => const MealLoggingScreen(),
      ),
      GoRoute(
        path: '/feedback',
        builder: (context, state) {
          final mealName = state.extra as String? ?? '';
          return InstantFeedbackScreen(mealName: mealName);
        },
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/celebration',
        builder: (context, state) => const CelebrationScreen(),
      ),
      GoRoute(
        path: '/rewards',
        builder: (context, state) => const RewardsScreen(),
      ),
    ],
  );
});
