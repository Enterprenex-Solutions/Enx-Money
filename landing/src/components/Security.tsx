import React from 'react';
import { 
  ShieldCheck, 
  KeyRound, 
  Lock, 
  Server, 
  UserCheck, 
  Cpu, 
  FileKey
} from 'lucide-react';

const SECURITY_ITEMS = [
  {
    title: 'Secure Authentication',
    description: 'Device-bound authentication protects your financial books from unauthorized access attempts.',
    icon: <Lock className="w-5 h-5 text-emerald-600" />,
  },
  {
    title: 'OTP Verification',
    description: 'Instant mobile verification via cryptographic one-time passcodes with strict rate-limiting protection.',
    icon: <KeyRound className="w-5 h-5 text-emerald-600" />,
  },
  {
    title: 'Protected User Accounts',
    description: 'Passwordless security options, salted hash storage, and automated session revocation across devices.',
    icon: <UserCheck className="w-5 h-5 text-emerald-600" />,
  },
  {
    title: 'Secure API Communication',
    description: 'Every request is encrypted in transit using industry-standard TLS 1.3 cryptographic protocols.',
    icon: <FileKey className="w-5 h-5 text-emerald-600" />,
  },
  {
    title: 'Controlled Access',
    description: 'Granular staff roles ensure employees only access the billing counter without viewing net profit or tax filings.',
    icon: <Cpu className="w-5 h-5 text-emerald-600" />,
  },
  {
    title: 'Reliable Cloud Infrastructure',
    description: 'Enterprise server architecture with automated daily backups ensures your ledgers are never lost or corrupted.',
    icon: <Server className="w-5 h-5 text-emerald-600" />,
  },
];

export const Security: React.FC = () => {
  return (
    <section className="py-24 bg-navy-950 text-white relative overflow-hidden">
      
      {/* Background radial accent */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[700px] h-[400px] bg-emerald-500/10 rounded-full blur-3xl pointer-events-none" />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        
        {/* Section Heading */}
        <div className="text-center max-w-3xl mx-auto mb-16 space-y-4">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-navy-900 border border-navy-800 text-emerald-400 text-xs font-semibold tracking-wide">
            <ShieldCheck className="w-3.5 h-3.5" />
            <span>ENTERPRISE-GRADE DATA PRIVACY</span>
          </div>

          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-white font-display tracking-tight">
            Your Business Data Deserves Security.
          </h2>

          <p className="text-base sm:text-lg text-slate-300 font-normal leading-relaxed">
            Financial records and customer contact details require uncompromising defense. ENX Money is architected from the ground up with multi-layered protective protocols.
          </p>
        </div>

        {/* 6-Pillar Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {SECURITY_ITEMS.map((item) => (
            <div
              key={item.title}
              className="bg-navy-900/90 rounded-2xl p-6 border border-navy-800 hover:border-emerald-500/50 shadow-md transition-all duration-300 hover:-translate-y-0.5 group"
            >
              <div className="w-12 h-12 rounded-xl bg-navy-950 border border-navy-800 flex items-center justify-center mb-5 group-hover:bg-emerald-500/10 group-hover:border-emerald-500/30 transition-colors">
                {item.icon}
              </div>

              <h3 className="text-lg font-bold text-white font-display mb-2 group-hover:text-emerald-400 transition-colors">
                {item.title}
              </h3>

              <p className="text-sm text-slate-300 leading-relaxed font-normal">
                {item.description}
              </p>
            </div>
          ))}
        </div>

        {/* Bottom DPDP Act 2023 Compliance Pill */}
        <div className="mt-12 text-center">
          <div className="inline-flex items-center gap-2.5 px-4 py-2 rounded-xl bg-navy-900 border border-navy-800 text-xs text-slate-300 font-medium">
            <span className="w-2 h-2 rounded-full bg-emerald-400"></span>
            <span>Architected in compliance with India's Digital Personal Data Protection (DPDP) Act 2023</span>
          </div>
        </div>

      </div>
    </section>
  );
};
