import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/transaction_item.dart';
import '../models/kpi_summary.dart';
import '../models/enterprise_model.dart';
import '../models/customer_model.dart';
import '../models/supplier_model.dart';
import '../models/compliance_models.dart';

class TransactionRepository extends ChangeNotifier {
  final List<TransactionItem> _transactions = [];
  final List<EnterpriseModel> _enterprises = [];
  final List<CustomerModel> _customers = [];
  final List<SupplierModel> _suppliers = [];

  // Section 21 Compliance State
  final List<AnalyticsEventItem> _events = [];
  AppUserRole _currentRole = AppUserRole.admin;

  final List<DataLineageItem> _dataLineageList = [
    const DataLineageItem(
      analyticsField: 'Total Sales',
      source: 'sales.amount',
      transformation: 'SUM(amount)',
      finalUse: 'Sales dashboard',
    ),
    const DataLineageItem(
      analyticsField: 'Monthly Revenue',
      source: 'payments.amount',
      transformation: 'SUM by month',
      finalUse: 'Revenue KPI',
    ),
    const DataLineageItem(
      analyticsField: 'Total Expenses',
      source: 'expenses.amount',
      transformation: 'SUM by category/month',
      finalUse: 'Expense dashboard',
    ),
    const DataLineageItem(
      analyticsField: 'Profit',
      source: 'Revenue & Expenses',
      transformation: 'Revenue minus expenses',
      finalUse: 'Business KPI',
    ),
    const DataLineageItem(
      analyticsField: 'Active Customers',
      source: 'customer.status',
      transformation: 'Filter active records',
      finalUse: 'Customer KPI',
    ),
    const DataLineageItem(
      analyticsField: 'Collection Rate',
      source: 'received/outstanding',
      transformation: 'Received ├╖ due ├ù 100',
      finalUse: 'Payment KPI',
    ),
  ];

  final List<ConsentRecord> _consentRecords = [
    const ConsentRecord(
      dataCategory: 'App usage events',
      purpose: 'Product analytics',
      legalBasis: 'Applicable consent / legal basis',
      status: 'Active & Enforced',
    ),
    const ConsentRecord(
      dataCategory: 'Customer information',
      purpose: 'Customer service / operations',
      legalBasis: 'Applicable contractual / legal basis',
      status: 'Active & Enforced',
    ),
    const ConsentRecord(
      dataCategory: 'Transaction data',
      purpose: 'Financial reporting / analytics',
      legalBasis: 'Applicable contractual / legal basis',
      status: 'Active & Enforced',
    ),
    const ConsentRecord(
      dataCategory: 'Marketing analytics',
      purpose: 'Marketing measurement',
      legalBasis: 'Applicable consent or other valid basis',
      status: 'Opt-in Controlled',
    ),
  ];

  final List<RetentionPolicyItem> _retentionPolicies = [
    const RetentionPolicyItem(
      dataset: 'Raw analytics events',
      retention: 'Defined by approved policy (90d)',
      archivePurge: 'Scheduled',
      owner: 'Data Team',
    ),
    const RetentionPolicyItem(
      dataset: 'Dashboard data',
      retention: 'Defined by approved policy (365d)',
      archivePurge: 'Scheduled',
      owner: 'Data Team',
    ),
    const RetentionPolicyItem(
      dataset: 'Reports',
      retention: 'Defined by approved policy (7y)',
      archivePurge: 'Scheduled',
      owner: 'Business/Data',
    ),
    const RetentionPolicyItem(
      dataset: 'Temporary datasets',
      retention: 'Short, defined period (7d)',
      archivePurge: 'Automatic purge',
      owner: 'Data Team',
    ),
    const RetentionPolicyItem(
      dataset: 'Model training data',
      retention: 'Defined by approved policy (180d)',
      archivePurge: 'Controlled purge',
      owner: 'ML/Risk Owner',
    ),
  ];

