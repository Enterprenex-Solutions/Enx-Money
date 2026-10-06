import sys
import asyncio

# Ensure UTF-8 output on Windows console
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# Configure uvloop as the asyncio event-loop implementation for high-throughput concurrency
try:
    import uvloop
    asyncio.set_event_loop_policy(uvloop.EventLoopPolicy())
    print("[EVENT LOOP] High-performance uvloop event loop initialized.")
except (ImportError, RuntimeError, AttributeError) as exc:
    print(f"[EVENT LOOP] Standard asyncio event loop active ({exc}).")

from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from config import settings
from routers import (
    enterprises_router,
    customers_router,
    suppliers_router,
    transactions_router,
    analytics_router,
    reports_router,
    data_router,
    power_bi_router,
    ai_router,
    notifications_router,
    admin_router,
)
from services.json_store import db_store


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: ensure data storage is loaded
    print(f"[STARTUP] Initializing {settings.app_name} v{settings.version}...")
    print(f"[STARTUP] Persistent JSON Data Store: {settings.storage_path.resolve()}")
    print(f"[STARTUP] Active Event Loop Policy: {asyncio.get_event_loop_policy().__class__.__name__}")
    db_store.reload_from_disk()
    yield
    # Shutdown
    print(f"[SHUTDOWN] Shutting down {settings.app_name}...")


app = FastAPI(
    title=settings.app_name,
    version=settings.version,
    description="Full-stack REST API server for ENX Money personal & business finance tracking platform with uvloop event-loop implementation.",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

# Configure CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global Exception Handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={"error": "InternalServerError", "message": str(exc)},
    )


# Root & Health Endpoints
@app.get("/", summary="API Root & Service Information")
def root():
    return {
        "app": settings.app_name,
        "version": settings.version,
        "status": "online",
        "storage": "JSON File Persistence",
        "eventLoop": asyncio.get_event_loop_policy().__class__.__name__,
        "documentation": {
            "swagger_ui": "/docs",
            "redoc": "/redoc",
            "openapi": "/openapi.json"
        },
        "endpoints": {
            "enterprises": "/api/enterprises",
            "customers": "/api/customers",
            "suppliers": "/api/suppliers",
            "transactions": "/api/transactions",
            "analytics_kpi": "/api/analytics/kpi",
            "analytics_daily_trend": "/api/analytics/daily-trend",
            "analytics_categories": "/api/analytics/categories",
            "reports_csv": "/api/reports/csv",
            "reports_json": "/api/reports/json",
            "data_status": "/api/data/status",
            "data_raw": "/api/data/raw",
            "data_seed": "/api/data/seed",
            "data_reset": "/api/data/reset",
            "powerbi_schema": "/api/powerbi/schema",
            "powerbi_payload": "/api/powerbi/payload",
            "powerbi_sync": "/api/powerbi/sync",
            "powerbi_status": "/api/powerbi/status",
            "ai_chat": "/api/ai/chat",
            "ai_history": "/api/ai/history",
            "notifications_send": "/api/notifications/send",
            "notifications": "/api/notifications",
            "admin_analytics": "/api/admin/analytics",
            "admin_users": "/api/admin/users",
            "admin_downloads": "/api/admin/downloads",
            "admin_ratings": "/api/admin/ratings",
        }
    }


@app.get("/health", summary="Health Check")
def health_check():
    return {
        "status": "healthy",
        "storagePath": str(settings.storage_path),
        "storageExists": settings.storage_path.exists(),
        "eventLoop": asyncio.get_event_loop_policy().__class__.__name__,
    }


# Mount Routers
app.include_router(enterprises_router)
app.include_router(customers_router)
app.include_router(suppliers_router)
app.include_router(transactions_router)
app.include_router(analytics_router)
app.include_router(reports_router)
app.include_router(data_router)
app.include_router(power_bi_router)
app.include_router(ai_router)
app.include_router(notifications_router)
app.include_router(admin_router)


if __name__ == "__main__":
    import uvicorn
    loop_impl = "uvloop"
    try:
        import uvloop  # noqa: F401
    except (ImportError, RuntimeError):
        loop_impl = "auto"

    uvicorn.run("main:app", host=settings.host, port=settings.port, reload=settings.debug, loop=loop_impl)
