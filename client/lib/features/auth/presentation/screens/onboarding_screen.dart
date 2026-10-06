import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/buttons/secondary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'tag': 'SMART WEALTH',
      'title': 'Track, Pay & Grow\nwith Ultimate Control',
      'subtitle': 'Aggregated real-time insights across your cards, bank balances, and mutual fund portfolios in one clean vault.',
      'icon': Icons.account_balance_wallet_outlined,
      'badgeColor': AppColors.brandBlue,
    },
    {
      'tag': 'CREDIT EXCELLENCE',
      'title': 'High-Limit Cards &\nExclusive Rewards',
      'subtitle': 'Real-time statement tracking, hidden fees detection, and one-tap card freeze capabilities.',
      'icon': Icons.credit_card_rounded,
      'badgeColor': AppColors.brandCyan,
    },
    {
      'tag': 'SMART PASSBOOK',
      'title': 'Zero Effort Automated\nExpense Analytics',
      'subtitle': 'Instant Walnut-style category intelligence and intelligent monthly cash outflow predictions.',
      'icon': Icons.pie_chart_outline_rounded,
      'badgeColor': AppColors.accentPurple,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/create-account');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController().isDarkTheme(context);
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final primaryTextColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    final screenHeight = MediaQuery.of(context).size.height;
    final iconCircleSize = (screenHeight * 0.2).clamp(120.0, 180.0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Top Bar with Skip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          width: 34,
                          height: 34,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'ENX MONEY',
                        style: AppTypography.labelLarge.copyWith(
                          color: primaryTextColor,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (_currentPage < _slides.length - 1)
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Text(
                        'SKIP',
                        style: AppTypography.badge.copyWith(
                          color: AppColors.brandTextMuted,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),

              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          // Visual Card
                          Center(
                            child: Container(
                              width: iconCircleSize,
                              height: iconCircleSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cardBgColor,
                                border: Border.all(
                                  color: (slide['badgeColor'] as Color).withValues(alpha: 0.2),
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (slide['badgeColor'] as Color).withValues(alpha: 0.12),
                                    blurRadius: 32,
                                    offset: const Offset(0, 10),
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                slide['icon'] as IconData,
                                size: iconCircleSize * 0.44,
                                color: slide['badgeColor'] as Color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Pill Tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: (slide['badgeColor'] as Color).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (slide['badgeColor'] as Color).withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              slide['tag'] as String,
                              style: AppTypography.badge.copyWith(
                                color: slide['badgeColor'] as Color,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Title
                          Text(
                            slide['title'] as String,
                            style: AppTypography.displaySmall.copyWith(
                              color: primaryTextColor,
                              height: 1.25,
                              fontWeight: FontWeight.w800,
                              fontSize: 26,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Subtitle
                          Text(
                            slide['subtitle'] as String,
                            style: AppTypography.bodyMedium.copyWith(
                              color: secondaryTextColor,
                              height: 1.5,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Indicators and Continue Button
              Row(
                children: List.generate(_slides.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 8),
                    height: 5,
                    width: isActive ? 28 : 8,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.brandBlue : AppColors.brandBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              if (_currentPage == _slides.length - 1) ...[
                PrimaryButton(
                  text: 'Create New Account',
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/create-account');
                  },
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  text: 'Already have an account? Sign In',
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  borderColor: isDark ? const Color(0xFF334155) : AppColors.brandBorder,
                  textColor: primaryTextColor,
                ),
              ] else ...[
                PrimaryButton(
                  text: 'Continue',
                  onPressed: _onNext,
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: Text(
                      'Already have an account? Sign In',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
