import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Premium Luxury Container Card with subtle specular borders, gentle elevation, and optional gradients
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final double elevation;
  final bool isGlass;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.gradient,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 18,
    this.elevation = 0,
    this.isGlass = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? AppColors.surfaceCard : Colors.white;
    final defaultBorder = isDark ? AppColors.border : AppColors.brandBorder;

    final cardContent = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? defaultBg) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? defaultBorder,
          width: 1,
        ),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.05),
                  blurRadius: elevation * 4,
                  offset: Offset(0, elevation * 1.5),
                ),
              ]
            : [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: child,
    );

    if (onTap == null) return cardContent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: AppColors.primaryGreen.withValues(alpha: 0.1),
        highlightColor: AppColors.primaryGreen.withValues(alpha: 0.05),
        child: cardContent,
      ),
    );
  }
}
