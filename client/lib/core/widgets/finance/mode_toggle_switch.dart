import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../finance_mode/finance_mode_service.dart';

class ModeToggleSwitch extends StatelessWidget {
  final FinanceMode? currentMode;
  final ValueChanged<FinanceMode>? onModeChanged;

  const ModeToggleSwitch({
    super.key,
    this.currentMode,
    this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FinanceModeService.instance,
      builder: (context, _) {
        final activeMode = currentMode ?? FinanceModeService.instance.currentMode;
        final isBusiness = activeMode == FinanceMode.business;

        return Container(
          height: 38,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildButton(
                title: 'Business',
                icon: Icons.storefront_rounded,
                isActive: isBusiness,
                activeColor: AppColors.primaryGreen,
                activeTextColor: Colors.black,
                onTap: () {
                  if (onModeChanged != null) {
                    onModeChanged!(FinanceMode.business);
                  } else {
                    FinanceModeService.instance.setMode(FinanceMode.business);
                  }
                },
              ),
              _buildButton(
                title: 'Personal',
                icon: Icons.person_rounded,
                isActive: !isBusiness,
                activeColor: AppColors.accentCyan,
                activeTextColor: Colors.black,
                onTap: () {
                  if (onModeChanged != null) {
                    onModeChanged!(FinanceMode.personal);
                  } else {
                    FinanceModeService.instance.setMode(FinanceMode.personal);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildButton({
    required String title,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required Color activeTextColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? activeTextColor : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                color: isActive ? activeTextColor : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
