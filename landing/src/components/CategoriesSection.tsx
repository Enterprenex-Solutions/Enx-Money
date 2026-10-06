import React, { useState } from 'react';
import { 
  Store, 
  Smartphone, 
  Wrench, 
  Shirt, 
  Pill, 
  Truck, 
  CheckCircle,
  TrendingUp,
  Send,
  BookOpen
} from 'lucide-react';
import { STATS, BUSINESS_CATEGORIES, WORKFLOW_STEPS } from '../data/content';

const iconMap: Record<string, React.ReactNode> = {
  Store: <Store className="w-6 h-6 text-emerald-600" />,
  Smartphone: <Smartphone className="w-6 h-6 text-blue-600" />,
  Wrench: <Wrench className="w-6 h-6 text-amber-600" />,
  Shirt: <Shirt className="w-6 h-6 text-purple-600" />,
  Pill: <Pill className="w-6 h-6 text-rose-600" />,
  Truck: <Truck className="w-6 h-6 text-cyan-600" />,
};

export const CategoriesSection: React.FC = () => {
  const [activeStep, setActiveStep] = useState<number>(0);

  return (
    <section id="categories" className="py-16 lg:py-24 bg-white relative overflow-hidden border-y border-slate-100">
      
      {/* ── Top Metrics Bar (OkCredit Screenshot 3 Style) ── */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mb-16 lg:mb-20">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-6 lg:gap-8 text-center divide-y md:divide-y-0 md:divide-x divide-slate-100">
          {STATS.map((stat, idx) => (
            <div key={idx} className="pt-4 md:pt-0 md:px-4">
              <div className="text-3xl sm:text-4xl lg:text-5xl font-black text-emerald-600 tracking-tight font-display">
                {stat.value}
              </div>
              <div className="mt-1 text-sm font-bold text-slate-800">
                {stat.label}
              </div>
              <div className="text-xs text-slate-500 font-medium">
                {stat.sub}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* ── Main Section: HAR DHANDHE KE LIYE ── */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Section Header */}
        <div className="text-center max-w-3xl mx-auto mb-10 sm:mb-12">
          <div className="inline-flex items-center gap-2 bg-emerald-50 text-emerald-700 border border-emerald-200/90 rounded-full px-4 py-1 text-xs font-black uppercase tracking-wider mb-4">
            HAR DHANDHE KE LIYE
          </div>
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-black text-slate-900 tracking-tight font-display">
            Aapke business ke liye bana hai ENX Money
          </h2>
          <p className="mt-4 text-base sm:text-lg text-slate-600 leading-relaxed">
            Kirana se wholesale tak, jahan bhi udhar aur billing chalta hai, wahan ENX Money chalta hai. India ke 50+ business categories ke vyapari roz apna khata ENX Money par likhte hain.
          </p>

          {/* Interactive 3-Step Pill Selector (Screenshot 3) */}
          <div className="mt-8 inline-flex items-center p-1.5 bg-slate-100/90 rounded-full border border-slate-200 shadow-inner">
            {WORKFLOW_STEPS.map((step, idx) => (
              <button
                key={step.id}
                onClick={() => setActiveStep(idx)}
                className={`flex items-center gap-2 px-4 sm:px-6 py-2 rounded-full text-xs sm:text-sm font-bold transition-all duration-200 ${
                  activeStep === idx
                    ? 'bg-emerald-600 text-white shadow-md shadow-emerald-600/25'
                    : 'text-slate-600 hover:text-slate-900'
                }`}
              >
                <span className={`w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-black ${
                  activeStep === idx ? 'bg-white/20 text-white' : 'bg-slate-200 text-slate-700'
                }`}>
                  {step.step}
                </span>
                <span>{step.title}</span>
              </button>
            ))}
          </div>

          {/* Active Step Explainer Card */}
          <div className="mt-6 max-w-xl mx-auto bg-emerald-50/70 border border-emerald-200 rounded-2xl p-4 text-left flex items-start gap-4 transition-all">
            <div className="w-10 h-10 rounded-xl bg-emerald-600 text-white flex items-center justify-center shrink-0 shadow-sm">
              {activeStep === 0 && <BookOpen className="w-5 h-5" />}
              {activeStep === 1 && <Send className="w-5 h-5" />}
              {activeStep === 2 && <TrendingUp className="w-5 h-5" />}
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-xs font-black uppercase tracking-wider text-emerald-800">
                  {WORKFLOW_STEPS[activeStep].tag}
                </span>
                <span className="text-[10px] bg-white text-emerald-700 font-extrabold px-2 py-0.5 rounded-full border border-emerald-200">
                  {WORKFLOW_STEPS[activeStep].badge}
                </span>
              </div>
              <p className="text-xs sm:text-sm text-slate-700 font-medium mt-1 leading-normal">
                {WORKFLOW_STEPS[activeStep].description}
              </p>
            </div>
          </div>
        </div>

        {/* ── Business Categories Grid ── */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {BUSINESS_CATEGORIES.map((cat) => (
            <div
              key={cat.id}
              className="bg-white border border-slate-200/90 rounded-2xl p-6 hover:shadow-lg hover:border-emerald-300 transition-all duration-300 group relative overflow-hidden"
            >
              {/* Category Badge */}
              <div className="flex items-center justify-between mb-4">
                <div className="w-12 h-12 rounded-xl bg-slate-50 border border-slate-100 flex items-center justify-center group-hover:scale-110 transition-transform">
                  {iconMap[cat.icon]}
                </div>
                <span className="text-[11px] font-extrabold text-emerald-700 bg-emerald-50 border border-emerald-200 px-2.5 py-0.5 rounded-full">
                  {cat.tag}
                </span>
              </div>

              {/* Title & Description */}
              <h3 className="text-lg font-black text-slate-900 group-hover:text-emerald-700 transition-colors font-display">
                {cat.title}
              </h3>
              <p className="mt-2 text-sm text-slate-600 leading-relaxed font-medium">
                {cat.sub}
              </p>

              {/* Verified Features Checklist */}
              <div className="mt-4 pt-4 border-t border-slate-100 flex items-center gap-4 text-xs font-bold text-slate-700">
                <span className="flex items-center gap-1">
                  <CheckCircle className="w-3.5 h-3.5 text-emerald-600" />
                  Instant Ledger
                </span>
                <span className="flex items-center gap-1">
                  <CheckCircle className="w-3.5 h-3.5 text-emerald-600" />
                  UPI Collection
                </span>
              </div>
            </div>
          ))}
        </div>

      </div>
    </section>
  );
};
