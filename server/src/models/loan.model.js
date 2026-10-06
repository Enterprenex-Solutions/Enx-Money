const db = require('../config/db.config');
const { generateUuid } = require('../utils/crypto.util');

class LoanModel {
  /**
   * Format database row into standard Loan object
   */
  static _formatLoan(row) {
    if (!row) return null;
    return {
      id: row.id,
      userId: row.user_id || row.userId,
      loanType: row.loan_type || row.loanType,
      principalAmount: parseFloat(row.principal_amount ?? row.principalAmount),
      interestRate: parseFloat(row.interest_rate ?? row.interestRate),
      tenureMonths: parseInt(row.tenure_months ?? row.tenureMonths, 10),
      startDate: row.start_date ? new Date(row.start_date).toISOString().split('T')[0] : (row.startDate ? new Date(row.startDate).toISOString().split('T')[0] : null),
      interestType: row.interest_type || row.interestType,
      emiAmount: parseFloat(row.emi_amount ?? row.emiAmount),
      totalInterest: parseFloat(row.total_interest ?? row.totalInterest),
      totalPayable: parseFloat(row.total_payable ?? row.totalPayable),
      status: row.status || 'Active',
      createdAt: row.created_at || row.createdAt,
      updatedAt: row.updated_at || row.updatedAt,
    };
  }

