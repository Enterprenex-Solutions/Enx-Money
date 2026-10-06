// ENX Money — Subscription Model
import 'plan_model.dart';

class SubscriptionModel {
  final String? id;
  final String userId;
  final String planId;
  final String status; // TRIALING, ACTIVE, PAST_DUE, PAUSED, CANCELLED, EXPIRED
  final String billingCycle; // MONTHLY, YEARLY
  final DateTime? startDate;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? trialEnd;
  final bool cancelAtPeriodEnd;
  final bool autoRenew;
  final PlanModel? plan;

  const SubscriptionModel({
    this.id,
    required this.userId,
    required this.planId,
    required this.status,
    required this.billingCycle,
    this.startDate,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.trialEnd,
    this.cancelAtPeriodEnd = false,
    this.autoRenew = true,
    this.plan,
  });

  bool get isActive => status == 'ACTIVE' || status == 'TRIALING';
  bool get isTrialing => status == 'TRIALING';
  bool get isCancelled => status == 'CANCELLED' || status == 'EXPIRED';
  bool get isPastDue => status == 'PAST_DUE';
  bool get isFree => plan?.isFree == true || planId == 'plan-free';

  String get planName => plan?.displayName ?? planId;
  String get statusLabel {
    switch (status) {
      case 'ACTIVE': return 'Active';
      case 'TRIALING': return 'Trial';
      case 'PAST_DUE': return 'Payment Due';
      case 'PAUSED': return 'Paused';
      case 'CANCELLED': return cancelAtPeriodEnd ? 'Cancelling' : 'Cancelled';
      case 'EXPIRED': return 'Expired';
      default: return status;
    }
  }

  factory SubscriptionModel.free() {
    return const SubscriptionModel(
      id: null,
      userId: '',
      planId: 'plan-free',
      status: 'ACTIVE',
      billingCycle: 'MONTHLY',
      cancelAtPeriodEnd: false,
      autoRenew: true,
    );
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String? ?? '',
      planId: json['plan_id'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      billingCycle: json['billing_cycle'] as String? ?? 'MONTHLY',
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date'].toString()) : null,
      currentPeriodStart: json['current_period_start'] != null ? DateTime.tryParse(json['current_period_start'].toString()) : null,
      currentPeriodEnd: json['current_period_end'] != null ? DateTime.tryParse(json['current_period_end'].toString()) : null,
      trialEnd: json['trial_end'] != null ? DateTime.tryParse(json['trial_end'].toString()) : null,
      cancelAtPeriodEnd: json['cancel_at_period_end'] == true || json['cancel_at_period_end'] == 1,
      autoRenew: json['auto_renew'] != false,
      plan: json['plan'] != null ? PlanModel.fromJson(json['plan'] as Map<String, dynamic>) : null,
    );
  }
}

class SettlementDestination {
  final String beneficiaryName;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String urnNumber;
  final String? gstin;
  final String merchantName;

  const SettlementDestination({
    this.beneficiaryName = 'ENX Money',
    this.bankName = 'ENX Money Secure Gateway',
    this.accountNumber = '',
    this.ifscCode = '',
    this.urnNumber = '',
    this.gstin = '27AARCP9260R1Z2',
    this.merchantName = 'ENX Money',
  });

  factory SettlementDestination.fromJson(Map<String, dynamic>? json) {
    return SettlementDestination(
      beneficiaryName: json?['merchant_name']?.toString() ?? json?['beneficiary_name']?.toString() ?? 'ENX Money',
      bankName: json?['bank_name']?.toString() ?? 'ENX Money Secure Gateway',
      accountNumber: json?['account_number']?.toString() ?? '',
      ifscCode: json?['ifsc_code']?.toString() ?? '',
      urnNumber: json?['urn_number']?.toString() ?? '',
      gstin: json?['gstin']?.toString() ?? '27AARCP9260R1Z2',
      merchantName: json?['merchant_name']?.toString() ?? 'ENX Money',
    );
  }
}

class CheckoutData {
  final String orderId;
  final int amountInPaise;
  final String currency;
  final String planName;
  final String billingCycle;
  final double originalAmount;
  final double discountAmount;
  final double finalAmount;
  final double? baseAmount;
  final double? gstAmount;
  final double? totalAmount;
  final String razorpayKey;
  final bool simulated;
  final String upiIntentUrl;
  final String upiQrData;
  final String paymentLink;
  final String upiVpa;
  final SettlementDestination settlementDestination;

  double get displayTotalAmount => totalAmount ?? finalAmount;
  double get displayBaseAmount => baseAmount ?? originalAmount;
  double get displayGstAmount => gstAmount ?? (displayTotalAmount - (displayBaseAmount - discountAmount)).clamp(0, double.infinity);

  const CheckoutData({
    required this.orderId,
    required this.amountInPaise,
    required this.currency,
    required this.planName,
    required this.billingCycle,
    required this.originalAmount,
    required this.discountAmount,
    required this.finalAmount,
    this.baseAmount,
    this.gstAmount,
    this.totalAmount,
    required this.razorpayKey,
    this.simulated = false,
    this.upiIntentUrl = '',
    this.upiQrData = '',
    this.paymentLink = '',
    this.upiVpa = '',
    this.settlementDestination = const SettlementDestination(
      beneficiaryName: 'ENX Money',
      bankName: 'ENX Money Secure Gateway',
      accountNumber: '',
      ifscCode: '',
      urnNumber: '',
      gstin: '27AARCP9260R1Z2',
      merchantName: 'ENX Money',
    ),
  });

  factory CheckoutData.fromJson(Map<String, dynamic> json) {
    return CheckoutData(
      orderId: json['order_id'] as String? ?? json['id'] as String? ?? '',
      amountInPaise: json['amount'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      planName: json['plan_name'] as String? ?? '',
      billingCycle: json['billing_cycle'] as String? ?? 'MONTHLY',
      originalAmount: (json['original_amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      finalAmount: (json['final_amount'] as num?)?.toDouble() ?? 0,
      baseAmount: (json['base_amount'] as num?)?.toDouble(),
      gstAmount: (json['gst_amount'] as num?)?.toDouble(),
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      razorpayKey: json['razorpay_key'] as String? ?? json['key_id'] as String? ?? '',
      simulated: json['_simulated'] == true,
      upiIntentUrl: json['upi_intent_url'] as String? ?? '',
      upiQrData: json['upi_qr_data'] as String? ?? '',
      paymentLink: json['payment_link'] as String? ?? json['merchant_upi_link'] as String? ?? '',
      upiVpa: json['upi_vpa'] as String? ?? '',
      settlementDestination: SettlementDestination.fromJson(
        json['settlement_destination'] as Map<String, dynamic>?,
      ),
    );
  }
}

