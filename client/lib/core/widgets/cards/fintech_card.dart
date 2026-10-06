import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';

class FintechCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BorderSide? border;
  final bool hasGlow;
  final double? width;
  final double? height;

  const FintechCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.border,
    this.hasGlow = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? AppColors.surfaceCard : Colors.white;
    final defaultBorder = isDark ? AppColors.border : AppColors.brandBorder;

    Widget cardContent = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: border?.color ?? (hasGlow ? (isDark ? AppColors.borderGlow : AppColors.primaryGreen.withValues(alpha: 0.3)) : defaultBorder),
          width: border?.width ?? 1,
        ),
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: AppColors.primaryGreen.withValues(alpha: isDark ? 0.08 : 0.12),
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : (isDark ? null : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]),
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          splashColor: AppColors.primaryGreen.withValues(alpha: 0.1),
          highlightColor: AppColors.primaryGreen.withValues(alpha: 0.05),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
