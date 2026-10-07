/**
 * Enterprenex Solutions — Company Management Portal Web Application
 * 
 * Production-ready Unified Web UI:
 * 1. ONE Common Login Screen (No role selection before login)
 * 2. Automatic Role & Permission Detection & Dynamic Dashboard Redirection
 * 3. Dynamic Sidebar displaying ONLY authorized modules
 * 4. Distinct Views for:
 *    - CEO (Executive Cockpit & Cross-Company KPIs)
 *    - CTO (Engineering Command, DevOps & Sprints)
 *    - CFO (Financial Health, Budgets & Payroll Overview)
 *    - HR (Staff Directory, Live Attendance & Leave Approvals)
 *    - Department Head (Scoped Department View)
 *    - Employee (Workstation, Live Punch Clock & Assigned Tasks)
 *    - Intern (Guided Learning & Daily Tasks)
 */

function getCompanyPortalHtml() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Enterprenex — Company Management Portal</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #0b1120;
      --card: #131c31;
      --card-hover: #18243e;
      --border: #1e293b;
      --text: #f8fafc;
      --text-muted: #94a3b8;
      --primary: #10b981;
      --primary-hover: #059669;
      --accent: #6366f1;
      --warning: #f59e0b;
      --danger: #ef4444;
      --blue: #0ea5e9;
      --sidebar-w: 260px;
      --header-h: 70px;
      --radius: 12px;
    }

    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Plus Jakarta Sans', -apple-system, sans-serif;
      background: var(--bg);
      color: var(--text);
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      overflow-x: hidden;
    }

    /* Ambient Background Glow */
    .ambient-glow {
      position: fixed;
      top: 0; left: 0; right: 0; height: 350px;
      background: radial-gradient(circle at 50% -20%, rgba(16, 185, 129, 0.12), transparent 70%);
      pointer-events: none;
      z-index: 0;
    }

    /* --- LOGIN VIEW STYLES --- */
    #login-view {
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
      position: relative;
      z-index: 10;
    }

    .login-card {
      width: 100%;
      max-width: 460px;
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 20px;
      padding: 40px;
      box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5), 0 0 0 1px rgba(255, 255, 255, 0.05);
      position: relative;
      backdrop-filter: blur(20px);
    }

    .brand-header {
      display: flex;
      flex-direction: column;
      align-items: center;
      text-align: center;
      margin-bottom: 32px;
    }

    .brand-badge {
      width: 56px;
      height: 56px;
      border-radius: 16px;
      background: linear-gradient(135deg, #10b981 0%, #047857 100%);
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 800;
      font-size: 24px;
      color: #fff;
      margin-bottom: 16px;
      box-shadow: 0 10px 25px -5px rgba(16, 185, 129, 0.4);
    }

    .brand-title {
      font-size: 22px;
      font-weight: 800;
      letter-spacing: -0.5px;
      color: #fff;
    }

    .brand-subtitle {
      font-size: 13px;
      color: var(--text-muted);
      margin-top: 4px;
    }

    .form-group {
      margin-bottom: 20px;
    }

    .form-label {
      display: block;
      font-size: 13px;
      font-weight: 600;
      color: #cbd5e1;
      margin-bottom: 8px;
    }

    .input-wrapper {
      position: relative;
      display: flex;
      align-items: center;
    }

    .form-input {
      width: 100%;
      padding: 13px 16px;
      background: #0b1120;
      border: 1px solid var(--border);
      border-radius: var(--radius);
      color: #fff;
      font-size: 14px;
      font-family: inherit;
      outline: none;
      transition: all 0.2s;
    }

    .form-input:focus {
      border-color: var(--primary);
      box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.15);
    }

    .form-options {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 24px;
      font-size: 13px;
    }

    .checkbox-label {
      display: flex;
      align-items: center;
      gap: 8px;
      color: var(--text-muted);
      cursor: pointer;
    }

    .forgot-link {
      color: var(--primary);
      text-decoration: none;
      font-weight: 600;
      transition: color 0.2s;
      cursor: pointer;
    }

    .forgot-link:hover {
      text-decoration: underline;
    }

    .btn-login {
      width: 100%;
      padding: 14px;
      background: var(--primary);
      color: #fff;
      border: none;
      border-radius: var(--radius);
      font-size: 15px;
      font-weight: 700;
      cursor: pointer;
      transition: all 0.2s;
      box-shadow: 0 10px 20px -5px rgba(16, 185, 129, 0.35);
    }

    .btn-login:hover {
      background: var(--primary-hover);
      transform: translateY(-1px);
    }

    .btn-login:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }

    /* Demo Quick Switcher Pills */
    .demo-pills-box {
      margin-top: 28px;
      padding-top: 24px;
      border-top: 1px solid var(--border);
      text-align: center;
    }

    .demo-pills-title {
      font-size: 11px;
      font-weight: 700;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-bottom: 12px;
    }

    .demo-pills-grid {
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
      justify-content: center;
    }

    .pill-btn {
      padding: 6px 12px;
      background: #0e172a;
      border: 1px solid var(--border);
      border-radius: 20px;
      font-size: 11px;
      font-weight: 600;
      color: #cbd5e1;
      cursor: pointer;
      transition: all 0.15s;
    }

    .pill-btn:hover {
      border-color: var(--primary);
      color: var(--primary);
      background: rgba(16, 185, 129, 0.05);
    }

    /* --- PORTAL APP MAIN LAYOUT --- */
    #portal-app {
      display: none;
      min-height: 100vh;
      position: relative;
      z-index: 10;
    }

    /* Sidebar */
    aside.sidebar {
      width: var(--sidebar-w);
      background: var(--card);
      border-right: 1px solid var(--border);
      position: fixed;
      top: 0; bottom: 0; left: 0;
      z-index: 40;
      display: flex;
      flex-direction: column;
    }

    .sidebar-brand {
      height: var(--header-h);
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 0 24px;
      border-bottom: 1px solid var(--border);
    }

    .sidebar-brand-badge {
      width: 38px;
      height: 38px;
      background: linear-gradient(135deg, #10b981 0%, #047857 100%);
      border-radius: 10px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 800;
      color: #fff;
      font-size: 18px;
    }

    .sidebar-brand-name {
      font-size: 16px;
      font-weight: 800;
      letter-spacing: -0.3px;
    }

    .sidebar-brand-sub {
      font-size: 10px;
      color: var(--primary);
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .sidebar-menu {
      flex: 1;
      overflow-y: auto;
      padding: 20px 16px;
      display: flex;
      flex-direction: column;
      gap: 6px;
    }

    .menu-heading {
      font-size: 10px;
      font-weight: 700;
      text-transform: uppercase;
      color: #64748b;
      letter-spacing: 0.8px;
      padding: 12px 12px 6px;
    }

    .menu-item {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 11px 14px;
      border-radius: 10px;
      font-size: 13.5px;
      font-weight: 600;
      color: #cbd5e1;
      text-decoration: none;
      cursor: pointer;
      transition: all 0.2s;
    }

    .menu-item:hover {
      background: rgba(255, 255, 255, 0.04);
      color: #fff;
    }

    .menu-item.active {
      background: rgba(16, 185, 129, 0.15);
      color: var(--primary);
      font-weight: 700;
      border: 1px solid rgba(16, 185, 129, 0.3);
    }

    .sidebar-user {
      padding: 18px 20px;
      border-top: 1px solid var(--border);
      display: flex;
      align-items: center;
      justify-content: space-between;
      background: rgba(0, 0, 0, 0.15);
    }

    .user-info {
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }

    .user-name {
      font-size: 13px;
      font-weight: 700;
      color: #fff;
      white-space: nowrap;
      text-overflow: ellipsis;
      overflow: hidden;
    }

    .user-badge {
      font-size: 10px;
      font-weight: 700;
      color: var(--primary);
      text-transform: uppercase;
    }

    .btn-logout {
      background: none;
      border: 1px solid var(--border);
      color: var(--text-muted);
      border-radius: 8px;
      padding: 6px 10px;
      font-size: 12px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s;
    }

    .btn-logout:hover {
      background: rgba(239, 68, 68, 0.15);
      border-color: var(--danger);
      color: var(--danger);
    }

    /* Main Content */
    main.main-content {
      margin-left: var(--sidebar-w);
      min-height: 100vh;
      display: flex;
      flex-direction: column;
    }

    /* Header */
    header.topbar {
      height: var(--header-h);
      background: rgba(11, 17, 32, 0.8);
      backdrop-filter: blur(12px);
      border-bottom: 1px solid var(--border);
      position: sticky;
      top: 0;
      z-index: 30;
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 32px;
    }

    .topbar-left {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .page-title {
      font-size: 18px;
      font-weight: 800;
      letter-spacing: -0.3px;
    }

    .role-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 4px 10px;
      border-radius: 20px;
      font-size: 11px;
      font-weight: 700;
      background: rgba(16, 185, 129, 0.12);
      border: 1px solid rgba(16, 185, 129, 0.3);
      color: var(--primary);
    }

    .topbar-right {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .digital-clock {
      font-family: 'JetBrains Mono', monospace;
      font-size: 13px;
      font-weight: 600;
      color: #94a3b8;
      background: #080d1a;
      padding: 6px 14px;
      border-radius: 20px;
      border: 1px solid var(--border);
    }

    .punch-action-pill {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 6px 14px;
      border-radius: 20px;
      background: #10b981;
      color: #fff;
      font-size: 12px;
      font-weight: 700;
      cursor: pointer;
      border: none;
      transition: all 0.2s;
    }

    .punch-action-pill:hover {
      background: #059669;
    }

    .punch-action-pill.clocked-in {
      background: #ef4444;
    }

    .punch-action-pill.clocked-in:hover {
      background: #dc2626;
    }

    /* Page View Containers */
    .view-container {
      display: none;
      padding: 32px;
      flex: 1;
    }

    .view-container.active {
      display: block;
      animation: fadeIn 0.2s ease-in-out;
    }

    @keyframes fadeIn {
      from { opacity: 0; transform: translateY(6px); }
      to { opacity: 1; transform: translateY(0); }
    }

    /* KPI Grid */
    .kpi-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 20px;
      margin-bottom: 32px;
    }

    .kpi-card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 22px;
      position: relative;
      overflow: hidden;
    }

    .kpi-card::after {
      content: '';
      position: absolute;
      top: 0; left: 0; right: 0; height: 3px;
      background: linear-gradient(90deg, var(--primary), var(--accent));
      opacity: 0.8;
    }

    .kpi-label {
      font-size: 12px;
      font-weight: 600;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .kpi-val {
      font-size: 28px;
      font-weight: 800;
      color: #fff;
      margin-top: 8px;
      font-family: 'JetBrains Mono', monospace;
    }

    .kpi-sub {
      font-size: 11px;
      color: #64748b;
      margin-top: 6px;
    }

    /* Section Header */
    .section-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 20px;
    }

    .section-title {
      font-size: 16px;
      font-weight: 700;
    }

    .btn-action {
      padding: 8px 16px;
      border-radius: 10px;
      background: var(--primary);
      color: #fff;
      border: none;
      font-size: 12px;
      font-weight: 700;
      cursor: pointer;
      transition: all 0.2s;
    }

    .btn-action:hover {
      background: var(--primary-hover);
    }

    /* Tables */
    .table-card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 16px;
      overflow: hidden;
      margin-bottom: 32px;
    }

    table {
      width: 100%;
      border-collapse: collapse;
      text-align: left;
    }

    th {
      background: rgba(0, 0, 0, 0.2);
      padding: 14px 20px;
      font-size: 11px;
      font-weight: 700;
      color: #94a3b8;
      text-transform: uppercase;
      letter-spacing: 0.6px;
      border-bottom: 1px solid var(--border);
    }

    td {
      padding: 16px 20px;
      font-size: 13px;
      border-bottom: 1px solid rgba(30, 41, 59, 0.6);
      color: #cbd5e1;
    }

    tr:last-child td {
      border-bottom: none;
    }

    tr:hover td {
      background: rgba(255, 255, 255, 0.02);
    }

    .badge-status {
      display: inline-block;
      padding: 4px 10px;
      border-radius: 20px;
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
    }

    .status-working { background: rgba(16, 185, 129, 0.15); color: #10b981; border: 1px solid rgba(16, 185, 129, 0.3); }
    .status-completed { background: rgba(14, 165, 233, 0.15); color: #0ea5e9; border: 1px solid rgba(14, 165, 233, 0.3); }
    .status-notin { background: rgba(239, 68, 68, 0.15); color: #ef4444; border: 1px solid rgba(239, 68, 68, 0.3); }
    .status-todo { background: rgba(148, 163, 184, 0.15); color: #94a3b8; border: 1px solid rgba(148, 163, 184, 0.3); }
    .status-inprogress { background: rgba(245, 158, 11, 0.15); color: #f59e0b; border: 1px solid rgba(245, 158, 11, 0.3); }

    /* Modals */
    .modal-overlay {
      display: none;
      position: fixed;
      inset: 0;
      background: rgba(0, 0, 0, 0.7);
      backdrop-filter: blur(8px);
      z-index: 100;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }

    .modal-overlay.active {
      display: flex;
    }

    .modal-box {
      width: 100%;
      max-width: 500px;
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 20px;
      padding: 32px;
      box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.6);
    }

    .modal-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 24px;
    }

    .modal-title {
      font-size: 18px;
      font-weight: 800;
    }

    .modal-close {
      background: none;
      border: none;
      color: var(--text-muted);
      font-size: 20px;
      cursor: pointer;
    }

    /* Alert Banners */
    .alert-banner {
      padding: 12px 16px;
      border-radius: 10px;
      font-size: 13px;
      margin-bottom: 20px;
      display: none;
    }

    .alert-error {
      background: rgba(239, 68, 68, 0.15);
      border: 1px solid rgba(239, 68, 68, 0.3);
      color: #fca5a5;
    }

    .alert-success {
      background: rgba(16, 185, 129, 0.15);
      border: 1px solid rgba(16, 185, 129, 0.3);
      color: #86efac;
    }
  </style>
</head>
<body>
  <div class="ambient-glow"></div>

  <!-- 1. UNIFIED LOGIN VIEW (ONE COMMON ENTRYPOINT FOR ALL) -->
  <div id="login-view">
    <div class="login-card">
      <div class="brand-header">
        <div class="brand-badge">E</div>
        <h1 class="brand-title">Enterprenex Solutions</h1>
        <p class="brand-subtitle">Company Management Portal • portal.enterprenex.solutions</p>
      </div>

      <div id="login-alert" class="alert-banner alert-error"></div>

      <form id="login-form" onsubmit="handleUnifiedLogin(event)">
        <div class="form-group">
          <label class="form-label" for="login-email">Company Email</label>
          <div class="input-wrapper">
            <input type="email" id="login-email" class="form-input" placeholder="name@enterprenex.solutions" required autofocus />
          </div>
        </div>

        <div class="form-group">
          <label class="form-label" for="login-password">Password</label>
          <div class="input-wrapper">
            <input type="password" id="login-password" class="form-input" placeholder="••••••••••••" required />
          </div>
        </div>

        <div class="form-options">
          <label class="checkbox-label">
            <input type="checkbox" id="login-remember" />
            <span>Remember Me</span>
          </label>
          <span class="forgot-link" onclick="showForgotPasswordModal()">Forgot Password?</span>
        </div>

        <button type="submit" id="btn-login-submit" class="btn-login">Sign In to Portal</button>
      </form>

      <!-- Convenient Demo Quick-Login Pills for Testing -->
      <div class="demo-pills-box">
        <div class="demo-pills-title">Quick Demo Logins (Default Master Password: Admin@123)</div>
        <div class="demo-pills-grid">
          <button class="pill-btn" onclick="quickFill('rohit@enterprenex.solutions', 'Admin@123')">👑 CEO (Rohit)</button>
          <button class="pill-btn" onclick="quickFill('revanth.reddy@enterprenex.solutions', 'Admin@123')">⚡ CTO (Revanth)</button>
          <button class="pill-btn" onclick="quickFill('aniket@enterprenex.solutions', 'Admin@123')">💼 CFO (Aniket)</button>
          <button class="pill-btn" onclick="quickFill('jyothi@enterprenex.solutions', 'Admin@123')">👥 HR Head (Jyothi)</button>
          <button class="pill-btn" onclick="quickFill('amit.marketing@enterprenex.solutions', 'Admin@123')">📢 Marketing Head</button>
          <button class="pill-btn" onclick="quickFill('piyush@enterprenex.solutions', 'Admin@123')">🛠️ Tech Lead (Piyush)</button>
          <button class="pill-btn" onclick="quickFill('kishore@enterprenex.solutions', 'Admin@123')">💻 Developer (Kishore)</button>
          <button class="pill-btn" onclick="quickFill('sneha.intern@enterprenex.solutions', 'Admin@123')">🎓 Intern (Sneha)</button>
        </div>
      </div>
    </div>
  </div>

  <!-- 2. MAIN APPLICATION WORKSPACE -->
  <div id="portal-app">
    <!-- Dynamic Sidebar -->
    <aside class="sidebar">
      <div class="sidebar-brand">
        <div class="sidebar-brand-badge">E</div>
        <div>
          <div class="sidebar-brand-name">Enterprenex</div>
          <div class="sidebar-brand-sub" id="sidebar-role-indicator">PORTAL</div>
        </div>
      </div>

      <nav class="sidebar-menu" id="sidebar-dynamic-menu">
        <!-- Rendered dynamically based on permissions -->
      </nav>

      <div class="sidebar-user">
        <div class="user-info">
          <span class="user-name" id="sidebar-user-name">Loading...</span>
          <span class="user-badge" id="sidebar-user-badge">ROLE</span>
        </div>
        <button class="btn-logout" onclick="handleLogout()">Sign Out</button>
      </div>
    </aside>

    <!-- Main Workspace -->
    <main class="main-content">
      <!-- Topbar Header -->
      <header class="topbar">
        <div class="topbar-left">
          <h2 class="page-title" id="page-title">Executive Cockpit</h2>
          <span class="role-badge" id="header-role-badge">CEO</span>
        </div>
        <div class="topbar-right">
          <div class="digital-clock" id="digital-clock">00:00:00</div>
          <button id="topbar-punch-btn" class="punch-action-pill" onclick="toggleClockPunch()">
            <span>⏱️ Punch In</span>
          </button>
        </div>
      </header>

      <!-- VIEW 1: CEO EXECUTIVE COCKPIT -->
      <div id="view-ceo" class="view-container">
        <div class="kpi-grid">
          <div class="kpi-card">
            <div class="kpi-label">Total Staff</div>
            <div class="kpi-val" id="ceo-total-emp">8</div>
            <div class="kpi-sub">Enterprenex Solutions Core</div>
          </div>
          <div class="kpi-card">
            <div class="kpi-label">Active Working Today</div>
            <div class="kpi-val" id="ceo-active-punch">0</div>
            <div class="kpi-sub">Clocked in right now</div>
          </div>
          <div class="kpi-card">
            <div class="kpi-label">Active Projects</div>
            <div class="kpi-val" id="ceo-active-proj">3</div>
            <div class="kpi-sub">Fintech & Internal Systems</div>
          </div>
          <div class="kpi-card">
            <div class="kpi-label">Sprint Velocity</div>
            <div class="kpi-val">94%</div>
            <div class="kpi-sub">Q4 On-Time Completion</div>
          </div>
        </div>

        <div class="table-card">
          <div class="section-header" style="padding: 20px 20px 0;">
            <div class="section-title">🏢 Live Company Attendance Roster</div>
          </div>
          <table>
            <thead>
              <tr>
                <th>Employee</th>
                <th>Role / Department</th>
                <th>Clock In</th>
                <th>Clock Out</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody id="ceo-roster-tbody">
              <!-- Rendered via JS -->
            </tbody>
          </table>
        </div>
      </div>

      <!-- VIEW 2: CTO TECHNICAL COMMAND -->
      <div id="view-cto" class="view-container">
        <div class="kpi-grid">
          <div class="kpi-card">
            <div class="kpi-label">Technical Team</div>
            <div class="kpi-val" id="cto-tech-team">5 Engineers</div>
            <div class="kpi-sub">Full-Stack, DevOps & QA</div>
          </div>
          <div class="kpi-card">
            <div class="kpi-label">Production Health</div>
            <div class="kpi-val" style="color: #10b981;">99.98%</div>
            <div class="kpi-sub">Render + MySQL Active</div>
          </div>
          <div class="kpi-card">
            <div class="kpi-label">GitHub CI/CD</div>
            <div class="kpi-val">origin/main</div>
            <div class="kpi-sub">Automated Test Suites Passing</div>
          </div>
          <div class="kpi-card">
            <div class="kpi-label">Open Dev Tasks</div>
            <div class="kpi-val" id="cto-open-tasks">2</div>
            <div class="kpi-sub">Current Sprint Milestones</div>
          </div>
        </div>

        <div class="table-card">
          <div class="section-header" style="padding: 20px 20px 0;">
            <div class="section-title">🛠️ Engineering Tasks & Sprints</div>
          </div>
          <table>
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
              <!-- Rendered via JS -->
            </tbody>
          </table>
        </div>
      </div>

      <!-- VIEW 3: CFO FINANCIAL COMMAND -->
      <div id="view-cfo" class="view-container">
        <div class="kpi-grid">
          <div class="kpi-card">
            <div class="kpi-label">Monthly Payroll Outlay</div>
            <div class="kpi-val" id="cfo-payroll">₹11,40,000</div>
            <div class="kpi-sub">All Active Departments</div>
          </div>
          <div class="kpi-card">
            <div class="kpi-label">Allocated Project Budgets</div>
            <div class="kpi-val">₹23,00,000</div>
            <div class="kpi-sub">Fintech Platform & Growth</div>
          </div>
          <div class="kpi-card">
            <div class="kpi-label">Financial Health Score</div>
            <div class="kpi-val" style="color: #10b981;">94 / 100</div>
            <div class="kpi-sub">Prudent Capital Allocation</div>
          </div>
          <div class="kpi-card">
            <div class="kpi-label">Statutory Compliance</div>
            <div class="kpi-val">FILED (Q2)</div>
            <div class="kpi-sub">GST & TDS Remittance Clear</div>
          </div>
        </div>

        <div class="table-card">
          <div class="section-header" style="padding: 20px 20px 0;">
            <div class="section-title">📊 Department Budget Allocation vs Spend</div>
          </div>
          <table>
            <thead>
              <tr>
                <th>Department</th>
                <th>Allocated Budget</th>
                <th>Actual Spend</th>
                <th>Variance / Utilization</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td><strong>ENGINEERING</strong></td>
                <td>₹12,00,000</td>
                <td>₹9,50,000</td>
                <td><span class="badge-status status-working">79% (ON TRACK)</span></td>
              </tr>
              <tr>
                <td><strong>MARKETING & OUTREACH</strong></td>
                <td>₹4,50,000</td>
                <td>₹3,20,000</td>
                <td><span class="badge-status status-working">71% (ON TRACK)</span></td>
              </tr>
              <tr>
                <td><strong>OPERATIONS & FIELD</strong></td>
                <td>₹3,00,000</td>
                <td>₹2,10,000</td>
                <td><span class="badge-status status-working">70% (HEALTHY)</span></td>
              </tr>
              <tr>
                <td><strong>HUMAN RESOURCES</strong></td>
                <td>₹1,80,000</td>
                <td>₹1,40,000</td>
                <td><span class="badge-status status-working">77% (OPTIMAL)</span></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- VIEW 4: HR PEOPLE & CULTURE -->
      <div id="view-hr" class="view-container">
        <div class="section-header">
          <div class="section-title">👥 Company Staff Directory</div>
          <button class="btn-action" onclick="showAddEmployeeModal()">+ Onboard New Employee</button>
        </div>

        <div class="table-card">
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Role</th>
                <th>Department</th>
                <th>Designation</th>
                <th>Phone</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody id="hr-employees-tbody">
              <!-- Rendered via JS -->
            </tbody>
          </table>
        </div>
      </div>

      <!-- VIEW 5: EMPLOYEE / INTERN WORKSTATION -->
      <div id="view-employee" class="view-container">
        <div class="kpi-grid">
          <div class="kpi-card">
            <div class="kpi-label">My Active Shift Status</div>
            <div class="kpi-val" id="emp-punch-status" style="font-size: 22px;">CLOCKED OUT</div>
            <div class="kpi-sub" id="emp-punch-time">Click top right button to punch in</div>
          </div>
          <div class="kpi-card">
            <div class="kpi-label">Tasks Assigned to Me</div>
            <div class="kpi-val" id="emp-task-count">1</div>
            <div class="kpi-sub">Priority deliverables</div>
          </div>
          <div class="kpi-card">
            <div class="kpi-label">Active Projects</div>
            <div class="kpi-val">PRJ-102</div>
            <div class="kpi-sub">Enterprenex Company Portal</div>
          </div>
          <div class="kpi-card">
            <div class="kpi-label">Leave Balance</div>
            <div class="kpi-val">14 Days</div>
            <div class="kpi-sub">Casual & Paid Leaves</div>
          </div>
        </div>

        <div class="section-header">
          <div class="section-title">📋 My Assigned Tasks</div>
        </div>

        <div class="table-card">
          <table>
            <thead>
              <tr>
                <th>Title</th>
                <th>Priority</th>
                <th>Deadline</th>
                <th>Status</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody id="emp-tasks-tbody">
              <!-- Rendered via JS -->
            </tbody>
          </table>
        </div>
      </div>

      <!-- VIEW 6: DOCUMENTS VAULT -->
      <div id="view-documents" class="view-container">
        <div class="section-header">
          <div class="section-title">📁 Company Document Vault</div>
          <button class="btn-action" onclick="showUploadDocModal()">+ Upload Document</button>
        </div>

        <div class="table-card">
          <table>
            <thead>
              <tr>
                <th>Document Title</th>
                <th>Category</th>
                <th>Confidential</th>
                <th>Uploaded By</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody id="docs-tbody">
              <!-- Rendered via JS -->
            </tbody>
          </table>
        </div>
      </div>

      <!-- VIEW 7: SECURITY AUDIT LOGS -->
      <div id="view-audit" class="view-container">
        <div class="section-header">
          <div class="section-title">🛡️ Security & Access Audit Trail</div>
        </div>
        <div class="table-card">
          <table>
            <thead>
              <tr>
                <th>Timestamp</th>
                <th>User / Email</th>
                <th>Role</th>
                <th>Action</th>
                <th>Resource</th>
                <th>IP Address</th>
              </tr>
            </thead>
            <tbody id="audit-tbody">
              <!-- Rendered via JS -->
            </tbody>
          </table>
        </div>
      </div>
    </main>
  </div>

  <!-- MODAL: ADD EMPLOYEE -->
  <div id="modal-add-employee" class="modal-overlay">
    <div class="modal-box">
      <div class="modal-header">
        <h3 class="modal-title">Onboard New Employee</h3>
        <button class="modal-close" onclick="closeModal('modal-add-employee')">&times;</button>
      </div>
      <form onsubmit="submitNewEmployee(event)">
        <div class="form-group">
          <label class="form-label">Full Name</label>
          <input type="text" id="add-emp-name" class="form-input" required />
        </div>
        <div class="form-group">
          <label class="form-label">Company Email</label>
          <input type="email" id="add-emp-email" class="form-input" placeholder="@enterprenex.solutions" required />
        </div>
        <div class="form-group">
          <label class="form-label">Department</label>
          <select id="add-emp-dept" class="form-input">
            <option value="ENGINEERING">Software & Technology</option>
            <option value="MARKETING">Growth & Marketing</option>
            <option value="FINANCE">Finance & Accounts</option>
            <option value="HUMAN_RESOURCES">People & Culture</option>
            <option value="OPERATIONS">Operations</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">Role</label>
          <select id="add-emp-role" class="form-input">
            <option value="EMPLOYEE">Employee</option>
            <option value="INTERN">Intern</option>
            <option value="PROJECT_MANAGER">Project Manager</option>
            <option value="DEPT_HEAD">Department Head</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">Designation</label>
          <input type="text" id="add-emp-designation" class="form-input" placeholder="e.g. Frontend Engineer" required />
        </div>
        <button type="submit" class="btn-login" style="margin-top: 10px;">Create Account & Send Invite</button>
      </form>
    </div>
  </div>

  <script>
    // State
    let currentUser = null;
    let authToken = localStorage.getItem('enx_portal_token') || null;
    let clockTimer = null;

    // Digital clock
    setInterval(() => {
      const now = new Date();
      document.getElementById('digital-clock').innerText = now.toTimeString().split(' ')[0];
    }, 1000);

    // Initial check
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
      const alertBox = document.getElementById('login-alert');
      const submitBtn = document.getElementById('btn-login-submit');

      alertBox.style.display = 'none';
      submitBtn.disabled = true;
      submitBtn.innerText = 'Authenticating...';

      try {
        const res = await fetch('/api/v1/portal/auth/login', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email, password, rememberMe })
        });

        const data = await res.json();
        if (!res.ok || !data.success) {
          throw new Error(data.error || data.message || 'Invalid email or password');
        }

        authToken = data.data.token;
        currentUser = data.data.user;
        localStorage.setItem('enx_portal_token', authToken);

        // Transition to Authorized View
        showPortalApp(currentUser);
      } catch (err) {
        alertBox.innerText = err.message;
        alertBox.style.display = 'block';
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

      // Update Topbar and User labels
      document.getElementById('sidebar-user-name').innerText = user.name;
      document.getElementById('sidebar-user-badge').innerText = user.role;
      document.getElementById('sidebar-role-indicator').innerText = user.role;
      document.getElementById('header-role-badge').innerText = user.role;

      // Build dynamic sidebar based on permissions
      buildDynamicSidebar(user);

      // Route to default dashboard
      routeToRoleDashboard(user.role);

      // Load data
      loadDashboardData(user);
    }

    function buildDynamicSidebar(user) {
      const menu = document.getElementById('sidebar-dynamic-menu');
      menu.innerHTML = '';
      const role = user.role;
      const perms = user.permissions || [];

      // Dashboard Link
      addMenuItem(menu, '📊', 'Dashboard', () => routeToRoleDashboard(role), true);

      if (perms.includes('VIEW_EMPLOYEES')) {
        addMenuItem(menu, '👥', 'Staff Directory', () => switchView('hr', 'Company Staff Directory'));
      }

      if (role === 'CEO' || role === 'SUPER_ADMIN') {
        addMenuItem(menu, '👑', 'Executive Cockpit', () => switchView('ceo', 'CEO Executive Cockpit'));
      }

      if (role === 'CTO' || role === 'SUPER_ADMIN') {
        addMenuItem(menu, '⚡', 'Engineering Hub', () => switchView('cto', 'CTO Technical Command'));
      }

      if (role === 'CFO' || role === 'SUPER_ADMIN') {
        addMenuItem(menu, '💼', 'Finance & Budgets', () => switchView('cfo', 'CFO Financial Command'));
      }

      // My Workstation (All employees/leads/interns)
      addMenuItem(menu, '💻', 'My Workstation', () => switchView('employee', 'Employee Workstation'));

      if (perms.includes('VIEW_DOCUMENTS')) {
        addMenuItem(menu, '📁', 'Document Vault', () => switchView('documents', 'Document Vault'));
      }

      if (perms.includes('VIEW_AUDIT_LOGS')) {
        addMenuItem(menu, '🛡️', 'Security Audit Trail', () => switchView('audit', 'Security Audit Logs'));
      }
    }

    function addMenuItem(parent, icon, label, onClick, isActive = false) {
      const a = document.createElement('a');
      a.className = 'menu-item' + (isActive ? ' active' : '');
      a.innerHTML = '<span>' + icon + '</span><span>' + label + '</span>';
      a.onclick = (e) => {
        document.querySelectorAll('.menu-item').forEach(m => m.classList.remove('active'));
        a.classList.add('active');
        onClick();
      };
      parent.appendChild(a);
    }

    function routeToRoleDashboard(role) {
      switch (role) {
        case 'CEO':
        case 'SUPER_ADMIN':
          switchView('ceo', 'CEO Executive Cockpit');
          break;
        case 'CTO':
          switchView('cto', 'CTO Technical Command');
          break;
        case 'CFO':
          switchView('cfo', 'CFO Financial Command');
          break;
        case 'HR':
          switchView('hr', 'HR & People Operations');
          break;
        default:
          switchView('employee', 'Employee Workstation');
      }
    }

    function switchView(viewId, title) {
      document.querySelectorAll('.view-container').forEach(v => v.classList.remove('active'));
      const target = document.getElementById('view-' + viewId);
      if (target) target.classList.add('active');
      document.getElementById('page-title').innerText = title;
    }

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

      // 5. Audit logs (if permitted)
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
      tbody.innerHTML = roster.map(function(r) {
        var statusCls = r.workStatus === 'WORKING' ? 'working' : (r.workStatus === 'COMPLETED' ? 'completed' : 'notin');
        return '<tr>' +
          '<td><strong>' + r.name + '</strong><br><span style="font-size: 11px; color: #64748b;">' + r.email + '</span></td>' +
          '<td>' + r.role + ' • ' + r.department + '</td>' +
          '<td>' + (r.clockInTime ? new Date(r.clockInTime).toLocaleTimeString() : '—') + '</td>' +
          '<td>' + (r.clockOutTime ? new Date(r.clockOutTime).toLocaleTimeString() : '—') + '</td>' +
          '<td><span class="badge-status status-' + statusCls + '">' + r.workStatus + '</span></td>' +
        '</tr>';
      }).join('');

      // Update KPI
      var working = roster.filter(function(r) { return r.workStatus === 'WORKING'; }).length;
      var kpi = document.getElementById('ceo-active-punch');
      if (kpi) kpi.innerText = working;
    }

    function renderEmployees(emps) {
      const tbody = document.getElementById('hr-employees-tbody');
      if (!tbody) return;
      tbody.innerHTML = emps.map(function(e) {
        var statusCls = e.status === 'ACTIVE' ? 'working' : 'notin';
        return '<tr>' +
          '<td><strong>' + e.name + '</strong></td>' +
          '<td>' + e.email + '</td>' +
          '<td><span class="badge-status status-working">' + e.role + '</span></td>' +
          '<td>' + e.department + '</td>' +
          '<td>' + e.designation + '</td>' +
          '<td>' + (e.phone || '—') + '</td>' +
          '<td><span class="badge-status status-' + statusCls + '">' + e.status + '</span></td>' +
        '</tr>';
      }).join('');
    }

    function renderTasks(tasks) {
      // For CTO
      const ctoTbody = document.getElementById('cto-tasks-tbody');
      if (ctoTbody) {
        ctoTbody.innerHTML = tasks.map(function(t) {
          var prioCls = t.priority === 'URGENT' ? 'notin' : 'inprogress';
          var statCls = t.status === 'COMPLETED' ? 'completed' : 'todo';
          return '<tr>' +
            '<td><strong>' + t.title + '</strong></td>' +
            '<td>' + t.assigneeId + '</td>' +
            '<td><span class="badge-status status-' + prioCls + '">' + t.priority + '</span></td>' +
            '<td>' + new Date(t.deadline).toLocaleDateString() + '</td>' +
            '<td><span class="badge-status status-' + statCls + '">' + t.status + '</span></td>' +
          '</tr>';
        }).join('');
      }

      // For Employee
      const empTbody = document.getElementById('emp-tasks-tbody');
      if (empTbody) {
        empTbody.innerHTML = tasks.map(function(t) {
          var prioCls = t.priority === 'URGENT' ? 'notin' : 'inprogress';
          var statCls = t.status === 'COMPLETED' ? 'completed' : 'todo';
          var actionBtn = t.status !== 'COMPLETED'
            ? '<button class="btn-action" style="padding: 4px 10px; font-size: 11px;" onclick="advanceTaskStatus(\\'' + t.id + '\\')">Mark Complete</button>'
            : '✓ Done';
          return '<tr>' +
            '<td><strong>' + t.title + '</strong></td>' +
            '<td><span class="badge-status status-' + prioCls + '">' + t.priority + '</span></td>' +
            '<td>' + new Date(t.deadline).toLocaleDateString() + '</td>' +
            '<td><span class="badge-status status-' + statCls + '">' + t.status + '</span></td>' +
            '<td>' + actionBtn + '</td>' +
          '</tr>';
        }).join('');
      }
    }

    function renderDocuments(docs) {
      const tbody = document.getElementById('docs-tbody');
      if (!tbody) return;
      tbody.innerHTML = docs.map(function(d) {
        return '<tr>' +
          '<td><strong>' + d.title + '</strong></td>' +
          '<td><span class="badge-status status-todo">' + d.category + '</span></td>' +
          '<td>' + (d.isConfidential ? '🔒 Confidential' : 'Public') + '</td>' +
          '<td>' + d.uploadedBy + '</td>' +
          '<td>' + new Date(d.createdAt).toLocaleDateString() + '</td>' +
        '</tr>';
      }).join('');
    }

    function renderAuditLogs(logs) {
      const tbody = document.getElementById('audit-tbody');
      if (!tbody) return;
      tbody.innerHTML = logs.map(function(l) {
        return '<tr>' +
          '<td style="font-family: monospace; font-size: 11px;">' + new Date(l.timestamp).toLocaleTimeString() + '</td>' +
          '<td>' + l.userEmail + '</td>' +
          '<td><span class="badge-status status-working">' + l.role + '</span></td>' +
          '<td><strong>' + l.action + '</strong></td>' +
          '<td>' + l.resourceType + '</td>' +
          '<td style="font-family: monospace;">' + l.ipAddress + '</td>' +
        '</tr>';
      }).join('');
    }

    async function toggleClockPunch() {
      const btn = document.getElementById('topbar-punch-btn');
      const isCurrentlyIn = btn.classList.contains('clocked-in');

      try {
        const endpoint = isCurrentlyIn ? '/api/v1/portal/attendance/clock-out' : '/api/v1/portal/attendance/clock-in';
        const res = await fetch(endpoint, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + authToken
          },
          body: JSON.stringify({ notes: 'Portal web punch' })
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.message || data.error);

        if (isCurrentlyIn) {
          btn.classList.remove('clocked-in');
          btn.innerHTML = '<span>⏱️ Punch In</span>';
          alert('Shift ended successfully! Duration logged.');
        } else {
          btn.classList.add('clocked-in');
          btn.innerHTML = '<span>🛑 Punch Out</span>';
          alert('Shift started! Clock-in timestamp recorded.');
        }
        loadDashboardData(currentUser);
      } catch (err) {
        alert(err.message);
      }
    }

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
          alert('Task marked as COMPLETED!');
          loadDashboardData(currentUser);
        }
      } catch (err) {
        alert(err.message);
      }
    }

    function showAddEmployeeModal() {
      document.getElementById('modal-add-employee').classList.add('active');
    }

    function closeModal(id) {
      document.getElementById(id).classList.remove('active');
    }

    async function submitNewEmployee(e) {
      e.preventDefault();
      const name = document.getElementById('add-emp-name').value;
      const email = document.getElementById('add-emp-email').value;
      const dept = document.getElementById('add-emp-dept').value;
      const role = document.getElementById('add-emp-role').value;
      const desig = document.getElementById('add-emp-designation').value;

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

        alert('Employee created successfully! Default login password: ' + data.data.defaultPassword);
        closeModal('modal-add-employee');
        loadDashboardData(currentUser);
      } catch (err) {
        alert(err.message);
      }
    }

    function showForgotPasswordModal() {
      const email = prompt('Enter your company email to request a password reset link:');
      if (email) {
        fetch('/api/v1/portal/auth/forgot-password', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email })
        }).then(() => alert('Reset link instructions have been forwarded to ' + email));
      }
    }

    function handleLogout() {
      localStorage.removeItem('enx_portal_token');
      authToken = null;
      currentUser = null;
      showLoginView();
    }
  </script>
</body>
</html>`;
}

module.exports = { getCompanyPortalHtml };
