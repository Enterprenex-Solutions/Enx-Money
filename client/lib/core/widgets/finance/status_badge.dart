import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

enum BadgeVariant { success, warning, error, info, neutral, gold }

/// Semantic Pill Badge with Glowing Dot Indicator
class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final IconData? icon;
  final bool showDot;

  final bool isLightBackground;
  final Color? customBg;
  final Color? customFg;
  final Color? customBorder;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.neutral,
    this.icon,
    this.showDot = true,
    this.isLightBackground = false,
    this.customBg,
    this.customFg,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color dotColor;
    Color border;

    if (isLightBackground) {
      switch (variant) {
        case BadgeVariant.success:
          bg = const Color(0xFFDCFCE7);
          fg = const Color(0xFF166534);
          dotColor = const Color(0xFF16A34A);
          border = const Color(0xFF86EFAC);
          break;
        case BadgeVariant.warning:
          bg = const Color(0xFFFEF3C7);
          fg = const Color(0xFF92400E);
          dotColor = const Color(0xFFD97706);
          border = const Color(0xFFFCD34D);
          break;
        case BadgeVariant.error:
          bg = const Color(0xFFFEE2E2);
          fg = const Color(0xFF991B1B);
          dotColor = const Color(0xFFDC2626);
          border = const Color(0xFFFCA5A5);
          break;
        case BadgeVariant.info:
          bg = const Color(0xFFDBEAFE);
          fg = const Color(0xFF1E40AF);
          dotColor = const Color(0xFF2563EB);
          border = const Color(0xFF93C5FD);
          break;
        case BadgeVariant.gold:
          bg = const Color(0xFFFEF9C3);
          fg = const Color(0xFF854D0E);
          dotColor = const Color(0xFFCA8A04);
          border = const Color(0xFFFDE047);
          break;
        case BadgeVariant.neutral:
          bg = const Color(0xFFF1F5F9);
          fg = const Color(0xFF1E293B);
          dotColor = const Color(0xFF64748B);
          border = const Color(0xFFCBD5E1);
          break;
      }
    } else {
      switch (variant) {
        case BadgeVariant.success:
          bg = AppColors.success.withValues(alpha: 0.15);
          fg = AppColors.primaryGreen;
          dotColor = AppColors.primaryGreen;
          border = AppColors.success.withValues(alpha: 0.35);
          break;
        case BadgeVariant.warning:
          bg = AppColors.warning.withValues(alpha: 0.15);
          fg = const Color(0xFFFDE68A);
          dotColor = AppColors.warning;
          border = AppColors.warning.withValues(alpha: 0.35);
          break;
        case BadgeVariant.error:
          bg = AppColors.error.withValues(alpha: 0.15);
          fg = const Color(0xFFFCA5A5);
          dotColor = AppColors.error;
          border = AppColors.error.withValues(alpha: 0.35);
          break;
        case BadgeVariant.info:
          bg = AppColors.info.withValues(alpha: 0.15);
          fg = const Color(0xFF93C5FD);
          dotColor = AppColors.info;
          border = AppColors.info.withValues(alpha: 0.35);
          break;
        case BadgeVariant.gold:
          bg = AppColors.accentGold.withValues(alpha: 0.15);
          fg = AppColors.accentGold;
          dotColor = AppColors.accentGold;
          border = AppColors.accentGold.withValues(alpha: 0.35);
          break;
        case BadgeVariant.neutral:
          bg = AppColors.surfaceElevated;
          fg = AppColors.textSecondary;
          dotColor = AppColors.textMuted;
          border = AppColors.border;
          break;
      }
    }

    if (customBg != null) bg = customBg!;
    if (customFg != null) fg = customFg!;
    if (customBorder != null) border = customBorder!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot && icon == null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withValues(alpha: 0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
