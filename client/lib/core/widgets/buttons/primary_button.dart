import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_typography.dart';

class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? disabledBackgroundColor;
  final Color? disabledForegroundColor;
  final double? width;
  final double height;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.disabledBackgroundColor,
    this.disabledForegroundColor,
    this.width,
    this.height = AppDimensions.buttonHeight,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? AppColors.brandBlue;
    final fg = widget.textColor ?? Colors.white;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return Listener(
      onPointerDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onPointerUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onPointerCancel: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: bg.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
        child: ElevatedButton(
          onPressed: isEnabled ? widget.onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            disabledBackgroundColor: widget.disabledBackgroundColor ?? AppColors.surfaceElevated,
            disabledForegroundColor: widget.disabledForegroundColor ?? AppColors.textMuted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          onFocusChange: (focus) {},
          child: widget.isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: fg,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 20, color: fg),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.text,
                        style: AppTypography.labelLarge.copyWith(
                          color: isEnabled ? fg : (widget.disabledForegroundColor ?? AppColors.textMuted),
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    ),
  );
}
}
