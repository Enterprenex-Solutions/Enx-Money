from .enterprises import router as enterprises_router
from .customers import router as customers_router
from .suppliers import router as suppliers_router
from .transactions import router as transactions_router
from .analytics import router as analytics_router
from .reports import router as reports_router
from .data_management import router as data_router
from .power_bi import router as power_bi_router
from .ai import router as ai_router
from .notifications import router as notifications_router
from .admin import router as admin_router

__all__ = [
    "enterprises_router",
    "customers_router",
    "suppliers_router",
    "transactions_router",
    "analytics_router",
    "reports_router",
    "data_router",
    "power_bi_router",
    "ai_router",
    "notifications_router",
    "admin_router",
]
