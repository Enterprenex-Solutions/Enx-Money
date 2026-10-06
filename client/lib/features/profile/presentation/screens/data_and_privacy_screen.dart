import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/widgets/app_bars/fintech_app_bar.dart';
import '../../../../core/widgets/cards/fintech_card.dart';

class DataAndPrivacyScreen extends StatelessWidget {
  const DataAndPrivacyScreen({super.key});

  Future<void> _launchUrl(String urlString, BuildContext context) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text('Could not open $urlString'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text('Could not open $urlString'),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const FintechAppBar(
        title: 'Data & Privacy',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Trust & Encryption Banner
            FintechCard(
              hasGlow: true,
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_outlined, color: AppColors.primaryGreen, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy-First Architecture',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Encrypted in transit via HTTPS/TLS 1.3 • Zero Advertising Trackers • Multi-Tenant Isolation',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Data Collected by ENX Money
            _buildSectionHeader('DATA COLLECTED & USAGE'),
            const SizedBox(height: 10),
            FintechCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _buildDataInfoRow(
                    icon: Icons.person_outline_rounded,
                    title: 'Personal Identification',
                    detail: 'Name, email, phone number used strictly for authentication and account management.',
                  ),
                  const Divider(color: AppColors.divider),
                  _buildDataInfoRow(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Financial & Khata Records',
                    detail: 'Customer ledgers, credit/debit balances, invoices, and loan amortization schedules.',
                  ),
                  const Divider(color: AppColors.divider),
                  _buildDataInfoRow(
                    icon: Icons.lock_outline_rounded,
                    title: 'Security Credentials',
                    detail: 'Bcrypt-hashed passwords, 5-minute email OTPs, signed JWT session tokens.',
                  ),
                  const Divider(color: AppColors.divider),
                  _buildDataInfoRow(
                    icon: Icons.block_flipped,
                    title: 'What We Do NOT Collect',
                    detail: 'No GPS location, no background tracking, no contacts scraping, no SMS/call log reading.',
                    isNegative: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Legal Documents & Compliance
            _buildSectionHeader('LEGAL POLICIES & DISCLOSURES'),
            const SizedBox(height: 10),
            FintechCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  _buildActionTile(
                    title: 'Privacy Policy (In-App)',
                    subtitle: 'Full 24-section audited policy',
                    icon: Icons.privacy_tip_outlined,
                    onTap: () => Navigator.pushNamed(context, '/privacy-policy'),
                  ),
                  const Divider(color: AppColors.divider),
                  _buildActionTile(
                    title: 'Privacy Policy (Web Page)',
                    subtitle: 'Open public HTTPS web document in browser',
                    icon: Icons.open_in_browser_rounded,
                    onTap: () => _launchUrl(ApiConfig.privacyPolicyUrl, context),
                  ),
                  const Divider(color: AppColors.divider),
                  _buildActionTile(
                    title: 'Terms & Conditions (In-App)',
                    subtitle: 'Full 33-section audited terms',
                    icon: Icons.description_outlined,
                    onTap: () => Navigator.pushNamed(context, '/terms-and-conditions'),
                  ),
                  const Divider(color: AppColors.divider),
                  _buildActionTile(
                    title: 'Terms & Conditions (Web Page)',
                    subtitle: 'Open public HTTPS web document in browser',
                    icon: Icons.open_in_browser_rounded,
                    onTap: () => _launchUrl(ApiConfig.termsAndConditionsUrl, context),
                  ),
                  const Divider(color: AppColors.divider),
                  _buildActionTile(
                    title: 'Refund & Cancellation Policy',
                    subtitle: 'Google Play Payments Policy compliance',
                    icon: Icons.receipt_long_outlined,
                    onTap: () => Navigator.pushNamed(context, '/refund-cancellation-policy'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. Data Rights & Retention
            _buildSectionHeader('RETENTION & DATA RIGHTS'),
            const SizedBox(height: 10),
            FintechCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Data Rights',
                    style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Data Portability: You can export your customer ledgers, invoices, and daily transactions into PDF or Excel spreadsheets directly inside the app.\n'
                    '• Retention: Active account data is stored while your account is open. Upon deletion, personal credentials are permanently wiped.\n'
                    '• Statutory Compliance: Historical ledger records are anonymized and retained in compliance with Indian taxation and corporate record regulations.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 5. Privacy Officer Contact
            _buildSectionHeader('PRIVACY CONTACT & INQUIRIES'),
            const SizedBox(height: 10),
            FintechCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shield_outlined, color: AppColors.primaryGreen, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mr. Rohit Pawar', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('Grievance Officer & Data Protection Officer', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text('Enterprenex Solutions Pvt. Ltd.', style: AppTypography.labelSmall.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, Maharashtra - 431136, India',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 12),
                  // Action Buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      InkWell(
                        onTap: () => _launchUrl('tel:+919226860060', context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.call_rounded, size: 14, color: AppColors.primaryGreen),
                              const SizedBox(width: 6),
                              Text('+91-9226860060', style: AppTypography.badge.copyWith(color: AppColors.pureWhite)),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _launchUrl('mailto:info@enterprenex.solutions', context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.mail_outline_rounded, size: 14, color: AppColors.primaryGreen),
                              const SizedBox(width: 6),
                              Text('info@enterprenex.solutions', style: AppTypography.badge.copyWith(color: AppColors.pureWhite)),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _launchUrl('mailto:privacy@enxmoney.com', context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.security_rounded, size: 14, color: AppColors.primaryGreen),
                              const SizedBox(width: 6),
                              Text('privacy@enxmoney.com', style: AppTypography.badge.copyWith(color: AppColors.pureWhite)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.labelSmall.copyWith(
        letterSpacing: 1.2,
        color: AppColors.textTertiary,
      ),
    );
  }

  Widget _buildDataInfoRow({
    required IconData icon,
    required String title,
    required String detail,
    bool isNegative = false,
  }) {
    final color = isNegative ? const Color(0xFFF59E0B) : AppColors.primaryGreen;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(detail, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
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
                    Text(subtitle, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
