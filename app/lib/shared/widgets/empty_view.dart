import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class EmptyView extends StatelessWidget {
  final String message;
  const EmptyView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 34,
                color: AppColors.textDisabled,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nessun distributore',
              style: AppTextStyles.statoTitolo,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.statoMessaggio,
            ),
          ],
        ),
      ),
    );
  }
}
