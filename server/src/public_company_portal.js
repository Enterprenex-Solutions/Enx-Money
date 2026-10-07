/**
 * Enterprenex Solutions — Company Management Portal Web Application
 * 
 * Minimalist, Modern, Production-Ready SaaS UI:
 * - Ultra-clean slate/neutral palette (no gaudy gradients or neon glows)
 * - Crisp typography & structured hierarchy (Plus Jakarta Sans + JetBrains Mono)
 * - Role-tailored navigation (Employee, HR, CEO, CTO, CFO, Lead, Intern)
 * - Focused dashboard summary cards and actionable metrics
 * - Enhanced tables with live search, filtering, status badges & empty states
 * - Fully responsive layout with mobile drawer toggle
 * - Toast notification system and confirmation dialogs
 * - 100% preservation of all existing backend APIs, RBAC logic & authentication
 */

function getCompanyPortalHtml() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Enterprenex — Company Management Portal</title>
  <link rel="icon" type="image/png" href="/enterprenex-badge.png">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
  <style>
    /* ─── DESIGN TOKENS & RESET ─────────────────────────── */
    :root {
      --bg: #090d16;
      --surface: #0f172a;
      --surface-elevated: #131d35;
      --surface-hover: #1a2644;
      --border: #1e293b;
      --border-subtle: #162032;
      --border-focus: #3b82f6;

      --text: #f8fafc;
      --text-muted: #94a3b8;
      --text-subtle: #64748b;

      --primary: #2563eb;
      --primary-hover: #1d4ed8;
      --primary-subtle: rgba(37, 99, 235, 0.1);

      --success: #10b981;
      --success-subtle: rgba(16, 185, 129, 0.1);
      --warning: #f59e0b;
      --warning-subtle: rgba(245, 158, 11, 0.1);
      --danger: #ef4444;
      --danger-subtle: rgba(239, 68, 68, 0.1);

      --sidebar-w: 250px;
      --topbar-h: 64px;
      --radius-sm: 6px;
      --radius: 10px;
      --radius-lg: 14px;
      --shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.3);
      --shadow: 0 4px 12px 0 rgba(0, 0, 0, 0.35);
      --shadow-lg: 0 12px 30px -4px rgba(0, 0, 0, 0.5);
    }

    * { box-sizing: border-box; margin: 0; padding: 0; }
    
    body {
      font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background-color: var(--bg);
      color: var(--text);
      line-height: 1.5;
      font-size: 14px;
      min-height: 100vh;
      -webkit-font-smoothing: antialiased;
      -moz-osx-font-smoothing: grayscale;
      overflow-x: hidden;
    }

    /* ─── TOAST NOTIFICATIONS ────────────────────────────── */
    #toast-container {
      position: fixed;
      top: 20px;
      right: 20px;
      z-index: 9999;
      display: flex;
      flex-direction: column;
      gap: 10px;
      pointer-events: none;
    }

    .toast {
      pointer-events: auto;
      background: var(--surface-elevated);
      color: var(--text);
      border: 1px solid var(--border);
      padding: 12px 18px;
      border-radius: var(--radius);
      box-shadow: var(--shadow-lg);
      font-size: 13px;
      font-weight: 500;
      display: flex;
      align-items: center;
      gap: 10px;
      min-width: 280px;
      max-width: 400px;
      animation: slideIn 0.2s cubic-bezier(0.16, 1, 0.3, 1);
    }

    .toast-success { border-left: 4px solid var(--success); }
    .toast-error { border-left: 4px solid var(--danger); }
    .toast-info { border-left: 4px solid var(--primary); }
    .toast-warning { border-left: 4px solid var(--warning); }

    @keyframes slideIn {
      from { transform: translateX(100%); opacity: 0; }
      to { transform: translateX(0); opacity: 1; }
    }

    /* ─── LOGIN VIEW ─────────────────────────────────────── */
    #login-view {
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
      background: radial-gradient(circle at 50% 20%, #111a2e 0%, var(--bg) 80%);
    }

    .login-container {
      width: 100%;
      max-width: 420px;
    }

    .login-brand {
      text-align: center;
      margin-bottom: 28px;
    }

    .login-logo-wrap {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      background: #ffffff;
      padding: 8px 16px;
      border-radius: var(--radius);
      margin-bottom: 16px;
      box-shadow: var(--shadow);
    }

    .login-logo-wrap img {
      max-height: 38px;
      width: auto;
      object-fit: contain;
      display: block;
    }

    .login-brand h1 {
      font-size: 20px;
      font-weight: 700;
      color: var(--text);
      letter-spacing: -0.3px;
    }

    .login-brand p {
      font-size: 13px;
      color: var(--text-muted);
      margin-top: 4px;
    }

    .login-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius-lg);
      padding: 32px;
      box-shadow: var(--shadow-lg);
    }

    .form-group {
      margin-bottom: 18px;
    }

    .form-label {
      display: block;
      font-size: 12.5px;
      font-weight: 600;
      color: var(--text-muted);
      margin-bottom: 6px;
    }

    .form-control {
      width: 100%;
      padding: 10px 14px;
      background: var(--bg);
      border: 1px solid var(--border);
      border-radius: var(--radius-sm);
      color: var(--text);
      font-size: 13.5px;
      font-family: inherit;
      outline: none;
      transition: border-color 0.15s, box-shadow 0.15s;
    }

    .form-control:focus {
      border-color: var(--border-focus);
      box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.2);
    }

    .form-control::placeholder {
      color: var(--text-subtle);
    }

    .form-row-between {
      display: flex;
      align-items: center;
      justify-content: space-between;
      font-size: 12.5px;
      margin-bottom: 20px;
    }

    .form-checkbox-label {
      display: flex;
      align-items: center;
      gap: 8px;
      color: var(--text-muted);
      cursor: pointer;
      user-select: none;
    }

    .link-subtle {
      color: var(--primary);
      text-decoration: none;
      cursor: pointer;
      font-weight: 500;
    }

    .link-subtle:hover {
      text-decoration: underline;
    }

    .btn-primary {
      width: 100%;
      padding: 11px 16px;
      background: var(--primary);
      color: #ffffff;
      border: none;
      border-radius: var(--radius-sm);
      font-size: 13.5px;
      font-weight: 600;
      cursor: pointer;
      transition: background-color 0.15s;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
    }

    .btn-primary:hover {
      background: var(--primary-hover);
    }

    .btn-primary:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }

    .login-quick-access {
      margin-top: 24px;
      padding-top: 20px;
      border-top: 1px solid var(--border-subtle);
      text-align: center;
    }

    .quick-access-label {
      font-size: 11px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      color: var(--text-subtle);
      margin-bottom: 12px;
    }

    .quick-pill-grid {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 6px;
    }

    .pill-role-btn {
      padding: 6px 4px;
      background: var(--surface-elevated);
      border: 1px solid var(--border);
      border-radius: var(--radius-sm);
      font-size: 11px;
      font-weight: 500;
      color: var(--text-muted);
      cursor: pointer;
      transition: all 0.15s;
      text-align: center;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .pill-role-btn:hover {
      border-color: var(--primary);
      color: var(--text);
      background: var(--primary-subtle);
    }

    /* ─── APP LAYOUT ─────────────────────────────────────── */
    #portal-app {
      display: none;
      min-height: 100vh;
      display: flex;
    }

    /* Sidebar Drawer */
    aside.sidebar {
      width: var(--sidebar-w);
      background: var(--surface);
      border-right: 1px solid var(--border);
      position: fixed;
      top: 0;
      bottom: 0;
      left: 0;
      z-index: 100;
      display: flex;
      flex-direction: column;
      transition: transform 0.2s cubic-bezier(0.16, 1, 0.3, 1);
    }

    .sidebar-brand {
      height: var(--topbar-h);
      padding: 0 20px;
      display: flex;
      align-items: center;
      gap: 12px;
      border-bottom: 1px solid var(--border);
    }

    .sidebar-brand-badge {
      width: 32px;
      height: 32px;
      border-radius: 50%;
      background: #ffffff;
      padding: 2px;
      object-fit: contain;
      flex-shrink: 0;
    }

    .sidebar-brand-text {
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }

    .sidebar-brand-name {
      font-size: 14px;
      font-weight: 700;
      color: var(--text);
      letter-spacing: -0.2px;
    }

    .sidebar-brand-role {
      font-size: 10px;
      font-weight: 600;
      color: var(--primary);
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .sidebar-nav {
      flex: 1;
      overflow-y: auto;
      padding: 16px 10px;
      display: flex;
      flex-direction: column;
      gap: 2px;
    }

    .nav-section-title {
      font-size: 10.5px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.6px;
      color: var(--text-subtle);
      padding: 12px 12px 6px;
    }

    .nav-item {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 8px 12px;
      border-radius: var(--radius-sm);
      font-size: 13px;
      font-weight: 500;
      color: var(--text-muted);
      text-decoration: none;
      cursor: pointer;
      transition: color 0.15s, background-color 0.15s;
    }

    .nav-item:hover {
      background: var(--surface-hover);
      color: var(--text);
    }

    .nav-item.active {
      background: var(--primary-subtle);
      color: var(--primary);
      font-weight: 600;
    }

    .nav-icon {
      width: 18px;
      height: 18px;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }

    .sidebar-footer {
      padding: 14px 16px;
      border-top: 1px solid var(--border);
      background: var(--surface);
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 10px;
    }

    .user-profile-badge {
      display: flex;
      align-items: center;
      gap: 10px;
      overflow: hidden;
    }

    .user-avatar {
      width: 32px;
      height: 32px;
      border-radius: 50%;
      background: var(--surface-elevated);
      border: 1px solid var(--border);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 12px;
      font-weight: 600;
      color: var(--text);
      flex-shrink: 0;
    }

    .user-meta {
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }

    .user-meta-name {
      font-size: 12.5px;
      font-weight: 600;
      color: var(--text);
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .user-meta-role {
      font-size: 10px;
      color: var(--text-muted);
      text-transform: uppercase;
      font-weight: 500;
    }

    .btn-icon-subtle {
      background: none;
      border: none;
      color: var(--text-muted);
      cursor: pointer;
      padding: 6px;
      border-radius: var(--radius-sm);
      display: flex;
      align-items: center;
      justify-content: center;
      transition: background-color 0.15s, color 0.15s;
    }

    .btn-icon-subtle:hover {
      background: var(--surface-hover);
      color: var(--danger);
    }

    /* Backdrop for Mobile Drawer */
    .sidebar-backdrop {
      display: none;
      position: fixed;
      inset: 0;
      background: rgba(0, 0, 0, 0.6);
      backdrop-filter: blur(2px);
      z-index: 90;
    }

    /* ─── MAIN CONTENT AREA ──────────────────────────────── */
    main.main-content {
      margin-left: var(--sidebar-w);
      flex: 1;
      display: flex;
      flex-direction: column;
      min-width: 0;
      min-height: 100vh;
    }

    /* Topbar Header */
    header.topbar {
      height: var(--topbar-h);
      background: var(--surface);
      border-bottom: 1px solid var(--border);
      position: sticky;
      top: 0;
      z-index: 50;
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 28px;
    }

    .topbar-left {
      display: flex;
      align-items: center;
      gap: 14px;
    }

    .mobile-menu-btn {
      display: none;
      background: none;
      border: 1px solid var(--border);
      color: var(--text);
      padding: 6px;
      border-radius: var(--radius-sm);
      cursor: pointer;
    }

    .topbar-title {
      font-size: 16px;
      font-weight: 700;
      letter-spacing: -0.2px;
      color: var(--text);
    }

    .topbar-badge {
      font-size: 11px;
      font-weight: 600;
      padding: 2px 8px;
      border-radius: 9999px;
      background: var(--primary-subtle);
      color: var(--primary);
      border: 1px solid rgba(37, 99, 235, 0.2);
    }

    .topbar-right {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .digital-clock {
      font-family: 'JetBrains Mono', monospace;
      font-size: 12.5px;
      font-weight: 500;
      color: var(--text-muted);
      background: var(--bg);
      border: 1px solid var(--border);
      padding: 6px 12px;
      border-radius: var(--radius-sm);
    }

    .btn-punch {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 7px 14px;
      border-radius: var(--radius-sm);
      font-size: 12px;
      font-weight: 600;
      cursor: pointer;
      border: 1px solid transparent;
      transition: all 0.15s;
    }

    .btn-punch-in {
      background: var(--success-subtle);
      color: var(--success);
      border-color: rgba(16, 185, 129, 0.25);
    }

    .btn-punch-in:hover {
      background: rgba(16, 185, 129, 0.2);
    }

    .btn-punch-out {
      background: var(--danger-subtle);
      color: var(--danger);
      border-color: rgba(239, 68, 68, 0.25);
    }

    .btn-punch-out:hover {
      background: rgba(239, 68, 68, 0.2);
    }

    /* ─── VIEWS & SECTIONS ───────────────────────────────── */
    .view-content {
      display: none;
      padding: 28px;
      flex: 1;
    }

    .view-content.active {
      display: block;
    }

    /* Metric Summary Grid */
    .metric-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }

    .metric-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 18px 20px;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
    }

    .metric-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      color: var(--text-muted);
      font-size: 12px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.4px;
    }

    .metric-value {
      font-size: 24px;
      font-weight: 700;
      color: var(--text);
      margin: 10px 0 4px;
      font-family: 'JetBrains Mono', monospace;
      letter-spacing: -0.5px;
    }

    .metric-footer {
      font-size: 11.5px;
      color: var(--text-subtle);
      display: flex;
      align-items: center;
      gap: 6px;
    }

    /* Panels & Tables */
    .panel {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      margin-bottom: 24px;
      overflow: hidden;
    }

    .panel-header {
      padding: 16px 20px;
      border-bottom: 1px solid var(--border);
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      flex-wrap: wrap;
    }

    .panel-title {
      font-size: 14px;
      font-weight: 700;
      color: var(--text);
      letter-spacing: -0.1px;
    }

    .panel-actions {
      display: flex;
      align-items: center;
      gap: 10px;
    }

    .table-search-input {
      background: var(--bg);
      border: 1px solid var(--border);
      border-radius: var(--radius-sm);
      padding: 6px 12px;
      font-size: 12.5px;
      color: var(--text);
      outline: none;
      width: 200px;
      transition: width 0.15s, border-color 0.15s;
    }

    .table-search-input:focus {
      border-color: var(--border-focus);
      width: 240px;
    }

    .table-search-input::placeholder {
      color: var(--text-subtle);
    }

    .btn-secondary {
      background: var(--surface-elevated);
      border: 1px solid var(--border);
      color: var(--text);
      padding: 7px 14px;
      border-radius: var(--radius-sm);
      font-size: 12.5px;
      font-weight: 600;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      transition: background-color 0.15s, border-color 0.15s;
    }

    .btn-secondary:hover {
      background: var(--surface-hover);
      border-color: var(--text-subtle);
    }

    /* Table Component */
    .table-responsive {
      width: 100%;
      overflow-x: auto;
    }

    table.data-table {
      width: 100%;
      border-collapse: collapse;
      text-align: left;
      font-size: 13px;
    }

    table.data-table th {
      padding: 12px 20px;
      background: rgba(0, 0, 0, 0.15);
      font-size: 11px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      color: var(--text-subtle);
      border-bottom: 1px solid var(--border);
      white-space: nowrap;
    }

    table.data-table td {
      padding: 14px 20px;
      border-bottom: 1px solid var(--border-subtle);
      color: var(--text-muted);
      vertical-align: middle;
    }

    table.data-table tr:last-child td {
      border-bottom: none;
    }

    table.data-table tbody tr:hover td {
      background: rgba(255, 255, 255, 0.02);
      color: var(--text);
    }

    .table-primary-text {
      color: var(--text);
      font-weight: 600;
    }

    .table-sub-text {
      font-size: 11.5px;
      color: var(--text-subtle);
    }

    /* Clean Status Badges */
    .badge-status {
      display: inline-flex;
      align-items: center;
      gap: 5px;
      padding: 3px 8px;
      border-radius: 9999px;
      font-size: 11px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.3px;
    }

    .status-active, .status-working, .status-healthy {
      background: var(--success-subtle);
      color: var(--success);
      border: 1px solid rgba(16, 185, 129, 0.2);
    }

    .status-completed {
      background: var(--primary-subtle);
      color: var(--primary);
      border: 1px solid rgba(37, 99, 235, 0.2);
    }

    .status-todo, .status-notin {
      background: rgba(148, 163, 184, 0.1);
      color: #94a3b8;
      border: 1px solid rgba(148, 163, 184, 0.2);
    }

    .status-inprogress, .status-urgent {
      background: var(--warning-subtle);
      color: var(--warning);
      border: 1px solid rgba(245, 158, 11, 0.2);
    }

    .table-footer {
      padding: 12px 20px;
      border-top: 1px solid var(--border);
      display: flex;
      align-items: center;
      justify-content: space-between;
      font-size: 12px;
      color: var(--text-subtle);
    }

    .empty-state {
      padding: 48px 20px;
      text-align: center;
      color: var(--text-subtle);
    }

    .empty-state p {
      font-size: 13px;
      margin-top: 6px;
    }

    /* ─── MODAL DIALOGS ──────────────────────────────────── */
    .modal-overlay {
      display: none;
      position: fixed;
      inset: 0;
      background: rgba(0, 0, 0, 0.7);
      backdrop-filter: blur(4px);
      z-index: 1000;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }

    .modal-overlay.active {
      display: flex;
    }

    .modal-dialog {
      width: 100%;
      max-width: 480px;
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius-lg);
      padding: 24px;
      box-shadow: var(--shadow-lg);
      animation: modalFade 0.15s ease-out;
    }

    @keyframes modalFade {
      from { transform: scale(0.96); opacity: 0; }
      to { transform: scale(1); opacity: 1; }
    }

    .modal-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 20px;
      padding-bottom: 12px;
      border-bottom: 1px solid var(--border-subtle);
    }

    .modal-title {
      font-size: 15px;
      font-weight: 700;
      color: var(--text);
    }

    .modal-close {
      background: none;
      border: none;
      color: var(--text-muted);
      cursor: pointer;
      font-size: 18px;
      line-height: 1;
      padding: 4px;
    }

    .modal-close:hover {
      color: var(--text);
    }

    .modal-actions {
      display: flex;
      align-items: center;
      justify-content: flex-end;
      gap: 10px;
      margin-top: 20px;
      padding-top: 16px;
      border-top: 1px solid var(--border-subtle);
    }

    /* ─── RESPONSIVE BEHAVIOR ────────────────────────────── */
    @media (max-width: 900px) {
      :root {
        --sidebar-w: 240px;
      }
      
      aside.sidebar {
        transform: translateX(-100%);
      }

      aside.sidebar.drawer-open {
        transform: translateX(0);
      }

      .sidebar-backdrop.active {
        display: block;
      }

      main.main-content {
        margin-left: 0;
      }

      .mobile-menu-btn {
        display: inline-flex;
      }

      header.topbar {
        padding: 0 16px;
      }

      .view-content {
        padding: 16px;
      }
    }
  </style>
