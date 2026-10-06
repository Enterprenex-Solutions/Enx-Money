import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/app_lock_service.dart';
import '../../../../core/services/secure_credential_vault.dart';
import '../../data/auth_repository.dart';
import 'app_lock_pin_screen.dart';
import 'onboarding_screen.dart';
import '../../../shell/presentation/screens/main_shell_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.easeIn)),
    );

    _controller.forward();

    _navigateNext();
  }

  void _navigateNext() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final authRepo = AuthRepository();
    final isLoggedIn = await authRepo.isLoggedIn();

    Widget target;
    if (isLoggedIn) {
      if (AppLockService.instance.isAnyLockActive) {
        // Mark as locked silently (no notifyListeners) so main.dart listener
        // doesn't race with our navigation below.
        AppLockService.instance.lockSilently();
        target = const AppLockPinScreen(isInitialUnlock: true);
      } else {
        target = const MainShellScreen();
      }
    } else {
      final hasQuickUnlock =
          await SecureCredentialVault.instance.hasStoredCredentialForQuickUnlock();
      if (hasQuickUnlock) {
        // Returning user with configured credentials routes directly to AppLockPinScreen
        AppLockService.instance.lockSilently();
        target = const AppLockPinScreen(isInitialUnlock: true);
      } else {
        // First-time or unauthenticated user routes to Onboarding Welcome
        target = const OnboardingScreen();
      }
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, anim1, anim2) => target,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      body: Stack(
        children: [
          // Background subtle azure brand glow
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandBlue.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandCyan.withValues(alpha: 0.06),
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Official App Logo
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.brandBlue.withValues(alpha: 0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              width: 104,
                              height: 104,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'ENX MONEY',
                          style: AppTypography.displaySmall.copyWith(
                            color: AppColors.brandNavy,
                            letterSpacing: 4.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.brandBlueLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'FINANCIAL SUITE & SME BANKING',
                            style: AppTypography.badge.copyWith(
                              letterSpacing: 1.8,
                              color: AppColors.brandBlue,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'POWERED BY ENTERPRENEX',
                style: AppTypography.badge.copyWith(
                  letterSpacing: 1.5,
                  color: AppColors.brandTextMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
