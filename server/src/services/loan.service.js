const LoanModel = require('../models/loan.model');
const EmiScheduleModel = require('../models/emiSchedule.model');
const LoanPaymentModel = require('../models/loanPayment.model');
const PrepaymentModel = require('../models/prepayment.model');
const EmiCalculatorService = require('./emiCalculator.service');
const LateFeeCalculatorService = require('./lateFeeCalculator.service');

class LoanService {
  /**
   * Create a new loan, calculate EMI, and automatically generate and store the full amortization schedule
   */
  static async createLoan({
    userId,
    loanType,
    principalAmount,
    interestRate,
    tenureMonths,
    startDate,
    interestType = 'Reducing',
  }) {
    const calculation = EmiCalculatorService.calculateEmi({
      principal: principalAmount,
      annualInterestRate: interestRate,
      tenureMonths,
      interestType,
    });

    const formattedStartDate = typeof startDate === 'string'
      ? startDate
      : new Date(startDate).toISOString().split('T')[0];

    const loan = await LoanModel.create({
      userId,
      loanType,
      principalAmount: calculation.principal,
      interestRate: calculation.annualInterestRate,
      tenureMonths: calculation.tenureMonths,
      startDate: formattedStartDate,
      interestType: calculation.interestType,
      emiAmount: calculation.emiAmount,
      totalInterest: calculation.totalInterest,
      totalPayable: calculation.totalPayable,
      status: 'Active',
    });

    const rawSchedule = EmiCalculatorService.generateAmortizationSchedule({
      principal: calculation.principal,
      annualInterestRate: calculation.annualInterestRate,
      tenureMonths: calculation.tenureMonths,
      startDate: formattedStartDate,
      interestType: calculation.interestType,
      loanId: loan.id,
    });

    const schedule = await EmiScheduleModel.bulkCreate(rawSchedule);

    return {
      loan,
      schedule,
      summary: {
        principal: calculation.principal,
        annualInterestRate: calculation.annualInterestRate,
        tenureMonths: calculation.tenureMonths,
        interestType: calculation.interestType,
        emiAmount: calculation.emiAmount,
        totalInterest: calculation.totalInterest,
        totalPayable: calculation.totalPayable,
        totalInstallments: schedule.length,
      },
    };
  }

  /**
   * Get all loans for a user with overview analytics
   */
  static async getLoansByUserId(userId, { status } = {}) {
    const loans = await LoanModel.findByUserId(userId, { status });

    let totalPrincipal = 0;
    let totalMonthlyEmi = 0;
    let totalPayable = 0;
    let totalInterest = 0;

    for (const loan of loans) {
      if (loan.status === 'Active') {
        totalPrincipal += loan.principalAmount;
        totalMonthlyEmi += loan.emiAmount;
        totalPayable += loan.totalPayable;
        totalInterest += loan.totalInterest;
      }
    }

    return {
      loans,
      analytics: {
        totalLoansCount: loans.length,
        activeLoansCount: loans.filter((l) => l.status === 'Active').length,
        totalActivePrincipal: EmiCalculatorService.round(totalPrincipal),
        totalMonthlyEmiBurden: EmiCalculatorService.round(totalMonthlyEmi),
        totalPayableAmount: EmiCalculatorService.round(totalPayable),
        totalInterestAmount: EmiCalculatorService.round(totalInterest),
      },
    };
  }

