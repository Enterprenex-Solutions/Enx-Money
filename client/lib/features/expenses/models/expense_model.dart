import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ExpenseItem {
  final String id;
  final dynamic userId;
  final String accountType;
  final String type;
  final String category;
  final double amount;
  final String? accountId;
  final String? accountName;
  final String paymentMode;
  final String date;
  final String note;
  final String status;
  final String? supplierId;
  final String? supplierName;
  final double? gstRate;
  final String? gstin;
  final double? taxableAmount;
  final double? cgst;
  final double? sgst;
  final double? igst;
  final double? totalGst;
  final String? invoiceNumber;
  final String? receiptUrl;
  final String? createdAt;

  const ExpenseItem({
    required this.id,
    this.userId,
    this.accountType = 'BUSINESS',
    this.type = 'DEBIT',
    required this.category,
    required this.amount,
    this.accountId,
    this.accountName,
    this.paymentMode = 'BANK_TRANSFER',
    required this.date,
    required this.note,
    this.status = 'PAID',
    this.supplierId,
    this.supplierName,
    this.gstRate,
    this.gstin,
    this.taxableAmount,
    this.cgst,
    this.sgst,
    this.igst,
    this.totalGst,
    this.invoiceNumber,
    this.receiptUrl,
    this.createdAt,
  });

  String get displayTitle => note.isNotEmpty ? note : '$category Expense';

  bool get isPaid => status.toUpperCase() == 'PAID';
  bool get isPending => status.toUpperCase() == 'PENDING' || status.toUpperCase() == 'UNPAID';

  IconData get categoryIcon {
    final cat = category.toLowerCase();
    if (cat.contains('rent') || cat.contains('facility')) return Icons.apartment_rounded;
    if (cat.contains('salar') || cat.contains('wage')) return Icons.badge_rounded;
    if (cat.contains('utilit') || cat.contains('bill') || cat.contains('electric')) return Icons.bolt_rounded;
    if (cat.contains('material') || cat.contains('inventory')) return Icons.inventory_2_rounded;
    if (cat.contains('vendor') || cat.contains('supplier')) return Icons.storefront_rounded;
    if (cat.contains('logistic') || cat.contains('shipping') || cat.contains('transport')) return Icons.local_shipping_rounded;
    if (cat.contains('market') || cat.contains('advert')) return Icons.campaign_rounded;
    if (cat.contains('suppl') || cat.contains('equip')) return Icons.print_rounded;
    if (cat.contains('legal') || cat.contains('profess')) return Icons.gavel_rounded;
    if (cat.contains('repair') || cat.contains('maint')) return Icons.build_rounded;
    if (cat.contains('travel') || cat.contains('fuel')) return Icons.directions_car_rounded;
    if (cat.contains('tax') || cat.contains('gst')) return Icons.receipt_long_rounded;
    if (cat.contains('soft') || cat.contains('tech') || cat.contains('sub')) return Icons.cloud_outlined;
    if (cat.contains('insur')) return Icons.security_rounded;
    return Icons.payments_rounded;
  }

  Color get categoryColor {
    final cat = category.toLowerCase();
    if (cat.contains('rent')) return const Color(0xFF6366F1);
    if (cat.contains('salar')) return const Color(0xFF10B981);
    if (cat.contains('utilit')) return const Color(0xFFF59E0B);
    if (cat.contains('material') || cat.contains('inventory')) return const Color(0xFF3B82F6);
    if (cat.contains('vendor') || cat.contains('supplier')) return const Color(0xFFEC4899);
    if (cat.contains('soft') || cat.contains('tech')) return const Color(0xFF8B5CF6);
    if (cat.contains('tax')) return const Color(0xFFEF4444);
    if (cat.contains('travel')) return const Color(0xFF14B8A6);
    return AppColors.brandBlue;
  }

  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    return ExpenseItem(
      id: json['id']?.toString() ?? '',
      userId: json['userId'],
      accountType: json['accountType']?.toString() ?? 'BUSINESS',
      type: json['type']?.toString() ?? 'DEBIT',
      category: json['category']?.toString() ?? 'Miscellaneous',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      accountId: json['accountId']?.toString(),
      accountName: json['accountName']?.toString(),
      paymentMode: json['paymentMode']?.toString() ?? 'BANK_TRANSFER',
      date: json['date']?.toString() ?? DateTime.now().toIso8601String(),
      note: (json['note']?.toString() ?? json['title']?.toString() ?? '').trim(),
      status: json['status']?.toString() ?? 'PAID',
      supplierId: json['supplierId']?.toString(),
      supplierName: json['supplierName']?.toString(),
      gstRate: json['gstRate'] != null ? (json['gstRate'] as num).toDouble() : null,
      gstin: json['gstin']?.toString(),
      taxableAmount: json['taxableAmount'] != null ? (json['taxableAmount'] as num).toDouble() : null,
      cgst: json['cgst'] != null ? (json['cgst'] as num).toDouble() : null,
      sgst: json['sgst'] != null ? (json['sgst'] as num).toDouble() : null,
      igst: json['igst'] != null ? (json['igst'] as num).toDouble() : null,
      totalGst: json['totalGst'] != null ? (json['totalGst'] as num).toDouble() : null,
      invoiceNumber: json['invoiceNumber']?.toString(),
      receiptUrl: json['receiptUrl']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'accountType': accountType,
      'type': type,
      'category': category,
      'amount': amount,
      'accountId': accountId,
      'accountName': accountName,
      'paymentMode': paymentMode,
      'date': date,
      'note': note,
      'status': status,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'gstRate': gstRate,
      'gstin': gstin,
      'taxableAmount': taxableAmount,
      'cgst': cgst,
      'sgst': sgst,
      'igst': igst,
      'totalGst': totalGst,
      'invoiceNumber': invoiceNumber,
      'receiptUrl': receiptUrl,
      'createdAt': createdAt,
    };
  }
}

class ExpenseSummary {
  final double totalExpenses;
  final double thisMonthExpenses;
  final double todayExpenses;
  final double pendingExpenses;
  final int expenseCount;
  final String currency;

  const ExpenseSummary({
    this.totalExpenses = 0.0,
    this.thisMonthExpenses = 0.0,
    this.todayExpenses = 0.0,
    this.pendingExpenses = 0.0,
    this.expenseCount = 0,
    this.currency = 'INR',
  });

  factory ExpenseSummary.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val) {
      if (val is num) return val.toDouble();
      return double.tryParse(val?.toString() ?? '0') ?? 0.0;
    }

    return ExpenseSummary(
      totalExpenses: parseNum(json['totalExpenses'] ?? json['totalExpense']),
      thisMonthExpenses: parseNum(json['thisMonthExpenses'] ?? json['thisMonthExpense']),
      todayExpenses: parseNum(json['todayExpenses'] ?? json['todayExpense']),
      pendingExpenses: parseNum(json['pendingExpenses'] ?? json['pendingExpense']),
      expenseCount: (json['expenseCount'] ?? json['count'] ?? 0) is num
          ? (json['expenseCount'] ?? json['count'] ?? 0).toInt()
          : int.tryParse(json['expenseCount']?.toString() ?? '0') ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
    );
  }
}
