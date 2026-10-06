from typing import List
from fastapi import APIRouter, HTTPException, status
from models.enterprise import EnterpriseModel, EnterpriseCreate, EnterpriseUpdate
from services.json_store import db_store
from utils.serializers import to_json_serializable

router = APIRouter(prefix="/api/enterprises", tags=["Enterprises"])


@router.get("", response_model=List[EnterpriseModel], summary="List all enterprises")
def list_enterprises():
    return db_store.get_all_enterprises()


@router.get("/{enterprise_id}", response_model=EnterpriseModel, summary="Get enterprise by ID")
def get_enterprise(enterprise_id: str):
    ent = db_store.get_enterprise_by_id(enterprise_id)
    if not ent:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Enterprise '{enterprise_id}' not found")
    return ent


@router.post("", response_model=EnterpriseModel, status_code=status.HTTP_201_CREATED, summary="Create a new enterprise")
def create_enterprise(payload: EnterpriseCreate):
    created = db_store.add_enterprise(to_json_serializable(payload.dict()))
    return created


@router.put("/{enterprise_id}", response_model=EnterpriseModel, summary="Update an existing enterprise")
def update_enterprise(enterprise_id: str, payload: EnterpriseUpdate):
    updated = db_store.update_enterprise(enterprise_id, to_json_serializable(payload.dict(exclude_unset=True)))
    if not updated:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Enterprise '{enterprise_id}' not found")
    return updated


@router.delete("/{enterprise_id}", status_code=status.HTTP_204_NO_CONTENT, summary="Delete an enterprise")
def delete_enterprise(enterprise_id: str):
    success = db_store.delete_enterprise(enterprise_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Enterprise '{enterprise_id}' not found")
    return None
