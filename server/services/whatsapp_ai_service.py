"""
ENX Money WhatsApp Chatbot & AI Financial Agent (Gemini & Multi-Engine Integration)
Provides natural language processing, tool calling, financial querying, live ledger mutations,
account balance aggregation, OTP pairing, and secure app handoffs.
"""

import os
import re
import json
import secrets
import datetime
from typing import Dict, Any, Optional, List
import httpx
from services.json_store import db_store

# In-memory simulator message audit and sessions
_sessions: Dict[str, Dict[str, Any]] = {}
_whatsapp_users: Dict[str, Dict[str, Any]] = {
    "919876543210": {
        "phone_number": "919876543210",
        "user_email": "admin@enx.com",
        "user_name": "Anjali Enterprise Admin",
        "verification_status": "verified",
        "language": "en",
        "daily_summary": True,
        "created_at": datetime.datetime.now().isoformat()
    }
}
_message_logs: List[Dict[str, Any]] = []
_handoff_tokens: Dict[str, Dict[str, Any]] = {}


def normalize_phone(raw_phone: str) -> str:
    if not raw_phone:
        return ""
    cleaned = re.sub(r"[^\d+]", "", str(raw_phone))
    if cleaned.startswith("+"):
        cleaned = cleaned[1:]
    if len(cleaned) == 10:
        cleaned = "91" + cleaned
    return cleaned


def format_currency(amount: float) -> str:
    try:
        val = float(amount)
        return f"₹{val:,.2f}"
    except (ValueError, TypeError):
        return "₹0.00"


def _safe_float(d: Dict[str, Any], *keys: str, default: float = 0.0) -> float:
    """Safely extracts a float value supporting both camelCase and snake_case keys."""
    for k in keys:
        if k in d and d[k] is not None:
            try:
                return float(d[k])
            except (ValueError, TypeError):
                continue
    return default


def _safe_str(d: Dict[str, Any], *keys: str, default: str = "") -> str:
    """Safely extracts a string value supporting both camelCase and snake_case keys."""
    for k in keys:
        if k in d and d[k] is not None:
            return str(d[k]).strip()
    return default


def _safe_bool(d: Dict[str, Any], *keys: str, default: bool = True) -> bool:
    """Safely extracts a boolean value supporting both camelCase and snake_case keys."""
    for k in keys:
        if k in d and d[k] is not None:
            return bool(d[k])
    return default


def get_whatsapp_user(phone: str) -> Optional[Dict[str, Any]]:
    p = normalize_phone(phone)
    if not p:
        p = "919876543210"

    # 1. Check persistent database store
    db_user = db_store.get_whatsapp_user_by_phone(p)
    if db_user:
        return db_user

    # 2. In-memory fallback/cache
    if p in _whatsapp_users:
        return _whatsapp_users[p]

    # 3. Match against registered Enterprises in db_store
    enterprises = db_store.get_all_enterprises()
    for ent in enterprises:
        ent_phone = normalize_phone(_safe_str(ent, "phone"))
        if ent_phone and ent_phone == p:
            user = {
                "phoneNumber": p,
                "phone_number": p,
                "user_email": _safe_str(ent, "email", default="admin@enx.com"),
                "email": _safe_str(ent, "email", default="admin@enx.com"),
                "user_name": _safe_str(ent, "companyName", "company_name", default="Enterprise Admin"),
                "userName": _safe_str(ent, "companyName", "company_name", default="Enterprise Admin"),
                "companyName": _safe_str(ent, "companyName", "company_name", default="Enterprise Admin"),
                "verification_status": "verified",
                "language": "en",
                "daily_summary": True,
                "createdAt": datetime.datetime.now().isoformat()
            }
            saved = db_store.save_whatsapp_user(user)
            _whatsapp_users[p] = saved
            return saved

    # 4. Auto-provision verified user for simulator/admin phone
    if p in ["919876543210", ""]:
        demo_u = {
            "phoneNumber": "919876543210",
            "phone_number": "919876543210",
            "user_email": "admin@enx.com",
            "email": "admin@enx.com",
            "user_name": "Anjali Enterprise Admin",
            "userName": "Anjali Enterprise Admin",
            "companyName": "ENX Global Technologies Pvt Ltd",
            "verification_status": "verified",
            "language": "en",
            "daily_summary": True,
            "createdAt": datetime.datetime.now().isoformat()
        }
        saved = db_store.save_whatsapp_user(demo_u)
        _whatsapp_users["919876543210"] = saved
        return saved

    return None


def start_verification(phone: str, identifier: str) -> Dict[str, Any]:
    p = normalize_phone(phone)
    ident = identifier.strip().lower()

    # Check if identifier matches an enterprise or customer in db_store
    resolved_name = "ENX Business User"
    company_name = "ENX Enterprise"
    enterprises = db_store.get_all_enterprises()
    for ent in enterprises:
        if ident == _safe_str(ent, "email").lower():
            resolved_name = _safe_str(ent, "companyName", "company_name", default="Enterprise Admin")
            company_name = resolved_name
            break

    otp_code = str(secrets.randbelow(900000) + 100000)
    expires_at = (datetime.datetime.now() + datetime.timedelta(minutes=10)).isoformat()

    record = {
        "phoneNumber": p,
        "phone_number": p,
        "user_email": ident if "@" in ident else f"{ident}@enx.com",
        "email": ident if "@" in ident else f"{ident}@enx.com",
        "user_name": resolved_name,
        "userName": resolved_name,
        "companyName": company_name,
        "verification_status": "pending",
        "otp_code": otp_code,
        "otp_expires_at": expires_at,
    }
    _whatsapp_users[p] = record

    _sessions[p] = {
        "state": "AWAITING_OTP",
        "context_data": {"temp_identifier": ident},
        "last_intent": "VERIFY_ACCOUNT"
    }

    return {
        "success": True,
        "otp_code": otp_code,
        "message": f"Verification code generated for {ident}. Enter 6-digit OTP: {otp_code} to complete pairing."
    }


def verify_otp(phone: str, otp: str) -> Dict[str, Any]:
    p = normalize_phone(phone)
    user = _whatsapp_users.get(p) or db_store.get_whatsapp_user_by_phone(p)

    if not user:
        return {"success": False, "message": "No verification pending for this number."}

    clean_otp = str(otp).strip()
    if clean_otp == user.get("otp_code") or clean_otp == "123456":
        user["verification_status"] = "verified"
        user.pop("otp_code", None)
        user.pop("otp_expires_at", None)
        saved = db_store.save_whatsapp_user(user)
        _whatsapp_users[p] = saved
        _sessions[p] = {"state": "IDLE", "context_data": {}}
        return {
            "success": True,
            "user": saved,
            "message": (
                f"✅ *Account Verified Successfully!*\n\n"
                f"Welcome *{user.get('user_name') or user.get('userName', 'Business Owner')}* to ENX Money WhatsApp Assistant! 🚀\n\n"
                f"Your account and real WhatsApp number (+{p}) are now permanently linked.\n\n"
                f"💡 _Reply 'Quick actions' or 'Check balance all' to begin!_"
            )
        }
    return {"success": False, "message": "Incorrect OTP code. Please try again or use demo code 123456."}


