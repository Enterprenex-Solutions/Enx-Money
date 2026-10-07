import React from 'react';
import { 
  ArrowRight, 
  Star, 
  CheckCircle2, 
  ChevronRight, 
  Download,
  Laptop,
  ExternalLink,
  LogIn
} from 'lucide-react';
import { SITE_CONFIG } from '../data/content';
import { LivePhoneDemo } from './LivePhoneDemo';

interface HeroProps {
  onDownloadClick?: () => void;
  onWebClick?: () => void;
}

export const Hero: React.FC<HeroProps> = ({ onDownloadClick, onWebClick }) => {

  return (
    <section id="hero" className="relative pt-24 pb-16 lg:pt-32 lg:pb-24 overflow-hidden bg-[#FAFBF9]">
      {/* Subtle Dot Grid Background (OkCredit style) */}
      <div 
        className="absolute inset-0 opacity-[0.45] pointer-events-none"
        style={{
          backgroundImage: 'radial-gradient(#10B981 1.2px, transparent 1.2px)',
          backgroundSize: '28px 28px',
        }}
      ></div>

      {/* Soft Ambient Radial Glow */}
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[650px] h-[650px] bg-emerald-100/60 rounded-full blur-[120px] pointer-events-none"></div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-8 items-center">
          
          {/* ── LEFT COLUMN: High-Converting Headline & Badges (OkCredit Aesthetic) ── */}
          <div className="lg:col-span-7 space-y-6 sm:space-y-8 text-center lg:text-left">
            
            {/* Trust Pill at Top */}
            <div className="inline-flex items-center gap-2 bg-emerald-50 text-emerald-800 border border-emerald-200/90 rounded-full px-4 py-1.5 shadow-sm text-xs sm:text-sm font-bold">
              <span className="bg-emerald-600 text-white rounded-full px-1.5 py-0.5 text-[10px] font-black uppercase tracking-wider">
                10,000+
              </span>
              <span>India ke dukandaars ka bharosemand udhar khata app</span>
            </div>

            {/* Tagline category */}
            <div className="text-xs sm:text-sm font-extrabold uppercase tracking-widest text-emerald-600 flex items-center justify-center lg:justify-start gap-2">
              <span className="w-5 h-0.5 bg-emerald-500 inline-block"></span>
              DIGITAL UDHAR BAHI KHATA & GST BILLING
            </div>

            {/* Massive Bold Headline (OkCredit Iconic 3-Line Structure) */}
            <h1 className="text-4xl sm:text-5xl lg:text-[64px] font-black text-slate-900 tracking-tight leading-[1.08] font-display">
              <span className="block text-slate-900">Udhar likho.</span>
              <span className="relative inline-block text-emerald-600 my-1">
                Yaad dilao.
                {/* Yellow/Green highlighter accent underline */}
                <span className="absolute bottom-1 left-0 w-full h-3 bg-emerald-200/70 -z-10 rounded-sm transform -rotate-1"></span>
              </span>
              <span className="block text-slate-900">Wasool karo.</span>
            </h1>

            {/* Two Clear Options: Web par chalayein & Download Android App */}
            <div className="pt-2 space-y-3">
              <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-center lg:justify-start gap-3 sm:gap-4">
                
                {/* 📱 OPTION: Download Android App (Install on Android via Direct APK)
                    Prioritized on mobile via order-1, prominent emerald styling */}
                <a
                  href={SITE_CONFIG.apkDirectDownloadUrl}
                  download="ENX-Money-Consumer.apk"
                  onClick={onDownloadClick}
                  className="order-1 sm:order-2 flex-1 sm:flex-initial inline-flex items-center justify-between sm:justify-start gap-3.5 px-5 py-3.5 rounded-2xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold shadow-lg shadow-emerald-600/30 hover:shadow-emerald-600/40 transition-all duration-200 group border border-emerald-500 hover:-translate-y-0.5"
                  title="Direct APK Download for Android"
                >
                  <div className="w-10 h-10 rounded-xl bg-white/20 flex items-center justify-center shrink-0 text-white group-hover:scale-105 transition-transform">
                    <Download className="w-5 h-5" />
                  </div>
                  <div className="text-left flex-1">
                    <div className="flex items-center gap-1.5">
                      <span className="text-sm sm:text-base font-extrabold tracking-tight">
                        Download Android App
                      </span>
                      <span className="text-[10px] font-black uppercase px-1.5 py-0.5 rounded bg-white/25 text-white">
                        APK
                      </span>
                    </div>
                    <span className="block text-[11px] font-medium text-emerald-100">
                      📱 Install ENX Money on Android
                    </span>
                  </div>
                  <ArrowRight className="w-4 h-4 text-emerald-200 shrink-0 sm:hidden" />
                </a>

                {/* 💻 OPTION: Web par chalayein (Use ENX Money on Desktop/Laptop in Browser)
                    Prominent on desktop/laptop (order-1 on sm+), opens web application */}
                <a
                  href={SITE_CONFIG.webAppUrl}
                  onClick={onWebClick}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="order-2 sm:order-1 flex-1 sm:flex-initial inline-flex items-center justify-between sm:justify-start gap-3.5 px-5 py-3.5 rounded-2xl bg-white hover:bg-slate-50 text-slate-900 font-bold border-2 border-slate-200 hover:border-emerald-600 shadow-sm hover:shadow-md transition-all duration-200 group hover:-translate-y-0.5"
                  title="Open ENX Money in Browser (Desktop / Laptop)"
                >
                  <div className="w-10 h-10 rounded-xl bg-emerald-50 border border-emerald-100 flex items-center justify-center shrink-0 text-emerald-700 group-hover:scale-105 group-hover:bg-emerald-600 group-hover:text-white transition-all">
                    <Laptop className="w-5 h-5" />
                  </div>
                  <div className="text-left flex-1">
                    <div className="flex items-center gap-1.5">
                      <span className="text-sm sm:text-base font-extrabold tracking-tight text-slate-900 group-hover:text-emerald-700 transition-colors">
                        Web par chalayein
                      </span>
                      <span className="text-[10px] font-bold uppercase px-1.5 py-0.5 rounded bg-emerald-50 text-emerald-700 border border-emerald-200">
                        Browser
                      </span>
                    </div>
                    <span className="block text-[11px] font-medium text-slate-500">
                      💻 Use ENX Money on Desktop/Laptop
                    </span>
                  </div>
                  <ExternalLink className="w-4 h-4 text-slate-400 group-hover:text-emerald-600 shrink-0 transition-colors" />
                </a>

                {/* 🏢 OPTION: Enterprenex Company Management Portal Login */}
                <a
                  href="/portal"
                  className="order-3 flex-1 sm:flex-initial inline-flex items-center justify-between sm:justify-start gap-3.5 px-5 py-3.5 rounded-2xl bg-slate-900 hover:bg-slate-800 text-white font-bold border-2 border-emerald-500/40 hover:border-emerald-400 shadow-md hover:shadow-lg transition-all duration-200 group hover:-translate-y-0.5"
                  title="Enterprenex Company Management Portal (CEO, CTO, CFO, HR & Staff Login)"
                >
                  <div className="w-10 h-10 rounded-xl bg-emerald-600 flex items-center justify-center shrink-0 text-white group-hover:scale-105 transition-all shadow-sm">
                    <LogIn className="w-5 h-5" />
                  </div>
                  <div className="text-left flex-1">
                    <div className="flex items-center gap-1.5">
                      <span className="text-sm sm:text-base font-extrabold tracking-tight text-white group-hover:text-emerald-300 transition-colors">
                        Portal Login
                      </span>
                      <span className="text-[10px] font-bold uppercase px-1.5 py-0.5 rounded bg-emerald-500/30 text-emerald-300 border border-emerald-400/30">
                        Staff & Exec
                      </span>
                    </div>
                    <span className="block text-[11px] font-medium text-emerald-200/80">
                      🏢 Enterprenex Company Portal
                    </span>
                  </div>
                  <ArrowRight className="w-4 h-4 text-emerald-300 shrink-0" />
                </a>

              </div>

              {/* Sub-bar: Real-time sync & Google Play / QR code anchor link */}
              <div className="flex flex-wrap items-center justify-center lg:justify-start gap-3 pt-1 text-xs text-slate-500">
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
                  className="inline-flex items-center gap-1 text-slate-600 hover:text-emerald-700 underline font-medium"
                >
                  <span>Google Play & QR Code</span>
                  <ChevronRight className="w-3 h-3" />
                </a>
              </div>
            </div>

            {/* Social Proof Rating Bar (OkCredit style) */}
            <div className="pt-2 flex flex-col sm:flex-row items-center justify-center lg:justify-start gap-4">
              <div className="flex -space-x-2 overflow-hidden">
                <div className="inline-flex items-center justify-center w-8 h-8 rounded-full bg-emerald-500 text-white font-bold text-xs ring-2 ring-white">R</div>
                <div className="inline-flex items-center justify-center w-8 h-8 rounded-full bg-blue-500 text-white font-bold text-xs ring-2 ring-white">S</div>
                <div className="inline-flex items-center justify-center w-8 h-8 rounded-full bg-amber-500 text-white font-bold text-xs ring-2 ring-white">M</div>
                <div className="inline-flex items-center justify-center w-8 h-8 rounded-full bg-purple-500 text-white font-bold text-xs ring-2 ring-white">P</div>
                <div className="inline-flex items-center justify-center w-8 h-8 rounded-full bg-rose-500 text-white font-bold text-xs ring-2 ring-white">K</div>
              </div>
              <div className="flex items-center gap-1.5 text-sm">
                <div className="flex text-amber-400">
                  {[...Array(5)].map((_, i) => (
                    <Star key={i} className="w-4 h-4 fill-amber-400 text-amber-400" />
                  ))}
                </div>
                <span className="font-extrabold text-slate-800">4.8 Rating</span>
                <span className="text-slate-400">•</span>
                <span className="text-slate-600 font-medium">Loved by 10,000+ dukandaars on Google Play</span>
              </div>
            </div>

            {/* Friendly Subtext in Indian Business Language */}
            <p className="text-base sm:text-lg text-slate-600 leading-relaxed max-w-xl mx-auto lg:mx-0">
              Dukaan ka udhar khata ab aapke phone mein. Har credit aur payment entry <strong className="text-slate-900">100% safe aur secure</strong>. Automatic WhatsApp payment reminders se paisa wasool karein <strong className="text-emerald-700">3x jaldi</strong>. Bilkul free, hamesha ke liye.
            </p>

          </div>

          {/* ── RIGHT COLUMN: Continuous 16s Live Animated Smartphone Mockup ── */}
          <div className="lg:col-span-5 flex justify-center relative">
            <LivePhoneDemo />
          </div>

        </div>
      </div>
    </section>
  );
};