  /**
   * Get complete loan details including schedule, payment history, and prepayments
   */
  static async getLoanDetails(loanId, userId) {
    const loan = await LoanModel.findByIdAndUserId(loanId, userId);
    if (!loan) {
      const error = new Error('Loan not found or unauthorized access');
      error.statusCode = 404;
      throw error;
    }

    const [schedule, payments, prepayments] = await Promise.all([
      EmiScheduleModel.findByLoanId(loanId),
      LoanPaymentModel.findByLoanId(loanId),
      PrepaymentModel.findByLoanId(loanId),
    ]);

    const paidInstallments = schedule.filter((s) => s.status === 'Paid');
    const pendingInstallments = schedule.filter((s) => s.status === 'Pending' || s.status === 'Overdue');
    const totalPaidPrincipal = paidInstallments.reduce((sum, item) => sum + item.principalAmount, 0);
    const totalPaidInterest = paidInstallments.reduce((sum, item) => sum + item.interestAmount, 0);
    const remainingPrincipal = Math.max(0, loan.principalAmount - totalPaidPrincipal);

    const nextPendingEmi = pendingInstallments.length > 0 ? pendingInstallments[0] : null;

    return {
      loan,
      schedule,
      payments,
      prepayments,
      stats: {
        totalInstallments: schedule.length,
        paidInstallmentsCount: paidInstallments.length,
        pendingInstallmentsCount: pendingInstallments.length,
        totalPaidPrincipal: EmiCalculatorService.round(totalPaidPrincipal),
        totalPaidInterest: EmiCalculatorService.round(totalPaidInterest),
        totalPaidAmount: EmiCalculatorService.round(totalPaidPrincipal + totalPaidInterest),
        remainingPrincipal: EmiCalculatorService.round(remainingPrincipal),
        completionPercentage: schedule.length > 0
          ? EmiCalculatorService.round((paidInstallments.length / schedule.length) * 100)
          : 0,
        nextPendingEmi,
      },
    };
  }

  /**
   * Update basic loan details or status
   */
  static async updateLoan(loanId, userId, updateFields = {}) {
    const loan = await LoanModel.findByIdAndUserId(loanId, userId);
    if (!loan) {
      const error = new Error('Loan not found or unauthorized access');
      error.statusCode = 404;
      throw error;
    }

    // If financial fields changed, recalculate EMI and schedule
    if (
      updateFields.principalAmount !== undefined ||
      updateFields.interestRate !== undefined ||
      updateFields.tenureMonths !== undefined ||
      updateFields.interestType !== undefined ||
      updateFields.startDate !== undefined
    ) {
      return this.regenerateSchedule(loanId, userId, updateFields);
    }

    const updated = await LoanModel.update(loanId, userId, updateFields);
    return {
      loan: updated,
      message: 'Loan updated successfully',
    };
  }

  /**
   * Retrieve amortization schedule for a specific loan
   */
  static async getAmortizationSchedule(loanId, userId) {
    const loan = await LoanModel.findByIdAndUserId(loanId, userId);
    if (!loan) {
      const error = new Error('Loan not found or unauthorized access');
      error.statusCode = 404;
      throw error;
    }

    const schedule = await EmiScheduleModel.findByLoanId(loanId);
    return {
      loanId: loan.id,
      loanType: loan.loanType,
      principalAmount: loan.principalAmount,
      interestRate: loan.interestRate,
      tenureMonths: loan.tenureMonths,
      emiAmount: loan.emiAmount,
      totalInterest: loan.totalInterest,
      totalPayable: loan.totalPayable,
      schedule,
    };
  }

  /**
   * Get upcoming EMIs (user-wide or loan-specific)
   */
  static async getUpcomingEmis({ userId, loanId = null, daysAhead = 30 }) {
    if (loanId) {
      const loan = await LoanModel.findByIdAndUserId(loanId, userId);
      if (!loan) {
        const error = new Error('Loan not found or unauthorized access');
        error.statusCode = 404;
        throw error;
      }
      const upcoming = await EmiScheduleModel.findUpcomingByLoanId(loanId, daysAhead);
      return {
        loanId,
        daysAhead,
        upcomingEmis: upcoming,
        count: upcoming.length,
      };
    }

    const upcoming = await EmiScheduleModel.findUpcomingByUserId(userId, daysAhead);
    return {
      daysAhead,
      upcomingEmis: upcoming,
      count: upcoming.length,
    };
  }

