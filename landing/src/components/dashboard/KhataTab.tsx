import React, { useState, useEffect } from 'react';
import {
  Search,
  Plus,
  ArrowDownRight,
  ArrowUpRight,
  Wallet
} from 'lucide-react';
import { api, type Transaction } from '../../services/api';

interface KhataTabProps {
  onOpenNewTransaction: (type?: 'CREDIT' | 'DEBIT') => void;
}

export const KhataTab: React.FC<KhataTabProps> = ({ onOpenNewTransaction }) => {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterType, setFilterType] = useState<'ALL' | 'CREDIT' | 'DEBIT'>('ALL');

  const fetchTransactions = async () => {
    try {
      const data = await api.getTransactions();
      setTransactions(data);
    } catch (err) {
      console.error('Failed to load transactions:', err);
    }
  };

  useEffect(() => {
    fetchTransactions();
  }, []);

  const formatInr = (n: number) => '₹' + Number(n || 0).toLocaleString('en-IN');

  const filteredList = transactions.filter((t) => {
    const matchesFilter = filterType === 'ALL' || t.type === filterType;
    const matchesSearch =
      (t.title || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
      (t.customerName || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
      (t.category || '').toLowerCase().includes(searchQuery.toLowerCase());
    return matchesFilter && matchesSearch;
  });

  const totalCredit = transactions
    .filter((t) => t.type === 'CREDIT' || t.type === 'REVENUE')
    .reduce((sum, t) => sum + Number(t.amount || 0), 0);

  const totalDebit = transactions
    .filter((t) => t.type === 'DEBIT' || t.type === 'EXPENSE')
    .reduce((sum, t) => sum + Number(t.amount || 0), 0);

  const netBalance = totalCredit - totalDebit;

  return (
    <div className="space-y-6">
      {/* Top Ledger Ribbon */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200/90 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Total Received (Got)</span>
            <div className="text-2xl font-black text-emerald-600 font-display mt-1">
              +{formatInr(totalCredit)}
            </div>
            <span className="text-[11px] text-slate-400">Total inflow & collections</span>
          </div>
          <div className="w-12 h-12 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
            <ArrowDownRight className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/90 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Total Given (Gave)</span>
            <div className="text-2xl font-black text-rose-600 font-display mt-1">
              -{formatInr(totalDebit)}
            </div>
            <span className="text-[11px] text-slate-400">Total supplier dues & expenses</span>
          </div>
          <div className="w-12 h-12 rounded-2xl bg-rose-50 text-rose-600 flex items-center justify-center">
            <ArrowUpRight className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/90 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Net Daily Balance</span>
            <div className="text-2xl font-black text-blue-600 font-display mt-1">
              {formatInr(netBalance)}
            </div>
            <span className="text-[11px] text-emerald-600 font-semibold">Positive Cash Inflow</span>
          </div>
          <div className="w-12 h-12 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center">
            <Wallet className="w-6 h-6" />
          </div>
        </div>
      </div>

      {/* Main Table Container */}
      <div className="bg-white rounded-2xl border border-slate-200/90 shadow-sm overflow-hidden">
        {/* Controls Bar */}
        <div className="p-5 border-b border-slate-100 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="flex flex-1 items-center gap-3">
            <div className="relative flex-1 max-w-md">
              <Search className="w-4 h-4 absolute left-3.5 top-3 text-slate-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search transactions, customers, or notes..."
                className="w-full pl-10 pr-4 py-2 text-xs rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all"
              />
            </div>

            <div className="flex rounded-xl bg-slate-100 p-1 text-xs font-semibold">
              <button
                onClick={() => setFilterType('ALL')}
                className={`px-3 py-1.5 rounded-lg transition-all ${
                  filterType === 'ALL' ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-500 hover:text-slate-800'
                }`}
              >
                All
              </button>
              <button
                onClick={() => setFilterType('CREDIT')}
                className={`px-3 py-1.5 rounded-lg transition-all ${
                  filterType === 'CREDIT' ? 'bg-emerald-600 text-white shadow-sm' : 'text-slate-500 hover:text-slate-800'
                }`}
              >
                Got (+ Sale)
              </button>
              <button
                onClick={() => setFilterType('DEBIT')}
                className={`px-3 py-1.5 rounded-lg transition-all ${
                  filterType === 'DEBIT' ? 'bg-rose-600 text-white shadow-sm' : 'text-slate-500 hover:text-slate-800'
                }`}
              >
                Gave (- Expense)
              </button>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => onOpenNewTransaction('CREDIT')}
              className="px-4 py-2 rounded-xl text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 shadow-sm flex items-center gap-1.5 transition-all"
            >
              <Plus className="w-3.5 h-3.5" />
              <span>+ Record Got</span>
            </button>
            <button
              onClick={() => onOpenNewTransaction('DEBIT')}
              className="px-4 py-2 rounded-xl text-xs font-bold text-white bg-rose-600 hover:bg-rose-700 shadow-sm flex items-center gap-1.5 transition-all"
            >
              <Plus className="w-3.5 h-3.5" />
              <span>- Record Gave</span>
            </button>
          </div>
        </div>

        {/* Table Content */}
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="bg-slate-50/80 border-b border-slate-100 text-slate-500 uppercase font-semibold text-[10px] tracking-wider">
                <th className="py-3 px-5">Date & ID</th>
                <th className="py-3 px-4">Transaction / Party</th>
                <th className="py-3 px-4">Category</th>
                <th className="py-3 px-4">Mode</th>
                <th className="py-3 px-4 text-right">You Gave (Dr)</th>
                <th className="py-3 px-5 text-right">You Got (Cr)</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700">
              {filteredList.map((tx) => {
                const isCredit = tx.type === 'CREDIT' || tx.type === 'REVENUE';
                return (
                  <tr key={tx.id} className="hover:bg-slate-50/60 transition-colors">
                    <td className="py-3.5 px-5">
                      <div className="font-semibold text-slate-900">{tx.date}</div>
                      <div className="text-[10px] text-slate-400">TXN-00{tx.id}</div>
                    </td>
                    <td className="py-3.5 px-4">
                      <div className="font-bold text-slate-900">{tx.title}</div>
                      <div className="text-[11px] text-slate-500">{tx.customerName || 'Direct Cash Entry'}</div>
                    </td>
                    <td className="py-3.5 px-4">
                      <span className="px-2.5 py-1 rounded-full text-[10px] font-semibold bg-slate-100 text-slate-600">
                        {tx.category}
                      </span>
                    </td>
                    <td className="py-3.5 px-4">
                      <span className="font-semibold text-slate-700">{tx.paymentMode}</span>
                    </td>
                    <td className="py-3.5 px-4 text-right font-black font-display text-sm">
                      {!isCredit ? (
                        <span className="text-rose-600">-{formatInr(tx.amount)}</span>
                      ) : (
                        <span className="text-slate-300">-</span>
                      )}
                    </td>
                    <td className="py-3.5 px-5 text-right font-black font-display text-sm">
                      {isCredit ? (
                        <span className="text-emerald-600">+{formatInr(tx.amount)}</span>
                      ) : (
                        <span className="text-slate-300">-</span>
                      )}
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
