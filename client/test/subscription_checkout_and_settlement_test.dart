import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/subscription/models/plan_model.dart';
import 'package:enx_money/features/subscription/models/subscription_model.dart';
import 'package:enx_money/features/subscription/models/invoice_model.dart';
import 'package:enx_money/features/subscription/presentation/widgets/subscription_payment_sheet.dart';
import 'package:enx_money/features/subscription/presentation/widgets/subscription_pdf_service.dart';
import 'package:enx_money/features/subscription/presentation/widgets/subscription_success_dialog.dart';
import 'package:enx_money/features/subscription/data/subscription_repository.dart';
import 'package:enx_money/features/subscription/presentation/screens/checkout_screen.dart';

void main() {
  group('Subscription Checkout & Backend Settlement Routing Tests', () {
    test('1. Plan tiers match required pricing (Basic 199, Pro 499, Advanced 999, Business 1999)', () {
      final plans = PlanModel.defaultPlans;

      final basic = plans.firstWhere((p) => p.name == 'BASIC');
      expect(basic.priceMonthly, 199.0);

      final pro = plans.firstWhere((p) => p.name == 'PRO');
      expect(pro.priceMonthly, 499.0);

      final advanced = plans.firstWhere((p) => p.name == 'ADVANCED');
      expect(advanced.priceMonthly, 999.0);

      final business = plans.firstWhere((p) => p.name == 'BUSINESS');
      expect(business.priceMonthly, 1999.0);
    });

    test('2. Merchant Settlement Destination represents ENX Money with secure gateway routing', () {
      const destination = SubscriptionPdfService.defaultSettlement;
      expect(destination.beneficiaryName, 'ENX Money');
      expect(destination.merchantName, 'ENX Money');
      expect(destination.gstin, '27AARCP9260R1Z2');
      expect(destination.accountNumber, isEmpty);
      expect(destination.ifscCode, isEmpty);
      expect(destination.urnNumber, isEmpty);
    });

    testWidgets('3. Payment Sheet Modal displays order breakdown, ENX Money merchant banner, and all payment methods', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final proPlan = PlanModel.defaultPlans.firstWhere((p) => p.name == 'PRO');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: SubscriptionPaymentSheet(
              plan: proPlan,
              initialBillingCycle: 'MONTHLY',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Order Breakdown
      expect(find.text('Secure Subscription Checkout'), findsOneWidget);
      expect(find.text(proPlan.displayName), findsOneWidget);
      expect(find.text('Applicable GST (18%)'), findsOneWidget);
      expect(find.text('Total Amount Due:'), findsOneWidget);

      // Verify ENX Money Merchant Security Banner
      expect(find.text('ENX Money Verified Merchant Checkout'), findsOneWidget);
      expect(find.text('100% SECURE'), findsOneWidget);

      // Verify strict confidentiality: No personal bank details displayed anywhere in the UI
      expect(find.textContaining('Rohit Samadhan Pawar'), findsNothing);
      expect(find.textContaining('002021712159733'), findsNothing);
      expect(find.textContaining('JIOP0000001'), findsNothing);
      expect(find.textContaining('92603438'), findsNothing);

      // Verify Supported Payment Methods Tabs
      expect(find.text('UPI Apps'), findsOneWidget);
      expect(find.text('Cards'), findsOneWidget);
      expect(find.text('NetBanking'), findsOneWidget);
      expect(find.text('AutoPay'), findsOneWidget);

      // Verify Popular UPI Apps
      expect(find.text('Google Pay'), findsOneWidget);
      expect(find.text('PhonePe'), findsOneWidget);
      expect(find.text('Paytm'), findsOneWidget);
      expect(find.text('BHIM'), findsOneWidget);

      // Verify Authorization Button
      expect(find.textContaining('Authorize & Pay'), findsOneWidget);
    });

    test('4. Subscription PDF Tax Invoice generates valid bytes with settlement information', () async {
      final inv = SubscriptionInvoice(
        id: 'inv-test-999',
        invoiceNumber: 'ENXI-2026-0099',
        planName: 'Pro — Smart Finance',
        billingCycle: 'MONTHLY',
        subtotal: 499.0,
        discount: 0.0,
        taxRate: 18.0,
        taxAmount: 89.82,
        total: 588.82,
        currency: 'INR',
        status: 'PAID',
        invoiceDate: DateTime(2026, 9, 25),
      );

      final pdfBytes = await SubscriptionPdfService.generateSubscriptionInvoicePdf(invoice: inv);
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
    });

    testWidgets('5. SubscriptionSuccessDialog renders Welcome to Business Suite with real Receipt ID and ENX Money Merchant', (tester) async {
      final businessPlan = PlanModel.defaultPlans.firstWhere((p) => p.name == 'BUSINESS');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubscriptionSuccessDialog(
              plan: businessPlan,
              billingCycle: 'MONTHLY',
              receiptId: 'ENXI-2026-0042',
              totalAmount: 2358.82,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title & receipt badge
      expect(find.text('🎉 Welcome to Business Suite!'), findsOneWidget);
      expect(find.text('Receipt ID'), findsOneWidget);
      expect(find.text('ENXI-2026-0042'), findsOneWidget);
      expect(find.textContaining('2,358.82'), findsOneWidget);
      expect(find.textContaining('ENX Money'), findsWidgets);

      // Strict confidentiality check
      expect(find.textContaining('Rohit Samadhan Pawar'), findsNothing);
      expect(find.textContaining('002021712159733'), findsNothing);
      expect(find.textContaining('JIOP0000001'), findsNothing);
      expect(find.textContaining('92603438'), findsNothing);

      expect(find.text('VERIFIED & CAPTURED'), findsOneWidget);
      expect(find.text('Continue to Dashboard'), findsOneWidget);
    });

    test('6. Payment Gateway Order Calculation includes 18% GST (Base ₹1,999 + GST ₹359.82 = ₹2,358.82)', () {
      const basePrice = 1999.0;
      final gst = (basePrice * 0.18 * 100).round() / 100;
      final total = ((basePrice + gst) * 100).round() / 100;
      final amountInPaise = (total * 100).round();

      expect(gst, 359.82);
      expect(total, 2358.82);
      expect(amountInPaise, 235882);

      final checkoutData = CheckoutData(
        orderId: 'order_test_99',
        amountInPaise: amountInPaise,
        currency: 'INR',
        planName: 'Business Suite',
        billingCycle: 'MONTHLY',
        originalAmount: basePrice,
        discountAmount: 0,
        finalAmount: total,
        totalAmount: total,
        baseAmount: basePrice,
        gstAmount: gst,
        razorpayKey: 'rzp_test_mock',
      );

      expect(checkoutData.displayTotalAmount, 2358.82);
      expect(checkoutData.displayBaseAmount, 1999.0);
      expect(checkoutData.displayGstAmount, 359.82);
    });

    test('7. WhatsApp Chatbot entitlement is enabled for PRO and BUSINESS tiers', () {
      final pro = PlanModel.defaultPlans.firstWhere((p) => p.name == 'PRO');
      final business = PlanModel.defaultPlans.firstWhere((p) => p.name == 'BUSINESS');

      final proHasBot = pro.features.any((f) => f.featureCode == 'WHATSAPP_CHATBOT' && f.isEnabled);
      final businessHasBot = business.features.any((f) => f.featureCode == 'WHATSAPP_CHATBOT' && f.isEnabled);

      expect(proHasBot, isTrue);
      expect(businessHasBot, isTrue);
    });

    test('8. CheckoutData correctly parses live dynamic UPI intent URL and QR data', () {
      final json = {
        'order_id': 'order_live_99',
        'amount': 117882,
        'currency': 'INR',
        'plan_name': 'Advanced Business',
        'billing_cycle': 'MONTHLY',
        'original_amount': 999.0,
        'discount_amount': 0.0,
        'final_amount': 1178.82,
        'razorpay_key': 'rzp_live_ThjlhbHvQ4iaQV',
        'upi_intent_url': 'upi://pay?pa=8767443493@jiopay&pn=Rohit%20Samadhan%20Pawar&am=1178.82&cu=INR&tn=Subscription%20Advanced%20Business&tr=order_live_99',
        'upi_qr_data': 'upi://pay?pa=8767443493@jiopay&pn=Rohit%20Samadhan%20Pawar&am=1178.82&cu=INR&tn=Subscription%20Advanced%20Business&tr=order_live_99',
        'payment_link': 'https://razorpay.me/@rohitsamadhanpawar4145',
        'upi_vpa': '8767443493@jiopay',
      };

      final data = CheckoutData.fromJson(json);
      expect(data.upiIntentUrl, contains('upi://pay?pa=8767443493@jiopay'));
      expect(data.upiIntentUrl, contains('am=1178.82'));
      expect(data.upiQrData, data.upiIntentUrl);
      expect(data.paymentLink, 'https://razorpay.me/@rohitsamadhanpawar4145');
      expect(data.upiVpa, '8767443493@jiopay');
    });

    test('9. Verification fails and returns null on invalid signature (Plan state remains Free)', () async {
      final repo = SubscriptionRepository();
      final result = await repo.verifyPaymentWithDetails(
        orderId: 'order_invalid_123',
        paymentId: 'pay_invalid_123',
        signature: 'invalid_tampered_signature',
        planId: 'business',
        billingCycle: 'MONTHLY',
      );

      // Must be strictly null
      expect(result, isNull);
    });

    testWidgets('10. CheckoutScreen displays only two clean payment triggers and no external web redirect button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final basicPlan = PlanModel.defaultPlans.firstWhere((p) => p.name == 'BASIC');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: CheckoutScreen(
            plan: basicPlan,
            billingCycle: 'MONTHLY',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify "Pay via Official Razorpay.me Page" is completely removed
      expect(find.textContaining('Pay via Official Razorpay.me Page'), findsNothing);
      expect(find.textContaining('razorpay.me'), findsNothing);

      // 2. Verify Primary CTA: Direct UPI Intent
      expect(find.text('Direct UPI Intent (GPay / PhonePe / Paytm)'), findsOneWidget);

      // 3. Verify Secondary CTA: Pay via Gateway (Cards / NetBanking / AutoPay)
      expect(find.textContaining('via Gateway (Cards / NetBanking / AutoPay)'), findsOneWidget);
      expect(find.text('Pay ₹234.82 via Gateway (Cards / NetBanking / AutoPay)'), findsOneWidget);
    });
  });
}
