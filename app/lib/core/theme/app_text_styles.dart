import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // ── Prezzi ───────────────────────────────────────────────
  static const prezzoHero = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.2,
    color: AppColors.textPrimary,
    height: 1,
  );
  static const prezzoLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: AppColors.textPrimary,
  );
  static const prezzoSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  // ── Card distributore ────────────────────────────────────
  static const nomeDistributore = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );
  static const bandiera = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );
  static const indirizzo = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  static const distanza = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: 0.1,
  );

  // ── Badge ────────────────────────────────────────────────
  static const badgeLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
  );

  // ── AppBar / Logo ────────────────────────────────────────
  static const appBarLogo = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
  );
  static const appBarLogoAccent = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: AppColors.primary,
    letterSpacing: -0.8,
  );

  // ── Stati ────────────────────────────────────────────────
  static const statoTitolo = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );
  static const statoMessaggio = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
    height: 1.6,
  );

  // ── Sezioni ──────────────────────────────────────────────
  static const sectionLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 1.0,
  );
}
