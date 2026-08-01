import 'package:flutter/material.dart';

/// Official SpazaLink brand colour palette.
///
/// All values extracted from the official SpazaLink logo:
/// — "Spaza" wordmark: dark forest green
/// — Chain icon top link: primary green
/// — Chain icon bottom link + "Link" wordmark: brand gold
/// — Vertical divider: brand gold
/// — Tagline: dark forest green
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────

  /// Darkest brand green — used in the "Spaza" wordmark and tagline.
  /// Official brand palette (spazalink.co.za): dark-green.
  static const Color brandGreenDark = Color(0xFF066837);

  /// Primary brand green — used in the chain icon and primary UI elements.
  /// Official brand palette: primary-green.
  static const Color brandGreenPrimary = Color(0xFF0B8F47);

  /// Medium green — headers, active states.
  static const Color brandGreenMedium = Color(0xFF0FA050);

  /// Light green — highlights on the chain icon, hover states.
  static const Color brandGreenLight = Color(0xFF34C471);

  /// Very light green tint — surface backgrounds.
  static const Color brandGreenSurface = Color(0xFFE8F5E9);

  /// Extra-light green — card backgrounds in light mode.
  static const Color brandGreenSurfaceLight = Color(0xFFF1F8F2);

  /// Brand gold — used in the "Link" wordmark, chain bottom link, divider.
  /// Official brand palette: gold.
  static const Color brandGold = Color(0xFFF5B301);

  /// Lighter gold — highlights, savings callouts.
  static const Color brandGoldLight = Color(0xFFFDD835);

  /// Gold surface tint — backgrounds for gold callouts.
  static const Color brandGoldSurface = Color(0xFFFFF8E1);

  // ── Light Mode ─────────────────────────────────────────────────────────────

  static const Color lightBackground = Color(0xFFF4F7F4);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEBF0EC);
  static const Color lightOnSurface = Color(0xFF1A2B1F);
  static const Color lightOnSurfaceVariant = Color(0xFF4A5E4E);
  static const Color lightOutline = Color(0xFFD0DDD2);
  static const Color lightOutlineVariant = Color(0xFFE5EDE7);
  static const Color lightScrim = Color(0x801A2B1F);

  // ── Dark Mode ──────────────────────────────────────────────────────────────

  static const Color darkBackground = Color(0xFF0F1A12);
  static const Color darkSurface = Color(0xFF1A2B1F);
  static const Color darkSurfaceVariant = Color(0xFF213328);
  static const Color darkOnSurface = Color(0xFFE2EDE4);
  static const Color darkOnSurfaceVariant = Color(0xFFA8BFAA);
  static const Color darkOutline = Color(0xFF2D4535);
  static const Color darkOutlineVariant = Color(0xFF3A5540);

  // ── Admin Dark Theme ───────────────────────────────────────────────────────

  /// Admin dashboard uses a distinct navy-dark background (from mockup screen 13).
  static const Color adminDarkBackground = Color(0xFF0B1120);
  static const Color adminDarkSurface = Color(0xFF151F30);
  static const Color adminDarkSurfaceVariant = Color(0xFF1E2C42);
  static const Color adminDarkOutline = Color(0xFF2A3A55);

  // ── Semantic ───────────────────────────────────────────────────────────────

  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFF57C00);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFC62828);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF1565C0);
  static const Color infoLight = Color(0xFFE3F2FD);

  // ── Order Status ───────────────────────────────────────────────────────────

  static const Color statusPending = Color(0xFF78909C);
  static const Color statusConfirmed = Color(0xFF1565C0);
  static const Color statusPacked = Color(0xFFF57C00);
  static const Color statusOutForDelivery = Color(0xFF8E24AA);
  static const Color statusDelivered = Color(0xFF2E7D32);
  static const Color statusCancelled = Color(0xFFC62828);

  // ── Shop Status ────────────────────────────────────────────────────────────

  static const Color shopPending = Color(0xFFF57C00);
  static const Color shopApproved = Color(0xFF2E7D32);
  static const Color shopRejected = Color(0xFFC62828);
  static const Color shopSuspended = Color(0xFF78909C);

  // ── Sync Status ────────────────────────────────────────────────────────────

  static const Color syncPending = Color(0xFFF9A825);
  static const Color syncSyncing = Color(0xFF1565C0);
  static const Color syncSent = Color(0xFF2E7D32);
  static const Color syncFailed = Color(0xFFC62828);

  // ── Utility ────────────────────────────────────────────────────────────────

  static const Color transparent = Colors.transparent;
  static const Color white = Colors.white;
  static const Color black = Colors.black;
}
