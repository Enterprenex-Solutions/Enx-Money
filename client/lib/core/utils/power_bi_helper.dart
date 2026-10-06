import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/kpi_summary.dart';
import '../../domain/models/transaction_item.dart';

class PowerBiHelper {
  // 1. Generates Power BI REST API Push Dataset Schema Definition
  static Map<String, dynamic> generatePowerBiDatasetSchema() {
    return {
      "name": "ENX_Money_Financial_Dataset",
      "defaultMode": "Push",
      "tables": [
        {
          "name": "KPI_Summaries",
          "columns": [
            {"name": "Profile", "dataType": "string"},
            {"name": "DateFilter", "dataType": "string"},
            {"name": "TotalRevenue", "dataType": "Double"},
            {"name": "TotalExpense", "dataType": "Double"},
            {"name": "NetProfit", "dataType": "Double"},
            {"name": "ProfitMargin", "dataType": "Double"},
            {"name": "CashInflow", "dataType": "Double"},
            {"name": "CashOutflow", "dataType": "Double"},
            {"name": "CollectionRate", "dataType": "Double"},
            {"name": "TotalCustomers", "dataType": "Int64"},
            {"name": "ActiveCustomers", "dataType": "Int64"},
            {"name": "AverageOrderValue", "dataType": "Double"},
            {"name": "OutstandingReceivables", "dataType": "Double"},
            {"name": "OutstandingPayables", "dataType": "Double"},
            {"name": "GstPayable", "dataType": "Double"},
            {"name": "EmiDueThisMonth", "dataType": "Double"},
            {"name": "LastUpdated", "dataType": "DateTime"}
          ]
        },
        {
          "name": "Transactions",
          "columns": [
            {"name": "TransactionID", "dataType": "string"},
            {"name": "Date", "dataType": "DateTime"},
            {"name": "ProfileType", "dataType": "string"},
            {"name": "TransactionType", "dataType": "string"},
            {"name": "Title", "dataType": "string"},
            {"name": "Category", "dataType": "string"},
            {"name": "AmountINR", "dataType": "Double"},
            {"name": "PaymentMode", "dataType": "string"},
            {"name": "GstRatePercent", "dataType": "Double"},
            {"name": "GstAmountINR", "dataType": "Double"},
            {"name": "InvoiceNumber", "dataType": "string"},
            {"name": "IsCleared", "dataType": "Int64"}
          ]
        }
      ]
    };
  }

  // 2. Generates Power BI Rows Push API Payload for current filtered data
  static Map<String, dynamic> generatePowerBiPushPayload({
    required ProfileType profile,
    required DateFilterOption dateFilter,
    required KpiSummary kpi,
    required List<TransactionItem> transactions,
  }) {
    final dateFormatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");

    final rows = transactions.map((t) {
      return {
        "TransactionID": t.id,
        "Date": dateFormatter.format(t.date),
        "ProfileType": t.profileType.name,
        "TransactionType": t.type.name,
        "Title": t.title,
        "Category": t.category,
        "AmountINR": t.amount,
        "PaymentMode": t.paymentMode.name,
        "GstRatePercent": t.gstRate,
        "GstAmountINR": t.gstAmount,
        "InvoiceNumber": t.invoiceNumber ?? "",
        "IsCleared": t.isCleared ? 1 : 0,
      };
    }).toList();

    return {
      "kpiSummary": {
        "Profile": profile.name,
        "DateFilter": dateFilter.name,
        "TotalRevenue": kpi.totalRevenue,
        "TotalExpense": kpi.totalExpense,
        "NetProfit": kpi.netProfit,
        "ProfitMargin": kpi.business.profitMargin,
        "CashInflow": kpi.business.cashInflow,
        "CashOutflow": kpi.business.cashOutflow,
        "CollectionRate": kpi.payments.collectionRate,
        "TotalCustomers": kpi.customer.totalCustomers,
        "ActiveCustomers": kpi.customer.activeCustomers,
        "AverageOrderValue": kpi.sales.averageOrderValue,
        "OutstandingReceivables": kpi.outstandingReceivables,
        "OutstandingPayables": kpi.outstandingPayables,
        "GstPayable": kpi.gstPayable,
        "EmiDueThisMonth": kpi.emiDueThisMonth,
        "LastUpdated": dateFormatter.format(DateTime.now()),
      },
      "rows": rows,
    };
  }

  // 3. Export Power BI Payload JSON file to device
  static Future<String?> exportPowerBiJsonPayload({
    required ProfileType profile,
    required DateFilterOption dateFilter,
    required KpiSummary kpi,
    required List<TransactionItem> transactions,
  }) async {
    final payload = generatePowerBiPushPayload(
      profile: profile,
      dateFilter: dateFilter,
      kpi: kpi,
      transactions: transactions,
    );

    final jsonString = const JsonEncoder.withIndent('  ').convert(payload);
    final tempDir = await getTemporaryDirectory();
    final fileName = 'ENX_Money_PowerBI_Payload_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
    final filePath = '${tempDir.path}/$fileName';

    final file = File(filePath);
    await file.writeAsString(jsonString);

    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'ENX Money Power BI Push Payload',
      text: 'Import this JSON directly into your Power BI Streaming Dataset endpoint or Azure Data Factory pipeline.',
    );

    return filePath;
  }
}
