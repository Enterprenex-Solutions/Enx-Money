"""
Automated Test Suite for ENX Money WhatsApp Chatbot (Python & FastAPI Engine)
Tests Real Account Data Fetching, Check Balance All, Live Ledger Add Expense/Income Mutations,
All Quick Actions in One Message, User Verification, Tool Execution, Expiring Handoffs, and Simulator.
"""

import sys
import asyncio

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

from services.whatsapp_ai_service import (
    process_whatsapp_message,
    start_verification,
    verify_otp,
    normalize_phone,
    exec_get_financial_kpis,
    exec_get_outstanding_receivables,
    exec_get_outstanding_payables,
    exec_get_recent_transactions,
    exec_check_transaction_status,
    exec_check_balance_all,
    exec_add_transaction,
    exec_get_all_quick_actions,
    create_handoff_token,
    verify_handoff_token,
)

async def run_all_tests():
    print("=" * 65)
    print("🧪 ENX MONEY WHATSAPP CHATBOT EXTENDED TEST SUITE")
    print("=" * 65)

    # 1. Phone normalization
    print("\n[1] Testing Phone Normalization...")
    assert normalize_phone("+91 98765 43210") == "919876543210"
    assert normalize_phone("9876543210") == "919876543210"
    print("    ✅ Phone normalization validated.")

    # 2. Account pairing & OTP verification
    print("\n[2] Testing Account Pairing & 6-Digit OTP...")
    test_phone = "919876543299"
    init_res = start_verification(test_phone, "anjali@enterprise.com")
    assert init_res["success"] is True
    assert len(init_res["otp_code"]) == 6

    verify_res = verify_otp(test_phone, init_res["otp_code"])
    assert verify_res["success"] is True
    assert "Verified" in verify_res["message"]
    print("    ✅ Account pairing & OTP verification succeeded.")

    # 3. Real Account Data: Financial KPIs
    print("\n[3] Testing Real Financial KPIs Tool...")
    kpi_res = exec_get_financial_kpis()
    assert "Financial Summary" in kpi_res["formatted"]
    assert kpi_res["total_revenue"] > 0
    assert kpi_res["total_expense"] > 0
    print(f"    ✅ Financial KPIs: Rev={kpi_res['total_revenue']}, Exp={kpi_res['total_expense']}, Net={kpi_res['net_profit']}")

    # 4. Real Account Data: Receivables (TechCorp Solutions due balance)
    print("\n[4] Testing Real Outstanding Receivables Tool...")
    recv_res = exec_get_outstanding_receivables()
    assert "formatted" in recv_res
    assert recv_res["count"] > 0, "Real customer receivables should be found"
    assert recv_res["total_due"] >= 95000.0, "TechCorp dues should be fetched"
    assert "TechCorp" in recv_res["formatted"]
    print(f"    ✅ Real customer receivables fetched: {recv_res['count']} debtor(s), Total Due=₹{recv_res['total_due']:,.2f}")

    # 5. Real Account Data: Payables (Dell Vendor due balance)
    print("\n[5] Testing Real Outstanding Vendor Payables Tool...")
    pay_res = exec_get_outstanding_payables()
    assert "formatted" in pay_res
    assert pay_res["count"] > 0, "Real supplier payables should be found"
    assert pay_res["total_due"] >= 68000.0, "Dell dues should be fetched"
    assert "Dell" in pay_res["formatted"]
    print(f"    ✅ Real vendor payables fetched: {pay_res['count']} creditor(s), Total Due=₹{pay_res['total_due']:,.2f}")

    # 6. Feature: Check Balance All (Unified Multi-Account Summary)
    print("\n[6] Testing 'Check Balance All' Comprehensive Tool...")
    bal_all_res = exec_check_balance_all()
    assert "ALL ACCOUNTS & BALANCE OVERVIEW" in bal_all_res["formatted"]
    assert "NET AVAILABLE CASH" in bal_all_res["formatted"]
    assert "Business Account" in bal_all_res["formatted"]
    assert "Personal Account" in bal_all_res["formatted"]
    assert "Net Working Capital" in bal_all_res["formatted"]
    print(f"    ✅ Check Balance All: Cash=₹{bal_all_res['net_cash_balance']:,.2f}, Working Capital=₹{bal_all_res['net_working_capital']:,.2f}")

    # 7. Feature: Live Ledger Add Expense & Add Revenue Mutations
    print("\n[7] Testing Live Ledger 'Add Expense' Mutation Tool...")
    exp_res = exec_add_transaction(amount=750.0, title="Team Coffee & Snacks", tx_type="expense")
    assert exp_res["success"] is True
    assert "Expense Logged Successfully" in exp_res["formatted"]
    assert "tx-wa-" in exp_res["transaction"]["id"]
    print(f"    ✅ Added real expense: ID={exp_res['transaction']['id']}, Amount=₹750.00")

    print("\n[8] Testing Live Ledger 'Add Revenue' Mutation Tool...")
    rev_res = exec_add_transaction(amount=18000.0, title="UI Design Consulting", tx_type="revenue")
    assert rev_res["success"] is True
    assert "Income Logged Successfully" in rev_res["formatted"]
    assert "tx-wa-" in rev_res["transaction"]["id"]
    print(f"    ✅ Added real revenue: ID={rev_res['transaction']['id']}, Amount=₹18,000.00")

    # 8. Feature: All Quick Actions in One Message
    print("\n[9] Testing 'All Quick Actions (One Message)' Tool...")
    actions_res = exec_get_all_quick_actions()
    assert "ALL QUICK ACTIONS (ONE MESSAGE)" in actions_res["formatted"]
    assert "Check balance all" in actions_res["formatted"]
    assert "Add expense" in actions_res["formatted"]
    assert "Add income" in actions_res["formatted"]
    assert "Who owes me money?" in actions_res["formatted"]
    print("    ✅ All Quick Actions single message generated with 7 functional action groups.")

    # 9. Recent Transactions & Invoice Status Lookup
    print("\n[10] Testing Recent Transactions & Status Lookup Tools...")
    tx_res = exec_get_recent_transactions(limit=3)
    assert "Recent Transactions" in tx_res["formatted"]

    inv_res = exec_check_transaction_status(invoice_number="INV-2026-089")
    assert inv_res["found"] is True
    assert "Transaction Status Lookup" in inv_res["formatted"]
    print("    ✅ Recent transactions and invoice lookup verified with real data.")

    # 10. Expiring Cryptographic Handoff Token
    print("\n[11] Testing 10-Minute Expiring Cryptographic Handoff Token...")
    handoff = create_handoff_token(test_phone, target_screen="compliance", reason="Audit Review")
    assert handoff["token"].startswith("enx_")
    valid_res = verify_handoff_token(handoff["token"])
    assert valid_res["valid"] is True
    replay_res = verify_handoff_token(handoff["token"])
    assert replay_res["valid"] is False
    print("    ✅ Single-use cryptographic handoff verified.")

    # 11. Conversational NLP Natural Language Routing
    print("\n[12] Testing Conversational Message Routing...")
    # Check balance all command
    chat_bal_all = await process_whatsapp_message("919876543210", "Check balance all")
    assert chat_bal_all["intent"] == "CHECK_BALANCE_ALL"
    assert "ALL ACCOUNTS & BALANCE OVERVIEW" in chat_bal_all["reply"]

    # Quick actions command
    chat_actions = await process_whatsapp_message("919876543210", "Quick actions")
    assert chat_actions["intent"] == "ALL_QUICK_ACTIONS"
    assert "ALL QUICK ACTIONS (ONE MESSAGE)" in chat_actions["reply"]

    # Natural language add expense
    chat_exp = await process_whatsapp_message("919876543210", "Add expense 500 for lunch")
    assert chat_exp["intent"] == "ADD_EXPENSE"
    assert "Expense Logged Successfully" in chat_exp["reply"]

    # Natural language add revenue
    chat_rev = await process_whatsapp_message("919876543210", "Add income 25000 consulting")
    assert chat_rev["intent"] == "ADD_INCOME"
    assert "Income Logged Successfully" in chat_rev["reply"]

    # Natural language receivables
    recv_chat = await process_whatsapp_message("919876543210", "Who owes me money?")
    assert recv_chat["intent"] == "GET_RECEIVABLES"
    assert "TechCorp" in recv_chat["reply"]

    # Natural language payables
    pay_chat = await process_whatsapp_message("919876543210", "What bills are due to suppliers?")
    assert pay_chat["intent"] == "GET_PAYABLES"
    assert "Dell" in pay_chat["reply"]

    print("    ✅ Conversational natural language matching & live ledger mutations fully verified.")

    # 12. Outbound WhatsApp Message Dispatching
    print("\n[13] Testing Outbound Message Dispatching...")
    from services.whatsapp_ai_service import send_whatsapp_message
    from services.json_store import db_store
    dispatch_res = await send_whatsapp_message("919876543210", "Test notification from ENX Money")
    assert dispatch_res["success"] is True
    print("    ✅ Outbound WhatsApp message dispatch verified.")

    # 14. Real Account Linking & JSON Persistence
    print("\n[14] Testing Real Account Linking & Persistence...")
    link_phone = "919811223344"
    chat_link = await process_whatsapp_message(link_phone, "Link account 919811223344 anjali.real@enterprise.com Real Anjali Industries")
    assert chat_link["intent"] == "ACCOUNT_LINKED"
    assert "Successfully Linked" in chat_link["reply"]

    # Verify saved in db_store
    linked_user = db_store.get_whatsapp_user_by_phone(link_phone)
    assert linked_user is not None
    assert linked_user["user_name"] == "Real Anjali Industries"
    assert linked_user["email"] == "anjali.real@enterprise.com"
    print(f"    ✅ Real account linked and persisted in data.json: {linked_user['user_name']} (+{link_phone})")

    # 15. WhatsApp Chat Persistence in data.json
    print("\n[15] Testing Persistent WhatsApp Chat Storage...")
    chats = db_store.get_whatsapp_chats(phone=link_phone)
    assert len(chats) >= 2, f"Expected at least 2 chat records (inbound + outbound), got {len(chats)}"
    inbound_found = any(c.get("direction") == "inbound" and "Link account" in c.get("message", "") for c in chats)
    outbound_found = any(c.get("direction") == "outbound" and "Successfully Linked" in c.get("message", "") for c in chats)
    assert inbound_found, "Inbound message should be persisted"
    assert outbound_found, "Outbound reply should be persisted"
    print(f"    ✅ Chat messages persistently stored in data.json: {len(chats)} message(s) retrieved.")

    # 16. Custom Transaction Values (Amount, Category, Profile, Payment Mode)
    print("\n[16] Testing Custom Transaction Values Extraction & Ledger Mutation...")
    custom_exp_text = "Add expense 4999.50 AWS Cloud Servers category Infrastructure mode card profile business"
    custom_exp_res = await process_whatsapp_message(link_phone, custom_exp_text)
    assert custom_exp_res["intent"] == "ADD_EXPENSE"
    assert "Expense Logged Successfully" in custom_exp_res["reply"]
    assert "₹4,999.50" in custom_exp_res["reply"]
    assert "Infrastructure" in custom_exp_res["reply"]
    assert "Business" in custom_exp_res["reply"]
    assert "CREDITCARD" in custom_exp_res["reply"] or "CARD" in custom_exp_res["reply"]
    print(f"    ✅ Custom expense with custom amount, category, mode, and profile logged successfully.")

    # Test guided prompt on bare 'Add expense'
    bare_prompt = await process_whatsapp_message(link_phone, "Add expense")
    assert bare_prompt["intent"] == "ADD_TRANSACTION_HELP"
    assert "Add Custom Expense" in bare_prompt["reply"]
    print("    ✅ Interactive custom transaction guide verified.")

    print("\n" + "=" * 65)
    print("🎉 ALL 16/16 WHATSAPP CHATBOT TESTS PASSED SUCCESSFULLY! 🎉")
    print("=" * 65)

if __name__ == "__main__":
    asyncio.run(run_all_tests())