def create_handoff_token(phone: str, target_screen: str = "dashboard", reason: str = "WhatsApp Request") -> Dict[str, Any]:
    token = f"enx_{secrets.token_hex(24)}"
    expires_at = datetime.datetime.now() + datetime.timedelta(minutes=10)

    _handoff_tokens[token] = {
        "token": token,
        "phone_number": normalize_phone(phone),
        "target_screen": target_screen,
        "reason": reason,
        "is_used": False,
        "expires_at": expires_at.isoformat()
    }

    return {
        "token": token,
        "target_screen": target_screen,
        "deep_link": f"enxmoney://handoff?token={token}&screen={target_screen}",
        "web_link": f"/api/whatsapp/handoff/open?token={token}",
        "expires_at": expires_at.isoformat()
    }


def verify_handoff_token(token: str) -> Dict[str, Any]:
    record = _handoff_tokens.get(token)
    if not record:
        return {"valid": False, "message": "Invalid handoff link."}

    if record.get("is_used"):
        return {"valid": False, "message": "This secure link has already been used."}

    exp = datetime.datetime.fromisoformat(record["expires_at"])
    if datetime.datetime.now() > exp:
        return {"valid": False, "message": "This handoff link has expired (10-minute limit)."}

    record["is_used"] = True
    return {
        "valid": True,
        "target_screen": record.get("target_screen", "dashboard"),
        "user": {"name": "Anjali Enterprise Admin", "email": "admin@enx.com"}
    }


# ============================================================================
# Financial Data Tools (Executing against live json_store)
# ============================================================================

def exec_get_financial_kpis(period: str = "this_month") -> Dict[str, Any]:
    txs = db_store.get_all_transactions()
    custs = db_store.get_all_customers()
    supps = db_store.get_all_suppliers()
    enterprises = db_store.get_all_enterprises()
    company_name = _safe_str(enterprises[0], "companyName", "company_name", default="ENX Money Enterprise") if enterprises else "ENX Money Enterprise"

    total_rev = sum(_safe_float(t, "amount") for t in txs if _safe_str(t, "type") == "revenue")
    total_exp = sum(_safe_float(t, "amount") for t in txs if _safe_str(t, "type") == "expense")
    net_profit = total_rev - total_exp

    pending_recv = sum(_safe_float(c, "outstandingBalance", "outstanding_balance") for c in custs)
    pending_pay = sum(_safe_float(s, "outstandingPayable", "outstanding_payable") for s in supps)

    formatted = (
        f"📊 *{company_name} — Financial Summary ({period.replace('_', ' ').upper()})*\n\n"
        f"🟢 *Total Revenue:* {format_currency(total_rev)}\n"
        f"🔴 *Total Expenses:* {format_currency(total_exp)}\n"
        f"💰 *Net Operating Profit:* *{format_currency(net_profit)}*\n"
        f"📥 *Pending Receivables (Due to you):* {format_currency(pending_recv)}\n"
        f"📤 *Pending Payables (You owe):* {format_currency(pending_pay)}\n\n"
        f"💡 _Reply 'Check balance all' for complete account breakdown, or 'Add expense' to log spending._"
    )

    return {
        "company_name": company_name,
        "total_revenue": total_rev,
        "total_expense": total_exp,
        "net_profit": net_profit,
        "pending_receivables": pending_recv,
        "pending_payables": pending_pay,
        "formatted": formatted
    }


def exec_check_balance_all() -> Dict[str, Any]:
    """Provides a single comprehensive balance and cash-flow overview across all accounts."""
    txs = db_store.get_all_transactions()
    custs = db_store.get_all_customers()
    supps = db_store.get_all_suppliers()
    enterprises = db_store.get_all_enterprises()

    ent = enterprises[0] if enterprises else {}
    company_name = _safe_str(ent, "companyName", "company_name", default="ENX Global Technologies Pvt Ltd")
    gstin = _safe_str(ent, "gstin", default="27AAACE1234F1Z9")

    # Business vs Personal breakdown
    biz_rev = sum(_safe_float(t, "amount") for t in txs if _safe_str(t, "type") == "revenue" and _safe_str(t, "profileType", "profile_type") == "business")
    biz_exp = sum(_safe_float(t, "amount") for t in txs if _safe_str(t, "type") == "expense" and _safe_str(t, "profileType", "profile_type") == "business")
    biz_net = biz_rev - biz_exp

    pers_rev = sum(_safe_float(t, "amount") for t in txs if _safe_str(t, "type") == "revenue" and _safe_str(t, "profileType", "profile_type") == "personal")
    pers_exp = sum(_safe_float(t, "amount") for t in txs if _safe_str(t, "type") == "expense" and _safe_str(t, "profileType", "profile_type") == "personal")
    pers_net = pers_rev - pers_exp

    total_rev = sum(_safe_float(t, "amount") for t in txs if _safe_str(t, "type") == "revenue")
    total_exp = sum(_safe_float(t, "amount") for t in txs if _safe_str(t, "type") == "expense")
    total_cash_balance = total_rev - total_exp

    # Receivables & Payables
    due_custs = [c for c in custs if _safe_float(c, "outstandingBalance", "outstanding_balance") > 0]
    total_receivables = sum(_safe_float(c, "outstandingBalance", "outstanding_balance") for c in due_custs)

    due_supps = [s for s in supps if _safe_float(s, "outstandingPayable", "outstanding_payable") > 0]
    total_payables = sum(_safe_float(s, "outstandingPayable", "outstanding_payable") for s in due_supps)

    # Net Working Capital
    net_working_capital = total_cash_balance + total_receivables - total_payables

    top_cust = f"{due_custs[0].get('name')} ({format_currency(_safe_float(due_custs[0], 'outstandingBalance', 'outstanding_balance'))})" if due_custs else "None"
    top_supp = f"{due_supps[0].get('name')} ({format_currency(_safe_float(due_supps[0], 'outstandingPayable', 'outstanding_payable'))})" if due_supps else "None"

    formatted = (
        f"🏦 *ENX MONEY ALL ACCOUNTS & BALANCE OVERVIEW*\n"
        f"🏢 *Entity:* {company_name} | GST: `{gstin}`\n"
        f"────────────────────────\n"
        f"💰 *NET AVAILABLE CASH:* *{format_currency(total_cash_balance)}*\n"
        f"🟢 *Total Inflow / Revenue:* {format_currency(total_rev)}\n"
        f"🔴 *Total Outflow / Expense:* {format_currency(total_exp)}\n"
        f"────────────────────────\n"
        f"💼 *Business Account:* *{format_currency(biz_net)}* net\n"
        f"   • Rev: {format_currency(biz_rev)} | Exp: {format_currency(biz_exp)}\n"
        f"👤 *Personal Account:* *{format_currency(pers_net)}* net\n"
        f"   • Income: {format_currency(pers_rev)} | Exp: {format_currency(pers_exp)}\n"
        f"────────────────────────\n"
        f"📥 *Receivables (Due to you):* *{format_currency(total_receivables)}* ({len(due_custs)} clients)\n"
        f"   • Top Debtor: {top_cust}\n"
        f"📤 *Payables (You owe):* *{format_currency(total_payables)}* ({len(due_supps)} vendors)\n"
        f"   • Top Payable: {top_supp}\n"
        f"────────────────────────\n"
        f"📊 *Net Working Capital:* *{format_currency(net_working_capital)}*\n"
        f"────────────────────────\n"
        f"⚡ _Reply 'Add expense 500 for lunch' or 'Quick actions' for more._"
    )

    return {
        "company_name": company_name,
        "total_revenue": total_rev,
        "total_expense": total_exp,
        "net_cash_balance": total_cash_balance,
        "business_net": biz_net,
        "personal_net": pers_net,
        "total_receivables": total_receivables,
        "total_payables": total_payables,
        "net_working_capital": net_working_capital,
        "formatted": formatted
    }


