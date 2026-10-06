import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/auth_repository.dart';
import '../../../shell/presentation/screens/main_shell_screen.dart';
import 'app_lock_pin_screen.dart';

class BiometricAuthScreen extends StatefulWidget {
  const BiometricAuthScreen({super.key});

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen> with SingleTickerProviderStateMixin {
  final AuthRepository _authRepo = AuthRepository();
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  bool _isAuthenticating = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerBiometric() async {
    setState(() {
      _isAuthenticating = true;
    });

    HapticFeedback.mediumImpact();
    final success = await _authRepo.verifyBiometric();

    if (!mounted) return;

    if (success) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isAuthenticating = false;
        _isSuccess = true;
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainShellScreen()),
            (route) => false,
          );
        }
      });
    } else {
      setState(() {
        _isAuthenticating = false;
      });
      NotificationService.showError('Biometric verification failed or cancelled.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(),

              // Animated Biometric Fingerprint / Face ID Ring
              Center(
                child: GestureDetector(
                  onTap: _isAuthenticating ? null : _triggerBiometric,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow ring
                          Container(
                            width: 140 * (_isAuthenticating ? _scaleAnimation.value : 1.0),
                            height: 140 * (_isAuthenticating ? _scaleAnimation.value : 1.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (_isSuccess
                                      ? AppColors.success
                                      : AppColors.primaryGreen)
                                  .withValues(alpha: 0.12),
                            ),
                          ),
                          // Core Icon Container
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.cardLuxuryGradient,
                              border: Border.all(
                                color: _isSuccess
                                    ? AppColors.success
                                    : (_isAuthenticating
                                        ? AppColors.primaryGreen
                                        : AppColors.borderLight),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isSuccess
                                          ? AppColors.success
                                          : AppColors.primaryGreen)
                                      .withValues(alpha: 0.25),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isSuccess
                                  ? Icons.check_rounded
                                  : Icons.fingerprint_rounded,
                              size: 52,
                              color: _isSuccess
                                  ? AppColors.success
                                  : AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 48),

              Text(
                _isSuccess ? 'Authentication Successful' : 'Quick Biometric Login',
                style: AppTypography.displaySmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _isSuccess
                    ? 'Redirecting to your dashboard...'
                    : 'Touch the sensor or tap authenticate to log in seamlessly with Fingerprint / Face ID.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              PrimaryButton(
                text: _isAuthenticating ? 'SCANNING BIOMETRICS...' : 'SCAN BIOMETRIC',
                isLoading: _isAuthenticating,
                icon: Icons.fingerprint,
                onPressed: _triggerBiometric,
              ),
              const SizedBox(height: 12),

              SecondaryButton(
                text: 'Use 4-Digit MPIN instead',
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AppLockPinScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
