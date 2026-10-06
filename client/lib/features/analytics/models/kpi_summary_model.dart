class KpiSummary {
  final double totalRevenue;
  final double totalExpense;
  final double netProfit;
  final double outstandingReceivables;
  final double outstandingPayables;
  final double gstPayable;
  final double emiDueThisMonth;
  final double inventoryValue;
  final double totalSales;
  final double totalPurchases;
  final double collectionRate;

  const KpiSummary({
    required this.totalRevenue,
    required this.totalExpense,
    required this.netProfit,
    required this.outstandingReceivables,
    required this.outstandingPayables,
    required this.gstPayable,
    required this.emiDueThisMonth,
    this.inventoryValue = 0.0,
    this.totalSales = 0.0,
    this.totalPurchases = 0.0,
    this.collectionRate = 0.0,
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
      inventoryValue: 0.0,
      totalSales: 0.0,
      totalPurchases: 0.0,
      collectionRate: 0.0,
    );
  }

  factory KpiSummary.fromJson(Map<String, dynamic> json) {
    return KpiSummary(
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (json['totalExpense'] as num?)?.toDouble() ?? 0.0,
      netProfit: (json['netProfit'] as num?)?.toDouble() ?? 0.0,
      outstandingReceivables: (json['outstandingReceivables'] as num?)?.toDouble() ?? 0.0,
      outstandingPayables: (json['outstandingPayables'] as num?)?.toDouble() ?? 0.0,
      gstPayable: (json['gstPayable'] as num?)?.toDouble() ?? 0.0,
      emiDueThisMonth: (json['emiDueThisMonth'] as num?)?.toDouble() ?? 0.0,
      inventoryValue: (json['inventoryValue'] as num?)?.toDouble() ??
          (json['total_inventory_valuation'] as num?)?.toDouble() ??
          (json['totalCostValuation'] as num?)?.toDouble() ??
          0.0,
      totalSales: (json['totalSales'] as num?)?.toDouble() ?? (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalPurchases: (json['totalPurchases'] as num?)?.toDouble() ?? 0.0,
      collectionRate: (json['collectionRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRevenue': totalRevenue,
      'totalExpense': totalExpense,
      'netProfit': netProfit,
      'outstandingReceivables': outstandingReceivables,
      'outstandingPayables': outstandingPayables,
      'gstPayable': gstPayable,
      'emiDueThisMonth': emiDueThisMonth,
      'inventoryValue': inventoryValue,
      'totalSales': totalSales,
      'totalPurchases': totalPurchases,
      'collectionRate': collectionRate,
    };
  }
}
