#!/usr/bin/env python3
"""
ENX Money REST API Server Runner
Starts the Uvicorn ASGI server with uvloop event-loop implementation and JSON database storage.
"""

import sys

# Ensure UTF-8 output on Windows console
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

import uvicorn
from config import settings


def main():
    loop_impl = "uvloop"
    try:
        import uvloop  # noqa: F401
    except (ImportError, RuntimeError):
        loop_impl = "auto"

    print("=" * 60)
    print("  ENX MONEY REST API SERVER - BACKEND (UVLOOP EVENT LOOP)")
    print("=" * 60)
    print(f"  * Version:        {settings.version}")
    print(f"  * Host:           http://{settings.host}:{settings.port}")
    print(f"  * Event Loop:     {loop_impl} (Production ASGI Engine)")
    print(f"  * Swagger Docs:   http://{settings.host}:{settings.port}/docs")
    print(f"  * ReDoc:          http://{settings.host}:{settings.port}/redoc")
    print(f"  * OpenAPI Spec:   http://{settings.host}:{settings.port}/openapi.json")
    print(f"  * JSON Database:  {settings.storage_path.resolve()}")
    print("=" * 60)
    print("  Press Ctrl+C to stop the server.")
    print("=" * 60 + "\n")

    uvicorn.run(
        "main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        loop=loop_impl,
        log_level="info",
    )


if __name__ == "__main__":
    main()
