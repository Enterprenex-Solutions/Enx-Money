import 'package:flutter/material.dart';
import 'pricing_screen.dart';

class UpgradePromptScreen extends StatelessWidget {
  final String feature;
  final String? featureName;
  final String? requiredTier;

  const UpgradePromptScreen({
    super.key,
    required this.feature,
    this.featureName,
    this.requiredTier = 'PRO',
  });

  String get _displayName {
    if (featureName != null && featureName!.isNotEmpty) return featureName!;
    return feature
        .split('_')
        .map((w) => w.isNotEmpty ? '${w[0]}${w.substring(1).toLowerCase()}' : '')
        .join(' ');
  }

  String get _description {
    switch (feature.toUpperCase()) {
      case 'WHATSAPP_CHATBOT':
        return 'Automate financial updates, track expenses via WhatsApp voice & text, and receive proactive payment reminders with our conversational AI agent.';
      case 'ADVANCED_REPORTS':
        return 'Unlock deep financial insights, custom date filters, multi-format exports (PDF, Excel), and comparative cash-flow analytics.';
      case 'ADVANCED_ANALYTICS':
        return 'Access predictive spending trends, machine-learning powered categorization, and merchant distribution breakdowns.';
      case 'GST_REPORT':
        return 'Generate GST-compliant tax filings, GSTR-1 & GSTR-3B preparation summaries, and tax invoice exports in one click.';
      case 'LOAN_MANAGEMENT':
        return 'Track personal and commercial loans, amortization schedules, automated EMI reminders, and early repayment calculators.';
      case 'SETTLEMENT':
        return 'Automate merchant settlements, T+1/T+0 reconciliation, and batch disbursement directly into linked bank accounts.';
      default:
        return 'Upgrade your subscription to unlock $_displayName and empower your financial workflows.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // Icon container with glow
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.lock_rounded, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 24),

              // Feature Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF6366F1)),
                ),
                child: Text(
                  'AVAILABLE ON ${requiredTier?.toUpperCase() ?? 'PRO'} & ABOVE',
                  style: const TextStyle(
                    color: Color(0xFF818CF8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Unlock $_displayName',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                _description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF94A3B8),
                  height: 1.5,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/settings/refund-policy'),
                  child: const Text(
                    '7-Day Satisfaction Guarantee • Refund Policy',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              // Upgrade Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const PricingScreen()),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rocket_launch, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'View Plans & Upgrade',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Dismiss
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Maybe Later',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
