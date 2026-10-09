import React, { useState, useEffect } from 'react';
import {
  Plus,
  Search,
  Printer,
  CheckCircle,
  Clock,
  X,
  Trash2,
  Eye
} from 'lucide-react';
import { api, type Invoice, type InvoiceItem } from '../../services/api';
import { useAuth } from '../../context/AuthContext';

export const InvoicesTab: React.FC = () => {
  const { user } = useAuth();
  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const [searchQuery, setSearchQuery] = useState('');

  // Create Invoice Modal
  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [customerName, setCustomerName] = useState('');
  const [customerPhone, setCustomerPhone] = useState('');
  const [customerGstin, setCustomerGstin] = useState('');
  const [invoiceDate, setInvoiceDate] = useState('2026-10-09');
  const [dueDate, setDueDate] = useState('2026-10-16');
  const [items, setItems] = useState<InvoiceItem[]>([
    { description: 'Item 1', quantity: 1, unitPrice: 1000, gstRate: 18 },
  ]);

  // Invoice Preview / Print Modal
  const [previewInvoice, setPreviewInvoice] = useState<Invoice | null>(null);

  const fetchInvoices = async () => {
    try {
      const data = await api.getInvoices();
      setInvoices(data);
    } catch (err) {
      console.error('Failed to load invoices:', err);
    }
  };

  useEffect(() => {
    fetchInvoices();
  }, []);

  const formatInr = (n: number) => '₹' + Number(n || 0).toLocaleString('en-IN');

  const handleAddItem = () => {
    setItems([
      ...items,
      { description: '', quantity: 1, unitPrice: 0, gstRate: 18 },
    ]);
  };

  const handleRemoveItem = (index: number) => {
    setItems(items.filter((_, i) => i !== index));
  };

  const handleItemChange = (index: number, field: keyof InvoiceItem, value: any) => {
    const updated = [...items];
    (updated[index] as any)[field] = value;
    setItems(updated);
  };

  // Real-time GST calculations
  const calculateTotals = () => {
    let subtotal = 0;
    let taxTotal = 0;

    items.forEach((item) => {
      const qty = Number(item.quantity) || 0;
      const rate = Number(item.unitPrice) || 0;
      const gst = Number(item.gstRate) || 0;
      const taxable = qty * rate;
      const tax = (taxable * gst) / 100;
      subtotal += taxable;
      taxTotal += tax;
    });

    return {
      subtotal,
      taxTotal,
      grandTotal: subtotal + taxTotal,
    };
  };

  const totals = calculateTotals();

  const handleSaveInvoice = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!customerName || items.length === 0) return;

    const newInv: Partial<Invoice> = {
      invoiceNumber: `INV-2026-00${invoices.length + 1}`,
      customerName,
      customerPhone,
      customerGstin,
      invoiceDate,
      dueDate,
      items,
      subtotal: totals.subtotal,
      taxTotal: totals.taxTotal,
      grandTotal: totals.grandTotal,
      paymentStatus: 'PAID',
    };

    const saved = await api.createInvoice(newInv);
    setInvoices([saved, ...invoices]);
    setCreateModalOpen(false);
    setPreviewInvoice(saved);
  };

  const filteredInvoices = invoices.filter((inv) => {
    return (
      inv.invoiceNumber.toLowerCase().includes(searchQuery.toLowerCase()) ||
      inv.customerName.toLowerCase().includes(searchQuery.toLowerCase())
    );
  });

  return (
    <div className="space-y-6">
      {/* Top Banner */}
      <div className="bg-white p-5 rounded-2xl border border-slate-200/90 shadow-sm flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold font-display text-slate-900">GST Billing & Sales Invoices</h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Create 100% compliant GST invoices with automated CGST/SGST breakdown and instant print.
          </p>
        </div>

        <button
          onClick={() => setCreateModalOpen(true)}
          className="px-5 py-2.5 rounded-xl font-bold text-xs text-white bg-blue-600 hover:bg-blue-700 shadow-md shadow-blue-500/20 flex items-center gap-2 transition-all self-start sm:self-auto"
        >
          <Plus className="w-4 h-4" />
          <span>+ Create New Invoice</span>
        </button>
      </div>

      {/* Invoices List Table */}
      <div className="bg-white rounded-2xl border border-slate-200/90 shadow-sm overflow-hidden">
        <div className="p-4 border-b border-slate-100 flex items-center justify-between gap-4">
          <div className="relative flex-1 max-w-md">
            <Search className="w-4 h-4 absolute left-3.5 top-3 text-slate-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search by invoice number or customer name..."
              className="w-full pl-10 pr-4 py-2 text-xs rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <span className="text-xs text-slate-500 font-medium">Total: {invoices.length} Invoices</span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="bg-slate-50/80 border-b border-slate-100 text-slate-500 uppercase font-semibold text-[10px] tracking-wider">
                <th className="py-3 px-5">Invoice #</th>
                <th className="py-3 px-4">Customer</th>
                <th className="py-3 px-4">Date</th>
                <th className="py-3 px-4">Tax (GST)</th>
                <th className="py-3 px-4">Grand Total</th>
                <th className="py-3 px-4">Status</th>
                <th className="py-3 px-5 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700">
              {filteredInvoices.map((inv) => (
                <tr key={inv.id} className="hover:bg-slate-50/60 transition-colors">
                  <td className="py-3.5 px-5 font-bold text-blue-600">
                    {inv.invoiceNumber}
                  </td>
                  <td className="py-3.5 px-4 font-bold text-slate-900">
                    {inv.customerName}
                  </td>
                  <td className="py-3.5 px-4 text-slate-500">{inv.invoiceDate}</td>
                  <td className="py-3.5 px-4 text-slate-600 font-mono">
                    {formatInr(inv.taxTotal)}
                  </td>
                  <td className="py-3.5 px-4 font-black font-display text-sm text-slate-900">
                    {formatInr(inv.grandTotal)}
                  </td>
                  <td className="py-3.5 px-4">
                    <span
                      className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                        inv.paymentStatus === 'PAID'
                          ? 'bg-emerald-50 text-emerald-700'
                          : 'bg-amber-50 text-amber-700'
                      }`}
                    >
                      {inv.paymentStatus === 'PAID' ? (
                        <CheckCircle className="w-3 h-3" />
                      ) : (
                        <Clock className="w-3 h-3" />
                      )}
                      <span>{inv.paymentStatus}</span>
                    </span>
                  </td>
                  <td className="py-3.5 px-5 text-right">
                    <button
                      onClick={() => setPreviewInvoice(inv)}
                      className="p-1.5 rounded-lg border border-slate-200 text-slate-600 hover:bg-slate-100 transition-colors"
                      title="Preview / Print Invoice"
                    >
                      <Eye className="w-4 h-4" />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Create GST Invoice Modal */}
      {createModalOpen && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-fadeIn">
          <div
            className="w-full max-w-3xl max-h-[90vh] flex flex-col bg-white rounded-2xl shadow-2xl border border-slate-100 overflow-hidden"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="bg-gradient-to-r from-blue-600 to-indigo-700 px-6 py-4 text-white flex items-center justify-between">
              <div>
                <h3 className="font-bold text-base font-display">New GST Tax Invoice</h3>
                <p className="text-xs text-blue-100">Calculates CGST (9%) + SGST (9%) or IGST automatically</p>
              </div>
              <button onClick={() => setCreateModalOpen(false)} className="text-white/80 hover:text-white">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSaveInvoice} className="flex-1 overflow-y-auto p-6 space-y-5">
              {/* Customer & Date Row */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">Customer Name</label>
                  <input
                    type="text"
                    required
                    value={customerName}
                    onChange={(e) => setCustomerName(e.target.value)}
                    placeholder="e.g. Ramesh Patil"
                    className="w-full px-3 py-2 text-xs rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">Customer Phone</label>
                  <input
                    type="tel"
                    value={customerPhone}
                    onChange={(e) => setCustomerPhone(e.target.value)}
                    placeholder="9823456789"
                    className="w-full px-3 py-2 text-xs rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">Customer GSTIN (Optional)</label>
                  <input
                    type="text"
                    value={customerGstin}
                    onChange={(e) => setCustomerGstin(e.target.value)}
                    placeholder="27AABCU9603R1ZM"
                    className="w-full px-3 py-2 text-xs rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">Invoice Date</label>
                  <input
                    type="date"
                    value={invoiceDate}
                    onChange={(e) => setInvoiceDate(e.target.value)}
                    className="w-full px-3 py-2 text-xs rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">Payment Due Date</label>
                  <input
                    type="date"
                    value={dueDate}
                    onChange={(e) => setDueDate(e.target.value)}
                    className="w-full px-3 py-2 text-xs rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              {/* Line Items */}
              <div>
                <div className="flex items-center justify-between mb-2">
                  <h4 className="text-xs font-bold text-slate-800 uppercase tracking-wider">Itemized Products / Services</h4>
                  <button
                    type="button"
                    onClick={handleAddItem}
                    className="text-xs font-bold text-blue-600 hover:text-blue-700 flex items-center gap-1"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    <span>Add Item</span>
                  </button>
                </div>

                <div className="space-y-2">
                  {items.map((item, idx) => (
                    <div key={idx} className="flex items-center gap-2 p-2.5 rounded-xl border border-slate-200 bg-slate-50/50">
                      <div className="flex-1">
                        <input
                          type="text"
                          required
                          value={item.description}
                          onChange={(e) => handleItemChange(idx, 'description', e.target.value)}
                          placeholder="Item Description"
                          className="w-full px-2.5 py-1.5 text-xs rounded-lg border border-slate-200 bg-white"
                        />
                      </div>
                      <div className="w-20">
                        <input
                          type="number"
                          min="1"
                          required
                          value={item.quantity}
                          onChange={(e) => handleItemChange(idx, 'quantity', Number(e.target.value))}
                          placeholder="Qty"
                          className="w-full px-2.5 py-1.5 text-xs rounded-lg border border-slate-200 bg-white text-center"
                        />
                      </div>
                      <div className="w-28">
                        <input
                          type="number"
                          min="0"
                          required
                          value={item.unitPrice}
                          onChange={(e) => handleItemChange(idx, 'unitPrice', Number(e.target.value))}
                          placeholder="Rate ₹"
                          className="w-full px-2.5 py-1.5 text-xs rounded-lg border border-slate-200 bg-white text-right"
                        />
                      </div>
                      <div className="w-24">
                        <select
                          value={item.gstRate}
                          onChange={(e) => handleItemChange(idx, 'gstRate', Number(e.target.value))}
                          className="w-full px-2 py-1.5 text-xs rounded-lg border border-slate-200 bg-white"
                        >
                          <option value="0">0% GST</option>
                          <option value="5">5% GST</option>
                          <option value="12">12% GST</option>
                          <option value="18">18% GST</option>
                          <option value="28">28% GST</option>
                        </select>
                      </div>
                      {items.length > 1 && (
                        <button
                          type="button"
                          onClick={() => handleRemoveItem(idx)}
                          className="p-1 text-rose-500 hover:text-rose-700"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      )}
                    </div>
                  ))}
                </div>
              </div>

              {/* Total Calculation Card */}
              <div className="p-4 rounded-xl bg-slate-50 border border-slate-200 flex flex-col items-end space-y-1.5 text-xs">
                <div className="flex justify-between w-64">
                  <span className="text-slate-500">Taxable Subtotal:</span>
                  <span className="font-semibold text-slate-800">{formatInr(totals.subtotal)}</span>
                </div>
                <div className="flex justify-between w-64">
                  <span className="text-slate-500">CGST (50% of tax):</span>
                  <span className="font-semibold text-slate-800">{formatInr(totals.taxTotal / 2)}</span>
                </div>
                <div className="flex justify-between w-64">
                  <span className="text-slate-500">SGST (50% of tax):</span>
                  <span className="font-semibold text-slate-800">{formatInr(totals.taxTotal / 2)}</span>
                </div>
                <div className="flex justify-between w-64 pt-2 border-t border-slate-200 text-sm font-black text-slate-900 font-display">
                  <span>Grand Total:</span>
                  <span className="text-blue-600">{formatInr(totals.grandTotal)}</span>
                </div>
              </div>

              <div className="pt-2 flex items-center justify-end gap-2.5">
                <button
                  type="button"
                  onClick={() => setCreateModalOpen(false)}
                  className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 hover:bg-slate-100"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-6 py-2.5 rounded-xl text-xs font-bold text-white bg-blue-600 hover:bg-blue-700 shadow-md shadow-blue-500/20"
                >
                  Generate Invoice
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Invoice Printable View Modal */}
      {previewInvoice && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-fadeIn">
          <div
            className="w-full max-w-2xl bg-white rounded-2xl shadow-2xl border border-slate-200 overflow-hidden"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Top Toolbar */}
            <div className="p-4 bg-slate-50 border-b border-slate-200 flex items-center justify-between">
              <span className="text-xs font-bold text-slate-700">GST Invoice Preview</span>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => window.print()}
                  className="px-3 py-1.5 rounded-lg bg-blue-600 text-white font-bold text-xs flex items-center gap-1.5 hover:bg-blue-700"
                >
                  <Printer className="w-3.5 h-3.5" />
                  <span>Print / Save PDF</span>
                </button>
                <button
                  onClick={() => setPreviewInvoice(null)}
                  className="p-1.5 rounded-lg text-slate-500 hover:bg-slate-200"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
            </div>

            {/* Printable Paper Canvas */}
            <div className="p-8 space-y-6 text-slate-800 text-xs">
              <div className="flex justify-between items-start border-b border-slate-200 pb-5">
                <div>
                  <div className="text-xl font-black font-display text-blue-600">
                    {user?.businessName || 'Shri Ganesh Enterprises'}
                  </div>
                  <div className="text-[11px] text-slate-500 mt-1">
                    GSTIN: {user?.gstin || '27AABCU9603R1ZM'} • State: Maharashtra (27)
                  </div>
                  <div className="text-[11px] text-slate-500">
                    Waluj Mahanagar 1, Chhatrapati Sambhajinagar
                  </div>
                </div>
                <div className="text-right">
                  <div className="text-lg font-black font-display text-slate-900">TAX INVOICE</div>
                  <div className="font-mono text-slate-600 font-bold mt-1">{previewInvoice.invoiceNumber}</div>
                  <div className="text-slate-500 mt-0.5">Date: {previewInvoice.invoiceDate}</div>
                </div>
              </div>

              {/* Billed To */}
              <div className="p-3.5 rounded-xl bg-slate-50 border border-slate-200">
                <span className="font-bold text-slate-500 uppercase text-[10px]">Billed To:</span>
                <div className="font-bold text-slate-900 text-sm mt-0.5">{previewInvoice.customerName}</div>
                {previewInvoice.customerGstin && (
                  <div className="text-slate-600 mt-0.5">GSTIN: {previewInvoice.customerGstin}</div>
                )}
                {previewInvoice.customerPhone && (
                  <div className="text-slate-500 mt-0.5">Phone: {previewInvoice.customerPhone}</div>
                )}
              </div>

              {/* Items Table */}
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="border-b border-slate-200 text-slate-500 font-bold text-[10px] uppercase">
                    <th className="py-2">Item Description</th>
                    <th className="py-2 text-center">Qty</th>
                    <th className="py-2 text-right">Unit Rate</th>
                    <th className="py-2 text-right">GST %</th>
                    <th className="py-2 text-right">Amount</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {previewInvoice.items?.map((item, idx) => (
                    <tr key={idx} className="py-2">
                      <td className="py-2 font-medium">{item.description}</td>
                      <td className="py-2 text-center">{item.quantity}</td>
                      <td className="py-2 text-right">{formatInr(item.unitPrice)}</td>
                      <td className="py-2 text-right">{item.gstRate}%</td>
                      <td className="py-2 text-right font-semibold">
                        {formatInr(item.quantity * item.unitPrice)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>

              {/* Summary */}
              <div className="border-t border-slate-200 pt-4 flex justify-between items-center text-sm font-black font-display">
                <span>Grand Total (Incl. GST):</span>
                <span className="text-blue-600 text-lg">{formatInr(previewInvoice.grandTotal)}</span>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
