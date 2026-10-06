import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:enx_money/features/suppliers/presentation/screens/suppliers_screen.dart';
import 'package:enx_money/features/suppliers/data/suppliers_repository.dart';
import 'package:enx_money/features/suppliers/models/supplier_model.dart';
import 'package:enx_money/core/theme/theme_controller.dart';
import 'package:enx_money/core/localization/app_localizations.dart';

class FakeSuppliersRepository extends SuppliersRepository {
  @override
  Future<List<SupplierModel>> getSuppliers() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SuppliersScreen Theme & Contrast Tests', () {
    testWidgets('Renders properly in Light Mode with high-contrast text and search input', (WidgetTester tester) async {
      await ThemeController().setThemeMode(ThemeMode.light);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
          ],
          home: SuppliersScreen(repository: FakeSuppliersRepository()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Suppliers & Vendors'), findsOneWidget);

      // Verify Top Banner Card
      expect(find.text('TOTAL YOU WILL GIVE (PAYABLE)'), findsOneWidget);

      // Verify Search TextField and hint
      expect(find.byType(TextField), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.cursorColor, const Color(0xFF2563EB));
      expect(textField.style?.color, const Color(0xFF0F172A)); // Dark slate in Light Mode

      // Verify Empty State Text
      expect(find.text('No Suppliers Found'), findsOneWidget);
      final emptyHeadline = tester.widget<Text>(find.text('No Suppliers Found'));
      expect(emptyHeadline.style?.color, const Color(0xFF1E293B)); // High contrast dark text in Light Mode

      // Verify Add Supplier Floating Action Button
      expect(find.text('Add Supplier'), findsOneWidget);
    });

    testWidgets('Renders properly in Dark Mode with crisp white text', (WidgetTester tester) async {
      await ThemeController().setThemeMode(ThemeMode.dark);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
          ],
          home: SuppliersScreen(repository: FakeSuppliersRepository()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Search TextField style in Dark Mode
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.cursorColor, const Color(0xFF3B82F6));
      expect(textField.style?.color, const Color(0xFFFFFFFF)); // Crisp white in Dark Mode

      // Verify Empty State in Dark Mode
      final emptyHeadline = tester.widget<Text>(find.text('No Suppliers Found'));
      expect(emptyHeadline.style?.color, const Color(0xFFF8FAFC)); // Crisp light in Dark Mode
    });
  });
}
