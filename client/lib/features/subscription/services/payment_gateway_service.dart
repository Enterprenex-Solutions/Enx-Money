// ENX Money — Real Payment Gateway Checkout Service
// Production Payment Gateway Integration via Razorpay Native SDK

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../data/subscription_repository.dart';
import '../models/invoice_model.dart';
import '../models/plan_model.dart';
import '../presentation/widgets/subscription_success_dialog.dart';

/// Real Production Payment Gateway Integration via Razorpay Native SDK
class RazorpayCheckout {
  RazorpayCheckout._();

  static Razorpay? _razorpay;

  /// Launch the real native Razorpay checkout
  static void open({
    required Map<String, dynamic> options,
    required void Function(PaymentSuccessResponse) onSuccess,
    required void Function(PaymentFailureResponse) onError,
    void Function(ExternalWalletResponse)? onExternalWallet,
  }) {
    try {
      _razorpay?.clear();
    } catch (_) {}

    _razorpay = Razorpay();

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
      try {
        _razorpay?.clear();
      } catch (_) {}
      onSuccess(response);
    });

    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
      try {
        _razorpay?.clear();
      } catch (_) {}
      onError(response);
    });

    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
      try {
        _razorpay?.clear();
      } catch (_) {}
      if (onExternalWallet != null) {
        onExternalWallet(response);
      }
    });

    _razorpay!.open(options);
  }

  static void dispose() {
    try {
      _razorpay?.clear();
    } catch (_) {}
    _razorpay = null;
  }
}

/// High-Level Payment Gateway Orchestration Service
class PaymentGatewayService {
  PaymentGatewayService._();

  static final SubscriptionRepository _repo = SubscriptionRepository();

