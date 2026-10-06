import 'package:flutter_test/flutter_test.dart';
import 'package:enx_money/core/services/pdf_invoice_service.dart';
import 'package:enx_money/features/invoices/models/invoice_model.dart';
import 'package:enx_money/features/customers/models/customer_model.dart';
import 'package:enx_money/features/customers/models/ledger_entry_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfInvoiceService Real Data & Non-Corrupt Generation Tests', () {
    test('generateInvoicePdf produces valid, non-empty, uncorrupted PDF bytes with %PDF header', () async {
      final invoice = InvoiceModel(
        id: 'inv_real_001',
        invoiceNumber: 'INV/2026-27/0042',
        invoiceType: 'GST',
        invoiceDate: '2026-09-13',
        customerId: 'cust_001',
        customerName: 'Krishna Enterprises',
        customerGstin: '36AAACK1234F1Z5',
        isIntraState: true,
        items: [
          InvoiceItemModel(
            id: 'item_1',
            description: 'Organic Cotton Bales',
            hsnCode: '5201',
            quantity: 10,
            unitPrice: 2500.0,
            taxableValue: 25000.0,
            gstRate: 18.0,
            cgstAmount: 2250.0,
            sgstAmount: 2250.0,
            total: 29500.0,
          ),
        ],
        taxableTotal: 25000.0,
        cgstTotal: 2250.0,
        sgstTotal: 2250.0,
        igstTotal: 0.0,
        grandTotal: 29500.0,
        paymentStatus: 'PAID',
        amountPaid: 29500.0,
        balanceDue: 0.0,
      );

      final pdfBytes = await PdfInvoiceService.generateInvoicePdf(
        invoice,
        businessName: 'Venkateshwara Textiles',
        merchantGstin: '36AABCU9603R1ZM',
      );

      expect(pdfBytes.isNotEmpty, true);
      expect(pdfBytes.length, greaterThan(1000));

      // Validate standard PDF magic number '%PDF'
      final header = String.fromCharCodes(pdfBytes.take(4));
      expect(header, '%PDF');
    });

    test('generateCustomerStatementPdf produces valid PDF bytes for customer ledger', () async {
      final customer = CustomerModel(
        id: 'cust_101',
        name: 'Ramesh Patel',
        phone: '9848022338',
        gstin: '36AAACP9876F1Z1',
        currentBalance: 15400.0,
        creditLimit: 50000.0,
      );

      final ledger = [
        LedgerEntryModel(
          id: 'ent_1',
          customerId: 'cust_101',
          entryType: 'GAVE',
          amount: 20000.0,
          balanceAfter: 20000.0,
          paymentMode: 'CREDIT',
          description: 'Fertilizer & Seeds Delivery',
          entryDate: '10 Sep 2026',
        ),
        LedgerEntryModel(
          id: 'ent_2',
          customerId: 'cust_101',
          entryType: 'GOT',
          amount: 4600.0,
          balanceAfter: 15400.0,
          paymentMode: 'UPI',
          description: 'Partial Settlement via GPay',
          entryDate: '12 Sep 2026',
        ),
      ];

      final pdfBytes = await PdfInvoiceService.generateCustomerStatementPdf(
        customer,
        ledger,
        businessName: 'Patel Agro Agencies',
      );

      expect(pdfBytes.isNotEmpty, true);
      expect(pdfBytes.length, greaterThan(1000));

      final header = String.fromCharCodes(pdfBytes.take(4));
      expect(header, '%PDF');
    });
  });
}
