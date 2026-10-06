from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field
import uuid


class EnterpriseBase(BaseModel):
    companyName: str = Field(..., description="Registered company name")
    gstin: str = Field(..., description="GST Identification Number")
    email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None


class EnterpriseCreate(EnterpriseBase):
    id: Optional[str] = Field(default_factory=lambda: f"ent-{uuid.uuid4().hex[:6]}")
    createdAt: Optional[datetime] = Field(default_factory=datetime.now)


class EnterpriseUpdate(BaseModel):
    companyName: Optional[str] = None
    gstin: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None


class EnterpriseModel(EnterpriseBase):
    id: str
    createdAt: datetime

    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
