import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../theme/theme_controller.dart';

class NumericKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback? onBiometricPressed;
  final bool showBiometric;
  final Color? keyTextColor;
  final Color? keyBackgroundColor;
  final Color? keyBorderColor;
  final Color? actionColor;

  const NumericKeypad({
    super.key,
    required this.onKeyPressed,
    required this.onDeletePressed,
    this.onBiometricPressed,
    this.showBiometric = false,
    this.keyTextColor,
    this.keyBackgroundColor,
    this.keyBorderColor,
    this.actionColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController().isDarkTheme(context);
    final effectiveTextColor = keyTextColor ?? (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A));
    final effectiveBgColor = keyBackgroundColor ?? (isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF1F5F9));
    final effectiveBorderColor = keyBorderColor ?? (isDark ? const Color(0xFF334155).withValues(alpha: 0.6) : const Color(0xFFCBD5E1));
    final effectiveActionColor = actionColor ?? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('1', effectiveTextColor, effectiveBgColor, effectiveBorderColor),
              _buildKey('2', effectiveTextColor, effectiveBgColor, effectiveBorderColor),
              _buildKey('3', effectiveTextColor, effectiveBgColor, effectiveBorderColor),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('4', effectiveTextColor, effectiveBgColor, effectiveBorderColor),
              _buildKey('5', effectiveTextColor, effectiveBgColor, effectiveBorderColor),
              _buildKey('6', effectiveTextColor, effectiveBgColor, effectiveBorderColor),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('7', effectiveTextColor, effectiveBgColor, effectiveBorderColor),
              _buildKey('8', effectiveTextColor, effectiveBgColor, effectiveBorderColor),
              _buildKey('9', effectiveTextColor, effectiveBgColor, effectiveBorderColor),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Left action (Biometric or empty)
              showBiometric && onBiometricPressed != null
                  ? _buildActionButton(
                      icon: Icons.fingerprint,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onBiometricPressed!();
                      },
                      color: AppColors.primaryGreen,
                    )
                  : const SizedBox(width: 72, height: 72),
              _buildKey('0', effectiveTextColor, effectiveBgColor, effectiveBorderColor),
              // Right action (Backspace)
              _buildActionButton(
                icon: Icons.backspace_outlined,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onDeletePressed();
                },
                color: effectiveActionColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String value, Color textColor, Color bgColor, Color borderColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onKeyPressed(value);
        },
        borderRadius: BorderRadius.circular(36),
        splashColor: AppColors.primaryGreen.withValues(alpha: 0.15),
        highlightColor: AppColors.surfaceElevated,
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: Border.all(color: borderColor),
          ),
          child: Text(
            value,
            style: AppTypography.displaySmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = AppColors.textSecondary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(36),
        splashColor: color.withValues(alpha: 0.15),
        highlightColor: AppColors.surfaceElevated,
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 26),
        ),
      ),
    );
  }
}

