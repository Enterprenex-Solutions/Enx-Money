import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

const List<String> _webFallbacks = [
  'Segoe UI',
  'Roboto',
  'Inter',
  '-apple-system',
  'BlinkMacSystemFont',
  'Helvetica Neue',
  'Arial',
  'sans-serif',
];

TextStyle _makeFont({
  required TextStyle mobileFont,
  required double fontSize,
  required FontWeight fontWeight,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  if (kIsWeb) {
    return TextStyle(
      fontFamily: '-apple-system',
      fontFamilyFallback: _webFallbacks,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
  return mobileFont;
}

/// Typography definitions with clean sans-serif and monospace numerals for currency
class AppTypography {
  AppTypography._();

  // Headings
  static TextStyle displayLarge = _makeFont(
    mobileFont: GoogleFonts.outfit(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: -0.8,
    ),
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
  );

  static TextStyle displayMedium = _makeFont(
    mobileFont: GoogleFonts.outfit(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: -0.5,
    ),
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle displaySmall = _makeFont(
    mobileFont: GoogleFonts.outfit(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: -0.3,
    ),
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle headingMedium = _makeFont(
    mobileFont: GoogleFonts.outfit(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: -0.2,
    ),
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  // Currency / Balances (Clean mono or bold sans)
  static TextStyle currencyLarge = _makeFont(
    mobileFont: GoogleFonts.spaceGrotesk(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: -0.5,
    ),
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle currencyMedium = _makeFont(
    mobileFont: GoogleFonts.spaceGrotesk(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: -0.2,
    ),
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static TextStyle currencySmall = _makeFont(
    mobileFont: GoogleFonts.spaceGrotesk(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Titles
  static TextStyle titleLarge = _makeFont(
    mobileFont: GoogleFonts.plusJakartaSans(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle titleMedium = _makeFont(
    mobileFont: GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle titleSmall = _makeFont(
    mobileFont: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body
  static TextStyle bodyLarge = _makeFont(
    mobileFont: GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
      height: 1.4,
    ),
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle bodyMedium = _makeFont(
    mobileFont: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
      height: 1.4,
    ),
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle bodySmall = _makeFont(
    mobileFont: GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textTertiary,
    ),
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );

  // Labels & Badges
  static TextStyle labelLarge = _makeFont(
    mobileFont: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: AppColors.textPrimary,
    ),
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: AppColors.textPrimary,
  );

  static TextStyle labelSmall = _makeFont(
    mobileFont: GoogleFonts.plusJakartaSans(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: AppColors.textSecondary,
    ),
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    color: AppColors.textSecondary,
  );

  static TextStyle badge = _makeFont(
    mobileFont: GoogleFonts.spaceGrotesk(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    ),
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
  );
}