def exec_get_outstanding_receivables(customer_name: Optional[str] = None) -> Dict[str, Any]:
    custs = db_store.get_all_customers()
    due_custs = [c for c in custs if _safe_float(c, "outstandingBalance", "outstanding_balance") > 0]

    if customer_name:
        due_custs = [
            c for c in due_custs
            if customer_name.lower() in _safe_str(c, "name").lower()
            or customer_name.lower() in _safe_str(c, "companyName", "company_name").lower()
        ]

    if not due_custs:
        return {
            "count": 0,
            "formatted": "✅ *All clear!* There are currently no pending receivables from customers. 🎉"
        }

    total_due = sum(_safe_float(c, "outstandingBalance", "outstanding_balance") for c in due_custs)
    text = f"📥 *Pending Customer Receivables (Total: {format_currency(total_due)})*\n\n"

    for i, c in enumerate(due_custs[:5], start=1):
        comp = f" ({c.get('companyName') or c.get('company_name')})" if (c.get('companyName') or c.get('company_name')) else ""
        text += f"{i}. *{c.get('name')}*{comp}\n"
        text += f"   • Due Balance: *{format_currency(_safe_float(c, 'outstandingBalance', 'outstanding_balance'))}*\n"
        text += f"   • Total Invoiced: {format_currency(_safe_float(c, 'totalInvoiced', 'total_invoiced'))}\n"
        if c.get("phone"):
            text += f"   • Phone: {c.get('phone')}\n"

    text += "\n💡 _Tip: Reply 'Send reminder to [Customer]' to queue a WhatsApp alert._"
    return {"count": len(due_custs), "total_due": total_due, "formatted": text}


def exec_get_outstanding_payables(supplier_name: Optional[str] = None) -> Dict[str, Any]:
    supps = db_store.get_all_suppliers()
    due_supps = [s for s in supps if _safe_float(s, "outstandingPayable", "outstanding_payable") > 0]

    if supplier_name:
        due_supps = [s for s in due_supps if supplier_name.lower() in _safe_str(s, "name").lower()]

    if not due_supps:
        return {
            "count": 0,
            "formatted": "✅ *No vendor bills pending!* All supplier accounts are settled. 🌟"
        }

    total_due = sum(_safe_float(s, "outstandingPayable", "outstanding_payable") for s in due_supps)
    text = f"📤 *Outstanding Vendor Payables (Total: {format_currency(total_due)})*\n\n"

    for i, s in enumerate(due_supps[:5], start=1):
        text += f"{i}. *{s.get('name')}* ({s.get('category', 'Vendor')})\n"
        text += f"   • Payable Due: *{format_currency(_safe_float(s, 'outstandingPayable', 'outstanding_payable'))}*\n"
        text += f"   • Total Billed: {format_currency(_safe_float(s, 'totalBilled', 'total_billed'))}\n"

    return {"count": len(due_supps), "total_due": total_due, "formatted": text}


def exec_get_recent_transactions(limit: int = 5, tx_type: Optional[str] = None) -> Dict[str, Any]:
    txs = db_store.get_all_transactions()
    if tx_type:
        txs = [t for t in txs if _safe_str(t, "type").lower() == tx_type.lower()]

    txs = sorted(txs, key=lambda x: _safe_str(x, "date"), reverse=True)[:limit]

    if not txs:
        return {"count": 0, "formatted": "ℹ️ No recent transactions found."}

    text = f"🧾 *Recent Transactions ({len(txs)})*\n\n"
    for t in txs:
        t_type = _safe_str(t, "type").lower()
        icon = "🟢" if t_type == "revenue" else ("🔴" if t_type == "expense" else "🟡")
        status = "✅ Cleared" if _safe_bool(t, "isCleared", "is_cleared", default=True) else "⏳ Pending"
        amt = format_currency(_safe_float(t, "amount"))
        text += f"{icon} *{_safe_str(t, 'title')}*\n"
        text += f"   • Amount: *{amt}* ({t_type.upper()})\n"
        text += f"   • Category: {_safe_str(t, 'category')} | {status}\n\n"

    return {"count": len(txs), "formatted": text.strip()}


def exec_check_transaction_status(invoice_number: Optional[str] = None, search: Optional[str] = None) -> Dict[str, Any]:
    txs = db_store.get_all_transactions()
    target = None

    if invoice_number:
        clean_inv = invoice_number.lower().strip()
        target = next((t for t in txs if clean_inv in _safe_str(t, "invoiceNumber", "invoice_number").lower()), None)
    elif search:
        clean_srch = search.lower().strip()
        target = next((
            t for t in txs
            if clean_srch in _safe_str(t, "title").lower()
            or clean_srch in _safe_str(t, "invoiceNumber", "invoice_number").lower()
        ), None)

    if not target:
        return {"found": False, "formatted": f"⚠️ No transaction or invoice found matching '{invoice_number or search}'."}

    t_type = _safe_str(target, "type").lower()
    icon = "🟢" if t_type == "revenue" else "🔴"
    status_badge = "✅ SETTLED & CLEARED" if _safe_bool(target, "isCleared", "is_cleared", default=True) else "⏳ PENDING CLEARANCE"

    text = (
        f"🔍 *Transaction Status Lookup* {icon}\n\n"
        f"*Title:* {_safe_str(target, 'title')}\n"
        f"*Invoice #:* {_safe_str(target, 'invoiceNumber', 'invoice_number', default='N/A')}\n"
        f"*Type:* {t_type.upper()}\n"
        f"*Amount:* *{format_currency(_safe_float(target, 'amount'))}*\n"
        f"*Category:* {_safe_str(target, 'category')}\n"
        f"*Status:* {status_badge}\n"
        f"*Payment Mode:* {_safe_str(target, 'paymentMode', 'payment_mode', default='bankTransfer').upper()}\n"
    )
    return {"found": True, "transaction": target, "formatted": text}


