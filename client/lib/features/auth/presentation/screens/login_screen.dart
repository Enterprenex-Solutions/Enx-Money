import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/app_lock_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/secure_credential_vault.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/fintech_text_field.dart';
import '../../../../core/widgets/inputs/numeric_keypad.dart';
import '../../../../core/widgets/inputs/pin_dot_indicator.dart';
import '../../../profile/data/profile_repository.dart';
import '../../data/auth_repository.dart';
import '../../data/biometric_service.dart';
import 'device_approval_screen.dart';
import 'otp_verification_screen.dart';

/// Unified Returning User Login Screen providing three distinct, secure authentication options:
/// - OPTION A: Email + Password
/// - OPTION B: Email / Phone + OTP
/// - OPTION C: Quick Unlock (Native Biometric or 4-digit MPIN)
class LoginScreen extends StatefulWidget {
  final String? prefilledIdentifier;
  final int initialTabIndex;

  const LoginScreen({
    super.key,
    this.prefilledIdentifier,
    this.initialTabIndex = 0,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthRepository _authRepo = AuthRepository();

  // Option A State
  late final TextEditingController _passwordIdentifierController;
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isPasswordLoading = false;
  String? _passwordIdentifierError;
  String? _passwordError;

  // Option B State
  final _otpIdentifierController = TextEditingController();
  bool _isOtpLoading = false;
  String? _otpIdentifierError;

  // Option C State (Quick Unlock)
  String _mpin = '';
  bool _isMpinLoading = false;
  bool _hasMpinError = false;
  String? _mpinErrorMessage;
  Map<String, String>? _lastUser;
  bool _hasQuickUnlockCredential = false;
  bool _hasAutoPromptedBiometric = false;
  bool _isBiometricLockedOut = false;
  int _biometricFailureCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    _passwordIdentifierController =
        TextEditingController(text: widget.prefilledIdentifier ?? '');

    _tabController.addListener(() {
      if (_tabController.index == 2) {
        _checkQuickUnlockState();
      }
    });

    _checkQuickUnlockState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _passwordIdentifierController.dispose();
    _passwordController.dispose();
    _otpIdentifierController.dispose();
    super.dispose();
  }

  Future<void> _checkQuickUnlockState() async {
    final user = await SecureCredentialVault.instance.getLastUser();
    final hasCredential =
        await SecureCredentialVault.instance.hasStoredCredentialForQuickUnlock();

    if (mounted) {
      setState(() {
        _lastUser = user;
        _hasQuickUnlockCredential = hasCredential;
      });

      if (_tabController.index == 2 &&
          hasCredential &&
          !_hasAutoPromptedBiometric &&
          user != null) {
        final userId = user['userId']!;
        final bioEnabled =
            await SecureCredentialVault.instance.isBiometricEnabled(userId);
        if (bioEnabled) {
          _hasAutoPromptedBiometric = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _authenticateWithBiometrics(userId: userId);
          });
        }
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OPTION A: Email + Password Authentication
  // ─────────────────────────────────────────────────────────────────────────

  bool _validatePasswordForm() {
    bool valid = true;
    setState(() {
      if (_passwordIdentifierController.text.trim().isEmpty) {
        _passwordIdentifierError = 'Please enter your email or mobile number';
        valid = false;
      } else {
        _passwordIdentifierError = null;
      }

      if (_passwordController.text.isEmpty) {
        _passwordError = 'Please enter your password';
        valid = false;
      } else {
        _passwordError = null;
      }
    });
    return valid;
  }

  Future<void> _loginWithPassword() async {
    if (!_validatePasswordForm() || _isPasswordLoading) return;

    setState(() => _isPasswordLoading = true);

    try {
      final identifier = _passwordIdentifierController.text.trim();
      final password = _passwordController.text;

      final success = await _authRepo.loginWithPassword(identifier, password);

      if (success) {
        await _authRepo.setLoggedIn(true);
        final loggedUser = await _authRepo.getLocalUser();
        if (loggedUser != null) {
          ProfileRepository().syncFromUser(loggedUser);
          if (loggedUser.accessToken != null &&
              loggedUser.accessToken!.isNotEmpty) {
            await SecureCredentialVault.instance.saveSessionCredential(
              user: loggedUser,
              token: loggedUser.accessToken!,
            );
          }
        }
        try {
          await ProfileRepository().loadProfile(fetchFromApi: true);
        } catch (_) {}

        AppLockService.instance.unlock();

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        if (!mounted) return;
        NotificationService.showError('Invalid Email/Mobile or Password');
      }
    } on OtpVerificationRequiredException catch (e) {
      if (!mounted) return;
      NotificationService.showWarning(e.message);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(email: e.email),
        ),
      );
    } on DeviceApprovalRequiredException catch (e) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeviceApprovalScreen(
            approvalRequestId: e.approvalRequestId,
            verificationCode: e.verificationCode,
            deviceName: e.deviceName,
            identifier: e.identifier,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e
          .toString()
          .replaceAll('Exception: ', '')
          .replaceAll('ApiException: ', '');
      NotificationService.showError(
        msg.isNotEmpty ? msg : 'Invalid credentials. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isPasswordLoading = false);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OPTION B: Email / Phone + OTP Authentication
  // ─────────────────────────────────────────────────────────────────────────

  bool _validateOtpForm() {
    final input = _otpIdentifierController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _otpIdentifierError = 'Please enter registered email or mobile number';
      });
      return false;
    }
    setState(() => _otpIdentifierError = null);
    return true;
  }

