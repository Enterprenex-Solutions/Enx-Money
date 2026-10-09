'use client';

import React, { useState, useEffect } from 'react';

// Demo seed accounts for Enterprenex Solutions (3 Canonical Roles per SDLC)
const DEMO_ACCOUNTS = [
  { role: 'DIRECTOR', name: 'Kishore Polamarasetti', email: 'director@enterprenex.solutions', badge: 'Director & Executive' },
  { role: 'MANAGER', name: 'Aniket Sharma', email: 'manager@enterprenex.solutions', badge: 'Manager & HR' },
  { role: 'EMPLOYEE', name: 'Rahul Verma', email: 'employee@enterprenex.solutions', badge: 'Software Engineer' },
];

// Phase 2 KPI Templates
const ROLE_KPI_PRESETS: Record<string, { role: string; metrics: { name: string; weight: number; score: number }[] }> = {
  Developer: {
    role: 'Developer',
    metrics: [
      { name: 'Delivery (Sprint Commitments)', weight: 25, score: 92 },
      { name: 'Code Quality & Review Rigor', weight: 25, score: 88 },
      { name: 'Bug Rate & Production Stability', weight: 20, score: 92 },
      { name: 'Technical Contribution & Design', weight: 10, score: 85 },
      { name: 'Documentation & Architecture Notes', weight: 10, score: 90 },
      { name: 'Team Collaboration & Mentoring', weight: 10, score: 95 },
    ],
  },
  'QA Engineer': {
    role: 'QA Engineer',
    metrics: [
      { name: 'Test Coverage & Plan Completeness', weight: 30, score: 94 },
      { name: 'Defect Detection & Density', weight: 25, score: 90 },
      { name: 'Automation Test Framework ROI', weight: 20, score: 88 },
      { name: 'Regression Escapes (Low is Better)', weight: 15, score: 96 },
      { name: 'Documentation & Test Artifacts', weight: 10, score: 90 },
    ],
  },
  'UI/UX Designer': {
    role: 'UI/UX Designer',
    metrics: [
      { name: 'Design System Adoption & Tokens', weight: 30, score: 95 },
      { name: 'Usability & Accessibility Scoring', weight: 25, score: 91 },
      { name: 'Delivery Pace & Figma Handoff', weight: 20, score: 89 },
      { name: 'Component Cleanliness & Specs', weight: 15, score: 92 },
      { name: 'Cross-functional Team Alignment', weight: 10, score: 94 },
    ],
  },
  'DevOps Engineer': {
    role: 'DevOps Engineer',
    metrics: [
      { name: 'Platform Uptime & SLA (99.99%)', weight: 30, score: 99 },
      { name: 'CI/CD Pipeline Speed & Reliability', weight: 25, score: 93 },
      { name: 'MTTR (Mean Time to Resolution)', weight: 20, score: 90 },
      { name: 'Security & Vulnerability Patching', weight: 15, score: 95 },
      { name: 'IaC Documentation & Runbooks', weight: 10, score: 92 },
    ],
  },
  Intern: {
    role: 'Intern',
    metrics: [
      { name: 'Learning Velocity & Growth Speed', weight: 35, score: 90 },
      { name: 'Assigned Task Completion', weight: 25, score: 85 },
      { name: 'Mentorship Adherence & Feedback', weight: 20, score: 95 },
      { name: 'Code Cleanliness & Git Hygiene', weight: 20, score: 88 },
    ],
  },
};

