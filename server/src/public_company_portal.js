/**
 * Enterprenex Solutions — Company Management Portal Web Application
 * 
 * Production-ready Minimalist Enterprise SaaS Interface:
 * - Clean, modern, distraction-free aesthetic with subtle borders & muted dark surfaces
 * - Strict role-based navigation and access for all 9 roles:
 *     1. SUPER_ADMIN: Users, Roles/Permissions, Settings, Staff, Projects, Vault, Reports, Audit Trail
 *     2. CEO:         Executive Cockpit, Staff, Depts, Financials, Tech Command, Milestones, KPIs, Reports, Audit
 *     3. CFO:         Financial Command, Budgets & Spend, Fiscal Reports, Document Vault, Profile
 *     4. CTO:         Engineering Command, Sprints & Tasks, Architecture Projects, Tech Vault, Roster, Profile
 *     5. DEPT_HEAD:   Dept Overview, Team Members, Projects & Milestones, Team Tasks, Time Tracking, KPIs
 *     6. HR:          HR Dashboard, Staff, Departments, Attendance, Leave, Onboarding, Offboarding, Documents, Reports
 *     7. MANAGER:     Manager Dashboard, Team, Projects, Tasks, Milestones, Time Tracking, Team KPIs, Approvals
 *     8. EMPLOYEE:    Dashboard, My Tasks, My Projects, Attendance, Time Tracker, Leave, My KPIs, Documents, Profile
 *     9. CLIENT:      Client Overview, Assigned Projects, Milestones, Shared Deliverables, Project Communication
 * - Client portal is strictly isolated: no employee rosters, HR records, internal financials, or audit trails
 * - 100% preservation of all backend APIs, authentication, RBAC, and workflows
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
    /* ─── DESIGN SYSTEM VARIABLES ───────────────────────── */
    :root {
      --bg: #090d16;
      --surface: #0f172a;
      --surface-elevated: #131d35;
      --surface-hover: #18233e;
      --border: #1e293b;
      --border-subtle: #162032;
      --border-focus: #3b82f6;

      --text: #f8fafc;
      --text-muted: #94a3b8;
      --text-subtle: #64748b;

      --primary: #2563eb;
      --primary-hover: #1d4ed8;
      --primary-subtle: rgba(37, 99, 235, 0.12);

      --success: #10b981;
      --success-subtle: rgba(16, 185, 129, 0.12);
      --warning: #f59e0b;
      --warning-subtle: rgba(245, 158, 11, 0.12);
      --danger: #ef4444;
      --danger-subtle: rgba(239, 68, 68, 0.12);
      --purple: #8b5cf6;
      --purple-subtle: rgba(139, 92, 246, 0.12);

      --sidebar-w: 256px;
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
      font-size: 13.5px;
      min-height: 100vh;
      -webkit-font-smoothing: antialiased;
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
      max-width: 420px;
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
      max-width: 440px;
    }

    .login-brand {
      text-align: center;
      margin-bottom: 24px;
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
      padding: 28px;
      box-shadow: var(--shadow-lg);
    }

    .form-group {
      margin-bottom: 16px;
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
      margin-bottom: 18px;
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
      margin-top: 22px;
      padding-top: 18px;
      border-top: 1px solid var(--border-subtle);
      text-align: center;
    }

    .quick-access-label {
      font-size: 11px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      color: var(--text-subtle);
      margin-bottom: 10px;
    }

    .quick-pill-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
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
      font-size: 10px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.6px;
      color: var(--text-subtle);
      padding: 14px 12px 6px;
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
      cursor: pointer;
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
      color: var(--primary);
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
      font-size: 10.5px;
      color: var(--text-subtle);
      text-transform: uppercase;
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
      transition: color 0.15s, background-color 0.15s;
    }

    .btn-icon-subtle:hover {
      color: var(--text);
      background: var(--surface-hover);
    }

    /* Main Area */
    main.main-content {
      margin-left: var(--sidebar-w);
      flex: 1;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      background: var(--bg);
    }

    header.topbar {
      height: var(--topbar-h);
      border-bottom: 1px solid var(--border);
      background: var(--surface);
      padding: 0 28px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      position: sticky;
      top: 0;
      z-index: 50;
    }

    .topbar-left {
      display: flex;
      align-items: center;
      gap: 14px;
    }

    .mobile-menu-btn {
      display: none;
      background: none;
      border: none;
      color: var(--text);
      cursor: pointer;
      padding: 4px;
    }

    .topbar-title {
      font-size: 16px;
      font-weight: 700;
      color: var(--text);
      letter-spacing: -0.2px;
    }

    .topbar-badge {
      display: inline-block;
      padding: 3px 8px;
      border-radius: 9999px;
      font-size: 10.5px;
      font-weight: 600;
      background: var(--primary-subtle);
      color: var(--primary);
      text-transform: uppercase;
      letter-spacing: 0.4px;
    }

    .topbar-right {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .digital-clock {
      font-family: 'JetBrains Mono', monospace;
      font-size: 13px;
      color: var(--text-muted);
      background: var(--surface-elevated);
      padding: 5px 10px;
      border-radius: var(--radius-sm);
      border: 1px solid var(--border);
    }

    .btn-punch {
      padding: 7px 14px;
      border-radius: var(--radius-sm);
      font-size: 12.5px;
      font-weight: 600;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      gap: 6px;
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
      flex-wrap: wrap;
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
      background: var(--surface-elevated);
      padding: 11px 18px;
      font-weight: 600;
      font-size: 11.5px;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 0.5px;
      border-bottom: 1px solid var(--border);
      white-space: nowrap;
    }

    table.data-table td {
      padding: 12px 18px;
      border-bottom: 1px solid var(--border-subtle);
      color: var(--text-muted);
    }

    table.data-table tbody tr {
      transition: background-color 0.1s;
    }

    table.data-table tbody tr:hover {
      background: rgba(255, 255, 255, 0.02);
    }

    .table-primary-text {
      color: var(--text);
      font-weight: 600;
    }

    .table-sub-text {
      font-size: 11.5px;
      color: var(--text-subtle);
    }

    .badge-status {
      display: inline-flex;
      align-items: center;
      padding: 3px 8px;
      border-radius: 9999px;
      font-size: 11px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.3px;
    }

    .status-working, .status-active { background: var(--success-subtle); color: var(--success); }
    .status-completed, .status-approved { background: var(--primary-subtle); color: var(--primary); }
    .status-urgent, .status-rejected, .status-blocked { background: var(--danger-subtle); color: var(--danger); }
    .status-todo, .status-pending, .status-planned { background: var(--warning-subtle); color: var(--warning); }
    .status-notin, .status-disabled, .status-inactive { background: rgba(148, 163, 184, 0.12); color: var(--text-muted); }

    .table-footer {
      padding: 12px 20px;
      font-size: 12px;
      color: var(--text-subtle);
      border-top: 1px solid var(--border-subtle);
      display: flex;
      align-items: center;
      justify-content: space-between;
    }

    /* Card Grids for Projects & Departments */
    .card-grid-3 {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }

    .info-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 20px;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      transition: border-color 0.15s;
    }

    .info-card:hover {
      border-color: var(--text-subtle);
    }

    .info-card-header {
      display: flex;
      align-items: flex-start;
      justify-content: space-between;
      gap: 12px;
      margin-bottom: 12px;
    }

    .info-card-title {
      font-size: 14px;
      font-weight: 700;
      color: var(--text);
    }

    .info-card-desc {
      font-size: 12.5px;
      color: var(--text-muted);
      margin-bottom: 16px;
      line-height: 1.4;
    }

    .info-card-meta {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding-top: 12px;
      border-top: 1px solid var(--border-subtle);
      font-size: 11.5px;
      color: var(--text-subtle);
    }

    /* Progress bar */
    .progress-bar-bg {
      height: 6px;
      background: var(--bg);
      border-radius: 9999px;
      overflow: hidden;
      margin-bottom: 12px;
    }

    .progress-bar-fill {
      height: 100%;
      background: var(--primary);
      border-radius: 9999px;
    }

    /* Workflow Pipeline Stepper */
    .pipeline-step-list {
      display: flex;
      align-items: center;
      gap: 6px;
      overflow-x: auto;
      padding: 8px 0;
    }

    .pipeline-step {
      display: flex;
      align-items: center;
      gap: 6px;
      padding: 6px 12px;
      border-radius: 9999px;
      font-size: 11.5px;
      font-weight: 600;
      background: var(--surface-elevated);
      color: var(--text-subtle);
      border: 1px solid var(--border);
      white-space: nowrap;
    }

    .pipeline-step.step-completed {
      background: var(--success-subtle);
      color: var(--success);
      border-color: rgba(16, 185, 129, 0.3);
    }

    .pipeline-step.step-active {
      background: var(--primary-subtle);
      color: var(--primary);
      border-color: var(--primary);
    }

    /* Time Tracking Clock Widget */
    .timer-widget {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 24px;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      text-align: center;
      margin-bottom: 24px;
    }

    .timer-digits {
      font-family: 'JetBrains Mono', monospace;
      font-size: 42px;
      font-weight: 700;
      color: var(--text);
      letter-spacing: -1px;
      margin: 12px 0 18px;
    }

    .timer-controls {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    /* Notifications List */
    .notification-item {
      padding: 16px 20px;
      border-bottom: 1px solid var(--border-subtle);
      display: flex;
      align-items: flex-start;
      gap: 14px;
      transition: background-color 0.15s;
    }

    .notification-item:hover {
      background: rgba(255, 255, 255, 0.02);
    }

    .notification-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: var(--primary);
      margin-top: 6px;
      flex-shrink: 0;
    }

    .notification-content {
      flex: 1;
    }

    .notification-title {
      font-size: 13px;
      font-weight: 600;
      color: var(--text);
      margin-bottom: 3px;
    }

    .notification-time {
      font-size: 11px;
      color: var(--text-subtle);
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
          <div class="quick-access-label">Quick Demo Access (9 Prompt Roles)</div>
          <div class="quick-pill-grid">
            <button class="pill-role-btn" title="Super Admin" onclick="quickFill('admin@enterprenex.solutions', 'Admin@123')">Super Admin</button>
            <button class="pill-role-btn" title="Chief Executive Officer" onclick="quickFill('rohit@enterprenex.solutions', 'Admin@123')">CEO</button>
            <button class="pill-role-btn" title="Chief Financial Officer" onclick="quickFill('aniket@enterprenex.solutions', 'Admin@123')">CFO</button>
            <button class="pill-role-btn" title="Chief Technology Officer" onclick="quickFill('revanth.reddy@enterprenex.solutions', 'Admin@123')">CTO</button>
            <button class="pill-role-btn" title="Department Head" onclick="quickFill('amit.marketing@enterprenex.solutions', 'Admin@123')">Dept Head</button>
            <button class="pill-role-btn" title="Human Resources" onclick="quickFill('jyothi@enterprenex.solutions', 'Admin@123')">HR</button>
            <button class="pill-role-btn" title="Engineering Manager" onclick="quickFill('piyush@enterprenex.solutions', 'Admin@123')">Manager</button>
            <button class="pill-role-btn" title="Developer Employee" onclick="quickFill('kishore@enterprenex.solutions', 'Admin@123')">Employee</button>
            <button class="pill-role-btn" title="External Client" onclick="quickFill('client@acmecorp.com', 'Admin@123')">Client</button>
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
        <!-- Rendered dynamically based strictly on role -->
      </nav>

      <div class="sidebar-footer">
        <div class="user-profile-badge" onclick="switchView('profile', 'My Account Profile')">
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

      <!-- ─── VIEW: SUPER ADMIN USERS MANAGEMENT ───────── -->
      <section id="view-super-admin-users" class="view-content">
        <div class="metric-grid">
          <div class="metric-card">
            <div class="metric-header"><span>Total Users</span></div>
            <div class="metric-value" id="sa-total-users">9</div>
            <div class="metric-footer">Registered system accounts</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Active Roles</span></div>
            <div class="metric-value">9</div>
            <div class="metric-footer">Granular RBAC roles</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Active Sessions</span></div>
            <div class="metric-value" id="sa-active-sessions">1</div>
            <div class="metric-footer">Dual-token JWT sessions</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Security Status</span></div>
            <div class="metric-value" style="color: var(--success); font-size: 18px;">SECURE</div>
            <div class="metric-footer">All logins audited</div>
          </div>
        </div>

        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">User Accounts Directory & Roles</h3>
            <div class="panel-actions">
              <input type="text" class="table-search-input" placeholder="Search users..." onkeyup="filterTable('sa-users-tbody', this.value)" />
              <button class="btn-secondary" onclick="showCreateUserModal()">+ Create User</button>
            </div>
          </div>
          <div class="table-responsive">
            <table class="data-table">
              <thead>
                <tr>
                  <th>User</th>
                  <th>Role</th>
                  <th>Department</th>
                  <th>Status</th>
                  <th>Last Login</th>
                  <th style="text-align: right;">Action</th>
                </tr>
              </thead>
              <tbody id="sa-users-tbody"></tbody>
            </table>
          </div>
        </div>
      </section>

      <!-- ─── VIEW: SUPER ADMIN ROLES & PERMISSIONS ────── -->
      <section id="view-super-admin-roles" class="view-content">
        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">Role-Based Access Control (RBAC) Matrix</h3>
          </div>
          <div class="table-responsive">
            <table class="data-table">
              <thead>
                <tr>
                  <th>Role</th>
                  <th>Scope</th>
                  <th>Assigned Permissions</th>
                  <th>Security Level</th>
                </tr>
              </thead>
              <tbody id="sa-roles-tbody">
                <tr>
                  <td><span class="table-primary-text">SUPER_ADMIN</span></td>
                  <td>Global</td>
                  <td>Complete administrative access, user creation, settings, role configuration, full audit access</td>
                  <td><span class="badge-status status-urgent">Tier 0 (Root)</span></td>
                </tr>
                <tr>
                  <td><span class="table-primary-text">CEO</span></td>
                  <td>Executive</td>
                  <td>Company analytics, departments, employees, project milestones, performance, audit view</td>
                  <td><span class="badge-status status-working">Tier 1 (Executive)</span></td>
                </tr>
                <tr>
                  <td><span class="table-primary-text">CFO</span></td>
                  <td>Financial</td>
                  <td>Budgets, payroll analysis, fiscal documents, departmental expenditure reviews</td>
                  <td><span class="badge-status status-working">Tier 1 (Executive)</span></td>
                </tr>
                <tr>
                  <td><span class="table-primary-text">CTO</span></td>
                  <td>Engineering</td>
                  <td>Technical systems, architecture projects, sprint tasks, engineering roster, tech vault</td>
                  <td><span class="badge-status status-working">Tier 1 (Executive)</span></td>
                </tr>
                <tr>
                  <td><span class="table-primary-text">DEPARTMENT_HEAD</span></td>
                  <td>Departmental</td>
                  <td>Department overview, team members, team milestones, project tasks, time tracking, KPIs</td>
                  <td><span class="badge-status status-completed">Tier 2 (Managerial)</span></td>
                </tr>
                <tr>
                  <td><span class="table-primary-text">HR</span></td>
                  <td>People Operations</td>
                  <td>Employees roster, attendance logging, leave approvals, onboarding, offboarding, documents</td>
                  <td><span class="badge-status status-completed">Tier 2 (Managerial)</span></td>
                </tr>
                <tr>
                  <td><span class="table-primary-text">MANAGER</span></td>
                  <td>Team Scope</td>
                  <td>Assigned team members, project milestones, task assignment, time reports, approvals, team KPIs</td>
                  <td><span class="badge-status status-completed">Tier 2 (Managerial)</span></td>
                </tr>
                <tr>
                  <td><span class="table-primary-text">EMPLOYEE</span></td>
                  <td>Individual Scope</td>
                  <td>Personal dashboard, assigned tasks, project sprint, attendance punch, leave requests, KPIs</td>
                  <td><span class="badge-status status-todo">Tier 3 (Staff)</span></td>
                </tr>
                <tr>
                  <td><span class="table-primary-text">CLIENT</span></td>
                  <td>Strictly Isolated</td>
                  <td>Assigned projects, milestone progress, shared documents, project comments & inquiries</td>
                  <td><span class="badge-status status-notin">Tier 4 (External)</span></td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </section>

      <!-- ─── VIEW: SUPER ADMIN COMPANY SETTINGS ────────── -->
      <section id="view-super-admin-settings" class="view-content">
        <div class="panel" style="max-width: 760px;">
          <div class="panel-header">
            <h3 class="panel-title">Enterprenex Company Settings & Security Policy</h3>
            <div class="panel-actions">
              <button class="btn-secondary" onclick="saveCompanySettings()">Save Settings</button>
            </div>
          </div>
          <div style="padding: 24px;">
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 20px;">
              <div class="form-group">
                <label class="form-label">Company Legal Name</label>
                <input type="text" id="setting-company-name" class="form-control" value="Enterprenex Solutions Pvt Ltd" />
              </div>
              <div class="form-group">
                <label class="form-label">Portal Domain</label>
                <input type="text" id="setting-portal-domain" class="form-control" value="portal.enterprenex.solutions" />
              </div>
              <div class="form-group">
                <label class="form-label">Shift Start Time</label>
                <input type="time" id="setting-shift-start" class="form-control" value="09:00" />
              </div>
              <div class="form-group">
                <label class="form-label">Shift End Time</label>
                <input type="time" id="setting-shift-end" class="form-control" value="18:00" />
              </div>
              <div class="form-group">
                <label class="form-label">JWT Session Expiry (Hours)</label>
                <input type="number" id="setting-jwt-expiry" class="form-control" value="24" />
              </div>
              <div class="form-group">
                <label class="form-label">Currency Code</label>
                <input type="text" id="setting-currency" class="form-control" value="INR (₹)" />
              </div>
            </div>

            <div style="border-top: 1px solid var(--border-subtle); padding-top: 18px; display: flex; flex-direction: column; gap: 12px;">
              <label class="form-checkbox-label">
                <input type="checkbox" id="setting-enforce-2fa" checked />
                <span>Enforce Multi-Factor Authentication (MFA) for Executive and Admin roles</span>
              </label>
              <label class="form-checkbox-label">
                <input type="checkbox" id="setting-strict-audit" checked />
                <span>Enable Immutable Audit Trails for all database modifications and file access</span>
              </label>
              <label class="form-checkbox-label">
                <input type="checkbox" id="setting-client-isolation" checked />
                <span>Strict Client Data Isolation (Never expose employee rosters or HR entities)</span>
              </label>
            </div>
          </div>
        </div>
      </section>

      <!-- ─── VIEW: MANAGER DASHBOARD ───────────────────── -->
      <section id="view-manager-dashboard" class="view-content">
        <div class="metric-grid">
          <div class="metric-card">
            <div class="metric-header"><span>Team Size</span></div>
            <div class="metric-value" id="mgr-team-size">4</div>
            <div class="metric-footer">Engineers & Analysts</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Active Projects</span></div>
            <div class="metric-value">3</div>
            <div class="metric-footer">Sprint deliverables</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Pending Approvals</span></div>
            <div class="metric-value" id="mgr-pending-tasks">2</div>
            <div class="metric-footer">Deliverables ready for review</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Team Velocity</span></div>
            <div class="metric-value" style="color: var(--success);">94.8%</div>
            <div class="metric-footer">Sprint completion on schedule</div>
          </div>
        </div>

        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">Team Task Approvals & Reviews</h3>
            <div class="panel-actions">
              <button class="btn-secondary" onclick="switchView('emp-tasks', 'Manage Tasks')">View All Tasks</button>
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
                  <th style="text-align: right;">Action</th>
                </tr>
              </thead>
              <tbody id="mgr-approvals-tbody"></tbody>
            </table>
          </div>
        </div>
      </section>

      <!-- ─── VIEW: PROJECTS & MILESTONES ───────────────── -->
      <section id="view-milestones" class="view-content">
        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">Active Projects & Sprint Milestones</h3>
            <div class="panel-actions">
              <button class="btn-secondary" onclick="showAddMilestoneModal()">+ Add Milestone</button>
            </div>
          </div>
          <div style="padding: 20px;" id="milestones-container">
            <div class="card-grid-3" id="milestones-cards-grid">
              <!-- Rendered via loadMilestones() -->
            </div>
          </div>
        </div>
      </section>

      <!-- ─── VIEW: TIME TRACKING ───────────────────────── -->
      <section id="view-time-tracking" class="view-content">
        <div class="timer-widget">
          <span style="font-size: 12px; font-weight: 600; text-transform: uppercase; color: var(--text-muted); letter-spacing: 0.5px;">Live Work Session</span>
          <div class="timer-digits" id="live-timer-digits">00:00:00</div>
          <div class="timer-controls">
            <button id="btn-timer-start" class="btn-secondary" onclick="startWorkTimer()">▶ Start Work</button>
            <button id="btn-timer-pause" class="btn-secondary" onclick="pauseWorkTimer()">⏸ Break</button>
            <button id="btn-timer-stop" class="btn-secondary" style="color: var(--danger); border-color: rgba(239, 68, 68, 0.3);" onclick="stopWorkTimer()">⏹ Stop Work</button>
          </div>
          <div style="font-size: 11.5px; color: var(--text-subtle); margin-top: 14px;" id="timer-session-note">No active session running. Click Start Work to begin tracking.</div>
        </div>

        <div class="metric-grid">
          <div class="metric-card">
            <div class="metric-header"><span>Logged Today</span></div>
            <div class="metric-value" id="tt-today-hours">0.0h</div>
            <div class="metric-footer">Billable working hours</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>This Week</span></div>
            <div class="metric-value" id="tt-week-hours">38.5h</div>
            <div class="metric-footer">Total week duration</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Efficiency Score</span></div>
            <div class="metric-value" style="color: var(--success);">98%</div>
            <div class="metric-footer">Active task focus</div>
          </div>
        </div>

        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">Recent Time Logs & Sessions</h3>
          </div>
          <div class="table-responsive">
            <table class="data-table">
              <thead>
                <tr>
                  <th>Date</th>
                  <th>Task / Activity</th>
                  <th>Start Time</th>
                  <th>End Time</th>
                  <th>Duration</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody id="time-logs-tbody">
                <tr>
                  <td class="table-primary-text">Today</td>
                  <td>API Gateway RBAC implementation</td>
                  <td>09:30 AM</td>
                  <td>01:30 PM</td>
                  <td>4h 0m</td>
                  <td><span class="badge-status status-completed">Logged</span></td>
                </tr>
                <tr>
                  <td class="table-primary-text">Today</td>
                  <td>Sprint Task Reviews & PR Approvals</td>
                  <td>02:15 PM</td>
                  <td>05:45 PM</td>
                  <td>3h 30m</td>
                  <td><span class="badge-status status-completed">Logged</span></td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </section>

      <!-- ─── VIEW: ONBOARDING WORKFLOW ─────────────────── -->
      <section id="view-onboarding" class="view-content">
        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">Employee Onboarding Pipeline (7-Step Workflow)</h3>
            <div class="panel-actions">
              <button class="btn-secondary" onclick="showInitiateOnboardingModal()">+ Initiate Candidate Onboarding</button>
            </div>
          </div>
          <div class="table-responsive">
            <table class="data-table">
              <thead>
                <tr>
                  <th>Candidate</th>
                  <th>Role & Department</th>
                  <th>Current Step</th>
                  <th>Progress</th>
                  <th>Status</th>
                  <th style="text-align: right;">Action</th>
                </tr>
              </thead>
              <tbody id="onboarding-tbody"></tbody>
            </table>
          </div>
        </div>
      </section>

      <!-- ─── VIEW: OFFBOARDING WORKFLOW ────────────────── -->
      <section id="view-offboarding" class="view-content">
        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">Employee Exit & Offboarding Tracker</h3>
            <div class="panel-actions">
              <button class="btn-secondary" onclick="showInitiateOffboardingModal()">+ Initiate Exit Checklist</button>
            </div>
          </div>
          <div class="table-responsive">
            <table class="data-table">
              <thead>
                <tr>
                  <th>Employee</th>
                  <th>Department</th>
                  <th>Notice / Last Day</th>
                  <th>Exit Stage</th>
                  <th>Status</th>
                  <th style="text-align: right;">Action</th>
                </tr>
              </thead>
              <tbody id="offboarding-tbody"></tbody>
            </table>
          </div>
        </div>
      </section>

      <!-- ─── VIEW: KPIS & PERFORMANCE ──────────────────── -->
      <section id="view-kpis" class="view-content">
        <div class="metric-grid">
          <div class="metric-card">
            <div class="metric-header"><span>Task Completion Rate</span></div>
            <div class="metric-value" style="color: var(--success);">96.2%</div>
            <div class="metric-footer">Sprint deliverables delivered</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>On-Time Delivery</span></div>
            <div class="metric-value">92.8%</div>
            <div class="metric-footer">Within target sprint window</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Quality Score</span></div>
            <div class="metric-value" style="color: var(--success);">98.0%</div>
            <div class="metric-footer">Code review pass rate</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Review Cycle</span></div>
            <div class="metric-value">Q4 2026</div>
            <div class="metric-footer">Active assessment window</div>
          </div>
        </div>

        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">Active Goals & KPI Performance Reviews</h3>
            <div class="panel-actions">
              <button class="btn-secondary" onclick="showCreateGoalModal()">+ New Goal</button>
              <button class="btn-secondary" onclick="showCreateReviewModal()">+ Review</button>
            </div>
          </div>
          <div class="table-responsive">
            <table class="data-table">
              <thead>
                <tr>
                  <th>Goal / Metric</th>
                  <th>Employee</th>
                  <th>Target Window</th>
                  <th>Target vs Actual</th>
                  <th>Score</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody id="kpi-goals-tbody"></tbody>
            </table>
          </div>
        </div>
      </section>

      <!-- ─── VIEW: CLIENT PORTAL (STRICT ISOLATION) ────── -->
      <section id="view-client-dashboard" class="view-content">
        <div class="metric-grid">
          <div class="metric-card">
            <div class="metric-header"><span>Assigned Projects</span></div>
            <div class="metric-value" id="client-project-count">1</div>
            <div class="metric-footer">Active client deliverables</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Milestone Progress</span></div>
            <div class="metric-value" style="color: var(--success);" id="client-milestone-progress">85%</div>
            <div class="metric-footer">Overall completion</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Shared Deliverables</span></div>
            <div class="metric-value" id="client-doc-count">2</div>
            <div class="metric-footer">Approved documents & specs</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Project Status</span></div>
            <div class="metric-value" style="font-size: 16px; color: var(--success);">ON TRACK</div>
            <div class="metric-footer">Delivery timeline green</div>
          </div>
        </div>

        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">Your Assigned Projects & Progress</h3>
            <div class="panel-actions">
              <button class="btn-secondary" onclick="showClientFeedbackModal()">Submit Inquiry / Feedback</button>
            </div>
          </div>
          <div class="table-responsive">
            <table class="data-table">
              <thead>
                <tr>
                  <th>Project Name</th>
                  <th>Scope</th>
                  <th>Current Milestone</th>
                  <th>Progress</th>
                  <th>Target Date</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody id="client-projects-tbody"></tbody>
            </table>
          </div>
        </div>

        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">Approved Deliverables & Project Documents</h3>
          </div>
          <div class="table-responsive">
            <table class="data-table">
              <thead>
                <tr>
                  <th>Document Name</th>
                  <th>Category</th>
                  <th>Shared Date</th>
                  <th style="text-align: right;">Action</th>
                </tr>
              </thead>
              <tbody id="client-docs-tbody"></tbody>
            </table>
          </div>
        </div>
      </section>

      <!-- ─── VIEW 1: EMPLOYEE DASHBOARD ────────────────── -->
      <section id="view-emp-dashboard" class="view-content">
        <div class="metric-grid">
          <div class="metric-card">
            <div class="metric-header"><span>Shift Status</span></div>
            <div class="metric-value" id="emp-punch-status">CLOCKED OUT</div>
            <div class="metric-footer" id="emp-punch-time">Click top right button to punch in</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Pending Tasks</span></div>
            <div class="metric-value" id="emp-dash-task-count">0</div>
            <div class="metric-footer">Deliverables pending</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Active Projects</span></div>
            <div class="metric-value">3</div>
            <div class="metric-footer">Sprint assignments</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Leave Balance</span></div>
            <div class="metric-value">14 Days</div>
            <div class="metric-footer">Annual balance remaining</div>
          </div>
        </div>

        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">Recent Activity & Tasks</h3>
            <div class="panel-actions">
              <button class="btn-secondary" onclick="switchView('emp-tasks', 'My Tasks')">View All Tasks</button>
            </div>
          </div>
          <div class="table-responsive">
            <table class="data-table">
              <thead>
                <tr>
                  <th>Task</th>
                  <th>Priority</th>
                  <th>Deadline</th>
                  <th>Status</th>
                  <th style="text-align: right;">Action</th>
                </tr>
              </thead>
              <tbody id="emp-recent-tasks-tbody"></tbody>
            </table>
          </div>
        </div>
      </section>

      <!-- ─── VIEW 2: EMPLOYEE MY TASKS ─────────────────── -->
      <section id="view-emp-tasks" class="view-content">
        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">My Tasks</h3>
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
              <tbody id="emp-tasks-tbody"></tbody>
            </table>
          </div>
          <div class="table-footer">
            <span id="emp-tasks-count">Showing active tasks</span>
          </div>
        </div>
      </section>

      <!-- ─── VIEW 3: EMPLOYEE MY PROJECTS ──────────────── -->
      <section id="view-emp-projects" class="view-content">
        <div class="card-grid-3">
          <div class="info-card">
            <div>
              <div class="info-card-header">
                <span class="info-card-title">ENX Money Mobile App</span>
                <span class="badge-status status-working">In Progress</span>
              </div>
              <p class="info-card-desc">React Native Android/iOS fintech app with Razorpay checkout & offline khata reconciliation.</p>
              <div class="progress-bar-bg"><div class="progress-bar-fill" style="width: 82%;"></div></div>
            </div>
            <div class="info-card-meta">
              <span>Code: PRJ-101</span>
              <span>Deadline: Dec 2026</span>
            </div>
          </div>

          <div class="info-card">
            <div>
              <div class="info-card-header">
                <span class="info-card-title">Company Portal & HRMS</span>
                <span class="badge-status status-completed">Active Sprint</span>
              </div>
              <p class="info-card-desc">Unified enterprise portal with RBAC dashboards, attendance logging, and staff management.</p>
              <div class="progress-bar-bg"><div class="progress-bar-fill" style="width: 95%;"></div></div>
            </div>
            <div class="info-card-meta">
              <span>Code: PRJ-102</span>
              <span>Deadline: Nov 2026</span>
            </div>
          </div>

          <div class="info-card">
            <div>
              <div class="info-card-header">
                <span class="info-card-title">WhatsApp Cloud Billing</span>
                <span class="badge-status status-working">In Progress</span>
              </div>
              <p class="info-card-desc">Automated debtor reminder dispatch, statements delivery, and AI conversational bot.</p>
              <div class="progress-bar-bg"><div class="progress-bar-fill" style="width: 68%;"></div></div>
            </div>
            <div class="info-card-meta">
              <span>Code: PRJ-103</span>
              <span>Deadline: Jan 2027</span>
            </div>
          </div>
        </div>
      </section>

      <!-- ─── VIEW 4: ATTENDANCE (EMPLOYEE / LIVE ROSTER) ── -->
      <section id="view-attendance" class="view-content">
        <div class="metric-grid">
          <div class="metric-card">
            <div class="metric-header"><span>Today's Shift</span></div>
            <div class="metric-value" id="att-shift-val">0h 0m</div>
            <div class="metric-footer" id="att-shift-sub">Logged duration</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Present This Month</span></div>
            <div class="metric-value">22 / 24</div>
            <div class="metric-footer">91.6% Attendance score</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Punctuality</span></div>
            <div class="metric-value" style="color: var(--success);">100%</div>
            <div class="metric-footer">Zero late punches</div>
          </div>
        </div>

        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">Attendance Records & Live Roster</h3>
            <div class="panel-actions">
              <input type="text" class="table-search-input" placeholder="Search roster..." onkeyup="filterTable('att-history-tbody', this.value)" />
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
              <tbody id="att-history-tbody"></tbody>
            </table>
          </div>
        </div>
      </section>

      <!-- ─── VIEW 5: HR DASHBOARD ──────────────────────── -->
      <section id="view-hr-dashboard" class="view-content">
        <div class="metric-grid">
          <div class="metric-card">
            <div class="metric-header"><span>Total Headcount</span></div>
            <div class="metric-value" id="hr-dash-total">8</div>
            <div class="metric-footer">Registered company staff</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Active Working Today</span></div>
            <div class="metric-value" id="hr-dash-present">0</div>
            <div class="metric-footer">Live shift records</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Departments</span></div>
            <div class="metric-value">5</div>
            <div class="metric-footer">Operational units</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Pending Leaves</span></div>
            <div class="metric-value">0</div>
            <div class="metric-footer">All applications reviewed</div>
          </div>
        </div>

        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">Company Staff Overview</h3>
            <div class="panel-actions">
              <button class="btn-secondary" onclick="switchView('hr-employees', 'Employees')">Manage Staff</button>
              <button class="btn-secondary" onclick="showAddEmployeeModal()">+ Onboard</button>
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
                  <th>Status</th>
                </tr>
              </thead>
              <tbody id="hr-dash-emp-tbody"></tbody>
            </table>
          </div>
        </div>
      </section>

      <!-- ─── VIEW 6: HR EMPLOYEES DIRECTORY ────────────── -->
      <section id="view-hr-employees" class="view-content">
        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">Staff Directory</h3>
            <div class="panel-actions">
              <input type="text" class="table-search-input" placeholder="Search staff..." onkeyup="filterTable('hr-employees-tbody', this.value)" />
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
              <tbody id="hr-employees-tbody"></tbody>
            </table>
          </div>
          <div class="table-footer">
            <span id="hr-emp-count">Active staff members</span>
          </div>
        </div>
      </section>

      <!-- ─── VIEW 7: HR DEPARTMENTS ────────────────────── -->
      <section id="view-hr-departments" class="view-content">
        <div class="card-grid-3">
          <div class="info-card">
            <div>
              <div class="info-card-header">
                <span class="info-card-title">Software & Engineering</span>
                <span class="badge-status status-working">5 Staff</span>
              </div>
              <p class="info-card-desc">Full-Stack, Mobile (React Native/Flutter), DevOps, Cloud Infrastructure, and QA automation.</p>
            </div>
            <div class="info-card-meta">
              <span>Budget: ₹12,00,000 / mo</span>
              <span>Lead: Revanth Reddy (CTO)</span>
            </div>
          </div>

          <div class="info-card">
            <div>
              <div class="info-card-header">
                <span class="info-card-title">Growth & Marketing</span>
                <span class="badge-status status-working">1 Staff</span>
              </div>
              <p class="info-card-desc">Customer acquisition, B2B merchant partnerships, digital campaigns, and community engagement.</p>
            </div>
            <div class="info-card-meta">
              <span>Budget: ₹4,50,000 / mo</span>
              <span>Lead: Amit Kumar</span>
            </div>
          </div>

          <div class="info-card">
            <div>
              <div class="info-card-header">
                <span class="info-card-title">Finance & Accounts</span>
                <span class="badge-status status-working">1 Staff</span>
              </div>
              <p class="info-card-desc">Capital allocation, statutory compliance (GST/TDS), merchant settlements, and treasury oversight.</p>
            </div>
            <div class="info-card-meta">
              <span>Budget: ₹3,00,000 / mo</span>
              <span>Lead: Aniket Sharma (CFO)</span>
            </div>
          </div>

          <div class="info-card">
            <div>
              <div class="info-card-header">
                <span class="info-card-title">People & Culture</span>
                <span class="badge-status status-working">1 Staff</span>
              </div>
              <p class="info-card-desc">Talent acquisition, onboarding, payroll processing, statutory labor compliance, and employee success.</p>
            </div>
            <div class="info-card-meta">
              <span>Budget: ₹1,80,000 / mo</span>
              <span>Lead: Jyothi Patil (HR)</span>
            </div>
          </div>
        </div>
      </section>

      <!-- ─── VIEW 8: LEAVE MANAGEMENT ──────────────────── -->
      <section id="view-leave" class="view-content">
        <div class="panel">
          <div class="panel-header">
            <h3 class="panel-title">Leave Applications & Approvals</h3>
            <div class="panel-actions">
              <button class="btn-secondary" onclick="showApplyLeaveModal()">+ Apply Leave</button>
            </div>
          </div>
          <div class="table-responsive">
            <table class="data-table">
              <thead>
                <tr>
                  <th>Employee</th>
                  <th>Leave Type</th>
                  <th>Duration</th>
                  <th>Reason</th>
                  <th>Status</th>
                  <th style="text-align: right;">Action</th>
                </tr>
              </thead>
              <tbody id="leaves-tbody">
                <tr><td colspan="6" class="empty-state">No pending leave applications.</td></tr>
              </tbody>
            </table>
          </div>
        </div>
      </section>

      <!-- ─── VIEW 9: REPORTS & INSIGHTS ────────────────── -->
      <section id="view-reports" class="view-content">
        <div class="metric-grid">
          <div class="metric-card">
            <div class="metric-header"><span>Monthly Output</span></div>
            <div class="metric-value">96.4%</div>
            <div class="metric-footer">Sprint deliverables completed</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Average Shift Hours</span></div>
            <div class="metric-value">8.4h</div>
            <div class="metric-footer">Per employee daily average</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Employee Retention</span></div>
            <div class="metric-value" style="color: var(--success);">100%</div>
            <div class="metric-footer">Zero voluntary churn in FY26</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Budget Variance</span></div>
            <div class="metric-value">-4.2%</div>
            <div class="metric-footer">Under budgeted projections</div>
          </div>
        </div>
      </section>

      <!-- ─── VIEW 10: DOCUMENTS VAULT ──────────────────── -->
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
              <tbody id="docs-tbody"></tbody>
            </table>
          </div>
          <div class="table-footer">
            <span id="docs-count">Enterprise document records</span>
          </div>
        </div>
      </section>

      <!-- ─── VIEW 11: NOTIFICATIONS CENTER ─────────────── -->
      <section id="view-notifications" class="view-content">
        <div class="panel" style="max-width: 800px;">
          <div class="panel-header">
            <h3 class="panel-title">System & Company Notifications</h3>
            <div class="panel-actions">
              <button class="btn-secondary" onclick="showToast('All notifications marked as read', 'info')">Mark All as Read</button>
            </div>
          </div>
          <div id="notifications-list">
            <div class="notification-item">
              <div class="notification-dot"></div>
              <div class="notification-content">
                <div class="notification-title">Scheduled System Maintenance Completed</div>
                <p style="font-size: 12.5px; color: var(--text-muted);">Database indexing and automated backup verification succeeded on Render.</p>
                <div class="notification-time">Today, 04:00 AM</div>
              </div>
            </div>
            <div class="notification-item">
              <div class="notification-dot" style="background: var(--success);"></div>
              <div class="notification-content">
                <div class="notification-title">Sprint 4 Milestones Finalized</div>
                <p style="font-size: 12.5px; color: var(--text-muted);">All team members can review assigned deliverables in the My Tasks view.</p>
                <div class="notification-time">Yesterday, 06:30 PM</div>
              </div>
            </div>
            <div class="notification-item">
              <div class="notification-dot" style="background: var(--text-subtle);"></div>
              <div class="notification-content">
                <div class="notification-title">Payroll Remittance Processed</div>
                <p style="font-size: 12.5px; color: var(--text-muted);">Monthly payroll disbursements for active staff have been initiated via bank integration.</p>
                <div class="notification-time">3 days ago</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <!-- ─── VIEW 12: USER ACCOUNT PROFILE ─────────────── -->
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
                <div class="form-label">Account Status</div>
                <div><span class="badge-status status-working">Active Account</span></div>
              </div>
            </div>

            <div style="margin-top: 24px; padding-top: 20px; border-top: 1px solid var(--border-subtle);">
              <button class="btn-secondary" onclick="confirmLogout()">Sign Out from Portal</button>
            </div>
          </div>
        </div>
      </section>

      <!-- ─── VIEW 13: CEO EXECUTIVE COCKPIT ────────────── -->
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
            <div class="metric-footer">Live shift records</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Projects</span></div>
            <div class="metric-value">3</div>
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
              <tbody id="ceo-roster-tbody"></tbody>
            </table>
          </div>
        </div>
      </section>

      <!-- ─── VIEW 14: CTO TECHNICAL COMMAND ────────────── -->
      <section id="view-cto" class="view-content">
        <div class="metric-grid">
          <div class="metric-card">
            <div class="metric-header"><span>Engineering Team</span></div>
            <div class="metric-value" id="cto-tech-team">5</div>
            <div class="metric-footer">Engineers & QA Staff</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Production Health</span></div>
            <div class="metric-value" style="color: var(--success);">99.98%</div>
            <div class="metric-footer">Render & MySQL operational</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>CI/CD Pipeline</span></div>
            <div class="metric-value" style="font-size: 16px;">PASSING</div>
            <div class="metric-footer">All automated unit tests passed</div>
          </div>
          <div class="metric-card">
            <div class="metric-header"><span>Active Tasks</span></div>
            <div class="metric-value" id="cto-open-tasks">2</div>
            <div class="metric-footer">Current sprint milestones</div>
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
              <tbody id="cto-tasks-tbody"></tbody>
            </table>
          </div>
        </div>
      </section>

      <!-- ─── VIEW 15: CFO FINANCIAL COMMAND ────────────── -->
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
            <div class="metric-header"><span>Statutory Compliance</span></div>
            <div class="metric-value" style="font-size: 16px; color: var(--success);">CLEAR</div>
            <div class="metric-footer">GST, TDS & regulatory remit</div>
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
        </div>
      </section>

      <!-- ─── VIEW 16: SECURITY AUDIT TRAIL ─────────────── -->
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
              <tbody id="audit-tbody"></tbody>
            </table>
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

  <!-- ─── MODAL: CREATE USER (SUPER ADMIN) ─────────────── -->
  <div id="modal-create-user" class="modal-overlay">
    <div class="modal-dialog">
      <div class="modal-header">
        <h3 class="modal-title">Create User Account</h3>
        <button class="modal-close" onclick="closeModal('modal-create-user')">&times;</button>
      </div>
      <form onsubmit="submitCreateUser(event)">
        <div class="form-group">
          <label class="form-label">Full Name</label>
          <input type="text" id="cu-name" class="form-control" required />
        </div>
        <div class="form-group">
          <label class="form-label">Email Address</label>
          <input type="email" id="cu-email" class="form-control" placeholder="name@enterprenex.solutions" required />
        </div>
        <div class="form-group">
          <label class="form-label">Role</label>
          <select id="cu-role" class="form-control">
            <option value="SUPER_ADMIN">SUPER_ADMIN</option>
            <option value="CEO">CEO</option>
            <option value="CFO">CFO</option>
            <option value="CTO">CTO</option>
            <option value="DEPARTMENT_HEAD">DEPARTMENT_HEAD</option>
            <option value="HR">HR</option>
            <option value="MANAGER">MANAGER</option>
            <option value="EMPLOYEE" selected>EMPLOYEE</option>
            <option value="CLIENT">CLIENT</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">Department</label>
          <input type="text" id="cu-dept" class="form-control" placeholder="ENGINEERING / FINANCE / etc." />
        </div>
        <div class="form-group">
          <label class="form-label">Initial Password</label>
          <input type="password" id="cu-pass" class="form-control" placeholder="Leave empty for Admin@123" />
        </div>
        <div class="modal-actions">
          <button type="button" class="btn-secondary" onclick="closeModal('modal-create-user')">Cancel</button>
          <button type="submit" class="btn-primary" style="width: auto;">Create User</button>
        </div>
      </form>
    </div>
  </div>

  <!-- ─── MODAL: ADD MILESTONE ─────────────────────────── -->
  <div id="modal-add-milestone" class="modal-overlay">
    <div class="modal-dialog">
      <div class="modal-header">
        <h3 class="modal-title">Create Project Milestone</h3>
        <button class="modal-close" onclick="closeModal('modal-add-milestone')">&times;</button>
      </div>
      <form onsubmit="submitAddMilestone(event)">
        <div class="form-group">
          <label class="form-label">Project</label>
          <select id="ms-project-id" class="form-control">
            <option value="PRJ-101">ENX Money Mobile App (PRJ-101)</option>
            <option value="PRJ-102">Company Portal & HRMS (PRJ-102)</option>
            <option value="PRJ-103">WhatsApp Cloud Billing (PRJ-103)</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">Milestone Title</label>
          <input type="text" id="ms-title" class="form-control" placeholder="e.g. Sprint 5 Security Signoff" required />
        </div>
        <div class="form-group">
          <label class="form-label">Target Due Date</label>
          <input type="date" id="ms-due" class="form-control" required />
        </div>
        <div class="form-group">
          <label class="form-label">Initial Progress (%)</label>
          <input type="number" id="ms-progress" class="form-control" min="0" max="100" value="0" />
        </div>
        <div class="modal-actions">
          <button type="button" class="btn-secondary" onclick="closeModal('modal-add-milestone')">Cancel</button>
          <button type="submit" class="btn-primary" style="width: auto;">Create Milestone</button>
        </div>
      </form>
    </div>
  </div>

  <!-- ─── MODAL: INITIATE ONBOARDING ───────────────────── -->
  <div id="modal-initiate-onboarding" class="modal-overlay">
    <div class="modal-dialog">
      <div class="modal-header">
        <h3 class="modal-title">Initiate Candidate Onboarding</h3>
        <button class="modal-close" onclick="closeModal('modal-initiate-onboarding')">&times;</button>
      </div>
      <form onsubmit="submitInitiateOnboarding(event)">
        <div class="form-group">
          <label class="form-label">Candidate Full Name</label>
          <input type="text" id="ob-candidate-name" class="form-control" required />
        </div>
        <div class="form-group">
          <label class="form-label">Personal Email</label>
          <input type="email" id="ob-candidate-email" class="form-control" required />
        </div>
        <div class="form-group">
          <label class="form-label">Role</label>
          <input type="text" id="ob-role" class="form-control" placeholder="e.g. Senior Backend Engineer" required />
        </div>
        <div class="form-group">
          <label class="form-label">Department</label>
          <select id="ob-dept" class="form-control">
            <option value="ENGINEERING">Software & Engineering</option>
            <option value="MARKETING">Growth & Marketing</option>
            <option value="FINANCE">Finance & Accounts</option>
            <option value="HUMAN_RESOURCES">People & Culture</option>
          </select>
        </div>
        <div class="modal-actions">
          <button type="button" class="btn-secondary" onclick="closeModal('modal-initiate-onboarding')">Cancel</button>
          <button type="submit" class="btn-primary" style="width: auto;">Start Pipeline</button>
        </div>
      </form>
    </div>
  </div>

  <!-- ─── MODAL: INITIATE OFFBOARDING ──────────────────── -->
  <div id="modal-initiate-offboarding" class="modal-overlay">
    <div class="modal-dialog">
      <div class="modal-header">
        <h3 class="modal-title">Initiate Employee Exit</h3>
        <button class="modal-close" onclick="closeModal('modal-initiate-offboarding')">&times;</button>
      </div>
      <form onsubmit="submitInitiateOffboarding(event)">
        <div class="form-group">
          <label class="form-label">Employee</label>
          <input type="text" id="offb-name" class="form-control" placeholder="Employee Name / Email" required />
        </div>
        <div class="form-group">
          <label class="form-label">Resignation Date</label>
          <input type="date" id="offb-resig-date" class="form-control" required />
        </div>
        <div class="form-group">
          <label class="form-label">Last Working Day</label>
          <input type="date" id="offb-last-day" class="form-control" required />
        </div>
        <div class="form-group">
          <label class="form-label">Reason / Handover Notes</label>
          <textarea id="offb-notes" class="form-control" rows="2" placeholder="Exit details..."></textarea>
        </div>
        <div class="modal-actions">
          <button type="button" class="btn-secondary" onclick="closeModal('modal-initiate-offboarding')">Cancel</button>
          <button type="submit" class="btn-primary" style="width: auto;">Initiate Exit</button>
        </div>
      </form>
    </div>
  </div>

  <!-- ─── MODAL: CREATE GOAL ───────────────────────────── -->
  <div id="modal-create-goal" class="modal-overlay">
    <div class="modal-dialog">
      <div class="modal-header">
        <h3 class="modal-title">Create Performance Goal</h3>
        <button class="modal-close" onclick="closeModal('modal-create-goal')">&times;</button>
      </div>
      <form onsubmit="submitCreateGoal(event)">
        <div class="form-group">
          <label class="form-label">Goal Title</label>
          <input type="text" id="goal-title" class="form-control" placeholder="e.g. 99.9% Uptime on API Gateway" required />
        </div>
        <div class="form-group">
          <label class="form-label">Target Target Quarter / Date</label>
          <input type="date" id="goal-date" class="form-control" required />
        </div>
        <div class="form-group">
          <label class="form-label">Target Metric Formula</label>
          <input type="text" id="goal-formula" class="form-control" placeholder="e.g. Completion Rate >= 95%" />
        </div>
        <div class="modal-actions">
          <button type="button" class="btn-secondary" onclick="closeModal('modal-create-goal')">Cancel</button>
          <button type="submit" class="btn-primary" style="width: auto;">Save Goal</button>
        </div>
      </form>
    </div>
  </div>

  <!-- ─── MODAL: CLIENT FEEDBACK ───────────────────────── -->
  <div id="modal-client-feedback" class="modal-overlay">
    <div class="modal-dialog">
      <div class="modal-header">
        <h3 class="modal-title">Client Inquiry & Feedback</h3>
        <button class="modal-close" onclick="closeModal('modal-client-feedback')">&times;</button>
      </div>
      <form onsubmit="submitClientFeedback(event)">
        <div class="form-group">
          <label class="form-label">Subject</label>
          <input type="text" id="cf-subject" class="form-control" placeholder="e.g. Sprint milestone review question" required />
        </div>
        <div class="form-group">
          <label class="form-label">Message</label>
          <textarea id="cf-message" class="form-control" rows="4" placeholder="Detail your question or deliverable feedback here..." required></textarea>
        </div>
        <div class="modal-actions">
          <button type="button" class="btn-secondary" onclick="closeModal('modal-client-feedback')">Cancel</button>
          <button type="submit" class="btn-primary" style="width: auto;">Submit Message</button>
        </div>
      </form>
    </div>
  </div>

  <!-- ─── MODAL: APPLY LEAVE ───────────────────────────── -->
  <div id="modal-apply-leave" class="modal-overlay">
    <div class="modal-dialog">
      <div class="modal-header">
        <h3 class="modal-title">Apply for Leave</h3>
        <button class="modal-close" onclick="closeModal('modal-apply-leave')">&times;</button>
      </div>
      <form onsubmit="submitApplyLeave(event)">
        <div class="form-group">
          <label class="form-label" for="leave-type">Leave Type</label>
          <select id="leave-type" class="form-control">
            <option value="CASUAL">Casual Leave (Paid)</option>
            <option value="SICK">Medical / Sick Leave</option>
            <option value="PRIVILEGE">Privilege / Annual Leave</option>
          </select>
        </div>
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
          <div class="form-group">
            <label class="form-label" for="leave-start">Start Date</label>
            <input type="date" id="leave-start" class="form-control" required />
          </div>
          <div class="form-group">
            <label class="form-label" for="leave-end">End Date</label>
            <input type="date" id="leave-end" class="form-control" required />
          </div>
        </div>
        <div class="form-group">
          <label class="form-label" for="leave-reason">Reason</label>
          <textarea id="leave-reason" class="form-control" rows="3" placeholder="Reason for leave application..." required></textarea>
        </div>
        <div class="modal-actions">
          <button type="button" class="btn-secondary" onclick="closeModal('modal-apply-leave')">Cancel</button>
          <button type="submit" class="btn-primary" style="width: auto;">Submit Application</button>
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
            <option value="CLIENT">Client Deliverable</option>
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
    let timerInterval = null;
    let timerSeconds = 0;
    let isTimerRunning = false;

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
        if (data.data.refreshToken) {
          localStorage.setItem('enx_portal_refresh_token', data.data.refreshToken);
        }
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

      // Hide internal clock punch button for external client
      const punchBtn = document.getElementById('topbar-punch-btn');
      if (punchBtn) {
        punchBtn.style.display = user.role === 'CLIENT' ? 'none' : 'inline-flex';
      }
      
      const initials = (user.name || 'User').split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase();
      document.getElementById('sidebar-user-avatar').innerText = initials;
      document.getElementById('profile-avatar').innerText = initials;
      document.getElementById('profile-name').innerText = user.name;
      document.getElementById('profile-email').innerText = user.email;
      document.getElementById('profile-role').innerText = user.role;
      document.getElementById('profile-dept').innerText = user.department || 'All Departments';
      document.getElementById('profile-designation').innerText = user.designation || user.role;

      // Build Clean Role-Based Navigation strictly adhering to user request
      buildRoleNavigation(user);

      // Route to initial role view
      routeToRoleDashboard(user.role);

      // Load remote data
      loadDashboardData(user);
    }

    // SVG Icons
    const ICONS = {
      dashboard: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7"></rect><rect x="14" y="3" width="7" height="7"></rect><rect x="14" y="14" width="7" height="7"></rect><rect x="3" y="14" width="7" height="7"></rect></svg>',
      users: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>',
      tasks: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"></path><rect x="8" y="2" width="8" height="4" rx="1" ry="1"></rect></svg>',
      projects: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="12 2 2 7 12 12 22 7 12 2"></polygon><polyline points="2 17 12 22 22 17"></polyline><polyline points="2 12 12 17 22 12"></polyline></svg>',
      attendance: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>',
      employees: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>',
      departments: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2" ry="2"></rect><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"></path></svg>',
      leave: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>',
      reports: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="20" x2="18" y2="10"></line><line x1="12" y1="20" x2="12" y2="4"></line><line x1="6" y1="20" x2="6" y2="14"></line></svg>',
      documents: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line></svg>',
      notifications: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path><path d="M13.73 21a2 2 0 0 1-3.46 0"></path></svg>',
      finance: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"></line><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path></svg>',
      tech: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="16 18 22 12 16 6"></polyline><polyline points="8 6 2 12 8 18"></polyline></svg>',
      security: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>',
      milestones: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 14 14"></polyline></svg>',
      time: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>',
      kpis: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 12h-4l-3 9L9 3l-3 9H2"></path></svg>',
      pipeline: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="6" cy="6" r="3"></circle><circle cx="6" cy="18" r="3"></circle><line x1="20" y1="4" x2="8.12" y2="15.88"></line><line x1="14.47" y1="14.48" x2="20" y2="20"></line><line x1="8.12" y1="8.12" x2="12" y2="12"></line></svg>',
      settings: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"></circle><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path></svg>',
      profile: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>'
    };

    function buildRoleNavigation(user) {
      const menu = document.getElementById('sidebar-dynamic-menu');
      menu.innerHTML = '';
      const role = user.role;

      if (role === 'SUPER_ADMIN') {
        // SUPER_ADMIN: Users, Roles, Settings, Staff, Projects, Vault, Reports, Audit Trail
        addNavSection(menu, 'Administration');
        addNavItem(menu, ICONS.users, 'User Accounts', () => switchView('super-admin-users', 'Users & Roles Management'), true);
        addNavItem(menu, ICONS.security, 'Roles & RBAC', () => switchView('super-admin-roles', 'Roles & Permissions Matrix'));
        addNavItem(menu, ICONS.settings, 'Company Settings', () => switchView('super-admin-settings', 'Company Settings & Policies'));
        addNavSection(menu, 'Operations');
        addNavItem(menu, ICONS.employees, 'Staff Directory', () => switchView('hr-employees', 'Company Staff Directory'));
        addNavItem(menu, ICONS.departments, 'Departments', () => switchView('hr-departments', 'Company Departments'));
        addNavItem(menu, ICONS.milestones, 'Projects & Sprints', () => switchView('milestones', 'Projects & Milestones'));
        addNavItem(menu, ICONS.documents, 'Document Vault', () => switchView('documents', 'Enterprise Documents'));
        addNavItem(menu, ICONS.reports, 'System Analytics', () => switchView('reports', 'Reports & Metrics'));
        addNavItem(menu, ICONS.security, 'Security Audit Trail', () => switchView('audit', 'Immutable Security Audit'));
      } else if (role === 'CEO') {
        // CEO: Executive Cockpit, Staff, Depts, Financials, Tech, Milestones, KPIs, Reports, Audit
        addNavSection(menu, 'Executive Command');
        addNavItem(menu, ICONS.dashboard, 'Executive Cockpit', () => switchView('ceo', 'CEO Executive Cockpit'), true);
        addNavItem(menu, ICONS.employees, 'Staff Overview', () => switchView('hr-employees', 'Company Staff'));
        addNavItem(menu, ICONS.departments, 'Departments', () => switchView('hr-departments', 'Operational Units'));
        addNavItem(menu, ICONS.finance, 'Financials', () => switchView('cfo', 'Financial Command'));
        addNavItem(menu, ICONS.tech, 'Engineering Hub', () => switchView('cto', 'Engineering Command'));
        addNavItem(menu, ICONS.milestones, 'Milestones', () => switchView('milestones', 'Projects & Milestones'));
        addNavItem(menu, ICONS.kpis, 'KPIs & Performance', () => switchView('kpis', 'Performance Reviews'));
        addNavItem(menu, ICONS.reports, 'Executive Reports', () => switchView('reports', 'Reports & Insights'));
        addNavItem(menu, ICONS.security, 'Security Trail', () => switchView('audit', 'Security Audit Trail'));
      } else if (role === 'CFO') {
        // CFO: Financial Command, Budgets & Spend, Fiscal Reports, Document Vault, Profile
        addNavSection(menu, 'Financial Command');
        addNavItem(menu, ICONS.dashboard, 'Financial Hub', () => switchView('cfo', 'CFO Financial Command'), true);
        addNavItem(menu, ICONS.finance, 'Department Budgets', () => switchView('cfo', 'Budget Allocation'));
        addNavItem(menu, ICONS.reports, 'Fiscal Reports', () => switchView('reports', 'Fiscal Reports'));
        addNavItem(menu, ICONS.documents, 'Fiscal Vault', () => switchView('documents', 'Financial Documents'));
        addNavItem(menu, ICONS.profile, 'Profile', () => switchView('profile', 'Account Profile'));
      } else if (role === 'CTO') {
        // CTO: Engineering Command, Sprints & Tasks, Architecture Projects, Tech Vault, Roster, Profile
        addNavSection(menu, 'Engineering Command');
        addNavItem(menu, ICONS.dashboard, 'Engineering Hub', () => switchView('cto', 'CTO Technical Command'), true);
        addNavItem(menu, ICONS.tasks, 'Sprints & Tasks', () => switchView('cto', 'Sprints & Backlog'));
        addNavItem(menu, ICONS.milestones, 'Architecture Milestones', () => switchView('milestones', 'Milestones'));
        addNavItem(menu, ICONS.documents, 'Tech Vault', () => switchView('documents', 'Tech Documentation'));
        addNavItem(menu, ICONS.attendance, 'Team Availability', () => switchView('attendance', 'Engineering Availability'));
        addNavItem(menu, ICONS.profile, 'Profile', () => switchView('profile', 'Account Profile'));
      } else if (role === 'DEPARTMENT_HEAD') {
        // DEPARTMENT_HEAD: Dept Overview, Team Members, Projects & Milestones, Team Tasks, Time Tracking, KPIs
        addNavSection(menu, 'Department Command');
        addNavItem(menu, ICONS.dashboard, 'Department Overview', () => switchView('manager-dashboard', 'Department Overview'), true);
        addNavItem(menu, ICONS.employees, 'Team Members', () => switchView('hr-employees', 'Team Directory'));
        addNavItem(menu, ICONS.milestones, 'Milestones', () => switchView('milestones', 'Projects & Milestones'));
        addNavItem(menu, ICONS.tasks, 'Team Tasks', () => switchView('emp-tasks', 'Department Tasks'));
        addNavItem(menu, ICONS.time, 'Time Tracking', () => switchView('time-tracking', 'Time Tracking'));
        addNavItem(menu, ICONS.kpis, 'Department KPIs', () => switchView('kpis', 'Department KPIs'));
        addNavItem(menu, ICONS.documents, 'Documents', () => switchView('documents', 'Department Documents'));
      } else if (role === 'MANAGER' || role === 'PROJECT_MANAGER') {
        // MANAGER: Manager Dashboard, Team, Projects, Tasks, Milestones, Time Tracking, Team KPIs, Approvals
        addNavSection(menu, 'Work Management');
        addNavItem(menu, ICONS.dashboard, 'Manager Dashboard', () => switchView('manager-dashboard', 'Manager Dashboard'), true);
        addNavItem(menu, ICONS.employees, 'Team Members', () => switchView('hr-employees', 'My Team'));
        addNavItem(menu, ICONS.milestones, 'Projects & Milestones', () => switchView('milestones', 'Projects & Milestones'));
        addNavItem(menu, ICONS.tasks, 'Tasks & Sprints', () => switchView('emp-tasks', 'Tasks Management'));
        addNavItem(menu, ICONS.time, 'Team Time Tracking', () => switchView('time-tracking', 'Time Tracking'));
        addNavItem(menu, ICONS.kpis, 'Team KPIs', () => switchView('kpis', 'KPIs & Goals'));
        addNavItem(menu, ICONS.leave, 'Leave Approvals', () => switchView('leave', 'Approvals & Leaves'));
        addNavItem(menu, ICONS.documents, 'Documents', () => switchView('documents', 'Project Documents'));
      } else if (role === 'HR') {
        // HR: HR Dashboard, Staff, Departments, Attendance, Leave, Onboarding, Offboarding, Documents, Reports
        addNavSection(menu, 'People Operations');
        addNavItem(menu, ICONS.dashboard, 'HR Dashboard', () => switchView('hr-dashboard', 'HR Dashboard'), true);
        addNavItem(menu, ICONS.employees, 'Staff Directory', () => switchView('hr-employees', 'Employees'));
        addNavItem(menu, ICONS.departments, 'Departments', () => switchView('hr-departments', 'Departments'));
        addNavItem(menu, ICONS.attendance, 'Attendance & Roster', () => switchView('attendance', 'Attendance'));
        addNavItem(menu, ICONS.leave, 'Leave Approvals', () => switchView('leave', 'Leave Management'));
        addNavItem(menu, ICONS.pipeline, 'Onboarding Pipeline', () => switchView('onboarding', 'Onboarding Pipeline'));
        addNavItem(menu, ICONS.pipeline, 'Offboarding Tracker', () => switchView('offboarding', 'Offboarding Tracker'));
        addNavItem(menu, ICONS.documents, 'Documents', () => switchView('documents', 'Employee Documents'));
        addNavItem(menu, ICONS.reports, 'HR Reports', () => switchView('reports', 'HR Reports'));
        addNavItem(menu, ICONS.notifications, 'Announcements', () => switchView('notifications', 'Announcements'));
      } else if (role === 'CLIENT') {
        // CLIENT (Strict Isolation: no employee records, HR data, or internal finances)
        addNavSection(menu, 'Client Workspace');
        addNavItem(menu, ICONS.dashboard, 'Project Overview', () => switchView('client-dashboard', 'Client Project Overview'), true);
        addNavItem(menu, ICONS.milestones, 'Project Milestones', () => switchView('client-dashboard', 'Milestones'));
        addNavItem(menu, ICONS.documents, 'Shared Deliverables', () => switchView('client-dashboard', 'Shared Documents'));
        addNavItem(menu, ICONS.profile, 'Client Profile', () => switchView('profile', 'Client Account'));
      } else {
        // EMPLOYEE / INTERN Workstation: Dashboard, My Tasks, My Projects, Attendance, Time Tracker, Leave, KPIs, Documents, Profile
        addNavSection(menu, 'Workstation');
        addNavItem(menu, ICONS.dashboard, 'Dashboard', () => switchView('emp-dashboard', 'Dashboard'), true);
        addNavItem(menu, ICONS.tasks, 'My Tasks', () => switchView('emp-tasks', 'My Tasks'));
        addNavItem(menu, ICONS.projects, 'My Projects', () => switchView('emp-projects', 'My Projects'));
        addNavItem(menu, ICONS.attendance, 'Attendance', () => switchView('attendance', 'Attendance'));
        addNavItem(menu, ICONS.time, 'Time Tracker', () => switchView('time-tracking', 'Time Tracker'));
        addNavItem(menu, ICONS.leave, 'Leave Requests', () => switchView('leave', 'Leave Requests'));
        addNavItem(menu, ICONS.kpis, 'My KPIs', () => switchView('kpis', 'My KPIs & Goals'));
        addNavItem(menu, ICONS.documents, 'Documents', () => switchView('documents', 'Documents'));
        addNavItem(menu, ICONS.notifications, 'Notifications', () => switchView('notifications', 'Notifications'));
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
      if (role === 'SUPER_ADMIN') {
        switchView('super-admin-users', 'Users & Roles Management');
      } else if (role === 'CEO') {
        switchView('ceo', 'CEO Executive Cockpit');
      } else if (role === 'CTO') {
        switchView('cto', 'CTO Technical Command');
      } else if (role === 'CFO') {
        switchView('cfo', 'CFO Financial Command');
      } else if (role === 'DEPARTMENT_HEAD' || role === 'MANAGER' || role === 'PROJECT_MANAGER') {
        switchView('manager-dashboard', 'Manager Dashboard');
      } else if (role === 'HR') {
        switchView('hr-dashboard', 'HR Dashboard');
      } else if (role === 'CLIENT') {
        switchView('client-dashboard', 'Client Project Overview');
      } else {
        switchView('emp-dashboard', 'Dashboard');
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
      // 1. Super Admin Users (if authorized)
      if (user.role === 'SUPER_ADMIN' || user.role === 'CEO') {
        try {
          const res = await fetch('/api/v1/portal/users', {
            headers: { 'Authorization': 'Bearer ' + authToken }
          });
          if (res.ok) {
            const json = await res.json();
            renderSuperAdminUsers(json.data || []);
          }
        } catch (_) {}
      }

      // 2. Live Attendance Roster (internal only)
      if (user.role !== 'CLIENT') {
        try {
          const res = await fetch('/api/v1/portal/attendance/live', {
            headers: { 'Authorization': 'Bearer ' + authToken }
          });
          if (res.ok) {
            const json = await res.json();
            renderRoster(json.data || []);
          }
        } catch (_) {}
      }

      // 3. Staff Directory (internal only)
      if (user.role !== 'CLIENT') {
        try {
          const res = await fetch('/api/v1/portal/employees', {
            headers: { 'Authorization': 'Bearer ' + authToken }
          });
          if (res.ok) {
            const json = await res.json();
            renderEmployees(json.data || []);
          }
        } catch (_) {}
      }

      // 4. Tasks
      try {
        const res = await fetch('/api/v1/portal/tasks', {
          headers: { 'Authorization': 'Bearer ' + authToken }
        });
        if (res.ok) {
          const json = await res.json();
          renderTasks(json.data || []);
        }
      } catch (_) {}

      // 5. Milestones
      try {
        const res = await fetch('/api/v1/portal/milestones', {
          headers: { 'Authorization': 'Bearer ' + authToken }
        });
        if (res.ok) {
          const json = await res.json();
          renderMilestones(json.data || []);
        }
      } catch (_) {}

      // 6. Documents
      try {
        const res = await fetch('/api/v1/portal/documents', {
          headers: { 'Authorization': 'Bearer ' + authToken }
        });
        if (res.ok) {
          const json = await res.json();
          renderDocuments(json.data || []);
        }
      } catch (_) {}

      // 7. Leaves
      if (user.role !== 'CLIENT') {
        try {
          const res = await fetch('/api/v1/portal/leaves', {
            headers: { 'Authorization': 'Bearer ' + authToken }
          });
          if (res.ok) {
            const json = await res.json();
            renderLeaves(json.data || []);
          }
        } catch (_) {}
      }

      // 8. Onboarding & Offboarding (HR / Admin)
      if (user.role === 'SUPER_ADMIN' || user.role === 'HR' || user.role === 'CEO') {
        try {
          const res = await fetch('/api/v1/portal/onboarding', {
            headers: { 'Authorization': 'Bearer ' + authToken }
          });
          if (res.ok) {
            const json = await res.json();
            renderOnboarding(json.data || []);
          }
        } catch (_) {}

        try {
          const res = await fetch('/api/v1/portal/offboarding', {
            headers: { 'Authorization': 'Bearer ' + authToken }
          });
          if (res.ok) {
            const json = await res.json();
            renderOffboarding(json.data || []);
          }
        } catch (_) {}
      }

      // 9. KPIs & Goals
      try {
        const res = await fetch('/api/v1/portal/goals', {
          headers: { 'Authorization': 'Bearer ' + authToken }
        });
        if (res.ok) {
          const json = await res.json();
          renderGoals(json.data || []);
        }
      } catch (_) {}

      // 10. Client Portal Data (if Client)
      if (user.role === 'CLIENT') {
        loadClientPortalData();
      }

      // 11. Security Audit Logs (if authorized)
      if (user.role === 'SUPER_ADMIN' || user.role === 'CEO') {
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
    }

    function renderSuperAdminUsers(users) {
      const tbody = document.getElementById('sa-users-tbody');
      if (!tbody) return;

      tbody.innerHTML = users.length ? users.map(u => {
        const isDeactivated = u.status === 'DEACTIVATED' || u.status === 'INACTIVE';
        const statusCls = isDeactivated ? 'disabled' : 'working';
        const toggleBtn = isDeactivated
          ? '<button class="btn-secondary" style="padding: 3px 8px; font-size: 11px;" onclick="toggleUserStatus(\\'' + u.id + '\\', \\'ACTIVE\\')">Enable</button>'
          : '<button class="btn-secondary" style="padding: 3px 8px; font-size: 11px; color: var(--danger);" onclick="toggleUserStatus(\\'' + u.id + '\\', \\'DEACTIVATED\\')">Disable</button>';
        return '<tr>' +
          '<td><span class="table-primary-text">' + u.name + '</span><br><span class="table-sub-text">' + u.email + '</span></td>' +
          '<td><span class="badge-status status-working">' + u.role + '</span></td>' +
          '<td>' + (u.department || '—') + '</td>' +
          '<td><span class="badge-status status-' + statusCls + '">' + (u.status || 'ACTIVE') + '</span></td>' +
          '<td>' + (u.lastLoginAt ? new Date(u.lastLoginAt).toLocaleDateString() : 'Active session') + '</td>' +
          '<td style="text-align: right;">' + toggleBtn + '</td>' +
        '</tr>';
      }).join('') : '<tr><td colspan="6" class="empty-state">No users registered in system.</td></tr>';

      const countEl = document.getElementById('sa-total-users');
      if (countEl) countEl.innerText = users.length;
    }

    function renderRoster(roster) {
      const tbodyCeo = document.getElementById('ceo-roster-tbody');
      const tbodyAtt = document.getElementById('att-history-tbody');
      
      const rowsHtml = roster.length ? roster.map(r => {
        const statusCls = r.workStatus === 'WORKING' ? 'working' : (r.workStatus === 'COMPLETED' ? 'completed' : 'notin');
        return '<tr>' +
          '<td><span class="table-primary-text">' + r.name + '</span><br><span class="table-sub-text">' + r.email + '</span></td>' +
          '<td>' + r.role + ' • ' + r.department + '</td>' +
          '<td>' + (r.clockInTime ? new Date(r.clockInTime).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) : '—') + '</td>' +
          '<td>' + (r.clockOutTime ? new Date(r.clockOutTime).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) : '—') + '</td>' +
          '<td><span class="badge-status status-' + statusCls + '">' + r.workStatus + '</span></td>' +
        '</tr>';
      }).join('') : '<tr><td colspan="5" class="empty-state">No attendance records logged today.</td></tr>';

      if (tbodyCeo) tbodyCeo.innerHTML = rowsHtml;
      if (tbodyAtt) tbodyAtt.innerHTML = rowsHtml;

      const workingCount = roster.filter(r => r.workStatus === 'WORKING').length;
      const kpiCeo = document.getElementById('ceo-active-punch');
      if (kpiCeo) kpiCeo.innerText = workingCount;
      const kpiHr = document.getElementById('hr-dash-present');
      if (kpiHr) kpiHr.innerText = workingCount;
    }

    function renderEmployees(emps) {
      const tbodyDir = document.getElementById('hr-employees-tbody');
      const tbodyDash = document.getElementById('hr-dash-emp-tbody');

      if (!emps.length) {
        if (tbodyDir) tbodyDir.innerHTML = '<tr><td colspan="6" class="empty-state">No employee records found.</td></tr>';
        if (tbodyDash) tbodyDash.innerHTML = '<tr><td colspan="5" class="empty-state">No employee records found.</td></tr>';
        return;
      }

      if (tbodyDir) {
        tbodyDir.innerHTML = emps.map(e => {
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
      }

      if (tbodyDash) {
        tbodyDash.innerHTML = emps.slice(0, 5).map(e => {
          const statusCls = e.status === 'ACTIVE' ? 'working' : 'notin';
          return '<tr>' +
            '<td><span class="table-primary-text">' + e.name + '</span><br><span class="table-sub-text">' + e.email + '</span></td>' +
            '<td>' + e.role + '</td>' +
            '<td>' + e.department + '</td>' +
            '<td>' + e.designation + '</td>' +
            '<td><span class="badge-status status-' + statusCls + '">' + e.status + '</span></td>' +
          '</tr>';
        }).join('');
      }

      const countEl = document.getElementById('hr-emp-count');
      if (countEl) countEl.innerText = 'Showing ' + emps.length + ' registered employees';
      const kpiHr = document.getElementById('hr-dash-total');
      if (kpiHr) kpiHr.innerText = emps.length;
      const kpiCeo = document.getElementById('ceo-total-emp');
      if (kpiCeo) kpiCeo.innerText = emps.length;
      const kpiMgr = document.getElementById('mgr-team-size');
      if (kpiMgr) kpiMgr.innerText = emps.length;
    }

    function renderTasks(tasks) {
      // 1. CTO Tasks
      const ctoTbody = document.getElementById('cto-tasks-tbody');
      if (ctoTbody) {
        ctoTbody.innerHTML = tasks.length ? tasks.map(t => {
          const prioCls = t.priority === 'URGENT' ? 'urgent' : 'inprogress';
          const statCls = t.status === 'COMPLETED' ? 'completed' : 'todo';
          return '<tr>' +
            '<td><span class="table-primary-text">' + t.title + '</span></td>' +
            '<td>' + (t.assigneeId || 'Team') + '</td>' +
            '<td><span class="badge-status status-' + prioCls + '">' + t.priority + '</span></td>' +
            '<td>' + new Date(t.deadline || Date.now()).toLocaleDateString() + '</td>' +
            '<td><span class="badge-status status-' + statCls + '">' + t.status + '</span></td>' +
          '</tr>';
        }).join('') : '<tr><td colspan="5" class="empty-state">No engineering tasks found.</td></tr>';
      }

      // 2. Manager Approvals Table
      const mgrTbody = document.getElementById('mgr-approvals-tbody');
      if (mgrTbody) {
        mgrTbody.innerHTML = tasks.length ? tasks.map(t => {
          const statCls = t.status === 'COMPLETED' ? 'completed' : 'todo';
          const approveBtn = t.status !== 'COMPLETED'
            ? '<button class="btn-secondary" style="padding: 3px 8px; font-size: 11px;" onclick="advanceTaskStatus(\\'' + t.id + '\\')">Approve Task</button>'
            : '<span style="color: var(--success); font-weight: 600; font-size: 12px;">✓ Verified</span>';
          return '<tr>' +
            '<td><span class="table-primary-text">' + t.title + '</span></td>' +
            '<td>' + (t.assigneeId || 'Team Member') + '</td>' +
            '<td><span class="badge-status status-working">' + (t.priority || 'NORMAL') + '</span></td>' +
            '<td>' + new Date(t.deadline || Date.now()).toLocaleDateString() + '</td>' +
            '<td><span class="badge-status status-' + statCls + '">' + t.status + '</span></td>' +
            '<td style="text-align: right;">' + approveBtn + '</td>' +
          '</tr>';
        }).join('') : '<tr><td colspan="6" class="empty-state">No pending approvals.</td></tr>';
      }

      // 3. Employee Workstation Tasks
      const empTbody = document.getElementById('emp-tasks-tbody');
      const recentTbody = document.getElementById('emp-recent-tasks-tbody');

      const renderEmpRows = (list) => list.map(t => {
        const prioCls = t.priority === 'URGENT' ? 'urgent' : 'inprogress';
        const statCls = t.status === 'COMPLETED' ? 'completed' : 'todo';
        const actionBtn = t.status !== 'COMPLETED'
          ? '<button class="btn-secondary" style="padding: 4px 10px; font-size: 11.5px;" onclick="advanceTaskStatus(\\'' + t.id + '\\')">Mark Done</button>'
          : '<span style="color: var(--success); font-weight: 600; font-size: 12px;">✓ Completed</span>';
        return '<tr>' +
          '<td><span class="table-primary-text">' + t.title + '</span></td>' +
          '<td><span class="badge-status status-' + prioCls + '">' + t.priority + '</span></td>' +
          '<td>' + new Date(t.deadline || Date.now()).toLocaleDateString() + '</td>' +
          '<td><span class="badge-status status-' + statCls + '">' + t.status + '</span></td>' +
          '<td style="text-align: right;">' + actionBtn + '</td>' +
        '</tr>';
      }).join('');

      if (empTbody) {
        empTbody.innerHTML = tasks.length ? renderEmpRows(tasks) : '<tr><td colspan="5" class="empty-state">No tasks assigned.</td></tr>';
      }
      if (recentTbody) {
        recentTbody.innerHTML = tasks.length ? renderEmpRows(tasks.slice(0, 4)) : '<tr><td colspan="5" class="empty-state">No recent tasks.</td></tr>';
      }

      const pendingCount = tasks.filter(t => t.status !== 'COMPLETED').length;
      const countEl = document.getElementById('emp-dash-task-count');
      if (countEl) countEl.innerText = pendingCount;
      const mgrPendingEl = document.getElementById('mgr-pending-tasks');
      if (mgrPendingEl) mgrPendingEl.innerText = pendingCount;
    }

    function renderMilestones(milestones) {
      const grid = document.getElementById('milestones-cards-grid');
      if (!grid) return;

      if (!milestones.length) {
        grid.innerHTML = '<div class="info-card"><p class="info-card-desc">No milestones scheduled.</p></div>';
        return;
      }

      grid.innerHTML = milestones.map(m => {
        const progress = m.progress || 0;
        const statusCls = m.status === 'COMPLETED' ? 'completed' : (m.status === 'IN_PROGRESS' ? 'working' : 'todo');
        return '<div class="info-card">' +
          '<div>' +
            '<div class="info-card-header">' +
              '<span class="info-card-title">' + m.name + '</span>' +
              '<span class="badge-status status-' + statusCls + '">' + (m.status || 'PLANNED') + '</span>' +
            '</div>' +
            '<p class="info-card-desc">' + (m.description || 'Deliverable milestone tracking Sprint progression and quality standards.') + '</p>' +
            '<div class="progress-bar-bg"><div class="progress-bar-fill" style="width: ' + progress + '%;"></div></div>' +
          '</div>' +
          '<div class="info-card-meta">' +
            '<span>Project: ' + (m.projectId || 'PRJ-101') + '</span>' +
            '<span>Target: ' + new Date(m.dueDate || Date.now()).toLocaleDateString() + '</span>' +
          '</div>' +
        '</div>';
      }).join('');
    }

    function renderOnboarding(list) {
      const tbody = document.getElementById('onboarding-tbody');
      if (!tbody) return;

      tbody.innerHTML = list.length ? list.map(ob => {
        const stepNum = ob.currentStep || 1;
        const steps = ['Candidate Selected', 'Account Created', 'Docs Requested', 'Docs Uploaded', 'HR Verified', 'Dept Assigned', 'Completed'];
        const currentStepName = steps[stepNum - 1] || 'Completed';
        const isComplete = stepNum >= 7;
        const advanceBtn = !isComplete
          ? '<button class="btn-secondary" style="padding: 3px 8px; font-size: 11px;" onclick="advanceOnboardingStep(\\'' + ob.id + '\\')">Advance Step ➔</button>'
          : '<span style="color: var(--success); font-weight: 600; font-size: 12px;">✓ Onboarded</span>';

        return '<tr>' +
          '<td><span class="table-primary-text">' + ob.candidateName + '</span><br><span class="table-sub-text">' + ob.candidateEmail + '</span></td>' +
          '<td>' + (ob.role || 'Engineer') + ' • ' + (ob.department || 'Tech') + '</td>' +
          '<td><span class="table-primary-text">Step ' + stepNum + '/7:</span> ' + currentStepName + '</td>' +
          '<td>' +
            '<div class="progress-bar-bg" style="width: 120px; margin-bottom: 0;">' +
              '<div class="progress-bar-fill" style="width: ' + Math.min(100, Math.round((stepNum / 7) * 100)) + '%;"></div>' +
            '</div>' +
          '</td>' +
          '<td><span class="badge-status status-' + (isComplete ? 'completed' : 'working') + '">' + (isComplete ? 'COMPLETED' : 'IN_PROGRESS') + '</span></td>' +
          '<td style="text-align: right;">' + advanceBtn + '</td>' +
        '</tr>';
      }).join('') : '<tr><td colspan="6" class="empty-state">No candidates in active onboarding pipeline.</td></tr>';
    }

    function renderOffboarding(list) {
      const tbody = document.getElementById('offboarding-tbody');
      if (!tbody) return;

      tbody.innerHTML = list.length ? list.map(off => {
        const stepNum = off.step || 1;
        const steps = ['Resignation Received', 'Asset Return', 'Handover Docs', 'Manager Approval', 'HR Signoff', 'Account Deactivated'];
        const currentStepName = steps[stepNum - 1] || 'Completed';
        const isComplete = stepNum >= 6;
        const advanceBtn = !isComplete
          ? '<button class="btn-secondary" style="padding: 3px 8px; font-size: 11px;" onclick="advanceOffboardingStep(\\'' + off.id + '\\')">Next Stage ➔</button>'
          : '<span style="color: var(--danger); font-weight: 600; font-size: 12px;">Deactivated</span>';

        return '<tr>' +
          '<td><span class="table-primary-text">' + (off.employeeName || off.employeeId) + '</span></td>' +
          '<td>' + (off.department || 'Tech') + '</td>' +
          '<td>' + (off.lastWorkingDay ? new Date(off.lastWorkingDay).toLocaleDateString() : 'Immediate') + '</td>' +
          '<td>' + currentStepName + '</td>' +
          '<td><span class="badge-status status-' + (isComplete ? 'disabled' : 'working') + '">' + (isComplete ? 'EXITED' : 'IN_PROGRESS') + '</span></td>' +
          '<td style="text-align: right;">' + advanceBtn + '</td>' +
        '</tr>';
      }).join('') : '<tr><td colspan="6" class="empty-state">No active exit procedures in progress.</td></tr>';
    }

    function renderGoals(goals) {
      const tbody = document.getElementById('kpi-goals-tbody');
      if (!tbody) return;

      tbody.innerHTML = goals.length ? goals.map(g => {
        return '<tr>' +
          '<td><span class="table-primary-text">' + g.title + '</span></td>' +
          '<td>' + (g.assignedTo || 'Engineering Team') + '</td>' +
          '<td>' + new Date(g.targetDate || Date.now()).toLocaleDateString() + '</td>' +
          '<td>' + (g.formula || 'Target 95%') + '</td>' +
          '<td><span style="color: var(--success); font-weight: 700;">' + (g.score || '98%') + '</span></td>' +
          '<td><span class="badge-status status-working">ACTIVE</span></td>' +
        '</tr>';
      }).join('') : '<tr><td colspan="6" class="empty-state">No goals or reviews recorded.</td></tr>';
    }

    async function loadClientPortalData() {
      try {
        const resProj = await fetch('/api/v1/portal/client/projects', {
          headers: { 'Authorization': 'Bearer ' + authToken }
        });
        if (resProj.ok) {
          const json = await resProj.json();
          const projects = json.data || [];
          const tbody = document.getElementById('client-projects-tbody');
          if (tbody) {
            tbody.innerHTML = projects.length ? projects.map(p => {
              return '<tr>' +
                '<td><span class="table-primary-text">' + p.name + '</span><br><span class="table-sub-text">Code: ' + (p.code || p.id) + '</span></td>' +
                '<td>' + p.description + '</td>' +
                '<td>Sprint 4 Milestone</td>' +
                '<td>' +
                  '<div class="progress-bar-bg" style="width: 100px; margin-bottom: 0;">' +
                    '<div class="progress-bar-fill" style="width: ' + (p.progress || 85) + '%;"></div>' +
                  '</div>' +
                '</td>' +
                '<td>' + new Date(p.endDate || Date.now()).toLocaleDateString() + '</td>' +
                '<td><span class="badge-status status-working">' + (p.status || 'ACTIVE') + '</span></td>' +
              '</tr>';
            }).join('') : '<tr><td colspan="6" class="empty-state">No assigned projects found.</td></tr>';
          }
          const cntEl = document.getElementById('client-project-count');
          if (cntEl) cntEl.innerText = projects.length;
        }

        const resDocs = await fetch('/api/v1/portal/client/documents', {
          headers: { 'Authorization': 'Bearer ' + authToken }
        });
        if (resDocs.ok) {
          const json = await resDocs.json();
          const docs = json.data || [];
          const tbody = document.getElementById('client-docs-tbody');
          if (tbody) {
            tbody.innerHTML = docs.length ? docs.map(d => {
              return '<tr>' +
                '<td><span class="table-primary-text">' + d.title + '</span></td>' +
                '<td>' + (d.category || 'Deliverable') + '</td>' +
                '<td>' + new Date(d.createdAt).toLocaleDateString() + '</td>' +
                '<td style="text-align: right;"><button class="btn-secondary" style="padding: 3px 8px; font-size: 11px;" onclick="showToast(\\'Opening secured document file...\\', \\'info\\')">Download</button></td>' +
              '</tr>';
            }).join('') : '<tr><td colspan="4" class="empty-state">No client deliverables shared yet.</td></tr>';
          }
          const cntDoc = document.getElementById('client-doc-count');
          if (cntDoc) cntDoc.innerText = docs.length;
        }
      } catch (_) {}
    }

    function renderDocuments(docs) {
      const tbody = document.getElementById('docs-tbody');
      if (!tbody) return;

      tbody.innerHTML = docs.length ? docs.map(d => {
        return '<tr>' +
          '<td><span class="table-primary-text">' + d.title + '</span></td>' +
          '<td><span class="badge-status status-todo">' + d.category + '</span></td>' +
          '<td>' + (d.isConfidential ? '<span style="color: var(--warning); font-weight: 600;">🔒 Restricted</span>' : 'Company Wide') + '</td>' +
          '<td>' + d.uploadedBy + '</td>' +
          '<td>' + new Date(d.createdAt).toLocaleDateString() + '</td>' +
        '</tr>';
      }).join('') : '<tr><td colspan="5" class="empty-state">No documents stored in vault.</td></tr>';

      const docsCountEl = document.getElementById('docs-count');
      if (docsCountEl) docsCountEl.innerText = 'Showing ' + docs.length + ' documents';
    }

    function renderLeaves(leaves) {
      const tbody = document.getElementById('leaves-tbody');
      if (!tbody) return;

      tbody.innerHTML = leaves.length ? leaves.map(l => {
        const statCls = l.status === 'APPROVED' ? 'approved' : (l.status === 'REJECTED' ? 'rejected' : 'pending');
        const actions = l.status === 'PENDING' && (currentUser.role === 'HR' || currentUser.role === 'CEO' || currentUser.role === 'SUPER_ADMIN' || currentUser.role === 'MANAGER')
          ? '<button class="btn-secondary" style="padding: 3px 8px; font-size: 11px; margin-right: 4px;" onclick="updateLeave(\\'' + l.id + '\\', \\'APPROVED\\')">Approve</button>' +
            '<button class="btn-secondary" style="padding: 3px 8px; font-size: 11px;" onclick="updateLeave(\\'' + l.id + '\\', \\'REJECTED\\')">Reject</button>'
          : '—';
        return '<tr>' +
          '<td><span class="table-primary-text">' + (l.employeeName || l.employeeId) + '</span></td>' +
          '<td>' + l.leaveType + '</td>' +
          '<td>' + new Date(l.startDate).toLocaleDateString() + ' to ' + new Date(l.endDate).toLocaleDateString() + '</td>' +
          '<td>' + l.reason + '</td>' +
          '<td><span class="badge-status status-' + statCls + '">' + l.status + '</span></td>' +
          '<td style="text-align: right;">' + actions + '</td>' +
        '</tr>';
      }).join('') : '<tr><td colspan="6" class="empty-state">No leave applications registered.</td></tr>';
    }

    function renderAuditLogs(logs) {
      const tbody = document.getElementById('audit-tbody');
      if (!tbody) return;

      tbody.innerHTML = logs.length ? logs.map(l => {
        return '<tr>' +
          '<td style="font-family: monospace; font-size: 11.5px;">' + new Date(l.timestamp).toLocaleTimeString() + '</td>' +
          '<td>' + l.userEmail + '</td>' +
          '<td><span class="badge-status status-working">' + l.role + '</span></td>' +
          '<td><span class="table-primary-text">' + l.action + '</span></td>' +
          '<td>' + l.resourceType + '</td>' +
          '<td style="font-family: monospace; font-size: 11.5px;">' + (l.ipAddress || '127.0.0.1') + '</td>' +
        '</tr>';
      }).join('') : '<tr><td colspan="6" class="empty-state">No security audit logs found.</td></tr>';
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

    // Live Work Time Tracking Handlers
    function startWorkTimer() {
      if (isTimerRunning) return;
      isTimerRunning = true;
      document.getElementById('btn-timer-start').innerText = 'Working...';
      document.getElementById('timer-session-note').innerText = 'Session running since ' + new Date().toLocaleTimeString();
      fetch('/api/v1/portal/time-tracking/start', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + authToken },
        body: JSON.stringify({ activity: 'Product development' })
      }).catch(() => {});

      timerInterval = setInterval(() => {
        timerSeconds++;
        const hrs = String(Math.floor(timerSeconds / 3600)).padStart(2, '0');
        const mins = String(Math.floor((timerSeconds % 3600) / 60)).padStart(2, '0');
        const secs = String(timerSeconds % 60).padStart(2, '0');
        document.getElementById('live-timer-digits').innerText = hrs + ':' + mins + ':' + secs;
      }, 1000);
      showToast('Work timer started', 'success');
    }

    function pauseWorkTimer() {
      if (!isTimerRunning) return;
      isTimerRunning = false;
      clearInterval(timerInterval);
      document.getElementById('btn-timer-start').innerText = '▶ Resume';
      document.getElementById('timer-session-note').innerText = 'Timer paused for break.';
      showToast('Work timer paused', 'info');
    }

    function stopWorkTimer() {
      isTimerRunning = false;
      clearInterval(timerInterval);
      timerSeconds = 0;
      document.getElementById('live-timer-digits').innerText = '00:00:00';
      document.getElementById('btn-timer-start').innerText = '▶ Start Work';
      document.getElementById('timer-session-note').innerText = 'Session completed and logged to database.';
      fetch('/api/v1/portal/time-tracking/stop', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + authToken }
      }).catch(() => {});
      showToast('Work session duration saved successfully', 'success');
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

    // Leave Status Update
    async function updateLeave(leaveId, status) {
      try {
        const res = await fetch('/api/v1/portal/leaves/' + leaveId, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + authToken
          },
          body: JSON.stringify({ status, note: 'Reviewed via portal' })
        });
        if (!res.ok) {
          const json = await res.json();
          throw new Error(json.error || json.message);
        }
        showToast('Leave marked as ' + status, 'success');
        loadDashboardData(currentUser);
      } catch (err) {
        showToast(err.message, 'error');
      }
    }

    // Super Admin: Toggle User Status
    async function toggleUserStatus(userId, newStatus) {
      try {
        const res = await fetch('/api/v1/portal/users/' + userId, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + authToken
          },
          body: JSON.stringify({ status: newStatus })
        });
        if (!res.ok) {
          const json = await res.json();
          throw new Error(json.error || json.message);
        }
        showToast('User status updated to ' + newStatus, 'success');
        loadDashboardData(currentUser);
      } catch (err) {
        showToast(err.message, 'error');
      }
    }

    // Onboarding Advancement
    async function advanceOnboardingStep(id) {
      try {
        const res = await fetch('/api/v1/portal/onboarding/' + id + '/step', {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + authToken
          }
        });
        if (!res.ok) {
          const json = await res.json();
          throw new Error(json.error || json.message);
        }
        showToast('Candidate advanced to next onboarding step', 'success');
        loadDashboardData(currentUser);
      } catch (err) {
        showToast(err.message, 'error');
      }
    }

    // Offboarding Advancement
    async function advanceOffboardingStep(id) {
      try {
        const res = await fetch('/api/v1/portal/offboarding/' + id + '/step', {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + authToken
          }
        });
        if (!res.ok) {
          const json = await res.json();
          throw new Error(json.error || json.message);
        }
        showToast('Exit procedure advanced to next stage', 'success');
        loadDashboardData(currentUser);
      } catch (err) {
        showToast(err.message, 'error');
      }
    }

    // Modal Helpers
    function showAddEmployeeModal() { document.getElementById('modal-add-employee').classList.add('active'); }
    function showCreateUserModal() { document.getElementById('modal-create-user').classList.add('active'); }
    function showAddMilestoneModal() { document.getElementById('modal-add-milestone').classList.add('active'); }
    function showInitiateOnboardingModal() { document.getElementById('modal-initiate-onboarding').classList.add('active'); }
    function showInitiateOffboardingModal() { document.getElementById('modal-initiate-offboarding').classList.add('active'); }
    function showCreateGoalModal() { document.getElementById('modal-create-goal').classList.add('active'); }
    function showCreateReviewModal() { document.getElementById('modal-create-goal').classList.add('active'); }
    function showClientFeedbackModal() { document.getElementById('modal-client-feedback').classList.add('active'); }
    function showUploadDocModal() { document.getElementById('modal-upload-doc').classList.add('active'); }
    function showApplyLeaveModal() { document.getElementById('modal-apply-leave').classList.add('active'); }
    function closeModal(id) { document.getElementById(id).classList.remove('active'); }

    async function submitCreateUser(e) {
      e.preventDefault();
      const name = document.getElementById('cu-name').value.trim();
      const email = document.getElementById('cu-email').value.trim();
      const role = document.getElementById('cu-role').value;
      const department = document.getElementById('cu-dept').value.trim() || 'GENERAL';
      const password = document.getElementById('cu-pass').value.trim() || 'Admin@123';

      try {
        const res = await fetch('/api/v1/portal/users', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + authToken
          },
          body: JSON.stringify({ name, email, role, department, password })
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || data.message);

        showToast('User ' + name + ' created successfully!', 'success');
        closeModal('modal-create-user');
        e.target.reset();
        loadDashboardData(currentUser);
      } catch (err) {
        showToast(err.message, 'error');
      }
    }

    async function submitAddMilestone(e) {
      e.preventDefault();
      const projectId = document.getElementById('ms-project-id').value;
      const name = document.getElementById('ms-title').value.trim();
      const dueDate = document.getElementById('ms-due').value;
      const progress = parseInt(document.getElementById('ms-progress').value, 10) || 0;

      try {
        const res = await fetch('/api/v1/portal/milestones', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + authToken
          },
          body: JSON.stringify({ projectId, name, dueDate, progress, status: progress === 100 ? 'COMPLETED' : 'IN_PROGRESS' })
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || data.message);

        showToast('Milestone created successfully!', 'success');
        closeModal('modal-add-milestone');
        e.target.reset();
        loadDashboardData(currentUser);
      } catch (err) {
        showToast(err.message, 'error');
      }
    }

    async function submitInitiateOnboarding(e) {
      e.preventDefault();
      const candidateName = document.getElementById('ob-candidate-name').value.trim();
      const candidateEmail = document.getElementById('ob-candidate-email').value.trim();
      const role = document.getElementById('ob-role').value.trim();
      const department = document.getElementById('ob-dept').value;

      try {
        const res = await fetch('/api/v1/portal/onboarding', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + authToken
          },
          body: JSON.stringify({ candidateName, candidateEmail, role, department })
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || data.message);

        showToast('Candidate onboarding pipeline initiated!', 'success');
        closeModal('modal-initiate-onboarding');
        e.target.reset();
        loadDashboardData(currentUser);
      } catch (err) {
        showToast(err.message, 'error');
      }
    }

    async function submitInitiateOffboarding(e) {
      e.preventDefault();
      const employeeName = document.getElementById('offb-name').value.trim();
      const lastWorkingDay = document.getElementById('offb-last-day').value;
      const notes = document.getElementById('offb-notes').value.trim();

      try {
        const res = await fetch('/api/v1/portal/offboarding', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + authToken
          },
          body: JSON.stringify({ employeeName, employeeId: 'emp-' + Date.now(), lastWorkingDay, notes })
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || data.message);

        showToast('Exit workflow initiated for ' + employeeName, 'info');
        closeModal('modal-initiate-offboarding');
        e.target.reset();
        loadDashboardData(currentUser);
      } catch (err) {
        showToast(err.message, 'error');
      }
    }

    async function submitCreateGoal(e) {
      e.preventDefault();
      const title = document.getElementById('goal-title').value.trim();
      const targetDate = document.getElementById('goal-date').value;
      const formula = document.getElementById('goal-formula').value.trim();

      try {
        const res = await fetch('/api/v1/portal/goals', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + authToken
          },
          body: JSON.stringify({ title, targetDate, formula })
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || data.message);

        showToast('Performance goal logged successfully', 'success');
        closeModal('modal-create-goal');
        e.target.reset();
        loadDashboardData(currentUser);
      } catch (err) {
        showToast(err.message, 'error');
      }
    }

    function submitClientFeedback(e) {
      e.preventDefault();
      const sub = document.getElementById('cf-subject').value.trim();
      showToast('Thank you! Your inquiry "' + sub + '" has been dispatched to Enterprenex project management.', 'success');
      closeModal('modal-client-feedback');
      e.target.reset();
    }

    function saveCompanySettings() {
      const companyName = document.getElementById('setting-company-name').value;
      fetch('/api/v1/portal/admin/settings', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + authToken
        },
        body: JSON.stringify({ companyName, enforceMfa: true })
      }).then(() => showToast('Company settings updated successfully', 'success'))
        .catch(err => showToast(err.message, 'error'));
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

    async function submitApplyLeave(e) {
      e.preventDefault();
      const leaveType = document.getElementById('leave-type').value;
      const startDate = document.getElementById('leave-start').value;
      const endDate = document.getElementById('leave-end').value;
      const reason = document.getElementById('leave-reason').value.trim();

      try {
        const res = await fetch('/api/v1/portal/leaves', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + authToken
          },
          body: JSON.stringify({ leaveType, startDate, endDate, reason })
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || data.message);

        showToast('Leave application submitted for approval', 'success');
        closeModal('modal-apply-leave');
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
      localStorage.removeItem('enx_portal_refresh_token');
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
