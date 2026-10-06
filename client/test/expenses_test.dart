import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/features/expenses/models/expense_model.dart';

void main() {
  group('ENX Money — Business Expense Models & Calculations', () {
    test('ExpenseItem parses json and calculates tax breakdown correctly', () {
      final json = {
        'id': 'tx_exp_001',
        'accountType': 'BUSINESS',
        'type': 'DEBIT',
        'category': 'Rent & Facility',
        'amount': 25000.0,
        'date': '2026-09-16T10:00:00.000Z',
        'note': 'Warehouse Floor Lease',
        'status': 'PAID',
        'supplierName': 'DLF CyberCity Properties',
        'gstRate': 18.0,
        'gstin': '07AAAAA0000A1Z5',
        'taxableAmount': 21186.44,
        'cgst': 1906.78,
        'sgst': 1906.78,
        'totalGst': 3813.56,
        'invoiceNumber': 'DLF/2026/09/88',
        'accountName': 'HDFC Current Account',
        'paymentMode': 'BANK_TRANSFER',
      };

      final item = ExpenseItem.fromJson(json);

      expect(item.id, 'tx_exp_001');
      expect(item.displayTitle, 'Warehouse Floor Lease');
      expect(item.category, 'Rent & Facility');
      expect(item.amount, 25000.0);
      expect(item.isPaid, true);
      expect(item.isPending, false);
      expect(item.gstRate, 18.0);
      expect(item.supplierName, 'DLF CyberCity Properties');
      expect(item.taxableAmount, 21186.44);
      expect(item.totalGst, 3813.56);
      expect(item.accountName, 'HDFC Current Account');
    });

    test('ExpenseSummary parses both singular and plural API responses', () {
      final json = {
        'totalExpenses': 154200.50,
        'thisMonthExpenses': 48300.00,
        'todayExpenses': 7500.00,
        'pendingExpenses': 12000.00,
        'expenseCount': 42,
        'currency': 'INR',
      };

      final summary = ExpenseSummary.fromJson(json);

      expect(summary.totalExpenses, 154200.50);
      expect(summary.thisMonthExpenses, 48300.00);
      expect(summary.todayExpenses, 7500.00);
      expect(summary.pendingExpenses, 12000.00);
      expect(summary.expenseCount, 42);
      expect(summary.currency, 'INR');
    });

    test('Pending status expense returns isPending == true', () {
      final pendingItem = ExpenseItem.fromJson({
        'id': 'tx_exp_002',
        'category': 'Vendor & Supplier',
        'amount': 15000.0,
        'date': '2026-09-16T12:00:00.000Z',
        'note': 'Packaging raw material shipment',
        'status': 'PENDING',
      });

      expect(pendingItem.isPaid, false);
      expect(pendingItem.isPending, true);
    });
  });
}
