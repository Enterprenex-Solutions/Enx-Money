import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/fintech_text_field.dart';
import '../../data/auth_repository.dart';

/// Screen where users enter their new password and confirm it after OTP verification.
class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String? otp;
  final String? resetToken;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    this.otp,
    this.resetToken,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authRepo = AuthRepository();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSpecial = false;

  String? _passwordError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updatePasswordStrength);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final pwd = _passwordController.text;
    setState(() {
      _hasMinLength = pwd.length >= 8;
      _hasUppercase = pwd.contains(RegExp(r'[A-Z]'));
      _hasNumber = pwd.contains(RegExp(r'[0-9]'));
      _hasSpecial = pwd.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
      if (_passwordError != null) _passwordError = null;
    });
  }

  int get _score {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasNumber) score++;
    if (_hasSpecial) score++;
    return score;
  }

  String get _strengthLabel {
    switch (_score) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return 'Weak';
    }
  }

  Color get _strengthColor {
    switch (_score) {
      case 0:
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.info;
      case 4:
        return AppColors.success;
      default:
        return AppColors.error;
    }
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      final pwd = _passwordController.text;
      if (pwd.isEmpty) {
        _passwordError = 'Please enter a new password';
        valid = false;
      } else if (pwd.length < 8) {
        _passwordError = 'Password must be at least 8 characters';
        valid = false;
      } else {
        _passwordError = null;
      }

      final confirm = _confirmPasswordController.text;
      if (confirm.isEmpty) {
        _confirmError = 'Please confirm your new password';
        valid = false;
      } else if (confirm != pwd) {
        _confirmError = 'Passwords do not match';
        valid = false;
      } else {
        _confirmError = null;
      }
    });
    return valid;
  }

  Future<void> _onResetPassword() async {
    if (!_validate()) return;

    if (_score < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please choose a stronger password matching the requirements'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authRepo.resetPassword(
        email: widget.email,
        otp: widget.otp,
        resetToken: widget.resetToken,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Color(0xFF10B981)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Password reset successful! Please sign in with your new password.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF131A24),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            side: const BorderSide(color: Color(0xFF10B981)),
          ),
        ),
      );

      // Navigate back to Login Screen
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', '');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.isNotEmpty ? msg : 'Unable to reset password. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
        ),
      );
    }
  }

  Widget _buildCheckItem(String text, bool isPassed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isPassed ? Icons.check_circle : Icons.cancel_outlined,
            size: 16,
            color: isPassed
                ? AppColors.success
                : AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: isPassed ? AppColors.textPrimary : AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.pureWhite),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security Shield Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, size: 13, color: AppColors.primaryGreen),
                    const SizedBox(width: 6),
                    Text(
                      'SECURE PASSWORD UPDATE',
                      style: AppTypography.badge.copyWith(
                        color: AppColors.primaryGreen,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title & Subtitle
              Text(
                'Create New Password',
                style: AppTypography.displayMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set a strong, secure password for ${widget.email}.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // New Password Field
              FintechTextField(
                label: 'NEW PASSWORD',
                hintText: 'Enter new strong password',
                controller: _passwordController,
                obscureText: _obscurePassword,
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                errorText: _passwordError,
              ),
              const SizedBox(height: 12),

              // Strength Meter
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: List.generate(4, (index) {
                        return Expanded(
                          child: Container(
                            height: 4,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: index < _score
                                  ? _strengthColor
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _passwordController.text.isEmpty ? '' : _strengthLabel,
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _strengthColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Password Requirements Checklist
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildCheckItem('At least 8 characters', _hasMinLength),
                    _buildCheckItem('At least one uppercase letter (A-Z)', _hasUppercase),
                    _buildCheckItem('At least one number (0-9)', _hasNumber),
                    _buildCheckItem('At least one special character (!@#\$%^&*)', _hasSpecial),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Confirm Password Field
              FintechTextField(
                label: 'CONFIRM NEW PASSWORD',
                hintText: 'Re-enter your new password',
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirm = !_obscureConfirm;
                    });
                  },
                ),
                errorText: _confirmError,
                onChanged: (_) {
                  if (_confirmError != null) {
                    setState(() => _confirmError = null);
                  }
                },
              ),
              const SizedBox(height: 32),

              // Reset Password Button
              PrimaryButton(
                text: 'Reset Password',
                isLoading: _isLoading,
                onPressed: _onResetPassword,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
