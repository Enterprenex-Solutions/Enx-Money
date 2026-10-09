import 'package:flutter/material.dart';

/// App Color Palette inspired by CRED & Walnut (Pitch Black, Vibrant Emerald/Mint, Crisp White, Slate Accents)
class AppColors {
  AppColors._();

  // Primary Backgrounds & Surfaces (Clean Minimalist White & Blue Design System)
  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceCard = Color(0xFFFFFFFF);

  // Dark Theme Alternative Tokens (when dark mode is explicitly enabled)
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);

  // Official ENX Money Brand Colors (Professional Vibrant Blue & Navy)
  static const Color brandBlue = Color(0xFF0066FF);
  static const Color brandBlueDark = Color(0xFF0047BA);
  static const Color brandBlueLight = Color(0xFFEFF6FF);
  static const Color brandNavy = Color(0xFF0F172A);
  static const Color brandNavyLight = Color(0xFF1E293B);
  static const Color brandCyan = Color(0xFF00D2FF);
  static const Color brandBackground = Color(0xFFF8FAFC);
  static const Color brandSurface = Color(0xFFFFFFFF);
  static const Color brandBorder = Color(0xFFE2E8F0);
  static const Color brandText = Color(0xFF0F172A);
  static const Color brandTextSecondary = Color(0xFF475569);
  static const Color brandTextMuted = Color(0xFF64748B);

  // Vibrant Brand Accents
  static const Color primaryGreen = Color(0xFF0066FF); // Brand Azure Blue for primary actions
  static const Color primaryGreenHover = Color(0xFF0052CC);
  static const Color emeraldGlow = Color(0x220066FF);
  static const Color mintLight = Color(0xFFEFF6FF);
  static const Color successMint = Color(0xFF10B981);

  // Secondary Accents
  static const Color accentNeon = Color(0xFF0066FF);
  static const Color accentCyan = Color(0xFF0066FF);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentGold = Color(0xFFF59E0B);

  // High-Contrast Modern Typography Neutrals
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderGlow = Color(0x330066FF);
  static const Color divider = Color(0xFFE2E8F0);

  // Status Indicators
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF0066FF), Color(0xFF0047BA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandBlueCyanGradient = LinearGradient(
    colors: [Color(0xFF0066FF), Color(0xFF00D2FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandNavyGradient = LinearGradient(
    colors: [Color(0xFF0A1931), Color(0xFF152A4A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF0066FF), Color(0xFF0052CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardLuxuryGradient = LinearGradient(
    colors: [Color(0xFF1D2433), Color(0xFF11151F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardPlatinumGradient = LinearGradient(
    colors: [Color(0xFF2B3245), Color(0xFF151922)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGlowGradient = LinearGradient(
    colors: [Color(0x2200E599), Colors.transparent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Dynamic Theme Helpers (Strict Token Specifications)
  static Color surfaceBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

  static Color cardContainer(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);

  static Color primaryText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);

  static Color secondaryText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

  static Color inputBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

  static Color cursorColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);

  static Color placeholder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  // Overloads for bool isDark
  static Color surfaceBackgroundOf(bool isDark) =>
      isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

  static Color cardContainerOf(bool isDark) =>
      isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);

  static Color primaryTextOf(bool isDark) =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);

  static Color secondaryTextOf(bool isDark) =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

  static Color inputBorderOf(bool isDark) =>
      isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

  static Color cursorColorOf(bool isDark) =>
      isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);

  static Color placeholderOf(bool isDark) =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
}
