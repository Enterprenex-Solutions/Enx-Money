import React, { useState, useEffect } from 'react';
import confetti from 'canvas-confetti';
import { AuthProvider, useAuth } from './context/AuthContext';
import { Navbar } from './components/Navbar';
import { Hero } from './components/Hero';
import { CategoriesSection } from './components/CategoriesSection';
import { Features } from './components/Features';
import { HowItWorks } from './components/HowItWorks';
import { DashboardShowcase } from './components/DashboardShowcase';
import { InvoiceShowcase } from './components/InvoiceShowcase';
import { InventoryShowcase } from './components/InventoryShowcase';
import { Analytics } from './components/Analytics';
import { Security } from './components/Security';
import { TrustSection } from './components/TrustSection';
import { FAQ } from './components/FAQ';
import { CTA } from './components/CTA';
import { Footer } from './components/Footer';

// Modals
import { AuthModal } from './components/auth/AuthModal';
import { AboutModal } from './components/public/AboutModal';
import { ContactModal } from './components/public/ContactModal';
import { LegalModal } from './components/public/LegalModal';

// Authenticated Business Dashboard
import { DashboardLayout } from './components/dashboard/DashboardLayout';

const MainAppContent: React.FC = () => {
  const { isAuthenticated } = useAuth();

  // Navigation View State
  const [currentView, setCurrentView] = useState<'public' | 'dashboard'>('public');

  // Modals State
  const [authModalOpen, setAuthModalOpen] = useState(false);
  const [authMode, setAuthMode] = useState<'signin' | 'signup'>('signin');
  const [aboutModalOpen, setAboutModalOpen] = useState(false);
  const [contactModalOpen, setContactModalOpen] = useState(false);
  const [legalModalOpen, setLegalModalOpen] = useState(false);
  const [legalTab, setLegalTab] = useState<'privacy' | 'terms' | 'refund'>('privacy');

  // Auto-detect route on load
  useEffect(() => {
    const path = window.location.pathname.toLowerCase();
    const hash = window.location.hash.toLowerCase();
    const search = window.location.search.toLowerCase();

    if (
      path.includes('/app') ||
      path.includes('/dashboard') ||
      path.includes('/web') ||
      hash.includes('#app') ||
      hash.includes('#dashboard') ||
      search.includes('view=dashboard')
    ) {
      if (isAuthenticated) {
        setCurrentView('dashboard');
      } else {
        setAuthMode('signin');
        setAuthModalOpen(true);
      }
    } else if (hash.includes('#terms') || search.includes('terms') || path.includes('/terms')) {
      setLegalTab('terms');
      setLegalModalOpen(true);
    } else if (hash.includes('#privacy') || search.includes('privacy') || path.includes('/privacy')) {
      setLegalTab('privacy');
      setLegalModalOpen(true);
    } else if (hash.includes('#refund') || search.includes('refund') || path.includes('/refund')) {
      setLegalTab('refund');
      setLegalModalOpen(true);
    }

    const handlePopState = () => {
      const p = window.location.pathname.toLowerCase();
      if (p.includes('/app') || p.includes('/dashboard')) {
        setCurrentView('dashboard');
      } else {
        setCurrentView('public');
      }
    };

    window.addEventListener('popstate', handlePopState);
    return () => window.removeEventListener('popstate', handlePopState);
  }, [isAuthenticated]);

  const triggerConfetti = () => {
    try {
      confetti({
        particleCount: 50,
        spread: 60,
        origin: { y: 0.8 },
        colors: ['#2563EB', '#10B981', '#3B82F6', '#06B6D4'],
      });
    } catch (_) {}
  };

  const handleOpenSignIn = () => {
    setAuthMode('signin');
    setAuthModalOpen(true);
  };

  const handleOpenSignUp = () => {
    setAuthMode('signup');
    setAuthModalOpen(true);
  };

  const handleOpenDashboard = () => {
    if (isAuthenticated) {
      setCurrentView('dashboard');
      window.history.pushState({}, '', '/app');
    } else {
      setAuthMode('signin');
      setAuthModalOpen(true);
    }
  };

  const handleBackToPublic = () => {
    setCurrentView('public');
    window.history.pushState({}, '', '/');
  };

  const handleAuthSuccess = () => {
    triggerConfetti();
    setCurrentView('dashboard');
    window.history.pushState({}, '', '/app');
  };

  // 1. If currently in Dashboard View, render the Authenticated Business Suite
  if (currentView === 'dashboard') {
    return (
      <DashboardLayout onBackToPublic={handleBackToPublic} />
    );
  }

  // 2. Otherwise render the public marketing and informational website
  return (
    <div className="min-h-screen bg-white text-slate-800 flex flex-col font-sans selection:bg-blue-600 selection:text-white">
      {/* Sticky Header Navbar */}
      <Navbar
        onSignInClick={handleOpenSignIn}
        onSignUpClick={handleOpenSignUp}
        onDashboardClick={handleOpenDashboard}
        onAboutClick={() => setAboutModalOpen(true)}
        onContactClick={() => setContactModalOpen(true)}
      />

      {/* Main Public Website Sections */}
      <main className="flex-grow">
        {/* 1. Hero Section */}
        <Hero
          onStartFreeClick={handleOpenSignUp}
          onLiveDemoClick={handleOpenDashboard}
        />

        {/* 2. Business Categories & Har Dhandhe Ke Liye */}
        <div id="categories">
          <CategoriesSection />
        </div>

        {/* 3. Product Features Grid */}
        <div id="features">
          <Features />
        </div>

        {/* 4. How It Works (Digital Bahi Khata Workflow) */}
        <div id="how-it-works">
          <HowItWorks />
        </div>

        {/* 5. Business Dashboard Interactive Showcase */}
        <div id="dashboard-preview">
          <DashboardShowcase />
        </div>

        {/* 6. GST Invoice Showcase */}
        <div id="invoices">
          <InvoiceShowcase onCreateInvoiceClick={handleOpenDashboard} />
        </div>

        {/* 7. Inventory Showcase */}
        <div id="inventory">
          <InventoryShowcase />
        </div>

        {/* 8. Business Analytics & Health Score */}
        <div id="insights">
          <Analytics />
        </div>

        {/* 9. Security & DPDP Compliance Pillars */}
        <Security />

        {/* 10. Product-Focused Trust Pillars */}
        <TrustSection />

        {/* 11. FAQ */}
        <div id="faq">
          <FAQ />
        </div>

        {/* 12. Final High-Impact CTA */}
        <CTA
          onDownloadClick={handleOpenSignUp}
          onWebClick={handleOpenDashboard}
        />
      </main>

      {/* Footer */}
      <Footer
        onAboutClick={() => setAboutModalOpen(true)}
        onContactClick={() => setContactModalOpen(true)}
        onLegalClick={(tab) => {
          setLegalTab(tab);
          setLegalModalOpen(true);
        }}
      />

      {/* Interactive Global Modals */}
      <AuthModal
        isOpen={authModalOpen}
        onClose={() => setAuthModalOpen(false)}
        initialMode={authMode}
        onSuccess={handleAuthSuccess}
        onLegalClick={(tab) => {
          setLegalTab(tab);
          setLegalModalOpen(true);
        }}
      />

      <AboutModal
        isOpen={aboutModalOpen}
        onClose={() => setAboutModalOpen(false)}
      />

      <ContactModal
        isOpen={contactModalOpen}
        onClose={() => setContactModalOpen(false)}
      />

      <LegalModal
        isOpen={legalModalOpen}
        onClose={() => setLegalModalOpen(false)}
        initialTab={legalTab}
      />
    </div>
  );
};

export const App: React.FC = () => {
  return (
    <AuthProvider>
      <MainAppContent />
    </AuthProvider>
  );
};

export default App;
