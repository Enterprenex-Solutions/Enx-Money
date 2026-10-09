import React, { useState, useEffect } from 'react';
import {
  TrendingUp,
  TrendingDown,
  Wallet,
  ArrowUpRight,
  ArrowDownRight,
  Users,
  FileText,
  Package,
  Activity,
  Plus,
  ArrowRight,
  Sparkles,
  RefreshCw
} from 'lucide-react';
import { api, type DashboardMetrics, type Transaction } from '../../services/api';
import { useAuth } from '../../context/AuthContext';

interface OverviewTabProps {
  onNavigateTab: (tab: string) => void;
  onOpenNewTransaction: (type?: 'CREDIT' | 'DEBIT') => void;
  onOpenNewInvoice: () => void;
}

export const OverviewTab: React.FC<OverviewTabProps> = ({
  onNavigateTab,
  onOpenNewTransaction,
  onOpenNewInvoice,
}) => {
  const { user } = useAuth();
  const [metrics, setMetrics] = useState<DashboardMetrics | null>(null);
  const [recentTx, setRecentTx] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [txFilter, setTxFilter] = useState<'ALL' | 'CREDIT' | 'DEBIT'>('ALL');

  const fetchDashboardData = async () => {
    setLoading(true);
    try {
      const [m, txs] = await Promise.all([
        api.getDashboardMetrics(),
        api.getTransactions(),
      ]);
      setMetrics(m);
      setRecentTx(txs);
    } catch (err) {
      console.error('Failed to load dashboard metrics:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const formatInr = (num: number = 0) => {
    return '₹' + Number(num || 0).toLocaleString('en-IN');
  };

  const filteredTransactions = recentTx.filter((t) => {
    if (txFilter === 'ALL') return true;
    return t.type === txFilter;
  });

  return (
    <div className="space-y-6">
      {/* Welcome Banner */}
      <div className="bg-gradient-to-r from-blue-600 via-blue-700 to-indigo-800 rounded-2xl p-6 text-white shadow-lg relative overflow-hidden">
        <div className="absolute right-0 top-0 bottom-0 w-1/3 bg-white/5 transform skew-x-12 pointer-events-none" />
        <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/15 text-blue-100 text-xs font-semibold mb-2 backdrop-blur-sm">
              <Sparkles className="w-3.5 h-3.5 text-amber-300" />
              <span>Real-Time Business Pulse</span>
            </div>
            <h1 className="text-2xl font-black font-display tracking-tight">
              Namaste, {user?.name || 'Merchant Partner'}!
            </h1>
            <p className="text-sm text-blue-100 max-w-xl mt-1">
              {user?.businessName || 'Shri Ganesh Enterprises'} is operating at an optimal financial health score. Track your daily sales, credit dues, and GST invoices here.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-2.5">
            <button
              onClick={() => onOpenNewTransaction('CREDIT')}
              className="px-4 py-2.5 rounded-xl font-bold text-xs bg-emerald-500 hover:bg-emerald-600 text-white shadow-md shadow-emerald-500/20 flex items-center gap-1.5 transition-all"
            >
              <Plus className="w-4 h-4" />
              <span>+ Record Sale (Got)</span>
            </button>
            <button
              onClick={() => onOpenNewTransaction('DEBIT')}
              className="px-4 py-2.5 rounded-xl font-bold text-xs bg-white/15 hover:bg-white/25 text-white backdrop-blur-sm border border-white/20 flex items-center gap-1.5 transition-all"
            >
              <Plus className="w-4 h-4" />
              <span>- Record Expense (Gave)</span>
            </button>
            <button
              onClick={onOpenNewInvoice}
              className="px-4 py-2.5 rounded-xl font-bold text-xs bg-white text-blue-700 hover:bg-blue-50 shadow-md flex items-center gap-1.5 transition-all"
            >
              <FileText className="w-4 h-4" />
              <span>+ New GST Invoice</span>
            </button>
          </div>
        </div>
      </div>

      {/* 6 Top KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4">
        {/* 1. Total Sales */}
        <div className="bg-white p-4 rounded-2xl border border-slate-200/90 shadow-sm hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between text-slate-500 mb-2">
            <span className="text-xs font-semibold uppercase tracking-wider">Total Sales</span>
            <div className="w-8 h-8 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center">
              <TrendingUp className="w-4 h-4" />
            </div>
          </div>
          <div className="text-xl font-black text-slate-900 font-display">
            {formatInr(metrics?.sales)}
          </div>
          <div className="flex items-center gap-1 text-[11px] text-emerald-600 font-semibold mt-1.5">
            <ArrowUpRight className="w-3.5 h-3.5" />
            <span>+14.2% vs last month</span>
          </div>
        </div>

        {/* 2. Total Expenses */}
        <div className="bg-white p-4 rounded-2xl border border-slate-200/90 shadow-sm hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between text-slate-500 mb-2">
            <span className="text-xs font-semibold uppercase tracking-wider">Total Expenses</span>
            <div className="w-8 h-8 rounded-xl bg-rose-50 text-rose-600 flex items-center justify-center">
              <TrendingDown className="w-4 h-4" />
            </div>
          </div>
          <div className="text-xl font-black text-slate-900 font-display">
            {formatInr(metrics?.expenses)}
          </div>
          <div className="flex items-center gap-1 text-[11px] text-slate-500 font-medium mt-1.5">
            <span>Shop utilities & inventory</span>
          </div>
        </div>

        {/* 3. Net Profit */}
        <div className="bg-white p-4 rounded-2xl border border-slate-200/90 shadow-sm hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between text-slate-500 mb-2">
            <span className="text-xs font-semibold uppercase tracking-wider">Net Profit</span>
            <div className="w-8 h-8 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <Wallet className="w-4 h-4" />
            </div>
          </div>
          <div className="text-xl font-black text-emerald-700 font-display">
            {formatInr(metrics?.netProfit)}
          </div>
          <div className="flex items-center gap-1 text-[11px] text-emerald-600 font-semibold mt-1.5">
            <span>77.1% Profit Margin</span>
          </div>
        </div>

        {/* 4. Receivables (Lene Hain) */}
        <div className="bg-white p-4 rounded-2xl border border-slate-200/90 shadow-sm hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between text-slate-500 mb-2">
            <span className="text-xs font-semibold uppercase tracking-wider">Receivables</span>
            <div className="w-8 h-8 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center">
              <Users className="w-4 h-4" />
            </div>
          </div>
          <div className="text-xl font-black text-amber-700 font-display">
            {formatInr(metrics?.outstandingReceivables)}
          </div>
          <div className="flex items-center gap-1 text-[11px] text-amber-600 font-medium mt-1.5">
            <span>Customer dues pending</span>
          </div>
        </div>

        {/* 5. Payables (Dene Hain) */}
        <div className="bg-white p-4 rounded-2xl border border-slate-200/90 shadow-sm hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between text-slate-500 mb-2">
            <span className="text-xs font-semibold uppercase tracking-wider">Payables</span>
            <div className="w-8 h-8 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center">
              <Package className="w-4 h-4" />
            </div>
          </div>
          <div className="text-xl font-black text-indigo-700 font-display">
            {formatInr(metrics?.outstandingPayables)}
          </div>
          <div className="flex items-center gap-1 text-[11px] text-slate-500 font-medium mt-1.5">
            <span>Supplier dues pending</span>
          </div>
        </div>

        {/* 6. Health Score */}
        <div className="bg-white p-4 rounded-2xl border border-slate-200/90 shadow-sm hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between text-slate-500 mb-2">
            <span className="text-xs font-semibold uppercase tracking-wider">Health Score</span>
            <div className="w-8 h-8 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center">
              <Activity className="w-4 h-4" />
            </div>
          </div>
          <div className="flex items-baseline gap-1 text-xl font-black text-blue-600 font-display">
            <span>92</span>
            <span className="text-xs text-slate-400 font-normal">/100</span>
          </div>
          <div className="flex items-center gap-1 text-[11px] text-emerald-600 font-semibold mt-1.5">
            <span>High Credit Worthiness</span>
          </div>
        </div>
      </div>

      {/* Main Grid: Interactive Sales & Expense Trend Chart + Quick Actions */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Visual Revenue & Cash Flow Chart */}
        <div className="lg:col-span-2 bg-white p-6 rounded-2xl border border-slate-200/90 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-base font-bold text-slate-900 font-display">
                Sales & Expense Trend
              </h2>
              <p className="text-xs text-slate-500">6-Month Financial Cashflow Performance</p>
            </div>
            <div className="flex items-center gap-4 text-xs">
              <div className="flex items-center gap-1.5">
                <span className="w-3 h-3 rounded-full bg-blue-600" />
                <span className="text-slate-600 font-medium">Sales (Inflow)</span>
              </div>
              <div className="flex items-center gap-1.5">
                <span className="w-3 h-3 rounded-full bg-rose-400" />
                <span className="text-slate-600 font-medium">Expenses</span>
              </div>
            </div>
          </div>

          {/* Responsive SVG Bar Chart */}
          <div className="h-60 w-full flex items-end justify-between gap-3 pt-6 pb-2 px-2 border-b border-slate-100">
            {[
              { month: 'May', sales: 120, exp: 35 },
              { month: 'Jun', sales: 145, exp: 40 },
              { month: 'Jul', sales: 135, exp: 38 },
              { month: 'Aug', sales: 165, exp: 45 },
              { month: 'Sep', sales: 172, exp: 42 },
              { month: 'Oct (Current)', sales: 184, exp: 42 },
            ].map((bar, idx) => {
              const maxVal = 200;
              const salesHeight = (bar.sales / maxVal) * 100;
              const expHeight = (bar.exp / maxVal) * 100;

              return (
                <div key={idx} className="flex-1 flex flex-col items-center gap-2 group h-full justify-end">
                  <div className="text-[10px] text-slate-400 opacity-0 group-hover:opacity-100 transition-opacity font-semibold">
                    ₹{bar.sales}k
                  </div>
                  <div className="w-full max-w-[42px] flex items-end justify-center gap-1.5 h-full">
                    {/* Sales Bar */}
                    <div
                      style={{ height: `${salesHeight}%` }}
                      className="w-1/2 bg-blue-600 hover:bg-blue-700 rounded-t-lg transition-all relative"
                      title={`Sales: ₹${bar.sales * 1000}`}
                    />
                    {/* Expense Bar */}
                    <div
                      style={{ height: `${expHeight}%` }}
                      className="w-1/2 bg-rose-400 hover:bg-rose-500 rounded-t-lg transition-all relative"
                      title={`Expenses: ₹${bar.exp * 1000}`}
                    />
                  </div>
                  <span className="text-[11px] font-semibold text-slate-600 text-center whitespace-nowrap">
                    {bar.month}
                  </span>
                </div>
              );
            })}
          </div>

          <div className="flex items-center justify-between pt-3 text-xs text-slate-500">
            <span>Average Monthly Revenue: <strong className="text-slate-800">₹1,53,500</strong></span>
            <button
              onClick={() => onNavigateTab('reports')}
              className="text-blue-600 font-semibold hover:underline flex items-center gap-1"
            >
              <span>Detailed P&L Reports</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>

        {/* Quick Operations & Business Shortcuts */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200/90 shadow-sm flex flex-col justify-between">
          <div>
            <h2 className="text-base font-bold text-slate-900 font-display mb-1">
              Quick Operations
            </h2>
            <p className="text-xs text-slate-500 mb-4">Fast merchant actions for your shop</p>

            <div className="space-y-2.5">
              <button
                onClick={() => onNavigateTab('customers')}
                className="w-full p-3 rounded-xl border border-slate-200/80 hover:border-blue-400 hover:bg-blue-50/40 text-left flex items-center justify-between group transition-all"
              >
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center group-hover:scale-105 transition-transform">
                    <Users className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-xs font-bold text-slate-800">Customers & Udhar</div>
                    <div className="text-[11px] text-slate-500">Send WhatsApp payment links</div>
                  </div>
                </div>
                <ArrowRight className="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all" />
              </button>

              <button
                onClick={() => onNavigateTab('invoices')}
                className="w-full p-3 rounded-xl border border-slate-200/80 hover:border-emerald-400 hover:bg-emerald-50/40 text-left flex items-center justify-between group transition-all"
              >
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center group-hover:scale-105 transition-transform">
                    <FileText className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-xs font-bold text-slate-800">GST Billing & Invoices</div>
                    <div className="text-[11px] text-slate-500">Generate PDF invoices in 10s</div>
                  </div>
                </div>
                <ArrowRight className="w-4 h-4 text-slate-400 group-hover:text-emerald-600 group-hover:translate-x-0.5 transition-all" />
              </button>

              <button
                onClick={() => onNavigateTab('inventory')}
                className="w-full p-3 rounded-xl border border-slate-200/80 hover:border-purple-400 hover:bg-purple-50/40 text-left flex items-center justify-between group transition-all"
              >
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center group-hover:scale-105 transition-transform">
                    <Package className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-xs font-bold text-slate-800">Stock & Inventory</div>
                    <div className="text-[11px] text-slate-500">Low-stock alerts & items</div>
                  </div>
                </div>
                <ArrowRight className="w-4 h-4 text-slate-400 group-hover:text-purple-600 group-hover:translate-x-0.5 transition-all" />
              </button>
            </div>
          </div>

          <div className="pt-4 border-t border-slate-100 mt-4">
            <div className="flex items-center justify-between text-xs text-slate-500">
              <span>Database Sync: <strong>Active</strong></span>
              <button
                onClick={fetchDashboardData}
                disabled={loading}
                className="flex items-center gap-1 text-blue-600 hover:text-blue-700 font-semibold"
              >
                <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
                <span>Refresh Data</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Recent Transactions Table */}
      <div className="bg-white rounded-2xl border border-slate-200/90 shadow-sm overflow-hidden">
        <div className="p-5 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <h2 className="text-base font-bold text-slate-900 font-display">Recent Transactions</h2>
            <p className="text-xs text-slate-500">Live credit & debit entries synced with your khata</p>
          </div>

          <div className="flex items-center gap-2">
            <div className="flex rounded-xl bg-slate-100 p-1 text-xs font-semibold">
              <button
                onClick={() => setTxFilter('ALL')}
                className={`px-3 py-1 rounded-lg transition-all ${
                  txFilter === 'ALL' ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-500 hover:text-slate-800'
                }`}
              >
                All
              </button>
              <button
                onClick={() => setTxFilter('CREDIT')}
                className={`px-3 py-1 rounded-lg transition-all ${
                  txFilter === 'CREDIT' ? 'bg-emerald-600 text-white shadow-sm' : 'text-slate-500 hover:text-slate-800'
                }`}
              >
                Got (+ Sale)
              </button>
              <button
                onClick={() => setTxFilter('DEBIT')}
                className={`px-3 py-1 rounded-lg transition-all ${
                  txFilter === 'DEBIT' ? 'bg-rose-600 text-white shadow-sm' : 'text-slate-500 hover:text-slate-800'
                }`}
              >
                Gave (- Expense)
              </button>
            </div>

            <button
              onClick={() => onNavigateTab('khata')}
              className="text-xs font-semibold text-blue-600 hover:underline px-2 py-1"
            >
              View All
            </button>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="bg-slate-50/80 border-b border-slate-100 text-slate-500 uppercase font-semibold text-[10px] tracking-wider">
                <th className="py-3 px-5">Transaction Details</th>
                <th className="py-3 px-4">Party / Customer</th>
                <th className="py-3 px-4">Category</th>
                <th className="py-3 px-4">Payment Mode</th>
                <th className="py-3 px-4">Date & Time</th>
                <th className="py-3 px-5 text-right">Amount</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700">
              {filteredTransactions.slice(0, 5).map((tx) => {
                const isCredit = tx.type === 'CREDIT' || tx.type === 'REVENUE';
                return (
                  <tr key={tx.id} className="hover:bg-slate-50/60 transition-colors">
                    <td className="py-3.5 px-5">
                      <div className="flex items-center gap-3">
                        <div
                          className={`w-8 h-8 rounded-xl flex items-center justify-center flex-shrink-0 ${
                            isCredit ? 'bg-emerald-50 text-emerald-600' : 'bg-rose-50 text-rose-600'
                          }`}
                        >
                          {isCredit ? (
                            <ArrowDownRight className="w-4 h-4" />
                          ) : (
                            <ArrowUpRight className="w-4 h-4" />
                          )}
                        </div>
                        <div>
                          <div className="font-bold text-slate-900">{tx.title}</div>
                          <div className="text-[11px] text-slate-400">ID: #{tx.id}</div>
                        </div>
                      </div>
                    </td>
                    <td className="py-3.5 px-4 font-medium text-slate-800">
                      {tx.customerName || 'Direct Counter'}
                    </td>
                    <td className="py-3.5 px-4">
                      <span className="px-2.5 py-1 rounded-full text-[10px] font-semibold bg-slate-100 text-slate-600">
                        {tx.category}
                      </span>
                    </td>
                    <td className="py-3.5 px-4">
                      <span className="font-semibold text-slate-700">{tx.paymentMode}</span>
                    </td>
                    <td className="py-3.5 px-4 text-slate-500">{tx.date}</td>
                    <td className="py-3.5 px-5 text-right font-black font-display text-sm">
                      <span className={isCredit ? 'text-emerald-600' : 'text-rose-600'}>
                        {isCredit ? '+' : '-'}{formatInr(tx.amount)}
                      </span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
