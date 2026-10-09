import React, { useState, useEffect } from 'react';
import { Menu, X, ArrowRight, User } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

interface NavbarProps {
  onSignInClick: () => void;
  onSignUpClick: () => void;
  onDashboardClick: () => void;
  onAboutClick: () => void;
  onContactClick: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({
  onSignInClick,
  onSignUpClick,
  onDashboardClick,
  onAboutClick,
  onContactClick,
}) => {
  const { isAuthenticated, user } = useAuth();
  const [isScrolled, setIsScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 15);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const navLinks = [
    { name: 'Features', href: '#features' },
    { name: 'Khata Guide', href: '#how-it-works' },
    { name: 'Categories', href: '#categories' },
    { name: 'GST Billing', href: '#invoices' },
    { name: 'Reports & Insights', href: '#insights' },
    { name: 'FAQ', href: '#faq' },
  ];

  return (
    <header
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        isScrolled
          ? 'bg-white/95 backdrop-blur-md shadow-sm py-3 border-b border-slate-200/80'
          : 'bg-white/90 backdrop-blur-sm py-4 border-b border-slate-100'
      }`}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between">
          {/* Official ENX Money Brand Logo */}
          <a href="#" className="flex items-center gap-3 group">
            <img
              src="/enx-emblem.png"
              alt="ENX Money"
              className="w-10 h-10 object-contain rounded-xl shadow-sm group-hover:scale-105 transition-transform bg-white p-0.5 border border-slate-100"
            />
            <div className="flex flex-col">
              <span className="text-xl font-black tracking-tight text-slate-900 font-display flex items-center gap-1.5">
                ENX Money
              </span>
              <span className="text-[10px] font-semibold text-blue-600 tracking-tight uppercase">
                Expenses tracker app
              </span>
            </div>
          </a>

          {/* Desktop Navigation Links */}
          <nav className="hidden lg:flex items-center gap-7">
            {navLinks.map((link) => (
              <a
                key={link.name}
                href={link.href}
                className="text-xs font-semibold text-slate-600 hover:text-blue-600 transition-colors py-1 relative hover:after:w-full after:w-0 after:h-0.5 after:bg-blue-600 after:absolute after:bottom-0 after:left-0 after:transition-all after:duration-200"
              >
                {link.name}
              </a>
            ))}
            <button
              onClick={onAboutClick}
              className="text-xs font-semibold text-slate-600 hover:text-blue-600 transition-colors py-1"
            >
              About
            </button>
            <button
              onClick={onContactClick}
              className="text-xs font-semibold text-slate-600 hover:text-blue-600 transition-colors py-1"
            >
              Support
            </button>
          </nav>

          {/* Right Action Buttons */}
          <div className="hidden md:flex items-center gap-3">
            {isAuthenticated ? (
              <button
                onClick={onDashboardClick}
                className="inline-flex items-center justify-center gap-2 px-4 py-2 rounded-xl font-bold text-xs text-white bg-blue-600 hover:bg-blue-700 shadow-md shadow-blue-500/20 transition-all"
              >
                <User className="w-3.5 h-3.5" />
                <span>Open Dashboard ({user?.name?.split(' ')[0] || 'My Business'})</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </button>
            ) : (
              <>
                <button
                  onClick={onSignInClick}
                  className="px-3.5 py-2 text-xs font-semibold text-slate-700 hover:text-blue-600 hover:bg-slate-50 rounded-xl transition-all"
                >
                  Sign In
                </button>
                <button
                  onClick={onSignUpClick}
                  className="inline-flex items-center justify-center gap-1.5 px-4 py-2 rounded-xl font-bold text-xs text-white bg-blue-600 hover:bg-blue-700 shadow-md shadow-blue-500/20 transition-all hover:scale-[1.02]"
                >
                  <span>Start Free</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </>
            )}
          </div>

          {/* Mobile Hamburger Toggle */}
          <div className="flex lg:hidden items-center gap-2">
            <button
              onClick={isAuthenticated ? onDashboardClick : onSignInClick}
              className="px-3 py-1.5 rounded-lg text-xs font-bold text-white bg-blue-600 hover:bg-blue-700"
            >
              {isAuthenticated ? 'Dashboard' : 'Sign In'}
            </button>
            
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="p-2 rounded-lg text-slate-700 hover:bg-slate-100 transition-colors"
              aria-label="Toggle Menu"
            >
              {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>
          </div>
        </div>
      </div>

      {/* Mobile Menu Dropdown */}
      {mobileMenuOpen && (
        <div className="lg:hidden bg-white border-b border-slate-200 px-4 pt-3 pb-5 space-y-2 animate-fadeIn shadow-xl">
          {navLinks.map((link) => (
            <a
              key={link.name}
              href={link.href}
              onClick={() => setMobileMenuOpen(false)}
              className="block px-3 py-2 rounded-lg text-sm font-semibold text-slate-700 hover:bg-blue-50 hover:text-blue-600"
            >
              {link.name}
            </a>
          ))}
          <button
            onClick={() => {
              setMobileMenuOpen(false);
              onAboutClick();
            }}
            className="w-full text-left px-3 py-2 rounded-lg text-sm font-semibold text-slate-700 hover:bg-blue-50 hover:text-blue-600"
          >
            About ENX Money
          </button>
          <button
            onClick={() => {
              setMobileMenuOpen(false);
              onContactClick();
            }}
            className="w-full text-left px-3 py-2 rounded-lg text-sm font-semibold text-slate-700 hover:bg-blue-50 hover:text-blue-600"
          >
            Contact & 24/7 Support
          </button>

          <div className="pt-3 border-t border-slate-100 flex flex-col gap-2">
            {isAuthenticated ? (
              <button
                onClick={() => {
                  setMobileMenuOpen(false);
                  onDashboardClick();
                }}
                className="w-full py-2.5 rounded-xl bg-blue-600 text-white font-bold text-center text-xs flex items-center justify-center gap-2 shadow-md shadow-blue-500/20"
              >
                <span>Go to Dashboard</span>
                <ArrowRight className="w-4 h-4" />
              </button>
            ) : (
              <>
                <button
                  onClick={() => {
                    setMobileMenuOpen(false);
                    onSignInClick();
                  }}
                  className="w-full py-2.5 rounded-xl border border-slate-200 text-slate-800 font-bold text-center text-xs bg-slate-50"
                >
                  Sign In to Account
                </button>
                <button
                  onClick={() => {
                    setMobileMenuOpen(false);
                    onSignUpClick();
                  }}
                  className="w-full py-2.5 rounded-xl bg-blue-600 text-white font-bold text-center text-xs shadow-md shadow-blue-500/20"
                >
                  Create Free Account
                </button>
              </>
            )}
          </div>
        </div>
      )}
    </header>
  );
};
