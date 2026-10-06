/**
 * ENX Money — Subscription Model
 * Handles Plans, PlanFeatures, Subscriptions and Entitlement checks.
 * Supports MySQL pool + in-memory fallback.
 */

const { v4: uuidv4 } = require('uuid');
const { query, isConnected, inMemoryStore } = require('../config/db.config');

// ── Plan seed data ────────────────────────────────────────────────────────────
const PLAN_SEED = [
  { name: 'FREE',     display_name: 'Free',                 price_monthly: 0,    price_yearly: 0,     sort_order: 1 },
  { name: 'BASIC',    display_name: 'Basic — Personal Plus', price_monthly: 199,  price_yearly: 1999,  sort_order: 2 },
  { name: 'PRO',      display_name: 'Pro — Smart Finance',   price_monthly: 499,  price_yearly: 4999,  sort_order: 3 },
  { name: 'ADVANCED', display_name: 'Advanced — Business',   price_monthly: 999,  price_yearly: 9999,  sort_order: 4 },
  { name: 'BUSINESS', display_name: 'Business Suite',        price_monthly: 1999, price_yearly: 19999, sort_order: 5 },
];

// feature_code → [FREE, BASIC, PRO, ADVANCED, BUSINESS]
// true/false for BOOLEAN; number for COUNT; 'unlimited' for UNLIMITED
const FEATURE_MATRIX = {
  EXPENSE_TRACKING:     [true,  true,  true,  true,  true],
  INCOME_TRACKING:      [true,  true,  true,  true,  true],
  CUSTOM_CATEGORIES:    [false, true,  true,  true,  true],
  ADVANCED_REPORTS:     [false, false, true,  true,  true],
  BANK_ACCOUNT:         [1,     3,     10,    25,    999999],
  ACCOUNT_TRANSFER:     [false, true,  true,  true,  true],
  BUSINESS_EXPENSE:     [false, true,  true,  true,  true],
  SETTLEMENT:           [false, false, true,  true,  true],
  UPI:                  [false, true,  true,  true,  true],
  AUTOPAY:              [false, false, true,  true,  true],
  LOAN_MANAGEMENT:      [false, false, true,  true,  true],
  WHATSAPP_CHATBOT:     [false, false, true,  true,  true],
  ADVANCED_ANALYTICS:   [false, false, true,  true,  true],
  GST_REPORT:           [false, false, false, true,  true],
  INVOICE_MANAGEMENT:   [false, false, false, true,  true],
  TEAM_MEMBER:          [1,     1,     3,     10,    25],
  ROLE_MANAGEMENT:      [false, false, false, true,  true],
  ADMIN_DASHBOARD:      [false, false, false, true,  true],
  API_ACCESS:           [false, false, false, true,  true],
  PRIORITY_SUPPORT:     [false, false, false, true,  true],
};

const PLAN_ORDER = ['FREE', 'BASIC', 'PRO', 'ADVANCED', 'BUSINESS'];

function featureName(code) {
  return code.split('_').map(w => w[0] + w.slice(1).toLowerCase()).join(' ');
}

