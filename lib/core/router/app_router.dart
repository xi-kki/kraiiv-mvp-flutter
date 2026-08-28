import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/kraiiv_shell.dart';
import '../../data/repository/food_repository.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/logging/screens/scanner_screen.dart';
import '../../features/logging/screens/scan_result_screen.dart';
import '../../features/rewards/screens/rewards_screen.dart';
import '../../features/chat/screens/klia_chat_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../core/services/data_service.dart';
import '../../features/progress/screens/progress_detail_screen.dart';
import '../../features/recipes/screens/recipe_detail_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final onboardingComplete = DataService.isOnboardingComplete;
      final loggedIn = DataService.isLoggedIn;
      final isAuthRoute = loc == '/login' || loc == '/onboarding' || loc == '/splash';
      if (!onboardingComplete && loc != '/onboarding' && loc != '/splash') return '/onboarding';
      if (onboardingComplete && !loggedIn && !isAuthRoute) return '/login';
      if (onboardingComplete && loggedIn && (loc == '/login' || loc == '/onboarding')) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            KraiivShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const KliaChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rewards',
                builder: (context, state) => const RewardsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) {
          final payload = state.extra as ScanResultPayload?;
          if (payload == null) {
            // Fallback: a default meal result.
            return ScanResultScreen(
              food: FoodRepository().matchFood(''),
            );
          }
          return ScanResultScreen(
            food: payload.food,
            imagePath: payload.imagePath,
            aiLabel: payload.aiLabel,
            aiConfidence: payload.aiConfidence,
          );
        },
      ),
      GoRoute(
        path: '/progress',
        builder: (context, state) => const ProgressDetailScreen(),
      ),
      GoRoute(
        path: '/recipe/:index',
        builder: (context, state) {
          final index =
              int.tryParse(state.pathParameters['index'] ?? '0') ?? 0;
          return RecipeDetailScreen(index: index);
        },
      ),
    ],
  );
});
