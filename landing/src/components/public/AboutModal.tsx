import React from 'react';
import { X, Shield, Award, Users, TrendingUp, Building2 } from 'lucide-react';
import { SITE_CONFIG } from '../../data/content';

interface AboutModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const AboutModal: React.FC<AboutModalProps> = ({ isOpen, onClose }) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 sm:p-6 bg-slate-900/60 backdrop-blur-sm animate-fadeIn">
      <div
        className="relative w-full max-w-2xl max-h-[90vh] overflow-y-auto bg-white rounded-2xl shadow-2xl border border-slate-100"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="sticky top-0 bg-white/95 backdrop-blur-md px-6 py-4 border-b border-slate-100 flex items-center justify-between z-10">
          <div className="flex items-center gap-3">
            <img src="/enx-emblem.png" alt="ENX Money" className="w-8 h-8 rounded-lg border border-slate-100 p-0.5" />
            <div>
              <h2 className="text-lg font-bold text-slate-900 font-display">About ENX Money</h2>
              <p className="text-xs text-slate-500">{SITE_CONFIG.companyName}</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-full hover:bg-slate-100 text-slate-500 hover:text-slate-800 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 space-y-6 text-sm text-slate-600 leading-relaxed">
          <div>
            <h3 className="text-base font-bold text-slate-900 mb-2">Empowering 6.3 Crore Indian Small Businesses</h3>
            <p>
              <strong>ENX Money</strong> is a flagship fintech platform built by <strong>Enterprenex Solutions Pvt. Ltd.</strong> with a singular mission: to make modern financial management, digital bahi-khata, automated WhatsApp debt recovery, and GST invoicing accessible to every Indian shop owner, retailer, and wholesaler.
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="p-4 rounded-xl bg-blue-50/60 border border-blue-100">
              <div className="flex items-center gap-2 text-blue-700 font-bold mb-1">
                <TrendingUp className="w-4 h-4" />
                <span>3x Faster Collections</span>
              </div>
              <p className="text-xs text-slate-600">
                Gentle, automated WhatsApp reminders with integrated UPI links recover credit 3x faster without uncomfortable conversations.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-emerald-50/60 border border-emerald-100">
              <div className="flex items-center gap-2 text-emerald-700 font-bold mb-1">
                <Shield className="w-4 h-4" />
                <span>100% Safe & Compliant</span>
              </div>
              <p className="text-xs text-slate-600">
                End-to-end encryption, automated cloud backups, and full compliance with the Digital Personal Data Protection (DPDP) Act 2023.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-purple-50/60 border border-purple-100">
              <div className="flex items-center gap-2 text-purple-700 font-bold mb-1">
                <Award className="w-4 h-4" />
                <span>GST Invoicing & Reports</span>
              </div>
              <p className="text-xs text-slate-600">
                Generate professional GST invoices and download automated monthly profit/loss reports ready for CA filing in seconds.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-amber-50/60 border border-amber-100">
              <div className="flex items-center gap-2 text-amber-700 font-bold mb-1">
                <Users className="w-4 h-4" />
                <span>Made for Bharat</span>
              </div>
              <p className="text-xs text-slate-600">
                Intuitive interface available in Hindi, English, and regional languages, designed for both desktop web browsers and smartphones.
              </p>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-slate-50 border border-slate-200">
            <h4 className="font-semibold text-slate-800 text-xs uppercase tracking-wider mb-2 flex items-center gap-1.5">
              <Building2 className="w-4 h-4 text-blue-600" /> Registered Corporate Headquarters
            </h4>
            <p className="text-xs text-slate-600 mb-1">
              <strong>Enterprenex Solutions Pvt. Ltd.</strong>
            </p>
            <p className="text-xs text-slate-500">
              {SITE_CONFIG.address}
            </p>
            <p className="text-xs text-slate-500 mt-2">
              CIN / Registration: Registered under Companies Act, Govt of India • Official Support: {SITE_CONFIG.officialPhone}
            </p>
          </div>

          <div className="flex items-center justify-end pt-2">
            <button
              onClick={onClose}
              className="px-5 py-2.5 rounded-xl font-semibold text-xs text-white bg-blue-600 hover:bg-blue-700 transition-all shadow-sm"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
