import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AppLogo extends StatelessWidget {
  final double iconSize;
  const AppLogo({super.key, this.iconSize = 22});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize + 6,
          height: iconSize + 6,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF8533), AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            Icons.local_gas_station_rounded,
            color: Colors.white,
            size: iconSize - 2,
          ),
        ),
        const SizedBox(width: 10),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(text: 'Pieno', style: AppTextStyles.appBarLogo),
              TextSpan(text: 'Amico', style: AppTextStyles.appBarLogoAccent),
            ],
          ),
        ),
      ],
    );
  }
}
