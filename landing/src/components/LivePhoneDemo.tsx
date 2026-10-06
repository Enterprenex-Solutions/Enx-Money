import React, { useState, useEffect, useRef } from 'react';
import { 
  Check, 
  Send, 
  Search, 
  Receipt, 
  CheckCircle2, 
  UserPlus, 
  Bell, 
  Sparkles,
  Store,
  Phone
} from 'lucide-react';

interface LivePhoneDemoProps {
  onInteract?: () => void;
}

export const LivePhoneDemo: React.FC<LivePhoneDemoProps> = () => {
  const [step, setStep] = useState<number>(0);
  const [progress, setProgress] = useState<number>(0);
  const timerRef = useRef<any>(null);

  const STEP_DURATION = 4000; // 4 seconds per scene
  const TOTAL_STEPS = 4; // 16 seconds total loop

  useEffect(() => {
    const intervalMs = 40;
    const progressIncrement = (intervalMs / (STEP_DURATION * TOTAL_STEPS)) * 100;

    timerRef.current = setInterval(() => {
      setProgress((prev) => {
        const next = prev + progressIncrement;
        if (next >= 100) {
          setStep(0);
          return 0;
        }
        const currentStep = Math.floor((next / 100) * TOTAL_STEPS);
        setStep(currentStep);
        return next;
      });
    }, intervalMs);

    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, []);

  const handleStepJump = (targetStep: number) => {
    setStep(targetStep);
    setProgress((targetStep / TOTAL_STEPS) * 100);
  };

  return (
    <div className="relative w-full max-w-[340px] sm:max-w-[365px] select-none">
      {/* Decorative Glow */}
      <div className="absolute -top-6 -right-6 w-36 h-36 bg-emerald-400/25 rounded-full blur-3xl pointer-events-none animate-pulse"></div>
      <div className="absolute -bottom-8 -left-8 w-32 h-32 bg-cyan-400/20 rounded-full blur-2xl pointer-events-none"></div>

      {/* ── Realistic Smartphone Frame ── */}
      <div className="relative bg-slate-950 rounded-[46px] p-3 shadow-2xl ring-2 ring-slate-800/80 shadow-emerald-950/30">
        
        {/* Dynamic Island / Notch */}
        <div className="absolute top-5 left-1/2 -translate-x-1/2 w-28 h-5 bg-slate-950 rounded-full z-40 flex items-center justify-between px-3 border border-slate-800/60 shadow-inner">
          <div className="w-2.5 h-2.5 rounded-full bg-slate-900 flex items-center justify-center">
            <div className="w-1 h-1 rounded-full bg-blue-500/70"></div>
          </div>
          <div className="flex items-center gap-1">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
            <div className="w-2 h-2 rounded-full bg-slate-900"></div>
          </div>
        </div>

        {/* ── Inner Screen Container ── */}
        <div className="bg-[#F8FAF9] rounded-[38px] overflow-hidden border border-slate-800/70 flex flex-col text-slate-900 min-h-[580px] shadow-inner relative">
          
          {/* Status Bar */}
          <div className="pt-3 px-6 pb-1.5 flex justify-between items-center text-[10px] font-bold text-slate-600 bg-white border-b border-slate-100 z-30">
            <span>9:41</span>
            <div className="flex items-center gap-1.5">
              <span className="text-[9px] font-extrabold text-slate-500">5G</span>
              <div className="w-4 h-2 bg-slate-800 rounded-[2px] p-0.5 flex items-center">
                <div className="w-full h-full bg-emerald-500 rounded-[1px]"></div>
              </div>
            </div>
          </div>

          {/* Continuous Cycle Progress Bar */}
          <div className="w-full h-1 bg-slate-100 relative z-30 overflow-hidden">
            <div 
              className="h-full bg-gradient-to-r from-emerald-500 via-teal-400 to-emerald-600 transition-all duration-75"
              style={{ width: `${progress}%` }}
            />
          </div>

          {/* ── Screen Stage Content (Animated Transitions) ── */}
          <div className="flex-1 flex flex-col relative overflow-hidden bg-[#FAFBF9]">
            
            {/* ════════════════════════════════════════════════════════════
                SCENE 0: Customer Ledger Directory (Search & Click Add)
               ════════════════════════════════════════════════════════════ */}
            {step === 0 && (
              <div className="flex-1 flex flex-col p-3.5 space-y-3 animate-fadeIn">
                {/* App Bar */}
                <div className="flex items-center justify-between bg-emerald-700 text-white -mx-3.5 -mt-3.5 px-4 pt-3 pb-3.5 rounded-b-2xl shadow-sm">
                  <div>
                    <span className="text-[10px] text-emerald-200 block font-semibold uppercase tracking-wider">Mera Khata</span>
                    <h3 className="text-base font-black tracking-tight text-white flex items-center gap-1.5">
                      <span>Ramesh Kirana Store</span>
                    </h3>
                  </div>
                  <div className="text-right">
                    <span className="text-[9px] text-emerald-200 block uppercase font-bold">Total Market Baki</span>
                    <span className="text-sm font-black text-white">₹24,850</span>
                  </div>
                </div>

                {/* Search Customer Bar */}
                <div className="relative">
                  <Search className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-2.5" />
                  <input
                    type="text"
                    readOnly
                    placeholder="Search grahak by name or mobile..."
                    className="w-full pl-8 pr-3 py-1.5 text-xs bg-white rounded-xl border border-slate-200 text-slate-700 shadow-2xs font-medium"
                  />
                </div>

                {/* Customer List Items */}
                <div className="space-y-2 flex-1">
                  <div className="text-[10px] font-bold text-slate-400 uppercase tracking-wider px-1">
                    Active Customers (128)
                  </div>

                  {/* Customer 1: Sharma Kirana */}
                  <div className="bg-white p-2.5 rounded-xl border border-slate-200 flex items-center justify-between shadow-2xs">
                    <div className="flex items-center gap-2.5">
                      <div className="w-8 h-8 rounded-full bg-emerald-100 text-emerald-800 font-extrabold flex items-center justify-center text-xs">
                        SK
                      </div>
                      <div>
                        <div className="text-xs font-bold text-slate-900">Sharma Kirana</div>
                        <div className="text-[10px] text-slate-500">+91 98234 56789</div>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-xs font-black text-rose-600">₹1,850</div>
                      <span className="text-[9px] text-slate-400 font-medium">Baki Due</span>
                    </div>
                  </div>

                  {/* Customer 2: Verma Dairy */}
                  <div className="bg-white p-2.5 rounded-xl border border-slate-200 flex items-center justify-between shadow-2xs opacity-75">
                    <div className="flex items-center gap-2.5">
                      <div className="w-8 h-8 rounded-full bg-blue-100 text-blue-800 font-extrabold flex items-center justify-center text-xs">
                        VD
                      </div>
                      <div>
                        <div className="text-xs font-bold text-slate-900">Verma Dairy Farm</div>
                        <div className="text-[10px] text-slate-500">+91 94220 11223</div>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-xs font-black text-emerald-600">₹0.00</div>
                      <span className="text-[9px] text-emerald-600 font-bold">Hisaab Clear</span>
                    </div>
                  </div>

                  {/* Customer 3: Gupta General Store */}
                  <div className="bg-white p-2.5 rounded-xl border border-slate-200 flex items-center justify-between shadow-2xs opacity-75">
                    <div className="flex items-center gap-2.5">
                      <div className="w-8 h-8 rounded-full bg-amber-100 text-amber-800 font-extrabold flex items-center justify-center text-xs">
                        GG
                      </div>
                      <div>
                        <div className="text-xs font-bold text-slate-900">Gupta Supermart</div>
                        <div className="text-[10px] text-slate-500">+91 91234 88990</div>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-xs font-black text-rose-600">₹3,400</div>
                      <span className="text-[9px] text-slate-400 font-medium">Baki Due</span>
                    </div>
                  </div>
                </div>

                {/* Floating Add Customer CTA with Animated Hand Cursor */}
                <div className="relative pt-1">
                  <div className="w-full py-3 bg-emerald-600 rounded-2xl text-white font-extrabold text-xs flex items-center justify-center gap-2 shadow-lg shadow-emerald-600/30 border border-emerald-500 animate-pulse">
                    <UserPlus className="w-4 h-4" />
                    <span>+ Naya Grahak / Business Jodein</span>
                  </div>

                  {/* Tap Ripple Indicator */}
                  <div className="absolute right-12 -top-1 w-8 h-8 rounded-full bg-emerald-400/40 animate-ping pointer-events-none"></div>
                  <div className="absolute right-14 top-1 w-4 h-4 rounded-full bg-white border-2 border-emerald-600 shadow-md pointer-events-none"></div>
                </div>
              </div>
            )}

            {/* ════════════════════════════════════════════════════════════
                SCENE 1: Adding Customer Business Profile Modal
               ════════════════════════════════════════════════════════════ */}
            {step === 1 && (
              <div className="flex-1 flex flex-col p-4 bg-slate-900/40 animate-fadeIn relative">
                {/* Background Dimmed Ledger */}
                <div className="absolute inset-0 bg-slate-900/30 backdrop-blur-[1px] z-10"></div>

                {/* Animated Slide-Up Modal */}
                <div className="mt-auto bg-white rounded-t-3xl p-4 shadow-2xl border-t border-emerald-200 z-20 space-y-3 animate-slideUp">
                  <div className="w-10 h-1 bg-slate-300 rounded-full mx-auto -mt-1 mb-2"></div>
                  
                  <div className="flex items-center justify-between border-b border-slate-100 pb-2">
                    <div className="flex items-center gap-1.5">
                      <Store className="w-4 h-4 text-emerald-600" />
                      <h4 className="text-xs font-black text-slate-900">Naya Grahak Business Account</h4>
                    </div>
                    <span className="text-[9px] bg-emerald-100 text-emerald-800 font-bold px-2 py-0.5 rounded-full">
                      Step 1 of 2
                    </span>
                  </div>

                  {/* Business Name Field */}
                  <div className="space-y-1">
                    <label className="text-[10px] font-bold text-slate-500 uppercase">Dukaan / Grahak Name</label>
                    <div className="flex items-center gap-2 px-3 py-2 bg-emerald-50/70 border border-emerald-300 rounded-xl text-xs font-bold text-slate-900 shadow-inner">
                      <Store className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                      <span>Sharma Kirana Store</span>
                      <span className="w-1.5 h-4 bg-emerald-600 animate-pulse ml-auto"></span>
                    </div>
                  </div>

                  {/* Mobile Number Field */}
                  <div className="space-y-1">
                    <label className="text-[10px] font-bold text-slate-500 uppercase">WhatsApp Mobile Number</label>
                    <div className="flex items-center gap-2 px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-800">
                      <Phone className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                      <span>+91 98234 56789</span>
                      <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600 ml-auto" />
                    </div>
                  </div>

                  {/* Opening Balance Field */}
                  <div className="space-y-1">
                    <label className="text-[10px] font-bold text-slate-500 uppercase">Opening Udhar (Balance Due)</label>
                    <div className="flex items-center justify-between px-3 py-2 bg-rose-50/80 border border-rose-200 rounded-xl text-xs font-black text-rose-700">
                      <span>Pehle ka baki udhar:</span>
                      <span className="text-sm font-black text-rose-700">₹1,850</span>
                    </div>
                  </div>

                  {/* Save Button */}
                  <div className="pt-1 relative">
                    <button className="w-full py-2.5 bg-emerald-600 rounded-xl text-white font-extrabold text-xs flex items-center justify-center gap-1.5 shadow-md shadow-emerald-600/30">
                      <Check className="w-4 h-4" />
                      <span>Khata Kholein (Save & Open Khata)</span>
                    </button>
                    {/* Ripple on save */}
                    <div className="absolute right-10 top-2 w-6 h-6 rounded-full bg-white/40 animate-ping"></div>
                  </div>
                </div>
              </div>
            )}

            {/* ════════════════════════════════════════════════════════════
                SCENE 2: Customer Ledger with Udhar Entry Recorded
               ════════════════════════════════════════════════════════════ */}
            {step === 2 && (
              <div className="flex-1 flex flex-col animate-fadeIn">
                {/* Customer Active Bar */}
                <div className="bg-white px-4 py-2.5 border-b border-slate-200 flex items-center justify-between shadow-2xs">
                  <div className="flex items-center gap-2.5">
                    <div className="w-9 h-9 rounded-full bg-amber-500 text-white font-black flex items-center justify-center text-xs shadow-sm">
                      SK
                    </div>
                    <div>
                      <div className="text-xs font-black text-slate-900 flex items-center gap-1">
                        <span>Sharma Kirana</span>
                        <CheckCircle2 className="w-3 h-3 text-emerald-600 fill-emerald-100" />
                      </div>
                      <span className="text-[10px] font-semibold text-slate-500">+91 98234 56789</span>
                    </div>
                  </div>
                  <div className="flex items-center gap-2 text-slate-400">
                    <Receipt className="w-4 h-4" />
                    <Search className="w-4 h-4" />
                  </div>
                </div>

                {/* Ledger Entries */}
                <div className="p-3.5 space-y-2.5 flex-1 bg-[#FAFBF9]">
                  {/* Today Chip */}
                  <div className="flex justify-center">
                    <span className="bg-slate-200/80 text-slate-600 text-[9px] font-bold px-2 py-0.5 rounded-full">
                      Aaj • Just Now
                    </span>
                  </div>

                  {/* New Udhar Entry Added */}
                  <div className="bg-white p-3 rounded-2xl border-2 border-rose-200 shadow-sm flex items-center justify-between animate-scaleIn">
                    <div>
                      <span className="text-[11px] font-bold text-slate-900 block">Basmati Rice 50kg, Oil 10L</span>
                      <div className="text-[10px] text-slate-500">11:30 AM • Bill #GST-4102</div>
                    </div>
                    <div className="text-right">
                      <span className="text-[10px] font-bold text-rose-600 block">Udhar diya</span>
                      <span className="text-sm font-black text-slate-900">₹1,850</span>
                    </div>
                  </div>

                  {/* Balance Due Banner */}
                  <div className="bg-rose-50 px-3 py-2 rounded-xl border border-rose-200 text-center flex items-center justify-between">
                    <span className="text-[11px] text-slate-600 font-medium">Total Baki (Balance Due):</span>
                    <strong className="text-sm font-black text-rose-600">₹1,850.00</strong>
                  </div>
                </div>

                {/* WhatsApp Reminder Pop-up Bar */}
                <div className="bg-slate-900 text-white p-3 rounded-t-3xl shadow-xl space-y-2.5 border-t-2 border-emerald-500 animate-slideUp">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-1.5">
                      <div className="w-4 h-4 rounded-full bg-emerald-500 flex items-center justify-center">
                        <Send className="w-2.5 h-2.5 text-white fill-white" />
                      </div>
                      <span className="text-xs font-bold text-emerald-400">WhatsApp Payment Reminder</span>
                    </div>
                    <span className="text-[9px] text-slate-400">Auto-ready</span>
                  </div>

                  <div className="bg-slate-800 rounded-xl p-2.5 border border-slate-700 flex items-center justify-between">
                    <div>
                      <span className="text-[9px] text-slate-300 block">Reminder to Sharma Kirana</span>
                      <div className="text-sm font-black text-white">₹1,850.00</div>
                    </div>
                    <button className="px-3 py-1.5 rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-xs flex items-center gap-1 shadow-sm animate-pulse">
                      <Send className="w-3 h-3" />
                      <span>Remind</span>
                    </button>
                  </div>
                </div>
              </div>
            )}

            {/* ════════════════════════════════════════════════════════════
                SCENE 3: Instant UPI Payment Settlement & Balance Clear!
               ════════════════════════════════════════════════════════════ */}
            {step === 3 && (
              <div className="flex-1 flex flex-col animate-fadeIn relative">
                {/* Incoming Notification Dropdown */}
                <div className="mx-3 mt-2 bg-slate-900 text-white p-2.5 rounded-2xl shadow-xl border border-emerald-500/80 flex items-center gap-2.5 z-30 animate-bounce">
                  <div className="w-7 h-7 rounded-full bg-emerald-500 flex items-center justify-center shrink-0 shadow-md">
                    <Bell className="w-4 h-4 text-white" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="text-[11px] font-black text-emerald-400 flex items-center gap-1">
                      <span>UPI Payment Received!</span>
                      <Sparkles className="w-3 h-3 text-amber-300" />
                    </div>
                    <div className="text-[10px] text-slate-200 truncate">
                      Sharma Kirana paid <strong>₹1,850</strong> via PhonePe
                    </div>
                  </div>
                  <span className="text-[9px] font-bold text-slate-400">Abhi</span>
                </div>

                {/* Customer Active Bar */}
                <div className="bg-white px-4 py-2 border-b border-slate-200 flex items-center justify-between mt-1">
                  <div className="flex items-center gap-2">
                    <div className="w-8 h-8 rounded-full bg-emerald-600 text-white font-black flex items-center justify-center text-xs">
                      SK
                    </div>
                    <div>
                      <div className="text-xs font-black text-slate-900">Sharma Kirana</div>
                      <span className="text-[9px] font-semibold text-emerald-600">Payment Verified ✓</span>
                    </div>
                  </div>
                  <span className="px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 text-[10px] font-extrabold">
                    Settled
                  </span>
                </div>

                {/* Ledger Entries Updating Live */}
                <div className="p-3.5 space-y-2 flex-1 bg-[#FAFBF9]">
                  {/* Previous Udhar */}
                  <div className="bg-white/80 p-2.5 rounded-xl border border-slate-200 flex items-center justify-between opacity-60">
                    <div>
                      <span className="text-[10px] font-medium text-slate-600">Basmati Rice 50kg</span>
                      <div className="text-[9px] text-slate-400">11:30 AM</div>
                    </div>
                    <span className="text-xs font-bold text-slate-700">₹1,850</span>
                  </div>

                  {/* Payment Received Entry with Green Glow */}
                  <div className="bg-emerald-50 p-3 rounded-2xl border-2 border-emerald-400 shadow-md flex items-center justify-between">
                    <div>
                      <span className="text-[11px] font-extrabold text-emerald-900 flex items-center gap-1">
                        <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600 fill-emerald-100" />
                        Full UPI Payment Received
                      </span>
                      <div className="text-[10px] text-emerald-700 font-semibold">11:32 AM • PhonePe / QR</div>
                    </div>
                    <div className="text-right">
                      <span className="text-[10px] font-bold text-emerald-700 block">↑ Jama (Paid)</span>
                      <span className="text-sm font-black text-emerald-700">₹1,850.00</span>
                    </div>
                  </div>

                  {/* Balance Zero - Hisaab Chuka Banner */}
                  <div className="bg-emerald-600 text-white px-3 py-2.5 rounded-xl text-center shadow-md animate-pulse">
                    <span className="text-[10px] text-emerald-100 block uppercase font-bold tracking-wider">Current Balance Due</span>
                    <strong className="text-base font-black">₹0.00 • Hisaab Chuka!</strong>
                  </div>
                </div>

                {/* Bottom Notification */}
                <div className="bg-slate-900 text-slate-300 p-3 text-center text-[10px] font-bold border-t border-slate-800">
                  <span className="text-emerald-400">✓ Customer SMS & WhatsApp confirmation sent</span>
                </div>
              </div>
            )}

          </div>

          {/* ── Bottom Navigation Timeline Bar ── */}
          <div className="bg-white border-t border-slate-200 p-2 px-3 z-30">
            <div className="grid grid-cols-4 gap-1 text-center">
              {[
                { idx: 0, label: '1. Grahak' },
                { idx: 1, label: '2. Add Info' },
                { idx: 2, label: '3. Udhar' },
                { idx: 3, label: '4. UPI Paid' },
              ].map((s) => (
                <button
                  key={s.idx}
                  onClick={() => handleStepJump(s.idx)}
                  className={`py-1 rounded-lg text-[9px] font-bold transition-all ${
                    step === s.idx
                      ? 'bg-emerald-600 text-white shadow-xs scale-105'
                      : 'bg-slate-100 text-slate-500 hover:bg-slate-200'
                  }`}
                >
                  {s.label}
                </button>
              ))}
            </div>
          </div>

        </div>

      </div>
    </div>
  );
};
