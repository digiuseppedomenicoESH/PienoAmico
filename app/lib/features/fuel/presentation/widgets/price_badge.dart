import 'package:flutter/material.dart';
import '../../../../core/extensions/double_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

enum PriceTier { best, mid, high }

class PriceBadge extends StatelessWidget {
  final double prezzo;
  final bool isSelf;
  final PriceTier tier;

  const PriceBadge({
    super.key,
    required this.prezzo,
    required this.isSelf,
    this.tier = PriceTier.mid,
  });

  Color get _color => switch (tier) {
        PriceTier.best => AppColors.prezzoTop,
        PriceTier.mid  => AppColors.prezzoMid,
        PriceTier.high => AppColors.prezzoHigh,
      };

  Color get _bgColor => switch (tier) {
        PriceTier.best => AppColors.prezzoTopBg,
        PriceTier.mid  => AppColors.prezzoMidBg,
        PriceTier.high => AppColors.prezzoHighBg,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isSelf ? 'SELF' : 'SERV',
            style: AppTextStyles.badgeLabel.copyWith(
              color: _color.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            prezzo.asPrezzo,
            style: AppTextStyles.prezzoSmall.copyWith(color: _color),
          ),
        ],
      ),
    );
  }
}
