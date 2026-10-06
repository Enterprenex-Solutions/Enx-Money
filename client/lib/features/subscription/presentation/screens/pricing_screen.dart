import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/plan_model.dart';
import '../../data/subscription_repository.dart';
import '../../models/subscription_model.dart';
import 'checkout_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});
  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> with TickerProviderStateMixin {
  final SubscriptionRepository _repo = SubscriptionRepository();
  final NumberFormat _fmt = NumberFormat('#,##0', 'en_IN');

  bool _isYearly = false;
  bool _isLoading = true;
  List<PlanModel> _plans = PlanModel.defaultPlans;
  SubscriptionModel? _currentSub;
  int _selectedPlanIndex = 2; // Default: PRO

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const _planColors = [
    Color(0xFF64748B), // FREE - Slate
    Color(0xFF3B82F6), // BASIC - Blue
    Color(0xFF8B5CF6), // PRO - Purple
    Color(0xFFF59E0B), // ADVANCED - Amber
    Color(0xFF10B981), // BUSINESS - Emerald
  ];

  static const _planGradients = [
    [Color(0xFF334155), Color(0xFF475569)],
    [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
    [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
    [Color(0xFFD97706), Color(0xFFF59E0B)],
    [Color(0xFF059669), Color(0xFF10B981)],
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final plans = await _repo.getPlans(forceRefresh: true);
      final sub = await _repo.getCurrentSubscription();
      if (mounted) {
        setState(() {
          _plans = plans.isNotEmpty ? plans : PlanModel.defaultPlans;
          _currentSub = sub;
          _isLoading = false;
          // Highlight current plan
          final idx = _plans.indexWhere((p) => p.id == sub.planId || p.name == sub.plan?.name);
          if (idx >= 0) _selectedPlanIndex = idx;
        });
        _fadeCtrl.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _plans = PlanModel.defaultPlans;
          _isLoading = false;
        });
        _fadeCtrl.forward();
      }
    }
  }

  Color _planColor(int idx) => _planColors[idx % _planColors.length];
  List<Color> _planGradient(int idx) => _planGradients[idx % _planGradients.length];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF1F5F9);
    final cardBg = isDark ? const Color(0xFF1A2035) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF0A0F1E),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A0F1E), Color(0xFF1E1B4B), Color(0xFF312E81)],
                  ),
                ),
                child: Stack(
                  children: [
                    // Background circles
                    Positioned(top: -30, right: -30, child: _glowCircle(120, const Color(0xFF8B5CF6))),
                    Positioned(bottom: -20, left: -20, child: _glowCircle(80, const Color(0xFF3B82F6))),
                    // Content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)]),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('💎 ENX Money Plans', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 12),
                          const Text('Choose Your Plan', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Text('Scale your financial management', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
                          const SizedBox(height: 16),
                          // Monthly / Yearly toggle
                          _buildBillingToggle(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6))),
            )
          else
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Plan Cards ─────────────────────────────────────────
                      ..._plans.asMap().entries.map((e) => _buildPlanCard(e.value, e.key, cardBg, isDark)),
                      const SizedBox(height: 24),
                      // ── Feature Comparison ──────────────────────────────────
                      _buildFeatureTable(cardBg, isDark),
                      const SizedBox(height: 32),
                      // ── FAQ ─────────────────────────────────────────────────
                      _buildFaq(cardBg, isDark),
                      const SizedBox(height: 28),
                      // ── Legal & Billing Support Footer ──────────────────────
                      _buildPricingLegalFooter(cardBg, isDark),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _glowCircle(double size, Color color) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleOption('Monthly', !_isYearly, () => setState(() => _isYearly = false)),
          _toggleOption('Yearly', _isYearly, () => setState(() => _isYearly = true), badge: 'Save up to 17%'),
        ],
      ),
    );
  }

  Widget _toggleOption(String label, bool active, VoidCallback onTap, {String? badge}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(
              color: active ? const Color(0xFF312E81) : Colors.white.withValues(alpha: 0.8),
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            )),
            if (badge != null && !active) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(PlanModel plan, int idx, Color cardBg, bool isDark) {
    final isSelected = _selectedPlanIndex == idx;
    final isCurrentPlan = _currentSub?.plan?.name == plan.name || _currentSub?.planId == plan.id;
    final price = _isYearly ? plan.priceYearly : plan.priceMonthly;
    final monthlyEquiv = _isYearly ? (plan.priceYearly / 12) : plan.priceMonthly;
    final planColor = _planColor(idx);
    final gradient = _planGradient(idx);
    final isPro = plan.name == 'PRO';

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isSelected ? null : cardBg,
          gradient: isSelected ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient) : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCurrentPlan ? const Color(0xFF10B981) : (isSelected ? Colors.transparent : planColor.withValues(alpha: 0.3)),
            width: isCurrentPlan ? 2.5 : (isSelected ? 0 : 1.5),
          ),
          boxShadow: isSelected ? [BoxShadow(color: planColor.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))] : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withValues(alpha: 0.2) : planColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_planIcon(plan.name), color: isSelected ? Colors.white : planColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(plan.displayName,
                              style: TextStyle(
                                color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF111827)),
                                fontSize: 17, fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isPro) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('POPULAR', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                              ),
                            ],
                            if (isCurrentPlan) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF10B981)),
                                ),
                                child: const Text('CURRENT', style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ],
                        ),
                        Text(plan.description,
                          style: TextStyle(color: isSelected ? Colors.white.withValues(alpha: 0.75) : Colors.grey, fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (plan.isFree)
                        Text('Free', style: TextStyle(color: isSelected ? Colors.white : planColor, fontSize: 22, fontWeight: FontWeight.w900))
                      else ...[
                        Text('₹${_fmt.format(monthlyEquiv.round())}',
                          style: TextStyle(color: isSelected ? Colors.white : planColor, fontSize: 20, fontWeight: FontWeight.w900)),
                        Text('/mo', style: TextStyle(color: isSelected ? Colors.white.withValues(alpha: 0.7) : Colors.grey, fontSize: 11)),
                        if (_isYearly)
                          Text('₹${_fmt.format(price.round())}/yr',
                            style: TextStyle(color: isSelected ? Colors.white.withValues(alpha: 0.7) : Colors.grey, fontSize: 11)),
                      ],
                    ],
                  ),
                ],
              ),

              // Yearly savings badge
              if (_isYearly && !plan.isFree && plan.savingsAmount > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: isSelected ? 0.25 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '🎉 Save ₹${_fmt.format(plan.savingsAmount.round())} vs monthly (${plan.savingsPercent.toStringAsFixed(0)}% off)',
                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              // Key features (top 5)
              ...plan.features.where((f) => f.isEnabled).take(5).map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 15,
                      color: isSelected ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${f.featureName}${f.limitType != 'BOOLEAN' ? ' (${f.displayLimit})' : ''}',
                        style: TextStyle(
                          color: isSelected ? Colors.white.withValues(alpha: 0.9) : (isDark ? Colors.white70 : const Color(0xFF374151)),
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),

              const SizedBox(height: 16),
              // CTA Button
              SizedBox(
                width: double.infinity,
                child: _buildCTAButton(plan, idx, isSelected, isCurrentPlan),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCTAButton(PlanModel plan, int idx, bool isSelected, bool isCurrentPlan) {
    if (isCurrentPlan) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF10B981)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: null,
        child: const Text('✓ Current Plan', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
      );
    }
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.white : _planColor(idx),
        foregroundColor: isSelected ? _planColor(idx) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: 0,
      ),
      onPressed: () => _handlePlanUpgrade(plan),
      child: Text(
        plan.isFree ? 'Get Started Free' : 'Upgrade to ${plan.name}',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  void _handlePlanUpgrade(PlanModel plan) {
    _navigateToCheckout(plan);
  }

  void _navigateToCheckout(PlanModel plan) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CheckoutScreen(
        plan: plan,
        billingCycle: _isYearly ? 'YEARLY' : 'MONTHLY',
        currentSubscription: _currentSub,
      )),
    ).then((result) {
      if (result == true) {
        _loadData();
      } else {
        // Payment was NOT completed / cancelled / user navigated back
        // Keep plan state unchanged (e.g. Free tier)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              content: Text('Payment was not completed. No changes were made to your subscription.'),
            ),
          );
        }
      }
    });
  }

  IconData _planIcon(String name) {
    switch (name) {
      case 'FREE': return Icons.star_outline_rounded;
      case 'BASIC': return Icons.trending_up_rounded;
      case 'PRO': return Icons.auto_awesome_rounded;
      case 'ADVANCED': return Icons.business_center_rounded;
      case 'BUSINESS': return Icons.corporate_fare_rounded;
      default: return Icons.workspace_premium_rounded;
    }
  }

  Widget _buildFeatureTable(Color cardBg, bool isDark) {
    const features = [
      ('Expense Tracking', 'EXPENSE_TRACKING'),
      ('Income Tracking', 'INCOME_TRACKING'),
      ('Custom Categories', 'CUSTOM_CATEGORIES'),
      ('Advanced Reports', 'ADVANCED_REPORTS'),
      ('Bank Accounts', 'BANK_ACCOUNT'),
      ('UPI Integration', 'UPI'),
      ('WhatsApp Chatbot', 'WHATSAPP_CHATBOT'),
      ('GST Reports', 'GST_REPORT'),
      ('Invoice Management', 'INVOICE_MANAGEMENT'),
      ('Team Members', 'TEAM_MEMBER'),
      ('API Access', 'API_ACCESS'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Feature Comparison', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF111827),
            )),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 48,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 44,
              columnSpacing: 24,
              columns: [
                const DataColumn(label: Text('Feature', style: TextStyle(fontWeight: FontWeight.bold))),
                ..._plans.map((p) => DataColumn(
                  label: Text(p.name, style: TextStyle(
                    fontWeight: FontWeight.bold, color: _planColor(_plans.indexOf(p)), fontSize: 12,
                  )),
                )),
              ],
              rows: features.map((feat) {
                final name = feat.$1;
                final code = feat.$2;
                return DataRow(
                  cells: [
                    DataCell(Text(name, style: const TextStyle(fontSize: 12.5))),
                    ..._plans.map((p) {
                      final f = p.getFeature(code);
                      if (f == null) return const DataCell(Text('—', style: TextStyle(color: Colors.grey)));
                      if (f.limitType != 'BOOLEAN') {
                        return DataCell(Text(f.displayLimit,
                          style: TextStyle(color: _planColor(_plans.indexOf(p)), fontWeight: FontWeight.bold, fontSize: 12)));
                      }
                      return DataCell(Icon(
                        f.isEnabled ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
                        color: f.isEnabled ? const Color(0xFF10B981) : Colors.grey.shade400,
                        size: 18,
                      ));
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFaq(Color cardBg, bool isDark) {
    final faqs = [
      ('Can I change my plan anytime?', 'Yes! You can upgrade immediately or downgrade at the end of your billing period.'),
      ('Is my data safe if I downgrade?', 'Yes. Your data is always safe. Some features may become view-only until you upgrade.'),
      ('Are there any setup fees?', 'No. All plans have zero setup fees. You only pay the subscription price.'),
      ('Can I cancel anytime?', 'Yes. Cancel anytime. You keep access until the end of your billing period.'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Frequently Asked Questions', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF111827),
        )),
        const SizedBox(height: 12),
        ...faqs.map((faq) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          child: ExpansionTile(
            title: Text(faq.$1, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(faq.$2, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54)),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildPricingLegalFooter(Color cardBg, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              Text(
                '7-Day Refund Policy • Cancel Anytime',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'All paid subscriptions include a 7-day initial satisfaction guarantee. No long-term lock-in: cancel renewal anytime in 1 click.',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/settings/refund-policy'),
                child: const Text(
                  'Refund & Cancellation Policy',
                  style: TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                ),
              ),
              const Text('•', style: TextStyle(color: Colors.grey, fontSize: 12)),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/settings/terms-conditions'),
                child: const Text(
                  'Terms & Conditions',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                ),
              ),
              const Text('•', style: TextStyle(color: Colors.grey, fontSize: 12)),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/settings/privacy-policy'),
                child: const Text(
                  'Privacy Policy',
                  style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            'Need assistance or custom corporate enterprise pricing? Enterprenex Solutions Pvt. Ltd.',
            style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black54),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.phone, size: 14, color: Color(0xFF10B981)),
                  label: const Text('Call +91-9226860060', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    side: const BorderSide(color: Color(0xFF8B5CF6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final uri = Uri.parse('mailto:billing@enterprenex.solutions?subject=Pricing%20Inquiry%20-%20ENX%20Money');
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
