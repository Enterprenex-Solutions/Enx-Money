import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/cards/fintech_card.dart';
import '../../data/profile_repository.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final ProfileRepository _repo = ProfileRepository();

  List<String> get _languages => LocaleController.languageNames;

  void _showThemeSelectionSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentMode = ThemeController().themeMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141824) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose App Theme',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.black54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildThemeOption(
                  ctx: ctx,
                  title: 'Light Theme',
                  subtitle: 'Clean & crisp bright daytime interface',
                  icon: Icons.light_mode_rounded,
                  iconColor: const Color(0xFFFFB300),
                  mode: ThemeMode.light,
                  isSelected: currentMode == ThemeMode.light,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildThemeOption(
                  ctx: ctx,
                  title: 'Dark Theme',
                  subtitle: 'OLED high-contrast night interface',
                  icon: Icons.dark_mode_rounded,
                  iconColor: const Color(0xFF818CF8),
                  mode: ThemeMode.dark,
                  isSelected: currentMode == ThemeMode.dark,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildThemeOption(
                  ctx: ctx,
                  title: 'System Default',
                  subtitle: 'Automatically syncs with your device display setting',
                  icon: Icons.brightness_auto_rounded,
                  iconColor: const Color(0xFF10B981),
                  mode: ThemeMode.system,
                  isSelected: currentMode == ThemeMode.system,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption({
    required BuildContext ctx,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required ThemeMode mode,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () async {
        Navigator.pop(ctx);
        await ThemeController().setThemeMode(mode);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E2638) : const Color(0xFFEFF6FF))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0066FF)
                : (isDark ? const Color(0xFF1F2638) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF0066FF), size: 22)
            else
              Icon(Icons.radio_button_unchecked_rounded,
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), size: 22),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_repo, LocaleController(), ThemeController()]),
      builder: (context, _) {
        final profile = _repo.profile;
        final currentLang = LocaleController().currentLanguageName;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark ? AppColors.background : AppColors.brandBackground;
        final textColor = isDark ? Colors.white : AppColors.brandNavy;
        final subtextColor = isDark ? AppColors.textSecondary : AppColors.brandTextSecondary;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            foregroundColor: textColor,
            centerTitle: true,
            title: Text(
              context.tr('preferences'),
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Theme & Appearance
                  Text(
                    'THEME & APPEARANCE',
                    style: AppTypography.labelSmall.copyWith(
                      letterSpacing: 1.2,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FintechCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () => _showThemeSelectionSheet(context),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            ThemeController().themeMode == ThemeMode.dark
                                ? Icons.dark_mode_rounded
                                : (ThemeController().themeMode == ThemeMode.light
                                    ? Icons.light_mode_rounded
                                    : Icons.brightness_auto_rounded),
                            color: AppColors.primaryGreen,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'App Theme',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ThemeController().themeModeName,
                                style: TextStyle(
                                  color: subtextColor,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? AppColors.textTertiary : AppColors.brandTextMuted,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 2. Notification Preferences
                  Text(
                    context.tr('notification_preferences'),
                    style: AppTypography.labelSmall.copyWith(
                      letterSpacing: 1.2,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  FintechCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Column(
                      children: [
                        _buildSettingSwitch(
                          title: 'Smart Push Notifications',
                          subtitle: 'Instant card swipes, OTPs & security alerts',
                          icon: Icons.notifications_active_outlined,
                          value: profile.pushNotifications,
                          isDark: isDark,
                          onChanged: (val) {
                            _repo.updatePreferences(pushNotifications: val);
                          },
                        ),
                        const Divider(),
                        _buildSettingSwitch(
                          title: 'Email Statements & Reports',
                          subtitle: 'Monthly cashflow and GST-ready invoices',
                          icon: Icons.mark_email_read_outlined,
                          value: profile.emailAlerts,
                          isDark: isDark,
                          onChanged: (val) {
                            _repo.updatePreferences(emailAlerts: val);
                          },
                        ),
                        const Divider(),
                        _buildSettingSwitch(
                          title: 'SMS & WhatsApp Notifications',
                          subtitle: 'Customer ledger payment links & reminders',
                          icon: Icons.sms_outlined,
                          value: profile.smsAlerts,
                          isDark: isDark,
                          onChanged: (val) {
                            _repo.updatePreferences(smsAlerts: val);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 3. Regional and Language
                  Text(
                    context.tr('regional_and_language'),
                    style: AppTypography.labelSmall.copyWith(
                      letterSpacing: 1.2,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  FintechCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.language_rounded, size: 22, color: AppColors.primaryGreen),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr('app_language'),
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    context.tr('choose_language'),
                                    style: TextStyle(
                                      color: subtextColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceElevated : Colors.white,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                            border: Border.all(color: isDark ? AppColors.border : AppColors.brandBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _languages.contains(currentLang)
                                  ? currentLang
                                  : (_languages.contains(profile.selectedLanguage)
                                      ? profile.selectedLanguage
                                      : _languages[0]),
                              isExpanded: true,
                              dropdownColor: isDark ? AppColors.surfaceElevated : Colors.white,
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: isDark ? AppColors.textTertiary : AppColors.brandTextMuted,
                              ),
                              items: _languages.map((lang) {
                                return DropdownMenuItem<String>(
                                  value: lang,
                                  child: Text(
                                    lang,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) async {
                                if (val != null) {
                                  await LocaleController().setLanguage(val);
                                  _repo.updatePreferences(selectedLanguage: val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingSwitch({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.primaryGreen),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtextColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: AppColors.primaryGreen.withValues(alpha: 0.3),
            activeColor: AppColors.primaryGreen,
            inactiveThumbColor: isDark ? AppColors.textTertiary : const Color(0xFF94A3B8),
            inactiveTrackColor: isDark ? AppColors.surfaceElevated : const Color(0xFFE2E8F0),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
