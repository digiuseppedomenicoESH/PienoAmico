import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/onboarding_repository.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;
  bool _gpsLoading = false;
  String? _carburanteSelezionato;

  static const _totalPages = 4;

  bool get _canProceed {
    // pagina carburante (index 2): obbligatorio scegliere
    if (_page == 2) return _carburanteSelezionato != null;
    return true;
  }

  void _next() {
    if (_page < _totalPages - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _complete() async {
    if (_carburanteSelezionato != null) {
      await OnboardingRepository.saveCarburantePreferito(_carburanteSelezionato!);
    }
    await OnboardingRepository.markCompleted();
    if (mounted) {
      ref.read(onboardingCompletedProvider.notifier).state = true;
    }
  }

  Future<void> _requestGpsAndComplete() async {
    setState(() => _gpsLoading = true);
    try {
      final status = await Geolocator.checkPermission();
      if (status == LocationPermission.denied ||
          status == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
      }
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
      await _complete();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip — visibile solo nelle prime due pagine
            Align(
              alignment: Alignment.topRight,
              child: AnimatedOpacity(
                opacity: _page < _totalPages - 1 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: _page < _totalPages - 1 ? _complete : null,
                  child: const Text(
                    'Salta',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // Pagine
            Expanded(
              child: PageView(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  const _PageBenvenuto(),
                  const _PageComeFunziona(),
                  _PageCarburante(
                    selezionato: _carburanteSelezionato,
                    onSelected: (c) =>
                        setState(() => _carburanteSelezionato = c),
                  ),
                  const _PageGps(),
                ],
              ),
            ),

            // Dots + bottone
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                children: [
                  _DotsIndicator(current: _page, total: _totalPages),
                  const SizedBox(height: 24),
                  _page < _totalPages - 1
                      ? _PrimaryButton(
                          label: 'Avanti',
                          onTap: _canProceed ? _next : null,
                        )
                      : _PrimaryButton(
                          label: _gpsLoading ? 'Attendere…' : 'Consenti posizione',
                          icon: Icons.my_location_rounded,
                          loading: _gpsLoading,
                          onTap: _requestGpsAndComplete,
                        ),
                  if (_page == _totalPages - 1) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _gpsLoading ? null : _complete,
                      child: const Text(
                        'Non ora',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pagina 1 — Benvenuto ──────────────────────────────────────────────────────

class _PageBenvenuto extends StatelessWidget {
  const _PageBenvenuto();

  @override
  Widget build(BuildContext context) {
    return _PageLayout(
      illustration: _IllustrationCircle(
        color: AppColors.primary,
        icon: Icons.local_gas_station_rounded,
        iconColor: Colors.white,
      ),
      title: 'Benvenuto in\nPienoAmico',
      subtitle:
          'Trova il distributore più conveniente\nvicino a te, in tempo reale.',
      extra: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Badge(icon: Icons.verified_outlined, label: 'Dati ufficiali MIMIT'),
            const SizedBox(width: 12),
            _Badge(icon: Icons.lock_outline_rounded, label: 'Gratuito'),
          ],
        ),
      ),
    );
  }
}

// ── Pagina 2 — Come funziona ──────────────────────────────────────────────────

class _PageComeFunziona extends StatelessWidget {
  const _PageComeFunziona();

  @override
  Widget build(BuildContext context) {
    return _PageLayout(
      illustration: _IllustrationCircle(
        color: AppColors.primary,
        icon: Icons.search_rounded,
        iconColor: Colors.white,
      ),
      title: 'Come funziona',
      subtitle: null,
      extra: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          children: const [
            _FeatureRow(
              icon: Icons.near_me_rounded,
              color: AppColors.primary,
              title: 'Trova distributori vicini',
              desc: 'Rileva la tua posizione e mostra tutti gli impianti nel raggio selezionato.',
            ),
            SizedBox(height: 16),
            _FeatureRow(
              icon: Icons.sort_rounded,
              color: AppColors.prezzoTop,
              title: 'Ordina per prezzo',
              desc: 'Il più conveniente sempre in cima. Filtra per carburante, self o servito.',
            ),
            SizedBox(height: 16),
            _FeatureRow(
              icon: Icons.update_rounded,
              color: AppColors.prezzoMid,
              title: 'Sempre aggiornato',
              desc: 'Dati MIMIT aggiornati due volte al giorno, alle 08:30 e alle 14:30.',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pagina 3 — Carburante ────────────────────────────────────────────────────

class _PageCarburante extends StatelessWidget {
  final String? selezionato;
  final ValueChanged<String> onSelected;

  const _PageCarburante({
    required this.selezionato,
    required this.onSelected,
  });

  static const _carburanti = [
    ('benzina', 'Benzina', Icons.local_gas_station_rounded),
    ('gasolio', 'Gasolio', Icons.oil_barrel_rounded),
    ('gpl', 'GPL', Icons.propane_rounded),
    ('metano', 'Metano', Icons.air_rounded),
    ('hvo', 'HVO', Icons.eco_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return _PageLayout(
      illustration: _IllustrationCircle(
        color: AppColors.primary,
        icon: Icons.directions_car_rounded,
        iconColor: Colors.white,
      ),
      title: 'Il tuo carburante',
      subtitle: 'Scegli il carburante del tuo veicolo.\nSarà il filtro predefinito nella ricerca.',
      extra: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          children: _carburanti.map((item) {
            final (id, label, icon) = item;
            final selected = selezionato == id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CarburanteCard(
                label: label,
                icon: icon,
                selected: selected,
                onTap: () => onSelected(id),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CarburanteCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CarburanteCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryMuted : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: selected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 180),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pagina 4 — GPS ────────────────────────────────────────────────────────────

class _PageGps extends StatelessWidget {
  const _PageGps();

  @override
  Widget build(BuildContext context) {
    return _PageLayout(
      illustration: _IllustrationCircle(
        color: AppColors.primary,
        icon: Icons.location_on_rounded,
        iconColor: Colors.white,
      ),
      title: 'Dove sei?',
      subtitle:
          'PienoAmico usa la tua posizione per trovare i distributori vicini.\n\nNessun dato viene trasmesso a terzi né conservato.',
      extra: null,
    );
  }
}

// ── Componenti condivisi ──────────────────────────────────────────────────────

class _PageLayout extends StatelessWidget {
  final Widget illustration;
  final String title;
  final String? subtitle;
  final Widget? extra;

  const _PageLayout({
    required this.illustration,
    required this.title,
    required this.subtitle,
    required this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          illustration,
          const SizedBox(height: 36),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.8,
              height: 1.15,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 14),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
          if (extra != null) extra!,
        ],
      ),
    );
  }
}

class _IllustrationCircle extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Color iconColor;

  const _IllustrationCircle({
    required this.color,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
      ),
      child: Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 38),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _DotsIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool loading;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onTap,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