  /**
   * Create a new loan record
   */
  static async create({
    userId,
    loanType,
    principalAmount,
    interestRate,
    tenureMonths,
    startDate,
    interestType = 'Reducing',
    emiAmount,
    totalInterest,
    totalPayable,
    status = 'Active',
  }) {
    const id = generateUuid();
    const now = new Date();
    const formattedStartDate = typeof startDate === 'string' ? startDate : new Date(startDate).toISOString().split('T')[0];

    if (db.isConnected()) {
      await db.query(
        `INSERT INTO loans (
          id, user_id, loan_type, principal_amount, interest_rate,
          tenure_months, start_date, interest_type, emi_amount,
          total_interest, total_payable, status, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          id,
          userId,
          loanType,
          principalAmount,
          interestRate,
          tenureMonths,
          formattedStartDate,
          interestType,
          emiAmount,
          totalInterest,
          totalPayable,
          status,
          now,
          now,
        ]
      );
      return this.findById(id);
    }

    // In-memory fallback
    const loanRecord = {
      id,
      userId,
      user_id: userId,
      loanType,
      loan_type: loanType,
      principalAmount: parseFloat(principalAmount),
      principal_amount: parseFloat(principalAmount),
      interestRate: parseFloat(interestRate),
      interest_rate: parseFloat(interestRate),
      tenureMonths: parseInt(tenureMonths, 10),
      tenure_months: parseInt(tenureMonths, 10),
      startDate: formattedStartDate,
      start_date: formattedStartDate,
      interestType,
      interest_type: interestType,
      emiAmount: parseFloat(emiAmount),
      emi_amount: parseFloat(emiAmount),
      totalInterest: parseFloat(totalInterest),
      total_interest: parseFloat(totalInterest),
      totalPayable: parseFloat(totalPayable),
      total_payable: parseFloat(totalPayable),
      status,
      createdAt: now,
      created_at: now,
      updatedAt: now,
      updated_at: now,
    };
    db.inMemoryStore.loans.set(id, loanRecord);
    return this._formatLoan(loanRecord);
  }

  /**
   * Find loan by ID
   */
  static async findById(id) {
    if (db.isConnected()) {
      const rows = await db.query('SELECT * FROM loans WHERE id = ? LIMIT 1', [id]);
      return rows[0] ? this._formatLoan(rows[0]) : null;
    }

    // In-memory fallback
    const loan = db.inMemoryStore.loans.get(id);
    return loan ? this._formatLoan(loan) : null;
  }

  /**
   * Find loan by ID and User ID (Ownership check)
   */
  static async findByIdAndUserId(id, userId) {
    if (db.isConnected()) {
      const rows = await db.query('SELECT * FROM loans WHERE id = ? AND user_id = ? LIMIT 1', [id, userId]);
      return rows[0] ? this._formatLoan(rows[0]) : null;
    }

    // In-memory fallback
    const loan = db.inMemoryStore.loans.get(id);
    if (loan && (loan.userId === userId || loan.user_id === userId)) {
      return this._formatLoan(loan);
    }
    return null;
  }

  /**
   * Find all loans for a user with optional status filter
   */
  static async findAll({ userId, status } = {}) {
    return this.findByUserId(userId, { status });
  }

  static async findByUserId(userId, { status } = {}) {
    if (db.isConnected()) {
      let queryStr = 'SELECT * FROM loans WHERE user_id = ?';
      const params = [userId];

      if (status) {
        queryStr += ' AND status = ?';
        params.push(status);
      }

      queryStr += ' ORDER BY created_at DESC';
      const rows = await db.query(queryStr, params);
      return rows.map((row) => this._formatLoan(row));
    }

    // In-memory fallback
    const matching = [];
    for (const loan of db.inMemoryStore.loans.values()) {
      if (loan.userId === userId || loan.user_id === userId) {
        if (!status || loan.status.toLowerCase() === status.toLowerCase()) {
          matching.push(this._formatLoan(loan));
        }
      }
    }
    matching.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    return matching;
  }

  /**
   * Update loan details
   */
  static async update(id, userId, fields = {}) {
    const now = new Date();

    if (db.isConnected()) {
      const updates = [];
      const values = [];

      if (fields.loanType !== undefined) { updates.push('loan_type = ?'); values.push(fields.loanType); }
      if (fields.principalAmount !== undefined) { updates.push('principal_amount = ?'); values.push(fields.principalAmount); }
      if (fields.interestRate !== undefined) { updates.push('interest_rate = ?'); values.push(fields.interestRate); }
      if (fields.tenureMonths !== undefined) { updates.push('tenure_months = ?'); values.push(fields.tenureMonths); }
      if (fields.startDate !== undefined) { updates.push('start_date = ?'); values.push(fields.startDate); }
      if (fields.interestType !== undefined) { updates.push('interest_type = ?'); values.push(fields.interestType); }
      if (fields.emiAmount !== undefined) { updates.push('emi_amount = ?'); values.push(fields.emiAmount); }
      if (fields.totalInterest !== undefined) { updates.push('total_interest = ?'); values.push(fields.totalInterest); }
      if (fields.totalPayable !== undefined) { updates.push('total_payable = ?'); values.push(fields.totalPayable); }
      if (fields.status !== undefined) { updates.push('status = ?'); values.push(fields.status); }

      if (updates.length === 0) return this.findByIdAndUserId(id, userId);

      updates.push('updated_at = ?');
      values.push(now);

      values.push(id, userId);

      await db.query(`UPDATE loans SET ${updates.join(', ')} WHERE id = ? AND user_id = ?`, values);
      return this.findByIdAndUserId(id, userId);
    }

    // In-memory fallback
    const loan = db.inMemoryStore.loans.get(id);
    if (!loan || (loan.userId !== userId && loan.user_id !== userId)) return null;

    if (fields.loanType !== undefined) { loan.loanType = fields.loanType; loan.loan_type = fields.loanType; }
    if (fields.principalAmount !== undefined) { loan.principalAmount = parseFloat(fields.principalAmount); loan.principal_amount = parseFloat(fields.principalAmount); }
    if (fields.interestRate !== undefined) { loan.interestRate = parseFloat(fields.interestRate); loan.interest_rate = parseFloat(fields.interestRate); }
    if (fields.tenureMonths !== undefined) { loan.tenureMonths = parseInt(fields.tenureMonths, 10); loan.tenure_months = parseInt(fields.tenureMonths, 10); }
    if (fields.startDate !== undefined) { loan.startDate = fields.startDate; loan.start_date = fields.startDate; }
    if (fields.interestType !== undefined) { loan.interestType = fields.interestType; loan.interest_type = fields.interestType; }
    if (fields.emiAmount !== undefined) { loan.emiAmount = parseFloat(fields.emiAmount); loan.emi_amount = parseFloat(fields.emiAmount); }
    if (fields.totalInterest !== undefined) { loan.totalInterest = parseFloat(fields.totalInterest); loan.total_interest = parseFloat(fields.totalInterest); }
    if (fields.totalPayable !== undefined) { loan.totalPayable = parseFloat(fields.totalPayable); loan.total_payable = parseFloat(fields.totalPayable); }
    if (fields.status !== undefined) { loan.status = fields.status; }
    loan.updatedAt = now;
    loan.updated_at = now;

    db.inMemoryStore.loans.set(id, loan);
    return this._formatLoan(loan);
  }

  /**
   * Delete a loan record
   */
  static async delete(id, userId) {
    if (db.isConnected()) {
      const result = await db.query('DELETE FROM loans WHERE id = ? AND user_id = ?', [id, userId]);
      return result.affectedRows > 0;
    }

    // In-memory fallback
    const loan = db.inMemoryStore.loans.get(id);
    if (loan && (loan.userId === userId || loan.user_id === userId)) {
      db.inMemoryStore.loans.delete(id);
      // Clean up associated schedules, payments, prepayments
      for (const [schedId, sched] of db.inMemoryStore.emiSchedules.entries()) {
        if (sched.loanId === id || sched.loan_id === id) db.inMemoryStore.emiSchedules.delete(schedId);
      }
      for (const [payId, pay] of db.inMemoryStore.loanPayments.entries()) {
        if (pay.loanId === id || pay.loan_id === id) db.inMemoryStore.loanPayments.delete(payId);
      }
      for (const [prepId, prep] of db.inMemoryStore.prepayments.entries()) {
        if (prep.loanId === id || prep.loan_id === id) db.inMemoryStore.prepayments.delete(prepId);
      }
      return true;
    }
    return false;
  }
}

module.exports = LoanModel;