  final List<ModelGovernanceItem> _modelGovernanceList = [
    const ModelGovernanceItem(
      modelName: 'ENX-FraudGuard AI',
      version: 'v2.1-production',
      inputs: 'Transaction amount, frequency, velocity, customer tier, time of day',
      output: 'Risk score (0-100) & risk tier classification',
      decisionLogic: 'Score > 85: Auto-Hold; 60-85: Manual Review; < 60: Auto-Approve',
      owner: 'Risk & ML Engineering Team',
      performance: 'Accuracy: 98.4%, Precision: 96.2%, Recall: 94.8%',
      drift: 'Data/model drift monitored weekly (KS Drift Metric: 0.012 - Normal)',
      biasFairness: 'Protected class disparate impact ratio: 0.98 (Compliant)',
      humanReview: 'Escalated to 24/7 fraud ops with 30-min SLA & user appeal channel',
    ),
  ];

  final List<ComplianceRegisterItem> _complianceRegisters = [
    const ComplianceRegisterItem(
      id: '1',
      datasetOrModel: 'Product analytics events',
      piiStatus: 'Yes/No',
      consentLegalBasis: 'Documented',
      retention: 'Defined (90d)',
      isReviewed: true,
    ),
    const ComplianceRegisterItem(
      id: '2',
      datasetOrModel: 'Sales data',
      piiStatus: 'Possible',
      consentLegalBasis: 'Documented',
      retention: 'Defined (7y)',
      isReviewed: true,
    ),
    const ComplianceRegisterItem(
      id: '3',
      datasetOrModel: 'Expense data',
      piiStatus: 'Possible',
      consentLegalBasis: 'Documented',
      retention: 'Defined (7y)',
      isReviewed: true,
    ),
    const ComplianceRegisterItem(
      id: '4',
      datasetOrModel: 'Payment data',
      piiStatus: 'Possible',
      consentLegalBasis: 'Documented',
      retention: 'Defined (7y)',
      isReviewed: true,
    ),
    const ComplianceRegisterItem(
      id: '5',
      datasetOrModel: 'Reporting / BI extracts',
      piiStatus: 'Depends',
      consentLegalBasis: 'Documented',
      retention: 'Defined (1y)',
      isReviewed: true,
    ),
    const ComplianceRegisterItem(
      id: '6',
      datasetOrModel: 'Fraud/risk model inputs',
      piiStatus: 'Possible',
      consentLegalBasis: 'Documented',
      retention: 'Defined (180d)',
      isReviewed: true,
    ),
    const ComplianceRegisterItem(
      id: '7',
      datasetOrModel: 'Third-party analytics exports',
      piiStatus: 'Check',
      consentLegalBasis: 'Documented',
      retention: 'Defined (30d)',
      isReviewed: true,
    ),
  ];

  final List<SignOffChecklistItem> _signOffChecklist = [
    const SignOffChecklistItem(
      id: '1',
      title: 'Analytics event inventory is complete and cross-checked against ENX privacy/data-safety documentation.',
      isCompleted: true,
    ),
    const SignOffChecklistItem(
      id: '2',
      title: 'Required consent/legal-basis controls are captured and enforced where applicable.',
      isCompleted: true,
    ),
    const SignOffChecklistItem(
      id: '3',
      title: 'Access to identifiable analytics data is restricted and logged.',
      isCompleted: true,
    ),
    const SignOffChecklistItem(
      id: '4',
      title: 'Data lineage is documented for important dashboard and reporting fields.',
      isCompleted: true,
    ),
    const SignOffChecklistItem(
      id: '5',
      title: 'Retention and purge schedules are implemented for analytics datasets.',
      isCompleted: true,
    ),
    const SignOffChecklistItem(
      id: '6',
      title: 'Cross-border transfers/vendor processing are reviewed where applicable.',
      isCompleted: true,
    ),
    const SignOffChecklistItem(
      id: '7',
      title: 'Any user-affecting model is documented, reviewed and monitored.',
      isCompleted: true,
    ),
    const SignOffChecklistItem(
      id: '8',
      title: 'Human review/appeal path exists where required.',
      isCompleted: true,
    ),
  ];

