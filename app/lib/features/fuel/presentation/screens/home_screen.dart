import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/distributore.dart';
import '../providers/fuel_provider.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../widgets/filters_bar.dart';
import '../widgets/fuel_card.dart';
import '../widgets/price_badge.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fuelAsync = ref.watch(fuelResultsProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const AppLogo(),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: () => context.push('/settings'),
            tooltip: 'Impostazioni',
          ),
        ],
      ),
      body: Column(
        children: [
          const FiltersBar(),
          Expanded(
            child: fuelAsync.when(
              loading: () => const LoadingView(message: 'Ricerca distributori...'),
              error: (err, _) => _buildError(err, ref),
              data: (results) => _buildList(context, ref, results),
            ),
          ),
          const _BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _buildError(Object err, WidgetRef ref) {
    final exception = err is AppException
        ? err
        : AppException(AppErrorType.erroreServer, dettaglio: err.toString());
    return ErrorView(
      exception: exception,
      onRetry: () {
        ref.invalidate(locationProvider);
        ref.invalidate(fuelResultsProvider);
      },
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<Distributore> results) {
    if (results.isEmpty) {
      return const EmptyView(
        message: 'Nessun distributore trovato\nnel raggio selezionato',
      );
    }

    final tiers = _computeTiers(results);

    return RefreshIndicator(
      onRefresh: () {
        ref.invalidate(fuelResultsProvider);
        return ref.read(fuelResultsProvider.future);
      },
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        itemCount: results.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) => FuelCard(
          distributore: results[i],
          tier: tiers[i],
          onTap: () => context.push('/detail/${results[i].id}', extra: results[i]),
        ),
      ),
    );
  }

  static List<PriceTier> _computeTiers(List<Distributore> results) {
    final prices  = results.map((d) => d.prezzoBest).toList();
    final nonNull = prices.whereType<double>().toList()..sort();

    if (nonNull.isEmpty) return List.filled(results.length, PriceTier.mid);

    final min   = nonNull.first;
    final max   = nonNull.last;
    final range = max - min;

    return prices.map((p) {
      if (p == null) return PriceTier.mid;
      if (range < 0.001) return PriceTier.best;
      final n = (p - min) / range;
      if (n < 0.33) return PriceTier.best;
      if (n < 0.67) return PriceTier.mid;
      return PriceTier.high;
    }).toList();
  }
}

class _BannerAdWidget extends StatefulWidget {
  const _BannerAdWidget();

  @override
  State<_BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final ad = BannerAd(
      adUnitId: AppConstants.admobBannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (a, _) => a.dispose(),
      ),
    )..load();
    _ad = ad;
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