def exec_get_expense_breakdown() -> Dict[str, Any]:
    txs = [t for t in db_store.get_all_transactions() if _safe_str(t, "type").lower() == "expense"]
    if not txs:
        return {"formatted": "ℹ️ No expense records found."}

    cat_map: Dict[str, float] = {}
    for t in txs:
        c = _safe_str(t, "category", default="General")
        cat_map[c] = cat_map.get(c, 0.0) + _safe_float(t, "amount")

    sorted_cats = sorted(cat_map.items(), key=lambda x: x[1], reverse=True)[:5]
    total_exp = sum(cat_map.values())

    text = f"📊 *Top Expense Categories (Total: {format_currency(total_exp)})*\n\n"
    for i, (cat, amt) in enumerate(sorted_cats, start=1):
        pct = (amt / total_exp * 100) if total_exp > 0 else 0
        text += f"{i}. *{cat}:* {format_currency(amt)} ({pct:.1f}%)\n"

    return {"total": total_exp, "formatted": text}


def _auto_detect_category(title: str, is_income: bool = False) -> str:
    t = title.lower()
    if is_income:
        if any(w in t for w in ["salary", "payroll"]): return "Salary"
        if any(w in t for w in ["freelance", "contract"]): return "Freelancing"
        if any(w in t for w in ["invest", "dividend", "interest", "stock"]): return "Investments"
        if any(w in t for w in ["rent", "lease"]): return "Rental Income"
        if any(w in t for w in ["software", "license", "saas"]): return "Software Sales"
        if any(w in t for w in ["consulting", "service", "client", "project"]): return "Consulting"
        return "Software Sales"

    # Expense categories
    if any(w in t for w in ["food", "lunch", "dinner", "breakfast", "tea", "coffee", "meal", "restaurant", "swiggy", "zomato"]): return "Dining Out"
    if any(w in t for w in ["grocer", "supermarket", "milk", "vegetable", "fruit", "kirana", "ration"]): return "Groceries"
    if any(w in t for w in ["office rent", "shop rent", "rent"]): return "Office Rent"
    if any(w in t for w in ["aws", "cloud", "server", "hosting", "domain", "software", "infrastructure", "saas"]): return "Infrastructure"
    if any(w in t for w in ["hardware", "laptop", "monitor", "cable", "mouse", "keyboard", "dell"]): return "Hardware"
    if any(w in t for w in ["salary", "wages", "stipend", "bonus"]): return "Salaries"
    if any(w in t for w in ["marketing", "ad", "ads", "campaign", "meta", "google", "promotion"]): return "Marketing"
    if any(w in t for w in ["travel", "fuel", "petrol", "diesel", "flight", "taxi", "cab", "uber", "ola"]): return "Travel"
    if any(w in t for w in ["electricity", "power", "utility", "wifi", "internet", "phone", "recharge", "water"]): return "Utilities"
    if any(w in t for w in ["tax", "gst", "tds", "income tax"]): return "Taxes"
    return "Miscellaneous"


def _parse_custom_transaction_attrs(raw_text: str, tx_type: str = "expense") -> Dict[str, Any]:
    """Extracts custom user values: amount, title, category, profile, and payment mode from natural text."""
    text = raw_text.strip()

    # 1. Category extraction: "category <name>", "cat: <name>", "cat <name>"
    cat = None
    cat_match = re.search(r"\b(?:category|cat)[:\s]+([a-zA-Z0-9_\s&]+?)(?=\s+(?:profile|account|mode|payment|via|notes)|$)", text, re.IGNORECASE)
    if cat_match:
        cat = cat_match.group(1).strip()
        text = text[:cat_match.start()] + " " + text[cat_match.end():]

    # 2. Profile extraction: "profile <business|personal>", "account <business|personal>"
    profile = None
    prof_match = re.search(r"\b(?:profile|account)[:\s]+(business|personal)\b", text, re.IGNORECASE)
    if prof_match:
        profile = prof_match.group(1).lower()
        text = text[:prof_match.start()] + " " + text[prof_match.end():]
    elif re.search(r"\bpersonal\b", text, re.IGNORECASE):
        profile = "personal"
        text = re.sub(r"\bpersonal\b", " ", text, flags=re.IGNORECASE)
    elif re.search(r"\bbusiness\b", text, re.IGNORECASE):
        profile = "business"
        text = re.sub(r"\bbusiness\b", " ", text, flags=re.IGNORECASE)

    # 3. Mode extraction: "mode <...>", "payment <...>", "via <...>"
    mode = "upi"
    mode_match = re.search(r"\b(?:mode|payment|via)[:\s]+(upi|credit\s*card|debit\s*card|card|cash|bank\s*transfer|bank|netbanking|cheque)\b", text, re.IGNORECASE)
    if mode_match:
        raw_m = mode_match.group(1).lower().replace(" ", "")
        if "credit" in raw_m or raw_m == "card":
            mode = "creditCard"
        elif "debit" in raw_m:
            mode = "debitCard"
        elif "bank" in raw_m or "netbanking" in raw_m:
            mode = "bankTransfer"
        elif "cash" in raw_m:
            mode = "cash"
        elif "cheque" in raw_m:
            mode = "cheque"
        else:
            mode = "upi"
        text = text[:mode_match.start()] + " " + text[mode_match.end():]
    elif re.search(r"\bvia\s+cash\b", text, re.IGNORECASE):
        mode = "cash"
        text = re.sub(r"\bvia\s+cash\b", " ", text, flags=re.IGNORECASE)
    elif re.search(r"\bvia\s+(?:upi|gpay|phonepe|paytm)\b", text, re.IGNORECASE):
        mode = "upi"
        text = re.sub(r"\bvia\s+(?:upi|gpay|phonepe|paytm)\b", " ", text, flags=re.IGNORECASE)
    elif re.search(r"\bvia\s+(?:card|credit\s*card)\b", text, re.IGNORECASE):
        mode = "creditCard"
        text = re.sub(r"\bvia\s+(?:card|credit\s*card)\b", " ", text, flags=re.IGNORECASE)

    # 4. Extract numeric amount
    amt = 0.0
    amt_match = re.search(r"(?:₹|rs\.?|inr)?\s*(\d+(?:\.\d+)?)", text, re.IGNORECASE)
    if amt_match:
        amt = float(amt_match.group(1))
        text = text[:amt_match.start()] + " " + text[amt_match.end():]

    # 5. Clean up remaining text to form item title
    clean = re.sub(r"(?:add\s+expense|record\s+expense|log\s+expense|spent|paid|add\s+income|add\s+revenue|record\s+revenue|log\s+income|received)", " ", text, flags=re.IGNORECASE)
    clean = re.sub(r"\b(?:for|on|towards|from|by|in|amount|rs|inr)\b", " ", clean, flags=re.IGNORECASE)
    clean = re.sub(r"[^\w\s-]", " ", clean)
    clean = re.sub(r"\s+", " ", clean).strip()

    title = clean if clean else ("Custom Expense" if tx_type == "expense" else "Custom Income")

    return {
        "amount": amt,
        "title": title,
        "category": cat,
        "profile_type": profile,
        "payment_mode": mode
    }


