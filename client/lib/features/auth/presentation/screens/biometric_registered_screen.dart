import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/buttons/primary_button.dart';

/// Confirmation screen shown when biometric registration completes successfully.
class BiometricRegisteredScreen extends StatefulWidget {
  const BiometricRegisteredScreen({super.key});

  @override
  State<BiometricRegisteredScreen> createState() =>
      _BiometricRegisteredScreenState();
}

class _BiometricRegisteredScreenState extends State<BiometricRegisteredScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 90,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Biometric Registered!',
                style: AppTypography.displayMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Your biometric authentication has been successfully set up. You can now log in instantly using Fingerprint or Face ID.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge.copyWith(height: 1.4),
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Go to Dashboard',
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
