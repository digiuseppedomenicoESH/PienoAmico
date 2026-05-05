import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Prezzi
  static const prezzoLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );
  static const prezzoSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Lista
  static const nomeDistributore = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const indirizzoDistributore = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
  );
  static const distanza = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w500,
  );

  // Badge
  static const badgeLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.3,
  );

  // Stato
  static const statoMessaggio = TextStyle(
    fontSize: 15,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // AppBar
  static const appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
}
