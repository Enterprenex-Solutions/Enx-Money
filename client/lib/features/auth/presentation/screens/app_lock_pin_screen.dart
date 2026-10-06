import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/app_lock_service.dart';
import '../../../../core/services/secure_credential_vault.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/inputs/pin_dot_indicator.dart';
import '../../../../core/widgets/inputs/numeric_keypad.dart';
import '../../../profile/data/profile_repository.dart';
import '../../data/auth_repository.dart';
import '../../data/biometric_service.dart';

class AppLockPinScreen extends StatefulWidget {
  final bool isInitialUnlock;
  final VoidCallback? onUnlocked;

  const AppLockPinScreen({
    super.key,
    this.isInitialUnlock = false,
    this.onUnlocked,
  });

  @override
  State<AppLockPinScreen> createState() => _AppLockPinScreenState();
}

class _AppLockPinScreenState extends State<AppLockPinScreen>
    with SingleTickerProviderStateMixin {
  final AppLockService _appLockService = AppLockService.instance;
  final AuthRepository _authRepo = AuthRepository();

  // Mode: if biometrics is available/enabled, start in biometric mode (_showMpinFallback = false).
  // MPIN UI appears ONLY if biometric authentication is not successfully completed
  // (cancelled, failed, unavailable, not enrolled, or user selects "Use MPIN").
  bool _showMpinFallback = false;
  bool _isAuthenticatingBiometric = false;
  bool _hasUnlocked = false;

  String _pin = '';
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Check biometric setup and auto-prompt native scanner immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndStartBiometrics();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkAndStartBiometrics() async {
    bool isBioConfigured =
        ProfileRepository().profile.isBiometricEnabled || _appLockService.isBiometricEnabled;

    final lastUser = await SecureCredentialVault.instance.getLastUser();
    if (!isBioConfigured && lastUser != null) {
      isBioConfigured =
          await SecureCredentialVault.instance.isBiometricEnabled(lastUser['userId']!);
    }

    if (!isBioConfigured) {
      if (mounted) {
        setState(() {
          _showMpinFallback = true;
        });
      }
      return;
    }

    final status = await BiometricService.instance.checkBiometricStatus();
    if (status != BiometricStatus.available) {
      if (mounted) {
        setState(() {
          _showMpinFallback = true;
          _errorMessage = status == BiometricStatus.notSupported
              ? 'Biometric hardware unavailable. Please enter 4-digit MPIN.'
              : BiometricService.notEnrolledMessage;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _showMpinFallback = false;
      });
      _attemptBiometricAuth(isAutoPrompt: true);
    }
  }

  Future<void> _attemptBiometricAuth({bool isAutoPrompt = false}) async {
    if (_hasUnlocked) return;

    setState(() {
      _isAuthenticatingBiometric = true;
      _errorMessage = null;
    });

    _appLockService.setBiometricPromptActive(true);

    try {
      final status = await BiometricService.instance.checkBiometricStatus();
      if (status != BiometricStatus.available) {
        _appLockService.setBiometricPromptActive(false);
        if (mounted && !_hasUnlocked) {
          setState(() {
            _isAuthenticatingBiometric = false;
            _showMpinFallback = true;
            _errorMessage = status == BiometricStatus.notSupported
                ? 'Biometric hardware unavailable. Please enter 4-digit MPIN.'
                : BiometricService.notEnrolledMessage;
          });
        }
        return;
      }

      final didAuth = await BiometricService.instance.authenticate(
        reason: 'Unlock ENX Money with Biometrics',
        biometricOnly: true,
      );

      _appLockService.setBiometricPromptActive(false);

      if (!mounted || _hasUnlocked) return;

      if (didAuth) {
        // ─────────────────────────────────────────────────────────────────
        // CRITICAL REQUIREMENT:
        // Result is SUCCESS / AUTHENTICATED.
        // Immediately complete unlock and navigate to Home.
        // Do NOT show the MPIN screen.
        // Do NOT ask for second authentication.
        // ─────────────────────────────────────────────────────────────────
        await _completeUnlock();
        return;
      } else {
        // ─────────────────────────────────────────────────────────────────
        // Biometric was cancelled, dismissed, or failed.
        // Fall back to 4-digit MPIN.
        // ─────────────────────────────────────────────────────────────────
        setState(() {
          _isAuthenticatingBiometric = false;
          _showMpinFallback = true;
          _errorMessage = 'Biometric cancelled or failed. Enter 4-digit MPIN.';
        });
      }
    } catch (_) {
      _appLockService.setBiometricPromptActive(false);
      if (mounted && !_hasUnlocked) {
        setState(() {
          _isAuthenticatingBiometric = false;
          _showMpinFallback = true;
          _errorMessage = 'Biometric unavailable. Enter 4-digit MPIN.';
        });
      }
    }
  }

  Future<void> _completeUnlock() async {
    if (_hasUnlocked) return;
    _hasUnlocked = true;

    try {
      // Securely validate and restore session into ApiClient and SharedPreferences
      final lastUser = await SecureCredentialVault.instance.getLastUser();
      if (lastUser != null) {
        final restoredUser = await SecureCredentialVault.instance
            .unlockAndRestoreSession(lastUser['userId']!);
        if (restoredUser != null) {
          ProfileRepository().syncFromUser(restoredUser);
        }
      }
      await _authRepo.setLoggedIn(true);
    } catch (_) {}

    _appLockService.unlock();

    if (!mounted) return;

    if (widget.onUnlocked != null) {
      widget.onUnlocked!();
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  void _onKeyPressed(String key) {
    if (_hasUnlocked || _isLoading) return;
    if (_pin.length < 4) {
      setState(() {
        _pin += key;
        _hasError = false;
        _errorMessage = null;
      });

      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDeletePressed() {
    if (_hasUnlocked || _isLoading) return;
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _hasError = false;
        _errorMessage = null;
      });
    }
  }

  Future<void> _verifyPin() async {
    if (_hasUnlocked) return;
    setState(() => _isLoading = true);

    try {
      bool isValid = false;

      // 1. Check with SecureCredentialVault if user exists
      final lastUser = await SecureCredentialVault.instance.getLastUser();
      if (lastUser != null) {
        final vaultResult = await SecureCredentialVault.instance
            .verifyMpin(lastUser['userId']!, _pin);
        if (vaultResult.isSuccess) {
          isValid = true;
        } else if (vaultResult.isLockedOut) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = vaultResult.message ?? 'MPIN is locked. Please try again later.';
            _pin = '';
          });
          return;
        }
      }

      // 2. Fallback check with AppLockService stored PIN
      if (!isValid) {
        isValid = await _appLockService.verifyPin(_pin);
      }

      if (!mounted || _hasUnlocked) return;

      if (isValid) {
        await _completeUnlock();
      } else {
        HapticFeedback.vibrate();
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Incorrect MPIN. Please try again.';
          _pin = '';
        });
      }
    } catch (e) {
      if (mounted && !_hasUnlocked) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Verification error. Try again.';
          _pin = '';
        });
      }
    }
  }

  void _onForgotPin() {
    final isDark = ThemeController().isDarkTheme(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Forgot App Lock PIN?',
          style: AppTypography.titleLarge.copyWith(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'For your security, if you forgot your 4-digit App Lock PIN, you must sign in again with your registered email and password.',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthRepository().logout();
              _appLockService.onLogout();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: const Text('Log In Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController().isDarkTheme(context);
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final primaryTextColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return PopScope(
      canPop: false, // Cannot bypass lock screen with back button
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Security Shield Badge
                        Container(
                          width: 60,
                          height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cardBgColor,
                  border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.12),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.primaryGreen,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'App Lock',
                style: AppTypography.displaySmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 6),

              Text(
                _showMpinFallback
                    ? 'Enter 4-digit MPIN'
                    : 'Touch the fingerprint sensor to unlock',
                style: AppTypography.bodyMedium.copyWith(
                  color: secondaryTextColor,
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _hasError
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: _hasError ? AppColors.error : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],

              // ─────────────────────────────────────────────────────────────
              // DISPLAY MODE 1: BIOMETRIC UNLOCK (NO MPIN SCREEN VISIBLE)
              // ─────────────────────────────────────────────────────────────
              if (!_showMpinFallback) ...[
                const Spacer(),

                // Animated Biometric Scanner Button
                Center(
                  child: GestureDetector(
                    onTap: () => _attemptBiometricAuth(isAutoPrompt: false),
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 120 * (_isAuthenticatingBiometric ? _scaleAnimation.value : 1.0),
                          height: 120 * (_isAuthenticatingBiometric ? _scaleAnimation.value : 1.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryGreen.withValues(alpha: 0.12),
                            border: Border.all(
                              color: AppColors.primaryGreen.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGreen.withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.fingerprint_rounded,
                              size: 64,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  _isAuthenticatingBiometric
                      ? 'Waiting for Fingerprint / Face ID...'
                      : 'Tap scanner or touch sensor to unlock',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: secondaryTextColor,
                  ),
                ),

                const Spacer(),

                // Secondary button to manually fallback to 4-Digit MPIN
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      setState(() {
                        _showMpinFallback = true;
                      });
                    },
                    icon: Icon(Icons.dialpad_rounded, size: 18, color: primaryTextColor),
                    label: Text(
                      'Use 4-Digit MPIN instead',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextButton(
                  onPressed: _onForgotPin,
                  child: Text(
                    'FORGOT PIN?',
                    style: AppTypography.badge.copyWith(
                      color: secondaryTextColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ]

              // ─────────────────────────────────────────────────────────────
              // DISPLAY MODE 2: 4-DIGIT MPIN FALLBACK (Appears ONLY on cancel/fail/unavailable)
              // ─────────────────────────────────────────────────────────────
              else ...[
                const SizedBox(height: 24),

                // 4-Digit PIN Indicators
                PinDotIndicator(
                  length: 4,
                  filledCount: _pin.length,
                  isMasked: true,
                  hasError: _hasError,
                ),

                const SizedBox(height: 14),

                // Biometrics retry badge button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _attemptBiometricAuth(isAutoPrompt: false),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryGreen.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.fingerprint_rounded, color: AppColors.primaryGreen, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Verify with Biometrics',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Numeric Keypad
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: AppColors.primaryGreen),
                  )
                else
                  NumericKeypad(
                    onKeyPressed: _onKeyPressed,
                    onDeletePressed: _onDeletePressed,
                    showBiometric: true,
                    onBiometricPressed: () => _attemptBiometricAuth(isAutoPrompt: false),
                  ),

                const SizedBox(height: 6),

                TextButton(
                  onPressed: _onForgotPin,
                  child: Text(
                    'FORGOT PIN?',
                    style: AppTypography.badge.copyWith(
                      color: secondaryTextColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  },
),
),
),
);
}
}
