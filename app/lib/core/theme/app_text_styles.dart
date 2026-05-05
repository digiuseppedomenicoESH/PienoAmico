import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // ── Prezzi ───────────────────────────────────────────────
  static const prezzoHero = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: AppColors.textPrimary,
  );
  static const prezzoLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );
  static const prezzoSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Card distributore ────────────────────────────────────
  static const nomeDistributore = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
  );
  static const bandiera = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  static const indirizzo = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
    height: 1.3,
  );
  static const distanza = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  // ── Badge ────────────────────────────────────────────────
  static const badgeLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  // ── AppBar ───────────────────────────────────────────────
  static const appBarLogo = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );
  static const appBarLogoAccent = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.accent,
    letterSpacing: -0.5,
  );

  // ── Stati (loading, empty, error) ────────────────────────
  static const statoTitolo = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const statoMessaggio = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ── Sezioni e label ──────────────────────────────────────
  static const sectionLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
}
