import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/fintech_text_field.dart';
import '../../data/auth_repository.dart';
import '../../../profile/presentation/widgets/profile_modals.dart';
import 'otp_verification_screen.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final AuthRepository _authRepo = AuthRepository();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isValidEmail {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
    return emailRegex.hasMatch(email);
  }

  void _onGetOtp() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail) {
      setState(() {
        _errorMessage = 'Please enter a valid email address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authRepo.sendOtp(email);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              email: email,
              phone: _phoneController.text.trim().isNotEmpty
                  ? _phoneController.text.trim()
                  : null,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final rawMsg = e.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', '');
        if (rawMsg.toLowerCase().contains('before requesting a new otp') ||
            rawMsg.contains('COOLDOWN_ACTIVE')) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification code already sent! Please check your email.'),
              backgroundColor: AppColors.brandBlue,
              duration: Duration(seconds: 4),
            ),
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                email: email,
                phone: _phoneController.text.trim().isNotEmpty
                    ? _phoneController.text.trim()
                    : null,
              ),
            ),
          );
          return;
        }

        setState(() {
          _isLoading = false;
          _errorMessage = rawMsg;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _isValidEmail;

    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.brandNavy),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security Shield Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.brandBlueLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 13, color: AppColors.brandBlue),
                    const SizedBox(width: 6),
                    Text(
                      'BANK-GRADE 256-BIT ENCRYPTION',
                      style: AppTypography.badge.copyWith(
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Title & Subtitle
              Text(
                'Enter your details',
                style: AppTypography.displayMedium.copyWith(
                  color: AppColors.brandNavy,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "We'll send a 6-digit verification code to your email to authenticate your ENX account.",
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.brandTextSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),

              // Email Input Field
              FintechTextField(
                controller: _emailController,
                label: 'EMAIL ADDRESS',
                hintText: 'name@example.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppColors.textSecondary, size: 20),
                suffixIcon: _emailController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textTertiary),
                        onPressed: () {
                          _emailController.clear();
                          setState(() {
                            _errorMessage = null;
                          });
                        },
                      )
                    : null,
                errorText: _errorMessage,
                onChanged: (val) {
                  setState(() {
                    _errorMessage = null;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Mobile Number Input Field (Optional)
              FintechTextField(
                controller: _phoneController,
                label: 'MOBILE NUMBER (OPTIONAL)',
                hintText: '+91 98765 43210',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.textSecondary, size: 20),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
                  LengthLimitingTextInputFormatter(15),
                ],
                onChanged: (val) {
                  setState(() {});
                },
              ),

              const Spacer(),

              // Terms & Privacy statement
              Center(
                child: Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                    children: [
                      const TextSpan(text: 'By continuing, you agree to our '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () => ProfileModals.showTermsModal(context),
                          child: Text(
                            'Terms of Service',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primaryGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ' & '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () => ProfileModals.showPrivacyPolicyModal(context),
                          child: Text(
                            'Privacy Policy',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primaryGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Get OTP CTA Button
              PrimaryButton(
                text: 'Get Verification Code',
                isLoading: _isLoading,
                onPressed: isValid ? _onGetOtp : null,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Prefer password? ',
                    style: AppTypography.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: Text(
                      'Sign In with Password',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
