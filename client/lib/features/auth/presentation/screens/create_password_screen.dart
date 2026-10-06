import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/fintech_text_field.dart';

/// Step 2 of registration: Create & confirm password with strength indicator.
class CreatePasswordScreen extends StatefulWidget {
  const CreatePasswordScreen({super.key});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

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
        _passwordError = 'Please enter a password';
        valid = false;
      } else if (pwd.length < 8) {
        _passwordError = 'Password must be at least 8 characters';
        valid = false;
      } else {
        _passwordError = null;
      }

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
    });
    return valid;
  }

  void _onContinue() {
    if (!_validate()) return;

    if (_score < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please choose a stronger password matching requirements'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
        ),
      );
      return;
    }

    final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
    Navigator.pushNamed(
      context,
      '/biometric-setup',
      arguments: {
        ...args,
        'password': _passwordController.text,
      },
    );
  }

  Widget _buildCheckItem(String text, bool isPassed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isPassed ? Icons.check_circle : Icons.cancel_outlined,
            size: 18,
            color: isPassed
                ? AppColors.success
                : AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: isPassed ? AppColors.textPrimary : AppColors.textTertiary,
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
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        title: Text(
          'Create Password',
          style: AppTypography.titleLarge,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator (step 2 of 3)
            LinearProgressIndicator(
              value: 0.66,
              color: AppColors.primaryGreen,
              backgroundColor: AppColors.border,
              minHeight: 3,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Secure Your Account',
                      style: AppTypography.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a strong password to protect your financial data',
                      style: AppTypography.bodyLarge,
                    ),
                    const SizedBox(height: 32),
                    FintechTextField(
                      label: 'PASSWORD',
                      hintText: 'Enter strong password',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      prefixIcon: Icon(
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
                    // Password Criteria Checklist
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
                    FintechTextField(
                      label: 'CONFIRM PASSWORD',
                      hintText: 'Re-enter your password',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      prefixIcon: Icon(
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
                    const SizedBox(height: 36),
                    PrimaryButton(
                      text: 'Continue',
                      onPressed: _onContinue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
