import React from 'react';
import { 
  BookOpen, 
  FileCheck, 
  Package, 
  Wallet, 
  Users, 
  BarChart3, 
  TrendingUp, 
  ShieldCheck,
  ArrowRight,
  Sparkles
} from 'lucide-react';
import { FEATURES, type FeatureItem } from '../data/content';

const iconMap: Record<string, React.ReactNode> = {
  BookOpen: <BookOpen className="w-6 h-6 text-emerald-600" />,
  FileCheck: <FileCheck className="w-6 h-6 text-emerald-600" />,
  Package: <Package className="w-6 h-6 text-emerald-600" />,
  Wallet: <Wallet className="w-6 h-6 text-emerald-600" />,
  Users: <Users className="w-6 h-6 text-emerald-600" />,
  BarChart3: <BarChart3 className="w-6 h-6 text-emerald-600" />,
  TrendingUp: <TrendingUp className="w-6 h-6 text-emerald-600" />,
  ShieldCheck: <ShieldCheck className="w-6 h-6 text-emerald-600" />,
};

export const Features: React.FC = () => {
  return (
    <section id="features" className="py-24 bg-slate-50/70 relative">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Section Heading */}
        <div className="text-center max-w-3xl mx-auto mb-16 space-y-4">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs font-semibold tracking-wide">
            <Sparkles className="w-3.5 h-3.5 text-emerald-600" />
            <span>BUILT FOR DAILY OPERATIONS</span>
          </div>

          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-navy-950 font-display tracking-tight">
            Everything You Need to Run Your Business
          </h2>

          <p className="text-base sm:text-lg text-slate-600 font-normal leading-relaxed">
            Eliminate paperwork, manual calculators, and scattered spreadsheets. ENX Money consolidates every aspect of your enterprise into eight powerful capabilities.
          </p>
        </div>

        {/* 8-Card Modern Feature Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {FEATURES.map((feature: FeatureItem, index: number) => (
            <div
              key={feature.id}
              className="bg-white rounded-2xl p-6 border border-slate-200/90 shadow-sm hover:shadow-premium hover:-translate-y-1 transition-all duration-300 flex flex-col justify-between group relative overflow-hidden"
            >
              {/* Top subtle hover accent line */}
              <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-navy-900 to-emerald-500 opacity-0 group-hover:opacity-100 transition-opacity" />

              <div>
                {/* Header row: Icon + Badge */}
                <div className="flex items-center justify-between mb-5">
                  <div className="w-12 h-12 rounded-xl bg-slate-50 border border-slate-100 flex items-center justify-center group-hover:bg-emerald-50 group-hover:border-emerald-200 transition-colors">
                    {iconMap[feature.iconName]}
                  </div>

                  {feature.badge && (
                    <span className="text-[10px] font-bold text-slate-500 bg-slate-100 px-2.5 py-1 rounded-full uppercase tracking-wider group-hover:bg-emerald-100 group-hover:text-emerald-800 transition-colors">
                      {feature.badge}
                    </span>
                  )}
                </div>

                {/* Feature Title & Tagline */}
                <h3 className="text-lg font-bold text-navy-950 font-display mb-1 group-hover:text-emerald-600 transition-colors">
                  {feature.title}
                </h3>
                
                <div className="text-xs font-semibold text-slate-400 mb-3 uppercase tracking-wider">
                  {feature.tagline}
                </div>

                {/* Description */}
                <p className="text-sm text-slate-600 leading-relaxed font-normal">
                  {feature.description}
                </p>
              </div>

              {/* Bottom number indicator */}
              <div className="pt-6 mt-4 border-t border-slate-100 flex items-center justify-between text-xs text-slate-400 font-semibold">
                <span>0{index + 1}</span>
                <span className="text-emerald-600 opacity-0 group-hover:opacity-100 flex items-center gap-1 transition-all group-hover:translate-x-0.5">
                  Learn more <ArrowRight className="w-3.5 h-3.5" />
                </span>
              </div>
            </div>
          ))}
        </div>

      </div>
    </section>
  );
};
