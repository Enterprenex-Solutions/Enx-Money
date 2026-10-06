import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/invoice_model.dart';
import '../../models/subscription_model.dart';

class SubscriptionPdfService {
  SubscriptionPdfService._();

  static final NumberFormat _fmt = NumberFormat('#,##0.00', 'en_IN');
  static String _clean(String s) => s.replaceAll('—', '-').replaceAll('–', '-').replaceAll('₹', 'INR ');

  static const defaultSettlement = SettlementDestination(
    beneficiaryName: 'ENX Money',
    bankName: 'ENX Money Secure Gateway',
    accountNumber: '',
    ifscCode: '',
    urnNumber: '',
    gstin: '27AARCP9260R1Z2',
    merchantName: 'ENX Money',
  );


  /// Generate raw PDF bytes for Subscription GST Tax Invoice
  static Future<Uint8List> generateSubscriptionInvoicePdf({
    required SubscriptionInvoice invoice,
    SettlementDestination? settlement,
  }) async {
    final settle = settlement ?? defaultSettlement;
    final pdf = pw.Document();

    final dateStr = DateFormat('dd MMMM yyyy').format(invoice.invoiceDate);
    final taxable = (invoice.subtotal - invoice.discount).clamp(0, double.infinity);
    final cgst = taxable * 0.09;
    final sgst = taxable * 0.09;
    final totalTax = invoice.taxAmount > 0 ? invoice.taxAmount : (cgst + sgst);
    final total = invoice.total > 0 ? invoice.total : (taxable + totalTax);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header Banner ─────────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('0F172A'),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ENX MONEY',
                          style: pw.TextStyle(
                            color: PdfColor.fromHex('10B981'),
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Next-Gen Business & Personal Finance OS',
                          style: pw.TextStyle(color: PdfColor.fromHex('94A3B8'), fontSize: 9),
                        ),
                        pw.Text(
                          'GSTIN: ${settle.gstin ?? "27AARCP9260R1Z2"} | Enterprenex Solutions Pvt Ltd',
                          style: pw.TextStyle(color: PdfColor.fromHex('64748B'), fontSize: 8),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'TAX INVOICE',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('10B981'),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Text(
                            'PAID / CONFIRMED',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Invoice: ${invoice.invoiceNumber}',
                          style: pw.TextStyle(color: PdfColor.fromHex('94A3B8'), fontSize: 8.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // ── Billed To & Metadata ──────────────────────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BILLED TO:',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('64748B'),
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Valued Subscriber',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('ENX Money Registered Customer', style: const pw.TextStyle(fontSize: 9.5)),
                      pw.Text(
                        'Status: ACTIVE SUBSCRIPTION',
                        style: pw.TextStyle(fontSize: 8.5, color: PdfColor.fromHex('10B981')),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'SUBSCRIPTION DETAILS:',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('64748B'),
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 9.5)),
                      pw.Text('Cycle: ${invoice.billingCycle}', style: const pw.TextStyle(fontSize: 9.5)),
                      pw.Text('Currency: INR', style: const pw.TextStyle(fontSize: 9.5)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // ── Plan Table ────────────────────────────────────────────────
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromHex('E2E8F0')),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('F1F5F9'),
                        borderRadius: const pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(5),
                          topRight: pw.Radius.circular(5),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 4,
                            child: pw.Text(
                              'Subscription Plan / Service Description',
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              'Billing Cycle',
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              'Base Price',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              'Amount (INR)',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 4,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'ENX Money - ${_clean(invoice.planName)}',
                                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  'Full access to automated accounting, AI, and banking limits',
                                  style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('64748B')),
                                ),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(invoice.billingCycle, style: const pw.TextStyle(fontSize: 9.5)),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              'INR ${_fmt.format(invoice.subtotal)}',
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 9.5),
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              'INR ${_fmt.format(taxable)}',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // ── Tax Breakdown ─────────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 240,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('F8FAFC'),
                      border: pw.Border.all(color: PdfColor.fromHex('E2E8F0')),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Column(
                      children: [
                        _buildSummaryLine('Subtotal', 'INR ${_fmt.format(invoice.subtotal)}'),
                        if (invoice.discount > 0)
                          _buildSummaryLine('Coupon Discount', '- INR ${_fmt.format(invoice.discount)}',
                              isDiscount: true),
                        _buildSummaryLine('Taxable Amount', 'INR ${_fmt.format(taxable)}'),
                        _buildSummaryLine('CGST (9%)', 'INR ${_fmt.format(cgst)}'),
                        _buildSummaryLine('SGST (9%)', 'INR ${_fmt.format(sgst)}'),
                        pw.Divider(color: PdfColor.fromHex('CBD5E1')),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total Paid:',
                                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                            pw.Text(
                              'INR ${_fmt.format(total)}',
                              style: pw.TextStyle(
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('10B981'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 18),

              // ── Merchant & Official Payment Confirmation Box ──────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('F8FAFC'),
                  border: pw.Border.all(color: PdfColor.fromHex('CBD5E1')),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Merchant & Official Payment Confirmation',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('0F172A'),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildInfoPair('Merchant / Business', 'ENX Money (Enterprenex Solutions Pvt Ltd)'),
                            _buildInfoPair('GSTIN', settle.gstin ?? '27AARCP9260R1Z2'),
                            _buildInfoPair('Payment Processor', 'Razorpay / PCI-DSS Level 1 Encrypted'),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildInfoPair('Settlement Status', 'VERIFIED & SETTLED TO ENX MONEY'),
                            _buildInfoPair('Support Email', 'support@enxmoney.com'),
                            _buildInfoPair('Official Website', 'https://enxmoney.com'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // ── Footer & Signatory ────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '1. Subscription payments are non-refundable once activated.',
                        style: pw.TextStyle(color: PdfColor.fromHex('94A3B8'), fontSize: 7.5),
                      ),
                      pw.Text(
                        '2. This is a computer-generated tax invoice and requires no physical signature.',
                        style: pw.TextStyle(color: PdfColor.fromHex('94A3B8'), fontSize: 7.5),
                      ),
                      pw.Text(
                        '3. For billing support, reach out to billing@enxmoney.com',
                        style: pw.TextStyle(color: PdfColor.fromHex('94A3B8'), fontSize: 7.5),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 120, height: 1, color: PdfColor.fromHex('94A3B8')),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Authorized Signatory',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Enterprenex Solutions Pvt Ltd',
                        style: pw.TextStyle(fontSize: 7.5, color: PdfColor.fromHex('64748B')),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSummaryLine(String label, String value, {bool isDiscount = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8.5)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: isDiscount ? PdfColor.fromHex('10B981') : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoPair(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          pw.Text('$label: ', style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('64748B'))),
          pw.Text(value, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  /// Show Action Bottom Sheet to View, Print, or Download/Share Subscription Invoice
  static Future<void> showInvoiceActionsModal(
    BuildContext context, {
    required SubscriptionInvoice invoice,
    SettlementDestination? settlement,
  }) async {
    final fileName = 'ENX_Invoice_${invoice.invoiceNumber}.pdf';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.invoiceNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${invoice.planName} • ${DateFormat('dd MMM yyyy').format(invoice.invoiceDate)}',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${_fmt.format(invoice.total)}',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.download_rounded, color: Color(0xFF10B981)),
                  title: const Text('Download / Save PDF', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Save to your device storage', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: const Color(0xFF0F172A),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _saveAndOpenPdf(context, invoice: invoice, settlement: settlement);
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.print_rounded, color: Color(0xFF38BDF8)),
                  title: const Text('Print Tax Invoice', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('AirPrint / Wi-Fi Print', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: const Color(0xFF0F172A),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final bytes = await generateSubscriptionInvoicePdf(invoice: invoice, settlement: settlement);
                    await Printing.layoutPdf(
                      onLayout: (PdfPageFormat format) async => bytes,
                      name: fileName,
                    );
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.share_rounded, color: Color(0xFFA855F7)),
                  title: const Text('Share Invoice PDF', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Send via WhatsApp, Email, or Drive', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: const Color(0xFF0F172A),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final bytes = await generateSubscriptionInvoicePdf(invoice: invoice, settlement: settlement);
                    await Printing.sharePdf(bytes: bytes, filename: fileName);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _saveAndOpenPdf(
    BuildContext context, {
    required SubscriptionInvoice invoice,
    SettlementDestination? settlement,
  }) async {
    try {
      final bytes = await generateSubscriptionInvoicePdf(invoice: invoice, settlement: settlement);
      final fileName = 'ENX_Invoice_${invoice.invoiceNumber}.pdf';

      if (kIsWeb) {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text('✓ Invoice saved: $fileName'),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () => OpenFilex.open(file.path),
            ),
          ),
        );
      }
      await OpenFilex.open(file.path);
    } catch (e) {
      debugPrint('[SubscriptionPdf] save error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Error saving invoice: $e')),
        );
      }
    }
  }
}
