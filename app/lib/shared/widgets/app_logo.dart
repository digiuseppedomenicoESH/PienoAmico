import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

// Logo testuale segnaposto — sostituire con asset SVG quando il logo è pronto.
class AppLogo extends StatelessWidget {
  final double iconSize;
  const AppLogo({super.key, this.iconSize = 22});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize + 4,
          height: iconSize + 4,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.local_gas_station_rounded,
            color: Colors.white,
            size: iconSize - 2,
          ),
        ),
        const SizedBox(width: 8),
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
