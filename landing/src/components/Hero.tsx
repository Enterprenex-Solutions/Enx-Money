import React from 'react';
import { 
  Star, 
  CheckCircle2, 
  ArrowRight,
  ShieldCheck,
  Laptop,
  Sparkles
} from 'lucide-react';
import { LivePhoneDemo } from './LivePhoneDemo';

interface HeroProps {
  onStartFreeClick: () => void;
  onLiveDemoClick?: () => void;
}

export const Hero: React.FC<HeroProps> = ({ onStartFreeClick, onLiveDemoClick }) => {
  return (
    <section id="hero" className="relative pt-28 pb-16 lg:pt-36 lg:pb-24 bg-white border-b border-slate-100 overflow-hidden">
      {/* Background Subtle Gradient Glow */}
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[700px] h-[350px] bg-gradient-to-tr from-blue-100/50 via-indigo-50/30 to-transparent rounded-full blur-3xl pointer-events-none" />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-8 items-center">
          
          {/* ── LEFT COLUMN: Clean Minimalist Headline & Actions ── */}
          <div className="lg:col-span-7 space-y-6 sm:space-y-8 text-center lg:text-left">
            
            {/* Subtle Trust Pill */}
            <div className="inline-flex items-center gap-2 bg-blue-50/80 text-blue-800 border border-blue-200/60 rounded-full px-3.5 py-1 text-xs font-semibold shadow-sm">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
              <span>Trusted by 10,000+ businesses across Bharat</span>
            </div>

            {/* Category Tagline */}
            <div className="text-xs font-bold uppercase tracking-wider text-blue-600">
              Smart Business Management • Khata & GST Invoicing
            </div>

            {/* Clean Bold Headline */}
            <h1 className="text-4xl sm:text-5xl lg:text-[56px] font-extrabold text-slate-900 tracking-tight leading-[1.12] font-display">
              <span className="block text-slate-900">Run Your Business.</span>
              <span className="block text-blue-600">Track Every Rupee.</span>
            </h1>

            {/* Subtext */}
            <p className="text-base sm:text-lg text-slate-600 leading-relaxed max-w-xl mx-auto lg:mx-0 font-normal">
              Dukaan ka digital bahi-khata, GST billing aur payment collection ab aapke computer aur smartphone par. Automatic WhatsApp reminders se udhar wasool karein 3x jaldi. 100% paperless, safe aur secure.
            </p>

            {/* Cohesive Minimalist Action Buttons */}
            <div className="pt-2 space-y-4">
              <div className="flex flex-col sm:flex-row items-center justify-center lg:justify-start gap-3">
                {/* 1. Primary: Start Free Web App */}
                <button
                  onClick={onStartFreeClick}
                  className="w-full sm:w-auto inline-flex items-center justify-center gap-2.5 px-7 py-3.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold text-sm shadow-lg shadow-blue-500/25 hover:shadow-blue-500/35 transition-all duration-150 group hover:scale-[1.02]"
                >
                  <span>Open Web Dashboard Free</span>
                  <ArrowRight className="w-4 h-4 text-white group-hover:translate-x-1 transition-transform" />
                </button>

                {/* 2. Secondary: Live Interactive Demo */}
                <button
                  type="button"
                  onClick={onLiveDemoClick}
                  className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-5 py-3.5 rounded-xl bg-white hover:bg-slate-50 text-slate-800 font-semibold text-sm border border-slate-200 hover:border-slate-300 shadow-sm transition-all duration-150"
                >
                  <Laptop className="w-4 h-4 text-slate-500" />
                  <span>Explore Live Features</span>
                </button>
              </div>

              {/* Minimal Trust Features */}
              <div className="flex flex-wrap items-center justify-center lg:justify-start gap-4 text-xs text-slate-500 pt-1">
                <span className="inline-flex items-center gap-1.5 font-medium text-slate-600">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                  <span>Desktop & Mobile browser sync</span>
                </span>
                <span className="text-slate-300 hidden sm:inline">•</span>
                <span className="inline-flex items-center gap-1.5 font-medium text-slate-600">
                  <ShieldCheck className="w-3.5 h-3.5 text-blue-600" />
                  <span>Zero setup fees • Instant start</span>
                </span>
                <span className="text-slate-300 hidden sm:inline">•</span>
                <span className="inline-flex items-center gap-1.5 font-medium text-slate-600">
                  <Sparkles className="w-3.5 h-3.5 text-amber-500" />
                  <span>GST compliant invoices</span>
                </span>
              </div>
            </div>

            {/* Social Proof Rating Bar */}
            <div className="pt-2 flex items-center justify-center lg:justify-start gap-3">
              <div className="flex text-amber-400">
                {[...Array(5)].map((_, i) => (
                  <Star key={i} className="w-4 h-4 fill-amber-400 text-amber-400" />
                ))}
              </div>
              <span className="text-sm font-bold text-slate-900">4.8 Rating</span>
              <span className="text-slate-300">•</span>
              <span className="text-xs text-slate-500 font-medium">Verified by small business owners across India</span>
            </div>

          </div>

          {/* ── RIGHT COLUMN: Continuous Live Animated Smartphone Mockup ── */}
          <div className="lg:col-span-5 flex justify-center relative">
            <LivePhoneDemo />
          </div>

        </div>
      </div>
    </section>
  );
};
