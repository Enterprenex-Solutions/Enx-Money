import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../../../core/network/api_client.dart';
import '../models/plan_model.dart';
import '../models/subscription_model.dart';
import '../models/invoice_model.dart';

class SubscriptionRepository {
  static final SubscriptionRepository _instance = SubscriptionRepository._internal();
  factory SubscriptionRepository() => _instance;
  SubscriptionRepository._internal();

  final ApiClient _api = ApiClient();

  SubscriptionModel? _cachedSubscription;
  List<PlanModel>? _cachedPlans;
  Map<String, Map<String, dynamic>>? _cachedEntitlements;

  SubscriptionModel? get cachedSubscription => _cachedSubscription;

  // ── Plans ──────────────────────────────────────────────────────────────────
  Future<List<PlanModel>> getPlans({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedPlans != null) return _cachedPlans!;
    try {
      final response = await _api.get('/api/v1/subscription/plans');
      if (response['success'] == true && response['data'] != null) {
        final list = (response['data'] as List<dynamic>)
            .map((p) => PlanModel.fromJson(p as Map<String, dynamic>))
            .toList();
        _cachedPlans = list;
        return list;
      }
    } catch (e) {
      debugPrint('[SubscriptionRepo] getPlans error: $e');
    }
    _cachedPlans ??= PlanModel.defaultPlans;
    if (_cachedPlans!.isEmpty) _cachedPlans = PlanModel.defaultPlans;
    return _cachedPlans!;
  }

  // ── Current Subscription ───────────────────────────────────────────────────
  Future<SubscriptionModel> getCurrentSubscription({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedSubscription != null) return _cachedSubscription!;
    try {
      final response = await _api.get('/api/v1/subscription');
      if (response['success'] == true && response['data'] != null) {
        _cachedSubscription = SubscriptionModel.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        return _cachedSubscription!;
      }
    } catch (e) {
      debugPrint('[SubscriptionRepo] getCurrentSubscription error: $e');
    }

    // Check locally persisted active subscription from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final localPlanId = prefs.getString('enx_active_sub_plan_id');
      final localStatus = prefs.getString('enx_active_sub_status');
      if (localPlanId != null && localStatus == 'ACTIVE') {
        final plan = PlanModel.defaultPlans.firstWhere(
          (p) => p.id.toLowerCase() == localPlanId.toLowerCase() || p.name.toUpperCase() == localPlanId.toUpperCase(),
          orElse: () => PlanModel.defaultPlans[2], // Default Pro
        );
        final cycle = prefs.getString('enx_active_sub_billing_cycle') ?? 'MONTHLY';
        _cachedSubscription = SubscriptionModel(
          id: 'sub_enx_${DateTime.now().millisecondsSinceEpoch}',
          userId: 'usr_active',
          planId: plan.id,
          status: 'ACTIVE',
          billingCycle: cycle,
          startDate: DateTime.now(),
          currentPeriodStart: DateTime.now(),
          currentPeriodEnd: DateTime.now().add(const Duration(days: 30)),
          plan: plan,
        );
        return _cachedSubscription!;
      }
    } catch (e) {
      debugPrint('[SubscriptionRepo] Local storage subscription lookup error: $e');
    }

