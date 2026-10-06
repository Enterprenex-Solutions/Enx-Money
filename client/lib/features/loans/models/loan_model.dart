class LoanModel {
  final String id;
  final String userId;
  final String loanType;
  final String lenderName;
  final double principalAmount;
  final double interestRate;
  final int tenureMonths;
  final String startDate;
  final String interestType;
  final double emiAmount;
  final double totalInterest;
  final double totalPayable;
  final String status;
  final double outstandingAmount;
  final int remainingTenureMonths;
  final String? nextDueDate;
  final String? nextEmiStatus; // 'Paid', 'Pending', 'Overdue'
  final String? createdAt;
  final String? updatedAt;

  const LoanModel({
    required this.id,
    required this.userId,
    required this.loanType,
    this.lenderName = 'ENX Capital',
    required this.principalAmount,
    required this.interestRate,
    required this.tenureMonths,
    required this.startDate,
    this.interestType = 'Reducing',
    required this.emiAmount,
    required this.totalInterest,
    required this.totalPayable,
    this.status = 'Active',
    this.outstandingAmount = 0.0,
    this.remainingTenureMonths = 0,
    this.nextDueDate,
    this.nextEmiStatus = 'Pending',
    this.createdAt,
    this.updatedAt,
  });

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    final principal = (json['principalAmount'] ?? json['principal_amount'] ?? 0.0).toDouble();
    final tenure = (json['tenureMonths'] ?? json['tenure_months'] ?? 0) as int;
    final outstanding = json['outstandingBalance'] != null 
        ? (json['outstandingBalance'] as num).toDouble()
        : (json['outstandingAmount'] != null ? (json['outstandingAmount'] as num).toDouble() : principal);

    final nextEmiJson = json['nextEmi'] as Map<String, dynamic>?;

    return LoanModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      loanType: json['loanType'] as String? ?? json['loan_type'] as String? ?? 'Personal',
      lenderName: json['lenderName'] as String? ?? json['lender_name'] as String? ?? _defaultLenderName(json['loanType'] as String?),
      principalAmount: principal,
      interestRate: (json['interestRate'] ?? json['interest_rate'] ?? 0.0).toDouble(),
      tenureMonths: tenure,
      startDate: json['startDate'] as String? ?? json['start_date'] as String? ?? '',
      interestType: json['interestType'] as String? ?? json['interest_type'] as String? ?? 'Reducing',
      emiAmount: (json['emiAmount'] ?? json['emi_amount'] ?? (json['emi'] != null ? (json['emi'] as num).toDouble() : 0.0)).toDouble(),
      totalInterest: (json['totalInterest'] ?? json['total_interest'] ?? 0.0).toDouble(),
      totalPayable: (json['totalPayable'] ?? json['total_payable'] ?? 0.0).toDouble(),
      status: json['status'] as String? ?? 'Active',
      outstandingAmount: outstanding,
      remainingTenureMonths: json['remainingTenure'] as int? ?? tenure,
      nextDueDate: nextEmiJson != null ? (nextEmiJson['dueDate'] as String?) : (json['nextDueDate'] as String?),
      nextEmiStatus: nextEmiJson != null && (nextEmiJson['isOverdue'] as bool? ?? false) ? 'Overdue' : 'Pending',
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String?,
      updatedAt: json['updatedAt'] as String? ?? json['updated_at'] as String?,
    );
  }

  static String _defaultLenderName(String? loanType) {
    switch (loanType?.toLowerCase()) {
      case 'home':
        return 'HDFC Housing Finance';
      case 'vehicle':
        return 'ICICI Auto Prime';
      case 'business':
        return 'Axis Business Credit';
      case 'personal':
      default:
        return 'ENX Black Credit';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'loanType': loanType,
      'lenderName': lenderName,
      'principalAmount': principalAmount,
      'interestRate': interestRate,
      'tenureMonths': tenureMonths,
      'startDate': startDate,
      'interestType': interestType,
      'emiAmount': emiAmount,
      'totalInterest': totalInterest,
      'totalPayable': totalPayable,
      'status': status,
      'outstandingAmount': outstandingAmount,
      'remainingTenureMonths': remainingTenureMonths,
      'nextDueDate': nextDueDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  LoanModel copyWith({
    String? id,
    String? userId,
    String? loanType,
    String? lenderName,
    double? principalAmount,
    double? interestRate,
    int? tenureMonths,
    String? startDate,
    String? interestType,
    double? emiAmount,
    double? totalInterest,
    double? totalPayable,
    String? status,
    double? outstandingAmount,
    int? remainingTenureMonths,
    String? nextDueDate,
    String? nextEmiStatus,
    String? createdAt,
    String? updatedAt,
  }) {
    return LoanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      loanType: loanType ?? this.loanType,
      lenderName: lenderName ?? this.lenderName,
      principalAmount: principalAmount ?? this.principalAmount,
      interestRate: interestRate ?? this.interestRate,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      startDate: startDate ?? this.startDate,
      interestType: interestType ?? this.interestType,
      emiAmount: emiAmount ?? this.emiAmount,
      totalInterest: totalInterest ?? this.totalInterest,
      totalPayable: totalPayable ?? this.totalPayable,
      status: status ?? this.status,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      remainingTenureMonths: remainingTenureMonths ?? this.remainingTenureMonths,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      nextEmiStatus: nextEmiStatus ?? this.nextEmiStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LoanDashboardSummary {
  final int totalLoans;
  final int activeLoans;
  final double totalOutstanding;
  final double nextEmiAmount;
  final String? nextEmiDueDate;
  final int? nextEmiDaysRemaining;
  final double totalInterestPaid;
  final int overdueEmisCount;
  final double overdueEmisAmount;

  const LoanDashboardSummary({
    required this.totalLoans,
    required this.activeLoans,
    required this.totalOutstanding,
    required this.nextEmiAmount,
    this.nextEmiDueDate,
    this.nextEmiDaysRemaining,
    required this.totalInterestPaid,
    required this.overdueEmisCount,
    this.overdueEmisAmount = 0.0,
  });

  factory LoanDashboardSummary.empty() {
    return const LoanDashboardSummary(
      totalLoans: 0,
      activeLoans: 0,
      totalOutstanding: 0.0,
      nextEmiAmount: 0.0,
      nextEmiDueDate: null,
      nextEmiDaysRemaining: null,
      totalInterestPaid: 0.0,
      overdueEmisCount: 0,
      overdueEmisAmount: 0.0,
    );
  }
}

class EmiScheduleItem {
  final String id;
  final String loanId;
  final int installmentNumber;
  final String dueDate;
  final double openingBalance;
  final double principalAmount;
  final double interestAmount;
  final double emiAmount;
  final double closingBalance;
  final String status; // 'Paid', 'Pending', 'Overdue'
  final String? paidDate;
  final double lateFee;

  const EmiScheduleItem({
    required this.id,
    required this.loanId,
    required this.installmentNumber,
    required this.dueDate,
    required this.openingBalance,
    required this.principalAmount,
    required this.interestAmount,
    required this.emiAmount,
    required this.closingBalance,
    required this.status,
    this.paidDate,
    this.lateFee = 0.0,
  });

  factory EmiScheduleItem.fromJson(Map<String, dynamic> json) {
    return EmiScheduleItem(
      id: json['id'] as String? ?? '',
      loanId: json['loanId'] as String? ?? json['loan_id'] as String? ?? '',
      installmentNumber: (json['installmentNumber'] ?? json['installment_number'] ?? 0) as int,
      dueDate: json['dueDate'] as String? ?? json['due_date'] as String? ?? '',
      openingBalance: (json['openingBalance'] ?? json['opening_balance'] ?? 0.0).toDouble(),
      principalAmount: (json['principalAmount'] ?? json['principal_amount'] ?? 0.0).toDouble(),
      interestAmount: (json['interestAmount'] ?? json['interest_amount'] ?? 0.0).toDouble(),
      emiAmount: (json['emiAmount'] ?? json['emi_amount'] ?? 0.0).toDouble(),
      closingBalance: (json['closingBalance'] ?? json['closing_balance'] ?? 0.0).toDouble(),
      status: json['status'] as String? ?? 'Pending',
      paidDate: json['paidDate'] as String? ?? json['paid_date'] as String?,
      lateFee: (json['lateFee'] ?? json['late_fee'] ?? 0.0).toDouble(),
    );
  }
}

class EmiCalculationPreview {
  final double principal;
  final double annualInterestRate;
  final int tenureMonths;
  final String interestType;
  final double emiAmount;
  final double totalInterest;
  final double totalPayable;
  final double monthlyPrincipalComponent;
  final double monthlyInterestComponent;

  const EmiCalculationPreview({
    required this.principal,
    required this.annualInterestRate,
    required this.tenureMonths,
    required this.interestType,
    required this.emiAmount,
    required this.totalInterest,
    required this.totalPayable,
    required this.monthlyPrincipalComponent,
    required this.monthlyInterestComponent,
  });

  factory EmiCalculationPreview.fromJson(Map<String, dynamic> json) {
    return EmiCalculationPreview(
      principal: (json['principal'] ?? 0.0).toDouble(),
      annualInterestRate: (json['annualInterestRate'] ?? 0.0).toDouble(),
      tenureMonths: (json['tenureMonths'] ?? 0) as int,
      interestType: json['interestType'] as String? ?? 'Reducing',
      emiAmount: (json['emiAmount'] ?? 0.0).toDouble(),
      totalInterest: (json['totalInterest'] ?? 0.0).toDouble(),
      totalPayable: (json['totalPayable'] ?? 0.0).toDouble(),
      monthlyPrincipalComponent: (json['monthlyPrincipalComponent'] ?? 0.0).toDouble(),
      monthlyInterestComponent: (json['monthlyInterestComponent'] ?? 0.0).toDouble(),
    );
  }
}

class LateFeeBreakdown {
  final double originalEmi;
  final int daysOverdue;
  final double fixedLateFee;
  final double percentageLateFee;
  final double dailyPenalty;
  final double lateFee;
  final double totalPayable;
  final String ruleApplied;
  final bool isOverdue;
  final bool inGracePeriod;

  const LateFeeBreakdown({
    required this.originalEmi,
    required this.daysOverdue,
    this.fixedLateFee = 0.0,
    this.percentageLateFee = 0.0,
    this.dailyPenalty = 0.0,
    required this.lateFee,
    required this.totalPayable,
    this.ruleApplied = '',
    this.isOverdue = false,
    this.inGracePeriod = false,
  });

  factory LateFeeBreakdown.fromJson(Map<String, dynamic> json) {
    return LateFeeBreakdown(
      originalEmi: (json['originalEmi'] ?? 0.0).toDouble(),
      daysOverdue: (json['daysOverdue'] ?? 0) as int,
      fixedLateFee: (json['fixedLateFee'] ?? 0.0).toDouble(),
      percentageLateFee: (json['percentageLateFee'] ?? 0.0).toDouble(),
      dailyPenalty: (json['dailyPenalty'] ?? 0.0).toDouble(),
      lateFee: (json['lateFee'] ?? 0.0).toDouble(),
      totalPayable: (json['totalPayable'] ?? 0.0).toDouble(),
      ruleApplied: json['ruleApplied'] as String? ?? '',
      isOverdue: json['isOverdue'] as bool? ?? false,
      inGracePeriod: json['inGracePeriod'] as bool? ?? false,
    );
  }

  factory LateFeeBreakdown.fromInstallment(EmiScheduleItem item) {
    final original = item.emiAmount;
    final isOverdue = item.status.toLowerCase() == 'overdue';
    if (!isOverdue) {
      return LateFeeBreakdown(
        originalEmi: original,
        daysOverdue: 0,
        lateFee: 0.0,
        totalPayable: original,
        isOverdue: false,
      );
    }

    // Default simulation if offline: 25 days overdue -> Flat 250 + 2% + 25/day past 3 grace days
    const daysOverdue = 25;
    final fee = (250.0 + (original * 0.02) + ((daysOverdue - 3) * 25.0)).clamp(0.0, 3000.0);
    return LateFeeBreakdown(
      originalEmi: original,
      daysOverdue: daysOverdue,
      fixedLateFee: 250.0,
      percentageLateFee: (original * 0.02),
      dailyPenalty: ((daysOverdue - 3) * 25.0),
      lateFee: (fee * 100).round() / 100.0,
      totalPayable: ((original + fee) * 100).round() / 100.0,
      ruleApplied: 'Late Fee: Flat ₹250 + 2% + ₹25/day after 3 days grace period',
      isOverdue: true,
    );
  }
}

class PrepaymentSimulationResult {
  final String strategy; // 'REDUCE_TENURE' or 'REDUCE_EMI'
  final double currentOutstanding;
  final double prepaymentAmount;
  final double revisedPrincipal;
  final double originalEmi;
  final double revisedEmi;
  final double monthlyEmiSaved;
  final int originalRemainingTenure;
  final int revisedTenureMonths;
  final int monthsSaved;
  final double interestSaved;
  final double originalTotalInterest;
  final double revisedTotalInterest;

  const PrepaymentSimulationResult({
    required this.strategy,
    required this.currentOutstanding,
    required this.prepaymentAmount,
    required this.revisedPrincipal,
    required this.originalEmi,
    required this.revisedEmi,
    this.monthlyEmiSaved = 0.0,
    required this.originalRemainingTenure,
    required this.revisedTenureMonths,
    this.monthsSaved = 0,
    required this.interestSaved,
    required this.originalTotalInterest,
    required this.revisedTotalInterest,
  });

  factory PrepaymentSimulationResult.fromJson(Map<String, dynamic> json) {
    return PrepaymentSimulationResult(
      strategy: json['strategy'] as String? ?? 'REDUCE_TENURE',
      currentOutstanding: (json['currentOutstanding'] ?? json['currentOutstandingPrincipal'] ?? 0.0).toDouble(),
      prepaymentAmount: (json['prepaymentAmount'] ?? 0.0).toDouble(),
      revisedPrincipal: (json['revisedPrincipal'] ?? 0.0).toDouble(),
      originalEmi: (json['originalEmi'] ?? 0.0).toDouble(),
      revisedEmi: (json['revisedEmi'] ?? 0.0).toDouble(),
      monthlyEmiSaved: (json['monthlyEmiSaved'] ?? 0.0).toDouble(),
      originalRemainingTenure: (json['originalRemainingTenure'] ?? 0) as int,
      revisedTenureMonths: (json['revisedTenureMonths'] ?? 0) as int,
      monthsSaved: (json['monthsSaved'] ?? 0) as int,
      interestSaved: (json['interestSaved'] ?? 0.0).toDouble(),
      originalTotalInterest: (json['originalTotalInterest'] ?? 0.0).toDouble(),
      revisedTotalInterest: (json['revisedTotalInterest'] ?? 0.0).toDouble(),
    );
  }
}

class ForeclosureSimulationResult {
  final double currentOutstandingPrincipal;
  final int remainingTenureMonths;
  final double foreclosureChargeRate;
  final double foreclosureChargeAmount;
  final double gstOnCharges;
  final double unpaidLateFees;
  final double totalCharges;
  final double totalForeclosureAmount;
  final double totalFutureInterestSaved;
  final double netSavings;

  const ForeclosureSimulationResult({
    required this.currentOutstandingPrincipal,
    required this.remainingTenureMonths,
    this.foreclosureChargeRate = 0.0,
    this.foreclosureChargeAmount = 0.0,
    this.gstOnCharges = 0.0,
    this.unpaidLateFees = 0.0,
    required this.totalCharges,
    required this.totalForeclosureAmount,
    required this.totalFutureInterestSaved,
    required this.netSavings,
  });

  factory ForeclosureSimulationResult.fromJson(Map<String, dynamic> json) {
    return ForeclosureSimulationResult(
      currentOutstandingPrincipal: (json['currentOutstandingPrincipal'] ?? 0.0).toDouble(),
      remainingTenureMonths: (json['remainingTenureMonths'] ?? 0) as int,
      foreclosureChargeRate: (json['foreclosureChargeRate'] ?? 0.0).toDouble(),
      foreclosureChargeAmount: (json['foreclosureChargeAmount'] ?? 0.0).toDouble(),
      gstOnCharges: (json['gstOnCharges'] ?? 0.0).toDouble(),
      unpaidLateFees: (json['unpaidLateFees'] ?? 0.0).toDouble(),
      totalCharges: (json['totalCharges'] ?? 0.0).toDouble(),
      totalForeclosureAmount: (json['totalForeclosureAmount'] ?? 0.0).toDouble(),
      totalFutureInterestSaved: (json['totalFutureInterestSaved'] ?? 0.0).toDouble(),
      netSavings: (json['netSavings'] ?? 0.0).toDouble(),
    );
  }
}

class LoanPaymentRecord {
  final String id;
  final String loanId;
  final String? emiScheduleId;
  final double amount;
  final String paymentDate;
  final String paymentType; // 'EMI', 'Custom / Prepayment', 'Settlement', 'Principal'
  final String paymentMethod; // 'Instant UPI', 'NetBanking', 'Debit Card', 'AutoPay'
  final double lateFee;
  final String? notes;

  const LoanPaymentRecord({
    required this.id,
    required this.loanId,
    this.emiScheduleId,
    required this.amount,
    required this.paymentDate,
    this.paymentType = 'EMI',
    this.paymentMethod = 'UPI',
    this.lateFee = 0.0,
    this.notes,
  });

  factory LoanPaymentRecord.fromJson(Map<String, dynamic> json) {
    return LoanPaymentRecord(
      id: json['id'] as String? ?? '',
      loanId: json['loanId'] as String? ?? json['loan_id'] as String? ?? '',
      emiScheduleId: json['emiScheduleId'] as String? ?? json['emi_schedule_id'] as String?,
      amount: (json['amount'] ?? 0.0).toDouble(),
      paymentDate: json['paymentDate'] as String? ?? json['payment_date'] as String? ?? json['createdAt'] as String? ?? '',
      paymentType: json['paymentType'] as String? ?? json['payment_type'] as String? ?? 'EMI',
      paymentMethod: json['paymentMethod'] as String? ?? json['payment_method'] as String? ?? 'UPI',
      lateFee: (json['lateFee'] ?? json['late_fee'] ?? 0.0).toDouble(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loanId': loanId,
      'emiScheduleId': emiScheduleId,
      'amount': amount,
      'paymentDate': paymentDate,
      'paymentType': paymentType,
      'paymentMethod': paymentMethod,
      'lateFee': lateFee,
      'notes': notes,
    };
  }
}

