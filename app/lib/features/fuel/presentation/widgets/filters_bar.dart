import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/filtri.dart';
import '../providers/filters_provider.dart';
import 'filters_bottom_sheet.dart';

class FiltersBar extends ConsumerWidget {
  const FiltersBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtri = ref.watch(filtriProvider);

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: Filtri.carburantiDisponibili.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                if (i < Filtri.carburantiDisponibili.length) {
                  final c        = Filtri.carburantiDisponibili[i];
                  final selected = filtri.carburante == c;
                  return ChoiceChip(
                    label: Text(Filtri.carburantiLabel[c] ?? c),
                    selected: selected,
                    onSelected: (_) =>
                        ref.read(filtriProvider.notifier).setCarburante(c),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    selectedColor: AppColors.primarySurface,
                    side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.surfaceBorder,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                }
                return _RaggioChip(filtri: filtri);
              },
            ),
          ),
          Container(
            width: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: AppColors.divider)),
            ),
            child: _FiltersIconButton(filtri: filtri),
          ),
        ],
      ),
    );
  }
}

class _RaggioChip extends ConsumerWidget {
  final Filtri filtri;
  const _RaggioChip({required this.filtri});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final km = filtri.raggioMetri ~/ 1000;
    return GestureDetector(
      onTap: () => _showMenu(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.radar, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              '$km km',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    const options = [1000, 2000, 5000, 10000, 20000];
    const labels  = ['1 km', '2 km', '5 km', '10 km', '20 km'];

    showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 140,
        56,
        12,
        0,
      ),
      items: List.generate(
        options.length,
        (i) => PopupMenuItem(
          value: options[i],
          height: 40,
          child: Row(
            children: [
              Icon(
                filtri.raggioMetri == options[i]
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 16,
                color: filtri.raggioMetri == options[i]
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(labels[i], style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    ).then((v) {
      if (v != null) ref.read(filtriProvider.notifier).setRaggio(v);
    });
  }
}

class _FiltersIconButton extends ConsumerWidget {
  final Filtri filtri;
  const _FiltersIconButton({required this.filtri});

  bool get _hasActive => filtri.isSelf != null || filtri.soloAutostrade;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.tune, size: 20),
          color: _hasActive ? AppColors.primary : AppColors.textSecondary,
          onPressed: () => FiltersBottomSheet.show(context),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        if (_hasActive)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
