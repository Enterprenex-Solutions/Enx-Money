import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_bars/fintech_app_bar.dart';
import '../../../../core/widgets/cards/fintech_card.dart';
import '../../../../core/widgets/feedback/stat_badge.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/services/app_lock_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/profile_repository.dart';
import '../widgets/profile_modals.dart';
import 'edit_personal_info_screen.dart';
import 'edit_business_profile_screen.dart';
import 'security_settings_screen.dart';
import 'preferences_screen.dart';
import 'data_and_privacy_screen.dart';
import '../../../auth/presentation/screens/security_questions_setup_screen.dart';
import '../../../analytics/presentation/screens/analytics_dashboard_screen.dart';
import '../../../ai/presentation/screens/meta_ai_chat_screen.dart';
import '../../../../core/utils/app_image_util.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileRepository _repo = ProfileRepository();
  final AuthRepository _authRepo = AuthRepository();

  @override
  void initState() {
    super.initState();
    _repo.loadProfile(fetchFromApi: true);
  }

  void _onLogout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            'Log out from ENX Money?',
            style: AppTypography.titleLarge,
          ),
          content: Text(
            'You will need your registered credentials or security verification code to log back in.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('cancel'), style: AppTypography.badge.copyWith(color: AppColors.textTertiary)),
            ),
            TextButton(
              onPressed: () async {
                await _authRepo.logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              },
              child: Text(
                context.tr('log_out'),
                style: AppTypography.badge.copyWith(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.brandBackground,
      appBar: FintechAppBar(
        title: context.tr('account_business'),
        subtitle: context.tr('nav_profile').toUpperCase(),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([_repo, ThemeController(), AppLockService.instance]),
        builder: (context, _) {
          final profile = _repo.profile;
          final completion = profile.completionPercentage;
          final missing = profile.missingFields;
          final business = profile.businessProfile;

          return RefreshIndicator(
            onRefresh: () => _repo.loadProfile(fetchFromApi: true),
            color: AppColors.primaryGreen,
            backgroundColor: AppColors.surfaceElevated,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // 1. User Profile Hero Card
                FintechCard(
                  hasGlow: true,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primaryGreen, width: 2),
                              image: profile.profilePhoto.isNotEmpty && getAppImageProvider(profile.profilePhoto) != null
                                  ? DecorationImage(
                                      image: getAppImageProvider(profile.profilePhoto)!,
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              gradient: (profile.profilePhoto.isEmpty || getAppImageProvider(profile.profilePhoto) == null) ? AppColors.greenGradient : null,
                            ),
                            alignment: Alignment.center,
                            child: (profile.profilePhoto.isEmpty || getAppImageProvider(profile.profilePhoto) == null)
                                ? Text(
                                    profile.initials,
                                    style: AppTypography.displaySmall.copyWith(
                                      color: AppColors.background,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceElevated,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_user_rounded,
                                size: 16,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.fullName,
                              style: AppTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.pureWhite : AppColors.brandNavy,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              profile.email,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.textSecondary : AppColors.brandTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile.mobileNumber,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.textTertiary : AppColors.brandTextMuted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 8),
                            StatBadge(
                              text: profile.isEmailVerified ? context.tr('verified') : context.tr('not_verified'),
                              type: profile.isEmailVerified ? StatBadgeType.positive : StatBadgeType.warning,
                              icon: profile.isEmailVerified ? Icons.verified_rounded : Icons.pending_outlined,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Profile Completion Progress Bar & "Complete Profile" Banner
                FintechCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  completion == 100 ? Icons.check_circle_rounded : Icons.pie_chart_rounded,
                                  color: completion == 100 ? const Color(0xFF10B981) : AppColors.brandBlue,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    completion == 100 ? 'Profile Complete: 100%' : 'Complete Profile: $completion%',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (completion < 100)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (!profile.isPersonalComplete) {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EditPersonalInfoScreen()));
                                  } else if (!profile.isBusinessComplete) {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EditBusinessProfileScreen()));
                                  } else {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()));
                                  }
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandBlue,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.brandBlue.withValues(alpha: 0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Complete Profile',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                        ),
                                      ),
                                      SizedBox(width: 2),
                                      Icon(Icons.chevron_right_rounded, color: Colors.black, size: 14),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                                  SizedBox(width: 4),
                                  Text(
                                    '100% COMPLETE',
                                    style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        completion == 100
                            ? 'Your account profile and business details are fully completed.'
                            : 'Personalize your business experience & unlock fast checkout tools',
                        softWrap: true,
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: completion / 100,
                          backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            completion == 100 ? const Color(0xFF10B981) : AppColors.brandBlue,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      if (missing.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Suggested profile additions you can add anytime:',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: missing.map((item) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_circle_outline_rounded, size: 12, color: AppColors.brandBlue),
                                  const SizedBox(width: 4),
                                  Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2.5 Digital Identity & Government KYC Section
                _buildSectionHeader('Digital Identity & Government KYC'),
                const SizedBox(height: 10),
                FintechCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      _buildSummaryTile(
                        icon: Icons.verified_user_rounded,
                        title: 'Digital Identity & KYC Hub',
                        subtitle: 'Aadhaar e-KYC, PAN, Biometrics & DigiLocker',
                        badge: 'TIER 3 ACTIVE',
                        onTap: () {
                          Navigator.pushNamed(context, '/digital-identity-kyc');
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Personal Information Section
                _buildSectionHeader(context.tr('personal_info')),
                const SizedBox(height: 10),
                FintechCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      _buildSummaryTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Personal Details',
                        subtitle: '${profile.fullName} • ${profile.selectedLanguage}',
                        badge: 'EDIT',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EditPersonalInfoScreen()),
                          );
                        },
                      ),
                      const Divider(),
                      _buildInfoRow('Email Address', profile.email,
                          isVerified: profile.isEmailVerified, allowWrap: true),
                      const Divider(),
                      _buildInfoRow('Mobile Number', profile.mobileNumber,
                          isVerified: profile.isMobileVerified),
                      if (profile.dateOfBirth.isNotEmpty) ...[
                        const Divider(),
                        _buildInfoRow('Date of Birth', profile.dateOfBirth),
                      ],
                      if (profile.gender.isNotEmpty) ...[
                        const Divider(),
                        _buildInfoRow('Gender', profile.gender),
                      ],
                      if (profile.addressCity.isNotEmpty || profile.addressState.isNotEmpty) ...[
                        const Divider(),
                        _buildInfoRow(
                          'Address',
                          [
                            if (profile.addressCity.isNotEmpty) profile.addressCity,
                            if (profile.addressDistrict.isNotEmpty) profile.addressDistrict,
                            if (profile.addressState.isNotEmpty) profile.addressState,
                            if (profile.addressPincode.isNotEmpty) profile.addressPincode,
                          ].join(', '),
                          allowWrap: true,
                        ),
                      ],
                      const Divider(),
                      _buildInfoRow('Preferred Language', profile.selectedLanguage),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 4. Business Profile Section
                _buildSectionHeader(context.tr('business_profile')),
                const SizedBox(height: 10),
                FintechCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      _buildSummaryTile(
                        icon: Icons.business_center_outlined,
                        title: business.businessName.isNotEmpty
                            ? business.businessName
                            : 'Setup Business Profile',
                        subtitle: '${business.businessType} • ${business.businessSize}',
                        badge: 'EDIT',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EditBusinessProfileScreen()),
                          );
                        },
                      ),
                      if (business.businessContactNumber.isNotEmpty) ...[
                        const Divider(),
                        _buildInfoRow('Business Contact', business.businessContactNumber),
                      ],
                      if (business.businessEmail.isNotEmpty) ...[
                        const Divider(),
                        _buildInfoRow('Business Email', business.businessEmail, allowWrap: true),
                      ],
                      const Divider(),
                      _buildInfoRow('Industry Category', business.businessCategory),
                      const Divider(),
                      _buildInfoRow(
                        'GST Status',
                        business.hasGst ? (business.gstin ?? 'Yes (Pending GSTIN)') : 'Not Applicable (No GST)',
                        isGst: business.hasGst,
                      ),
                      const Divider(),
                      _buildInfoRow(
                        'Business Address',
                        business.businessAddress.isNotEmpty
                            ? business.businessAddress
                            : 'Not set yet',
                        allowWrap: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 5. Security & Access Section
                _buildSectionHeader(context.tr('security_settings')),
                const SizedBox(height: 10),
                FintechCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      _buildSummaryTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Security Settings',
                        subtitle: 'Password, MPIN, Biometrics & Recovery',
                        badge: AppLockService.instance.isLockEnabled ? 'PIN ACTIVE' : 'MANAGE',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()),
                          );
                        },
                      ),
                      const Divider(),
                      _buildSettingTile(
                        title: 'Account Password',
                        subtitle: 'Update your account login password',
                        icon: Icons.key_rounded,
                        trailingBadge: 'UPDATE',
                        onTap: () => ProfileModals.showChangePasswordModal(context),
                      ),
                      const Divider(),
                      _buildSettingTile(
                        title: AppLockService.instance.isLockEnabled ? 'Change MPIN / Lock PIN' : 'Set Up MPIN / Lock PIN',
                        subtitle: AppLockService.instance.isLockEnabled
                            ? 'Update your 4-digit security PIN'
                            : 'Require 4-digit PIN to access app',
                        icon: Icons.pin_outlined,
                        trailingBadge: AppLockService.instance.isLockEnabled ? 'ENABLED' : 'OFF',
                        onTap: () {
                          if (AppLockService.instance.isLockEnabled) {
                            ProfileModals.showChangePinModal(context);
                          } else {
                            ProfileModals.showSetPinModal(context);
                          }
                        },
                      ),
                      const Divider(),
                      _buildSettingTile(
                        title: 'Biometric / Fingerprint',
                        subtitle: profile.isBiometricEnabled
                            ? 'Biometric unlock active'
                            : 'Fast fingerprint / Face ID access',
                        icon: Icons.fingerprint_rounded,
                        trailingBadge: profile.isBiometricEnabled ? 'ENABLED' : 'OFF',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()),
                          );
                        },
                      ),
                      const Divider(),
                      _buildSettingTile(
                        title: 'Security & Recovery Questions',
                        subtitle: profile.hasSecurityQuestions
                            ? 'Update your 2 recovery questions'
                            : 'Reset password or recover account without OTP',
                        icon: Icons.help_outline_rounded,
                        trailingBadge: profile.hasSecurityQuestions ? 'UPDATE' : 'SET UP',
                        onTap: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SecurityRecoveryQuestionsScreen(),
                            ),
                          );
                          if (result == true && mounted) {
                            NotificationService.showSuccess('Security recovery questions saved!');
                            await ProfileRepository().loadProfile();
                            setState(() {});
                          }
                        },
                      ),
                      const Divider(),
                      _buildSettingTile(
                        title: 'Active Login Sessions',
                        subtitle: '${profile.activeDevices.length} device(s) logged in',
                        icon: Icons.devices_rounded,
                        onTap: () => ProfileModals.showActiveDevicesSheet(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 6. Preferences Section
                _buildSectionHeader(context.tr('preferences')),
                const SizedBox(height: 10),
                FintechCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      _buildSummaryTile(
                        icon: Icons.tune_rounded,
                        title: 'Theme, Notifications & Language',
                        subtitle: '${ThemeController().themeModeName} • ${profile.selectedLanguage}',
                        badge: 'CONFIGURE',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PreferencesScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 6b. Analytics & Data Analysis Section
                _buildSectionHeader('ANALYTICS & DATA ANALYSIS'),
                const SizedBox(height: 10),
                FintechCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      _buildSummaryTile(
                        icon: Icons.analytics_outlined,
                        title: 'Data Analysis & Insights',
                        subtitle: 'Visual business KPIs, revenue, cashflow & ledger trends',
                        badge: 'VIEW',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AnalyticsDashboardScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 6c. Meta AI Assistant Section
                _buildSectionHeader('AI BUSINESS ADVISOR'),
                const SizedBox(height: 10),
                FintechCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      _buildSummaryTile(
                        icon: Icons.auto_awesome_rounded,
                        title: context.tr('meta_ai_title'),
                        subtitle: context.tr('meta_ai_subtitle'),
                        badge: 'LIVE CHAT',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MetaAiChatScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 7. Help, Privacy, Terms & Logout
                _buildSectionHeader(context.tr('support_and_legal')),
                const SizedBox(height: 10),
                FintechCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      _buildSettingTile(
                        title: '24/7 Priority Concierge & FAQ',
                        subtitle: 'Instant support & common questions',
                        icon: Icons.headset_mic_outlined,
                        onTap: () => ProfileModals.showHelpAndSupportModal(context),
                      ),
                      const Divider(),
                      _buildSettingTile(
                        title: 'Data & Privacy Dashboard',
                        subtitle: 'Audited data practices, rights & legal center',
                        icon: Icons.shield_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const DataAndPrivacyScreen()),
                          );
                        },
                      ),
                      const Divider(),
                      _buildSettingTile(
                        title: 'Privacy Policy',
                        subtitle: 'How we encrypt and protect your data',
                        icon: Icons.privacy_tip_outlined,
                        onTap: () => ProfileModals.showPrivacyPolicyModal(context),
                      ),
                      const Divider(),
                      _buildSettingTile(
                        title: 'Terms & Conditions',
                        subtitle: 'User agreement, non-marketplace & accounting terms',
                        icon: Icons.description_outlined,
                        onTap: () => ProfileModals.showTermsModal(context),
                      ),
                      const Divider(),
                      _buildSettingTile(
                        title: 'Refund & Cancellation Policy',
                        subtitle: 'Google Play billing & subscription terms',
                        icon: Icons.receipt_long_outlined,
                        onTap: () => ProfileModals.showRefundPolicyModal(context),
                      ),
                      const Divider(),
                      _buildSettingTile(
                        title: 'Contact & Support',
                        subtitle: 'Official helpline, billing & grievance redressal',
                        icon: Icons.support_agent_rounded,
                        onTap: () => Navigator.pushNamed(context, '/support'),
                      ),
                      const Divider(),
                      _buildSettingTile(
                        title: context.tr('log_out'),
                        subtitle: 'Securely sign out of this device',
                        icon: Icons.logout_rounded,
                        iconColor: AppColors.error,
                        textColor: AppColors.error,
                        onTap: _onLogout,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),
              ],
            ),
          ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(
        letterSpacing: 1.4,
        fontSize: 11,
        // #94A3B8 in dark, #64748B in light — crisp mid-grey contrast
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      ),
    );
  }

  Widget _buildSummaryTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primaryGreen, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.pureWhite : AppColors.brandNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.textSecondary : AppColors.brandTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceElevated : AppColors.brandBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.border : AppColors.brandBorder),
                ),
                child: Text(
                  badge,
                  style: AppTypography.badge.copyWith(color: AppColors.primaryGreen, fontSize: 10),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool? isVerified, bool? isGst, bool allowWrap = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayValue = value.trim().isEmpty ? '—' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                // #94A3B8 tertiary in dark, brand secondary in light
                color: isDark ? const Color(0xFF94A3B8) : AppColors.brandTextSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    displayValue,
                    style: AppTypography.bodyMedium.copyWith(
                      // Crisp #FFFFFF in dark, deep slate in light
                      color: isDark ? const Color(0xFFFFFFFF) : AppColors.brandNavy,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.end,
                    // Allow long emails to wrap to next line cleanly
                    maxLines: allowWrap ? 2 : 1,
                    overflow: allowWrap ? TextOverflow.visible : TextOverflow.ellipsis,
                    softWrap: allowWrap,
                  ),
                ),
                if (isVerified == true) ...[
                  const SizedBox(width: 6),
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = AppColors.primaryGreen,
    Color? textColor,
    String? trailingBadge,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveTextColor = textColor ?? (isDark ? AppColors.pureWhite : AppColors.brandNavy);
    final effectiveSubtitleColor = isDark ? AppColors.textSecondary : AppColors.brandTextSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleSmall.copyWith(color: effectiveTextColor)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.bodySmall.copyWith(color: effectiveSubtitleColor)),
                  ],
                ),
              ),
              if (trailingBadge != null)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: trailingBadge == 'ENABLED'
                        ? AppColors.primaryGreen.withValues(alpha: 0.15)
                        : (isDark ? AppColors.surfaceElevated : AppColors.brandBackground),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: trailingBadge == 'ENABLED'
                          ? AppColors.primaryGreen.withValues(alpha: 0.4)
                          : (isDark ? AppColors.border : AppColors.brandBorder),
                    ),
                  ),
                  child: Text(
                    trailingBadge,
                    style: AppTypography.badge.copyWith(
                      color: trailingBadge == 'ENABLED' ? AppColors.primaryGreen : AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