</head>
<body>
  <!-- Toast Container -->
  <div id="toast-container"></div>

  <!-- 1. UNIFIED LOGIN VIEW -->
  <div id="login-view">
    <div class="login-container">
      <div class="login-brand">
        <div class="login-logo-wrap">
          <img src="/enterprenex-logo.png" alt="Enterprenex Solutions" />
        </div>
        <h1>Company Portal</h1>
        <p>Enterprise Management • portal.enterprenex.solutions</p>
      </div>

      <div class="login-card">
        <form id="login-form" onsubmit="handleUnifiedLogin(event)">
          <div class="form-group">
            <label class="form-label" for="login-email">Company Email</label>
            <input type="email" id="login-email" class="form-control" placeholder="name@enterprenex.solutions" required autofocus />
          </div>

          <div class="form-group">
            <label class="form-label" for="login-password">Password</label>
            <input type="password" id="login-password" class="form-control" placeholder="••••••••••••" required />
          </div>

          <div class="form-row-between">
            <label class="form-checkbox-label">
              <input type="checkbox" id="login-remember" />
              <span>Remember session</span>
            </label>
            <a class="link-subtle" onclick="showForgotPasswordDialog()">Forgot password?</a>
          </div>

          <button type="submit" id="btn-login-submit" class="btn-primary">
            Sign In to Portal
          </button>
        </form>

        <div class="login-quick-access">
          <div class="quick-access-label">Quick Demo Access</div>
          <div class="quick-pill-grid">
            <button class="pill-role-btn" onclick="quickFill('rohit@enterprenex.solutions', 'Admin@123')">CEO</button>
            <button class="pill-role-btn" onclick="quickFill('revanth.reddy@enterprenex.solutions', 'Admin@123')">CTO</button>
            <button class="pill-role-btn" onclick="quickFill('aniket@enterprenex.solutions', 'Admin@123')">CFO</button>
            <button class="pill-role-btn" onclick="quickFill('jyothi@enterprenex.solutions', 'Admin@123')">HR</button>
            <button class="pill-role-btn" onclick="quickFill('amit.marketing@enterprenex.solutions', 'Admin@123')">Marketing</button>
            <button class="pill-role-btn" onclick="quickFill('piyush@enterprenex.solutions', 'Admin@123')">Lead</button>
            <button class="pill-role-btn" onclick="quickFill('kishore@enterprenex.solutions', 'Admin@123')">Dev</button>
            <button class="pill-role-btn" onclick="quickFill('sneha.intern@enterprenex.solutions', 'Admin@123')">Intern</button>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- 2. MAIN APPLICATION WORKSPACE -->
  <div id="portal-app">
    <!-- Backdrop for mobile drawer -->
    <div id="sidebar-backdrop" class="sidebar-backdrop" onclick="toggleMobileSidebar()"></div>

    <!-- Sidebar Navigation -->
    <aside id="app-sidebar" class="sidebar">
      <div class="sidebar-brand">
        <img src="/enterprenex-badge.png" alt="Enterprenex" class="sidebar-brand-badge" />
        <div class="sidebar-brand-text">
          <span class="sidebar-brand-name">Enterprenex</span>
          <span class="sidebar-brand-role" id="sidebar-role-indicator">PORTAL</span>
        </div>
      </div>

      <nav class="sidebar-nav" id="sidebar-dynamic-menu">
        <!-- Rendered dynamically based on permissions -->
      </nav>

      <div class="sidebar-footer">
        <div class="user-profile-badge">
          <div class="user-avatar" id="sidebar-user-avatar">U</div>
          <div class="user-meta">
            <span class="user-meta-name" id="sidebar-user-name">Loading...</span>
            <span class="user-meta-role" id="sidebar-user-badge">ROLE</span>
          </div>
        </div>
        <button class="btn-icon-subtle" onclick="confirmLogout()" title="Sign Out">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
        </button>
      </div>
    </aside>

    <!-- Main Workspace -->
    <main class="main-content">
      <!-- Topbar Header -->
      <header class="topbar">
        <div class="topbar-left">
          <button class="mobile-menu-btn" onclick="toggleMobileSidebar()">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="3" y1="12" x2="21" y2="12"></line><line x1="3" y1="6" x2="21" y2="6"></line><line x1="3" y1="18" x2="21" y2="18"></line></svg>
          </button>
          <h2 class="topbar-title" id="page-title">Dashboard</h2>
          <span class="topbar-badge" id="header-role-badge">ROLE</span>
        </div>

        <div class="topbar-right">
          <div class="digital-clock" id="digital-clock">00:00:00</div>
          <button id="topbar-punch-btn" class="btn-punch btn-punch-in" onclick="toggleClockPunch()">
            <span>Punch In</span>
          </button>
        </div>
      </header>

      <!-- ─── VIEW: EMPLOYEE DASHBOARD ──────────────────── -->
      <section id="view-employee" class="view-content">
        <div class="metric-grid">
          <div class="metric-card">
            <div class="metric-header">
              <span>Shift Status</span>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
            </div>
            <div class="metric-value" id="emp-punch-status">CLOCKED OUT</div>
            <div class="metric-footer" id="emp-punch-time">Click top right button to punch in</div>
          </div>

          <div class="metric-card">
            <div class="metric-header">
              <span>Assigned Tasks</span>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"></path><rect x="8" y="2" width="8" height="4" rx="1" ry="1"></rect></svg>
            </div>
            <div class="metric-value" id="emp-task-count">0</div>
            <div class="metric-footer">Active sprint responsibilities</div>
          </div>

          <div class="metric-card">
            <div class="metric-header">
              <span>Active Projects</span>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="12 2 2 7 12 12 22 7 12 2"></polygon><polyline points="2 17 12 22 22 17"></polyline><polyline points="2 12 12 17 22 12"></polyline></svg>
            </div>
            <div class="metric-value">3</div>
            <div class="metric-footer">Core platform deliverables</div>
          </div>

          <div class="metric-card">
            <div class="metric-header">
              <span>Leave Balance</span>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
            </div>
            <div class="metric-value">14 Days</div>
            <div class="metric-footer">Annual paid balance remaining</div>
          </div>
        </div>

        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">My Priority Tasks</h3>
            <div class="panel-actions">
              <input type="text" class="table-search-input" placeholder="Search tasks..." onkeyup="filterTable('emp-tasks-tbody', this.value)" />
            </div>
          </div>
          <div class="table-responsive">
            <table class="data-table">
              <thead>
                <tr>
                  <th>Task Title</th>
                  <th>Priority</th>
                  <th>Deadline</th>
                  <th>Status</th>
                  <th style="text-align: right;">Action</th>
                </tr>
              </thead>
              <tbody id="emp-tasks-tbody">
                <!-- Rendered dynamically -->
              </tbody>
            </table>
          </div>
          <div class="table-footer">
            <span id="emp-tasks-count">Showing active tasks</span>
          </div>
        </div>
      </section>

      <!-- ─── VIEW: HR & STAFF DIRECTORY ───────────────── -->
      <section id="view-hr" class="view-content">
        <div class="metric-grid">
          <div class="metric-card">
            <div class="metric-header"><span>Total Employees</span></div>
            <div class="metric-value" id="hr-total-emp">8</div>
            <div class="metric-footer">Active personnel across departments</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Present Today</span></div>
            <div class="metric-value" id="hr-present-today">0</div>
            <div class="metric-footer">Clocked in right now</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Pending Leaves</span></div>
            <div class="metric-value">0</div>
            <div class="metric-footer">All requests up to date</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Policy Compliance</span></div>
            <div class="metric-value" style="color: var(--success);">100%</div>
            <div class="metric-footer">Verified documentation</div>
          </div>
        </div>

        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">Staff Directory</h3>
            <div class="panel-actions">
              <input type="text" class="table-search-input" placeholder="Search employee..." onkeyup="filterTable('hr-employees-tbody', this.value)" />
              <button class="btn-secondary" onclick="showAddEmployeeModal()">+ Onboard Employee</button>
            </div>
          </div>
          <div class="table-responsive">
            <table class="data-table">
              <thead>
                <tr>
                  <th>Employee</th>
                  <th>Role</th>
                  <th>Department</th>
                  <th>Designation</th>
                  <th>Contact</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody id="hr-employees-tbody">
                <!-- Rendered dynamically -->
              </tbody>
            </table>
          </div>
          <div class="table-footer">
            <span id="hr-emp-count">Active staff members</span>
          </div>
        </div>
      </section>

      <!-- ─── VIEW: CEO EXECUTIVE COCKPIT ──────────────── -->
      <section id="view-ceo" class="view-content">
        <div class="metric-grid">
          <div class="metric-card">
            <div class="metric-header"><span>Headcount</span></div>
            <div class="metric-value" id="ceo-total-emp">8</div>
            <div class="metric-footer">Core company workforce</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Active Working</span></div>
            <div class="metric-value" id="ceo-active-punch">0</div>
            <div class="metric-footer">Live shift attendance</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Key Projects</span></div>
            <div class="metric-value" id="ceo-active-proj">3</div>
            <div class="metric-footer">Fintech & Internal systems</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Sprint Velocity</span></div>
            <div class="metric-value" style="color: var(--success);">94%</div>
            <div class="metric-footer">On-time quarterly delivery</div>
          </div>
        </div>

        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">Live Company Attendance Roster</h3>
            <div class="panel-actions">
              <input type="text" class="table-search-input" placeholder="Search roster..." onkeyup="filterTable('ceo-roster-tbody', this.value)" />
            </div>
          </div>
          <div class="table-responsive">
            <table class="data-table">
              <thead>
                <tr>
                  <th>Employee</th>
                  <th>Department / Role</th>
                  <th>Clock In</th>
                  <th>Clock Out</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody id="ceo-roster-tbody">
                <!-- Rendered dynamically -->
              </tbody>
            </table>
          </div>
          <div class="table-footer">
            <span>Real-time punch records</span>
          </div>
        </div>
      </section>

      <!-- ─── VIEW: CTO TECHNICAL COMMAND ──────────────── -->
      <section id="view-cto" class="view-content">
        <div class="metric-grid">
          <div class="metric-card">
            <div class="metric-header"><span>Engineering Team</span></div>
            <div class="metric-value" id="cto-tech-team">5</div>
            <div class="metric-footer">Engineers & QA Staff</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Production Uptime</span></div>
            <div class="metric-value" style="color: var(--success);">99.98%</div>
            <div class="metric-footer">Render & MySQL operational</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>CI/CD Pipeline</span></div>
            <div class="metric-value" style="font-size: 16px;">PASSING</div>
            <div class="metric-footer">378 Automated unit tests passed</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Active Tasks</span></div>
            <div class="metric-value" id="cto-open-tasks">2</div>
            <div class="metric-footer">Current engineering sprint</div>
          </div>
        </div>

        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">Engineering Sprints & Backlog</h3>
            <div class="panel-actions">
              <input type="text" class="table-search-input" placeholder="Search dev tasks..." onkeyup="filterTable('cto-tasks-tbody', this.value)" />
            </div>
          </div>
          <div class="table-responsive">
            <table class="data-table">
              <thead>
                <tr>
                  <th>Task Title</th>
                  <th>Assignee</th>
                  <th>Priority</th>
                  <th>Deadline</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody id="cto-tasks-tbody">
                <!-- Rendered dynamically -->
              </tbody>
            </table>
          </div>
          <div class="table-footer">
            <span>Engineering task allocation</span>
          </div>
        </div>
      </section>

      <!-- ─── VIEW: CFO FINANCIAL COMMAND ──────────────── -->
      <section id="view-cfo" class="view-content">
        <div class="metric-grid">
          <div class="metric-card">
            <div class="metric-header"><span>Monthly Payroll</span></div>
            <div class="metric-value" id="cfo-payroll">₹11,40,000</div>
            <div class="metric-footer">Total company staff outlay</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Allocated Budgets</span></div>
            <div class="metric-value">₹23,00,000</div>
            <div class="metric-footer">Fintech development & ops</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Health Score</span></div>
            <div class="metric-value" style="color: var(--success);">94 / 100</div>
            <div class="metric-footer">Prudent capital allocation</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Compliance</span></div>
            <div class="metric-value" style="font-size: 18px; color: var(--success);">CLEAR</div>
            <div class="metric-footer">GST, TDS & statutory remit</div>
          </div>
        </div>

        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">Department Budget Allocation vs Spend</h3>
          </div>
          <div class="table-responsive">
            <table class="data-table">
              <thead>
                <tr>
                  <th>Department</th>
                  <th>Allocated Budget</th>
                  <th>Actual Spend</th>
                  <th>Utilization</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td class="table-primary-text">Software & Engineering</td>
                  <td>₹12,00,000</td>
                  <td>₹9,50,000</td>
                  <td><span class="badge-status status-working">79% (Optimal)</span></td>
                </tr>
                <tr>
                  <td class="table-primary-text">Growth & Marketing</td>
                  <td>₹4,50,000</td>
                  <td>₹3,20,000</td>
                  <td><span class="badge-status status-working">71% (Healthy)</span></td>
                </tr>
                <tr>
                  <td class="table-primary-text">Operations</td>
                  <td>₹3,00,000</td>
                  <td>₹2,10,000</td>
                  <td><span class="badge-status status-working">70% (Healthy)</span></td>
                </tr>
                <tr>
                  <td class="table-primary-text">People & Culture</td>
                  <td>₹1,80,000</td>
                  <td>₹1,40,000</td>
                  <td><span class="badge-status status-working">77% (Optimal)</span></td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="table-footer">
            <span>Fiscal Year 2026 budget utilization</span>
          </div>
        </div>
      </section>

      <!-- ─── VIEW: DOCUMENT VAULT ─────────────────────── -->
      <section id="view-documents" class="view-content">
        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">Document Vault</h3>
            <div class="panel-actions">
              <input type="text" class="table-search-input" placeholder="Search documents..." onkeyup="filterTable('docs-tbody', this.value)" />
              <button class="btn-secondary" onclick="showUploadDocModal()">+ Upload Document</button>
            </div>
          </div>
          <div class="table-responsive">
            <table class="data-table">
              <thead>
                <tr>
                  <th>Document Title</th>
                  <th>Category</th>
                  <th>Confidentiality</th>
                  <th>Uploaded By</th>
                  <th>Date</th>
                </tr>
              </thead>
              <tbody id="docs-tbody">
                <!-- Rendered dynamically -->
              </tbody>
            </table>
          </div>
          <div class="table-footer">
            <span id="docs-count">Enterprise document records</span>
          </div>
        </div>
      </section>

      <!-- ─── VIEW: SECURITY AUDIT TRAIL ───────────────── -->
      <section id="view-audit" class="view-content">
        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">Security & Access Audit Trail</h3>
            <div class="panel-actions">
              <input type="text" class="table-search-input" placeholder="Search audit logs..." onkeyup="filterTable('audit-tbody', this.value)" />
            </div>
          </div>
          <div class="table-responsive">
            <table class="data-table">
              <thead>
                <tr>
                  <th>Timestamp</th>
                  <th>User</th>
                  <th>Role</th>
                  <th>Action</th>
                  <th>Resource</th>
                  <th>IP Address</th>
                </tr>
              </thead>
              <tbody id="audit-tbody">
                <!-- Rendered dynamically -->
              </tbody>
            </table>
          </div>
          <div class="table-footer">
            <span>Immutable security trail</span>
          </div>
        </div>
      </section>

      <!-- ─── VIEW: USER PROFILE ───────────────────────── -->
      <section id="view-profile" class="view-content">
        <div class="panel" style="max-width: 680px;">
          <div class="panel-header">
            <h3 class="panel-title">User Account Details</h3>
          </div>
          <div style="padding: 24px;">
            <div style="display: flex; align-items: center; gap: 18px; margin-bottom: 24px; padding-bottom: 20px; border-bottom: 1px solid var(--border-subtle);">
              <div class="user-avatar" id="profile-avatar" style="width: 52px; height: 52px; font-size: 18px;">U</div>
              <div>
                <h3 id="profile-name" style="font-size: 16px; font-weight: 700;">User Name</h3>
                <p id="profile-email" style="color: var(--text-muted); font-size: 13px;">user@enterprenex.solutions</p>
              </div>
            </div>
            
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 18px;">
              <div>
                <div class="form-label">Role</div>
                <div id="profile-role" class="table-primary-text">ROLE</div>
              </div>
              <div>
                <div class="form-label">Department</div>
                <div id="profile-dept" class="table-primary-text">DEPARTMENT</div>
              </div>
              <div>
                <div class="form-label">Designation</div>
                <div id="profile-designation" class="table-primary-text">DESIGNATION</div>
              </div>
              <div>
                <div class="form-label">Status</div>
                <div><span class="badge-status status-working">Active Account</span></div>
              </div>
            </div>

            <div style="margin-top: 24px; padding-top: 20px; border-top: 1px solid var(--border-subtle);">
              <button class="btn-secondary" onclick="confirmLogout()">Sign Out from Portal</button>
            </div>
          </div>
        </div>
      </section>
    </main>
  </div>

  <!-- ─── MODAL: ONBOARD EMPLOYEE ──────────────────────── -->
  <div id="modal-add-employee" class="modal-overlay">
    <div class="modal-dialog">
      <div class="modal-header">
        <h3 class="modal-title">Onboard New Employee</h3>
        <button class="modal-close" onclick="closeModal('modal-add-employee')">&times;</button>
      </div>
      <form onsubmit="submitNewEmployee(event)">
        <div class="form-group">
          <label class="form-label" for="add-emp-name">Full Name</label>
          <input type="text" id="add-emp-name" class="form-control" required />
        </div>
        <div class="form-group">
          <label class="form-label" for="add-emp-email">Company Email</label>
          <input type="email" id="add-emp-email" class="form-control" placeholder="@enterprenex.solutions" required />
        </div>
        <div class="form-group">
          <label class="form-label" for="add-emp-dept">Department</label>
          <select id="add-emp-dept" class="form-control">
            <option value="ENGINEERING">Software & Engineering</option>
            <option value="MARKETING">Growth & Marketing</option>
            <option value="FINANCE">Finance & Accounts</option>
            <option value="HUMAN_RESOURCES">People & Culture</option>
            <option value="OPERATIONS">Operations</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label" for="add-emp-role">Role</label>
          <select id="add-emp-role" class="form-control">
            <option value="EMPLOYEE">Employee</option>
            <option value="INTERN">Intern</option>
            <option value="PROJECT_MANAGER">Project Manager</option>
            <option value="DEPT_HEAD">Department Head</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label" for="add-emp-designation">Designation</label>
          <input type="text" id="add-emp-designation" class="form-control" placeholder="e.g. Frontend Engineer" required />
        </div>
        <div class="modal-actions">
          <button type="button" class="btn-secondary" onclick="closeModal('modal-add-employee')">Cancel</button>
          <button type="submit" class="btn-primary" style="width: auto;">Onboard Staff</button>
        </div>
      </form>
    </div>
  </div>

  <!-- ─── MODAL: UPLOAD DOCUMENT ───────────────────────── -->
  <div id="modal-upload-doc" class="modal-overlay">
    <div class="modal-dialog">
      <div class="modal-header">
        <h3 class="modal-title">Upload Company Document</h3>
        <button class="modal-close" onclick="closeModal('modal-upload-doc')">&times;</button>
      </div>
      <form onsubmit="submitNewDocument(event)">
        <div class="form-group">
          <label class="form-label" for="doc-title">Document Title</label>
          <input type="text" id="doc-title" class="form-control" placeholder="e.g. Q4 Policy Guide" required />
        </div>
        <div class="form-group">
          <label class="form-label" for="doc-category">Category</label>
          <select id="doc-category" class="form-control">
            <option value="POLICY">Policy & Handbook</option>
            <option value="FINANCIAL">Financial Statement</option>
            <option value="TECHNICAL">Technical Architecture</option>
            <option value="LEGAL">Legal & Contracts</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-checkbox-label">
            <input type="checkbox" id="doc-confidential" />
            <span>Mark as Confidential (Restricted Access)</span>
          </label>
        </div>
        <div class="modal-actions">
          <button type="button" class="btn-secondary" onclick="closeModal('modal-upload-doc')">Cancel</button>
          <button type="submit" class="btn-primary" style="width: auto;">Save Document</button>
        </div>
      </form>
    </div>
  </div>

  <!-- ─── SCRIPT / LOGIC ───────────────────────────────── -->
  <script>
    // State
    let currentUser = null;
    let authToken = localStorage.getItem('enx_portal_token') || null;

    // Toast notifications
    function showToast(message, type = 'info') {
      const container = document.getElementById('toast-container');
      const toast = document.createElement('div');
      toast.className = 'toast toast-' + type;
      toast.innerText = message;
      container.appendChild(toast);
      setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transform = 'translateY(-10px)';
        toast.style.transition = 'all 0.2s';
        setTimeout(() => toast.remove(), 200);
      }, 3500);
    }

    // Digital Clock
    setInterval(() => {
      const el = document.getElementById('digital-clock');
      if (el) {
        const now = new Date();
        el.innerText = now.toTimeString().split(' ')[0];
      }
    }, 1000);

    // Mobile Sidebar Drawer
    function toggleMobileSidebar() {
      const sidebar = document.getElementById('app-sidebar');
      const backdrop = document.getElementById('sidebar-backdrop');
      sidebar.classList.toggle('drawer-open');
      backdrop.classList.toggle('active');
    }

    // Initial session verification
    window.addEventListener('DOMContentLoaded', () => {
      if (authToken) {
        verifySession();
      } else {
        showLoginView();
      }
    });

    function quickFill(email, pass) {
      document.getElementById('login-email').value = email;
      document.getElementById('login-password').value = pass;
    }

    async function handleUnifiedLogin(e) {
      e.preventDefault();
      const email = document.getElementById('login-email').value.trim();
      const password = document.getElementById('login-password').value;
      const rememberMe = document.getElementById('login-remember').checked;
      const submitBtn = document.getElementById('btn-login-submit');

      submitBtn.disabled = true;
      submitBtn.innerText = 'Verifying credentials...';

      try {
        const res = await fetch('/api/v1/portal/auth/login', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email, password, rememberMe })
        });

        const data = await res.json();
        if (!res.ok || !data.success) {
          throw new Error(data.error || data.message || 'Invalid credentials');
        }

        authToken = data.data.token;
        currentUser = data.data.user;
        localStorage.setItem('enx_portal_token', authToken);

        showToast('Welcome back, ' + currentUser.name, 'success');
        showPortalApp(currentUser);
      } catch (err) {
        showToast(err.message, 'error');
      } finally {
        submitBtn.disabled = false;
        submitBtn.innerText = 'Sign In to Portal';
      }
    }

    async function verifySession() {
      try {
        const res = await fetch('/api/v1/portal/auth/me', {
          headers: { 'Authorization': 'Bearer ' + authToken }
        });
        if (!res.ok) throw new Error('Session expired');
        const data = await res.json();
        currentUser = data.data.user;
        showPortalApp(currentUser);
      } catch (_) {
        handleLogout();
      }
    }

    function showLoginView() {
      document.getElementById('login-view').style.display = 'flex';
      document.getElementById('portal-app').style.display = 'none';
    }

    function showPortalApp(user) {
      document.getElementById('login-view').style.display = 'none';
      document.getElementById('portal-app').style.display = 'flex';

      // Update User indicators
      document.getElementById('sidebar-user-name').innerText = user.name;
      document.getElementById('sidebar-user-badge').innerText = user.role;
      document.getElementById('sidebar-role-indicator').innerText = user.role;
      document.getElementById('header-role-badge').innerText = user.role;
      
      const initials = user.name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase();
      document.getElementById('sidebar-user-avatar').innerText = initials;
      document.getElementById('profile-avatar').innerText = initials;
      document.getElementById('profile-name').innerText = user.name;
      document.getElementById('profile-email').innerText = user.email;
      document.getElementById('profile-role').innerText = user.role;
      document.getElementById('profile-dept').innerText = user.department || 'All Departments';
      document.getElementById('profile-designation').innerText = user.designation || user.role;

      // Build Clean Role-Based Navigation
      buildRoleNavigation(user);

      // Route to initial role view
      routeToRoleDashboard(user.role);

      // Load remote data
      loadDashboardData(user);
    }

    // Icons
    const ICONS = {
      dashboard: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7"></rect><rect x="14" y="3" width="7" height="7"></rect><rect x="14" y="14" width="7" height="7"></rect><rect x="3" y="14" width="7" height="7"></rect></svg>',
      tasks: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"></path><rect x="8" y="2" width="8" height="4" rx="1" ry="1"></rect></svg>',
      projects: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="12 2 2 7 12 12 22 7 12 2"></polygon><polyline points="2 17 12 22 22 17"></polyline><polyline points="2 12 12 17 22 12"></polyline></svg>',
      attendance: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>',
      employees: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>',
      departments: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2" ry="2"></rect><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"></path></svg>',
      documents: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line></svg>',
      finance: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"></line><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path></svg>',
      tech: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="16 18 22 12 16 6"></polyline><polyline points="8 6 2 12 8 18"></polyline></svg>',
      security: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>',
      profile: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>'
    };

    function buildRoleNavigation(user) {
      const menu = document.getElementById('sidebar-dynamic-menu');
      menu.innerHTML = '';
      const role = user.role;
      const perms = user.permissions || [];

      // 1. Navigation items based strictly on role
      if (role === 'EMPLOYEE' || role === 'INTERN' || role === 'DEVELOPER') {
        // Employee Role Spec: Dashboard, My Tasks, My Projects, Attendance, Documents, Profile
        addNavSection(menu, 'Workstation');
        addNavItem(menu, ICONS.dashboard, 'Dashboard', () => switchView('employee', 'Employee Dashboard'), true);
        addNavItem(menu, ICONS.tasks, 'My Tasks', () => switchView('employee', 'My Tasks'));
        addNavItem(menu, ICONS.attendance, 'Attendance', () => switchView('employee', 'My Attendance'));
        addNavItem(menu, ICONS.documents, 'Documents', () => switchView('documents', 'Document Vault'));
        addNavItem(menu, ICONS.profile, 'Profile', () => switchView('profile', 'My Account Profile'));
      } else if (role === 'HR') {
        // HR Role Spec: Dashboard, Employees, Tasks, Attendance, Documents, Profile
        addNavSection(menu, 'People Operations');
        addNavItem(menu, ICONS.dashboard, 'Dashboard', () => switchView('hr', 'HR Dashboard'), true);
        addNavItem(menu, ICONS.employees, 'Employees', () => switchView('hr', 'Staff Directory'));
        addNavItem(menu, ICONS.tasks, 'Tasks', () => switchView('employee', 'Company Tasks'));
        addNavItem(menu, ICONS.attendance, 'Attendance', () => switchView('ceo', 'Live Roster'));
        addNavItem(menu, ICONS.documents, 'Documents', () => switchView('documents', 'Document Vault'));
        addNavItem(menu, ICONS.profile, 'Profile', () => switchView('profile', 'HR Profile'));
      } else if (role === 'CEO' || role === 'SUPER_ADMIN') {
        // Executive Role Spec
        addNavSection(menu, 'Executive Command');
        addNavItem(menu, ICONS.dashboard, 'Cockpit', () => switchView('ceo', 'CEO Executive Cockpit'), true);
        addNavItem(menu, ICONS.employees, 'Staff Directory', () => switchView('hr', 'Company Staff Directory'));
        addNavItem(menu, ICONS.finance, 'Financials', () => switchView('cfo', 'CFO Financial Command'));
        addNavItem(menu, ICONS.tech, 'Engineering Hub', () => switchView('cto', 'CTO Technical Command'));
        addNavItem(menu, ICONS.documents, 'Documents', () => switchView('documents', 'Document Vault'));
        addNavItem(menu, ICONS.security, 'Security Trail', () => switchView('audit', 'Security Audit Trail'));
      } else if (role === 'CTO') {
        // Technical Leadership
        addNavSection(menu, 'Engineering Command');
        addNavItem(menu, ICONS.dashboard, 'Engineering Hub', () => switchView('cto', 'CTO Technical Command'), true);
        addNavItem(menu, ICONS.tasks, 'Sprints & Tasks', () => switchView('cto', 'Engineering Sprints'));
        addNavItem(menu, ICONS.attendance, 'Team Availability', () => switchView('ceo', 'Team Roster'));
        addNavItem(menu, ICONS.documents, 'Tech Vault', () => switchView('documents', 'Document Vault'));
        addNavItem(menu, ICONS.profile, 'Profile', () => switchView('profile', 'My Account Profile'));
      } else if (role === 'CFO') {
        // Financial Leadership
        addNavSection(menu, 'Financial Command');
        addNavItem(menu, ICONS.dashboard, 'Financial Hub', () => switchView('cfo', 'CFO Financial Command'), true);
        addNavItem(menu, ICONS.employees, 'Payroll Outlay', () => switchView('cfo', 'Payroll & Budgets'));
        addNavItem(menu, ICONS.documents, 'Fiscal Vault', () => switchView('documents', 'Document Vault'));
        addNavItem(menu, ICONS.profile, 'Profile', () => switchView('profile', 'My Account Profile'));
      } else {
        // General Department Head or Lead
        addNavSection(menu, 'Management');
        addNavItem(menu, ICONS.dashboard, 'Dashboard', () => switchView('employee', 'Dashboard'), true);
        addNavItem(menu, ICONS.tasks, 'Tasks', () => switchView('employee', 'Tasks'));
        addNavItem(menu, ICONS.employees, 'Team Directory', () => switchView('hr', 'Team Directory'));
        addNavItem(menu, ICONS.documents, 'Documents', () => switchView('documents', 'Document Vault'));
        addNavItem(menu, ICONS.profile, 'Profile', () => switchView('profile', 'Profile'));
      }
    }

    function addNavSection(parent, label) {
      const div = document.createElement('div');
      div.className = 'nav-section-title';
      div.innerText = label;
      parent.appendChild(div);
    }

    function addNavItem(parent, iconSvg, label, onClick, isActive = false) {
      const a = document.createElement('a');
      a.className = 'nav-item' + (isActive ? ' active' : '');
      a.innerHTML = '<span class="nav-icon">' + iconSvg + '</span><span>' + label + '</span>';
      a.onclick = () => {
        document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));
        a.classList.add('active');
        const sidebar = document.getElementById('app-sidebar');
        const backdrop = document.getElementById('sidebar-backdrop');
        sidebar.classList.remove('drawer-open');
        backdrop.classList.remove('active');
        onClick();
      };
      parent.appendChild(a);
    }

    function routeToRoleDashboard(role) {
      if (role === 'CEO' || role === 'SUPER_ADMIN') {
        switchView('ceo', 'CEO Executive Cockpit');
      } else if (role === 'CTO') {
        switchView('cto', 'CTO Technical Command');
      } else if (role === 'CFO') {
        switchView('cfo', 'CFO Financial Command');
      } else if (role === 'HR') {
        switchView('hr', 'HR & People Operations');
      } else {
        switchView('employee', 'Employee Dashboard');
      }
    }

    function switchView(viewId, title) {
      document.querySelectorAll('.view-content').forEach(el => el.classList.remove('active'));
      const target = document.getElementById('view-' + viewId);
      if (target) target.classList.add('active');
      document.getElementById('page-title').innerText = title;
    }

    // Real-time table search filter
    function filterTable(tbodyId, query) {
      const tbody = document.getElementById(tbodyId);
      if (!tbody) return;
      const term = (query || '').toLowerCase().trim();
      const rows = tbody.getElementsByTagName('tr');
      for (let i = 0; i < rows.length; i++) {
        const text = rows[i].textContent.toLowerCase();
        rows[i].style.display = text.includes(term) ? '' : 'none';
      }
    }

    // Remote Data Loader
    async function loadDashboardData(user) {
      // 1. Live Attendance Roster
      try {
        const res = await fetch('/api/v1/portal/attendance/live', {
          headers: { 'Authorization': 'Bearer ' + authToken }
        });
        if (res.ok) {
          const json = await res.json();
          renderRoster(json.data || []);
        }
      } catch (_) {}

      // 2. Staff Directory
      try {
        const res = await fetch('/api/v1/portal/employees', {
          headers: { 'Authorization': 'Bearer ' + authToken }
        });
        if (res.ok) {
          const json = await res.json();
          renderEmployees(json.data || []);
        }
      } catch (_) {}

      // 3. Tasks
      try {
        const res = await fetch('/api/v1/portal/tasks', {
          headers: { 'Authorization': 'Bearer ' + authToken }
        });
        if (res.ok) {
          const json = await res.json();
          renderTasks(json.data || []);
        }
      } catch (_) {}

      // 4. Documents
      try {
        const res = await fetch('/api/v1/portal/documents', {
          headers: { 'Authorization': 'Bearer ' + authToken }
        });
        if (res.ok) {
          const json = await res.json();
          renderDocuments(json.data || []);
        }
      } catch (_) {}

      // 5. Security Audit Logs (if authorized)
      try {
        const res = await fetch('/api/v1/portal/audit-logs', {
          headers: { 'Authorization': 'Bearer ' + authToken }
        });
        if (res.ok) {
          const json = await res.json();
          renderAuditLogs(json.data || []);
        }
      } catch (_) {}
    }

    function renderRoster(roster) {
      const tbody = document.getElementById('ceo-roster-tbody');
      if (!tbody) return;
      
      if (!roster.length) {
        tbody.innerHTML = '<tr><td colspan="5" class="empty-state">No attendance records logged today.</td></tr>';
        return;
      }

      tbody.innerHTML = roster.map(r => {
        const statusCls = r.workStatus === 'WORKING' ? 'working' : (r.workStatus === 'COMPLETED' ? 'completed' : 'notin');
        return '<tr>' +
          '<td><span class="table-primary-text">' + r.name + '</span><br><span class="table-sub-text">' + r.email + '</span></td>' +
          '<td>' + r.role + ' • ' + r.department + '</td>' +
          '<td>' + (r.clockInTime ? new Date(r.clockInTime).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) : '—') + '</td>' +
          '<td>' + (r.clockOutTime ? new Date(r.clockOutTime).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) : '—') + '</td>' +
          '<td><span class="badge-status status-' + statusCls + '">' + r.workStatus + '</span></td>' +
        '</tr>';
      }).join('');

      const workingCount = roster.filter(r => r.workStatus === 'WORKING').length;
      const kpiCeo = document.getElementById('ceo-active-punch');
      if (kpiCeo) kpiCeo.innerText = workingCount;
      const kpiHr = document.getElementById('hr-present-today');
      if (kpiHr) kpiHr.innerText = workingCount;
    }

    function renderEmployees(emps) {
      const tbody = document.getElementById('hr-employees-tbody');
      if (!tbody) return;

      if (!emps.length) {
        tbody.innerHTML = '<tr><td colspan="6" class="empty-state">No employee records found.</td></tr>';
        return;
      }

      tbody.innerHTML = emps.map(e => {
        const statusCls = e.status === 'ACTIVE' ? 'working' : 'notin';
        return '<tr>' +
          '<td><span class="table-primary-text">' + e.name + '</span><br><span class="table-sub-text">' + e.email + '</span></td>' +
          '<td><span class="badge-status status-working">' + e.role + '</span></td>' +
          '<td>' + e.department + '</td>' +
          '<td>' + e.designation + '</td>' +
          '<td>' + (e.phone || '—') + '</td>' +
          '<td><span class="badge-status status-' + statusCls + '">' + e.status + '</span></td>' +
        '</tr>';
      }).join('');

      const countEl = document.getElementById('hr-emp-count');
      if (countEl) countEl.innerText = 'Showing ' + emps.length + ' registered employees';
      const kpiHr = document.getElementById('hr-total-emp');
      if (kpiHr) kpiHr.innerText = emps.length;
      const kpiCeo = document.getElementById('ceo-total-emp');
      if (kpiCeo) kpiCeo.innerText = emps.length;
    }

    function renderTasks(tasks) {
      // 1. CTO Tasks
      const ctoTbody = document.getElementById('cto-tasks-tbody');
      if (ctoTbody) {
        if (!tasks.length) {
          ctoTbody.innerHTML = '<tr><td colspan="5" class="empty-state">No engineering tasks found.</td></tr>';
        } else {
          ctoTbody.innerHTML = tasks.map(t => {
            const prioCls = t.priority === 'URGENT' ? 'urgent' : 'inprogress';
            const statCls = t.status === 'COMPLETED' ? 'completed' : 'todo';
            return '<tr>' +
              '<td><span class="table-primary-text">' + t.title + '</span></td>' +
              '<td>' + t.assigneeId + '</td>' +
              '<td><span class="badge-status status-' + prioCls + '">' + t.priority + '</span></td>' +
              '<td>' + new Date(t.deadline).toLocaleDateString() + '</td>' +
              '<td><span class="badge-status status-' + statCls + '">' + t.status + '</span></td>' +
            '</tr>';
          }).join('');
        }
      }

      // 2. Employee Workstation Tasks
      const empTbody = document.getElementById('emp-tasks-tbody');
      if (empTbody) {
        if (!tasks.length) {
          empTbody.innerHTML = '<tr><td colspan="5" class="empty-state">No pending tasks assigned.</td></tr>';
        } else {
          empTbody.innerHTML = tasks.map(t => {
            const prioCls = t.priority === 'URGENT' ? 'urgent' : 'inprogress';
            const statCls = t.status === 'COMPLETED' ? 'completed' : 'todo';
            const actionBtn = t.status !== 'COMPLETED'
              ? '<button class="btn-secondary" style="padding: 4px 10px; font-size: 11.5px;" onclick="advanceTaskStatus(\\'' + t.id + '\\')">Mark Done</button>'
              : '<span style="color: var(--success); font-weight: 600; font-size: 12px;">✓ Completed</span>';
            return '<tr>' +
              '<td><span class="table-primary-text">' + t.title + '</span></td>' +
              '<td><span class="badge-status status-' + prioCls + '">' + t.priority + '</span></td>' +
              '<td>' + new Date(t.deadline).toLocaleDateString() + '</td>' +
              '<td><span class="badge-status status-' + statCls + '">' + t.status + '</span></td>' +
              '<td style="text-align: right;">' + actionBtn + '</td>' +
            '</tr>';
          }).join('');
        }
        const taskCountEl = document.getElementById('emp-task-count');
        if (taskCountEl) taskCountEl.innerText = tasks.filter(t => t.status !== 'COMPLETED').length;
      }
    }

    function renderDocuments(docs) {
      const tbody = document.getElementById('docs-tbody');
      if (!tbody) return;

      if (!docs.length) {
        tbody.innerHTML = '<tr><td colspan="5" class="empty-state">No documents stored in vault.</td></tr>';
        return;
      }

      tbody.innerHTML = docs.map(d => {
        return '<tr>' +
          '<td><span class="table-primary-text">' + d.title + '</span></td>' +
          '<td><span class="badge-status status-todo">' + d.category + '</span></td>' +
          '<td>' + (d.isConfidential ? '<span style="color: var(--warning); font-weight: 600;">🔒 Restricted</span>' : 'Company Wide') + '</td>' +
          '<td>' + d.uploadedBy + '</td>' +
          '<td>' + new Date(d.createdAt).toLocaleDateString() + '</td>' +
        '</tr>';
      }).join('');

      const docsCountEl = document.getElementById('docs-count');
      if (docsCountEl) docsCountEl.innerText = 'Showing ' + docs.length + ' documents';
    }

    function renderAuditLogs(logs) {
      const tbody = document.getElementById('audit-tbody');
      if (!tbody) return;

      if (!logs.length) {
        tbody.innerHTML = '<tr><td colspan="6" class="empty-state">No security audit logs found.</td></tr>';
        return;
      }

      tbody.innerHTML = logs.map(l => {
        return '<tr>' +
          '<td style="font-family: monospace; font-size: 11.5px;">' + new Date(l.timestamp).toLocaleTimeString() + '</td>' +
          '<td>' + l.userEmail + '</td>' +
          '<td><span class="badge-status status-working">' + l.role + '</span></td>' +
          '<td><span class="table-primary-text">' + l.action + '</span></td>' +
          '<td>' + l.resourceType + '</td>' +
          '<td style="font-family: monospace; font-size: 11.5px;">' + l.ipAddress + '</td>' +
        '</tr>';
      }).join('');
    }

    // Punch Clock Flow
    async function toggleClockPunch() {
      const btn = document.getElementById('topbar-punch-btn');
      const isCurrentlyIn = btn.classList.contains('btn-punch-out');

      try {
        const endpoint = isCurrentlyIn ? '/api/v1/portal/attendance/clock-out' : '/api/v1/portal/attendance/clock-in';
        const res = await fetch(endpoint, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + authToken
          },
          body: JSON.stringify({ notes: 'Portal Shift Punch' })
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.message || data.error);

        if (isCurrentlyIn) {
          btn.className = 'btn-punch btn-punch-in';
          btn.innerHTML = '<span>Punch In</span>';
          document.getElementById('emp-punch-status').innerText = 'CLOCKED OUT';
          document.getElementById('emp-punch-time').innerText = 'Shift completed at ' + new Date().toLocaleTimeString();
          showToast('Shift ended successfully! Duration saved.', 'info');
        } else {
          btn.className = 'btn-punch btn-punch-out';
          btn.innerHTML = '<span>Punch Out</span>';
          document.getElementById('emp-punch-status').innerText = 'CLOCKED IN';
          document.getElementById('emp-punch-time').innerText = 'Started today at ' + new Date().toLocaleTimeString();
          showToast('Shift started! Punch-in recorded.', 'success');
        }
        loadDashboardData(currentUser);
      } catch (err) {
        showToast(err.message, 'error');
      }
    }

    // Task Status Advancement
    async function advanceTaskStatus(taskId) {
      try {
        const res = await fetch('/api/v1/portal/tasks/' + taskId + '/status', {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + authToken
          },
          body: JSON.stringify({ status: 'COMPLETED', notes: 'Completed via portal workstation' })
        });
        if (res.ok) {
          showToast('Task marked as completed', 'success');
          loadDashboardData(currentUser);
        } else {
          const json = await res.json();
          throw new Error(json.error || json.message);
        }
      } catch (err) {
        showToast(err.message, 'error');
      }
    }

    // Modal helpers
    function showAddEmployeeModal() {
      document.getElementById('modal-add-employee').classList.add('active');
    }

    function showUploadDocModal() {
      document.getElementById('modal-upload-doc').classList.add('active');
    }

    function closeModal(id) {
      document.getElementById(id).classList.remove('active');
    }

    async function submitNewEmployee(e) {
      e.preventDefault();
      const name = document.getElementById('add-emp-name').value.trim();
      const email = document.getElementById('add-emp-email').value.trim();
      const dept = document.getElementById('add-emp-dept').value;
      const role = document.getElementById('add-emp-role').value;
      const desig = document.getElementById('add-emp-designation').value.trim();

      try {
        const res = await fetch('/api/v1/portal/employees', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + authToken
          },
          body: JSON.stringify({
            name,
            email,
            department: dept,
            role,
            designation: desig,
            salaryAmount: 50000
          })
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || data.message);

        showToast('Staff member onboarded! Password: ' + data.data.defaultPassword, 'success');
        closeModal('modal-add-employee');
        e.target.reset();
        loadDashboardData(currentUser);
      } catch (err) {
        showToast(err.message, 'error');
      }
    }

    async function submitNewDocument(e) {
      e.preventDefault();
      const title = document.getElementById('doc-title').value.trim();
      const category = document.getElementById('doc-category').value;
      const isConfidential = document.getElementById('doc-confidential').checked;

      try {
        const res = await fetch('/api/v1/portal/documents', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + authToken
          },
          body: JSON.stringify({
            title,
            category,
            isConfidential,
            fileUrl: '/uploads/sample.pdf'
          })
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || data.message);

        showToast('Document uploaded successfully to vault', 'success');
        closeModal('modal-upload-doc');
        e.target.reset();
        loadDashboardData(currentUser);
      } catch (err) {
        showToast(err.message, 'error');
      }
    }

    function showForgotPasswordDialog() {
      const email = prompt('Enter your company email for reset instructions:');
      if (email) {
        fetch('/api/v1/portal/auth/forgot-password', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email })
        }).then(() => showToast('Password reset instructions forwarded to ' + email, 'info'));
      }
    }

    function confirmLogout() {
      if (confirm('Are you sure you want to sign out from Enterprenex Portal?')) {
        handleLogout();
      }
    }

    function handleLogout() {
      localStorage.removeItem('enx_portal_token');
      authToken = null;
      currentUser = null;
      showToast('Signed out successfully', 'info');
      showLoginView();
    }
  </script>
</body>
</html>`;
}

module.exports = { getCompanyPortalHtml };
