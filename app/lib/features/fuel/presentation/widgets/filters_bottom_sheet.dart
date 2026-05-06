import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/filtri.dart';
import '../providers/filters_provider.dart';

class FiltersBottomSheet extends ConsumerStatefulWidget {
  const FiltersBottomSheet._();

  static void show(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.backgroundCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => const FiltersBottomSheet._(),
      );

  @override
  ConsumerState<FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends ConsumerState<FiltersBottomSheet> {
  late Filtri _local;

  @override
  void initState() {
    super.initState();
    _local = ref.read(filtriProvider);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPad),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 6),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filtri',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _local = const Filtri()),
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.divider, margin: const EdgeInsets.symmetric(vertical: 12)),

          // Carburante
          _Section(
            title: 'CARBURANTE',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Filtri.carburantiDisponibili.map((c) {
                final sel = _local.carburante == c;
                return _SheetPill(
                  label: Filtri.carburantiLabel[c] ?? c,
                  selected: sel,
                  onTap: () =>
                      setState(() => _local = _local.copyWith(carburante: c)),
                );
              }).toList(),
            ),
          ),

          // Modalità
          _Section(
            title: 'MODALITÀ',
            child: Row(
              children: [
                _SheetPill(
                  label: 'Entrambe',
                  selected: _local.isSelf == null,
                  onTap: () =>
                      setState(() => _local = _local.copyWith(isSelf: null)),
                ),
                const SizedBox(width: 8),
                _SheetPill(
                  label: 'Self',
                  selected: _local.isSelf == true,
                  onTap: () =>
                      setState(() => _local = _local.copyWith(isSelf: true)),
                ),
                const SizedBox(width: 8),
                _SheetPill(
                  label: 'Servito',
                  selected: _local.isSelf == false,
                  onTap: () =>
                      setState(() => _local = _local.copyWith(isSelf: false)),
                ),
              ],
            ),
          ),

          // Raggio
          _Section(
            title: 'RAGGIO — ${(_local.raggioMetri / 1000).round()} km',
            child: Slider(
              value: _local.raggioMetri.toDouble(),
              min: 1000,
              max: 20000,
              divisions: 19,
              label: '${(_local.raggioMetri / 1000).round()} km',
              onChanged: (v) =>
                  setState(() => _local = _local.copyWith(raggioMetri: v.round())),
            ),
          ),

          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ref.read(filtriProvider.notifier).applyAll(_local);
                  Navigator.of(context).pop();
                },
                child: const Text('Applica filtri'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.sectionLabel),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SheetPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SheetPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryMuted : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
