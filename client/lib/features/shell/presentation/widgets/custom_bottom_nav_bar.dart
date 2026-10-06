import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/theme_controller.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController(),
      builder: (context, _) {
        final isDark = ThemeController().isDarkTheme(context);
        final barBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF);
        final barBorder = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

        return Container(
          decoration: BoxDecoration(
            color: barBg,
            border: Border(
              top: BorderSide(color: barBorder, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Container(
              height: AppDimensions.bottomNavHeight,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    context: context,
                    isDark: isDark,
                    index: 0,
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    label: context.tr('nav_home'),
                  ),
                  _buildNavItem(
                    context: context,
                    isDark: isDark,
                    index: 1,
                    icon: Icons.people_alt_outlined,
                    activeIcon: Icons.people_alt_rounded,
                    label: context.tr('nav_customers'),
                  ),
                  _buildNavItem(
                    context: context,
                    isDark: isDark,
                    index: 2,
                    icon: Icons.storefront_outlined,
                    activeIcon: Icons.storefront_rounded,
                    label: context.tr('nav_suppliers'),
                  ),
                  _buildNavItem(
                    context: context,
                    isDark: isDark,
                    index: 3,
                    icon: Icons.analytics_outlined,
                    activeIcon: Icons.analytics_rounded,
                    label: context.tr('nav_reports'),
                  ),
                  _buildNavItem(
                    context: context,
                    isDark: isDark,
                    index: 4,
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings_rounded,
                    label: context.tr('nav_settings'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required bool isDark,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = currentIndex == index;

    final Color activePillBg = isDark
        ? const Color(0xFF1E3A8A)
        : const Color(0xFFDBEAFE);
    final Color activeColor = isDark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF2563EB);
    final Color activeTextColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF1D4ED8);
    final Color inactiveColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap(index);
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? activePillBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  size: 22,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTypography.badge.copyWith(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? activeTextColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
