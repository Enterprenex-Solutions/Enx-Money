enum TransactionType { debit, credit }

enum TransactionCategory {
  shopping,
  food,
  entertainment,
  travel,
  investment,
  salary,
  utilities,
  transfer,
}

class TransactionItem {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final DateTime dateTime;
  final String? paymentMethod;
  final String? cashbackEarned;
  final String status;

  const TransactionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.type,
    required this.category,
    required this.dateTime,
    this.paymentMethod,
    this.cashbackEarned,
    this.status = 'COMPLETED',
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] as String? ?? 'DEBIT').toUpperCase();
    final isCredit = typeStr == 'CREDIT';
    final rawCategory = (json['category'] as String? ?? 'other').toLowerCase();
    
    TransactionCategory cat = TransactionCategory.shopping;
    if (rawCategory.contains('food') || rawCategory.contains('restaurant')) {
      cat = TransactionCategory.food;
    } else if (rawCategory.contains('travel') || rawCategory.contains('fuel')) {
      cat = TransactionCategory.travel;
    } else if (rawCategory.contains('entertain') || rawCategory.contains('movie')) {
      cat = TransactionCategory.entertainment;
    } else if (rawCategory.contains('invest') || rawCategory.contains('stock') || rawCategory.contains('mutual')) {
      cat = TransactionCategory.investment;
    } else if (rawCategory.contains('salary') || rawCategory.contains('sales') || rawCategory.contains('income')) {
      cat = TransactionCategory.salary;
    } else if (rawCategory.contains('utilit') || rawCategory.contains('bill') || rawCategory.contains('rent')) {
      cat = TransactionCategory.utilities;
    } else if (rawCategory.contains('transfer')) {
      cat = TransactionCategory.transfer;
    }

    DateTime parsedDate;
    try {
      parsedDate = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : (json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now());
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final double amt = (json['amount'] is num)
        ? (json['amount'] as num).toDouble()
        : (double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0);

    return TransactionItem(
      id: json['id']?.toString() ?? 'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: json['note'] as String? ?? json['title'] as String? ?? json['category'] as String? ?? 'Transaction',
      subtitle: json['accountName'] as String? ?? json['referenceId'] as String? ?? json['subtitle'] as String? ?? '',
      amount: amt,
      type: isCredit ? TransactionType.credit : TransactionType.debit,
      category: cat,
      dateTime: parsedDate,
      paymentMethod: json['paymentMode'] as String? ?? json['paymentMethod'] as String?,
      status: json['status'] as String? ?? 'COMPLETED',
    );
  }
}
