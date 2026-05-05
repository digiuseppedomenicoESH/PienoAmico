import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/fuel/domain/entities/distributore.dart';
import '../../features/fuel/presentation/screens/home_screen.dart';
import '../../features/fuel/presentation/screens/detail_screen.dart';
import '../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final done = ref.read(onboardingCompletedProvider);
      final onOnboarding = state.matchedLocation == '/onboarding';

      // Onboarding non completato → vai a /onboarding
      if (!done && !onOnboarding) return '/onboarding';
      // Onboarding completato ma ancora su /onboarding → vai a /
      if (done && onOnboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/detail/:id',
        builder: (context, state) {
          final id           = int.parse(state.pathParameters['id']!);
          final distributore = state.extra as Distributore?;
          return DetailScreen(distributoreId: id, distributore: distributore);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

// Notifica GoRouter quando lo stato dell'onboarding cambia,
// così il redirect viene rivalutato automaticamente.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(onboardingCompletedProvider, (_, __) => notifyListeners());
  }
}
