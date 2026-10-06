import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_typography.dart';

class FintechTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? hint;
  final String? prefixText;
  final dynamic prefixIcon;
  final dynamic suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool autofocus;
  final FocusNode? focusNode;
  final int? maxLength;
  final int? maxLines;

  const FintechTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.hint,
    this.prefixText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.onChanged,
    this.errorText,
    this.autofocus = false,
    this.focusNode,
    this.maxLength,
    this.maxLines = 1,
  });

  @override
  State<FintechTextField> createState() => _FintechTextFieldState();
}

class _FintechTextFieldState extends State<FintechTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget? resolvedPrefix;
    if (widget.prefixIcon is IconData) {
      resolvedPrefix = Icon(widget.prefixIcon as IconData, color: AppColors.textTertiary);
    } else if (widget.prefixIcon is Widget) {
      resolvedPrefix = widget.prefixIcon as Widget;
    }

    Widget? resolvedSuffix;
    if (widget.suffixIcon is IconData) {
      resolvedSuffix = Icon(widget.suffixIcon as IconData, color: AppColors.textTertiary);
    } else if (widget.suffixIcon is Widget) {
      resolvedSuffix = widget.suffixIcon as Widget;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final hintColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cursorColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.bodySmall.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: widget.errorText != null
                  ? AppColors.error
                  : (_isFocused ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB)) : borderColor),
              width: _isFocused ? 1.5 : 1.0,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB)).withValues(alpha: 0.16),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            onChanged: widget.onChanged,
            maxLength: widget.maxLength,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            style: AppTypography.titleMedium.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: cursorColor,
            decoration: InputDecoration(
              counterText: '',
              hintText: widget.hintText ?? widget.hint,
              hintStyle: AppTypography.bodyMedium.copyWith(color: hintColor),
              prefixIcon: resolvedPrefix,
              prefixText: widget.prefixText,
              prefixStyle: AppTypography.titleMedium.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w700,
              ),
              suffixIcon: resolvedSuffix,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}
