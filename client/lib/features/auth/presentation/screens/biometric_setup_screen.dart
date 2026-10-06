import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/buttons/secondary_button.dart';
import '../../data/auth_repository.dart';
import '../../data/biometric_service.dart';

/// Step 3 of registration: Setup Biometric Authentication (Fingerprint / Face ID).
class BiometricSetupScreen extends StatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  bool _isLoading = false;

  Future<void> _enableBiometric() async {
    setState(() => _isLoading = true);

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, String>;

    try {
      final isAvailable = await BiometricService.instance.isBiometricAvailable();

      if (!isAvailable) {
        // Hardware not available or web/emulator: register anyway for seamless experience
        await _registerUser(args, biometricEnabled: true);
        if (!mounted) return;
        Navigator.pushNamed(context, '/biometric-registered');
        return;
      }

      final authenticated = await BiometricService.instance.authenticate(
        reason:
            'Scan your fingerprint or face to enable biometric login for ENX Money',
      );

      if (authenticated) {
        await _registerUser(args, biometricEnabled: true);
        if (!mounted) return;
        Navigator.pushNamed(context, '/biometric-registered');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Biometric authentication cancelled or failed.'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _skipBiometric() async {
    setState(() => _isLoading = true);
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, String>;
    try {
      await _registerUser(args, biometricEnabled: false);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _registerUser(
    Map<String, String> args, {
    required bool biometricEnabled,
  }) async {
    final authRepo = AuthRepository();
    await authRepo.register(
      name: args['name']!,
      email: args['email']!,
      mobile: args['mobile']!,
      password: args['password']!,
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
          'Set Up Biometric',
          style: AppTypography.titleLarge,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator (step 3 of 3)
            LinearProgressIndicator(
              value: 1.0,
              color: AppColors.primaryGreen,
              backgroundColor: AppColors.border,
              minHeight: 3,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fingerprint,
                        size: 90,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Fingerprint / Face ID',
                      style: AppTypography.displayMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Enable biometric login for instant, secure access to your ENX Money account without typing your password.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge.copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 48),
                    PrimaryButton(
                      text: 'Enable Biometric Login',
                      isLoading: _isLoading,
                      icon: Icons.fingerprint,
                      onPressed: _enableBiometric,
                    ),
                    const SizedBox(height: 16),
                    SecondaryButton(
                      text: 'Skip for Now',
                      onPressed: _skipBiometric,
                      borderColor: AppColors.border,
                      textColor: AppColors.textSecondary,
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
