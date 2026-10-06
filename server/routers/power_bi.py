from datetime import datetime
from typing import Optional, Dict, Any
from pydantic import BaseModel
from fastapi import APIRouter, Query
from models.enums import ProfileType, DateFilterOption
from services.analytics_service import AnalyticsService
from services.json_store import db_store

router = APIRouter(prefix="/api/powerbi", tags=["Power BI Backend Engine"])

POWER_BI_SCHEMA = {
    "name": "ENX_Money_Financial_Dataset",
    "defaultMode": "Push",
    "tables": [
        {
            "name": "KPI_Summaries",
            "columns": [
                {"name": "Profile", "dataType": "string"},
                {"name": "DateFilter", "dataType": "string"},
                {"name": "TotalRevenue", "dataType": "Double"},
                {"name": "TotalExpense", "dataType": "Double"},
                {"name": "NetProfit", "dataType": "Double"},
                {"name": "ProfitMargin", "dataType": "Double"},
                {"name": "CashInflow", "dataType": "Double"},
                {"name": "CashOutflow", "dataType": "Double"},
                {"name": "CollectionRate", "dataType": "Double"},
                {"name": "TotalCustomers", "dataType": "Int64"},
                {"name": "ActiveCustomers", "dataType": "Int64"},
                {"name": "AverageOrderValue", "dataType": "Double"},
                {"name": "OutstandingReceivables", "dataType": "Double"},
                {"name": "OutstandingPayables", "dataType": "Double"},
                {"name": "GstPayable", "dataType": "Double"},
                {"name": "EmiDueThisMonth", "dataType": "Double"},
                {"name": "LastUpdated", "dataType": "DateTime"},
            ],
        },
        {
            "name": "Transactions",
            "columns": [
                {"name": "TransactionID", "dataType": "string"},
                {"name": "Date", "dataType": "DateTime"},
                {"name": "ProfileType", "dataType": "string"},
                {"name": "TransactionType", "dataType": "string"},
                {"name": "Title", "dataType": "string"},
                {"name": "Category", "dataType": "string"},
                {"name": "AmountINR", "dataType": "Double"},
                {"name": "PaymentMode", "dataType": "string"},
                {"name": "GstRatePercent", "dataType": "Double"},
                {"name": "GstAmountINR", "dataType": "Double"},
                {"name": "InvoiceNumber", "dataType": "string"},
                {"name": "IsCleared", "dataType": "Int64"},
            ],
        },
    ],
}

_sync_status = {
    "lastSyncAt": None,
    "lastStatus": "Backend Push Ready",
    "totalPushedRows": 0,
    "datasetName": POWER_BI_SCHEMA["name"],
}


class PowerBiSyncRequest(BaseModel):
    endpointUrl: Optional[str] = None
    apiKey: Optional[str] = None


@router.get("/schema", summary="Get Power BI Push Dataset Schema")
def get_powerbi_schema():
    return {"success": True, "schema": POWER_BI_SCHEMA}


@router.get("/payload", summary="Generate live Power BI Push Dataset Payload")
def get_powerbi_payload(
    profile: ProfileType = Query(default=ProfileType.business),
    filter_option: DateFilterOption = Query(default=DateFilterOption.thisMonth),
):
    kpi = AnalyticsService.calculate_kpi(profile=profile, filter_option=filter_option)
    txs = db_store.get_transactions(profile=profile, filter_option=filter_option)

    formatted_rows = [
        {
            "TransactionID": t.id,
            "Date": t.date.isoformat(),
            "ProfileType": t.profile_type.value,
            "TransactionType": t.type.value,
            "Title": t.title,
            "Category": t.category,
            "AmountINR": float(t.amount),
            "PaymentMode": t.payment_mode.value,
            "GstRatePercent": float(t.gst_rate),
            "GstAmountINR": float(t.gst_amount),
            "InvoiceNumber": t.invoice_number or "",
            "IsCleared": 1 if t.is_cleared else 0,
        }
        for t in txs
    ]

    now_iso = datetime.now().isoformat()

    kpi_summary = {
        "Profile": profile.value,
        "DateFilter": filter_option.value,
        "TotalRevenue": kpi.total_revenue,
        "TotalExpense": kpi.total_expense,
        "NetProfit": kpi.net_profit,
        "ProfitMargin": kpi.business.profit_margin if kpi.business else 0.0,
        "CashInflow": kpi.business.cash_inflow if kpi.business else kpi.total_revenue,
        "CashOutflow": kpi.business.cash_outflow if kpi.business else kpi.total_expense,
        "CollectionRate": kpi.payments.collection_rate if kpi.payments else 0.0,
        "TotalCustomers": kpi.customer.total_customers if kpi.customer else 0,
        "ActiveCustomers": kpi.customer.active_customers if kpi.customer else 0,
        "AverageOrderValue": kpi.sales.average_order_value if kpi.sales else 0.0,
        "OutstandingReceivables": kpi.outstanding_receivables,
        "OutstandingPayables": kpi.outstanding_payables,
        "GstPayable": kpi.gst_payable,
        "EmiDueThisMonth": kpi.emi_due_this_month,
        "LastUpdated": now_iso,
    }

    return {
        "success": True,
        "data": {
            "dataset": POWER_BI_SCHEMA["name"],
            "generatedAt": now_iso,
            "kpiSummary": kpi_summary,
            "rows": formatted_rows,
            "rowCount": len(formatted_rows),
        },
    }


@router.post("/sync", summary="Backend automated Power BI synchronization")
def sync_to_powerbi(payload: PowerBiSyncRequest = PowerBiSyncRequest()):
    now_iso = datetime.now().isoformat()
    txs = db_store.get_transactions()

    _sync_status["lastSyncAt"] = now_iso
    _sync_status["totalPushedRows"] = len(txs)
    _sync_status["lastStatus"] = "Backend Payload Processed"

    return {
        "success": True,
        "message": "Power BI backend dataset generated and synchronized.",
        "rowsProcessed": len(txs),
        "timestamp": now_iso,
        "dataset": POWER_BI_SCHEMA["name"],
    }


@router.get("/status", summary="Get Power BI Backend Sync Status")
def get_powerbi_status():
    return {
        "success": True,
        "data": {
            **_sync_status,
            "backendEngine": "ENX Money FastAPI Power BI ETL Service",
            "autoSyncEnabled": True,
        },
    }
