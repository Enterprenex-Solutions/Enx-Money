import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/plan_model.dart';
import '../../models/subscription_model.dart';
import '../../data/subscription_repository.dart';
import '../../services/payment_gateway_service.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutScreen extends StatefulWidget {
  final PlanModel plan;
  final String billingCycle;
  final SubscriptionModel? currentSubscription;

  const CheckoutScreen({
    super.key,
    required this.plan,
    required this.billingCycle,
    this.currentSubscription,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final SubscriptionRepository _repo = SubscriptionRepository();
  final TextEditingController _couponCtrl = TextEditingController();
  final NumberFormat _fmt = NumberFormat('#,##0.00', 'en_IN');

  bool _isProcessing = false;
  String? _activeTrigger;
  String? _errorMessage;
  bool _couponLoading = false;
  double _discountAmount = 0;
  String? _couponMessage;
  bool _couponValid = false;
  String _billingCycle = 'MONTHLY';

  @override
  void initState() {
    super.initState();
    _billingCycle = widget.billingCycle;
  }

  double get _baseAmount => _billingCycle == 'YEARLY' ? widget.plan.priceYearly : widget.plan.priceMonthly;
  double get _finalAmount => (_baseAmount - _discountAmount).clamp(0, double.infinity);

  Future<void> _validateCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() { _couponLoading = true; _couponMessage = null; });

    final result = await _repo.validateCoupon(
      code: code, planId: widget.plan.id, billingCycle: _billingCycle,
    );

    if (mounted) {
      setState(() {
        _couponLoading = false;
        if (result?['success'] == true && result?['data'] != null) {
          final data = result!['data'] as Map<String, dynamic>;
          _couponValid = data['valid'] == true;
          _couponMessage = data['message'] as String?;
          _discountAmount = _couponValid ? (data['discount'] as num?)?.toDouble() ?? 0 : 0;
        } else {
          _couponValid = false;
          _couponMessage = 'Invalid coupon code';
          _discountAmount = 0;
        }
      });
    }
  }

  Future<void> _processPayment({bool isUpiIntentOnly = false}) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _activeTrigger = isUpiIntentOnly ? 'upi' : 'gateway';
      _errorMessage = null;
    });

    try {
      final success = await PaymentGatewayService.startSubscriptionCheckout(
        context: context,
        plan: widget.plan,
        billingCycle: _billingCycle,
        discount: _discountAmount,
        couponCode: _couponValid ? _couponCtrl.text.trim() : null,
        isUpiIntentOnly: isUpiIntentOnly,
      );

      if (success == true && mounted) {
        Navigator.of(context).pop(true);
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Transaction cancelled or failed. Please try again.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Transaction cancelled or failed. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _activeTrigger = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF1F5F9);
    final cardBg = isDark ? const Color(0xFF1A2035) : Colors.white;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Safe back navigation returns false if payment was not confirmed
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0A0F1E) : Colors.white,
          title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Plan Summary Card ──────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.plan.displayName,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('${_billingCycle == 'YEARLY' ? 'Annual' : 'Monthly'} Subscription',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${_fmt.format(_baseAmount)}',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                      Text(_billingCycle == 'YEARLY' ? '/year' : '/month',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Billing Cycle Toggle ───────────────────────────────────────
            if (!widget.plan.isFree)
              Container(
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Billing Cycle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _cycleOption('MONTHLY', 'Monthly', '₹${_fmt.format(widget.plan.priceMonthly)}/mo')),
                        const SizedBox(width: 10),
                        Expanded(child: _cycleOption('YEARLY', 'Yearly',
                          '₹${_fmt.format(widget.plan.priceYearly)}/yr\n🎉 Save ${widget.plan.savingsPercent.toStringAsFixed(0)}%')),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // ── Coupon Code ────────────────────────────────────────────────
            if (!widget.plan.isFree)
              Container(
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Coupon Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _couponCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'Enter coupon code',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onPressed: _couponLoading ? null : _validateCoupon,
                          child: _couponLoading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Apply'),
                        ),
                      ],
                    ),
                    if (_couponMessage != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(_couponValid ? Icons.check_circle_rounded : Icons.error_rounded,
                            color: _couponValid ? const Color(0xFF10B981) : Colors.red, size: 16),
                          const SizedBox(width: 6),
                          Text(_couponMessage!, style: TextStyle(
                            color: _couponValid ? const Color(0xFF10B981) : Colors.red, fontSize: 13)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 16),
            // ── Direct Merchant Settlement Routing Card ────────────────────
            if (!widget.plan.isFree)
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Verified Business Checkout',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF10B981)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('100% SECURE', style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Merchant: ENX Money',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '256-Bit SSL Encrypted • PCI-DSS Compliant Payment Routing',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // ── Order Summary ──────────────────────────────────────────────
            if (!widget.plan.isFree)
              Container(
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    _summaryRow('Subscription (${widget.plan.displayName})', '₹${_fmt.format(_baseAmount)}'),
                    if (_discountAmount > 0)
                      _summaryRow('Coupon Discount', '- ₹${_fmt.format(_discountAmount)}', valueColor: const Color(0xFF10B981)),
                    const Divider(height: 20),
                    _summaryRow('Subtotal', '₹${_fmt.format(_finalAmount)}', bold: true),
                    _summaryRow('GST (18%)', '₹${_fmt.format(_finalAmount * 0.18)}'),
                    const Divider(height: 20),
                    _summaryRow('Total Due', '₹${_fmt.format(_finalAmount * 1.18)}',
                      bold: true, valueColor: const Color(0xFF8B5CF6), fontSize: 16),
                  ],
                ),
              ),
            // ── Inline Error Banner ──────────────────────────────────────────
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _errorMessage = null),
                      child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFEF4444)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // ── Payment Triggers ─────────────────────────────────────────────
            if (!widget.plan.isFree) ...[
              // Primary CTA: Direct UPI Intent (GPay / PhonePe / Paytm)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _isProcessing ? null : () => _processPayment(isUpiIntentOnly: true),
                  child: _isProcessing && _activeTrigger == 'upi'
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'Launching UPI...',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flash_on_rounded, size: 20),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Direct UPI Intent (GPay / PhonePe / Paytm)',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Secondary CTA: Pay via Gateway (Cards / NetBanking / AutoPay)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _isProcessing ? null : () => _processPayment(isUpiIntentOnly: false),
                child: _isProcessing && _activeTrigger == 'gateway'
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          SizedBox(width: 12),
                          Text('Processing...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : Text(
                        widget.plan.isFree
                            ? 'Get Started Free'
                            : 'Pay ₹${_fmt.format(_finalAmount * 1.18)} via Gateway (Cards / NetBanking / AutoPay)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Secured by Razorpay • Cancel anytime',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('By proceeding, you agree to our ', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/settings/terms-conditions'),
                    child: const Text(
                      'Terms & Conditions',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                    ),
                  ),
                  const Text(' and ', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/settings/refund-policy'),
                    child: const Text(
                      'Refund & Cancellation Policy',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF10B981), fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                    ),
                  ),
                  const Text('.', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.help_outline_rounded, size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Text(
                        'Billing Assistance & Refund Inquiries',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Questions about payment or invoice? Enterprenex Solutions support is here to help (Mon–Sat, 10:00 AM – 6:00 PM IST).',
                    style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.phone, size: 14, color: Color(0xFF10B981)),
                          label: const Text('Call Helpline', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            side: const BorderSide(color: Color(0xFF10B981)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            final uri = Uri.parse('tel:+919226860060');
                            if (await canLaunchUrl(uri)) await launchUrl(uri);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.email, size: 14, color: Color(0xFF8B5CF6)),
                          label: const Text('Email Billing', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            side: const BorderSide(color: Color(0xFF8B5CF6)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            final uri = Uri.parse('mailto:billing@enterprenex.solutions?subject=Checkout%20Billing%20Inquiry%20-%20ENX%20Money');
                            if (await canLaunchUrl(uri)) await launchUrl(uri);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      ),
    );
  }

  Widget _cycleOption(String value, String label, String subtitle) {
    final isActive = _billingCycle == value;
    return GestureDetector(
      onTap: () => setState(() {
        _billingCycle = value;
        _discountAmount = 0;
        _couponValid = false;
        _couponMessage = null;
        _couponCtrl.clear();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF8B5CF6).withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? const Color(0xFF8B5CF6) : Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(isActive ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                color: isActive ? const Color(0xFF8B5CF6) : Colors.grey, size: 18),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF8B5CF6) : null)),
            ]),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false, Color? valueColor, double fontSize = 13}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          ),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: valueColor)),
        ],
      ),
    );
  }
}
