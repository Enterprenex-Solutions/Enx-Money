from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, HTTPException, Query, status
from models.enums import ProfileType, TransactionType, DateFilterOption
from models.transaction import TransactionModel, TransactionCreate, TransactionUpdate
from services.analytics_service import AnalyticsService
from services.json_store import db_store
from utils.serializers import to_json_serializable

router = APIRouter(prefix="/api/transactions", tags=["Transactions"])


@router.get("", response_model=List[TransactionModel], summary="List and filter transactions")
def list_transactions(
    profile: ProfileType = Query(default=ProfileType.business, description="Profile scope: business or personal"),
    filter_option: DateFilterOption = Query(default=DateFilterOption.thisMonth, description="Date filter range"),
    custom_start: Optional[datetime] = Query(default=None, description="Custom range start date (ISO-8601)"),
    custom_end: Optional[datetime] = Query(default=None, description="Custom range end date (ISO-8601)"),
    category: Optional[str] = Query(default=None, description="Filter by category name"),
    search: Optional[str] = Query(default=None, description="Search term across title, category, invoice number"),
    drill_down_type: Optional[TransactionType] = Query(default=None, description="Filter by specific transaction type"),
):
    return AnalyticsService.get_filtered_transactions(
        profile=profile,
        filter_option=filter_option,
        custom_start=custom_start,
        custom_end=custom_end,
        category=category,
        search_query=search,
        drill_down_type=drill_down_type,
    )


@router.get("/all-raw", response_model=List[TransactionModel], summary="Get all transactions without filtering")
def get_all_raw_transactions():
    return db_store.get_all_transactions()


@router.get("/{transaction_id}", response_model=TransactionModel, summary="Get transaction by ID")
def get_transaction(transaction_id: str):
    tx = db_store.get_transaction_by_id(transaction_id)
    if not tx:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Transaction '{transaction_id}' not found")
    return tx


@router.post("", response_model=TransactionModel, status_code=status.HTTP_201_CREATED, summary="Create a new transaction and auto-sync balances")
def create_transaction(payload: TransactionCreate):
    created = db_store.add_transaction(to_json_serializable(payload.dict()))
    return created


@router.put("/{transaction_id}", response_model=TransactionModel, summary="Update an existing transaction")
def update_transaction(transaction_id: str, payload: TransactionUpdate):
    updated = db_store.update_transaction(transaction_id, to_json_serializable(payload.dict(exclude_unset=True)))
    if not updated:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Transaction '{transaction_id}' not found")
    return updated


@router.delete("/{transaction_id}", status_code=status.HTTP_204_NO_CONTENT, summary="Delete a transaction")
def delete_transaction(transaction_id: str):
    success = db_store.delete_transaction(transaction_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Transaction '{transaction_id}' not found")
    return None
