import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:enx_money/core/constants/app_colors.dart';
import 'package:enx_money/core/services/device_service.dart';
import 'package:enx_money/core/theme/theme_controller.dart';
import 'package:enx_money/core/theme/app_theme.dart';
import 'package:enx_money/features/auth/data/auth_repository.dart';
import 'package:enx_money/core/widgets/device_approval_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Requirement 3: Bright Interface / Theme Tests', () {
    test('ThemeController strictly defaults to ThemeMode.light and bright mode', () async {
      final controller = ThemeController();
      await controller.init();

      expect(controller.themeMode, ThemeMode.light);
      expect(controller.isDarkMode, false);
    });

    testWidgets('AppTheme lightTheme has brand primary color and bright scaffold background', (tester) async {
      final lightTheme = AppTheme.lightTheme;
      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.primaryColor, AppColors.brandBlue);
      expect(lightTheme.scaffoldBackgroundColor, AppColors.brandBackground);
      expect(lightTheme.colorScheme.primary, AppColors.brandBlue);
    });
  });

  group('Requirement 1 & 2: Multi-Device Service & Exception Tests', () {
    test('DeviceService generates unique and persistent device ID', () async {
      final id1 = await DeviceService.getDeviceId();
      final id2 = await DeviceService.getDeviceId();

      expect(id1, isNotEmpty);
      expect(id1, equals(id2)); // Must be persistent
    });

    test('DeviceService bundles device payload with name and platform', () async {
      final payload = await DeviceService.getDevicePayload();

      expect(payload['deviceId'], isNotEmpty);
      expect(payload['deviceName'], isNotEmpty);
      expect(payload['devicePlatform'], isNotEmpty);
    });

    test('DeviceApprovalRequiredException correctly encapsulates approval details', () {
      final ex = DeviceApprovalRequiredException(
        approvalRequestId: 'req_test_123',
        verificationCode: '4589',
        deviceName: 'iPhone 15 Pro',
        deviceId: 'device_iphone_15',
        message: 'Permission required from primary device',
        identifier: 'user@enxmoney.com',
      );

      expect(ex.approvalRequestId, 'req_test_123');
      expect(ex.verificationCode, '4589');
      expect(ex.deviceName, 'iPhone 15 Pro');
      expect(ex.identifier, 'user@enxmoney.com');
      expect(ex.toString(), 'Permission required from primary device');
    });

    testWidgets('DeviceApprovalDialog renders verification code and device details', (tester) async {
      final mockRequest = {
        'id': 'req_test_999',
        'deviceName': 'MacBook Pro',
        'platform': 'macos',
        'ipAddress': '192.168.1.50',
        'verificationCode': '7821',
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DeviceApprovalDialog(request: mockRequest),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('New Device Login Request'), findsOneWidget);
      expect(find.text('MacBook Pro'), findsOneWidget);
      expect(find.text('7821'), findsOneWidget);
      expect(find.text('DENY'), findsOneWidget);
      expect(find.text('APPROVE'), findsOneWidget);
    });
  });
}
