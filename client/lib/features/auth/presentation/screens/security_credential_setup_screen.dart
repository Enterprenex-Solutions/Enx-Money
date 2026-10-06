import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/app_lock_service.dart';
import '../../../../core/services/secure_credential_vault.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../core/widgets/inputs/numeric_keypad.dart';
import '../../../../core/widgets/inputs/pin_dot_indicator.dart';
import '../../../profile/data/profile_repository.dart';
import '../../data/auth_repository.dart';
import '../../data/biometric_service.dart';
import '../../models/user_model.dart';

/// Mandatory First-Time Security Setup Screen:
/// Step A (Mandatory): Create & Confirm 4-Digit MPIN (stored using salted SHA-256 in secure vault).
/// Step B (Optional): Enable Fingerprint / Face ID with "Enable Biometric" and "Skip for Now".
/// On completion: Activates authenticated session and routes directly to Home Dashboard.
class SecurityCredentialSetupScreen extends StatefulWidget {
  final UserModel user;

  const SecurityCredentialSetupScreen({
    super.key,
    required this.user,
  });

  @override
  State<SecurityCredentialSetupScreen> createState() =>
      _SecurityCredentialSetupScreenState();
}

enum _SetupPhase {
  enterMpin,
  confirmMpin,
  biometricPrompt,
}

