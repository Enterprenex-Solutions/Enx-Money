import React, { useState } from 'react';
import { 
  LayoutDashboard, 
  FileSpreadsheet, 
  Package, 
  BarChart, 
  ArrowUpRight, 
  Download, 
  Share2, 
  AlertCircle, 
  Plus
} from 'lucide-react';

type TabType = 'dashboard' | 'invoices' | 'inventory' | 'reports';

export const DashboardShowcase: React.FC = () => {
  const [activeTab, setActiveTab] = useState<TabType>('dashboard');

  return (
    <section id="solutions" className="py-24 bg-gradient-to-b from-slate-50 to-white relative">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Section Heading */}
        <div className="text-center max-w-3xl mx-auto mb-12 space-y-4">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-navy-50 border border-navy-100 text-navy-800 text-xs font-semibold tracking-wide">
            <LayoutDashboard className="w-3.5 h-3.5 text-emerald-600" />
            <span>INTERACTIVE PRODUCT PREVIEW</span>
          </div>

          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-navy-950 font-display tracking-tight">
            Everything Your Business Needs. One Dashboard.
          </h2>

          <p className="text-base sm:text-lg text-slate-600 font-normal leading-relaxed">
            Click through the operational modules below to experience how ENX Money organizes billing, ledger accounts, inventory, and executive reporting.
          </p>
        </div>

        {/* Tab Toggle Bar */}
        <div className="flex justify-center mb-10">
          <div className="inline-flex p-1.5 rounded-2xl bg-white border border-slate-200/90 shadow-sm max-w-full overflow-x-auto">
            <button
              type="button"
              onClick={() => setActiveTab('dashboard')}
              className={`flex items-center gap-2 px-5 py-2.5 rounded-xl font-bold text-sm transition-all whitespace-nowrap ${
                activeTab === 'dashboard'
                  ? 'bg-navy-900 text-white shadow-md'
                  : 'text-slate-600 hover:text-navy-950 hover:bg-slate-50'
              }`}
            >
              <LayoutDashboard className="w-4 h-4" />
              <span>Dashboard</span>
            </button>

            <button
              type="button"
              onClick={() => setActiveTab('invoices')}
              className={`flex items-center gap-2 px-5 py-2.5 rounded-xl font-bold text-sm transition-all whitespace-nowrap ${
                activeTab === 'invoices'
                  ? 'bg-navy-900 text-white shadow-md'
                  : 'text-slate-600 hover:text-navy-950 hover:bg-slate-50'
              }`}
            >
              <FileSpreadsheet className="w-4 h-4" />
              <span>Invoices</span>
            </button>

            <button
              type="button"
              onClick={() => setActiveTab('inventory')}
              className={`flex items-center gap-2 px-5 py-2.5 rounded-xl font-bold text-sm transition-all whitespace-nowrap ${
                activeTab === 'inventory'
                  ? 'bg-navy-900 text-white shadow-md'
                  : 'text-slate-600 hover:text-navy-950 hover:bg-slate-50'
              }`}
            >
              <Package className="w-4 h-4" />
              <span>Inventory</span>
            </button>

            <button
              type="button"
              onClick={() => setActiveTab('reports')}
              className={`flex items-center gap-2 px-5 py-2.5 rounded-xl font-bold text-sm transition-all whitespace-nowrap ${
                activeTab === 'reports'
                  ? 'bg-navy-900 text-white shadow-md'
                  : 'text-slate-600 hover:text-navy-950 hover:bg-slate-50'
              }`}
            >
              <BarChart className="w-4 h-4" />
              <span>Reports</span>
            </button>
          </div>
        </div>

        {/* Dashboard Display Frame */}
        <div className="bg-white rounded-3xl shadow-elevated border border-slate-200/90 overflow-hidden transition-all duration-300">
          
          {/* Top Browser / App chrome simulation */}
          <div className="bg-navy-950 px-6 py-4 flex items-center justify-between border-b border-navy-800">
            <div className="flex items-center gap-3">
              <div className="flex gap-1.5">
                <span className="w-3 h-3 rounded-full bg-rose-500/80 inline-block"></span>
                <span className="w-3 h-3 rounded-full bg-amber-500/80 inline-block"></span>
                <span className="w-3 h-3 rounded-full bg-emerald-500/80 inline-block"></span>
              </div>
              <div className="hidden sm:block text-xs font-mono text-slate-400 bg-navy-900 px-3 py-1 rounded-md border border-navy-800">
                https://enxmoney.enterprenex.solutions/portal/business-ops
              </div>
            </div>

            <div className="flex items-center gap-4 text-xs text-slate-300">
              <span className="flex items-center gap-1.5">
                <span className="w-2 h-2 rounded-full bg-emerald-400"></span>
                <span className="font-semibold text-white">Live Cloud Sync</span>
              </span>
              <span className="text-slate-500">|</span>
              <span className="text-slate-400 font-mono">FY 2026-27</span>
            </div>
          </div>

          {/* Dynamic Content Views */}
          <div className="p-6 sm:p-8 bg-slate-50/60 min-h-[520px]">
            
            {/* VIEW 1: DASHBOARD */}
            {activeTab === 'dashboard' && (
              <div className="space-y-6 animate-fadeIn">
                {/* Row 1: 5 Financial Cards */}
                <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
                  <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
                    <div className="text-xs font-medium text-slate-500">Total Sales (YTD)</div>
                    <div className="text-xl font-extrabold text-navy-950 font-display mt-1">₹18,42,800</div>
                    <div className="text-[11px] text-emerald-600 font-semibold mt-1 flex items-center gap-0.5">
                      <ArrowUpRight className="w-3 h-3" /> +22.4% YoY
                    </div>
                  </div>

                  <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
                    <div className="text-xs font-medium text-slate-500">Total Expenses</div>
                    <div className="text-xl font-extrabold text-navy-950 font-display mt-1">₹8,15,400</div>
                    <div className="text-[11px] text-slate-500 font-medium mt-1">Operational + COGS</div>
                  </div>

                  <div className="bg-emerald-50/40 p-4 rounded-xl border border-emerald-200 shadow-sm">
                    <div className="text-xs font-semibold text-emerald-900">Net Profit</div>
                    <div className="text-xl font-extrabold text-emerald-700 font-display mt-1">₹10,27,400</div>
                    <div className="text-[11px] text-emerald-800 font-bold mt-1">55.7% Margin</div>
                  </div>

                  <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
                    <div className="text-xs font-medium text-slate-500">Receivables (To Get)</div>
                    <div className="text-xl font-extrabold text-amber-600 font-display mt-1">₹2,45,000</div>
                    <div className="text-[11px] text-slate-500 font-medium mt-1">6 Customers</div>
                  </div>

                  <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
                    <div className="text-xs font-medium text-slate-500">Payables (To Give)</div>
                    <div className="text-xl font-extrabold text-slate-700 font-display mt-1">₹98,500</div>
                    <div className="text-[11px] text-slate-500 font-medium mt-1">3 Vendors Due</div>
                  </div>
                </div>

                {/* Row 2: Sales Chart & Action Bar */}
                <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
                  {/* Chart */}
                  <div className="lg:col-span-8 bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
                    <div className="flex items-center justify-between mb-4">
                      <div>
                        <div className="text-sm font-bold text-navy-950">Cash Inflow vs Outflow</div>
                        <div className="text-xs text-slate-500">Monthly reconciliation</div>
                      </div>
                      <div className="flex items-center gap-3 text-xs font-medium">
                        <span className="flex items-center gap-1.5 text-emerald-700">
                          <span className="w-2.5 h-2.5 rounded-sm bg-emerald-500"></span> Sales Inflow
                        </span>
                        <span className="flex items-center gap-1.5 text-slate-500">
                          <span className="w-2.5 h-2.5 rounded-sm bg-slate-300"></span> Expenses
                        </span>
                      </div>
                    </div>

                    {/* Visual Bar Graph */}
                    <div className="h-44 flex items-end justify-between gap-3 pt-4 border-b border-slate-100">
                      {[
                        { month: 'Apr', in: 65, out: 30 },
                        { month: 'May', in: 75, out: 35 },
                        { month: 'Jun', in: 70, out: 28 },
                        { month: 'Jul', in: 85, out: 40 },
                        { month: 'Aug', in: 95, out: 45 },
                        { month: 'Sep', in: 110, out: 48 },
                        { month: 'Oct', in: 125, out: 52 },
                      ].map((item) => (
                        <div key={item.month} className="flex-1 flex flex-col items-center gap-1">
                          <div className="w-full flex items-end justify-center gap-1.5 h-36">
                            <div
                              style={{ height: `${(item.in / 130) * 100}%` }}
                              className="w-1/2 max-w-[20px] bg-emerald-500 rounded-t-sm transition-all"
                            />
                            <div
                              style={{ height: `${(item.out / 130) * 100}%` }}
                              className="w-1/2 max-w-[20px] bg-slate-300 rounded-t-sm transition-all"
                            />
                          </div>
                          <span className="text-[11px] font-medium text-slate-500">{item.month}</span>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Quick Khata Activity */}
                  <div className="lg:col-span-4 bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex flex-col justify-between">
                    <div>
                      <div className="text-sm font-bold text-navy-950 mb-3">Live Khata Ledger</div>
                      <div className="space-y-3">
                        <div className="flex items-center justify-between text-xs pb-2 border-b border-slate-100">
                          <div>
                            <div className="font-bold text-slate-800">Radha Krishna Kirana</div>
                            <div className="text-[10px] text-slate-400">Received via PhonePe</div>
                          </div>
                          <span className="font-bold text-emerald-600">+₹12,400</span>
                        </div>
                        <div className="flex items-center justify-between text-xs pb-2 border-b border-slate-100">
                          <div>
                            <div className="font-bold text-slate-800">Shivaji Traders Pune</div>
                            <div className="text-[10px] text-slate-400">Credit given (Khata)</div>
                          </div>
                          <span className="font-bold text-amber-600">₹34,000 Due</span>
                        </div>
                        <div className="flex items-center justify-between text-xs">
                          <div>
                            <div className="font-bold text-slate-800">Sai Steel Distributors</div>
                            <div className="text-[10px] text-slate-400">Vendor Payment Made</div>
                          </div>
                          <span className="font-bold text-slate-700">-₹22,500</span>
                        </div>
                      </div>
                    </div>

                    <div className="pt-4 border-t border-slate-100">
                      <div className="bg-slate-50 p-2.5 rounded-xl text-[11px] text-slate-600 flex items-center justify-between font-medium">
                        <span>WhatsApp Reminders:</span>
                        <span className="text-emerald-700 font-bold">14 Sent Today</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* VIEW 2: INVOICES */}
            {activeTab === 'invoices' && (
              <div className="space-y-6 animate-fadeIn">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-slate-200">
                  <div>
                    <h4 className="text-lg font-bold text-navy-950">GST Tax Invoices</h4>
                    <p className="text-xs text-slate-500">Automated CGST/SGST/IGST compliance with instant PDF delivery</p>
                  </div>
                  <div className="flex items-center gap-2">
                    <button className="px-3 py-1.5 bg-navy-900 text-white rounded-lg text-xs font-semibold flex items-center gap-1.5 shadow-sm">
                      <Plus className="w-3.5 h-3.5 text-emerald-400" /> Create GST Bill
                    </button>
                    <button className="px-3 py-1.5 bg-white border border-slate-200 text-slate-700 rounded-lg text-xs font-semibold flex items-center gap-1.5">
                      <Download className="w-3.5 h-3.5" /> Export GSTR-1
                    </button>
                  </div>
                </div>

                {/* Invoices Table */}
                <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-sm">
                  <div className="overflow-x-auto">
                    <table className="w-full text-left text-xs">
                      <thead className="bg-slate-50 border-b border-slate-200 text-slate-500 font-semibold uppercase tracking-wider">
                        <tr>
                          <th className="py-3 px-4">Invoice #</th>
                          <th className="py-3 px-4">Client Name</th>
                          <th className="py-3 px-4">Date</th>
                          <th className="py-3 px-4">Taxable</th>
                          <th className="py-3 px-4">GST</th>
                          <th className="py-3 px-4">Total</th>
                          <th className="py-3 px-4">Status</th>
                          <th className="py-3 px-4 text-right">Actions</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-100 font-medium text-slate-700">
                        <tr>
                          <td className="py-3 px-4 font-mono font-bold text-navy-900">ENX/2026/0412</td>
                          <td className="py-3 px-4">Mahindra Logistics Ltd.</td>
                          <td className="py-3 px-4 text-slate-500">04 Oct 2026</td>
                          <td className="py-3 px-4">₹46,000</td>
                          <td className="py-3 px-4 text-slate-500">₹8,280 (18% IGST)</td>
                          <td className="py-3 px-4 font-bold text-navy-950">₹54,280</td>
                          <td className="py-3 px-4">
                            <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                              PAID
                            </span>
                          </td>
                          <td className="py-3 px-4 text-right">
                            <button className="text-slate-400 hover:text-navy-900 p-1">
                              <Download className="w-4 h-4 inline" />
                            </button>
                          </td>
                        </tr>

                        <tr>
                          <td className="py-3 px-4 font-mono font-bold text-navy-900">ENX/2026/0411</td>
                          <td className="py-3 px-4">Apollo Diagnostic Solutions</td>
                          <td className="py-3 px-4 text-slate-500">02 Oct 2026</td>
                          <td className="py-3 px-4">₹72,500</td>
                          <td className="py-3 px-4 text-slate-500">₹13,050 (CGST+SGST)</td>
                          <td className="py-3 px-4 font-bold text-navy-950">₹85,550</td>
                          <td className="py-3 px-4">
                            <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-50 text-amber-700 border border-amber-200">
                              PENDING
                            </span>
                          </td>
                          <td className="py-3 px-4 text-right">
                            <button className="text-slate-400 hover:text-navy-900 p-1">
                              <Share2 className="w-4 h-4 inline" />
                            </button>
                          </td>
                        </tr>

                        <tr>
                          <td className="py-3 px-4 font-mono font-bold text-navy-900">ENX/2026/0410</td>
                          <td className="py-3 px-4">Tata AutoComp Systems</td>
                          <td className="py-3 px-4 text-slate-500">28 Sep 2026</td>
                          <td className="py-3 px-4">₹1,10,000</td>
                          <td className="py-3 px-4 text-slate-500">₹19,800 (18% IGST)</td>
                          <td className="py-3 px-4 font-bold text-navy-950">₹1,29,800</td>
                          <td className="py-3 px-4">
                            <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                              PAID
                            </span>
                          </td>
                          <td className="py-3 px-4 text-right">
                            <button className="text-slate-400 hover:text-navy-900 p-1">
                              <Download className="w-4 h-4 inline" />
                            </button>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            )}

            {/* VIEW 3: INVENTORY */}
            {activeTab === 'inventory' && (
              <div className="space-y-6 animate-fadeIn">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-slate-200">
                  <div>
                    <h4 className="text-lg font-bold text-navy-950">Live Stock & Valuation Catalogue</h4>
                    <p className="text-xs text-slate-500">Track purchase prices, selling rates, and automated low-stock warnings</p>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-semibold px-3 py-1 rounded-lg bg-emerald-50 text-emerald-700 border border-emerald-200">
                      Total Valuation: ₹14,80,000
                    </span>
                  </div>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                  <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-bold text-navy-900">Industrial Copper Wire 2.5mm</span>
                      <span className="text-[10px] px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700 font-bold">In Stock</span>
                    </div>
                    <div className="mt-2 text-2xl font-extrabold text-navy-950 font-display">120 <span className="text-xs font-normal text-slate-500">Coils</span></div>
                    <div className="mt-3 pt-2 border-t border-slate-100 flex justify-between text-xs text-slate-500">
                      <span>Buy: ₹1,250</span>
                      <span className="font-bold text-emerald-600">Sell: ₹1,680 (34% Margin)</span>
                    </div>
                  </div>

                  <div className="bg-white p-4 rounded-xl border border-amber-200 bg-amber-50/10 shadow-sm">
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-bold text-navy-900">Aluminium Conduit Pipe 1-inch</span>
                      <span className="text-[10px] px-2 py-0.5 rounded-full bg-amber-100 text-amber-800 font-bold flex items-center gap-1">
                        <AlertCircle className="w-2.5 h-2.5" /> Low Stock
                      </span>
                    </div>
                    <div className="mt-2 text-2xl font-extrabold text-amber-700 font-display">14 <span className="text-xs font-normal text-slate-500">Bundles</span></div>
                    <div className="mt-3 pt-2 border-t border-slate-100 flex justify-between text-xs text-slate-500">
                      <span>Reorder level: 25</span>
                      <span className="font-bold text-navy-900">Sell: ₹450 / pc</span>
                    </div>
                  </div>

                  <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-bold text-navy-900">LED Modular Panel 18W</span>
                      <span className="text-[10px] px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700 font-bold">In Stock</span>
                    </div>
                    <div className="mt-2 text-2xl font-extrabold text-navy-950 font-display">240 <span className="text-xs font-normal text-slate-500">Units</span></div>
                    <div className="mt-3 pt-2 border-t border-slate-100 flex justify-between text-xs text-slate-500">
                      <span>Buy: ₹280</span>
                      <span className="font-bold text-emerald-600">Sell: ₹420 (50% Margin)</span>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* VIEW 4: REPORTS */}
            {activeTab === 'reports' && (
              <div className="space-y-6 animate-fadeIn">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-slate-200">
                  <div>
                    <h4 className="text-lg font-bold text-navy-950">Executive Financial & Tax Reports</h4>
                    <p className="text-xs text-slate-500">Instant generation of Profit & Loss, Balance Sheet, Daybook and GSTR-3B filings</p>
                  </div>
                  <div className="flex items-center gap-2">
                    <button className="px-3.5 py-1.5 bg-navy-900 text-white rounded-lg text-xs font-semibold flex items-center gap-1.5 shadow-sm">
                      <Download className="w-3.5 h-3.5 text-emerald-400" /> Download Full P&L (PDF)
                    </button>
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                  <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-3">
                    <div className="text-xs font-bold text-navy-900 uppercase">Profit & Loss Summary</div>
                    <div className="space-y-2 text-xs">
                      <div className="flex justify-between text-slate-600">
                        <span>Gross Revenue:</span>
                        <span className="font-bold text-navy-950">₹18,42,800</span>
                      </div>
                      <div className="flex justify-between text-slate-600">
                        <span>Cost of Goods Sold (COGS):</span>
                        <span className="text-slate-800">₹6,20,000</span>
                      </div>
                      <div className="flex justify-between text-slate-600">
                        <span>Operating Overheads:</span>
                        <span className="text-slate-800">₹1,95,400</span>
                      </div>
                      <div className="pt-2 border-t border-slate-200 flex justify-between font-bold text-emerald-700">
                        <span>Net Operating Profit:</span>
                        <span>₹10,27,400</span>
                      </div>
                    </div>
                  </div>

                  <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-3">
                    <div className="text-xs font-bold text-navy-900 uppercase">GST Return Readiness</div>
                    <div className="space-y-2 text-xs">
                      <div className="flex justify-between text-slate-600">
                        <span>GSTR-1 Outward Supply:</span>
                        <span className="font-bold text-emerald-600">Ready (34 Invoices)</span>
                      </div>
                      <div className="flex justify-between text-slate-600">
                        <span>GSTR-3B Tax Liability:</span>
                        <span className="font-bold text-navy-950">₹1,44,200</span>
                      </div>
                      <div className="flex justify-between text-slate-600">
                        <span>Input Tax Credit (ITC):</span>
                        <span className="text-emerald-700">₹82,400</span>
                      </div>
                      <div className="pt-2 border-t border-slate-200 flex justify-between font-bold text-navy-950">
                        <span>Net Tax Payable:</span>
                        <span>₹61,800</span>
                      </div>
                    </div>
                  </div>

                  <div className="bg-navy-950 text-white p-5 rounded-2xl border border-navy-800 shadow-sm flex flex-col justify-between">
                    <div>
                      <div className="text-xs font-bold text-emerald-400 uppercase tracking-wider">Business Health Benchmark</div>
                      <div className="text-3xl font-black font-display text-white mt-2">82 / 100</div>
                      <p className="text-xs text-slate-400 mt-2 leading-relaxed">
                        Top quartile in debtor turnaround (9.4 days) and operating profit preservation compared to regional peers.
                      </p>
                    </div>
                    <div className="mt-4 pt-3 border-t border-navy-800 flex justify-between text-[11px] text-slate-400">
                      <span>Liquidity: Strong</span>
                      <span className="text-emerald-400 font-semibold">Audit Passed</span>
                    </div>
                  </div>
                </div>
              </div>
            )}

          </div>

        </div>

      </div>
    </section>
  );
};
