import React from 'react';
import { Download, ExternalLink, Sparkles, CheckCircle2 } from 'lucide-react';
import { SITE_CONFIG } from '../data/content';

interface CTAProps {
  onDownloadClick?: () => void;
  onWebClick?: () => void;
}

export const CTA: React.FC<CTAProps> = ({ onDownloadClick, onWebClick }) => {
  return (
    <section className="py-24 bg-gradient-to-b from-white to-slate-50 relative overflow-hidden">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        <div className="bg-gradient-to-br from-navy-950 via-navy-900 to-navy-850 rounded-3xl p-10 sm:p-16 text-center text-white relative shadow-elevated border border-navy-800 overflow-hidden">
          
          {/* Subtle background glow */}
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[350px] bg-emerald-500/15 rounded-full blur-3xl pointer-events-none" />

          <div className="max-w-3xl mx-auto space-y-6 relative z-10">
            
            {/* Small Badge */}
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-emerald-500/20 border border-emerald-500/30 text-emerald-300 text-xs font-semibold">
              <Sparkles className="w-3.5 h-3.5" />
              <span>TRANSFORM YOUR BUSINESS TODAY</span>
            </div>

            {/* Heading */}
            <h2 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold font-display tracking-tight text-white leading-tight">
              Ready to Take Control of Your Business?
            </h2>

            {/* Supporting Text */}
            <p className="text-base sm:text-lg text-slate-300 font-normal leading-relaxed max-w-2xl mx-auto">
              Start managing your customers, invoices, inventory and business finances with ENX Money.
            </p>

            {/* Buttons */}
            <div className="flex flex-col sm:flex-row items-center justify-center gap-4 pt-4">
              <a
                href={SITE_CONFIG.apkDirectDownloadUrl}
                download="ENX-Money-Consumer.apk"
                onClick={onDownloadClick}
                className="w-full sm:w-auto inline-flex items-center justify-center gap-3 px-8 py-4 rounded-xl font-bold text-base text-navy-950 bg-emerald-400 hover:bg-emerald-300 shadow-glow-green hover:shadow-lg transition-all hover:-translate-y-0.5"
              >
                <Download className="w-5 h-5 text-navy-950" />
                <span>Download ENX Money</span>
              </a>

              <a
                href={SITE_CONFIG.webAppUrl}
                onClick={onWebClick}
                target="_blank"
                rel="noopener noreferrer"
                className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-8 py-4 rounded-xl font-bold text-base text-white bg-navy-800 hover:bg-navy-750 border border-navy-700 shadow-sm transition-all hover:-translate-y-0.5"
              >
                <span>Open Web App</span>
                <ExternalLink className="w-4 h-4 text-slate-400" />
              </a>
            </div>

            {/* Guarantees */}
            <div className="pt-6 flex flex-wrap items-center justify-center gap-6 text-xs text-slate-400">
              <span className="flex items-center gap-1.5">
                <CheckCircle2 className="w-4 h-4 text-emerald-400" />
                <span>Zero Onboarding Fee</span>
              </span>
              <span className="flex items-center gap-1.5">
                <CheckCircle2 className="w-4 h-4 text-emerald-400" />
                <span>No Credit Card Required</span>
              </span>
              <span className="flex items-center gap-1.5">
                <CheckCircle2 className="w-4 h-4 text-emerald-400" />
                <span>Instant Android & Web Cloud Sync</span>
              </span>
            </div>

          </div>

        </div>

      </div>
    </section>
  );
};
