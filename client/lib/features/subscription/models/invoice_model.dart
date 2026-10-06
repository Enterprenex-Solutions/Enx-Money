// ENX Money — Subscription Invoice Model
class SubscriptionInvoice {
  final String id;
  final String invoiceNumber;
  final String planName;
  final String billingCycle;
  final double subtotal;
  final double discount;
  final double taxRate;
  final double taxAmount;
  final double total;
  final String currency;
  final String status;
  final DateTime invoiceDate;
  final String? pdfUrl;

  const SubscriptionInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.planName,
    required this.billingCycle,
    required this.subtotal,
    required this.discount,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
    required this.currency,
    required this.status,
    required this.invoiceDate,
    this.pdfUrl,
  });

  String get formattedTotal => '₹${total.toStringAsFixed(2)}';

  factory SubscriptionInvoice.fromJson(Map<String, dynamic> json) {
    return SubscriptionInvoice(
      id: json['id'] as String? ?? '',
      invoiceNumber: json['invoice_number'] as String? ?? '',
      planName: json['plan_name'] as String? ?? '',
      billingCycle: json['billing_cycle'] as String? ?? 'MONTHLY',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 18,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      status: json['status'] as String? ?? 'PAID',
      invoiceDate: json['invoice_date'] != null
          ? DateTime.tryParse(json['invoice_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      pdfUrl: json['pdf_url'] as String?,
    );
  }
}
