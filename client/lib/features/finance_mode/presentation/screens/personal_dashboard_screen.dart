import 'package:flutter/material.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/finance/mode_toggle_switch.dart';
import '../../../../core/widgets/finance/skeleton_loader.dart';
import '../../../../core/finance_mode/finance_mode_service.dart';
import '../../data/finance_mode_repository.dart';
import '../../models/account_model.dart';
import '../../models/goal_model.dart';
import '../../models/budget_model.dart';
import '../../../loans/data/loan_repository.dart';
import '../../../loans/models/loan_model.dart';
import '../../../transactions/data/transactions_repository.dart';
import '../../../transactions/models/transaction_model.dart';

/// Personal Financial Overview Dashboard - Live production connected personal finance dashboard
class PersonalDashboardScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const PersonalDashboardScreen({
    super.key,
    this.onOpenDrawer,
  });

  @override
  State<PersonalDashboardScreen> createState() => _PersonalDashboardScreenState();
}

class _PersonalDashboardScreenState extends State<PersonalDashboardScreen> {
  final FinanceModeRepository _financeRepo = FinanceModeRepository();
  final LoanRepository _loanRepo = LoanRepository();
  final TransactionsRepository _transactionsRepo = TransactionsRepository();

  double _totalBalance = 0.0;
  double _monthlyIncome = 0.0;
  double _monthlySpend = 0.0;
  double _netSavings = 0.0;
  double _savingsRate = 0.0;

  List<AccountModel> _accounts = [];
  List<TransactionItem> _transactions = [];
  List<LoanModel> _loans = [];
  List<GoalModel> _goals = [];
  List<BudgetCategoryModel> _budgets = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ledgerFuture = _financeRepo.getLedgerSummary(mode: 'PERSONAL');
      final accountsFuture = _financeRepo.getAccounts(type: FinanceType.personal);
      final loansFuture = _loanRepo.getLoans();
      final txFuture = _transactionsRepo.getTransactions(mode: 'PERSONAL');
      final goalsFuture = _financeRepo.getGoals();
      final budgetsFuture = _financeRepo.getBudgets();

      final results = await Future.wait([
        ledgerFuture,
        accountsFuture,
        loansFuture,
        txFuture,
        goalsFuture,
        budgetsFuture,
      ]);

      final ledger = results[0] as Map<String, dynamic>;
      final accounts = results[1] as List<AccountModel>;
      final loans = results[2] as List<LoanModel>;
      final txs = results[3] as List<TransactionItem>;
      final goals = results[4] as List<GoalModel>;
      final budgets = results[5] as List<BudgetCategoryModel>;

      final balance = (ledger['totalBalance'] is num)
          ? (ledger['totalBalance'] as num).toDouble()
          : accounts.fold(0.0, (sum, a) => sum + a.balance);

      final inflow = (ledger['totalInflow'] is num) ? (ledger['totalInflow'] as num).toDouble() : 0.0;
      final outflow = (ledger['totalOutflow'] is num) ? (ledger['totalOutflow'] as num).toDouble() : 0.0;
      final savings = (ledger['netSavings'] is num) ? (ledger['netSavings'] as num).toDouble() : (inflow - outflow);
      final rate = (ledger['savingsRate'] is num)
          ? (ledger['savingsRate'] as num).toDouble()
          : (inflow > 0 ? (savings / inflow) * 100 : 0.0);

