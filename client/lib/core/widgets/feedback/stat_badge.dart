import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';

enum StatBadgeType { positive, negative, neutral, primary, warning }

class StatBadge extends StatelessWidget {
  final String text;
  final StatBadgeType type;
  final IconData? icon;

  const StatBadge({
    super.key,
    required this.text,
    this.type = StatBadgeType.positive,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;

    switch (type) {
      case StatBadgeType.positive:
        bg = AppColors.primaryGreen.withValues(alpha: 0.12);
        fg = AppColors.primaryGreen;
        border = AppColors.primaryGreen.withValues(alpha: 0.3);
        break;
      case StatBadgeType.negative:
        bg = AppColors.error.withValues(alpha: 0.12);
        fg = AppColors.error;
        border = AppColors.error.withValues(alpha: 0.3);
        break;
      case StatBadgeType.warning:
        bg = AppColors.warning.withValues(alpha: 0.12);
        fg = AppColors.warning;
        border = AppColors.warning.withValues(alpha: 0.3);
        break;
      case StatBadgeType.neutral:
        bg = AppColors.surfaceElevated;
        fg = AppColors.textSecondary;
        border = AppColors.border;
        break;
      case StatBadgeType.primary:
        bg = AppColors.primaryGreen;
        fg = AppColors.background;
        border = AppColors.primaryGreen;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppTypography.badge.copyWith(color: fg, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
