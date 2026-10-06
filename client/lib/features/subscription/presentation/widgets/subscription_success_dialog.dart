// ENX Money — Verified Subscription Success Dialog
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/invoice_model.dart';
import '../../models/plan_model.dart';
import 'subscription_pdf_service.dart';

class SubscriptionSuccessDialog extends StatelessWidget {
  final PlanModel plan;
  final String billingCycle;
  final String receiptId;
  final double totalAmount;
  final SubscriptionInvoice? invoice;
  final Map<String, dynamic>? entitlements;
  final String merchantName;

  static final NumberFormat _fmt = NumberFormat('#,##0.00', 'en_IN');

  const SubscriptionSuccessDialog({
    super.key,
    required this.plan,
    required this.billingCycle,
    required this.receiptId,
    required this.totalAmount,
    this.invoice,
    this.entitlements,
    this.merchantName = 'ENX Money',
  });

  bool get _isBusiness =>
      plan.id.toLowerCase().contains('business') ||
      plan.id.toLowerCase().contains('advanced') ||
      plan.name.toUpperCase() == 'BUSINESS' ||
      plan.name.toUpperCase() == 'ADVANCED';

  String get _title => _isBusiness
      ? '🎉 Welcome to Business Suite!'
      : '🎉 Welcome to ${plan.displayName}!';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Success Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                _title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Live payment gateway signature verified (200 OK). Your subscription plan is now active.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12.5),
              ),
              const SizedBox(height: 16),

              // Verified Receipt Badge & Routing Details
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payment Status',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'VERIFIED & CAPTURED',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFF334155), height: 16),
                    _infoRow('Receipt ID', receiptId, highlight: true),
                    _infoRow('Plan Tier', plan.displayName),
                    _infoRow('Billing Cycle', billingCycle == 'YEARLY' ? 'Annual' : 'Monthly'),
                    _infoRow('Total Paid (incl. GST)', '₹${_fmt.format(totalAmount)}', color: const Color(0xFF10B981)),
                    _infoRow('Merchant', 'ENX Money (Enterprenex Solutions Pvt Ltd)'),
                    _infoRow('Payment Gateway', 'Razorpay / 256-Bit SSL Encrypted'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Unlocked Entitlements
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock_open_rounded, color: Color(0xFF10B981), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Unlocked Premium Features',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _featureLine('✓ WhatsApp Chatbot (Anjali) AI Assistant active'),
                    _featureLine('✓ Higher bank account limits & transaction routing'),
                    _featureLine('✓ Real-time audit ledgers & GST Tax Invoices'),
                    if (_isBusiness)
                      _featureLine('✓ Multi-user collaboration & Priority Support unlocked'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action: Download Tax Invoice
              if (invoice != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF10B981)),
                      foregroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: Text('Download Tax Invoice (${invoice!.invoiceNumber})'),
                    onPressed: () {
                      SubscriptionPdfService.showInvoiceActionsModal(
                        context,
                        invoice: invoice!,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Action: Continue to Dashboard
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Continue to Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool highlight = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color ?? (highlight ? const Color(0xFF38BDF8) : Colors.white),
                fontSize: 11.5,
                fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(text, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5)),
    );
  }
}