  /**
   * Get overdue EMIs (user-wide or loan-specific) with dynamic late fee breakdown
   */
  static async getOverdueEmis({ userId, loanId = null, asOfDate = new Date() }) {
    let overdue = [];
    if (loanId) {
      const loan = await LoanModel.findByIdAndUserId(loanId, userId);
      if (!loan) {
        const error = new Error('Loan not found or unauthorized access');
        error.statusCode = 404;
        throw error;
      }
      overdue = await EmiScheduleModel.findOverdueByLoanId(loanId);
    } else {
      overdue = await EmiScheduleModel.findOverdueByUserId(userId);
    }

    // Attach dynamic late fee breakdown to every overdue installment
    const enrichedOverdue = overdue.map((item) => {
      const lateFeeDetails = LateFeeCalculatorService.calculateLateFee({
        emiAmount: item.emiAmount,
        dueDate: item.dueDate,
        status: item.status,
        asOfDate,
      });

      return {
        ...item,
        lateFeeBreakdown: lateFeeDetails,
      };
    });

    const totalOverduePrincipal = enrichedOverdue.reduce((sum, item) => sum + (item.principalAmount || 0), 0);
    const totalLateFees = enrichedOverdue.reduce((sum, item) => sum + (item.lateFeeBreakdown?.lateFee || 0), 0);
    const totalPayableAmount = enrichedOverdue.reduce((sum, item) => sum + (item.lateFeeBreakdown?.totalPayable || item.emiAmount), 0);

    return {
      loanId,
      overdueEmis: enrichedOverdue,
      count: enrichedOverdue.length,
      totalOverduePrincipal: EmiCalculatorService.round(totalOverduePrincipal),
      totalLateFees: EmiCalculatorService.round(totalLateFees),
      totalPayableAmount: EmiCalculatorService.round(totalPayableAmount),
    };
  }

  /**
   * Calculate late fee for a specific installment schedule item
   */
  static async getScheduleLateFee(loanId, scheduleId, userId, asOfDate = new Date()) {
    const loan = await LoanModel.findByIdAndUserId(loanId, userId);
    if (!loan) {
      const error = new Error('Loan not found or unauthorized access');
      error.statusCode = 404;
      throw error;
    }

    const scheduleItem = await EmiScheduleModel.findById(scheduleId);
    if (!scheduleItem || (scheduleItem.loanId !== loanId && scheduleItem.loan_id !== loanId)) {
      const error = new Error('EMI schedule item not found for this loan');
      error.statusCode = 404;
      throw error;
    }

    const lateFeeDetails = LateFeeCalculatorService.calculateLateFee({
      emiAmount: scheduleItem.emiAmount,
      dueDate: scheduleItem.dueDate,
      status: scheduleItem.status,
      asOfDate,
    });

    return {
      loanId: loan.id,
      scheduleId: scheduleItem.id,
      installmentNumber: scheduleItem.installmentNumber,
      dueDate: scheduleItem.dueDate,
      status: scheduleItem.status,
      ...lateFeeDetails,
    };
  }

