const InvoiceModel = require('../models/invoice.model');
const SettingsModel = require('../models/settings.model');
const PDFDocument = require('pdfkit');

class InvoicesController {
  static async getInvoices(req, res) {
    try {
      const { search, status, invoiceType } = req.query;
      const userId = req.user ? req.user.id : null;
      const list = await InvoiceModel.findAll({ search, status, invoiceType, userId });
      return res.status(200).json({ success: true, data: list });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async getInvoiceById(req, res) {
    try {
      const invoice = await InvoiceModel.findById(req.params.id);
      if (!invoice) return res.status(404).json({ success: false, message: 'Invoice not found' });
      return res.status(200).json({ success: true, data: invoice });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async createInvoice(req, res) {
    try {
      const userId = req.user ? req.user.id : (req.body.userId || (process.env.NODE_ENV === 'test' ? 1 : null));
      const invoice = await InvoiceModel.create({ ...req.body, userId });
      return res.status(201).json({ success: true, message: 'Invoice generated successfully', data: invoice });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async calculateGstPreview(req, res) {
    try {
      const calculation = InvoiceModel.calculateGST(req.body);
      return res.status(200).json({ success: true, data: calculation });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }

  static async downloadPdf(req, res) {
    try {
      const invoice = await InvoiceModel.findById(req.params.id);
      if (!invoice) return res.status(404).json({ success: false, message: 'Invoice not found' });

      const userId = invoice.userId || (req.user ? req.user.id : 1);
      const settings = await SettingsModel.getByUserId(userId);
      const businessName = settings?.business?.registeredBusinessName || 'ENX Money Enterprise';
      const gstin = settings?.business?.gstin || '36AAACK1234F1Z5';
      const state = settings?.business?.businessState || 'Telangana';

      const doc = new PDFDocument({ margin: 40, size: 'A4' });

      const filename = `Invoice_${(invoice.invoiceNumber || invoice.id).replace(/[^a-zA-Z0-9_-]/g, '_')}.pdf`;
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);

      doc.pipe(res);

      // Header
      doc.fontSize(22).fillColor('#00695C').text('TAX INVOICE', { align: 'left' });
      doc.moveDown(0.2);
      doc.fontSize(12).fillColor('#111827').text(businessName);
      doc.fontSize(10).fillColor('#4B5563').text(`GSTIN: ${gstin}`);
      doc.text(`State: ${state} • India`);
      doc.moveDown(0.8);

      // Divider
      doc.strokeColor('#D1D5DB').lineWidth(1).moveTo(40, doc.y).lineTo(555, doc.y).stroke();
      doc.moveDown(0.8);

      // Invoice Details & Billed To
      const topY = doc.y;
      doc.fontSize(10).fillColor('#374151');
      doc.text(`Invoice #: ${invoice.invoiceNumber || invoice.id}`, 40, topY, { bold: true });
      doc.text(`Date: ${invoice.invoiceDate || new Date().toISOString().split('T')[0]}`, 40, topY + 15);
      doc.text(`Payment Status: ${invoice.paymentStatus || 'UNPAID'}`, 40, topY + 30);

      doc.text('BILLED TO:', 320, topY, { bold: true });
      doc.text(invoice.customerName || 'Customer', 320, topY + 15);
      if (invoice.customerGstin) doc.text(`GSTIN: ${invoice.customerGstin}`, 320, topY + 30);
      doc.moveDown(2.5);

      // Item Table
      const tableTop = doc.y + 10;
      doc.rect(40, tableTop, 515, 20).fill('#00695C');
      doc.fillColor('#FFFFFF').fontSize(9);
      doc.text('#', 45, tableTop + 5);
      doc.text('Description', 70, tableTop + 5);
      doc.text('HSN', 240, tableTop + 5);
      doc.text('Qty', 300, tableTop + 5);
      doc.text('Rate', 340, tableTop + 5);
      doc.text('GST%', 410, tableTop + 5);
      doc.text('Total (INR)', 470, tableTop + 5, { align: 'right', width: 80 });

      let currentY = tableTop + 25;
      const items = invoice.items || [];
      items.forEach((item, index) => {
        if (index % 2 === 1) {
          doc.rect(40, currentY - 3, 515, 18).fill('#F9FAFB');
        }
        doc.fillColor('#111827').fontSize(8.5);
        doc.text(`${index + 1}`, 45, currentY);
        doc.text(item.description || 'Item', 70, currentY, { width: 165 });
        doc.text(item.hsnCode || '-', 240, currentY);
        doc.text(`${item.quantity || 1}`, 300, currentY);
        doc.text(`Rs. ${(item.unitPrice || 0).toFixed(2)}`, 340, currentY);
        doc.text(`${item.gstRate || 0}%`, 410, currentY);
        doc.text(`Rs. ${(item.total || 0).toFixed(2)}`, 470, currentY, { align: 'right', width: 80 });
        currentY += 20;
      });

      // Summary
      currentY += 10;
      doc.strokeColor('#E5E7EB').lineWidth(0.5).moveTo(40, currentY).lineTo(555, currentY).stroke();
      currentY += 10;

      const summaryX = 350;
      doc.fontSize(9).fillColor('#374151');
      doc.text('Taxable Subtotal:', summaryX, currentY);
      doc.text(`Rs. ${(invoice.taxableTotal || 0).toFixed(2)}`, 470, currentY, { align: 'right', width: 80 });
      currentY += 16;

      if ((invoice.cgstTotal || 0) > 0) {
        doc.text('CGST Total:', summaryX, currentY);
        doc.text(`Rs. ${invoice.cgstTotal.toFixed(2)}`, 470, currentY, { align: 'right', width: 80 });
        currentY += 16;
      }
      if ((invoice.sgstTotal || 0) > 0) {
        doc.text('SGST Total:', summaryX, currentY);
        doc.text(`Rs. ${invoice.sgstTotal.toFixed(2)}`, 470, currentY, { align: 'right', width: 80 });
        currentY += 16;
      }
      if ((invoice.igstTotal || 0) > 0) {
        doc.text('IGST Total:', summaryX, currentY);
        doc.text(`Rs. ${invoice.igstTotal.toFixed(2)}`, 470, currentY, { align: 'right', width: 80 });
        currentY += 16;
      }

      doc.rect(summaryX - 5, currentY - 2, 210, 20).fill('#E0F2FE');
      doc.fillColor('#0369A1').fontSize(10);
      doc.text('Grand Total:', summaryX, currentY + 3);
      doc.text(`Rs. ${(invoice.grandTotal || 0).toFixed(2)}`, 470, currentY + 3, { align: 'right', width: 80 });
      currentY += 25;

      doc.fillColor('#374151').fontSize(9);
      doc.text('Amount Paid:', summaryX, currentY);
      doc.text(`Rs. ${(invoice.amountPaid || 0).toFixed(2)}`, 470, currentY, { align: 'right', width: 80 });
      currentY += 16;

      doc.fillColor('#DC2626');
      doc.text('Balance Due:', summaryX, currentY);
      doc.text(`Rs. ${(invoice.balanceDue || 0).toFixed(2)}`, 470, currentY, { align: 'right', width: 80 });

      // Footer
      doc.fontSize(8).fillColor('#9CA3AF').text(
        'Generated securely via ENX Money Enterprise Cloud • Valid Computer-Generated Tax Document',
        40,
        780,
        { align: 'center', width: 515 }
      );

      doc.end();
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  }
}

module.exports = InvoicesController;
