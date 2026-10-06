enum ProfileType {
  personal('Personal Expense', 'Personal bank accounts, home budget & daily expenses'),
  business('Business Management', 'Commercial revenues, vendor payments, GST & invoices');

  final String label;
  final String description;
  const ProfileType(this.label, this.description);
}

enum TransactionType {
  revenue('Revenue / Income', true),
  expense('Expense / Outflow', false),
  receivable('Receivable', true),
  payable('Payable', false),
  emi('EMI Due', false);

  final String label;
  final bool isPositive;
  const TransactionType(this.label, this.isPositive);
}

enum DateFilterOption {
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  financialYear('Financial Year'),
  custom('Custom Range');

  final String label;
  const DateFilterOption(this.label);
}

enum PaymentMode {
  cash('Cash'),
  upi('UPI / Wallet'),
  bankTransfer('Bank Transfer'),
  creditCard('Credit Card'),
  cheque('Cheque');

  final String label;
  const PaymentMode(this.label);
}
