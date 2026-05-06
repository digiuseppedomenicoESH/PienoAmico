import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/double_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/distributore.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import 'price_badge.dart';

class FuelCard extends ConsumerStatefulWidget {
  final Distributore distributore;
  final PriceTier tier;
  final VoidCallback onTap;
  final int index;

  const FuelCard({
    super.key,
    required this.distributore,
    required this.tier,
    required this.onTap,
    this.index = 0,
  });

  @override
  ConsumerState<FuelCard> createState() => _FuelCardState();
}

class _FuelCardState extends ConsumerState<FuelCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final delay = (widget.index * 60).clamp(0, 480);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _tierColor => switch (widget.tier) {
        PriceTier.best => AppColors.prezzoTop,
        PriceTier.mid  => AppColors.prezzoMid,
        PriceTier.high => AppColors.prezzoHigh,
      };

  Color get _tierBg => switch (widget.tier) {
        PriceTier.best => AppColors.prezzoTopBg,
        PriceTier.mid  => AppColors.prezzoMidBg,
        PriceTier.high => AppColors.prezzoHighBg,
      };

  @override
  Widget build(BuildContext context) {
    final isFav = ref.watch(
      favoritesProvider.select((s) => s.contains(widget.distributore.id)),
    );
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: _CardBody(
          distributore: widget.distributore,
          tier: widget.tier,
          tierColor: _tierColor,
          tierBg: _tierBg,
          onTap: widget.onTap,
          isFavorite: isFav,
          onFavoriteTap: () =>
              ref.read(favoritesProvider.notifier).toggle(widget.distributore.id),
        ),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  final Distributore distributore;
  final PriceTier tier;
  final Color tierColor;
  final Color tierBg;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  const _CardBody({
    required this.distributore,
    required this.tier,
    required this.tierColor,
    required this.tierBg,
    required this.onTap,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final d = distributore;
    return Material(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: tierColor.withValues(alpha: 0.08),
        highlightColor: tierColor.withValues(alpha: 0.04),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                tierBg,
                AppColors.backgroundCard,
              ],
              stops: const [0.0, 0.4],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Cuore preferiti
              _RankColumn(
                isFavorite: isFavorite,
                onFavoriteTap: onFavoriteTap,
              ),
              // Station info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.nome.isNotEmpty ? d.nome : d.bandiera,
                        style: AppTextStyles.nomeDistributore,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      _SubInfo(bandiera: d.bandiera, comune: d.comune),
                      const SizedBox(height: 8),
                      _DistanzaRow(
                        distanzaM: d.distanzaM,
                        isAutostradale: d.isAutostradale,
                        isFresco: d.isPrezzoFresco,
                      ),
                    ],
                  ),
                ),
              ),
              // Prezzo + modalità
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (d.prezzoBest != null) ...[
                      Text(
                        d.prezzoBest!.toStringAsFixed(3).replaceAll('.', ','),
                        style: AppTextStyles.prezzoHero.copyWith(
                          color: tierColor,
                        ),
                      ),
                      Text(
                        '€/L',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: tierColor.withValues(alpha: 0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (d.prezzoSelf != null)
                          _MiniChip(
                            label: 'SELF',
                            color: AppColors.selfColor,
                            bg: AppColors.selfBg,
                          ),
                        if (d.prezzoSelf != null && d.prezzoServito != null)
                          const SizedBox(width: 4),
                        if (d.prezzoServito != null)
                          _MiniChip(
                            label: 'SERV',
                            color: AppColors.servitoColor,
                            bg: AppColors.servitoBg,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.textDisabled,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankColumn extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  const _RankColumn({
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onFavoriteTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 24,
          color: isFavorite ? AppColors.prezzoHigh : AppColors.textDisabled,
        ),
      ),
    );
  }
}

class _SubInfo extends StatelessWidget {
  final String bandiera;
  final String comune;
  const _SubInfo({required this.bandiera, required this.comune});

  @override
  Widget build(BuildContext context) {
    final parts = [
      if (bandiera.isNotEmpty) bandiera,
      if (comune.isNotEmpty) comune,
    ];
    return Text(
      parts.join(' · '),
      style: AppTextStyles.bandiera,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _DistanzaRow extends StatelessWidget {
  final int distanzaM;
  final bool isAutostradale;
  final bool isFresco;
  const _DistanzaRow({
    required this.distanzaM,
    required this.isAutostradale,
    required this.isFresco,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.near_me_rounded, size: 11, color: AppColors.primary),
        const SizedBox(width: 3),
        Text(distanzaM.toDouble().asDistanza, style: AppTextStyles.distanza),
        if (isAutostradale) ...[
          const SizedBox(width: 6),
          _Pill(label: 'A', color: AppColors.prezzoMid),
        ],
        if (isFresco) ...[
          const SizedBox(width: 6),
          _Pill(label: '●', color: AppColors.prezzoTop),
        ],
      ],
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

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _MiniChip({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
