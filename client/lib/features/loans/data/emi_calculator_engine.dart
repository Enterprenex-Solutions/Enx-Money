import 'dart:math';
import '../models/loan_model.dart';

/// Client-side high-performance EMI Calculator Engine for instant 60fps UI responsiveness
class EmiCalculatorEngine {
  EmiCalculatorEngine._();

  static double roundTo2Decimals(double value) {
    if (value.isNaN || value.isInfinite) return 0.0;
    return (value * 100).roundToDouble() / 100.0;
  }

  static EmiCalculationPreview calculate({
    required double principal,
    required double annualInterestRate,
    required int tenureMonths,
    String interestType = 'Reducing',
  }) {
    if (principal <= 0 || tenureMonths <= 0) {
      return EmiCalculationPreview(
        principal: max(0.0, principal),
        annualInterestRate: max(0.0, annualInterestRate),
        tenureMonths: max(0, tenureMonths),
        interestType: interestType,
        emiAmount: 0.0,
        totalInterest: 0.0,
        totalPayable: max(0.0, principal),
        monthlyPrincipalComponent: 0.0,
        monthlyInterestComponent: 0.0,
      );
    }

    final p = principal;
    final rAnnual = annualInterestRate;
    final n = tenureMonths;
    final isFlat = interestType.toLowerCase() == 'flat';

    // 1. Zero-Interest case
    if (rAnnual <= 0) {
      final emi = roundTo2Decimals(p / n);
      return EmiCalculationPreview(
        principal: roundTo2Decimals(p),
        annualInterestRate: 0.0,
        tenureMonths: n,
        interestType: interestType,
        emiAmount: emi,
        totalInterest: 0.0,
        totalPayable: roundTo2Decimals(p),
        monthlyPrincipalComponent: emi,
        monthlyInterestComponent: 0.0,
      );
    }

    // 2. Flat Rate
    if (isFlat) {
      final totalInterest = roundTo2Decimals(p * (rAnnual / 100.0) * (n / 12.0));
      final totalPayable = roundTo2Decimals(p + totalInterest);
      final emi = roundTo2Decimals(totalPayable / n);
      final monthlyPrincipal = roundTo2Decimals(p / n);
      final monthlyInterest = roundTo2Decimals(totalInterest / n);

      return EmiCalculationPreview(
        principal: roundTo2Decimals(p),
        annualInterestRate: rAnnual,
        tenureMonths: n,
        interestType: 'Flat',
        emiAmount: emi,
        totalInterest: totalInterest,
        totalPayable: totalPayable,
        monthlyPrincipalComponent: monthlyPrincipal,
        monthlyInterestComponent: monthlyInterest,
      );
    }

    // 3. Reducing Balance
    // EMI = P * r * (1 + r)^n / ((1 + r)^n - 1)
    final r = (rAnnual / 12.0) / 100.0;
    final powVal = pow(1.0 + r, n.toDouble()).toDouble();
    final emi = roundTo2Decimals((p * r * powVal) / (powVal - 1.0));
    final totalPayable = roundTo2Decimals(emi * n);
    final totalInterest = roundTo2Decimals(totalPayable - p);
    final initialInterest = roundTo2Decimals(p * r);
    final initialPrincipal = roundTo2Decimals(emi - initialInterest);

    return EmiCalculationPreview(
      principal: roundTo2Decimals(p),
      annualInterestRate: rAnnual,
      tenureMonths: n,
      interestType: 'Reducing',
      emiAmount: emi,
      totalInterest: totalInterest,
      totalPayable: totalPayable,
      monthlyPrincipalComponent: initialPrincipal,
      monthlyInterestComponent: initialInterest,
    );
  }

  static String calculateDueDate(String startDateStr, int installmentIndex) {
    try {
      final start = DateTime.parse(startDateStr);
      final year = start.year + ((start.month - 1 + installmentIndex) ~/ 12);
      final month = ((start.month - 1 + installmentIndex) % 12) + 1;
      final originalDay = start.day;
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final day = min(originalDay, daysInMonth);

      final dt = DateTime(year, month, day);
      return "${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    } catch (_) {
      final now = DateTime.now().add(Duration(days: 30 * installmentIndex));
      return "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    }
  }

  static List<EmiScheduleItem> generateAmortizationSchedule({
    required String loanId,
    required double principal,
    required double annualInterestRate,
    required int tenureMonths,
    required String startDate,
    String interestType = 'Reducing',
    int paidCount = 0,
    int overdueCount = 0,
  }) {
    if (principal <= 0 || tenureMonths <= 0) return [];

    final isFlat = interestType.toLowerCase() == 'flat';
    final preview = calculate(
      principal: principal,
      annualInterestRate: annualInterestRate,
      tenureMonths: tenureMonths,
      interestType: interestType,
    );

    final emi = preview.emiAmount;
    final r = (annualInterestRate / 12.0) / 100.0;
    double currentBalance = principal;
    final List<EmiScheduleItem> schedule = [];

    for (int i = 1; i <= tenureMonths; i++) {
      final openingBalance = roundTo2Decimals(currentBalance);
      double interestAmount;
      double principalAmount;
      double closingBalance;

      if (isFlat) {
        interestAmount = roundTo2Decimals(preview.monthlyInterestComponent);
        if (i == tenureMonths) {
          principalAmount = roundTo2Decimals(openingBalance);
          closingBalance = 0.0;
        } else {
          principalAmount = roundTo2Decimals(preview.monthlyPrincipalComponent);
          closingBalance = roundTo2Decimals(max(0.0, openingBalance - principalAmount));
        }
      } else {
        if (annualInterestRate <= 0) {
          interestAmount = 0.0;
          if (i == tenureMonths) {
            principalAmount = roundTo2Decimals(openingBalance);
            closingBalance = 0.0;
          } else {
            principalAmount = roundTo2Decimals(emi);
            closingBalance = roundTo2Decimals(max(0.0, openingBalance - principalAmount));
          }
        } else {
          interestAmount = roundTo2Decimals(openingBalance * r);
          if (i == tenureMonths) {
            principalAmount = roundTo2Decimals(openingBalance);
            closingBalance = 0.0;
          } else {
            principalAmount = roundTo2Decimals(emi - interestAmount);
            closingBalance = roundTo2Decimals(max(0.0, openingBalance - principalAmount));
          }
        }
      }

      currentBalance = closingBalance;
      final dueDate = calculateDueDate(startDate, i);

      String status = 'Pending';
      if (i <= paidCount) {
        status = 'Paid';
      } else if (i <= paidCount + overdueCount) {
        status = 'Overdue';
      }

      schedule.add(
        EmiScheduleItem(
          id: '$loanId-inst-$i',
          loanId: loanId,
          installmentNumber: i,
          dueDate: dueDate,
          openingBalance: openingBalance,
          principalAmount: principalAmount,
          interestAmount: interestAmount,
          emiAmount: emi,
          closingBalance: closingBalance,
          status: status,
        ),
      );
    }

    return schedule;
  }
}