class _SecurityCredentialSetupScreenState
    extends State<SecurityCredentialSetupScreen> {
  _SetupPhase _phase = _SetupPhase.enterMpin;
  String _mpin = '';
  String _confirmedMpin = '';
  String? _firstMpin;
  bool _hasError = false;
  String? _errorMessage;
  bool _isProcessing = false;
  String? _biometricUnavailableReason;

  void _onKeyPressed(String key) {
    if (_isProcessing) return;

    if (_phase == _SetupPhase.enterMpin) {
      if (_mpin.length < 4) {
        setState(() {
          _mpin += key;
          _hasError = false;
          _errorMessage = null;
        });
        if (_mpin.length == 4) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              setState(() {
                _firstMpin = _mpin;
                _mpin = '';
                _phase = _SetupPhase.confirmMpin;
              });
            }
          });
        }
      }
    } else if (_phase == _SetupPhase.confirmMpin) {
      if (_confirmedMpin.length < 4) {
        setState(() {
          _confirmedMpin += key;
          _hasError = false;
          _errorMessage = null;
        });
        if (_confirmedMpin.length == 4) {
          _verifyAndSaveMpin();
        }
      }
    }
  }

  void _onDeletePressed() {
    if (_isProcessing) return;

    setState(() {
      _hasError = false;
      _errorMessage = null;
      if (_phase == _SetupPhase.enterMpin && _mpin.isNotEmpty) {
        _mpin = _mpin.substring(0, _mpin.length - 1);
      } else if (_phase == _SetupPhase.confirmMpin && _confirmedMpin.isNotEmpty) {
        _confirmedMpin =
            _confirmedMpin.substring(0, _confirmedMpin.length - 1);
      }
    });
  }

  Future<void> _verifyAndSaveMpin() async {
    if (_confirmedMpin != _firstMpin) {
      HapticFeedback.vibrate();
      setState(() {
        _hasError = true;
        _errorMessage = 'MPINs do not match. Please enter your MPIN again.';
        _mpin = '';
        _confirmedMpin = '';
        _firstMpin = null;
        _phase = _SetupPhase.enterMpin;
      });
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final userId = widget.user.id.toString();

      // 1. Save hashed MPIN with unique cryptographic salt in device vault
      await SecureCredentialVault.instance.saveMpin(userId, _confirmedMpin);
      await AppLockService.instance.enablePin(_confirmedMpin);

      // 2. Persist session credentials in vault
      if (widget.user.accessToken != null && widget.user.accessToken!.isNotEmpty) {
        await SecureCredentialVault.instance.saveSessionCredential(
          user: widget.user,
          token: widget.user.accessToken!,
        );
      }

      // 3. Transition to Step B: Biometric Setup
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _phase = _SetupPhase.biometricPrompt;
        });
        _checkBiometricSupport();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _hasError = true;
          _errorMessage = 'Failed to securely store MPIN. Please try again.';
        });
      }
    }
  }

  Future<void> _checkBiometricSupport() async {
    final status = await BiometricService.instance.checkBiometricStatus();
    if (status == BiometricStatus.notSupported) {
      setState(() {
        _biometricUnavailableReason =
            'Biometric sensor hardware is not available on this device.';
      });
    } else if (status == BiometricStatus.notEnrolled) {
      setState(() {
        _biometricUnavailableReason = BiometricService.notEnrolledMessage;
      });
    }
  }

  Future<void> _enableBiometric() async {
    setState(() => _isProcessing = true);

    try {
      final status = await BiometricService.instance.checkBiometricStatus();
      if (status != BiometricStatus.available) {
        setState(() {
          _isProcessing = false;
          _biometricUnavailableReason = status == BiometricStatus.notSupported
              ? 'Biometric authentication is not supported on this device.'
              : BiometricService.notEnrolledMessage;
        });
        return;
      }

      // Prompt native OS biometric authentication
      final authenticated = await BiometricService.instance.authenticate(
        reason: 'Verify biometric identity to enable fast login',
      );

      if (authenticated) {
        final userId = widget.user.id.toString();
        await SecureCredentialVault.instance.setBiometricEnabled(userId, true);
        await ProfileRepository().updateSecurity(isBiometricEnabled: true);
        _finishSetup();
      } else {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _errorMessage = 'Biometric registration cancelled or not recognized.';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Biometric sensor error. Continuing with MPIN only.';
        });
      }
    }
  }

  void _skipBiometric() {
    _finishSetup();
  }

  Future<void> _finishSetup() async {
    setState(() => _isProcessing = true);

    // Sync profile, unlock app lock session, and navigate directly to Home Dashboard
    ProfileRepository().syncFromUser(widget.user);
    try {
      await ProfileRepository().loadProfile(fetchFromApi: true);
    } catch (_) {}

    await AuthRepository().setLoggedIn(true);
    AppLockService.instance.unlock();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController().isDarkTheme(context);
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryTextColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        automaticallyImplyLeading: _phase == _SetupPhase.confirmMpin,
        leading: _phase == _SetupPhase.confirmMpin
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryTextColor, size: 20),
                onPressed: () {
                  setState(() {
                    _phase = _SetupPhase.enterMpin;
                    _firstMpin = null;
                    _confirmedMpin = '';
                    _mpin = '';
                    _errorMessage = null;
                    _hasError = false;
                  });
                },
              )
            : null,
        title: Text(
          'Security Setup',
          style: AppTypography.headingMedium.copyWith(
            color: primaryTextColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _phase == _SetupPhase.biometricPrompt
            ? _buildBiometricStep(cardBgColor, primaryTextColor, secondaryTextColor)
            : _buildMpinStep(cardBgColor, primaryTextColor, secondaryTextColor),
      ),
    );
  }

  Widget _buildMpinStep(Color cardBgColor, Color primaryTextColor, Color secondaryTextColor) {
    final isConfirm = _phase == _SetupPhase.confirmMpin;
    final activePin = isConfirm ? _confirmedMpin : _mpin;

    return Column(
      children: [
        const SizedBox(height: 20),
        // Step Indicator Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.brandBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.3)),
          ),
          child: Text(
            'STEP 1 OF 2: MANDATORY MPIN',
            style: AppTypography.badge.copyWith(
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isConfirm ? 'Confirm Your 4-Digit MPIN' : 'Create 4-Digit Security MPIN',
          style: AppTypography.displaySmall.copyWith(
            fontWeight: FontWeight.w800,
            color: primaryTextColor,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            isConfirm
                ? 'Re-enter your 4 digits to confirm your security passcode.'
                : 'This MPIN will be required to open your app and authorize sensitive financial transactions.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: secondaryTextColor,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // MPIN Dots
        PinDotIndicator(
          length: 4,
          filledCount: activePin.length,
          isMasked: true,
          hasError: _hasError,
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],

        const Spacer(),

        if (_isProcessing)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(color: AppColors.brandBlue),
          )
        else
          NumericKeypad(
            onKeyPressed: _onKeyPressed,
            onDeletePressed: _onDeletePressed,
            showBiometric: false,
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBiometricStep(Color cardBgColor, Color primaryTextColor, Color secondaryTextColor) {
    final isUnavailable = _biometricUnavailableReason != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          const Spacer(),
          // Biometric Graphic
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardBgColor,
              border: Border.all(
                color: isUnavailable
                    ? AppColors.warning.withValues(alpha: 0.4)
                    : AppColors.brandBlue.withValues(alpha: 0.35),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isUnavailable ? AppColors.warning : AppColors.brandBlue)
                      .withValues(alpha: 0.15),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              isUnavailable ? Icons.fingerprint_rounded : Icons.fingerprint_rounded,
              color: isUnavailable ? AppColors.warning : AppColors.brandBlue,
              size: 52,
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'Enable Fingerprint / Face ID for faster login',
            textAlign: TextAlign.center,
            style: AppTypography.displaySmall.copyWith(
              fontWeight: FontWeight.w800,
              color: primaryTextColor,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isUnavailable
                ? _biometricUnavailableReason!
                : 'Unlock ENX Money instantly using your device\'s built-in biometric sensor without typing your MPIN every time.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: isUnavailable ? AppColors.warning : secondaryTextColor,
              fontSize: 14,
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          const Spacer(),

          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: AppColors.brandBlue),
            )
          else ...[
            if (!isUnavailable) ...[
              PrimaryButton(
                text: 'Enable Biometric',
                onPressed: _enableBiometric,
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                text: 'Skip for Now',
                textColor: primaryTextColor,
                borderColor: secondaryTextColor.withValues(alpha: 0.35),
                onPressed: _skipBiometric,
              ),
            ] else ...[
              PrimaryButton(
                text: 'Continue with MPIN',
                onPressed: _skipBiometric,
              ),
            ],
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
