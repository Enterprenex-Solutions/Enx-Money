const request = require('supertest');
const app = require('../src/app');
const TokenService = require('../src/services/token.service');
const FinanceProfileModel = require('../src/models/financeProfile.model');
const TransactionModel = require('../src/models/transaction.model');

describe('ENX Money — Business Expense Management Tests', () => {
  let authToken;
  const testUserId = 88888;
  let testAccountId;

  beforeAll(async () => {
    authToken = TokenService.signAccessToken({ id: testUserId, email: 'expense.tester@enxmoney.com' });

    // Create a business account with initial balance of 50000
    const account = await FinanceProfileModel.createAccount(testUserId, {
      mode: 'BUSINESS',
      accountName: 'Business Current Account',
      bankName: 'HDFC Bank',
      accountNumber: 'XXXX8888',
      accountType: 'Bank',
      balance: 50000,
    });
    testAccountId = account.id;
  });

  describe('Categories Endpoint', () => {
    it('GET /api/v1/expenses/categories should return standard business expense categories', async () => {
      const res = await request(app)
        .get('/api/v1/expenses/categories')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data).toContain('Rent & Facility');
      expect(res.body.data).toContain('Vendor & Supplier');
      expect(res.body.data).toContain('Utilities & Bills');
    });
  });

  describe('Expense Lifecycle & Account Balance Integration', () => {
    let createdExpenseId;

    it('POST /api/v1/expenses should record an expense and debit the linked account balance', async () => {
      const expensePayload = {
        title: 'Office Cloud Server & SaaS',
        amount: 5000,
        category: 'Software & Tech Subscriptions',
        accountId: testAccountId,
        paymentMode: 'BANK_TRANSFER',
        status: 'PAID',
        gstRate: 18,
        supplierName: 'AWS Cloud Services',
        invoiceNumber: 'INV-2026-001',
        date: new Date().toISOString(),
      };

      const res = await request(app)
        .post('/api/v1/expenses')
        .set('Authorization', `Bearer ${authToken}`)
        .send(expensePayload);

      expect(res.statusCode).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('id');
      expect(res.body.data.amount).toBe(5000);
      expect(res.body.data.accountType).toBe('BUSINESS');
      expect(res.body.data.type).toBe('DEBIT');
      expect(res.body.data.taxableAmount).toBeCloseTo(4237.29, 1);
      expect(res.body.data.totalGst).toBeCloseTo(762.71, 1);

      createdExpenseId = res.body.data.id;

      // Verify account balance was debited: 50,000 - 5,000 = 45,000
      const account = await FinanceProfileModel.getAccountById(testAccountId);
      expect(account.balance).toBe(45000);
    });

    it('GET /api/v1/expenses/summary should calculate total, this month, and today amounts', async () => {
      const res = await request(app)
        .get('/api/v1/expenses/summary?mode=BUSINESS')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.totalExpenses).toBeGreaterThanOrEqual(5000);
      expect(res.body.data.thisMonthExpenses).toBeGreaterThanOrEqual(5000);
      expect(res.body.data.todayExpenses).toBeGreaterThanOrEqual(5000);
      expect(res.body.data.expenseCount).toBeGreaterThanOrEqual(1);
    });

    it('GET /api/v1/expenses should retrieve list filtered by category and search', async () => {
      const res = await request(app)
        .get('/api/v1/expenses')
        .query({
          category: 'Software & Tech Subscriptions',
          search: 'Cloud',
        })
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.length).toBeGreaterThanOrEqual(1);
      expect(res.body.data[0].id).toBe(createdExpenseId);
    });

    it('PUT /api/v1/expenses/:id should update amount and adjust account balance accordingly', async () => {
      // Update amount from 5000 to 6000 (an extra 1000 debited, balance should become 44000)
      const res = await request(app)
        .put(`/api/v1/expenses/${createdExpenseId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: 6000,
          title: 'Office Cloud Server & Dedicated IP',
        });

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.amount).toBe(6000);

      const account = await FinanceProfileModel.getAccountById(testAccountId);
      expect(account.balance).toBe(44000);
    });

    it('DELETE /api/v1/expenses/:id should delete expense and refund balance', async () => {
      const res = await request(app)
        .delete(`/api/v1/expenses/${createdExpenseId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);

      // Account balance should be refunded back to 50000
      const account = await FinanceProfileModel.getAccountById(testAccountId);
      expect(account.balance).toBe(50000);

      // Verify expense no longer exists
      const getRes = await request(app)
        .get(`/api/v1/expenses/${createdExpenseId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(getRes.statusCode).toBe(404);
    });
  });

  describe('Business vs Personal Expense Isolation', () => {
    it('Personal expenses must not appear in business expenses', async () => {
      // Create a personal expense for testUserId
      await TransactionModel.create({
        userId: testUserId,
        accountType: 'PERSONAL',
        type: 'DEBIT',
        category: 'Personal Groceries',
        amount: 2500,
        date: new Date().toISOString(),
        note: 'Supermarket Shopping',
        referenceType: 'PERSONAL_EXPENSE',
      });

      // Query business expenses
      const res = await request(app)
        .get('/api/v1/expenses?mode=BUSINESS')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.statusCode).toBe(200);
      const hasPersonalItem = res.body.data.some(
        (tx) => tx.category === 'Personal Groceries' || tx.accountType === 'PERSONAL'
      );
      expect(hasPersonalItem).toBe(false);
    });
  });
});
