from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field
import uuid


class SupplierBase(BaseModel):
    name: str = Field(..., description="Supplier / Vendor name")
    companyName: Optional[str] = None
    category: str = Field(default="General Vendor", description="Vendor category")
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    totalBilled: float = Field(default=0.0, description="Cumulative billed amount")
    outstandingPayable: float = Field(default=0.0, description="Outstanding payable balance")


class SupplierCreate(SupplierBase):
    id: Optional[str] = Field(default_factory=lambda: f"supp-{uuid.uuid4().hex[:6]}")
    createdAt: Optional[datetime] = Field(default_factory=datetime.now)


class SupplierUpdate(BaseModel):
    name: Optional[str] = None
    companyName: Optional[str] = None
    category: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    totalBilled: Optional[float] = None
    outstandingPayable: Optional[float] = None


class SupplierModel(SupplierBase):
    id: str
    createdAt: datetime

    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
