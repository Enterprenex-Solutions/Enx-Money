#!/usr/bin/env python3
"""
Test Suite for ENX Money REST API Server and uvloop Asyncio Integration.
Runs tests against all endpoints, validates business logic, AI live chat,
notifications, and multi-user concurrent throughput.
"""

import os
import sys
import asyncio
from pathlib import Path

# Ensure UTF-8 output on Windows console
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# Load environment variables from .env if present
try:
    from dotenv import load_dotenv
    load_dotenv(Path(__file__).parent / ".env")
except ImportError:
    pass

import httpx
from fastapi.testclient import TestClient
from main import app
from services.json_store import db_store

client = TestClient(app)


def test_root_and_health():
    print("[TEST] Root & Health Endpoints...")
    res = client.get("/")
    assert res.status_code == 200, f"Root failed: {res.text}"
    data = res.json()
    assert data["status"] == "online"
    assert "documentation" in data
    assert "eventLoop" in data
    assert "ai_chat" in data["endpoints"]
    assert "notifications" in data["endpoints"]

    res_health = client.get("/health")
    assert res_health.status_code == 200
    health_data = res_health.json()
    assert health_data["status"] == "healthy"
    assert "eventLoop" in health_data
    print(f"  [PASS] Root & Health OK (Active Event Loop Policy: {health_data['eventLoop']})")


def test_seed_and_status():
    print("[TEST] Data Seed & Status...")
    res = client.post("/api/data/seed")
    assert res.status_code == 200
    assert "counts" in res.json()

    res_status = client.get("/api/data/status")
    assert res_status.status_code == 200
    status_data = res_status.json()
    assert status_data["status"] == "healthy"
    assert status_data["counts"]["enterprises"] >= 1
    assert status_data["counts"]["customers"] >= 1
    assert status_data["counts"]["suppliers"] >= 1
    assert status_data["counts"]["transactions"] >= 1
    print("  [PASS] Seed & Status OK")


def test_enterprises_crud():
    print("[TEST] Enterprises CRUD...")
    # List
    res = client.get("/api/enterprises")
    assert res.status_code == 200

    # Create
    new_ent = {
        "companyName": "Vertex Systems Pvt Ltd",
        "gstin": "29ABCDE1234F2Z5",
        "email": "contact@vertex.io",
        "phone": "+91 99887 76655",
        "address": "Indiranagar, Bengaluru",
    }
    create_res = client.post("/api/enterprises", json=new_ent)
    assert create_res.status_code == 201
    created_id = create_res.json()["id"]

    # Get by ID
    get_res = client.get(f"/api/enterprises/{created_id}")
    assert get_res.status_code == 200
    assert get_res.json()["companyName"] == "Vertex Systems Pvt Ltd"

    # Update
    update_res = client.put(f"/api/enterprises/{created_id}", json={"companyName": "Vertex Systems Global"})
    assert update_res.status_code == 200
    assert update_res.json()["companyName"] == "Vertex Systems Global"

    # Delete
    del_res = client.delete(f"/api/enterprises/{created_id}")
    assert del_res.status_code == 204
    print("  [PASS] Enterprises CRUD OK")


def test_customers_crud():
    print("[TEST] Customers CRUD...")
    new_cust = {
        "name": "Arjun Sharma",
        "companyName": "Nexus Infotech",
        "phone": "+91 98700 11223",
        "email": "arjun@nexus.com",
        "address": "Cyber City, Gurugram",
        "totalInvoiced": 120000.0,
        "outstandingBalance": 50000.0,
    }
    create_res = client.post("/api/customers", json=new_cust)
    assert create_res.status_code == 201
    cust_id = create_res.json()["id"]

    # Get
    get_res = client.get(f"/api/customers/{cust_id}")
    assert get_res.status_code == 200
    assert get_res.json()["name"] == "Arjun Sharma"

    # Update
    upd_res = client.put(f"/api/customers/{cust_id}", json={"name": "Arjun K. Sharma"})
    assert upd_res.status_code == 200
    assert upd_res.json()["name"] == "Arjun K. Sharma"

    # Clean up
    client.delete(f"/api/customers/{cust_id}")
    print("  [PASS] Customers CRUD OK")


