import React from 'react';
import { 
  ArrowUpRight, 
  Clock, 
  CheckCircle, 
  Activity,
  Sparkles
} from 'lucide-react';

export const Analytics: React.FC = () => {
  return (
    <section id="insights" className="py-24 bg-white relative overflow-hidden">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Section Heading */}
        <div className="text-center max-w-3xl mx-auto mb-16 space-y-4">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs font-semibold tracking-wide">
            <Activity className="w-3.5 h-3.5 text-emerald-600" />
            <span>EXECUTIVE DECISION MAKING</span>
          </div>

          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-navy-950 font-display tracking-tight">
            Turn Business Data Into Better Decisions.
          </h2>

          <p className="text-base sm:text-lg text-slate-600 font-normal leading-relaxed">
            Every transaction, bill, and payment you record in ENX Money feeds into real-time business health metrics—giving you clear, actionable clarity without complicated accounting jargon.
          </p>
        </div>

        {/* Analytics Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-stretch">
          
          {/* Main Health Score Showcase (5 Cols) */}
          <div className="lg:col-span-5 bg-gradient-to-br from-navy-950 via-navy-900 to-navy-850 text-white rounded-3xl p-8 border border-navy-800 shadow-elevated flex flex-col justify-between relative overflow-hidden">
            
            {/* Ambient blur glow */}
            <div className="absolute top-0 right-0 w-64 h-64 bg-emerald-500/10 rounded-full blur-3xl pointer-events-none" />

            <div>
              <div className="flex items-center justify-between mb-6">
                <span className="text-xs font-bold text-emerald-400 uppercase tracking-wider flex items-center gap-1.5">
                  <Sparkles className="w-3.5 h-3.5" />
                  <span>Proprietary Index</span>
                </span>
                <span className="text-[11px] font-mono text-slate-400">ENX-BHS v2.0</span>
              </div>

              <h3 className="text-2xl font-bold font-display text-white mb-2">
                Business Health Score: <span className="text-emerald-400">82/100</span>
              </h3>

              <p className="text-sm text-slate-300 leading-relaxed mb-8">
                Your business health is categorized as <strong className="text-white">Robust</strong>. Your collection cycle is 3.2x faster than the industry average, with zero accounts overdue past 60 days.
              </p>

              {/* Visual Health Gauge */}
              <div className="bg-navy-900/90 rounded-2xl p-6 border border-navy-800 space-y-4">
                <div className="flex justify-between items-baseline">
                  <span className="text-xs text-slate-400 font-medium">Overall Performance</span>
                  <span className="text-2xl font-black text-emerald-400 font-display">82 / 100</span>
                </div>

                <div className="w-full h-3 rounded-full bg-navy-950 overflow-hidden p-0.5 border border-navy-800">
                  <div className="h-full bg-gradient-to-r from-emerald-500 via-emerald-400 to-cyan-400 rounded-full w-[82%]" />
                </div>

                <div className="grid grid-cols-2 gap-3 pt-2 text-xs">
                  <div className="p-2.5 rounded-lg bg-navy-950/60 border border-navy-850">
                    <span className="text-slate-400 block text-[10px]">Debtor Days</span>
                    <span className="text-sm font-bold text-white">9.4 Days</span>
                    <span className="text-[10px] text-emerald-400 block mt-0.5">Top 5% speed</span>
                  </div>

                  <div className="p-2.5 rounded-lg bg-navy-950/60 border border-navy-850">
                    <span className="text-slate-400 block text-[10px]">Operating Margin</span>
                    <span className="text-sm font-bold text-white">55.7%</span>
                    <span className="text-[10px] text-emerald-400 block mt-0.5">Healthy liquidity</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="pt-6 mt-6 border-t border-navy-800 flex items-center justify-between text-xs text-slate-400">
              <span>Updated automatically with each invoice</span>
              <span className="text-emerald-400 font-semibold flex items-center gap-1">
                <CheckCircle className="w-3.5 h-3.5" /> Verified
              </span>
            </div>

          </div>

          {/* Right Visual Charts & Cards (7 Cols) */}
          <div className="lg:col-span-7 space-y-6 flex flex-col justify-between">
            
            {/* Row 1: Sales, Expenses & Profit Summary */}
            <div className="bg-slate-50/80 rounded-2xl p-6 border border-slate-200/90 shadow-sm space-y-4">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                <div>
                  <h4 className="text-sm font-bold text-navy-950 uppercase tracking-wider">
                    Sales vs Expenses Trajectory
                  </h4>
                  <p className="text-xs text-slate-500">Year-to-Date financial reconciliation</p>
                </div>
                <div className="flex items-center gap-3 text-xs font-semibold">
                  <span className="text-emerald-700">● Sales: ₹18.42L</span>
                  <span className="text-slate-500">● Expenses: ₹8.15L</span>
                  <span className="text-navy-900 font-bold">● Net: ₹10.27L</span>
                </div>
              </div>

              {/* Visual Multi-Area Chart */}
              <div className="h-36 w-full pt-2">
                <svg viewBox="0 0 500 120" className="w-full h-full overflow-visible">
                  <defs>
                    <linearGradient id="analyticsSalesGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#10B981" stopOpacity="0.3" />
                      <stop offset="100%" stopColor="#10B981" stopOpacity="0.0" />
                    </linearGradient>
                  </defs>
                  
                  {/* Expense line (lower) */}
                  <path
                    d="M0,90 Q80,85 160,80 T320,70 T500,60"
                    fill="none"
                    stroke="#94A3B8"
                    strokeWidth="2"
                    strokeDasharray="4 4"
                  />
                  
                  {/* Sales area (rising) */}
                  <path
                    d="M0,95 Q80,75 160,60 T320,40 T500,15 L500,120 L0,120 Z"
                    fill="url(#analyticsSalesGrad)"
                  />
                  <path
                    d="M0,95 Q80,75 160,60 T320,40 T500,15"
                    fill="none"
                    stroke="#10B981"
                    strokeWidth="3.5"
                    strokeLinecap="round"
                  />
                </svg>

                <div className="flex justify-between text-[11px] text-slate-500 font-medium pt-2">
                  <span>Q1 (Apr-Jun)</span>
                  <span>Q2 (Jul-Sep)</span>
                  <span>Q3 (Oct-Dec)</span>
                  <span className="font-bold text-navy-950">Q4 (Projected)</span>
                </div>
              </div>
            </div>

            {/* Row 2: Cash Flow & Receivables Aging */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              
              {/* Cash Flow Widget */}
              <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-sm flex flex-col justify-between">
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-xs font-bold text-navy-950 uppercase">Cash Flow Stability</span>
                    <ArrowUpRight className="w-4 h-4 text-emerald-600" />
                  </div>
                  <div className="text-2xl font-black text-navy-950 font-display">
                    +₹8,92,400
                  </div>
                  <div className="text-[11px] text-emerald-700 font-semibold mt-0.5">
                    Net Positive Monthly Reserve
                  </div>
                </div>

                <div className="space-y-1.5 pt-4 border-t border-slate-100 text-xs">
                  <div className="flex justify-between text-slate-600">
                    <span>Cash Inflow:</span>
                    <span className="font-semibold text-emerald-700">₹16,84,000</span>
                  </div>
                  <div className="flex justify-between text-slate-600">
                    <span>Vendor Outflow:</span>
                    <span className="font-semibold text-slate-700">₹7,91,600</span>
                  </div>
                </div>
              </div>

              {/* Receivables Aging Widget */}
              <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-sm flex flex-col justify-between">
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-xs font-bold text-navy-950 uppercase">Receivables Aging</span>
                    <Clock className="w-4 h-4 text-slate-400" />
                  </div>
                  <div className="text-2xl font-black text-navy-950 font-display">
                    ₹2,45,000
                  </div>
                  <div className="text-[11px] text-slate-500 font-medium mt-0.5">
                    Total pending from 6 parties
                  </div>
                </div>

                <div className="space-y-1.5 pt-4 border-t border-slate-100 text-xs">
                  <div className="flex justify-between text-slate-600">
                    <span>0–30 Days (Current):</span>
                    <span className="font-bold text-emerald-700">₹1,85,000 (75%)</span>
                  </div>
                  <div className="flex justify-between text-slate-600">
                    <span>31–60 Days (Follow-up):</span>
                    <span className="font-bold text-amber-600">₹60,000 (25%)</span>
                  </div>
                  <div className="flex justify-between text-slate-600">
                    <span>&gt;60 Days (Overdue):</span>
                    <span className="font-bold text-emerald-600">₹0 (0% Bad Debts)</span>
                  </div>
                </div>
              </div>

            </div>

          </div>

        </div>

      </div>
    </section>
  );
};
