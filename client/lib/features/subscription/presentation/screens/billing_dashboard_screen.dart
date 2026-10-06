import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/subscription_repository.dart';
import '../../models/subscription_model.dart';
import '../../models/invoice_model.dart';
import '../widgets/subscription_pdf_service.dart';
import 'pricing_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class BillingDashboardScreen extends StatefulWidget {
  const BillingDashboardScreen({super.key});

  @override
  State<BillingDashboardScreen> createState() => _BillingDashboardScreenState();
}

class _BillingDashboardScreenState extends State<BillingDashboardScreen> {
  final SubscriptionRepository _repo = SubscriptionRepository();
  bool _isLoading = true;
  SubscriptionModel? _subscription;
  List<SubscriptionInvoice> _invoices = [];
  List<Map<String, dynamic>> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final sub = await _repo.getCurrentSubscription(forceRefresh: true);
      final invs = await _repo.getInvoices();
      final payments = await _repo.getPayments();
      if (mounted) {
        setState(() {
          _subscription = sub;
          _invoices = invs;
          _payments = payments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Cancel Subscription', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'In-App Cancellation Pathway (Settings > Subscription > Cancel Plan):',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              '• You will retain full access to your plan features until the end of the current billing cycle.\n'
              '• Auto-renewal stops immediately; you will not be charged again.\n'
              '• Your account will automatically revert to the free tier.\n'
              '• Data Retention: Your financial ledger records, customer contacts, invoices, and EMI trackers will NOT be deleted and remain safely preserved.\n'
              '• Refund Window: If you purchased within the last 7 days and have not substantially used paid features, contact billing@enterprenex.solutions to evaluate refund eligibility under our Refund Policy.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.45),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Plan', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Plan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final success = await _repo.cancelSubscription();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            content: Text(
              success
                  ? 'Subscription set to cancel at the end of the billing period.'
                  : 'Failed to cancel subscription. Please try again.',
            ),
          ),
        );
        _loadData();
      }
    }
  }

  Future<void> _reactivateSubscription() async {
    setState(() => _isLoading = true);
    final success = await _repo.reactivateSubscription();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          content: Text(
            success ? 'Subscription reactivated successfully!' : 'Failed to reactivate. Please try again.',
          ),
        ),
      );
      _loadData();
    }
  }

  Color _getPlanColor(String planName) {
    switch (planName.toUpperCase()) {
      case 'BUSINESS':
        return const Color(0xFFEC4899);
      case 'ADVANCED':
        return const Color(0xFF8B5CF6);
      case 'PRO':
        return const Color(0xFF6366F1);
      case 'BASIC':
        return const Color(0xFF0EA5E9);
      default:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = _subscription;
    final planName = sub?.plan?.name ?? 'FREE';
    final planColor = _getPlanColor(planName);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text('Subscription & Billing', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF10B981),
              backgroundColor: const Color(0xFF1E293B),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Active Plan Card ──────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            planColor.withOpacity(0.2),
                            const Color(0xFF1E293B),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: planColor.withOpacity(0.4), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: planColor.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: planColor),
                                ),
                                child: Text(
                                  planName.toUpperCase(),
                                  style: TextStyle(
                                    color: planColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (sub?.isActive == true ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  sub?.status.toUpperCase() ?? 'ACTIVE',
                                  style: TextStyle(
                                    color: sub?.isActive == true ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            sub?.plan?.displayName ?? 'Free Plan',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            sub?.plan?.priceFormatted(sub.billingCycle) ?? '₹0 / month',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFFCBD5E1),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Divider(color: Color(0xFF334155), height: 28),
                          if (sub?.currentPeriodEnd != null) ...[
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 8),
                                Text(
                                  sub!.cancelAtPeriodEnd
                                      ? 'Expires on: ${DateFormat('dd MMM yyyy').format(sub.currentPeriodEnd!)}'
                                      : 'Renews on: ${DateFormat('dd MMM yyyy').format(sub.currentPeriodEnd!)}',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.rocket_launch, size: 16),
                                  label: Text(planName == 'BUSINESS' ? 'Change Plan' : 'Upgrade Plan'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const PricingScreen()),
                                    );
                                    _loadData();
                                  },
                                ),
                              ),
                              if (planName != 'FREE') ...[
                                const SizedBox(width: 10),
                                if (sub?.cancelAtPeriodEnd == true)
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF10B981),
                                      side: const BorderSide(color: Color(0xFF10B981)),
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: _reactivateSubscription,
                                    child: const Text('Reactivate'),
                                  )
                                else
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFEF4444),
                                      side: const BorderSide(color: Color(0xFFEF4444)),
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: _cancelSubscription,
                                    child: const Text('Cancel'),
                                  ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Invoices Section ──────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Billing Invoices',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${_invoices.length} Invoices',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_invoices.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.receipt_long_outlined, size: 44, color: Color(0xFF64748B)),
                            SizedBox(height: 10),
                            Text(
                              'No invoices yet',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Paid subscription receipts will appear here with GST details.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _invoices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, idx) {
                          final inv = _invoices[idx];
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              SubscriptionPdfService.showInvoiceActionsModal(context, invoice: inv);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF334155)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.receipt_outlined, color: Color(0xFF10B981), size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          inv.invoiceNumber,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${inv.planName} • ${DateFormat('dd MMM yyyy').format(inv.invoiceDate)}',
                                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        inv.formattedTotal,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              inv.status,
                                              style: const TextStyle(
                                                color: Color(0xFF10B981),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF38BDF8), size: 16),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 24),

                    // ── Payment & Transaction History ─────────────────────────
                    _buildPaymentHistorySection(),

                    const SizedBox(height: 24),
                    _buildBillingSupportCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPaymentHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Payment & Transaction History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${_payments.isNotEmpty ? _payments.length : _invoices.length} Transactions',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_payments.isEmpty && _invoices.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Column(
              children: [
                Icon(Icons.history_rounded, size: 44, color: Color(0xFF64748B)),
                SizedBox(height: 10),
                Text(
                  'No transactions yet',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                ),
                SizedBox(height: 4),
                Text(
                  'Real gateway payment IDs and settlement statuses will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ],
            ),
          )
        else if (_payments.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, idx) {
              final p = _payments[idx];
              final txnId = (p['gateway_payment_id'] ?? p['payment_id'] ?? p['order_id'] ?? p['id'] ?? 'pay_tx_$idx').toString();
              final planName = (p['plan_display_name'] ?? p['plan_name'] ?? p['plan_id'] ?? 'Subscription').toString();
              final amount = (p['amount'] as num?)?.toDouble() ?? 0;
              final status = (p['status'] ?? 'SUCCESS').toString().toUpperCase();
              final createdAt = p['created_at'] != null ? DateTime.tryParse(p['created_at'].toString()) : null;
              final isSuccess = status == 'SUCCESS' || status == 'PAID';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                        color: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            txnId,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$planName • ${createdAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt) : 'Recently'}',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          )
        else
          // Fallback to displaying invoice records as payment records
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _invoices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, idx) {
              final inv = _invoices[idx];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFF10B981),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv.invoiceNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${inv.planName} • ${DateFormat('dd MMM yyyy').format(inv.invoiceDate)}',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          inv.formattedTotal,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            inv.status,
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildBillingSupportCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
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
                child: const Icon(Icons.support_agent_rounded, color: Color(0xFF10B981), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Official Billing & Plan Support',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Enterprenex Solutions Pvt. Ltd.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'For any payment inquiries, failed transaction reversals, tax invoices, or refund requests, our billing desk is available Monday to Saturday, 10:00 AM – 6:00 PM IST.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8), height: 1.45),
          ),
          const SizedBox(height: 16),
          _buildSupportInfoRow(Icons.person_pin_rounded, 'Grievance / Privacy Officer', 'Mr. Rohit Pawar'),
          const SizedBox(height: 8),
          _buildSupportInfoRow(Icons.phone_outlined, 'Support Phone', '+91-9226860060'),
          const SizedBox(height: 8),
          _buildSupportInfoRow(Icons.email_outlined, 'Billing Email', 'billing@enterprenex.solutions'),
          const SizedBox(height: 8),
          _buildSupportInfoRow(Icons.mail_outline_rounded, 'General Support', 'support@enterprenex.solutions / info@enterprenex.solutions'),
          const SizedBox(height: 8),
          _buildSupportInfoRow(Icons.location_on_outlined, 'Registered Address', 'Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, Maharashtra - 431136, India'),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.phone, size: 14, color: Color(0xFF10B981)),
                label: const Text('Call +91-9226860060', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF10B981)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final uri = Uri.parse('tel:+919226860060');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.receipt_long_rounded, size: 14, color: Color(0xFF8B5CF6)),
                label: const Text('Email Billing', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF8B5CF6)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final uri = Uri.parse('mailto:billing@enterprenex.solutions?subject=Billing%20Support%20Inquiry%20-%20ENX%20Money');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.policy_outlined, size: 14, color: Color(0xFF38BDF8)),
                label: const Text('Refund Policy', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF38BDF8)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings/refund-policy');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF10B981)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.4),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
