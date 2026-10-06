import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/domain/models/enums.dart';
import 'package:enx_money/domain/models/kpi_summary.dart';
import 'package:enx_money/domain/models/transaction_item.dart';
import 'package:enx_money/domain/models/customer_model.dart';
import 'package:enx_money/domain/models/compliance_models.dart';
import 'package:enx_money/domain/repositories/transaction_repository.dart';

void main() {
  group('Section 10 KPI Error Guards & Math Verification', () {
    test('safeDivide gracefully handles division by zero and NaNs', () {
      expect(safeDivide(100, 0), equals(0.0));
      expect(safeDivide(0, 0), equals(0.0));
      expect(safeDivide(double.nan, 5), equals(0.0));
      expect(safeDivide(10, double.nan), equals(0.0));
      expect(safeDivide(50, 100), equals(0.5));
      expect(safeDivide(100, 0, -1.0), equals(-1.0));
    });

    test('Empty transaction repository produces zero-error safe KPIs', () {
      final repo = TransactionRepository();
      final kpi = repo.kpiSummary;

      // Ensure no NaNs or Infinities
      expect(kpi.totalRevenue, equals(0.0));
      expect(kpi.totalExpense, equals(0.0));
      expect(kpi.netProfit, equals(0.0));
      expect(kpi.business.profitMargin.isNaN, isFalse);
      expect(kpi.business.profitMargin.isInfinite, isFalse);
      expect(kpi.business.profitMargin, equals(0.0));

      expect(kpi.payments.collectionRate.isNaN, isFalse);
      expect(kpi.payments.collectionRate.isInfinite, isFalse);
      expect(kpi.payments.collectionRate, equals(0.0));

      expect(kpi.customer.retentionRate, equals(0.0));
      expect(kpi.customer.growthRate, equals(0.0));
      expect(kpi.sales.averageOrderValue, equals(0.0));
    });

    test('Computes multi-area Section 10 KPIs correctly when data is added', () {
      final repo = TransactionRepository();
      final now = DateTime.now();

      // Add Customers
      repo.addCustomer(CustomerModel(
        id: 'c1',
        name: 'Alpha Corp',
        status: 'active',
        createdAt: now.subtract(const Duration(days: 5)),
      ));
      repo.addCustomer(CustomerModel(
        id: 'c2',
        name: 'Beta LLC',
        status: 'inactive',
        createdAt: now.subtract(const Duration(days: 10)),
      ));

      // Add Transactions
      repo.addTransaction(TransactionItem(
        id: 't1',
        title: 'Product Sale',
        amount: 10000.0,
        type: TransactionType.revenue,
        profileType: ProfileType.business,
        category: 'Software',
        date: now,
        paymentMode: PaymentMode.bankTransfer,
        customerId: 'c1',
      ));
      repo.addTransaction(TransactionItem(
        id: 't2',
        title: 'Office Cloud Expense',
        amount: 2500.0,
        type: TransactionType.expense,
        profileType: ProfileType.business,
        category: 'Infrastructure',
        date: now,
        paymentMode: PaymentMode.creditCard,
      ));
      repo.addTransaction(TransactionItem(
        id: 't3',
        title: 'Pending Milestone Invoice',
        amount: 5000.0,
        type: TransactionType.receivable,
        profileType: ProfileType.business,
        category: 'Consulting',
        date: now,
        paymentMode: PaymentMode.bankTransfer,
        isCleared: false,
        customerId: 'c1',
      ));

      final kpi = repo.kpiSummary;

      // Business Area
      expect(kpi.business.revenue, equals(10000.0));
      expect(kpi.business.expenses, equals(2500.0));
      expect(kpi.business.profit, equals(7500.0));
      expect(kpi.business.profitMargin, equals(75.0)); // 7500 / 10000 * 100

      // Customer Area
      expect(kpi.customer.totalCustomers, equals(2));
      expect(kpi.customer.activeCustomers, equals(1));
      expect(kpi.customer.retentionRate, equals(50.0)); // 1 active / 2 total = 50%

      // Sales Area
      expect(kpi.sales.totalSales, equals(10000.0));
      expect(kpi.sales.totalOrders, equals(1));
      expect(kpi.sales.averageOrderValue, equals(10000.0));
      expect(kpi.sales.topProduct, equals('Software'));

      // Payments Area
      expect(kpi.payments.amountReceived, equals(10000.0));
      expect(kpi.payments.amountPending, equals(5000.0));
      // Total due = 15000. Collection rate = 10000 / 15000 * 100 = 66.7%
      expect(kpi.payments.collectionRate, equals(66.7));
    });
  });

  group('Section 21 Analytics Compliance & Governance', () {
    test('Event dictionary automatically logs domain actions', () {
      final repo = TransactionRepository();
      final initialCount = repo.events.length;

      repo.addCustomer(CustomerModel(
        id: 'c99',
        name: 'New Growth Client',
        createdAt: DateTime.now(),
      ));

      expect(repo.events.length, equals(initialCount + 1));
      expect(repo.events.first.eventName, equals('customer_added'));
      expect(repo.events.first.purpose, equals('Customer growth'));
    });

    test('Data minimization extracts non-PII analytics dataset (Section 4)', () {
      final repo = TransactionRepository();
      repo.addCustomer(CustomerModel(
        id: 'c-secret-1',
        name: 'Confidential Client Name',
        phone: '+91 99999 88888',
        email: 'secret@client.com',
        customerType: 'Enterprise',
        businessCategory: 'Fintech',
        createdAt: DateTime.now(),
        totalInvoiced: 50000.0,
      ));

      final minimized = repo.getMinimizedAnalyticsDataset();
      expect(minimized.length, equals(1));
      final row = minimized.first;

      // PII stripped
      expect(row.containsKey('name'), isFalse);
      expect(row.containsKey('phone'), isFalse);
      expect(row.containsKey('email'), isFalse);

      // Necessary analytics attributes preserved
      expect(row['customer_id'], equals('c-secret-1'));
      expect(row['customer_type'], equals('Enterprise'));
      expect(row['business_category'], equals('Fintech'));
      expect(row['total_volume'], equals(50000.0));
    });

    test('Role-Based Access Control switches roles properly (Section 7)', () {
      final repo = TransactionRepository();
      expect(repo.currentRole, equals(AppUserRole.admin));

      repo.switchRole(AppUserRole.dataAnalyst);
      expect(repo.currentRole, equals(AppUserRole.dataAnalyst));

      repo.switchRole(AppUserRole.support);
      expect(repo.currentRole, equals(AppUserRole.support));
    });

    test('Retention purge action updates timestamp (Section 9)', () {
      final repo = TransactionRepository();
      final policy = repo.retentionPolicies.firstWhere((p) => p.dataset == 'Temporary datasets');
      expect(policy.lastPurged, isNull);

      repo.purgeExpiredData('Temporary datasets');
      final updatedPolicy = repo.retentionPolicies.firstWhere((p) => p.dataset == 'Temporary datasets');
      expect(updatedPolicy.lastPurged, isNotNull);
      expect(repo.events.first.eventName, equals('retention_purged'));
    });

    test('Compliance register and signoff checklist toggling (Sections 12 & 14)', () {
      final repo = TransactionRepository();
      final firstCheck = repo.signOffChecklist.first;
      final initialStatus = firstCheck.isCompleted;

      repo.toggleSignOffItem(firstCheck.id);
      expect(repo.signOffChecklist.first.isCompleted, equals(!initialStatus));

      final firstReg = repo.complianceRegisters.first;
      final initialRegStatus = firstReg.isReviewed;
      repo.toggleComplianceReviewed(firstReg.id);
      expect(repo.complianceRegisters.first.isReviewed, equals(!initialRegStatus));
    });
  });
}
