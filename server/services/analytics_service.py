from datetime import datetime, date
from typing import Dict, List, Optional
from models.enums import ProfileType, TransactionType, DateFilterOption
from models.analytics import KpiSummary, DailyTrendPoint, DailyTrendResponse, CategoryBreakdownItem, CategoryBreakdownResponse
from services.json_store import db_store
from utils.date_helpers import get_date_range_boundary


class AnalyticsService:

    @staticmethod
    def get_filtered_transactions(
        profile: ProfileType = ProfileType.business,
        filter_option: DateFilterOption = DateFilterOption.thisMonth,
        custom_start: Optional[datetime] = None,
        custom_end: Optional[datetime] = None,
        category: Optional[str] = None,
        search_query: Optional[str] = None,
        drill_down_type: Optional[TransactionType] = None,
    ) -> List[Dict]:
        start_date, end_date = get_date_range_boundary(
            filter_option,
            custom_start=custom_start,
            custom_end=custom_end
        )

        all_tx = db_store.get_all_transactions()
        filtered = []

        for tx in all_tx:
            # Match profile
            if tx.get("profileType") != profile.value:
                continue

            # Match date boundary
            tx_date_str = tx.get("date")
            if not tx_date_str:
                continue
            try:
                tx_date = datetime.fromisoformat(tx_date_str)
            except Exception:
                continue

            if tx_date < start_date or tx_date > end_date:
                continue

            # Match search query
            if search_query:
                query = search_query.lower()
                title = (tx.get("title") or "").lower()
                cat = (tx.get("category") or "").lower()
                inv = (tx.get("invoiceNumber") or "").lower()
                if query not in title and query not in cat and query not in inv:
                    continue

            # Match category
            if category and category != "All":
                if tx.get("category") != category:
                    continue

            # Match drill down type
            if drill_down_type:
                if tx.get("type") != drill_down_type.value:
                    continue

            filtered.append(tx)

        return filtered

    @classmethod
    def calculate_kpi_summary(
        cls,
        profile: ProfileType = ProfileType.business,
        filter_option: DateFilterOption = DateFilterOption.thisMonth,
        custom_start: Optional[datetime] = None,
        custom_end: Optional[datetime] = None,
    ) -> KpiSummary:
        transactions = cls.get_filtered_transactions(
            profile=profile,
            filter_option=filter_option,
            custom_start=custom_start,
            custom_end=custom_end,
        )

        revenue = 0.0
        expense = 0.0
        receivables = 0.0
        payables = 0.0
        gst = 0.0
        emi = 0.0

        for tx in transactions:
            amount = float(tx.get("amount", 0.0))
            gst_rate = float(tx.get("gstRate", 0.0))
            tx_type = tx.get("type")

            if tx_type == TransactionType.revenue.value:
                revenue += amount
                gst += (amount * gst_rate) / 100.0
            elif tx_type == TransactionType.expense.value:
                expense += amount
            elif tx_type == TransactionType.receivable.value:
                receivables += amount
            elif tx_type == TransactionType.payable.value:
                payables += amount
            elif tx_type == TransactionType.emi.value:
                emi += amount

        if profile == ProfileType.personal:
            receivables = 0.0
            payables = 0.0
            gst = 0.0
            emi = 0.0

        return KpiSummary(
            totalRevenue=round(revenue, 2),
            totalExpense=round(expense, 2),
            netProfit=round(revenue - expense, 2),
            outstandingReceivables=round(receivables, 2),
            outstandingPayables=round(payables, 2),
            gstPayable=round(gst, 2),
            emiDueThisMonth=round(emi, 2),
        )

    @classmethod
    def calculate_daily_trend(
        cls,
        profile: ProfileType = ProfileType.business,
        filter_option: DateFilterOption = DateFilterOption.thisMonth,
        custom_start: Optional[datetime] = None,
        custom_end: Optional[datetime] = None,
    ) -> DailyTrendResponse:
        transactions = cls.get_filtered_transactions(
            profile=profile,
            filter_option=filter_option,
            custom_start=custom_start,
            custom_end=custom_end,
        )

        daily_map: Dict[str, Dict[str, float]] = {}
        total_rev = 0.0
        total_exp = 0.0

        for tx in transactions:
            tx_date_str = tx.get("date")
            if not tx_date_str:
                continue
            date_key = tx_date_str[:10]  # YYYY-MM-DD
            if date_key not in daily_map:
                daily_map[date_key] = {"revenue": 0.0, "expense": 0.0}

            amount = float(tx.get("amount", 0.0))
            tx_type = tx.get("type")

            if tx_type == TransactionType.revenue.value:
                daily_map[date_key]["revenue"] += amount
                total_rev += amount
            elif tx_type == TransactionType.expense.value:
                daily_map[date_key]["expense"] += amount
                total_exp += amount

        points = [
            DailyTrendPoint(
                date=k,
                revenue=round(v["revenue"], 2),
                expense=round(v["expense"], 2)
            )
            for k, v in sorted(daily_map.items())
        ]

        return DailyTrendResponse(
            trend=points,
            totalRevenueInPeriod=round(total_rev, 2),
            totalExpenseInPeriod=round(total_exp, 2),
        )

    @classmethod
    def calculate_category_breakdown(
        cls,
        profile: ProfileType = ProfileType.business,
        filter_option: DateFilterOption = DateFilterOption.thisMonth,
        custom_start: Optional[datetime] = None,
        custom_end: Optional[datetime] = None,
    ) -> CategoryBreakdownResponse:
        transactions = cls.get_filtered_transactions(
            profile=profile,
            filter_option=filter_option,
            custom_start=custom_start,
            custom_end=custom_end,
        )

        breakdown: Dict[str, float] = {}
        total_amount = 0.0

        for tx in transactions:
            tx_type = tx.get("type")
            if tx_type in (TransactionType.expense.value, TransactionType.revenue.value):
                cat = tx.get("category") or "Uncategorized"
                amount = float(tx.get("amount", 0.0))
                breakdown[cat] = breakdown.get(cat, 0.0) + amount
                total_amount += amount

        items = []
        for cat, amt in sorted(breakdown.items(), key=lambda x: x[1], reverse=True):
            pct = (amt / total_amount * 100.0) if total_amount > 0 else 0.0
            items.append(CategoryBreakdownItem(
                category=cat,
                amount=round(amt, 2),
                percentage=round(pct, 2)
            ))

        return CategoryBreakdownResponse(
            categories=items,
            totalAmount=round(total_amount, 2)
        )
