import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/analytics/models/business_health_score_model.dart';
import 'package:enx_money/features/analytics/presentation/widgets/business_health_score_card.dart';
import 'package:enx_money/features/analytics/presentation/widgets/data_analysis_card.dart';

void main() {
  group('Data Analysis & Analytics Responsiveness Tests', () {
    final insufficientDataScore = BusinessHealthScore(
      score: 0,
      status: 'Insufficient Data',
      statusColorHex: '#64748B',
      hasSufficientData: false,
      calculatedAt: DateTime.now(),
      breakdown: {
        'profitability': HealthScoreMetric(score: 0, max: 20),
        'collections': HealthScoreMetric(score: 0, max: 20),
        'expenseControl': HealthScoreMetric(score: 0, max: 20),
        'liabilityCoverage': HealthScoreMetric(score: 0, max: 20),
      },
      actionableTips: [
        'Record business sales, GST invoices, or operating expenses to unlock your AI Business Health Score.'
      ],
    );

    final activeScore = BusinessHealthScore(
      score: 82,
      status: 'Excellent',
      statusColorHex: '#00E676',
      hasSufficientData: true,
      calculatedAt: DateTime.now(),
      breakdown: {
        'profitability': HealthScoreMetric(score: 18, max: 20),
        'collections': HealthScoreMetric(score: 16, max: 20),
        'expenseControl': HealthScoreMetric(score: 15, max: 20),
        'liabilityCoverage': HealthScoreMetric(score: 17, max: 20),
      },
      actionableTips: [
        'Great cash reserves! Maintain your collection cycle below 30 days.'
      ],
    );

    // Screen dimensions to test:
    final screenSizes = [
      const Size(320, 640), // Compact screen / small phone
      const Size(360, 780), // Standard Android phone
      const Size(390, 844), // Medium-large Android phone
      const Size(412, 915), // High-res Pixel Android phone
    ];

    for (final size in screenSizes) {
      testWidgets('BusinessHealthScoreCard (Insufficient Data) fits without overflow on ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: BusinessHealthScoreCard(
                  healthScore: insufficientDataScore,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify key text elements exist
        expect(find.text('BUSINESS HEALTH SCORE'), findsOneWidget);
        expect(find.text('AI Financial Vitality'), findsOneWidget);
        expect(find.text('INSUFFICIENT DATA'), findsOneWidget);
        expect(find.text('Awaiting First Business Activity'), findsOneWidget);

        // Verify no overflow errors
        expect(tester.takeException(), isNull);
      });

      testWidgets('BusinessHealthScoreCard (Active Score) fits without overflow on ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: BusinessHealthScoreCard(
                  healthScore: activeScore,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('BUSINESS HEALTH SCORE'), findsOneWidget);
        expect(find.text('82'), findsOneWidget);
        expect(find.text('EXCELLENT'), findsOneWidget);
        expect(find.text('Profit Margin'), findsOneWidget);

        expect(tester.takeException(), isNull);
      });

      testWidgets('DataAnalysisCard grid layout renders cleanly without overflow on ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final cardWidth = size.width - 32;
        final ratio = cardWidth < 350 ? 1.20 : (cardWidth < 400 ? 1.25 : 1.30);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: ratio,
                  children: [
                    DataAnalysisCard(
                      title: 'Total Revenue',
                      amount: 154200,
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFF00E676),
                      subtitle: 'Gross Inflow',
                    ),
                    DataAnalysisCard(
                      title: 'Total Expense',
                      amount: 84300,
                      icon: Icons.trending_down_rounded,
                      color: const Color(0xFFFF5252),
                      subtitle: 'Total Outflow',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Total Revenue'), findsOneWidget);
        expect(find.text('Gross Inflow'), findsOneWidget);
        expect(find.text('Total Expense'), findsOneWidget);
        expect(find.text('Total Outflow'), findsOneWidget);

        expect(tester.takeException(), isNull);
      });
    }
  });
}
