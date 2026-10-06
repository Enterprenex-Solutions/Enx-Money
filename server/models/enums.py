from enum import Enum


class ProfileType(str, Enum):
    personal = "personal"
    business = "business"


class TransactionType(str, Enum):
    revenue = "revenue"
    expense = "expense"
    receivable = "receivable"
    payable = "payable"
    emi = "emi"


class DateFilterOption(str, Enum):
    today = "today"
    thisWeek = "thisWeek"
    thisMonth = "thisMonth"
    financialYear = "financialYear"
    custom = "custom"


class PaymentMode(str, Enum):
    cash = "cash"
    upi = "upi"
    bankTransfer = "bankTransfer"
    creditCard = "creditCard"
    cheque = "cheque"
