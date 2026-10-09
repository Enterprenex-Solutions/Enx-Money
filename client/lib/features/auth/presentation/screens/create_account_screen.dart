import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/fintech_text_field.dart';

import '../../data/auth_repository.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/presentation/widgets/profile_modals.dart';
import '../../../../core/widgets/already_registered_dialog.dart';
import 'otp_verification_screen.dart';
import 'security_credential_setup_screen.dart';

/// Registration: Collects Name, Email, Mobile, Password, Confirm Password.
/// Sends OTP after validation, then proceeds to OTP verification.
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authRepo = AuthRepository();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;

  bool _isEmailVerified = false;
  bool _isMobileVerified = false;
  bool _isSendingEmailOtp = false;
  bool _isSendingMobileOtp = false;

  String? _nameError;
  String? _businessNameError;
  String? _emailError;
  String? _mobileError;
  String? _passwordError;
  String? _confirmError;
  String? _termsError;

  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    final pwd = _passwordController.text;
    setState(() {
      _hasMinLength = pwd.length >= 8;
      _hasUppercase = pwd.contains(RegExp(r'[A-Z]'));
      _hasNumber = pwd.contains(RegExp(r'[0-9]'));
      if (_passwordError != null) _passwordError = null;
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _nameController.dispose();
    _businessNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      // Name
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        _nameError = 'Please enter your full name';
        valid = false;
      } else if (name.length < 2) {
        _nameError = 'Name must be at least 2 characters';
        valid = false;
      } else {
        _nameError = null;
      }

      // Business Name
      final bName = _businessNameController.text.trim();
      if (bName.isEmpty) {
        _businessNameError = 'Please enter your business or company name';
        valid = false;
      } else if (bName.length < 2) {
        _businessNameError = 'Business name must be at least 2 characters';
        valid = false;
      } else {
        _businessNameError = null;
      }

      // Email
      final email = _emailController.text.trim();
      final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
      if (email.isEmpty) {
        _emailError = 'Please enter your email address';
        valid = false;
      } else if (!emailRegex.hasMatch(email)) {
        _emailError = 'Please enter a valid email address';
        valid = false;
      } else {
        _emailError = null;
      }

      // Mobile
      final mobile = _mobileController.text.trim();
      final phoneRegex = RegExp(r'^\+?[0-9]{10,12}$');
      if (mobile.isEmpty) {
        _mobileError = 'Please enter your mobile number';
        valid = false;
      } else if (!phoneRegex.hasMatch(mobile)) {
        _mobileError = 'Please enter a valid mobile number (10-12 digits)';
        valid = false;
      } else {
        _mobileError = null;
      }

      // Password
      final pwd = _passwordController.text;
      if (pwd.isEmpty) {
        _passwordError = 'Please create a password';
        valid = false;
      } else if (pwd.length < 8) {
        _passwordError = 'Password must be at least 8 characters';
        valid = false;
      } else {
        _passwordError = null;
      }

      // Confirm Password
      final confirm = _confirmPasswordController.text;
      if (confirm.isEmpty) {
        _confirmError = 'Please confirm your password';
        valid = false;
      } else if (confirm != pwd) {
        _confirmError = 'Passwords do not match';
        valid = false;
      } else {
        _confirmError = null;
      }

      // Terms & Conditions Agreement
      if (!_agreedToTerms) {
        _termsError = 'Please agree to the Terms & Conditions to proceed.';
        valid = false;
      } else {
        _termsError = null;
      }
    });
    return valid;
  }

  void _onContinue() async {
    if (!_validate() || _isLoading) return;

    final name = _nameController.text.trim();
    final businessName = _businessNameController.text.trim();
    final email = _emailController.text.trim();
    final mobile = _mobileController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
      _emailError = null;
    });

    try {
      if (_isEmailVerified) {
        // Email is already verified inline! Directly create account and proceed to security setup
        final user = await _authRepo.register(
          name: name,
          businessName: businessName,
          email: email,
          mobile: mobile,
          password: password,
        );
        ProfileRepository().syncFromUser(user);
        try {
          await ProfileRepository().loadProfile(fetchFromApi: true);
        } catch (_) {}

        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => SecurityCredentialSetupScreen(user: user),
            ),
            (route) => false,
          );
        }
        return;
      }

      // 1. Check account availability before sending OTP (Duplicate Prevention)
      await _authRepo.checkAccountAvailability(email: email, phone: mobile);

      // 2. Dispatch OTP with purpose REGISTRATION
      await _authRepo.sendOtp(
        email,
        phone: mobile,
        purpose: 'REGISTRATION',
      );
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              email: email,
              phone: mobile,
              isRegistration: true,
              name: name,
              registrationData: {
                'name': name,
                'businessName': businessName,
                'email': email,
                'mobile': mobile,
                'password': password,
                'termsAccepted': 'true',
                'termsVersion': '1.0',
                'termsAcceptedAt': DateTime.now().toIso8601String(),
              },
            ),
          ),
        );
      }
    } on AlreadyRegisteredException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AlreadyRegisteredDialog.show(
          context,
          email: email,
          phone: mobile,
          field: e.field,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailError = e.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', '');
        });
      }
    }
  }

  Future<void> _verifyEmailInline() async {
    if (!_agreedToTerms) {
      setState(() => _termsError = 'Please agree to the Terms & Conditions and Privacy Policy before verifying email');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms & Conditions and Privacy Policy before verifying your email'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _emailError = 'Please enter a valid email address first');
      return;
    }
    setState(() {
      _isSendingEmailOtp = true;
      _emailError = null;
      _termsError = null;
    });

    try {
      await _authRepo.checkAccountAvailability(email: email);
      await _authRepo.sendOtp(email, purpose: 'REGISTRATION');
      if (!mounted) return;
      setState(() => _isSendingEmailOtp = false);
      _showInlineOtpDialog(
        identifier: email,
        isEmail: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSendingEmailOtp = false;
        _emailError = e.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', '');
      });
    }
  }

  Future<void> _verifyMobileInline() async {
    final mobile = _mobileController.text.trim();
    if (mobile.isEmpty || mobile.length < 10) {
      setState(() => _mobileError = 'Please enter a valid 10-digit mobile number first');
      return;
    }
    setState(() {
      _isSendingMobileOtp = true;
      _mobileError = null;
    });

    try {
      await _authRepo.checkAccountAvailability(phone: mobile);
      await _authRepo.sendOtp(
        _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        phone: mobile,
        purpose: 'REGISTRATION',
      );
      if (!mounted) return;
      setState(() => _isSendingMobileOtp = false);
      _showInlineOtpDialog(
        identifier: mobile,
        isEmail: false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSendingMobileOtp = false;
        _mobileError = e.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', '');
      });
    }
  }

  void _showInlineOtpDialog({required String identifier, required bool isEmail}) {
    final otpController = TextEditingController();
    String? modalError;
    bool isVerifying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = ThemeController().isDarkTheme(context);
            final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
            final txtColor = isDark ? Colors.white : const Color(0xFF0F172A);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: sheetBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEmail ? 'Verify Email Address' : 'Verify Mobile Number',
                      style: AppTypography.titleLarge.copyWith(
                        color: txtColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter the 6-digit verification code sent to $identifier',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 18),
                    FintechTextField(
                      controller: otpController,
                      label: '6-DIGIT OTP',
                      hintText: 'Enter 6-digit OTP',
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      errorText: modalError,
                      onChanged: (_) {
                        if (modalError != null) setModalState(() => modalError = null);
                      },
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      text: 'Verify Code',
                      isLoading: isVerifying,
                      onPressed: () async {
                        final code = otpController.text.trim();
                        if (code.length != 6) {
                          setModalState(() => modalError = 'Please enter a complete 6-digit code');
                          return;
                        }
                        setModalState(() => isVerifying = true);
                        try {
                          await _authRepo.verifyOtp(
                            isEmail ? identifier : (_emailController.text.trim().isNotEmpty ? _emailController.text.trim() : identifier),
                            code,
                            phone: isEmail ? null : identifier,
                            purpose: 'REGISTRATION',
                          );
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          setState(() {
                            if (isEmail) {
                              _isEmailVerified = true;
                            } else {
                              _isMobileVerified = true;
                            }
                          });
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.surfaceElevated,
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    isEmail ? 'Email verified successfully!' : 'Mobile number verified successfully!',
                                    style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } catch (err) {
                          setModalState(() {
                            isVerifying = false;
                            modalError = err.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', '');
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPasswordHint(String text, bool isPassed) {
    return Row(
      children: [
        Icon(
          isPassed ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 14,
          color: isPassed ? AppColors.success : AppColors.textMuted,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTypography.bodySmall.copyWith(
            color: isPassed ? AppColors.textPrimary : AppColors.textTertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController().isDarkTheme(context);
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final primaryTextColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: primaryTextColor,
        centerTitle: true,
        title: Text(
          'Create Account',
          style: AppTypography.titleLarge.copyWith(
            color: primaryTextColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: 0.5,
              color: AppColors.brandBlue,
              backgroundColor: isDark ? const Color(0xFF334155) : AppColors.brandBorder,
              minHeight: 3,
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimensions.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cardBgColor,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandBlue.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome to ENX Money',
                      style: AppTypography.displayMedium.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your account to get started with smart finance tracking',
                      style: AppTypography.bodyLarge.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Full Name
                    FintechTextField(
                      label: 'FULL NAME',
                      hintText: 'Enter your full name',
                      controller: _nameController,
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary, size: 20),
                      errorText: _nameError,
                      onChanged: (_) { if (_nameError != null) setState(() => _nameError = null); },
                    ),
                    const SizedBox(height: 16),

                    // Business Name
                    FintechTextField(
                      label: 'BUSINESS NAME',
                      hintText: 'Enter your enterprise or business name',
                      controller: _businessNameController,
                      prefixIcon: Icon(Icons.business_center_outlined, color: AppColors.textSecondary, size: 20),
                      errorText: _businessNameError,
                      onChanged: (_) { if (_businessNameError != null) setState(() => _businessNameError = null); },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    FintechTextField(
                      label: 'EMAIL ADDRESS',
                      hintText: 'Enter your email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 20),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _isSendingEmailOtp
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(4),
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandBlue),
                                ),
                              )
                            : _isEmailVerified
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, size: 14, color: AppColors.primaryGreen),
                                        SizedBox(width: 4),
                                        Text(
                                          'Verified',
                                          style: TextStyle(
                                            color: AppColors.primaryGreen,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: AppColors.brandBlue.withValues(alpha: 0.12),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    onPressed: _verifyEmailInline,
                                    child: const Text(
                                      'Verify',
                                      style: TextStyle(
                                        color: AppColors.brandBlue,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                      ),
                      errorText: _emailError,
                      onChanged: (_) {
                        if (_isEmailVerified) setState(() => _isEmailVerified = false);
                        if (_emailError != null) setState(() => _emailError = null);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Mobile
                    FintechTextField(
                      label: 'MOBILE NUMBER',
                      hintText: 'Enter your mobile number',
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textSecondary, size: 20),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _isSendingMobileOtp
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(4),
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandBlue),
                                ),
                              )
                            : _isMobileVerified
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, size: 14, color: AppColors.primaryGreen),
                                        SizedBox(width: 4),
                                        Text(
                                          'Verified',
                                          style: TextStyle(
                                            color: AppColors.primaryGreen,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: AppColors.brandBlue.withValues(alpha: 0.12),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    onPressed: _verifyMobileInline,
                                    child: const Text(
                                      'Verify',
                                      style: TextStyle(
                                        color: AppColors.brandBlue,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                      ),
                      errorText: _mobileError,
                      onChanged: (_) {
                        if (_isMobileVerified) setState(() => _isMobileVerified = false);
                        if (_mobileError != null) setState(() => _mobileError = null);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    FintechTextField(
                      label: 'PASSWORD',
                      hintText: 'Create a strong password',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      errorText: _passwordError,
                    ),
                    if (_passwordController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            _buildPasswordHint('At least 8 characters', _hasMinLength),
                            const SizedBox(height: 3),
                            _buildPasswordHint('At least one uppercase letter', _hasUppercase),
                            const SizedBox(height: 3),
                            _buildPasswordHint('At least one number', _hasNumber),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Confirm Password
                    FintechTextField(
                      label: 'CONFIRM PASSWORD',
                      hintText: 'Re-enter your password',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      errorText: _confirmError,
                      onChanged: (_) { if (_confirmError != null) setState(() => _confirmError = null); },
                    ),
                    const SizedBox(height: 24),

                    // Terms & Conditions and Privacy Policy Agreement Checkbox
                    GestureDetector(
                      key: const Key('terms_agreement_row'),
                      onTap: () {
                        setState(() {
                          _agreedToTerms = !_agreedToTerms;
                          if (_agreedToTerms) _termsError = null;
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Explicit High-Contrast Checkbox (22x22, 2px solid #0066FF)
                            GestureDetector(
                              key: const Key('terms_checkbox_tap'),
                              onTap: () {
                                setState(() {
                                  _agreedToTerms = !_agreedToTerms;
                                  if (_agreedToTerms) _termsError = null;
                                });
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Container(
                                  key: const Key('terms_checkbox'),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: _agreedToTerms
                                        ? const Color(0xFF0066FF)
                                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: const Color(0xFF0066FF),
                                      width: 2.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0066FF).withValues(alpha: isDark ? 0.25 : 0.12),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: _agreedToTerms
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                    fontSize: 12.5,
                                    height: 1.45,
                                  ),
                                  children: [
                                    const TextSpan(text: 'I agree to the '),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: GestureDetector(
                                        onTap: () => ProfileModals.showTermsModal(
                                          context,
                                          showConsentToggles: true,
                                          initialConsent: _agreedToTerms,
                                          onConsentChanged: (agreed) {
                                            setState(() {
                                              _agreedToTerms = agreed;
                                              if (agreed) _termsError = null;
                                            });
                                          },
                                        ),
                                        child: Text(
                                          'Terms & Conditions',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: const Color(0xFF0066FF),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            decoration: TextDecoration.underline,
                                            decorationColor: const Color(0xFF0066FF),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const TextSpan(text: ' and '),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: GestureDetector(
                                        onTap: () => ProfileModals.showPrivacyPolicyModal(
                                          context,
                                          showConsentToggles: true,
                                          initialConsent: _agreedToTerms,
                                          onConsentChanged: (agreed) {
                                            setState(() {
                                              _agreedToTerms = agreed;
                                              if (agreed) _termsError = null;
                                            });
                                          },
                                        ),
                                        child: Text(
                                          'Privacy Policy',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: const Color(0xFF0066FF),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            decoration: TextDecoration.underline,
                                            decorationColor: const Color(0xFF0066FF),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_termsError != null) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 34),
                        child: Text(
                          _termsError!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.error,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    PrimaryButton(
                      text: 'Create Account',
                      isLoading: _isLoading,
                      backgroundColor: const Color(0xFF0066FF),
                      textColor: Colors.white,
                      disabledBackgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      disabledForegroundColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      onPressed: _onContinue,
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.brandTextSecondary),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: Text(
                            'Sign In',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.brandBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);
  }
}
