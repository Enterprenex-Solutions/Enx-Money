"""
ENX Money Asynchronous Notifications & Reminders Router
Non-blocking I/O dispatch engine executing on the uvloop event loop.
"""

from datetime import datetime
from typing import List, Optional, Dict, Any
from fastapi import APIRouter, BackgroundTasks, HTTPException, status
from pydantic import BaseModel, Field

router = APIRouter(prefix="/api/notifications", tags=["Async Notifications & Alerts Engine"])

_notifications_queue: List[Dict[str, Any]] = []


class NotificationPayload(BaseModel):
    title: str = Field(..., min_length=1, description="Notification title")
    message: str = Field(..., min_length=1, description="Notification body")
    channel: Optional[str] = "push"  # push, email, sms
    recipient: Optional[str] = None
    priority: Optional[str] = "normal"  # high, normal, low


async def _dispatch_notification_async(notification_data: Dict[str, Any]):
    """
    Non-blocking asynchronous dispatch task running on the uvloop event loop.
    Simulates external delivery and marks delivered without blocking request threads.
    """
    notification_data["status"] = "delivered"
    notification_data["deliveredAt"] = datetime.utcnow().isoformat() + "Z"
    _notifications_queue.append(notification_data)
    if len(_notifications_queue) > 100:
        _notifications_queue.pop(0)


@router.post("/send", summary="Asynchronously dispatch notification")
async def send_notification(payload: NotificationPayload, background_tasks: BackgroundTasks):
    """
    Accepts a notification request and queues it for asynchronous execution.
    Returns immediately to ensure ultra-low latency for concurrent mobile users.
    """
    notification_id = f"notif_{int(datetime.utcnow().timestamp() * 1000)}"
    data = {
        "id": notification_id,
        "title": payload.title,
        "message": payload.message,
        "channel": payload.channel,
        "recipient": payload.recipient or "all_users",
        "priority": payload.priority,
        "createdAt": datetime.utcnow().isoformat() + "Z",
        "status": "queued"
    }

    # Delegate I/O to background asynchronous task
    background_tasks.add_task(_dispatch_notification_async, data)

    return {
        "success": True,
        "message": "Notification queued for asynchronous delivery",
        "notificationId": notification_id,
        "status": "queued"
    }


@router.get("/", summary="Get notification queue status")
async def get_notifications():
    """
    Retrieves queued/dispatched notifications.
    """
    return {
        "success": True,
        "total": len(_notifications_queue),
        "notifications": list(reversed(_notifications_queue[-50:]))
    }
