// ENX Money — Subscription Payment Model
import 'package:intl/intl.dart';

class SubscriptionPayment {
  final String id;
  final String? userId;
  final String? planId;
  final String? planName;
  final String? orderId;
  final String? paymentId;
  final double amount;
  final String currency;
  final String status; // CREATED, AUTHORIZED, CAPTURED, FAILED, REFUNDED
  final String? paymentMethod;
  final String billingCycle;
  final double discountAmount;
  final String? couponCode;
  final DateTime createdAt;

  const SubscriptionPayment({
    required this.id,
    this.userId,
    this.planId,
    this.planName,
    this.orderId,
    this.paymentId,
    required this.amount,
    this.currency = 'INR',
    required this.status,
    this.paymentMethod,
    this.billingCycle = 'MONTHLY',
    this.discountAmount = 0.0,
    this.couponCode,
    required this.createdAt,
  });

  bool get isSuccessful => status == 'CAPTURED' || status == 'AUTHORIZED' || status == 'SUCCESS';

  String get formattedAmount {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return fmt.format(amount);
  }

  factory SubscriptionPayment.fromJson(Map<String, dynamic> json) {
    return SubscriptionPayment(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      planId: json['plan_id']?.toString(),
      planName: json['plan_name']?.toString() ?? json['plan_display_name']?.toString(),
      orderId: json['order_id']?.toString() ?? json['gateway_order_id']?.toString(),
      paymentId: json['payment_id']?.toString() ?? json['gateway_payment_id']?.toString(),
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      currency: json['currency']?.toString() ?? 'INR',
      status: (json['status']?.toString() ?? 'CREATED').toUpperCase(),
      paymentMethod: json['payment_method']?.toString() ?? json['method']?.toString(),
      billingCycle: json['billing_cycle']?.toString() ?? 'MONTHLY',
      discountAmount: (json['discount_amount'] is num)
          ? (json['discount_amount'] as num).toDouble()
          : double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0.0,
      couponCode: json['coupon_code']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'plan_id': planId,
    'order_id': orderId,
    'payment_id': paymentId,
    'amount': amount,
    'currency': currency,
    'status': status,
    'payment_method': paymentMethod,
    'billing_cycle': billingCycle,
    'discount_amount': discountAmount,
    'coupon_code': couponCode,
    'created_at': createdAt.toIso8601String(),
  };
}
