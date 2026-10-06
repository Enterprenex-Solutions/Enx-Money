import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:enx_money/features/finance_mode/models/upi_handle_model.dart';
import 'package:enx_money/features/finance_mode/data/finance_mode_repository.dart';
import 'package:enx_money/features/finance_mode/presentation/screens/manage_upi_handles_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
      theme: ThemeData.light().copyWith(splashFactory: NoSplash.splashFactory),
      home: child,
    );
  }

  group('Manage UPI IDs & Handles Unit & Repository Tests', () {
    test('UpiHandleModel json serialization and copyWith works properly', () {
      final handle = UpiHandleModel(
        id: 'hdl_test_1',
        vpa: 'revanth@enxmoney',
        prefix: 'revanth',
        suffix: '@enxmoney',
        bankName: 'State Bank of India',
        accountId: 'acc_p01',
        accountNumberLast4: '1024',
        isPrimary: true,
        isActive: true,
        qrData: 'upi://pay?pa=revanth@enxmoney&pn=Revanth&cu=INR',
        createdAt: DateTime(2026, 1, 1),
      );

      final json = handle.toJson();
      expect(json['vpa'], 'revanth@enxmoney');
      expect(json['isPrimary'], true);
      expect(json['bankName'], 'State Bank of India');

      final fromJson = UpiHandleModel.fromJson(json);
      expect(fromJson.vpa, handle.vpa);
      expect(fromJson.isPrimary, true);
      expect(fromJson.accountNumberLast4, '1024');

      final copied = handle.copyWith(isPrimary: false, isActive: false);
      expect(copied.isPrimary, false);
      expect(copied.isActive, false);
      expect(copied.vpa, 'revanth@enxmoney');
    });

    test('Real-time handle availability check detects valid, reserved, and taken aliases', () async {
      final repo = FinanceModeRepository();

      // 1. Reserved prefix check
      final reservedCheck = await repo.checkHandleAvailability('admin@enxmoney');
      expect(reservedCheck.available, false);
      expect(reservedCheck.suggestions, isNotEmpty);

      // 2. Short prefix check
      final shortCheck = await repo.checkHandleAvailability('ab@enxmoney');
      expect(shortCheck.available, false);

      // 3. Valid new prefix check
      final validCheck = await repo.checkHandleAvailability('krishna999@enxmoney');
      expect(validCheck.available, true);
      expect(validCheck.suggestions, isNotEmpty);
    });

    test('Dynamic alias creation, primary toggle, and deletion works in repository', () async {
      final repo = FinanceModeRepository();

      // Create new handle
      final newHandle = await repo.createCustomHandle(
        vpa: 'testuser88@enxmoney',
        bankName: 'State Bank of India',
        accountNumberLast4: '1024',
        isPrimary: true,
      );

      expect(newHandle, isNotNull);
      expect(newHandle!.vpa, 'testuser88@enxmoney');
      expect(newHandle.isPrimary, true);

      // Toggle status
      final toggled = await repo.toggleHandleStatus(newHandle.id, false);
      expect(toggled, isNotNull);
      expect(toggled!.isActive, false);

      // Delete handle
      final deleted = await repo.deleteHandle(newHandle.id);
      expect(deleted, true);
    });
  });

  group('Manage UPI IDs & Handles Screen UI Tests', () {
    testWidgets('Manage UPI IDs screen renders header, input, suffix chips, bank selector and handles', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithTheme(const ManageUpiHandlesScreen()));
      await tester.pumpAndSettle();

      // Screen title and subtitle
      expect(find.text('Manage UPI IDs & Handles'), findsOneWidget);
      expect(find.text('Create Custom UPI Handle'), findsOneWidget);
      expect(find.text('NPCI BHIM UPI Verified Routing'), findsOneWidget);

      // Input field
      expect(find.text('UPI Prefix'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);

      // Suffix chips
      expect(find.text('@enxmoney'), findsWidgets);
      expect(find.text('@okhdfcbank'), findsWidgets);
      expect(find.text('@oksbi'), findsWidgets);

      // Bank account selection
      expect(find.text('Link to Primary Bank Account'), findsOneWidget);

      // Primary toggle switch
      expect(find.text('Set as Primary Receiving Alias'), findsOneWidget);

      // Active handles section
      expect(find.textContaining('Active Handles'), findsOneWidget);
    });

    testWidgets('Tapping View QR Code opens modal with QrImageView and payee details', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithTheme(const ManageUpiHandlesScreen()));
      await tester.pumpAndSettle();

      // Find 'View QR Code' button
      final qrButtons = find.text('View QR Code');
      expect(qrButtons, findsWidgets);

      // Tap first QR code button
      await tester.tap(qrButtons.first);
      await tester.pumpAndSettle();

      // Verify QR Code Modal contents
      expect(find.text('Direct Payment QR Code'), findsOneWidget);
      expect(find.text('Scan using any UPI App (GPay, PhonePe, Paytm, BHIM)'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Copy UPI ID'), findsOneWidget);
      expect(find.text('Share QR'), findsOneWidget);
    });
  });
}
