import React, { useState } from 'react';
import { 
  Smartphone, 
  Laptop, 
  Apple, 
  Download, 
  ExternalLink, 
  QrCode, 
  Check, 
  Copy, 
  ShieldCheck, 
  Sparkles
} from 'lucide-react';
import { SITE_CONFIG } from '../data/content';

interface AppDownloadProps {
  onDownloadTriggered?: () => void;
}

export const AppDownload: React.FC<AppDownloadProps> = ({ onDownloadTriggered }) => {
  const [copied, setCopied] = useState(false);

  const handleCopyLink = () => {
    const fullUrl = `${window.location.origin}${SITE_CONFIG.googlePlayUrl}`;
    navigator.clipboard.writeText(fullUrl);
    setCopied(true);
    setTimeout(() => setCopied(false), 2500);
  };

  return (
    <section id="download" className="py-24 bg-white relative overflow-hidden">
      {/* Background radial gradient accent */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[500px] bg-gradient-to-tr from-emerald-100/40 via-navy-100/20 to-transparent blur-3xl -z-10 pointer-events-none rounded-full" />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Section Heading */}
        <div className="text-center max-w-3xl mx-auto mb-16 space-y-4">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-navy-50 border border-navy-100 text-navy-800 text-xs font-semibold tracking-wide">
            <Smartphone className="w-3.5 h-3.5 text-emerald-600" />
            <span>CROSS-PLATFORM ACCESSIBILITY</span>
          </div>

          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-navy-950 font-display tracking-tight">
            Your Business, Wherever You Work.
          </h2>

          <p className="text-base sm:text-lg text-slate-600 font-normal leading-relaxed">
            ENX Money seamlessly syncs your ledgers, inventory, invoices, and payment records across your Android mobile counter and desktop web browser in real time.
          </p>
        </div>

        {/* 3 Main Platform Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-16">
          
          {/* Option 1: Google Play / Android */}
          <div className="bg-gradient-to-b from-white to-slate-50/80 p-8 rounded-2xl border-2 border-emerald-500/30 hover:border-emerald-500 shadow-premium hover:shadow-xl transition-all duration-300 relative flex flex-col justify-between group">
            
            {/* Top Tag */}
            <div className="absolute -top-3.5 right-6 bg-emerald-600 text-white text-[11px] font-bold px-3 py-1 rounded-full uppercase tracking-wider shadow-sm flex items-center gap-1.5">
              <Sparkles className="w-3 h-3" />
              <span>Recommended</span>
            </div>

            <div>
              <div className="w-14 h-14 rounded-2xl bg-emerald-50 text-emerald-600 border border-emerald-100 flex items-center justify-center mb-6 group-hover:scale-105 transition-transform">
                {/* Modern Android SVG icon */}
                <svg className="w-7 h-7 fill-current" viewBox="0 0 24 24">
                  <path d="M17.523 15.3414c-.5511 0-.9993-.4486-.9993-.9997s.4482-.9993.9993-.9993c.551 0 .9993.4482.9993.9993.0001.5511-.4483.9997-.9993.9997m-11.046 0c-.5511 0-.9993-.4486-.9993-.9997s.4482-.9993.9993-.9993c.5511 0 .9993.4482.9993.9993 0 .5511-.4482.9997-.9993.9997m11.4045-6.02l1.9973-3.4592a.416.416 0 00-.1521-.5676.416.416 0 00-.5676.1521l-2.0223 3.503C15.5902 8.414 13.8533 8.082 12 8.082c-1.8534 0-3.5902.332-5.1367.8677L4.841 5.4467a.4161.4161 0 00-.5677-.1521.4157.4157 0 00-.1521.5676l1.9973 3.4592C2.6889 11.1867.3432 14.6589 0 18.761h24c-.3432-4.1021-2.6889-7.5743-6.1185-9.4396" />
                </svg>
              </div>

              <h3 className="text-xl font-bold text-navy-950 font-display mb-2">
                Google Play / Android
              </h3>

              <p className="text-sm text-slate-600 leading-relaxed mb-6">
                Fast, responsive, and works seamlessly even on low-bandwidth networks. Ideal for counter billing, field collections, and quick khata entries.
              </p>

              <div className="space-y-2 mb-8 text-xs text-slate-500 font-medium">
                <div className="flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                  <span>Version: {SITE_CONFIG.appVersion}</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                  <span>Requires Android 7.0 (Nougat) or later</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                  <span>Signed with Enterprenex Release Keystore</span>
                </div>
              </div>
            </div>

            <div className="space-y-3">
              <a
                href={SITE_CONFIG.googlePlayUrl}
                download="ENX-Money-Consumer.apk"
                onClick={onDownloadTriggered}
                className="w-full py-3.5 px-6 rounded-xl bg-navy-900 hover:bg-navy-850 text-white font-bold text-sm flex items-center justify-center gap-2.5 shadow-md hover:shadow-lg transition-all group-hover:-translate-y-0.5"
              >
                <Download className="w-4 h-4 text-emerald-400" />
                <span>Download Android App</span>
              </a>

              <button
                type="button"
                onClick={handleCopyLink}
                className="w-full py-2 px-3 text-xs text-slate-500 hover:text-navy-900 flex items-center justify-center gap-1.5 transition-colors"
              >
                {copied ? (
                  <>
                    <Check className="w-3.5 h-3.5 text-emerald-600" />
                    <span className="text-emerald-700 font-medium">Download Link Copied!</span>
                  </>
                ) : (
                  <>
                    <Copy className="w-3.5 h-3.5" />
                    <span>Copy direct download URL</span>
                  </>
                )}
              </button>
            </div>

          </div>

          {/* Option 2: Apple App Store */}
          <div className="bg-white p-8 rounded-2xl border border-slate-200 shadow-soft flex flex-col justify-between relative opacity-95">
            
            {/* Top Coming Soon Tag */}
            <div className="absolute -top-3.5 right-6 bg-slate-100 text-slate-600 border border-slate-200 text-[11px] font-bold px-3 py-1 rounded-full uppercase tracking-wider">
              Coming Soon
            </div>

            <div>
              <div className="w-14 h-14 rounded-2xl bg-slate-100 text-slate-700 flex items-center justify-center mb-6">
                <Apple className="w-7 h-7" />
              </div>

              <h3 className="text-xl font-bold text-navy-950 font-display mb-2">
                Apple App Store (iOS)
              </h3>

              <p className="text-sm text-slate-600 leading-relaxed mb-6">
                Native iOS experience engineered for iPhone and iPad with Face ID security, iCloud synchronization, and clean iPad POS interface.
              </p>

              <div className="space-y-2 mb-8 text-xs text-slate-400 font-medium">
                <div className="flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-slate-300"></span>
                  <span>Currently in App Store Review queue</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-slate-300"></span>
                  <span>Supports iOS 15.0+</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-slate-300"></span>
                  <span>Optimized for iPad Pro split-screen billing</span>
                </div>
              </div>
            </div>

            <button
              disabled
              className="w-full py-3.5 px-6 rounded-xl bg-slate-100 text-slate-400 font-bold text-sm flex items-center justify-center gap-2 cursor-not-allowed border border-slate-200"
            >
              <span>App Store — Coming Soon</span>
            </button>

          </div>

          {/* Option 3: Web App */}
          <div className="bg-white p-8 rounded-2xl border border-slate-200 hover:border-navy-300 shadow-soft hover:shadow-premium transition-all duration-300 flex flex-col justify-between group">
            
            <div>
              <div className="w-14 h-14 rounded-2xl bg-navy-50 text-navy-800 border border-navy-100 flex items-center justify-center mb-6 group-hover:scale-105 transition-transform">
                <Laptop className="w-7 h-7" />
              </div>

              <h3 className="text-xl font-bold text-navy-950 font-display mb-2">
                ENX Money Web Platform
              </h3>

              <p className="text-sm text-slate-600 leading-relaxed mb-6">
                Zero installation needed. Access your complete business books, bulk GSTR exports, and comprehensive analytics on any PC or laptop browser.
              </p>

              <div className="space-y-2 mb-8 text-xs text-slate-500 font-medium">
                <div className="flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-navy-600"></span>
                  <span>Works on Chrome, Edge, Safari, Firefox</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-navy-600"></span>
                  <span>Instant multi-user staff permissions</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-navy-600"></span>
                  <span>Thermal and A4 printer auto-connect</span>
                </div>
              </div>
            </div>

            <a
              href={SITE_CONFIG.webAppUrl}
              className="w-full py-3.5 px-6 rounded-xl bg-white hover:bg-slate-50 text-navy-950 font-bold text-sm flex items-center justify-center gap-2 border-2 border-navy-900 shadow-sm transition-all group-hover:-translate-y-0.5"
            >
              <span>Open ENX Money Web</span>
              <ExternalLink className="w-4 h-4 text-navy-700" />
            </a>

          </div>

        </div>

        {/* QR Code Scan Area */}
        <div className="bg-gradient-to-r from-navy-950 via-navy-900 to-navy-850 text-white rounded-3xl p-8 sm:p-10 shadow-elevated border border-navy-800 relative overflow-hidden">
          
          {/* Subtle background decorative shapes */}
          <div className="absolute right-0 top-0 w-80 h-80 bg-emerald-500/10 rounded-full blur-3xl pointer-events-none" />

          <div className="grid grid-cols-1 md:grid-cols-12 gap-8 items-center">
            
            {/* Left explanation */}
            <div className="md:col-span-8 space-y-4">
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/20 border border-emerald-500/30 text-emerald-300 text-xs font-semibold">
                <QrCode className="w-3.5 h-3.5" />
                <span>INSTANT MOBILE ONBOARDING</span>
              </div>

              <h3 className="text-2xl sm:text-3xl font-extrabold tracking-tight font-display text-white">
                Scan to Download ENX Money on Your Phone
              </h3>

              <p className="text-slate-300 text-sm sm:text-base leading-relaxed max-w-xl">
                Open your smartphone's camera or Google Lens and point it at the QR code. You'll be directed immediately to the verified installer without needing to search.
              </p>

              <div className="flex flex-wrap items-center gap-6 pt-2 text-xs text-slate-400">
                <div className="flex items-center gap-2">
                  <ShieldCheck className="w-4 h-4 text-emerald-400" />
                  <span>Virus-Scanned & Keystore-Signed</span>
                </div>
                <div className="flex items-center gap-2">
                  <Check className="w-4 h-4 text-emerald-400" />
                  <span>Automatic Cloud Backup Included</span>
                </div>
              </div>
            </div>

            {/* Right QR Code Graphic Container */}
            <div className="md:col-span-4 flex justify-center md:justify-end">
              <div className="bg-white p-5 rounded-2xl shadow-xl text-center border-4 border-emerald-400/80 group transform hover:scale-105 transition-transform duration-300">
                
                {/* Authentic Simulated QR Code SVG */}
                <div className="w-44 h-44 mx-auto relative bg-white p-1">
                  <svg viewBox="0 0 100 100" className="w-full h-full">
                    {/* Corners */}
                    <rect x="0" y="0" width="28" height="28" fill="#0B192C" rx="4" />
                    <rect x="4" y="4" width="20" height="20" fill="#FFFFFF" rx="2" />
                    <rect x="8" y="8" width="12" height="12" fill="#0B192C" rx="2" />

                    <rect x="72" y="0" width="28" height="28" fill="#0B192C" rx="4" />
                    <rect x="76" y="4" width="20" height="20" fill="#FFFFFF" rx="2" />
                    <rect x="80" y="8" width="12" height="12" fill="#0B192C" rx="2" />

                    <rect x="0" y="72" width="28" height="28" fill="#0B192C" rx="4" />
                    <rect x="4" y="76" width="20" height="20" fill="#FFFFFF" rx="2" />
                    <rect x="8" y="80" width="12" height="12" fill="#0B192C" rx="2" />

                    {/* QR Matrix Pattern Dots */}
                    <rect x="36" y="8" width="6" height="6" fill="#0B192C" />
                    <rect x="48" y="14" width="6" height="6" fill="#0B192C" />
                    <rect x="58" y="8" width="6" height="6" fill="#0B192C" />

                    <rect x="34" y="24" width="6" height="6" fill="#0B192C" />
                    <rect x="46" y="28" width="8" height="6" fill="#0B192C" />
                    <rect x="58" y="22" width="6" height="6" fill="#0B192C" />

                    <rect x="8" y="36" width="6" height="6" fill="#0B192C" />
                    <rect x="18" y="44" width="6" height="6" fill="#0B192C" />
                    <rect x="26" y="38" width="6" height="6" fill="#0B192C" />

                    <rect x="72" y="36" width="6" height="6" fill="#0B192C" />
                    <rect x="82" y="44" width="8" height="6" fill="#0B192C" />
                    <rect x="76" y="54" width="6" height="6" fill="#0B192C" />

                    <rect x="34" y="66" width="6" height="6" fill="#0B192C" />
                    <rect x="46" y="74" width="8" height="6" fill="#0B192C" />
                    <rect x="58" y="68" width="6" height="6" fill="#0B192C" />

                    <rect x="72" y="72" width="6" height="6" fill="#0B192C" />
                    <rect x="84" y="78" width="6" height="6" fill="#0B192C" />
                    <rect x="76" y="88" width="8" height="6" fill="#0B192C" />

                    {/* Center Brand Pill */}
                    <rect x="38" y="38" width="24" height="24" rx="5" fill="#10B981" />
                    <text x="50" y="55" fill="#FFFFFF" fontSize="12" fontWeight="900" textAnchor="middle" fontFamily="sans-serif">EX</text>
                  </svg>
                </div>

                <div className="mt-2 text-[11px] font-bold text-navy-950 uppercase tracking-wider">
                  Scan to Download
                </div>
                <div className="text-[10px] text-slate-500 font-medium">
                  {SITE_CONFIG.brandName} • Android
                </div>
              </div>
            </div>

          </div>

        </div>

      </div>
    </section>
  );
};
