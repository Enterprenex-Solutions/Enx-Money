import React from 'react';
import confetti from 'canvas-confetti';
import { Navbar } from './components/Navbar';
import { Hero } from './components/Hero';
import { CategoriesSection } from './components/CategoriesSection';
import { AppDownload } from './components/AppDownload';
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
import { FloatingCTA } from './components/FloatingCTA';

export const App: React.FC = () => {
  const triggerConfetti = () => {
    try {
      confetti({
        particleCount: 60,
        spread: 70,
        origin: { y: 0.8 },
        colors: ['#10B981', '#0B192C', '#34D399', '#06B6D4'],
      });
    } catch (_) {}
  };

  const handleDownloadClick = () => {
    triggerConfetti();
  };

  const handleWebClick = () => {
    // Navigate to web app
  };

  return (
    <div className="min-h-screen bg-white text-slate-800 flex flex-col">
      {/* Sticky Navigation */}
      <Navbar onDownloadClick={handleDownloadClick} onWebClick={handleWebClick} />

      {/* Main Content Sections */}
      <main className="flex-grow">
        {/* 1. Hero Section with Live OkCredit Style Smartphone Mockup */}
        <Hero onDownloadClick={handleDownloadClick} onWebClick={handleWebClick} />

        {/* 2. Metrics Ribbon & Har Dhandhe Ke Liye Categories Section */}
        <CategoriesSection />

        {/* 3. App Download Section (Dedicated Cross-Platform with QR) */}
        <AppDownload onDownloadTriggered={triggerConfetti} />

        {/* 3. Product Features Grid (8 Cards) */}
        <Features />

        {/* 4. How It Works (3-Step Timeline) */}
        <HowItWorks />

        {/* 5. ENX Money Dashboard Showcase (Interactive Tabs) */}
        <DashboardShowcase />

        {/* 6. GST Invoice Showcase */}
        <InvoiceShowcase onCreateInvoiceClick={handleWebClick} />

        {/* 7. Inventory Showcase */}
        <InventoryShowcase />

        {/* 8. Business Insights & Analytics */}
        <Analytics />

        {/* 9. Security & Infrastructure */}
        <Security />

        {/* 10. Product-Focused Trust Pillars */}
        <TrustSection />

        {/* 11. Frequently Asked Questions */}
        <FAQ />

        {/* 12. Final High-Impact CTA */}
        <CTA onDownloadClick={handleDownloadClick} onWebClick={handleWebClick} />
      </main>

      {/* Footer */}
      <Footer />

      {/* Persistent Floating Download CTA for mobile & desktop */}
      <FloatingCTA onDownloadClick={handleDownloadClick} onWebClick={handleWebClick} />
    </div>
  );
};

export default App;
