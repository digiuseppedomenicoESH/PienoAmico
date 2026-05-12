import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../fuel/domain/entities/distributore.dart';
import '../../../fuel/presentation/widgets/price_badge.dart' show PriceTier;
import '../../../location/presentation/providers/location_provider.dart';
import '../../data/repositories/trip_repository.dart';
import '../../domain/entities/trip_result.dart';
import '../../domain/entities/trip_suggestion.dart';
import '../providers/trip_provider.dart';

class TripScreen extends ConsumerStatefulWidget {
  const TripScreen({super.key});

  @override
  ConsumerState<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends ConsumerState<TripScreen> {
  final _controller = TextEditingController();
  bool _showSuggestions = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onInputChanged(String value) {
    ref.read(tripInputProvider.notifier).state = value;
    setState(() => _showSuggestions = value.trim().length >= 2);
  }

  void _selectSuggestion(TripSuggestion s) {
    _controller.text = s.description;
    setState(() => _showSuggestions = false);
    FocusScope.of(context).unfocus();
    ref.read(tripInputProvider.notifier).state = '';
    ref.read(tripSelectedProvider.notifier).state = s;
  }

  void _clearDestination() {
    _controller.clear();
    ref.read(tripInputProvider.notifier).state = '';
    ref.read(tripSelectedProvider.notifier).state = null;
    setState(() => _showSuggestions = false);
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(tripSelectedProvider);
    final tripAsync = ref.watch(tripResultProvider);

    return Column(
      children: [
        _SearchBar(
          controller: _controller,
          onChanged: _onInputChanged,
          onClear: _clearDestination,
          hasDestination: selected != null,
        ),
        if (_showSuggestions) _SuggestionsDropdown(onSelect: _selectSuggestion),
        Expanded(
          child: selected == null
              ? const _EmptyState()
              : tripAsync.when(
                  loading: () => const _LoadingState(),
                  error: (_, __) => const _ErrorState(),
                  data: (result) => result == null
                      ? const _ErrorState()
                      : _TripResult(result: result),
                ),
        ),
      ],
    );
  }
}

// ── Barra di ricerca ─────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool hasDestination;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.hasDestination,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.flag_rounded, size: 18, color: AppColors.primary),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'Dove stai andando?',
                hintStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              textInputAction: TextInputAction.search,
            ),
          ),
          if (hasDestination || controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Dropdown suggerimenti ────────────────────────────────────

class _SuggestionsDropdown extends ConsumerWidget {
  final ValueChanged<TripSuggestion> onSelect;
  const _SuggestionsDropdown({required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tripSuggestionsProvider);

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (suggestions) {
        if (suggestions.isEmpty) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (_, i) {
                final s = suggestions[i];
                return InkWell(
                  onTap: () => onSelect(s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ── Stato vuoto ──────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.route_rounded, size: 56, color: AppColors.primary.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          const Text(
            'Inserisci la destinazione',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ti mostreremo i distributori\npiù convenienti lungo il percorso',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }
}

// ── Caricamento ──────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
          SizedBox(height: 16),
          Text(
            'Calcolo percorso in corso...',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Errore ───────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 40, color: AppColors.prezzoHigh),
          SizedBox(height: 12),
          Text(
            'Impossibile calcolare il percorso',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Verifica la connessione e riprova',
            style: TextStyle(fontSize: 12, color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }
}

// ── Risultato: mappa + lista ─────────────────────────────────

class _TripResult extends ConsumerWidget {
  final TripResult result;
  const _TripResult({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(locationProvider);
    final mid = TripRepository.midpoint(result.routePoints);

    return Stack(
      children: [
        // Mappa con percorso e stazioni
        FlutterMap(
          options: MapOptions(
            initialCenter: mid,
            initialZoom: 7,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.pienoamico.app',
            ),
            // Percorso
            PolylineLayer(
              polylines: [
                Polyline(
                  points: result.routePoints,
                  color: AppColors.primary,
                  strokeWidth: 4,
                ),
              ],
            ),
            // Posizione utente
            locationAsync.whenData((pos) => MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(pos.latitude, pos.longitude),
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.brandBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandBlue.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )).valueOrNull ??
                const MarkerLayer(markers: []),
            // Marker stazioni
            MarkerLayer(
              markers: result.stations
                  .asMap()
                  .entries
                  .map(
                    (e) => Marker(
                      point: LatLng(e.value.latitudine, e.value.longitudine),
                      width: 28,
                      height: 28,
                      child: _StationMarker(
                        tier: _tier(e.key, result.stations.length),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),

        // Bottom sheet con lista stazioni
        DraggableScrollableSheet(
          initialChildSize: 0.32,
          minChildSize: 0.12,
          maxChildSize: 0.7,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textDisabled,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.local_gas_station_rounded,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          '${result.stations.length} distributori sul percorso',
                          style: AppTextStyles.sectionLabel,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  // Lista
                  Expanded(
                    child: result.stations.isEmpty
                        ? const Center(
                            child: Text(
                              'Nessun distributore trovato\nlungo questo percorso',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: result.stations.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (ctx, i) => _TripStationCard(
                              distributore: result.stations[i],
                              rank: i + 1,
                              tier: _tier(i, result.stations.length),
                              onTap: () => ctx.push(
                                '/detail/${result.stations[i].id}',
                                extra: result.stations[i],
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  PriceTier _tier(int index, int total) {
    if (total <= 1) return PriceTier.best;
    final n = index / (total - 1);
    if (n < 0.33) return PriceTier.best;
    if (n < 0.67) return PriceTier.mid;
    return PriceTier.high;
  }
}

// ── Marker sulla mappa ───────────────────────────────────────

class _StationMarker extends StatelessWidget {
  final PriceTier tier;
  const _StationMarker({required this.tier});

  Color get _color => switch (tier) {
        PriceTier.best => AppColors.prezzoTop,
        PriceTier.mid  => AppColors.prezzoMid,
        PriceTier.high => AppColors.prezzoHigh,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: _color.withValues(alpha: 0.4),
            blurRadius: 4,
          ),
        ],
      ),
      child: const Icon(Icons.local_gas_station_rounded,
          size: 13, color: Colors.white),
    );
  }
}

// ── Card stazione nel viaggio ────────────────────────────────

class _TripStationCard extends StatelessWidget {
  final Distributore distributore;
  final int rank;
  final PriceTier tier;
  final VoidCallback onTap;

  const _TripStationCard({
    required this.distributore,
    required this.rank,
    required this.tier,
    required this.onTap,
  });

  Color get _tierColor => switch (tier) {
        PriceTier.best => AppColors.prezzoTop,
        PriceTier.mid  => AppColors.prezzoMid,
        PriceTier.high => AppColors.prezzoHigh,
      };

  Color get _tierBg => switch (tier) {
        PriceTier.best => AppColors.prezzoTopBg,
        PriceTier.mid  => AppColors.prezzoMidBg,
        PriceTier.high => AppColors.prezzoHighBg,
      };

  String get _distanzaStrada {
    final m = distributore.distanzaM;
    if (m < 100) return 'sulla strada';
    if (m < 1000) return 'a ${m}m dalla strada';
    return 'a ${(m / 1000).toStringAsFixed(1)}km dalla strada';
  }

  @override
  Widget build(BuildContext context) {
    final d = distributore;
    return Material(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: _tierColor.withValues(alpha: 0.08),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [_tierBg, AppColors.backgroundCard],
              stops: const [0.0, 0.4],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Numero ranking
              Container(
                width: 44,
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _tierColor,
                  ),
                ),
              ),
              // Info stazione
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.nome.isNotEmpty ? d.nome : d.bandiera,
                        style: AppTextStyles.nomeDistributore,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [if (d.bandiera.isNotEmpty) d.bandiera, d.comune]
                            .join(' · '),
                        style: AppTextStyles.bandiera,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.near_me_rounded,
                              size: 11, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Text(_distanzaStrada,
                              style: AppTextStyles.distanza),
                          if (d.isAutostradale) ...[
                            const SizedBox(width: 6),
                            _Pill(label: 'A', color: AppColors.prezzoMid),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Prezzo
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (d.prezzoBest != null) ...[
                      Text(
                        d.prezzoBest!.toStringAsFixed(3).replaceAll('.', ','),
                        style: AppTextStyles.prezzoHero
                            .copyWith(color: _tierColor),
                      ),
                      Text(
                        '€/L',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _tierColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: AppColors.textDisabled),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
