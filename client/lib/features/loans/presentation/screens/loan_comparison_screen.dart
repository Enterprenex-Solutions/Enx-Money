import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_bars/fintech_app_bar.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/cards/fintech_card.dart';
import '../../data/loan_repository.dart';
import '../../models/loan_model.dart';
import 'loan_details_screen.dart';
import 'add_loan_screen.dart';

class LoanComparisonScreen extends StatefulWidget {
  final List<LoanModel>? initialLoans;
  final LoanRepository? repository;

  const LoanComparisonScreen({
    super.key,
    this.initialLoans,
    this.repository,
  });

  @override
  State<LoanComparisonScreen> createState() => _LoanComparisonScreenState();
}

class _LoanComparisonScreenState extends State<LoanComparisonScreen> {
  late final LoanRepository _repo;
  List<LoanModel> _allLoans = [];
  Set<String> _selectedLoanIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? LoanRepository();
    if (widget.initialLoans != null && widget.initialLoans!.isNotEmpty) {
      _allLoans = widget.initialLoans!;
      _selectedLoanIds = _allLoans.map((l) => l.id).toSet();
      _isLoading = false;
    } else {
      _loadLoans();
    }
  }

  Future<void> _loadLoans() async {
    setState(() => _isLoading = true);
    try {
      final loans = await _repo.getLoans();
      if (mounted) {
        setState(() {
          _allLoans = loans.where((l) => l.status.toLowerCase() != 'closed').toList();
          _selectedLoanIds = _allLoans.map((l) => l.id).toSet();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<LoanModel> get _selectedLoans {
    return _allLoans.where((l) => _selectedLoanIds.contains(l.id)).toList();
  }

  // --- Insight Computations ---
  LoanModel? get _highestInterestLoan {
    if (_selectedLoans.isEmpty) return null;
    return _selectedLoans.reduce((a, b) => a.totalInterest > b.totalInterest ? a : b);
  }

  LoanModel? get _highestEmiLoan {
    if (_selectedLoans.isEmpty) return null;
    return _selectedLoans.reduce((a, b) => a.emiAmount > b.emiAmount ? a : b);
  }

  LoanModel? get _largestOutstandingLoan {
    if (_selectedLoans.isEmpty) return null;
    return _selectedLoans.reduce((a, b) => a.outstandingAmount > b.outstandingAmount ? a : b);
  }

  LoanModel? get _shortestTenureLoan {
    if (_selectedLoans.isEmpty) return null;
    return _selectedLoans.reduce((a, b) => a.remainingTenureMonths < b.remainingTenureMonths ? a : b);
  }

  double get _maxEmi {
    if (_selectedLoans.isEmpty) return 1.0;
    return _selectedLoans.map((l) => l.emiAmount).reduce(math.max);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: FintechAppBar(
        title: 'Multi-Loan Comparison',
        subtitle: 'BENCHMARKS & COMPARATIVE MATRIX',
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).maybePop(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: _loadLoans,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _allLoans.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: AppDimensions.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Selector Chips & Controls
                      _buildLoanSelectorBar(),

                      const SizedBox(height: 20),

                      if (_selectedLoans.isEmpty)
                        _buildNoSelectionState()
                      else ...[
                        // 2. Key Highlights Hero Grid
                        _buildHighlightsSection(),

                        const SizedBox(height: 24),

                        // 3. Visual Comparison Distribution (EMI & Balance)
                        _buildVisualComparisonSection(),

                        const SizedBox(height: 24),

                        // 4. Comprehensive Comparison Table
                        _buildComparisonTableSection(),

                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
    );
  }

  // --- 1. SELECTION BAR ---
  Widget _buildLoanSelectorBar() {
    return FintechCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SELECT LOANS TO COMPARE',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_selectedLoanIds.length == _allLoans.length) {
                          _selectedLoanIds.clear();
                        } else {
                          _selectedLoanIds = _allLoans.map((l) => l.id).toSet();
                        }
                      });
                    },
                    child: Text(
                      _selectedLoanIds.length == _allLoans.length ? 'Deselect All' : 'Select All',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allLoans.map((loan) {
              final isSelected = _selectedLoanIds.contains(loan.id);
              final color = _getLoanColor(loan.loanType);
              return FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getLoanIcon(loan.loanType),
                      size: 14,
                      color: isSelected ? Colors.black : color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${loan.loanType} (${CurrencyFormatter.formatCompact(loan.outstandingAmount)})',
                      style: TextStyle(
                        color: isSelected ? Colors.black : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.surfaceElevated,
                selectedColor: AppColors.primaryGreen,
                checkmarkColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? AppColors.primaryGreen : AppColors.border,
                  ),
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedLoanIds.add(loan.id);
                    } else {
                      _selectedLoanIds.remove(loan.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- 2. HIGHLIGHTS SECTION ---
  Widget _buildHighlightsSection() {
    final highestInterest = _highestInterestLoan;
    final highestEmi = _highestEmiLoan;
    final largestOutstanding = _largestOutstandingLoan;
    final shortestTenure = _shortestTenureLoan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KEY COMPARISON HIGHLIGHTS',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isWide ? 1.4 : 1.1,
              children: [
                _buildHighlightCard(
                  title: 'Highest Interest Cost',
                  badgeText: 'MAX INTEREST',
                  badgeColor: AppColors.error,
                  loanName: highestInterest?.loanType ?? '-',
                  value: CurrencyFormatter.format(highestInterest?.totalInterest ?? 0),
                  icon: Icons.trending_up_rounded,
                  iconColor: AppColors.error,
                ),
                _buildHighlightCard(
                  title: 'Highest Monthly EMI',
                  badgeText: 'MAX EMI',
                  badgeColor: AppColors.warning,
                  loanName: highestEmi?.loanType ?? '-',
                  value: CurrencyFormatter.format(highestEmi?.emiAmount ?? 0),
                  icon: Icons.payments_outlined,
                  iconColor: AppColors.warning,
                ),
                _buildHighlightCard(
                  title: 'Largest Balance',
                  badgeText: 'MAX PRINCIPAL',
                  badgeColor: AppColors.info,
                  loanName: largestOutstanding?.loanType ?? '-',
                  value: CurrencyFormatter.format(largestOutstanding?.outstandingAmount ?? 0),
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: AppColors.info,
                ),
                _buildHighlightCard(
                  title: 'Shortest Remaining',
                  badgeText: 'QUICKEST PAYOFF',
                  badgeColor: AppColors.primaryGreen,
                  loanName: shortestTenure?.loanType ?? '-',
                  value: '${shortestTenure?.remainingTenureMonths ?? 0} Mos',
                  icon: Icons.timer_outlined,
                  iconColor: AppColors.primaryGreen,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHighlightCard({
    required String title,
    required String badgeText,
    required Color badgeColor,
    required String loanName,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return FintechCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    badgeText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.pureWhite,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '$loanName Loan',
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 3. VISUAL COMPARISON SECTION ---
  Widget _buildVisualComparisonSection() {
    return FintechCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VISUAL METRIC BENCHMARK',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                '${_selectedLoans.length} Loans Selected',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // A. Monthly EMI Visual Bars
          Text(
            'Monthly EMI Breakdown',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ..._selectedLoans.map((loan) {
            final double ratio = _maxEmi > 0 ? (loan.emiAmount / _maxEmi).clamp(0.05, 1.0) : 0.05;
            final isMax = loan.id == _highestEmiLoan?.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(_getLoanIcon(loan.loanType), size: 14, color: _getLoanColor(loan.loanType)),
                          const SizedBox(width: 6),
                          Text(
                            loan.loanType,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: isMax ? FontWeight.w700 : FontWeight.w500,
                              color: isMax ? AppColors.warning : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        CurrencyFormatter.format(loan.emiAmount),
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isMax ? AppColors.warning : AppColors.pureWhite,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        Container(height: 8, color: AppColors.surfaceElevated),
                        FractionallySizedBox(
                          widthFactor: ratio,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isMax
                                    ? [AppColors.warning, Colors.orangeAccent]
                                    : [AppColors.primaryGreen, AppColors.info],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),

          // B. Principal vs Total Interest Ratio
          Text(
            'Principal vs Total Interest Breakdown',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ..._selectedLoans.map((loan) {
            final total = loan.totalPayable > 0 ? loan.totalPayable : (loan.principalAmount + loan.totalInterest);
            final principalRatio = total > 0 ? (loan.principalAmount / total).clamp(0.1, 0.95) : 0.7;
            final interestRatio = 1.0 - principalRatio;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${loan.loanType} (${loan.interestRate}% ${loan.interestType})',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Int: ${CurrencyFormatter.formatCompact(loan.totalInterest)} (${(interestRatio * 100).toStringAsFixed(0)}%)',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: (principalRatio * 100).toInt(),
                          child: Container(height: 8, color: AppColors.primaryGreen),
                        ),
                        Expanded(
                          flex: (interestRatio * 100).toInt(),
                          child: Container(height: 8, color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(AppColors.primaryGreen, 'Principal Amount'),
              const SizedBox(width: 16),
              _buildLegendItem(AppColors.error, 'Interest Cost'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }

  // --- 4. DETAILED COMPARISON TABLE ---
  Widget _buildComparisonTableSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SIDE-BY-SIDE MATRIX',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        FintechCard(
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.surfaceElevated),
              dataRowColor: WidgetStateProperty.all(Colors.transparent),
              horizontalMargin: 16,
              columnSpacing: 24,
              columns: [
                const DataColumn(
                  label: Text(
                    'FINANCIAL METRIC',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                ..._selectedLoans.map((loan) {
                  return DataColumn(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getLoanIcon(loan.loanType), size: 14, color: _getLoanColor(loan.loanType)),
                        const SizedBox(width: 6),
                        Text(
                          '${loan.loanType} Loan',
                          style: TextStyle(
                            color: _getLoanColor(loan.loanType),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              rows: [
                _buildTableRow('Lender / Source', _selectedLoans.map((l) => l.lenderName).toList()),
                _buildTableRow(
                  'Principal Amount',
                  _selectedLoans.map((l) => CurrencyFormatter.format(l.principalAmount)).toList(),
                ),
                _buildTableRow(
                  'Interest Rate',
                  _selectedLoans.map((l) => '${l.interestRate}% p.a.').toList(),
                ),
                _buildTableRow(
                  'Interest Type',
                  _selectedLoans.map((l) => l.interestType).toList(),
                ),
                _buildTableRow(
                  'Monthly EMI',
                  _selectedLoans.map((l) => CurrencyFormatter.format(l.emiAmount)).toList(),
                  highlightIdx: _selectedLoans.indexOf(_highestEmiLoan ?? _selectedLoans.first),
                  highlightColor: AppColors.warning,
                  highlightTag: 'Highest EMI',
                ),
                _buildTableRow(
                  'Outstanding Balance',
                  _selectedLoans.map((l) => CurrencyFormatter.format(l.outstandingAmount)).toList(),
                  highlightIdx: _selectedLoans.indexOf(_largestOutstandingLoan ?? _selectedLoans.first),
                  highlightColor: AppColors.info,
                  highlightTag: 'Largest',
                ),
                _buildTableRow(
                  'Remaining Tenure',
                  _selectedLoans.map((l) => '${l.remainingTenureMonths} Months').toList(),
                  highlightIdx: _selectedLoans.indexOf(_shortestTenureLoan ?? _selectedLoans.first),
                  highlightColor: AppColors.primaryGreen,
                  highlightTag: 'Shortest',
                ),
                _buildTableRow(
                  'Total Interest Cost',
                  _selectedLoans.map((l) => CurrencyFormatter.format(l.totalInterest)).toList(),
                  highlightIdx: _selectedLoans.indexOf(_highestInterestLoan ?? _selectedLoans.first),
                  highlightColor: AppColors.error,
                  highlightTag: 'Most Expensive',
                ),
                _buildTableRow(
                  'Total Payable',
                  _selectedLoans.map((l) => CurrencyFormatter.format(l.totalPayable)).toList(),
                ),
                _buildTableRow(
                  'Action',
                  _selectedLoans.map((l) => 'View Details').toList(),
                  isActionRow: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildTableRow(
    String metric,
    List<String> values, {
    int? highlightIdx,
    Color? highlightColor,
    String? highlightTag,
    bool isActionRow = false,
  }) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            metric,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        ...values.asMap().entries.map((entry) {
          final idx = entry.key;
          final val = entry.value;
          final isHighlighted = highlightIdx == idx;
          final loan = _selectedLoans[idx];

          if (isActionRow) {
            return DataCell(
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LoanDetailsScreen(
                        loan: loan,
                        repository: _repo,
                      ),
                    ),
                  ).then((_) => _loadLoans());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'View Loan',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.primaryGreen),
                    ],
                  ),
                ),
              ),
            );
          }

          return DataCell(
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  val,
                  style: TextStyle(
                    color: isHighlighted ? (highlightColor ?? AppColors.primaryGreen) : AppColors.pureWhite,
                    fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                if (isHighlighted && highlightTag != null)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: (highlightColor ?? AppColors.primaryGreen).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      highlightTag,
                      style: TextStyle(
                        color: highlightColor ?? AppColors.primaryGreen,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- EMPTY STATES ---
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.compare_arrows_rounded, size: 48, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'No Loans to Compare',
              style: AppTypography.displaySmall.copyWith(color: AppColors.pureWhite),
            ),
            const SizedBox(height: 8),
            Text(
              'Add at least 2 active loans to view multi-loan comparisons and visual benchmarks.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Add New Loan',
              icon: Icons.add_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddLoanScreen(repository: _repo)),
                ).then((_) => _loadLoans());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSelectionState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.touch_app_outlined, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'Please select at least one loan from above to compare metrics.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---
  IconData _getLoanIcon(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return Icons.home_rounded;
      case 'vehicle':
        return Icons.directions_car_rounded;
      case 'business':
        return Icons.business_center_rounded;
      case 'personal':
      default:
        return Icons.person_rounded;
    }
  }

  Color _getLoanColor(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return AppColors.info;
      case 'vehicle':
        return AppColors.warning;
      case 'business':
        return AppColors.accentPurple;
      case 'personal':
      default:
        return AppColors.primaryGreen;
    }
  }
}