def exec_add_transaction(
    amount: float,
    title: str,
    tx_type: str = "expense",
    category: Optional[str] = None,
    profile_type: Optional[str] = None,
    payment_mode: str = "upi"
) -> Dict[str, Any]:
    """Records a new expense or revenue transaction directly into the persistent ledger."""
    try:
        amt = float(amount)
        if amt <= 0:
            return {"success": False, "formatted": "⚠️ Amount must be greater than zero."}
    except (ValueError, TypeError):
        return {"success": False, "formatted": "⚠️ Invalid amount format. Example: `Add expense 500 for Lunch`."}

    clean_title = (title or ("Quick Expense" if tx_type == "expense" else "Quick Revenue")).strip()
    is_inc = tx_type == "revenue"
    cat = category if category else _auto_detect_category(clean_title, is_income=is_inc)

    # Auto-assign profile
    if profile_type is None:
        if any(w in clean_title.lower() for w in ["grocery", "lunch", "dinner", "coffee", "personal", "home", "family", "milk"]):
            profile_type = "personal"
        else:
            profile_type = "business"

    enterprises = db_store.get_all_enterprises()
    ent_id = enterprises[0].get("id") if enterprises and profile_type == "business" else None

    tx_id = f"tx-wa-{secrets.token_hex(4)}"
    new_tx = {
        "id": tx_id,
        "title": clean_title,
        "amount": amt,
        "type": tx_type,
        "profileType": profile_type,
        "category": cat,
        "date": datetime.datetime.now().isoformat(),
        "paymentMode": payment_mode,
        "notes": "Recorded via ENX WhatsApp Assistant",
        "gstRate": 0.0,
        "invoiceNumber": f"WA-{secrets.token_hex(3).upper()}",
        "isCleared": True,
        "enterpriseId": ent_id,
        "customerId": None,
        "supplierId": None
    }

    db_store.add_transaction(new_tx)

    # Compute updated balance
    txs = db_store.get_all_transactions()
    total_rev = sum(_safe_float(t, "amount") for t in txs if _safe_str(t, "type") == "revenue")
    total_exp = sum(_safe_float(t, "amount") for t in txs if _safe_str(t, "type") == "expense")
    net_bal = total_rev - total_exp

    icon = "🔴" if tx_type == "expense" else "🟢"
    action_label = "Expense Logged" if tx_type == "expense" else "Income Logged"

    formatted = (
        f"✅ *{action_label} Successfully!* {icon}\n\n"
        f"• *Title:* {clean_title}\n"
        f"• *Amount:* *{format_currency(amt)}*\n"
        f"• *Category:* {cat}\n"
        f"• *Account:* {profile_type.capitalize()}\n"
        f"• *Payment Mode:* {payment_mode.upper()}\n"
        f"• *Ledger Ref:* `{tx_id}`\n\n"
        f"💰 *Updated Net Cash Balance:* *{format_currency(net_bal)}*\n\n"
        f"⚡ _This transaction is live in your ENX ledger and Flutter dashboard!_"
    )

    return {
        "success": True,
        "transaction": new_tx,
        "updated_balance": net_bal,
        "formatted": formatted
    }


def exec_get_all_quick_actions() -> Dict[str, Any]:
    """Returns a single, comprehensive WhatsApp message detailing all quick actions."""
    text = (
        f"⚡ *ENX MONEY — ALL QUICK ACTIONS (ONE MESSAGE)* ⚡\n\n"
        f"Send or copy-paste any command below for instant action:\n\n"
        f"🌐 *1. ALL ACCOUNT BALANCES*\n"
        f"• `Check balance all` → Unified Business & Personal balance, cash flow & debts\n"
        f"• `Check balance` → Overall net profit and revenue KPIs\n\n"
        f"🔴 *2. ADD AN EXPENSE (LIVE LEDGER)*\n"
        f"• `Add expense 500 for Lunch`\n"
        f"• `Add expense 2500 Office Internet`\n"
        f"• `Spent 1200 on Fuel`\n"
        f"• `Paid 4500 Electricity Bill`\n\n"
        f"🟢 *3. ADD REVENUE / INCOME*\n"
        f"• `Add income 25000 Consulting`\n"
        f"• `Received 15000 from Client`\n\n"
        f"📥 *4. RECEIVABLES (WHO OWES YOU)*\n"
        f"• `Who owes me money?` / `Receivables`\n"
        f"• `Receivables for TechCorp`\n\n"
        f"📤 *5. PAYABLES (BILLS DUE TO VENDORS)*\n"
        f"• `What bills are due?` / `Payables`\n"
        f"• `Payable to Dell`\n\n"
        f"🧾 *6. TRANSACTIONS & AUDIT*\n"
        f"• `Show recent transactions`\n"
        f"• `Expense breakdown`\n"
        f"• `Status of INV-2026-089`\n\n"
        f"🔐 *7. APP ACCESS & PORTAL*\n"
        f"• `Open app link` → 10-minute secure single-sign-on token\n\n"
        f"💡 _You can also ask financial questions naturally in your own words!_"
    )
    return {"formatted": text}


# ============================================================================
# Gemini AI Configuration & Function Declarations
# ============================================================================

SYSTEM_PROMPT = """
You are the official ENX Money WhatsApp Smart Financial Assistant.
Provide fast, precise, actionable, and secure financial assistance to enterprise owners and users.

Formatting Guidelines:
- WhatsApp compatible styling: Use *bold* for key numbers, amounts, and headers.
- Format all money values with currency symbol (e.g. ₹1,45,000.00).
- Use clean emojis (💰, 📈, 📉, ⚠️, ✅, ⏳, 🧾, 🏢, 🔗) to make responses scannable.
- Keep responses concise, direct, and easy to read on mobile screens.
- When user asks for balance all, call checkBalanceAll.
- When user asks for quick actions or menu, call getAllQuickActions.
- When user asks to add/record/log an expense, call addExpense.
- When user asks to add/record income or revenue, call addIncome.
- When user asks for financial KPIs, receivables, payables, transactions, or invoice status, call the appropriate tool.
- For opening reports or secure portal links, call createSecureAppHandoff.
""".strip()

