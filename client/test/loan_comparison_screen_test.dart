import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/loans/models/loan_model.dart';
import 'package:enx_money/features/loans/presentation/screens/loan_comparison_screen.dart';

void main() {
  final sampleLoans = [
    const LoanModel(
      id: 'loan-comp-1',
      userId: 'user-1',
      loanType: 'Personal',
      lenderName: 'ENX Black Credit',
      principalAmount: 200000,
      interestRate: 12.0,
      tenureMonths: 24,
      startDate: '2026-01-01',
      interestType: 'Reducing',
      emiAmount: 9414.69,
      totalInterest: 25952.66,
      totalPayable: 225952.66,
      outstandingAmount: 150000,
      remainingTenureMonths: 18,
    ),
    const LoanModel(
      id: 'loan-comp-2',
      userId: 'user-1',
      loanType: 'Vehicle',
      lenderName: 'ICICI Auto Prime',
      principalAmount: 600000,
      interestRate: 9.5,
      tenureMonths: 36,
      startDate: '2025-06-01',
      interestType: 'Reducing',
      emiAmount: 19221.72,
      totalInterest: 91981.82,
      totalPayable: 691981.82,
      outstandingAmount: 480000,
      remainingTenureMonths: 28,
    ),
    const LoanModel(
      id: 'loan-comp-3',
      userId: 'user-1',
      loanType: 'Home',
      lenderName: 'HDFC Housing Finance',
      principalAmount: 3000000,
      interestRate: 8.5,
      tenureMonths: 120,
      startDate: '2024-01-01',
      interestType: 'Reducing',
      emiAmount: 37198.81,
      totalInterest: 1463856.88,
      totalPayable: 4463856.88,
      outstandingAmount: 2800000,
      remainingTenureMonths: 108,
    ),
  ];

  Widget buildTestWidget(List<LoanModel> loans) {
    return MaterialApp(
      home: LoanComparisonScreen(
        initialLoans: loans,
      ),
    );
  }

  testWidgets('LoanComparisonScreen renders key highlights, visual benchmarks, and matrix table', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    await tester.pumpWidget(buildTestWidget(sampleLoans));
    await tester.pumpAndSettle();

    // Verify Title and Selection Bar
    expect(find.text('Multi-Loan Comparison'), findsOneWidget);
    expect(find.text('SELECT LOANS TO COMPARE'), findsOneWidget);

    // Verify 4 Highlight Cards
    expect(find.text('Highest Interest Cost'), findsOneWidget);
    expect(find.text('Highest Monthly EMI'), findsOneWidget);
    expect(find.text('Largest Balance'), findsOneWidget);
    expect(find.text('Shortest Remaining'), findsOneWidget);

    // Verify Highlight Values
    expect(find.text('MAX INTEREST'), findsOneWidget);
    expect(find.text('Home Loan'), findsWidgets); // Home has highest interest & largest balance
    expect(find.text('18 Mos'), findsOneWidget); // Personal loan has shortest remaining (18 mos)

    // Verify Visual Metric Benchmark
    expect(find.text('VISUAL METRIC BENCHMARK'), findsOneWidget);
    expect(find.text('Monthly EMI Breakdown'), findsOneWidget);
    expect(find.text('Principal vs Total Interest Breakdown'), findsOneWidget);

    // Verify Comparison Table
    expect(find.text('SIDE-BY-SIDE MATRIX'), findsOneWidget);
    expect(find.text('FINANCIAL METRIC'), findsOneWidget);
    expect(find.text('Personal Loan'), findsWidgets);
    expect(find.text('Vehicle Loan'), findsWidgets);
  });

  testWidgets('Toggling loan selection updates compared set', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    await tester.pumpWidget(buildTestWidget(sampleLoans));
    await tester.pumpAndSettle();

    // Tap Deselect All
    await tester.tap(find.text('Deselect All'));
    await tester.pumpAndSettle();

    // Verify No Selection State
    expect(find.text('Please select at least one loan from above to compare metrics.'), findsOneWidget);

    // Tap Select All
    await tester.tap(find.text('Select All'));
    await tester.pumpAndSettle();

    // Highlights should reappear
    expect(find.text('KEY COMPARISON HIGHLIGHTS'), findsOneWidget);
  });
}
