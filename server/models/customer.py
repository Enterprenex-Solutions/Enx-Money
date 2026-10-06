from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field
import uuid


class CustomerBase(BaseModel):
    name: str = Field(..., description="Customer primary contact person or client name")
    companyName: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    totalInvoiced: float = Field(default=0.0, description="Cumulative amount invoiced")
    outstandingBalance: float = Field(default=0.0, description="Outstanding receivable balance")


class CustomerCreate(CustomerBase):
    id: Optional[str] = Field(default_factory=lambda: f"cust-{uuid.uuid4().hex[:6]}")
    createdAt: Optional[datetime] = Field(default_factory=datetime.now)


class CustomerUpdate(BaseModel):
    name: Optional[str] = None
    companyName: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    totalInvoiced: Optional[float] = None
    outstandingBalance: Optional[float] = None


class CustomerModel(CustomerBase):
    id: str
    createdAt: datetime

    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