GEMINI_TOOLS = [
    {
        "function_declarations": [
            {
                "name": "checkBalanceAll",
                "description": "Retrieves comprehensive balance across all accounts, including cash, business net, personal net, receivables, payables, and working capital.",
                "parameters": {"type": "object", "properties": {}}
            },
            {
                "name": "getAllQuickActions",
                "description": "Returns a single message containing all quick actions and command shortcuts available in the chatbot.",
                "parameters": {"type": "object", "properties": {}}
            },
            {
                "name": "addExpense",
                "description": "Records a new expense transaction into the live ENX ledger.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "amount": {"type": "number", "description": "Expense monetary amount"},
                        "title": {"type": "string", "description": "Expense description or item name"},
                        "category": {"type": "string", "description": "Optional category, e.g. Dining Out, Groceries, Utilities, Travel"},
                        "profile_type": {"type": "string", "description": "business or personal"}
                    },
                    "required": ["amount", "title"]
                }
            },
            {
                "name": "addIncome",
                "description": "Records a new revenue or income transaction into the live ENX ledger.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "amount": {"type": "number", "description": "Revenue monetary amount"},
                        "title": {"type": "string", "description": "Revenue description or client name"},
                        "category": {"type": "string", "description": "Optional category, e.g. Software Sales, Consulting, Salary"}
                    },
                    "required": ["amount", "title"]
                }
            },
            {
                "name": "getFinancialKPIs",
                "description": "Retrieves core financial metrics including total revenue, expenses, net profit, pending receivables, and outstanding payables.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "period": {"type": "string", "description": "Time filter: 'today', 'this_month', 'last_month', 'year', or 'all'"}
                    }
                }
            },
            {
                "name": "getOutstandingReceivables",
                "description": "Finds customers who owe money, their total invoice amounts, and overdue balances.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "customer_name": {"type": "string", "description": "Optional customer name to filter by"}
                    }
                }
            },
            {
                "name": "getOutstandingPayables",
                "description": "Finds suppliers/vendors that need to be paid, total billed amounts, and pending payables.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "supplier_name": {"type": "string", "description": "Optional supplier or vendor name"}
                    }
                }
            },
            {
                "name": "getRecentTransactions",
                "description": "Fetches recent ledger transactions with filters.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "limit": {"type": "integer", "description": "Number of transactions (1-10)"},
                        "tx_type": {"type": "string", "description": "Optional filter: 'revenue' or 'expense'"}
                    }
                }
            },
            {
                "name": "checkTransactionStatus",
                "description": "Looks up a specific invoice or transaction by its invoice ID.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "invoice_number": {"type": "string", "description": "Invoice number, e.g. INV-2026-089"}
                    },
                    "required": ["invoice_number"]
                }
            },
            {
                "name": "createSecureAppHandoff",
                "description": "Generates a 10-minute expiring secure link for the user to open full reports or edit sensitive records.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "target_screen": {"type": "string", "description": "Target screen: 'dashboard', 'analytics', 'transactions'"}
                    }
                }
            }
        ]
    }
]


async def call_gemini_api(phone: str, user_message: str) -> Optional[Dict[str, Any]]:
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return None

    model = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
    endpoint = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"

    payload = {
        "contents": [
            {
                "role": "user",
                "parts": [
                    {"text": SYSTEM_PROMPT},
                    {"text": f"User question: {user_message}"}
                ]
            }
        ],
        "tools": GEMINI_TOOLS,
        "generationConfig": {
            "temperature": 0.2,
            "maxOutputTokens": 800
        }
    }

    try:
        async with httpx.AsyncClient(timeout=12.0) as client:
            resp = await client.post(endpoint, json=payload)
            if resp.status_code != 200:
                print(f"[WARN] Gemini API returned {resp.status_code}: {resp.text}")
                return None
            data = resp.json()
            candidates = data.get("candidates", [])
            if not candidates:
                return None
            parts = candidates[0].get("content", {}).get("parts", [])
            for part in parts:
                if "functionCall" in part:
                    fc = part["functionCall"]
                    fn_name = fc.get("name")
                    fn_args = fc.get("args", {})

                    if fn_name == "checkBalanceAll":
                        res = exec_check_balance_all()
                        return {"reply": res["formatted"], "state": "IDLE", "intent": "CHECK_BALANCE_ALL", "tool": fn_name}
                    elif fn_name == "getAllQuickActions":
                        res = exec_get_all_quick_actions()
                        return {"reply": res["formatted"], "state": "IDLE", "intent": "ALL_QUICK_ACTIONS", "tool": fn_name}
                    elif fn_name == "addExpense":
                        res = exec_add_transaction(
                            amount=fn_args.get("amount", 0),
                            title=fn_args.get("title", "Quick Expense"),
                            tx_type="expense",
                            category=fn_args.get("category"),
                            profile_type=fn_args.get("profile_type")
                        )
                        return {"reply": res["formatted"], "state": "IDLE", "intent": "ADD_EXPENSE", "tool": fn_name}
                    elif fn_name == "addIncome":
                        res = exec_add_transaction(
                            amount=fn_args.get("amount", 0),
                            title=fn_args.get("title", "Quick Revenue"),
                            tx_type="revenue",
                            category=fn_args.get("category")
                        )
                        return {"reply": res["formatted"], "state": "IDLE", "intent": "ADD_INCOME", "tool": fn_name}
                    elif fn_name == "getFinancialKPIs":
                        res = exec_get_financial_kpis(period=fn_args.get("period", "this_month"))
                        return {"reply": res["formatted"], "state": "IDLE", "intent": "GEMINI_KPIS", "tool": fn_name}
                    elif fn_name == "getOutstandingReceivables":
                        res = exec_get_outstanding_receivables(customer_name=fn_args.get("customer_name"))
                        return {"reply": res["formatted"], "state": "IDLE", "intent": "GEMINI_RECEIVABLES", "tool": fn_name}
                    elif fn_name == "getOutstandingPayables":
                        res = exec_get_outstanding_payables(supplier_name=fn_args.get("supplier_name"))
                        return {"reply": res["formatted"], "state": "IDLE", "intent": "GEMINI_PAYABLES", "tool": fn_name}
                    elif fn_name == "getRecentTransactions":
                        res = exec_get_recent_transactions(limit=int(fn_args.get("limit", 5)), tx_type=fn_args.get("tx_type"))
                        return {"reply": res["formatted"], "state": "IDLE", "intent": "GEMINI_TRANSACTIONS", "tool": fn_name}
                    elif fn_name == "checkTransactionStatus":
                        res = exec_check_transaction_status(invoice_number=fn_args.get("invoice_number", ""))
                        return {"reply": res["formatted"], "state": "IDLE", "intent": "GEMINI_INVOICE", "tool": fn_name}
                    elif fn_name == "createSecureAppHandoff":
                        target = fn_args.get("target_screen", "dashboard")
                        handoff = create_handoff_token(phone, target_screen=target)
                        reply = (
                            f"🔐 *Secure ENX Money App Access Link*\n\n"
                            f"Click below to access your account dashboard securely:\n"
                            f"👉 {handoff['web_link']}\n\n"
                            f"⚡ _This single-use cryptographic token is valid for 10 minutes._"
                        )
                        return {"reply": reply, "state": "IDLE", "intent": "GEMINI_APP_HANDOFF", "tool": fn_name}

                if "text" in part and part["text"].strip():
                    return {"reply": part["text"].strip(), "state": "IDLE", "intent": "GEMINI_TEXT"}
    except Exception as e:
        print(f"[WARN] Gemini API call exception: {e}")
        return None
    return None


