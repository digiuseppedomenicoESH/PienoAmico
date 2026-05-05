import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/extensions/datetime_ext.dart';
import '../../../../core/extensions/double_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/distributore.dart';
import '../../domain/entities/filtri.dart';
import '../../domain/entities/prezzo_record.dart';
import '../providers/fuel_provider.dart';
import '../widgets/price_badge.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final int distributoreId;
  final Distributore? distributore;

  const DetailScreen({
    super.key,
    required this.distributoreId,
    this.distributore,
  });

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  static const _expandedHeight = 180.0;
  final _scrollCtrl = ScrollController();
  bool _titleVisible = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    final collapsed =
        _scrollCtrl.offset > _expandedHeight - kToolbarHeight - 8;
    if (collapsed != _titleVisible) {
      setState(() => _titleVisible = collapsed);
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.distributore;
    final prezziAsync = ref.watch(stationPricesProvider(widget.distributoreId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          _HeroAppBar(
            distributore: d,
            titleVisible: _titleVisible,
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('PREZZI', style: AppTextStyles.sectionLabel),
                ),
                const SizedBox(height: 10),
                prezziAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                  error: (_, __) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Text(
                      'Impossibile caricare i prezzi',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  data: (prezzi) => _PrezziTable(prezzi: prezzi),
                ),
                if (d != null) ...[
                  const SizedBox(height: 20),
                  _InfoSection(distributore: d),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: d != null ? _NavigaFAB(distributore: d) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ── Hero SliverAppBar ─────────────────────────────────────────────────────────

class _HeroAppBar extends StatelessWidget {
  final Distributore? distributore;
  final bool titleVisible;
  const _HeroAppBar({required this.distributore, required this.titleVisible});

  @override
  Widget build(BuildContext context) {
    final d = distributore;
    final nomeLabel = d != null && d.nome.isNotEmpty ? d.nome : 'Distributore';

    return SliverAppBar(
      expandedHeight: d != null ? 180 : 80,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
      ),
      // Il titolo appare solo quando il hero è collassato
      title: AnimatedOpacity(
        opacity: titleVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 180),
        child: Text(
          nomeLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: d != null ? _HeroBg(distributore: d) : null,
        // Nessun title in FlexibleSpaceBar — evita la sovrapposizione
      ),
    );
  }
}

class _HeroBg extends StatelessWidget {
  final Distributore distributore;
  const _HeroBg({required this.distributore});

  @override
  Widget build(BuildContext context) {
    final d = distributore;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.backgroundMid, AppColors.background],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (d.bandiera.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMuted,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        d.bandiera.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  Text(
                    d.nome.isNotEmpty ? d.nome : d.bandiera,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.near_me_rounded,
                          size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        d.distanzaM.toDouble().asDistanza,
                        style: AppTextStyles.distanza,
                      ),
                      if (d.isAutostradale) ...[
                        const SizedBox(width: 8),
                        const Text(
                          'AUTOSTRADA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.prezzoMid,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (d.prezzoBest != null)
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    d.prezzoBest!.toStringAsFixed(3).replaceAll('.', ','),
                    style: AppTextStyles.prezzoHero.copyWith(
                      fontSize: 36,
                      color: AppColors.prezzoTop,
                    ),
                  ),
                  const Text(
                    '€/L',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.prezzoTop,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ── Tabella prezzi ───────────────────────────────────────────────────────────

class _PrezziTable extends StatelessWidget {
  final List<PrezzoRecord> prezzi;
  const _PrezziTable({required this.prezzi});

  @override
  Widget build(BuildContext context) {
    if (prezzi.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Text(
          'Nessun prezzo disponibile',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Expanded(child: SizedBox()),
                const _ColHeader(label: 'SELF'),
                const SizedBox(width: 8),
                const _ColHeader(label: 'SERV'),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.divider),
          ...prezzi.asMap().entries.map((e) {
            final isLast = e.key == prezzi.length - 1;
            return Column(
              children: [
                _PrezzoRow(record: e.value),
                if (!isLast)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: AppColors.divider,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String label;
  const _ColHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTextStyles.sectionLabel,
      ),
    );
  }
}

class _PrezzoRow extends StatelessWidget {
  final PrezzoRecord record;
  const _PrezzoRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final label = Filtri.carburantiLabel[record.carburante] ?? record.carburante;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (record.prezzoSelf != null)
            PriceBadge(
              prezzo: record.prezzoSelf!,
              isSelf: true,
              tier: PriceTier.best,
            )
          else
            const SizedBox(width: 80),
          const SizedBox(width: 8),
          if (record.prezzoServito != null)
            PriceBadge(
              prezzo: record.prezzoServito!,
              isSelf: false,
              tier: PriceTier.mid,
            )
          else
            const SizedBox(width: 80),
        ],
      ),
    );
  }
}

// ── Info sezione ─────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final Distributore distributore;
  const _InfoSection({required this.distributore});

  @override
  Widget build(BuildContext context) {
    final d = distributore;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoLine(
            icon: Icons.location_on_outlined,
            text: '${d.indirizzo}, ${d.comune}',
          ),
          if (d.dtAggiornamento != null) ...[
            const SizedBox(height: 10),
            _InfoLine(
              icon: Icons.access_time_rounded,
              text: d.dtAggiornamento!.asAgo,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: AppTextStyles.indirizzo),
        ),
      ],
    );
  }
}

// ── FAB Naviga ───────────────────────────────────────────────────────────────

class _NavigaFAB extends StatelessWidget {
  final Distributore distributore;
  const _NavigaFAB({required this.distributore});

  Future<void> _launch() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${distributore.latitudine},${distributore.longitudine}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _launch,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      icon: const Icon(Icons.navigation_rounded),
      label: const Text(
        'Naviga',
        style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3),
      ),
    );
  }
}
