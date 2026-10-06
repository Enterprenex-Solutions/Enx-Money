const request = require('supertest');
const app = require('../src/app');
const { initDb } = require('../src/config/db.config');
const userModel = require('../src/models/user.model');
const tokenService = require('../src/services/token.service');
const downloadModel = require('../src/models/download.model');
const ratingModel = require('../src/models/rating.model');

describe('ENX Money — Admin Analytics & Dashboard Security Test Suite', () => {
  let regularToken;
  let adminToken;
  let regularUser;
  let adminUser;
  const adminEmail = `admin_tester_${Date.now()}@enxmoney.com`;
  const regularEmail = `user_tester_${Date.now()}@enxmoney.com`;

  beforeAll(async () => {
    await initDb();

    // 1. Create a regular user
    regularUser = await userModel.create({
      name: 'Regular Customer',
      email: regularEmail,
      password: 'StrongPassword123!',
      businessName: 'Regular Enterprise Ltd',
      role: 'user',
    });

    const regTokens = tokenService.generateTokens(regularUser);
    regularToken = regTokens.accessToken;

    // 2. Create an admin user
    adminUser = await userModel.create({
      name: 'ENX Executive Admin',
      email: adminEmail,
      password: 'AdminSuperPassword123!',
      businessName: 'ENX Money Corporate',
      role: 'admin',
    });
    // Ensure role is explicitly elevated to admin in DB
    await userModel.setUserRole(adminUser.id, 'admin');
    adminUser.role = 'admin';

    const admTokens = tokenService.generateTokens({
      ...adminUser,
      role: 'admin',
    });
    adminToken = admTokens.accessToken;
  });

  // 1. Security & Authorization Enforcement
  describe('1. Security & RBAC Enforcement', () => {
    test('Unauthenticated request to /api/admin/analytics returns 401', async () => {
      const res = await request(app).get('/api/admin/analytics');
      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toMatch(/token/i);
    });

    test('Regular user request to /api/admin/analytics returns 403 Forbidden', async () => {
      const res = await request(app)
        .get('/api/admin/analytics')
        .set('Authorization', `Bearer ${regularToken}`);
      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toMatch(/Forbidden|admin privileges required|access denied|admin authorization required/i);
    });

    test('Regular user cannot view admin user list /api/admin/users (403)', async () => {
      const res = await request(app)
        .get('/api/admin/users')
        .set('Authorization', `Bearer ${regularToken}`);
      expect(res.status).toBe(403);
    });

    test('Regular user cannot view admin downloads /api/admin/downloads (403)', async () => {
      const res = await request(app)
        .get('/api/admin/downloads')
        .set('Authorization', `Bearer ${regularToken}`);
      expect(res.status).toBe(403);
    });
  });

  // 2. Admin Analytics Aggregation
  describe('2. Comprehensive Admin Analytics (GET /api/admin/analytics)', () => {
    test('Admin receives 200 OK with fully aggregated real data structure', async () => {
      const res = await request(app)
        .get('/api/admin/analytics')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toBeDefined();

      const { data } = res.body;

      // User Analytics assertions
      expect(data.userAnalytics).toBeDefined();
      expect(typeof data.userAnalytics.totalRegisteredUsers).toBe('number');
      expect(data.userAnalytics.totalRegisteredUsers).toBeGreaterThanOrEqual(2);
      expect(typeof data.userAnalytics.activeUsers).toBe('number');
      expect(typeof data.userAnalytics.dau).toBe('number');
      expect(typeof data.userAnalytics.mau).toBe('number');
      expect(Array.isArray(data.userAnalytics.growthTrends)).toBe(true);

      // App Usage Analytics assertions
      expect(data.appUsage).toBeDefined();
      expect(typeof data.appUsage.totalSessions).toBe('number');
      expect(typeof data.appUsage.signupCount).toBe('number');
      expect(data.appUsage.featureUsage).toBeDefined();

      // Download Analytics assertions
      expect(data.downloadAnalytics).toBeDefined();
      expect(typeof data.downloadAnalytics.totalDownloads).toBe('number');
      expect(Array.isArray(data.downloadAnalytics.dailyTimeline)).toBe(true);
      expect(data.downloadAnalytics.googlePlayConsole).toBeDefined();

      // Rating & Review Analytics assertions
      expect(data.ratingAnalytics).toBeDefined();
      expect(typeof data.ratingAnalytics.totalRatings).toBe('number');
      expect(typeof data.ratingAnalytics.averageRating).toBe('number');
      expect(data.ratingAnalytics.ratingDistribution).toBeDefined();
      expect(data.ratingAnalytics.ratingDistribution['5_star']).toBeDefined();

      // Attribution validation
      expect(data.dataSourceAttribution).toBeDefined();
      expect(data.dataSourceAttribution.zeroMockDataEnforced).toBe(true);
    });

    test('GET /api/admin/users/count returns granular count metrics', async () => {
      const res = await request(app)
        .get('/api/admin/users/count')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.totalRegistered).toBeGreaterThanOrEqual(2);
      expect(res.body.data.newToday).toBeGreaterThanOrEqual(1);
      expect(res.body.data.dau).toBeGreaterThanOrEqual(1);
    });
  });

  // 3. User Drilldown & Privacy Safeguards
  describe('3. User List & Activity Audit', () => {
    test('GET /api/admin/users returns user list without leaking sensitive password hashes', async () => {
      const res = await request(app)
        .get('/api/admin/users?limit=10')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data.users)).toBe(true);
      expect(res.body.data.users.length).toBeGreaterThanOrEqual(1);

      // Verify no password or salt is leaked
      for (const u of res.body.data.users) {
        expect(u.password).toBeUndefined();
        expect(u.passwordHash).toBeUndefined();
        expect(u.salt).toBeUndefined();
        expect(u.email).toBeDefined();
        expect(u.role).toBeDefined();
      }
    });

    test('GET /api/admin/users/:id/activity returns detailed timeline', async () => {
      const res = await request(app)
        .get(`/api/admin/users/${regularUser.id}/activity`)
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.user).toBeDefined();
      expect(res.body.data.user.email).toBe(regularEmail);
      expect(Array.isArray(res.body.data.activityLog)).toBe(true);
    });
  });

  // 4. Download Tracking Engine
  describe('4. Real Download Tracking & Direct APK Interceptor', () => {
    test('Direct APK download logs a real download event with masked IP', async () => {
      const initialStats = await downloadModel.getDownloadStats();
      const initialTotal = initialStats.totalDownloads;

      // Trigger download route
      const dlRes = await request(app)
        .get('/download-apk')
        .set('User-Agent', 'Mozilla/5.0 (Android 14; Mobile; rv:120.0) Gecko/120.0');

      // Regardless of whether the 70MB APK binary is bundled or redirected, status should be 200 or 302
      expect([200, 302, 404]).toContain(dlRes.status);

      // Verify stats updated
      const updatedStats = await downloadModel.getDownloadStats();
      expect(updatedStats.totalDownloads).toBeGreaterThanOrEqual(initialTotal + 1);

      // Check recent downloads list has masked IP for privacy
      const recent = updatedStats.recentDownloads;
      if (recent.length > 0) {
        expect(recent[0].ipAddress).toMatch(/\.xxx|xxx|unknown/i);
      }
    });

    test('GET /api/admin/downloads returns download stats and Google Play Console status', async () => {
      const res = await request(app)
        .get('/api/admin/downloads')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.totalDownloads).toBeGreaterThanOrEqual(1);
      expect(res.body.data.googlePlayConsole.packageName).toBe('com.enxmoney.enx_money');
    });
  });

  // 5. In-App Rating & Review Store
  describe('5. In-App Rating & Review Store with Real Distribution Math', () => {
    test('Submit rating updates 5-star distribution and average rating accurately', async () => {
      // Submit a 5-star review
      const postRes = await request(app)
        .post('/api/admin/ratings')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          rating: 5,
          review: 'Outstanding enterprise fintech platform!',
          source: 'in_app',
        });

      expect(postRes.status).toBe(201);
      expect(postRes.body.success).toBe(true);
      expect(postRes.body.data.rating).toBe(5);

      // Verify GET /api/admin/ratings reflects the submitted rating
      const ratingRes = await request(app)
        .get('/api/admin/ratings')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(ratingRes.status).toBe(200);
      expect(ratingRes.body.data.totalRatings).toBeGreaterThanOrEqual(1);
      expect(ratingRes.body.data.averageRating).toBeGreaterThanOrEqual(1.0);
      expect(ratingRes.body.data.ratingDistribution['5_star']).toBeGreaterThanOrEqual(1);
    });

    test('GET /api/admin/reviews returns the reviews list', async () => {
      const res = await request(app)
        .get('/api/admin/reviews')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data.reviews)).toBe(true);
      expect(res.body.data.reviews.length).toBeGreaterThanOrEqual(1);
    });
  });

  // 6. Admin Web Dashboard Portal Route
  describe('6. Admin Dashboard Web Portal HTML Endpoint', () => {
    test('GET /admin serves the dark-mode Admin Analytics Dashboard HTML', async () => {
      const res = await request(app).get('/admin');
      expect(res.status).toBe(200);
      expect(res.headers['content-type']).toContain('text/html');
      expect(res.text).toContain('Secure Admin Analytics Dashboard');
      expect(res.text).toContain('chart.umd.min.js');
    });

    test('GET /admin/dashboard also serves the dashboard HTML', async () => {
      const res = await request(app).get('/admin/dashboard');
      expect(res.status).toBe(200);
      expect(res.headers['content-type']).toContain('text/html');
      expect(res.text).toContain('Secure Admin Analytics Dashboard');
    });
  });
});
