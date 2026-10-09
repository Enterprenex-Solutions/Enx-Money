import React from 'react';
import { Mail, Phone, MapPin, ExternalLink } from 'lucide-react';
import { SITE_CONFIG } from '../data/content';

interface FooterProps {
  onAboutClick?: () => void;
  onContactClick?: () => void;
  onLegalClick?: (tab: 'privacy' | 'terms' | 'refund') => void;
}

export const Footer: React.FC<FooterProps> = ({
  onAboutClick,
  onContactClick,
  onLegalClick,
}) => {
  return (
    <footer className="bg-slate-900 text-slate-300 pt-16 pb-12 border-t border-slate-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Main Footer Navigation Columns */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-12 gap-10 pb-12 border-b border-slate-800">
          
          {/* Brand Info (4 Cols) */}
          <div className="lg:col-span-4 space-y-4">
            <div className="flex items-center gap-3">
              <img
                src="/enx-emblem.png"
                alt="ENX Money"
                className="w-12 h-12 object-contain rounded-xl shadow-md bg-white p-1"
              />
              <div className="flex flex-col">
                <span className="text-xl font-extrabold tracking-tight text-white font-display">
                  ENX Money
                </span>
                <span className="text-[10px] tracking-wider uppercase font-semibold text-blue-400">
                  Expenses tracker app
                </span>
              </div>
            </div>

            <p className="text-sm text-slate-400 leading-relaxed max-w-sm">
              Smart business management for growing businesses. ENX Money brings billing, digital khata, inventory, payments, and business insights together in one simple web platform.
            </p>

            {/* Official Parent Brand Logo */}
            <div className="pt-1">
              <a
                href="https://enterprenex.solutions"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 bg-white px-3 py-1.5 rounded-lg shadow hover:opacity-95 transition-opacity"
                title="Enterprenex Solutions Pvt. Ltd."
              >
                <img
                  src="/enterprenex-logo.png"
                  alt="Enterprenex Solutions"
                  className="h-6 w-auto object-contain"
                />
              </a>
            </div>

            <div className="space-y-2 pt-2 text-xs text-slate-400">
              <div className="flex items-start gap-2.5">
                <MapPin className="w-4 h-4 text-blue-400 shrink-0 mt-0.5" />
                <span>{SITE_CONFIG.address}</span>
              </div>

              <div className="flex items-center gap-2.5">
                <Mail className="w-4 h-4 text-blue-400 shrink-0" />
                <a
                  href={`mailto:${SITE_CONFIG.billingEmail}`}
                  className="hover:text-blue-400 transition-colors font-medium text-slate-300"
                  title="Official Email"
                >
                  {SITE_CONFIG.billingEmail}
                </a>
              </div>

              <div className="flex items-center gap-2.5">
                <Phone className="w-4 h-4 text-blue-400 shrink-0" />
                <a
                  href={`tel:${SITE_CONFIG.officialPhone.replace(/\s+/g, '')}`}
                  className="hover:text-blue-400 transition-colors font-medium text-slate-300"
                  title="Official Phone"
                >
                  {SITE_CONFIG.officialPhone}
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
                <a href="#features" className="hover:text-blue-400 transition-colors">
                  Features
                </a>
              </li>
              <li>
                <a href="#invoices" className="hover:text-blue-400 transition-colors">
                  GST Invoicing
                </a>
              </li>
              <li>
                <a href="#inventory" className="hover:text-blue-400 transition-colors">
                  Inventory
                </a>
              </li>
              <li>
                <a href="#how-it-works" className="hover:text-blue-400 transition-colors">
                  Digital Khata
                </a>
              </li>
              <li>
                <a href="#insights" className="hover:text-blue-400 transition-colors">
                  Reports & P&L
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
                <button
                  onClick={onAboutClick}
                  className="hover:text-blue-400 transition-colors text-left"
                >
                  About ENX Money
                </button>
              </li>
              <li>
                <button
                  onClick={onContactClick}
                  className="hover:text-blue-400 transition-colors text-left"
                >
                  Contact Desk
                </button>
              </li>
              <li>
                <a
                  href="https://enterprenex.solutions"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="hover:text-blue-400 transition-colors flex items-center gap-1"
                >
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
                <button
                  onClick={onContactClick}
                  className="hover:text-blue-400 transition-colors text-left"
                >
                  Help Center
                </button>
              </li>
              <li>
                <a
                  href={`tel:${SITE_CONFIG.officialPhone.replace(/\s+/g, '')}`}
                  className="hover:text-blue-400 transition-colors"
                >
                  Customer Hotline
                </a>
              </li>
              <li>
                <a href="#faq" className="hover:text-blue-400 transition-colors">
                  FAQ
                </a>
              </li>
              <li>
                <a
                  href={SITE_CONFIG.whatsappUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-emerald-400 hover:text-emerald-300 font-medium"
                >
                  WhatsApp Bot
                </a>
              </li>
            </ul>
          </div>

          {/* Legal & Social Links (2 Cols) */}
          <div className="lg:col-span-2 space-y-3">
            <h4 className="text-xs font-bold text-white uppercase tracking-wider font-display">
              Legal & Policies
            </h4>
            <ul className="space-y-2 text-sm text-slate-400">
              <li>
                <button
                  onClick={() => onLegalClick?.('privacy')}
                  className="hover:text-blue-400 transition-colors text-left"
                >
                  Privacy Policy
                </button>
              </li>
              <li>
                <button
                  onClick={() => onLegalClick?.('terms')}
                  className="hover:text-blue-400 transition-colors text-left"
                >
                  Terms & Conditions
                </button>
              </li>
              <li>
                <button
                  onClick={() => onLegalClick?.('refund')}
                  className="hover:text-blue-400 transition-colors text-left"
                >
                  Refund Policy
                </button>
              </li>
            </ul>

            <div className="pt-2">
              <span className="text-[11px] font-bold text-slate-400 uppercase tracking-wider block mb-2 font-display">
                Official Channels
              </span>
              <div className="flex items-center gap-2 text-slate-400 text-xs">
                <a
                  href={SITE_CONFIG.linkedinUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="hover:text-blue-400 transition-colors font-medium"
                >
                  LinkedIn
                </a>
                <span>•</span>
                <a
                  href={SITE_CONFIG.instagramUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="hover:text-blue-400 transition-colors font-medium"
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
