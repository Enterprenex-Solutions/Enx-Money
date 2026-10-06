import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/loans/presentation/screens/loan_dashboard_screen.dart';
import 'package:enx_money/features/loans/data/loan_repository.dart';

import 'package:enx_money/features/loans/models/loan_model.dart';

class TestLoanRepository extends LoanRepository {
  final List<LoanModel> _testLoans = [
    const LoanModel(
      id: 'test-loan-001',
      userId: 'user-01',
      loanType: 'Home',
      lenderName: 'HDFC Housing Finance',
      principalAmount: 4500000.0,
      interestRate: 8.5,
      tenureMonths: 240,
      startDate: '2025-01-01',
      interestType: 'Reducing',
      emiAmount: 39052.04,
      totalInterest: 4872489.6,
      totalPayable: 9372489.6,
      status: 'Active',
      outstandingAmount: 4320400.0,
      remainingTenureMonths: 220,
      nextDueDate: '2026-09-01',
      nextEmiStatus: 'Pending',
    ),
    const LoanModel(
      id: 'test-loan-002',
      userId: 'user-01',
      loanType: 'Vehicle',
      lenderName: 'ICICI Auto Prime',
      principalAmount: 1200000.0,
      interestRate: 9.25,
      tenureMonths: 60,
      startDate: '2024-06-15',
      interestType: 'Reducing',
      emiAmount: 25066.85,
      totalInterest: 304011.0,
      totalPayable: 1504011.0,
      status: 'Active',
      outstandingAmount: 845200.0,
      remainingTenureMonths: 34,
      nextDueDate: '2026-09-15',
      nextEmiStatus: 'Pending',
    ),
    const LoanModel(
      id: 'test-loan-003',
      userId: 'user-01',
      loanType: 'Personal',
      lenderName: 'ENX Black Credit',
      principalAmount: 300000.0,
      interestRate: 11.5,
      tenureMonths: 24,
      startDate: '2025-11-01',
      interestType: 'Reducing',
      emiAmount: 14052.40,
      totalInterest: 37257.6,
      totalPayable: 337257.6,
      status: 'Active',
      outstandingAmount: 195000.0,
      remainingTenureMonths: 14,
      nextDueDate: '2026-08-20',
      nextEmiStatus: 'Overdue',
    ),
    const LoanModel(
      id: 'test-loan-004',
      userId: 'user-01',
      loanType: 'Business',
      lenderName: 'Axis Business Credit',
      principalAmount: 500000.0,
      interestRate: 12.0,
      tenureMonths: 12,
      startDate: '2024-01-01',
      interestType: 'Flat',
      emiAmount: 46666.67,
      totalInterest: 60000.0,
      totalPayable: 560000.0,
      status: 'Closed',
      outstandingAmount: 0.0,
      remainingTenureMonths: 0,
      nextDueDate: null,
      nextEmiStatus: 'Paid',
    ),
  ];

  @override
  Future<List<LoanModel>> getLoans({String? status}) async {
    if (status == null || status.isEmpty || status.toLowerCase() == 'all') {
      return _testLoans;
    }
    return _testLoans.where((l) => l.status.toLowerCase() == status.toLowerCase()).toList();
  }

  @override
  Future<LoanDashboardSummary> getDashboardSummary() async {
    return const LoanDashboardSummary(
      totalLoans: 4,
      activeLoans: 3,
      totalOutstanding: 5360600.0,
      nextEmiAmount: 39052.04,
      nextEmiDueDate: '01 Sep 2026',
      nextEmiDaysRemaining: 6,
      totalInterestPaid: 184500.0,
      overdueEmisCount: 1,
      overdueEmisAmount: 14052.40,
    );
  }
}

void main() {
  testWidgets('LoanDashboardScreen renders summary cards, overdue banner, and loan list', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repo = TestLoanRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: LoanDashboardScreen(repository: repo),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and Subtitle
    expect(find.text('Loan Portfolio'), findsOneWidget);
    expect(find.text('TOTAL OUTSTANDING DEBT'), findsOneWidget);

    // Verify Overdue Alert Banner
    expect(find.textContaining('OVERDUE EMI DETECTED'), findsOneWidget);

    // Verify Summary Metrics
    expect(find.text('TOTAL LOANS'), findsOneWidget);
    expect(find.text('INTEREST PAID'), findsOneWidget);

    // Verify Filter Tabs
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);

    // Verify Loan Cards & Lenders
    expect(find.text('HDFC Housing Finance'), findsOneWidget);
    expect(find.text('ICICI Auto Prime'), findsOneWidget);
    expect(find.text('ENX Black Credit'), findsOneWidget);
    expect(find.text('Axis Business Credit'), findsOneWidget);

    // Verify Status Badges
    expect(find.text('OVERDUE'), findsOneWidget);
    expect(find.text('COMPLETED'), findsOneWidget);
    expect(find.text('PENDING'), findsWidgets);
  });

  testWidgets('Filtering tabs filters loans accurately', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repo = TestLoanRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: LoanDashboardScreen(repository: repo),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Overdue filter tab
    await tester.tap(find.text('Overdue'));
    await tester.pumpAndSettle();

    // Only overdue loan should be displayed in the list
    expect(find.text('ENX Black Credit'), findsOneWidget);
    expect(find.text('HDFC Housing Finance'), findsNothing);

    // Tap Completed filter tab
    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();

    expect(find.text('Axis Business Credit'), findsOneWidget);
    expect(find.text('ENX Black Credit'), findsNothing);
  });

  testWidgets('Tapping Pay EMI opens payment modal', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repo = TestLoanRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: LoanDashboardScreen(repository: repo),
      ),
    );
    await tester.pumpAndSettle();

    // Tap first 'Pay EMI' button
    await tester.tap(find.text('Pay EMI').first);
    await tester.pumpAndSettle();

    expect(find.text('PAY MONTHLY EMI'), findsOneWidget);
    expect(find.text('AUTO-DEBIT READY'), findsOneWidget);
  });
}
