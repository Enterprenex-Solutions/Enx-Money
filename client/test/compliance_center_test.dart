import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:enx_money/domain/repositories/transaction_repository.dart';
import 'package:enx_money/ui/features/compliance/compliance_center_view.dart';

void main() {
  testWidgets('ComplianceCenterView renders all 8 tabs on mobile screen (392dp) with 0 layout overflows', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75; // 392.7 x 872.7 dp
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TransactionRepository()),
        ],
        child: const MaterialApp(
          home: ComplianceCenterView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Compliance Center'), findsOneWidget);
    expect(find.text('1. Workflow'), findsOneWidget);

    final tabBarView = tester.widget<TabBarView>(find.byType(TabBarView));
    final controller = tabBarView.controller!;

    for (int i = 0; i < 8; i++) {
      controller.animateTo(i);
      await tester.pumpAndSettle();
    }

    // Verify Tab 8 content
    expect(find.text('Section 12: Data Analysis Compliance Register'), findsOneWidget);
  });

  testWidgets('ComplianceCenterView renders all 8 tabs on narrow screen (320dp) with 0 layout overflows', (tester) async {
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2.0; // 320 x 568 dp
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TransactionRepository()),
        ],
        child: const MaterialApp(
          home: ComplianceCenterView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tabBarView = tester.widget<TabBarView>(find.byType(TabBarView));
    final controller = tabBarView.controller!;

    for (int i = 0; i < 8; i++) {
      controller.animateTo(i);
      await tester.pumpAndSettle();
    }

    expect(find.text('Section 12: Data Analysis Compliance Register'), findsOneWidget);
  });
}