  /**
   * Mark an EMI installment as paid & record payment
   */
  static async markEmiAsPaid({
    loanId,
    scheduleId,
    userId,
    amount,
    paymentDate,
    paymentType = 'EMI',
    lateFee = 0,
    notes = null,
  }) {
    // 1. Verify loan and ownership
    const loan = await LoanModel.findByIdAndUserId(loanId, userId);
    if (!loan) {
      const error = new Error('Loan not found or unauthorized access');
      error.statusCode = 404;
      throw error;
    }

    // 2. Verify schedule item (or auto-locate next due/overdue schedule installment)
    let scheduleItem;
    if (scheduleId) {
      scheduleItem = await EmiScheduleModel.findById(scheduleId);
    } else {
      const allSchedules = await EmiScheduleModel.findByLoanId(loanId);
      scheduleItem = allSchedules.find((s) => s.status === 'Overdue') || allSchedules.find((s) => s.status === 'Pending') || allSchedules[0];
    }

    if (!scheduleItem || (scheduleItem.loanId !== loanId && scheduleItem.loan_id !== loanId)) {
      const error = new Error('EMI schedule item not found for this loan');
      error.statusCode = 404;
      throw error;
    }

    // 3. Prevent duplicate payment records
    if (scheduleItem.status === 'Paid') {
      const paidDateFormatted = scheduleItem.paidDate ? new Date(scheduleItem.paidDate).toISOString().split('T')[0] : 'a previous date';
      const error = new Error(`Duplicate payment rejected: Installment #${scheduleItem.installmentNumber} has already been marked as Paid on ${paidDateFormatted}.`);
      error.statusCode = 400;
      throw error;
    }

    const paidAmount = amount !== undefined ? parseFloat(amount) : (scheduleItem.emiAmount + parseFloat(lateFee || 0));
    const paidAt = paymentDate ? new Date(paymentDate) : new Date();

    // 4. Create Loan Payment Record
    const payment = await LoanPaymentModel.create({
      loanId,
      emiScheduleId: scheduleItem.id,
      amount: paidAmount,
      paymentDate: paidAt,
      paymentType,
      lateFee: parseFloat(lateFee || 0),
      notes: notes || `Payment for installment #${scheduleItem.installmentNumber}`,
    });

    // 5. Update Schedule Item Status to 'Paid'
    const updatedSchedule = await EmiScheduleModel.updateStatus(scheduleItem.id, {
      status: 'Paid',
      paidDate: paidAt,
      lateFee: parseFloat(lateFee || 0),
    });

    // 6. Check if all installments for loan are now paid -> Close loan if finished
    const allSchedules = await EmiScheduleModel.findByLoanId(loanId);
    const hasUnpaid = allSchedules.some((s) => s.status !== 'Paid');
    if (!hasUnpaid) {
      await LoanModel.update(loanId, userId, { status: 'Closed' });
    }

    const summary = await this.getLoanSummary(loanId, userId);

    return {
      message: `EMI installment #${scheduleItem.installmentNumber} marked as paid successfully`,
      payment,
      scheduleItem: updatedSchedule,
      loanSummary: summary,
    };
  }

  /**
   * Update an existing payment record
   */
  static async updatePayment(paymentId, userId, updateFields = {}) {
    const payment = await LoanPaymentModel.findById(paymentId);
    if (!payment) {
      const error = new Error('Payment record not found');
      error.statusCode = 404;
      throw error;
    }

    // Check ownership of the parent loan
    const loan = await LoanModel.findByIdAndUserId(payment.loanId, userId);
    if (!loan) {
      const error = new Error('Unauthorized access to payment record');
      error.statusCode = 403;
      throw error;
    }

    const updated = await LoanPaymentModel.update(paymentId, updateFields);
    return {
      message: 'Payment record updated successfully',
      payment: updated,
    };
  }

  /**
   * Get payment history for a loan
   */
  static async getPaymentHistory(loanId, userId) {
    const loan = await LoanModel.findByIdAndUserId(loanId, userId);
    if (!loan) {
      const error = new Error('Loan not found or unauthorized access');
      error.statusCode = 404;
      throw error;
    }

    const payments = await LoanPaymentModel.findByLoanId(loanId);
    const totalPaidAmount = payments.reduce((sum, p) => sum + p.amount, 0);

    return {
      loanId,
      totalPaymentsCount: payments.length,
      totalAmountPaid: EmiCalculatorService.round(totalPaidAmount),
      payments,
    };
  }