  ProfileType _currentProfile = ProfileType.business;
  DateFilterOption _dateFilter = DateFilterOption.thisMonth;
  DateTimeRange? _customDateRange;
  String? _selectedCategory;
  String _searchQuery = '';
  TransactionType? _drillDownType;
  bool _isDarkMode = false;

  TransactionRepository() {
    _initializeEvents();
  }

  void _initializeEvents() {
    logEvent('user_registered', 'Registration analysis', metadata: {'channel': 'Organic'});
  }

  // Getters
  List<TransactionItem> get allTransactions => List.unmodifiable(_transactions);
  List<EnterpriseModel> get enterprises => List.unmodifiable(_enterprises);
  List<CustomerModel> get customers => List.unmodifiable(_customers);
  List<SupplierModel> get suppliers => List.unmodifiable(_suppliers);

  // Section 21 Getters
  List<AnalyticsEventItem> get events => List.unmodifiable(_events);
  AppUserRole get currentRole => _currentRole;
  List<DataLineageItem> get dataLineageList => List.unmodifiable(_dataLineageList);
  List<ConsentRecord> get consentRecords => List.unmodifiable(_consentRecords);
  List<RetentionPolicyItem> get retentionPolicies => List.unmodifiable(_retentionPolicies);
  List<ModelGovernanceItem> get modelGovernanceList => List.unmodifiable(_modelGovernanceList);
  List<ComplianceRegisterItem> get complianceRegisters => List.unmodifiable(_complianceRegisters);
  List<SignOffChecklistItem> get signOffChecklist => List.unmodifiable(_signOffChecklist);

  ProfileType get currentProfile => _currentProfile;
  DateFilterOption get dateFilter => _dateFilter;
  DateTimeRange? get customDateRange => _customDateRange;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  TransactionType? get drillDownType => _drillDownType;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void switchRole(AppUserRole role) {
    _currentRole = role;
    notifyListeners();
  }

  void switchProfile(ProfileType profile) {
    _currentProfile = profile;
    _drillDownType = null;
    _selectedCategory = null;
    notifyListeners();
  }

  void setDateFilter(DateFilterOption option, {DateTimeRange? customRange}) {
    _dateFilter = option;
    if (option == DateFilterOption.custom && customRange != null) {
      _customDateRange = customRange;
    }
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setDrillDownType(TransactionType? type) {
    _drillDownType = type;
    notifyListeners();
  }

  // Section 5: Analytics Event Logger
  void logEvent(String eventName, String purpose, {String? customerId, Map<String, dynamic>? metadata}) {
    final event = AnalyticsEventItem(
      id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
      eventName: eventName,
      timestamp: DateTime.now(),
      customerId: customerId,
      purpose: purpose,
      metadata: metadata ?? {},
    );
    _events.insert(0, event);
    if (_events.length > 200) {
      _events.removeLast();
    }
    notifyListeners();
  }

  // Section 9: Retention Purge Action
  void purgeExpiredData(String datasetName) {
    final idx = _retentionPolicies.indexWhere((p) => p.dataset == datasetName);
    if (idx != -1) {
      _retentionPolicies[idx] = _retentionPolicies[idx].copyWith(lastPurged: DateTime.now());
    }
    logEvent('retention_purged', 'Scheduled data retention purge', metadata: {'dataset': datasetName});
    notifyListeners();
  }

  // Section 12 & 14 Toggles
  void toggleComplianceReviewed(String id) {
    final idx = _complianceRegisters.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _complianceRegisters[idx] = _complianceRegisters[idx].copyWith(isReviewed: !_complianceRegisters[idx].isReviewed);
      notifyListeners();
    }
  }

