const EmiCalculatorService = require('../src/services/emiCalculator.service');

describe('Loan EMI Calculation Engine Unit Tests', () => {
  describe('Reducing-Balance Interest EMI Calculations', () => {
    it('should correctly calculate EMI for standard home loan (₹5,000,000, 8.5% p.a., 20 years/240 months)', () => {
      const result = EmiCalculatorService.calculateEmi({
        principal: 5000000,
        annualInterestRate: 8.5,
        tenureMonths: 240,
        interestType: 'Reducing',
      });

      // Standard EMI = 5000000 * 0.00708333 * (1.00708333)^240 / ((1.00708333)^240 - 1) = 43391.16
      expect(result.emiAmount).toBe(43391.16);
      expect(result.principal).toBe(5000000);
      expect(result.tenureMonths).toBe(240);
      expect(result.interestType).toBe('Reducing');
      expect(result.totalPayable).toBe(10413878.4);
      expect(result.totalInterest).toBe(5413878.4);
    });

    it('should correctly calculate EMI for personal loan (₹1,000,000, 10.5% p.a., 36 months)', () => {
      const result = EmiCalculatorService.calculateEmi({
        principal: 1000000,
        annualInterestRate: 10.5,
        tenureMonths: 36,
        interestType: 'Reducing',
      });

      // Monthly r = 10.5 / 1200 = 0.00875
      // Exact EMI = 32502.44
      expect(result.emiAmount).toBe(32502.44);
      expect(result.totalPayable).toBe(1170087.84);
      expect(result.totalInterest).toBe(170087.84);
      expect(result.monthlyInterestComponent).toBe(8750); // 1000000 * 0.00875
      expect(result.monthlyPrincipalComponent).toBe(23752.44); // 32502.44 - 8750
    });

    it('should handle decimal interest rates (e.g. 7.65% p.a., 60 months, ₹750,000)', () => {
      const result = EmiCalculatorService.calculateEmi({
        principal: 750000,
        annualInterestRate: 7.65,
        tenureMonths: 60,
        interestType: 'Reducing',
      });

      expect(result.emiAmount).toBe(15081.98);
      expect(result.totalPayable).toBe(904918.8);
      expect(result.totalInterest).toBe(154918.8);
    });

    it('should handle short tenures (e.g. 3 months, 12% p.a., ₹30,000)', () => {
      const result = EmiCalculatorService.calculateEmi({
        principal: 30000,
        annualInterestRate: 12,
        tenureMonths: 3,
        interestType: 'Reducing',
      });

      // r = 1%, EMI = 30000 * 0.01 * (1.01)^3 / ((1.01)^3 - 1) = 10200.66
      expect(result.emiAmount).toBe(10200.66);
      expect(result.totalPayable).toBe(30601.98);
      expect(result.totalInterest).toBe(601.98);
    });
  });

  describe('Flat-Rate Interest Calculations', () => {
    it('should correctly calculate flat rate EMI (₹100,000, 10% flat, 12 months)', () => {
      const result = EmiCalculatorService.calculateEmi({
        principal: 100000,
        annualInterestRate: 10,
        tenureMonths: 12,
        interestType: 'Flat',
      });

      // Total interest = 100,000 * 0.10 * 1 = 10,000
      // Total payable = 110,000
      // EMI = 110,000 / 12 = 9166.67
      expect(result.interestType).toBe('Flat');
      expect(result.totalInterest).toBe(10000);
      expect(result.totalPayable).toBe(110000);
      expect(result.emiAmount).toBe(9166.67);
      expect(result.monthlyPrincipalComponent).toBe(8333.33);
      expect(result.monthlyInterestComponent).toBe(833.33);
    });

    it('should correctly calculate flat rate for multi-year vehicle loan (₹500,000, 9% flat, 36 months)', () => {
      const result = EmiCalculatorService.calculateEmi({
        principal: 500000,
        annualInterestRate: 9,
        tenureMonths: 36,
        interestType: 'Flat',
      });

      // Total interest = 500000 * 0.09 * 3 = 135000
      // Total payable = 635000
      // EMI = 635000 / 36 = 17638.89
      expect(result.totalInterest).toBe(135000);
      expect(result.totalPayable).toBe(635000);
      expect(result.emiAmount).toBe(17638.89);
    });
  });

  describe('Zero-Interest Rate (No-Cost EMI)', () => {
    it('should handle 0% interest rate gracefully without divide-by-zero errors', () => {
      const result = EmiCalculatorService.calculateEmi({
        principal: 60000,
        annualInterestRate: 0,
        tenureMonths: 6,
      });

      expect(result.emiAmount).toBe(10000.0);
      expect(result.totalInterest).toBe(0.0);
      expect(result.totalPayable).toBe(60000.0);
      expect(result.monthlyPrincipalComponent).toBe(10000.0);
      expect(result.monthlyInterestComponent).toBe(0.0);
    });
  });

  describe('Amortization Schedule Generation', () => {
    it('should generate complete amortization schedule with exact zero ending balance', () => {
      const principal = 200000;
      const annualRate = 12; // 1% monthly
      const tenure = 12;

      const schedule = EmiCalculatorService.generateAmortizationSchedule({
        principal,
        annualInterestRate: annualRate,
        tenureMonths: tenure,
        startDate: '2026-09-01',
        interestType: 'Reducing',
        loanId: 'test-loan-101',
      });

      expect(schedule.length).toBe(tenure);

      // Month 1 checks
      expect(schedule[0].installmentNumber).toBe(1);
      expect(schedule[0].openingBalance).toBe(principal);
      expect(schedule[0].interestAmount).toBe(2000); // 200,000 * 0.01
      expect(schedule[0].emiAmount).toBe(17769.76);
      expect(schedule[0].principalAmount).toBe(15769.76);
      expect(schedule[0].closingBalance).toBe(184230.24);

      // Verify continuity across all months
      for (let i = 0; i < schedule.length; i++) {
        const item = schedule[i];
        expect(item.principalAmount + item.interestAmount).toBeCloseTo(item.emiAmount, 1);

        if (i < schedule.length - 1) {
          expect(schedule[i + 1].openingBalance).toBe(item.closingBalance);
        }
      }

      // Final installment must reach exact zero closing balance
      const last = schedule[schedule.length - 1];
      expect(last.installmentNumber).toBe(12);
      expect(last.closingBalance).toBe(0.00);
      expect(last.principalAmount).toBe(last.openingBalance);
    });

    it('should generate amortization schedule for flat rate loan', () => {
      const schedule = EmiCalculatorService.generateAmortizationSchedule({
        principal: 120000,
        annualInterestRate: 10,
        tenureMonths: 6,
        startDate: '2026-09-01',
        interestType: 'Flat',
      });

      expect(schedule.length).toBe(6);
      expect(schedule[0].principalAmount).toBe(20000);
      expect(schedule[0].interestAmount).toBe(1000);
      expect(schedule[5].closingBalance).toBe(0.00);
    });

    it('should generate amortization schedule for 0% loan', () => {
      const schedule = EmiCalculatorService.generateAmortizationSchedule({
        principal: 50000,
        annualInterestRate: 0,
        tenureMonths: 5,
      });

      expect(schedule.length).toBe(5);
      schedule.forEach((item, idx) => {
        expect(item.interestAmount).toBe(0.00);
        expect(item.emiAmount).toBe(10000.00);
        expect(item.principalAmount).toBe(10000.00);
      });
      expect(schedule[4].closingBalance).toBe(0.00);
    });
  });

  describe('Prepayment Simulator', () => {
    it('should simulate prepayment with REDUCE_TENURE strategy', () => {
      const simulation = EmiCalculatorService.simulatePrepayment({
        currentOutstanding: 4000000,
        annualInterestRate: 8.5,
        remainingTenureMonths: 180,
        currentEmi: 39399.29,
        prepaymentAmount: 500000,
        strategy: 'REDUCE_TENURE',
      });

      expect(simulation.strategy).toBe('REDUCE_TENURE');
      expect(simulation.revisedPrincipal).toBe(3500000);
      expect(simulation.revisedEmi).toBe(39399.29);
      expect(simulation.revisedTenureMonths).toBeLessThan(180);
      expect(simulation.monthsSaved).toBeGreaterThan(0);
      expect(simulation.interestSaved).toBeGreaterThan(0);
    });

    it('should simulate prepayment with REDUCE_EMI strategy', () => {
      const simulation = EmiCalculatorService.simulatePrepayment({
        currentOutstanding: 4000000,
        annualInterestRate: 8.5,
        remainingTenureMonths: 180,
        currentEmi: 39399.29,
        prepaymentAmount: 500000,
        strategy: 'REDUCE_EMI',
      });

      expect(simulation.strategy).toBe('REDUCE_EMI');
      expect(simulation.revisedPrincipal).toBe(3500000);
      expect(simulation.revisedTenureMonths).toBe(180);
      expect(simulation.revisedEmi).toBeLessThan(39399.29);
      expect(simulation.monthlyEmiSaved).toBeGreaterThan(0);
      expect(simulation.interestSaved).toBeGreaterThan(0);
    });
  });

  describe('Flat vs Reducing Comparison', () => {
    it('should compare flat rate vs reducing balance accurately', () => {
      const comparison = EmiCalculatorService.compareFlatVsReducing({
        principal: 500000,
        annualInterestRate: 12,
        tenureMonths: 36,
      });

      expect(comparison.reducingBalance.totalInterest).toBeLessThan(comparison.flatRate.totalInterest);
      expect(comparison.difference.interestDifference).toBeGreaterThan(0);
      expect(comparison.difference.emiDifference).toBeGreaterThan(0);
    });
  });

  describe('Input Validations & Edge Cases', () => {
    it('should throw error when principal is invalid or negative', () => {
      expect(() => {
        EmiCalculatorService.calculateEmi({
          principal: -5000,
          annualInterestRate: 10,
          tenureMonths: 12,
        });
      }).toThrow('Principal amount must be greater than 0');
    });

    it('should throw error when tenure is invalid or zero', () => {
      expect(() => {
        EmiCalculatorService.calculateEmi({
          principal: 50000,
          annualInterestRate: 10,
          tenureMonths: 0,
        });
      }).toThrow('Tenure months must be greater than 0');
    });

    it('should throw error when interest rate is negative', () => {
      expect(() => {
        EmiCalculatorService.calculateEmi({
          principal: 50000,
          annualInterestRate: -5,
          tenureMonths: 12,
        });
      }).toThrow('Interest rate cannot be negative');
    });
  });
});