async def send_whatsapp_message(recipient_phone: str, message_text: str) -> Dict[str, Any]:
    phone = normalize_phone(recipient_phone)
    provider = os.getenv("WHATSAPP_PROVIDER", "simulator")
    access_token = os.getenv("WHATSAPP_ACCESS_TOKEN") or os.getenv("WHATSAPP_META_TOKEN")
    phone_number_id = os.getenv("WHATSAPP_PHONE_NUMBER_ID")

    log_entry = {
        "id": f"msg-{secrets.token_hex(4)}",
        "phoneNumber": phone,
        "phone_number": phone,
        "direction": "outbound",
        "message": message_text,
        "provider": provider,
        "timestamp": datetime.datetime.now().isoformat()
    }
    _message_logs.append(log_entry)
    if len(_message_logs) > 100:
        _message_logs.pop(0)
    db_store.save_whatsapp_message(log_entry)

    # Live Meta WhatsApp Cloud API
    if provider == "meta" and access_token and phone_number_id:
        try:
            url = f"https://graph.facebook.com/v21.0/{phone_number_id}/messages"
            headers = {
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json"
            }
            payload = {
                "messaging_product": "whatsapp",
                "recipient_type": "individual",
                "to": phone,
                "type": "text",
                "text": {"body": message_text}
            }
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.post(url, headers=headers, json=payload)
                data = resp.json()
                return {"success": resp.status_code == 200, "provider": "meta", "data": data}
        except Exception as e:
            print(f"[ERROR] Meta WhatsApp API dispatch failed: {e}")
            return {"success": False, "provider": "meta", "error": str(e)}

    return {"success": True, "provider": "simulator", "logged": True}


# ============================================================================
# Conversational Message Processor
# ============================================================================

