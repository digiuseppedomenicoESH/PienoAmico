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
      height: 52,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              itemCount: Filtri.carburantiDisponibili.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                if (i < Filtri.carburantiDisponibili.length) {
                  final c = Filtri.carburantiDisponibili[i];
                  final selected = filtri.carburante == c;
                  return _FilterPill(
                    label: Filtri.carburantiLabel[c] ?? c,
                    selected: selected,
                    onTap: () =>
                        ref.read(filtriProvider.notifier).setCarburante(c),
                  );
                }
                return _RaggioChip(filtri: filtri);
              },
            ),
          ),
          Container(
            width: 52,
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

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
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
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
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
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.primary : AppColors.textSecondary,
            letterSpacing: 0.1,
          ),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.radar_rounded, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              '$km km',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    const options = [1000, 2000, 5000, 10000, 20000];
    const labels = ['1 km', '2 km', '5 km', '10 km', '20 km'];

    showMenu<int>(
      context: context,
      color: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 140,
        58,
        14,
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
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 16,
                color: filtri.raggioMetri == options[i]
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                labels[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: filtri.raggioMetri == options[i]
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
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
        Material(
          color: _hasActive ? AppColors.primaryMuted : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => FiltersBottomSheet.show(context),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.tune_rounded,
                size: 20,
                color:
                    _hasActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
        if (_hasActive)
          Positioned(
            top: 4,
            right: 4,
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
