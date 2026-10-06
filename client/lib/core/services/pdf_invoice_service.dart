import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/customers/models/customer_model.dart';
import '../../features/customers/models/ledger_entry_model.dart';
import '../../features/invoices/models/invoice_model.dart';
import '../../features/profile/data/profile_repository.dart';

class PdfInvoiceService {
  PdfInvoiceService._();

  static final NumberFormat _currencyFormat = NumberFormat('#,##,##0.00', 'en_IN');

  /// Helper to get real active user business details
  static Map<String, String?> _resolveBusinessDetails({String? customName, String? customGstin}) {
    final profile = ProfileRepository().profile;
    final bName = (customName != null && customName.trim().isNotEmpty)
        ? customName.trim()
        : (profile.businessProfile.businessName.trim().isNotEmpty
            ? profile.businessProfile.businessName.trim()
            : (profile.fullName.trim().isNotEmpty ? '${profile.fullName.trim()}\'s Enterprise' : 'ENX Money Enterprise'));

    final bGstin = (customGstin != null && customGstin.trim().isNotEmpty)
        ? customGstin.trim()
        : ((profile.businessProfile.gstin != null && profile.businessProfile.gstin!.trim().isNotEmpty)
            ? profile.businessProfile.gstin!.trim()
            : '36AAACK1234F1Z5');

    final bAddress = profile.businessProfile.businessAddress.trim().isNotEmpty
        ? profile.businessProfile.businessAddress.trim()
        : 'Telangana, India';

    final bPhone = profile.mobileNumber.trim().isNotEmpty
        ? profile.mobileNumber.trim()
        : null;

    return {
      'name': bName,
      'gstin': bGstin,
      'address': bAddress,
      'phone': bPhone,
    };
  }