async def process_whatsapp_message(phone: str, message: str) -> Dict[str, Any]:
    p = normalize_phone(phone)
    text = (message or "").strip()
    session = _sessions.get(p, {"state": "IDLE", "context_data": {}})

    # 1. Log incoming message to memory and persistent data.json
    inbound_entry = {
        "id": f"in-{secrets.token_hex(4)}",
        "phoneNumber": p,
        "phone_number": p,
        "direction": "inbound",
        "message": text,
        "timestamp": datetime.datetime.now().isoformat()
    }
    _message_logs.append(inbound_entry)
    if len(_message_logs) > 100:
        _message_logs.pop(0)
    db_store.save_whatsapp_message(inbound_entry)

    def _finalize(res_obj: Dict[str, Any]) -> Dict[str, Any]:
        """Saves outgoing bot reply to memory and persistent data.json."""
        rep = res_obj.get("reply")
        if rep:
            out_entry = {
                "id": f"out-{secrets.token_hex(4)}",
                "phoneNumber": p,
                "phone_number": p,
                "direction": "outbound",
                "message": rep,
                "timestamp": datetime.datetime.now().isoformat()
            }
            _message_logs.append(out_entry)
            if len(_message_logs) > 100:
                _message_logs.pop(0)
            db_store.save_whatsapp_message(out_entry)
        return res_obj

    # User resolution: Check if verified or auto-associate for direct financial queries
    user = get_whatsapp_user(p)
    lower = text.lower()

    # If user is in an active OTP verification state
    if session.get("state") == "AWAITING_OTP":
        otp_match = re.search(r"\b\d{6}\b", text)
        if otp_match:
            res = verify_otp(p, otp_match.group(0))
            return _finalize({"reply": res["message"], "state": "IDLE", "intent": "OTP_VERIFY"})

    # In-chat Account Linking: e.g. "link account 919876543210 john@acme.com Acme Corp" or "link account john@acme.com"
    link_match = re.search(r"link\s+(?:real\s+)?account\s*(.*)", text, re.IGNORECASE)
    if link_match:
        link_args = link_match.group(1).strip()
        phone_in_arg = re.search(r"\b(?:\+?\d{10,13})\b", link_args)
        target_phone = normalize_phone(phone_in_arg.group(0)) if phone_in_arg else p

        email_in_arg = re.search(r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}", link_args)
        target_email = email_in_arg.group(0) if email_in_arg else (user.get("email") if user else "user@enx.com")

        rem = link_args
        if phone_in_arg:
            rem = rem.replace(phone_in_arg.group(0), "")
        if email_in_arg:
            rem = rem.replace(email_in_arg.group(0), "")
        user_name = rem.strip() if rem.strip() else (user.get("user_name") if user else "Business Owner")

        user_record = {
            "phoneNumber": target_phone,
            "phone_number": target_phone,
            "userName": user_name,
            "user_name": user_name,
            "email": target_email,
            "user_email": target_email,
            "companyName": user_name,
            "company_name": user_name,
            "verification_status": "verified",
            "profileType": "business",
            "language": "en",
            "daily_summary": True,
            "created_at": datetime.datetime.now().isoformat()
        }
        db_store.save_whatsapp_user(user_record)
        _whatsapp_users[target_phone] = user_record
        _sessions[target_phone] = {"state": "IDLE", "context_data": {}}

        reply = (
            f"🎉 *Real WhatsApp Account Successfully Linked!*\n\n"
            f"• *Name:* {user_name}\n"
            f"• *WhatsApp Phone:* +{target_phone}\n"
            f"• *Email:* {target_email}\n"
            f"• *Account Type:* Business\n\n"
            f"All your chats, live balances, and custom transactions are now permanently saved.\n\n"
            f"💡 _Reply 'Check balance all' or 'Quick actions' to begin!_"
        )
        return _finalize({"reply": reply, "state": "IDLE", "intent": "ACCOUNT_LINKED", "user": user_record})

    # If unverified and sending an email
    email_match = re.search(r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}", text)
    if not user or user.get("verification_status") != "verified":
        if email_match:
            res = start_verification(p, email_match.group(0))
            return _finalize({"reply": res["message"], "state": "AWAITING_OTP", "intent": "OTP_GENERATED", "otpCode": res["otp_code"]})

        # Auto-provision if message is asking for balance, actions, or expenses (User convenience)
        is_direct_action = any(w in lower for w in [
            "balance", "quick", "action", "expense", "revenue", "income", "spent", "paid",
            "receivable", "payable", "owe", "transaction", "help", "menu"
        ])
        if is_direct_action:
            enterprises = db_store.get_all_enterprises()
            ent_name = _safe_str(enterprises[0], "companyName", "company_name", default="Anjali Enterprise Admin") if enterprises else "Anjali Enterprise Admin"
            user = {
                "phoneNumber": p,
                "phone_number": p,
                "userName": ent_name,
                "user_name": ent_name,
                "email": "admin@enx.com",
                "user_email": "admin@enx.com",
                "verification_status": "verified",
                "language": "en",
                "daily_summary": True,
                "created_at": datetime.datetime.now().isoformat()
            }
            db_store.save_whatsapp_user(user)
            _whatsapp_users[p] = user
        else:
            welcome = (
                "👋 *Welcome to ENX Money WhatsApp Assistant!*\n\n"
                "To link your registered account, reply with your *email address* (e.g. `admin@enx.com`) or type:\n"
                "`Link account <phone> <email> <name>`\n\n"
                "⚡ Or reply *'Quick actions'* or *'Check balance all'* to explore instant financial actions! 🚀"
            )
            return _finalize({"reply": welcome, "state": "AWAITING_EMAIL", "intent": "ONBOARDING"})

    # Unlink command
    if lower in ["unlink", "logout"]:
        db_store.delete_whatsapp_user(p)
        _whatsapp_users.pop(p, None)
        _sessions.pop(p, None)
        return _finalize({"reply": "🔓 WhatsApp account unlinked. Send any message or 'Link account' to reconnect.", "state": "UNLINKED", "intent": "UNLINK"})

    # Interactive Help when bare 'add expense' or 'add income' is sent
    if lower in ["add expense", "add income", "log expense", "log income", "record expense", "record income", "add revenue", "new expense", "new income"]:
        action_name = "Expense" if "expense" in lower else "Income"
        prompt = (
            f"➕ *Add Custom {action_name}*\n\n"
            f"You can add any custom amount, title, category, profile, and payment mode:\n\n"
            f"📝 *Format:*\n"
            f"`Add {action_name.lower()} <amount> <description> [category <cat>] [mode <upi|card|cash|bank>] [profile <business|personal>]`\n\n"
            f"📌 *Examples:*\n"
            f"• `Add {action_name.lower()} 1500 Office Stationery category Utilities mode upi`\n"
            f"• `Add {action_name.lower()} 4999.50 Cloud Servers category Infrastructure mode card profile business`\n"
            f"• `Add {action_name.lower()} 750 Coffee and Snacks profile personal mode cash`\n\n"
            f"✨ Or use the interactive *Add Custom Value* button in the app/simulator!"
        )
        return _finalize({"reply": prompt, "state": "IDLE", "intent": "ADD_TRANSACTION_HELP"})

    # 1. All Quick Actions in One Message (Menu / Help)
    if any(lower == q or lower.startswith(q) for q in ["quick action", "quick actions", "all quick actions", "actions", "menu", "help", "commands", "start", "what can you do"]):
        res = exec_get_all_quick_actions()
        return _finalize({"reply": res["formatted"], "state": "IDLE", "intent": "ALL_QUICK_ACTIONS", "tool": "getAllQuickActions"})

    # 2. Check Balance All (Comprehensive multi-account cash flow summary)
    if any(w in lower for w in ["check balance all", "balance all", "all balance", "all accounts", "full balance", "total balance", "net balance", "overall balance"]):
        res = exec_check_balance_all()
        return _finalize({"reply": res["formatted"], "state": "IDLE", "intent": "CHECK_BALANCE_ALL", "tool": "checkBalanceAll"})

    # 3. Add Expense (Natural Language Extraction with Custom Attributes)
    add_exp_match = re.search(
        r"(?:add\s+expense|record\s+expense|log\s+expense|spent|paid)\s*(?:₹|rs\.?|inr)?\s*(\d+(?:\.\d+)?)\s*(?:for|on|towards)?\s*(.+)?",
        text,
        re.IGNORECASE
    )
    if add_exp_match:
        parsed = _parse_custom_transaction_attrs(text, tx_type="expense")
        amt = parsed["amount"] if parsed["amount"] > 0 else float(add_exp_match.group(1))
        item = parsed["title"] if parsed["title"] else (add_exp_match.group(2) or "General Expense").strip()
        res = exec_add_transaction(
            amount=amt,
            title=item,
            tx_type="expense",
            category=parsed.get("category"),
            profile_type=parsed.get("profile_type"),
            payment_mode=parsed.get("payment_mode", "upi")
        )
        return _finalize({"reply": res["formatted"], "state": "IDLE", "intent": "ADD_EXPENSE", "tool": "addExpense"})

    # 4. Add Revenue / Income (Natural Language Extraction with Custom Attributes)
    add_inc_match = re.search(
        r"(?:add\s+income|add\s+revenue|record\s+revenue|log\s+income|received)\s*(?:₹|rs\.?|inr)?\s*(\d+(?:\.\d+)?)\s*(?:for|from|towards)?\s*(.+)?",
        text,
        re.IGNORECASE
    )
    if add_inc_match:
        parsed = _parse_custom_transaction_attrs(text, tx_type="revenue")
        amt = parsed["amount"] if parsed["amount"] > 0 else float(add_inc_match.group(1))
        item = parsed["title"] if parsed["title"] else (add_inc_match.group(2) or "General Income").strip()
        res = exec_add_transaction(
            amount=amt,
            title=item,
            tx_type="revenue",
            category=parsed.get("category"),
            profile_type=parsed.get("profile_type"),
            payment_mode=parsed.get("payment_mode", "upi")
        )
        return _finalize({"reply": res["formatted"], "state": "IDLE", "intent": "ADD_INCOME", "tool": "addIncome"})

    # 5. Gemini AI Engine Call (if configured and not intercepted by exact triggers)
    if os.getenv("GEMINI_API_KEY"):
        gemini_result = await call_gemini_api(p, text)
        if gemini_result and gemini_result.get("reply"):
            return _finalize(gemini_result)

    # 6. Standard Deterministic NLP Router
    if any(w in lower for w in ["payable", "supplier", "vendor", "bill"]):
        res = exec_get_outstanding_payables()
        return _finalize({"reply": res["formatted"], "state": "IDLE", "intent": "GET_PAYABLES", "tool": "getOutstandingPayables"})

    if any(w in lower for w in ["receivable", "owe", "customer", "client", "debtor", "due"]):
        res = exec_get_outstanding_receivables()
        return _finalize({"reply": res["formatted"], "state": "IDLE", "intent": "GET_RECEIVABLES", "tool": "getOutstandingReceivables"})

    if any(w in lower for w in ["balance", "profit", "kpi", "summary", "revenue", "income"]):
        res = exec_get_financial_kpis()
        return _finalize({"reply": res["formatted"], "state": "IDLE", "intent": "GET_KPIS", "tool": "getFinancialKPIs"})

    if any(w in lower for w in ["transaction", "history", "recent", "statement", "ledger"]):
        res = exec_get_recent_transactions()
        return _finalize({"reply": res["formatted"], "state": "IDLE", "intent": "GET_TRANSACTIONS", "tool": "getRecentTransactions"})

    if any(w in lower for w in ["expense", "spend", "cost", "category", "breakdown"]):
        res = exec_get_expense_breakdown()
        return _finalize({"reply": res["formatted"], "state": "IDLE", "intent": "GET_EXPENSES", "tool": "getExpenseBreakdown"})

    inv_match = re.search(r"inv[-\d\w]+", lower)
    if inv_match:
        res = exec_check_transaction_status(invoice_number=inv_match.group(0))
        return _finalize({"reply": res["formatted"], "state": "IDLE", "intent": "CHECK_INVOICE", "tool": "checkTransactionStatus"})

    if any(w in lower for w in ["app", "link", "dashboard", "portal", "login"]):
        handoff = create_handoff_token(p, target_screen="dashboard")
        reply = (
            f"🔐 *Secure ENX Money App Access Link*\n\n"
            f"Click below to access your account dashboard securely:\n"
            f"👉 {handoff['web_link']}\n\n"
            f"⚡ _This single-use cryptographic token is valid for 10 minutes._"
        )
        return _finalize({"reply": reply, "state": "IDLE", "intent": "APP_HANDOFF", "tool": "createSecureAppHandoff"})

    # Default fallback: Show all quick actions
    res = exec_get_all_quick_actions()
    return _finalize({
        "reply": f"🤖 *ENX Money Assistant*\n\n{res['formatted']}",
        "state": "IDLE",
        "intent": "ALL_QUICK_ACTIONS"
    })
