from datetime import datetime, timedelta
from typing import Tuple, Optional
from models.enums import DateFilterOption


def get_date_range_boundary(
    filter_option: DateFilterOption,
    custom_start: Optional[datetime] = None,
    custom_end: Optional[datetime] = None,
    reference_date: Optional[datetime] = None
) -> Tuple[datetime, datetime]:
    now = reference_date or datetime.now()

    if filter_option == DateFilterOption.today:
        start = datetime(now.year, now.month, now.day, 0, 0, 0)
        end = datetime(now.year, now.month, now.day, 23, 59, 59)
        return start, end

    elif filter_option == DateFilterOption.thisWeek:
        # Monday is 0 in Python weekday()
        monday = now - timedelta(days=now.weekday())
        start = datetime(monday.year, monday.month, monday.day, 0, 0, 0)
        sunday = monday + timedelta(days=6)
        end = datetime(sunday.year, sunday.month, sunday.day, 23, 59, 59)
        return start, end

    elif filter_option == DateFilterOption.thisMonth:
        start = datetime(now.year, now.month, 1, 0, 0, 0)
        # End of month
        if now.month == 12:
            next_month = datetime(now.year + 1, 1, 1, 0, 0, 0)
        else:
            next_month = datetime(now.year, now.month + 1, 1, 0, 0, 0)
        end = next_month - timedelta(seconds=1)
        return start, end

    elif filter_option == DateFilterOption.financialYear:
        # Indian FY starts April 1
        fy_start_year = now.year if now.month >= 4 else now.year - 1
        start = datetime(fy_start_year, 4, 1, 0, 0, 0)
        end = datetime(fy_start_year + 1, 3, 31, 23, 59, 59)
        return start, end

    elif filter_option == DateFilterOption.custom:
        start = custom_start or datetime(now.year, now.month, 1, 0, 0, 0)
        end = custom_end or datetime(now.year, now.month, now.day, 23, 59, 59)
        return start, end

    # Fallback
    return datetime(now.year, now.month, 1, 0, 0, 0), now
