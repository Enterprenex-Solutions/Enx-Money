/**
 * Loan EMI Calculation Engine
 * 
 * Supports:
 * 1. Reducing-Balance Interest (Standard reducing amortized schedule)
 * 2. Flat-Rate Interest
 * 3. 0% Interest (Zero-cost / No-cost EMI)
 * 4. Decimal Interest Rates & Various Tenures
 * 5. Complete Amortization Schedule Generation
 * 6. Prepayment Impact Simulation (Reduce Tenure vs Reduce EMI)
 */

class EmiCalculatorService {
  /**
   * Helper to round numbers consistently to 2 decimal places
   * @param {number} value
   * @returns {number}
   */
  static round(value) {
    if (isNaN(value) || !isFinite(value)) return 0.00;
    return Math.round((value + Number.EPSILON) * 100) / 100;
  }

  /**
   * Calculate EMI, Total Interest, and Total Payable for a loan
   * 
   * @param {Object} params
   * @param {number} params.principal - Loan principal amount (P)
   * @param {number} params.annualInterestRate - Annual interest rate in percentage (e.g., 8.5 for 8.5%)
   * @param {number} params.tenureMonths - Number of monthly installments (n)
   * @param {('Reducing'|'Flat')} [params.interestType='Reducing'] - Type of interest
   * @returns {Object} Calculation result
   */
  static calculateEmi({
    principal,
    annualInterestRate,
    tenureMonths,
    interestType = 'Reducing',
  }) {
    const P = parseFloat(principal);
    const R = parseFloat(annualInterestRate);
    const n = parseInt(tenureMonths, 10);
    const normalizedType = interestType && interestType.toLowerCase() === 'flat' ? 'Flat' : 'Reducing';

    if (isNaN(P) || P <= 0) {
      throw new Error('Principal amount must be greater than 0');
    }
    if (isNaN(n) || n <= 0) {
      throw new Error('Tenure months must be greater than 0');
    }
    if (isNaN(R) || R < 0) {
      throw new Error('Interest rate cannot be negative');
    }

    // 1. Zero Interest Case (0% APR / No-Cost EMI)
    if (R === 0) {
      const emi = this.round(P / n);
      const totalPayable = this.round(P);
      const totalInterest = 0.00;

      return {
        principal: this.round(P),
        annualInterestRate: 0,
        tenureMonths: n,
        interestType: normalizedType,
        monthlyInterestRate: 0,
        emiAmount: emi,
        totalInterest,
        totalPayable,
        monthlyPrincipalComponent: emi,
        monthlyInterestComponent: 0.00,
      };
    }

    // 2. Flat Rate Calculation
    if (normalizedType === 'Flat') {
      // Total Interest = P * (R / 100) * (n / 12)
      const totalInterest = this.round(P * (R / 100) * (n / 12));
      const totalPayable = this.round(P + totalInterest);
      const emi = this.round(totalPayable / n);
      const monthlyPrincipal = this.round(P / n);
      const monthlyInterest = this.round(totalInterest / n);

      return {
        principal: this.round(P),
        annualInterestRate: R,
        tenureMonths: n,
        interestType: 'Flat',
        monthlyInterestRate: this.round((R / 12) * 10000) / 10000,
        emiAmount: emi,
        totalInterest,
        totalPayable,
        monthlyPrincipalComponent: monthlyPrincipal,
        monthlyInterestComponent: monthlyInterest,
      };
    }

    // 3. Reducing-Balance Calculation:
    // EMI = P * r * (1 + r)^n / ((1 + r)^n - 1)
    // where r = (R / 12) / 100
    const r = (R / 12) / 100;
    const pow = Math.pow(1 + r, n);
    const emi = this.round((P * r * pow) / (pow - 1));
    const totalPayable = this.round(emi * n);
    const totalInterest = this.round(totalPayable - P);

    return {
      principal: this.round(P),
      annualInterestRate: R,
      tenureMonths: n,
      interestType: 'Reducing',
      monthlyInterestRate: r,
      emiAmount: emi,
      totalInterest,
      totalPayable,
      monthlyPrincipalComponent: this.round(emi - (P * r)),
      monthlyInterestComponent: this.round(P * r),
    };
  }

