import 'package:flutter/material.dart';
import '../../../../core/extensions/double_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/distributore.dart';
import 'price_badge.dart';

class FuelCard extends StatelessWidget {
  final Distributore distributore;
  final PriceTier tier;
  final VoidCallback onTap;

  const FuelCard({
    super.key,
    required this.distributore,
    required this.tier,
    required this.onTap,
  });

  Color get _tierColor => switch (tier) {
        PriceTier.best => AppColors.prezzoTop,
        PriceTier.mid  => AppColors.prezzoMid,
        PriceTier.high => AppColors.prezzoHigh,
      };

  @override
  Widget build(BuildContext context) {
    final d = distributore;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tier color bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _tierColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: info
                      Expanded(
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
                            _BandieraComune(bandiera: d.bandiera, comune: d.comune),
                            const SizedBox(height: 8),
                            _DistanzaRow(distanzaM: d.distanzaM, isAutostradale: d.isAutostradale),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Right: price + modalità
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (d.prezzoBest != null)
                            _PrezzoHero(prezzo: d.prezzoBest!, color: _tierColor),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (d.prezzoSelf != null)
                                const _MiniChip(label: 'SELF', color: AppColors.selfColor, bg: AppColors.selfBg),
                              if (d.prezzoSelf != null && d.prezzoServito != null)
                                const SizedBox(width: 4),
                              if (d.prezzoServito != null)
                                const _MiniChip(label: 'SERV', color: AppColors.servitoColor, bg: AppColors.servitoBg),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Chevron
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.chevron_right, size: 18, color: AppColors.textDisabled),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrezzoHero extends StatelessWidget {
  final double prezzo;
  final Color color;
  const _PrezzoHero({required this.prezzo, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          prezzo.toStringAsFixed(3).replaceAll('.', ','),
          style: AppTextStyles.prezzoHero.copyWith(color: color),
        ),
        Text(
          '€/L',
          style: TextStyle(
            fontSize: 10,
            color: color.withValues(alpha: 0.8),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _BandieraComune extends StatelessWidget {
  final String bandiera;
  final String comune;
  const _BandieraComune({required this.bandiera, required this.comune});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (bandiera.isNotEmpty) ...[
          Text(bandiera, style: AppTextStyles.bandiera),
          const Text(' · ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
        Flexible(
          child: Text(comune, style: AppTextStyles.bandiera, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _DistanzaRow extends StatelessWidget {
  final int distanzaM;
  final bool isAutostradale;
  const _DistanzaRow({required this.distanzaM, required this.isAutostradale});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.near_me_outlined, size: 12, color: AppColors.primary),
        const SizedBox(width: 3),
        Text(distanzaM.toDouble().asDistanza, style: AppTextStyles.distanza),
        if (isAutostradale) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: const Text(
              'AUTOSTRADA',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