  /// Generate raw PDF bytes for GST Tax Invoice with real user business data
  static Future<Uint8List> generateInvoicePdf(
    InvoiceModel invoice, {
    String? businessName,
    String? merchantGstin,
  }) async {
    final biz = _resolveBusinessDetails(customName: businessName, customGstin: merchantGstin);
    final bName = biz['name']!;
    final bGstin = biz['gstin']!;
    final bAddress = biz['address']!;
    final bPhone = biz['phone'];

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header & Merchant Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TAX INVOICE',
                          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(bName, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                        pw.Text('GSTIN: $bGstin', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.Text(bAddress, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        if (bPhone != null && bPhone.isNotEmpty)
                          pw.Text('Phone: $bPhone', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.teal50,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.teal400),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Invoice #: ${invoice.invoiceNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        pw.Text('Date: ${invoice.invoiceDate}', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text(
                          'Status: ${invoice.paymentStatus}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: invoice.paymentStatus == 'PAID' ? PdfColors.green800 : PdfColors.red800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 14),
              pw.Divider(color: PdfColors.grey400, thickness: 1),
              pw.SizedBox(height: 8),

              // Billed To Section
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BILLED TO (CUSTOMER):', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                        pw.SizedBox(height: 2),
                        pw.Text(invoice.customerName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        if (invoice.customerGstin.isNotEmpty)
                          pw.Text('GSTIN: ${invoice.customerGstin}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Place of Supply: ${invoice.isIntraState ? "Intra-State (CGST + SGST)" : "Inter-State (IGST)"}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // Table of Items
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.teal800),
                    children: [
                      _buildCell('#', isHeader: true, flex: 1),
                      _buildCell('Description', isHeader: true, flex: 4),
                      _buildCell('HSN', isHeader: true, flex: 2),
                      _buildCell('Qty', isHeader: true, flex: 1),
                      _buildCell('Rate', isHeader: true, flex: 2),
                      _buildCell('Taxable', isHeader: true, flex: 2),
                      _buildCell('GST %', isHeader: true, flex: 2),
                      _buildCell('Total (INR)', isHeader: true, flex: 2),
                    ],
                  ),
                  // Table Rows
                  ...invoice.items.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final itm = entry.value;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: idx.isEven ? PdfColors.grey50 : PdfColors.white),
                      children: [
                        _buildCell('$idx', flex: 1),
                        _buildCell(itm.description, flex: 4),
                        _buildCell(itm.hsnCode, flex: 2),
                        _buildCell('${itm.quantity}', flex: 1),
                        _buildCell('Rs. ${_currencyFormat.format(itm.unitPrice)}', flex: 2),
                        _buildCell('Rs. ${_currencyFormat.format(itm.taxableValue)}', flex: 2),
                        _buildCell('${itm.gstRate.toStringAsFixed(0)}%', flex: 2),
                        _buildCell('Rs. ${_currencyFormat.format(itm.total)}', flex: 2, isBold: true),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 12),

              // Summary Breakdown
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Terms and Notes
                  pw.Container(
                    width: 200,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Payment Terms:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                        pw.SizedBox(height: 2),
                        pw.Text('Payable on receipt via UPI / NEFT / RTGS.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
                        if (invoice.notes.isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Text('Note: ${invoice.notes}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        ],
                      ],
                    ),
                  ),

                  // Grand Total Summary Box
                  pw.Container(
                    width: 250,
                    child: pw.Column(
                      children: [
                        _buildSummaryRow('Taxable Subtotal:', 'Rs. ${_currencyFormat.format(invoice.taxableTotal)}'),
                        if (invoice.cgstTotal > 0)
                          _buildSummaryRow('CGST Total:', 'Rs. ${_currencyFormat.format(invoice.cgstTotal)}'),
                        if (invoice.sgstTotal > 0)
                          _buildSummaryRow('SGST Total:', 'Rs. ${_currencyFormat.format(invoice.sgstTotal)}'),
                        if (invoice.igstTotal > 0)
                          _buildSummaryRow('IGST Total:', 'Rs. ${_currencyFormat.format(invoice.igstTotal)}'),
                        pw.Divider(color: PdfColors.grey400),
                        _buildSummaryRow('Grand Total:', 'Rs. ${_currencyFormat.format(invoice.grandTotal)}', isGrandTotal: true),
                        _buildSummaryRow('Amount Paid:', 'Rs. ${_currencyFormat.format(invoice.amountPaid)}'),
                        _buildSummaryRow('Balance Due:', 'Rs. ${_currencyFormat.format(invoice.balanceDue)}', isDue: true),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Footer Note
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated securely via ENX Money Enterprise Cloud | GST Compliant', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text('Authorized Signatory', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Download and immediately open/share GST Tax Invoice PDF
  static Future<File?> downloadAndOpenInvoicePdf(
    InvoiceModel invoice, {
    BuildContext? context,
    String? businessName,
    String? merchantGstin,
  }) async {
    try {
      final bytes = await generateInvoicePdf(
        invoice,
        businessName: businessName,
        merchantGstin: merchantGstin,
      );

      final safeInvNum = invoice.invoiceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final filename = 'Invoice_$safeInvNum.pdf';

      final file = await _savePdfToStorage(bytes: bytes, filename: filename);

      if (context != null && context.mounted) {
        await _openOrSharePdf(
          context: context,
          file: file,
          bytes: bytes,
          title: 'Tax Invoice #$safeInvNum',
          subject: 'Tax Invoice from ${businessName ?? "ENX Money"}',
        );
      } else if (!kIsWeb) {
        await OpenFilex.open(file.path, type: 'application/pdf');
      }

      return file;
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Failed to download invoice: $e'),
          ),
        );
      }
      return null;
    }
  }

  /// Backward compatible Print / Preview for Tax Invoice
  static Future<void> generateAndPreviewInvoice(
    InvoiceModel invoice, {
    String? businessName,
    String? merchantGstin,
  }) async {
    final pdfBytes = await generateInvoicePdf(invoice, businessName: businessName, merchantGstin: merchantGstin);
    final safeInvNum = invoice.invoiceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Invoice_$safeInvNum.pdf',
    );
  }

  /// Generate raw PDF bytes for Customer Statement / Khata Book Statement
  static Future<Uint8List> generateCustomerStatementPdf(
    CustomerModel customer,
    List<LedgerEntryModel> ledger, {
    String? businessName,
  }) async {
    final biz = _resolveBusinessDetails(customName: businessName);
    final bName = biz['name']!;
    final bPhone = biz['phone'];

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          final isDue = customer.currentBalance > 0;
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('CUSTOMER ACCOUNT STATEMENT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                        pw.SizedBox(height: 2),
                        pw.Text(bName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        if (bPhone != null && bPhone.isNotEmpty)
                          pw.Text('Contact: $bPhone', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        pw.Text('Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(6)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Customer: ${customer.name}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        pw.Text('Phone: ${customer.phone}', style: const pw.TextStyle(fontSize: 10)),
                        if (customer.gstin.isNotEmpty)
                          pw.Text('GSTIN: ${customer.gstin}', style: const pw.TextStyle(fontSize: 9)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Current Balance: Rs. ${_currencyFormat.format(customer.currentBalance.abs())} ${isDue ? "DUE" : "SETTLED"}',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                            color: isDue ? PdfColors.red800 : PdfColors.green800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),

              // Table of Transactions
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.teal800),
                    children: [
                      _buildCell('Date', isHeader: true, flex: 2),
                      _buildCell('Description', isHeader: true, flex: 4),
                      _buildCell('Payment Mode', isHeader: true, flex: 2),
                      _buildCell('Gave (Sale)', isHeader: true, flex: 2),
                      _buildCell('Got (Payment)', isHeader: true, flex: 2),
                      _buildCell('Balance (INR)', isHeader: true, flex: 2),
                    ],
                  ),
                  ...ledger.map((e) {
                    final isGave = e.entryType == 'GAVE';
                    return pw.TableRow(
                      children: [
                        _buildCell(e.entryDate.isNotEmpty ? e.entryDate : 'Today', flex: 2),
                        _buildCell(e.description.isNotEmpty ? e.description : (isGave ? 'Sale' : 'Payment'), flex: 4),
                        _buildCell(e.paymentMode, flex: 2),
                        _buildCell(isGave ? 'Rs. ${_currencyFormat.format(e.amount)}' : '-', flex: 2, isBold: isGave),
                        _buildCell(!isGave ? 'Rs. ${_currencyFormat.format(e.amount)}' : '-', flex: 2, isBold: !isGave),
                        _buildCell('Rs. ${_currencyFormat.format(e.balanceAfter)}', flex: 2, isBold: true),
                      ],
                    );
                  }),
                ],
              ),

              pw.Spacer(),

              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated securely via ENX Money Enterprise Cloud', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text('Authorized Signatory', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Download and open/share customer statement PDF
  static Future<File?> downloadAndOpenCustomerStatement(
    CustomerModel customer,
    List<LedgerEntryModel> ledger, {
    BuildContext? context,
    String? businessName,
  }) async {
    try {
      final bytes = await generateCustomerStatementPdf(
        customer,
        ledger,
        businessName: businessName,
      );

      final safeName = customer.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final filename = 'Statement_$safeName.pdf';

      final file = await _savePdfToStorage(bytes: bytes, filename: filename);

      if (context != null && context.mounted) {
        await _openOrSharePdf(
          context: context,
          file: file,
          bytes: bytes,
          title: 'Account Statement - ${customer.name}',
          subject: 'Statement of Account for ${customer.name}',
        );
      } else if (!kIsWeb) {
        await OpenFilex.open(file.path, type: 'application/pdf');
      }

      return file;
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Failed to download statement: $e'),
          ),
        );
      }
      return null;
    }
  }

  /// Backward compatible Print / Preview for Customer Statement
  static Future<void> generateCustomerStatement(
    CustomerModel customer,
    List<LedgerEntryModel> ledger, {
    String? businessName,
  }) async {
    final bytes = await generateCustomerStatementPdf(customer, ledger, businessName: businessName);
    final safeName = customer.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Statement_$safeName.pdf',
    );
  }

  /// Saves PDF bytes to Android / Local storage cleanly without corruption
  static Future<File> _savePdfToStorage({
    required Uint8List bytes,
    required String filename,
  }) async {
    if (kIsWeb) {
      // In web, write to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    }

    // 1. On Android, attempt writing directly to standard public Downloads folder
    if (Platform.isAndroid) {
      try {
        final publicDownloadDir = Directory('/storage/emulated/0/Download');
        if (await publicDownloadDir.exists()) {
          final targetFile = File('${publicDownloadDir.path}/$filename');
          await targetFile.writeAsBytes(bytes, flush: true);
          return targetFile;
        }
      } catch (_) {
        // Scoped storage restricted - fall through to app external download directory
      }

      try {
        final extDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        if (extDirs != null && extDirs.isNotEmpty) {
          final targetFile = File('${extDirs.first.path}/$filename');
          await targetFile.writeAsBytes(bytes, flush: true);
          return targetFile;
        }
      } catch (_) {}
    }

    // 2. Default app documents directory fallback
    final docsDir = await getApplicationDocumentsDirectory();
    final targetFile = File('${docsDir.path}/$filename');
    await targetFile.writeAsBytes(bytes, flush: true);
    return targetFile;
  }

  /// Opens or offers quick sharing for the downloaded PDF
  static Future<void> _openOrSharePdf({
    required BuildContext context,
    required File file,
    required Uint8List bytes,
    required String title,
    required String subject,
  }) async {
    // Attempt instant opening via OpenFilex
    if (!kIsWeb) {
      try {
        final result = await OpenFilex.open(file.path, type: 'application/pdf');
        if (result.type == ResultType.done) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF00E676),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                content: Text(
                  'Saved: ${file.path.split(Platform.pathSeparator).last}',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                action: SnackBarAction(
                  label: 'Share',
                  textColor: Colors.black87,
                  onPressed: () => Share.shareXFiles([XFile(file.path)], subject: subject),
                ),
              ),
            );
          }
          return;
        }
      } catch (_) {}
    }

    // If viewer didn't open immediately, show action bottom sheet
    if (context.mounted) {
      _showPdfActionSheet(
        context,
        file: file,
        bytes: bytes,
        title: title,
        subject: subject,
      );
    }
  }

  /// Displays an interactive action sheet for downloaded PDF
  static void _showPdfActionSheet(
    BuildContext context, {
    required File file,
    required Uint8List bytes,
    required String title,
    required String subject,
  }) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141824) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BCD4).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF00BCD4), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Saved: $fileName',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    // Open in PDF Viewer
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                        label: const Text('Open PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await OpenFilex.open(file.path, type: 'application/pdf');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Share File
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                          side: BorderSide(color: isDark ? const Color(0xFF2A3447) : const Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await Share.shareXFiles([XFile(file.path)], subject: subject);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Print Document
                    IconButton(
                      icon: const Icon(Icons.print_outlined, color: Color(0xFF00BCD4)),
                      tooltip: 'Print',
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await Printing.layoutPdf(
                          onLayout: (PdfPageFormat format) async => bytes,
                          name: fileName,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static pw.Widget _buildCell(String text, {bool isHeader = false, bool isBold = false, int flex = 1}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      alignment: isHeader ? pw.Alignment.center : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value, {bool isGrandTotal = false, bool isDue = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: isGrandTotal ? 11 : 9.5, fontWeight: isGrandTotal ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isGrandTotal ? 12 : 10,
              fontWeight: isGrandTotal || isDue ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isDue ? PdfColors.red800 : (isGrandTotal ? PdfColors.teal800 : PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }
}