  /**
   * Calculate precise due date for installment n, handling month-end variance and leap years
   * @param {Date|string} startDate 
   * @param {number} installmentNumber 
   * @returns {string} ISO Date string YYYY-MM-DD
   */
  static calculateDueDate(startDate, installmentNumber) {
    const start = new Date(startDate);
    const originalDay = isNaN(start.getTime()) ? 1 : start.getUTCDate();
    const startYear = isNaN(start.getTime()) ? new Date().getUTCFullYear() : start.getUTCFullYear();
    const startMonth = isNaN(start.getTime()) ? new Date().getUTCMonth() : start.getUTCMonth();

    const targetMonthIndex = startMonth + installmentNumber;
    const targetYear = startYear + Math.floor(targetMonthIndex / 12);
    const targetMonth = targetMonthIndex % 12;

    const maxDaysInMonth = new Date(Date.UTC(targetYear, targetMonth + 1, 0)).getUTCDate();
    const targetDay = Math.min(originalDay, maxDaysInMonth);

    const targetDate = new Date(Date.UTC(targetYear, targetMonth, targetDay));
    return targetDate.toISOString().split('T')[0];
  }

  /**
   * Generate Full Amortization Schedule
   * 
   * @param {Object} params
   * @param {number} params.principal - Loan principal amount (P)
   * @param {number} params.annualInterestRate - Annual interest rate in % (R)
   * @param {number} params.tenureMonths - Number of monthly installments (n)
   * @param {Date|string} [params.startDate] - Start date of the loan
   * @param {('Reducing'|'Flat')} [params.interestType='Reducing'] - Type of interest
   * @param {string} [params.loanId] - Optional loan ID reference
   * @returns {Array<Object>} List of amortization schedule installments
   */
  static generateAmortizationSchedule({
    principal,
    annualInterestRate,
    tenureMonths,
    startDate = new Date(),
    interestType = 'Reducing',
    loanId = null,
  }) {
    const calculation = this.calculateEmi({
      principal,
      annualInterestRate,
      tenureMonths,
      interestType,
    });

    const P = calculation.principal;
    const R = calculation.annualInterestRate;
    const n = calculation.tenureMonths;
    const emi = calculation.emiAmount;
    const isFlat = calculation.interestType === 'Flat';
    const isZeroRate = R === 0;
    const r = isZeroRate ? 0 : (R / 12) / 100;

    const schedule = [];
    let currentBalance = P;

    // Fixed values for Flat Rate
    const flatMonthlyPrincipal = isFlat ? this.round(P / n) : 0;
    const flatMonthlyInterest = isFlat ? this.round(calculation.totalInterest / n) : 0;

    for (let i = 1; i <= n; i++) {
      // Compute due date (monthly step)
      const formattedDueDate = this.calculateDueDate(startDate, i);

      const openingBalance = this.round(currentBalance);
      let interestAmount = 0.00;
      let principalAmount = 0.00;
      let emiAmount = emi;
      let closingBalance = 0.00;

      if (isZeroRate) {
        if (i === n) {
          principalAmount = openingBalance;
          emiAmount = principalAmount;
          closingBalance = 0.00;
        } else {
          principalAmount = emi;
          closingBalance = this.round(openingBalance - principalAmount);
        }
        interestAmount = 0.00;
      } else if (isFlat) {
        if (i === n) {
          principalAmount = openingBalance;
          interestAmount = flatMonthlyInterest;
          emiAmount = this.round(principalAmount + interestAmount);
          closingBalance = 0.00;
        } else {
          principalAmount = flatMonthlyPrincipal;
          interestAmount = flatMonthlyInterest;
          closingBalance = this.round(openingBalance - principalAmount);
        }
      } else {
        // Reducing Balance:
        // Interest for this month = openingBalance * r
        interestAmount = this.round(openingBalance * r);

        if (i === n) {
          // Final installment: absorb any rounding variance to ensure exact zero closing balance
          principalAmount = openingBalance;
          emiAmount = this.round(principalAmount + interestAmount);
          closingBalance = 0.00;
        } else {
          principalAmount = this.round(emi - interestAmount);

          // Guard against floating point underflow
          if (principalAmount > openingBalance) {
            principalAmount = openingBalance;
          }
          closingBalance = this.round(openingBalance - principalAmount);
        }
      }

      currentBalance = closingBalance;

      schedule.push({
        loanId,
        installmentNumber: i,
        dueDate: formattedDueDate,
        openingBalance,
        principalAmount,
        interestAmount,
        emiAmount,
        closingBalance,
        status: 'Pending',
        paidDate: null,
        lateFee: 0.00,
      });
    }

    return schedule;
  }

