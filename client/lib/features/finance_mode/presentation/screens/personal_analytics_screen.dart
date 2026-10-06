import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/finance/app_card.dart';
import '../../data/finance_mode_repository.dart';
import '../../models/budget_model.dart';

class PersonalAnalyticsScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const PersonalAnalyticsScreen({super.key, this.onOpenDrawer});

  @override
  State<PersonalAnalyticsScreen> createState() => _PersonalAnalyticsScreenState();
}

class _PersonalAnalyticsScreenState extends State<PersonalAnalyticsScreen> {
  final FinanceModeRepository _repo = FinanceModeRepository();

  bool _isLoading = true;
  String? _errorMessage;

  double _totalInflow = 0;
  double _totalOutflow = 0;
  double _netSavings = 0;
  double _savingsRate = 0;
  int _transactionCount = 0;
  List<BudgetCategoryModel> _budgets = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _repo.getLedgerSummary(mode: 'PERSONAL'),
        _repo.getBudgets(),
      ]);

      final ledger = results[0] as Map<String, dynamic>;
      final budgets = results[1] as List<BudgetCategoryModel>;

      if (mounted) {
        setState(() {
          _totalInflow = (ledger['totalInflow'] as num?)?.toDouble() ?? 0;
          _totalOutflow = (ledger['totalOutflow'] as num?)?.toDouble() ?? 0;
          _netSavings = (ledger['netSavings'] as num?)?.toDouble() ?? 0;
          _savingsRate = (ledger['savingsRate'] as num?)?.toDouble() ?? 0;
          _transactionCount = (ledger['transactionCount'] as num?)?.toInt() ?? 0;
          _budgets = budgets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load financial data.';
          _isLoading = false;
        });
      }
    }
  }

  /// Computes a 0–100 financial health score from live metrics.
  /// Returns null when there is insufficient data (< 3 transactions).
  int? _computeHealthScore() {
    if (_transactionCount < 3 || _totalInflow <= 0) return null;

    // Savings rate component: max 50 pts (100% savings = 50pts)
    final savingsPts = (_savingsRate.clamp(0.0, 100.0) / 100.0 * 50).round();

    // Spend discipline component: max 30 pts (outflow < 60% of inflow = full pts)
    final spendRatio = _totalInflow > 0 ? _totalOutflow / _totalInflow : 1.0;
    final spendPts = spendRatio <= 0.6
        ? 30
        : spendRatio <= 0.8
            ? 20
            : spendRatio <= 1.0
                ? 10
                : 0;

    // Positive savings component: 20 pts if net savings > 0
    final posPts = _netSavings > 0 ? 20 : 0;

    return (savingsPts + spendPts + posPts).clamp(0, 100);
  }

  String _healthLabel(int score) {
    if (score >= 80) return 'Strong Financial Health';
    if (score >= 60) return 'Moderate Financial Health';
    if (score >= 40) return 'Needs Improvement';
    return 'Critical — Review Spending';
  }

  String _healthSubtitle(int score) {
    if (score >= 80) {
      return 'Your savings rate and spend discipline are in great shape. Keep it up!';
    }
    if (score >= 60) {
      return 'Good progress. Try to reduce discretionary spending to improve your score.';
    }
    if (score >= 40) {
      return 'Your outflow is high relative to inflow. Focus on cutting non-essential expenses.';
    }
    return 'Outflow exceeds inflow. Immediate budget review is recommended.';
  }

  /// Generates rule-based advice cards from live data.
  List<Map<String, dynamic>> _buildAdviceCards() {
    if (_transactionCount < 3 || _totalInflow <= 0) return [];

    final cards = <Map<String, dynamic>>[];
    final spendRatio = _totalInflow > 0 ? _totalOutflow / _totalInflow : 0.0;

    if (_savingsRate > 20) {
      cards.add({
        'icon': Icons.lightbulb_outline_rounded,
        'color': AppColors.accentGold,
        'title': 'Optimize Liquid Savings',
        'desc':
            'Your savings rate is ${_savingsRate.toStringAsFixed(1)}%. Consider moving idle cash to a liquid fund or high-yield savings plan to earn more.',
      });
    }

    if (spendRatio > 0.8) {
      cards.add({
        'icon': Icons.warning_amber_rounded,
        'color': Colors.orangeAccent,
        'title': 'High Spend-to-Income Ratio',
        'desc':
            'You are spending ${(spendRatio * 100).toStringAsFixed(0)}% of your income. Aim to bring this below 80% to build a financial cushion.',
      });
    }

    if (_netSavings > 0 && _savingsRate < 10) {
      cards.add({
        'icon': Icons.trending_up_rounded,
        'color': AppColors.primaryGreen,
        'title': 'Boost Your Savings Rate',
        'desc':
            'Your current savings rate is only ${_savingsRate.toStringAsFixed(1)}%. Increasing it to 20%+ can significantly accelerate your financial goals.',
      });
    }

    if (cards.isEmpty) {
      cards.add({
        'icon': Icons.check_circle_outline_rounded,
        'color': AppColors.primaryGreen,
        'title': 'Great Financial Discipline',
        'desc':
            'Your income, savings, and spending are well balanced. Log more transactions each month to get personalised AI recommendations.',
      });
    }

    return cards;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Personal Financial Health', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: widget.onOpenDrawer,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 14),
          Text(_errorMessage!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              side: const BorderSide(color: AppColors.primaryGreen),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final healthScore = _computeHealthScore();
    final adviceCards = _buildAdviceCards();
    final hasInsufficientData = _transactionCount < 3 || _totalInflow <= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Financial Health Score Card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppColors.cardLuxuryGradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderGlow),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Score circle
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGlow,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasInsufficientData
                          ? AppColors.textSecondary
                          : (healthScore! >= 60 ? AppColors.primaryGreen : Colors.orangeAccent),
                      width: 3,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        hasInsufficientData ? '--' : '$healthScore',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                      const Text(
                        '/100',
                        style: TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasInsufficientData
                            ? 'Insufficient Data'
                            : _healthLabel(healthScore!),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasInsufficientData
                            ? 'Log at least 3 transactions to calculate your financial health score.'
                            : _healthSubtitle(healthScore!),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Spending Distribution ──
          const Text(
            'Spending Distribution by Category',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 12),

          if (_budgets.isEmpty)
            _buildEmptyState(
              icon: Icons.pie_chart_outline_rounded,
              message: 'No expenses logged this month',
              sub: 'Record personal expenses to see a live breakdown by category.',
            )
          else
            AppCard(
              child: Column(
                children: _budgets.map((b) {
                  final pct = b.budgetLimit > 0 ? ((b.spentAmount / b.budgetLimit) * 100).clamp(0.0, 100.0) : 0.0;
                  final color = b.isOverBudget ? Colors.redAccent : b.color;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                b.categoryName,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${pct.toStringAsFixed(0)}% • ₹${b.spentAmount.toStringAsFixed(0)}',
                              style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: pct / 100.0,
                            minHeight: 7,
                            backgroundColor: AppColors.surfaceElevated,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 20),

          // ── AI Advisor Recommendations ──
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Advisor Recommendations', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 12),
                if (hasInsufficientData)
                  _buildEmptyState(
                    icon: Icons.auto_awesome_rounded,
                    message: 'Recommendations unavailable',
                    sub: 'Log at least 3 transactions to unlock personalised AI advice.',
                    compact: true,
                  )
                else
                  ...adviceCards.asMap().entries.map((entry) {
                    final card = entry.value;
                    final isLast = entry.key == adviceCards.length - 1;
                    return Column(
                      children: [
                        _buildInsightRow(
                          icon: card['icon'] as IconData,
                          title: card['title'] as String,
                          desc: card['desc'] as String,
                          color: card['color'] as Color,
                        ),
                        if (!isLast) const Divider(height: 16, color: AppColors.border),
                      ],
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String sub,
    bool compact = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 12 : 28),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: compact ? 32 : 44, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            SizedBox(height: compact ? 8 : 12),
            Text(
              message,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
              const SizedBox(height: 3),
              Text(desc, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}
