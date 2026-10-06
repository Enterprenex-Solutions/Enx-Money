from typing import List
from fastapi import APIRouter, HTTPException, status
from models.supplier import SupplierModel, SupplierCreate, SupplierUpdate
from models.transaction import TransactionModel
from services.json_store import db_store
from utils.serializers import to_json_serializable

router = APIRouter(prefix="/api/suppliers", tags=["Suppliers"])


@router.get("", response_model=List[SupplierModel], summary="List all suppliers")
def list_suppliers():
    return db_store.get_all_suppliers()


@router.get("/{supplier_id}", response_model=SupplierModel, summary="Get supplier by ID")
def get_supplier(supplier_id: str):
    supp = db_store.get_supplier_by_id(supplier_id)
    if not supp:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Supplier '{supplier_id}' not found")
    return supp


@router.get("/{supplier_id}/transactions", response_model=List[TransactionModel], summary="Get all transactions for a specific supplier")
def get_supplier_transactions(supplier_id: str):
    supp = db_store.get_supplier_by_id(supplier_id)
    if not supp:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Supplier '{supplier_id}' not found")
    txs = [t for t in db_store.get_all_transactions() if t.get("supplierId") == supplier_id]
    return txs


@router.post("", response_model=SupplierModel, status_code=status.HTTP_201_CREATED, summary="Create a new supplier")
def create_supplier(payload: SupplierCreate):
    created = db_store.add_supplier(to_json_serializable(payload.dict()))
    return created


@router.put("/{supplier_id}", response_model=SupplierModel, summary="Update supplier details")
def update_supplier(supplier_id: str, payload: SupplierUpdate):
    updated = db_store.update_supplier(supplier_id, to_json_serializable(payload.dict(exclude_unset=True)))
    if not updated:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Supplier '{supplier_id}' not found")
    return updated


@router.delete("/{supplier_id}", status_code=status.HTTP_204_NO_CONTENT, summary="Delete a supplier")
def delete_supplier(supplier_id: str):
    success = db_store.delete_supplier(supplier_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Supplier '{supplier_id}' not found")
    return None