  /**
   * Simulate Prepayment (Part-Payment or Lump Sum)
   * 
   * Options:
   * 1. 'REDUCE_TENURE': Keep EMI constant, reduce overall months to payoff & save interest.
   * 2. 'REDUCE_EMI': Keep tenure constant, reduce monthly EMI amount & save interest.
   * 
   * @param {Object} params
   * @param {number} params.currentOutstanding - Current principal balance before prepayment
   * @param {number} params.annualInterestRate - Annual interest rate in %
   * @param {number} params.remainingTenureMonths - Remaining months before prepayment
   * @param {number} params.currentEmi - Current monthly EMI amount
   * @param {number} params.prepaymentAmount - Lump sum amount to prepay
   * @param {('REDUCE_TENURE'|'REDUCE_EMI')} [params.strategy='REDUCE_TENURE'] - Prepayment optimization strategy
   * @returns {Object} Simulation analysis
   */
  static simulatePrepayment({
    currentOutstanding,
    annualInterestRate,
    remainingTenureMonths,
    currentEmi,
    prepaymentAmount,
    strategy = 'REDUCE_TENURE',
  }) {
    const P_curr = parseFloat(currentOutstanding);
    const R = parseFloat(annualInterestRate);
    const n_curr = parseInt(remainingTenureMonths, 10);
    const emi_curr = parseFloat(currentEmi);
    const prepay = parseFloat(prepaymentAmount);

    if (prepay <= 0 || prepay >= P_curr) {
      throw new Error(`Prepayment amount must be between 1 and ${P_curr - 1}`);
    }

    const r = (R / 12) / 100;
    const P_new = this.round(P_curr - prepay);

    // Current remaining trajectory
    const currentTotalPayable = this.round(emi_curr * n_curr);
    const currentTotalInterest = this.round(currentTotalPayable - P_curr);

    if (strategy === 'REDUCE_TENURE') {
      // Keep EMI same: n_new = ln(EMI / (EMI - P_new * r)) / ln(1 + r)
      if (r === 0) {
        const n_new = Math.ceil(P_new / emi_curr);
        const newTotalPayable = this.round(P_new);
        const interestSaved = 0.00;
        const monthsSaved = n_curr - n_new;

        return {
          strategy: 'REDUCE_TENURE',
          prepaymentAmount: prepay,
          currentOutstanding: P_curr,
          revisedPrincipal: P_new,
          revisedEmi: emi_curr,
          revisedTenureMonths: n_new,
          monthsSaved: Math.max(0, monthsSaved),
          interestSaved,
          originalTotalInterest: currentTotalInterest,
          revisedTotalInterest: 0.00,
        };
      }

      const numerator = Math.log(emi_curr / (emi_curr - (P_new * r)));
      const denominator = Math.log(1 + r);
      const n_new = Math.ceil(numerator / denominator);

      const revisedTotalPayable = this.round((emi_curr * n_new) + prepay);
      const revisedTotalInterest = this.round((emi_curr * n_new) - P_new);
      const interestSaved = Math.max(0.00, this.round(currentTotalInterest - revisedTotalInterest));
      const monthsSaved = Math.max(0, n_curr - n_new);

      return {
        strategy: 'REDUCE_TENURE',
        prepaymentAmount: prepay,
        currentOutstanding: P_curr,
        revisedPrincipal: P_new,
        revisedEmi: emi_curr,
        revisedTenureMonths: n_new,
        monthsSaved,
        interestSaved,
        originalTotalInterest: currentTotalInterest,
        revisedTotalInterest,
      };
    } else {
      // REDUCE_EMI Strategy: Keep remaining tenure same, recalculate lower EMI
      const newCalc = this.calculateEmi({
        principal: P_new,
        annualInterestRate: R,
        tenureMonths: n_curr,
        interestType: 'Reducing',
      });

      const revisedEmi = newCalc.emiAmount;
      const revisedTotalInterest = newCalc.totalInterest;
      const interestSaved = Math.max(0.00, this.round(currentTotalInterest - revisedTotalInterest));
      const monthlyEmiSaved = this.round(emi_curr - revisedEmi);

      return {
        strategy: 'REDUCE_EMI',
        prepaymentAmount: prepay,
        currentOutstanding: P_curr,
        revisedPrincipal: P_new,
        revisedEmi,
        monthlyEmiSaved,
        revisedTenureMonths: n_curr,
        monthsSaved: 0,
        interestSaved,
        originalTotalInterest: currentTotalInterest,
        revisedTotalInterest,
      };
    }
  }

