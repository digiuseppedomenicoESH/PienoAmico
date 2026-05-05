import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/distributore.dart';
import '../../domain/entities/filtri.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../providers/filters_provider.dart';
import '../providers/fuel_provider.dart';
import '../providers/view_mode_provider.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../widgets/filters_bottom_sheet.dart';
import '../widgets/fuel_card.dart';
import '../widgets/fuel_map.dart';
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
    final viewMode = ref.watch(viewModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        titleSpacing: 16,
        title: const AppLogo(),
        actions: [
          _ViewToggle(current: viewMode),
          const SizedBox(width: 4),
          const _FilterBtn(),
          const SizedBox(width: 4),
          const _FavoritesToggleBtn(),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: fuelAsync.when(
              loading: () =>
                  const LoadingView(message: 'Ricerca distributori...'),
              error: (err, _) => _buildError(err, ref),
              data: (results) => viewMode == ViewMode.list
                  ? _buildList(context, ref, results)
                  : _buildMap(ref, results),
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

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<Distributore> results,
  ) {
    final favIds = ref.watch(favoritesProvider);
    final showFavorites = ref.watch(showFavoritesProvider);

    if (showFavorites) {
      return _buildFavoritesView(context, ref, results, favIds);
    }

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
      backgroundColor: AppColors.backgroundCard,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _ListHeader(count: results.length)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            sliver: SliverList.separated(
              itemCount: results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => FuelCard(
                distributore: results[i],
                tier: tiers[i],
                index: i,
                onTap: () => context.push(
                  '/detail/${results[i].id}',
                  extra: results[i],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesView(
    BuildContext context,
    WidgetRef ref,
    List<Distributore> results,
    Set<int> favIds,
  ) {
    if (favIds.isEmpty) {
      return const EmptyView(
        message: 'Nessun preferito salvato\nTocca ♡ su un distributore per aggiungerlo',
      );
    }

    final tiers = _computeTiers(results);
    final favEntries = results.asMap().entries
        .where((e) => favIds.contains(e.value.id))
        .toList();

    if (favEntries.isEmpty) {
      return const EmptyView(
        message: 'Nessun preferito\nnel raggio selezionato',
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        ref.invalidate(fuelResultsProvider);
        return ref.read(fuelResultsProvider.future);
      },
      color: AppColors.primary,
      backgroundColor: AppColors.backgroundCard,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.favorite_rounded,
                      size: 12, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Text('PREFERITI (${favEntries.length})',
                      style: AppTextStyles.sectionLabel),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList.separated(
              itemCount: favEntries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final idx = favEntries[i].key;
                final d = favEntries[i].value;
                return FuelCard(
                  distributore: d,
                  tier: tiers[idx],
                  index: idx,
                  onTap: () => context.push('/detail/${d.id}', extra: d),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(WidgetRef ref, List<Distributore> results) {
    final locationAsync = ref.watch(locationProvider);

    return locationAsync.when(
      loading: () => const LoadingView(message: 'Localizzazione in corso...'),
      error: (err, _) {
        final exception = err is AppException
            ? err
            : AppException(AppErrorType.erroreServer, dettaglio: err.toString());
        return ErrorView(exception: exception);
      },
      data: (position) {
        if (results.isEmpty) {
          return const EmptyView(
            message: 'Nessun distributore trovato\nnel raggio selezionato',
          );
        }
        final tiers = _computeTiers(results);
        return FuelMap(
          distributori: results,
          tiers: tiers,
          userLat: position.latitude,
          userLon: position.longitude,
        );
      },
    );
  }

  static List<PriceTier> _computeTiers(List<Distributore> results) {
    final prices = results.map((d) => d.prezzoBest).toList();
    final nonNull = prices.whereType<double>().toList()..sort();

    if (nonNull.isEmpty) return List.filled(results.length, PriceTier.mid);

    final min = nonNull.first;
    final max = nonNull.last;
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

// ── Toggle vista lista/mappa ─────────────────────────────────────────────────

class _ViewToggle extends ConsumerWidget {
  final ViewMode current;
  const _ViewToggle({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(
            icon: Icons.format_list_bulleted_rounded,
            active: current == ViewMode.list,
            onTap: () => ref.read(viewModeProvider.notifier).state = ViewMode.list,
            isLeft: true,
          ),
          Container(width: 1, color: AppColors.border),
          _ToggleBtn(
            icon: Icons.map_outlined,
            active: current == ViewMode.map,
            onTap: () => ref.read(viewModeProvider.notifier).state = ViewMode.map,
            isLeft: false,
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final bool isLeft;

  const _ToggleBtn({
    required this.icon,
    required this.active,
    required this.onTap,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 34,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(9) : Radius.zero,
            right: isLeft ? Radius.zero : const Radius.circular(9),
          ),
        ),
        child: Icon(
          icon,
          size: 17,
          color: active ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ── Header conteggio lista ───────────────────────────────────────────────────

class _ListHeader extends StatelessWidget {
  final int count;
  const _ListHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 4),
      child: Row(
        children: [
          const Icon(Icons.place_rounded, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            '$count distributori trovati',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottone filtri ───────────────────────────────────────────────────────────

class _FilterBtn extends ConsumerWidget {
  const _FilterBtn();

  bool _hasActive(Filtri f) =>
      f.carburante != 'benzina' ||
      f.isSelf != null ||
      f.raggioMetri != 5000 ||
      f.soloAutostrade;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtri = ref.watch(filtriProvider);
    final active = _hasActive(filtri);
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.tune_rounded,
            size: 22,
            color: active ? AppColors.primary : AppColors.textSecondary,
          ),
          onPressed: () => FiltersBottomSheet.show(context),
          tooltip: 'Filtri',
        ),
        if (active)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Toggle preferiti / ricerca ───────────────────────────────────────────────

class _FavoritesToggleBtn extends ConsumerWidget {
  const _FavoritesToggleBtn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showFavorites = ref.watch(showFavoritesProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
      child: IconButton(
        key: ValueKey(showFavorites),
        icon: Icon(
          showFavorites ? Icons.search_rounded : Icons.favorite_rounded,
          size: 22,
          color: showFavorites ? AppColors.primary : AppColors.textSecondary,
        ),
        onPressed: () =>
            ref.read(showFavoritesProvider.notifier).state = !showFavorites,
        tooltip: showFavorites ? 'Cerca distributori' : 'Preferiti',
      ),
    );
  }
}

// ── Banner AdMob ─────────────────────────────────────────────────────────────

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
    return Container(
      height: _ad!.size.height.toDouble(),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: AdWidget(ad: _ad!),
    );
  }
}
