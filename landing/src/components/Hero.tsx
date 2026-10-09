import React from 'react';
import { 
  Star, 
  CheckCircle2, 
  ChevronRight, 
  Download,
  Laptop
} from 'lucide-react';
import { SITE_CONFIG } from '../data/content';
import { LivePhoneDemo } from './LivePhoneDemo';

interface HeroProps {
  onDownloadClick?: () => void;
  onWebClick?: () => void;
}

export const Hero: React.FC<HeroProps> = ({ onDownloadClick, onWebClick }) => {
  return (
    <section id="hero" className="relative pt-24 pb-16 lg:pt-32 lg:pb-24 bg-white border-b border-slate-100">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-8 items-center">
          
          {/* ── LEFT COLUMN: Clean Minimalist Headline & Actions ── */}
          <div className="lg:col-span-7 space-y-6 sm:space-y-8 text-center lg:text-left">
            
            {/* Subtle Trust Pill */}
            <div className="inline-flex items-center gap-2 bg-slate-50 text-slate-700 border border-slate-200/80 rounded-full px-3.5 py-1 text-xs font-medium shadow-sm">
              <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
              <span>Trusted by 10,000+ businesses across India</span>
            </div>

            {/* Category Tagline */}
            <div className="text-xs font-semibold uppercase tracking-wider text-slate-400">
              Digital Udhar Khata & GST Billing
            </div>

            {/* Clean Bold Headline */}
            <h1 className="text-4xl sm:text-5xl lg:text-[58px] font-extrabold text-slate-900 tracking-tight leading-[1.12] font-display">
              <span className="block text-slate-900">Udhar likho.</span>
              <span className="block text-slate-900">Yaad dilao.</span>
              <span className="block text-slate-900">Wasool karo.</span>
            </h1>

            {/* Subtext */}
            <p className="text-base sm:text-lg text-slate-600 leading-relaxed max-w-xl mx-auto lg:mx-0 font-normal">
              Dukaan ka udhar khata ab aapke phone mein. Automatic WhatsApp reminders se payments collect karein 3x jaldi. 100% safe, secure, aur hamesha ke liye free.
            </p>

            {/* Cohesive Minimalist Action Buttons */}
            <div className="pt-2 space-y-4">
              <div className="flex flex-col sm:flex-row items-center justify-center lg:justify-start gap-3">
                {/* 1. Primary: Download App */}
                <a
                  href={SITE_CONFIG.apkDirectDownloadUrl}
                  download="ENX-Money-Consumer.apk"
                  onClick={onDownloadClick}
                  className="w-full sm:w-auto inline-flex items-center justify-center gap-2.5 px-6 py-3.5 rounded-xl bg-slate-900 hover:bg-slate-800 text-white font-semibold text-sm shadow-sm hover:shadow transition-all duration-150 group"
                  title="Direct APK Download for Android"
                >
                  <Download className="w-4 h-4 text-slate-300 group-hover:text-white transition-colors" />
                  <span>Download Android App</span>
                  <span className="text-[10px] font-bold uppercase px-1.5 py-0.5 rounded bg-white/20 text-white ml-0.5">
                    APK
                  </span>
                </a>

                {/* 2. Secondary: Web App */}
                <a
                  href={SITE_CONFIG.webAppUrl}
                  onClick={onWebClick}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-5 py-3.5 rounded-xl bg-white hover:bg-slate-50 text-slate-800 font-semibold text-sm border border-slate-200 hover:border-slate-300 shadow-sm transition-all duration-150"
                  title="Open ENX Money in Browser (Desktop / Laptop)"
                >
                  <Laptop className="w-4 h-4 text-slate-500" />
                  <span>Web par chalayein</span>
                </a>
              </div>

              {/* Minimal Trust Features */}
              <div className="flex flex-wrap items-center justify-center lg:justify-start gap-4 text-xs text-slate-500 pt-1">
                <span className="inline-flex items-center gap-1.5 font-medium text-slate-600">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                  <span>Desktop & Mobile real-time sync</span>
                </span>
                <span className="text-slate-300 hidden sm:inline">•</span>
                <span className="inline-flex items-center gap-1.5 font-medium text-slate-600">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                  <span>100% Free & Secure</span>
                </span>
                <span className="text-slate-300 hidden sm:inline">•</span>
                <a
                  href="#download"
                  onClick={onDownloadClick}
                  className="inline-flex items-center gap-1 text-slate-600 hover:text-slate-900 underline font-medium"
                >
                  <span>Google Play & QR Code</span>
                  <ChevronRight className="w-3 h-3" />
                </a>
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
              <span className="text-xs text-slate-500 font-medium">Loved by 10,000+ dukandaars on Google Play</span>
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
