import React, { useState, useEffect } from 'react';
import { Download, X, Smartphone, Globe } from 'lucide-react';
import { SITE_CONFIG } from '../data/content';

interface FloatingCTAProps {
  onDownloadClick?: () => void;
  onWebClick?: () => void;
}

export const FloatingCTA: React.FC<FloatingCTAProps> = ({ onDownloadClick, onWebClick }) => {
  const [isVisible, setIsVisible] = useState(false);
  const [isDismissed, setIsDismissed] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      if (window.scrollY > 400) {
        setIsVisible(true);
      } else {
        setIsVisible(false);
      }
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  if (!isVisible || isDismissed) return null;

  return (
    <>
      {/* Mobile Floating Bottom Bar */}
      <div className="md:hidden fixed bottom-0 left-0 right-0 z-40 bg-white/95 backdrop-blur-md border-t border-slate-200 px-4 py-2.5 shadow-2xl flex items-center justify-between gap-3 animate-slideUp">
        <div className="flex items-center gap-2.5">
          <img
            src="/enterprenex-badge.png"
            alt="Enterprenex"
            className="w-8 h-8 rounded-full object-contain shrink-0 shadow-sm bg-white p-0.5 border border-slate-100"
          />
          <div className="leading-tight">
            <span className="text-xs font-black text-slate-900 block">ENX Money</span>
            <span className="text-[10px] text-emerald-700 font-bold block">100% Free Udhar Khata</span>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <a
            href={SITE_CONFIG.webAppUrl}
            onClick={onWebClick}
            target="_blank"
            rel="noopener noreferrer"
            className="py-1.5 px-3 rounded-lg text-xs font-bold text-emerald-800 bg-emerald-50 hover:bg-emerald-100 border border-emerald-200"
          >
            Web
          </a>

          <a
            href={SITE_CONFIG.apkDirectDownloadUrl}
            download="ENX-Money-Consumer.apk"
            onClick={onDownloadClick}
            className="py-1.5 px-3.5 rounded-full text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 flex items-center gap-1.5 shadow-md shadow-emerald-600/25"
          >
            <Download className="w-3.5 h-3.5" />
            <span>Download</span>
          </a>
        </div>
      </div>

      {/* Desktop Floating Pill Dock (OkCredit Style) */}
      <div className="hidden md:flex fixed bottom-6 right-6 z-40 bg-white/95 text-slate-900 backdrop-blur-xl border border-emerald-200/90 py-2.5 px-4 rounded-full shadow-2xl items-center gap-3.5 animate-slideUp ring-1 ring-emerald-500/10">
        <div className="flex items-center gap-2.5">
          <img
            src="/enterprenex-badge.png"
            alt="Enterprenex"
            className="w-8 h-8 rounded-full object-contain shrink-0 shadow-sm bg-white p-0.5 border border-slate-100"
          />
          <div>
            <div className="text-xs font-black text-slate-900 flex items-center gap-1">
              <span>ENX Money</span>
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
            </div>
            <div className="text-[10px] text-slate-500 font-medium">Bahi Khata & GST Billing</div>
          </div>
        </div>

        <div className="h-5 w-px bg-slate-200" />

        <div className="flex items-center gap-2">
          <a
            href={SITE_CONFIG.apkDirectDownloadUrl}
            download="ENX-Money-Consumer.apk"
            onClick={onDownloadClick}
            className="py-1.5 px-3.5 rounded-full text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 flex items-center gap-1.5 transition-colors shadow-sm shadow-emerald-600/30"
          >
            <Smartphone className="w-3.5 h-3.5" />
            <span>Download App</span>
          </a>

          <a
            href={SITE_CONFIG.webAppUrl}
            onClick={onWebClick}
            target="_blank"
            rel="noopener noreferrer"
            className="py-1.5 px-3 rounded-full text-xs font-bold text-slate-700 hover:text-emerald-700 bg-slate-100 hover:bg-emerald-50 border border-slate-200 flex items-center gap-1 transition-colors"
          >
            <Globe className="w-3.5 h-3.5 text-emerald-600" />
            <span>Web Par Chalayein</span>
          </a>

          <button
            type="button"
            onClick={() => setIsDismissed(true)}
            className="p-1 rounded-full text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors ml-0.5"
            title="Dismiss"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>
    </>
  );
};
