"""
FastAPI Router for ENX Money WhatsApp Chatbot
Webhook verification, message ingestion, simulator API, and app handoff.
"""

import os
import secrets
import datetime
from pathlib import Path
from fastapi import APIRouter, Request, Response, Query, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from services.whatsapp_ai_service import (
    process_whatsapp_message,
    send_whatsapp_message,
    get_whatsapp_user,
    verify_handoff_token,
    normalize_phone,
    exec_add_transaction,
    _sessions
)
from services.json_store import db_store

whatsapp_router = APIRouter(prefix="/api/whatsapp", tags=["WhatsApp Chatbot"])


class SimulateRequest(BaseModel):
    phoneNumber: str = Field(default="919876543210", description="WhatsApp Phone Number")
    message: str = Field(..., description="Message text or financial query")


class LinkAccountRequest(BaseModel):
    phoneNumber: str = Field(..., description="Real WhatsApp Phone Number (with country code)")
    userName: str = Field(..., description="User Full Name")
    email: str = Field(..., description="Registered Email Address")
    companyName: Optional[str] = Field(default=None, description="Enterprise or Business Name")
    profileType: Optional[str] = Field(default="business", description="Default Profile: business or personal")
    notes: Optional[str] = Field(default=None, description="Optional notes")


class CustomTransactionRequest(BaseModel):
    phoneNumber: str = Field(default="919876543210", description="WhatsApp Phone Number")
    amount: float = Field(..., gt=0, description="Custom monetary amount")
    title: str = Field(..., description="Item description or title")
    type: str = Field(default="expense", description="expense or revenue")
    category: Optional[str] = Field(default=None, description="Category name")
    profileType: Optional[str] = Field(default=None, description="business or personal")
    paymentMode: Optional[str] = Field(default="upi", description="upi, bankTransfer, cash, creditCard, debitCard")


class WhatsAppConfigUpdateRequest(BaseModel):
    whatsappVerifyToken: Optional[str] = None
    whatsappAccessToken: Optional[str] = None
    whatsappPhoneNumberId: Optional[str] = None
    whatsappProvider: Optional[str] = None
    geminiApiKey: Optional[str] = None
    geminiModel: Optional[str] = None


@whatsapp_router.get("/webhook", summary="Meta WhatsApp Cloud API Verification")
async def verify_meta_webhook(
    hub_mode: Optional[str] = Query(None, alias="hub.mode"),
    hub_challenge: Optional[str] = Query(None, alias="hub.challenge"),
    hub_verify_token: Optional[str] = Query(None, alias="hub.verify_token")
):
    expected = os.getenv("WHATSAPP_VERIFY_TOKEN", "enx_money_webhook_token_2026")
    if hub_mode == "subscribe" and hub_verify_token == expected:
        return Response(content=hub_challenge or "", media_type="text/plain")
    raise HTTPException(status_code=403, detail="Verification token mismatch.")


@whatsapp_router.post("/webhook", summary="Meta WhatsApp Inbound Message Webhook")
async def handle_meta_webhook(request: Request):
    body = await request.json()
    if body.get("object") == "whatsapp_business_account":
        entry = body.get("entry", [{}])[0]
        changes = entry.get("changes", [{}])[0]
        value = changes.get("value", {})
        messages = value.get("messages", [])

        if messages:
            msg = messages[0]
            if msg.get("type") == "text":
                sender = msg.get("from")
                text = msg.get("text", {}).get("body", "")
                result = await process_whatsapp_message(sender, text)
                if result and result.get("reply"):
                    await send_whatsapp_message(sender, result["reply"])
        return Response(content="EVENT_RECEIVED", status_code=200)
    return Response(status_code=404)


@whatsapp_router.post("/twilio-webhook", summary="Twilio WhatsApp Webhook")
async def handle_twilio_webhook(request: Request):
    form_data = await request.form()
    sender = form_data.get("From") or form_data.get("from")
    body = form_data.get("Body") or form_data.get("body")

    if sender and body:
        res = await process_whatsapp_message(str(sender), str(body))
        xml = f"<Response><Message>{res['reply']}</Message></Response>"
        return Response(content=xml, media_type="application/xml")
    raise HTTPException(status_code=400, detail="Missing From or Body in form.")