export default function EwmsPortal() {
  const [user, setUser] = useState<any>(null);
  const [token, setToken] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<string>('dashboard');
  const [toast, setToast] = useState<{ msg: string; type: 'info' | 'success' | 'error' } | null>(null);

  // Live Timer State
  const [timerRunning, setTimerRunning] = useState(false);
  const [seconds, setSeconds] = useState(0);

  // Form State
  const [emailInput, setEmailInput] = useState('director@enterprenex.solutions');
  const [passwordInput, setPasswordInput] = useState('Enterprenex@2026');

  // Dashboard Data Mock / Live Cache
  const [tasks, setTasks] = useState([
    { id: 'tsk-101', number: 'TSK-101', title: 'Design OAuth2 & JWT Schema', status: 'COMPLETED', priority: 'HIGH', estHours: 10, actualHours: 9.5, dependsOn: null },
    { id: 'tsk-102', number: 'TSK-102', title: 'Implement Authentication & RBAC API', status: 'IN_PROGRESS', priority: 'URGENT', estHours: 15, actualHours: 8.0, dependsOn: 'TSK-101' },
    { id: 'tsk-103', number: 'TSK-103', title: 'Build Web Portal & MFA Screen', status: 'ASSIGNED', priority: 'HIGH', estHours: 12, actualHours: 0, dependsOn: 'TSK-102' },
  ]);

  const [attendanceClockedIn, setAttendanceClockedIn] = useState(true);

  // Phase 2 State
  const [selectedKpiRole, setSelectedKpiRole] = useState<string>('Developer');
  const [leaveBalances, setLeaveBalances] = useState({ annual: 18, sick: 10, casual: 6 });
  const [leaveRequests, setLeaveRequests] = useState([
    { id: 'lr-1', employee: 'Rahul Verma', type: 'ANNUAL', days: 2, dates: '2026-04-14 to 2026-04-15', status: 'PENDING', reason: 'Family commitment' },
    { id: 'lr-2', employee: 'Aniket Sharma', type: 'SICK', days: 1, dates: '2026-03-20', status: 'APPROVED', reason: 'Medical appointment' },
  ]);
  const [timesheetApproved, setTimesheetApproved] = useState(true);

  // Phase 3 State
  const [meetingActionItems, setMeetingActionItems] = useState([
    { id: 'act-1', text: 'Configure Redis distributed locks for request idempotency', assignee: 'Rahul Verma', converted: false, convertedTaskNum: '' },
    { id: 'act-2', text: 'Conduct k6 benchmark load testing for 10k req/sec peak load', assignee: 'Aniket Sharma', converted: false, convertedTaskNum: '' },
  ]);

  const [risks, setRisks] = useState([
    { id: 'rsk-1', title: 'Third-party OAuth identity provider intermittent timeout', severity: 'HIGH', probability: 'LOW', mitigation: 'Maintain local JWT session fallback cache', status: 'OPEN' },
    { id: 'rsk-2', title: 'Cloud provider memory limit ceiling on staging clusters', severity: 'MEDIUM', probability: 'MEDIUM', mitigation: 'Enable horizontal pod autoscaling', status: 'RESOLVED' },
  ]);

  const showToast = (msg: string, type: 'info' | 'success' | 'error' = 'info') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 3500);
  };

  useEffect(() => {
    let interval: any = null;
    if (timerRunning) {
      interval = setInterval(() => setSeconds(s => s + 1), 1000);
    } else {
      clearInterval(interval);
    }
    return () => clearInterval(interval);
  }, [timerRunning]);

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    const account = DEMO_ACCOUNTS.find(a => a.email.toLowerCase() === emailInput.toLowerCase());
    if (account) {
      const authUser = {
        name: account.name,
        email: account.email,
        role: account.role,
        badge: account.badge,
        organization: 'Enterprenex Solutions Pvt Ltd',
      };
      setUser(authUser);
      setToken('mock_jwt_token_' + Date.now());
      showToast(`Welcome back, ${account.name} (${account.role})`, 'success');
    } else {
      showToast('Invalid demo credentials', 'error');
    }
  };

  const handleQuickSelect = (acc: typeof DEMO_ACCOUNTS[0]) => {
    setEmailInput(acc.email);
    setPasswordInput('Enterprenex@2026');
  };

  const handleStatusChange = (taskId: string, targetStatus: string) => {
    if (targetStatus === 'IN_PROGRESS') {
      const task = tasks.find(t => t.id === taskId);
      if (task && task.dependsOn) {
        const parent = tasks.find(t => t.number === task.dependsOn);
        if (parent && parent.status !== 'COMPLETED') {
          showToast(`Cannot start task: Dependent prerequisite ${parent.number} is still ${parent.status}!`, 'error');
          return;
        }
      }
    }

    setTasks(prev => prev.map(t => t.id === taskId ? { ...t, status: targetStatus } : t));
    showToast(`Task status updated to ${targetStatus}`, 'success');
  };

  // Convert Meeting Action Item to Task (Phase 3 Core Feature)
  const handleConvertActionItemToTask = (actionId: string) => {
    const act = meetingActionItems.find(a => a.id === actionId);
    if (!act || act.converted) return;

    const newTaskNum = `TSK-${100 + tasks.length + 1}`;
    const newTask = {
      id: `tsk-${Date.now()}`,
      number: newTaskNum,
      title: act.text,
      status: 'ASSIGNED',
      priority: 'HIGH',
      estHours: 8,
      actualHours: 0,
      dependsOn: null,
    };

    setTasks(prev => [...prev, newTask]);
    setMeetingActionItems(prev => prev.map(a => a.id === actionId ? { ...a, converted: true, convertedTaskNum: newTaskNum } : a));
    showToast(`Converted meeting action item into new Project Task ${newTaskNum}!`, 'success');
  };

  // Calculate Weighted KPI Score
  const currentKpiMetrics = ROLE_KPI_PRESETS[selectedKpiRole]?.metrics || [];
  const calculatedKpiScore = currentKpiMetrics.reduce((acc, m) => acc + (m.weight * m.score) / 100, 0).toFixed(1);

  // ─── LOGIN VIEW ───────────────────────────────────────────
  if (!user) {
    return (
      <div className="min-h-screen bg-bg flex items-center justify-center p-6 bg-[radial-gradient(ellipse_at_top,_#141f36,_#090d16)]">
        {toast && (
          <div className={`fixed top-5 right-5 z-50 px-4 py-3 rounded-lg shadow-xl text-sm font-medium border ${
            toast.type === 'error' ? 'bg-red-950 border-red-500 text-red-200' : 'bg-slate-800 border-blue-500 text-slate-100'
          }`}>
            {toast.msg}
          </div>
        )}

        <div className="w-full max-w-md bg-surface border border-border rounded-xl p-8 shadow-2xl">
          <div className="text-center mb-6">
            <img
              src="/enx-emblem.png"
              alt="Enterprenex Solutions"
              className="w-14 h-14 object-contain rounded-xl shadow-md mx-auto mb-3 bg-white p-1 border border-slate-700"
            />
            <h1 className="text-xl font-bold text-slate-100 tracking-tight">Enterprenex Solutions EWMS</h1>
            <p className="text-xs text-slate-400 mt-1">Employee & Work Management System • Enterprenex Platform</p>
          </div>

          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-slate-300 mb-1">Company Email</label>
              <input
                type="email"
                value={emailInput}
                onChange={e => setEmailInput(e.target.value)}
                className="w-full px-3 py-2 bg-bg border border-border rounded-md text-sm text-slate-100 focus:outline-none focus:border-primary"
                required
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-300 mb-1">Password</label>
              <input
                type="password"
                value={passwordInput}
                onChange={e => setPasswordInput(e.target.value)}
                className="w-full px-3 py-2 bg-bg border border-border rounded-md text-sm text-slate-100 focus:outline-none focus:border-primary"
                required
              />
            </div>
            <button
              type="submit"
              className="w-full py-2.5 bg-primary hover:bg-primary-hover text-white text-sm font-semibold rounded-md transition shadow-md"
            >
              Sign In to EWMS Workstation
            </button>
          </form>

          <div className="mt-6 pt-5 border-t border-border-subtle">
            <span className="block text-[11px] font-bold text-slate-400 uppercase tracking-wider mb-2 text-center">
              Quick Role Switcher (3 Canonical Roles)
            </span>
            <div className="grid grid-cols-3 gap-2">
              {DEMO_ACCOUNTS.map(acc => (
                <button
                  key={acc.role}
                  type="button"
                  onClick={() => handleQuickSelect(acc)}
                  className={`px-2 py-2 text-xs font-semibold rounded-lg border transition truncate text-center ${
                    emailInput === acc.email
                      ? 'bg-primary/20 border-primary text-white shadow-sm'
                      : 'bg-surface-elevated border-border text-slate-300 hover:border-slate-500'
                  }`}
                  title={`${acc.name} (${acc.role}) - ${acc.badge}`}
                >
                  {acc.role === 'MANAGER' ? 'MANAGER (HR)' : acc.role}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  }

  // ─── MAIN ENTERPRISE WORKSPACE ────────────────────────────
  const formatTimer = (s: number) => {
    const hrs = String(Math.floor(s / 3600)).padStart(2, '0');
    const mins = String(Math.floor((s % 3600) / 60)).padStart(2, '0');
    const secs = String(s % 60).padStart(2, '0');
    return `${hrs}:${mins}:${secs}`;
  };

  return (
    <div className="min-h-screen bg-bg flex text-slate-100">
      {/* Toast Notification */}
      {toast && (
        <div className={`fixed top-5 right-5 z-50 px-4 py-3 rounded-lg shadow-xl text-sm font-medium border ${
          toast.type === 'error' ? 'bg-red-950 border-red-500 text-red-200' : 'bg-slate-800 border-blue-500 text-slate-100'
        }`}>
          {toast.msg}
        </div>
      )}

      {/* Sidebar Navigation */}
      <aside className="w-64 bg-surface border-r border-border flex flex-col justify-between">
        <div>
          <div className="h-16 px-5 border-b border-border flex items-center gap-3">
            <img
              src="/enx-emblem.png"
              alt="Enterprenex Solutions"
              className="w-9 h-9 object-contain rounded-lg shadow-sm bg-white p-0.5 border border-slate-700"
            />
            <div>
              <div className="font-bold text-sm tracking-tight">Enterprenex Solutions</div>
              <div className="text-[10px] text-primary uppercase font-semibold">{user.role}</div>
            </div>
          </div>

          <nav className="p-3 space-y-1">
            <button
              onClick={() => setActiveTab('dashboard')}
              className={`w-full text-left px-3 py-2 rounded-md text-xs font-medium transition ${
                activeTab === 'dashboard' ? 'bg-primary/15 text-primary font-semibold' : 'text-slate-400 hover:bg-surface-hover hover:text-slate-200'
              }`}
            >
              Workstation Dashboard
            </button>

            {user.role !== 'CLIENT' && (
              <>
                <button
                  onClick={() => setActiveTab('tasks')}
                  className={`w-full text-left px-3 py-2 rounded-md text-xs font-medium transition ${
                    activeTab === 'tasks' ? 'bg-primary/15 text-primary font-semibold' : 'text-slate-400 hover:bg-surface-hover hover:text-slate-200'
                  }`}
                >
                  Tasks & Dependencies
                </button>
                <button
                  onClick={() => setActiveTab('time')}
                  className={`w-full text-left px-3 py-2 rounded-md text-xs font-medium transition ${
                    activeTab === 'time' ? 'bg-primary/15 text-primary font-semibold' : 'text-slate-400 hover:bg-surface-hover hover:text-slate-200'
                  }`}
                >
                  Time Tracking & Sessions
                </button>
              </>
            )}

            <button
              onClick={() => setActiveTab('projects')}
              className={`w-full text-left px-3 py-2 rounded-md text-xs font-medium transition ${
                activeTab === 'projects' ? 'bg-primary/15 text-primary font-semibold' : 'text-slate-400 hover:bg-surface-hover hover:text-slate-200'
              }`}
            >
              {user.role === 'CLIENT' ? 'Assigned Projects' : 'Projects & Milestones'}
            </button>

            {/* PHASE 2: Performance & Talent */}
            {user.role !== 'CLIENT' && (
              <>
                <button
                  onClick={() => setActiveTab('performance')}
                  className={`w-full text-left px-3 py-2 rounded-md text-xs font-medium transition flex items-center justify-between ${
                    activeTab === 'performance' ? 'bg-primary/15 text-primary font-semibold' : 'text-slate-400 hover:bg-surface-hover hover:text-slate-200'
                  }`}
                >
                  <span>Performance & OKRs</span>
                  <span className="text-[9px] bg-primary/20 text-primary px-1.5 py-0.5 rounded font-mono">P2</span>
                </button>

                <button
                  onClick={() => setActiveTab('leaves_timesheets')}
                  className={`w-full text-left px-3 py-2 rounded-md text-xs font-medium transition flex items-center justify-between ${
                    activeTab === 'leaves_timesheets' ? 'bg-primary/15 text-primary font-semibold' : 'text-slate-400 hover:bg-surface-hover hover:text-slate-200'
                  }`}
                >
                  <span>Leaves & Timesheets</span>
                  <span className="text-[9px] bg-primary/20 text-primary px-1.5 py-0.5 rounded font-mono">P2</span>
                </button>

                {/* PHASE 3: Company Platform & Workflows */}
                <button
                  onClick={() => setActiveTab('company_platform')}
                  className={`w-full text-left px-3 py-2 rounded-md text-xs font-medium transition flex items-center justify-between ${
                    activeTab === 'company_platform' ? 'bg-primary/15 text-primary font-semibold' : 'text-slate-400 hover:bg-surface-hover hover:text-slate-200'
                  }`}
                >
                  <span>Company Platform & Collab</span>
                  <span className="text-[9px] bg-emerald-500/20 text-emerald-400 px-1.5 py-0.5 rounded font-mono">P3</span>
                </button>
              </>
            )}

            {/* Role-Specific Admin & HR Tabs */}
            {['DIRECTOR', 'MANAGER', 'SUPER_ADMIN', 'COMPANY_ADMIN', 'HR_ADMIN', 'PROJECT_MANAGER', 'TEAM_LEAD'].includes(user.role) && (
              <button
                onClick={() => setActiveTab('team')}
                className={`w-full text-left px-3 py-2 rounded-md text-xs font-medium transition ${
                  activeTab === 'team' ? 'bg-primary/15 text-primary font-semibold' : 'text-slate-400 hover:bg-surface-hover hover:text-slate-200'
                }`}
              >
                Team Workload & Capacity
              </button>
            )}

            {['DIRECTOR', 'MANAGER', 'SUPER_ADMIN', 'COMPANY_ADMIN', 'HR_ADMIN'].includes(user.role) && (
              <button
                onClick={() => setActiveTab('employees')}
                className={`w-full text-left px-3 py-2 rounded-md text-xs font-medium transition ${
                  activeTab === 'employees' ? 'bg-primary/15 text-primary font-semibold' : 'text-slate-400 hover:bg-surface-hover hover:text-slate-200'
                }`}
              >
                Staff Directory & Profiles
              </button>
            )}

            {['DIRECTOR', 'SUPER_ADMIN', 'COMPANY_ADMIN'].includes(user.role) && (
              <button
                onClick={() => setActiveTab('audit')}
                className={`w-full text-left px-3 py-2 rounded-md text-xs font-medium transition ${
                  activeTab === 'audit' ? 'bg-primary/15 text-primary font-semibold' : 'text-slate-400 hover:bg-surface-hover hover:text-slate-200'
                }`}
              >
                Security Audit Trail
              </button>
            )}
          </nav>
        </div>

        {/* User Footer Profile */}
        <div className="p-4 border-t border-border flex items-center justify-between">
          <div>
            <div className="text-xs font-bold text-slate-200">{user.name}</div>
            <div className="text-[10px] text-slate-400 truncate w-36">{user.email}</div>
          </div>
          <button
            onClick={() => setUser(null)}
            className="text-xs text-red-400 hover:text-red-300 font-semibold"
          >
            Exit
          </button>
        </div>
      </aside>

      {/* Main Content Workspace */}
      <main className="flex-1 flex flex-col min-w-0">
        {/* Topbar */}
        <header className="h-16 px-8 border-b border-border bg-surface flex items-center justify-between">
          <div className="flex items-center gap-3">
            <h2 className="text-base font-bold capitalize">{activeTab.replace('_', ' ')}</h2>
            <span className="text-[10px] px-2 py-0.5 rounded bg-surface-elevated border border-border text-slate-400 font-semibold uppercase">
              {user.role} Scope
            </span>
          </div>

          {user.role !== 'CLIENT' && (
            <div className="flex items-center gap-4">
              <div className="font-mono text-xs bg-bg px-3 py-1.5 rounded border border-border text-slate-300">
                Session: {formatTimer(seconds)}
              </div>
              <button
                onClick={() => {
                  setTimerRunning(!timerRunning);
                  showToast(timerRunning ? 'Timer stopped & duration saved' : 'Live work timer started', 'info');
                }}
                className={`text-xs px-3 py-1.5 rounded font-semibold transition ${
                  timerRunning ? 'bg-amber-500/20 text-amber-300 border border-amber-500/30' : 'bg-primary/20 text-primary border border-primary/30'
                }`}
              >
                {timerRunning ? 'Pause Timer' : 'Start Timer'}
              </button>
              <button
                onClick={() => {
                  setAttendanceClockedIn(!attendanceClockedIn);
                  showToast(attendanceClockedIn ? 'Clocked out of shift' : 'Clocked in to shift', 'success');
                }}
                className={`text-xs px-3 py-1.5 rounded font-semibold transition ${
                  attendanceClockedIn ? 'bg-red-500/20 text-red-300 border border-red-500/30' : 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30'
                }`}
              >
                {attendanceClockedIn ? 'Clock Out' : 'Clock In'}
              </button>
            </div>
          )}
        </header>

        {/* View Content */}
        <div className="p-8 flex-1 overflow-auto space-y-6">
          {/* TAB 1: DASHBOARD */}
          {activeTab === 'dashboard' && (
            <div className="space-y-6">
              <div className="grid grid-cols-4 gap-4">
                <div className="bg-surface border border-border rounded-lg p-5">
                  <div className="text-xs font-semibold text-slate-400 uppercase">Today's Work Duration</div>
                  <div className="text-2xl font-bold font-mono text-slate-100 mt-2">{formatTimer(seconds)}</div>
                  <div className="text-[11px] text-slate-500 mt-1">Live active task session</div>
                </div>
                <div className="bg-surface border border-border rounded-lg p-5">
                  <div className="text-xs font-semibold text-slate-400 uppercase">Active Sprint Tasks</div>
                  <div className="text-2xl font-bold font-mono text-slate-100 mt-2">{tasks.length} Tasks</div>
                  <div className="text-[11px] text-emerald-400 mt-1">
                    {tasks.filter(t => t.status === 'COMPLETED').length} Done · {tasks.filter(t => t.status === 'IN_PROGRESS').length} Active
                  </div>
                </div>
                <div className="bg-surface border border-border rounded-lg p-5">
                  <div className="text-xs font-semibold text-slate-400 uppercase">Attendance Status</div>
                  <div className="text-2xl font-bold font-mono text-emerald-400 mt-2">
                    {attendanceClockedIn ? 'PRESENT' : 'NOT CLOCKED IN'}
                  </div>
                  <div className="text-[11px] text-slate-500 mt-1">09:30 AM Shift Start</div>
                </div>
                <div className="bg-surface border border-border rounded-lg p-5">
                  <div className="text-xs font-semibold text-slate-400 uppercase">Workload Capacity</div>
                  <div className="text-2xl font-bold font-mono text-amber-400 mt-2">72%</div>
                  <div className="text-[11px] text-slate-400 mt-1">Status Band: HEALTHY</div>
                </div>
              </div>

              {/* Notice Banner */}
              <div className="bg-surface border border-border-subtle rounded-lg p-4 flex items-center justify-between text-xs text-slate-400">
                <span>Core Principle: Dashboard metrics represent management signals, not automatic employee verdicts.</span>
                <span className="font-semibold text-primary">Enterprenex Solutions Enterprise Protocol</span>
              </div>
            </div>
          )}

          {/* TAB 2: TASKS & DEPENDENCY FLOW */}
          {activeTab === 'tasks' && (
            <div className="bg-surface border border-border rounded-lg overflow-hidden">
              <div className="p-4 border-b border-border flex items-center justify-between">
                <div>
                  <h3 className="text-sm font-bold">Active Sprint Tasks & Dependency Enforcement</h3>
                  <p className="text-xs text-slate-400 mt-0.5">Task Dependency Rule: A task cannot start until its prerequisite is COMPLETED.</p>
                </div>
                <button
                  onClick={() => {
                    const nextNum = `TSK-${100 + tasks.length + 1}`;
                    setTasks(prev => [...prev, {
                      id: `tsk-${Date.now()}`,
                      number: nextNum,
                      title: 'New Ad-hoc Engineering Task',
                      status: 'ASSIGNED',
                      priority: 'MEDIUM',
                      estHours: 6,
                      actualHours: 0,
                      dependsOn: null,
                    }]);
                    showToast(`Created new task ${nextNum}`, 'success');
                  }}
                  className="px-3 py-1.5 bg-primary/20 hover:bg-primary/30 text-primary border border-primary/30 rounded text-xs font-semibold"
                >
                  + Add Sprint Task
                </button>
              </div>
              <table className="w-full text-left text-xs">
                <thead className="bg-surface-elevated text-slate-400 font-semibold border-b border-border">
                  <tr>
                    <th className="p-3">Task ID</th>
                    <th className="p-3">Title</th>
                    <th className="p-3">Priority</th>
                    <th className="p-3">Prerequisite</th>
                    <th className="p-3">Status</th>
                    <th className="p-3 text-right">Advance Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border-subtle">
                  {tasks.map(t => (
                    <tr key={t.id} className="hover:bg-surface-hover/50 transition">
                      <td className="p-3 font-mono font-bold text-slate-300">{t.number}</td>
                      <td className="p-3 font-semibold text-slate-100">{t.title}</td>
                      <td className="p-3">
                        <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                          t.priority === 'URGENT' ? 'bg-red-500/20 text-red-400' : 'bg-blue-500/20 text-blue-400'
                        }`}>
                          {t.priority}
                        </span>
                      </td>
                      <td className="p-3 text-slate-400">
                        {t.dependsOn ? `Depends on ${t.dependsOn}` : 'None'}
                      </td>
                      <td className="p-3">
                        <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                          t.status === 'COMPLETED' ? 'bg-emerald-500/20 text-emerald-400' :
                          t.status === 'IN_PROGRESS' ? 'bg-amber-500/20 text-amber-400' : 'bg-slate-700 text-slate-300'
                        }`}>
                          {t.status}
                        </span>
                      </td>
                      <td className="p-3 text-right space-x-1">
                        {t.status !== 'IN_PROGRESS' && t.status !== 'COMPLETED' && (
                          <button
                            onClick={() => handleStatusChange(t.id, 'IN_PROGRESS')}
                            className="px-2 py-1 bg-surface-elevated hover:bg-surface-hover border border-border text-[11px] rounded"
                          >
                            Start
                          </button>
                        )}
                        {t.status === 'IN_PROGRESS' && (
                          <button
                            onClick={() => handleStatusChange(t.id, 'COMPLETED')}
                            className="px-2 py-1 bg-emerald-600/30 hover:bg-emerald-600/50 text-emerald-300 border border-emerald-500/40 text-[11px] rounded font-semibold"
                          >
                            Mark Complete
                          </button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {/* TAB 3: TIME TRACKING */}
          {activeTab === 'time' && (
            <div className="grid grid-cols-2 gap-6">
              <div className="bg-surface border border-border rounded-lg p-5">
                <h3 className="text-sm font-bold mb-2">Live Work Session Engine</h3>
                <p className="text-xs text-slate-400 mb-4">
                  Tracks actual productive work seconds, pause intervals, and calculates net effective sprint duration.
                </p>
                <div className="p-4 rounded-lg bg-bg border border-border flex items-center justify-between">
                  <div>
                    <div className="text-xs text-slate-400">Current Session Active Time</div>
                    <div className="text-3xl font-mono font-bold text-primary mt-1">{formatTimer(seconds)}</div>
                  </div>
                  <button
                    onClick={() => {
                      setTimerRunning(!timerRunning);
                      showToast(timerRunning ? 'Work session paused' : 'Work session started', 'info');
                    }}
                    className={`px-4 py-2 rounded text-xs font-semibold ${
                      timerRunning ? 'bg-amber-500/20 text-amber-300 border border-amber-500/30' : 'bg-primary text-white'
                    }`}
                  >
                    {timerRunning ? 'Pause Session' : 'Resume Session'}
                  </button>
                </div>
              </div>

              <div className="bg-surface border border-border rounded-lg p-5">
                <h3 className="text-sm font-bold mb-2">Office Attendance Summary</h3>
                <p className="text-xs text-slate-400 mb-4">
                  Separate measure from task delivery — attendance confirms workplace presence while task completion measures output.
                </p>
                <div className="space-y-2 text-xs">
                  <div className="flex justify-between p-2.5 rounded bg-surface-elevated border border-border-subtle">
                    <span>Shift Type</span>
                    <span className="font-semibold text-slate-200">Standard 09:30 - 18:30 IST</span>
                  </div>
                  <div className="flex justify-between p-2.5 rounded bg-surface-elevated border border-border-subtle">
                    <span>Clock-in Status</span>
                    <span className="font-semibold text-emerald-400">{attendanceClockedIn ? 'PUNCHED IN' : 'OUT'}</span>
                  </div>
                  <div className="flex justify-between p-2.5 rounded bg-surface-elevated border border-border-subtle">
                    <span>Work Mode</span>
                    <span className="font-semibold text-slate-200">HYBRID (Bengaluru Innovation Hub)</span>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 4: PROJECTS */}
          {activeTab === 'projects' && (
            <div className="grid grid-cols-2 gap-4">
              <div className="bg-surface border border-border rounded-lg p-5">
                <div className="flex justify-between items-start">
                  <h4 className="font-bold text-sm text-slate-100">Enterprise Cloud Platform (EWMS)</h4>
                  <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-500/20 text-emerald-400">ACTIVE</span>
                </div>
                <p className="text-xs text-slate-400 mt-2">Enterprenex Solutions core modular work and employee management platform.</p>
                <div className="mt-4 pt-3 border-t border-border-subtle flex justify-between text-xs text-slate-400">
                  <span>Code: PRJ-ALPHA</span>
                  <span>Budget: ₹15,00,000</span>
                </div>
              </div>

              <div className="bg-surface border border-border rounded-lg p-5">
                <div className="flex justify-between items-start">
                  <h4 className="font-bold text-sm text-slate-100">AI Workload Prediction Engine</h4>
                  <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-blue-500/20 text-blue-400">PLANNED</span>
                </div>
                <p className="text-xs text-slate-400 mt-2">Predictive analytics module for sprint resource optimization.</p>
                <div className="mt-4 pt-3 border-t border-border-subtle flex justify-between text-xs text-slate-400">
                  <span>Code: PRJ-BETA</span>
                  <span>Budget: ₹8,50,000</span>
                </div>
              </div>
            </div>
          )}

          {/* TAB 5: PERFORMANCE & OKRs (PHASE 2) */}
          {activeTab === 'performance' && (
            <div className="space-y-6">
              {/* Signal Not Verdict Notice */}
              <div className="p-4 rounded-lg bg-primary/10 border border-primary/30 flex items-start gap-3">
                <span className="text-primary text-base">ℹ️</span>
                <div>
                  <h4 className="text-xs font-bold text-primary">Management Signal Only — Not an Automated Verdict</h4>
                  <p className="text-xs text-slate-300 mt-0.5">
                    EWMS strictly separates hours worked, attendance, and performance. KPI scores are management signals to support career growth, mentorship, and 1-on-1 reviews; never automatic decisions.
                  </p>
                </div>
              </div>

              {/* Role-Specific KPI Template Calculator */}
              <div className="bg-surface border border-border rounded-lg p-5">
                <div className="flex justify-between items-center mb-4">
                  <div>
                    <h3 className="text-sm font-bold text-slate-100">Role-Specific Weighted KPI Scorecard</h3>
                    <p className="text-xs text-slate-400">Select role template to evaluate weighted KPI distribution (Weights must equal 100%).</p>
                  </div>
                  <div className="flex gap-1.5 bg-bg p-1 rounded-md border border-border">
                    {Object.keys(ROLE_KPI_PRESETS).map(role => (
                      <button
                        key={role}
                        onClick={() => setSelectedKpiRole(role)}
                        className={`px-2.5 py-1 text-xs rounded font-medium transition ${
                          selectedKpiRole === role
                            ? 'bg-primary text-white font-semibold'
                            : 'text-slate-400 hover:text-slate-200'
                        }`}
                      >
                        {role}
                      </button>
                    ))}
                  </div>
                </div>

                <div className="grid grid-cols-3 gap-6 items-center">
                  <div className="col-span-2 space-y-3">
                    {currentKpiMetrics.map((m, idx) => (
                      <div key={idx} className="space-y-1">
                        <div className="flex justify-between text-xs">
                          <span className="text-slate-300 font-medium">{m.name}</span>
                          <span className="text-slate-400">Weight: <strong className="text-slate-200">{m.weight}%</strong> · Score: <strong className="text-primary">{m.score}/100</strong></span>
                        </div>
                        <div className="h-1.5 bg-bg rounded-full overflow-hidden">
                          <div className="h-full bg-primary" style={{ width: `${m.score}%` }}></div>
                        </div>
                      </div>
                    ))}
                  </div>

                  <div className="col-span-1 bg-surface-elevated border border-border rounded-lg p-4 text-center">
                    <div className="text-xs text-slate-400 uppercase font-semibold">Weighted KPI Score</div>
                    <div className="text-4xl font-extrabold font-mono text-emerald-400 my-2">
                      {calculatedKpiScore} <span className="text-sm font-normal text-slate-400">/ 100</span>
                    </div>
                    <div className="text-[11px] text-emerald-300 font-semibold bg-emerald-500/10 border border-emerald-500/20 py-1 px-2 rounded inline-block">
                      {Number(calculatedKpiScore) >= 90 ? 'Grade A · Outstanding' : 'Grade B · Competent'}
                    </div>
                    <div className="text-[10px] text-slate-500 mt-2">Evaluated for: Kishore Kumar (Senior Full-Stack)</div>
                  </div>
                </div>
              </div>

              {/* Company Objectives & Key Results (OKRs) */}
              <div className="bg-surface border border-border rounded-lg p-5">
                <h3 className="text-sm font-bold text-slate-100 mb-3">Objectives & Key Results (OKR) Progress Roll-up</h3>
                <div className="space-y-4">
                  <div className="p-4 rounded-lg bg-surface-elevated border border-border-subtle">
                    <div className="flex justify-between items-center mb-2">
                      <div>
                        <span className="text-[10px] px-2 py-0.5 rounded bg-blue-500/20 text-blue-400 font-bold uppercase">COMPANY OBJECTIVE</span>
                        <h4 className="text-xs font-bold text-slate-100 mt-1">Zero-Downtime Multi-Region Cloud Deployment (2026-Q2)</h4>
                      </div>
                      <span className="text-sm font-bold font-mono text-emerald-400">88.3% Completed</span>
                    </div>
                    <div className="h-2 bg-bg rounded-full overflow-hidden mb-3">
                      <div className="h-full bg-emerald-500 w-[88.3%]"></div>
                    </div>
                    <div className="grid grid-cols-3 gap-2 text-[11px] text-slate-400">
                      <div className="p-2 rounded bg-bg">✓ Multi-AZ Failover Test: <strong>100%</strong></div>
                      <div className="p-2 rounded bg-bg">✓ Edge CDN Latency &lt;35ms: <strong>85%</strong></div>
                      <div className="p-2 rounded bg-bg">✓ DR Automated Drill: <strong>80%</strong></div>
                    </div>
                  </div>

                  <div className="p-4 rounded-lg bg-surface-elevated border border-border-subtle">
                    <div className="flex justify-between items-center mb-2">
                      <div>
                        <span className="text-[10px] px-2 py-0.5 rounded bg-purple-500/20 text-purple-400 font-bold uppercase">SECURITY OBJECTIVE</span>
                        <h4 className="text-xs font-bold text-slate-100 mt-1">Achieve SOC 2 Type II Enterprise Compliance Audit</h4>
                      </div>
                      <span className="text-sm font-bold font-mono text-primary">73.3% Completed</span>
                    </div>
                    <div className="h-2 bg-bg rounded-full overflow-hidden mb-3">
                      <div className="h-full bg-primary w-[73.3%]"></div>
                    </div>
                    <div className="grid grid-cols-3 gap-2 text-[11px] text-slate-400">
                      <div className="p-2 rounded bg-bg">✓ AES-256 Sensitive Data Encryption: <strong>100%</strong></div>
                      <div className="p-2 rounded bg-bg">✓ Pen-test Vulnerability Remediations: <strong>60%</strong></div>
                      <div className="p-2 rounded bg-bg">✓ Immutable Audit Logs Verification: <strong>60%</strong></div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 6: LEAVES & TIMESHEETS (PHASE 2) */}
          {activeTab === 'leaves_timesheets' && (
            <div className="space-y-6">
              {/* Leave Balances Ledger */}
              <div className="grid grid-cols-3 gap-4">
                <div className="bg-surface border border-border rounded-lg p-5">
                  <div className="text-xs text-slate-400 uppercase font-semibold">Annual / Privilege Leave</div>
                  <div className="text-3xl font-extrabold font-mono text-slate-100 mt-2">
                    {leaveBalances.annual} <span className="text-sm font-normal text-slate-400">/ 21 Days</span>
                  </div>
                  <div className="text-[11px] text-emerald-400 mt-1">Available for planned vacations</div>
                </div>
                <div className="bg-surface border border-border rounded-lg p-5">
                  <div className="text-xs text-slate-400 uppercase font-semibold">Sick Leave Allowance</div>
                  <div className="text-3xl font-extrabold font-mono text-slate-100 mt-2">
                    {leaveBalances.sick} <span className="text-sm font-normal text-slate-400">/ 12 Days</span>
                  </div>
                  <div className="text-[11px] text-blue-400 mt-1">Medical coverage quota</div>
                </div>
                <div className="bg-surface border border-border rounded-lg p-5">
                  <div className="text-xs text-slate-400 uppercase font-semibold">Casual Leave Quota</div>
                  <div className="text-3xl font-extrabold font-mono text-slate-100 mt-2">
                    {leaveBalances.casual} <span className="text-sm font-normal text-slate-400">/ 7 Days</span>
                  </div>
                  <div className="text-[11px] text-amber-400 mt-1">Short notice personal emergencies</div>
                </div>
              </div>

              {/* Leave Requests & Review */}
              <div className="bg-surface border border-border rounded-lg p-5">
                <div className="flex justify-between items-center mb-3">
                  <h3 className="text-sm font-bold text-slate-100">Leave Applications & Approval Workflow</h3>
                  <button
                    onClick={() => {
                      if (leaveBalances.casual <= 0) {
                        showToast('No casual leave days remaining!', 'error');
                        return;
                      }
                      setLeaveBalances(b => ({ ...b, casual: b.casual - 1 }));
                      setLeaveRequests(prev => [
                        ...prev,
                        { id: `lr-${Date.now()}`, employee: user.name, type: 'CASUAL', days: 1, dates: '2026-04-20', status: 'PENDING', reason: 'Personal errand' },
                      ]);
                      showToast('Leave application submitted for approval!', 'success');
                    }}
                    className="px-3 py-1.5 bg-primary/20 hover:bg-primary/30 text-primary border border-primary/30 rounded text-xs font-semibold"
                  >
                    + Apply for Leave
                  </button>
                </div>

                <table className="w-full text-left text-xs">
                  <thead className="bg-surface-elevated text-slate-400 font-semibold border-b border-border">
                    <tr>
                      <th className="p-3">Employee</th>
                      <th className="p-3">Leave Type</th>
                      <th className="p-3">Duration</th>
                      <th className="p-3">Dates</th>
                      <th className="p-3">Reason</th>
                      <th className="p-3">Status</th>
                      <th className="p-3 text-right">Action</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border-subtle">
                    {leaveRequests.map(r => (
                      <tr key={r.id}>
                        <td className="p-3 font-semibold text-slate-200">{r.employee}</td>
                        <td className="p-3 font-mono text-slate-300">{r.type}</td>
                        <td className="p-3">{r.days} Day(s)</td>
                        <td className="p-3 text-slate-400">{r.dates}</td>
                        <td className="p-3 text-slate-400">{r.reason}</td>
                        <td className="p-3">
                          <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                            r.status === 'APPROVED' ? 'bg-emerald-500/20 text-emerald-400' : 'bg-amber-500/20 text-amber-400'
                          }`}>
                            {r.status}
                          </span>
                        </td>
                        <td className="p-3 text-right">
                          {r.status === 'PENDING' && ['DIRECTOR', 'MANAGER', 'SUPER_ADMIN', 'COMPANY_ADMIN', 'HR_ADMIN', 'TEAM_LEAD'].includes(user.role) && (
                            <button
                              onClick={() => {
                                setLeaveRequests(prev => prev.map(x => x.id === r.id ? { ...x, status: 'APPROVED' } : x));
                                showToast(`Approved leave application for ${r.employee}`, 'success');
                              }}
                              className="px-2 py-1 bg-emerald-600/30 hover:bg-emerald-600/50 text-emerald-300 border border-emerald-500/40 rounded text-[11px]"
                            >
                              Approve
                            </button>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Weekly Timesheet Review */}
              <div className="bg-surface border border-border rounded-lg p-5">
                <div className="flex justify-between items-center mb-3">
                  <div>
                    <h3 className="text-sm font-bold text-slate-100">Weekly Timesheet Submission</h3>
                    <p className="text-xs text-slate-400">Current Week: 2026-W14 (Mon - Fri)</p>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className={`px-2.5 py-1 rounded text-xs font-bold ${
                      timesheetApproved ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30' : 'bg-amber-500/20 text-amber-400 border border-amber-500/30'
                    }`}>
                      {timesheetApproved ? 'STATUS: APPROVED' : 'STATUS: SUBMITTED (PENDING REVIEW)'}
                    </span>
                    {!timesheetApproved && (
                      <button
                        onClick={() => {
                          setTimesheetApproved(true);
                          showToast('Timesheet approved by Team Lead!', 'success');
                        }}
                        className="px-3 py-1 bg-emerald-600/30 text-emerald-300 border border-emerald-500/40 rounded text-xs font-semibold"
                      >
                        Approve Timesheet
                      </button>
                    )}
                  </div>
                </div>

                <div className="grid grid-cols-5 gap-2 text-center text-xs">
                  <div className="p-3 rounded bg-surface-elevated border border-border-subtle">
                    <div className="text-slate-400">Monday</div>
                    <div className="text-base font-bold font-mono text-slate-100 mt-1">8.0h</div>
                  </div>
                  <div className="p-3 rounded bg-surface-elevated border border-border-subtle">
                    <div className="text-slate-400">Tuesday</div>
                    <div className="text-base font-bold font-mono text-slate-100 mt-1">8.5h</div>
                  </div>
                  <div className="p-3 rounded bg-surface-elevated border border-border-subtle">
                    <div className="text-slate-400">Wednesday</div>
                    <div className="text-base font-bold font-mono text-slate-100 mt-1">7.5h</div>
                  </div>
                  <div className="p-3 rounded bg-surface-elevated border border-border-subtle">
                    <div className="text-slate-400">Thursday</div>
                    <div className="text-base font-bold font-mono text-slate-100 mt-1">8.0h</div>
                  </div>
                  <div className="p-3 rounded bg-surface-elevated border border-border-subtle">
                    <div className="text-slate-400">Friday</div>
                    <div className="text-base font-bold font-mono text-slate-100 mt-1">8.0h</div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 7: COMPANY PLATFORM & COLLABORATION (PHASE 3) */}
          {activeTab === 'company_platform' && (
            <div className="space-y-6">
              {/* Documents & Knowledge Base with Access Control */}
              <div className="bg-surface border border-border rounded-lg p-5">
                <div className="flex justify-between items-center mb-3">
                  <div>
                    <h3 className="text-sm font-bold text-slate-100">Documents & Knowledge Base</h3>
                    <p className="text-xs text-slate-400">Confidential files strictly restricted to HR & Super Administrators.</p>
                  </div>
                  <button
                    onClick={() => showToast('File upload modal initialized (S3 Object Storage)', 'info')}
                    className="px-3 py-1.5 bg-primary/20 hover:bg-primary/30 text-primary border border-primary/30 rounded text-xs font-semibold"
                  >
                    + Upload Document
                  </button>
                </div>

                <div className="space-y-2">
                  <div className="flex justify-between items-center p-3 rounded bg-surface-elevated border border-border-subtle text-xs">
                    <div>
                      <div className="font-bold text-slate-200">Enterprenex Solutions Engineering Architecture Spec v2.4</div>
                      <div className="text-slate-400">Architecture, Microservices, Event Bus • Updated: 2026-03-15</div>
                    </div>
                    <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-blue-500/20 text-blue-400 border border-blue-500/30">
                      INTERNAL
                    </span>
                  </div>

                  <div className="flex justify-between items-center p-3 rounded bg-surface-elevated border border-border-subtle text-xs">
                    <div>
                      <div className="font-bold text-slate-200">Enterprenex Solutions Enterprise Security & Cryptography Guidelines</div>
                      <div className="text-slate-400">PBKDF2 Hashing, AES-256 Data-at-Rest, MFA Enforcements</div>
                    </div>
                    <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-blue-500/20 text-blue-400 border border-blue-500/30">
                      INTERNAL
                    </span>
                  </div>

                  <div className="flex justify-between items-center p-3 rounded bg-surface-elevated border border-border-subtle text-xs">
                    <div>
                      <div className="font-bold text-slate-200">
                        {['DIRECTOR', 'MANAGER', 'SUPER_ADMIN', 'COMPANY_ADMIN', 'HR_ADMIN'].includes(user.role)
                          ? 'Executive Compensation, Payroll Ledger & Cap Table 2026'
                          : '[RESTRICTED] Executive Compensation & Confidential Payroll'}
                      </div>
                      <div className="text-slate-400">
                        {['DIRECTOR', 'MANAGER', 'SUPER_ADMIN', 'COMPANY_ADMIN', 'HR_ADMIN'].includes(user.role)
                          ? 'Enterprenex Solutions Board, Executive Salary Matrix & Equity Grants'
                          : 'Requires HR_ADMIN or Tier 0 Security Clearance'}
                      </div>
                    </div>
                    <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-amber-500/20 text-amber-400 border border-amber-500/30">
                      CONFIDENTIAL
                    </span>
                  </div>
                </div>
              </div>

              {/* Meetings & Action Item to Task Conversion */}
              <div className="bg-surface border border-border rounded-lg p-5">
                <div className="flex justify-between items-center mb-3">
                  <div>
                    <h3 className="text-sm font-bold text-slate-100">Meetings & Action Item to Task Conversion</h3>
                    <p className="text-xs text-slate-400">Core Feature: Click "Convert to Task" to dispatch an action item directly onto the active Sprint Board.</p>
                  </div>
                  <button
                    onClick={() => showToast('Meeting scheduler opened', 'info')}
                    className="px-3 py-1.5 bg-surface-elevated hover:bg-surface-hover border border-border rounded text-xs"
                  >
                    + Schedule Meeting
                  </button>
                </div>

                <div className="p-4 rounded-lg bg-surface-elevated border border-border-subtle mb-4">
                  <div className="flex justify-between items-start">
                    <div>
                      <h4 className="text-xs font-bold text-slate-100">Sprint 14 Architecture & Performance Review</h4>
                      <p className="text-[11px] text-slate-400 mt-0.5">Participants: Vikram Mehra, Rahul Deshmukh, Ananya Sen, Kishore Kumar</p>
                    </div>
                    <span className="text-[10px] px-2 py-0.5 rounded bg-emerald-500/20 text-emerald-400 font-bold">COMPLETED</span>
                  </div>

                  <div className="mt-3 pt-3 border-t border-border space-y-2">
                    <div className="text-xs font-semibold text-slate-300">Meeting Action Items:</div>
                    {meetingActionItems.map(act => (
                      <div key={act.id} className="flex justify-between items-center p-2.5 rounded bg-bg border border-border text-xs">
                        <div>
                          <span className="text-slate-200 font-medium">{act.text}</span>
                          <span className="text-slate-400 ml-2">Assignee: <strong className="text-slate-300">{act.assignee}</strong></span>
                        </div>
                        <div>
                          {act.converted ? (
                            <span className="px-2 py-1 rounded text-[10px] font-bold bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
                              ✓ Converted to Task #{act.convertedTaskNum}
                            </span>
                          ) : (
                            <button
                              onClick={() => handleConvertActionItemToTask(act.id)}
                              className="px-2.5 py-1 bg-primary hover:bg-primary-hover text-white rounded text-[11px] font-semibold transition shadow-sm"
                            >
                              ⚡ Convert to Project Task
                            </button>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              {/* Project Risks Register & Health Scoring */}
              <div className="bg-surface border border-border rounded-lg p-5">
                <div className="flex justify-between items-center mb-3">
                  <div>
                    <h3 className="text-sm font-bold text-slate-100">Project Risks Register & Computed Health Score</h3>
                    <p className="text-xs text-slate-400">Formula considers task velocity, overdue delivery dates, and open severity risks.</p>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="text-xs text-slate-400">Project Health Score:</span>
                    <span className="text-sm font-extrabold font-mono text-emerald-400 bg-emerald-500/10 px-2.5 py-1 rounded border border-emerald-500/20">
                      88.0% (HEALTHY)
                    </span>
                  </div>
                </div>

                <table className="w-full text-left text-xs">
                  <thead className="bg-surface-elevated text-slate-400 font-semibold border-b border-border">
                    <tr>
                      <th className="p-3">Risk Title</th>
                      <th className="p-3">Severity</th>
                      <th className="p-3">Probability</th>
                      <th className="p-3">Mitigation Strategy</th>
                      <th className="p-3">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border-subtle">
                    {risks.map(r => (
                      <tr key={r.id}>
                        <td className="p-3 font-semibold text-slate-200">{r.title}</td>
                        <td className="p-3">
                          <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                            r.severity === 'HIGH' ? 'bg-red-500/20 text-red-400' : 'bg-amber-500/20 text-amber-400'
                          }`}>
                            {r.severity}
                          </span>
                        </td>
                        <td className="p-3 text-slate-400">{r.probability}</td>
                        <td className="p-3 text-slate-300">{r.mitigation}</td>
                        <td className="p-3">
                          <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                            r.status === 'OPEN' ? 'bg-blue-500/20 text-blue-400' : 'bg-emerald-500/20 text-emerald-400'
                          }`}>
                            {r.status}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Workflow Automation Safeguards */}
              <div className="p-4 rounded-lg bg-surface border border-border flex items-center justify-between">
                <div>
                  <h4 className="text-xs font-bold text-slate-200">Active Workflow Automation Engine Safeguards</h4>
                  <div className="flex gap-4 text-xs text-slate-400 mt-1">
                    <span className="flex items-center gap-1.5"><strong className="text-emerald-400">●</strong> Overdue Task Auto-Escalation (Active)</span>
                    <span className="flex items-center gap-1.5"><strong className="text-emerald-400">●</strong> Workload &gt;100% Protective Alerts (Active)</span>
                    <span className="flex items-center gap-1.5"><strong className="text-emerald-400">●</strong> Weekly Timesheet Auto-Reminders (Active)</span>
                  </div>
                </div>
                <button
                  onClick={() => showToast('Triggered automated workflow health scan: 0 critical escalations.', 'success')}
                  className="px-3 py-1.5 bg-surface-elevated hover:bg-surface-hover border border-border rounded text-xs font-semibold text-slate-300"
                >
                  Run Rule Scan Now
                </button>
              </div>
            </div>
          )}

          {/* TAB 8: TEAM WORKLOAD & CAPACITY */}
          {activeTab === 'team' && (
            <div className="space-y-6">
              <div className="bg-surface border border-border rounded-lg p-5">
                <h3 className="text-sm font-bold mb-3">Team Capacity Planning & Overload Prevention</h3>
                <p className="text-xs text-slate-400 mb-4">
                  Formula: (Assigned Estimated Hours / 40h Weekly Capacity) × 100.
                  Shows capacity before work assignment to prevent burnout.
                </p>
                <div className="space-y-4">
                  <div>
                    <div className="flex justify-between text-xs mb-1">
                      <span>Kishore Kumar (Senior Full-Stack) — 45h Assigned</span>
                      <span className="font-bold text-red-400">112.5% (OVERLOADED)</span>
                    </div>
                    <div className="h-2 bg-bg rounded-full overflow-hidden">
                      <div className="h-full bg-red-500 w-full"></div>
                    </div>
                  </div>
                  <div>
                    <div className="flex justify-between text-xs mb-1">
                      <span>Ananya Sen (Team Lead) — 28.8h Assigned</span>
                      <span className="font-bold text-emerald-400">72.0% (HEALTHY)</span>
                    </div>
                    <div className="h-2 bg-bg rounded-full overflow-hidden">
                      <div className="h-full bg-emerald-500 w-[72%]"></div>
                    </div>
                  </div>
                  <div>
                    <div className="flex justify-between text-xs mb-1">
                      <span>Priya Nair (Intern) — 18.0h Assigned</span>
                      <span className="font-bold text-blue-400">45.0% (AVAILABLE)</span>
                    </div>
                    <div className="h-2 bg-bg rounded-full overflow-hidden">
                      <div className="h-full bg-blue-500 w-[45%]"></div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 9: EMPLOYEES & DIRECTORY */}
          {activeTab === 'employees' && (
            <div className="bg-surface border border-border rounded-lg overflow-hidden">
              <div className="p-4 border-b border-border flex justify-between items-center">
                <h3 className="text-sm font-bold">Staff Directory & Profiles</h3>
                <span className="text-xs text-slate-400">Sensitive fields (salary, banking) masked according to RBAC.</span>
              </div>
              <div className="p-4 space-y-3">
                {DEMO_ACCOUNTS.filter(a => a.role !== 'CLIENT').map(emp => (
                  <div key={emp.email} className="flex justify-between items-center p-3 rounded bg-surface-elevated border border-border-subtle text-xs">
                    <div>
                      <div className="font-bold text-slate-200">{emp.name}</div>
                      <div className="text-slate-400">{emp.email} • {emp.role}</div>
                    </div>
                    <div className="text-right">
                      <div className="font-mono text-slate-300">
                        {['DIRECTOR', 'MANAGER', 'HR_ADMIN', 'COMPANY_ADMIN', 'SUPER_ADMIN'].includes(user.role)
                          ? 'Salary: ₹1,20,000/mo'
                          : 'Salary: [RESTRICTED]'}
                      </div>
                      <div className="text-[10px] text-slate-500">
                        {['DIRECTOR', 'MANAGER', 'HR_ADMIN', 'COMPANY_ADMIN', 'SUPER_ADMIN'].includes(user.role)
                          ? 'Bank: Decrypted (AES-256)'
                          : 'Bank: Access Prohibited'}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* TAB 10: AUDIT TRAIL */}
          {activeTab === 'audit' && (
            <div className="bg-surface border border-border rounded-lg overflow-hidden">
              <div className="p-4 border-b border-border">
                <h3 className="text-sm font-bold">Immutable Security & State Mutation Audit Logs</h3>
              </div>
              <div className="p-4 font-mono text-xs space-y-2 text-slate-300">
                <div className="p-2.5 rounded bg-bg border border-border">
                  <span className="text-blue-400">[LOGIN_SUCCESS]</span> Actor: director@enterprenex.solutions • IP: 127.0.0.1 • Role: DIRECTOR
                </div>
                <div className="p-2.5 rounded bg-bg border border-border">
                  <span className="text-amber-400">[TASK_STATUS_CHANGE]</span> Entity: TSK-102 • Before: IN_PROGRESS • After: COMPLETED
                </div>
                <div className="p-2.5 rounded bg-bg border border-border">
                  <span className="text-emerald-400">[SYSTEM_BOOTSTRAP]</span> Enterprenex Solutions tenant provisioned with 3 canonical roles (Director, Manager, Employee)
                </div>
              </div>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
