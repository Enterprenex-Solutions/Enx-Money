import React from 'react';
import { 
  FileText, 
  CheckCircle2, 
  ArrowRight
} from 'lucide-react';
import { SITE_CONFIG } from '../data/content';

interface InvoiceShowcaseProps {
  onCreateInvoiceClick?: () => void;
}

export const InvoiceShowcase: React.FC<InvoiceShowcaseProps> = ({ onCreateInvoiceClick }) => {
  return (
    <section className="py-24 bg-white relative overflow-hidden">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-8 items-center">
          
          {/* Left Column: Feature Highlights & CTAs */}
          <div className="lg:col-span-5 space-y-6">
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs font-semibold tracking-wide">
              <FileText className="w-3.5 h-3.5 text-emerald-600" />
              <span>GST TAX INVOICING</span>
            </div>

            <h2 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-navy-950 font-display tracking-tight leading-tight">
              Create Professional GST Invoices in Seconds.
            </h2>

            <p className="text-base sm:text-lg text-slate-600 font-normal leading-relaxed">
              Eliminate billing disputes and tax miscalculations. ENX Money automatically handles HSN codes, calculates CGST, SGST, and IGST based on location, and embeds dynamic UPI QR codes for rapid payment clearance.
            </p>

            <div className="space-y-3.5 pt-2">
              <div className="flex items-start gap-3">
                <div className="w-5 h-5 rounded-full bg-emerald-100 text-emerald-700 flex items-center justify-center shrink-0 mt-0.5">
                  <CheckCircle2 className="w-3.5 h-3.5" />
                </div>
                <div>
                  <h4 className="text-sm font-bold text-navy-900">Intra-State & Inter-State Auto-Detection</h4>
                  <p className="text-xs text-slate-500">Automatically applies CGST+SGST or IGST based on the customer’s GSTIN and Place of Supply.</p>
                </div>
              </div>

              <div className="flex items-start gap-3">
                <div className="w-5 h-5 rounded-full bg-emerald-100 text-emerald-700 flex items-center justify-center shrink-0 mt-0.5">
                  <CheckCircle2 className="w-3.5 h-3.5" />
                </div>
                <div>
                  <h4 className="text-sm font-bold text-navy-900">Embedded UPI Payment QR Code</h4>
                  <p className="text-xs text-slate-500">Customers can scan directly from the printed or PDF bill using PhonePe, Google Pay, or Paytm.</p>
                </div>
              </div>

              <div className="flex items-start gap-3">
                <div className="w-5 h-5 rounded-full bg-emerald-100 text-emerald-700 flex items-center justify-center shrink-0 mt-0.5">
                  <CheckCircle2 className="w-3.5 h-3.5" />
                </div>
                <div>
                  <h4 className="text-sm font-bold text-navy-900">1-Click WhatsApp & Email Dispatch</h4>
                  <p className="text-xs text-slate-500">Send signed, formatted PDF invoices directly to customer phones with automated payment reminders.</p>
                </div>
              </div>
            </div>

            {/* Action Buttons */}
            <div className="flex flex-wrap items-center gap-4 pt-4">
              <a
                href={SITE_CONFIG.webAppUrl}
                onClick={onCreateInvoiceClick}
                className="inline-flex items-center gap-2 px-6 py-3.5 rounded-xl font-bold text-sm text-white bg-navy-900 hover:bg-navy-850 shadow-md transition-all hover:-translate-y-0.5"
              >
                <span>Create Invoice</span>
                <ArrowRight className="w-4 h-4 text-emerald-400" />
              </a>

              <a
                href="#features"
                className="inline-flex items-center gap-2 px-6 py-3.5 rounded-xl font-bold text-sm text-navy-900 bg-slate-100 hover:bg-slate-200 transition-colors"
              >
                <span>View Features</span>
              </a>
            </div>
          </div>

          {/* Right Column: Realistic GST Invoice Preview */}
          <div className="lg:col-span-7">
            <div className="bg-white rounded-2xl shadow-elevated border border-slate-300 p-6 sm:p-8 max-w-2xl mx-auto font-sans relative">
              
              {/* Top Watermark / Status */}
              <div className="flex items-center justify-between pb-6 border-b-2 border-navy-950">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-navy-900 text-white flex items-center justify-center font-bold text-lg">
                    EX
                  </div>
                  <div>
                    <h3 className="text-base font-extrabold text-navy-950 font-display">Enterprenex Solutions Pvt. Ltd.</h3>
                    <p className="text-[11px] text-slate-500">Chhatrapati Sambhajinagar, Maharashtra - 431136</p>
                    <p className="text-[11px] font-mono text-slate-700 font-semibold">GSTIN: 27AARCP9260R1Z2</p>
                  </div>
                </div>

                <div className="text-right">
                  <div className="inline-block bg-navy-900 text-white text-[10px] font-bold px-3 py-1 rounded tracking-wider uppercase">
                    TAX INVOICE
                  </div>
                  <div className="text-xs font-mono font-bold text-navy-950 mt-1">#ENX/2026-27/0412</div>
                  <div className="text-[11px] text-slate-500">Date: 04 Oct 2026</div>
                </div>
              </div>

              {/* Bill To & Ship To */}
              <div className="grid grid-cols-2 gap-4 py-4 border-b border-slate-200 text-xs">
                <div>
                  <div className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Billed To:</div>
                  <div className="font-bold text-navy-950 mt-0.5">Mahindra Logistics Ltd.</div>
                  <div className="text-slate-600">Viman Nagar Business Bay, Pune, MH</div>
                  <div className="font-mono text-slate-700 font-semibold mt-0.5">GSTIN: 27AABCM4567P1Z5</div>
                </div>

                <div className="text-right">
                  <div className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Invoice Details:</div>
                  <div className="text-slate-700 mt-0.5">Place of Supply: <span className="font-semibold text-navy-950">Maharashtra (27)</span></div>
                  <div className="text-slate-700">Reverse Charge: <span className="font-semibold">No</span></div>
                  <div className="text-slate-700">Due Date: <span className="font-semibold text-emerald-700">Immediate</span></div>
                </div>
              </div>

              {/* Invoice Line Items Table */}
              <div className="py-4 overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-slate-50 text-slate-600 font-bold uppercase text-[10px] border-y border-slate-200">
                    <tr>
                      <th className="py-2 px-2">Item Description</th>
                      <th className="py-2 px-2">HSN</th>
                      <th className="py-2 px-2 text-center">Qty</th>
                      <th className="py-2 px-2 text-right">Rate (₹)</th>
                      <th className="py-2 px-2 text-right">CGST</th>
                      <th className="py-2 px-2 text-right">SGST</th>
                      <th className="py-2 px-2 text-right">Amount (₹)</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 font-medium text-slate-800">
                    <tr>
                      <td className="py-2.5 px-2 font-semibold">Industrial Cloud Sensor Hub</td>
                      <td className="py-2.5 px-2 font-mono text-slate-500">8517</td>
                      <td className="py-2.5 px-2 text-center">2 Nos</td>
                      <td className="py-2.5 px-2 text-right">18,000</td>
                      <td className="py-2.5 px-2 text-right text-slate-600">9% (₹3,240)</td>
                      <td className="py-2.5 px-2 text-right text-slate-600">9% (₹3,240)</td>
                      <td className="py-2.5 px-2 text-right font-bold text-navy-950">42,480.00</td>
                    </tr>
                    <tr>
                      <td className="py-2.5 px-2 font-semibold">Enterprise Telemetry Module</td>
                      <td className="py-2.5 px-2 font-mono text-slate-500">8504</td>
                      <td className="py-2.5 px-2 text-center">1 Nos</td>
                      <td className="py-2.5 px-2 text-right">10,000</td>
                      <td className="py-2.5 px-2 text-right text-slate-600">9% (₹900)</td>
                      <td className="py-2.5 px-2 text-right text-slate-600">9% (₹900)</td>
                      <td className="py-2.5 px-2 text-right font-bold text-navy-950">11,800.00</td>
                    </tr>
                  </tbody>
                </table>
              </div>

              {/* Tax Breakdown & Total Summary */}
              <div className="grid grid-cols-2 gap-4 pt-4 border-t-2 border-slate-200 text-xs">
                
                {/* Bank / QR info */}
                <div className="bg-slate-50 p-3 rounded-xl border border-slate-200/80 space-y-1">
                  <div className="text-[10px] font-bold text-slate-500 uppercase">Payment Bank Details</div>
                  <div className="font-semibold text-navy-950 text-[11px]">Bank of Maharashtra, CIDCO Waluj</div>
                  <div className="text-[10px] text-slate-600 font-mono">A/c: 60418923412 • IFSC: MAHB0001244</div>
                  <div className="text-[10px] text-emerald-700 font-mono font-bold">UPI: enterprenex@mahb</div>
                </div>

                {/* Subtotals */}
                <div className="space-y-1.5 text-right">
                  <div className="flex justify-between text-slate-600">
                    <span>Taxable Value:</span>
                    <span className="font-semibold text-slate-800">₹46,000.00</span>
                  </div>
                  <div className="flex justify-between text-slate-600">
                    <span>Total CGST (9%):</span>
                    <span>₹4,140.00</span>
                  </div>
                  <div className="flex justify-between text-slate-600">
                    <span>Total SGST (9%):</span>
                    <span>₹4,140.00</span>
                  </div>
                  <div className="pt-2 border-t border-slate-300 flex justify-between items-baseline font-bold text-navy-950">
                    <span className="text-sm">Invoice Total:</span>
                    <span className="text-lg text-emerald-700 font-display">₹54,280.00</span>
                  </div>
                </div>

              </div>

              {/* Footer signature line */}
              <div className="mt-6 pt-4 border-t border-slate-100 flex items-center justify-between text-[10px] text-slate-400">
                <span>Computer Generated Tax Invoice. No physical signature required.</span>
                <span className="font-semibold text-slate-700">For Enterprenex Solutions Pvt. Ltd.</span>
              </div>

            </div>
          </div>

        </div>

      </div>
    </section>
  );
};
