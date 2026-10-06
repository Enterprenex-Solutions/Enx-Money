from datetime import date
from typing import Dict, List, Optional
from pydantic import BaseModel, Field


class KpiSummary(BaseModel):
    totalRevenue: float = 0.0
    totalExpense: float = 0.0
    netProfit: float = 0.0
    outstandingReceivables: float = 0.0
    outstandingPayables: float = 0.0
    gstPayable: float = 0.0
    emiDueThisMonth: float = 0.0


class DailyTrendPoint(BaseModel):
    date: str
    revenue: float = 0.0
    expense: float = 0.0


class DailyTrendResponse(BaseModel):
    trend: List[DailyTrendPoint]
    totalRevenueInPeriod: float = 0.0
    totalExpenseInPeriod: float = 0.0


class CategoryBreakdownItem(BaseModel):
    category: str
    amount: float
    percentage: float


class CategoryBreakdownResponse(BaseModel):
    categories: List[CategoryBreakdownItem]
    totalAmount: float
