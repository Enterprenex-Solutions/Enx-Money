import React from 'react';
import { 
  Building2, 
  FileSpreadsheet, 
  Sparkles, 
  Smartphone, 
  Lock, 
  LineChart 
} from 'lucide-react';
import { TRUST_POINTS } from '../data/content';

const iconMap: Record<string, React.ReactNode> = {
  Building2: <Building2 className="w-5 h-5 text-emerald-600" />,
  FileSpreadsheet: <FileSpreadsheet className="w-5 h-5 text-emerald-600" />,
  Sparkles: <Sparkles className="w-5 h-5 text-emerald-600" />,
  Smartphone: <Smartphone className="w-5 h-5 text-emerald-600" />,
  Lock: <Lock className="w-5 h-5 text-emerald-600" />,
  LineChart: <LineChart className="w-5 h-5 text-emerald-600" />,
};

export const TrustSection: React.FC = () => {
  return (
    <section className="py-20 bg-slate-50/60 border-y border-slate-200/80">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Section Header */}
        <div className="text-center max-w-2xl mx-auto mb-12">
          <h3 className="text-xs font-bold text-navy-900 uppercase tracking-widest mb-2">
            ENGINEERED WITH PURPOSE
          </h3>
          <p className="text-2xl sm:text-3xl font-extrabold text-navy-950 font-display">
            Built on Real Product Integrity
          </p>
        </div>

        {/* 6 Trust Points Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {TRUST_POINTS.map((item) => (
            <div
              key={item.title}
              className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm hover:shadow-md transition-shadow flex items-start gap-4"
            >
              <div className="w-10 h-10 rounded-xl bg-slate-50 border border-slate-100 flex items-center justify-center shrink-0">
                {iconMap[item.icon]}
              </div>

              <div>
                <h4 className="text-base font-bold text-navy-950 font-display mb-1">
                  {item.title}
                </h4>
                <p className="text-xs text-slate-600 leading-relaxed font-normal">
                  {item.description}
                </p>
              </div>
            </div>
          ))}
        </div>

      </div>
    </section>
  );
};
