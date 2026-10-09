import React, { useState } from 'react';
import { X, Shield, FileText, RefreshCw, CheckCircle2 } from 'lucide-react';
import { SITE_CONFIG } from '../../data/content';

interface LegalModalProps {
  isOpen: boolean;
  onClose: () => void;
  initialTab?: 'privacy' | 'terms' | 'refund';
}

export const LegalModal: React.FC<LegalModalProps> = ({
  isOpen,
  onClose,
  initialTab = 'privacy',
}) => {
  const [activeTab, setActiveTab] = useState<'privacy' | 'terms' | 'refund'>(initialTab);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 sm:p-6 bg-slate-900/60 backdrop-blur-sm animate-fadeIn">
      <div
        className="relative w-full max-w-3xl max-h-[90vh] flex flex-col bg-white rounded-2xl shadow-2xl border border-slate-100 overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="bg-white px-6 py-4 border-b border-slate-200 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center">
              <Shield className="w-4 h-4" />
            </div>
            <div>
              <h2 className="text-base font-bold text-slate-900">Legal, Governance & Compliance</h2>
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

        {/* Tab Navigation */}
        <div className="flex border-b border-slate-100 bg-slate-50/70 px-6 gap-6 text-xs font-semibold">
          <button
            onClick={() => setActiveTab('privacy')}
            className={`py-3 flex items-center gap-2 border-b-2 transition-all ${
              activeTab === 'privacy'
                ? 'border-blue-600 text-blue-600'
                : 'border-transparent text-slate-500 hover:text-slate-800'
            }`}
          >
            <Shield className="w-3.5 h-3.5" />
            <span>Privacy Policy (DPDP Act 2023)</span>
          </button>
          <button
            onClick={() => setActiveTab('terms')}
            className={`py-3 flex items-center gap-2 border-b-2 transition-all ${
              activeTab === 'terms'
                ? 'border-blue-600 text-blue-600'
                : 'border-transparent text-slate-500 hover:text-slate-800'
            }`}
          >
            <FileText className="w-3.5 h-3.5" />
            <span>Terms of Service</span>
          </button>
          <button
            onClick={() => setActiveTab('refund')}
            className={`py-3 flex items-center gap-2 border-b-2 transition-all ${
              activeTab === 'refund'
                ? 'border-blue-600 text-blue-600'
                : 'border-transparent text-slate-500 hover:text-slate-800'
            }`}
          >
            <RefreshCw className="w-3.5 h-3.5" />
            <span>Refund & Cancellation</span>
          </button>
        </div>

        {/* Content Area */}
        <div className="flex-1 overflow-y-auto p-6 text-sm text-slate-600 leading-relaxed space-y-4">
          {activeTab === 'privacy' && (
            <div className="space-y-4">
              <div className="p-3.5 rounded-xl bg-blue-50/70 border border-blue-100 text-xs text-blue-900 flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-blue-600 flex-shrink-0" />
                <span>Last Updated: October 2026 • Compliant with Indian Digital Personal Data Protection Act 2023.</span>
              </div>
              <h3 className="text-base font-bold text-slate-900">1. Data Collection & Purpose</h3>
              <p>
                Enterprenex Solutions Pvt. Ltd. (&quot;we&quot;, &quot;our&quot;, &quot;Company&quot;) operates the ENX Money application and website. We collect business information (such as merchant name, shop name, email, phone number, GSTIN, and customer ledger entries) solely to deliver digital accounting, khata tracking, payment reconciliation, and invoicing services.
              </p>
              <h3 className="text-base font-bold text-slate-900">2. Customer Financial Data & Confidentiality</h3>
              <p>
                We do NOT sell, rent, or monetize your ledger, customer contacts, or financial books to third-party marketing brokers or advertisers. All transactions and khata records remain strictly confidential to your authenticated merchant account.
              </p>
              <h3 className="text-base font-bold text-slate-900">3. Bank-Grade Encryption & Backups</h3>
              <p>
                All data transmission between your browser and our servers uses TLS 1.3 256-bit SSL encryption. Data at rest is encrypted using AES-256 with automated disaster recovery backups.
              </p>
              <h3 className="text-base font-bold text-slate-900">4. Right to Deletion & Portability</h3>
              <p>
                Merchants retain full rights to export their data in Excel/CSV format or request complete account and data erasure by visiting our settings or emailing <a href={`mailto:${SITE_CONFIG.generalLegalEmail}`} className="text-blue-600 underline">{SITE_CONFIG.generalLegalEmail}</a>.
              </p>
            </div>
          )}

          {activeTab === 'terms' && (
            <div className="space-y-4">
              <h3 className="text-base font-bold text-slate-900">1. Acceptance of Terms</h3>
              <p>
                By creating an account or accessing the ENX Money website, you agree to be bound by these Terms of Service. If you are registering on behalf of a business, you represent that you have legal authority to bind that entity.
              </p>
              <h3 className="text-base font-bold text-slate-900">2. Permitted Merchant Use</h3>
              <p>
                ENX Money is provided as a SaaS accounting and billing utility. You agree not to use the service for unlawful transactions, money laundering, fraud, or activities violating RBI guidelines or the Information Technology Act 2000.
              </p>
              <h3 className="text-base font-bold text-slate-900">3. Subscription Billing & Taxes</h3>
              <p>
                Paid tiers are billed in INR plus applicable GST (18%). Tax invoices will be issued to your registered billing email with full input tax credit eligibility.
              </p>
              <h3 className="text-base font-bold text-slate-900">4. Limitation of Liability</h3>
              <p>
                While we maintain 99.9% uptime, ENX Money is provided on an &quot;as-is&quot; basis for business bookkeeping. Enterprenex Solutions Pvt. Ltd. shall not be held liable for indirect commercial losses or tax filing discrepancies arising from user miscalculations.
              </p>
            </div>
          )}

          {activeTab === 'refund' && (
            <div className="space-y-4">
              <h3 className="text-base font-bold text-slate-900">1. 14-Day Money-Back Guarantee</h3>
              <p>
                We stand behind the quality of ENX Money. If you upgrade to a paid Pro or Enterprise plan and feel unsatisfied with the platform, you may request a 100% refund within 14 calendar days of payment without tricky questions.
              </p>
              <h3 className="text-base font-bold text-slate-900">2. Refund Processing Timeline</h3>
              <p>
                Approved refunds are processed via our payment gateway (Razorpay) back to your original source of payment (UPI, Net Banking, or Card) within 5 to 7 business banking days.
              </p>
              <h3 className="text-base font-bold text-slate-900">3. How to Request a Cancellation or Refund</h3>
              <p>
                Send an email with your registered merchant phone number and invoice receipt to <a href={`mailto:${SITE_CONFIG.billingEmail}`} className="text-blue-600 underline">{SITE_CONFIG.billingEmail}</a> or WhatsApp our billing desk at {SITE_CONFIG.officialPhone}.
              </p>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-slate-100 bg-slate-50 flex items-center justify-between">
          <span className="text-xs text-slate-500">Corporate Address: Waluj, Sambhajinagar, MH - 431136</span>
          <button
            onClick={onClose}
            className="px-5 py-2 rounded-xl text-xs font-semibold text-white bg-blue-600 hover:bg-blue-700 transition-all shadow-sm"
          >
            I Understand
          </button>
        </div>
      </div>
    </div>
  );
};
