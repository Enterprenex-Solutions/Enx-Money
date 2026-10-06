const db = require('../config/db.config');
const { generateUuid } = require('../utils/crypto.util');

class EmiScheduleModel {
  /**
   * Format database row into standard EMI Schedule object
   */
  static _formatSchedule(row) {
    if (!row) return null;
    return {
      id: row.id,
      loanId: row.loan_id || row.loanId,
      installmentNumber: parseInt(row.installment_number ?? row.installmentNumber, 10),
      dueDate: row.due_date ? new Date(row.due_date).toISOString().split('T')[0] : (row.dueDate ? new Date(row.dueDate).toISOString().split('T')[0] : null),
      openingBalance: parseFloat(row.opening_balance ?? row.openingBalance),
      principalAmount: parseFloat(row.principal_amount ?? row.principalAmount),
      interestAmount: parseFloat(row.interest_amount ?? row.interestAmount),
      emiAmount: parseFloat(row.emi_amount ?? row.emiAmount),
      closingBalance: parseFloat(row.closing_balance ?? row.closingBalance),
      status: row.status || 'Pending',
      paidDate: row.paid_date || row.paidDate || null,
      lateFee: parseFloat(row.late_fee ?? row.lateFee ?? 0),
      createdAt: row.created_at || row.createdAt,
      updatedAt: row.updated_at || row.updatedAt,
    };
  }

