import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class LoadingView extends StatefulWidget {
  final String? message;
  const LoadingView({super.key, this.message});

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryMuted,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25 * _pulse.value),
                    blurRadius: 24 * _pulse.value,
                    spreadRadius: 4 * _pulse.value,
                  ),
                ],
              ),
              child: Icon(
                Icons.local_gas_station_rounded,
                color: AppColors.primary.withValues(alpha: _pulse.value),
                size: 26,
              ),
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 20),
            Text(
              widget.message!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