// ── Seed default plans ────────────────────────────────────────────────────────
async function seedDefaultPlans() {
  if (!isConnected()) {
    // In-memory seed
    if (inMemoryStore.subscriptionPlans.size > 0) return;
    PLAN_SEED.forEach((p, idx) => {
      const id = `plan-${p.name.toLowerCase()}`;
      inMemoryStore.subscriptionPlans.set(id, {
        id, ...p, currency: 'INR', trial_days: 0, is_active: true,
        description: `ENX Money ${p.display_name} plan`,
        created_at: new Date().toISOString(),
      });
      Object.entries(FEATURE_MATRIX).forEach(([code, vals]) => {
        const val = vals[idx];
        const fId = `pf-${p.name}-${code}`;
        const isNum = typeof val === 'number';
        inMemoryStore.planFeatures.set(fId, {
          id: fId, plan_id: id, feature_code: code, feature_name: featureName(code),
          is_enabled: isNum ? val > 0 : val,
          limit_value: isNum ? val : null,
          limit_type: isNum ? (val >= 999999 ? 'UNLIMITED' : 'COUNT') : 'BOOLEAN',
        });
      });
    });
    return;
  }

  // MySQL seed (idempotent)
  for (let idx = 0; idx < PLAN_SEED.length; idx++) {
    const p = PLAN_SEED[idx];
    const id = `plan-${p.name.toLowerCase()}`;
    await query(
      `INSERT IGNORE INTO subscription_plans
         (id, name, display_name, description, price_monthly, price_yearly, currency, trial_days, is_active, sort_order)
       VALUES (?, ?, ?, ?, ?, ?, 'INR', 0, 1, ?)`,
      [id, p.name, p.display_name, `ENX Money ${p.display_name} plan`,
       p.price_monthly, p.price_yearly, p.sort_order]
    );

    for (const [code, vals] of Object.entries(FEATURE_MATRIX)) {
      const val = vals[idx];
      const fId = `pf-${p.name}-${code}`;
      const isNum = typeof val === 'number';
      await query(
        `INSERT IGNORE INTO plan_features
           (id, plan_id, feature_code, feature_name, is_enabled, limit_value, limit_type)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [fId, id, code, featureName(code),
         isNum ? (val > 0 ? 1 : 0) : (val ? 1 : 0),
         isNum ? val : null,
         isNum ? (val >= 999999 ? 'UNLIMITED' : 'COUNT') : 'BOOLEAN']
      );
    }
  }
}

// ── Plan queries ──────────────────────────────────────────────────────────────
async function getPlans() {
  if (!isConnected()) {
    const plans = Array.from(inMemoryStore.subscriptionPlans.values())
      .sort((a, b) => a.sort_order - b.sort_order);
    return plans.map(p => ({
      ...p,
      features: Array.from(inMemoryStore.planFeatures.values())
        .filter(f => f.plan_id === p.id),
    }));
  }
  const plans = await query(
    'SELECT * FROM subscription_plans WHERE is_active = 1 ORDER BY sort_order ASC'
  );
  for (const plan of plans) {
    plan.features = await query(
      'SELECT * FROM plan_features WHERE plan_id = ?', [plan.id]
    );
  }
  return plans;
}

async function getPlanById(planId) {
  if (!isConnected()) {
    const p = inMemoryStore.subscriptionPlans.get(planId);
    if (!p) return null;
    return {
      ...p,
      features: Array.from(inMemoryStore.planFeatures.values()).filter(f => f.plan_id === planId),
    };
  }
  const [plan] = await query('SELECT * FROM subscription_plans WHERE id = ?', [planId]);
  if (!plan) return null;
  plan.features = await query('SELECT * FROM plan_features WHERE plan_id = ?', [planId]);
  return plan;
}

async function getPlanByName(name) {
  const id = `plan-${name.toLowerCase()}`;
  return getPlanById(id);
}

// ── Subscription CRUD ─────────────────────────────────────────────────────────
async function getUserSubscription(userId) {
  if (!isConnected()) {
    const subs = Array.from(inMemoryStore.subscriptions.values())
      .filter(s => s.user_id === userId)
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    const active = subs.find(s => ['ACTIVE', 'TRIALING', 'PAST_DUE'].includes(s.status));
    if (!active) {
      // Return virtual FREE plan subscription
      const freePlan = await getPlanByName('FREE');
      return { id: null, user_id: userId, plan_id: 'plan-free', plan: freePlan, status: 'ACTIVE', billing_cycle: 'MONTHLY', cancel_at_period_end: false, auto_renew: true };
    }
    const plan = await getPlanById(active.plan_id);
    return { ...active, plan };
  }
  const [sub] = await query(
    `SELECT s.*, sp.name as plan_name, sp.display_name, sp.price_monthly, sp.price_yearly
     FROM subscriptions s
     JOIN subscription_plans sp ON s.plan_id = sp.id
     WHERE s.user_id = ? AND s.status IN ('ACTIVE','TRIALING','PAST_DUE')
     ORDER BY s.created_at DESC LIMIT 1`,
    [userId]
  );
  if (!sub) {
    const freePlan = await getPlanByName('FREE');
    return { id: null, user_id: userId, plan_id: 'plan-free', plan: freePlan, status: 'ACTIVE', billing_cycle: 'MONTHLY' };
  }
  sub.plan = await getPlanById(sub.plan_id);
  return sub;
}

async function createSubscription(data) {
  const id = uuidv4();
  const sub = { id, ...data, created_at: new Date().toISOString(), updated_at: new Date().toISOString() };
  if (!isConnected()) {
    inMemoryStore.subscriptions.set(id, sub);
    return sub;
  }
  await query(
    `INSERT INTO subscriptions
       (id, user_id, plan_id, status, billing_cycle, start_date, current_period_start,
        current_period_end, trial_end, cancel_at_period_end, auto_renew,
        gateway_customer_id, gateway_subscription_id)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [id, data.user_id, data.plan_id, data.status || 'ACTIVE', data.billing_cycle || 'MONTHLY',
     data.start_date || new Date(), data.current_period_start || new Date(),
     data.current_period_end, data.trial_end || null,
     data.cancel_at_period_end || false, data.auto_renew !== false,
     data.gateway_customer_id || null, data.gateway_subscription_id || null]
  );
  return { id, ...data };
}

async function updateSubscription(id, updates) {
  if (!isConnected()) {
    const existing = inMemoryStore.subscriptions.get(id);
    if (!existing) return null;
    const updated = { ...existing, ...updates, updated_at: new Date().toISOString() };
    inMemoryStore.subscriptions.set(id, updated);
    return updated;
  }
  const fields = Object.keys(updates).map(k => `${k} = ?`).join(', ');
  const values = [...Object.values(updates), id];
  await query(`UPDATE subscriptions SET ${fields}, updated_at = NOW() WHERE id = ?`, values);
  return { id, ...updates };
}

// ── Entitlement Engine ────────────────────────────────────────────────────────
async function checkEntitlement(userId, featureCode) {
  const sub = await getUserSubscription(userId);
  const planName = sub?.plan?.name || 'FREE';
  const planIdx = PLAN_ORDER.indexOf(planName);
  if (planIdx === -1) return { allowed: false, limit: 0, planName };

  const featureVals = FEATURE_MATRIX[featureCode];
  if (!featureVals) return { allowed: true, limit: null, planName }; // unknown code → allow

  const val = featureVals[planIdx];
  if (typeof val === 'number') {
    return { allowed: val > 0, limit: val >= 999999 ? null : val, planName };
  }
  return { allowed: val === true, limit: null, planName };
}

async function checkLimit(userId, featureCode) {
  const result = await checkEntitlement(userId, featureCode);
  return result.limit; // null = unlimited, 0 = not allowed
}

async function getEntitlements(userId) {
  const sub = await getUserSubscription(userId);
  const planName = sub?.plan?.name || 'FREE';
  const planIdx = PLAN_ORDER.indexOf(planName);
  const result = {};
  for (const [code, vals] of Object.entries(FEATURE_MATRIX)) {
    const val = vals[planIdx] ?? false;
    result[code] = typeof val === 'number'
      ? { allowed: val > 0, limit: val >= 999999 ? null : val }
      : { allowed: val, limit: null };
  }
  return { planName, subscription: sub, entitlements: result };
}

module.exports = {
  seedDefaultPlans,
  getPlans,
  getPlanById,
  getPlanByName,
  getUserSubscription,
  createSubscription,
  updateSubscription,
  checkEntitlement,
  checkLimit,
  getEntitlements,
  PLAN_ORDER,
  FEATURE_MATRIX,
};
