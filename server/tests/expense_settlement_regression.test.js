const request = require('supertest');
const app = require('../src/app');
const TokenService = require('../src/services/token.service');
const FinanceProfileModel = require('../src/models/financeProfile.model');

describe('Business Expense Settlement Regression Tests', () => {
  const userId = 99991;
  let token;
  let accountA;
  let accountB;

  beforeEach(async () => {
    token = TokenService.signAccessToken({
      id: userId,
      email: 'settlement.tester@enxmoney.com',
    });

    accountA = await FinanceProfileModel.createAccount(userId, {
      mode: 'BUSINESS',
      accountName: 'Test Bank Account',
      accountType: 'Bank',
      balance: 10000,
    });

    accountB = await FinanceProfileModel.createAccount(userId, {
      mode: 'BUSINESS',
      accountName: 'Test Cash Account',
      accountType: 'Cash',
      balance: 20000,
    });
  });

  async function getBalance(accountId) {
    const account = await FinanceProfileModel.getAccountById(accountId);
    return account.balance;
  }

  async function createExpense(status = 'PAID', accountId = accountA.id) {
    const res = await request(app)
      .post('/api/v1/expenses')
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'Settlement Regression Test',
        amount: 1000,
        category: 'Office Supplies & Equipment',
        accountId,
        status,
        paymentMode: accountId === accountB.id ? 'CASH' : 'BANK_TRANSFER',
        mode: 'BUSINESS',
      });

    expect(res.statusCode).toBe(201);
    return res.body.data.id;
  }

  async function updateExpense(id, updates) {
    const res = await request(app)
      .put(`/api/v1/expenses/${id}`)
      .set('Authorization', `Bearer ${token}`)
      .send(updates);

    expect(res.statusCode).toBe(200);
  }

  async function deleteExpense(id) {
    const res = await request(app)
      .delete(`/api/v1/expenses/${id}`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.statusCode).toBe(200);
  }

  test('Paid expense should debit bank account exactly once', async () => {
    await createExpense();
    expect(await getBalance(accountA.id)).toBe(9000);
  });

  test('Switching accounts should refund old account and debit new account', async () => {
    const id = await createExpense();

    await updateExpense(id, {
      accountId: accountB.id,
      amount: 1000,
      paymentMode: 'CASH',
      status: 'PAID',
    });

    expect(await getBalance(accountA.id)).toBe(10000);
    expect(await getBalance(accountB.id)).toBe(19000);
  });

  test('Pending expense should not debit account', async () => {
    await createExpense('PENDING');
    expect(await getBalance(accountA.id)).toBe(10000);
  });

  test('Pending to paid should debit account exactly once', async () => {
    const id = await createExpense('PENDING');

    await updateExpense(id, { status: 'PAID' });

    expect(await getBalance(accountA.id)).toBe(9000);
  });

  test('Paid to pending should restore account balance', async () => {
    const id = await createExpense();

    await updateExpense(id, { status: 'PENDING' });

    expect(await getBalance(accountA.id)).toBe(10000);
  });

  test('Deleting pending expense should not increase balance', async () => {
    const id = await createExpense('PENDING');

    await deleteExpense(id);

    expect(await getBalance(accountA.id)).toBe(10000);
  });

  test('Repeated paid updates should not cause extra deductions', async () => {
    const id = await createExpense();

    await updateExpense(id, { status: 'PAID', amount: 1000 });
    await updateExpense(id, { status: 'PAID', amount: 1000 });

    expect(await getBalance(accountA.id)).toBe(9000);
  });

  test('Deleting expense after paid update should refund exactly once', async () => {
    const id = await createExpense();

    await updateExpense(id, { status: 'PAID' });
    await deleteExpense(id);

    expect(await getBalance(accountA.id)).toBe(10000);
  });

  test('Cash expense should debit selected cash account only', async () => {
    await createExpense('PAID', accountB.id);

    expect(await getBalance(accountA.id)).toBe(10000);
    expect(await getBalance(accountB.id)).toBe(19000);
  });
});

