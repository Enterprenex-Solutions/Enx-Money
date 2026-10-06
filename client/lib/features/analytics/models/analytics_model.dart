import 'package:flutter/material.dart';

class SpendingCategoryMetric {
  final String categoryName;
  final double amount;
  final double percentage;
  final IconData icon;
  final Color color;
  final int transactionCount;

  const SpendingCategoryMetric({
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.icon,
    required this.color,
    required this.transactionCount,
  });
}

class MonthlyExpenseAnalytics {
  final double totalSpent;
  final double monthlyBudget;
  final double dailyAverage;
  final double savingsRate;
  final List<SpendingCategoryMetric> topCategories;
  final List<double> weeklySpends;

  const MonthlyExpenseAnalytics({
    required this.totalSpent,
    required this.monthlyBudget,
    required this.dailyAverage,
    required this.savingsRate,
    required this.topCategories,
    required this.weeklySpends,
  });
}
