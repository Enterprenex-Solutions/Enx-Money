const db = require('../config/db.config');
const { generateUuid } = require('../utils/crypto.util');

class LoanPaymentModel {
  /**
   * Format database row into standard Loan Payment object
   */
  static _formatPayment(row) {
    if (!row) return null;
    return {
      id: row.id,
      loanId: row.loan_id || row.loanId,
      emiScheduleId: row.emi_schedule_id || row.emiScheduleId || null,
      amount: parseFloat(row.amount),
      paymentDate: row.payment_date || row.paymentDate,
      paymentType: row.payment_type || row.paymentType || 'EMI',
      lateFee: parseFloat(row.late_fee ?? row.lateFee ?? 0),
      notes: row.notes || null,
      createdAt: row.created_at || row.createdAt,
    };
  }

  /**
   * Record a new loan payment
   */
  static async create({
    loanId,
    emiScheduleId = null,
    amount,
    paymentDate,
    paymentType = 'EMI',
    lateFee = 0,
    notes = null,
  }) {
    const id = generateUuid();
    const date = paymentDate ? new Date(paymentDate) : new Date();

    if (db.isConnected()) {
      await db.query(
        `INSERT INTO loan_payments (
          id, loan_id, emi_schedule_id, amount, payment_date,
          payment_type, late_fee, notes, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          id,
          loanId,
          emiScheduleId,
          amount,
          date,
          paymentType,
          lateFee,
          notes,
          date,
        ]
      );
      return this.findById(id);
    }

    // In-memory fallback
    const paymentRecord = {
      id,
      loanId,
      loan_id: loanId,
      emiScheduleId,
      emi_schedule_id: emiScheduleId,
      amount: parseFloat(amount),
      paymentDate: date,
      payment_date: date,
      paymentType,
      payment_type: paymentType,
      lateFee: parseFloat(lateFee || 0),
      late_fee: parseFloat(lateFee || 0),
      notes,
      createdAt: date,
      created_at: date,
    };
    db.inMemoryStore.loanPayments.set(id, paymentRecord);
    return this._formatPayment(paymentRecord);
  }

  /**
   * Find payment by ID
   */
  static async findById(id) {
    if (db.isConnected()) {
      const rows = await db.query('SELECT * FROM loan_payments WHERE id = ? LIMIT 1', [id]);
      return rows[0] ? this._formatPayment(rows[0]) : null;
    }

    // In-memory fallback
    const payment = db.inMemoryStore.loanPayments.get(id);
    return payment ? this._formatPayment(payment) : null;
  }

  /**
   * Find all payments for a loan
   */
  static async findByLoanId(loanId) {
    if (db.isConnected()) {
      const rows = await db.query(
        'SELECT * FROM loan_payments WHERE loan_id = ? ORDER BY payment_date DESC, created_at DESC',
        [loanId]
      );
      return rows.map((row) => this._formatPayment(row));
    }

    // In-memory fallback
    const matching = [];
    for (const payment of db.inMemoryStore.loanPayments.values()) {
      if (payment.loanId === loanId || payment.loan_id === loanId) {
        matching.push(this._formatPayment(payment));
      }
    }
    matching.sort((a, b) => new Date(b.paymentDate) - new Date(a.paymentDate));
    return matching;
  }

  /**
   * Find payment by EMI schedule ID
   */
  static async findByEmiScheduleId(emiScheduleId) {
    if (db.isConnected()) {
      const rows = await db.query(
        'SELECT * FROM loan_payments WHERE emi_schedule_id = ? LIMIT 1',
        [emiScheduleId]
      );
      return rows[0] ? this._formatPayment(rows[0]) : null;
    }

    // In-memory fallback
    for (const payment of db.inMemoryStore.loanPayments.values()) {
      if (payment.emiScheduleId === emiScheduleId || payment.emi_schedule_id === emiScheduleId) {
        return this._formatPayment(payment);
      }
    }
    return null;
  }

  /**
   * Update payment record
   */
  static async update(id, fields = {}) {
    if (db.isConnected()) {
      const updates = [];
      const values = [];

      if (fields.amount !== undefined) { updates.push('amount = ?'); values.push(fields.amount); }
      if (fields.paymentDate !== undefined) { updates.push('payment_date = ?'); values.push(fields.paymentDate); }
      if (fields.paymentType !== undefined) { updates.push('payment_type = ?'); values.push(fields.paymentType); }
      if (fields.lateFee !== undefined) { updates.push('late_fee = ?'); values.push(fields.lateFee); }
      if (fields.notes !== undefined) { updates.push('notes = ?'); values.push(fields.notes); }

      if (updates.length === 0) return this.findById(id);

      values.push(id);
      await db.query(`UPDATE loan_payments SET ${updates.join(', ')} WHERE id = ?`, values);
      return this.findById(id);
    }

    // In-memory fallback
    const payment = db.inMemoryStore.loanPayments.get(id);
    if (!payment) return null;

    if (fields.amount !== undefined) { payment.amount = parseFloat(fields.amount); }
    if (fields.paymentDate !== undefined) { payment.paymentDate = fields.paymentDate; payment.payment_date = fields.paymentDate; }
    if (fields.paymentType !== undefined) { payment.paymentType = fields.paymentType; payment.payment_type = fields.paymentType; }
    if (fields.lateFee !== undefined) { payment.lateFee = parseFloat(fields.lateFee); payment.late_fee = parseFloat(fields.lateFee); }
    if (fields.notes !== undefined) { payment.notes = fields.notes; }

    db.inMemoryStore.loanPayments.set(id, payment);
    return this._formatPayment(payment);
  }
}

module.exports = LoanPaymentModel;
