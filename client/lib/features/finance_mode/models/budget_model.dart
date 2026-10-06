import 'package:flutter/material.dart';

class BudgetCategoryModel {
  final String id;
  final String categoryName;
  final double budgetLimit;
  final double spentAmount;
  final String colorHex;
  final String iconName;

  const BudgetCategoryModel({
    required this.id,
    required this.categoryName,
    required this.budgetLimit,
    this.spentAmount = 0.0,
    this.colorHex = '#0066FF',
    this.iconName = 'category',
  });

  double get progress {
    if (budgetLimit <= 0) return 0.0;
    return (spentAmount / budgetLimit).clamp(0.0, 1.0);
  }

  double get percentage => progress * 100;

  double get remaining => (budgetLimit - spentAmount).clamp(0.0, double.infinity);

  bool get isOverBudget => spentAmount > budgetLimit;

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF0066FF);
  }

  IconData get icon {
    switch (iconName.toLowerCase()) {
      case 'shopping_basket':
      case 'grocery':
      case 'groceries':
        return Icons.shopping_basket_outlined;
      case 'flash_on':
      case 'utility':
      case 'utilities':
        return Icons.flash_on_outlined;
      case 'restaurant':
      case 'dining':
      case 'food':
        return Icons.restaurant_outlined;
      case 'shopping_bag':
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'directions_car':
      case 'fuel':
      case 'travel':
        return Icons.directions_car_outlined;
      case 'home':
      case 'housing':
      case 'rent':
        return Icons.home_outlined;
      case 'local_hospital':
      case 'medical':
      case 'health':
        return Icons.local_hospital_outlined;
      case 'subscriptions':
      case 'digital':
        return Icons.subscriptions_outlined;
      default:
        return Icons.pie_chart_outline_rounded;
    }
  }

  factory BudgetCategoryModel.fromJson(Map<String, dynamic> json) {
    return BudgetCategoryModel(
      id: json['id'] as String? ?? 'bgt_${DateTime.now().millisecondsSinceEpoch}',
      categoryName: json['categoryName'] as String? ?? json['name'] as String? ?? 'General',
      budgetLimit: (json['budgetLimit'] is num)
          ? (json['budgetLimit'] as num).toDouble()
          : (double.tryParse(json['budgetLimit']?.toString() ?? '') ??
              (json['budget'] is num ? (json['budget'] as num).toDouble() : 0.0)),
      spentAmount: (json['spentAmount'] is num)
          ? (json['spentAmount'] as num).toDouble()
          : (double.tryParse(json['spentAmount']?.toString() ?? '') ??
              (json['spent'] is num ? (json['spent'] as num).toDouble() : 0.0)),
      colorHex: json['colorHex'] as String? ?? '#0066FF',
      iconName: json['iconName'] as String? ?? 'category',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryName': categoryName,
      'budgetLimit': budgetLimit,
      'spentAmount': spentAmount,
      'colorHex': colorHex,
      'iconName': iconName,
    };
  }
}
