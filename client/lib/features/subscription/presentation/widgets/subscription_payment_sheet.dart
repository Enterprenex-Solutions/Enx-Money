import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/plan_model.dart';
import '../../services/payment_gateway_service.dart';

enum PaymentMethodType { upi, card, netbanking, autopay }

class SubscriptionPaymentSheet extends StatefulWidget {
  final PlanModel plan;
  final String initialBillingCycle;
  final double? initialDiscount;
  final String? couponCode;
  final VoidCallback? onSubscriptionActivated;

  const SubscriptionPaymentSheet({
    super.key,
    required this.plan,
    this.initialBillingCycle = 'MONTHLY',
    this.initialDiscount,
    this.couponCode,
    this.onSubscriptionActivated,
  });

  /// Static helper to launch the payment sheet from anywhere
  static Future<bool?> show(
    BuildContext context, {
    required PlanModel plan,
    String billingCycle = 'MONTHLY',
    double? discount,
    String? couponCode,
    VoidCallback? onSubscriptionActivated,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SubscriptionPaymentSheet(
        plan: plan,
        initialBillingCycle: billingCycle,
        initialDiscount: discount,
        couponCode: couponCode,
        onSubscriptionActivated: onSubscriptionActivated,
      ),
    );
  }

  @override
  State<SubscriptionPaymentSheet> createState() => _SubscriptionPaymentSheetState();
}

class _SubscriptionPaymentSheetState extends State<SubscriptionPaymentSheet> {
  final NumberFormat _fmt = NumberFormat('#,##0.00', 'en_IN');

  late String _billingCycle;
  PaymentMethodType _selectedMethod = PaymentMethodType.upi;
  String _selectedUpiApp = 'Google Pay';
  String _selectedBank = 'Jio Payments Bank';

  // Text Controllers
  final TextEditingController _upiIdCtrl = TextEditingController(text: 'subscriber@okaxis');
  final TextEditingController _cardNumberCtrl = TextEditingController(text: '4532 •••• •••• 8821');
  final TextEditingController _expiryCtrl = TextEditingController(text: '12/28');
  final TextEditingController _cvvCtrl = TextEditingController(text: '•••');
  final TextEditingController _cardHolderCtrl = TextEditingController(text: 'ENX Money Subscriber');

  bool _isProcessing = false;
  String _processingStatus = '';

  @override
  void initState() {
    super.initState();
    _billingCycle = widget.initialBillingCycle;
  }

  @override
  void dispose() {
    _upiIdCtrl.dispose();
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _cardHolderCtrl.dispose();
    super.dispose();
  }

  double get _baseAmount => _billingCycle == 'YEARLY' ? widget.plan.priceYearly : widget.plan.priceMonthly;
  double get _discount => widget.initialDiscount ?? 0.0;
  double get _taxable => (_baseAmount - _discount).clamp(0, double.infinity);
  double get _gstAmount => _taxable * 0.18;
  double get _totalDue => _taxable + _gstAmount;

