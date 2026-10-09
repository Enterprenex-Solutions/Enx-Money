import React, { useState, useEffect } from 'react';
import {
  Search,
  Plus,
  MessageSquare,
  UserCheck,
  X,
  AlertCircle
} from 'lucide-react';
import { api, type Customer } from '../../services/api';
import { useAuth } from '../../context/AuthContext';

export const CustomersTab: React.FC = () => {
  const { user } = useAuth();
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'PENDING' | 'SETTLED'>('ALL');

  // Add Customer Modal
  const [addModalOpen, setAddModalOpen] = useState(false);
  const [newName, setNewName] = useState('');
  const [newPhone, setNewPhone] = useState('');
  const [newAddress, setNewAddress] = useState('');
  const [newBalance, setNewBalance] = useState('');
  const [modalLoading, setModalLoading] = useState(false);

  // Customer Detail Drawer
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null);

  const fetchCustomers = async () => {
    try {
      const data = await api.getCustomers();
      setCustomers(data);
    } catch (err) {
      console.error('Failed to load customers:', err);
    }
  };

  useEffect(() => {
    fetchCustomers();
  }, []);

  const formatInr = (n: number) => '₹' + Number(n || 0).toLocaleString('en-IN');

  const filteredCustomers = customers.filter((c) => {
    const matchesStatus =
      statusFilter === 'ALL' ||
      (statusFilter === 'PENDING' && Number(c.balance || 0) > 0) ||
      (statusFilter === 'SETTLED' && Number(c.balance || 0) <= 0);

    const matchesSearch =
      c.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.phone.includes(searchQuery) ||
      (c.address || '').toLowerCase().includes(searchQuery.toLowerCase());

    return matchesStatus && matchesSearch;
  });

  const totalReceivables = customers.reduce(
    (sum, c) => sum + (c.balance > 0 ? c.balance : 0),
    0
  );

  const handleAddCustomer = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newName || !newPhone) return;

    setModalLoading(true);
    try {
      const created = await api.createCustomer({
        name: newName,
        phone: newPhone,
        address: newAddress,
        balance: Number(newBalance || 0),
      });
      setCustomers([created, ...customers]);
      setAddModalOpen(false);
      setNewName('');
      setNewPhone('');
      setNewAddress('');
      setNewBalance('');
    } catch (err) {
      console.error('Failed to create customer:', err);
    } finally {
      setModalLoading(false);
    }
  };

  const handleSendWhatsAppReminder = (c: Customer) => {
    const url = api.getWhatsAppShareUrl(
      c.phone,
      c.name,
      c.balance,
      user?.businessName || 'ENX Money Merchant'
    );
    window.open(url, '_blank', 'noopener,noreferrer');
  };

  return (
    <div className="space-y-6">
      {/* Top Summary Banner */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200/90 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Total Customers</span>
            <div className="text-2xl font-black text-slate-900 font-display mt-1">
              {customers.length} Accounts
            </div>
            <span className="text-[11px] text-slate-400">Verified dukaan buyers</span>
          </div>
          <div className="w-12 h-12 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center">
            <UserCheck className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/90 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Total Receivables (Lene Hain)</span>
            <div className="text-2xl font-black text-amber-600 font-display mt-1">
              {formatInr(totalReceivables)}
            </div>
            <span className="text-[11px] text-amber-600 font-semibold">Active udhar balances</span>
          </div>
          <div className="w-12 h-12 rounded-2xl bg-amber-50 text-amber-600 flex items-center justify-center">
            <AlertCircle className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200/90 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">WhatsApp Recovery</span>
            <div className="text-2xl font-black text-emerald-600 font-display mt-1">
              3x Faster
            </div>
            <span className="text-[11px] text-emerald-600 font-medium">Auto UPI payment links</span>
          </div>
          <div className="w-12 h-12 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
            <MessageSquare className="w-6 h-6" />
          </div>
        </div>
      </div>

      {/* Main Customers List Card */}
      <div className="bg-white rounded-2xl border border-slate-200/90 shadow-sm overflow-hidden">
        {/* Controls */}
        <div className="p-5 border-b border-slate-100 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="flex flex-1 items-center gap-3">
            <div className="relative flex-1 max-w-md">
              <Search className="w-4 h-4 absolute left-3.5 top-3 text-slate-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search by customer name, phone, or address..."
                className="w-full pl-10 pr-4 py-2 text-xs rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all"
              />
            </div>

            <div className="flex rounded-xl bg-slate-100 p-1 text-xs font-semibold">
              <button
                onClick={() => setStatusFilter('ALL')}
                className={`px-3 py-1.5 rounded-lg transition-all ${
                  statusFilter === 'ALL' ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-500 hover:text-slate-800'
                }`}
              >
                All ({customers.length})
              </button>
              <button
                onClick={() => setStatusFilter('PENDING')}
                className={`px-3 py-1.5 rounded-lg transition-all ${
                  statusFilter === 'PENDING' ? 'bg-amber-500 text-white shadow-sm' : 'text-slate-500 hover:text-slate-800'
                }`}
              >
                Dues Pending
              </button>
              <button
                onClick={() => setStatusFilter('SETTLED')}
                className={`px-3 py-1.5 rounded-lg transition-all ${
                  statusFilter === 'SETTLED' ? 'bg-emerald-600 text-white shadow-sm' : 'text-slate-500 hover:text-slate-800'
                }`}
              >
                Settled
              </button>
            </div>
          </div>

          <button
            onClick={() => setAddModalOpen(true)}
            className="px-4 py-2.5 rounded-xl text-xs font-bold text-white bg-blue-600 hover:bg-blue-700 shadow-md shadow-blue-500/20 flex items-center gap-2 transition-all"
          >
            <Plus className="w-4 h-4" />
            <span>+ Add New Customer</span>
          </button>
        </div>

        {/* Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="bg-slate-50/80 border-b border-slate-100 text-slate-500 uppercase font-semibold text-[10px] tracking-wider">
                <th className="py-3 px-5">Customer Name</th>
                <th className="py-3 px-4">Contact Phone</th>
                <th className="py-3 px-4">Address / Area</th>
                <th className="py-3 px-4">Last Activity</th>
                <th className="py-3 px-4 text-right">Balance Due</th>
                <th className="py-3 px-5 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700">
              {filteredCustomers.map((c) => {
                const hasDues = c.balance > 0;
                return (
                  <tr key={c.id} className="hover:bg-slate-50/60 transition-colors">
                    <td className="py-3.5 px-5">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-blue-100 text-blue-700 font-bold flex items-center justify-center flex-shrink-0 text-xs">
                          {c.name.charAt(0).toUpperCase()}
                        </div>
                        <div>
                          <button
                            onClick={() => setSelectedCustomer(c)}
                            className="font-bold text-slate-900 hover:text-blue-600 text-left transition-colors"
                          >
                            {c.name}
                          </button>
                          <div className="text-[10px] text-slate-400">CUST-00{c.id}</div>
                        </div>
                      </div>
                    </td>
                    <td className="py-3.5 px-4 font-mono text-slate-700">
                      {c.phone}
                    </td>
                    <td className="py-3.5 px-4 text-slate-500">
                      {c.address || 'Local Market'}
                    </td>
                    <td className="py-3.5 px-4 text-slate-500">
                      {c.lastTransactionDate || 'Recent'}
                    </td>
                    <td className="py-3.5 px-4 text-right font-black font-display text-sm">
                      <span className={hasDues ? 'text-amber-600' : 'text-emerald-600'}>
                        {formatInr(c.balance)}
                      </span>
                    </td>
                    <td className="py-3.5 px-5 text-right">
                      <div className="inline-flex items-center gap-2">
                        {hasDues && (
                          <button
                            onClick={() => handleSendWhatsAppReminder(c)}
                            className="p-1.5 rounded-lg bg-emerald-50 text-emerald-700 hover:bg-emerald-100 transition-colors"
                            title="Send WhatsApp Payment Reminder"
                          >
                            <MessageSquare className="w-4 h-4" />
                          </button>
                        )}
                        <button
                          onClick={() => setSelectedCustomer(c)}
                          className="px-2.5 py-1 rounded-lg border border-slate-200 text-slate-600 hover:bg-slate-100 font-semibold text-[11px] transition-colors"
                        >
                          Ledger
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Customer Detail & Ledger Drawer */}
      {selectedCustomer && (
        <div className="fixed inset-0 z-[100] flex justify-end bg-slate-900/50 backdrop-blur-sm animate-fadeIn">
          <div
            className="w-full max-w-md bg-white h-full shadow-2xl flex flex-col overflow-hidden animate-slideLeft"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Drawer Header */}
            <div className="p-5 border-b border-slate-100 bg-slate-50 flex items-center justify-between">
              <div>
                <h3 className="font-bold text-base text-slate-900">{selectedCustomer.name}</h3>
                <p className="text-xs text-slate-500 font-mono">{selectedCustomer.phone}</p>
              </div>
              <button
                onClick={() => setSelectedCustomer(null)}
                className="p-1.5 rounded-full hover:bg-slate-200 text-slate-500"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Balance Highlight */}
            <div className="p-6 border-b border-slate-100 bg-gradient-to-br from-blue-50/50 to-indigo-50/50 text-center">
              <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Net Outstanding Balance</span>
              <div className="text-3xl font-black text-amber-600 font-display mt-1">
                {formatInr(selectedCustomer.balance)}
              </div>
              <p className="text-xs text-slate-500 mt-1">
                {selectedCustomer.balance > 0 ? 'Customer owes you money' : 'All accounts settled'}
              </p>

              {selectedCustomer.balance > 0 && (
                <button
                  onClick={() => handleSendWhatsAppReminder(selectedCustomer)}
                  className="mt-4 w-full py-2.5 px-4 rounded-xl font-bold text-xs text-white bg-emerald-600 hover:bg-emerald-700 shadow-md shadow-emerald-600/20 flex items-center justify-center gap-2 transition-all"
                >
                  <MessageSquare className="w-4 h-4" />
                  <span>Send Free WhatsApp Reminder</span>
                </button>
              )}
            </div>

            {/* Ledger Transactions */}
            <div className="flex-1 overflow-y-auto p-5 space-y-3">
              <h4 className="text-xs font-bold text-slate-800 uppercase tracking-wider">Recent Khata Entries</h4>
              <div className="p-3.5 rounded-xl border border-slate-100 bg-slate-50 text-xs flex items-center justify-between">
                <div>
                  <div className="font-bold text-slate-800">Opening Balance / Credit Due</div>
                  <div className="text-[10px] text-slate-400">01 Oct 2026 • Ledger Note</div>
                </div>
                <div className="font-black text-amber-600 font-display text-sm">
                  {formatInr(selectedCustomer.balance)}
                </div>
              </div>
            </div>

            {/* Drawer Footer */}
            <div className="p-4 border-t border-slate-100 bg-slate-50 flex items-center justify-between">
              <span className="text-xs text-slate-500">ID: #{selectedCustomer.id}</span>
              <button
                onClick={() => setSelectedCustomer(null)}
                className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-700 bg-white border border-slate-200 hover:bg-slate-100"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Add Customer Modal */}
      {addModalOpen && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-fadeIn">
          <div
            className="w-full max-w-md bg-white rounded-2xl shadow-2xl border border-slate-100 overflow-hidden"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="bg-gradient-to-r from-blue-600 to-indigo-700 px-6 py-4 text-white flex items-center justify-between">
              <h3 className="font-bold text-base font-display">Add New Customer</h3>
              <button onClick={() => setAddModalOpen(false)} className="text-white/80 hover:text-white">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleAddCustomer} className="p-6 space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Customer / Party Name</label>
                <input
                  type="text"
                  required
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  placeholder="e.g. Ramesh Patil"
                  className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Mobile Phone (for WhatsApp Reminders)</label>
                <input
                  type="tel"
                  required
                  value={newPhone}
                  onChange={(e) => setNewPhone(e.target.value)}
                  placeholder="e.g. 9823456789"
                  className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Address / Shop Landmark</label>
                <input
                  type="text"
                  value={newAddress}
                  onChange={(e) => setNewAddress(e.target.value)}
                  placeholder="e.g. Main Market, Shop No 4"
                  className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Opening Credit Due (₹)</label>
                <input
                  type="number"
                  value={newBalance}
                  onChange={(e) => setNewBalance(e.target.value)}
                  placeholder="0 (Enter past udhar if any)"
                  className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div className="pt-2 flex items-center justify-end gap-2.5">
                <button
                  type="button"
                  onClick={() => setAddModalOpen(false)}
                  className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 hover:bg-slate-100"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={modalLoading}
                  className="px-5 py-2 rounded-xl text-xs font-bold text-white bg-blue-600 hover:bg-blue-700 shadow-md shadow-blue-500/20 disabled:opacity-60"
                >
                  {modalLoading ? 'Saving...' : 'Save Customer'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
