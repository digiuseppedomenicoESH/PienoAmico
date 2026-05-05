import 'package:flutter/material.dart';

class AppColors {
  // ── Background ───────────────────────────────────────────
  static const background      = Color(0xFFF8F9FC); // Bianco freddo — sfondo principale
  static const backgroundCard  = Color(0xFFFFFFFF); // Card pure white
  static const backgroundMid   = Color(0xFFF1F3F8); // Sezioni intermedie

  // ── Bordi e divisori ─────────────────────────────────────
  static const border          = Color(0xFFE2E6EF);
  static const divider         = Color(0xFFEEF0F6);

  // ── Superfici interattive ────────────────────────────────
  static const surface         = Color(0xFFF1F3F8);
  static const surfaceHover    = Color(0xFFE8EBF3);

  // ── Brand arancio (carburante, energia) ──────────────────
  static const primary         = Color(0xFFFF6600);
  static const primaryMuted    = Color(0x1AFF6600); // ~10% opacity
  static const primaryLight    = Color(0xFFFF8533);

  // ── Prezzi ───────────────────────────────────────────────
  static const prezzoTop       = Color(0xFF00A878); // Verde — prezzo più basso
  static const prezzoTopBg     = Color(0xFFE6F7F3);
  static const prezzoMid       = Color(0xFFD97706); // Ambra — nella media
  static const prezzoMidBg     = Color(0xFFFEF3C7);
  static const prezzoHigh      = Color(0xFFDC2626); // Rosso — sopra la media
  static const prezzoHighBg    = Color(0xFFFEE2E2);

  // ── Testo ────────────────────────────────────────────────
  static const textPrimary     = Color(0xFF0D1117);
  static const textSecondary   = Color(0xFF6B7280);
  static const textDisabled    = Color(0xFFC4C9D4);

  // ── Badge Self / Servito ─────────────────────────────────
  static const selfColor       = Color(0xFF2563EB);
  static const selfBg          = Color(0xFFEFF6FF);
  static const servitoColor    = Color(0xFF059669);
  static const servitoBg       = Color(0xFFECFDF5);

  // ── Alias legacy (per compatibilità) ─────────────────────
  static const backgroundGrey  = backgroundMid;
  static const surfaceBorder   = border;
  static const primarySurface  = primaryMuted;
  static const accent          = primary;
  static const accentLight     = primaryMuted;
}