  /**
   * Get detailed Loan Summary conforming to all required metrics
   */
  static async getLoanSummary(loanId, userId) {
    const loan = await LoanModel.findByIdAndUserId(loanId, userId);
    if (!loan) {
      const error = new Error('Loan not found or unauthorized access');
      error.statusCode = 404;
      throw error;
    }

    const schedule = await EmiScheduleModel.findByLoanId(loanId);
    const today = new Date().toISOString().split('T')[0];

    const paidList = schedule.filter((s) => s.status === 'Paid');
    const pendingList = schedule.filter((s) => s.status === 'Pending' && s.dueDate >= today);
    const overdueList = schedule.filter((s) => s.status === 'Overdue' || (s.status === 'Pending' && s.dueDate < today));

    const prepayments = await PrepaymentModel.findByLoanId(loanId);
    const totalPrepayments = prepayments.reduce((sum, p) => sum + (parseFloat(p.amount) || 0), 0);

    const principalPaid = paidList.reduce((sum, s) => sum + s.principalAmount, 0) + totalPrepayments;
    const interestPaid = paidList.reduce((sum, s) => sum + s.interestAmount, 0);
    const outstandingBalance = loan.status === 'Closed' ? 0.0 : Math.max(0, loan.principalAmount - principalPaid);

    // Next EMI calculation
    let nextEmi = null;
    if (pendingList.length > 0 || overdueList.length > 0) {
      const upcomingSorted = [...overdueList, ...pendingList].sort((a, b) => new Date(a.dueDate) - new Date(b.dueDate));
      const target = upcomingSorted[0];
      const targetDate = new Date(target.dueDate);
      const now = new Date(today);
      const diffTime = targetDate.getTime() - now.getTime();
      const daysRemaining = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

      nextEmi = {
        installmentNumber: target.installmentNumber,
        dueDate: target.dueDate,
        emiAmount: target.emiAmount,
        principalAmount: target.principalAmount,
        interestAmount: target.interestAmount,
        isOverdue: target.dueDate < today,
        daysRemaining,
      };
    }

    return {
      loanId: loan.id,
      loanType: loan.loanType,
      status: loan.status,
      principalAmount: loan.principalAmount,
      emi: loan.emiAmount,
      emiAmount: loan.emiAmount,
      outstandingBalance: EmiCalculatorService.round(outstandingBalance),
      totalInterest: loan.totalInterest,
      interestPaid: EmiCalculatorService.round(interestPaid),
      principalPaid: EmiCalculatorService.round(principalPaid),
      totalPayable: loan.totalPayable,
      nextEmi,
      numberPaidEmis: paidList.length,
      numberPendingEmis: pendingList.length,
      numberOverdueEmis: overdueList.length,
      totalEmis: schedule.length,
      completionPercentage: schedule.length > 0
        ? EmiCalculatorService.round((paidList.length / schedule.length) * 100)
        : 0,
    };
  }

  /**
   * Regenerate Amortization Schedule for a loan
   */
  static async regenerateSchedule(loanId, userId, updateParams = {}) {
    const loan = await LoanModel.findByIdAndUserId(loanId, userId);
    if (!loan) {
      const error = new Error('Loan not found or unauthorized access');
      error.statusCode = 404;
      throw error;
    }

    const principal = updateParams.principalAmount !== undefined ? parseFloat(updateParams.principalAmount) : loan.principalAmount;
    const interestRate = updateParams.interestRate !== undefined ? parseFloat(updateParams.interestRate) : loan.interestRate;
    const tenureMonths = updateParams.tenureMonths !== undefined ? parseInt(updateParams.tenureMonths, 10) : loan.tenureMonths;
    const startDate = updateParams.startDate || loan.startDate;
    const interestType = updateParams.interestType || loan.interestType;

    const calculation = EmiCalculatorService.calculateEmi({
      principal,
      annualInterestRate: interestRate,
      tenureMonths,
      interestType,
    });

    const updatedLoan = await LoanModel.update(loanId, userId, {
      principalAmount: calculation.principal,
      interestRate: calculation.annualInterestRate,
      tenureMonths: calculation.tenureMonths,
      startDate,
      interestType: calculation.interestType,
      emiAmount: calculation.emiAmount,
      totalInterest: calculation.totalInterest,
      totalPayable: calculation.totalPayable,
    });

    await EmiScheduleModel.deleteByLoanId(loanId);

    const rawSchedule = EmiCalculatorService.generateAmortizationSchedule({
      principal: calculation.principal,
      annualInterestRate: calculation.annualInterestRate,
      tenureMonths: calculation.tenureMonths,
      startDate,
      interestType: calculation.interestType,
      loanId,
    });

    const schedule = await EmiScheduleModel.bulkCreate(rawSchedule);

    return {
      loan: updatedLoan,
      schedule,
      message: 'Amortization schedule regenerated successfully',
    };
  }

