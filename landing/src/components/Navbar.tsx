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
  const [activeItem, setActiveItem] = useState<string>('Home');

  // Track scroll position for sticky border & active section spy
  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 10);

      const sections = [
        { name: 'Home', id: 'home' },
        { name: 'Features', id: 'features' },
        { name: 'Khata Guide', id: 'khata-guide' },
        { name: 'Categories', id: 'categories' },
        { name: 'GST Billing', id: 'gst-billing' },
        { name: 'Reports & Insights', id: 'reports-insights' },
        { name: 'FAQ', id: 'faq' },
      ];

      const scrollPosition = window.scrollY + 140;

      for (let i = sections.length - 1; i >= 0; i--) {
        const sec = sections[i];
        if (sec.id === 'home' && window.scrollY < 300) {
          setActiveItem('Home');
          break;
        }
        const el = document.getElementById(sec.id);
        if (el && el.offsetTop <= scrollPosition) {
          setActiveItem(sec.name);
          break;
        }
      }
    };

    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const handleNavClick = (
    e: React.MouseEvent,
    item: { name: string; href?: string; action?: () => void }
  ) => {
    e.preventDefault();
    setActiveItem(item.name);
    setMobileMenuOpen(false);

    if (item.action) {
      item.action();
      return;
    }

    if (item.name === 'Home') {
      window.scrollTo({ top: 0, behavior: 'smooth' });
      return;
    }

    if (item.href) {
      const targetId = item.href.replace('#', '');
      const el = document.getElementById(targetId);
      if (el) {
        el.scrollIntoView({ behavior: 'smooth' });
      }
    }
  };

  // Exactly Ordered Navigation Items:
  // 1. Logo (Positioned on far left)
  // 2. Home
  // 3. Features
  // 4. Khata Guide
  // 5. Categories
  // 6. GST Billing
  // 7. Reports & Insights
  // 8. About Us
  // 9. FAQ
  // 10. Support
  // 11. Login / Sign Up (Positioned on far right as a prominent button)
  const navItems = [
    { name: 'Home', href: '#home' },
    { name: 'Features', href: '#features' },
    { name: 'Khata Guide', href: '#khata-guide' },
    { name: 'Categories', href: '#categories' },
    { name: 'GST Billing', href: '#gst-billing' },
    { name: 'Reports & Insights', href: '#reports-insights' },
    { name: 'About Us', action: onAboutClick },
    { name: 'FAQ', href: '#faq' },
    { name: 'Support', action: onContactClick },
  ];

  return (
    <header
      className={`sticky top-0 left-0 right-0 z-50 bg-white transition-all duration-200 ${
        isScrolled
          ? 'shadow-sm border-b border-slate-200/90 py-2.5'
          : 'border-b border-slate-100 py-3.5'
      }`}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between">
          
          {/* 1. ENX Money Logo — Far Left */}
          <a
            href="#home"
            onClick={(e) => handleNavClick(e, { name: 'Home', href: '#home' })}
            className="flex items-center gap-2.5 sm:gap-3 shrink-0 group focus:outline-none"
            aria-label="ENX Money Home"
          >
            <img
              src="/enx-emblem.png"
              alt="ENX Money Logo"
              className="w-9 h-9 object-contain rounded-xl p-0.5 bg-white border border-slate-200 shadow-sm group-hover:border-blue-400 transition-colors"
            />
            <div className="flex flex-col">
              <span className="text-base sm:text-lg font-black tracking-tight text-slate-900 font-display leading-tight">
                ENX Money
              </span>
              <span className="text-[9px] font-semibold text-blue-600 tracking-wider uppercase">
                Expenses tracker app
              </span>
            </div>
          </a>

          {/* Items 2 - 10: Horizontal Navigation Bar (Desktop) */}
          <nav className="hidden xl:flex items-center gap-1 lg:gap-1.5">
            {navItems.map((item) => {
              const isActive = activeItem === item.name;
              return (
                <button
                  key={item.name}
                  type="button"
                  onClick={(e) => handleNavClick(e, item)}
                  className={`px-3 py-1.5 rounded-lg text-xs font-semibold tracking-tight transition-all cursor-pointer ${
                    isActive
                      ? 'text-blue-600 bg-blue-50/70 font-bold'
                      : 'text-slate-600 hover:text-blue-600 hover:bg-slate-50'
                  }`}
                >
                  {item.name}
                </button>
              );
            })}
          </nav>

          {/* Tablet intermediate navigation (lg screens) */}
          <nav className="hidden lg:flex xl:hidden items-center gap-1">
            {navItems.slice(0, 7).map((item) => {
              const isActive = activeItem === item.name;
              return (
                <button
                  key={item.name}
                  type="button"
                  onClick={(e) => handleNavClick(e, item)}
                  className={`px-2 py-1.5 rounded-lg text-xs font-semibold transition-all cursor-pointer ${
                    isActive
                      ? 'text-blue-600 bg-blue-50/70 font-bold'
                      : 'text-slate-600 hover:text-blue-600 hover:bg-slate-50'
                  }`}
                >
                  {item.name}
                </button>
              );
            })}
          </nav>          {/* 11. Login / Sign Up — Far Right Prominent Button */}
          <div className="hidden md:flex items-center gap-2 shrink-0">
            {isAuthenticated ? (
              <button
                type="button"
                onClick={onDashboardClick}
                className="inline-flex items-center justify-center gap-2 px-4 py-2 rounded-xl font-bold text-xs text-white bg-blue-600 hover:bg-blue-700 shadow-sm shadow-blue-600/20 transition-all cursor-pointer"
              >
                <User className="w-3.5 h-3.5" />
                <span>Dashboard ({user?.name?.split(' ')[0] || 'My Business'})</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </button>
            ) : (
              <>
                <button
                  type="button"
                  onClick={onSignInClick}
                  className="px-3 py-1.5 text-xs font-semibold text-slate-700 hover:text-blue-600 hover:bg-slate-50 rounded-lg transition-all cursor-pointer"
                >
                  Sign In
                </button>
                <button
                  type="button"
                  onClick={onSignUpClick}
                  className="inline-flex items-center justify-center gap-1.5 px-4 py-2 rounded-xl font-bold text-xs text-white bg-blue-600 hover:bg-blue-700 shadow-sm shadow-blue-600/20 transition-all hover:scale-[1.01] cursor-pointer"
                >
                  <span>Login / Sign Up</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </>
            )}
          </div>

          {/* Mobile Menu Hamburger Button */}
          <div className="flex xl:hidden items-center gap-2">
            {!isAuthenticated && (
              <button
                type="button"
                onClick={onSignInClick}
                className="md:hidden px-3 py-1.5 rounded-lg text-xs font-bold text-white bg-blue-600 hover:bg-blue-700"
              >
                Login
              </button>
            )}
            <button
              type="button"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="p-2 rounded-lg text-slate-700 hover:bg-slate-100 transition-colors focus:outline-none cursor-pointer"
              aria-label="Toggle Navigation Menu"
            >
              {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>
          </div>

        </div>
      </div>

      {/* Mobile Drawer Navigation Menu */}
      {mobileMenuOpen && (
        <div className="xl:hidden bg-white border-b border-slate-200 px-4 pt-3 pb-5 space-y-1 animate-fadeIn shadow-lg">
          {navItems.map((item) => {
            const isActive = activeItem === item.name;
            return (
              <button
                key={item.name}
                type="button"
                onClick={(e) => handleNavClick(e, item)}
                className={`w-full text-left px-3.5 py-2.5 rounded-lg text-sm font-semibold transition-all flex items-center justify-between cursor-pointer ${
                  isActive
                    ? 'text-blue-600 bg-blue-50 font-bold'
                    : 'text-slate-700 hover:bg-slate-50 hover:text-blue-600'
                }`}
              >
                <span>{item.name}</span>
                {isActive && <span className="w-1.5 h-1.5 rounded-full bg-blue-600" />}
              </button>
            );
          })}

          <div className="pt-3 border-t border-slate-100 mt-2">
            {isAuthenticated ? (
              <button
                type="button"
                onClick={() => {
                  setMobileMenuOpen(false);
                  onDashboardClick();
                }}
                className="w-full py-2.5 rounded-xl bg-blue-600 text-white font-bold text-center text-xs flex items-center justify-center gap-2 shadow-sm cursor-pointer"
              >
                <User className="w-4 h-4" />
                <span>Go to Business Dashboard</span>
              </button>
            ) : (
              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => {
                    setMobileMenuOpen(false);
                    onSignInClick();
                  }}
                  className="w-full py-2.5 rounded-xl border border-slate-200 text-slate-800 font-bold text-center text-xs bg-slate-50 cursor-pointer"
                >
                  Sign In
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setMobileMenuOpen(false);
                    onSignUpClick();
                  }}
                  className="w-full py-2.5 rounded-xl bg-blue-600 text-white font-bold text-center text-xs flex items-center justify-center gap-1 shadow-sm cursor-pointer"
                >
                  <span>Login / Sign Up</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </div>
            )}
          </div>
        </div>
      )}
    </header>
  );
};

export default Navbar;
