import csv
import io
import json
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional
from config import settings
from models.enums import ProfileType, DateFilterOption
from services.analytics_service import AnalyticsService
from utils.serializers import CustomJSONEncoder


class ReportService:

    @staticmethod
    def _ensure_export_dir() -> Path:
        export_dir = settings.exports_path
        export_dir.mkdir(parents=True, exist_ok=True)
        return export_dir

    @classmethod
    def generate_csv_report(
        cls,
        profile: ProfileType = ProfileType.business,
        filter_option: DateFilterOption = DateFilterOption.thisMonth,
        custom_start: Optional[datetime] = None,
        custom_end: Optional[datetime] = None,
        category: Optional[str] = None,
    ) -> str:
        transactions = AnalyticsService.get_filtered_transactions(
            profile=profile,
            filter_option=filter_option,
            custom_start=custom_start,
            custom_end=custom_end,
            category=category,
        )

        output = io.StringIO()
        fieldnames = [
            "ID",
            "Date",
            "Title",
            "Type",
            "Category",
            "Amount (INR)",
            "GST Rate (%)",
            "GST Amount (INR)",
            "Total With GST (INR)",
            "Payment Mode",
            "Invoice Number",
            "Is Cleared",
            "Notes",
            "Customer ID",
            "Supplier ID",
            "Enterprise ID",
        ]

        writer = csv.DictWriter(output, fieldnames=fieldnames)
        writer.writeheader()

        for tx in transactions:
            amount = float(tx.get("amount", 0.0))
            gst_rate = float(tx.get("gstRate", 0.0))
            gst_amount = (amount * gst_rate) / 100.0
            total_with_gst = amount + gst_amount

            writer.writerow({
                "ID": tx.get("id", ""),
                "Date": tx.get("date", ""),
                "Title": tx.get("title", ""),
                "Type": tx.get("type", ""),
                "Category": tx.get("category", ""),
                "Amount (INR)": f"{amount:.2f}",
                "GST Rate (%)": f"{gst_rate:.1f}",
                "GST Amount (INR)": f"{gst_amount:.2f}",
                "Total With GST (INR)": f"{total_with_gst:.2f}",
                "Payment Mode": tx.get("paymentMode", ""),
                "Invoice Number": tx.get("invoiceNumber") or "-",
                "Is Cleared": "Yes" if tx.get("isCleared", True) else "No",
                "Notes": tx.get("notes") or "",
                "Customer ID": tx.get("customerId") or "-",
                "Supplier ID": tx.get("supplierId") or "-",
                "Enterprise ID": tx.get("enterpriseId") or "-",
            })

        return output.getvalue()

    @classmethod
    def save_csv_report_file(
        cls,
        profile: ProfileType = ProfileType.business,
        filter_option: DateFilterOption = DateFilterOption.thisMonth,
    ) -> Path:
        csv_content = cls.generate_csv_report(profile=profile, filter_option=filter_option)
        export_dir = cls._ensure_export_dir()
        filename = f"ENX_Report_{profile.value}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
        file_path = export_dir / filename
        with open(file_path, "w", encoding="utf-8-sig", newline="") as f:
            f.write(csv_content)
        return file_path

    @classmethod
    def generate_json_report(
        cls,
        profile: ProfileType = ProfileType.business,
        filter_option: DateFilterOption = DateFilterOption.thisMonth,
    ) -> Dict:
        kpi = AnalyticsService.calculate_kpi_summary(profile=profile, filter_option=filter_option)
        trend = AnalyticsService.calculate_daily_trend(profile=profile, filter_option=filter_option)
        categories = AnalyticsService.calculate_category_breakdown(profile=profile, filter_option=filter_option)
        transactions = AnalyticsService.get_filtered_transactions(profile=profile, filter_option=filter_option)

        return {
            "metadata": {
                "generatedAt": datetime.now().isoformat(),
                "profile": profile.value,
                "dateFilter": filter_option.value,
                "currency": settings.default_currency,
                "totalRecords": len(transactions),
            },
            "kpiSummary": kpi.dict(),
            "dailyTrend": trend.dict(),
            "categoryBreakdown": categories.dict(),
            "transactions": transactions,
        }
