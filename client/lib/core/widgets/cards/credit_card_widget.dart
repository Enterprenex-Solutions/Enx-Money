import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_typography.dart';
import '../../../features/cards/models/card_model.dart';

class CreditCardWidget extends StatelessWidget {
  final UserCard card;
  final bool showFullNumber;
  final VoidCallback? onToggleVisibility;

  const CreditCardWidget({
    super.key,
    required this.card,
    this.showFullNumber = false,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        gradient: card.isBlackEdition
            ? AppColors.cardLuxuryGradient
            : AppColors.cardPlatinumGradient,
        border: Border.all(
          color: card.isFrozen ? AppColors.error.withValues(alpha: 0.5) : AppColors.borderLight,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (card.isBlackEdition ? Colors.black : AppColors.surfaceElevated).withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle luxury glow
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row: Brand & EMV Chip / Type
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                            border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'ENX ${card.cardTier.toUpperCase()}',
                            style: AppTypography.badge.copyWith(
                              color: AppColors.primaryGreen,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        if (card.isFrozen) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lock, size: 10, color: AppColors.error),
                                const SizedBox(width: 4),
                                Text(
                                  'FROZEN',
                                  style: AppTypography.badge.copyWith(
                                    color: AppColors.error,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Contactless & Chip Icon
                    Row(
                      children: [
                        const Icon(Icons.contactless, color: AppColors.textSecondary, size: 22),
                        const SizedBox(width: 10),
                        Container(
                          width: 32,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37),
                            borderRadius: BorderRadius.circular(4),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFDF73), Color(0xFFA67C1E)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Card Number
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      showFullNumber
                          ? card.cardNumber
                          : '••••  ••••  ••••  ${card.lastFourDigits}',
                      style: AppTypography.currencyMedium.copyWith(
                        letterSpacing: 3.5,
                        fontSize: 19,
                        color: AppColors.pureWhite,
                      ),
                    ),
                    if (onToggleVisibility != null)
                      IconButton(
                        icon: Icon(
                          showFullNumber ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: onToggleVisibility,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),

                // Bottom row: Holder name, expiry, network logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CARD HOLDER',
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 9,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          card.cardHolderName.toUpperCase(),
                          style: AppTypography.labelLarge.copyWith(
                            fontSize: 13,
                            color: AppColors.pureWhite,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXPIRES',
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 9,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          card.expiryDate,
                          style: AppTypography.labelLarge.copyWith(
                            fontSize: 13,
                            color: AppColors.pureWhite,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      card.network.toUpperCase(),
                      style: AppTypography.displaySmall.copyWith(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.pureWhite,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
