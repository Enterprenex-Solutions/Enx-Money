import 'enums.dart';

class TransactionItem {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final ProfileType profileType;
  final String category;
  final DateTime date;
  final PaymentMode paymentMode;
  final String? notes;
  final double gstRate; // e.g. 18.0 for 18% GST
  final String? invoiceNumber;
  final bool isCleared;
  final String? enterpriseId;
  final String? customerId;
  final String? supplierId;

  const TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.profileType,
    required this.category,
    required this.date,
    required this.paymentMode,
    this.notes,
    this.gstRate = 0.0,
    this.invoiceNumber,
    this.isCleared = true,
    this.enterpriseId,
    this.customerId,
    this.supplierId,
  });

  double get gstAmount => (amount * gstRate) / 100.0;
  double get totalWithGst => amount + gstAmount;

  TransactionItem copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    ProfileType? profileType,
    String? category,
    DateTime? date,
    PaymentMode? paymentMode,
    String? notes,
    double? gstRate,
    String? invoiceNumber,
    bool? isCleared,
    String? enterpriseId,
    String? customerId,
    String? supplierId,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      profileType: profileType ?? this.profileType,
      category: category ?? this.category,
      date: date ?? this.date,
      paymentMode: paymentMode ?? this.paymentMode,
      notes: notes ?? this.notes,
      gstRate: gstRate ?? this.gstRate,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      isCleared: isCleared ?? this.isCleared,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      customerId: customerId ?? this.customerId,
      supplierId: supplierId ?? this.supplierId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'profileType': profileType.name,
      'category': category,
      'date': date.toIso8601String(),
      'paymentMode': paymentMode.name,
      'notes': notes,
      'gstRate': gstRate,
      'invoiceNumber': invoiceNumber,
      'isCleared': isCleared,
      'enterpriseId': enterpriseId,
      'customerId': customerId,
      'supplierId': supplierId,
    };
  }

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere((e) => e.name == json['type']),
      profileType: ProfileType.values.firstWhere((e) => e.name == json['profileType']),
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      paymentMode: PaymentMode.values.firstWhere((e) => e.name == json['paymentMode']),
      notes: json['notes'] as String?,
      gstRate: (json['gstRate'] as num?)?.toDouble() ?? 0.0,
      invoiceNumber: json['invoiceNumber'] as String?,
      isCleared: json['isCleared'] as bool? ?? true,
      enterpriseId: json['enterpriseId'] as String?,
      customerId: json['customerId'] as String?,
      supplierId: json['supplierId'] as String?,
    );
  }
}