      if (mounted) {
        setState(() {
          _totalBalance = balance;
          _monthlyIncome = inflow;
          _monthlySpend = outflow;
          _netSavings = savings;
          _savingsRate = rate;
          _accounts = accounts;
          _loans = loans;
          _transactions = txs;
          _goals = goals;
          _budgets = budgets;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to fetch personal financial metrics. Check your network connection.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController(),
      builder: (context, _) {
        final isDark = ThemeController().isDarkTheme(context);

        final Color scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
        final Color cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
        final Color cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
        final Color primaryText = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
        final Color secondaryText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: AppBar(
            title: Text(
              'Personal Financial Overview',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: primaryText,
                letterSpacing: -0.2,
              ),
            ),
            backgroundColor: scaffoldBg,
            elevation: 0,
            iconTheme: IconThemeData(color: primaryText),
            leading: widget.onOpenDrawer != null
                ? IconButton(
                    icon: Icon(Icons.menu_rounded, color: primaryText),
                    onPressed: widget.onOpenDrawer,
                  )
                : (Navigator.canPop(context)
                    ? IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: primaryText),
                        onPressed: () => Navigator.pop(context),
                      )
                    : null),
            actions: [
              IconButton(
                icon: Icon(
                  ThemeController().isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: const Color(0xFF0066FF),
                  size: 20,
                ),
                tooltip: 'Toggle Theme',
                onPressed: () => ThemeController().toggleTheme(),
              ),
              IconButton(
                icon: Icon(Icons.swap_horiz_rounded, color: primaryText),
                tooltip: 'Fund Transfer',
                onPressed: () => Navigator.pushNamed(context, '/fund-transfer').then((_) => _loadMetrics()),
              ),
              IconButton(
                icon: Icon(Icons.analytics_outlined, color: primaryText),
                tooltip: 'Analytics',
                onPressed: () => Navigator.pushNamed(context, '/analytics'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _isLoading
              ? const DashboardSkeletonLoader()
              : _errorMessage != null
                  ? _buildErrorView(isDark, cardBg, cardBorder, primaryText, secondaryText)
                  : RefreshIndicator(
                      onRefresh: _loadMetrics,
                      color: const Color(0xFF0066FF),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Mode Indicator Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'FINANCE MODE: PERSONAL',
                                  style: TextStyle(
                                    color: secondaryText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                ModeToggleSwitch(
                                  currentMode: FinanceModeService().mode,
                                  onModeChanged: (newMode) {
                                    FinanceModeService().setMode(newMode);
                                    if (newMode == FinanceMode.business && Navigator.canPop(context)) {
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Net Worth Hero Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0066FF), Color(0xFF0047BA)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0066FF).withValues(alpha: 0.28),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'PERSONAL NET SAVINGS & WORTH',
                                        style: TextStyle(
                                          color: Color(0xFFE0E7FF),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _savingsRate > 0
                                              ? '${_savingsRate.toStringAsFixed(1)}% SAVINGS RATE'
                                              : 'REAL-TIME LEDGER',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    CurrencyFormatter.format(_totalBalance, showDecimals: false),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    height: 1,
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildHeroStat('Total Inflow', CurrencyFormatter.format(_monthlyIncome, showDecimals: false)),
                                      _buildHeroStat('Total Outflow', CurrencyFormatter.format(_monthlySpend, showDecimals: false)),
                                      _buildHeroStat('Net Savings', CurrencyFormatter.format(_netSavings, showDecimals: false)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Top KPI Cards
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricCard(
                                    title: 'Total Inflow Credited',
                                    value: CurrencyFormatter.format(_monthlyIncome, showDecimals: false),
                                    subtitle: 'Income & ledger credits',
                                    icon: Icons.arrow_downward_rounded,
                                    iconColor: const Color(0xFF0066FF),
                                    iconBgColor: const Color(0xFFEFF6FF),
                                    cardBg: cardBg,
                                    cardBorder: cardBorder,
                                    primaryText: primaryText,
                                    secondaryText: secondaryText,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildMetricCard(
                                    title: 'Total Outflow Debited',
                                    value: CurrencyFormatter.format(_monthlySpend, showDecimals: false),
                                    subtitle: 'Expenses & liabilities',
                                    icon: Icons.arrow_upward_rounded,
                                    iconColor: const Color(0xFFEF4444),
                                    iconBgColor: const Color(0xFFFEF2F2),
                                    cardBg: cardBg,
                                    cardBorder: cardBorder,
                                    primaryText: primaryText,
                                    secondaryText: secondaryText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Cash Velocity & Net Savings Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cardBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.speed_rounded, color: Color(0xFF0066FF), size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Personal Savings Velocity',
                                          style: TextStyle(
                                            color: secondaryText,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          CurrencyFormatter.format(_netSavings, showDecimals: false),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: primaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDBEAFE),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF93C5FD), width: 1),
                                    ),
                                    child: Text(
                                      _savingsRate > 0
                                          ? '${_savingsRate.toStringAsFixed(1)}% saved'
                                          : '0.0% saved',
                                      style: const TextStyle(
                                        color: Color(0xFF1E40AF),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Connected Accounts & Financial Cards Section
                            _buildAccountsSection(isDark, cardBg, cardBorder, primaryText, secondaryText),
                            const SizedBox(height: 22),

                            // Quick Personal Actions Section
                            Text(
                              'Quick Personal Actions',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: primaryText,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _buildActionChip(
                                  label: 'Personal Expenses',
                                  icon: Icons.shopping_bag_outlined,
                                  color: const Color(0xFF38BDF8),
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  textColor: primaryText,
                                  onTap: () => Navigator.pushNamed(context, '/personal-expenses').then((_) => _loadMetrics()),
                                ),
                                _buildActionChip(
                                  label: 'Savings & Wallets',
                                  icon: Icons.account_balance_wallet_outlined,
                                  color: const Color(0xFF34D399),
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  textColor: primaryText,
                                  onTap: () => Navigator.pushNamed(context, '/account-setup').then((_) => _loadMetrics()),
                                ),
                                _buildActionChip(
                                  label: 'Cash Flow Analytics',
                                  icon: Icons.insights_rounded,
                                  color: const Color(0xFFA78BFA),
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  textColor: primaryText,
                                  onTap: () => Navigator.pushNamed(context, '/analytics'),
                                ),
                                _buildActionChip(
                                  label: 'Fund Transfer',
                                  icon: Icons.swap_horiz_rounded,
                                  color: const Color(0xFF60A5FA),
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  textColor: primaryText,
                                  onTap: () => Navigator.pushNamed(context, '/fund-transfer').then((_) => _loadMetrics()),
                                ),
                                _buildActionChip(
                                  label: 'Personal Budget',
                                  icon: Icons.pie_chart_outline_rounded,
                                  color: const Color(0xFFFBBF24),
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  textColor: primaryText,
                                  onTap: () => Navigator.pushNamed(context, '/personal-budget').then((_) => _loadMetrics()),
                                ),
                                _buildActionChip(
                                  label: 'Consolidated View',
                                  icon: Icons.assessment_rounded,
                                  color: const Color(0xFF4ADE80),
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  textColor: primaryText,
                                  onTap: () => Navigator.pushNamed(context, '/consolidated-dashboard'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Live Recent Transactions List
                            _buildRecentTransactionsSection(isDark, cardBg, cardBorder, primaryText, secondaryText),
                            const SizedBox(height: 22),

                            // Loans & Liabilities Section (Live Verified Debt Records)
                            _buildLoansAndLiabilitiesSection(isDark, cardBg, cardBorder, primaryText, secondaryText),
                            const SizedBox(height: 22),

                            // Personal Targets & Milestones (Goals)
                            _buildGoalProgress(isDark, cardBg, cardBorder, primaryText, secondaryText),
                            const SizedBox(height: 22),

                            // Monthly Budget Meters Widget
                            _buildBudgetMetersSection(isDark, cardBg, cardBorder, primaryText, secondaryText),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildErrorView(bool isDark, Color cardBg, Color cardBorder, Color primaryText, Color secondaryText) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFEF4444)),
              const SizedBox(height: 16),
              Text(
                'Live Connection Interrupted',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unable to retrieve real-time personal ledger data.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: secondaryText),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadMetrics,
                icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                label: const Text('Retry Connection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountsSection(
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color primaryText,
    Color secondaryText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Connected Accounts & Wallets',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: primaryText,
              ),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/account-setup').then((_) => _loadMetrics()),
              icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF0066FF)),
              label: const Text(
                'Add Account',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0066FF)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_accounts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              children: [
                Icon(Icons.account_balance_wallet_outlined, size: 36, color: secondaryText),
                const SizedBox(height: 10),
                Text(
                  'No Personal Accounts Linked',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: primaryText),
                ),
                const SizedBox(height: 4),
                Text(
                  'Link your personal bank accounts, wallets, or credit cards to see live ledger updates.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/account-setup').then((_) => _loadMetrics()),
                  icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF0066FF)),
                  label: const Text('+ Link Personal Account', style: TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0066FF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _accounts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final acc = _accounts[index];
                final isLiability = acc.balance < 0;
                return Container(
                  width: 220,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              acc.bankName.isNotEmpty ? acc.bankName : acc.title,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: primaryText),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isLiability
                                  ? const Color(0xFFFEE2E2)
                                  : (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isLiability ? 'DUE' : (acc.upiId != null && acc.upiId!.isNotEmpty ? 'UPI' : 'BANK'),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: isLiability ? const Color(0xFFDC2626) : const Color(0xFF0066FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        acc.title,
                        style: TextStyle(fontSize: 11, color: secondaryText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            CurrencyFormatter.format(acc.balance, showDecimals: false),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: isLiability ? const Color(0xFFEF4444) : primaryText,
                            ),
                          ),
                          Text(
                            acc.accountNumberLast4.isNotEmpty ? '•• ${acc.accountNumberLast4}' : '',
                            style: TextStyle(fontSize: 11, color: secondaryText, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRecentTransactionsSection(
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color primaryText,
    Color secondaryText,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Recent Transactions',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: primaryText,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/personal-expenses').then((_) => _loadMetrics()),
                child: const Text(
                  'View All',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0066FF)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_transactions.isEmpty)
            _buildEmptyTransactionsState(isDark, primaryText, secondaryText)
          else
            ..._transactions.take(5).map((tx) => _buildTransactionItem(tx, isDark, primaryText, secondaryText)),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactionsState(bool isDark, Color primaryText, Color secondaryText) {
    final Color innerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color innerBorder = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: innerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: innerBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 32, color: secondaryText),
          const SizedBox(height: 10),
          Text(
            'No transactions recorded yet',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: primaryText),
          ),
          const SizedBox(height: 4),
          Text(
            'Your recent personal purchases, bills, and income will show here dynamically.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: secondaryText),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/personal-expenses').then((_) => _loadMetrics()),
            icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            label: const Text('+ Record Personal Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    TransactionItem tx,
    bool isDark,
    Color primaryText,
    Color secondaryText,
  ) {
    final isCredit = tx.type == TransactionType.credit;
    final Color innerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color innerBorder = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: innerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: innerBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCredit ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isCredit ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: primaryText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  tx.subtitle.isNotEmpty
                      ? tx.subtitle
                      : '${tx.dateTime.day}/${tx.dateTime.month}/${tx.dateTime.year}',
                  style: TextStyle(fontSize: 11, color: secondaryText),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'} ${CurrencyFormatter.format(tx.amount)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isCredit ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoansAndLiabilitiesSection(
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color primaryText,
    Color secondaryText,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Loans & Liabilities',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: primaryText,
                ),
              ),
              if (_loans.isNotEmpty)
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/loans').then((_) => _loadMetrics()),
                  child: const Text(
                    'Manage Loans',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0066FF),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loans.isEmpty)
            _buildEmptyLoansState(isDark, primaryText, secondaryText)
          else
            ..._loans.map((loan) => _buildLoanItem(loan, isDark, primaryText, secondaryText)),
        ],
      ),
    );
  }

  Widget _buildEmptyLoansState(bool isDark, Color primaryText, Color secondaryText) {
    final Color innerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color innerBorder = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: innerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: innerBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_outlined,
              size: 26,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No active loans linked',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You currently have no recorded debts or liabilities.',
            style: TextStyle(
              fontSize: 12,
              color: secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/add-loan').then((_) => _loadMetrics()),
            icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
            label: const Text(
              '+ Link Loan Account',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanItem(LoanModel loan, bool isDark, Color primaryText, Color secondaryText) {
    final Color innerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color innerBorder = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: innerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: innerBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0066FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance_rounded, color: Color(0xFF0066FF), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loan.lenderName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${loan.loanType} Loan • EMI: ${CurrencyFormatter.format(loan.emiAmount)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(loan.outstandingAmount),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: loan.status == 'Active'
                      ? (isDark ? const Color(0xFF132B20) : const Color(0xFFDCFCE7))
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  loan.status.toUpperCase(),
                  style: TextStyle(
                    color: loan.status == 'Active' ? const Color(0xFF059669) : const Color(0xFF64748B),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgress(
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color primaryText,
    Color secondaryText,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personal Targets & Milestones',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: primaryText,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/financial-goals').then((_) => _loadMetrics()),
                child: const Text(
                  'All Goals',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0066FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_goals.isEmpty)
            _buildEmptyGoalsState(isDark, primaryText, secondaryText)
          else
            ..._goals.map((goal) {
              final progress = goal.progress;
              final color = const Color(0xFF0066FF);

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
                            goal.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: primaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Saved: ${CurrencyFormatter.formatCompact(goal.currentAmount)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: secondaryText,
                          ),
                        ),
                        Text(
                          'Target: ${CurrencyFormatter.formatCompact(goal.targetAmount)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyGoalsState(bool isDark, Color primaryText, Color secondaryText) {
    final Color innerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color innerBorder = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: innerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: innerBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.flag_outlined, size: 28, color: secondaryText),
          const SizedBox(height: 8),
          Text(
            'No financial goals set yet',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: primaryText),
          ),
          const SizedBox(height: 4),
          Text(
            'Define personal targets for emergency funds, vacations, or savings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: secondaryText),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/financial-goals').then((_) => _loadMetrics()),
            icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF0066FF)),
            label: const Text('+ Create Financial Goal', style: TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.w700, fontSize: 12)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF0066FF)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetMetersSection(
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color primaryText,
    Color secondaryText,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Budget Status',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: primaryText,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/personal-budget').then((_) => _loadMetrics()),
                child: const Text(
                  'Manage Budget',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0066FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_budgets.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 28, color: secondaryText),
                  const SizedBox(height: 8),
                  Text('No budget limits set', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: primaryText)),
                  const SizedBox(height: 4),
                  Text('Set monthly spending limits for groceries, dining, utilities, etc.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: secondaryText)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/personal-budget').then((_) => _loadMetrics()),
                    icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF0066FF)),
                    label: const Text('+ Set Category Budget', style: TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.w700, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0066FF)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._budgets.take(4).map((bgt) {
              final progress = bgt.progress;
              final Color meterColor = bgt.isOverBudget
                  ? const Color(0xFFEF4444)
                  : (progress > 0.8 ? const Color(0xFFF59E0B) : bgt.color);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(bgt.icon, size: 16, color: meterColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            bgt.categoryName,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: primaryText),
                          ),
                        ),
                        Text(
                          '${CurrencyFormatter.format(bgt.spentAmount, showDecimals: false)} / ${CurrencyFormatter.format(bgt.budgetLimit, showDecimals: false)}',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: secondaryText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(meterColor),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  static Widget _buildHeroStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFE0E7FF),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  static Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color cardBg,
    required Color cardBorder,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: primaryText,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildActionChip({
    required String label,
    required IconData icon,
    required Color color,
    required Color cardBg,
    required Color cardBorder,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder, width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
