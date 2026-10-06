import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/kpi_summary.dart';
import '../../domain/models/transaction_item.dart';
import '../../domain/models/customer_model.dart';

class ExcelExporter {
  static Future<String?> exportToExcel({
    required ProfileType profile,
    required DateFilterOption dateFilter,
    required KpiSummary kpi,
    required List<TransactionItem> transactions,
  }) async {
    final excel = Excel.createExcel();
    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm');

    excel.rename('Sheet1', 'KPI Dashboard Summary');
    final Sheet summarySheet = excel['KPI Dashboard Summary'];

    summarySheet.appendRow([TextCellValue('ENX Money - Financial Summary Report')]);
    summarySheet.appendRow([TextCellValue('Profile: ${profile.label}')]);
    summarySheet.appendRow([TextCellValue('Date Filter: ${dateFilter.label}')]);
    summarySheet.appendRow([TextCellValue('Export Date: ${dateFormatter.format(DateTime.now())}')]);
    summarySheet.appendRow([TextCellValue('')]);

    summarySheet.appendRow([
      TextCellValue('Metric Name'),
      TextCellValue('Value (INR)'),
      TextCellValue('Category Type'),
    ]);

    summarySheet.appendRow([TextCellValue('Total Revenue'), DoubleCellValue(kpi.totalRevenue), TextCellValue('Inflow')]);
    summarySheet.appendRow([TextCellValue('Total Expense'), DoubleCellValue(kpi.totalExpense), TextCellValue('Outflow')]);
    summarySheet.appendRow([TextCellValue('Net Profit / Balance'), DoubleCellValue(kpi.netProfit), TextCellValue('Surplus/Deficit')]);
    summarySheet.appendRow([TextCellValue('Outstanding Receivables'), DoubleCellValue(kpi.outstandingReceivables), TextCellValue('Pending Revenue')]);
    summarySheet.appendRow([TextCellValue('Outstanding Payables'), DoubleCellValue(kpi.outstandingPayables), TextCellValue('Pending Expense')]);
    summarySheet.appendRow([TextCellValue('GST Payable (Est.)'), DoubleCellValue(kpi.gstPayable), TextCellValue('Tax Liability')]);
    summarySheet.appendRow([TextCellValue('EMI Due This Month'), DoubleCellValue(kpi.emiDueThisMonth), TextCellValue('Loan Obligation')]);

    final Sheet ledgerSheet = excel['Transaction Ledger'];

    ledgerSheet.appendRow([
      TextCellValue('Transaction ID'),
      TextCellValue('Date'),
      TextCellValue('Profile'),
      TextCellValue('Type'),
      TextCellValue('Title / Description'),
      TextCellValue('Category'),
      TextCellValue('Amount (INR)'),
      TextCellValue('Payment Mode'),
      TextCellValue('GST %'),
      TextCellValue('GST Amount (INR)'),
      TextCellValue('Total Incl. GST'),
      TextCellValue('Invoice Number'),
      TextCellValue('Notes'),
    ]);

    for (var t in transactions) {
      ledgerSheet.appendRow([
        TextCellValue(t.id),
        TextCellValue(dateFormatter.format(t.date)),
        TextCellValue(t.profileType.name),
        TextCellValue(t.type.label),
        TextCellValue(t.title),
        TextCellValue(t.category),
        DoubleCellValue(t.amount),
        TextCellValue(t.paymentMode.label),
        DoubleCellValue(t.gstRate),
        DoubleCellValue(t.gstAmount),
        DoubleCellValue(t.totalWithGst),
        TextCellValue(t.invoiceNumber ?? '-'),
        TextCellValue(t.notes ?? ''),
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes == null) return null;

    final tempDir = await getTemporaryDirectory();
    final fileName = 'ENX_Money_Export_${profile.name}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    final filePath = '${tempDir.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(fileBytes);

    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'ENX Money Excel Financial Export',
      text: 'Here is your exported financial statement from ENX Money.',
    );

    return filePath;
  }

  // Specialized Customer Management Excel Exporter
  static Future<String?> exportCustomerManagementExcel({
    required CustomerModel customer,
    required List<TransactionItem> customerTransactions,
  }) async {
    final excel = Excel.createExcel();
    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm');

    excel.rename('Sheet1', 'Customer Summary');
    final Sheet profileSheet = excel['Customer Summary'];

    profileSheet.appendRow([TextCellValue('CUSTOMER MANAGEMENT LEDGER STATEMENT')]);
    profileSheet.appendRow([TextCellValue('Customer Name: ${customer.name}')]);
    profileSheet.appendRow([TextCellValue('Company: ${customer.companyName ?? "-"}')]);
    profileSheet.appendRow([TextCellValue('Phone: ${customer.phone ?? "-"} | Email: ${customer.email ?? "-"}')]);
    profileSheet.appendRow([TextCellValue('Total Invoiced (INR): ₹${customer.totalInvoiced}')]);
    profileSheet.appendRow([TextCellValue('Outstanding Balance (INR): ₹${customer.outstandingBalance}')]);
    profileSheet.appendRow([TextCellValue('Generated Date: ${dateFormatter.format(DateTime.now())}')]);
    profileSheet.appendRow([TextCellValue('')]);

    final Sheet ledgerSheet = excel['Customer Ledger'];
    ledgerSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Invoice / Reference'),
      TextCellValue('Description'),
      TextCellValue('Category'),
      TextCellValue('Amount (INR)'),
      TextCellValue('GST %'),
      TextCellValue('GST Amount'),
      TextCellValue('Payment Mode'),
      TextCellValue('Notes'),
    ]);

    for (var t in customerTransactions) {
      ledgerSheet.appendRow([
        TextCellValue(dateFormatter.format(t.date)),
        TextCellValue(t.invoiceNumber ?? '-'),
        TextCellValue(t.title),
        TextCellValue(t.category),
        DoubleCellValue(t.amount),
        DoubleCellValue(t.gstRate),
        DoubleCellValue(t.gstAmount),
        TextCellValue(t.paymentMode.label),
        TextCellValue(t.notes ?? ''),
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes == null) return null;

    final tempDir = await getTemporaryDirectory();
    final fileName = 'Customer_Statement_${customer.name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
    final filePath = '${tempDir.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(fileBytes);

    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'Customer Statement - ${customer.name}',
      text: 'Exported customer ledger and invoice statement for ${customer.name}.',
    );

    return filePath;
  }
}
