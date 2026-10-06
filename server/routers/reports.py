from datetime import datetime
from typing import Dict, List, Optional
from fastapi import APIRouter, Query, Response
from models.enums import ProfileType, DateFilterOption
from services.json_store import db_store
from services.report_service import ReportService

router = APIRouter(prefix="/api/reports", tags=["Reports & Exports"])


@router.get("/csv", summary="Export transactions to CSV format")
def export_csv_report(
    profile: ProfileType = Query(default=ProfileType.business, description="Profile: business or personal"),
    filter_option: DateFilterOption = Query(default=DateFilterOption.thisMonth, description="Date filter"),
    custom_start: Optional[datetime] = Query(default=None, description="Custom start date"),
    custom_end: Optional[datetime] = Query(default=None, description="Custom end date"),
    category: Optional[str] = Query(default=None, description="Filter by category"),
):
    csv_data = ReportService.generate_csv_report(
        profile=profile,
        filter_option=filter_option,
        custom_start=custom_start,
        custom_end=custom_end,
        category=category,
    )
    filename = f"ENX_{profile.value}_Report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
    return Response(
        content=csv_data,
        media_type="text/csv",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'}
    )


@router.get("/json", summary="Export comprehensive financial report in JSON format")
def export_json_report(
    profile: ProfileType = Query(default=ProfileType.business, description="Profile: business or personal"),
    filter_option: DateFilterOption = Query(default=DateFilterOption.thisMonth, description="Date filter"),
):
    return ReportService.generate_json_report(profile=profile, filter_option=filter_option)


@router.get("/categories", summary="Get predefined categories taxonomy")
def get_categories_taxonomy(
    profile: Optional[str] = Query(default=None, description="Optional profile: business or personal")
):
    return db_store.get_categories(profile=profile)


@router.get("/profiles", summary="Get supported user profile modes")
def get_profiles():
    return db_store.get_profiles()
