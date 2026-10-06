import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/loans/presentation/screens/add_loan_screen.dart';
import 'package:enx_money/features/loans/data/emi_calculator_engine.dart';
import 'package:enx_money/features/loans/models/loan_model.dart';
import 'package:enx_money/features/loans/data/loan_repository.dart';

class FakeLoanRepository extends LoanRepository {
  LoanModel? createdLoan;

  @override
  Future<LoanModel> createLoan({
    required String loanType,
    required double principalAmount,
    required double interestRate,
    required int tenureMonths,
    required String startDate,
    String interestType = 'Reducing',
    String? lenderName,
  }) async {
    final calc = EmiCalculatorEngine.calculate(
      principal: principalAmount,
      annualInterestRate: interestRate,
      tenureMonths: tenureMonths,
      interestType: interestType,
    );

    createdLoan = LoanModel(
      id: 'fake-loan-123',
      userId: 'test-user',
      loanType: loanType,
      principalAmount: principalAmount,
      interestRate: interestRate,
      tenureMonths: tenureMonths,
      startDate: startDate,
      interestType: interestType,
      emiAmount: calc.emiAmount,
      totalInterest: calc.totalInterest,
      totalPayable: calc.totalPayable,
      status: 'Active',
    );
    return createdLoan!;
  }
}

void main() {
  test('EmiCalculatorEngine computes Reducing and Flat EMI properly', () {
    final reducing = EmiCalculatorEngine.calculate(
      principal: 500000,
      annualInterestRate: 8.5,
      tenureMonths: 60,
      interestType: 'Reducing',
    );

    expect(reducing.emiAmount, 10258.27);
    expect(reducing.totalPayable, 615496.2);
    expect(reducing.totalInterest, 115496.2);

    final flat = EmiCalculatorEngine.calculate(
      principal: 100000,
      annualInterestRate: 10.0,
      tenureMonths: 12,
      interestType: 'Flat',
    );

    expect(flat.emiAmount, 9166.67);
    expect(flat.totalInterest, 10000.0);
    expect(flat.totalPayable, 110000.0);
  });

  testWidgets('AddLoanScreen renders all loan input fields and preview card', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final fakeRepo = FakeLoanRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: AddLoanScreen(repository: fakeRepo),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and Subtitle
    expect(find.text('Add New Loan'), findsOneWidget);
    expect(find.text('LIVE ESTIMATED MONTHLY EMI'), findsOneWidget);

    // Verify Loan Types are rendered
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Vehicle'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Business'), findsOneWidget);

    // Verify Principal Amount input and quick chips
    expect(find.text('PRINCIPAL LOAN AMOUNT'), findsOneWidget);
    expect(find.text('₹1 Lakh'), findsOneWidget);
    expect(find.text('₹5 Lakhs'), findsOneWidget);

    // Verify Interest Rate & Method
    expect(find.text('ANNUAL INTEREST RATE'), findsOneWidget);
    expect(find.text('Reducing'), findsOneWidget);
    expect(find.text('Flat'), findsOneWidget);

    // Verify Tenure & Unit
    expect(find.text('LOAN TENURE'), findsOneWidget);
    expect(find.text('Years'), findsOneWidget);
    expect(find.text('Months'), findsOneWidget);

    // Verify Create Button
    expect(find.text('Create Loan & Schedule'), findsOneWidget);
  });

  testWidgets('Selecting quick chips updates principal and recalculates EMI preview', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final fakeRepo = FakeLoanRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: AddLoanScreen(repository: fakeRepo),
      ),
    );
    await tester.pumpAndSettle();

    // Tap ₹10 Lakhs quick chip
    await tester.tap(find.text('₹10 Lakhs'));
    await tester.pumpAndSettle();

    // Verify live preview recalculated for 10 Lakhs (8.5% p.a., 5 years / 60 months => ~₹20,516)
    expect(find.textContaining('20,516'), findsOneWidget);
  });
}
