import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/services/app_lock_service.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/fintech_text_field.dart';
import '../../../../core/widgets/inputs/pin_dot_indicator.dart';
import '../../../../core/widgets/inputs/numeric_keypad.dart';
import '../../data/profile_repository.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../ai/presentation/screens/meta_ai_chat_screen.dart';
import '../../../auth/presentation/screens/security_questions_setup_screen.dart';

class ProfileModals {
  /// Opens the Security & Recovery Questions Screen / Modal
  static Future<bool?> showSecurityQuestionsModal(BuildContext context) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const SecurityRecoveryQuestionsScreen(),
      ),
    );
  }

  /// Bottom Sheet for viewing and managing active login devices
  static void showActiveDevicesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final repo = ProfileRepository();
            final devices = repo.profile.activeDevices;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Login Devices',
                        style: AppTypography.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Devices currently authenticated with your ENX Money account',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  ...devices.map((device) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        border: Border.all(
                          color: device.isCurrent
                              ? AppColors.primaryGreen.withValues(alpha: 0.4)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              device.platform.toLowerCase().contains('mac') ||
                                      device.platform.toLowerCase().contains('win')
                                  ? Icons.laptop_mac_rounded
                                  : Icons.phone_android_rounded,
                              color: device.isCurrent ? AppColors.primaryGreen : AppColors.textSecondary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        device.deviceName,
                                        style: AppTypography.titleSmall.copyWith(
                                          color: AppColors.pureWhite,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (device.isCurrent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGreen.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'THIS DEVICE',
                                          style: AppTypography.badge.copyWith(
                                            color: AppColors.primaryGreen,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${device.platform} • ${device.location} • ${device.lastActive}',
                                  style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          if (!device.isCurrent)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                              tooltip: 'Revoke Access',
                              onPressed: () async {
                                await repo.revokeDevice(device.id);
                                setModalState(() {});
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('${device.deviceName} session revoked'),
                                      backgroundColor: AppColors.surfaceElevated,
                                    ),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    text: 'Sign Out Other Sessions',
                    onPressed: () async {
                      await ProfileRepository().revokeOtherDevices();
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All other device sessions have been safely logged out.'),
                            backgroundColor: AppColors.surfaceElevated,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Set 4-Digit Security PIN Bottom Sheet Modal (Enable)
  static void showSetPinModal(BuildContext context, {VoidCallback? onSuccess}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _SetPinSheetContent(onSuccess: onSuccess);
      },
    );
  }

  /// Disable 4-Digit Security PIN Bottom Sheet Modal (Disable)
  static void showDisablePinModal(BuildContext context, {VoidCallback? onSuccess}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _DisablePinSheetContent(onSuccess: onSuccess);
      },
    );
  }

  /// Change 4-Digit Security PIN Bottom Sheet Modal
  static void showChangePinModal(BuildContext context, {VoidCallback? onSuccess}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _ChangePinSheetContent(onSuccess: onSuccess);
      },
    );
  }

  /// Change Account Password Bottom Sheet Modal
  static void showChangePasswordModal(BuildContext context, {VoidCallback? onSuccess}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _ChangePasswordSheetContent(onSuccess: onSuccess);
      },
    );
  }

  /// Help & Support / 24x7 Private Assistant Bottom Sheet
  static void showHelpAndSupportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.92,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ListView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Help & Support', style: AppTypography.titleLarge),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Text(
                    '24/7 Dedicated Concierge for ENX Private Wealth & Business',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 20),

                  // Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildHelpCard(
                          icon: Icons.call_rounded,
                          title: 'Call Helpline',
                          subtitle: '+91-9226860060',
                          onTap: () async {
                            final uri = Uri.parse('tel:+919226860060');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildHelpCard(
                          icon: Icons.mail_outline_rounded,
                          title: 'Corporate Email',
                          subtitle: 'info@enterprenex.solutions',
                          onTap: () async {
                            final uri = Uri.parse('mailto:info@enterprenex.solutions?subject=Support%20Inquiry%20-%20ENX%20Money');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildHelpCard(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Live Chat',
                          subtitle: 'Instant AI Advisor',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MetaAiChatScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildHelpCard(
                          icon: Icons.shield_outlined,
                          title: 'Grievance Officer',
                          subtitle: 'Mr. Rohit Pawar',
                          onTap: () async {
                            final uri = Uri.parse('mailto:privacy@enxmoney.com?subject=Grievance%20Inquiry%20-%20ENX%20Money');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Enterprenex Solutions Pvt. Ltd.', style: AppTypography.titleSmall.copyWith(color: AppColors.primaryGreen, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          'Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, Maharashtra - 431136, India',
                          style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text('FREQUENTLY ASKED QUESTIONS', style: AppTypography.labelSmall.copyWith(letterSpacing: 1.2, color: AppColors.textTertiary)),
                  const SizedBox(height: 12),

                  _buildFaqTile(
                    'How does ENX Money protect my financial data?',
                    'ENX Money implements AES-256 bank-grade data encryption at rest and TLS 1.3 in transit. We enforce dual-factor verification and never share your financial records with third parties.',
                  ),
                  _buildFaqTile(
                    'How is GST validation verified for businesses?',
                    'When you enter a 15-digit GSTIN, our system validates the state code, PAN linkage, and checksum according to the GST council specifications.',
                  ),
                  _buildFaqTile(
                    'Can I change my registered email or mobile number?',
                    'Yes, you can edit your personal details anytime under "Personal Information". Verified updates will trigger an instant email verification code for security.',
                  ),
                  _buildFaqTile(
                    'How does smart Khata settlement work?',
                    'Smart Khata automatically syncs customer balances and generates shareable payment links via UPI and Instant Settlement channels.',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Privacy Policy Document Viewer Modal
  static Future<bool?> showPrivacyPolicyModal(
    BuildContext context, {
    bool showConsentToggles = false,
    bool initialConsent = false,
    ValueChanged<bool>? onConsentChanged,
  }) {
    return _showDocumentDialog(
      context,
      title: 'Privacy Policy',
      routeName: '/settings/privacy-policy',
      webUrl: ApiConfig.privacyPolicyUrl,
      showConsentToggles: showConsentToggles,
      initialConsent: initialConsent,
      onConsentChanged: onConsentChanged,
      content: '''
Official Privacy Policy • DPDP Act, 2023 Compliant • Version 1.0 • Updated: October 4, 2026
Company Name: Enterprenex Solutions Pvt. Ltd.
Grievance / Privacy Officer: Mr. Rohit Pawar (Data Protection Officer)
Phone Number: +91-9226860060 (Mon–Sat, 10:00 AM – 6:00 PM IST)
Billing Email: billing@enterprenex.solutions
General / Legal Email: info@enterprenex.solutions
Technical Support Email: support@enxmoney.com
Privacy / Grievance Email: privacy@enxmoney.com / grievance@enxmoney.com
Website Domain: https://enxmoney.enterprenex.solutions
GitHub Pages Legal Host: https://enterprenex-solution-pvt-ltd.github.io/Enx-Money/
Registered Address: Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, Maharashtra - 431136, India

Section 1: Introduction & Multi-Tenant Ledger Scope
Enterprenex Solutions Pvt. Ltd. operates the ENX Money platform. Under the Digital Personal Data Protection Act, 2023 ("DPDP Act") and DPDP Rules, 2025, ENX Money acts as a Data Fiduciary for registered merchant accounts. For Khata customer records entered by merchants, ENX Money operates under a multi-tenant ledger architecture as a Data Processor on behalf of the merchant, who remains the independent Data Fiduciary.

Section 2: Data Collected (Identity, Financial Ledgers, Telemetry)
• Account & Identity: Full legal name, business name, registration date, email address, mobile phone number, business address, GSTIN, business category.
• Credentials: Salted bcrypt-hashed passwords (10 rounds), signed session JWTs.
• Financial Ledgers: Gave/got balances, cash/UPI notes, GST invoices (HSN/SAC codes, CGST/SGST/IGST).
• Verified Zero-Collection Audit: Zero raw biometric server storage, zero plaintext passwords, zero address book uploads, zero GPS sensor tracking, zero audio/mic/SMS access, zero advertising identifiers (AAID/IDFA).

Section 3: Data Protection Safeguards
• Biometric Protection: Zero raw biometric server storage. Biometric authentication (Face ID, fingerprint) utilizes WebAuthn/FIDO2 processed strictly inside your device hardware enclave (Apple Secure Enclave, Android StrongBox/Titan M). Only an irreversible cryptographic public key (ES256/RS256) is transmitted.
• Security Architecture: 100% TLS 1.3 transport encryption with HSTS; AES-256 encryption at rest; multi-tenant database isolation (business_id query scoping) preventing IDOR vulnerabilities; instant server-side JWT session revocation upon logout.

Section 4: Data Retention & Statutory Limits
• Financial/GST Records: Retained for a minimum statutory period of 8 years in strict accordance with the Indian Companies Act, 2013 and Goods and Services Tax (GST) laws.
• Active Account Profiles: Maintained during active account standing and purged upon verified deletion request.
• Ephemeral OTPs: Purged automatically within 5 minutes.
• Session Tokens: 7-day automatic expiry with immediate blacklisting upon logout.

Section 5: Data Principal Rights & In-App Deletion Pathway
Under the DPDP Act, you have enforceable rights to access, correction, erasure, consent withdrawal, grievance redressal, and nomination.
Immediate Deletion Pathway: Settings > Data & Privacy > Delete Account, or visit https://enxmoney.enterprenex.solutions/delete-account. Verified requests are fulfilled within 30 days.

Section 6: Grievance Redressal & Contact Officer
Company Name: Enterprenex Solutions Pvt. Ltd.
Grievance / Privacy Officer: Mr. Rohit Pawar (Data Protection Officer)
Phone Number: +91-9226860060 (Mon–Sat, 10:00 AM – 6:00 PM IST)
Billing Email: billing@enterprenex.solutions
General / Legal Email: info@enterprenex.solutions
Technical Support Email: support@enxmoney.com
Privacy / Grievance Email: privacy@enxmoney.com / grievance@enxmoney.com
Website Domain: https://enxmoney.enterprenex.solutions
GitHub Pages Legal Host: https://enterprenex-solution-pvt-ltd.github.io/Enx-Money/
Registered Address: Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, Maharashtra - 431136, India
Timeline: Acknowledged within 48 hours; resolved within 30 days. Unresolved grievances may be escalated to the Data Protection Board of India.

Tap 'Full Page View' below to inspect the complete 6 compliance chapters and interactive contact CTAs.
      ''',
    );
  }

  /// Terms & Conditions Document Viewer Modal
  static Future<bool?> showTermsModal(
    BuildContext context, {
    bool showConsentToggles = false,
    bool initialConsent = false,
    ValueChanged<bool>? onConsentChanged,
  }) {
    return _showDocumentDialog(
      context,
      title: 'Terms & Conditions',
      routeName: '/settings/terms-conditions',
      webUrl: ApiConfig.termsAndConditionsUrl,
      showConsentToggles: showConsentToggles,
      initialConsent: initialConsent,
      onConsentChanged: onConsentChanged,
      content: '''
Official Terms & Conditions • Version 1.0 • Updated: October 4, 2026
Company Name: Enterprenex Solutions Pvt. Ltd.
Grievance / Privacy Officer: Mr. Rohit Pawar
Phone Number: +91-9226860060 (Mon–Sat, 10:00 AM – 6:00 PM IST)
Billing Email: billing@enterprenex.solutions
General / Legal Email: info@enterprenex.solutions
Technical Support Email: support@enxmoney.com
Website Domain: https://enxmoney.enterprenex.solutions
GitHub Pages Legal Host: https://enterprenex-solution-pvt-ltd.github.io/Enx-Money/
Registered Address: Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, Maharashtra - 431136, India

Section 1: Acceptance of Terms & Signup Agreement Rules
These Terms & Conditions constitute a legally binding agreement between you and Enterprenex Solutions Pvt. Ltd. By creating an account, verifying email OTP, setting a password, or enabling biometric/passkey login, you agree to be bound by these Terms and our Privacy Policy. Material changes will be communicated with prior notice.

Section 2: Eligibility & Multi-User Role Responsibilities
• Age Requirement: You must be at least 18 years old and competent to contract under the Indian Contract Act, 1872. Use by minors is prohibited.
• Multi-User Hierarchy: Business accounts support Owner, Admin, Staff, and Accountant roles. The account holder is responsible for user permissions and revoking access upon employment termination.
• Account Security: Safeguard passwords and PINs; notify support@enxmoney.com immediately of unauthorized access.

Section 3: Core Service Scope
ENX Money provides bookkeeping utilities: Khata customer credit ledgers, business/personal finance tracking, analytics & reporting (PDF/Excel/Power BI), inventory tracking, credit/debit cashbooks, loan EMI tracking, and automated GST tax computation (CGST/SGST/IGST).

Section 4: User Data Accuracy & Customer Record Obligations
You are solely responsible for the accuracy of customer records, GSTIN numbers, and financial entries. Under the DPDP Act, 2023, ENX Money acts as a Data Processor for end-customer ledgers; merchants remain the independent Data Fiduciary.

Section 5: Subscription Pricing & 30-Day Advance Notice
ENX Money core features are free during the MVP production phase. If paid subscription plans are introduced in the future, we will provide at least thirty (30) days advance notice before fee changes take effect.

Section 6: Disclaimers (Not a Financial Institution / Bank / NBFC)
• Not a Bank: ENX Money is NOT a bank, NBFC, lender, payment aggregator, or tax authority. We do not extend credit or hold deposits.
• GST Disclaimer: Tax calculations are convenience tools; verify figures with a qualified Chartered Accountant before filing statutory GSTR returns.
• Loan EMI Disclaimer: Simulation tool only; lending institution figures prevail.
• Service Availability: Provided on an "as is" and "as available" basis.

Section 7: Intellectual Property & User Data Ownership
• User Ownership: You retain 100% proprietary ownership of all your business records, invoices, and Khata ledgers.
• Platform Ownership: Software code, logos, branding, and UI are the exclusive property of Enterprenex Solutions Pvt. Ltd.

Section 8: Third-Party Service Integrations
Integrates with email SMTP relay (Gmail, Brevo), cloud hosting, analytics, and optional SMS/WhatsApp gateways under respective third-party terms.

Section 9: Limitation of Liability & Indemnification
Our aggregate liability is limited to fees paid in the preceding 12 months, or INR 1,000 if used free of charge. Users agree to indemnify Enterprenex Solutions Pvt. Ltd. from breaches of Terms or misuse of customer data.

Section 10: Suspension & Account Closure Pathways
You may close your account at any time via: Settings > Data & Privacy > Delete Account, or through https://enxmoney.enterprenex.solutions/delete-account.

Section 11: Governing Law & Dispute Resolution
Governed by the laws of India (Contract Act 1872, IT Act 2000, DPDP Act 2023). Unresolved disputes shall be referred to binding arbitration under the Arbitration and Conciliation Act, 1996, seated in Chhatrapati Sambhajinagar, Maharashtra, India.

Section 12: General Provisions
Entire Agreement, Severability, No Waiver, Force Majeure.

Section 13: Official Contact Details
Company Name: Enterprenex Solutions Pvt. Ltd.
Grievance / Privacy Officer: Mr. Rohit Pawar
Phone Number: +91-9226860060 (Mon–Sat, 10:00 AM – 6:00 PM IST)
Billing Email: billing@enterprenex.solutions
General / Legal Email: info@enterprenex.solutions
Technical Support Email: support@enxmoney.com
Website Domain: https://enxmoney.enterprenex.solutions
GitHub Pages Legal Host: https://enterprenex-solution-pvt-ltd.github.io/Enx-Money/
Registered Address: Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, Maharashtra - 431136, India

Tap 'Full Page View' below to review the complete 13 chapters and interactive contact CTAs.
      ''',
    );
  }

  /// Refund & Cancellation Policy Document Viewer Modal (Google Play Policy)
  static void showRefundPolicyModal(
    BuildContext context, {
    bool showConsentToggles = false,
    bool initialConsent = false,
    ValueChanged<bool>? onConsentChanged,
  }) {
    _showDocumentDialog(
      context,
      title: 'Refund & Cancellation Policy',
      routeName: '/settings/refund-policy',
      webUrl: ApiConfig.refundPolicyUrl,
      showConsentToggles: showConsentToggles,
      initialConsent: initialConsent,
      onConsentChanged: onConsentChanged,
      content: '''
Refund & Cancellation Policy (v1.0)
Published by Enterprenex Solutions Pvt. Ltd.
Effective Date: October 4, 2026

Company Name: Enterprenex Solutions Pvt. Ltd.
Grievance / Privacy Officer: Mr. Rohit Pawar
Phone Number: +91-9226860060 (Mon–Sat, 10:00 AM – 6:00 PM IST)
Billing Email: billing@enterprenex.solutions
General / Legal Email: info@enterprenex.solutions
Technical Support Email: support@enxmoney.com
Website Domain: https://enxmoney.enterprenex.solutions
GitHub Pages Legal Host: https://enterprenex-solution-pvt-ltd.github.io/Enx-Money/
Registered Address: Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, Maharashtra - 431136, India

1. Current Status of ENX Money (MVP Free Phase Notice)
ENX Money is currently offered free of charge during its MVP (Minimum Viable Product) phase. No payment is collected at signup, and therefore no refund is applicable at this time. This Policy describes how refunds and cancellations will be handled once paid subscription plans are introduced.

2. Scope of This Policy
• What This Policy Covers: Paid subscription plans (Starter, Business, Enterprise), add-on features (extra WhatsApp reminder credits, extra user seats), and premium exports.
• What This Policy Does Not Cover: Counterparty ledger debts logged between you and your customers; third-party payment gateway fees; losses arising from user data entry errors.

3. Subscription Plans and Billing
• Billing Cycle: Billed on a monthly or annual recurring basis, charged automatically on each renewal date.
• Free Trial: Cancel anytime during trial without charge; automatically converts to paid if not cancelled.
• Auto-Renewal: Renews automatically unless cancelled at least 24 hours prior to the renewal date. Reminder notifications sent 3 days before renewal where required.
• Price Changes: 30 days advance notice provided for any fee modifications.

4. How to Cancel
• In-App Pathway: Settings > Subscription > Cancel Plan.
• Email Support: billing@enterprenex.solutions from your registered account email.
• What Happens After Cancellation: Continuous access until current billing period ends. No further charges. Reverts to free tier. Your ledger data is NEVER deleted upon plan cancellation and remains safely accessible.
• Complete Account Closure: Available via Settings > Data & Privacy > Delete Account.

5. Refund Eligibility
• When Eligible: Verified duplicate charges, technical service non-delivery, cancellation within 7 days of initial subscription purchase without substantial usage, or statutory rights under Consumer Protection Act, 2019.
• When Not Eligible: Requests made after 7 days, non-usage during billing cycle, breach of Terms & Conditions, dissatisfaction with correct calculations, or mid-cycle partial month usage.
• Request Process: Email billing@enterprenex.solutions with your account email and transaction ID. Acknowledged within 2 business days; approved refunds processed in 7–10 business days.

6. Failed, Duplicate, and Disputed Payments
• Failed Transactions: Automatically reversed by your bank/gateway within 5–7 business days.
• Duplicate Charges: Refunded in full within 7 business days of verification.
• Dispute Handling: Contact billing@enterprenex.solutions first for rapid resolution before initiating bank chargebacks.

7. Refund Timelines Matrix
• UPI: 2–5 business days
• Debit/Credit Cards: 5–10 business days (subject to issuing bank)
• Net Banking: 5–7 business days
• Digital Wallets: 1–3 business days

8. Special Cases
• Enterprise / Custom Plans: Governed by individual signed agreements.
• Promotional Subscriptions: Refunded only up to actual net amount paid.
• Add-On Credits: Non-refundable but eligible for rollover/carryforward.

9. Contact Us
• Company Name: Enterprenex Solutions Pvt. Ltd.
• Grievance / Privacy Officer: Mr. Rohit Pawar
• Phone Number: +91-9226860060 (Mon–Sat, 10:00 AM – 6:00 PM IST)
• Billing Email: billing@enterprenex.solutions
• General / Legal Email: info@enterprenex.solutions
• Technical Support Email: support@enxmoney.com
• Website Domain: https://enxmoney.enterprenex.solutions
• GitHub Pages Legal Host: https://enterprenex-solution-pvt-ltd.github.io/Enx-Money/
• Registered Address: Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, Maharashtra - 431136, India
      ''',
    );
  }

  /// Delete Account Confirmation Modal (Google Play Account Deletion Policy)
  static void showDeleteAccountConfirmationModal(BuildContext context, {required VoidCallback onConfirmed}) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Delete Account & Data',
                  style: AppTypography.titleLarge.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Are you sure you want to permanently delete your ENX Money account?',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.pureWhite, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  '• Your personal profile, email, phone number, credentials, and active sessions will be permanently purged.\n'
                  '• In accordance with Google Play Data Deletion Policy and statutory financial record regulations, historical ledger entries are unlinked and anonymized.\n'
                  '• This action is permanent and cannot be undone.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('CANCEL', style: AppTypography.badge.copyWith(color: AppColors.textTertiary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onConfirmed();
              },
              child: Text(
                'DELETE PERMANENTLY',
                style: AppTypography.badge.copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<bool?> _showDocumentDialog(
    BuildContext context, {
    required String title,
    required String content,
    String? webUrl,
    String? routeName,
    bool showConsentToggles = false,
    bool initialConsent = false,
    ValueChanged<bool>? onConsentChanged,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        bool currentConsent = initialConsent;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceElevated,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Text(title, style: AppTypography.titleLarge),
              content: SizedBox(
                width: double.maxFinite,
                height: showConsentToggles ? 420 : 380,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          content.trim(),
                          style: AppTypography.bodyMedium.copyWith(height: 1.5, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    if (showConsentToggles) ...[
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () {
                          setModalState(() {
                            currentConsent = !currentConsent;
                          });
                          onConsentChanged?.call(currentConsent);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: currentConsent ? AppColors.primaryGreen.withOpacity(0.12) : AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: currentConsent ? AppColors.primaryGreen : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                currentConsent ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                color: currentConsent ? AppColors.primaryGreen : AppColors.textTertiary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'I have reviewed and agree to the $title',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: currentConsent ? AppColors.pureWhite : AppColors.textSecondary,
                                    fontWeight: currentConsent ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                if (routeName != null)
                  TextButton.icon(
                    icon: const Icon(Icons.fullscreen_rounded, size: 18, color: AppColors.primaryGreen),
                    label: Text('Full Page View', style: AppTypography.badge.copyWith(color: AppColors.primaryGreen)),
                    onPressed: () {
                      Navigator.pop(ctx, currentConsent);
                      Navigator.pushNamed(context, routeName);
                    },
                  )
                else if (webUrl != null)
                  TextButton.icon(
                    icon: const Icon(Icons.open_in_browser_rounded, size: 16, color: AppColors.primaryGreen),
                    label: Text('Open Web Page', style: AppTypography.badge.copyWith(color: AppColors.primaryGreen)),
                    onPressed: () async {
                      final uri = Uri.parse(webUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                if (showConsentToggles) ...[
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        currentConsent = false;
                      });
                      onConsentChanged?.call(false);
                      Navigator.pop(ctx, false);
                    },
                    child: Text('Decline', style: AppTypography.badge.copyWith(color: AppColors.textTertiary)),
                  ),
                  PrimaryButton(
                    text: currentConsent ? 'Agreed' : 'Agree & Close',
                    height: 40,
                    width: 130,
                    onPressed: () {
                      if (!currentConsent) {
                        currentConsent = true;
                        onConsentChanged?.call(true);
                      }
                      Navigator.pop(ctx, true);
                    },
                  ),
                ] else ...[
                  PrimaryButton(
                    text: 'Close',
                    height: 40,
                    width: 90,
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  static Widget _buildHelpCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primaryGreen, size: 24),
              const SizedBox(height: 10),
              Text(title, style: AppTypography.titleSmall.copyWith(color: AppColors.pureWhite)),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildFaqTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: AppColors.primaryGreen,
        collapsedIconColor: AppColors.textTertiary,
        title: Text(
          question,
          style: AppTypography.titleSmall.copyWith(color: AppColors.pureWhite, fontSize: 13),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              answer,
              style: AppTypography.bodySmall.copyWith(height: 1.4, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetPinSheetContent extends StatefulWidget {
  final VoidCallback? onSuccess;
  const _SetPinSheetContent({this.onSuccess});

  @override
  State<_SetPinSheetContent> createState() => _SetPinSheetContentState();
}

class _SetPinSheetContentState extends State<_SetPinSheetContent> {
  int _step = 1; // 1: Enter New, 2: Confirm New
  String _pinInput = '';
  String _confirmInput = '';
  String? _errorMessage;
  bool _hasError = false;

  void _onKeyPressed(String key) {
    setState(() {
      _hasError = false;
      _errorMessage = null;

      if (_step == 1 && _pinInput.length < 4) {
        _pinInput += key;
        if (_pinInput.length == 4) {
          _step = 2;
        }
      } else if (_step == 2 && _confirmInput.length < 4) {
        _confirmInput += key;
        if (_confirmInput.length == 4) {
          _processConfirmation();
        }
      }
    });
  }

  void _onDeletePressed() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      if (_step == 1 && _pinInput.isNotEmpty) {
        _pinInput = _pinInput.substring(0, _pinInput.length - 1);
      } else if (_step == 2 && _confirmInput.isNotEmpty) {
        _confirmInput = _confirmInput.substring(0, _confirmInput.length - 1);
      }
    });
  }

  void _processConfirmation() async {
    if (_confirmInput == _pinInput) {
      final success = await AppLockService.instance.enablePin(_pinInput);
      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('App Lock PIN enabled successfully!'),
              backgroundColor: AppColors.surfaceElevated,
            ),
          );
          widget.onSuccess?.call();
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = 'Error saving PIN. Please try again.';
            _step = 1;
            _pinInput = '';
            _confirmInput = '';
          });
        }
      }
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _hasError = true;
        _errorMessage = 'PINs do not match. Please try again.';
        _step = 1;
        _pinInput = '';
        _confirmInput = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepTitle = _step == 1 ? 'Set 4-Digit Lock PIN' : 'Confirm Lock PIN';
    final stepSubtitle = _step == 1
        ? 'Choose a secure 4-digit PIN for instant access'
        : 'Re-enter your 4-digit PIN to confirm';
    final currentVal = _step == 1 ? _pinInput : _confirmInput;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(stepTitle, style: AppTypography.titleLarge),
          const SizedBox(height: 6),
          Text(stepSubtitle, style: AppTypography.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Center(
            child: PinDotIndicator(
              length: 4,
              filledCount: currentVal.length,
              isMasked: true,
              enteredValue: currentVal,
              hasError: _hasError,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          NumericKeypad(
            onKeyPressed: _onKeyPressed,
            onDeletePressed: _onDeletePressed,
          ),
        ],
      ),
    );
  }
}

class _DisablePinSheetContent extends StatefulWidget {
  final VoidCallback? onSuccess;
  const _DisablePinSheetContent({this.onSuccess});

  @override
  State<_DisablePinSheetContent> createState() => _DisablePinSheetContentState();
}

class _DisablePinSheetContentState extends State<_DisablePinSheetContent> {
  String _pinInput = '';
  String? _errorMessage;
  bool _hasError = false;

  void _onKeyPressed(String key) {
    if (_pinInput.length < 4) {
      setState(() {
        _hasError = false;
        _errorMessage = null;
        _pinInput += key;
        if (_pinInput.length == 4) {
          _processDisable();
        }
      });
    }
  }

  void _onDeletePressed() {
    if (_pinInput.isNotEmpty) {
      setState(() {
        _hasError = false;
        _errorMessage = null;
        _pinInput = _pinInput.substring(0, _pinInput.length - 1);
      });
    }
  }

  void _processDisable() async {
    final success = await AppLockService.instance.disablePin(_pinInput);
    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App Lock PIN disabled.'),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
      widget.onSuccess?.call();
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _hasError = true;
        _errorMessage = 'Incorrect PIN. Please try again.';
        _pinInput = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('Disable App Lock PIN', style: AppTypography.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Enter your current 4-digit PIN to turn off PIN protection',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Center(
            child: PinDotIndicator(
              length: 4,
              filledCount: _pinInput.length,
              isMasked: true,
              enteredValue: _pinInput,
              hasError: _hasError,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          NumericKeypad(
            onKeyPressed: _onKeyPressed,
            onDeletePressed: _onDeletePressed,
          ),
        ],
      ),
    );
  }
}

class _ChangePinSheetContent extends StatefulWidget {
  final VoidCallback? onSuccess;
  const _ChangePinSheetContent({this.onSuccess});

  @override
  State<_ChangePinSheetContent> createState() => _ChangePinSheetContentState();
}

class _ChangePinSheetContentState extends State<_ChangePinSheetContent> {
  int _step = 1; // 1: Enter Current, 2: Enter New, 3: Confirm New
  String _currentPinInput = '';
  String _newPinInput = '';
  String _confirmPinInput = '';
  String? _errorMessage;
  bool _hasError = false;

  void _onKeyPressed(String key) {
    setState(() {
      _hasError = false;
      _errorMessage = null;

      if (_step == 1 && _currentPinInput.length < 4) {
        _currentPinInput += key;
        if (_currentPinInput.length == 4) _processStep1();
      } else if (_step == 2 && _newPinInput.length < 4) {
        _newPinInput += key;
        if (_newPinInput.length == 4) _processStep2();
      } else if (_step == 3 && _confirmPinInput.length < 4) {
        _confirmPinInput += key;
        if (_confirmPinInput.length == 4) _processStep3();
      }
    });
  }

  void _onDeletePressed() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      if (_step == 1 && _currentPinInput.isNotEmpty) {
        _currentPinInput = _currentPinInput.substring(0, _currentPinInput.length - 1);
      } else if (_step == 2 && _newPinInput.isNotEmpty) {
        _newPinInput = _newPinInput.substring(0, _newPinInput.length - 1);
      } else if (_step == 3 && _confirmPinInput.isNotEmpty) {
        _confirmPinInput = _confirmPinInput.substring(0, _confirmPinInput.length - 1);
      }
    });
  }

  void _processStep1() async {
    final isValid = await AppLockService.instance.verifyPin(_currentPinInput);
    if (!mounted) return;
    if (isValid) {
      setState(() {
        _step = 2;
        _errorMessage = null;
      });
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _hasError = true;
        _errorMessage = 'Incorrect current PIN. Please try again.';
        _currentPinInput = '';
      });
    }
  }

  void _processStep2() {
    setState(() {
      _step = 3;
    });
  }

  void _processStep3() async {
    if (_confirmPinInput == _newPinInput) {
      final success = await AppLockService.instance.changePin(
        currentPin: _currentPinInput,
        newPin: _newPinInput,
      );
      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('App Lock PIN successfully updated!'),
              backgroundColor: AppColors.surfaceElevated,
            ),
          );
          widget.onSuccess?.call();
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = 'Failed to update PIN. Please try again.';
            _step = 2;
            _newPinInput = '';
            _confirmPinInput = '';
          });
        }
      }
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _hasError = true;
        _errorMessage = 'PINs do not match. Please re-enter new PIN.';
        _step = 2;
        _newPinInput = '';
        _confirmPinInput = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String stepTitle = 'Enter Current PIN';
    String stepSubtitle = 'Please enter your current 4-digit security PIN';
    String currentVal = _currentPinInput;

    if (_step == 2) {
      stepTitle = 'Create New PIN';
      stepSubtitle = 'Choose a secure 4-digit PIN for instant access';
      currentVal = _newPinInput;
    } else if (_step == 3) {
      stepTitle = 'Confirm New PIN';
      stepSubtitle = 'Re-enter your new 4-digit PIN to confirm';
      currentVal = _confirmPinInput;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(stepTitle, style: AppTypography.titleLarge),
          const SizedBox(height: 6),
          Text(stepSubtitle, style: AppTypography.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 24),

          // 4-dot Indicator
          Center(
            child: PinDotIndicator(
              length: 4,
              filledCount: currentVal.length,
              isMasked: true,
              enteredValue: currentVal,
              hasError: _hasError,
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 24),
          NumericKeypad(
            onKeyPressed: _onKeyPressed,
            onDeletePressed: _onDeletePressed,
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordSheetContent extends StatefulWidget {
  final VoidCallback? onSuccess;
  const _ChangePasswordSheetContent({this.onSuccess});

  @override
  State<_ChangePasswordSheetContent> createState() => _ChangePasswordSheetContentState();
}

class _ChangePasswordSheetContentState extends State<_ChangePasswordSheetContent> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  String? _currentError;
  String? _newError;
  String? _confirmError;
  String? _generalError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _currentError = null;
      _newError = null;
      _confirmError = null;
      _generalError = null;

      final current = _currentPasswordController.text;
      final newPass = _newPasswordController.text;
      final confirm = _confirmPasswordController.text;

      if (current.isEmpty) {
        _currentError = 'Current password is required';
        valid = false;
      }

      if (newPass.isEmpty) {
        _newError = 'New password is required';
        valid = false;
      } else if (newPass.length < 8) {
        _newError = 'Password must be at least 8 characters long';
        valid = false;
      }

      if (confirm.isEmpty) {
        _confirmError = 'Please confirm your new password';
        valid = false;
      } else if (newPass != confirm) {
        _confirmError = 'Passwords do not match';
        valid = false;
      }
    });
    return valid;
  }

  Future<void> _submitChangePassword() async {
    if (!_validate()) return;

    setState(() {
      _isLoading = true;
      _generalError = null;
    });

    try {
      final success = await AuthRepository().changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Account password successfully updated!'),
              backgroundColor: AppColors.surfaceElevated,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
            ),
          );
          widget.onSuccess?.call();
        } else {
          setState(() {
            _isLoading = false;
            _generalError = 'Failed to update password. Please check your current password.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          final msg = e.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', '');
          _generalError = msg.isNotEmpty ? msg : 'Error updating password. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Change Password', style: AppTypography.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Enter your current password followed by your new password',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 20),

            if (_generalError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _generalError!,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            FintechTextField(
              label: 'Current Password',
              hintText: 'Enter current password',
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryGreen, size: 20),
              obscureText: _obscureCurrent,
              controller: _currentPasswordController,
              errorText: _currentError,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              onChanged: (_) {
                if (_currentError != null) setState(() => _currentError = null);
              },
            ),
            const SizedBox(height: 16),

            FintechTextField(
              label: 'New Password (min. 8 characters)',
              hintText: 'Enter new password',
              prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.primaryGreen, size: 20),
              obscureText: _obscureNew,
              controller: _newPasswordController,
              errorText: _newError,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
              onChanged: (_) {
                if (_newError != null) setState(() => _newError = null);
              },
            ),
            const SizedBox(height: 16),

            FintechTextField(
              label: 'Confirm New Password',
              hintText: 'Re-enter new password',
              prefixIcon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.primaryGreen, size: 20),
              obscureText: _obscureConfirm,
              controller: _confirmPasswordController,
              errorText: _confirmError,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              onChanged: (_) {
                if (_confirmError != null) setState(() => _confirmError = null);
              },
            ),
            const SizedBox(height: 24),

            PrimaryButton(
              text: 'Update Password',
              isLoading: _isLoading,
              onPressed: _submitChangePassword,
            ),
          ],
        ),
      ),
    );
  }
}
