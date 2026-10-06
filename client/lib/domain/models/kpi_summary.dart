/// Helper to avoid Division by Zero and NaN/Infinite rendering crashes
double safeDivide(double numerator, double denominator, [double fallback = 0.0]) {
  if (denominator == 0.0 || denominator.isNaN || numerator.isNaN) return fallback;
  final res = numerator / denominator;
  return (res.isInfinite || res.isNaN) ? fallback : res;
}

/// Area 1: Customer KPIs (Section 10)
class CustomerKpi {
  final int totalCustomers;
  final int newCustomers;
  final int activeCustomers;
  final double retentionRate; // percentage e.g. 85.0%
  final double growthRate; // percentage e.g. 12.5%

  const CustomerKpi({
    this.totalCustomers = 0,
    this.newCustomers = 0,
    this.activeCustomers = 0,
    this.retentionRate = 0.0,
    this.growthRate = 0.0,
  });

  factory CustomerKpi.empty() => const CustomerKpi();

  Map<String, dynamic> toJson() => {
    'totalCustomers': totalCustomers,
    'newCustomers': newCustomers,
    'activeCustomers': activeCustomers,
    'retentionRate': retentionRate,
    'growthRate': growthRate,
  };
}

/// Area 2: Sales KPIs (Section 10)
class SalesKpi {
  final double totalSales;
  final double monthlySales;
  final double averageOrderValue;
  final double salesGrowth;
  final String topProduct;
  final int totalOrders;

  const SalesKpi({
    this.totalSales = 0.0,
    this.monthlySales = 0.0,
    this.averageOrderValue = 0.0,
    this.salesGrowth = 0.0,
    this.topProduct = 'N/A',
    this.totalOrders = 0,
  });

  factory SalesKpi.empty() => const SalesKpi();

  Map<String, dynamic> toJson() => {
    'totalSales': totalSales,
    'monthlySales': monthlySales,
    'averageOrderValue': averageOrderValue,
    'salesGrowth': salesGrowth,
    'topProduct': topProduct,
    'totalOrders': totalOrders,
  };
}

/// Area 3: Expenses KPIs (Section 10)
class ExpensesKpi {
  final double totalExpenses;
  final double monthlyExpense;
  final double expenseGrowth;
  final String topCategory;
  final Map<String, double> expenseByCategory;

  const ExpensesKpi({
    this.totalExpenses = 0.0,
    this.monthlyExpense = 0.0,
    this.expenseGrowth = 0.0,
    this.topCategory = 'N/A',
    this.expenseByCategory = const {},
  });

  factory ExpensesKpi.empty() => const ExpensesKpi();

  Map<String, dynamic> toJson() => {
    'totalExpenses': totalExpenses,
    'monthlyExpense': monthlyExpense,
    'expenseGrowth': expenseGrowth,
    'topCategory': topCategory,
    'expenseByCategory': expenseByCategory,
  };
}

/// Area 4: Payments KPIs (Section 10)
class PaymentsKpi {
  final double amountReceived;
  final double amountPending;
  final double collectionRate; // percentage (received / due * 100)
  final Map<String, double> paymentModeDistribution;

  const PaymentsKpi({
    this.amountReceived = 0.0,
    this.amountPending = 0.0,
    this.collectionRate = 0.0,
    this.paymentModeDistribution = const {},
  });

  factory PaymentsKpi.empty() => const PaymentsKpi();

  Map<String, dynamic> toJson() => {
    'amountReceived': amountReceived,
    'amountPending': amountPending,
    'collectionRate': collectionRate,
    'paymentModeDistribution': paymentModeDistribution,
  };
}

/// Area 5: Business KPIs (Section 10)
class BusinessKpi {
  final double revenue;
  final double expenses;
  final double profit;
  final double profitMargin; // percentage (profit / revenue * 100)
  final double cashInflow;
  final double cashOutflow;
  final double outstanding;

  const BusinessKpi({
    this.revenue = 0.0,
    this.expenses = 0.0,
    this.profit = 0.0,
    this.profitMargin = 0.0,
    this.cashInflow = 0.0,
    this.cashOutflow = 0.0,
    this.outstanding = 0.0,
  });

  factory BusinessKpi.empty() => const BusinessKpi();

  Map<String, dynamic> toJson() => {
    'revenue': revenue,
    'expenses': expenses,
    'profit': profit,
    'profitMargin': profitMargin,
    'cashInflow': cashInflow,
    'cashOutflow': cashOutflow,
    'outstanding': outstanding,
  };
}

/// Unified KPI Summary representing Section 10 ENX Money Dashboard KPIs
class KpiSummary {
  final CustomerKpi customer;
  final SalesKpi sales;
  final ExpensesKpi expensesKpi;
  final PaymentsKpi payments;
  final BusinessKpi business;

  final double totalRevenue;
  final double totalExpense;
  final double netProfit;
  final double outstandingReceivables;
  final double outstandingPayables;
  final double gstPayable;
  final double emiDueThisMonth;

  const KpiSummary({
    required this.totalRevenue,
    required this.totalExpense,
    required this.netProfit,
    required this.outstandingReceivables,
    required this.outstandingPayables,
    required this.gstPayable,
    required this.emiDueThisMonth,
    this.customer = const CustomerKpi(),
    this.sales = const SalesKpi(),
    this.expensesKpi = const ExpensesKpi(),
    this.payments = const PaymentsKpi(),
    this.business = const BusinessKpi(),
  });

  factory KpiSummary.empty() {
    return const KpiSummary(
      totalRevenue: 0.0,
      totalExpense: 0.0,
      netProfit: 0.0,
      outstandingReceivables: 0.0,
      outstandingPayables: 0.0,
      gstPayable: 0.0,
      emiDueThisMonth: 0.0,
      customer: CustomerKpi(),
      sales: SalesKpi(),
      expensesKpi: ExpensesKpi(),
      payments: PaymentsKpi(),
      business: BusinessKpi(),
    );
  }

  Map<String, dynamic> toJson() => {
    'totalRevenue': totalRevenue,
    'totalExpense': totalExpense,
    'netProfit': netProfit,
    'outstandingReceivables': outstandingReceivables,
    'outstandingPayables': outstandingPayables,
    'gstPayable': gstPayable,
    'emiDueThisMonth': emiDueThisMonth,
    'customer': customer.toJson(),
    'sales': sales.toJson(),
    'expenses': expensesKpi.toJson(),
    'payments': payments.toJson(),
    'business': business.toJson(),
  };
}
