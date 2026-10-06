from typing import List
from fastapi import APIRouter, HTTPException, status
from models.customer import CustomerModel, CustomerCreate, CustomerUpdate
from models.transaction import TransactionModel
from services.json_store import db_store
from utils.serializers import to_json_serializable

router = APIRouter(prefix="/api/customers", tags=["Customers"])


@router.get("", response_model=List[CustomerModel], summary="List all customers")
def list_customers():
    return db_store.get_all_customers()


@router.get("/{customer_id}", response_model=CustomerModel, summary="Get customer by ID")
def get_customer(customer_id: str):
    cust = db_store.get_customer_by_id(customer_id)
    if not cust:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Customer '{customer_id}' not found")
    return cust


@router.get("/{customer_id}/transactions", response_model=List[TransactionModel], summary="Get all transactions for a specific customer")
def get_customer_transactions(customer_id: str):
    cust = db_store.get_customer_by_id(customer_id)
    if not cust:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Customer '{customer_id}' not found")
    txs = [t for t in db_store.get_all_transactions() if t.get("customerId") == customer_id]
    return txs


@router.post("", response_model=CustomerModel, status_code=status.HTTP_201_CREATED, summary="Create a new customer")
def create_customer(payload: CustomerCreate):
    created = db_store.add_customer(to_json_serializable(payload.dict()))
    return created


@router.put("/{customer_id}", response_model=CustomerModel, summary="Update customer details")
def update_customer(customer_id: str, payload: CustomerUpdate):
    updated = db_store.update_customer(customer_id, to_json_serializable(payload.dict(exclude_unset=True)))
    if not updated:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Customer '{customer_id}' not found")
    return updated


@router.delete("/{customer_id}", status_code=status.HTTP_204_NO_CONTENT, summary="Delete a customer")
def delete_customer(customer_id: str):
    success = db_store.delete_customer(customer_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Customer '{customer_id}' not found")
    return None
