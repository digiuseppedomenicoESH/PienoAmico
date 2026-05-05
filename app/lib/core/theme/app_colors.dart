import 'package:flutter/material.dart';

class AppColors {
  // ── Brand ────────────────────────────────────────────────
  static const primary        = Color(0xFF1565C0); // Blu Material 800 — affidabilità
  static const primaryLight   = Color(0xFF1E88E5); // Blu 600 — hover / highlight
  static const primarySurface = Color(0xFFE3F2FD); // Blu 50 — sfondi tinti

  static const accent         = Color(0xFFF57C00); // Arancio 700 — energia, carburante
  static const accentLight    = Color(0xFFFFF3E0); // Arancio 50 — sfondi badge accent

  // ── Prezzi ───────────────────────────────────────────────
  static const prezzoTop      = Color(0xFF2E7D32); // Verde 800 — prezzo più basso
  static const prezzoTopBg    = Color(0xFFE8F5E9); // Verde 50 — sfondo badge economico
  static const prezzoMid      = Color(0xFFF9A825); // Ambra 700 — nella media
  static const prezzoMidBg    = Color(0xFFFFFDE7); // Ambra 50 — sfondo badge medio
  static const prezzoHigh     = Color(0xFFC62828); // Rosso 800 — sopra la media
  static const prezzoHighBg   = Color(0xFFFFEBEE); // Rosso 50 — sfondo badge caro

  // ── Base / Superfici ─────────────────────────────────────
  static const background     = Color(0xFFFFFFFF); // Bianco puro
  static const backgroundGrey = Color(0xFFF5F7FA); // Grigio chiarissimo per sezioni
  static const surface        = Color(0xFFFFFFFF); // Card flat — stesso dello sfondo
  static const surfaceBorder  = Color(0xFFE8ECF0); // Bordo sottile card flat

  // ── Testo ────────────────────────────────────────────────
  static const textPrimary    = Color(0xFF0D1117); // Quasi nero — titoli
  static const textSecondary  = Color(0xFF6B7280); // Grigio medio — sottotitoli
  static const textDisabled   = Color(0xFFBEC5CC); // Grigio chiaro — placeholder

  // ── Divisori ─────────────────────────────────────────────
  static const divider        = Color(0xFFEEF0F3);

  // ── Badge Self / Servito ─────────────────────────────────
  static const selfColor      = Color(0xFF1565C0); // Blu — self service
  static const selfBg         = Color(0xFFE3F2FD);
  static const servitoColor   = Color(0xFF2E7D32); // Verde — servito
  static const servitoBg      = Color(0xFFE8F5E9);
}
