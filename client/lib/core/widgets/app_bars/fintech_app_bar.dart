import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_typography.dart';

class FintechAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? customTitle;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool showAvatar;
  final String? avatarInitials;
  final VoidCallback? onAvatarTap;

  const FintechAppBar({
    super.key,
    this.title,
    this.customTitle,
    this.subtitle,
    this.showBackButton = false,
    this.onBackPressed,
    this.actions,
    this.showAvatar = false,
    this.avatarInitials = 'KS',
    this.onAvatarTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68.0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.background : AppColors.brandBackground;
    final btnBg = isDark ? AppColors.surface : Colors.white;
    final btnBorder = isDark ? AppColors.border : AppColors.brandBorder;
    final iconColor = isDark ? AppColors.pureWhite : AppColors.brandNavy;
    final titleColor = isDark ? Colors.white : AppColors.brandNavy;

    return Container(
      padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 8),
      color: bgColor,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (showBackButton)
              IconButton(
                onPressed: onBackPressed ?? () => Navigator.maybePop(context),
                icon: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: btnBg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(color: btnBorder),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: iconColor,
                  ),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            else if (showAvatar)
              GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.greenGradient,
                    border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.2), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    avatarInitials ?? 'EN',
                    style: AppTypography.badge.copyWith(
                      color: AppColors.background,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: customTitle ??
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (subtitle != null) ...[
                        Text(
                          subtitle!,
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark ? AppColors.textTertiary : AppColors.brandTextSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      if (title != null)
                        Text(
                          title!,
                          style: AppTypography.titleLarge.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
            ),
            ...?actions,
          ],
        ),
      ),
    );
  }
}
