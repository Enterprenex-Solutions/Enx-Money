"""
ENX Money Meta AI & Live Chat Router
Asynchronous non-blocking AI gateway powered by uvloop event-loop implementation.
"""

import os
import httpx
from datetime import datetime
from typing import List, Optional, Dict, Any
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field

router = APIRouter(prefix="/api/ai", tags=["Meta AI & Live Chat Engine"])

# In-memory store for session chat history
_chat_history_store: Dict[str, List[Dict[str, Any]]] = {}


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, description="User prompt string")
    language: Optional[str] = "en"
    history: Optional[List[Dict[str, Any]]] = []
    provider: Optional[str] = "auto"


def _save_history(user_id: str, user_msg: str, ai_reply: str):
    existing = _chat_history_store.setdefault(user_id, [])
    now_iso = datetime.utcnow().isoformat() + "Z"
    existing.append({"role": "user", "content": user_msg, "timestamp": now_iso})
    existing.append({"role": "assistant", "content": ai_reply, "timestamp": now_iso})
    if len(existing) > 30:
        existing[:] = existing[-30:]


@router.post("/chat", summary="Asynchronous Live Chat with Meta AI / Business Advisor")
async def chat_message(payload: ChatRequest):
    """
    Sends message to Meta AI (Groq Llama 3.3) or Google Gemini.
    Runs asynchronously on the uvloop event loop without blocking concurrent requests.
    """
    clean_message = payload.message.strip()
    if not clean_message:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error": "INVALID_REQUEST_BODY", "message": "A valid message string is required"}
        )

    lang = (payload.language or "en")[:2].lower()
    selected_provider = (payload.provider or "auto").lower()

    groq_key = os.getenv("GROQ_API_KEY") or os.getenv("META_AI_API_KEY")
    groq_model = os.getenv("GROQ_MODEL", "groq/compound-mini")
    gemini_key = os.getenv("GEMINI_API_KEY")
    gemini_model = os.getenv("GEMINI_MODEL", "gemini-3.6-flash")

    async with httpx.AsyncClient(timeout=10.0) as client:
        # 1. Groq Meta AI (Llama 3.3)
        if selected_provider in ("auto", "meta") and groq_key:
            try:
                headers = {
                    "Authorization": f"Bearer {groq_key.strip()}",
                    "Content-Type": "application/json"
                }
                groq_payload = {
                    "model": groq_model,
                    "messages": [
                        {
                            "role": "system",
                            "content": (
                                f"You are the Meta AI Business & Accounting Advisor embedded in ENX Money. "
                                f"Provide concise, expert, actionable advice on GST, invoicing, retail inventory, "
                                f"debt recovery, and Khata in {lang} language. Format with clean markdown."
                            )
                        },
                        *[
                            {"role": "user" if h.get("role") == "user" else "assistant", "content": str(h.get("content", ""))}
                            for h in (payload.history or [])
                        ],
                        {"role": "user", "content": clean_message}
                    ],
                    "max_tokens": 800,
                    "temperature": 0.7
                }
                res = await client.post(
                    "https://api.groq.com/openai/v1/chat/completions",
                    json=groq_payload,
                    headers=headers
                )
                if res.status_code == 200:
                    data = res.json()
                    reply = data["choices"][0]["message"]["content"]
                    _save_history("default_user", clean_message, reply)
                    return {
                        "success": True,
                        "message": "AI response generated successfully",
                        "data": {
                            "reply": reply,
                            "source": "META_AI_GROQ",
                            "provider": "Meta AI (Llama 3.3)",
                            "model": groq_model,
                            "timestamp": datetime.utcnow().isoformat() + "Z"
                        }
                    }
                elif res.status_code in (401, 403):
                    raise HTTPException(status_code=502, detail={"error": "UNAUTHORIZED", "message": "AI service authentication error. Please try again later."})
                elif res.status_code == 404:
                    raise HTTPException(status_code=502, detail={"error": "WRONG_MODEL", "message": "Selected AI model is currently unavailable."})
                elif res.status_code == 429:
                    raise HTTPException(status_code=429, detail={"error": "RATE_LIMIT_EXCEEDED", "message": "AI service is receiving high volume. Please wait a moment and try again."})
            except HTTPException:
                if selected_provider == "meta":
                    raise
            except httpx.TimeoutException:
                if selected_provider == "meta":
                    raise HTTPException(status_code=504, detail={"error": "NETWORK_TIMEOUT", "message": "AI service took too long to respond. Please try again."})
            except Exception as e:
                if selected_provider == "meta":
                    raise HTTPException(status_code=503, detail={"error": "UPSTREAM_UNAVAILABLE", "message": "AI service is temporarily unavailable. Please try again."})

        # 2. Secondary upstream: Google Gemini
        if gemini_key:
            try:
                gemini_url = f"https://generativelanguage.googleapis.com/v1beta/models/{gemini_model}:generateContent?key={gemini_key.strip()}"
                gemini_payload = {
                    "contents": [{"role": "user", "parts": [{"text": clean_message}]}]
                }
                res = await client.post(gemini_url, json=gemini_payload)
                if res.status_code == 200:
                    data = res.json()
                    reply = data["candidates"][0]["content"]["parts"][0]["text"]
                    _save_history("default_user", clean_message, reply)
                    return {
                        "success": True,
                        "message": "AI response generated successfully",
                        "data": {
                            "reply": reply,
                            "source": "GOOGLE_GEMINI",
                            "provider": "Google Gemini 3.6",
                            "model": gemini_model,
                            "timestamp": datetime.utcnow().isoformat() + "Z"
                        }
                    }
            except Exception:
                pass

    raise HTTPException(
        status_code=503,
        detail={"error": "UPSTREAM_UNAVAILABLE", "message": "AI service is temporarily unavailable. Please try again."}
    )


@router.get("/history", summary="Retrieve Chat History")
async def get_chat_history():
    history = _chat_history_store.get("default_user", [])
    return {"success": True, "data": history}


@router.delete("/history", summary="Clear Chat History")
async def clear_chat_history():
    _chat_history_store.pop("default_user", None)
    return {"success": True, "message": "Chat history cleared successfully", "data": {"cleared": True}}
