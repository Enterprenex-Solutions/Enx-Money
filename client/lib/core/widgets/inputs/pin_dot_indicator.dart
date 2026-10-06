import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../theme/theme_controller.dart';

class PinDotIndicator extends StatelessWidget {
  final int length;
  final int filledCount;
  final bool isMasked;
  final String? enteredValue;
  final bool hasError;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? borderColor;
  final Color? textColor;

  const PinDotIndicator({
    super.key,
    required this.length,
    required this.filledCount,
    this.isMasked = true,
    this.enteredValue,
    this.hasError = false,
    this.activeColor,
    this.inactiveColor,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController().isDarkTheme(context);
    final effectiveActiveColor = activeColor ?? AppColors.primaryGreen;
    final effectiveInactiveColor = inactiveColor ?? (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0));
    final effectiveBorderColor = borderColor ?? (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1));
    final effectiveTextColor = textColor ?? (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final isFilled = index < filledCount;
        final isCurrent = index == filledCount && !hasError;

        if (!isMasked && enteredValue != null && index < enteredValue!.length) {
          // Box style with readable digit
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 46,
            height: 54,
            decoration: BoxDecoration(
              color: isFilled
                  ? (isDark ? AppColors.surfaceElevated : const Color(0xFFFFFFFF))
                  : (isDark ? AppColors.surface : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError
                    ? AppColors.error
                    : (isCurrent || isFilled ? effectiveActiveColor : effectiveBorderColor),
                width: isCurrent || isFilled ? 1.5 : 1.0,
              ),
              boxShadow: isFilled
                  ? [
                      BoxShadow(
                        color: effectiveActiveColor.withValues(alpha: 0.15),
                        blurRadius: 8,
                      )
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              enteredValue![index],
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: effectiveTextColor,
              ),
            ),
          );
        }

        // Dot / Circle Indicator Style (for App Lock PIN)
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: isFilled ? 18 : 14,
          height: isFilled ? 18 : 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasError
                ? AppColors.error
                : (isFilled ? effectiveActiveColor : effectiveInactiveColor),
            border: Border.all(
              color: hasError
                  ? AppColors.error
                  : (isFilled ? effectiveActiveColor : effectiveBorderColor),
              width: 1.5,
            ),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: (hasError ? AppColors.error : effectiveActiveColor).withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

