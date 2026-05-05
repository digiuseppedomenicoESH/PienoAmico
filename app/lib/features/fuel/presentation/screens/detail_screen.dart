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

class DetailScreen extends ConsumerWidget {
  final int distributoreId;
  final Distributore? distributore;

  const DetailScreen({
    super.key,
    required this.distributoreId,
    this.distributore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d           = distributore;
    final prezziAsync = ref.watch(stationPricesProvider(distributoreId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          d != null && d.nome.isNotEmpty ? d.nome : 'Distributore',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (d != null) _HeroSection(distributore: d),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Text(
                'PREZZI',
                style: AppTextStyles.sectionLabel,
              ),
            ),
            prezziAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Text(
                  'Impossibile caricare i prezzi',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              data: (prezzi) => _PrezziList(prezzi: prezzi),
            ),
            if (d != null) _InfoBox(distributore: d),
            const SizedBox(height: 96),
          ],
        ),
      ),
      floatingActionButton: d != null ? _NavigaFAB(distributore: d) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _HeroSection extends StatelessWidget {
  final Distributore distributore;
  const _HeroSection({required this.distributore});

  @override
  Widget build(BuildContext context) {
    final d = distributore;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.backgroundGrey,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_gas_station_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (d.bandiera.isNotEmpty)
                  Text(d.bandiera, style: AppTextStyles.bandiera),
                Text(
                  d.indirizzo,
                  style: AppTextStyles.indirizzo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.near_me_outlined, size: 12, color: AppColors.primary),
                    const SizedBox(width: 3),
                    Text(d.distanzaM.toDouble().asDistanza, style: AppTextStyles.distanza),
                    if (d.isAutostradale) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'Autostradale',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
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
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  d.prezzoBest!.toStringAsFixed(3).replaceAll('.', ','),
                  style: AppTextStyles.prezzoHero.copyWith(
                    color: AppColors.prezzoTop,
                    fontSize: 26,
                  ),
                ),
                const Text(
                  '€/L',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.prezzoTop,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PrezziList extends StatelessWidget {
  final List<PrezzoRecord> prezzi;
  const _PrezziList({required this.prezzi});

  @override
  Widget build(BuildContext context) {
    if (prezzi.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Text(
          'Nessun prezzo disponibile',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.surface,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: prezzi.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, i) => _PrezzoRow(record: prezzi[i], isFirst: i == 0, isLast: i == prezzi.length - 1),
      ),
    );
  }
}

class _PrezzoRow extends StatelessWidget {
  final PrezzoRecord record;
  final bool isFirst;
  final bool isLast;
  const _PrezzoRow({required this.record, required this.isFirst, required this.isLast});

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
              style: AppTextStyles.nomeDistributore.copyWith(fontSize: 14),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final Distributore distributore;
  const _InfoBox({required this.distributore});

  @override
  Widget build(BuildContext context) {
    final d = distributore;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoLine(
            icon: Icons.location_on_outlined,
            text: '${d.indirizzo}, ${d.comune}',
          ),
          if (d.dtAggiornamento != null) ...[
            const SizedBox(height: 8),
            _InfoLine(
              icon: Icons.access_time_outlined,
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
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: AppTextStyles.indirizzo)),
      ],
    );
  }
}

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
      elevation: 4,
      icon: const Icon(Icons.navigation_outlined),
      label: const Text(
        'Naviga',
        style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
      ),
    );
  }
}
