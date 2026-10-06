import React from 'react';
import { Mail, Phone, MapPin, ExternalLink } from 'lucide-react';
import { SITE_CONFIG } from '../data/content';

export const Footer: React.FC = () => {
  return (
    <footer className="bg-navy-950 text-slate-300 pt-16 pb-12 border-t border-navy-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Main Footer Navigation Columns (5 Columns) */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-12 gap-10 pb-12 border-b border-navy-800">
          
          {/* Brand Info (4 Cols) */}
          <div className="lg:col-span-4 space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-navy-800 to-navy-700 p-0.5 shadow-md flex items-center justify-center text-white font-bold border border-navy-600">
                <div className="w-full h-full bg-navy-900 rounded-[10px] flex items-center justify-center">
                  <span className="text-xl font-extrabold text-white">E</span>
                  <span className="text-lg font-black text-emerald-400 -ml-0.5">X</span>
                </div>
              </div>
              <div className="flex flex-col">
                <span className="text-xl font-extrabold tracking-tight text-white font-display">
                  {SITE_CONFIG.brandName}
                </span>
                <span className="text-[10px] tracking-wider uppercase font-semibold text-emerald-400">
                  by Enterprenex Solutions
                </span>
              </div>
            </div>

            <p className="text-sm text-slate-400 leading-relaxed max-w-sm">
              Smart business management for growing businesses. ENX Money brings billing, khata, inventory, payments and business insights together in one simple platform.
            </p>

            <div className="space-y-2 pt-2 text-xs text-slate-400">
              <div className="flex items-start gap-2.5">
                <MapPin className="w-4 h-4 text-emerald-400 shrink-0 mt-0.5" />
                <span>{SITE_CONFIG.address}</span>
              </div>

              <div className="flex items-center gap-2.5">
                <Mail className="w-4 h-4 text-emerald-400 shrink-0" />
                <a
                  href={`mailto:${SITE_CONFIG.billingEmail}`}
                  className="hover:text-emerald-400 transition-colors font-medium text-slate-300"
                  title="Official Email"
                >
                  {SITE_CONFIG.billingEmail}
                </a>
              </div>

              <div className="flex items-center gap-2.5">
                <Phone className="w-4 h-4 text-emerald-400 shrink-0" />
                <a
                  href={`tel:${SITE_CONFIG.officialPhone.replace(/\s+/g, '')}`}
                  className="hover:text-emerald-400 transition-colors font-medium text-slate-300"
                  title="Official Phone"
                >
                  {SITE_CONFIG.officialPhone}
                </a>
              </div>

              <div className="flex items-center gap-2.5">
                <svg className="w-4 h-4 text-emerald-400 fill-current shrink-0" viewBox="0 0 24 24" aria-hidden="true">
                  <path d="M12.031 6.172c-3.181 0-5.767 2.586-5.768 5.766-.001 1.298.38 2.27 1.019 3.287l-.582 2.128 2.182-.573c.978.58 1.911.928 3.145.929 3.178 0 5.767-2.587 5.768-5.766.001-3.187-2.575-5.77-5.764-5.771zm3.392 8.244c-.144.405-.837.774-1.17.824-.299.045-.677.063-1.092-.069-.252-.08-.575-.187-.988-.365-1.739-.751-2.874-2.502-2.961-2.617-.087-.116-.708-.94-.708-1.793s.448-1.273.607-1.446c.159-.173.346-.217.462-.217l.332.007c.106.005.249-.04.39.298.144.347.491 1.2.534 1.287.043.087.072.188.014.304-.058.116-.087.188-.173.289l-.26.304c-.087.086-.177.18-.076.354.101.174.449.741.964 1.201.662.591 1.221.774 1.394.86.174.086.275.072.376-.044.101-.116.433-.506.549-.68.116-.173.231-.145.39-.087s1.011.477 1.184.564.289.13.332.202c.043.073.043.419-.101.824z" />
                </svg>
                <a
                  href={SITE_CONFIG.whatsappUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="hover:text-emerald-400 transition-colors font-medium text-slate-300"
                  title="WhatsApp Official Desk"
                >
                  WhatsApp: {SITE_CONFIG.whatsappPhone}
                </a>
              </div>
            </div>
          </div>

          {/* Product Links (2 Cols) */}
          <div className="lg:col-span-2 space-y-3">
            <h4 className="text-xs font-bold text-white uppercase tracking-wider font-display">
              Product
            </h4>
            <ul className="space-y-2 text-sm text-slate-400">
              <li>
                <a href="#features" className="hover:text-emerald-400 transition-colors">
                  Features
                </a>
              </li>
              <li>
                <a href="#solutions" className="hover:text-emerald-400 transition-colors">
                  GST Invoicing
                </a>
              </li>
              <li>
                <a href="#solutions" className="hover:text-emerald-400 transition-colors">
                  Inventory
                </a>
              </li>
              <li>
                <a href="#features" className="hover:text-emerald-400 transition-colors">
                  Digital Khata
                </a>
              </li>
              <li>
                <a href="#insights" className="hover:text-emerald-400 transition-colors">
                  Reports
                </a>
              </li>
            </ul>
          </div>

          {/* Company Links (2 Cols) */}
          <div className="lg:col-span-2 space-y-3">
            <h4 className="text-xs font-bold text-white uppercase tracking-wider font-display">
              Company
            </h4>
            <ul className="space-y-2 text-sm text-slate-400">
              <li>
                <a href="#hero" className="hover:text-emerald-400 transition-colors">
                  About
                </a>
              </li>
              <li>
                <a href={`mailto:${SITE_CONFIG.generalLegalEmail}`} className="hover:text-emerald-400 transition-colors">
                  Contact
                </a>
              </li>
              <li>
                <a href={`mailto:${SITE_CONFIG.generalLegalEmail}?subject=Career%20Inquiry%20-%20Enterprenex`} className="hover:text-emerald-400 transition-colors">
                  Careers
                </a>
              </li>
              <li>
                <a href="https://enterprenex.solutions" target="_blank" rel="noopener noreferrer" className="hover:text-emerald-400 transition-colors flex items-center gap-1">
                  <span>Enterprenex</span>
                  <ExternalLink className="w-3 h-3" />
                </a>
              </li>
            </ul>
          </div>

          {/* Support Links (2 Cols) */}
          <div className="lg:col-span-2 space-y-3">
            <h4 className="text-xs font-bold text-white uppercase tracking-wider font-display">
              Support
            </h4>
            <ul className="space-y-2 text-sm text-slate-400">
              <li>
                <a href={`mailto:${SITE_CONFIG.billingEmail}`} className="hover:text-emerald-400 transition-colors">
                  Help Center
                </a>
              </li>
              <li>
                <a href={`tel:${SITE_CONFIG.officialPhone.replace(/\s+/g, '')}`} className="hover:text-emerald-400 transition-colors">
                  Contact Support
                </a>
              </li>
              <li>
                <a href="#faq" className="hover:text-emerald-400 transition-colors">
                  FAQ
                </a>
              </li>
              <li>
                <a href={SITE_CONFIG.accountDeletionUrl} className="hover:text-emerald-400 transition-colors">
                  Account Deletion
                </a>
              </li>
            </ul>
          </div>

          {/* Legal & Social Links (2 Cols) */}
          <div className="lg:col-span-2 space-y-3">
            <h4 className="text-xs font-bold text-white uppercase tracking-wider font-display">
              Legal & Social
            </h4>
            <ul className="space-y-2 text-sm text-slate-400">
              <li>
                <a href={SITE_CONFIG.privacyUrl} className="hover:text-emerald-400 transition-colors">
                  Privacy Policy
                </a>
              </li>
              <li>
                <a href={SITE_CONFIG.termsUrl} className="hover:text-emerald-400 transition-colors">
                  Terms & Conditions
                </a>
              </li>
              <li>
                <a href={SITE_CONFIG.refundUrl} className="hover:text-emerald-400 transition-colors">
                  Refund Policy
                </a>
              </li>
            </ul>

            <div className="pt-2">
              <span className="text-[11px] font-bold text-slate-400 uppercase tracking-wider block mb-2 font-display">
                Social
              </span>
              <div className="flex items-center gap-2 text-slate-400">
                <a
                  href="https://www.linkedin.com/company/enterprenex-solution-pvt-ltd"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="hover:text-emerald-400 transition-colors text-xs flex items-center gap-1 font-medium"
                  title="Follow Enterprenex Solution on LinkedIn"
                >
                  LinkedIn
                </a>
                <span>•</span>
                <a
                  href="https://www.instagram.com/enterprenexsolution?utm_source=ig_web_button_share_sheet&stkn=ZDNlZDc0MzIxNw=="
                  target="_blank"
                  rel="noopener noreferrer"
                  className="hover:text-emerald-400 transition-colors text-xs flex items-center gap-1 font-medium"
                  title="Follow @enterprenexsolution on Instagram"
                >
                  Instagram
                </a>
              </div>
            </div>
          </div>

        </div>

        {/* Bottom Bar: Copyright & Compliance */}
        <div className="pt-8 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-slate-500">
          <div>
            © 2026 {SITE_CONFIG.companyName}. All rights reserved.
          </div>

          <div className="flex items-center gap-4 text-[11px]">
            <span>DPDP Act 2023 Compliant</span>
            <span>•</span>
            <span>Made in Chhatrapati Sambhajinagar, India</span>
          </div>
        </div>

      </div>
    </footer>
  );
};
