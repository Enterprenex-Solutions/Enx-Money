import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/finance_mode/models/goal_model.dart';
import 'package:enx_money/features/finance_mode/models/budget_model.dart';
import 'package:enx_money/core/widgets/finance/skeleton_loader.dart';

void main() {
  group('Personal Dashboard Models & Live Calculations Tests', () {
    test('GoalModel calculates progress, percentage, and remaining correctly', () {
      final goal = GoalModel(
        id: 'goal_001',
        title: 'Emergency Fund',
        targetAmount: 500000.0,
        currentAmount: 250000.0,
        targetDate: 'Dec 2026',
        category: 'Safety',
      );

      expect(goal.id, 'goal_001');
      expect(goal.title, 'Emergency Fund');
      expect(goal.progress, 0.5);
      expect(goal.percentage, 50.0);
      expect(goal.remaining, 250000.0);

      // JSON Serialization
      final json = goal.toJson();
      expect(json['title'], 'Emergency Fund');
      expect(json['targetAmount'], 500000.0);

      final fromJson = GoalModel.fromJson(json);
      expect(fromJson.title, goal.title);
      expect(fromJson.targetAmount, goal.targetAmount);
      expect(fromJson.currentAmount, goal.currentAmount);
      expect(fromJson.progress, 0.5);
    });

    test('BudgetCategoryModel calculates progress and over-budget flag correctly', () {
      final budget = BudgetCategoryModel(
        id: 'bgt_001',
        categoryName: 'Groceries',
        budgetLimit: 15000.0,
        spentAmount: 9000.0,
        colorHex: '#10B981',
        iconName: 'shopping_basket',
      );

      expect(budget.progress, 0.6);
      expect(budget.percentage, 60.0);
      expect(budget.remaining, 6000.0);
      expect(budget.isOverBudget, isFalse);
      expect(budget.icon, Icons.shopping_basket_outlined);

      // Over-budget condition
      final overBudget = BudgetCategoryModel(
        id: 'bgt_002',
        categoryName: 'Dining Out',
        budgetLimit: 5000.0,
        spentAmount: 7000.0,
      );
      expect(overBudget.isOverBudget, isTrue);
      expect(overBudget.progress, 1.0); // clamped
      expect(overBudget.remaining, 0.0);
    });

    testWidgets('DashboardSkeletonLoader renders without layout errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardSkeletonLoader(),
          ),
        ),
      );

      expect(find.byType(DashboardSkeletonLoader), findsOneWidget);
      expect(find.byType(SkeletonBox), findsWidgets);
    });
  });
}