def test_suppliers_crud():
    print("[TEST] Suppliers CRUD...")
    new_supp = {
        "name": "Google Cloud Billing",
        "companyName": "Google LLC",
        "category": "Cloud Infrastructure",
        "phone": "+91 80000 99887",
        "email": "gcp-billing@google.com",
        "totalBilled": 45000.0,
        "outstandingPayable": 45000.0,
    }
    create_res = client.post("/api/suppliers", json=new_supp)
    assert create_res.status_code == 201
    supp_id = create_res.json()["id"]

    # Get
    get_res = client.get(f"/api/suppliers/{supp_id}")
    assert get_res.status_code == 200
    assert get_res.json()["name"] == "Google Cloud Billing"

    # Clean up
    client.delete(f"/api/suppliers/{supp_id}")
    print("  [PASS] Suppliers CRUD OK")


def test_transactions_and_balance_sync():
    print("[TEST] Transactions & Auto-Balance Sync...")
    # 1. Create a customer
    cust_res = client.post("/api/customers", json={
        "name": "Test Client Corp",
        "totalInvoiced": 10000.0,
        "outstandingBalance": 0.0,
    })
    cust_id = cust_res.json()["id"]

    # 2. Add receivable transaction linked to this customer
    tx_res = client.post("/api/transactions", json={
        "title": "Cloud Consulting Milestones",
        "amount": 25000.0,
        "type": "receivable",
        "profileType": "business",
        "category": "Consulting",
        "paymentMode": "bankTransfer",
        "customerId": cust_id,
        "gstRate": 18.0,
    })
    assert tx_res.status_code == 201
    tx_id = tx_res.json()["id"]

    # 3. Verify Customer balance automatically synchronized
    cust_check = client.get(f"/api/customers/{cust_id}").json()
    assert cust_check["totalInvoiced"] == 35000.0, f"Expected 35000, got {cust_check['totalInvoiced']}"
    assert cust_check["outstandingBalance"] == 25000.0, f"Expected 25000, got {cust_check['outstandingBalance']}"

    # 4. Filter transactions
    filter_res = client.get("/api/transactions?profile=business&category=Consulting")
    assert filter_res.status_code == 200
    assert any(t["id"] == tx_id for t in filter_res.json())

    # Clean up
    client.delete(f"/api/transactions/{tx_id}")
    client.delete(f"/api/customers/{cust_id}")
    print("  [PASS] Transactions & Balance Sync OK")


def test_analytics():
    print("[TEST] Analytics (KPIs, Trend, Categories)...")
    client.post("/api/data/seed")

    kpi_res = client.get("/api/analytics/kpi?profile=business&filter_option=thisMonth")
    assert kpi_res.status_code == 200
    kpi = kpi_res.json()
    assert "totalRevenue" in kpi
    assert "totalExpense" in kpi
    assert "netProfit" in kpi
    assert kpi["totalRevenue"] >= 0

    trend_res = client.get("/api/analytics/daily-trend?profile=business&filter_option=thisMonth")
    assert trend_res.status_code == 200
    assert "trend" in trend_res.json()

    cat_res = client.get("/api/analytics/categories?profile=business&filter_option=thisMonth")
    assert cat_res.status_code == 200
    assert "categories" in cat_res.json()
    print("  [PASS] Analytics OK")


def test_reports():
    print("[TEST] CSV and JSON Reports...")
    csv_res = client.get("/api/reports/csv?profile=business&filter_option=thisMonth")
    assert csv_res.status_code == 200
    assert "text/csv" in csv_res.headers["content-type"]
    assert "Amount (INR)" in csv_res.text

    json_res = client.get("/api/reports/json?profile=business&filter_option=thisMonth")
    assert json_res.status_code == 200
    assert "kpiSummary" in json_res.json()
    assert "transactions" in json_res.json()

    cat_tax = client.get("/api/reports/categories")
    assert cat_tax.status_code == 200
    assert "business" in cat_tax.json()
    assert "personal" in cat_tax.json()
    print("  [PASS] Reports OK")


