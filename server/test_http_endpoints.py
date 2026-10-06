"""
End-to-End HTTP Endpoint Verification for ENX Money WhatsApp Chatbot & Webhooks
"""

import sys
import httpx

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

BASE_URL = "http://127.0.0.1:8000"

def test_endpoints():
    print("=" * 60)
    print("🌐 TESTING LIVE HTTP & WEBHOOK ENDPOINTS (http://127.0.0.1:8000)")
    print("=" * 60)

    client = httpx.Client(base_url=BASE_URL, timeout=10.0)

    # 1. Root & Simulator UI
    print("\n[1] GET /whatsapp-simulator (HTML UI)")
    r = client.get("/whatsapp-simulator")
    assert r.status_code == 200
    assert "<title>ENX Money WhatsApp Chatbot Simulator</title>" in r.text
    print(f"    ✅ HTTP {r.status_code} - Simulator HTML UI loaded successfully ({len(r.text)} bytes).")

    # 2. Meta WhatsApp Webhook Verification
    print("\n[2] GET /api/whatsapp/webhook (Meta Hub Verification)")
    r = client.get("/api/whatsapp/webhook", params={
        "hub.mode": "subscribe",
        "hub.challenge": "1158201244",
        "hub.verify_token": "enx_money_webhook_token_2026"
    })
    assert r.status_code == 200
    assert r.text == "1158201244"
    print(f"    ✅ HTTP {r.status_code} - Meta Webhook verification handshake successful.")

    # 3. Simulate Financial Query (Balance & KPIs)
    print("\n[3] POST /api/whatsapp/simulate (Balance Query)")
    r = client.post("/api/whatsapp/simulate", json={
        "phoneNumber": "+91 98765 43210",
        "message": "Check my current balance and profit summary"
    })
    assert r.status_code == 200
    data = r.json()
    assert data["success"] is True
    assert "Financial Summary" in data["data"]["reply"]
    print(f"    ✅ HTTP {r.status_code} - Balance query replied:\n       {data['data']['reply'].splitlines()[0]}")

    # 4. Simulate Customer Receivables Query
    print("\n[4] POST /api/whatsapp/simulate (Receivables Due)")
    r = client.post("/api/whatsapp/simulate", json={
        "phoneNumber": "+91 98765 43210",
        "message": "Who owes me money?"
    })
    assert r.status_code == 200
    data = r.json()
    assert data["success"] is True
    print(f"    ✅ HTTP {r.status_code} - Receivables query replied:\n       {data['data']['reply'].splitlines()[0]}")

    # 5. Simulate Secure App Handoff Link Generation
    print("\n[5] POST /api/whatsapp/simulate (App Handoff Link)")
    r = client.post("/api/whatsapp/simulate", json={
        "phoneNumber": "+91 98765 43210",
        "message": "Give me a link to open the app"
    })
    assert r.status_code == 200
    data = r.json()
    assert data["success"] is True
    assert "token=" in data["data"]["reply"]

    # Extract token from response
    reply_text = data["data"]["reply"]
    token_str = reply_text.split("token=")[1].split()[0].replace("\n", "")
    print(f"    ✅ HTTP {r.status_code} - Handoff link generated with token: {token_str}")

    # 6. Verify Handoff Link Landing Page
    print("\n[6] GET /api/whatsapp/handoff/open (Landing Page Verification)")
    r = client.get(f"/api/whatsapp/handoff/open?token={token_str}")
    assert r.status_code == 200
    assert "App Handoff Authenticated!" in r.text
    print(f"    ✅ HTTP {r.status_code} - Handoff landing page authenticated user successfully.")

    # 7. Active Sessions List
    print("\n[7] GET /api/whatsapp/sessions (Sessions List)")
    r = client.get("/api/whatsapp/sessions")
    assert r.status_code == 200
    data = r.json()
    assert data["success"] is True
    print(f"    ✅ HTTP {r.status_code} - Active paired users: {list(data['users'].keys())}")

    print("\n" + "=" * 60)
    print("🎉 ALL LIVE HTTP AND WEBHOOK ENDPOINT CHECKS PASSED! 🎉")
    print("=" * 60)

if __name__ == "__main__":
    test_endpoints()