  /// Start the complete, real payment gateway checkout flow
  static Future<bool> startSubscriptionCheckout({
    required BuildContext context,
    required PlanModel plan,
    required String billingCycle,
    double discount = 0,
    String? couponCode,
    bool isUpiIntentOnly = false,
    VoidCallback? onSuccess,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    // 1. Order Creation via POST /api/v1/subscription/create-order
    messenger.showSnackBar(
      const SnackBar(
        duration: Duration(milliseconds: 1200),
        backgroundColor: Color(0xFF1E293B),
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
            ),
            SizedBox(width: 12),
            Text(
              'Connecting to ENX Money Secure Gateway...',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );

    final checkoutData = await _repo.createPaymentOrder(
      planId: plan.id,
      billingCycle: billingCycle,
      couponCode: couponCode,
    );

    if (checkoutData == null || checkoutData.amountInPaise <= 0) {
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFEF4444),
            content: Text('Payment gateway order initialization failed. Please check network and try again.'),
          ),
        );
      }
      return false;
    }

    if (!context.mounted) return false;

    final completer = Completer<bool>();

    // 2. Prepare Razorpay Native SDK Checkout Options
    final options = <String, dynamic>{
      'key': checkoutData.razorpayKey.isNotEmpty
          ? checkoutData.razorpayKey
          : 'rzp_live_ThjlhbHvQ4iaQV',
      'amount': checkoutData.amountInPaise,
      'currency': checkoutData.currency,
      'name': 'ENX Money',
      'display_name': 'ENX Money',
      'description': 'Subscription: ${plan.displayName}',
      'prefill': {
        'contact': '9876543210',
        'email': 'billing@enxmoney.com',
      },
      'theme': {
        'color': '#10B981',
      },
      'modal': {
        'confirm_close': true,
      },
      'retry': {
        'enabled': false,
      },
    };

    // Attach order_id received from backend API (/api/v1/subscription/create-order)
    if (checkoutData.orderId.isNotEmpty) {
      options['order_id'] = checkoutData.orderId;
    }

    if (isUpiIntentOnly) {
      // Direct Native UPI Intent (Google Pay, PhonePe, Paytm apps directly detected by device OS)
      options['display_name'] = 'ENX Money';
      options['method'] = 'upi';
      options['upi'] = {
        'flow': 'intent',
      };
    } else {
      // Standard Gateway (Cards, NetBanking, AutoPay/Wallets, UPI)
      options['method'] = {
        'card': true,
        'netbanking': true,
        'wallet': true,
        'upi': true,
      };
      options['config'] = {
        'display': {
          'blocks': {
            'gateway': {
              'name': 'Cards, NetBanking, AutoPay & UPI',
              'instruments': [
                {'method': 'card'},
                {'method': 'netbanking'},
                {'method': 'wallet'},
                {'method': 'upi'},
              ],
            },
          },
          'sequence': ['block.gateway'],
          'preferences': {
            'show_default_blocks': true,
          },
        },
      };
    }

    // 3. Open Real Native Razorpay Gateway Sheet
    try {
      RazorpayCheckout.open(
        options: options,
        onError: (failure) {
          debugPrint('[Razorpay] Payment Failed/Cancelled: code=${failure.code}, message=${failure.message}');
          if (context.mounted) {
            messenger.showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
                content: Text('Transaction cancelled or failed. Please try again.'),
              ),
            );
          }
          if (!completer.isCompleted) completer.complete(false);
        },
        onExternalWallet: (wallet) {
          debugPrint('[Razorpay] External Wallet Selected: ${wallet.walletName}');
          if (context.mounted) {
            messenger.showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF1E293B),
                content: Text('External wallet chosen: ${wallet.walletName ?? 'Wallet'}.'),
              ),
            );
          }
          if (!completer.isCompleted) completer.complete(false);
        },
        onSuccess: (paymentResponse) async {
          debugPrint('[Razorpay] Payment Success: paymentId=${paymentResponse.paymentId}, orderId=${paymentResponse.orderId}');

          if (context.mounted) {
            messenger.showSnackBar(
              const SnackBar(
                duration: Duration(milliseconds: 1500),
                backgroundColor: Color(0xFF1E293B),
                content: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Verifying payment signature with ENX Money server...',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }

          // 4. Cryptographic Server-side Verification via POST /api/v1/subscription/verify
          final verifyResult = await _repo.verifyPaymentWithDetails(
            orderId: paymentResponse.orderId ?? checkoutData.orderId,
            paymentId: paymentResponse.paymentId ?? '',
            signature: paymentResponse.signature ?? '',
            planId: plan.id,
            billingCycle: billingCycle,
          );

          if (verifyResult == null || (verifyResult['verified'] != true && verifyResult['status'] != 'SUCCESS')) {
            debugPrint('[Razorpay] Verification rejected by server: $verifyResult');
            if (context.mounted) {
              messenger.showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    'Payment was not completed. No changes were made to your subscription.',
                  ),
                ),
              );
            }
            if (!completer.isCompleted) completer.complete(false);
            return;
          }

          // 5. Verification 200 OK — Activate subscription!
          onSuccess?.call();

          final receiptId = (verifyResult['receipt_id'] ?? verifyResult['receiptId']) as String? ??
              'ENXI-${DateTime.now().year}-0001';
          final invoiceJson = verifyResult['invoice'] as Map<String, dynamic>?;
          final invoice = invoiceJson != null ? SubscriptionInvoice.fromJson(invoiceJson) : null;
          final entitlements = verifyResult['entitlements'] as Map<String, dynamic>?;

          if (context.mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogCtx) => SubscriptionSuccessDialog(
                plan: plan,
                billingCycle: billingCycle,
                receiptId: receiptId,
                totalAmount: checkoutData.displayTotalAmount,
                invoice: invoice,
                entitlements: entitlements,
              ),
            );
          }

          if (!completer.isCompleted) completer.complete(true);
        },
      );
    } catch (e) {
      debugPrint('[Razorpay] Exception opening checkout: $e');
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Payment gateway error: $e'),
          ),
        );
      }
      if (!completer.isCompleted) completer.complete(false);
    }

    return completer.future;
  }
}
