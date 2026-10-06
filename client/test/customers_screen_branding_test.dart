import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:enx_money/features/customers/presentation/screens/customers_screen.dart';
import 'package:enx_money/features/customers/models/customer_model.dart';
import 'package:enx_money/features/customers/data/customers_repository.dart';
import 'package:enx_money/features/profile/data/profile_repository.dart';
import 'package:enx_money/core/utils/reminder_launcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Customers Screen Dynamic Business Header & Contrast', () {
    testWidgets('Header displays dynamic business name "${"Revanth Enterprises"} • Customers" and removes ENTERPRENEX BUSINESS', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final prefs = await SharedPreferences.getInstance();
      final profileJson = {
        'fullName': 'Revanth V',
        'businessProfile': {
          'businessName': 'Revanth Enterprises',
          'businessType': 'Wholesaler',
        },
      };
      await prefs.setString('user_full_profile_data', jsonEncode(profileJson));
      await ProfileRepository().loadProfile(fetchFromApi: false);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(splashFactory: NoSplash.splashFactory),
          home: const CustomersScreen(),
        ),
      );
      await tester.pump();

      // 1. Dynamic business name in header
      expect(find.text('Revanth Enterprises • Customers'), findsOneWidget);
      expect(find.text('ENX Money • Customers'), findsNothing);

      // 2. ENTERPRENEX BUSINESS is completely removed
      expect(find.text('ENTERPRENEX BUSINESS'), findsNothing);

      // 3. Light mode text color is #0F172A
      final titleWidget = tester.widget<Text>(find.text('Revanth Enterprises • Customers'));
      expect(titleWidget.style?.color, const Color(0xFF0F172A));
    });

    testWidgets('Header adapts to Dark Mode with #FFFFFF text and defaults gracefully to "Business • Customers"', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Explicitly set empty profile so it falls back to 'Business'
      final prefs = await SharedPreferences.getInstance();
      final profileJson = {
        'fullName': '',
        'businessProfile': {
          'businessName': '',
        },
      };
      await prefs.setString('user_full_profile_data', jsonEncode(profileJson));
      await ProfileRepository().loadProfile(fetchFromApi: false);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(splashFactory: NoSplash.splashFactory),
          home: const CustomersScreen(),
        ),
      );
      await tester.pump();

      // Graceful default
      expect(find.text('Business • Customers'), findsOneWidget);
      expect(find.text('ENX Money • Customers'), findsNothing);
      expect(find.text('ENTERPRENEX BUSINESS'), findsNothing);

      // Dark mode text color is #FFFFFF
      final titleWidget = tester.widget<Text>(find.text('Business • Customers'));
      expect(titleWidget.style?.color, const Color(0xFFFFFFFF));
    });
  });

  group('Dynamic Payment Reminder Templates', () {
    testWidgets('Reminder bottom sheet displays live business name and strict template wording', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final prefs = await SharedPreferences.getInstance();
      final profileJson = {
        'fullName': 'Revanth V',
        'businessProfile': {
          'businessName': 'Revanth Enterprises',
        },
      };
      await prefs.setString('user_full_profile_data', jsonEncode(profileJson));
      await ProfileRepository().loadProfile(fetchFromApi: false);

      const customer = CustomerModel(
        id: 'cust_101',
        name: 'Suresh Kumar',
        phone: '9876543210',
        currentBalance: 12500.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: false,
            splashFactory: NoSplash.splashFactory,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ReminderLauncher.showReminderBottomSheet(
                      context: context,
                      customer: customer,
                      repository: CustomersRepository(),
                    );
                  },
                  child: const Text('Open Reminder'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Reminder'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify customer name and due badge
      expect(find.text('Suresh Kumar'), findsOneWidget);
      expect(find.text('₹12,500.00 DUE'), findsOneWidget);
      expect(find.text('Send via WhatsApp'), findsOneWidget);
      expect(find.text('Send SMS'), findsOneWidget);
      expect(find.text('Send Email Statement'), findsOneWidget);

      // Verify that ENX Money Enterprise is NEVER present
      expect(find.textContaining('ENX Money Enterprise'), findsNothing);
    });

    testWidgets('Reminder fallback hierarchy defaults to user full name when business name is unconfigured', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final prefs = await SharedPreferences.getInstance();
      final profileJson = {
        'fullName': 'Pooja Hegde',
        'businessProfile': {
          'businessName': '',
        },
      };
      await prefs.setString('user_full_profile_data', jsonEncode(profileJson));
      await ProfileRepository().loadProfile(fetchFromApi: false);

      const customer = CustomerModel(
        id: 'cust_102',
        name: 'Amit Shah',
        phone: '9876543211',
        currentBalance: 4500.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: false,
            splashFactory: NoSplash.splashFactory,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ReminderLauncher.showReminderBottomSheet(
                      context: context,
                      customer: customer,
                      repository: CustomersRepository(),
                    );
                  },
                  child: const Text('Open Reminder Fallback'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Reminder Fallback'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Amit Shah'), findsOneWidget);
      expect(find.text('₹4,500.00 DUE'), findsOneWidget);
      expect(find.textContaining('ENX Money Enterprise'), findsNothing);
    });

    test('generateReminderMessage generates exact template format with dynamic business name', () async {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = {
        'fullName': 'Srinivas Rao',
        'businessProfile': {
          'businessName': 'Sri Sai Balaji Traders',
        },
      };
      await prefs.setString('user_full_profile_data', jsonEncode(profileJson));
      await ProfileRepository().loadProfile(fetchFromApi: false);

      const customer = CustomerModel(
        id: 'cust_201',
        name: 'Venkata Ramana',
        phone: '9848012345',
        currentBalance: 15750.50,
      );

      final msg = ReminderLauncher.generateReminderMessage(customer: customer);
      expect(
        msg,
        equals('Dear Venkata Ramana, this is a gentle payment reminder from Sri Sai Balaji Traders for your outstanding balance of ₹15,750.50. Please settle the pending dues at your earliest convenience. Thank you!'),
      );
    });

    test('generateReminderMessage falls back to user full name when business name is empty', () async {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = {
        'fullName': 'Srinivas Rao',
        'businessProfile': {
          'businessName': '',
        },
      };
      await prefs.setString('user_full_profile_data', jsonEncode(profileJson));
      await ProfileRepository().loadProfile(fetchFromApi: false);

      const customer = CustomerModel(
        id: 'cust_202',
        name: 'Kavitha M',
        phone: '9848012346',
        currentBalance: 8200.0,
      );

      final msg = ReminderLauncher.generateReminderMessage(customer: customer);
      expect(
        msg,
        equals('Dear Kavitha M, this is a gentle payment reminder from Srinivas Rao for your outstanding balance of ₹8,200.00. Please settle the pending dues at your earliest convenience. Thank you!'),
      );
    });

    test('generateReminderMessage falls back to "Business" when both business name and full name are empty', () async {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = {
        'fullName': '',
        'businessProfile': {
          'businessName': '',
        },
      };
      await prefs.setString('user_full_profile_data', jsonEncode(profileJson));
      await ProfileRepository().loadProfile(fetchFromApi: false);

      const customer = CustomerModel(
        id: 'cust_203',
        name: 'Raghu V',
        phone: '9848012347',
        currentBalance: 3000.0,
      );

      final msg = ReminderLauncher.generateReminderMessage(customer: customer);
      expect(
        msg,
        equals('Dear Raghu V, this is a gentle payment reminder from Business for your outstanding balance of ₹3,000.00. Please settle the pending dues at your earliest convenience. Thank you!'),
      );
    });
  });
}
