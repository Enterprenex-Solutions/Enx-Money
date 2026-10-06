import 'package:flutter/material.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/app_lock_service.dart';
import '../../../auth/data/biometric_service.dart';
import '../screens/super_admin_dashboard_screen.dart';

class SuperAdminAuthGate {
  /// Static method to prompt Master Admin credentials before opening Super Admin Console
  static Future<void> authenticateAndNavigate(BuildContext context) async {
    // If the app is already unlocked globally, allow immediate navigation without prompt
    if (AppLockService.instance.isAppUnlocked) {
      _navigateToDashboard(context);
      return;
    }

    final isBiometricAvailable = await BiometricService.instance.isBiometricAvailable();

    // 1. Try biometric authentication first if supported on device
    if (isBiometricAvailable) {
      final authenticated = await BiometricService.instance.authenticate(
        reason: 'Super Admin RBAC Authorization: Confirm biometric identity to access Global Analytics',
      );

      if (authenticated && context.mounted) {
        _navigateToDashboard(context);
        return;
      }
    }

    // 2. Fall back to Master Admin Passcode / PIN Dialog
    if (context.mounted) {
      _showAdminPinDialog(context);
    }
  }

  static void _navigateToDashboard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SuperAdminDashboardScreen(),
      ),
    );
  }

  static Future<void> _showAdminPinDialog(BuildContext context) async {
    final pinController = TextEditingController();
    String? errorText;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final dialogBg = isDark ? const Color(0xFF141824) : Colors.white;
            final borderColor = isDark ? const Color(0xFF1F2638) : const Color(0xFFCBD5E1);
            final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

            return Dialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: borderColor, width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Color(0xFF3B82F6),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Super Admin Authorization',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'RBAC Protected • Enter Master Admin Passcode (Default: 9988) or active MPIN to decrypt telemetry.',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // PIN TextField
                    TextField(
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        letterSpacing: 8,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••',
                        hintStyle: TextStyle(
                          fontSize: 22,
                          letterSpacing: 8,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        errorText: errorText,
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0B0E14) : const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF00E676), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: borderColor),
                            ),
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E676),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              final input = pinController.text.trim();
                              final isAppLockMatch = await AppLockService.instance.verifyPin(input);

                              // Validate against Master Admin Passcode '9988' or configured AppLock PIN
                              final isValid = input == '9988' || isAppLockMatch;

                              if (isValid) {
                                if (dialogContext.mounted) Navigator.pop(dialogContext);
                                if (context.mounted) _navigateToDashboard(context);
                              } else {
                                setDialogState(() {
                                  errorText = 'Invalid Passcode. Enter 9988';
                                });
                              }
                            },
                            child: const Text(
                              'Authorize',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