  Future<void> _sendLoginOtp() async {
    if (!_validateOtpForm() || _isOtpLoading) return;

    final input = _otpIdentifierController.text.trim();
    final isEmail = input.contains('@');
    final email = isEmail ? input : '$input@enxmoney.local';
    final phone = isEmail ? null : input;

    setState(() => _isOtpLoading = true);

    try {
      await _authRepo.sendOtp(email, phone: phone, purpose: 'AUTH');

      if (!mounted) return;
      setState(() => _isOtpLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: email,
            phone: phone,
            isRegistration: false,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isOtpLoading = false);
      final msg = e
          .toString()
          .replaceAll('Exception: ', '')
          .replaceAll('ApiException: ', '');
      NotificationService.showError(
        msg.isNotEmpty ? msg : 'Unable to send OTP. Please check your details.',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OPTION C: Quick Unlock (Biometric / 4-Digit MPIN)
  // ─────────────────────────────────────────────────────────────────────────

  void _onMpinKeyPressed(String key) {
    if (_isMpinLoading || _lastUser == null) return;

    if (_mpin.length < 4) {
      setState(() {
        _mpin += key;
        _hasMpinError = false;
        _mpinErrorMessage = null;
      });

      if (_mpin.length == 4) {
        _verifyMpin();
      }
    }
  }

  void _onMpinDeletePressed() {
    if (_isMpinLoading || _lastUser == null) return;

    if (_mpin.isNotEmpty) {
      setState(() {
        _mpin = _mpin.substring(0, _mpin.length - 1);
        _hasMpinError = false;
        _mpinErrorMessage = null;
      });
    }
  }

  Future<void> _verifyMpin() async {
    if (_lastUser == null) return;
    final userId = _lastUser!['userId']!;

    setState(() => _isMpinLoading = true);

    try {
      final result =
          await SecureCredentialVault.instance.verifyMpin(userId, _mpin);

      if (result.isSuccess) {
        // Securely restore authenticated session token into ApiClient
        final user = await SecureCredentialVault.instance
            .unlockAndRestoreSession(userId);

        if (user != null) {
          ProfileRepository().syncFromUser(user);
          try {
            await ProfileRepository().loadProfile(fetchFromApi: true);
          } catch (_) {}

          await _authRepo.setLoggedIn(true);
          AppLockService.instance.unlock();

          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          return;
        } else {
          // Token expired or not present, fall back to password login
          setState(() {
            _isMpinLoading = false;
            _hasMpinError = true;
            _mpinErrorMessage =
                'Session expired. Please sign in with your password.';
            _mpin = '';
          });
        }
      } else {
        HapticFeedback.vibrate();
        setState(() {
          _isMpinLoading = false;
          _hasMpinError = true;
          _mpinErrorMessage = result.message ?? 'Incorrect MPIN. Please try again.';
          _mpin = '';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isMpinLoading = false;
          _hasMpinError = true;
          _mpinErrorMessage = 'Verification error. Please try again.';
          _mpin = '';
        });
      }
    }
  }

  Future<void> _authenticateWithBiometrics({String? userId}) async {
    final targetUserId = userId ?? _lastUser?['userId'];
    if (targetUserId == null) return;

    if (_isBiometricLockedOut) {
      NotificationService.showWarning(
        'Biometrics locked due to multiple failed attempts. Enter your MPIN.',
      );
      return;
    }

    final status = await BiometricService.instance.checkBiometricStatus();
    if (status != BiometricStatus.available) {
      if (mounted) {
        setState(() {
          _mpinErrorMessage = status == BiometricStatus.notSupported
              ? 'Biometric hardware unavailable. Please enter 4-digit MPIN.'
              : BiometricService.notEnrolledMessage;
        });
      }
      return;
    }

    AppLockService.instance.setBiometricPromptActive(true);

    try {
      final success = await BiometricService.instance.authenticate(
        reason: 'Authenticate to access your ENX Money account',
        biometricOnly: true,
      );

      AppLockService.instance.setBiometricPromptActive(false);

      if (success) {
        _biometricFailureCount = 0;
        final user = await SecureCredentialVault.instance
            .unlockAndRestoreSession(targetUserId);

        if (user != null) {
          ProfileRepository().syncFromUser(user);
          try {
            await ProfileRepository().loadProfile(fetchFromApi: true);
          } catch (_) {}

          await _authRepo.setLoggedIn(true);
          AppLockService.instance.unlock();

          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        } else {
          if (mounted) {
            setState(() {
              _mpinErrorMessage =
                  'Stored session expired. Please sign in with password.';
            });
          }
        }
      } else {
        _biometricFailureCount++;
        if (_biometricFailureCount >= 3) {
          setState(() {
            _isBiometricLockedOut = true;
            _mpinErrorMessage =
                'Biometrics locked after 3 failed attempts. Enter 4-digit MPIN.';
          });
        } else {
          setState(() {
            _mpinErrorMessage =
                'Biometric scan cancelled or failed. Enter 4-digit MPIN.';
          });
        }
      }
    } catch (_) {
      AppLockService.instance.setBiometricPromptActive(false);
      if (mounted) {
        setState(() {
          _mpinErrorMessage = 'Biometric scan failed. Enter 4-digit MPIN.';
        });
      }
    }
  }

  void _onForgotMpin() {
    final email = _lastUser?['email'];
    final phone = _lastUser?['phone'];

    if (email == null || email.isEmpty) {
      _tabController.animateTo(0);
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset 4-Digit MPIN'),
        content: Text(
          'To securely reset your MPIN, a verification code will be sent to your registered address:\n\n$email',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _authRepo.sendOtp(email, phone: phone, purpose: 'AUTH');
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OtpVerificationScreen(
                        email: email,
                        phone: phone,
                        isRegistration: true, // Will route to Security Setup upon verification
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  NotificationService.showError(
                    'Failed to send recovery code: $e',
                  );
                }
              }
            },
            child: const Text('Send Verification Code'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD METHOD & THEMED UI
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController().isDarkTheme(context);
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryTextColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
            const SizedBox(height: 16),
            // App Branding Header
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cardBgColor,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandBlue.withValues(alpha: 0.15),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sign In to ENX Money',
              style: AppTypography.displaySmall.copyWith(
                fontWeight: FontWeight.w800,
                color: primaryTextColor,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select your preferred sign-in method',
              style: AppTypography.bodySmall.copyWith(
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 18),

            // 3-Option Segmented Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: AppColors.brandBlue,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: secondaryTextColor,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Password'),
                    Tab(text: 'OTP'),
                    Tab(text: 'Quick Unlock'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // OPTION A: Email + Password
                  _buildPasswordView(cardBgColor, primaryTextColor, secondaryTextColor),
                  // OPTION B: Email / Phone + OTP
                  _buildOtpView(cardBgColor, primaryTextColor, secondaryTextColor),
                  // OPTION C: Quick Unlock (Biometric / MPIN)
                  _buildQuickUnlockView(cardBgColor, primaryTextColor, secondaryTextColor),
                ],
              ),
            ),

            // Bottom Register CTA
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Don\'t have an account? ',
                    style: AppTypography.bodyMedium.copyWith(color: secondaryTextColor),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/create-account');
                    },
                    child: Text(
                      'Create Account',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OPTION A VIEW (Email + Password)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPasswordView(
    Color cardBgColor,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FintechTextField(
            controller: _passwordIdentifierController,
            label: 'EMAIL OR MOBILE NUMBER',
            hintText: 'Enter your registered email or phone',
            prefixIcon: Icons.person_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            errorText: _passwordIdentifierError,
          ),
          const SizedBox(height: 18),
          FintechTextField(
            controller: _passwordController,
            label: 'PASSWORD',
            hintText: 'Enter your account password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            errorText: _passwordError,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: secondaryTextColor,
                size: 20,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/forgot-password');
              },
              child: Text(
                'Forgot Password?',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            text: 'Sign In',
            isLoading: _isPasswordLoading,
            onPressed: _loginWithPassword,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OPTION B VIEW (Email / Phone + OTP)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildOtpView(
    Color cardBgColor,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sign In with One-Time Password',
            style: AppTypography.headingMedium.copyWith(
              color: primaryTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'We will send a 6-digit verification code to your registered email or phone number.',
            style: AppTypography.bodyMedium.copyWith(
              color: secondaryTextColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          FintechTextField(
            controller: _otpIdentifierController,
            label: 'REGISTERED EMAIL OR MOBILE',
            hintText: 'e.g. name@example.com or +919876543210',
            prefixIcon: Icons.dialpad_rounded,
            keyboardType: TextInputType.emailAddress,
            errorText: _otpIdentifierError,
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            text: 'Send OTP',
            isLoading: _isOtpLoading,
            onPressed: _sendLoginOtp,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OPTION C VIEW (Quick Unlock: Biometric / MPIN)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildQuickUnlockView(
    Color cardBgColor,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    if (!_hasQuickUnlockCredential || _lastUser == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cardBgColor,
                  border: Border.all(
                    color: AppColors.brandBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 40,
                  color: AppColors.brandBlue,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Quick Unlock Not Set Up',
                style: AppTypography.titleLarge.copyWith(
                  color: primaryTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Quick unlock with Biometrics or MPIN requires signing in once on this device.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: secondaryTextColor,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Sign In with Password or OTP',
                onPressed: () {
                  _tabController.animateTo(0);
                },
              ),
            ],
          ),
        ),
      );
    }

    final email = _lastUser!['email'] ?? 'User';

    return Column(
      children: [
        const SizedBox(height: 8),
        // User Account Badge Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_circle_rounded, size: 16, color: AppColors.brandBlue),
              const SizedBox(width: 8),
              Text(
                email,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryTextColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Enter 4-Digit MPIN',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w800,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 14),

        // MPIN Dots
        PinDotIndicator(
          length: 4,
          filledCount: _mpin.length,
          isMasked: true,
          hasError: _hasMpinError,
        ),

        const SizedBox(height: 12),

        // Biometric Trigger Button
        InkWell(
          onTap: () => _authenticateWithBiometrics(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fingerprint_rounded, size: 20, color: AppColors.brandBlue),
                const SizedBox(width: 8),
                Text(
                  'Tap to verify Fingerprint / Face ID',
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

        if (_mpinErrorMessage != null) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _hasMpinError || _isBiometricLockedOut
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _mpinErrorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: _hasMpinError || _isBiometricLockedOut
                      ? AppColors.error
                      : AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],

        const Spacer(),

        if (_isMpinLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: CircularProgressIndicator(color: AppColors.brandBlue),
          )
        else
          NumericKeypad(
            onKeyPressed: _onMpinKeyPressed,
            onDeletePressed: _onMpinDeletePressed,
            showBiometric: true,
            onBiometricPressed: () => _authenticateWithBiometrics(),
          ),

        const SizedBox(height: 4),

        TextButton(
          onPressed: _onForgotMpin,
          child: Text(
            'FORGOT MPIN?',
            style: AppTypography.badge.copyWith(
              color: secondaryTextColor,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
