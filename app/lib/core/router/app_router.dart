import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/fuel/domain/entities/distributore.dart';
import '../../features/fuel/presentation/screens/home_screen.dart';
import '../../features/fuel/presentation/screens/detail_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
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
