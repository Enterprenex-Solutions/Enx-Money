import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/env.dart';
import '../../../../core/constants/app_colors.dart';

// ============================================================================
// 1. PRIVACY POLICY SCREEN (Official 14 Chapters from PDF)
// ============================================================================
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';

  final List<Map<String, String>> _sections = [
    {
      'title': '1. Introduction and Scope',
      'body':
          '1.1 Who We Are:\n'
          'Enterprenex Solutions Pvt. Ltd. ("ENX Money", "we", "us", or "our") operates the ENX Money mobile and web application (the "Platform"), a digital business finance and ledger management tool designed for Indian micro, small, and medium enterprises (MSMEs).\n\n'
          'Under the Digital Personal Data Protection Act, 2023 ("DPDP Act") and the Digital Personal Data Protection Rules, 2025, ENX Money acts as a Data Fiduciary in respect of the personal data of its registered merchant users, and facilitates its merchant users (acting as independent data controllers of their own customer records) in maintaining their business ledgers.\n\n'
          '1.2 Scope of This Policy:\n'
          'This Privacy Policy applies to personal data collected through our mobile application, web portal (https://enxmoney.enterprenex.solutions), and related backend services. It explains what data we collect, why we collect it, how it is protected, and your statutory rights under Indian law.\n\n'
          '1.3 Important Note on Multi-Tenant Ledger Data:\n'
          'ENX Money provides a multi-tenant business bookkeeping utility. When you record transaction entries, customer names, contact numbers, and invoice records, you act as the independent Data Fiduciary for those counterparty records. ENX Money acts as a Data Processor providing the digital infrastructure, enforcing strict database-level tenant isolation.',
    },
    {
      'title': '2. Data We Collect',
      'body':
          '2.1 Account and Identity Data:\n'
          '• Identity: Full legal name, business name, date of registration.\n'
          '• Contact: Email address, mobile phone number, business billing address.\n'
          '• Business Identifiers: GSTIN, business type/industry, state of registration.\n'
          '• Credentials: Salted bcrypt password hashes (10 salt rounds), signed JSON Web Tokens (JWT).\n\n'
          '2.2 Biometric and Authentication Data:\n'
          'ENX Money does NOT collect, store, transmit, or have access to any raw biometric data. Biometric authentication (Fingerprint, Face Unlock) is performed entirely on your device by your operating system via Android BiometricPrompt / iOS LocalAuthentication. Only public key cryptographic assertions (WebAuthn/FIDO2) are verified on our servers.\n\n'
          '2.3 Financial and Business Data:\n'
          '• Customer and supplier details entered by you.\n'
          '• Transaction records ("Gave ₹" credit and "Got ₹" payment entries, dates, payment modes including Cash, UPI, Bank Transfer, and Cheque).\n'
          '• GST invoice details (line items, HSN/SAC codes, CGST/SGST/IGST tax rates).\n'
          '• Loan EMI calculation parameters (principal, interest rate, tenure, payment schedules).\n'
          'Note: ENX Money does not store raw credit/debit card numbers or bank account net-banking passwords.\n\n'
          '2.4 Technical and Usage Data:\n'
          '• Device operating system, client app version, and connection state.\n'
          '• IP address for network security, rate limiting, and fraud prevention.\n'
          '• Diagnostics and error logs (strictly redacted of passwords, OTPs, and personal financial figures).\n\n'
          '2.5 Data We Do Not Collect:\n'
          '• Zero raw biometric data (fingerprint scans, facial images).\n'
          '• Zero plaintext passwords.\n'
          '• Zero contact address book uploads (native system picker used on-demand only).\n'
          '• Zero background GPS sensor tracking.\n'
          '• Zero SMS reading or call log surveillance.\n'
          '• Zero third-party advertising identifiers (AAID, IDFA) or behavioral ad cookies.',
    },
    {
      'title': '3. Purpose of Collection and Legal Basis',
      'body':
          '3.1 Purpose Limitation:\n'
          'In strict accordance with the DPDP Act purpose limitation principle, personal data is processed solely for specific stated purposes:\n'
          '• Name, Email, Phone: Account creation, 6-digit OTP verification, session security, and account recovery.\n'
          '• GSTIN & Business Address: Generating tax-compliant invoices and GSTR-1/GSTR-3B export calculations.\n'
          '• Passkey Public Key: Fast, passwordless local biometric login via asymmetric cryptography.\n'
          '• Financial & Khata Records: Computing ledger balances, tracking dues, generating PDF/Excel reports, and cash flow analysis.\n\n'
          '3.2 Legal Basis for Processing:\n'
          '• Consent: Freely given, specific, informed, and unambiguous consent obtained at account registration.\n'
          '• Contractual Necessity: Processing required to deliver digital bookkeeping features requested by the user.\n'
          '• Legal Compliance: Retaining transaction records and tax invoices as mandated by Indian tax and corporate laws.\n\n'
          '3.3 Consent Standards:\n'
          'Consent is collected through clear affirmative action. Where you use a Consent Manager registered under DPDP Rules, 2025, we will honor consent signals routed through that Consent Manager.',
    },
    {
      'title': '4. How We Share Your Data',
      'body':
          '4.1 Third-Party Processors:\n'
          'We share limited data with verified service providers strictly to operate the Platform under contractual data processing terms:\n'
          '• Email / SMTP Relay (Gmail SMTP / Brevo): Transmits registered email address solely to deliver 6-digit verification OTP codes and security alerts.\n'
          '• Cloud Backend & Database (Render / Managed MySQL): Secure cloud infrastructure providing relational database storage, utilizing TLS 1.3 in transit and AES-256 encryption at rest.\n\n'
          '4.2 We Do Not Sell Your Data:\n'
          'We NEVER sell, rent, monetize, or trade your personal or financial data to advertising networks, data brokers, or marketing intermediaries.\n\n'
          '4.3 Disclosure Required by Law:\n'
          'We disclose personal data only when strictly required by a court order, law enforcement warrant, or binding statutory regulatory authority under applicable Indian law.\n\n'
          '4.4 Business Transfers:\n'
          'In the event of a merger, acquisition, or corporate reorganization, customer data will continue to be governed by the protections of this Privacy Policy.',
    },
    {
      'title': '5. Data Retention & Deletion Policy',
      'body':
          '5.1 Retention Principles:\n'
          'We retain personal data only for as long as necessary to fulfill the purpose for which it was collected, or as required by applicable Indian statutes:\n'
          '• Account Profile: Retained while the account is active; personal identity credentials permanently purged upon verified account deletion.\n'
          '• Active Session JWTs: Expire automatically after 7 days; revoked immediately upon logout or deletion.\n'
          '• Ephemeral OTPs: Automatically purged within 5 minutes or immediately after successful verification.\n'
          '• Financial Ledger Entries & Invoices: Retained in anonymized, decoupled format for up to 8 years in strict accordance with the Indian Companies Act, 2013 and GST statutory requirements.\n'
          '• Operational Diagnostics: Automated rolling retention cycle of 30 days.\n\n'
          '5.2 Direct In-App & Web Deletion Pathways:\n'
          'In compliance with Google Play Account Deletion requirements, users may permanently delete their account and associated data at any time via:\n'
          '1. In-App: Profile & Settings > Data & Privacy > Delete Account & Data.\n'
          '2. Public Web Portal: https://enxmoney.enterprenex.solutions/delete-account (no app installation required).\n'
          'Account deletion permanently invalidates credentials, revokes active tokens, and purges personal profile identifiers within 30 days.',
    },
    {
      'title': '6. How We Protect Your Data',
      'body':
          '6.1 Technical Safeguards:\n'
          '• 100% HTTPS / TLS 1.3 transport encryption with HTTP Strict Transport Security (HSTS).\n'
          '• Irreversible salted bcrypt password hashing (10 salt rounds).\n'
          '• Asymmetric WebAuthn/FIDO2 public-key cryptography (ES256/RS256) for biometric security.\n'
          '• Multi-tenant database isolation with strict business_id query-level scoping, preventing Insecure Direct Object References (IDOR).\n'
          '• Parameterized SQL queries mitigating SQL injection.\n'
          '• Express Helmet HTTP security headers and Content Security Policy.\n'
          '• Rate limiting on sensitive endpoints via express-rate-limit to protect against brute-force attacks.\n'
          '• Strict environment variable secret management.\n\n'
          '6.2 Organisational Safeguards:\n'
          '• Role-based access control (Owner, Admin, Staff, Accountant).\n'
          '• Least privilege access policies for internal engineering staff.\n'
          '• Never-log sanitization: passwords, tokens, and OTPs are redacted from server logs.\n\n'
          '6.3 Data Breach Notification:\n'
          'In the event of a confirmed personal data breach affecting users, we will notify the Data Protection Board of India and affected users within the timelines mandated by the DPDP Rules, 2025 and CERT-In directions.',
    },
    {
      'title': '7. Your Rights as a Data Principal',
      'body':
          'Under the Digital Personal Data Protection Act, 2023, you possess enforceable statutory rights:\n'
          '• Right to Access: Obtain a summary of personal data held about you and processing activities carried out.\n'
          '• Right to Correction: Request correction of inaccurate, misleading, or incomplete personal data via Profile & Settings > Edit Profile.\n'
          '• Right to Erasure: Request permanent deletion of personal data no longer necessary for the original purpose, subject to statutory 8-year tax limits.\n'
          '• Right to Withdraw Consent: Withdraw consent at any time without impacting the lawfulness of prior processing.\n'
          '• Right to Nominate: Nominate another individual to exercise your data rights in the event of death or incapacity.\n'
          '• Right to Grievance Redressal: File a complaint directly with our Grievance Officer.\n\n'
          '7.1 How to Exercise Your Rights:\n'
          '1. Directly within the app via Profile & Settings > Data & Privacy Dashboard.\n'
          '2. By emailing our Grievance Officer at privacy@enxmoney.com.',
    },
    {
      'title': '8. Grievance Redressal',
      'body':
          'In accordance with Section 8 of the DPDP Act, 2023, Enterprenex Solutions Pvt. Ltd. has appointed an official Grievance Officer to address all data privacy concerns:\n\n'
          '• Company: Enterprenex Solutions Pvt. Ltd.\n'
          '• Grievance / Privacy Officer: Mr. Rohit Pawar (Data Protection Officer)\n'
          '• Contact Phone: +91-9226860060 (Mon–Sat, 10:00 AM – 6:00 PM IST)\n'
          '• Grievance Email: grievance@enxmoney.com\n'
          '• Privacy Compliance Email: privacy@enxmoney.com\n'
          '• Registered Office Address: Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, Maharashtra - 431136, India\n'
          '• Response Timeline: We acknowledge all grievances within 48 hours and resolve them within 30 days.\n\n'
          'If you are not satisfied with our resolution, you have the statutory right to escalate your complaint to the Data Protection Board of India.',
    },
    {
      'title': '9. Children\'s Data',
      'body':
          'ENX Money is intended exclusively for use by business owners, independent entrepreneurs, and individuals aged 18 years and above.\n\n'
          'We do not knowingly market to or collect personal data from minors under the age of 18. If we become aware that an account has been created by a minor, all associated personal information will be promptly purged from our active databases. Parents or guardians may contact us at privacy@enxmoney.com if they believe a minor has registered an account.',
    },
    {
      'title': '10. International Data Transfers',
      'body':
          'Your data is primarily stored and processed on secure cloud infrastructure located within India.\n\n'
          'Where any data processor is located outside India (e.g., global SMTP delivery relays), such transfers are conducted in strict compliance with the cross-border data transfer provisions of the DPDP Act, 2023 and DPDP Rules, 2025, which permit transfers except to countries specifically restricted by the Central Government of India.',
    },
    {
      'title': '11. Cookies and Similar Technologies',
      'body':
          'Our web application utilizes strictly necessary HTTP cookies and local browser storage (SharedPreferences / localStorage) solely to maintain authenticated user login sessions, manage active theme preferences (Light/Dark mode), and secure state.\n\n'
          'We do NOT use third-party advertising cookies, cross-site tracking pixels, or behavioral analytics cookies.',
    },
    {
      'title': '12. Changes to This Privacy Policy',
      'body':
          'We may update this Privacy Policy periodically to reflect new application features, operational updates, or legal and regulatory developments under Indian law and Google Play policies.\n\n'
          'When modifications are published, the "Last Updated" date will be updated, notice will be posted on our public web portal (https://enxmoney.enterprenex.solutions/privacy-policy), and registered users will be notified in-app for material changes. Continued use of the Platform after such updates constitutes acceptance of the revised terms.',
    },
    {
      'title': '13. Governing Law and Jurisdiction',
      'body':
          'This Privacy Policy is governed by and construed in accordance with the laws of the Republic of India, including the Digital Personal Data Protection Act, 2023, the Information Technology Act, 2000, and rules framed thereunder.\n\n'
          'Any disputes arising in connection with this Policy shall be subject to the exclusive jurisdiction of the competent courts at Chhatrapati Sambhajinagar, Maharashtra, India.',
    },
    {
      'title': '14. Contact Us',
      'body':
          'For any inquiries, privacy concerns, or compliance requests regarding this Privacy Policy, please contact our official compliance desk:\n\n'
          '• Operating Entity: Enterprenex Solutions Pvt. Ltd.\n'
          '• Grievance / Privacy Officer: Mr. Rohit Pawar (Data Protection Officer)\n'
          '• Contact Phone: +91-9226860060 (Mon–Sat, 10:00 AM – 6:00 PM IST)\n'
          '• Corporate Legal Email: info@enterprenex.solutions\n'
          '• Billing Inquiries: billing@enterprenex.solutions\n'
          '• Technical Support Email: support@enterprenex.solutions\n'
          '• Privacy Desk Email: privacy@enxmoney.com\n'
          '• Grievance Redressal: grievance@enxmoney.com\n'
          '• Website Domain: https://enxmoney.enterprenex.solutions\n'
          '• GitHub Documentation: https://enterprenex-solution-pvt-ltd.github.io/Enx-Money/\n'
          '• Registered Office: Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, Maharashtra - 431136, India',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0B0E14) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF141824) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final borderColor = isDark ? const Color(0xFF1F293D) : const Color(0xFFE2E8F0);

    final filtered = _filterQuery.isEmpty
        ? _sections
        : _sections
            .where((s) =>
                s['title']!.toLowerCase().contains(_filterQuery.toLowerCase()) ||
                s['body']!.toLowerCase().contains(_filterQuery.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Navigator.canPop(context) ? Icons.arrow_back_rounded : Icons.home_rounded,
            color: textColor,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
        title: Text(
          'Privacy Policy',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy Link',
            icon: const Icon(Icons.share_outlined, color: AppColors.primaryGreen, size: 20),
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: 'https://enxmoney.enterprenex.solutions/privacy-policy'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy Policy URL copied to clipboard')),
              );
            },
          ),
          IconButton(
            tooltip: 'Contact Privacy Officer',
            icon: const Icon(Icons.email_outlined, color: AppColors.primaryGreen, size: 20),
            onPressed: () async {
              final uri = Uri.parse('mailto:privacy@enxmoney.com?subject=ENX%20Money%20Privacy%20Inquiry');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text('₹', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ENX Money • Privacy Policy',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  Env.companyName,
                                  style: TextStyle(fontSize: 12, color: subtextColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildBadge('v3.2.0', AppColors.primaryGreen),
                          _buildBadge('Google Play Verified', Colors.blue),
                          _buildBadge('DPDP Act Compliant', Colors.teal),
                          _buildBadge('Effective: Sep 2026', Colors.amber),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search Box
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _filterQuery = val.trim()),
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search policy sections (e.g., contacts, deletion, OTP)...',
                    hintStyle: TextStyle(color: subtextColor, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: subtextColor, size: 20),
                    suffixIcon: _filterQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _filterQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: cardColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGreen)),
                  ),
                ),
                const SizedBox(height: 16),

                // Policy Sections
                ...filtered.map((sec) => _buildSectionCard(sec['title']!, sec['body']!, cardColor, borderColor, textColor, subtextColor)),

                const SizedBox(height: 10),
                _buildContactCard(cardColor, borderColor, textColor, subtextColor),

                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Permanent Production Document • ${Env.companyName}',
                    style: TextStyle(fontSize: 11, color: subtextColor),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _buildSectionCard(String title, String body, Color cardColor, Color borderColor, Color textColor, Color subtextColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryGreen,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              color: subtextColor,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Color cardColor, Color borderColor, Color textColor, Color subtextColor) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield_outlined, color: AppColors.primaryGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Official Grievance & Compliance Desk',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'DPDP Act, 2023 Statutory Point of Contact',
                      style: TextStyle(fontSize: 11, color: subtextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 14),
          _buildContactInfoRow(Icons.business_outlined, 'Company Name', Env.companyName, textColor, subtextColor),
          const SizedBox(height: 8),
          _buildContactInfoRow(Icons.person_outline_rounded, 'Grievance / Privacy Officer', '${Env.grievanceOfficer} (Data Protection Officer)', textColor, subtextColor),
          const SizedBox(height: 8),
          _buildContactInfoRow(Icons.phone_outlined, 'Phone Number', Env.supportPhone, textColor, subtextColor),
          const SizedBox(height: 8),
          _buildContactInfoRow(Icons.receipt_long_outlined, 'Billing Email', Env.billingEmail, textColor, subtextColor),
          const SizedBox(height: 8),
          _buildContactInfoRow(Icons.mail_outline_rounded, 'General / Legal Email', Env.legalEmail, textColor, subtextColor),
          const SizedBox(height: 8),
          _buildContactInfoRow(Icons.support_agent_outlined, 'Technical Support Email', Env.supportEmail, textColor, subtextColor),
          const SizedBox(height: 8),
          _buildContactInfoRow(Icons.gavel_rounded, 'Privacy & Grievance Email', Env.privacyEmail, textColor, subtextColor),
          const SizedBox(height: 8),
          _buildContactInfoRow(Icons.language_rounded, 'Website Domain', Env.webPortalUrl, textColor, subtextColor),
          const SizedBox(height: 8),
          _buildContactInfoRow(Icons.code_rounded, 'GitHub Documentation', Env.legalPoliciesHost, textColor, subtextColor),
          const SizedBox(height: 8),
          _buildContactInfoRow(Icons.location_on_outlined, 'Registered Address', Env.registeredAddress, textColor, subtextColor),
          const SizedBox(height: 16),
          // Interactive Action Buttons
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.call_rounded, size: 16, color: Colors.white),
                label: Text(Env.supportPhone, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final uri = Uri.parse('tel:${Env.supportPhone.replaceAll(RegExp(r'[^0-9+]'), '')}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.primaryGreen),
                label: Text(Env.billingEmail, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryGreen),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final uri = Uri.parse('mailto:${Env.billingEmail}?subject=Billing%20Inquiry%20-%20ENX%20Money');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.mail_outline_rounded, size: 16, color: AppColors.primaryGreen),
                label: Text(Env.legalEmail, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final uri = Uri.parse('mailto:${Env.legalEmail}?subject=Corporate%20Inquiry%20-%20ENX%20Money');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.support_agent_rounded, size: 16, color: AppColors.primaryGreen),
                label: Text(Env.supportEmail, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final uri = Uri.parse('mailto:${Env.supportEmail}?subject=Support%20Inquiry%20-%20ENX%20Money');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.gavel_rounded, size: 16, color: AppColors.primaryGreen),
                label: Text(Env.privacyEmail, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final uri = Uri.parse('mailto:${Env.privacyEmail}?subject=DPDP%20Act%20Inquiry%20-%20ENX%20Money');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoRow(IconData icon, String label, String value, Color textColor, Color subtextColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primaryGreen),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12, color: subtextColor, height: 1.4),
              children: [
                TextSpan(text: '$label: ', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 2. TERMS & CONDITIONS SCREEN (Official 13 Chapters from PDF)
// ============================================================================
class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  State<TermsAndConditionsScreen> createState() => _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';

  final List<Map<String, String>> _termsSections = [
    {
      'title': '1. Acceptance of Terms',
      'body':
          '1.1 Agreement to Terms:\n'
          'These Terms & Conditions ("Terms") constitute a legally binding agreement between you ("User", "Merchant", "you") and Enterprenex Solutions Pvt. Ltd. ("ENX Money", "we", "us", "our"), governing your access to and use of the ENX Money mobile application, web application, and related bookkeeping and financial services (collectively, the "Platform").\n\n'
          'By creating an account, verifying your email One-Time Password (OTP), setting a password, or enabling biometric/passkey login, you confirm that you have read, understood, and agree to be bound by these Terms and our Privacy Policy. If you do not agree, you must not access or use the Platform.\n\n'
          '1.2 Changes to the Platform or Terms:\n'
          'We may update these Terms from time to time to reflect new features, statutory legal requirements, or changes to our services. We will notify you of material changes via in-app notification or email at least thirty (30) days in advance. Continued use of the Platform after such changes take effect constitutes your acceptance of the revised Terms.',
    },
    {
      'title': '2. Eligibility and Account Registration',
      'body':
          '2.1 Who May Use ENX Money:\n'
          '• You must be at least 18 years of age and capable of entering into a legally binding contract under the Indian Contract Act, 1872. Use by minors is strictly prohibited.\n'
          '• You must be registering on behalf of a legitimate business, freelance practice, or personal finance need within the Republic of India.\n'
          '• You must provide accurate, current, and complete registration information (legal name, email, mobile number, and GSTIN where applicable).\n\n'
          '2.2 Account Creation Process:\n'
          'Registration follows our secure verification pipeline: (1) basic identity details, (2) 6-digit email OTP verification, (3) secure password creation, and (4) optional WebAuthn/FIDO2 hardware passkey enrolment.\n\n'
          '2.3 Account Security:\n'
          'You are solely responsible for maintaining the confidentiality of your credentials, App Lock PIN, and devices. Notify support@enterprenex.solutions immediately if you suspect unauthorized access.\n\n'
          '2.4 Multi-User Roles:\n'
          'When enabling multi-user access (Owner, Admin, Staff, Accountant), the business owner is responsible for assigning permission levels, monitoring actions taken by designated staff, and promptly revoking access upon termination of employment.',
    },
    {
      'title': '3. Description of Service',
      'body':
          'ENX Money provides the following core digital bookkeeping and financial features, subject to availability:\n\n'
          '• Customer Management: Maintain customer records, credit ledgers (Khata), payment settlement tracking, and transaction history.\n'
          '• Business & Personal Finance: Track business and personal finances under segregated multi-account ledgers with category tagging.\n'
          '• Analytics & Reporting: Visual dashboards, income/expense breakdown, and exportable PDF, Excel, and Power BI financial summaries.\n'
          '• Inventory & Supplies: Stock tracking, purchase orders, and supplier directory.\n'
          '• Transactions & Cashbook: Real-time credit/debit records, payment modes (Cash, UPI, Bank Transfer, Cheque).\n'
          '• Loan EMI Tracking: Amortization tracking and installment calculation (informational simulation tool, not lending).\n'
          '• GST Invoicing: Automated CGST, SGST, and IGST tax calculations with HSN/SAC code support.',
    },
    {
      'title': '4. User Responsibilities',
      'body':
          '4.1 Accuracy of Data You Enter:\n'
          'You are solely responsible for the accuracy, completeness, and legality of all data you input into the Platform, including customer and supplier details, ledger entries, GSTIN numbers, HSN/SAC codes, and tax rates applied to invoices.\n\n'
          '4.2 Lawful Use Only:\n'
          'You agree to use ENX Money exclusively for lawful business and personal finance. You must not use the Platform for fraudulent transactions, tax evasion, money laundering, reverse-engineering, scraping, or automated abuse.\n\n'
          '4.3 Your Obligations Toward Your Own Customers\' Data:\n'
          'As specified in our Privacy Policy, ENX Money operates as a Data Processor for end-customer records. Merchants act as the independent Data Fiduciary under the DPDP Act, 2023 and must possess a lawful basis for collecting and storing customer details.',
    },
    {
      'title': '5. Fees and Subscriptions',
      'body':
          '5.1 Current Pricing:\n'
          'Core bookkeeping and Khata features of ENX Money are currently provided free of charge during our production MVP phase.\n\n'
          '5.2 Future Changes to Fees:\n'
          'We reserve the right to introduce optional premium subscription tiers or add-on features. If fee adjustments occur, we will provide at least thirty (30) days advance notice via email or prominent in-app notification prior to implementation.\n\n'
          '5.3 Refunds:\n'
          'Any future paid features and subscriptions are governed strictly by our official Refund & Cancellation Policy.',
    },
    {
      'title': '6. Disclaimers',
      'body':
          '6.1 Not a Financial Institution:\n'
          'ENX Money is an informational digital software utility for bookkeeping. We are NOT a bank, Non-Banking Financial Company (NBFC), lender, payment aggregator, escrow agent, or tax consultant. We do not extend credit, process loan disbursements, or hold customer funds.\n\n'
          '6.2 GST Calculation Disclaimer:\n'
          'Automated tax computations (CGST/SGST/IGST) are provided for convenience. Merchants remain solely responsible for tax filings and must verify figures with a qualified Chartered Accountant before filing statutory GSTR returns.\n\n'
          '6.3 Loan EMI Disclaimer:\n'
          'The EMI calculator is an informational simulation tool only. Actual terms, interest calculations, and fees determined by your lending bank or NBFC shall prevail.\n\n'
          '6.4 Analytics and Business Decisions:\n'
          'Visual dashboards and business analytics support, but never substitute for, independent commercial judgment.\n\n'
          '6.5 Service Availability:\n'
          'The Platform is provided on an "as is" and "as available" basis without warranties of uninterrupted uptime.',
    },
    {
      'title': '7. Intellectual Property',
      'body':
          '7.1 Our Ownership:\n'
          'All software code, algorithms, visual interfaces, brand trademarks, logos, and underlying technology are the exclusive intellectual property of Enterprenex Solutions Pvt. Ltd.\n\n'
          '7.2 Your Data Remains Yours:\n'
          'You retain full, exclusive proprietary ownership of all business records, customer ledgers, invoices, and transaction entries input into the Platform.\n\n'
          '7.3 Licence to Use the Platform:\n'
          'We grant you a revocable, non-exclusive, non-transferable licence to access and use the Platform in compliance with these Terms.',
    },
    {
      'title': '8. Third-Party Services',
      'body':
          'The Platform integrates with trusted third-party providers for transactional email delivery (Gmail SMTP, Brevo), cloud database hosting (Render / MySQL), and optional messaging gateways. Your use of third-party features is subject to their respective terms and service availability.',
    },
    {
      'title': '9. Limitation of Liability',
      'body':
          '9.1 Limitation:\n'
          'To the maximum extent permitted under applicable Indian law, Enterprenex Solutions Pvt. Ltd. and its directors shall not be liable for indirect, incidental, special, consequential, or punitive damages.\n\n'
          '9.2 Cap on Liability:\n'
          'In all events, our total aggregate liability arising out of or related to the Platform is capped at the total fees paid by you to ENX Money in the preceding 12 months, or INR 1,000 if used free of charge.\n\n'
          '9.3 Indemnification:\n'
          'You agree to defend, indemnify, and hold harmless Enterprenex Solutions Pvt. Ltd. from any claims or liabilities arising from your breach of these Terms or misuse of customer data.',
    },
    {
      'title': '10. Suspension and Termination',
      'body':
          '10.1 Termination by You:\n'
          'You may close your account and initiate data erasure at any time via: Settings > Data & Privacy > Delete Account, or through our public web portal at https://enxmoney.enterprenex.solutions/delete-account.\n\n'
          '10.2 Termination or Suspension by Us:\n'
          'We may suspend or terminate accounts in instances of fraud, security compromise, illegal activity, or severe breach of Terms.\n\n'
          '10.3 Effect of Termination:\n'
          'Upon account termination, access ceases immediately. Sections regarding Intellectual Property, Disclaimers, Liability, and Governing Law survive.',
    },
    {
      'title': '11. Governing Law and Dispute Resolution',
      'body':
          '11.1 Governing Law:\n'
          'These Terms are governed by and construed in accordance with the laws of the Republic of India, including the Indian Contract Act, 1872, the Information Technology Act, 2000, and the Digital Personal Data Protection Act, 2023.\n\n'
          '11.2 Amicable Dispute Resolution:\n'
          'In the event of a dispute, parties shall first attempt resolution through good-faith mutual consultation within thirty (30) days of written notice.\n\n'
          '11.3 Binding Arbitration & Jurisdiction:\n'
          'Unresolved disputes shall be referred to and finally resolved by binding arbitration under the Arbitration and Conciliation Act, 1996. The seat and venue of arbitration shall be Chhatrapati Sambhajinagar, Maharashtra, India, conducted in English. Subject to arbitration, the competent courts at Chhatrapati Sambhajinagar, Maharashtra shall have exclusive jurisdiction.',
    },
    {
      'title': '12. General Provisions',
      'body':
          '12.1 Entire Agreement:\n'
          'These Terms, together with our Privacy Policy and Refund Policy, constitute the entire agreement between you and ENX Money regarding your use of the Platform.\n\n'
          '12.2 Severability:\n'
          'If any provision is deemed unenforceable or invalid, the remaining provisions remain in full force.\n\n'
          '12.3 No Waiver:\n'
          'Failure to enforce any provision does not constitute a waiver of future enforcement.\n\n'
          '12.4 Force Majeure:\n'
          'We are not liable for performance failures resulting from natural disasters, telecommunications outages, or government actions.',
    },
    {
      'title': '13. Contact Us',
      'body':
          'For any questions about these Terms & Conditions, please contact:\n\n'
          '• Operating Entity: Enterprenex Solutions Pvt. Ltd.\n'
          '• Grievance / Privacy Officer: Mr. Rohit Pawar\n'
          '• Phone Number: +91-9226860060 (Mon–Sat, 10:00 AM – 6:00 PM IST)\n'
          '• Billing Inquiries: billing@enterprenex.solutions\n'
          '• Corporate Legal Email: info@enterprenex.solutions\n'
          '• Technical Support Email: support@enterprenex.solutions\n'
          '• Privacy Compliance Email: privacy@enxmoney.com\n'
          '• Website Domain: https://enxmoney.enterprenex.solutions\n'
          '• GitHub Documentation: https://enterprenex-solution-pvt-ltd.github.io/Enx-Money/\n'
          '• Registered Office Address: Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, Maharashtra - 431136, India',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0B0E14) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF141824) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final borderColor = isDark ? const Color(0xFF1F293D) : const Color(0xFFE2E8F0);

    final filtered = _filterQuery.isEmpty
        ? _termsSections
        : _termsSections
            .where((s) =>
                s['title']!.toLowerCase().contains(_filterQuery.toLowerCase()) ||
                s['body']!.toLowerCase().contains(_filterQuery.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Navigator.canPop(context) ? Icons.arrow_back_rounded : Icons.home_rounded,
            color: textColor,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
        title: Text(
          'Terms & Conditions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy Link',
            icon: const Icon(Icons.share_outlined, color: AppColors.primaryGreen, size: 20),
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: 'https://enxmoney.enterprenex.solutions/terms-and-conditions'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terms & Conditions URL copied to clipboard')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Terms & Conditions of Service',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${Env.companyName} • Policy v3.2.0 • Effective: September 1, 2026',
                        style: TextStyle(fontSize: 12, color: subtextColor),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Text(
                          'NOTICE: ENX Money is an informational software utility for bookkeeping and GST invoices. It is NOT a bank, payment processor, or certified tax consultant.',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.amber.shade200 : Colors.amber.shade900, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search Box
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _filterQuery = val.trim()),
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search terms & clauses...',
                    hintStyle: TextStyle(color: subtextColor, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: subtextColor, size: 20),
                    suffixIcon: _filterQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _filterQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: cardColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGreen)),
                  ),
                ),
                const SizedBox(height: 16),

                // Terms Sections
                ...filtered.map((sec) => _buildTermsCard(sec['title']!, sec['body']!, cardColor, borderColor, textColor, subtextColor)),

                const SizedBox(height: 10),
                _buildTermsContactCard(cardColor, borderColor, textColor, subtextColor),

                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Permanent Production Document • ${Env.companyName}',
                    style: TextStyle(fontSize: 11, color: subtextColor),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsCard(String title, String body, Color cardColor, Color borderColor, Color textColor, Color subtextColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3B82F6),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              color: subtextColor,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsContactCard(Color cardColor, Color borderColor, Color textColor, Color subtextColor) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.gavel_rounded, color: Color(0xFF3B82F6), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Legal & Contractual Inquiries',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${Env.companyName} Legal Desk',
                      style: TextStyle(fontSize: 11, color: subtextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 14),
          _buildTermsContactRow(Icons.business_outlined, 'Company Name', Env.companyName, textColor, subtextColor),
          const SizedBox(height: 8),
          _buildTermsContactRow(Icons.person_outline_rounded, 'Grievance / Privacy Officer', Env.grievanceOfficer, textColor, subtextColor),
          const SizedBox(height: 8),
          _buildTermsContactRow(Icons.phone_outlined, 'Phone Number', Env.supportPhone, textColor, subtextColor),
          const SizedBox(height: 8),
          _buildTermsContactRow(Icons.receipt_long_outlined, 'Billing Email', Env.billingEmail, textColor, subtextColor),
          const SizedBox(height: 8),
          _buildTermsContactRow(Icons.mail_outline_rounded, 'General / Legal Email', Env.legalEmail, textColor, subtextColor),
          const SizedBox(height: 8),
          _buildTermsContactRow(Icons.support_agent_outlined, 'Technical Support Email', Env.supportEmail, textColor, subtextColor),
          const SizedBox(height: 8),
          _buildTermsContactRow(Icons.language_rounded, 'Website Domain', Env.webPortalUrl, textColor, subtextColor),
          const SizedBox(height: 8),
          _buildTermsContactRow(Icons.code_rounded, 'GitHub Pages Host', Env.legalPoliciesHost, textColor, subtextColor),
          const SizedBox(height: 8),
          _buildTermsContactRow(Icons.location_on_outlined, 'Registered Address', Env.registeredAddress, textColor, subtextColor),
          const SizedBox(height: 16),
          // Interactive Action Buttons
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.call_rounded, size: 16, color: Colors.white),
                label: Text(Env.supportPhone, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final uri = Uri.parse('tel:${Env.supportPhone.replaceAll(RegExp(r'[^0-9+]'), '')}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF3B82F6)),
                label: Text(Env.billingEmail, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3B82F6)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final uri = Uri.parse('mailto:${Env.billingEmail}?subject=Billing%20Inquiry%20-%20ENX%20Money');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.mail_outline_rounded, size: 16, color: Color(0xFF3B82F6)),
                label: Text(Env.legalEmail, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3B82F6)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final uri = Uri.parse('mailto:${Env.legalEmail}?subject=Legal%20Inquiry%20-%20ENX%20Money');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.help_outline_rounded, size: 16, color: AppColors.primaryGreen),
                label: Text(Env.supportEmail, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final uri = Uri.parse('mailto:${Env.supportEmail}?subject=Support%20Inquiry%20-%20ENX%20Money');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTermsContactRow(IconData icon, String label, String value, Color textColor, Color subtextColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF3B82F6)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12, color: subtextColor, height: 1.4),
              children: [
                TextSpan(text: '$label: ', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 3. REFUND & CANCELLATION POLICY SCREEN (Official 9 Chapters from PDF)
// ============================================================================
class RefundCancellationPolicyScreen extends StatefulWidget {
  const RefundCancellationPolicyScreen({super.key});

  @override
  State<RefundCancellationPolicyScreen> createState() => _RefundCancellationPolicyScreenState();
}

class _RefundCancellationPolicyScreenState extends State<RefundCancellationPolicyScreen> {
  final List<Map<String, String>> _refundSections = [
    {
      'title': '1. Current Status of ENX Money (MVP Free Phase Notice)',
      'body':
          'ENX Money is currently offered free of charge during its MVP (Minimum Viable Product) phase. No payment is collected at signup, and therefore no refund is applicable at this time. This Policy describes how refunds and cancellations will be handled once paid subscription plans are introduced, and takes effect automatically from the date any paid plan is launched.\n\n'
          'If you are using ENX Money under a free plan, Chapters 2 onward of this document do not yet apply to you, but are published in advance for transparency about our future billing practices.',
    },
    {
      'title': '2. Scope of This Policy',
      'body':
          '2.1 What This Policy Covers:\n'
          '• Paid subscription plans for the ENX Money Platform (e.g., Starter, Business, Enterprise tiers).\n'
          '• Add-on features purchased separately (e.g., extra WhatsApp reminder credits, additional user seats).\n'
          '• Any one-time charges for premium exports or integrations, if introduced.\n\n'
          '2.2 What This Policy Does Not Cover:\n'
          '• Counterparty Ledger Transactions: Transactions, invoices, or payments you record within the app between you and your own customers – ENX Money is not a party to those transactions and cannot refund them.\n'
          '• Third-Party Gateway Fees: Payment gateway charges (e.g., payment processing fees), which are governed by the payment provider\'s own terms.\n'
          '• Data Entry Errors: Losses arising from your own data entry errors in ledgers, invoices, or EMI records.',
    },
    {
      'title': '3. Subscription Plans and Billing',
      'body':
          '3.1 Billing Cycle:\n'
          'Paid subscriptions are billed on a monthly or annual recurring basis, charged automatically to your registered payment method on each renewal date, unless cancelled before the renewal date.\n\n'
          '3.2 Free Trial (If Offered):\n'
          'If a free trial period (e.g., 14 days) is offered on a paid plan, you will not be charged until the trial ends. You may cancel at any time during the trial without any charge. If you do not cancel before the trial ends, your subscription will automatically convert to a paid plan and billing will begin.\n\n'
          '3.3 Auto-Renewal:\n'
          'All paid subscriptions renew automatically at the end of each billing cycle unless cancelled by you at least 24 hours before the renewal date. We will send a reminder notification 3 days before renewal where required by applicable payment regulations.\n\n'
          '3.4 Price Changes:\n'
          'We will notify you at least 30 days in advance of any change to your subscription price. Continued use after the notice period constitutes acceptance of the new price; you may cancel before the change takes effect if you do not agree.',
    },
    {
      'title': '4. How to Cancel',
      'body':
          '4.1 Cancelling Your Subscription:\n'
          'You may cancel your paid subscription at any time through:\n'
          '1. In-App Pathway: Settings > Subscription > Cancel Plan.\n'
          '2. Email: billing@enterprenex.solutions (from your registered account email).\n\n'
          '4.2 What Happens After Cancellation:\n'
          '• Continued Access: You will continue to have access to paid features until the end of your current billing period – cancellation does not cut off access immediately.\n'
          '• No Further Charges: No further charges will be made after the current billing period ends.\n'
          '• Plan Reversion: Your account will automatically revert to the free tier (if available) or be restricted to read-only/export access, depending on your plan.\n'
          '• Data Retention Rules: Your ledger, invoice, and transaction data is NOT deleted upon cancellation of a paid plan; it remains safely accessible subject to our Privacy Policy\'s data retention terms.\n\n'
          '4.3 Cancelling Your Account Entirely:\n'
          'Closing your ENX Money account entirely (not just a paid plan) is a separate action, available through Settings > Data & Privacy > Delete Account, or contacting support. Account closure does not automatically generate a refund for unused subscription time unless you qualify under Chapter 5.',
    },
    {
      'title': '5. Refund Eligibility',
      'body':
          '5.1 When You Are Eligible for a Refund:\n'
          '• Duplicate or Erroneous Charge: You were charged more than once for the same billing period, or charged due to a verified technical error on our end.\n'
          '• Service Non-Delivery: You paid for a plan or feature that was never activated on your account due to our fault.\n'
          '• Cancellation Within Refund Window (7 Days): You cancel within seven (7) days of a new subscription purchase (first-time subscribers only) and have not substantially used paid-tier features (e.g., bulk exports, Power BI embedded reports).\n'
          '• Statutory Right: Any refund right available to you under the Consumer Protection Act, 2019 or other applicable Indian law.\n\n'
          '5.2 When You Are Not Eligible for a Refund:\n'
          '• Changed Mind: You simply changed your mind after the 7-day refund window has passed.\n'
          '• Non-Usage: You did not use the Platform during the billing period (non-usage is not grounds for a refund, as access was made available).\n'
          '• Terms Breach: Your subscription was cancelled or suspended due to your breach of the Terms & Conditions.\n'
          '• Discontent with Calculations: You are dissatisfied with GST calculations, EMI estimates, or analytics outputs that were generated correctly based on the data you entered.\n'
          '• Partial-Month Usage: Partial-month usage after a mid-cycle cancellation (we do not pro-rate refunds for partially used billing periods, except where required by law).\n\n'
          '5.3 Refund Request Process:\n'
          '1. Email billing@enterprenex.solutions with your registered account email, transaction ID / invoice number, and reason for the refund request.\n'
          '2. We will acknowledge your request within 2 business days.\n'
          '3. We may request additional information to verify eligibility under Section 5.1.\n'
          '4. Approved refunds are processed within 7–10 business days to your original payment method.',
    },
    {
      'title': '6. Failed, Duplicate, and Disputed Payments',
      'body':
          '6.1 Failed Payment Charged in Error:\n'
          'If a payment attempt fails but an amount is still deducted from your account (a known issue with some payment gateways), this amount is typically auto-reversed by your bank/payment provider within 5–7 business days. If it is not reversed automatically, contact us with your transaction reference and we will coordinate with our payment gateway to resolve it.\n\n'
          '6.2 Duplicate Charges:\n'
          'If you are charged twice for the same billing period due to a technical error, the duplicate charge will be refunded in full within 7 business days of verification.\n\n'
          '6.3 Chargebacks and Payment Disputes:\n'
          'If you initiate a chargeback with your bank or card issuer without first contacting us, we reserve the right to suspend your account pending resolution of the dispute. We encourage you to contact billing@enterprenex.solutions first so we can resolve billing issues directly and faster than the chargeback process typically allows.',
    },
    {
      'title': '7. Refund Method and Timeline',
      'body':
          '7.1 How Refunds Are Issued:\n'
          'Approved refunds are credited back to the original payment method used for the transaction (card, UPI, net banking, or wallet), in accordance with your payment gateway\'s and bank\'s processing timelines.\n\n'
          '• UPI: 2–5 business days\n'
          '• Debit / Credit Card: 5–10 business days (subject to issuing bank)\n'
          '• Net Banking: 5–7 business days\n'
          '• Digital Wallet: 1–3 business days\n\n'
          'Actual refund timelines depend on your bank or payment provider and may vary beyond our control once the refund has been initiated from our end.',
    },
    {
      'title': '8. Special Cases',
      'body':
          '8.1 Enterprise / Custom Plans:\n'
          'Refund terms for Enterprise or custom-negotiated plans (if applicable) are governed by the specific agreement signed with your organisation, which takes precedence over this general Policy.\n\n'
          '8.2 Promotional or Discounted Subscriptions:\n'
          'Subscriptions purchased using a promotional code, discount, or free-credit offer are refunded, if eligible, only up to the actual amount paid by you (not the full list price).\n\n'
          '8.3 Add-On Purchases:\n'
          'Unused credits (e.g., extra WhatsApp reminder credits) are generally non-refundable but may be carried forward, subject to plan terms. Additional user seat purchases follow the same 7-day refund window as Section 5.1 if cancelled shortly after purchase and unused.',
    },
    {
      'title': '9. Contact Us',
      'body':
          'For any billing, refund, or cancellation queries, please contact our dedicated billing and customer support team:\n\n'
          '• Operating Entity: Enterprenex Solutions Pvt. Ltd.\n'
          '• Grievance / Privacy Officer: Mr. Rohit Pawar\n'
          '• Support Phone: +91-9226860060 (Mon–Sat, 10:00 AM – 6:00 PM IST)\n'
          '• Billing Support Email: billing@enterprenex.solutions\n'
          '• Corporate Legal Email: info@enterprenex.solutions\n'
          '• General Support Email: support@enterprenex.solutions\n'
          '• Website Domain: https://enxmoney.enterprenex.solutions\n'
          '• GitHub Documentation: https://enterprenex-solution-pvt-ltd.github.io/Enx-Money/\n'
          '• Registered Office Address: Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, Maharashtra - 431136, India',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0B0E14) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF141824) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final borderColor = isDark ? const Color(0xFF1F293D) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Navigator.canPop(context) ? Icons.arrow_back_rounded : Icons.home_rounded,
            color: textColor,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
        title: Text(
          'Refund & Cancellation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy Link',
            icon: const Icon(Icons.share_outlined, color: AppColors.primaryGreen, size: 20),
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: 'https://enxmoney.enterprenex.solutions/refund-cancellation-policy'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refund Policy URL copied to clipboard')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Refund & Cancellation Policy',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${Env.companyName} • Policy v3.2.0 • Effective: September 1, 2026',
                        style: TextStyle(fontSize: 12, color: subtextColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Sections
                ..._refundSections.map((sec) => _buildRefundCard(sec['title']!, sec['body']!, cardColor, borderColor, textColor, subtextColor)),

                const SizedBox(height: 12),
                _buildRefundContactCard(cardColor, borderColor, textColor, subtextColor),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Permanent Production Document • ${Env.companyName}',
                    style: TextStyle(fontSize: 11, color: subtextColor),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRefundContactCard(Color cardColor, Color borderColor, Color textColor, Color subtextColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.support_agent_rounded, color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Billing & Cancellation Inquiries',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Need assistance with your plan, duplicate charges, or refund requests? Our support team is available Monday to Saturday, 10:00 AM – 6:00 PM IST.',
            style: TextStyle(fontSize: 13, color: subtextColor, height: 1.45),
          ),
          const SizedBox(height: 16),
          _buildRefundContactRow(Icons.business_rounded, 'Company Name', Env.companyName, textColor, subtextColor),
          const SizedBox(height: 8),
          _buildRefundContactRow(Icons.person_pin_rounded, 'Grievance / Privacy Officer', Env.grievanceOfficer, textColor, subtextColor),
          const SizedBox(height: 8),
          _buildRefundContactRow(Icons.phone_outlined, 'Phone Number', Env.supportPhone, textColor, subtextColor),
          const SizedBox(height: 8),
          _buildRefundContactRow(Icons.receipt_long_outlined, 'Billing Email', Env.billingEmail, textColor, subtextColor),
          const SizedBox(height: 8),
          _buildRefundContactRow(Icons.mail_outline_rounded, 'General / Legal Email', Env.legalEmail, textColor, subtextColor),
          const SizedBox(height: 8),
          _buildRefundContactRow(Icons.support_agent_outlined, 'Technical Support Email', Env.supportEmail, textColor, subtextColor),
          const SizedBox(height: 8),
          _buildRefundContactRow(Icons.language_rounded, 'Website Domain', Env.webPortalUrl, textColor, subtextColor),
          const SizedBox(height: 8),
          _buildRefundContactRow(Icons.code_rounded, 'GitHub Documentation', Env.legalPoliciesHost, textColor, subtextColor),
          const SizedBox(height: 8),
          _buildRefundContactRow(Icons.location_on_outlined, 'Registered Address', Env.registeredAddress, textColor, subtextColor),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.phone, size: 16, color: Color(0xFF10B981)),
                label: Text('Call ${Env.supportPhone}', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF10B981)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final uri = Uri.parse('tel:${Env.supportPhone.replaceAll(RegExp(r'[^0-9+]'), '')}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF10B981)),
                label: const Text('Email Billing', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF10B981)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final uri = Uri.parse('mailto:${Env.billingEmail}?subject=Billing%20Inquiry%20-%20ENX%20Money');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.mail_outline_rounded, size: 16, color: Color(0xFF10B981)),
                label: const Text('General Email', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF10B981)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final uri = Uri.parse('mailto:${Env.legalEmail}?subject=Corporate%20Inquiry%20-%20ENX%20Money');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.support_agent_rounded, size: 16, color: Color(0xFF10B981)),
                label: const Text('Technical Support', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF10B981)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final uri = Uri.parse('mailto:${Env.supportEmail}?subject=Support%20Inquiry%20-%20ENX%20Money');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefundContactRow(IconData icon, String label, String value, Color textColor, Color subtextColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF10B981)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12, color: subtextColor, height: 1.4),
              children: [
                TextSpan(text: '$label: ', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRefundCard(String title, String body, Color cardColor, Color borderColor, Color textColor, Color subtextColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF10B981),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              color: subtextColor,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
