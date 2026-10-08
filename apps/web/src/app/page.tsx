'use client';

import React, { useState, useEffect } from 'react';

// Demo seed accounts for quick testing
const DEMO_ACCOUNTS = [
  { role: 'SUPER_ADMIN', name: 'Vikram Mehra', email: 'superadmin@zerocarbonix.com', badge: 'Tier 0' },
  { role: 'COMPANY_ADMIN', name: 'Aarti Sharma', email: 'admin@zerocarbonix.com', badge: 'Tier 1' },
  { role: 'HR_ADMIN', name: 'Sneha Patil', email: 'hr@zerocarbonix.com', badge: 'HR Ops' },
  { role: 'PROJECT_MANAGER', name: 'Rahul Deshmukh', email: 'pm@zerocarbonix.com', badge: 'Projects' },
  { role: 'TEAM_LEAD', name: 'Ananya Sen', email: 'lead@zerocarbonix.com', badge: 'Tech Lead' },
  { role: 'EMPLOYEE', name: 'Kishore Kumar', email: 'employee@zerocarbonix.com', badge: 'Developer' },
  { role: 'INTERN', name: 'Priya Nair', email: 'intern@zerocarbonix.com', badge: 'Intern' },
  { role: 'CLIENT', name: 'John Acme', email: 'client@acmecorp.com', badge: 'External' },
];

