import React, { useState } from 'react';
import {
  LayoutDashboard,
  BookOpen,
  Users,
  Building2,
  FileText,
  Boxes,
  BarChart3,
  Settings,
  LogOut,
  Menu,
  X,
  Search,
  Plus,
  Globe
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { OverviewTab } from './OverviewTab';
import { KhataTab } from './KhataTab';
import { CustomersTab } from './CustomersTab';
import { SuppliersTab } from './SuppliersTab';
import { InvoicesTab } from './InvoicesTab';
import { InventoryTab } from './InventoryTab';
import { ReportsTab } from './ReportsTab';
import { SettingsTab } from './SettingsTab';
import { api } from '../../services/api';

interface DashboardLayoutProps {
  onBackToPublic: () => void;
}

export const DashboardLayout: React.FC<DashboardLayoutProps> = ({ onBackToPublic }) => {
  const { user, logout } = useAuth();
  const [activeTab, setActiveTab] = useState('overview');
  const [mobileSidebarOpen, setMobileSidebarOpen] = useState(false);

  // Global Quick Transaction Modal
  const [txModalOpen, setTxModalOpen] = useState(false);
  const [txType, setTxType] = useState<'CREDIT' | 'DEBIT'>('CREDIT');
  const [txTitle, setTxTitle] = useState('');
  const [txAmount, setTxAmount] = useState('');
  const [txCustomer, setTxCustomer] = useState('');
  const [txCategory, setTxCategory] = useState('Sales');
  const [txMode, setTxMode] = useState('UPI');
  const [txNotes, setTxNotes] = useState('');
  const [txLoading, setTxLoading] = useState(false);

  const navigationItems = [
    { id: 'overview', label: 'Overview', icon: LayoutDashboard },
    { id: 'khata', label: 'Bahi Khata', icon: BookOpen },
    { id: 'customers', label: 'Customers & Dues', icon: Users },
    { id: 'suppliers', label: 'Suppliers & Payables', icon: Building2 },
    { id: 'invoices', label: 'GST Invoices', icon: FileText },
    { id: 'inventory', label: 'Stock & Inventory', icon: Boxes },
    { id: 'reports', label: 'Financial Reports', icon: BarChart3 },
    { id: 'settings', label: 'Settings', icon: Settings },
  ];

  const handleOpenNewTransaction = (type: 'CREDIT' | 'DEBIT' = 'CREDIT') => {
    setTxType(type);
    setTxCategory(type === 'CREDIT' ? 'Sales' : 'Expense');
    setTxModalOpen(true);
  };

  const handleCreateTransactionSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!txTitle || !txAmount) return;

    setTxLoading(true);
    try {
      await api.createTransaction({
        title: txTitle,
        amount: Number(txAmount),
        type: txType,
        category: txCategory,
        customerName: txCustomer || (txType === 'CREDIT' ? 'Cash Customer' : 'Vendor'),
        paymentMode: txMode as any,
        notes: txNotes,
      });
      setTxModalOpen(false);
      setTxTitle('');
      setTxAmount('');
      setTxCustomer('');
      setTxNotes('');
      // Force refresh if active tab is overview or khata
      if (activeTab === 'overview' || activeTab === 'khata') {
        // Trigger re-render by switching briefly or state
        window.dispatchEvent(new Event('transaction-created'));
      }
    } catch (err) {
      console.error('Failed to create transaction:', err);
    } finally {
      setTxLoading(false);
    }
  };

  const handleSignOut = () => {
    logout();
    onBackToPublic();
  };

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col md:flex-row antialiased">
      {/* 1. Desktop Fixed Sidebar */}
      <aside className="hidden md:flex flex-col w-64 bg-white border-r border-slate-200/90 z-20 sticky top-0 h-screen select-none">
        {/* Brand Header */}
        <div className="p-5 border-b border-slate-100 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <img
              src="/enx-emblem.png"
              alt="ENX Money"
              className="w-9 h-9 object-contain rounded-xl p-0.5 border border-slate-100 shadow-sm"
            />
            <div>
              <div className="text-base font-black font-display tracking-tight text-slate-900 leading-none">
                ENX Money
              </div>
              <div className="text-[10px] text-blue-600 font-bold uppercase tracking-wider mt-1">
                Business Suite
              </div>
            </div>
          </div>
        </div>

        {/* Merchant Store Badge */}
        <div className="px-4 py-3 border-b border-slate-100 bg-slate-50/60">
          <div className="text-[10px] font-semibold text-slate-400 uppercase tracking-wider">
            Active Business
          </div>
          <div className="text-xs font-bold text-slate-900 truncate mt-0.5">
            {user?.businessName || 'Shri Ganesh Enterprises'}
          </div>
          <div className="text-[10px] text-slate-500 font-mono">
            {user?.gstin ? `GST: ${user.gstin}` : 'Non-GST Retailer'}
          </div>
        </div>

        {/* Navigation Links */}
        <nav className="flex-1 overflow-y-auto p-3 space-y-1">
          {navigationItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id)}
                className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-semibold transition-all ${
                  isActive
                    ? 'bg-blue-600 text-white shadow-md shadow-blue-500/20'
                    : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100/80'
                }`}
              >
                <Icon className={`w-4 h-4 ${isActive ? 'text-white' : 'text-slate-400'}`} />
                <span>{item.label}</span>
              </button>
            );
          })}
        </nav>

        {/* Sidebar Footer Controls */}
        <div className="p-4 border-t border-slate-100 space-y-2 bg-slate-50/50">
          <button
            onClick={onBackToPublic}
            className="w-full flex items-center gap-2.5 px-3 py-2 rounded-xl text-xs font-semibold text-slate-600 hover:bg-slate-200/70 transition-colors"
          >
            <Globe className="w-4 h-4 text-slate-400" />
            <span>Public Website</span>
          </button>
          <button
            onClick={handleSignOut}
            className="w-full flex items-center gap-2.5 px-3 py-2 rounded-xl text-xs font-semibold text-rose-600 hover:bg-rose-50 transition-colors"
          >
            <LogOut className="w-4 h-4 text-rose-500" />
            <span>Sign Out</span>
          </button>
        </div>
      </aside>

      {/* 2. Mobile Header Bar & Sidebar Drawer */}
      <header className="md:hidden bg-white border-b border-slate-200 px-4 py-3 flex items-center justify-between sticky top-0 z-30 shadow-sm">
        <div className="flex items-center gap-2.5">
          <button
            onClick={() => setMobileSidebarOpen(true)}
            className="p-1.5 rounded-lg text-slate-700 hover:bg-slate-100"
          >
            <Menu className="w-5 h-5" />
          </button>
          <img src="/enx-emblem.png" alt="ENX Money" className="w-7 h-7 object-contain" />
          <span className="font-bold text-sm text-slate-900 font-display">ENX Money</span>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => handleOpenNewTransaction('CREDIT')}
            className="px-3 py-1.5 rounded-lg bg-emerald-600 text-white font-bold text-xs flex items-center gap-1 shadow-sm"
          >
            <Plus className="w-3.5 h-3.5" />
            <span>Sale</span>
          </button>
          <button
            onClick={handleSignOut}
            className="p-1.5 rounded-lg text-slate-500 hover:bg-slate-100"
            title="Sign out"
          >
            <LogOut className="w-4 h-4" />
          </button>
        </div>
      </header>

      {/* Mobile Drawer Backdrop & Menu */}
      {mobileSidebarOpen && (
        <div className="fixed inset-0 z-50 flex md:hidden bg-slate-900/50 backdrop-blur-sm animate-fadeIn">
          <div className="w-64 bg-white h-full shadow-2xl flex flex-col p-4">
            <div className="flex items-center justify-between pb-4 border-b border-slate-100">
              <div className="flex items-center gap-2">
                <img src="/enx-emblem.png" alt="ENX Money" className="w-7 h-7 object-contain" />
                <span className="font-bold text-sm text-slate-900 font-display">ENX Money</span>
              </div>
              <button
                onClick={() => setMobileSidebarOpen(false)}
                className="p-1.5 rounded-lg text-slate-500 hover:bg-slate-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <nav className="flex-1 py-4 space-y-1 overflow-y-auto">
              {navigationItems.map((item) => {
                const Icon = item.icon;
                const isActive = activeTab === item.id;
                return (
                  <button
                    key={item.id}
                    onClick={() => {
                      setActiveTab(item.id);
                      setMobileSidebarOpen(false);
                    }}
                    className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-semibold transition-all ${
                      isActive
                        ? 'bg-blue-600 text-white font-bold'
                        : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                    }`}
                  >
                    <Icon className="w-4 h-4" />
                    <span>{item.label}</span>
                  </button>
                );
              })}
            </nav>

            <div className="pt-3 border-t border-slate-100 space-y-2">
              <button
                onClick={() => {
                  setMobileSidebarOpen(false);
                  onBackToPublic();
                }}
                className="w-full flex items-center gap-2 px-3 py-2 text-xs font-semibold text-slate-600 hover:bg-slate-100 rounded-lg"
              >
                <Globe className="w-4 h-4" />
                <span>Public Website</span>
              </button>
              <button
                onClick={handleSignOut}
                className="w-full flex items-center gap-2 px-3 py-2 text-xs font-semibold text-rose-600 hover:bg-rose-50 rounded-lg"
              >
                <LogOut className="w-4 h-4" />
                <span>Sign Out</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 3. Main Dashboard Workspace */}
      <main className="flex-1 flex flex-col min-w-0 h-screen overflow-y-auto">
        {/* Top Header Bar for Desktop */}
        <header className="hidden md:flex bg-white border-b border-slate-200/90 px-8 py-3.5 items-center justify-between sticky top-0 z-10">
          <div className="flex items-center gap-3 flex-1 max-w-md">
            <div className="relative w-full">
              <Search className="w-4 h-4 absolute left-3.5 top-2.5 text-slate-400" />
              <input
                type="text"
                placeholder="Search across transactions, customers, or GST invoices..."
                className="w-full pl-9 pr-4 py-1.5 text-xs rounded-xl border border-slate-200 bg-slate-50/50 focus:bg-white focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all"
              />
            </div>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={() => handleOpenNewTransaction('CREDIT')}
              className="px-3.5 py-2 rounded-xl text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 shadow-sm flex items-center gap-1.5 transition-all"
            >
              <Plus className="w-3.5 h-3.5" />
              <span>Record Sale (Got)</span>
            </button>
            <button
              onClick={() => handleOpenNewTransaction('DEBIT')}
              className="px-3.5 py-2 rounded-xl text-xs font-bold text-white bg-rose-600 hover:bg-rose-700 shadow-sm flex items-center gap-1.5 transition-all"
            >
              <Plus className="w-3.5 h-3.5" />
              <span>Record Expense (Gave)</span>
            </button>

            <div className="h-5 w-px bg-slate-200 mx-1" />

            <div className="flex items-center gap-2.5 pl-1">
              <div className="w-8 h-8 rounded-full bg-blue-100 text-blue-700 font-bold flex items-center justify-center text-xs">
                {user?.name?.charAt(0) || 'M'}
              </div>
              <div className="text-left hidden lg:block">
                <div className="text-xs font-bold text-slate-900 leading-tight">
                  {user?.name || 'Ramesh Kumar'}
                </div>
                <div className="text-[10px] text-slate-400 font-medium">Merchant Admin</div>
              </div>
            </div>
          </div>
        </header>

        {/* Tab Content Canvas */}
        <div className="p-4 sm:p-6 lg:p-8 flex-1">
          {activeTab === 'overview' && (
            <OverviewTab
              onNavigateTab={(tab) => setActiveTab(tab)}
              onOpenNewTransaction={handleOpenNewTransaction}
              onOpenNewInvoice={() => setActiveTab('invoices')}
            />
          )}

          {activeTab === 'khata' && (
            <KhataTab onOpenNewTransaction={handleOpenNewTransaction} />
          )}

          {activeTab === 'customers' && <CustomersTab />}

          {activeTab === 'suppliers' && <SuppliersTab />}

          {activeTab === 'invoices' && <InvoicesTab />}

          {activeTab === 'inventory' && <InventoryTab />}

          {activeTab === 'reports' && <ReportsTab />}

          {activeTab === 'settings' && <SettingsTab onSignOut={handleSignOut} />}
        </div>
      </main>

      {/* Global Quick Transaction Modal */}
      {txModalOpen && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-fadeIn">
          <div
            className="w-full max-w-md bg-white rounded-2xl shadow-2xl border border-slate-100 overflow-hidden"
            onClick={(e) => e.stopPropagation()}
          >
            <div
              className={`px-6 py-4 text-white flex items-center justify-between ${
                txType === 'CREDIT'
                  ? 'bg-gradient-to-r from-emerald-600 to-teal-700'
                  : 'bg-gradient-to-r from-rose-600 to-red-700'
              }`}
            >
              <div>
                <h3 className="font-bold text-base font-display">
                  {txType === 'CREDIT' ? 'Record Sale (You Got Money)' : 'Record Expense (You Gave Money)'}
                </h3>
                <p className="text-xs text-white/80">
                  {txType === 'CREDIT' ? 'Adds to sales and customer credits' : 'Deducts from cash and records expense'}
                </p>
              </div>
              <button onClick={() => setTxModalOpen(false)} className="text-white/80 hover:text-white">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreateTransactionSubmit} className="p-6 space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Amount in Rupees (₹)
                </label>
                <div className="relative">
                  <span className="absolute left-3.5 top-2.5 text-base font-bold text-slate-400">₹</span>
                  <input
                    type="number"
                    required
                    autoFocus
                    value={txAmount}
                    onChange={(e) => setTxAmount(e.target.value)}
                    placeholder="e.g. 1500"
                    className="w-full pl-8 pr-4 py-2.5 text-lg font-black font-display rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Transaction Title / Description
                </label>
                <input
                  type="text"
                  required
                  value={txTitle}
                  onChange={(e) => setTxTitle(e.target.value)}
                  placeholder={txType === 'CREDIT' ? 'e.g. Grocery counter sale' : 'e.g. Shop electricity bill'}
                  className="w-full px-3.5 py-2 text-xs rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Customer / Party Name
                  </label>
                  <input
                    type="text"
                    value={txCustomer}
                    onChange={(e) => setTxCustomer(e.target.value)}
                    placeholder="Party Name"
                    className="w-full px-3.5 py-2 text-xs rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Payment Mode
                  </label>
                  <select
                    value={txMode}
                    onChange={(e) => setTxMode(e.target.value)}
                    className="w-full px-3 py-2 text-xs rounded-xl border border-slate-200 bg-white"
                  >
                    <option value="UPI">UPI (GPay / PhonePe / Paytm)</option>
                    <option value="CASH">Cash in Hand</option>
                    <option value="BANK">Bank Transfer (NEFT/IMPS)</option>
                    <option value="CARD">Debit / Credit Card</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Additional Notes (Optional)
                </label>
                <input
                  type="text"
                  value={txNotes}
                  onChange={(e) => setTxNotes(e.target.value)}
                  placeholder="Optional reference notes..."
                  className="w-full px-3.5 py-2 text-xs rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div className="pt-2 flex items-center justify-end gap-2.5">
                <button
                  type="button"
                  onClick={() => setTxModalOpen(false)}
                  className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 hover:bg-slate-100"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={txLoading}
                  className={`px-5 py-2.5 rounded-xl text-xs font-bold text-white shadow-md transition-all ${
                    txType === 'CREDIT'
                      ? 'bg-emerald-600 hover:bg-emerald-700 shadow-emerald-500/20'
                      : 'bg-rose-600 hover:bg-rose-700 shadow-rose-500/20'
                  }`}
                >
                  {txLoading ? 'Saving...' : txType === 'CREDIT' ? 'Save Got Entry' : 'Save Gave Entry'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
