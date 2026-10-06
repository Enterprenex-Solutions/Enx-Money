import React from 'react';
import { HOW_IT_WORKS } from '../data/content';
import { UserCheck, Sliders, TrendingUp } from 'lucide-react';

const stepIcons = [
  <UserCheck className="w-6 h-6 text-emerald-600" />,
  <Sliders className="w-6 h-6 text-emerald-600" />,
  <TrendingUp className="w-6 h-6 text-emerald-600" />,
];

export const HowItWorks: React.FC = () => {
  return (
    <section id="how-it-works" className="py-24 bg-white relative overflow-hidden">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Section Heading */}
        <div className="text-center max-w-3xl mx-auto mb-20 space-y-4">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-navy-50 border border-navy-100 text-navy-800 text-xs font-semibold tracking-wide">
            <span>GET STARTED IN MINUTES</span>
          </div>

          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-navy-950 font-display tracking-tight">
            How ENX Money Works
          </h2>

          <p className="text-base sm:text-lg text-slate-600 font-normal leading-relaxed">
            Transitioning your business from paper khatas or complex software takes less than three simple steps.
          </p>
        </div>

        {/* 3-Step Timeline Grid */}
        <div className="relative">
          
          {/* Desktop Connecting Line */}
          <div className="hidden lg:block absolute top-1/2 left-0 right-0 -translate-y-12 h-0.5 bg-gradient-to-r from-emerald-400 via-navy-700 to-emerald-400 -z-0 opacity-25" />

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 relative z-10">
            {HOW_IT_WORKS.map((item, index) => (
              <div
                key={item.step}
                className="bg-slate-50/80 rounded-2xl p-8 border border-slate-200 hover:border-emerald-300 hover:bg-white shadow-soft hover:shadow-premium transition-all duration-300 relative group flex flex-col justify-between"
              >
                <div>
                  {/* Top Step Row */}
                  <div className="flex items-center justify-between mb-6">
                    <span className="text-3xl font-extrabold text-navy-900 font-display group-hover:text-emerald-600 transition-colors">
                      {item.step}
                    </span>
                    
                    <div className="w-12 h-12 rounded-xl bg-white border border-slate-200 flex items-center justify-center shadow-sm group-hover:scale-110 transition-transform">
                      {stepIcons[index]}
                    </div>
                  </div>

                  {/* Title */}
                  <h3 className="text-xl font-bold text-navy-950 font-display mb-3">
                    {item.title}
                  </h3>

                  {/* Description */}
                  <p className="text-sm text-slate-600 leading-relaxed font-normal mb-6">
                    {item.description}
                  </p>
                </div>

                {/* Highlight Badge */}
                <div className="pt-4 border-t border-slate-200/80 flex items-center gap-2 text-xs font-semibold text-emerald-700">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                  <span>{item.highlight}</span>
                </div>
              </div>
            ))}
          </div>

        </div>

      </div>
    </section>
  );
};
