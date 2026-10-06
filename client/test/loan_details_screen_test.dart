import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/loans/presentation/screens/loan_details_screen.dart';
import 'package:enx_money/features/loans/models/loan_model.dart';
import 'package:enx_money/features/loans/data/loan_repository.dart';

void main() {
  final testLoan = const LoanModel(
    id: 'test-loan-home-01',
    userId: 'user-001',
    loanType: 'Home',
    lenderName: 'HDFC Housing Finance',
    principalAmount: 4500000.0,
    interestRate: 8.5,
    tenureMonths: 24,
    startDate: '2025-01-01',
    interestType: 'Reducing',
    emiAmount: 204560.85,
    totalInterest: 409460.40,
    totalPayable: 4909460.40,
    status: 'Active',
    outstandingAmount: 4120000.0,
    remainingTenureMonths: 20,
    nextDueDate: '2026-09-01',
    nextEmiStatus: 'Overdue',
  );

  testWidgets('LoanDetailsScreen renders Loan Overview and Amortization Schedule', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repo = LoanRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: LoanDetailsScreen(loan: testLoan, repository: repo),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Status
    expect(find.text('Home Loan'), findsOneWidget);
    expect(find.text('HDFC HOUSING FINANCE'), findsOneWidget);

    // Verify Loan Overview Hero Section
    expect(find.text('MONTHLY EMI OBLIGATION'), findsOneWidget);
    expect(find.text('PRINCIPAL AMOUNT'), findsOneWidget);
    expect(find.text('TOTAL INTEREST'), findsOneWidget);
    expect(find.text('TOTAL PAYABLE'), findsOneWidget);
    expect(find.text('TENURE'), findsOneWidget);

    // Verify Amortization Schedule section and filters
    expect(find.text('AMORTIZATION SCHEDULE'), findsOneWidget);
    expect(find.textContaining('All (24)'), findsOneWidget);
    expect(find.textContaining('Paid (4)'), findsOneWidget);
    expect(find.textContaining('Overdue (1)'), findsOneWidget);

    // Verify Installments & Columns
    expect(find.text('#01'), findsOneWidget);
    expect(find.text('EMI Amount'), findsWidgets);
    expect(find.text('Principal'), findsWidgets);
    expect(find.text('Interest'), findsWidgets);
    expect(find.text('Closing Bal.'), findsWidgets);

    // Verify Overdue status highlighting
    expect(find.text('OVERDUE'), findsWidgets);
    expect(find.text('Pay Now'), findsOneWidget);
  });

  testWidgets('Filtering Amortization Schedule shows only selected status', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repo = LoanRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: LoanDetailsScreen(loan: testLoan, repository: repo),
      ),
    );
    await tester.pumpAndSettle();

    // Tap 'Overdue' filter
    await tester.tap(find.textContaining('Overdue'));
    await tester.pumpAndSettle();

    expect(find.text('Pay Now'), findsOneWidget);

    // Tap 'Paid' filter
    await tester.tap(find.textContaining('Paid'));
    await tester.pumpAndSettle();

    expect(find.textContaining('PAID'), findsWidgets);
    expect(find.text('Pay Now'), findsNothing);
  });

  testWidgets('Tapping Pay Now on overdue installment opens confirmation modal and updates status', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repo = LoanRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: LoanDetailsScreen(loan: testLoan, repository: repo),
      ),
    );
    await tester.pumpAndSettle();

    // Tap 'Pay Now' on overdue installment
    await tester.tap(find.text('Pay Now'));
    await tester.pumpAndSettle();

    expect(find.text('RECORD EMI PAYMENT'), findsOneWidget);
    expect(find.textContaining('Confirm Pay'), findsOneWidget);

    // Tap 'Confirm Pay'
    await tester.tap(find.textContaining('Confirm Pay'));
    await tester.pumpAndSettle();

    expect(find.textContaining('marked as PAID'), findsOneWidget);
  });

  testWidgets('Pagination buttons navigate pages on 24-installment schedule', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repo = LoanRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: LoanDetailsScreen(loan: testLoan, repository: repo),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Page 1 of 2'), findsOneWidget);
    expect(find.text('#01'), findsOneWidget);

    // Tap next page arrow
    await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Page 2 of 2'), findsOneWidget);
    expect(find.text('#13'), findsOneWidget);
  });
}