describe('Expense Amount Validation and Precision', () => {
  let account, token;

  beforeEach(async () => {
    const userId = 99998;

    token = TokenService.signAccessToken({
      id: userId,
      email: 'amount.validation@example.com',
    });

    account = await FinanceProfileModel.createAccount(userId, {
      mode: 'BUSINESS',
      accountType: 'Bank',
      balance: 10000,
    });
  });

  function createExpense(amount) {
    return request(app)
      .post('/api/v1/expenses')
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'Amount Validation Test',
        amount,
        category: 'Office Supplies & Equipment',
        accountId: account.id,
        status: 'PAID',
        mode: 'BUSINESS',
      });
  }

  test.each(['Infinity', '-Infinity', 'NaN', 0, -100, 0.001])(
    'Reject invalid expense creation amount: %s',
    async (amount) => {
      const res = await createExpense(amount);

      expect(res.statusCode).toBe(400);
      expect(account.balance).toBe(10000);
    }
  );

  test.each(['Infinity', '-Infinity', 'NaN', 0, -100, 0.001])(
    'Reject invalid expense update amount: %s',
    async (amount) => {
      const created = await createExpense(1000);
      expect(created.statusCode).toBe(201);

      const id = created.body.data.id;

      const res = await request(app)
        .put(`/api/v1/expenses/${id}`)
        .set('Authorization', `Bearer ${token}`)
        .send({ amount });

      expect(res.statusCode).toBe(400);
      expect(account.balance).toBe(9000);

      const saved = await request(app)
        .get(`/api/v1/expenses/${id}`)
        .set('Authorization', `Bearer ${token}`);

      expect(saved.statusCode).toBe(200);
      expect(saved.body.data.amount).toBe(1000);
    }
  );

  test('Decimal update must match stored amount and account balance', async () => {
    const created = await createExpense(1000);
    expect(created.statusCode).toBe(201);

    const id = created.body.data.id;

    const updated = await request(app)
      .put(`/api/v1/expenses/${id}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ amount: 100.125 });

    expect(updated.statusCode).toBe(200);
    expect(updated.body.data.amount).toBe(100.13);
    expect(account.balance).toBe(9899.87);

    const deleted = await request(app)
      .delete(`/api/v1/expenses/${id}`)
      .set('Authorization', `Bearer ${token}`);

    expect(deleted.statusCode).toBe(200);
    expect(account.balance).toBe(10000);
  });
});

describe('Expense GST Consistency', () => {
  const userId = 99999;
  let token;
  let accountId;

  beforeEach(async () => {
    token = TokenService.generateAccessToken({
      id: userId,
      email: 'expense.gst@example.com',
    });

    const account = await FinanceProfileModel.createAccount(userId, {
      mode: 'BUSINESS',
      accountType: 'Bank',
      accountName: 'GST Test Account',
      openingBalance: 10000,
    });

    accountId = account.id;
  });

  async function createGstExpense() {
    return request(app)
      .post('/api/v1/expenses')
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'GST Test Expense',
        amount: 5000,
        category: 'Office Supplies & Equipment',
        accountId,
        status: 'PAID',
        mode: 'BUSINESS',
        gstRate: 18,
      });
  }

  test('CGST and SGST must equal total GST', async () => {
    const res = await createGstExpense();

    expect(res.statusCode).toBe(201);

    const tx = res.body.data;

    expect(tx.cgst + tx.sgst + tx.igst)
      .toBeCloseTo(tx.totalGst, 2);

    expect(tx.taxableAmount + tx.totalGst)
      .toBeCloseTo(tx.amount, 2);
  });

  test('Amount update must maintain GST consistency', async () => {
    const created = await createGstExpense();

    expect(created.statusCode).toBe(201);

    const res = await request(app)
      .put(`/api/v1/expenses/${created.body.data.id}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ amount: 6000 });

    expect(res.statusCode).toBe(200);

    const tx = res.body.data;

    expect(tx.taxableAmount).toBeCloseTo(5084.75, 2);
    expect(tx.totalGst).toBeCloseTo(915.25, 2);
    expect(tx.cgst + tx.sgst + tx.igst)
      .toBeCloseTo(tx.totalGst, 2);

    const account = await FinanceProfileModel.getAccountById(
      accountId, userId
    );

    expect(account.balance).toBe(4000);
  });
});
