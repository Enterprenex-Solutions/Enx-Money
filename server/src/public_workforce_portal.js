/**
 * Enterprenex Solutions — Workforce & Task Management Web Portal
 * Interactive role-based dashboard for Clock-in/Clock-out attendance,
 * task assignments, and executive visibility across CEO, CTO, CFO, HR, Leads & Staff.
 */

function getWorkforcePortalHtml() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Enterprenex Workforce — Task & Attendance Portal</title>
  <link rel="icon" type="image/png" href="/enterprenex-badge.png">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #090d16;
      --card: #111726;
      --card-hover: #161e31;
      --card-border: #1e293b;
      --text: #f8fafc;
      --text-muted: #94a3b8;
      --primary: #10b981;
      --primary-glow: rgba(16, 185, 129, 0.2);
      --accent: #6366f1;
      --warning: #f59e0b;
      --danger: #ef4444;
      --blue: #0ea5e9;
      --radius: 14px;
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

    /* Background Glow */
    .bg-ambient {
      position: fixed;
      top: 0; left: 0; right: 0; height: 350px;
      background: radial-gradient(circle at 50% -20%, rgba(99, 102, 241, 0.15), transparent 70%);
      pointer-events: none;
      z-index: 0;
    }

    /* Header */
    header {
      position: sticky;
      top: 0;
      z-index: 50;
      background: rgba(9, 13, 22, 0.85);
      backdrop-filter: blur(16px);
      border-bottom: 1px solid var(--card-border);
      padding: 16px 28px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
    }

    .brand {
      display: flex;
      align-items: center;
      gap: 12px;
      text-decoration: none;
      color: var(--text);
    }

    .brand-logo {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      background: #ffffff;
      padding: 2px;
      object-fit: contain;
      box-shadow: 0 0 15px rgba(16, 185, 129, 0.3);
    }

    .brand-info h1 {
      font-size: 16px;
      font-weight: 800;
      letter-spacing: 0.5px;
      background: linear-gradient(135deg, #fff, #cbd5e1);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }

    .brand-info p {
      font-size: 12px;
      color: var(--text-muted);
      letter-spacing: 0.2px;
    }

    .header-actions {
      display: flex;
      align-items: center;
      gap: 14px;
    }

    .role-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 6px 14px;
      border-radius: 9999px;
      font-size: 12px;
      font-weight: 700;
      background: rgba(99, 102, 241, 0.15);
      color: #a5b4fc;
      border: 1px solid rgba(99, 102, 241, 0.3);
    }

    .role-badge.ceo { background: rgba(245, 158, 11, 0.15); color: #fde047; border-color: rgba(245, 158, 11, 0.3); }
    .role-badge.cto { background: rgba(14, 165, 233, 0.15); color: #7dd3fc; border-color: rgba(14, 165, 233, 0.3); }
    .role-badge.cfo { background: rgba(16, 185, 129, 0.15); color: #6ee7b7; border-color: rgba(16, 185, 129, 0.3); }
    .role-badge.hr { background: rgba(236, 72, 153, 0.15); color: #f472b6; border-color: rgba(236, 72, 153, 0.3); }

    .user-pill {
      display: flex;
      align-items: center;
      gap: 10px;
      background: var(--card);
      border: 1px solid var(--card-border);
      padding: 6px 14px;
      border-radius: 10px;
      cursor: pointer;
      transition: all 0.2s;
    }

    .user-pill:hover { border-color: var(--accent); }

    .user-avatar {
      width: 28px;
      height: 28px;
      border-radius: 50%;
      background: #334155;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 12px;
      font-weight: 700;
      color: #fff;
    }

    .clock-display {
      font-family: 'JetBrains Mono', monospace;
      font-size: 13px;
      color: var(--text-muted);
      background: rgba(15, 23, 42, 0.6);
      padding: 6px 12px;
      border-radius: 8px;
      border: 1px solid var(--card-border);
    }

    /* Container */
    .container {
      max-width: 1380px;
      margin: 0 auto;
      padding: 24px 20px 48px;
      width: 100%;
      position: relative;
      z-index: 10;
    }

    /* Top Grid: Punch Clock & Executive Metrics */
    .top-grid {
      display: grid;
      grid-template-columns: 360px 1fr;
      gap: 20px;
      margin-bottom: 24px;
    }

    @media (max-width: 960px) {
      .top-grid { grid-template-columns: 1fr; }
    }

    /* Card */
    .card {
      background: var(--card);
      border: 1px solid var(--card-border);
      border-radius: var(--radius);
      padding: 24px;
      position: relative;
      box-shadow: 0 4px 24px -2px rgba(0, 0, 0, 0.4);
    }

    /* Punch Clock Card */
    .punch-card {
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      border-top: 3px solid var(--primary);
    }

    .punch-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 16px;
    }

    .punch-status {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      font-size: 13px;
      font-weight: 700;
      padding: 4px 12px;
      border-radius: 9999px;
    }

    .punch-status.working {
      background: rgba(16, 185, 129, 0.15);
      color: #34d399;
      border: 1px solid rgba(16, 185, 129, 0.3);
    }

    .punch-status.stopped {
      background: rgba(239, 68, 68, 0.15);
      color: #f87171;
      border: 1px solid rgba(239, 68, 68, 0.3);
    }

    .pulse-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: currentColor;
      box-shadow: 0 0 10px currentColor;
    }

    .timer-val {
      font-family: 'JetBrains Mono', monospace;
      font-size: 42px;
      font-weight: 700;
      color: #fff;
      letter-spacing: -1px;
      margin: 12px 0 6px;
    }

    .timer-label {
      font-size: 13px;
      color: var(--text-muted);
      margin-bottom: 20px;
    }

    .punch-btn {
      width: 100%;
      padding: 14px;
      border-radius: 10px;
      font-size: 15px;
      font-weight: 700;
      border: none;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .punch-btn.in {
      background: linear-gradient(135deg, #10b981, #059669);
      color: #fff;
      box-shadow: 0 4px 20px rgba(16, 185, 129, 0.35);
    }

    .punch-btn.in:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 24px rgba(16, 185, 129, 0.5);
    }

    .punch-btn.out {
      background: linear-gradient(135deg, #ef4444, #dc2626);
      color: #fff;
      box-shadow: 0 4px 20px rgba(239, 68, 68, 0.35);
    }

    .punch-btn.out:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 24px rgba(239, 68, 68, 0.5);
    }

    .punch-meta {
      margin-top: 16px;
      padding-top: 16px;
      border-top: 1px solid var(--card-border);
      display: flex;
      justify-content: space-between;
      font-size: 12px;
      color: var(--text-muted);
    }

    /* Executive Metrics Grid */
    .metrics-grid {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 16px;
    }

    @media (max-width: 1180px) {
      .metrics-grid { grid-template-columns: repeat(2, 1fr); }
    }

    .metric-card {
      background: rgba(17, 23, 38, 0.7);
      border: 1px solid var(--card-border);
      border-radius: 12px;
      padding: 18px;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
    }

    .metric-title {
      font-size: 12px;
      color: var(--text-muted);
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      display: flex;
      align-items: center;
      gap: 6px;
    }

    .metric-value {
      font-size: 28px;
      font-weight: 800;
      margin: 10px 0 4px;
      color: #fff;
    }

    .metric-foot {
      font-size: 12px;
      color: var(--text-muted);
    }

    /* Nav Tabs */
    .nav-tabs {
      display: flex;
      align-items: center;
      gap: 8px;
      border-bottom: 1px solid var(--card-border);
      margin-bottom: 24px;
      padding-bottom: 12px;
      overflow-x: auto;
    }

    .tab-btn {
      background: transparent;
      border: 1px solid transparent;
      color: var(--text-muted);
      font-size: 14px;
      font-weight: 600;
      padding: 10px 20px;
      border-radius: 10px;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 8px;
      transition: all 0.2s;
      white-space: nowrap;
    }

    .tab-btn:hover {
      color: var(--text);
      background: rgba(255, 255, 255, 0.04);
    }

    .tab-btn.active {
      color: #fff;
      background: var(--card);
      border-color: var(--card-border);
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
    }

    .tab-btn .badge-pill {
      background: var(--accent);
      color: #fff;
      font-size: 11px;
      padding: 2px 8px;
      border-radius: 9999px;
      font-weight: 700;
    }

    /* Tab Sections */
    .tab-pane { display: none; }
    .tab-pane.active { display: block; }

    /* Task Kanban / Cards Grid */
    .tasks-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(360px, 1fr));
      gap: 20px;
    }

    .task-card {
      background: var(--card);
      border: 1px solid var(--card-border);
      border-radius: var(--radius);
      padding: 20px;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      gap: 16px;
      transition: all 0.2s;
    }

    .task-card:hover {
      border-color: rgba(99, 102, 241, 0.4);
      transform: translateY(-2px);
      box-shadow: 0 8px 30px rgba(0, 0, 0, 0.3);
    }

    .task-top {
      display: flex;
      align-items: flex-start;
      justify-content: space-between;
      gap: 12px;
    }

    .priority-badge {
      font-size: 11px;
      font-weight: 800;
      text-transform: uppercase;
      padding: 3px 8px;
      border-radius: 6px;
      letter-spacing: 0.5px;
    }

    .priority-URGENT { background: rgba(239, 68, 68, 0.2); color: #f87171; border: 1px solid rgba(239, 68, 68, 0.4); }
    .priority-HIGH { background: rgba(245, 158, 11, 0.2); color: #fbbf24; border: 1px solid rgba(245, 158, 11, 0.4); }
    .priority-MEDIUM { background: rgba(99, 102, 241, 0.2); color: #a5b4fc; border: 1px solid rgba(99, 102, 241, 0.4); }
    .priority-LOW { background: rgba(148, 163, 184, 0.2); color: #cbd5e1; border: 1px solid rgba(148, 163, 184, 0.4); }

    .status-select {
      background: #090d16;
      border: 1px solid var(--card-border);
      color: #fff;
      font-size: 12px;
      font-weight: 600;
      padding: 4px 8px;
      border-radius: 6px;
      cursor: pointer;
    }

    .task-title {
      font-size: 15px;
      font-weight: 700;
      color: #fff;
      line-height: 1.4;
      margin-bottom: 8px;
    }

    .task-desc {
      font-size: 13px;
      color: var(--text-muted);
      line-height: 1.5;
    }

    .task-foot {
      padding-top: 14px;
      border-top: 1px solid rgba(255, 255, 255, 0.06);
      display: flex;
      align-items: center;
      justify-content: space-between;
      font-size: 12px;
      color: var(--text-muted);
    }

    .task-assignee {
      display: flex;
      align-items: center;
      gap: 6px;
      font-weight: 600;
      color: #e2e8f0;
    }

    /* Assign Task Modal / Form */
    .form-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
    }

    @media (max-width: 700px) {
      .form-grid { grid-template-columns: 1fr; }
    }

    .form-group {
      display: flex;
      flex-direction: column;
      gap: 6px;
      margin-bottom: 16px;
    }

    .form-group.full { grid-column: span 2; }
    @media (max-width: 700px) { .form-group.full { grid-column: span 1; } }

    .form-label {
      font-size: 13px;
      font-weight: 600;
      color: #cbd5e1;
    }

    .form-input, .form-select, .form-textarea {
      background: #090d16;
      border: 1px solid var(--card-border);
      border-radius: 8px;
      padding: 10px 14px;
      color: #fff;
      font-family: inherit;
      font-size: 14px;
      transition: all 0.2s;
    }

    .form-input:focus, .form-select:focus, .form-textarea:focus {
      outline: none;
      border-color: var(--primary);
      box-shadow: 0 0 0 3px var(--primary-glow);
    }

    .form-textarea { min-height: 90px; resize: vertical; }

    /* Tables */
    .table-responsive {
      overflow-x: auto;
      border-radius: var(--radius);
      border: 1px solid var(--card-border);
    }

    table {
      width: 100%;
      border-collapse: collapse;
      text-align: left;
      font-size: 13px;
    }

    th {
      background: rgba(15, 23, 42, 0.8);
      padding: 14px 18px;
      font-weight: 700;
      color: #cbd5e1;
      text-transform: uppercase;
      font-size: 11px;
      letter-spacing: 0.5px;
      border-bottom: 1px solid var(--card-border);
    }

    td {
      padding: 14px 18px;
      border-bottom: 1px solid rgba(255, 255, 255, 0.05);
      color: #e2e8f0;
    }

    tr:hover td {
      background: rgba(255, 255, 255, 0.02);
    }

    /* Status Pills */
    .status-pill {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 4px 10px;
      border-radius: 9999px;
      font-size: 12px;
      font-weight: 700;
    }

    .status-pill.WORKING { background: rgba(16, 185, 129, 0.15); color: #34d399; }
    .status-pill.CLOCKED_OUT { background: rgba(148, 163, 184, 0.15); color: #cbd5e1; }
    .status-pill.NOT_CHECKED_IN { background: rgba(239, 68, 68, 0.15); color: #f87171; }

    /* Switch User Modal */
    .modal-overlay {
      position: fixed;
      inset: 0;
      background: rgba(0, 0, 0, 0.7);
      backdrop-filter: blur(8px);
      z-index: 100;
      display: none;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }

    .modal-overlay.open { display: flex; }

    .modal-box {
      background: var(--card);
      border: 1px solid var(--card-border);
      border-radius: 16px;
      padding: 28px;
      max-width: 520px;
      width: 100%;
      box-shadow: 0 20px 40px rgba(0, 0, 0, 0.6);
    }

    .modal-head {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 20px;
    }

    .modal-title { font-size: 18px; font-weight: 800; }
    .modal-close { background: none; border: none; color: var(--text-muted); font-size: 20px; cursor: pointer; }

    .user-select-grid {
      display: grid;
      gap: 10px;
    }

    .user-select-item {
      padding: 12px 16px;
      border-radius: 10px;
      background: #090d16;
      border: 1px solid var(--card-border);
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: space-between;
      transition: all 0.2s;
    }

    .user-select-item:hover {
      border-color: var(--primary);
      background: rgba(16, 185, 129, 0.05);
    }

    /* Toast */
    #toast {
      position: fixed;
      bottom: 24px;
      right: 24px;
      background: #1e293b;
      border: 1px solid var(--primary);
      color: #fff;
      padding: 12px 20px;
      border-radius: 10px;
      font-size: 14px;
      font-weight: 600;
      z-index: 200;
      transform: translateY(100px);
      opacity: 0;
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      box-shadow: 0 10px 25px rgba(0, 0, 0, 0.5);
    }

    #toast.show {
      transform: translateY(0);
      opacity: 1;
    }
  </style>
</head>
<body>
  <div class="bg-ambient"></div>

  <!-- Header -->
  <header>
    <a href="/workforce" class="brand">
      <img src="/enterprenex-badge.png" alt="Enterprenex Solutions" class="brand-logo" />
      <div class="brand-info">
        <h1>ENTERPRENEX WORKFORCE</h1>
        <p>Enterprise People Ops & Task Management</p>
      </div>
    </a>

    <div class="header-actions">
      <div id="roleBadgeContainer" class="role-badge ceo">👑 CEO</div>

      <div class="user-pill" onclick="openUserModal()">
        <div id="userAvatar" class="user-avatar">RP</div>
        <div>
          <div id="userName" style="font-size: 13px; font-weight: 700;">Rohit Pawar</div>
          <div id="userDesignation" style="font-size: 11px; color: var(--text-muted);">Chief Executive Officer</div>
        </div>
        <span style="font-size: 12px; color: var(--text-muted);">▼</span>
      </div>

      <div id="clockDisplay" class="clock-display">10:00:00 AM</div>
    </div>
  </header>

  <!-- Main Content -->
  <main class="container">
    <!-- Top Grid: Punch Clock & Executive Metrics -->
    <div class="top-grid">
      <!-- Punch Clock Card -->
      <div class="card punch-card">
        <div>
          <div class="punch-header">
            <span style="font-size: 13px; font-weight: 700; color: #cbd5e1;">DAILY ATTENDANCE</span>
            <div id="punchStatusBadge" class="punch-status stopped">
              <span class="pulse-dot"></span>
              <span id="punchStatusText">CLOCKED OUT</span>
            </div>
          </div>
          <div id="timerVal" class="timer-val">00:00:00</div>
          <div id="timerLabel" class="timer-label">Today's active working hours</div>
        </div>

        <div>
          <button id="punchBtn" class="punch-btn in" onclick="togglePunch()">
            <span>⏱️</span>
            <span id="punchBtnText">Clock In / Punch In</span>
          </button>
          <div class="punch-meta">
            <span>Check-In: <strong id="clockInTimeText" style="color: #fff;">--:--</strong></span>
            <span>Check-Out: <strong id="clockOutTimeText" style="color: #fff;">--:--</strong></span>
          </div>
        </div>
      </div>

      <!-- Executive / Department Overview Cards -->
      <div class="card">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
          <h2 style="font-size: 15px; font-weight: 800;">COMPANY-WIDE PERFORMANCE</h2>
          <span style="font-size: 12px; color: var(--primary); font-weight: 700;">● Real-time Live</span>
        </div>

        <div class="metrics-grid">
          <div class="metric-card">
            <div class="metric-title">👥 Active Staff Online</div>
            <div id="mOnlineStaff" class="metric-value" style="color: #34d399;">--</div>
            <div class="metric-foot">Currently checked-in</div>
          </div>

          <div class="metric-card">
            <div class="metric-title">📋 Assigned Work Tasks</div>
            <div id="mTotalTasks" class="metric-value">--</div>
            <div class="metric-foot">Across all departments</div>
          </div>

          <div class="metric-card">
            <div class="metric-title">⚡ Tasks Completed</div>
            <div id="mCompletedTasks" class="metric-value" style="color: #60a5fa;">--</div>
            <div class="metric-foot">Ready / Verified</div>
          </div>

          <div class="metric-card">
            <div class="metric-title">📈 Productivity Rate</div>
            <div id="mProductivity" class="metric-value" style="color: #a78bfa;">--%</div>
            <div class="metric-foot">Overall task resolution</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Navigation Tabs -->
    <div class="nav-tabs">
      <button class="tab-btn active" onclick="switchTab('my-tasks')">
        <span>📋</span> My Assigned Tasks
        <span id="myTasksBadge" class="badge-pill">0</span>
      </button>

      <button id="assignWorkTabBtn" class="tab-btn" onclick="switchTab('assign-task')">
        <span>➕</span> Assign Work Task
      </button>

      <button id="hrRosterTabBtn" class="tab-btn" onclick="switchTab('hr-roster')">
        <span>👥</span> HR & Live Attendance Desk
      </button>

      <button id="orgOverviewTabBtn" class="tab-btn" onclick="switchTab('all-tasks')">
        <span>📊</span> All Company Tasks
      </button>
    </div>

    <!-- TAB 1: My Tasks -->
    <div id="tab-my-tasks" class="tab-pane active">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
        <h3 style="font-size: 18px; font-weight: 800;">Tasks Assigned to You</h3>
        <span style="font-size: 13px; color: var(--text-muted);">Update your work progress directly below</span>
      </div>
      <div id="myTasksContainer" class="tasks-grid">
        <!-- Rendered by JS -->
      </div>
    </div>

    <!-- TAB 2: Assign Work Task -->
    <div id="tab-assign-task" class="tab-pane">
      <div class="card" style="max-width: 780px; margin: 0 auto;">
        <h3 style="font-size: 18px; font-weight: 800; margin-bottom: 6px;">Assign New Work Task</h3>
        <p style="font-size: 13px; color: var(--text-muted); margin-bottom: 20px;">
          As an Executive / Department Head, assign work directly to team members with priority and deadlines.
        </p>

        <form id="createTaskForm" onsubmit="handleCreateTask(event)">
          <div class="form-grid">
            <div class="form-group full">
              <label class="form-label">Task Title *</label>
              <input type="text" id="taskTitle" class="form-input" placeholder="e.g. Audit Razorpay settlement batches" required>
            </div>

            <div class="form-group">
              <label class="form-label">Assign To Employee *</label>
              <select id="taskAssignee" class="form-select" required>
                <!-- Populated by JS -->
              </select>
            </div>

            <div class="form-group">
              <label class="form-label">Department *</label>
              <select id="taskDepartment" class="form-select">
                <option value="ENGINEERING">Engineering & Tech</option>
                <option value="FINANCE">Finance & Accounts</option>
                <option value="HUMAN_RESOURCES">Human Resources</option>
                <option value="OPERATIONS">Operations & Field</option>
                <option value="EXECUTIVE">Executive Management</option>
              </select>
            </div>

            <div class="form-group">
              <label class="form-label">Priority Level *</label>
              <select id="taskPriority" class="form-select">
                <option value="URGENT">🔴 Urgent (Immediate Action)</option>
                <option value="HIGH">🟡 High Priority</option>
                <option value="MEDIUM" selected>🔵 Medium Priority</option>
                <option value="LOW">⚪ Low Priority</option>
              </select>
            </div>

            <div class="form-group">
              <label class="form-label">Due Date *</label>
              <input type="date" id="taskDueDate" class="form-input" required>
            </div>

            <div class="form-group full">
              <label class="form-label">Task Description & Deliverables</label>
              <textarea id="taskDescription" class="form-textarea" placeholder="Detail the expected deliverables, links, requirements, or acceptance criteria..."></textarea>
            </div>
          </div>

          <div style="text-align: right; margin-top: 10px;">
            <button type="submit" class="punch-btn in" style="display: inline-flex; width: auto; padding: 12px 28px;">
              🚀 Dispatch & Assign Task
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- TAB 3: HR & Live Attendance Desk -->
    <div id="tab-hr-roster" class="tab-pane">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
        <div>
          <h3 style="font-size: 18px; font-weight: 800;">HR Live Attendance & Clock-In Desk</h3>
          <p style="font-size: 13px; color: var(--text-muted);">Real-time monitoring of who is working right now across all company departments</p>
        </div>
        <button class="punch-btn in" style="width: auto; padding: 8px 18px; font-size: 13px;" onclick="loadWorkforceData()">
          🔄 Refresh Roster
        </button>
      </div>

      <div class="table-responsive">
        <table>
          <thead>
            <tr>
              <th>Employee</th>
              <th>Role / Position</th>
              <th>Department</th>
              <th>Today's Status</th>
              <th>Punch In</th>
              <th>Punch Out</th>
              <th>Active Hours</th>
            </tr>
          </thead>
          <tbody id="attendanceTableBody">
            <!-- Populated by JS -->
          </tbody>
        </table>
      </div>
    </div>

    <!-- TAB 4: All Company Tasks -->
    <div id="tab-all-tasks" class="tab-pane">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
        <h3 style="font-size: 18px; font-weight: 800;">All Organization Work Deliveries</h3>
        <span style="font-size: 13px; color: var(--text-muted);">Full visibility into all project milestones</span>
      </div>
      <div id="allTasksContainer" class="tasks-grid">
        <!-- Rendered by JS -->
      </div>
    </div>
  </main>

  <!-- Switch User Modal (Role Simulation) -->
  <div id="userModal" class="modal-overlay">
    <div class="modal-box">
      <div class="modal-head">
        <h4 class="modal-title">Switch Active Position / Employee</h4>
        <button class="modal-close" onclick="closeUserModal()">✕</button>
      </div>
      <p style="font-size: 13px; color: var(--text-muted); margin-bottom: 16px;">
        Select any leadership or team role to simulate its exact permissions and view:
      </p>
      <div id="userModalGrid" class="user-select-grid">
        <!-- Populated by JS -->
      </div>
    </div>
  </div>

  <div id="toast">Task Updated Successfully!</div>

  <script>
    // State
    let currentUser = {
      id: 'EMP-001',
      name: 'Rohit Pawar',
      email: 'rohit@enterprenex.solutions',
      role: 'CEO',
      department: 'EXECUTIVE',
      designation: 'Chief Executive Officer'
    };

    let employees = [];
    let myTasks = [];
    let allTasks = [];
    let liveAttendance = [];
    let todayAttendance = null;
    let timerInterval = null;
    let elapsedSeconds = 0;

    // Toast helper
    function showToast(msg) {
      const toast = document.getElementById('toast');
      toast.innerText = msg;
      toast.classList.add('show');
      setTimeout(() => toast.classList.remove('show'), 3500);
    }

    // Digital clock
    function updateClock() {
      const now = new Date();
      document.getElementById('clockDisplay').innerText = now.toLocaleTimeString('en-US', { hour12: true });
    }
    setInterval(updateClock, 1000);
    updateClock();

    // Tab switcher
    function switchTab(tabId) {
      document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
      document.querySelectorAll('.tab-pane').forEach(pane => pane.classList.remove('active'));
      
      const targetPane = document.getElementById('tab-' + tabId);
      if (targetPane) targetPane.classList.add('active');

      const activeBtn = Array.from(document.querySelectorAll('.tab-btn')).find(b => b.getAttribute('onclick') && b.getAttribute('onclick').includes(tabId));
      if (activeBtn) activeBtn.classList.add('active');
    }

    // Modal
    function openUserModal() { document.getElementById('userModal').classList.add('open'); }
    function closeUserModal() { document.getElementById('userModal').classList.remove('open'); }

    // Timer management
    function startTimer(startTimeIso) {
      clearInterval(timerInterval);
      const startMs = new Date(startTimeIso).getTime();
      function tick() {
        const diffMs = Math.max(0, Date.now() - startMs);
        const totalSec = Math.floor(diffMs / 1000);
        const hrs = String(Math.floor(totalSec / 3600)).padStart(2, '0');
        const mins = String(Math.floor((totalSec % 3600) / 60)).padStart(2, '0');
        const secs = String(totalSec % 60).padStart(2, '0');
        document.getElementById('timerVal').innerText = \`\${hrs}:\${mins}:\${secs}\`;
      }
      tick();
      timerInterval = setInterval(tick, 1000);
    }

    function stopTimer(hours) {
      clearInterval(timerInterval);
      if (hours) {
        const totalMins = Math.round(hours * 60);
        const hrs = String(Math.floor(totalMins / 60)).padStart(2, '0');
        const mins = String(totalMins % 60).padStart(2, '0');
        document.getElementById('timerVal').innerText = \`\${hrs}:\${mins}:00\`;
      } else {
        document.getElementById('timerVal').innerText = '00:00:00';
      }
    }

    // Load initial data
    async function loadWorkforceData() {
      try {
        // 1. Employees
        const empRes = await fetch('/api/v1/workforce/employees');
        const empJson = await empRes.json();
        if (empJson.success) {
          employees = empJson.data;
          renderEmployeeSelectors();
        }

        // 2. Overview Stats
        const ovRes = await fetch('/api/v1/workforce/overview');
        const ovJson = await ovRes.json();
        if (ovJson.success) {
          const o = ovJson.data;
          document.getElementById('mOnlineStaff').innerText = o.onlineNow;
          document.getElementById('mTotalTasks').innerText = o.totalTasks;
          document.getElementById('mCompletedTasks').innerText = o.completedTasks;
          document.getElementById('mProductivity').innerText = o.productivityPercentage + '%';
        }

        // 3. User Profile & Today Attendance
        const meRes = await fetch('/api/v1/workforce/me?employeeId=' + currentUser.id);
        const meJson = await meRes.json();
        if (meJson.success) {
          todayAttendance = meJson.data.attendanceToday;
          updatePunchUi(todayAttendance);
        }

        // 4. Tasks
        const myTasksRes = await fetch('/api/v1/workforce/tasks?assignedTo=' + currentUser.id);
        const myTasksJson = await myTasksRes.json();
        if (myTasksJson.success) {
          myTasks = myTasksJson.data;
          document.getElementById('myTasksBadge').innerText = myTasks.filter(t => t.status !== 'DONE').length;
          renderMyTasks();
        }

        const allTasksRes = await fetch('/api/v1/workforce/tasks');
        const allTasksJson = await allTasksRes.json();
        if (allTasksJson.success) {
          allTasks = allTasksJson.data;
          renderAllTasks();
        }

        // 5. Live Attendance
        const liveRes = await fetch('/api/v1/workforce/attendance/live');
        const liveJson = await liveRes.json();
        if (liveJson.success) {
          liveAttendance = liveJson.data;
          renderLiveAttendanceTable();
        }

      } catch (err) {
        console.error('Failed to load workforce data:', err);
      }
    }

    // Update Punch UI
    function updatePunchUi(att) {
      const badge = document.getElementById('punchStatusBadge');
      const badgeText = document.getElementById('punchStatusText');
      const btn = document.getElementById('punchBtn');
      const btnText = document.getElementById('punchBtnText');
      const inText = document.getElementById('clockInTimeText');
      const outText = document.getElementById('clockOutTimeText');

      if (att && att.clockInTime && !att.clockOutTime) {
        // Working
        badge.className = 'punch-status working';
        badgeText.innerText = 'WORKING (ACTIVE)';
        btn.className = 'punch-btn out';
        btnText.innerText = 'Clock Out / Punch Out';
        inText.innerText = new Date(att.clockInTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        outText.innerText = '--:--';
        startTimer(att.clockInTime);
      } else if (att && att.clockOutTime) {
        // Clocked Out
        badge.className = 'punch-status stopped';
        badgeText.innerText = 'CLOCKED OUT';
        btn.className = 'punch-btn in';
        btnText.innerText = 'Clock In Again';
        inText.innerText = new Date(att.clockInTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        outText.innerText = new Date(att.clockOutTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        stopTimer(att.totalHours);
      } else {
        // Not checked in
        badge.className = 'punch-status stopped';
        badgeText.innerText = 'NOT CLOCKED IN';
        btn.className = 'punch-btn in';
        btnText.innerText = 'Clock In / Punch In';
        inText.innerText = '--:--';
        outText.innerText = '--:--';
        stopTimer(0);
      }
    }

    // Toggle Punch
    async function togglePunch() {
      try {
        const isCurrentlyWorking = todayAttendance && todayAttendance.clockInTime && !todayAttendance.clockOutTime;
        const endpoint = isCurrentlyWorking 
          ? '/api/v1/workforce/attendance/clock-out' 
          : '/api/v1/workforce/attendance/clock-in';

        const res = await fetch(endpoint, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ employeeId: currentUser.id })
        });
        const json = await res.json();

        if (json.success) {
          todayAttendance = json.data;
          updatePunchUi(todayAttendance);
          showToast(json.message);
          loadWorkforceData(); // Refresh roster and stats
        } else {
          showToast(json.error || 'Failed to update attendance');
        }
      } catch (err) {
        showToast('Error: ' + err.message);
      }
    }

    // Switch Role / Position
    function selectUser(empId) {
      const found = employees.find(e => e.id === empId);
      if (!found) return;
      currentUser = found;

      document.getElementById('userName').innerText = found.name;
      document.getElementById('userDesignation').innerText = found.designation;
      document.getElementById('userAvatar').innerText = found.name.split(' ').map(n => n[0]).join('');

      const badge = document.getElementById('roleBadgeContainer');
      badge.className = 'role-badge ' + found.role.toLowerCase();
      const roleIcons = { CEO: '👑', CTO: '⚡', CFO: '💼', HR: '👥', LEAD: '🛠️', EMPLOYEE: '💻' };
      badge.innerText = (roleIcons[found.role] || '👤') + ' ' + found.role;

      closeUserModal();
      showToast('Switched view to ' + found.name + ' (' + found.role + ')');
      loadWorkforceData();
    }

    // Render Employee Dropdowns & Selectors
    function renderEmployeeSelectors() {
      // 1. Assign Task select
      const select = document.getElementById('taskAssignee');
      select.innerHTML = employees.map(e => \`<option value="\${e.id}">\${e.name} — \${e.designation} (\${e.department})</option>\`).join('');

      // 2. Switch User modal grid
      const modalGrid = document.getElementById('userModalGrid');
      modalGrid.innerHTML = employees.map(e => \`
        <div class="user-select-item" onclick="selectUser('\${e.id}')">
          <div>
            <div style="font-weight: 700; font-size: 14px;">\${e.name}</div>
            <div style="font-size: 12px; color: var(--text-muted);">\${e.email} • \${e.designation}</div>
          </div>
          <span class="role-badge \${e.role.toLowerCase()}">\${e.role}</span>
        </div>
      \`).join('');
    }

    // Render Tasks
    function renderMyTasks() {
      const container = document.getElementById('myTasksContainer');
      if (myTasks.length === 0) {
        container.innerHTML = \`<div class="card" style="grid-column: span 3; text-align: center; color: var(--text-muted); padding: 40px;">🎉 No pending tasks assigned to you right now! Great job!</div>\`;
        return;
      }

      container.innerHTML = myTasks.map(t => \`
        <div class="task-card">
          <div>
            <div class="task-top">
              <span class="priority-badge priority-\${t.priority}">\${t.priority}</span>
              <select class="status-select" onchange="updateTaskStatus('\${t.id}', this.value)">
                <option value="TODO" \${t.status === 'TODO' ? 'selected' : ''}>To-Do</option>
                <option value="IN_PROGRESS" \${t.status === 'IN_PROGRESS' ? 'selected' : ''}>In Progress</option>
                <option value="REVIEW" \${t.status === 'REVIEW' ? 'selected' : ''}>Review</option>
                <option value="DONE" \${t.status === 'DONE' ? 'selected' : ''}>Done</option>
              </select>
            </div>
            <div class="task-title" style="margin-top: 12px;">\${t.title}</div>
            <div class="task-desc">\${t.description}</div>
            \${t.workNotes ? \`<div style="font-size: 12px; color: #a5b4fc; background: rgba(99, 102, 241, 0.1); padding: 8px; border-radius: 6px; margin-top: 8px;">📝 Notes: \${t.workNotes}</div>\` : ''}
          </div>

          <div class="task-foot">
            <span>Assigned by: <strong>\${t.assignedByName || 'Management'}</strong></span>
            <span>Due: <strong>\${t.dueDate || 'No Deadline'}</strong></span>
          </div>
        </div>
      \`).join('');
    }

    function renderAllTasks() {
      const container = document.getElementById('allTasksContainer');
      container.innerHTML = allTasks.map(t => \`
        <div class="task-card">
          <div>
            <div class="task-top">
              <span class="priority-badge priority-\${t.priority}">\${t.priority}</span>
              <span style="font-size: 12px; font-weight: 700; color: \${t.status === 'DONE' ? '#34d399' : '#a5b4fc'};">\${t.status}</span>
            </div>
            <div class="task-title" style="margin-top: 12px;">\${t.title}</div>
            <div class="task-desc">\${t.description}</div>
          </div>

          <div class="task-foot">
            <span class="task-assignee">👤 \${t.assignedToName}</span>
            <span>Due: <strong>\${t.dueDate}</strong></span>
          </div>
        </div>
      \`).join('');
    }

    // Update Task Status
    async function updateTaskStatus(taskId, newStatus) {
      try {
        let workNotes = undefined;
        if (newStatus === 'DONE' || newStatus === 'REVIEW') {
          workNotes = prompt('Add optional delivery note or link (e.g. Completed & tested):', 'Completed on schedule');
        }

        const res = await fetch(\`/api/v1/workforce/tasks/\${taskId}/status\`, {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ status: newStatus, workNotes: workNotes || undefined })
        });
        const json = await res.json();
        if (json.success) {
          showToast('Task updated to ' + newStatus);
          loadWorkforceData();
        }
      } catch (err) {
        showToast('Error: ' + err.message);
      }
    }

    // Create Task Handler
    async function handleCreateTask(e) {
      e.preventDefault();
      const title = document.getElementById('taskTitle').value;
      const assignedTo = document.getElementById('taskAssignee').value;
      const department = document.getElementById('taskDepartment').value;
      const priority = document.getElementById('taskPriority').value;
      const dueDate = document.getElementById('taskDueDate').value;
      const description = document.getElementById('taskDescription').value;

      try {
        const res = await fetch('/api/v1/workforce/tasks', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            title,
            assignedTo,
            assignedBy: currentUser.id,
            department,
            priority,
            dueDate,
            description
          })
        });
        const json = await res.json();
        if (json.success) {
          showToast('Task successfully assigned to team member!');
          document.getElementById('createTaskForm').reset();
          switchTab('all-tasks');
          loadWorkforceData();
        } else {
          showToast(json.error || 'Failed to assign task');
        }
      } catch (err) {
        showToast('Error: ' + err.message);
      }
    }

    // Render Live Attendance Table
    function renderLiveAttendanceTable() {
      const tbody = document.getElementById('attendanceTableBody');
      tbody.innerHTML = liveAttendance.map(e => \`
        <tr>
          <td>
            <div style="font-weight: 700;">\${e.name}</div>
            <div style="font-size: 11px; color: var(--text-muted);">\${e.email}</div>
          </td>
          <td><span class="role-badge \${e.role.toLowerCase()}">\${e.role}</span></td>
          <td>\${e.department}</td>
          <td>
            <span class="status-pill \${e.workStatus}">
              \${e.workStatus === 'WORKING' ? '🟢 Working' : e.workStatus === 'CLOCKED_OUT' ? '🔴 Clocked Out' : '⚪ Not Checked In'}
            </span>
          </td>
          <td>\${e.clockInTime ? new Date(e.clockInTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '--'}</td>
          <td>\${e.clockOutTime ? new Date(e.clockOutTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '--'}</td>
          <td><strong style="color: #fff;">\${e.activeHoursFormatted}</strong></td>
        </tr>
      \`).join('');
    }

    // Set default due date to 3 days from now
    const d = new Date();
    d.setDate(d.getDate() + 3);
    document.getElementById('taskDueDate').value = d.toISOString().split('T')[0];

    // Initialize
    loadWorkforceData();
  </script>
</body>
</html>`;
}

module.exports = {
  getWorkforcePortalHtml
};