  /**
   * Preview schedule without DB write
   */
  static previewSchedule({
    principalAmount,
    interestRate,
    tenureMonths,
    startDate = new Date(),
    interestType = 'Reducing',
  }) {
    const calculation = EmiCalculatorService.calculateEmi({
      principal: principalAmount,
      annualInterestRate: interestRate,
      tenureMonths,
      interestType,
    });

    const schedule = EmiCalculatorService.generateAmortizationSchedule({
      principal: calculation.principal,
      annualInterestRate: calculation.annualInterestRate,
      tenureMonths: calculation.tenureMonths,
      startDate,
      interestType: calculation.interestType,
    });

    return {
      calculation,
      schedule,
    };
  }

  /**
   * Delete a loan and associated schedule/records
   */
  static async deleteLoan(loanId, userId) {
    const loan = await LoanModel.findByIdAndUserId(loanId, userId);
    if (!loan) {
      const error = new Error('Loan not found or unauthorized access');
      error.statusCode = 404;
      throw error;
    }

    await LoanModel.delete(loanId, userId);
    return { message: 'Loan and amortization schedule deleted successfully' };
  }

  /**
   * Simulate Prepayment Impact on a loan
   */
  static async simulatePrepayment(loanId, userId, { prepaymentAmount, strategy = 'REDUCE_TENURE' }) {
    const loan = await LoanModel.findByIdAndUserId(loanId, userId);
    if (!loan) {
      const error = new Error('Loan not found or unauthorized access');
      error.statusCode = 404;
      throw error;
    }

    const summary = await this.getLoanSummary(loanId, userId);
    const outstanding = summary.outstandingBalance;
    const remainingTenure = summary.numberPendingEmis + summary.numberOverdueEmis;

    if (parseFloat(prepaymentAmount) >= outstanding) {
      const error = new Error(`Prepayment amount (₹${prepaymentAmount}) cannot exceed or equal total outstanding balance (₹${outstanding}). Use Foreclosure instead.`);
      error.statusCode = 400;
      throw error;
    }

    const simulation = EmiCalculatorService.simulatePrepayment({
      currentOutstanding: outstanding,
      annualInterestRate: loan.interestRate,
      remainingTenureMonths: remainingTenure || 1,
      currentEmi: loan.emiAmount,
      prepaymentAmount,
      strategy,
    });

    return {
      loanId: loan.id,
      loanType: loan.loanType,
      currentOutstandingPrincipal: outstanding,
      originalRemainingTenure: remainingTenure,
      originalEmi: loan.emiAmount,
      ...simulation,
    };
  }

  /**
   * Simulate Foreclosure on a loan
   */
  static async simulateForeclosure(loanId, userId, { foreclosureChargeRate = 0.0 } = {}) {
    const loan = await LoanModel.findByIdAndUserId(loanId, userId);
    if (!loan) {
      const error = new Error('Loan not found or unauthorized access');
      error.statusCode = 404;
      throw error;
    }

    const summary = await this.getLoanSummary(loanId, userId);
    const outstanding = summary.outstandingBalance;
    const remainingTenure = summary.numberPendingEmis + summary.numberOverdueEmis;

    const overdueData = await this.getOverdueEmis({ userId, loanId });
    const unpaidLateFees = overdueData.totalLateFees || 0;

    const simulation = EmiCalculatorService.simulateForeclosure({
      currentOutstanding: outstanding,
      annualInterestRate: loan.interestRate,
      remainingTenureMonths: remainingTenure || 1,
      currentEmi: loan.emiAmount,
      foreclosureChargeRate,
      unpaidLateFees,
    });

    return {
      loanId: loan.id,
      loanType: loan.loanType,
      ...simulation,
    };
  }

