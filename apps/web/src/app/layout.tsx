import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Enterprenex Solutions — Employee & Work Management System (EWMS)',
  description: 'Enterprise modular workforce, project, task, time and capacity platform for Enterprenex Solutions',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-bg text-slate-100">{children}</body>
    </html>
  );
}