@whatsapp_router.get("/config", summary="Get Current WhatsApp & Gemini Status")
async def get_whatsapp_config():
    access_token = os.getenv("WHATSAPP_ACCESS_TOKEN", "")
    gemini_key = os.getenv("GEMINI_API_KEY", "")
    masked_token = f"{access_token[:6]}...{access_token[-4:]}" if len(access_token) > 12 else ("Configured" if access_token else "Not Set")
    masked_gemini = f"{gemini_key[:6]}...{gemini_key[-4:]}" if len(gemini_key) > 12 else ("Configured" if gemini_key else "Not Set")

    return {
        "success": True,
        "config": {
            "whatsappVerifyToken": os.getenv("WHATSAPP_VERIFY_TOKEN", "enx_money_webhook_token_2026"),
            "whatsappAccessToken": masked_token,
            "whatsappPhoneNumberId": os.getenv("WHATSAPP_PHONE_NUMBER_ID", ""),
            "whatsappProvider": os.getenv("WHATSAPP_PROVIDER", "simulator"),
            "geminiApiKey": masked_gemini,
            "geminiModel": os.getenv("GEMINI_MODEL", "gemini-2.5-flash"),
            "isGeminiConfigured": bool(gemini_key),
            "isMetaConfigured": bool(access_token and os.getenv("WHATSAPP_PHONE_NUMBER_ID")),
        }
    }


@whatsapp_router.post("/config", summary="Update WhatsApp & Gemini Configuration")
async def update_whatsapp_config(req: WhatsAppConfigUpdateRequest):
    if req.whatsappVerifyToken is not None:
        os.environ["WHATSAPP_VERIFY_TOKEN"] = req.whatsappVerifyToken.strip()
    if req.whatsappAccessToken is not None:
        os.environ["WHATSAPP_ACCESS_TOKEN"] = req.whatsappAccessToken.strip()
    if req.whatsappPhoneNumberId is not None:
        os.environ["WHATSAPP_PHONE_NUMBER_ID"] = req.whatsappPhoneNumberId.strip()
    if req.whatsappProvider is not None:
        os.environ["WHATSAPP_PROVIDER"] = req.whatsappProvider.strip()
    if req.geminiApiKey is not None:
        os.environ["GEMINI_API_KEY"] = req.geminiApiKey.strip()
    if req.geminiModel is not None:
        os.environ["GEMINI_MODEL"] = req.geminiModel.strip()

    # Persist changes to server/.env
    env_path = Path(__file__).resolve().parent.parent / ".env"
    if env_path.exists():
        try:
            lines = env_path.read_text(encoding="utf-8").splitlines()
            keys_to_update = {
                "WHATSAPP_VERIFY_TOKEN": os.getenv("WHATSAPP_VERIFY_TOKEN"),
                "WHATSAPP_ACCESS_TOKEN": os.getenv("WHATSAPP_ACCESS_TOKEN"),
                "WHATSAPP_PHONE_NUMBER_ID": os.getenv("WHATSAPP_PHONE_NUMBER_ID"),
                "WHATSAPP_PROVIDER": os.getenv("WHATSAPP_PROVIDER"),
                "GEMINI_API_KEY": os.getenv("GEMINI_API_KEY"),
                "GEMINI_MODEL": os.getenv("GEMINI_MODEL"),
            }
            new_lines = []
            found_keys = set()
            for line in lines:
                if "=" in line and not line.strip().startswith("#"):
                    k = line.split("=", 1)[0].strip()
                    if k in keys_to_update:
                        new_lines.append(f"{k}={keys_to_update[k] or ''}")
                        found_keys.add(k)
                        continue
                new_lines.append(line)
            for k, v in keys_to_update.items():
                if k not in found_keys:
                    new_lines.append(f"{k}={v or ''}")
            env_path.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
        except Exception as e:
            print(f"[WARN] Failed to update .env: {e}")

    return {"success": True, "message": "WhatsApp & Gemini configuration updated successfully."}


