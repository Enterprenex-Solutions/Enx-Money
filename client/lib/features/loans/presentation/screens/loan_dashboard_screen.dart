import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_bars/fintech_app_bar.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/cards/fintech_card.dart';
import '../../../../core/widgets/feedback/stat_badge.dart';
import '../../data/loan_repository.dart';
import '../../models/loan_model.dart';
import '../widgets/loan_portfolio_tracker_card.dart';
import 'add_loan_screen.dart';
import 'loan_details_screen.dart';
import 'loan_comparison_screen.dart';

class LoanDashboardScreen extends StatefulWidget {
  final LoanRepository? repository;

  const LoanDashboardScreen({super.key, this.repository});

  @override
  State<LoanDashboardScreen> createState() => _LoanDashboardScreenState();
}

class _LoanDashboardScreenState extends State<LoanDashboardScreen> {
  late final LoanRepository _loanRepository;

  List<LoanModel> _loans = [];
  LoanDashboardSummary _summary = LoanDashboardSummary.empty();
  String _selectedFilter = 'All'; // 'All', 'Active', 'Overdue', 'Completed'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loanRepository = widget.repository ?? LoanRepository();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final summary = await _loanRepository.getDashboardSummary();
      final loans = await _loanRepository.getLoans();

      if (mounted) {
        setState(() {
          _summary = summary;
          _loans = loans;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<LoanModel> get _filteredLoans {
    if (_selectedFilter == 'All') return _loans;
    if (_selectedFilter == 'Active') return _loans.where((l) => l.status == 'Active').toList();
    if (_selectedFilter == 'Overdue') return _loans.where((l) => l.nextEmiStatus == 'Overdue').toList();
    if (_selectedFilter == 'Completed') return _loans.where((l) => l.status == 'Closed').toList();
    return _loans;
  }

  void _handleRealTimePaymentSuccess(LoanModel updatedLoan, double amountPaid) {
    setState(() {
      final index = _loans.indexWhere((l) => l.id == updatedLoan.id);
      if (index != -1) {
        _loans[index] = updatedLoan;
      }
      final newTotalOutstanding = math.max(0.0, _summary.totalOutstanding - amountPaid);
      final wasOverdue = _loans.any((l) => l.id == updatedLoan.id && l.nextEmiStatus == 'Overdue');
      final newOverdueCount = wasOverdue ? math.max(0, _summary.overdueEmisCount - 1) : _summary.overdueEmisCount;

      _summary = LoanDashboardSummary(
        totalLoans: _summary.totalLoans,
        activeLoans: updatedLoan.status == 'Closed' ? math.max(0, _summary.activeLoans - 1) : _summary.activeLoans,
        totalOutstanding: (newTotalOutstanding * 100).round() / 100.0,
        nextEmiAmount: _summary.nextEmiAmount,
        nextEmiDueDate: _summary.nextEmiDueDate,
        nextEmiDaysRemaining: _summary.nextEmiDaysRemaining,
        totalInterestPaid: _summary.totalInterestPaid,
        overdueEmisCount: newOverdueCount,
        overdueEmisAmount: _summary.overdueEmisAmount,
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: FintechAppBar(
        title: 'Loan Portfolio',
        subtitle: 'LIABILITIES & EMI HUB',
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).maybePop(),
        actions: [
          IconButton(
            tooltip: 'Compare Loans',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.compare_arrows_rounded, color: AppColors.info, size: 18),
            ),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LoanComparisonScreen(
                    initialLoans: _loans,
                    repository: _loanRepository,
                  ),
                ),
              );
              _loadDashboardData();
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.add, color: AppColors.primaryGreen, size: 18),
            ),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AddLoanScreen(repository: _loanRepository)),
              );
              _loadDashboardData();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : RefreshIndicator(
              color: AppColors.primaryGreen,
              backgroundColor: AppColors.surfaceElevated,
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. OVERDUE ALERT BANNER (If any overdue EMIs)
                    if (_summary.overdueEmisCount > 0) ...[
                      _buildOverdueAlertBanner(),
                      const SizedBox(height: 16),
                    ],

                    // 2. MASTER TOTAL OUTSTANDING & SUMMARY CARDS
                    _buildMasterOutstandingCard(),

                    const SizedBox(height: 16),

                    // 3. STAT METRICS GRID (Total Loans, Next Due Date, Interest Paid, Next EMI)
                    _buildMetricsGrid(),

                    const SizedBox(height: 24),

                    // 4. FILTER TABS
                    _buildFilterTabs(),

                    const SizedBox(height: 16),

                    // 5. LOANS LIST SECTION
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'YOUR LOANS (${_filteredLoans.length})',
                          style: AppTypography.labelSmall.copyWith(
                            letterSpacing: 1.2,
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${_summary.activeLoans} ACTIVE',
                          style: AppTypography.badge.copyWith(
                            color: AppColors.primaryGreen,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_filteredLoans.isEmpty)
                      _buildEmptyLoansState()
                    else
                      ..._filteredLoans.map((loan) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: LoanPortfolioTrackerCard(
                              loan: loan,
                              repository: _loanRepository,
                              onPaymentSuccess: _handleRealTimePaymentSuccess,
                              onDetailsTapped: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => LoanDetailsScreen(
                                      loan: loan,
                                      repository: _loanRepository,
                                    ),
                                  ),
                                );
                              },
                            ),
                          )),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildOverdueAlertBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_summary.overdueEmisCount} OVERDUE EMI DETECTED',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.error, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Immediate payment of ${CurrencyFormatter.format(_summary.overdueEmisAmount)} required to avoid penalty.',
                  style: AppTypography.bodySmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterOutstandingCard() {
    return FintechCard(
      hasGlow: true,
      padding: const EdgeInsets.all(22),
      backgroundColor: AppColors.surfaceCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL OUTSTANDING DEBT',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              StatBadge(
                text: '${_summary.activeLoans} ACTIVE LOANS',
                type: StatBadgeType.neutral,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            CurrencyFormatter.format(_summary.totalOutstanding),
            style: AppTypography.currencyLarge.copyWith(
              fontSize: 34,
              color: AppColors.pureWhite,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Next EMI Due', style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textTertiary)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(_summary.nextEmiAmount),
                      style: AppTypography.titleMedium.copyWith(color: AppColors.pureWhite, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.divider),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Due Date', style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textTertiary)),
                    const SizedBox(height: 4),
                    Text(
                      '${_summary.nextEmiDueDate} (${_summary.nextEmiDaysRemaining}d)',
                      style: AppTypography.titleMedium.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.w700),
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

  Widget _buildMetricsGrid() {
    return Row(
      children: [
        Expanded(
          child: FintechCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL LOANS', style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textTertiary)),
                    const Icon(Icons.account_balance_outlined, color: AppColors.primaryGreen, size: 16),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_summary.totalLoans}',
                  style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text('${_summary.activeLoans} Active • ${_summary.totalLoans - _summary.activeLoans} Closed', style: AppTypography.bodySmall.copyWith(fontSize: 10)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FintechCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('INTEREST PAID', style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textTertiary)),
                    const Icon(Icons.trending_down_rounded, color: AppColors.accentGold, size: 16),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.format(_summary.totalInterestPaid),
                  style: AppTypography.titleMedium.copyWith(color: AppColors.accentGold, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text('Cumulative to Date', style: AppTypography.bodySmall.copyWith(fontSize: 10)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    final tabs = ['All', 'Active', 'Overdue', 'Completed'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedFilter == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() => _selectedFilter = tab);
              },
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryGreen : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryGreen : AppColors.border,
                  ),
                ),
                child: Text(
                  tab,
                  style: AppTypography.badge.copyWith(
                    color: isSelected ? AppColors.background : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }



  Widget _buildEmptyLoansState() {
    return FintechCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primaryGreen, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'No Loans in this Category',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Add your active loans to monitor repayment schedules, interest savings, and upcoming EMIs in one vault.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'Add First Loan',
              icon: Icons.add_circle_outline_rounded,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AddLoanScreen(repository: _loanRepository)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
