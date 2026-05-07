import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/fuel/presentation/providers/fuel_provider.dart';

class PienoAmicoApp extends ConsumerStatefulWidget {
  const PienoAmicoApp({super.key});

  @override
  ConsumerState<PienoAmicoApp> createState() => _PienoAmicoAppState();
}

class _PienoAmicoAppState extends ConsumerState<PienoAmicoApp>
    with WidgetsBindingObserver {
  static const _staleAfter = Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final results = ref.read(fuelResultsProvider).valueOrNull;
    if (results == null) return;
    if (DateTime.now().difference(results.fetchedAt) >= _staleAfter) {
      ref.invalidate(fuelResultsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'PienoAmico',
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
