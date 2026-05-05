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
        builder: (_) => const FiltersBottomSheet._(),
      );

  @override
  ConsumerState<FiltersBottomSheet> createState() =>
      _FiltersBottomSheetState();
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

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Handle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filtri',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _local = const Filtri()),
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: AppColors.accent, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          _Section(
            title: 'CARBURANTE',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Filtri.carburantiDisponibili.map((c) {
                final sel = _local.carburante == c;
                return ChoiceChip(
                  label: Text(Filtri.carburantiLabel[c] ?? c),
                  selected: sel,
                  onSelected: (_) =>
                      setState(() => _local = _local.copyWith(carburante: c)),
                  selectedColor: AppColors.primarySurface,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: sel ? AppColors.primary : AppColors.textPrimary,
                  ),
                  side: BorderSide(
                    color: sel ? AppColors.primary : AppColors.surfaceBorder,
                  ),
                );
              }).toList(),
            ),
          ),
          _Section(
            title: 'MODALITÀ',
            child: Row(
              children: [
                _Toggle(
                  label: 'Entrambe',
                  selected: _local.isSelf == null,
                  onTap: () =>
                      setState(() => _local = _local.copyWith(isSelf: null)),
                ),
                const SizedBox(width: 8),
                _Toggle(
                  label: 'Self',
                  selected: _local.isSelf == true,
                  onTap: () =>
                      setState(() => _local = _local.copyWith(isSelf: true)),
                ),
                const SizedBox(width: 8),
                _Toggle(
                  label: 'Servito',
                  selected: _local.isSelf == false,
                  onTap: () =>
                      setState(() => _local = _local.copyWith(isSelf: false)),
                ),
              ],
            ),
          ),
          _Section(
            title: 'RAGGIO — ${(_local.raggioMetri / 1000).round()} km',
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: _local.raggioMetri.toDouble(),
                min: 1000,
                max: 20000,
                divisions: 19,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.primarySurface,
                label: '${(_local.raggioMetri / 1000).round()} km',
                onChanged: (v) =>
                    setState(() => _local = _local.copyWith(raggioMetri: v.round())),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Solo autostrade',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              value: _local.soloAutostrade,
              onChanged: (v) =>
                  setState(() => _local = _local.copyWith(soloAutostrade: v)),
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primarySurface,
              dense: true,
            ),
          ),
          const Divider(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.surfaceBorder,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
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
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
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

class _Toggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Toggle({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
