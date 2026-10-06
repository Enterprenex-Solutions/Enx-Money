import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_bars/fintech_app_bar.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/cards/credit_card_widget.dart';
import '../../../../core/widgets/cards/fintech_card.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/auth_repository.dart';
import '../../data/cards_repository.dart';
import '../../models/card_model.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final CardsRepository _cardsRepo = CardsRepository();
  final AuthRepository _authRepo = AuthRepository();
  List<UserCard> _cards = [];
  int _selectedCardIndex = 0;
  bool _showFullCardDetails = false;
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final cards = await _cardsRepo.getCards();
      if (mounted) {
        setState(() {
          _cards = cards;
          _selectedCardIndex = 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = (e is ApiException) ? e.message : 'Unable to load cards. Please check your internet connection.';
          _isLoading = false;
        });
      }
    }
  }

  void _onCreateNewCard() async {
    final user = _authRepo.currentUser ?? await _authRepo.getLocalUser();
    final userName = user?.fullName.isNotEmpty == true ? user!.fullName : 'ENX MEMBER';

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Issue ENX Card', style: AppTypography.titleLarge),
              const SizedBox(height: 6),
              Text(
                'A new customized physical & virtual card will be issued for $userName.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryGreen),
                  ),
                  child: const Icon(Icons.credit_card_rounded, color: AppColors.primaryGreen),
                ),
                title: Text('ENX Black Edition (Metal)', style: AppTypography.titleSmall),
                subtitle: Text('Limit: ₹5,00,000 • Visa Signature', style: AppTypography.bodySmall),
                trailing: const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'CONFIRM & ISSUE CARD',
                isLoading: _isActionLoading,
                onPressed: () async {
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  try {
                    final newCard = await _cardsRepo.createCard(
                      cardTier: 'Black Metal',
                      network: 'Visa',
                    );
                    if (mounted) {
                      setState(() {
                        _cards.insert(0, newCard);
                        _selectedCardIndex = 0;
                        _isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Card issued successfully for ${newCard.cardHolderName}!'),
                          backgroundColor: AppColors.primaryGreen,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to issue card: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _toggleFreeze() async {
    if (_cards.isEmpty) return;
    final current = _cards[_selectedCardIndex];
    HapticFeedback.mediumImpact();
    try {
      final updated = await _cardsRepo.toggleFreezeCard(current.id);
      if (mounted) {
        setState(() {
          _cards[_selectedCardIndex] = updated;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Card ${updated.isFrozen ? "Frozen" : "Unfrozen"}'),
            backgroundColor: updated.isFrozen ? AppColors.warning : AppColors.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      // Local toggle fallback
      setState(() {
        _cards[_selectedCardIndex] = current.copyWith(isFrozen: !current.isFrozen);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    if (_errorMessage != null && _cards.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const FintechAppBar(
          title: 'Cards & Limits',
          subtitle: 'ENX CARD VAULT',
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: 'TRY AGAIN',
                  icon: Icons.refresh_rounded,
                  onPressed: _loadCards,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_cards.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const FintechAppBar(
          title: 'Cards & Limits',
          subtitle: 'ENX CARD VAULT',
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withValues(alpha: 0.15),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.credit_card_off_rounded, size: 36, color: AppColors.primaryGreen),
                ),
                const SizedBox(height: 24),
                Text('No card available', style: AppTypography.displaySmall),
                const SizedBox(height: 8),
                Text(
                  'You do not have an active ENX Metal or Platinum card linked to your account yet.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  text: '+ CREATE CARD',
                  icon: Icons.add_rounded,
                  onPressed: _onCreateNewCard,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final card = _cards[_selectedCardIndex];
    final spentRatio = (card.spentThisMonth / card.limit).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: FintechAppBar(
        title: 'Cards & Limits',
        subtitle: 'ENX CARD VAULT',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card_rounded, color: AppColors.primaryGreen),
            tooltip: 'Issue New Card',
            onPressed: _onCreateNewCard,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Carousel / Switcher
            SizedBox(
              height: 220,
              child: PageView.builder(
                itemCount: _cards.length,
                onPageChanged: (index) {
                  setState(() {
                    _selectedCardIndex = index;
                    _showFullCardDetails = false;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CreditCardWidget(
                      card: _cards[index],
                      showFullNumber: _showFullCardDetails && index == _selectedCardIndex,
                      onToggleVisibility: () {
                        setState(() {
                          _showFullCardDetails = !_showFullCardDetails;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Indicator dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_cards.length, (index) {
                final isSelected = index == _selectedCardIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 20 : 6,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryGreen : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Card Action Buttons (Freeze, CVV, PIN, Replace)
            Row(
              children: [
                Expanded(
                  child: _buildCardActionButton(
                    icon: card.isFrozen ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                    label: card.isFrozen ? 'Unfreeze' : 'Freeze Card',
                    color: card.isFrozen ? AppColors.error : AppColors.pureWhite,
                    onTap: _toggleFreeze,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCardActionButton(
                    icon: Icons.visibility_outlined,
                    label: _showFullCardDetails ? 'Hide CVV' : 'View CVV',
                    color: AppColors.pureWhite,
                    onTap: () {
                      setState(() {
                        _showFullCardDetails = !_showFullCardDetails;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCardActionButton(
                    icon: Icons.pin_outlined,
                    label: 'Change PIN',
                    color: AppColors.pureWhite,
                    onTap: () {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Spending Limit Tracker Card
            FintechCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MONTHLY SPENDING LIMIT',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        '${(spentRatio * 100).toInt()}% USED',
                        style: AppTypography.badge.copyWith(
                          color: spentRatio > 0.8 ? AppColors.warning : AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        CurrencyFormatter.format(card.spentThisMonth, showDecimals: false),
                        style: AppTypography.currencyMedium,
                      ),
                      Text(
                        'of ${CurrencyFormatter.format(card.limit, showDecimals: false)}',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: spentRatio,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        spentRatio > 0.8 ? AppColors.warning : AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Remaining: ${CurrencyFormatter.format(card.limit - card.spentThisMonth, showDecimals: false)}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.primaryGreen),
                      ),
                      Text(
                        'Resets on 1st of month',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Security Controls & Channel Toggles
            Text(
              'TRANSACTION PREFERENCES',
              style: AppTypography.labelSmall.copyWith(
                letterSpacing: 1.2,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 12),

            FintechCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: 'Contactless (NFC / Tap)',
                    subtitle: 'Up to ₹5,000 per transaction without PIN',
                    icon: Icons.contactless_outlined,
                    value: card.isContactlessActive,
                    onChanged: (val) {
                      setState(() {
                        _cards[_selectedCardIndex] = card.copyWith(isContactlessActive: val);
                      });
                    },
                  ),
                  const Divider(),
                  _buildSwitchTile(
                    title: 'International Payments',
                    subtitle: 'Allow foreign currency transactions',
                    icon: Icons.public_outlined,
                    value: card.isInternationalActive,
                    onChanged: (val) {
                      setState(() {
                        _cards[_selectedCardIndex] = card.copyWith(isInternationalActive: val);
                      });
                    },
                  ),
                  const Divider(),
                  _buildSwitchTile(
                    title: 'Online E-Commerce',
                    subtitle: 'Allow online payments and OTP authorization',
                    icon: Icons.shopping_cart_outlined,
                    value: true,
                    onChanged: (val) {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCardActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTypography.badge.copyWith(
                  fontSize: 10,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.primaryGreen),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.primaryGreen,
            activeTrackColor: AppColors.primaryGreen.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.textTertiary,
            inactiveTrackColor: AppColors.surfaceElevated,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
