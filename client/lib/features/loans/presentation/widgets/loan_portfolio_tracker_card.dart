import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/loan_repository.dart';
import '../../models/loan_model.dart';
import '../screens/loan_details_screen.dart';

/// Real-time Interactive Loan Repayment & Portfolio Tracker Component
class LoanPortfolioTrackerCard extends StatefulWidget {
  final LoanModel loan;
  final LoanRepository repository;
  final void Function(LoanModel updatedLoan, double amountPaid)? onPaymentSuccess;
  final VoidCallback? onDetailsTapped;

  const LoanPortfolioTrackerCard({
    super.key,
    required this.loan,
    required this.repository,
    this.onPaymentSuccess,
    this.onDetailsTapped,
  });

  @override
  State<LoanPortfolioTrackerCard> createState() => _LoanPortfolioTrackerCardState();
}

class _LoanPortfolioTrackerCardState extends State<LoanPortfolioTrackerCard> with SingleTickerProviderStateMixin {
  late LoanModel _currentLoan;
  bool _isAccordionExpanded = false;
  bool _isLoadingHistory = false;
  List<LoanPaymentRecord> _paymentHistory = [];
  bool _historyLoadedOnce = false;

  // Exact Theme colors required
  static const Color darkCardBg = Color(0xFF0F172A); // Dark slate background
  static const Color lightCardBg = Color(0xFFFFFFFF); // White card background
  static const Color vibrantBlueAccent = Color(0xFF2563EB); // Vibrant blue accent button
  static const Color crispWhiteText = Color(0xFFFFFFFF); // Crisp white numbers
  static const Color slateText = Color(0xFF0F172A); // Slate text in light mode
  static const Color darkBorder = Color(0xFF334155);
  static const Color lightBorder = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _currentLoan = widget.loan;
  }

  @override
  void didUpdateWidget(covariant LoanPortfolioTrackerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loan != widget.loan) {
      _currentLoan = widget.loan;
    }
  }

  Future<void> _loadPaymentHistory() async {
    if (_historyLoadedOnce) return;
    setState(() => _isLoadingHistory = true);
    try {
      final history = await widget.repository.getPaymentHistory(_currentLoan.id);
      if (mounted) {
        setState(() {
          _paymentHistory = history;
          _isLoadingHistory = false;
          _historyLoadedOnce = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  void _toggleAccordion() {
    setState(() {
      _isAccordionExpanded = !_isAccordionExpanded;
    });
    if (_isAccordionExpanded && !_historyLoadedOnce) {
      _loadPaymentHistory();
    }
  }

  void _showRepaymentModal({bool isSettleMode = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => _RepaymentPaymentModalSheet(
        loan: _currentLoan,
        repository: widget.repository,
        initialMode: isSettleMode ? 'SETTLE' : 'EMI',
        onPaymentCompleted: (paidAmount, paymentType, paymentMethod, newRecord) {
          _handlePaymentSuccess(paidAmount, paymentType, paymentMethod, newRecord);
        },
      ),
    );
  }

  void _handlePaymentSuccess(
    double paidAmount,
    String paymentType,
    String paymentMethod,
    LoanPaymentRecord newRecord,
  ) {
    // 1. Immediately deduct the paid amount in local state
    final newOutstanding = math.max(0.0, _currentLoan.outstandingAmount - paidAmount);
    final isFullyPaid = newOutstanding <= 0.0;

    int newRemainingMonths = _currentLoan.remainingTenureMonths;
    if (paymentType == 'EMI' && newRemainingMonths > 0) {
      newRemainingMonths = math.max(0, newRemainingMonths - 1);
    } else if (isFullyPaid) {
      newRemainingMonths = 0;
    }

    final updatedLoan = _currentLoan.copyWith(
      outstandingAmount: (newOutstanding * 100).round() / 100.0,
      remainingTenureMonths: newRemainingMonths,
      status: isFullyPaid ? 'Closed' : _currentLoan.status,
      nextEmiStatus: isFullyPaid ? 'Settled' : 'Pending',
    );

    setState(() {
      _currentLoan = updatedLoan;
      // Prepend to local payment history accordion
      _paymentHistory.insert(0, newRecord);
      _historyLoadedOnce = true;
    });

    // 2. Play success animation toast
    _showPaymentSuccessToast(paidAmount, paymentType, paymentMethod);

    // 3. Notify parent dashboard to update overall metrics in real-time
    widget.onPaymentSuccess?.call(updatedLoan, paidAmount);
  }

  void _showPaymentSuccessToast(double amount, String paymentType, String paymentMethod) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
        ),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0x3310B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Received!',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Loan Outstanding Updated: ${CurrencyFormatter.format(amount)} via $paymentMethod',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getLoanTypeIcon(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('home')) return Icons.home_outlined;
    if (lower.contains('vehicle') || lower.contains('car') || lower.contains('bike')) {
      return Icons.directions_car_outlined;
    }
    if (lower.contains('business')) return Icons.business_center_outlined;
    if (lower.contains('education')) return Icons.school_outlined;
    if (lower.contains('gold')) return Icons.monetization_on_outlined;
    return Icons.person_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? darkCardBg : lightCardBg;
    final cardBorder = isDark ? darkBorder : lightBorder;
    final balanceColor = isDark ? crispWhiteText : slateText;
    final textColor = isDark ? const Color(0xFFF8FAFC) : slateText;
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final isOverdue = _currentLoan.nextEmiStatus == 'Overdue';
    final isClosed = _currentLoan.status == 'Closed' || _currentLoan.outstandingAmount <= 0.0;

    // Progress calculation
    final totalPrincipal = _currentLoan.principalAmount > 0
        ? _currentLoan.principalAmount
        : (_currentLoan.outstandingAmount + (_currentLoan.emiAmount * 6));
    final paidAmount = math.max(0.0, totalPrincipal - _currentLoan.outstandingAmount);
    final progress = totalPrincipal > 0
        ? (paidAmount / totalPrincipal).clamp(0.0, 1.0)
        : 0.0;
    final percentageInt = (progress * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue ? const Color(0xFFEF4444) : cardBorder,
          width: isOverdue ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header Row
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, top: 18, bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Icon Container
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? const Color(0x26EF4444)
                        : (isDark ? const Color(0x1F2563EB) : const Color(0x142563EB)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isOverdue
                          ? const Color(0x4DEF4444)
                          : vibrantBlueAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    _getLoanTypeIcon(_currentLoan.loanType),
                    color: isOverdue ? const Color(0xFFEF4444) : vibrantBlueAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Loan & Lender Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _currentLoan.lenderName.isNotEmpty
                                  ? _currentLoan.lenderName
                                  : '${_currentLoan.loanType} Loan',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusBadge(isClosed, isOverdue),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_currentLoan.loanType} Loan • ${_currentLoan.interestRate}% p.a. (${_currentLoan.interestType})',
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Divider(color: cardBorder, height: 1),
          ),

          // Core Financial Metrics (Total Outstanding Balance & Monthly EMI Amount)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Total Outstanding Balance
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL OUTSTANDING',
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(_currentLoan.outstandingAmount),
                        style: TextStyle(
                          color: balanceColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Monthly EMI Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'MONTHLY EMI',
                      style: TextStyle(
                        color: subtextColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(_currentLoan.emiAmount),
                      style: TextStyle(
                        color: isOverdue ? const Color(0xFFEF4444) : textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Paid Progress Bar & Due Date
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder.withValues(alpha: 0.6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: isOverdue ? const Color(0xFFEF4444) : subtextColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isClosed
                                ? 'Loan Fully Settled'
                                : (_currentLoan.nextDueDate != null && _currentLoan.nextDueDate!.isNotEmpty
                                    ? 'Due: ${_currentLoan.nextDueDate}'
                                    : 'Due in 6 days'),
                            style: TextStyle(
                              color: isOverdue ? const Color(0xFFEF4444) : textColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$percentageInt% Paid',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Progress Track
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: isClosed ? 1.0 : progress,
                      minHeight: 6,
                      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isClosed ? const Color(0xFF10B981) : vibrantBlueAccent,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_currentLoan.remainingTenureMonths} of ${_currentLoan.tenureMonths} Months Left',
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${CurrencyFormatter.format(paidAmount)} Repaid',
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Primary & Secondary Action CTAs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                if (!isClosed) ...[
                  // Primary CTA: "Pay EMI Now" (Vibrant Blue #2563EB)
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vibrantBlueAccent,
                        foregroundColor: crispWhiteText,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _showRepaymentModal(isSettleMode: false),
                      icon: const Icon(Icons.flash_on_rounded, size: 18, color: crispWhiteText),
                      label: const Text(
                        'Pay EMI Now',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Secondary CTA: "Settle Loan"
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? const Color(0xFFE2E8F0) : slateText,
                        side: BorderSide(
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _showRepaymentModal(isSettleMode: true),
                      child: const Text(
                        'Settle Loan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Loan Details & Options Menu Button
                IconButton(
                  tooltip: 'View Loan Details',
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: cardBorder),
                    ),
                  ),
                  icon: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: subtextColor,
                  ),
                  onPressed: () {
                    if (widget.onDetailsTapped != null) {
                      widget.onDetailsTapped!();
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LoanDetailsScreen(
                            loan: _currentLoan,
                            repository: widget.repository,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Payment History & Repayment Schedule Accordion Header
          InkWell(
            onTap: _toggleAccordion,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x331E293B) : const Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(color: cardBorder, width: 1),
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 16,
                        color: vibrantBlueAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Payment History / Repayment Schedule',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (_paymentHistory.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0x2610B981),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_paymentHistory.length}',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  AnimatedRotation(
                    turns: _isAccordionExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: subtextColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable Accordion Body
          if (_isAccordionExpanded)
            _buildPaymentHistoryAccordionBody(isDark, cardBorder, textColor, subtextColor),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isClosed, bool isOverdue) {
    if (isClosed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0x2610B981),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'SETTLED',
          style: TextStyle(
            color: Color(0xFF10B981),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      );
    }
    if (isOverdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0x26EF4444),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'OVERDUE',
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0x1F2563EB),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'ACTIVE',
        style: TextStyle(
          color: vibrantBlueAccent,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPaymentHistoryAccordionBody(
    bool isDark,
    Color cardBorder,
    Color textColor,
    Color subtextColor,
  ) {
    if (_isLoadingHistory) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: vibrantBlueAccent),
        ),
      );
    }

    if (_paymentHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 30, color: subtextColor.withValues(alpha: 0.5)),
            const SizedBox(height: 6),
            Text(
              'No payments recorded yet',
              style: TextStyle(color: subtextColor, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              'Tap "Pay EMI Now" to make an instant repayment.',
              style: TextStyle(color: subtextColor.withValues(alpha: 0.7), fontSize: 10),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
      child: Column(
        children: _paymentHistory.take(5).map((record) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? darkCardBg : lightCardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cardBorder.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0x2610B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 14),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${record.paymentType} Payment',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${record.paymentDate.split("T").first} • ${record.paymentMethod}',
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(record.amount),
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'Successful',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Bottom Sheet Repayment Payment Modal with Payment Type, Payment Methods, and Gateway Flow
class _RepaymentPaymentModalSheet extends StatefulWidget {
  final LoanModel loan;
  final LoanRepository repository;
  final String initialMode; // 'EMI' or 'SETTLE'
  final void Function(double amount, String paymentType, String paymentMethod, LoanPaymentRecord record) onPaymentCompleted;

  const _RepaymentPaymentModalSheet({
    required this.loan,
    required this.repository,
    this.initialMode = 'EMI',
    required this.onPaymentCompleted,
  });

  @override
  State<_RepaymentPaymentModalSheet> createState() => _RepaymentPaymentModalSheetState();
}

class _RepaymentPaymentModalSheetState extends State<_RepaymentPaymentModalSheet> {
  late String _selectedPaymentType; // 'EMI', 'CUSTOM', 'SETTLE'
  late String _selectedMethod; // 'Instant UPI', 'NetBanking', 'Debit Card', 'AutoPay'
  late TextEditingController _customAmountController;
  bool _isProcessing = false;
  String _processingStep = '';

  static const Color vibrantBlueAccent = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _selectedPaymentType = widget.initialMode == 'SETTLE' ? 'SETTLE' : 'EMI';
    _selectedMethod = 'Instant UPI';

    double defaultCustom = (widget.loan.outstandingAmount * 0.25).clamp(1000.0, widget.loan.outstandingAmount);
    _customAmountController = TextEditingController(text: defaultCustom.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  double _getCalculatedPayable() {
    if (_selectedPaymentType == 'EMI') {
      return widget.loan.emiAmount;
    } else if (_selectedPaymentType == 'SETTLE') {
      return widget.loan.outstandingAmount;
    } else {
      final parsed = double.tryParse(_customAmountController.text.replaceAll(',', '')) ?? 0.0;
      return parsed.clamp(100.0, widget.loan.outstandingAmount);
    }
  }

  Future<void> _triggerPaymentGateway() async {
    final amountToPay = _getCalculatedPayable();
    if (amountToPay <= 0) return;

    setState(() {
      _isProcessing = true;
      _processingStep = 'Connecting to Razorpay / Cashfree Gateway...';
    });

    try {
      await Future.delayed(const Duration(milliseconds: 650));
      if (mounted) {
        setState(() {
          _processingStep = 'Authorizing $_selectedMethod transaction...';
        });
      }

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _processingStep = 'Verifying with Bank & Updating Loan Ledger...';
        });
      }

      // Record in backend via repository
      final record = await widget.repository.recordLoanPayment(
        loanId: widget.loan.id,
        amount: amountToPay,
        paymentType: _selectedPaymentType == 'EMI'
            ? 'EMI'
            : (_selectedPaymentType == 'SETTLE' ? 'Settlement' : 'Prepayment'),
        paymentMethod: _selectedMethod,
        notes: 'Repayment of ${CurrencyFormatter.format(amountToPay)} via $_selectedMethod',
      );

      await Future.delayed(const Duration(milliseconds: 400));

      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        widget.onPaymentCompleted(
          amountToPay,
          _selectedPaymentType == 'EMI'
              ? 'EMI'
              : (_selectedPaymentType == 'SETTLE' ? 'Settlement' : 'Custom / Prepayment'),
          _selectedMethod,
          record ??
              LoanPaymentRecord(
                id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
                loanId: widget.loan.id,
                amount: amountToPay,
                paymentDate: DateTime.now().toIso8601String().split('T').first,
                paymentType: _selectedPaymentType,
                paymentMethod: _selectedMethod,
              ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment authorization failed. Please try again.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final text = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final subtext = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final payable = _getCalculatedPayable();
    final methodShort = _selectedMethod.replaceAll('Instant ', '');

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: border, width: 1),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: subtext.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title & Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loan Repayment',
                      style: TextStyle(
                        color: text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.loan.lenderName} • Outstanding: ${CurrencyFormatter.format(widget.loan.outstandingAmount)}',
                      style: TextStyle(color: subtext, fontSize: 12),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: subtext, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 1. Select Payment Type
            Text(
              'SELECT PAYMENT TYPE',
              style: TextStyle(
                color: subtext,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),

            // Payment Type Options
            _buildPaymentTypeSelector(
              type: 'EMI',
              title: 'Monthly EMI (${CurrencyFormatter.format(widget.loan.emiAmount)})',
              subtitle: 'Regular scheduled installment payment',
              isSelected: _selectedPaymentType == 'EMI',
              cardBg: cardBg,
              border: border,
              text: text,
              subtext: subtext,
            ),
            const SizedBox(height: 8),

            _buildPaymentTypeSelector(
              type: 'CUSTOM',
              title: 'Custom / Prepayment Amount',
              subtitle: 'Pay extra principal to reduce interest & tenure',
              isSelected: _selectedPaymentType == 'CUSTOM',
              cardBg: cardBg,
              border: border,
              text: text,
              subtext: subtext,
            ),
            const SizedBox(height: 8),

            _buildPaymentTypeSelector(
              type: 'SETTLE',
              title: 'Full Settlement (${CurrencyFormatter.format(widget.loan.outstandingAmount)})',
              subtitle: 'Close loan in full with zero prepayment penalties',
              isSelected: _selectedPaymentType == 'SETTLE',
              cardBg: cardBg,
              border: border,
              text: text,
              subtext: subtext,
            ),

            // Custom Amount Input if CUSTOM selected
            if (_selectedPaymentType == 'CUSTOM') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: vibrantBlueAccent, width: 1.5),
                ),
                child: Row(
                  children: [
                    Text(
                      '₹',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: text,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _customAmountController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: text,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter prepayment amount',
                          hintStyle: TextStyle(color: subtext, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Quick Amount Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [5000, 10000, 25000, 50000].map((amt) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text('+₹${amt ~/ 1000}k'),
                        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        backgroundColor: cardBg,
                        side: BorderSide(color: border),
                        onPressed: () {
                          final cur = double.tryParse(_customAmountController.text) ?? 0;
                          final next = math.min(widget.loan.outstandingAmount, cur + amt);
                          setState(() {
                            _customAmountController.text = next.toStringAsFixed(0);
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 2. Payment Methods
            Text(
              'PAYMENT METHOD',
              style: TextStyle(
                color: subtext,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),

            // 4 Payment Methods
            Row(
              children: [
                Expanded(
                  child: _buildMethodTile(
                    'Instant UPI',
                    Icons.qr_code_scanner_rounded,
                    'Zero Fee',
                    cardBg,
                    border,
                    text,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMethodTile(
                    'NetBanking',
                    Icons.account_balance_rounded,
                    'All Banks',
                    cardBg,
                    border,
                    text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMethodTile(
                    'Debit Card',
                    Icons.credit_card_rounded,
                    'Visa / RuPay',
                    cardBg,
                    border,
                    text,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMethodTile(
                    'AutoPay',
                    Icons.sync_rounded,
                    'e-Mandate',
                    cardBg,
                    border,
                    text,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Gateway Security Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF10B981)),
                const SizedBox(width: 6),
                Text(
                  'Secured by Razorpay & Cashfree (256-Bit SSL)',
                  style: TextStyle(
                    color: subtext,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Dynamic Proceed Button: "Pay ₹15,000 via UPI"
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: vibrantBlueAccent,
                  foregroundColor: const Color(0xFFFFFFFF),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isProcessing ? null : _triggerPaymentGateway,
                child: _isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFFFFFF),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              _processingStep,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Pay ${CurrencyFormatter.format(payable)} via $methodShort',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTypeSelector({
    required String type,
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color cardBg,
    required Color border,
    required Color text,
    required Color subtext,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedPaymentType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? vibrantBlueAccent.withValues(alpha: 0.12)
              : cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? vibrantBlueAccent : border,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? vibrantBlueAccent : subtext,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: subtext, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodTile(
    String method,
    IconData icon,
    String badge,
    Color cardBg,
    Color border,
    Color text,
  ) {
    final isSelected = _selectedMethod == method;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? vibrantBlueAccent.withValues(alpha: 0.12) : cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? vibrantBlueAccent : border,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? vibrantBlueAccent : text,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method,
                    style: TextStyle(
                      color: text,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    badge,
                    style: TextStyle(
                      color: isSelected ? vibrantBlueAccent : const Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
