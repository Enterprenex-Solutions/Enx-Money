const db = require('../config/db.config');
const { generateUuid } = require('../utils/crypto.util');

class PrepaymentModel {
  /**
   * Format database row into standard Prepayment object
   */
  static _formatPrepayment(row) {
    if (!row) return null;
    return {
      id: row.id,
      loanId: row.loan_id || row.loanId,
      amount: parseFloat(row.amount),
      paymentDate: row.payment_date || row.paymentDate,
      interestSaved: parseFloat(row.interest_saved ?? row.interestSaved ?? 0),
      revisedTenure: parseInt(row.revised_tenure ?? row.revisedTenure, 10),
      revisedEmi: parseFloat(row.revised_emi ?? row.revisedEmi),
      createdAt: row.created_at || row.createdAt,
    };
  }

  /**
   * Record a new prepayment record
   */
  static async create({
    loanId,
    amount,
    paymentDate,
    interestSaved = 0,
    revisedTenure,
    revisedEmi,
  }) {
    const id = generateUuid();
    const date = paymentDate ? new Date(paymentDate) : new Date();

    if (db.isConnected()) {
      await db.query(
        `INSERT INTO prepayments (
          id, loan_id, amount, payment_date, interest_saved,
          revised_tenure, revised_emi, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          id,
          loanId,
          amount,
          date,
          interestSaved,
          revisedTenure,
          revisedEmi,
          date,
        ]
      );
      return this.findById(id);
    }

    // In-memory fallback
    const prepaymentRecord = {
      id,
      loanId,
      loan_id: loanId,
      amount: parseFloat(amount),
      paymentDate: date,
      payment_date: date,
      interestSaved: parseFloat(interestSaved || 0),
      interest_saved: parseFloat(interestSaved || 0),
      revisedTenure: parseInt(revisedTenure, 10),
      revised_tenure: parseInt(revisedTenure, 10),
      revisedEmi: parseFloat(revisedEmi),
      revised_emi: parseFloat(revisedEmi),
      createdAt: date,
      created_at: date,
    };
    db.inMemoryStore.prepayments.set(id, prepaymentRecord);
    return this._formatPrepayment(prepaymentRecord);
  }

  /**
   * Find prepayment by ID
   */
  static async findById(id) {
    if (db.isConnected()) {
      const rows = await db.query('SELECT * FROM prepayments WHERE id = ? LIMIT 1', [id]);
      return rows[0] ? this._formatPrepayment(rows[0]) : null;
    }

    // In-memory fallback
    const prepayment = db.inMemoryStore.prepayments.get(id);
    return prepayment ? this._formatPrepayment(prepayment) : null;
  }

  /**
   * Find all prepayments for a loan
   */
  static async findByLoanId(loanId) {
    if (db.isConnected()) {
      const rows = await db.query(
        'SELECT * FROM prepayments WHERE loan_id = ? ORDER BY payment_date DESC, created_at DESC',
        [loanId]
      );
      return rows.map((row) => this._formatPrepayment(row));
    }

    // In-memory fallback
    const matching = [];
    for (const item of db.inMemoryStore.prepayments.values()) {
      if (item.loanId === loanId || item.loan_id === loanId) {
        matching.push(this._formatPrepayment(item));
      }
    }
    matching.sort((a, b) => new Date(b.paymentDate) - new Date(a.paymentDate));
    return matching;
  }
}

module.exports = PrepaymentModel;
