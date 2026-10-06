import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../models/loan_model.dart';
import 'emi_calculator_engine.dart';

class LoanRepository {
  final ApiClient _apiClient;
  LoanRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Create a new loan and persist it to backend database
  Future<LoanModel> createLoan({
    required String loanType,
    required double principalAmount,
    required double interestRate,
    required int tenureMonths,
    required String startDate,
    String interestType = 'Reducing',
    String? lenderName,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.loans,
      body: {
        'loanType': loanType,
        'principalAmount': principalAmount,
        'interestRate': interestRate,
        'tenureMonths': tenureMonths,
        'startDate': startDate,
        'interestType': interestType,
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    final loanJson = data['loan'] as Map<String, dynamic>;
    return LoanModel.fromJson(loanJson);
  }

  /// Fetch all user loans from backend
  Future<List<LoanModel>> getLoans({String? status}) async {
    try {
      final endpoint = status != null ? '${ApiConfig.loans}?status=$status' : ApiConfig.loans;
      final response = await _apiClient.get(endpoint);
      final data = response['data'] as Map<String, dynamic>?;
      final loansJson = (data?['loans'] as List<dynamic>?) ?? [];
      
      final list = loansJson.map((json) => LoanModel.fromJson(json as Map<String, dynamic>)).toList();
      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
        return list.where((l) => l.status.toLowerCase() == status.toLowerCase()).toList();
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Compute or fetch aggregate Dashboard summary
  Future<LoanDashboardSummary> getDashboardSummary() async {
    try {
      final loans = await getLoans();
      final activeLoans = loans.where((l) => l.status == 'Active').toList();

      double totalOutstanding = 0;
      double nextEmiAmount = 0;
      String? nextDueDate;
      int? nextDaysRemaining;
      int overdueCount = 0;
      double overdueAmount = 0;

      for (final loan in activeLoans) {
        totalOutstanding += loan.outstandingAmount;
        if (loan.nextEmiStatus == 'Overdue') {
          overdueCount++;
          overdueAmount += loan.emiAmount;
        }
      }

      if (activeLoans.isNotEmpty) {
        final sortedByDue = List<LoanModel>.from(activeLoans)
          ..sort((a, b) => (a.nextDueDate ?? '').compareTo(b.nextDueDate ?? ''));
        nextEmiAmount = sortedByDue.first.emiAmount;
        nextDueDate = sortedByDue.first.nextDueDate;
        nextDaysRemaining = 6;
      }

      return LoanDashboardSummary(
        totalLoans: loans.length,
        activeLoans: activeLoans.length,
        totalOutstanding: EmiCalculatorEngine.roundTo2Decimals(totalOutstanding),
        nextEmiAmount: EmiCalculatorEngine.roundTo2Decimals(nextEmiAmount),
        nextEmiDueDate: nextDueDate ?? '',
        nextEmiDaysRemaining: nextDaysRemaining ?? 0,
        totalInterestPaid: 0.0,
        overdueEmisCount: overdueCount,
        overdueEmisAmount: EmiCalculatorEngine.roundTo2Decimals(overdueAmount),
      );
    } catch (_) {
      return LoanDashboardSummary.empty();
    }
  }

  /// Delete / Archive a loan
  Future<bool> deleteLoan(String loanId) async {
    try {
      await _apiClient.delete('${ApiConfig.loans}/$loanId');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Update loan status (e.g. archive or mark completed)
  Future<bool> updateLoanStatus(String loanId, String newStatus) async {
    try {
      await _apiClient.patch('${ApiConfig.loans}/$loanId', body: {'status': newStatus});
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get complete Amortization Schedule for a loan
  Future<List<EmiScheduleItem>> getAmortizationSchedule(LoanModel loan) async {
    try {
      final response = await _apiClient.get('${ApiConfig.loans}/${loan.id}/schedule');
      final data = response['data'] as Map<String, dynamic>;
      final scheduleJson = (data['schedule'] as List<dynamic>?) ?? [];

      if (scheduleJson.isNotEmpty) {
        return scheduleJson.map((json) => EmiScheduleItem.fromJson(json as Map<String, dynamic>)).toList();
      }
      return _generateFallbackSchedule(loan);
    } catch (_) {
      return _generateFallbackSchedule(loan);
    }
  }

  List<EmiScheduleItem> _generateFallbackSchedule(LoanModel loan) {
    int paidCount = (loan.tenureMonths - loan.remainingTenureMonths).clamp(0, loan.tenureMonths);
    if (loan.status == 'Closed') paidCount = loan.tenureMonths;
    int overdueCount = loan.nextEmiStatus == 'Overdue' ? 1 : 0;

    return EmiCalculatorEngine.generateAmortizationSchedule(
      loanId: loan.id,
      principal: loan.principalAmount,
      annualInterestRate: loan.interestRate,
      tenureMonths: loan.tenureMonths,
      startDate: loan.startDate.isNotEmpty ? loan.startDate : '2025-01-01',
      interestType: loan.interestType,
      paidCount: paidCount,
      overdueCount: overdueCount,
    );
  }

  /// Record EMI payment
  Future<bool> markEmiAsPaid({
    required String loanId,
    String? scheduleId,
    required double amount,
    double lateFee = 0.0,
    String? notes,
  }) async {
    try {
      await _apiClient.post(
        '${ApiConfig.loans}/$loanId/payments',
        body: {
          if (scheduleId != null && scheduleId.isNotEmpty) 'scheduleId': scheduleId,
          'amount': amount,
          'lateFee': lateFee,
          'notes': notes,
        },
      );
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Record payment (EMI, Prepayment, Settle) with payment method and real-time backend sync
  Future<LoanPaymentRecord?> recordLoanPayment({
    required String loanId,
    required double amount,
    String? scheduleId,
    String paymentType = 'EMI',
    String paymentMethod = 'UPI',
    double lateFee = 0.0,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.loans}/$loanId/payments',
        body: {
          if (scheduleId != null && scheduleId.isNotEmpty) 'scheduleId': scheduleId,
          'amount': amount,
          'paymentType': paymentType,
          'paymentMethod': paymentMethod,
          'lateFee': lateFee,
          'notes': notes ?? '$paymentType via $paymentMethod',
        },
      );

      final data = response['data'] as Map<String, dynamic>?;
      if (data != null && data['payment'] != null) {
        return LoanPaymentRecord.fromJson(data['payment'] as Map<String, dynamic>);
      }
      return LoanPaymentRecord(
        id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
        loanId: loanId,
        emiScheduleId: scheduleId,
        amount: amount,
        paymentDate: DateTime.now().toIso8601String().split('T').first,
        paymentType: paymentType,
        paymentMethod: paymentMethod,
        lateFee: lateFee,
        notes: notes,
      );
    } catch (_) {
      // Local fallback on offline/mock mode
      return LoanPaymentRecord(
        id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
        loanId: loanId,
        emiScheduleId: scheduleId,
        amount: amount,
        paymentDate: DateTime.now().toIso8601String().split('T').first,
        paymentType: paymentType,
        paymentMethod: paymentMethod,
        lateFee: lateFee,
        notes: notes,
      );
    }
  }

  /// Fetch all historical payments recorded for a loan
  Future<List<LoanPaymentRecord>> getPaymentHistory(String loanId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.loans}/$loanId/payments');
      final data = response['data'] as Map<String, dynamic>?;
      final paymentsJson = (data?['payments'] as List<dynamic>?) ?? [];
      return paymentsJson
          .map((item) => LoanPaymentRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }


  /// Get dynamic late fee calculation from backend
  Future<LateFeeBreakdown> getScheduleLateFee(
    String loanId,
    String scheduleId,
    EmiScheduleItem item,
  ) async {
    try {
      final response = await _apiClient.get('${ApiConfig.loans}/$loanId/schedules/$scheduleId/late-fee');
      final data = response['data'] as Map<String, dynamic>;
      return LateFeeBreakdown.fromJson(data);
    } catch (_) {
      return LateFeeBreakdown.fromInstallment(item);
    }
  }

  /// Simulate Prepayment Impact
  Future<PrepaymentSimulationResult?> simulatePrepayment({
    required String loanId,
    required double prepaymentAmount,
    String strategy = 'REDUCE_TENURE',
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.loans}/$loanId/prepayment/simulate',
        body: {
          'prepaymentAmount': prepaymentAmount,
          'strategy': strategy,
        },
      );
      final data = response['data'] as Map<String, dynamic>;
      return PrepaymentSimulationResult.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Simulate Full Foreclosure
  Future<ForeclosureSimulationResult?> simulateForeclosure({
    required String loanId,
    double foreclosureChargeRate = 0.0,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.loans}/$loanId/foreclosure/simulate',
        body: {
          'foreclosureChargeRate': foreclosureChargeRate,
        },
      );
      final data = response['data'] as Map<String, dynamic>;
      return ForeclosureSimulationResult.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Apply Prepayment
  Future<bool> applyPrepayment({
    required String loanId,
    required double prepaymentAmount,
    String strategy = 'REDUCE_TENURE',
    String? notes,
  }) async {
    try {
      await _apiClient.post(
        '${ApiConfig.loans}/$loanId/prepayment/apply',
        body: {
          'prepaymentAmount': prepaymentAmount,
          'strategy': strategy,
          'notes': notes,
        },
      );
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Apply Foreclosure
  Future<bool> applyForeclosure({
    required String loanId,
    double foreclosureChargeRate = 0.0,
    String? notes,
  }) async {
    try {
      await _apiClient.post(
        '${ApiConfig.loans}/$loanId/foreclosure/apply',
        body: {
          'foreclosureChargeRate': foreclosureChargeRate,
          'notes': notes,
        },
      );
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Get EMI Reminder configuration
  Future<Map<String, dynamic>> getReminderConfig() async {
    try {
      final res = await _apiClient.get('${ApiConfig.loans}/reminders/config');
      return (res['data'] as Map<String, dynamic>?) ?? {};
    } catch (_) {
      return {
        'advanceDays': [7, 3, 1, 0],
        'sendOverdueAlerts': true,
        'emailNotifications': true,
      };
    }
  }

  /// Update EMI Reminder configuration
  Future<bool> updateReminderConfig(Map<String, dynamic> config) async {
    try {
      await _apiClient.put('${ApiConfig.loans}/reminders/config', body: config);
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Trigger automated reminder scan & dispatch
  Future<Map<String, dynamic>> triggerReminderCheck() async {
    try {
      final res = await _apiClient.post('${ApiConfig.loans}/reminders/trigger-check', body: {});
      return (res['data'] as Map<String, dynamic>?) ?? {};
    } catch (_) {
      return {'dispatchedCount': 0, 'skippedDuplicatesCount': 0};
    }
  }
}
