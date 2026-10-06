import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/kpi_summary.dart';
import '../../domain/models/transaction_item.dart';

class PdfExporter {
  static Future<Uint8List> generateFinancialReportPdf({
    required ProfileType profile,
    required DateFilterOption dateFilter,
    required KpiSummary kpi,
    required List<TransactionItem> transactions,
  }) async {
    final pdf = pw.Document();
    final currencyFormatter = NumberFormat.currency(symbol: 'INR ', decimalDigits: 2);
    final dateFormatter = DateFormat('dd MMM yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 20.0),
            padding: const pw.EdgeInsets.only(bottom: 10.0),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.indigo600, width: 2)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'ENX MONEY FINANCIAL REPORT',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo800,
                      ),
                    ),
                    pw.Text(
                      'Profile: ${profile.label.toUpperCase()} | Range: ${dateFilter.label}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Text(
                  'Generated: ${dateFormatter.format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20.0),
            padding: const pw.EdgeInsets.only(top: 10.0),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 1)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('ENX Money - Expense & Business Management App',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Executive KPI Summary Grid
            pw.Text(
              '1. Executive Summary & Dashboard KPIs',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
                  children: [
                    _buildTableCell('KPI Metric', isHeader: true),
                    _buildTableCell('Amount (INR)', isHeader: true),
                    _buildTableCell('Status / Notes', isHeader: true),
                  ],
                ),
                pw.TableRow(children: [
                  _buildTableCell('Total Revenue / Income'),
                  _buildTableCell(currencyFormatter.format(kpi.totalRevenue), color: PdfColors.green700),
                  _buildTableCell('Gross Inflow'),
                ]),
                pw.TableRow(children: [
                  _buildTableCell('Total Expense / Outflow'),
                  _buildTableCell(currencyFormatter.format(kpi.totalExpense), color: PdfColors.red700),
                  _buildTableCell('Operating Outflow'),
                ]),
                pw.TableRow(children: [
                  _buildTableCell('Net Profit / Balance'),
                  _buildTableCell(currencyFormatter.format(kpi.netProfit),
                      color: kpi.netProfit >= 0 ? PdfColors.green800 : PdfColors.red800, isBold: true),
                  _buildTableCell(kpi.netProfit >= 0 ? 'Surplus' : 'Deficit'),
                ]),
                pw.TableRow(children: [
                  _buildTableCell('Outstanding Receivables'),
                  _buildTableCell(currencyFormatter.format(kpi.outstandingReceivables), color: PdfColors.blue700),
                  _buildTableCell('Pending Inward'),
                ]),
                pw.TableRow(children: [
                  _buildTableCell('Outstanding Payables'),
                  _buildTableCell(currencyFormatter.format(kpi.outstandingPayables), color: PdfColors.orange700),
                  _buildTableCell('Pending Vendor Payment'),
                ]),
                pw.TableRow(children: [
                  _buildTableCell('GST Payable (Est.)'),
                  _buildTableCell(currencyFormatter.format(kpi.gstPayable), color: PdfColors.purple700),
                  _buildTableCell('Tax Liability'),
                ]),
                pw.TableRow(children: [
                  _buildTableCell('EMI Due This Month'),
                  _buildTableCell(currencyFormatter.format(kpi.emiDueThisMonth), color: PdfColors.red900),
                  _buildTableCell('Scheduled Payment'),
                ]),
              ],
            ),
            pw.SizedBox(height: 20),

            // Detailed Transaction Ledger Table
            pw.Text(
              '2. Transaction Ledger (${transactions.length} Records)',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
            ),
            pw.SizedBox(height: 10),
            if (transactions.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                alignment: pw.Alignment.center,
                child: pw.Text('No transactions found for the selected period.',
                    style: const pw.TextStyle(color: PdfColors.grey600)),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.2), // Date
                  1: const pw.FlexColumnWidth(2.5), // Title
                  2: const pw.FlexColumnWidth(1.5), // Category
                  3: const pw.FlexColumnWidth(1.5), // Type
                  4: const pw.FlexColumnWidth(1.8), // Amount
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('Date', isHeader: true),
                      _buildTableCell('Description / Invoice', isHeader: true),
                      _buildTableCell('Category', isHeader: true),
                      _buildTableCell('Type', isHeader: true),
                      _buildTableCell('Amount', isHeader: true),
                    ],
                  ),
                  ...transactions.map((t) {
                    final isPositive = t.type == TransactionType.revenue || t.type == TransactionType.receivable;
                    return pw.TableRow(
                      children: [
                        _buildTableCell(dateFormatter.format(t.date)),
                        _buildTableCell(t.invoiceNumber != null ? '${t.title}\n(${t.invoiceNumber})' : t.title),
                        _buildTableCell(t.category),
                        _buildTableCell(t.type.label),
                        _buildTableCell(
                          '${isPositive ? '+' : '-'} ${currencyFormatter.format(t.amount)}',
                          color: isPositive ? PdfColors.green700 : PdfColors.red700,
                        ),
                      ],
                    );
                  }),
                ],
              ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTableCell(String text,
      {bool isHeader = false, PdfColor? color, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.black : PdfColors.grey900),
        ),
      ),
    );
  }

  static Future<void> sharePdfReport({
    required ProfileType profile,
    required DateFilterOption dateFilter,
    required KpiSummary kpi,
    required List<TransactionItem> transactions,
  }) async {
    final pdfBytes = await generateFinancialReportPdf(
      profile: profile,
      dateFilter: dateFilter,
      kpi: kpi,
      transactions: transactions,
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'ENX_Money_Report_${profile.name}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }
}