  /**
   * Bulk insert generated EMI schedule entries for a loan
   */
  static async bulkCreate(schedules = []) {
    if (!schedules.length) return [];

    const now = new Date();
    const createdRecords = [];

    if (db.isConnected()) {
      const values = [];
      const placeholders = [];

      for (const item of schedules) {
        const id = item.id || generateUuid();
        const formattedDueDate = typeof item.dueDate === 'string' ? item.dueDate : new Date(item.dueDate).toISOString().split('T')[0];
        
        values.push(
          id,
          item.loanId,
          item.installmentNumber,
          formattedDueDate,
          item.openingBalance,
          item.principalAmount,
          item.interestAmount,
          item.emiAmount,
          item.closingBalance,
          item.status || 'Pending',
          item.paidDate || null,
          item.lateFee || 0.0,
          now,
          now
        );
        placeholders.push('(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
      }

      const sql = `
        INSERT INTO emi_schedules (
          id, loan_id, installment_number, due_date, opening_balance,
          principal_amount, interest_amount, emi_amount, closing_balance,
          status, paid_date, late_fee, created_at, updated_at
        ) VALUES ${placeholders.join(', ')}
      `;

      await db.query(sql, values);
      return this.findByLoanId(schedules[0].loanId);
    }

    // In-memory fallback
    for (const item of schedules) {
      const id = item.id || generateUuid();
      const formattedDueDate = typeof item.dueDate === 'string' ? item.dueDate : new Date(item.dueDate).toISOString().split('T')[0];

      const record = {
        id,
        loanId: item.loanId,
        loan_id: item.loanId,
        installmentNumber: parseInt(item.installmentNumber, 10),
        installment_number: parseInt(item.installmentNumber, 10),
        dueDate: formattedDueDate,
        due_date: formattedDueDate,
        openingBalance: parseFloat(item.openingBalance),
        opening_balance: parseFloat(item.openingBalance),
        principalAmount: parseFloat(item.principalAmount),
        principal_amount: parseFloat(item.principalAmount),
        interestAmount: parseFloat(item.interestAmount),
        interest_amount: parseFloat(item.interestAmount),
        emiAmount: parseFloat(item.emiAmount),
        emi_amount: parseFloat(item.emiAmount),
        closingBalance: parseFloat(item.closingBalance),
        closing_balance: parseFloat(item.closingBalance),
        status: item.status || 'Pending',
        paidDate: item.paidDate || null,
        paid_date: item.paidDate || null,
        lateFee: parseFloat(item.lateFee || 0),
        late_fee: parseFloat(item.lateFee || 0),
        createdAt: now,
        created_at: now,
        updatedAt: now,
        updated_at: now,
      };
      db.inMemoryStore.emiSchedules.set(id, record);
      createdRecords.push(this._formatSchedule(record));
    }

    createdRecords.sort((a, b) => a.installmentNumber - b.installmentNumber);
    return createdRecords;
  }

  /**
   * Find EMI schedule list by loan ID
   */
  static async findByLoanId(loanId) {
    if (db.isConnected()) {
      const rows = await db.query(
        'SELECT * FROM emi_schedules WHERE loan_id = ? ORDER BY installment_number ASC',
        [loanId]
      );
      return rows.map((row) => this._formatSchedule(row));
    }

    // In-memory fallback
    const matching = [];
    for (const item of db.inMemoryStore.emiSchedules.values()) {
      if (item.loanId === loanId || item.loan_id === loanId) {
        matching.push(this._formatSchedule(item));
      }
    }
    matching.sort((a, b) => a.installmentNumber - b.installmentNumber);
    return matching;
  }

  /**
   * Find EMI schedule entry by ID
   */
  static async findById(id) {
    if (db.isConnected()) {
      const rows = await db.query('SELECT * FROM emi_schedules WHERE id = ? LIMIT 1', [id]);
      return rows[0] ? this._formatSchedule(rows[0]) : null;
    }

    // In-memory fallback
    const item = db.inMemoryStore.emiSchedules.get(id);
    return item ? this._formatSchedule(item) : null;
  }

  /**
   * Find specific installment by loan ID and installment number
   */
  static async findByLoanIdAndInstallment(loanId, installmentNumber) {
    if (db.isConnected()) {
      const rows = await db.query(
        'SELECT * FROM emi_schedules WHERE loan_id = ? AND installment_number = ? LIMIT 1',
        [loanId, installmentNumber]
      );
      return rows[0] ? this._formatSchedule(rows[0]) : null;
    }

    // In-memory fallback
    for (const item of db.inMemoryStore.emiSchedules.values()) {
      if (
        (item.loanId === loanId || item.loan_id === loanId) &&
        (item.installmentNumber === installmentNumber || item.installment_number === installmentNumber)
      ) {
        return this._formatSchedule(item);
      }
    }
    return null;
  }

  /**
   * Find the next upcoming/pending EMI for a loan
   */
  static async findNextPendingEmi(loanId) {
    if (db.isConnected()) {
      const rows = await db.query(
        `SELECT * FROM emi_schedules 
         WHERE loan_id = ? AND status IN ('Pending', 'Overdue')
         ORDER BY installment_number ASC 
         LIMIT 1`,
        [loanId]
      );
      return rows[0] ? this._formatSchedule(rows[0]) : null;
    }

    // In-memory fallback
    const pending = [];
    for (const item of db.inMemoryStore.emiSchedules.values()) {
      if (
        (item.loanId === loanId || item.loan_id === loanId) &&
        (item.status === 'Pending' || item.status === 'Overdue')
      ) {
        pending.push(this._formatSchedule(item));
      }
    }
    pending.sort((a, b) => a.installmentNumber - b.installmentNumber);
    return pending[0] || null;
  }

  /**
   * Update payment status of an EMI schedule item
   */
  static async updateStatus(id, { status, paidDate, lateFee }) {
    const now = new Date();

    if (db.isConnected()) {
      const updates = [];
      const values = [];

      if (status !== undefined) { updates.push('status = ?'); values.push(status); }
      if (paidDate !== undefined) { updates.push('paid_date = ?'); values.push(paidDate); }
      if (lateFee !== undefined) { updates.push('late_fee = ?'); values.push(lateFee); }

      if (updates.length === 0) return this.findById(id);

      updates.push('updated_at = ?');
      values.push(now);
      values.push(id);

      await db.query(`UPDATE emi_schedules SET ${updates.join(', ')} WHERE id = ?`, values);
      return this.findById(id);
    }

    // In-memory fallback
    const item = db.inMemoryStore.emiSchedules.get(id);
    if (!item) return null;

    if (status !== undefined) item.status = status;
    if (paidDate !== undefined) { item.paidDate = paidDate; item.paid_date = paidDate; }
    if (lateFee !== undefined) { item.lateFee = parseFloat(lateFee); item.late_fee = parseFloat(lateFee); }
    item.updatedAt = now;
    item.updated_at = now;

    db.inMemoryStore.emiSchedules.set(id, item);
    return this._formatSchedule(item);
  }

  /**
   * Find upcoming EMIs for a specific loan
   */
  static async findUpcomingByLoanId(loanId, daysAhead = 30) {
    const today = new Date().toISOString().split('T')[0];
    const futureDate = new Date(Date.now() + daysAhead * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

    if (db.isConnected()) {
      const rows = await db.query(
        `SELECT * FROM emi_schedules 
         WHERE loan_id = ? AND status = 'Pending' AND due_date >= ? AND due_date <= ?
         ORDER BY due_date ASC`,
        [loanId, today, futureDate]
      );
      return rows.map((row) => this._formatSchedule(row));
    }

    // In-memory fallback
    const upcoming = [];
    for (const item of db.inMemoryStore.emiSchedules.values()) {
      if (
        (item.loanId === loanId || item.loan_id === loanId) &&
        item.status === 'Pending' &&
        item.dueDate >= today &&
        item.dueDate <= futureDate
      ) {
        upcoming.push(this._formatSchedule(item));
      }
    }
    upcoming.sort((a, b) => new Date(a.dueDate) - new Date(b.dueDate));
    return upcoming;
  }

  /**
   * Find overdue EMIs for a specific loan
   */
  static async findOverdueByLoanId(loanId) {
    const today = new Date().toISOString().split('T')[0];

    if (db.isConnected()) {
      const rows = await db.query(
        `SELECT * FROM emi_schedules 
         WHERE loan_id = ? AND (status = 'Overdue' OR (status = 'Pending' AND due_date < ?))
         ORDER BY due_date ASC`,
        [loanId, today]
      );
      return rows.map((row) => this._formatSchedule(row));
    }

    // In-memory fallback
    const overdue = [];
    for (const item of db.inMemoryStore.emiSchedules.values()) {
      if (
        (item.loanId === loanId || item.loan_id === loanId) &&
        (item.status === 'Overdue' || (item.status === 'Pending' && item.dueDate < today))
      ) {
        overdue.push(this._formatSchedule(item));
      }
    }
    overdue.sort((a, b) => new Date(a.dueDate) - new Date(b.dueDate));
    return overdue;
  }

  /**
   * Find upcoming EMIs across all active loans for a user
   */
  static async findUpcomingByUserId(userId, daysAhead = 30) {
    const today = new Date().toISOString().split('T')[0];
    const futureDate = new Date(Date.now() + daysAhead * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

    if (db.isConnected()) {
      const rows = await db.query(
        `SELECT s.*, l.loan_type, l.principal_amount as loan_principal, l.interest_rate, l.emi_amount as loan_emi
         FROM emi_schedules s
         JOIN loans l ON s.loan_id = l.id
         WHERE l.user_id = ? AND l.status = 'Active' AND s.status = 'Pending' 
           AND s.due_date >= ? AND s.due_date <= ?
         ORDER BY s.due_date ASC`,
        [userId, today, futureDate]
      );
      return rows.map((row) => ({
        ...this._formatSchedule(row),
        loanType: row.loan_type,
        loanPrincipal: parseFloat(row.loan_principal),
        interestRate: parseFloat(row.interest_rate),
      }));
    }

    // In-memory fallback
    const userLoans = Array.from(db.inMemoryStore.loans.values()).filter(
      (l) => (l.userId === userId || l.user_id === userId) && l.status === 'Active'
    );
    const loanMap = new Map(userLoans.map((l) => [l.id, l]));

    const upcoming = [];
    for (const item of db.inMemoryStore.emiSchedules.values()) {
      const loan = loanMap.get(item.loanId || item.loan_id);
      if (
        loan &&
        item.status === 'Pending' &&
        item.dueDate >= today &&
        item.dueDate <= futureDate
      ) {
        upcoming.push({
          ...this._formatSchedule(item),
          loanType: loan.loanType || loan.loan_type,
          loanPrincipal: parseFloat(loan.principalAmount || loan.principal_amount),
          interestRate: parseFloat(loan.interestRate || loan.interest_rate),
        });
      }
    }
    upcoming.sort((a, b) => new Date(a.dueDate) - new Date(b.dueDate));
    return upcoming;
  }

  /**
   * Find overdue EMIs across all active loans for a user
   */
  static async findOverdueByUserId(userId) {
    const today = new Date().toISOString().split('T')[0];

    if (db.isConnected()) {
      const rows = await db.query(
        `SELECT s.*, l.loan_type, l.principal_amount as loan_principal, l.interest_rate, l.emi_amount as loan_emi
         FROM emi_schedules s
         JOIN loans l ON s.loan_id = l.id
         WHERE l.user_id = ? AND l.status = 'Active' 
           AND (s.status = 'Overdue' OR (s.status = 'Pending' AND s.due_date < ?))
         ORDER BY s.due_date ASC`,
        [userId, today]
      );
      return rows.map((row) => ({
        ...this._formatSchedule(row),
        loanType: row.loan_type,
        loanPrincipal: parseFloat(row.loan_principal),
        interestRate: parseFloat(row.interest_rate),
      }));
    }

    // In-memory fallback
    const userLoans = Array.from(db.inMemoryStore.loans.values()).filter(
      (l) => (l.userId === userId || l.user_id === userId) && l.status === 'Active'
    );
    const loanMap = new Map(userLoans.map((l) => [l.id, l]));

    const overdue = [];
    for (const item of db.inMemoryStore.emiSchedules.values()) {
      const loan = loanMap.get(item.loanId || item.loan_id);
      if (
        loan &&
        (item.status === 'Overdue' || (item.status === 'Pending' && item.dueDate < today))
      ) {
        overdue.push({
          ...this._formatSchedule(item),
          loanType: loan.loanType || loan.loan_type,
          loanPrincipal: parseFloat(loan.principalAmount || loan.principal_amount),
          interestRate: parseFloat(loan.interestRate || loan.interest_rate),
        });
      }
    }
    overdue.sort((a, b) => new Date(a.dueDate) - new Date(b.dueDate));
    return overdue;
  }

  /**
   * Delete all schedule items for a loan (used when recalculating schedules after prepayment)
   */
  static async deleteByLoanId(loanId) {
    if (db.isConnected()) {
      await db.query('DELETE FROM emi_schedules WHERE loan_id = ?', [loanId]);
      return true;
    }

    // In-memory fallback
    for (const [id, item] of db.inMemoryStore.emiSchedules.entries()) {
      if (item.loanId === loanId || item.loan_id === loanId) {
        db.inMemoryStore.emiSchedules.delete(id);
      }
    }
    return true;
  }

  /**
   * Delete only pending and overdue schedule items for a loan (preserving paid history during prepayment recalculation)
   */
  static async deletePendingByLoanId(loanId) {
    if (db.isConnected()) {
      await db.query("DELETE FROM emi_schedules WHERE loan_id = ? AND status != 'Paid'", [loanId]);
      return true;
    }

    // In-memory fallback
    for (const [id, item] of db.inMemoryStore.emiSchedules.entries()) {
      if ((item.loanId === loanId || item.loan_id === loanId) && item.status !== 'Paid') {
        db.inMemoryStore.emiSchedules.delete(id);
      }
    }
    return true;
  }
}

module.exports = EmiScheduleModel;
