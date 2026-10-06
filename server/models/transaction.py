from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field
import uuid
from .enums import ProfileType, TransactionType, PaymentMode


class TransactionBase(BaseModel):
    title: str = Field(..., description="Transaction summary or title")
    amount: float = Field(..., gt=0, description="Monetary value of transaction")
    type: TransactionType = Field(..., description="revenue, expense, receivable, payable, emi")
    profileType: ProfileType = Field(..., description="business or personal")
    category: str = Field(..., description="Expense or income category")
    date: datetime = Field(default_factory=datetime.now, description="Transaction date/time")
    paymentMode: PaymentMode = Field(default=PaymentMode.bankTransfer, description="Mode of payment")
    notes: Optional[str] = None
    gstRate: float = Field(default=0.0, description="GST rate percentage (e.g., 18.0)")
    invoiceNumber: Optional[str] = None
    isCleared: bool = Field(default=True, description="Whether the payment is settled")
    enterpriseId: Optional[str] = None
    customerId: Optional[str] = None
    supplierId: Optional[str] = None

    @property
    def gstAmount(self) -> float:
        return (self.amount * self.gstRate) / 100.0

    @property
    def totalWithGst(self) -> float:
        return self.amount + self.gstAmount


class TransactionCreate(TransactionBase):
    id: Optional[str] = Field(default_factory=lambda: f"tx-{uuid.uuid4().hex[:6]}")


class TransactionUpdate(BaseModel):
    title: Optional[str] = None
    amount: Optional[float] = Field(default=None, gt=0)
    type: Optional[TransactionType] = None
    profileType: Optional[ProfileType] = None
    category: Optional[str] = None
    date: Optional[datetime] = None
    paymentMode: Optional[PaymentMode] = None
    notes: Optional[str] = None
    gstRate: Optional[float] = None
    invoiceNumber: Optional[str] = None
    isCleared: Optional[bool] = None
    enterpriseId: Optional[str] = None
    customerId: Optional[str] = None
    supplierId: Optional[str] = None


class TransactionModel(TransactionBase):
    id: str

    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