@whatsapp_router.post("/simulate", summary="WhatsApp Web Simulator API")
async def simulate_message(req: SimulateRequest):
    result = await process_whatsapp_message(req.phoneNumber, req.message)
    user = get_whatsapp_user(req.phoneNumber)

    return {
        "success": True,
        "data": {
            "phoneNumber": normalize_phone(req.phoneNumber),
            "user": user,
            "reply": result.get("reply"),
            "intent": result.get("intent", "GENERAL"),
            "toolCalled": result.get("tool"),
            "sessionState": result.get("state", "IDLE"),
            "otpCode": result.get("otpCode")
        }
    }


@whatsapp_router.post("/link-account", summary="Link Real Account with WhatsApp Number")
async def link_real_account(req: LinkAccountRequest):
    phone = normalize_phone(req.phoneNumber)
    if not phone or len(phone) < 10:
        raise HTTPException(status_code=400, detail="Invalid WhatsApp phone number. Please include country code, e.g. 919876543210.")

    # 1. Check or associate enterprise if companyName provided
    ent_id = None
    if req.companyName:
        enterprises = db_store.get_all_enterprises()
        matching_ent = next((e for e in enterprises if req.companyName.lower() in e.get("companyName", "").lower()), None)
        if matching_ent:
            ent_id = matching_ent.get("id")
        else:
            # Create enterprise record
            new_ent = {
                "id": f"ent-{secrets.token_hex(3)}",
                "companyName": req.companyName.strip(),
                "gstin": "27AAACE1234F1Z9",
                "email": req.email.strip(),
                "phone": f"+{phone}",
                "address": "Registered Office"
            }
            db_store.add_enterprise(new_ent)
            ent_id = new_ent["id"]

    # 2. Persist to json_store
    user_record = {
        "phoneNumber": phone,
        "phone_number": phone,
        "userName": req.userName.strip(),
        "user_name": req.userName.strip(),
        "email": req.email.strip(),
        "user_email": req.email.strip(),
        "companyName": req.companyName.strip() if req.companyName else "ENX Enterprise",
        "company_name": req.companyName.strip() if req.companyName else "ENX Enterprise",
        "enterpriseId": ent_id,
        "profileType": req.profileType or "business",
        "verification_status": "verified",
        "language": "en",
        "daily_summary": True,
        "notes": req.notes
    }
    saved_user = db_store.save_whatsapp_user(user_record)

    # 3. Create audit message in chats
    welcome_msg = {
        "id": f"msg-{secrets.token_hex(4)}",
        "phoneNumber": phone,
        "direction": "outbound",
        "message": f"🎉 *Account Successfully Linked!*\n\nHello *{req.userName}*, your real WhatsApp number *+{phone}* is now linked to *{user_record['companyName']}*.\n\nYou can now check live balances, add custom expenses, and query financial metrics.",
        "timestamp": datetime.datetime.now().isoformat()
    }
    db_store.save_whatsapp_message(welcome_msg)

    return {
        "success": True,
        "message": f"Real WhatsApp account for '{req.userName}' (+{phone}) linked and saved successfully.",
        "user": saved_user
    }


@whatsapp_router.get("/users", summary="Get All Linked WhatsApp Users")
async def get_whatsapp_users_list():
    users = db_store.get_all_whatsapp_users()
    return {"success": True, "users": users}


@whatsapp_router.get("/chats", summary="Get Saved WhatsApp Chat Messages")
async def get_saved_chats(phoneNumber: Optional[str] = Query(None, description="Optional phone number filter")):
    phone = normalize_phone(phoneNumber) if phoneNumber else None
    chats = db_store.get_whatsapp_chats(phone=phone, limit=200)
    return {"success": True, "count": len(chats), "chats": chats}


@whatsapp_router.delete("/chats", summary="Clear WhatsApp Chat History")
async def clear_chats(phoneNumber: Optional[str] = Query(None, description="Optional phone number filter")):
    phone = normalize_phone(phoneNumber) if phoneNumber else None
    db_store.clear_whatsapp_chats(phone=phone)
    return {"success": True, "message": "WhatsApp chat history cleared successfully."}