  Future<void> _handleAuthorizePayment() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _processingStatus = 'Opening ENX Money Gateway...';
    });

    try {
      final success = await PaymentGatewayService.startSubscriptionCheckout(
        context: context,
        plan: widget.plan,
        billingCycle: _billingCycle,
        discount: _discount,
        couponCode: widget.couponCode,
        onSuccess: () {
          widget.onSubscriptionActivated?.call();
        },
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        if (success) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: const Color(0xFFEF4444), content: Text('Checkout error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _buildCheckoutView(),
    );
  }

  // ── 1. Main Checkout View ──────────────────────────────────────────────────
  Widget _buildCheckoutView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Drag Handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Sheet Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Secure Subscription Checkout',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '256-Bit Encrypted Payment Routing',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),

        const Divider(color: Color(0xFF1E293B), height: 1),

        // Scrollable Checkout Body
        Flexible(
          child: ListView(
            padding: const EdgeInsets.all(20),
            shrinkWrap: true,
            children: [
              // ── Order Breakdown Card ───────────────────────────────────────
              _buildOrderBreakdownCard(),

              const SizedBox(height: 16),

              // ── ENX Money Verified Security Banner ───────────────────────
              _buildMerchantSecurityBanner(),

              const SizedBox(height: 20),

              // ── Payment Method Selector Tabs ───────────────────────────────
              const Text(
                'Select Payment Method',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildPaymentMethodTabs(),

              const SizedBox(height: 16),

              // ── Payment Method Form ────────────────────────────────────────
              _buildSelectedMethodForm(),
            ],
          ),
        ),

        // Bottom Action Footer
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            border: Border(top: BorderSide(color: Color(0xFF334155))),
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _isProcessing ? null : _handleAuthorizePayment,
                child: _isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              _processingStatus,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Authorize & Pay ₹${_fmt.format(_totalDue)}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 2. Order Breakdown Card ────────────────────────────────────────────────
  Widget _buildOrderBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.plan.displayName,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${_billingCycle == 'YEARLY' ? 'Annual' : 'Monthly'} Subscription Tier',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Cycle Switcher
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    _cycleChip('MONTHLY', 'Monthly'),
                    _cycleChip('YEARLY', 'Yearly (-17%)'),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF334155), height: 24),
          _summaryRow('Selected Plan Base Price', '₹${_fmt.format(_baseAmount)}'),
          if (_discount > 0)
            _summaryRow('Coupon Discount', '- ₹${_fmt.format(_discount)}', color: const Color(0xFF10B981)),
          _summaryRow('Subtotal', '₹${_fmt.format(_taxable)}'),
          _summaryRow('Applicable GST (18%)', '₹${_fmt.format(_gstAmount)}'),
          const Divider(color: Color(0xFF334155), height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount Due:',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${_fmt.format(_totalDue)}',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cycleChip(String cycle, String label) {
    final isSelected = _billingCycle == cycle;
    return GestureDetector(
      onTap: () => setState(() => _billingCycle = cycle),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5)),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Verified Merchant Security Banner ──────────────────────────────────
  Widget _buildMerchantSecurityBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ENX Money Verified Merchant Checkout',
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '100% SECURE',
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Merchant: ENX Money',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          const Text(
            '256-Bit SSL Encrypted • PCI-DSS Compliant Payment Routing • Instant Activation',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ── 4. Payment Method Tabs ─────────────────────────────────────────────────
  Widget _buildPaymentMethodTabs() {
    return Row(
      children: [
        _methodTab(PaymentMethodType.upi, 'UPI Apps', Icons.qr_code_2_rounded),
        const SizedBox(width: 8),
        _methodTab(PaymentMethodType.card, 'Cards', Icons.credit_card_rounded),
        const SizedBox(width: 8),
        _methodTab(PaymentMethodType.netbanking, 'NetBanking', Icons.account_balance_rounded),
        const SizedBox(width: 8),
        _methodTab(PaymentMethodType.autopay, 'AutoPay', Icons.autorenew_rounded),
      ],
    );
  }

  Widget _methodTab(PaymentMethodType type, String title, IconData icon) {
    final isSelected = _selectedMethod == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF10B981) : const Color(0xFF334155),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8), size: 18),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 5. Payment Forms by Method ─────────────────────────────────────────────
  Widget _buildSelectedMethodForm() {
    switch (_selectedMethod) {
      case PaymentMethodType.upi:
        return _buildUpiForm();
      case PaymentMethodType.card:
        return _buildCardForm();
      case PaymentMethodType.netbanking:
        return _buildNetBankingForm();
      case PaymentMethodType.autopay:
        return _buildAutoPayForm();
    }
  }

  // UPI Apps Form
  Widget _buildUpiForm() {
    final upiApps = ['Google Pay', 'PhonePe', 'Paytm', 'BHIM'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Popular UPI Apps', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: upiApps.map((app) {
              final isAppSelected = _selectedUpiApp == app;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedUpiApp = app),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isAppSelected ? const Color(0xFF10B981).withValues(alpha: 0.2) : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isAppSelected ? const Color(0xFF10B981) : const Color(0xFF334155),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.smartphone_rounded,
                          size: 16,
                          color: isAppSelected ? const Color(0xFF10B981) : Colors.white70,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          app,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isAppSelected ? Colors.white : Colors.white70,
                            fontSize: 10,
                            fontWeight: isAppSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Text('Or Enter UPI ID / VPA', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: _upiIdCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0F172A),
              hintText: 'username@upi',
              hintStyle: const TextStyle(color: Colors.white38),
              suffixIcon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Cards Form
  Widget _buildCardForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Card Number', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: _cardNumberCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0F172A),
              suffixIcon: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.credit_card_rounded, color: Color(0xFF38BDF8)),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Expiry Date', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _expiryCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        hintText: 'MM/YY',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CVV', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _cvvCtrl,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        hintText: '123',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // NetBanking Form
  Widget _buildNetBankingForm() {
    final banks = ['Jio Payments Bank', 'State Bank of India', 'HDFC Bank', 'ICICI Bank', 'Axis Bank'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Your Bank', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          const SizedBox(height: 10),
          ...banks.map((b) {
            final isBankSelected = _selectedBank == b;
            return GestureDetector(
              onTap: () => setState(() => _selectedBank = b),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isBankSelected ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isBankSelected ? const Color(0xFF10B981) : const Color(0xFF334155),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      b == 'Jio Payments Bank' ? Icons.star_rounded : Icons.account_balance_outlined,
                      color: isBankSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b,
                        style: TextStyle(
                          color: isBankSelected ? Colors.white : Colors.white70,
                          fontSize: 13,
                          fontWeight: isBankSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // AutoPay Form
  Widget _buildAutoPayForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.autorenew_rounded, color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('UPI AutoPay / eNACH Mandate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('Automated recurring subscription renewals', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _autopayRow('Payment Method', 'Customer Linked Primary Bank / UPI AutoPay'),
                _autopayRow('Recurring Amount', '₹${_fmt.format(_totalDue)} / ${_billingCycle.toLowerCase()}'),
                _autopayRow('Next Renewal', DateFormat('dd MMM yyyy').format(DateTime.now().add(const Duration(days: 30)))),
                _autopayRow('Cancellation', 'Cancel anytime in 1 tap from settings'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _autopayRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5)),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

}

