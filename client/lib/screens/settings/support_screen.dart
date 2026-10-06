import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../config/env.dart';

class SupportSettingsScreen extends StatelessWidget {
  const SupportSettingsScreen({super.key});

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

  void _copyToClipboard(String text, String label, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Text('$label copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        title: Text(
          'Contact & Support',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.headset_mic_rounded, color: AppColors.primaryGreen, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Env.companyName,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Official Support, Billing & Grievance Redressal Desk',
                              style: TextStyle(fontSize: 12, color: subtextColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Fast Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.phone_rounded,
                        label: 'Call Us',
                        subtitle: Env.supportPhone,
                        color: AppColors.primaryGreen,
                        onTap: () => _launchUrl('tel:+919226860060', context),
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        subtextColor: subtextColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'WhatsApp',
                        subtitle: Env.whatsappPhone,
                        color: const Color(0xFF25D366),
                        onTap: () => _launchUrl(Env.whatsappUrl, context),
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        subtextColor: subtextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.receipt_long_rounded,
                        label: 'Billing Support',
                        subtitle: Env.billingEmail,
                        color: Colors.blue,
                        onTap: () => _launchUrl('mailto:${Env.billingEmail}?subject=Billing%20Support', context),
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        subtextColor: subtextColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.support_agent_rounded,
                        label: 'Tech Support',
                        subtitle: Env.supportEmail,
                        color: Colors.teal,
                        onTap: () => _launchUrl('mailto:${Env.supportEmail}?subject=Technical%20Support', context),
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        subtextColor: subtextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Grievance Officer & Statutory Desk
                Text(
                  'STATUTORY GRIEVANCE & DPDP ACT COMPLIANCE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: subtextColor),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryGreen.withOpacity(0.35)),
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
                                  Env.grievanceOfficer,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Grievance Officer & Data Protection Officer (DPDP Act, 2023)',
                                  style: TextStyle(fontSize: 12, color: subtextColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: borderColor, height: 1),
                      const SizedBox(height: 16),

                      _buildDetailRow(
                        icon: Icons.business_outlined,
                        title: 'Operating Entity',
                        value: Env.companyName,
                        textColor: textColor,
                        subtextColor: subtextColor,
                        onCopy: () => _copyToClipboard(Env.companyName, 'Entity Name', context),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.phone_outlined,
                        title: 'Official Helpline',
                        value: Env.supportPhone,
                        textColor: textColor,
                        subtextColor: subtextColor,
                        onTap: () => _launchUrl('tel:+919226860060', context),
                        onCopy: () => _copyToClipboard(Env.supportPhone, 'Helpline', context),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'WhatsApp Official Desk',
                        value: Env.whatsappPhone,
                        textColor: textColor,
                        subtextColor: subtextColor,
                        onTap: () => _launchUrl(Env.whatsappUrl, context),
                        onCopy: () => _copyToClipboard(Env.whatsappPhone, 'WhatsApp Desk', context),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.receipt_long_outlined,
                        title: 'Billing Inquiries',
                        value: Env.billingEmail,
                        textColor: textColor,
                        subtextColor: subtextColor,
                        onTap: () => _launchUrl('mailto:${Env.billingEmail}', context),
                        onCopy: () => _copyToClipboard(Env.billingEmail, 'Billing Email', context),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.mail_outline_rounded,
                        title: 'General & Legal Inquiries',
                        value: Env.legalEmail,
                        textColor: textColor,
                        subtextColor: subtextColor,
                        onTap: () => _launchUrl('mailto:${Env.legalEmail}', context),
                        onCopy: () => _copyToClipboard(Env.legalEmail, 'General Email', context),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.language_rounded,
                        title: 'Web Portal',
                        value: Env.webPortalUrl,
                        textColor: textColor,
                        subtextColor: subtextColor,
                        onTap: () => _launchUrl(Env.webPortalUrl, context),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.link_rounded,
                        title: 'LinkedIn',
                        value: Env.linkedinUrl,
                        textColor: textColor,
                        subtextColor: subtextColor,
                        onTap: () => _launchUrl(Env.linkedinUrl, context),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.camera_alt_outlined,
                        title: 'Instagram',
                        value: Env.instagramUrl,
                        textColor: textColor,
                        subtextColor: subtextColor,
                        onTap: () => _launchUrl(Env.instagramUrl, context),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.location_on_outlined,
                        title: 'Registered Office Address',
                        value: Env.registeredAddress,
                        textColor: textColor,
                        subtextColor: subtextColor,
                        onCopy: () => _copyToClipboard(Env.registeredAddress, 'Registered Address', context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Permanent Document Footer
                Center(
                  child: Text(
                    'Permanent Production Document • ${Env.companyName}',
                    style: TextStyle(fontSize: 11, color: subtextColor),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: subtextColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required Color textColor,
    required Color subtextColor,
    VoidCallback? onTap,
    VoidCallback? onCopy,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primaryGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 11, color: subtextColor)),
              const SizedBox(height: 2),
              InkWell(
                onTap: onTap,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: onTap != null ? const Color(0xFF0066FF) : textColor,
                    decoration: onTap != null ? TextDecoration.underline : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (onCopy != null)
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primaryGreen),
            onPressed: onCopy,
            tooltip: 'Copy',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }
}