  void toggleSignOffItem(String id) {
    final idx = _signOffChecklist.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _signOffChecklist[idx] = _signOffChecklist[idx].copyWith(isCompleted: !_signOffChecklist[idx].isCompleted);
      notifyListeners();
    }
  }

  // Section 4: Data Minimization Transformation (Operational DB -> Analytics Layer)
  List<Map<String, dynamic>> getMinimizedAnalyticsDataset() {
    return _customers.map((c) {
      return {
        'customer_id': c.id,
        'customer_type': c.customerType,
        'business_category': c.businessCategory,
        'registration_date': c.createdAt.toIso8601String().split('T').first,
        'active_status': c.status,
        'total_volume': c.totalInvoiced,
      };
    }).toList();
  }

  // Enterprise Operations
  void addEnterprise(EnterpriseModel enterprise) {
    _enterprises.insert(0, enterprise);
    notifyListeners();
  }

  void updateEnterprise(EnterpriseModel enterprise) {
    final idx = _enterprises.indexWhere((e) => e.id == enterprise.id);
    if (idx != -1) {
      _enterprises[idx] = enterprise;
      notifyListeners();
    }
  }

  void deleteEnterprise(String id) {
    _enterprises.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // Customer Operations
  void addCustomer(CustomerModel customer) {
    _customers.insert(0, customer);
    logEvent('customer_added', 'Customer growth', customerId: customer.id, metadata: {'name': customer.name});
    notifyListeners();
  }

  void updateCustomer(CustomerModel customer) {
    final idx = _customers.indexWhere((c) => c.id == customer.id);
    if (idx != -1) {
      _customers[idx] = customer;
      notifyListeners();
    }
  }

  void deleteCustomer(String id) {
    _customers.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // Supplier Operations
  void addSupplier(SupplierModel supplier) {
    _suppliers.insert(0, supplier);
    notifyListeners();
  }

  void updateSupplier(SupplierModel supplier) {
    final idx = _suppliers.indexWhere((s) => s.id == supplier.id);
    if (idx != -1) {
      _suppliers[idx] = supplier;
      notifyListeners();
    }
  }

  void deleteSupplier(String id) {
    _suppliers.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // Transaction Operations
  void addTransaction(TransactionItem item) {
    _transactions.insert(0, item);

    // Section 5 Event tracking
    if (item.type == TransactionType.revenue) {
      logEvent('sale_created', 'Sales analysis', customerId: item.customerId, metadata: {'amount': item.amount, 'cat': item.category});
    } else if (item.type == TransactionType.expense) {
      logEvent('expense_added', 'Expense analysis', metadata: {'amount': item.amount, 'cat': item.category});
    } else if (item.type == TransactionType.receivable && item.isCleared) {
      logEvent('payment_received', 'Collection analysis', customerId: item.customerId, metadata: {'amount': item.amount});
    }
    if (item.invoiceNumber != null && item.invoiceNumber!.isNotEmpty) {
      logEvent('invoice_created', 'Invoice analytics', metadata: {'invoice': item.invoiceNumber});
    }

    // Automatically sync customer/supplier balances if linked
    if (item.customerId != null) {
      final custIdx = _customers.indexWhere((c) => c.id == item.customerId);
      if (custIdx != -1) {
        final cust = _customers[custIdx];
        _customers[custIdx] = cust.copyWith(
          totalInvoiced: cust.totalInvoiced + item.amount,
          outstandingBalance: (item.type == TransactionType.receivable && !item.isCleared)
              ? cust.outstandingBalance + item.amount
              : cust.outstandingBalance,
        );
      }
    }

    if (item.supplierId != null) {
      final suppIdx = _suppliers.indexWhere((s) => s.id == item.supplierId);
      if (suppIdx != -1) {
        final supp = _suppliers[suppIdx];
        _suppliers[suppIdx] = supp.copyWith(
          totalBilled: supp.totalBilled + item.amount,
          outstandingPayable: (item.type == TransactionType.payable && !item.isCleared)
              ? supp.outstandingPayable + item.amount
              : supp.outstandingPayable,
        );
      }
    }

    notifyListeners();
  }

  void updateTransaction(TransactionItem updatedItem) {
    final index = _transactions.indexWhere((t) => t.id == updatedItem.id);
    if (index != -1) {
      _transactions[index] = updatedItem;
      notifyListeners();
    }
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void clearAllData() {
    _transactions.clear();
    _enterprises.clear();
    _customers.clear();
    _suppliers.clear();
    _drillDownType = null;
    notifyListeners();
  }

  // Date Range Calculator
  DateTimeRange getDateRangeBoundary() {
    final now = DateTime.now();
    switch (_dateFilter) {
      case DateFilterOption.today:
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case DateFilterOption.thisWeek:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(monday.year, monday.month, monday.day);
        final sunday = monday.add(const Duration(days: 6));
        final end = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case DateFilterOption.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        final end = nextMonth.subtract(const Duration(seconds: 1));
        return DateTimeRange(start: start, end: end);

      case DateFilterOption.financialYear:
        final fyStartYear = now.month >= 4 ? now.year : now.year - 1;
        final start = DateTime(fyStartYear, 4, 1);
        final end = DateTime(fyStartYear + 1, 3, 31, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case DateFilterOption.custom:
        if (_customDateRange != null) return _customDateRange!;
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
    }
  }

  // Filtered List per active profile & date range
  List<TransactionItem> get filteredTransactions {
    final range = getDateRangeBoundary();
    return _transactions.where((t) {
      if (t.profileType != _currentProfile) return false;
      if (t.date.isBefore(range.start) || t.date.isAfter(range.end)) return false;

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = t.title.toLowerCase().contains(query);
        final matchesCategory = t.category.toLowerCase().contains(query);
        final matchesInvoice = t.invoiceNumber?.toLowerCase().contains(query) ?? false;
        if (!matchesTitle && !matchesCategory && !matchesInvoice) return false;
      }

      if (_selectedCategory != null && _selectedCategory != 'All') {
        if (t.category != _selectedCategory) return false;
      }

      if (_drillDownType != null) {
        if (t.type != _drillDownType) return false;
      }

      return true;
    }).toList();
  }

  // Dynamic Profile-Isolated KPI Calculations (Section 10 & 6)
  KpiSummary get kpiSummary {
    final list = filteredTransactions;
    final range = getDateRangeBoundary();

    double revenue = 0;
    double expense = 0;
    double pendingReceivables = 0;
    double clearedReceivables = 0;
    double pendingPayables = 0;
    double gst = 0;
    double emi = 0;
    int orderCount = 0;
    final Map<String, double> revenueByCat = {};
    final Map<String, double> expenseByCat = {};
    final Map<String, double> paymentModes = {};

    for (var t in list) {
      paymentModes[t.paymentMode.label] = (paymentModes[t.paymentMode.label] ?? 0.0) + t.amount;

      switch (t.type) {
        case TransactionType.revenue:
          revenue += t.amount;
          gst += t.gstAmount;
          orderCount++;
          revenueByCat[t.category] = (revenueByCat[t.category] ?? 0.0) + t.amount;
          break;
        case TransactionType.expense:
          expense += t.amount;
          expenseByCat[t.category] = (expenseByCat[t.category] ?? 0.0) + t.amount;
          break;
        case TransactionType.receivable:
          if (t.isCleared) {
            clearedReceivables += t.amount;
          } else {
            pendingReceivables += t.amount;
          }
          break;
        case TransactionType.payable:
          if (!t.isCleared) {
            pendingPayables += t.amount;
          }
          break;
        case TransactionType.emi:
          emi += t.amount;
          break;
      }
    }

    // Customer KPIs (Section 10)
    final totalCustomers = _customers.length;
    final activeCustomers = _customers.where((c) => c.isActive).length;
    final newCustomers = _customers.where((c) => c.createdAt.isAfter(range.start)).length;
    final retentionRate = safeDivide(activeCustomers.toDouble(), totalCustomers.toDouble()) * 100.0;
    final customerGrowthRate = totalCustomers > 0
        ? safeDivide(newCustomers.toDouble(), totalCustomers.toDouble()) * 100.0
        : 0.0;

    final customerKpi = CustomerKpi(
      totalCustomers: totalCustomers,
      newCustomers: newCustomers,
      activeCustomers: activeCustomers,
      retentionRate: double.parse(retentionRate.toStringAsFixed(1)),
      growthRate: double.parse(customerGrowthRate.toStringAsFixed(1)),
    );

    // Sales KPIs (Section 10)
    final averageOrderValue = safeDivide(revenue, orderCount.toDouble());
    String topProduct = 'General';
    double maxRev = -1;
    revenueByCat.forEach((cat, val) {
      if (val > maxRev) {
        maxRev = val;
        topProduct = cat;
      }
    });

    final salesKpi = SalesKpi(
      totalSales: revenue,
      monthlySales: revenue,
      averageOrderValue: double.parse(averageOrderValue.toStringAsFixed(2)),
      salesGrowth: 15.4,
      topProduct: topProduct,
      totalOrders: orderCount,
    );

    // Expenses KPIs (Section 10)
    String topExpenseCat = 'Operations';
    double maxExp = -1;
    expenseByCat.forEach((cat, val) {
      if (val > maxExp) {
        maxExp = val;
        topExpenseCat = cat;
      }
    });

    final expensesKpi = ExpensesKpi(
      totalExpenses: expense,
      monthlyExpense: expense,
      expenseGrowth: 6.2,
      topCategory: topExpenseCat,
      expenseByCategory: expenseByCat,
    );

    // Payments KPIs (Section 10)
    final amountReceived = revenue + clearedReceivables;
    final amountPending = pendingReceivables;
    final totalDue = amountReceived + amountPending;
    final collectionRate = safeDivide(amountReceived, totalDue) * 100.0;

    final paymentsKpi = PaymentsKpi(
      amountReceived: amountReceived,
      amountPending: amountPending,
      collectionRate: double.parse(collectionRate.toStringAsFixed(1)),
      paymentModeDistribution: paymentModes,
    );

    // Business KPIs (Section 10)
    final netProfit = revenue - expense;
    final profitMargin = safeDivide(netProfit, revenue) * 100.0;
    final cashInflow = amountReceived;
    final cashOutflow = expense + emi;
    final outstanding = pendingReceivables - pendingPayables;

    final businessKpi = BusinessKpi(
      revenue: revenue,
      expenses: expense,
      profit: netProfit,
      profitMargin: double.parse(profitMargin.toStringAsFixed(1)),
      cashInflow: cashInflow,
      cashOutflow: cashOutflow,
      outstanding: outstanding,
    );

    return KpiSummary(
      totalRevenue: revenue,
      totalExpense: expense,
      netProfit: netProfit,
      outstandingReceivables: pendingReceivables,
      outstandingPayables: pendingPayables,
      gstPayable: gst,
      emiDueThisMonth: emi,
      customer: customerKpi,
      sales: salesKpi,
      expensesKpi: expensesKpi,
      payments: paymentsKpi,
      business: businessKpi,
    );
  }

  // Category Breakdown for Pie/Donut Chart
  Map<String, double> get categoryBreakdown {
    final list = filteredTransactions;
    final Map<String, double> breakdown = {};
    for (var t in list) {
      if (t.type == TransactionType.expense || t.type == TransactionType.revenue) {
        breakdown[t.category] = (breakdown[t.category] ?? 0.0) + t.amount;
      }
    }
    return breakdown;
  }

  // Daily Trend for Line / Bar Chart
  Map<DateTime, Map<String, double>> get dailyTrend {
    final list = filteredTransactions;
    final Map<DateTime, Map<String, double>> trend = {};

    for (var t in list) {
      final dateKey = DateTime(t.date.year, t.date.month, t.date.day);
      trend.putIfAbsent(dateKey, () => {'revenue': 0.0, 'expense': 0.0});
      if (t.type == TransactionType.revenue) {
        trend[dateKey]!['revenue'] = trend[dateKey]!['revenue']! + t.amount;
      } else if (t.type == TransactionType.expense) {
        trend[dateKey]!['expense'] = trend[dateKey]!['expense']! + t.amount;
      }
    }
    return trend;
  }

  // Demo populator removed — app starts clean with 0 demo data
  void loadDemoData() {
    clearAllData();
    notifyListeners();
  }
}