@whatsapp_router.post("/transaction", summary="Add Custom Expense or Revenue via WhatsApp")
async def add_custom_transaction(req: CustomTransactionRequest):
    phone = normalize_phone(req.phoneNumber)
    tx_type = "revenue" if req.type.lower() in ["revenue", "income"] else "expense"
    res = exec_add_transaction(
        amount=req.amount,
        title=req.title,
        tx_type=tx_type,
        category=req.category,
        profile_type=req.profileType,
        payment_mode=req.paymentMode or "upi"
    )

    if not res.get("success"):
        raise HTTPException(status_code=400, detail=res.get("formatted"))

    # Save to persistent chat logs
    inbound_msg = {
        "id": f"in-{secrets.token_hex(4)}",
        "phoneNumber": phone,
        "direction": "inbound",
        "message": f"Add {tx_type} {req.amount} for {req.title}",
        "timestamp": datetime.datetime.now().isoformat()
    }
    db_store.save_whatsapp_message(inbound_msg)

    outbound_msg = {
        "id": f"msg-{secrets.token_hex(4)}",
        "phoneNumber": phone,
        "direction": "outbound",
        "message": res["formatted"],
        "timestamp": datetime.datetime.now().isoformat()
    }
    db_store.save_whatsapp_message(outbound_msg)

    return {
        "success": True,
        "data": {
            "transaction": res.get("transaction"),
            "updated_balance": res.get("updated_balance"),
            "reply": res["formatted"]
        }
    }


@whatsapp_router.get("/sessions", summary="Get WhatsApp Active Sessions")
async def get_whatsapp_sessions():
    users = db_store.get_all_whatsapp_users()
    return {
        "success": True,
        "users": users,
        "sessions": _sessions
    }


@whatsapp_router.get("/handoff/verify", summary="Verify Expiring Handoff Token")
async def verify_token(token: str):
    res = verify_handoff_token(token)
    if not res.get("valid"):
        raise HTTPException(status_code=400, detail=res.get("message"))
    return {"success": True, "data": res}


@whatsapp_router.get("/handoff/open", response_class=HTMLResponse, summary="Handoff Web Landing Page")
async def open_handoff(token: str):
    res = verify_handoff_token(token)
    if not res.get("valid"):
        return HTMLResponse(
            content=f"""
            <!DOCTYPE html>
            <html>
            <head><title>Handoff Error</title>
            <style>body {{ font-family: sans-serif; background: #0b0f19; color: #fff; display: flex; align-items: center; justify-content: center; height: 100vh; }}
            .c {{ background: #161f30; padding: 32px; border-radius: 12px; text-align: center; }}</style>
            </head>
            <body><div class="c"><h2>⚠️ Invalid Link</h2><p>{res.get('message')}</p><a href="https://wa.me/919226860060?text=Hi%20ENX%20Money%20AI%20Assistant" style="color:#60a5fa;">Back to Official WhatsApp</a></div></body>
            </html>
            """,
            status_code=400
        )

    return HTMLResponse(
        content=f"""
        <!DOCTYPE html>
        <html>
        <head><title>ENX Money Handoff</title>
        <style>body {{ font-family: sans-serif; background: #070a13; color: #fff; display: flex; align-items: center; justify-content: center; height: 100vh; margin:0; }}
        .c {{ background: #111827; border: 1px solid #1f2937; padding: 36px; border-radius: 16px; text-align: center; max-width: 440px; }}
        .btn {{ display: block; margin-top: 20px; background: #10b981; color: #fff; padding: 12px; border-radius: 8px; text-decoration: none; font-weight: bold; }}</style>
        </head>
        <body><div class="c">
        <h2>🚀 App Handoff Authenticated!</h2>
        <p>Authenticated as <strong>{res['user']['name']}</strong> ({res['user']['email']})</p>
        <p style="color:#9ca3af;">Target: <strong>{res['target_screen'].upper()}</strong></p>
        <a class="btn" href="https://wa.me/919226860060?text=Hi%20ENX%20Money%20AI%20Assistant">Return to Official WhatsApp</a>
        </div></body>
        </html>
        """
    )
