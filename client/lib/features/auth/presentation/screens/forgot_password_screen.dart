import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/fintech_text_field.dart';
import '../../data/auth_repository.dart';
import 'otp_verification_screen.dart';
import 'reset_password_screen.dart';

/// Multi-step password recovery screen.
///
/// Step 1 – Enter registered email / mobile.
///   • If security questions are set → go to Step 2 (answer questions).
///   • If no security questions → fall back to OTP email flow.
///
/// Step 2 – Answer the stored security questions.
///   • On success → navigate to [ResetPasswordScreen] with resetToken.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthRepository _authRepo = AuthRepository();

  // ── Step state ──────────────────────────────────────────────────────
  int _step = 1; // 1 = email, 2 = security questions

  // ── Step 1 ──────────────────────────────────────────────────────────
  final _emailController = TextEditingController();
  bool _isLoadingStep1 = false;
  String? _step1Error;

  // ── Step 2 ──────────────────────────────────────────────────────────
  String _identifier = '';
  List<Map<String, dynamic>> _questions = [];
  final List<TextEditingController> _answerControllers = [];
  final List<bool> _obscureAnswers = [];
  bool _isVerifying = false;
  String? _step2Error;

  @override
  void dispose() {
    _emailController.dispose();
    for (final c in _answerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Validation
  // ─────────────────────────────────────────────────────────────────────

  bool get _isIdentifierValid {
    final input = _emailController.text.trim();
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
    final phoneRegex = RegExp(r'^\+?[0-9]{10,13}$');
    return emailRegex.hasMatch(input) || phoneRegex.hasMatch(input);
  }

  bool get _allAnswersFilled =>
      _answerControllers.every((c) => c.text.trim().length >= 2);

  // ─────────────────────────────────────────────────────────────────────
  // Step 1 – Email / Mobile submit
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _onStep1Submit() async {
    final id = _emailController.text.trim();
    setState(() {
      _isLoadingStep1 = true;
      _step1Error = null;
    });

    try {
      // Try to fetch user's configured security questions
      final questions = await _authRepo.fetchQuestionsForUser(id);

      if (!mounted) return;

      if (questions.isNotEmpty) {
        // Route through security-question flow
        final controllers = List.generate(
          questions.length,
          (_) => TextEditingController(),
        );
        setState(() {
          _identifier = id;
          _questions = questions;
          _answerControllers
            ..clear()
            ..addAll(controllers);
          _obscureAnswers
            ..clear()
            ..addAll(List.generate(questions.length, (_) => true));
          _step = 2;
          _isLoadingStep1 = false;
        });
      } else {
        // No security questions — fall back to OTP email flow
        await _sendOtpFallback(id);
      }
    } on Exception catch (e) {
      final msg = e
          .toString()
          .replaceAll('Exception: ', '')
          .replaceAll('ApiException: ', '');

      // 404 = user not found; still try OTP path so we don't reveal existence
      if (msg.toLowerCase().contains('not found') ||
          msg.contains('404') ||
          msg.isEmpty) {
        if (mounted) await _sendOtpFallback(id);
        return;
      }

      if (mounted) {
        setState(() {
          _isLoadingStep1 = false;
          _step1Error = msg.isNotEmpty
              ? msg
              : 'Unable to proceed. Please try again.';
        });
      }
    }
  }

  /// Fallback: trigger OTP reset email and navigate to OTP verification screen
  Future<void> _sendOtpFallback(String id) async {
    try {
      final res = await _authRepo.forgotPassword(id);
      if (!mounted) return;
      setState(() => _isLoadingStep1 = false);
      final targetEmail = (res['email'] as String?) ?? id;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: targetEmail,
            isForgotPassword: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e
          .toString()
          .replaceAll('Exception: ', '')
          .replaceAll('ApiException: ', '');

      // OTP already sent (cooldown) — navigate to OTP screen anyway
      if (msg.toLowerCase().contains('please wait') ||
          msg.contains('COOLDOWN_ACTIVE')) {
        setState(() => _isLoadingStep1 = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'A reset code was already sent. Please check your email/mobile.'),
            backgroundColor: AppColors.brandBlue,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                OtpVerificationScreen(email: id, isForgotPassword: true),
          ),
        );
        return;
      }

      setState(() {
        _isLoadingStep1 = false;
        _step1Error = msg.isNotEmpty
            ? msg
            : 'Unable to send password reset code. Please try again.';
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Step 2 – Verify security question answers
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _onVerifyAnswers() async {
    setState(() {
      _isVerifying = true;
      _step2Error = null;
    });

    try {
      final answers = List.generate(_questions.length, (i) {
        return {
          'questionId': (_questions[i]['id']).toString(),
          'answer': _answerControllers[i].text.trim(),
        };
      });

      final resetToken = await _authRepo.verifySecurityAnswers(
        identifier: _identifier,
        answers: answers,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            email: _identifier,
            resetToken: resetToken,
          ),
        ),
      );
    } catch (e) {
      final msg = e
          .toString()
          .replaceAll('Exception: ', '')
          .replaceAll('ApiException: ', '');
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _step2Error = msg.isNotEmpty
              ? msg
              : 'Incorrect answers. Please try again.';
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.pureWhite),
          onPressed: () {
            if (_step == 2) {
              setState(() {
                _step = 1;
                _step2Error = null;
              });
            } else {
              Navigator.maybePop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: _step == 1 ? _buildStep1() : _buildStep2(),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Step 1 UI
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildStep1() {
    return Padding(
      key: const ValueKey(1),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBadge(
            icon: Icons.lock_reset_rounded,
            label: 'ACCOUNT RECOVERY',
            color: AppColors.primaryGreen,
          ),
          const SizedBox(height: 20),
          Text(
            'Forgot Password',
            style: AppTypography.displayMedium
                .copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your registered email address or mobile number. We will check if you have security questions set up.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 32),

          FintechTextField(
            controller: _emailController,
            label: 'REGISTERED EMAIL OR MOBILE',
            hintText: 'name@example.com or 10-digit mobile',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.alternate_email_rounded,
                color: AppColors.textSecondary, size: 20),
            suffixIcon: _emailController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textTertiary),
                    onPressed: () {
                      _emailController.clear();
                      setState(() => _step1Error = null);
                    },
                  )
                : null,
            errorText: _step1Error,
            onChanged: (_) => setState(() => _step1Error = null),
          ),
          const SizedBox(height: 16),

          _buildInfoBox(
            'If you have security questions configured, you can answer them to reset your password instantly. Otherwise, we will send you a one-time code.',
          ),

          const Spacer(),

          PrimaryButton(
            text: 'Continue',
            isLoading: _isLoadingStep1,
            onPressed: _isIdentifierValid ? _onStep1Submit : null,
            icon: Icons.arrow_forward_rounded,
          ),
          const SizedBox(height: 16),

          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Remember your password? ',
                    style: AppTypography.bodyMedium),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'Sign In',
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.primaryGreen),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Step 2 UI
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildStep2() {
    return SingleChildScrollView(
      key: const ValueKey(2),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBadge(
            icon: Icons.shield_outlined,
            label: 'IDENTITY VERIFICATION',
            color: AppColors.accentPurple,
          ),
          const SizedBox(height: 20),
          Text(
            'Security Questions',
            style: AppTypography.displayMedium
                .copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Answer your security questions to verify your identity and reset your password.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 8),
          _buildInfoBox(
              'Answers are case-insensitive. You have limited attempts before the account is temporarily locked.'),
          const SizedBox(height: 28),

          // Question slots
          for (int i = 0; i < _questions.length; i++) ...[
            _buildQuestionSlot(i),
            if (i < _questions.length - 1) const SizedBox(height: 24),
          ],

          if (_step2Error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_step2Error!,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.error)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),
          PrimaryButton(
            text: 'Verify & Reset Password',
            isLoading: _isVerifying,
            onPressed: _allAnswersFilled ? _onVerifyAnswers : null,
            icon: Icons.verified_user_outlined,
          ),
          const SizedBox(height: 16),

          Center(
            child: TextButton(
              onPressed: () async {
                // Fall back to OTP for this identifier
                setState(() {
                  _step = 1;
                  _isLoadingStep1 = true;
                  _step2Error = null;
                });
                await _sendOtpFallback(_identifier);
              },
              child: Text(
                'Send reset code by email instead',
                style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primaryGreen,
                    decoration: TextDecoration.underline),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuestionSlot(int index) {
    final q = _questions[index];
    final questionText = q['text'] as String? ?? 'Security Question';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question text (read-only)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryGreen.withValues(alpha: 0.12),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  questionText,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textPrimary, height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Answer field
        FintechTextField(
          controller: _answerControllers[index],
          label: 'YOUR ANSWER',
          hintText: 'Enter your answer...',
          keyboardType: TextInputType.text,
          obscureText: _obscureAnswers[index],
          prefixIcon: const Icon(Icons.lock_outline_rounded,
              color: AppColors.textSecondary, size: 18),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureAnswers[index]
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textTertiary,
              size: 18,
            ),
            onPressed: () {
              setState(() {
                _obscureAnswers[index] = !_obscureAnswers[index];
              });
            },
          ),
          onChanged: (_) => setState(() => _step2Error = null),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Shared helpers
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: AppTypography.badge.copyWith(color: color, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: AppColors.primaryGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary, height: 1.35)),
          ),
        ],
      ),
    );
  }
}
