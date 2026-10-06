from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Query
from models.enums import ProfileType, DateFilterOption
from models.analytics import KpiSummary, DailyTrendResponse, CategoryBreakdownResponse
from services.analytics_service import AnalyticsService

router = APIRouter(prefix="/api/analytics", tags=["Analytics & KPIs"])


@router.get("/kpi", response_model=KpiSummary, summary="Calculate dynamic financial KPI summary")
def get_kpi_summary(
    profile: ProfileType = Query(default=ProfileType.business, description="Profile type: business or personal"),
    filter_option: DateFilterOption = Query(default=DateFilterOption.thisMonth, description="Date filter range"),
    custom_start: Optional[datetime] = Query(default=None, description="Custom range start date (ISO-8601)"),
    custom_end: Optional[datetime] = Query(default=None, description="Custom range end date (ISO-8601)"),
):
    return AnalyticsService.calculate_kpi_summary(
        profile=profile,
        filter_option=filter_option,
        custom_start=custom_start,
        custom_end=custom_end,
    )


@router.get("/daily-trend", response_model=DailyTrendResponse, summary="Calculate daily trend for line charts")
def get_daily_trend(
    profile: ProfileType = Query(default=ProfileType.business, description="Profile type: business or personal"),
    filter_option: DateFilterOption = Query(default=DateFilterOption.thisMonth, description="Date filter range"),
    custom_start: Optional[datetime] = Query(default=None, description="Custom range start date (ISO-8601)"),
    custom_end: Optional[datetime] = Query(default=None, description="Custom range end date (ISO-8601)"),
):
    return AnalyticsService.calculate_daily_trend(
        profile=profile,
        filter_option=filter_option,
        custom_start=custom_start,
        custom_end=custom_end,
    )


@router.get("/categories", response_model=CategoryBreakdownResponse, summary="Calculate category breakdown for pie/donut charts")
def get_category_breakdown(
    profile: ProfileType = Query(default=ProfileType.business, description="Profile type: business or personal"),
    filter_option: DateFilterOption = Query(default=DateFilterOption.thisMonth, description="Date filter range"),
    custom_start: Optional[datetime] = Query(default=None, description="Custom range start date (ISO-8601)"),
    custom_end: Optional[datetime] = Query(default=None, description="Custom range end date (ISO-8601)"),
):
    return AnalyticsService.calculate_category_breakdown(
        profile=profile,
        filter_option=filter_option,
        custom_start=custom_start,
        custom_end=custom_end,
    )
