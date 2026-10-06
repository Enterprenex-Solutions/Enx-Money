const LoanModel = require('../src/models/loan.model');
const EmiScheduleModel = require('../src/models/emiSchedule.model');
const LoanPaymentModel = require('../src/models/loanPayment.model');
const PrepaymentModel = require('../src/models/prepayment.model');

describe('Loan EMI Management — Database Layer Models', () => {
  const testUserId = 'test-user-uuid-123';
  let createdLoanId = '';
  let createdScheduleId = '';

  it('should create a loan successfully in LoanModel', async () => {
    const loan = await LoanModel.create({
      userId: testUserId,
      loanType: 'Home',
      principalAmount: 5000000.0,
      interestRate: 8.5,
      tenureMonths: 240,
      startDate: '2026-09-01',
      interestType: 'Reducing',
      emiAmount: 43391.0,
      totalInterest: 5413840.0,
      totalPayable: 10413840.0,
      status: 'Active',
    });

    expect(loan).toBeDefined();
    expect(loan.id).toBeDefined();
    expect(loan.userId).toBe(testUserId);
    expect(loan.loanType).toBe('Home');
    expect(loan.principalAmount).toBe(5000000.0);
    expect(loan.interestRate).toBe(8.5);
    expect(loan.tenureMonths).toBe(240);
    expect(loan.interestType).toBe('Reducing');
    expect(loan.emiAmount).toBe(43391.0);
    expect(loan.status).toBe('Active');

    createdLoanId = loan.id;
  });

  it('should find loan by id and user ownership', async () => {
    const loan = await LoanModel.findByIdAndUserId(createdLoanId, testUserId);
    expect(loan).toBeDefined();
    expect(loan.id).toBe(createdLoanId);

    const wrongUserLoan = await LoanModel.findByIdAndUserId(createdLoanId, 'different-user-id');
    expect(wrongUserLoan).toBeNull();
  });

  it('should create and retrieve EMI schedule items in EmiScheduleModel', async () => {
    const schedules = [
      {
        loanId: createdLoanId,
        installmentNumber: 1,
        dueDate: '2026-10-01',
        openingBalance: 5000000.0,
        principalAmount: 7974.33,
        interestAmount: 35416.67,
        emiAmount: 43391.0,
        closingBalance: 4992025.67,
        status: 'Pending',
        lateFee: 0.0,
      },
      {
        loanId: createdLoanId,
        installmentNumber: 2,
        dueDate: '2026-11-01',
        openingBalance: 4992025.67,
        principalAmount: 8030.82,
        interestAmount: 35360.18,
        emiAmount: 43391.0,
        closingBalance: 4983994.85,
        status: 'Pending',
        lateFee: 0.0,
      },
    ];

    const result = await EmiScheduleModel.bulkCreate(schedules);
    expect(result.length).toBe(2);
    expect(result[0].installmentNumber).toBe(1);
    expect(result[0].status).toBe('Pending');

    createdScheduleId = result[0].id;

    const list = await EmiScheduleModel.findByLoanId(createdLoanId);
    expect(list.length).toBe(2);

    const nextPending = await EmiScheduleModel.findNextPendingEmi(createdLoanId);
    expect(nextPending).toBeDefined();
    expect(nextPending.installmentNumber).toBe(1);
  });

  it('should update EMI schedule status when paid', async () => {
    const updated = await EmiScheduleModel.updateStatus(createdScheduleId, {
      status: 'Paid',
      paidDate: new Date(),
      lateFee: 0,
    });

    expect(updated.status).toBe('Paid');
    expect(updated.paidDate).toBeDefined();
  });

  it('should record payment in LoanPaymentModel', async () => {
    const payment = await LoanPaymentModel.create({
      loanId: createdLoanId,
      emiScheduleId: createdScheduleId,
      amount: 43391.0,
      paymentDate: new Date(),
      paymentType: 'EMI',
      lateFee: 0,
      notes: 'October 2026 EMI installment',
    });

    expect(payment).toBeDefined();
    expect(payment.amount).toBe(43391.0);
    expect(payment.paymentType).toBe('EMI');
    expect(payment.notes).toBe('October 2026 EMI installment');

    const paymentsList = await LoanPaymentModel.findByLoanId(createdLoanId);
    expect(paymentsList.length).toBeGreaterThanOrEqual(1);
  });

  it('should record prepayment in PrepaymentModel', async () => {
    const prepayment = await PrepaymentModel.create({
      loanId: createdLoanId,
      amount: 500000.0,
      paymentDate: new Date(),
      interestSaved: 854000.0,
      revisedTenure: 198,
      revisedEmi: 43391.0,
    });

    expect(prepayment).toBeDefined();
    expect(prepayment.amount).toBe(500000.0);
    expect(prepayment.interestSaved).toBe(854000.0);
    expect(prepayment.revisedTenure).toBe(198);

    const prepaymentsList = await PrepaymentModel.findByLoanId(createdLoanId);
    expect(prepaymentsList.length).toBe(1);
  });

  it('should update loan and delete loan with cascade cleanup', async () => {
    const updatedLoan = await LoanModel.update(createdLoanId, testUserId, {
      status: 'Closed',
    });
    expect(updatedLoan.status).toBe('Closed');

    const deleted = await LoanModel.delete(createdLoanId, testUserId);
    expect(deleted).toBe(true);

    const loanAfterDelete = await LoanModel.findById(createdLoanId);
    expect(loanAfterDelete).toBeNull();
  });
});