  /**
   * Apply Prepayment to a loan (explicit user action)
   */
  static async applyPrepayment(loanId, userId, { prepaymentAmount, strategy = 'REDUCE_TENURE', paymentDate = new Date(), notes } = {}) {
    const sim = await this.simulatePrepayment(loanId, userId, { prepaymentAmount, strategy });
    const loan = await LoanModel.findByIdAndUserId(loanId, userId);

    // 1. Record Prepayment in PrepaymentModel
    const prepaymentRecord = await PrepaymentModel.create({
      loanId,
      amount: sim.prepaymentAmount,
      paymentDate: new Date(paymentDate),
      interestSaved: sim.interestSaved,
      revisedTenure: sim.revisedTenureMonths,
      revisedEmi: sim.revisedEmi,
    });

    // 2. Record Payment in LoanPaymentModel
    await LoanPaymentModel.create({
      loanId,
      amount: sim.prepaymentAmount,
      paymentDate: new Date(paymentDate),
      paymentType: 'PREPAYMENT',
      notes: notes || `Part-prepayment of ₹${sim.prepaymentAmount} (${strategy})`,
    });

    // 3. Regenerate remaining amortization schedule with revised parameters
    const todayStr = new Date(paymentDate).toISOString().split('T')[0];
    const newSchedule = EmiCalculatorService.generateAmortizationSchedule({
      principal: sim.revisedPrincipal,
      annualInterestRate: loan.interestRate,
      tenureMonths: sim.revisedTenureMonths,
      startDate: todayStr,
      interestType: loan.interestType,
      loanId,
    });

    // Remove future unpaid installments and insert revised schedule
    await EmiScheduleModel.deletePendingByLoanId(loanId);
    await EmiScheduleModel.bulkCreate(newSchedule);

    // 4. Update loan record with revised tenure/EMI
    const updatedLoan = await LoanModel.update(loanId, userId, {
      tenureMonths: strategy === 'REDUCE_TENURE' ? sim.revisedTenureMonths : loan.tenureMonths,
      emiAmount: sim.revisedEmi,
    });

    const summary = await this.getLoanSummary(loanId, userId);

    return {
      message: `Prepayment of ₹${sim.prepaymentAmount} applied successfully! Interest saved: ₹${sim.interestSaved}`,
      prepayment: prepaymentRecord,
      loan: updatedLoan,
      loanSummary: summary,
    };
  }

  /**
   * Apply Foreclosure to a loan (explicit user action)
   */
  static async applyForeclosure(loanId, userId, { foreclosureChargeRate = 0.0, paymentDate = new Date(), notes } = {}) {
    const loan = await LoanModel.findByIdAndUserId(loanId, userId);
    if (!loan) {
      const error = new Error('Loan not found or unauthorized access');
      error.statusCode = 404;
      throw error;
    }

    if (loan.status === 'Closed') {
      const error = new Error('This loan is already Closed.');
      error.statusCode = 400;
      throw error;
    }

    const sim = await this.simulateForeclosure(loanId, userId, { foreclosureChargeRate });

    // 1. Record Final Foreclosure Settlement Payment
    const payment = await LoanPaymentModel.create({
      loanId,
      amount: sim.totalForeclosureAmount,
      paymentDate: new Date(paymentDate),
      paymentType: 'FORECLOSURE',
      notes: notes || `Full loan foreclosure settlement (Principal: ₹${sim.currentOutstandingPrincipal}, Charges: ₹${sim.totalCharges})`,
    });

    // 2. Mark all remaining schedule installments as Paid
    const allSchedules = await EmiScheduleModel.findByLoanId(loanId);
    for (const item of allSchedules) {
      if (item.status !== 'Paid') {
        await EmiScheduleModel.updateStatus(item.id, {
          status: 'Paid',
          paidDate: new Date(paymentDate),
        });
      }
    }

    // 3. Update Loan status to 'Closed'
    const updatedLoan = await LoanModel.update(loanId, userId, { status: 'Closed' });
    const summary = await this.getLoanSummary(loanId, userId);

    return {
      message: `Loan foreclosed and closed successfully! Total settled: ₹${sim.totalForeclosureAmount}. Future interest saved: ₹${sim.totalFutureInterestSaved}`,
      payment,
      loan: updatedLoan,
      foreclosureDetails: sim,
      loanSummary: summary,
    };
  }
}

module.exports = LoanService;
