import os
from datetime import datetime
from fastapi import APIRouter, status
from config import settings
from services.json_store import db_store

router = APIRouter(prefix="/api/data", tags=["Data Store Management"])


@router.get("/raw", summary="Retrieve complete raw JSON database file")
def get_raw_database():
    return db_store.get_raw_data()


@router.get("/status", summary="Get database storage statistics and health")
def get_database_status():
    file_path = settings.storage_path
    exists = file_path.exists()
    size_bytes = file_path.stat().st_size if exists else 0
    modified = datetime.fromtimestamp(file_path.stat().st_mtime).isoformat() if exists else None

    return {
        "status": "healthy",
        "storageType": "JSON File Persistence",
        "storagePath": str(file_path),
        "exists": exists,
        "sizeBytes": size_bytes,
        "lastModified": modified,
        "counts": {
            "enterprises": len(db_store.get_all_enterprises()),
            "customers": len(db_store.get_all_customers()),
            "suppliers": len(db_store.get_all_suppliers()),
            "transactions": len(db_store.get_all_transactions()),
        }
    }


@router.post("/reset", status_code=status.HTTP_200_OK, summary="Clear all stored entities in database")
def reset_database():
    db_store.clear_all()
    return {"message": "All transactions, enterprises, customers, and suppliers have been cleared."}


@router.post("/seed", status_code=status.HTTP_200_OK, summary="Repopulate database with default demo dataset")
def seed_demo_data():
    now = datetime.now()

    # Clear and repopulate
    db_store.clear_all()

    # Enterprise
    db_store.add_enterprise({
        "id": "ent-1",
        "companyName": "ENX Global Technologies Pvt Ltd",
        "gstin": "27AAACE1234F1Z9",
        "email": "billing@enxtech.com",
        "phone": "+91 98765 43210",
        "address": "101 Tech Park, BKC, Mumbai, Maharashtra 400051",
        "createdAt": now.isoformat()
    })

    # Customers
    db_store.add_customer({
        "id": "cust-1",
        "name": "TechCorp Solutions",
        "companyName": "TechCorp LLC",
        "phone": "+91 91234 56789",
        "email": "accounts@techcorp.com",
        "address": "Sector 62, Noida, Uttar Pradesh 201301",
        "totalInvoiced": 245000.0,
        "outstandingBalance": 95000.0,
        "createdAt": now.isoformat()
    })

    # Suppliers
    db_store.add_supplier({
        "id": "supp-1",
        "name": "AWS Cloud Services",
        "companyName": "Amazon Web Services",
        "category": "Cloud Infrastructure",
        "phone": "+91 80000 11223",
        "email": "aws-billing@amazon.com",
        "address": "Hyderabad, Telangana 500081",
        "totalBilled": 32400.0,
        "outstandingPayable": 0.0,
        "createdAt": now.isoformat()
    })
    db_store.add_supplier({
        "id": "supp-2",
        "name": "Dell Hardware Vendor",
        "companyName": "Dell Technologies",
        "category": "Hardware Supplier",
        "phone": "+91 80000 44556",
        "email": "enterprise-sales@dell.com",
        "address": "Whitefield, Bengaluru, Karnataka 560066",
        "totalBilled": 68000.0,
        "outstandingPayable": 68000.0,
        "createdAt": now.isoformat()
    })

    # Transactions
    db_store.add_transaction({
        "id": "b-101",
        "title": "Enterprise Software License Sale",
        "amount": 245000.0,
        "type": "revenue",
        "profileType": "business",
        "category": "Software Sales",
        "date": now.isoformat(),
        "paymentMode": "bankTransfer",
        "notes": "Annual license renewal for TechCorp",
        "gstRate": 18.0,
        "invoiceNumber": "INV-2026-089",
        "isCleared": True,
        "enterpriseId": "ent-1",
        "customerId": "cust-1",
        "supplierId": None
    })
    db_store.add_transaction({
        "id": "b-102",
        "title": "AWS Cloud Hosting Invoice",
        "amount": 32400.0,
        "type": "expense",
        "profileType": "business",
        "category": "Infrastructure",
        "date": now.isoformat(),
        "paymentMode": "creditCard",
        "notes": "Monthly production server fees",
        "gstRate": 18.0,
        "invoiceNumber": "AWS-99210",
        "isCleared": True,
        "enterpriseId": "ent-1",
        "customerId": None,
        "supplierId": "supp-1"
    })
    db_store.add_transaction({
        "id": "p-201",
        "title": "Monthly Salary Credit",
        "amount": 150000.0,
        "type": "revenue",
        "profileType": "personal",
        "category": "Salary",
        "date": now.isoformat(),
        "paymentMode": "bankTransfer",
        "notes": "Monthly salary credit",
        "gstRate": 0.0,
        "invoiceNumber": None,
        "isCleared": True,
        "enterpriseId": None,
        "customerId": None,
        "supplierId": None
    })

    return {
        "message": "Demo seed dataset populated successfully.",
        "counts": {
            "enterprises": len(db_store.get_all_enterprises()),
            "customers": len(db_store.get_all_customers()),
            "suppliers": len(db_store.get_all_suppliers()),
            "transactions": len(db_store.get_all_transactions()),
        }
    }
