import 'package:flutter/material.dart';

class NetWorthSummary {
  final double totalNetWorth;
  final double totalInvestments;
  final double bankBalances;
  final double totalCreditDue;
  final double monthOverMonthChange;
  final int creditScore;

  const NetWorthSummary({
    required this.totalNetWorth,
    required this.totalInvestments,
    required this.bankBalances,
    required this.totalCreditDue,
    required this.monthOverMonthChange,
    required this.creditScore,
  });
}

class SmartBillAlert {
  final String id;
  final String providerName;
  final String category;
  final double amount;
  final String dueDate;
  final bool isUrgent;
  final String cardLast4;

  const SmartBillAlert({
    required this.id,
    required this.providerName,
    required this.category,
    required this.amount,
    required this.dueDate,
    this.isUrgent = false,
    required this.cardLast4,
  });
}

class DashboardQuickAction {
  final String id;
  final String title;
  final IconData icon;
  final Color? color;

  const DashboardQuickAction({
    required this.id,
    required this.title,
    required this.icon,
    this.color,
  });
}
