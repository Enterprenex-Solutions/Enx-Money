import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/core/network/api_client.dart';
import 'package:enx_money/core/finance_mode/finance_mode_service.dart';
import 'package:enx_money/features/finance_mode/models/account_model.dart';
import 'package:enx_money/features/finance_mode/data/finance_mode_repository.dart';

void main() {
  setUp(() {
    ApiClient().setActiveBaseUrl('http://127.0.0.1:5000/api');
  });

  group('FinanceModeService Tests', () {
    test('Defaults to business mode and toggles mode', () {
      final service = FinanceModeService();
      expect(service.isBusiness, isTrue);
      expect(service.isPersonal, isFalse);
      expect(service.mode, FinanceMode.business);

      service.setMode(FinanceMode.personal);
      expect(service.isBusiness, isFalse);
      expect(service.isPersonal, isTrue);
      expect(service.mode, FinanceMode.personal);

      service.toggleMode();
      expect(service.isBusiness, isTrue);
    });
  });

  group('AccountModel Tests', () {
    test('Parses from JSON and exposes aliases correctly', () {
      final json = {
        'id': 'acc_test_101',
        'accountName': 'Apex Current Account',
        'bank': 'HDFC Bank',
        'accountNumber': '9840',
        'balance': 1250000.50,
        'mode': 'BUSINESS',
      };

      final acc = AccountModel.fromJson(json);
      expect(acc.id, 'acc_test_101');
      expect(acc.accountName, 'Apex Current Account');
      expect(acc.title, 'Apex Current Account');
      expect(acc.bankName, 'HDFC Bank');
      expect(acc.accountNumber, '9840');
      expect(acc.accountNumberLast4, '9840');
      expect(acc.balance, 1250000.50);
      expect(acc.isBusiness, isTrue);
      expect(acc.type, FinanceType.business);
    });
  });

  group('FinanceModeRepository Tests', () {
    test('Returns default fallback accounts when offline', () async {
      final repo = FinanceModeRepository();
      final accounts = await repo.getAccounts();
      expect(accounts, isNotEmpty);
      expect(accounts.any((a) => a.isBusiness), isTrue);
      expect(accounts.any((a) => a.isPersonal), isTrue);
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('Transfers funds with simulated fallback', () async {
      final repo = FinanceModeRepository();
      final result = await repo.transferFunds(
        fromAccountId: 'acc_b01',
        toAccountId: 'acc_p01',
        amount: 25000.0,
        fromMode: 'business',
        toMode: 'personal',
        reason: 'Monthly Director Drawings',
      );

      expect(result, isNotNull);
      expect(result['success'], isTrue);
    });
  });
}