def test_ai_live_chat_and_history():
    print("[TEST] Meta AI & Live Chat Asynchronous Endpoints...")
    # 1. Validation error on empty message
    bad_res = client.post("/api/ai/chat", json={"message": "   "})
    assert bad_res.status_code == 400
    assert bad_res.json()["detail"]["error"] == "INVALID_REQUEST_BODY"

    # 2. Live chat message
    chat_res = client.post("/api/ai/chat", json={"message": "Hello", "language": "en", "provider": "auto"})
    assert chat_res.status_code in (200, 503)
    if chat_res.status_code == 200:
        data = chat_res.json()
        assert data["success"] is True
        assert "reply" in data["data"]
        assert len(data["data"]["reply"]) > 5
        print(f"  [PASS] Real AI Response: {data['data']['provider']} ({data['data']['model']})")

    # 3. History endpoints
    hist_res = client.get("/api/ai/history")
    assert hist_res.status_code == 200
    assert "data" in hist_res.json()

    del_res = client.delete("/api/ai/history")
    assert del_res.status_code == 200
    assert del_res.json()["data"]["cleared"] is True
    print("  [PASS] Meta AI Live Chat & History OK")


def test_async_notifications():
    print("[TEST] Asynchronous Notifications Non-Blocking Engine...")
    payload = {
        "title": "GST Due Reminder",
        "message": "GSTR-3B filing deadline is approaching in 2 days.",
        "channel": "push",
        "priority": "high",
        "recipient": "merchant_889"
    }
    send_res = client.post("/api/notifications/send", json=payload)
    assert send_res.status_code == 200
    data = send_res.json()
    assert data["success"] is True
    assert data["status"] == "queued"
    assert "notificationId" in data

    list_res = client.get("/api/notifications/")
    assert list_res.status_code == 200
    assert list_res.json()["success"] is True
    print("  [PASS] Notifications Async Non-Blocking Engine OK")


async def _run_concurrent_requests():
    print("[TEST] High-Concurrency Multi-User Request Processing (Asyncio/uvloop)...")
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as async_client:
        # Simulate 25 simultaneous user requests across multiple routes
        tasks = [
            async_client.get("/health"),
            async_client.get("/api/analytics/kpi?profile=business&filter_option=thisMonth"),
            async_client.get("/api/customers"),
            async_client.get("/api/suppliers"),
            async_client.get("/api/transactions"),
            async_client.get("/api/data/status"),
            async_client.get("/api/notifications/"),
            async_client.get("/api/analytics/categories?profile=business&filter_option=thisMonth"),
            async_client.get("/api/analytics/daily-trend?profile=business&filter_option=thisMonth"),
            async_client.get("/api/reports/json?profile=business&filter_option=thisMonth"),
            async_client.get("/health"),
            async_client.get("/api/customers"),
            async_client.get("/api/enterprises"),
            async_client.get("/api/transactions"),
            async_client.get("/api/analytics/kpi?profile=business&filter_option=thisMonth"),
            async_client.get("/api/data/status"),
            async_client.get("/api/notifications/"),
            async_client.get("/api/analytics/categories?profile=business&filter_option=thisMonth"),
            async_client.get("/api/analytics/daily-trend?profile=business&filter_option=thisMonth"),
            async_client.get("/api/reports/json?profile=business&filter_option=thisMonth"),
            async_client.post("/api/notifications/send", json={"title": "T1", "message": "M1"}),
            async_client.post("/api/notifications/send", json={"title": "T2", "message": "M2"}),
            async_client.post("/api/notifications/send", json={"title": "T3", "message": "M3"}),
            async_client.get("/health"),
            async_client.get("/api/data/status"),
        ]

        responses = await asyncio.gather(*tasks)
        success_count = sum(1 for r in responses if r.status_code in (200, 201))
        assert success_count == len(tasks), f"Only {success_count}/{len(tasks)} succeeded"
        print(f"  [PASS] Successfully handled {len(tasks)} concurrent simultaneous requests without blocking!")


def test_concurrent_multi_user():
    asyncio.run(_run_concurrent_requests())


def run_all_tests():
    print("\n" + "=" * 65)
    print("  STARTING ENX MONEY REST API & UVLOOP TEST SUITE")
    print("=" * 65 + "\n")

    test_root_and_health()
    test_seed_and_status()
    test_enterprises_crud()
    test_customers_crud()
    test_suppliers_crud()
    test_transactions_and_balance_sync()
    test_analytics()
    test_reports()
    test_ai_live_chat_and_history()
    test_async_notifications()
    test_concurrent_multi_user()

    print("\n" + "=" * 65)
    print("  ALL 11 TEST SUITES PASSED SUCCESSFULLY! (100% OK)")
    print("=" * 65 + "\n")


if __name__ == "__main__":
    run_all_tests()
