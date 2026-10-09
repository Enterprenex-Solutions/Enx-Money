import React, { useState } from 'react';
import {
  Download,
  ArrowUpRight,
  ArrowDownRight
} from 'lucide-react';

export const ReportsTab: React.FC = () => {
  const [dateRange, setDateRange] = useState('CURRENT_MONTH');

  const formatInr = (n: number) => '₹' + Number(n || 0).toLocaleString('en-IN');

  const handleExportCsv = () => {
    const csvContent =
      'data:text/csv;charset=utf-8,' +
      'Metric,Amount (INR),Period\n' +
      'Gross Sales,184500,October 2026\n' +
      'Cost of Goods Sold (Inventory),42300,October 2026\n' +
      'Operating Profit,142200,October 2026\n' +
      'Receivables Pending,68400,All Time\n' +
      'Payables Pending,19200,All Time\n';
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', 'ENX_Money_Financial_Report_Oct2026.csv');
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="space-y-6">
      {/* Top Header & Range Filter */}
      <div className="bg-white p-5 rounded-2xl border border-slate-200/90 shadow-sm flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold font-display text-slate-900">Financial Reports & Analytics</h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Download audited P&L statements, monthly turnover, and GST tax summaries for filing.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <select
            value={dateRange}
            onChange={(e) => setDateRange(e.target.value)}
            className="px-3.5 py-2 text-xs font-semibold rounded-xl border border-slate-200 bg-slate-50 text-slate-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="CURRENT_MONTH">Current Month (Oct 2026)</option>
            <option value="LAST_MONTH">Last Month (Sep 2026)</option>
            <option value="Q3_2026">Q3 FY 2026-27</option>
            <option value="FULL_YEAR">Full Financial Year 2026</option>
          </select>

          <button
            onClick={handleExportCsv}
            className="px-4 py-2 rounded-xl text-xs font-bold text-slate-700 bg-white border border-slate-200 hover:bg-slate-50 shadow-sm flex items-center gap-1.5 transition-all"
          >
            <Download className="w-3.5 h-3.5 text-blue-600" />
            <span>Export CSV</span>
          </button>
        </div>
      </div>

      {/* Profit & Loss Statement Card */}
      <div className="bg-white rounded-2xl border border-slate-200/90 shadow-sm p-6 space-y-6">
        <div className="flex items-center justify-between border-b border-slate-100 pb-4">
          <div>
            <h3 className="text-base font-bold text-slate-900 font-display">
              Statement of Profit & Loss (P&L)
            </h3>
            <p className="text-xs text-slate-500">Period: 01 Oct 2026 - Present</p>
          </div>
          <span className="px-3 py-1 rounded-full text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-100">
            Profitable (+77.1%)
          </span>
        </div>

        <div className="space-y-3 text-xs">
          {/* Revenue */}
          <div className="p-3.5 rounded-xl bg-slate-50 border border-slate-100 space-y-2">
            <div className="flex justify-between items-center font-bold text-slate-800 text-sm">
              <span className="flex items-center gap-1.5">
                <ArrowDownRight className="w-4 h-4 text-emerald-600" />
                <span>1. Operating Revenue & Sales</span>
              </span>
              <span className="text-emerald-700">{formatInr(184500)}</span>
            </div>
            <div className="pl-6 space-y-1 text-slate-500">
              <div className="flex justify-between">
                <span>• In-Store Direct Cash & UPI Sales</span>
                <span className="font-mono text-slate-700">{formatInr(128000)}</span>
              </div>
              <div className="flex justify-between">
                <span>• Khata Credit Collections</span>
                <span className="font-mono text-slate-700">{formatInr(42500)}</span>
              </div>
              <div className="flex justify-between">
                <span>• GST B2B Invoices</span>
                <span className="font-mono text-slate-700">{formatInr(14000)}</span>
              </div>
            </div>
          </div>

          {/* Cost of Goods Sold */}
          <div className="p-3.5 rounded-xl bg-slate-50 border border-slate-100 space-y-2">
            <div className="flex justify-between items-center font-bold text-slate-800 text-sm">
              <span className="flex items-center gap-1.5">
                <ArrowUpRight className="w-4 h-4 text-rose-600" />
                <span>2. Cost of Inventory & Supplies</span>
              </span>
              <span className="text-rose-600">-{formatInr(42300)}</span>
            </div>
            <div className="pl-6 space-y-1 text-slate-500">
              <div className="flex justify-between">
                <span>• Wholesale Stock Procurement</span>
                <span className="font-mono text-slate-700">{formatInr(34200)}</span>
              </div>
              <div className="flex justify-between">
                <span>• Freight & Packaging</span>
                <span className="font-mono text-slate-700">{formatInr(8100)}</span>
              </div>
            </div>
          </div>

          {/* Net Operating Profit */}
          <div className="p-4 rounded-xl bg-gradient-to-r from-blue-50 to-indigo-50 border border-blue-100 flex items-center justify-between text-base font-black text-slate-900 font-display">
            <span>Net Operating Business Profit:</span>
            <span className="text-blue-600 text-xl font-display">{formatInr(142200)}</span>
          </div>
        </div>
      </div>

      {/* Expense Category Breakdown */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-2xl border border-slate-200/90 shadow-sm">
          <h3 className="text-base font-bold text-slate-900 font-display mb-1">
            Expense Categories
          </h3>
          <p className="text-xs text-slate-500 mb-4">Breakdown of operational outflows</p>

          <div className="space-y-3 text-xs">
            {[
              { cat: 'Inventory Purchases', amt: 34200, pct: '80.8%', col: 'bg-blue-600' },
              { cat: 'Shop Rent & Utilities', amt: 4800, pct: '11.3%', col: 'bg-indigo-500' },
              { cat: 'Transport & Delivery', amt: 2100, pct: '5.0%', col: 'bg-amber-500' },
              { cat: 'Staff & Miscellaneous', amt: 1200, pct: '2.9%', col: 'bg-emerald-500' },
            ].map((item, idx) => (
              <div key={idx} className="space-y-1">
                <div className="flex justify-between font-semibold text-slate-700">
                  <span>{item.cat}</span>
                  <span className="font-mono">{formatInr(item.amt)} ({item.pct})</span>
                </div>
                <div className="w-full h-2 rounded-full bg-slate-100 overflow-hidden">
                  <div
                    className={`h-full ${item.col} rounded-full`}
                    style={{ width: item.pct }}
                  />
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-white p-6 rounded-2xl border border-slate-200/90 shadow-sm flex flex-col justify-between">
          <div>
            <h3 className="text-base font-bold text-slate-900 font-display mb-1">
              GST Tax Summary (GSTR-1 Ready)
            </h3>
            <p className="text-xs text-slate-500 mb-4">Estimated taxes ready for CA reconciliation</p>

            <div className="space-y-2.5 text-xs">
              <div className="flex justify-between p-2.5 rounded-lg bg-slate-50 border border-slate-100">
                <span className="text-slate-600">Total Taxable Value:</span>
                <span className="font-bold text-slate-900">{formatInr(172400)}</span>
              </div>
              <div className="flex justify-between p-2.5 rounded-lg bg-slate-50 border border-slate-100">
                <span className="text-slate-600">Output CGST (Collected):</span>
                <span className="font-bold text-blue-600">{formatInr(6050)}</span>
              </div>
              <div className="flex justify-between p-2.5 rounded-lg bg-slate-50 border border-slate-100">
                <span className="text-slate-600">Output SGST (Collected):</span>
                <span className="font-bold text-blue-600">{formatInr(6050)}</span>
              </div>
              <div className="flex justify-between p-2.5 rounded-lg bg-slate-50 border border-slate-100">
                <span className="text-slate-600">Input Tax Credit (Purchases):</span>
                <span className="font-bold text-emerald-600">-{formatInr(3800)}</span>
              </div>
            </div>
          </div>

          <div className="pt-4 border-t border-slate-100 mt-4 flex items-center justify-between">
            <span className="text-xs font-bold text-slate-700">Net Tax Payable:</span>
            <span className="text-base font-black font-display text-blue-700">{formatInr(8300)}</span>
          </div>
        </div>
      </div>
    </div>
  );
};
