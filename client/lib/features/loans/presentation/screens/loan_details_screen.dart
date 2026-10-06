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

class LoanDetailsScreen extends StatefulWidget {
  final LoanModel loan;
  final LoanRepository? repository;

  const LoanDetailsScreen({
    super.key,
    required this.loan,
    this.repository,
  });

  @override
  State<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends State<LoanDetailsScreen> {
  late final LoanRepository _loanRepository;
  late LoanModel _currentLoan;

  List<EmiScheduleItem> _schedule = [];
  bool _isLoading = true;
  String _selectedFilter = 'All'; // 'All', 'Paid', 'Pending', 'Overdue'
  int _currentPage = 1;
  final int _pageSize = 12; // 12 installments per page

  @override
  void initState() {
    super.initState();
    _loanRepository = widget.repository ?? LoanRepository();
    _currentLoan = widget.loan;
    _loadAmortizationSchedule();
  }

  Future<void> _loadAmortizationSchedule() async {
    setState(() => _isLoading = true);
    try {
      final schedule = await _loanRepository.getAmortizationSchedule(_currentLoan);
      if (mounted) {
        setState(() {
          _schedule = schedule;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<EmiScheduleItem> get _filteredSchedule {
    if (_selectedFilter == 'All') return _schedule;
    return _schedule.where((item) => item.status.toLowerCase() == _selectedFilter.toLowerCase()).toList();
  }

  List<EmiScheduleItem> get _pagedSchedule {
    final filtered = _filteredSchedule;
    final startIndex = (_currentPage - 1) * _pageSize;
    if (startIndex >= filtered.length) return [];
    final endIndex = (startIndex + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(startIndex, endIndex);
  }

  int get _totalPages {
    final filtered = _filteredSchedule;
    if (filtered.isEmpty) return 1;
    return (filtered.length / _pageSize).ceil();
  }

  void _markInstallmentAsPaid(EmiScheduleItem item) async {
    if (item.status == 'Paid') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Text('Installment #${item.installmentNumber} has already been paid on ${item.paidDate ?? 'a previous date'}.'),
        ),
      );
      return;
    }

    final lateFeeBreakdown = await _loanRepository.getScheduleLateFee(_currentLoan.id, item.id, item);
    final isOverdueWithFee = lateFeeBreakdown.isOverdue && lateFeeBreakdown.lateFee > 0;
    DateTime selectedPaymentDate = DateTime.now();
    bool isProcessing = false;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
        side: BorderSide(color: AppColors.border, width: 1),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECORD EMI PAYMENT',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Installment #${item.installmentNumber.toString().padLeft(2, '0')}',
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                '${_currentLoan.lenderName} • Due Date: ${item.dueDate}',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 16),

              // Late Fee Alert Banner (if overdue)
              if (isOverdueWithFee) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'OVERDUE BY ${lateFeeBreakdown.daysOverdue} DAYS',
                              style: AppTypography.badge.copyWith(color: AppColors.error, fontSize: 11),
                            ),
                            Text(
                              'Late Fee Assessed: ${CurrencyFormatter.format(lateFeeBreakdown.lateFee)}',
                              style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.pureWhite),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Breakdown Card
              FintechCard(
                padding: const EdgeInsets.all(16),
                backgroundColor: AppColors.surfaceElevated,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Original EMI', style: AppTypography.bodySmall),
                        Text(
                          CurrencyFormatter.format(lateFeeBreakdown.originalEmi),
                          style: AppTypography.titleMedium.copyWith(color: AppColors.pureWhite, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    if (lateFeeBreakdown.lateFee > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Late Fee (${lateFeeBreakdown.daysOverdue} days)', style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
                          Text(
                            '+ ${CurrencyFormatter.format(lateFeeBreakdown.lateFee)}',
                            style: AppTypography.titleSmall.copyWith(color: AppColors.error, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount Payable', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.textTertiary)),
                        Text(
                          CurrencyFormatter.format(lateFeeBreakdown.totalPayable),
                          style: AppTypography.currencyLarge.copyWith(fontSize: 22, color: AppColors.pureWhite),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Confirm Pay Button
              PrimaryButton(
                text: 'Confirm Pay ${CurrencyFormatter.format(lateFeeBreakdown.totalPayable)}',
                icon: Icons.check_circle_outline_rounded,
                isLoading: isProcessing,
                onPressed: () async {
                  setModalState(() => isProcessing = true);

                  await _loanRepository.markEmiAsPaid(
                    loanId: _currentLoan.id,
                    scheduleId: item.id,
                    amount: lateFeeBreakdown.totalPayable,
                    lateFee: lateFeeBreakdown.lateFee,
                  );

                  final todayStr = selectedPaymentDate.toIso8601String().split('T').first;

                  setState(() {
                    final idx = _schedule.indexWhere((s) => s.id == item.id);
                    if (idx != -1) {
                      _schedule[idx] = EmiScheduleItem(
                        id: item.id,
                        loanId: item.loanId,
                        installmentNumber: item.installmentNumber,
                        dueDate: item.dueDate,
                        openingBalance: item.openingBalance,
                        principalAmount: item.principalAmount,
                        interestAmount: item.interestAmount,
                        emiAmount: item.emiAmount,
                        closingBalance: item.closingBalance,
                        status: 'Paid',
                        paidDate: todayStr,
                        lateFee: lateFeeBreakdown.lateFee,
                      );
                    }

                    // Update live loan metrics
                    final newRemainingTenure = (_currentLoan.remainingTenureMonths - 1).clamp(0, _currentLoan.tenureMonths);
                    final newOutstanding = item.closingBalance;
                    final isAllPaid = _schedule.every((s) => s.status == 'Paid');

                    _currentLoan = _currentLoan.copyWith(
                      outstandingAmount: newOutstanding,
                      remainingTenureMonths: newRemainingTenure,
                      status: isAllPaid ? 'Closed' : 'Active',
                    );
                  });

                  if (!mounted) return;
                  Navigator.pop(ctx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.surfaceElevated,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        side: const BorderSide(color: AppColors.primaryGreen, width: 1),
                      ),
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen),
                          const SizedBox(width: 12),
                          Text('Installment #${item.installmentNumber} marked as PAID! Total: ${CurrencyFormatter.format(lateFeeBreakdown.totalPayable)}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loan = _currentLoan;
    final isClosed = loan.status == 'Closed';
    final progress = loan.tenureMonths > 0
        ? ((loan.tenureMonths - loan.remainingTenureMonths) / loan.tenureMonths).clamp(0.0, 1.0)
        : 1.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: FintechAppBar(
        title: '${loan.loanType} Loan',
        subtitle: loan.lenderName.toUpperCase(),
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).maybePop(),
        actions: [
          StatBadge(
            text: loan.status.toUpperCase(),
            type: loan.status == 'Active' ? StatBadgeType.positive : StatBadgeType.neutral,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. LOAN OVERVIEW HERO CARD
                  _buildLoanOverviewHeroCard(loan, progress, isClosed),

                  const SizedBox(height: 20),

                  // 2. FINANCIAL METRICS MATRIX
                  _buildFinancialMetricsGrid(loan),

                  const SizedBox(height: 28),

                  // 3. AMORTIZATION SCHEDULE HEADER & FILTERS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AMORTIZATION SCHEDULE',
                        style: AppTypography.labelSmall.copyWith(
                          letterSpacing: 1.2,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${_filteredSchedule.length} INSTALLMENTS',
                        style: AppTypography.badge.copyWith(color: AppColors.primaryGreen, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildScheduleFilterTabs(),

                  const SizedBox(height: 16),

                  // 4. VIRTUALIZED AMORTIZATION TABLE / CARDS
                  if (_filteredSchedule.isEmpty)
                    _buildEmptyScheduleState()
                  else
                    ..._pagedSchedule.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildInstallmentCard(item),
                        )),

                  const SizedBox(height: 14),

                  // 5. RESPONSIVE PAGINATION CONTROLS
                  if (_filteredSchedule.length > _pageSize) _buildPaginationBar(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildLoanOverviewHeroCard(LoanModel loan, double progress, bool isClosed) {
    return FintechCard(
      hasGlow: true,
      padding: const EdgeInsets.all(22),
      backgroundColor: AppColors.surfaceCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'MONTHLY EMI OBLIGATION',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${loan.interestRate}% p.a. (${loan.interestType})',
                style: AppTypography.badge.copyWith(color: AppColors.primaryGreen, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                CurrencyFormatter.format(loan.emiAmount),
                style: AppTypography.currencyLarge.copyWith(
                  fontSize: 34,
                  color: AppColors.pureWhite,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ month',
                style: AppTypography.titleSmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 14),

          // Repayment Progress Bar
          Row(
            children: [
              Expanded(
                child: Text(
                  'Outstanding: ${CurrencyFormatter.format(loan.outstandingAmount)}',
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isClosed
                    ? '100% Repaid'
                    : '${(progress * 100).toStringAsFixed(0)}% (${loan.tenureMonths - loan.remainingTenureMonths}/${loan.tenureMonths} Mo)',
                style: AppTypography.bodySmall.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialMetricsGrid(LoanModel loan) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                'PRINCIPAL AMOUNT',
                CurrencyFormatter.format(loan.principalAmount),
                AppColors.pureWhite,
                Icons.account_balance_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                'TOTAL INTEREST',
                CurrencyFormatter.format(loan.totalInterest),
                AppColors.accentGold,
                Icons.trending_down_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                'TOTAL PAYABLE',
                CurrencyFormatter.format(loan.totalPayable),
                AppColors.pureWhite,
                Icons.receipt_long_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                'TENURE',
                '${loan.tenureMonths} Months (${(loan.tenureMonths / 12).toStringAsFixed(1)} Yrs)',
                AppColors.primaryGreen,
                Icons.schedule_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, Color valueColor, IconData icon) {
    return FintechCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(icon, color: valueColor.withValues(alpha: 0.8), size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleFilterTabs() {
    final paidCount = _schedule.where((s) => s.status.toLowerCase() == 'paid').length;
    final pendingCount = _schedule.where((s) => s.status.toLowerCase() == 'pending').length;
    final overdueCount = _schedule.where((s) => s.status.toLowerCase() == 'overdue').length;

    final filters = [
      {'key': 'All', 'label': 'All (${_schedule.length})'},
      {'key': 'Paid', 'label': 'Paid ($paidCount)'},
      {'key': 'Pending', 'label': 'Pending ($pendingCount)'},
      {'key': 'Overdue', 'label': 'Overdue ($overdueCount)'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilter = f['key']!;
                  _currentPage = 1;
                });
              },
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryGreen : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryGreen : AppColors.border,
                  ),
                ),
                child: Text(
                  f['label']!,
                  style: AppTypography.badge.copyWith(
                    color: isSelected ? AppColors.background : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInstallmentCard(EmiScheduleItem item) {
    final isOverdue = item.status == 'Overdue';
    final isPaid = item.status == 'Paid';

    return Container(
      decoration: BoxDecoration(
        color: isOverdue ? AppColors.error.withValues(alpha: 0.08) : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isOverdue
              ? AppColors.error.withValues(alpha: 0.7)
              : (isPaid ? AppColors.primaryGreen.withValues(alpha: 0.3) : AppColors.border),
          width: isOverdue ? 1.4 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Header Row: Installment #, Due Date, Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? AppColors.error.withValues(alpha: 0.2)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#${item.installmentNumber.toString().padLeft(2, '0')}',
                      style: AppTypography.badge.copyWith(
                        color: isOverdue ? AppColors.error : AppColors.pureWhite,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Due: ${item.dueDate}',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              _buildInstallmentStatusBadge(item),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Core Data Breakdown Matrix
          Row(
            children: [
              Expanded(child: _buildTableColumn('EMI Amount', CurrencyFormatter.format(item.emiAmount), isOverdue ? AppColors.error : AppColors.pureWhite, true)),
              Expanded(child: _buildTableColumn('Principal', CurrencyFormatter.format(item.principalAmount), AppColors.primaryGreen, false)),
              Expanded(child: _buildTableColumn('Interest', CurrencyFormatter.format(item.interestAmount), AppColors.accentGold, false)),
              Expanded(child: _buildTableColumn('Closing Bal.', CurrencyFormatter.format(item.closingBalance), AppColors.textSecondary, false)),
            ],
          ),

          if (isOverdue) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                    const SizedBox(width: 6),
                    Text('Late fee penalty accumulating', style: AppTypography.bodySmall.copyWith(color: AppColors.error, fontSize: 11)),
                  ],
                ),
                InkWell(
                  onTap: () => _markInstallmentAsPaid(item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Pay Now', style: AppTypography.badge.copyWith(color: AppColors.pureWhite, fontSize: 10)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableColumn(String label, String value, Color color, bool isBold) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: color,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildInstallmentStatusBadge(EmiScheduleItem item) {
    if (item.status == 'Paid') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 14),
          const SizedBox(width: 4),
          Text(
            item.paidDate != null ? 'PAID (${item.paidDate})' : 'PAID',
            style: AppTypography.badge.copyWith(color: AppColors.primaryGreen, fontSize: 10),
          ),
        ],
      );
    }
    if (item.status == 'Overdue') {
      return const StatBadge(text: 'OVERDUE', type: StatBadgeType.negative);
    }
    return const StatBadge(text: 'PENDING', type: StatBadgeType.neutral);
  }

  Widget _buildPaginationBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.primaryGreen, size: 16),
          onPressed: _currentPage > 1
              ? () {
                  setState(() => _currentPage--);
                }
              : null,
        ),
        Text(
          'Page $_currentPage of $_totalPages',
          style: AppTypography.badge.copyWith(color: AppColors.textSecondary),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primaryGreen, size: 16),
          onPressed: _currentPage < _totalPages
              ? () {
                  setState(() => _currentPage++);
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildEmptyScheduleState() {
    return FintechCard(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          'No installments found for filter: $_selectedFilter',
          style: AppTypography.bodySmall,
        ),
      ),
    );
  }
}
