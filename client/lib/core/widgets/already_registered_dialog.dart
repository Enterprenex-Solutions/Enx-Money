import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../../features/auth/presentation/screens/login_screen.dart';

/// Clean, professional modal dialog shown when a user attempts
/// to register with an email address or mobile number that is already registered.
class AlreadyRegisteredDialog extends StatelessWidget {
  /// The matched email address (if applicable)
  final String? email;

  /// The matched phone number (if applicable)
  final String? phone;

  /// Which field matched: 'email', 'phone', or 'both'
  final String? field;

  /// Optional callback invoked when the user clicks 'Login'
  final VoidCallback? onLogin;

  /// Optional callback invoked when the user clicks 'Cancel'
  final VoidCallback? onCancel;

  const AlreadyRegisteredDialog({
    super.key,
    this.email,
    this.phone,
    this.field,
    this.onLogin,
    this.onCancel,
  });

  /// Static helper to display the Already Registered dialog
  static Future<void> show(
    BuildContext context, {
    String? email,
    String? phone,
    String? field,
    VoidCallback? onLogin,
    VoidCallback? onCancel,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => AlreadyRegisteredDialog(
        email: email,
        phone: phone,
        field: field,
        onLogin: onLogin,
        onCancel: onCancel,
      ),
    );
  }

  void _handleLogin(BuildContext context) {
    Navigator.of(context).pop();
    if (onLogin != null) {
      onLogin!();
    } else {
      final identifier = (email != null && email!.trim().isNotEmpty)
          ? email!.trim()
          : (phone != null && phone!.trim().isNotEmpty ? phone!.trim() : null);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(prefilledIdentifier: identifier),
        ),
      );
    }
  }

  void _handleCancel(BuildContext context) {
    Navigator.of(context).pop();
    onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    final hasEmail = email != null && email!.trim().isNotEmpty;
    final hasPhone = phone != null && phone!.trim().isNotEmpty;
    final isPhoneOnly = field == 'phone';
    final isEmailOnly = field == 'email';

    final title = isPhoneOnly
        ? 'Mobile Number Already Registered'
        : (isEmailOnly
            ? 'Email Already Registered'
            : 'This account is already registered.');

    final subtitle = isPhoneOnly
        ? 'This mobile number is already linked to an existing account. Please log in to continue.'
        : 'Please log in to continue using your ENX Money account.';

    final showEmail = hasEmail && !isPhoneOnly;
    final showPhone = hasPhone && !isEmailOnly;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 12,
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Brand Logo & Status Accent
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/images/app_logo.png',
                      height: 38,
                      errorBuilder: (context, error, stackTrace) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.brandBlueLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ENX MONEY',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_pin_circle_rounded,
                        color: AppColors.warning,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Primary Message
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.brandNavy,
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle / Prompt
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    subtitle,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.brandTextSecondary,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Account identifier card (Email or Phone)
                if (showEmail || showPhone)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.brandBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.brandBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showEmail)
                          Row(
                            children: [
                              const Icon(
                                Icons.alternate_email_rounded,
                                size: 16,
                                color: AppColors.brandBlue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  email!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.brandNavy,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        if (showEmail && showPhone) const SizedBox(height: 8),
                        if (showPhone)
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_android_rounded,
                                size: 16,
                                color: AppColors.brandBlue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  phone!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.brandNavy,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Two Action Buttons: [Cancel] and [Login]
                Row(
                  children: [
                    // Cancel Button -> Close popup & remain on Signup
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.brandTextSecondary,
                          side: const BorderSide(color: AppColors.brandBorder, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _handleCancel(context),
                        child: Text(
                          'Cancel',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.brandTextSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Login Button -> Redirect to Login page
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _handleLogin(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.login_rounded, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Login',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