    _cachedSubscription ??= SubscriptionModel.free();
    return _cachedSubscription!;
  }

  // ── Checkout / Order Creation (Payment Gateway) ───────────────────────────
  Future<CheckoutData?> checkout({
    required String planId,
    required String billingCycle,
    String? couponCode,
  }) async {
    return createPaymentOrder(
      planId: planId,
      billingCycle: billingCycle,
      couponCode: couponCode,
    );
  }

  Future<CheckoutData?> createPaymentOrder({
    required String planId,
    required String billingCycle,
    String? couponCode,
  }) async {
    // 1. Primary endpoint: POST /api/v1/subscription/create-order
    try {
      final response = await _api.post('/api/v1/subscription/create-order', body: {
        'plan_id': planId,
        'billing_cycle': billingCycle,
        if (couponCode != null && couponCode.isNotEmpty) 'coupon_code': couponCode,
      });
      if (response['success'] == true && response['data'] != null) {
        return CheckoutData.fromJson(response['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[SubscriptionRepo] createPaymentOrder (/subscription/create-order) error: $e');
    }

    // 2. Try fallback to /subscription/checkout
    try {
      final response = await _api.post('/api/v1/subscription/checkout', body: {
        'plan_id': planId,
        'billing_cycle': billingCycle,
        if (couponCode != null && couponCode.isNotEmpty) 'coupon_code': couponCode,
      });
      if (response['success'] == true && response['data'] != null) {
        return CheckoutData.fromJson(response['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[SubscriptionRepo] checkout fallback error: $e');
    }

    // 3. Direct Authentic Razorpay Order Creation via Razorpay API
    final plan = PlanModel.defaultPlans.firstWhere(
      (p) => p.id.toLowerCase() == planId.toLowerCase() || p.name.toUpperCase() == planId.toUpperCase(),
      orElse: () => PlanModel.defaultPlans[1],
    );
    final basePrice = billingCycle == 'YEARLY' ? plan.priceYearly : plan.priceMonthly;
    final taxable = basePrice.clamp(0.0, double.infinity);
    final gst = double.parse((taxable * 0.18).toStringAsFixed(2));
    final total = double.parse((taxable + gst).toStringAsFixed(2));
    final amountPaise = (total * 100).round();

    String genuineOrderId = '';
    const razorpayKeyId = 'rzp_live_ThjlhbHvQ4iaQV';
    const razorpaySecret = 'obTkTnLgWoM2bkq35zhUY7Og';

    try {
      final authStr = base64Encode(utf8.encode('$razorpayKeyId:$razorpaySecret'));
      final rzpResponse = await http.post(
        Uri.parse('https://api.razorpay.com/v1/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $authStr',
        },
        body: jsonEncode({
          'amount': amountPaise,
          'currency': 'INR',
          'receipt': 'rcpt_${DateTime.now().millisecondsSinceEpoch}',
          'notes': {
            'plan_id': planId,
            'plan_name': plan.displayName,
            'billing_cycle': billingCycle,
            'merchant': 'ENX Money',
          },
        }),
      );

      if (rzpResponse.statusCode == 200 || rzpResponse.statusCode == 201) {
        final rzpBody = jsonDecode(rzpResponse.body) as Map<String, dynamic>;
        genuineOrderId = rzpBody['id'] as String? ?? '';
        debugPrint('[SubscriptionRepo] Real Razorpay Order created directly: $genuineOrderId');
      } else {
        debugPrint('[SubscriptionRepo] Razorpay API error (${rzpResponse.statusCode}): ${rzpResponse.body}');
      }
    } catch (e) {
      debugPrint('[SubscriptionRepo] Razorpay direct order creation error: $e');
    }

    return CheckoutData(
      orderId: genuineOrderId,
      amountInPaise: amountPaise,
      currency: 'INR',
      planName: plan.displayName,
      billingCycle: billingCycle,
      originalAmount: basePrice,
      discountAmount: 0,
      finalAmount: total,
      baseAmount: basePrice,
      gstAmount: gst,
      totalAmount: total,
      razorpayKey: razorpayKeyId,
      settlementDestination: const SettlementDestination(
        beneficiaryName: 'ENX Money',
        bankName: 'ENX Money Secure Gateway',
        accountNumber: '',
        ifscCode: '',
        urnNumber: '',
        gstin: '27AARCP9260R1Z2',
        merchantName: 'ENX Money',
      ),
    );
  }

  // ── Verify Payment ─────────────────────────────────────────────────────────
  Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required String planId,
    required String billingCycle,
  }) async {
    final result = await verifyPaymentWithDetails(
      orderId: orderId,
      paymentId: paymentId,
      signature: signature,
      planId: planId,
      billingCycle: billingCycle,
    );
    return result != null;
  }

  Future<Map<String, dynamic>?> verifyPaymentWithDetails({
    required String orderId,
    required String paymentId,
    required String signature,
    required String planId,
    required String billingCycle,
    String? method,
  }) async {
    // 1. Primary: POST /api/v1/subscription/verify (strict server-side signature verification)
    try {
      final response = await _api.post('/api/v1/subscription/verify', body: {
        'order_id': orderId,
        'payment_id': paymentId,
        'signature': signature,
        'plan_id': planId,
        'billing_cycle': billingCycle,
        if (method != null) 'method': method,
      });
      if (response['success'] == true && response['data'] != null && (response['data']['verified'] == true || response['data']['status'] == 'SUCCESS')) {
        final data = response['data'] as Map<String, dynamic>;
        await _persistActiveSubscription(
          planId: planId,
          billingCycle: billingCycle,
          paymentId: paymentId,
          orderId: orderId,
          method: method,
        );
        return data;
      }
    } catch (e) {
      debugPrint('[SubscriptionRepo] verifyPaymentWithDetails (/subscription/verify) error: $e');
    }

    // 2. Secondary: POST /api/v1/payment/verify
    try {
      final response = await _api.post('/api/v1/payment/verify', body: {
        'order_id': orderId,
        'payment_id': paymentId,
        'signature': signature,
        'razorpay_signature': signature,
        'plan_id': planId,
        'billing_cycle': billingCycle,
        if (method != null) 'method': method,
      });
      if (response['success'] == true && (response['verified'] == true || response['status'] == 'PAID' || response['data']?['verified'] == true)) {
        final data = (response['data'] as Map<String, dynamic>?) ?? response;
        await _persistActiveSubscription(
          planId: planId,
          billingCycle: billingCycle,
          paymentId: paymentId,
          orderId: orderId,
          method: method,
        );
        return data;
      }
    } catch (e) {
      debugPrint('[SubscriptionRepo] verifyPaymentWithDetails (/payment/verify) error: $e');
    }

    // 3. Fallback: Authenticated Direct HMAC-SHA256 Verification with active secret
    // ONLY if orderId, paymentId and signature are ALL provided and cryptographically valid!
    // NEVER activate on unverified paymentId alone.
    bool isCryptographicallyValid = false;
    const activeSecret = 'XI8094mTE5f4DzOmCJpw23oL';

    if (orderId.isNotEmpty && paymentId.isNotEmpty && signature.isNotEmpty) {
      final hmac = Hmac(sha256, utf8.encode(activeSecret));
      final generatedDigest = hmac.convert(utf8.encode('$orderId|$paymentId')).toString();
      isCryptographicallyValid = generatedDigest.toLowerCase() == signature.toLowerCase();
      debugPrint('[SubscriptionRepo] Strict local HMAC check: $isCryptographicallyValid');
    }

    if (isCryptographicallyValid) {
      await _persistActiveSubscription(
        planId: planId,
        billingCycle: billingCycle,
        paymentId: paymentId,
        orderId: orderId,
        method: method,
      );

      final plan = PlanModel.defaultPlans.firstWhere(
        (p) => p.id.toLowerCase() == planId.toLowerCase() || p.name.toUpperCase() == planId.toUpperCase(),
        orElse: () => PlanModel.defaultPlans[1],
      );
      final total = billingCycle == 'YEARLY' ? plan.priceYearly * 1.18 : plan.priceMonthly * 1.18;
      final receiptSuffix = paymentId.replaceAll('pay_', '').length >= 6
          ? paymentId.replaceAll('pay_', '').substring(0, 6).toUpperCase()
          : '${DateTime.now().millisecondsSinceEpoch % 100000}';

      return {
        'verified': true,
        'status': 'SUCCESS',
        'receipt_id': 'ENXI-${DateTime.now().year}-$receiptSuffix',
        'receiptId': 'ENXI-${DateTime.now().year}-$receiptSuffix',
        'order_id': orderId,
        'payment_id': paymentId,
        'plan_id': planId,
        'billing_cycle': billingCycle,
        'total_amount': total,
        'invoice': {
          'invoiceNumber': 'INV-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}',
          'merchantName': 'ENX Money',
          'planName': plan.displayName,
          'billingCycle': billingCycle,
          'totalAmount': total,
          'paymentMethod': method ?? 'Razorpay Gateway',
          'paymentId': paymentId,
          'gstNumber': '27AARCP9260R1Z2',
          'date': DateTime.now().toIso8601String(),
        },
      };
    }

    // Server verification failed or cryptographic mismatch - strictly do NOT activate plan
    debugPrint('[SubscriptionRepo] Payment signature verification failed. Plan state remains unchanged.');
    return null;
  }

  Future<void> _persistActiveSubscription({
    required String planId,
    required String billingCycle,
    required String paymentId,
    required String orderId,
    String? method,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('enx_active_sub_plan_id', planId);
    await prefs.setString('enx_active_sub_billing_cycle', billingCycle);
    await prefs.setString('enx_active_sub_status', 'ACTIVE');
    await prefs.setString('enx_active_sub_payment_id', paymentId);
    await prefs.setString('enx_active_sub_order_id', orderId);
    await prefs.setInt('enx_active_sub_activated_at', DateTime.now().millisecondsSinceEpoch);

    final plan = PlanModel.defaultPlans.firstWhere(
      (p) => p.id.toLowerCase() == planId.toLowerCase() || p.name.toUpperCase() == planId.toUpperCase(),
      orElse: () => PlanModel.defaultPlans[1],
    );
    final total = billingCycle == 'YEARLY' ? plan.priceYearly * 1.18 : plan.priceMonthly * 1.18;

    try {
      final rawHistory = prefs.getString('enx_payment_history') ?? '[]';
      final List<dynamic> history = jsonDecode(rawHistory) as List<dynamic>;
      history.insert(0, {
        'id': paymentId,
        'order_id': orderId,
        'amount': total,
        'currency': 'INR',
        'status': 'captured',
        'method': method ?? 'Razorpay Gateway',
        'merchant_name': 'ENX Money',
        'plan_id': planId,
        'billing_cycle': billingCycle,
        'created_at': DateTime.now().toIso8601String(),
      });
      await prefs.setString('enx_payment_history', jsonEncode(history));
    } catch (e) {
      debugPrint('[SubscriptionRepo] Record local payment history error: $e');
    }

    _cachedSubscription = null;
    _cachedEntitlements = null;
  }

  // ── Payment History ────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getPayments() async {
    List<Map<String, dynamic>> remoteList = [];
    try {
      final response = await _api.get('/api/v1/subscription/payments');
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        if (data is Map && data['payments'] is List) {
          remoteList = List<Map<String, dynamic>>.from(data['payments'] as List);
        }
      }
    } catch (e) {
      debugPrint('[SubscriptionRepo] getPayments error: $e');
    }

    // Also include locally recorded payments
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('enx_payment_history');
      if (raw != null && raw.isNotEmpty) {
        final localList = List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
        final seenIds = remoteList.map((p) => p['id']?.toString() ?? '').toSet();
        for (final p in localList) {
          final id = p['id']?.toString() ?? '';
          if (!seenIds.contains(id)) {
            remoteList.add(p);
          }
        }
      }
    } catch (e) {
      debugPrint('[SubscriptionRepo] merge local payment history error: $e');
    }

    return remoteList;
  }

  // ── Trigger Webhook Activation ─────────────────────────────────────────────
  Future<Map<String, dynamic>?> triggerWebhookActivation({
    required String orderId,
    required String paymentId,
    required String planId,
    required String billingCycle,
    String method = 'upi',
    String? billingName,
    String? billingEmail,
  }) async {
    try {
      final response = await _api.post('/api/v1/subscription/webhook', body: {
        'event': 'payment.captured',
        'order_id': orderId,
        'payment_id': paymentId,
        'method': method,
        'plan_id': planId,
        'billing_cycle': billingCycle,
        if (billingName != null) 'billing_name': billingName,
        if (billingEmail != null) 'billing_email': billingEmail,
      });
      if (response['success'] == true) {
        _cachedSubscription = null;
        _cachedEntitlements = null;
        return response['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('[SubscriptionRepo] triggerWebhookActivation error: $e');
    }
    return null;
  }

  // ── Cancel ─────────────────────────────────────────────────────────────────
  Future<bool> cancelSubscription() async {
    try {
      final response = await _api.post('/api/v1/subscription/cancel', body: {});
      if (response['success'] == true) {
        _cachedSubscription = null;
        return true;
      }
    } catch (e) {
      debugPrint('[SubscriptionRepo] cancel error: $e');
    }
    return false;
  }

  // ── Reactivate ─────────────────────────────────────────────────────────────
  Future<bool> reactivateSubscription() async {
    try {
      final response = await _api.post('/api/v1/subscription/reactivate', body: {});
      if (response['success'] == true) {
        _cachedSubscription = null;
        return true;
      }
    } catch (e) {
      debugPrint('[SubscriptionRepo] reactivate error: $e');
    }
    return false;
  }

  // ── Invoices ───────────────────────────────────────────────────────────────
  Future<List<SubscriptionInvoice>> getInvoices() async {
    try {
      final response = await _api.get('/api/v1/subscription/invoices');
      if (response['success'] == true && response['data'] != null) {
        return (response['data'] as List<dynamic>)
            .map((i) => SubscriptionInvoice.fromJson(i as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[SubscriptionRepo] getInvoices error: $e');
    }
    return [];
  }

  // ── Entitlements ───────────────────────────────────────────────────────────
  Future<Map<String, Map<String, dynamic>>> getEntitlements({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedEntitlements != null && _cachedEntitlements!.isNotEmpty) {
      return _cachedEntitlements!;
    }

    try {
      final response = await _api.get('/api/v1/entitlements');
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final raw = data['entitlements'] as Map<String, dynamic>? ?? {};
        if (raw.isNotEmpty) {
          _cachedEntitlements = raw.map((k, v) => MapEntry(k, v as Map<String, dynamic>));
          return _cachedEntitlements!;
        }
      }
    } catch (e) {
      debugPrint('[SubscriptionRepo] getEntitlements error: $e');
    }

    // Dynamic fallback: build entitlements directly from active subscription
    try {
      final sub = await getCurrentSubscription();
      final plan = sub.plan ?? PlanModel.defaultPlans.firstWhere(
        (p) => p.id.toLowerCase() == sub.planId.toLowerCase() || p.name.toUpperCase() == sub.planId.toUpperCase(),
        orElse: () => PlanModel.defaultPlans[1],
      );
      final map = <String, Map<String, dynamic>>{};
      final isPaid = sub.isActive && !plan.isFree;
      final planTier = plan.name.toUpperCase();
      final isProOrAbove = isPaid && (planTier == 'PRO' || planTier == 'ADVANCED' || planTier == 'BUSINESS');

      for (final feat in plan.features) {
        final code = feat.featureCode.isNotEmpty ? feat.featureCode : feat.featureName.replaceAll(' ', '_').toUpperCase();
        map[code] = {
          'allowed': feat.isEnabled && sub.isActive,
          'limit': feat.limitValue,
          'feature_name': feat.featureName,
        };
      }

      // Explicit guarantee for WhatsApp AI Chatbot on Pro & above
      if (isProOrAbove) {
        map['WHATSAPP_CHATBOT'] = {
          'allowed': true,
          'limit': null,
          'feature_name': 'WhatsApp AI Chatbot',
        };
      }

      _cachedEntitlements = map;
      return map;
    } catch (e) {
      debugPrint('[SubscriptionRepo] build dynamic entitlements error: $e');
    }

    return _cachedEntitlements ?? {};
  }

  Future<bool> canAccess(String featureCode) async {
    try {
      // 1. Direct check against active subscription
      final sub = await getCurrentSubscription();
      if (sub.isActive) {
        final plan = sub.plan ?? PlanModel.defaultPlans.firstWhere(
          (p) => p.id.toLowerCase() == sub.planId.toLowerCase() || p.name.toUpperCase() == sub.planId.toUpperCase(),
          orElse: () => PlanModel.defaultPlans[1],
        );
        final planTier = plan.name.toUpperCase();
        final planId = sub.planId.toLowerCase();

        // Business Suite has all features fully unlocked
        if (planTier == 'BUSINESS' || planId.contains('business')) {
          return true;
        }

        // WhatsApp Chatbot is unlocked on PRO, ADVANCED, and BUSINESS
        if (featureCode.toUpperCase() == 'WHATSAPP_CHATBOT') {
          if (planTier == 'PRO' || planTier == 'ADVANCED' || planTier == 'BUSINESS' ||
              planId.contains('pro') || planId.contains('advanced') || planId.contains('business')) {
            return true;
          }
        }

        // Check if feature is enabled in active plan's feature list
        final match = plan.features.firstWhere(
          (f) => f.featureCode.toUpperCase() == featureCode.toUpperCase() ||
                 f.featureName.toUpperCase() == featureCode.toUpperCase(),
          orElse: () => const PlanFeature(featureCode: '', featureName: '', isEnabled: false, limitType: 'BOOLEAN'),
        );
        if (match.featureCode.isNotEmpty) {
          return match.isEnabled;
        }

        // Paid tiers unlock standard features
        if (!plan.isFree && (planTier == 'PRO' || planTier == 'ADVANCED')) {
          return true;
        }
      }

      // 2. Check remote entitlements API
      final entitlements = await getEntitlements();
      if (entitlements.containsKey(featureCode)) {
        return entitlements[featureCode]?['allowed'] == true;
      }

      // If active paid subscription, allow by default
      return sub.isActive && !sub.isFree;
    } catch (e) {
      debugPrint('[SubscriptionRepo] canAccess error: $e');
      return true; // Fail open
    }
  }

  // ── Coupon Validation ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> validateCoupon({
    required String code,
    required String planId,
    required String billingCycle,
  }) async {
    try {
      final response = await _api.post('/api/v1/coupons/validate', body: {
        'code': code,
        'plan_id': planId,
        'billing_cycle': billingCycle,
      });
      return response;
    } catch (e) {
      debugPrint('[SubscriptionRepo] validateCoupon error: $e');
      return null;
    }
  }

  void clearCache() {
    _cachedSubscription = null;
    _cachedPlans = null;
    _cachedEntitlements = null;
  }
}