export default function EwmsPortal() {
  const [user, setUser] = useState<any>(null);
  const [token, setToken] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<string>('dashboard');
  const [toast, setToast] = useState<{ msg: string; type: 'info' | 'success' | 'error' } | null>(null);

  // Live Timer State
  const [timerRunning, setTimerRunning] = useState(false);
  const [seconds, setSeconds] = useState(0);

  // Form State
  const [emailInput, setEmailInput] = useState('superadmin@zerocarbonix.com');
  const [passwordInput, setPasswordInput] = useState('ZeroCarbonix@2026');

  // Dashboard Data Mock / Live Cache
  const [tasks, setTasks] = useState([
    { id: 'tsk-101', number: 'TSK-101', title: 'Design OAuth2 & JWT Schema', status: 'COMPLETED', priority: 'HIGH', estHours: 10, actualHours: 9.5, dependsOn: null },
    { id: 'tsk-102', number: 'TSK-102', title: 'Implement Authentication & RBAC API', status: 'IN_PROGRESS', priority: 'URGENT', estHours: 15, actualHours: 8.0, dependsOn: 'TSK-101' },
    { id: 'tsk-103', number: 'TSK-103', title: 'Build Web Portal & MFA Screen', status: 'ASSIGNED', priority: 'HIGH', estHours: 12, actualHours: 0, dependsOn: 'TSK-102' },
  ]);

  const [attendanceClockedIn, setAttendanceClockedIn] = useState(true);

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
        organization: 'ZeroCarbonix Technologies Pvt Ltd',
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
    setPasswordInput('ZeroCarbonix@2026');
  };

  const handleStatusChange = (taskId: string, targetStatus: string) => {
    // Task Dependency Rule Enforcement
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
            <div className="inline-flex items-center justify-center w-12 h-12 rounded-lg bg-primary/20 text-primary font-bold text-xl mb-3 border border-primary/30">
              ZC
            </div>
            <h1 className="text-xl font-bold text-slate-100 tracking-tight">ZeroCarbonix EWMS</h1>
            <p className="text-xs text-slate-400 mt-1">Employee & Work Management System • Phase 1 MVP</p>
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
              Quick Role Switcher (8 Canonical Roles)
            </span>
            <div className="grid grid-cols-4 gap-1.5">
              {DEMO_ACCOUNTS.map(acc => (
                <button
                  key={acc.role}
                  type="button"
                  onClick={() => handleQuickSelect(acc)}
                  className={`px-1.5 py-1.5 text-[10px] font-medium rounded border transition truncate text-center ${
                    emailInput === acc.email
                      ? 'bg-primary/20 border-primary text-white font-semibold'
                      : 'bg-surface-elevated border-border text-slate-300 hover:border-slate-500'
                  }`}
                  title={`${acc.name} (${acc.role})`}
                >
                  {acc.role.replace('_', ' ')}
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
            <div className="w-8 h-8 rounded bg-primary/20 border border-primary/40 flex items-center justify-center font-bold text-primary text-sm">
              ZC
            </div>
            <div>
              <div className="font-bold text-sm tracking-tight">ZeroCarbonix</div>
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

            {/* Role-Specific Admin & HR Tabs */}
            {['SUPER_ADMIN', 'COMPANY_ADMIN', 'HR_ADMIN', 'PROJECT_MANAGER', 'TEAM_LEAD'].includes(user.role) && (
              <button
                onClick={() => setActiveTab('team')}
                className={`w-full text-left px-3 py-2 rounded-md text-xs font-medium transition ${
                  activeTab === 'team' ? 'bg-primary/15 text-primary font-semibold' : 'text-slate-400 hover:bg-surface-hover hover:text-slate-200'
                }`}
              >
                Team Workload & Capacity
              </button>
            )}

            {['SUPER_ADMIN', 'COMPANY_ADMIN', 'HR_ADMIN'].includes(user.role) && (
              <button
                onClick={() => setActiveTab('employees')}
                className={`w-full text-left px-3 py-2 rounded-md text-xs font-medium transition ${
                  activeTab === 'employees' ? 'bg-primary/15 text-primary font-semibold' : 'text-slate-400 hover:bg-surface-hover hover:text-slate-200'
                }`}
              >
                Staff Directory & Profiles
              </button>
            )}

            {['SUPER_ADMIN', 'COMPANY_ADMIN'].includes(user.role) && (
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
            <h2 className="text-base font-bold capitalize">{activeTab.replace('-', ' ')}</h2>
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
        <div className="p-8 flex-1 overflow-auto">
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
                  <div className="text-2xl font-bold font-mono text-slate-100 mt-2">3 Tasks</div>
                  <div className="text-[11px] text-emerald-400 mt-1">1 In Progress · 1 Backlog</div>
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
                <span className="font-semibold text-primary">ZeroCarbonix Enterprise Protocol</span>
              </div>
            </div>
          )}

          {/* TAB 2: TASKS & DEPENDENCY FLOW */}
          {activeTab === 'tasks' && (
            <div className="bg-surface border border-border rounded-lg overflow-hidden">
              <div className="p-4 border-b border-border flex items-center justify-between">
                <h3 className="text-sm font-bold">Active Sprint Tasks & Dependency Enforcement</h3>
                <span className="text-xs text-slate-400">Task Dependency Rule: A task cannot start until its prerequisite is COMPLETED.</span>
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

          {/* TAB 3: TEAM WORKLOAD & CAPACITY */}
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

          {/* TAB 4: PROJECTS */}
          {activeTab === 'projects' && (
            <div className="grid grid-cols-2 gap-4">
              <div className="bg-surface border border-border rounded-lg p-5">
                <div className="flex justify-between items-start">
                  <h4 className="font-bold text-sm text-slate-100">Enterprise Cloud Platform (EWMS)</h4>
                  <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-500/20 text-emerald-400">ACTIVE</span>
                </div>
                <p className="text-xs text-slate-400 mt-2">ZeroCarbonix core modular work and employee management platform.</p>
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

          {/* TAB 5: EMPLOYEES & DIRECTORY */}
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
                        {['HR_ADMIN', 'COMPANY_ADMIN', 'SUPER_ADMIN'].includes(user.role)
                          ? 'Salary: ₹1,20,000/mo'
                          : 'Salary: [RESTRICTED]'}
                      </div>
                      <div className="text-[10px] text-slate-500">
                        {['HR_ADMIN', 'COMPANY_ADMIN', 'SUPER_ADMIN'].includes(user.role)
                          ? 'Bank: Decrypted (AES-256)'
                          : 'Bank: Access Prohibited'}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* TAB 6: AUDIT TRAIL */}
          {activeTab === 'audit' && (
            <div className="bg-surface border border-border rounded-lg overflow-hidden">
              <div className="p-4 border-b border-border">
                <h3 className="text-sm font-bold">Immutable Security & State Mutation Audit Logs</h3>
              </div>
              <div className="p-4 font-mono text-xs space-y-2 text-slate-300">
                <div className="p-2.5 rounded bg-bg border border-border">
                  <span className="text-blue-400">[LOGIN_SUCCESS]</span> Actor: superadmin@zerocarbonix.com • IP: 127.0.0.1 • Role: SUPER_ADMIN
                </div>
                <div className="p-2.5 rounded bg-bg border border-border">
                  <span className="text-amber-400">[TASK_STATUS_CHANGE]</span> Entity: TSK-102 • Before: IN_PROGRESS • After: COMPLETED
                </div>
                <div className="p-2.5 rounded bg-bg border border-border">
                  <span className="text-emerald-400">[SYSTEM_BOOTSTRAP]</span> ZeroCarbonix Technologies tenant provisioned with 8 roles
                </div>
              </div>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
