class LedgerEntryModel {
  final String id;
  final String customerId;
  final String entryType; // 'GAVE' (Udhaar), 'GOT' (Jama)
  final double amount;
  final double balanceAfter;
  final String paymentMode; // 'CASH', 'UPI', 'BANK_TRANSFER', 'CHEQUE', 'CREDIT'
  final String invoiceNumber;
  final String description;
  final String entryDate;
  final DateTime? createdAt;

  const LedgerEntryModel({
    required this.id,
    required this.customerId,
    required this.entryType,
    required this.amount,
    required this.balanceAfter,
    this.paymentMode = 'CASH',
    this.invoiceNumber = '',
    this.description = '',
    required this.entryDate,
    this.createdAt,
  });

  bool get isGave => entryType == 'GAVE';
  bool get isGot => entryType == 'GOT';

  factory LedgerEntryModel.fromJson(Map<String, dynamic> json) {
    return LedgerEntryModel(
      id: json['id'] ?? '',
      customerId: json['customerId'] ?? json['customer_id'] ?? '',
      entryType: json['entryType'] ?? json['entry_type'] ?? 'GAVE',
      amount: (json['amount'] ?? 0.0).toDouble(),
      balanceAfter: (json['balanceAfter'] ?? json['balance_after'] ?? 0.0).toDouble(),
      paymentMode: json['paymentMode'] ?? json['payment_mode'] ?? 'CASH',
      invoiceNumber: json['invoiceNumber'] ?? json['invoice_number'] ?? '',
      description: json['description'] ?? '',
      entryDate: json['entryDate'] ?? json['entry_date'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entryType': entryType,
      'amount': amount,
      'paymentMode': paymentMode,
      'invoiceNumber': invoiceNumber,
      'description': description,
      'entryDate': entryDate,
    };
  }
}
