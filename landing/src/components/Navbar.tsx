import React, { useState, useEffect } from 'react';
import { Menu, X, Download, Globe, LogIn } from 'lucide-react';
import { SITE_CONFIG } from '../data/content';

interface NavbarProps {
  onDownloadClick?: () => void;
  onWebClick?: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({ onDownloadClick, onWebClick }) => {
  const [isScrolled, setIsScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const navLinks = [
    { name: 'Features', href: '#features' },
    { name: 'Khata Guide', href: '#how-it-works' },
    { name: 'Har Dhandhe Ke Liye', href: '#categories' },
    { name: 'Reports & Insights', href: '#insights' },
    { name: 'FAQ', href: '#faq' },
  ];

  return (
    <header
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        isScrolled
          ? 'bg-white/95 backdrop-blur-md shadow-sm py-3 border-b border-emerald-100/60'
          : 'bg-white/90 backdrop-blur-sm py-4 border-b border-slate-100'
      }`}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between">
          {/* Official Enterprenex Solutions Brand Logo */}
          <a href="#hero" className="flex items-center gap-3 group">
            <img
              src="/enterprenex-badge.png"
              alt="Enterprenex Solutions"
              className="w-10 h-10 object-contain rounded-full shadow-sm group-hover:scale-105 transition-transform bg-white p-0.5 border border-slate-100"
            />
            <div className="flex flex-col">
              <span className="text-xl font-black tracking-tight text-slate-900 font-display flex items-center gap-1.5">
                {SITE_CONFIG.brandName}
              </span>
              <span className="text-[11px] font-semibold text-slate-500 tracking-tight">
                by Enterprenex Solutions
              </span>
            </div>
          </a>

          {/* Desktop Navigation Links */}
          <nav className="hidden lg:flex items-center gap-8">
            {navLinks.map((link) => (
              <a
                key={link.name}
                href={link.href}
                className="text-sm font-semibold text-slate-700 hover:text-emerald-600 transition-colors py-1 relative hover:after:w-full after:w-0 after:h-0.5 after:bg-emerald-600 after:absolute after:bottom-0 after:left-0 after:transition-all after:duration-200"
              >
                {link.name}
              </a>
            ))}
          </nav>

          {/* Right Action Icons & Web CTA */}
          <div className="hidden md:flex items-center gap-2.5">
            {/* Enterprenex Company Portal Login Link */}
            <a
              href="/portal"
              className="text-xs font-semibold text-slate-600 hover:text-slate-900 transition-colors flex items-center gap-1.5 py-2 px-3 rounded-lg hover:bg-slate-100"
              title="Enterprenex Company Management Portal"
            >
              <LogIn className="w-3.5 h-3.5 text-slate-500" />
              <span>Portal</span>
            </a>

            {/* Quick Web app link (Desktop / Laptop) */}
            <a
              href={SITE_CONFIG.webAppUrl}
              onClick={onWebClick}
              target="_blank"
              rel="noopener noreferrer"
              className="text-xs font-semibold text-slate-600 hover:text-slate-900 transition-colors flex items-center gap-1.5 py-2 px-3 rounded-lg hover:bg-slate-100"
              title="Open ENX Money in Browser (Desktop / Laptop)"
            >
              <Globe className="w-3.5 h-3.5 text-slate-500" />
              <span>Web App</span>
            </a>

            {/* Download Android App Button (Direct APK) */}
            <a
              href={SITE_CONFIG.apkDirectDownloadUrl}
              download="ENX-Money-Consumer.apk"
              onClick={onDownloadClick}
              className="inline-flex items-center justify-center gap-2 px-4 py-2 rounded-lg font-semibold text-xs text-white bg-slate-900 hover:bg-slate-800 transition-all shadow-sm"
              title="Direct APK Download for Android"
            >
              <Download className="w-3.5 h-3.5" />
              <span>Download App</span>
            </a>
          </div>

          {/* Mobile Hamburger Toggle */}
          <div className="flex lg:hidden items-center gap-2">
            <a
              href="/portal"
              className="p-2 rounded-lg text-emerald-700 bg-emerald-50 border border-emerald-200"
              title="Portal Login"
            >
              <LogIn className="w-4 h-4" />
            </a>

            <a
              href="#download"
              onClick={onDownloadClick}
              className="p-2 rounded-full text-white bg-emerald-600 hover:bg-emerald-700 transition-colors"
              title="Download App"
            >
              <Download className="w-4 h-4" />
            </a>
            
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="p-2 rounded-lg text-slate-700 hover:bg-slate-100 transition-colors"
              aria-label="Toggle Menu"
            >
              {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
            </button>
          </div>
        </div>
      </div>

      {/* Mobile Menu Dropdown */}
      {mobileMenuOpen && (
        <div className="lg:hidden bg-white border-b border-slate-200 px-4 pt-4 pb-6 space-y-3 animate-fadeIn shadow-xl">
          {navLinks.map((link) => (
            <a
              key={link.name}
              href={link.href}
              onClick={() => setMobileMenuOpen(false)}
              className="block px-3 py-2.5 rounded-lg text-base font-semibold text-slate-800 hover:bg-emerald-50 hover:text-emerald-700"
            >
              {link.name}
            </a>
          ))}
          <div className="pt-3 border-t border-slate-100 flex flex-col gap-2.5">
            {/* Portal Login Mobile Link */}
            <a
              href="/portal"
              onClick={() => setMobileMenuOpen(false)}
              className="w-full py-3 rounded-xl border border-emerald-300 text-emerald-900 font-bold text-center text-sm flex items-center justify-center gap-2 bg-emerald-50/90 shadow-sm"
            >
              <LogIn className="w-4 h-4 text-emerald-600" />
              <span>Portal Login (CEO, CTO, CFO, HR & Staff)</span>
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
            </a>

            <a
              href={SITE_CONFIG.whatsappUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="w-full py-3 rounded-xl border border-emerald-300 text-emerald-800 font-bold text-center text-sm flex items-center justify-center gap-2 bg-emerald-50"
            >
              <svg className="w-4 h-4 fill-current text-emerald-600" viewBox="0 0 24 24">
                <path d="M12.031 6.172c-3.181 0-5.767 2.586-5.768 5.766-.001 1.298.38 2.27 1.019 3.287l-.582 2.128 2.182-.573c.978.58 1.911.928 3.145.929 3.178 0 5.767-2.587 5.768-5.766.001-3.187-2.575-5.77-5.764-5.771zm3.392 8.244c-.144.405-.837.774-1.17.824-.299.045-.677.063-1.092-.069-.252-.08-.575-.187-.988-.365-1.739-.751-2.874-2.502-2.961-2.617-.087-.116-.708-.94-.708-1.793s.448-1.273.607-1.446c.159-.173.346-.217.462-.217l.332.007c.106.005.249-.04.39.298.144.347.491 1.2.534 1.287.043.087.072.188.014.304-.058.116-.087.188-.173.289l-.26.304c-.087.086-.177.18-.076.354.101.174.449.741.964 1.201.662.591 1.221.774 1.394.86.174.086.275.072.376-.044.101-.116.433-.506.549-.68.116-.173.231-.145.39-.087s1.011.477 1.184.564.289.13.332.202c.043.073.043.419-.101.824z" />
              </svg>
              <span>WhatsApp Par Baat Karein</span>
            </a>
            <a
              href={SITE_CONFIG.webAppUrl}
              onClick={() => {
                setMobileMenuOpen(false);
                onWebClick?.();
              }}
              className="w-full py-3 rounded-xl border border-slate-200 text-slate-800 font-bold text-center text-sm flex items-center justify-center gap-2 bg-slate-50"
            >
              <Globe className="w-4 h-4 text-emerald-600" />
              <span>Web Version Kholein</span>
            </a>
            <a
              href={SITE_CONFIG.apkDirectDownloadUrl}
              download="ENX-Money-Consumer.apk"
              onClick={() => {
                setMobileMenuOpen(false);
                onDownloadClick?.();
              }}
              className="w-full py-3 rounded-xl bg-emerald-600 text-white font-bold text-center text-sm flex items-center justify-center gap-2 shadow-md shadow-emerald-600/20 hover:bg-emerald-700"
            >
              <Download className="w-4 h-4" />
              <span>Download Android App</span>
            </a>
          </div>
        </div>
      )}
    </header>
  );
};
