import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/services/app_lock_service.dart';
import '../../../../core/services/secure_credential_vault.dart';
import '../../../../core/widgets/inputs/pin_dot_indicator.dart';
import '../../../../core/widgets/inputs/numeric_keypad.dart';
import '../../data/auth_repository.dart';
import '../../../profile/data/profile_repository.dart';
import 'reset_password_screen.dart';
import 'device_approval_screen.dart';
import 'security_credential_setup_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String? phone;
  final bool isRegistration;
  final bool isForgotPassword;
  final String? name;
  final Map<String, String>? registrationData;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.phone,
    this.isRegistration = false,
    this.isForgotPassword = false,
    this.name,
    this.registrationData,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final AuthRepository _authRepo = AuthRepository();
  String _otp = '';
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  int _countdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown(30);
  }

  void _startCountdown([int seconds = 30]) {
    _countdown = seconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      final digits = data.text!.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isNotEmpty) {
        final code = digits.length > 6 ? digits.substring(0, 6) : digits;
        setState(() {
          _otp = code;
          _hasError = false;
          _errorMessage = null;
        });
        if (_otp.length == 6) {
          _verifyOtp();
        }
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onKeyPressed(String key) {
    if (_otp.length < 6 && !_isLoading) {
      setState(() {
        _otp += key;
        _hasError = false;
        _errorMessage = null;
      });

      if (_otp.length == 6) {
        _verifyOtp();
      }
    }
  }

  void _onDeletePressed() {
    if (_otp.isNotEmpty && !_isLoading) {
      setState(() {
        _otp = _otp.substring(0, _otp.length - 1);
        _hasError = false;
        _errorMessage = null;
      });
    }
  }

  void _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      if (widget.isForgotPassword) {
        // Forgot Password Flow: verify reset OTP and navigate to create new password
        final res = await _authRepo.verifyResetOtp(widget.email, _otp);
        final resetToken = res['resetToken'] as String?;

        if (!mounted) return;

        setState(() => _isLoading = false);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              email: widget.email,
              otp: _otp,
              resetToken: resetToken,
            ),
          ),
        );
      } else if (widget.isRegistration) {
        // Atomic Registration + Verification: verifies email OTP on backend, then advances to Security Setup
        final regData = widget.registrationData;
        final verifiedUser = await _authRepo.verifyOtp(
          widget.email,
          _otp,
          phone: widget.phone ?? regData?['mobile'],
          name: regData?['name'] ?? widget.name,
          businessName: regData?['businessName'],
          password: regData?['password'],
          purpose: 'REGISTRATION',
        );
        ProfileRepository().syncFromUser(verifiedUser);
        try {
          await ProfileRepository().loadProfile(fetchFromApi: true);
        } catch (_) {}

        if (mounted) {
          setState(() => _isLoading = false);
          // Navigate immediately to Mandatory Security Setup (MPIN + Biometrics)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SecurityCredentialSetupScreen(user: verifiedUser),
            ),
          );
        }
      } else {
        // Returning User Email/Phone OTP login flow: verify on backend then restore session and enter Home
        final verifiedUser = await _authRepo.verifyOtp(widget.email, _otp, phone: widget.phone);
        ProfileRepository().syncFromUser(verifiedUser);
        try {
          await ProfileRepository().loadProfile(fetchFromApi: true);
        } catch (_) {}

        if (verifiedUser.accessToken != null && verifiedUser.accessToken!.isNotEmpty) {
          await SecureCredentialVault.instance.saveSessionCredential(
            user: verifiedUser,
            token: verifiedUser.accessToken!,
          );
        }
        await _authRepo.setLoggedIn(true);
        AppLockService.instance.unlock();

        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      }
    } on DeviceApprovalRequiredException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacement(
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
      if (mounted) {
        HapticFeedback.heavyImpact();
        String message = e
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('ApiException: ', '')
            .replaceAll('ValidationException: ', '');
        setState(() {
          _isLoading = false;
          _hasError = true;
          _otp = '';
          _errorMessage = message.isNotEmpty ? message : 'Invalid verification code. Please try again.';
        });
      }
    }
  }

  void _onResendOtp() async {
    if (_countdown > 0 || _isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final res = widget.isForgotPassword
          ? await _authRepo.forgotPassword(widget.email)
          : await _authRepo.resendOtp(
              widget.email,
              phone: widget.phone,
              purpose: widget.isRegistration ? 'REGISTRATION' : 'AUTH',
            );
      final cooldown = (res['cooldownSeconds'] as int?) ?? 60;
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _startCountdown(cooldown);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text(
              (widget.phone != null && widget.phone!.isNotEmpty)
                  ? 'New verification code sent to ${widget.email} and ${widget.phone}'
                  : 'New verification code sent to ${widget.email}',
              style: const TextStyle(color: AppColors.primaryGreen),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: primaryTextColor),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Verify your email',
                      style: AppTypography.displayMedium.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Destination Email details
                    Row(
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: AppTypography.bodyMedium.copyWith(
                                color: secondaryTextColor,
                              ),
                              children: [
                                const TextSpan(text: 'Enter the 6-digit verification code sent to '),
                                TextSpan(
                                  text: widget.email,
                                  style: const TextStyle(
                                    color: AppColors.brandBlue,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.brandBlue),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Change Email',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Security Notice Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : AppColors.brandBlueLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mark_email_read_rounded, color: AppColors.brandBlue, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Please check your inbox (and spam folder) for the 6-digit verification code.',
                              style: TextStyle(
                                color: primaryTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 6-digit Box Indicators
                    Center(
                      child: PinDotIndicator(
                        length: 6,
                        filledCount: _otp.length,
                        isMasked: false,
                        enteredValue: _otp,
                        hasError: _hasError,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Paste Code Button
                    Center(
                      child: InkWell(
                        onTap: _pasteFromClipboard,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.35)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.content_paste_rounded, size: 14, color: AppColors.brandBlue),
                              const SizedBox(width: 6),
                              Text(
                                'Paste Code',
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
                    const SizedBox(height: 16),

                    // Error Alert Message
                    if (_errorMessage != null)
                      Center(
                        child: AnimatedOpacity(
                          opacity: _errorMessage != null ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _errorMessage!,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Resend Timer Row
                    Center(
                      child: _countdown > 0
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer_outlined, size: 16, color: secondaryTextColor),
                                const SizedBox(width: 6),
                                Text(
                                  'Resend code in 00:${_countdown.toString().padLeft(2, '0')}',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: secondaryTextColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : TextButton.icon(
                              onPressed: _onResendOtp,
                              icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.brandBlue),
                              label: Text(
                                'Resend Code',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.brandBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Loading Indicator / Custom Numeric Keypad
            if (_isLoading)
              const SizedBox(
                height: 240,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primaryGreen),
                      SizedBox(height: 16),
                      Text('Verifying code...', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: NumericKeypad(
                  onKeyPressed: _onKeyPressed,
                  onDeletePressed: _onDeletePressed,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
