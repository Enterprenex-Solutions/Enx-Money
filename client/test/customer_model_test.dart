import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/customers/models/customer_model.dart';

void main() {
  group('CustomerModel Robust Type Coercion', () {
    test('Correctly parses string numbers and integer booleans from MySQL', () {
      final json = {
        'id': 'cust_test_1',
        'name': 'Krishna Textiles',
        'phone': '9848012345',
        'opening_balance': '25000.50',
        'current_balance': '15000.75',
        'credit_limit': '50000',
        'block_on_credit_breach': 1, // MySQL TINYINT (1)
        'total_sales': '100000.00',
        'total_payments': '85000.00',
        'aging': {
          'days0_30': '10000.00',
          'days31_60': '5000.75',
          'days61_90': '0',
          'days90_plus': 0,
        },
      };

      final model = CustomerModel.fromJson(json);

      expect(model.id, equals('cust_test_1'));
      expect(model.name, equals('Krishna Textiles'));
      expect(model.openingBalance, equals(25000.50));
      expect(model.currentBalance, equals(15000.75));
      expect(model.creditLimit, equals(50000.0));
      expect(model.blockOnCreditBreach, isTrue);
      expect(model.totalSales, equals(100000.00));
      expect(model.totalPayments, equals(85000.00));
      expect(model.aging.days0To30, equals(10000.00));
      expect(model.aging.days31To60, equals(5000.75));
    });

    test('Handles null fields with safe defaults', () {
      final json = {
        'id': 'cust_null_test',
        'name': 'Ramesh Kumar',
        'phone': '9123456780',
      };

      final model = CustomerModel.fromJson(json);

      expect(model.name, equals('Ramesh Kumar'));
      expect(model.openingBalance, equals(0.0));
      expect(model.currentBalance, equals(0.0));
      expect(model.creditLimit, equals(0.0));
      expect(model.blockOnCreditBreach, isFalse);
      expect(model.aging.days0To30, equals(0.0));
    });
  });
}