  /**
   * Simulate Full Loan Foreclosure
   * Calculates the exact amount required to close the loan early today.
   */
  static simulateForeclosure({
    currentOutstanding,
    annualInterestRate,
    remainingTenureMonths,
    currentEmi,
    foreclosureChargeRate = 0.0,
    unpaidLateFees = 0.0,
  }) {
    const P_curr = parseFloat(currentOutstanding);
    const n_curr = parseInt(remainingTenureMonths, 10);
    const emi_curr = parseFloat(currentEmi);
    const chargeRate = parseFloat(foreclosureChargeRate || 0.0);
    const lateFees = parseFloat(unpaidLateFees || 0.0);

    // Future interest if loan runs its full tenure
    const currentTotalPayable = this.round(emi_curr * n_curr);
    const futureInterestPayable = Math.max(0.00, this.round(currentTotalPayable - P_curr));

    // Foreclosure charges & GST (18% on penalty charges if any)
    const foreclosureCharge = this.round((P_curr * chargeRate) / 100);
    const gstOnCharges = this.round((foreclosureCharge * 18) / 100);
    const totalCharges = this.round(foreclosureCharge + gstOnCharges + lateFees);

    const totalForeclosureAmount = this.round(P_curr + totalCharges);
    const netSavings = Math.max(0.00, this.round(futureInterestPayable - totalCharges));

    return {
      currentOutstandingPrincipal: P_curr,
      remainingTenureMonths: n_curr,
      foreclosureChargeRate: chargeRate,
      foreclosureChargeAmount: foreclosureCharge,
      gstOnCharges,
      unpaidLateFees: lateFees,
      totalCharges,
      totalForeclosureAmount,
      totalFutureInterestSaved: futureInterestPayable,
      netSavings,
    };
  }

  /**
   * Compare Flat Rate vs Reducing Balance Interest for a loan
   * 
   * @param {Object} params
   * @param {number} params.principal
   * @param {number} params.annualInterestRate
   * @param {number} params.tenureMonths
   * @returns {Object} Side-by-side comparison
   */
  static compareFlatVsReducing({
    principal,
    annualInterestRate,
    tenureMonths,
  }) {
    const reducing = this.calculateEmi({
      principal,
      annualInterestRate,
      tenureMonths,
      interestType: 'Reducing',
    });

    const flat = this.calculateEmi({
      principal,
      annualInterestRate,
      tenureMonths,
      interestType: 'Flat',
    });

    const interestDifference = this.round(flat.totalInterest - reducing.totalInterest);
    const emiDifference = this.round(flat.emiAmount - reducing.emiAmount);

    return {
      principal: reducing.principal,
      annualInterestRate: reducing.annualInterestRate,
      tenureMonths: reducing.tenureMonths,
      reducingBalance: {
        emiAmount: reducing.emiAmount,
        totalInterest: reducing.totalInterest,
        totalPayable: reducing.totalPayable,
      },
      flatRate: {
        emiAmount: flat.emiAmount,
        totalInterest: flat.totalInterest,
        totalPayable: flat.totalPayable,
      },
      difference: {
        interestDifference,
        emiDifference,
        description: `Reducing balance saves ₹${interestDifference.toLocaleString()} in interest compared to flat rate.`,
      },
    };
  }
}

module.exports = EmiCalculatorService;
