import json
import os
import shutil
import threading
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional
from config import settings
from utils.serializers import CustomJSONEncoder


class JsonStore:
    """Thread-safe, atomic JSON file-based database store."""

    _instance = None
    _lock = threading.RLock()

    def __new__(cls, *args, **kwargs):
        if not cls._instance:
            with cls._lock:
                if not cls._instance:
                    cls._instance = super(JsonStore, cls).__new__(cls)
                    cls._instance._initialized = False
        return cls._instance

    def __init__(self, file_path: Optional[Path] = None):
        if getattr(self, "_initialized", False):
            return

        with self._lock:
            self.file_path = file_path or settings.storage_path
            self._data: Dict[str, Any] = {
                "enterprises": [],
                "customers": [],
                "suppliers": [],
                "transactions": [],
                "categories": {
                    "business": {
                        "revenue": ["Software Sales", "Consulting", "Maintenance", "Service Contracts", "Other Income"],
                        "expense": ["Infrastructure", "Hardware", "Office Rent", "Salaries", "Marketing", "Travel", "Legal & Accounting", "Taxes", "Miscellaneous"]
                    },
                    "personal": {
                        "revenue": ["Salary", "Freelancing", "Investments", "Dividends", "Rental Income", "Gifts"],
                        "expense": ["Rent", "Groceries", "Dining Out", "Utilities", "Shopping", "Entertainment", "Healthcare", "Loans & EMI", "Travel", "Education"]
                    }
                },
                "profiles": [
                    {"id": "business", "label": "Business Management", "description": "Commercial revenues, vendor payments, GST & invoices"},
                    {"id": "personal", "label": "Personal Expense", "description": "Personal bank accounts, home budget & daily expenses"}
                ]
            }
            self._load()
            self._initialized = True

    def _ensure_dir(self):
        self.file_path.parent.mkdir(parents=True, exist_ok=True)

    def _load(self):
        self._ensure_dir()
        if self.file_path.exists():
            try:
                with open(self.file_path, "r", encoding="utf-8") as f:
                    content = json.load(f)
                    if isinstance(content, dict):
                        self._data.update(content)
            except Exception as e:
                print(f"[ERROR] Failed to load JSON data from {self.file_path}: {e}")
                self._save()
        else:
            self._save()

    def _save(self):
        """Atomic write to prevent corruption during concurrent operations."""
        self._ensure_dir()
        temp_file = self.file_path.with_suffix(".tmp")
        try:
            with open(temp_file, "w", encoding="utf-8") as f:
                json.dump(self._data, f, indent=2, cls=CustomJSONEncoder)
            shutil.move(str(temp_file), str(self.file_path))
        except Exception as e:
            if temp_file.exists():
                temp_file.unlink(missing_ok=True)
            raise IOError(f"Could not persist JSON storage: {e}")

    # ==================== Raw Data & Management ====================

    def get_raw_data(self) -> Dict[str, Any]:
        with self._lock:
            return json.loads(json.dumps(self._data, cls=CustomJSONEncoder))

    def clear_all(self):
        with self._lock:
            self._data["enterprises"] = []
            self._data["customers"] = []
            self._data["suppliers"] = []
            self._data["transactions"] = []
            self._save()

    def reload_from_disk(self):
        with self._lock:
            self._load()

    # ==================== Enterprises ====================

    def get_all_enterprises(self) -> List[Dict[str, Any]]:
        with self._lock:
            return list(self._data.get("enterprises", []))

    def get_enterprise_by_id(self, enterprise_id: str) -> Optional[Dict[str, Any]]:
        with self._lock:
            for ent in self._data.get("enterprises", []):
                if ent.get("id") == enterprise_id:
                    return ent
            return None

    def add_enterprise(self, enterprise: Dict[str, Any]) -> Dict[str, Any]:
        with self._lock:
            if "createdAt" not in enterprise or not enterprise["createdAt"]:
                enterprise["createdAt"] = datetime.now().isoformat()
            elif isinstance(enterprise["createdAt"], datetime):
                enterprise["createdAt"] = enterprise["createdAt"].isoformat()

            self._data["enterprises"].insert(0, enterprise)
            self._save()
            return enterprise

    def update_enterprise(self, enterprise_id: str, updates: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        with self._lock:
            for i, ent in enumerate(self._data.get("enterprises", [])):
                if ent.get("id") == enterprise_id:
                    updated = {**ent, **{k: v for k, v in updates.items() if v is not None}}
                    self._data["enterprises"][i] = updated
                    self._save()
                    return updated
            return None

    def delete_enterprise(self, enterprise_id: str) -> bool:
        with self._lock:
            initial_len = len(self._data.get("enterprises", []))
            self._data["enterprises"] = [
                e for e in self._data.get("enterprises", []) if e.get("id") != enterprise_id
            ]
            if len(self._data["enterprises"]) < initial_len:
                self._save()
                return True
            return False

    # ==================== Customers ====================

    def get_all_customers(self) -> List[Dict[str, Any]]:
        with self._lock:
            return list(self._data.get("customers", []))

    def get_customer_by_id(self, customer_id: str) -> Optional[Dict[str, Any]]:
        with self._lock:
            for cust in self._data.get("customers", []):
                if cust.get("id") == customer_id:
                    return cust
            return None

    def add_customer(self, customer: Dict[str, Any]) -> Dict[str, Any]:
        with self._lock:
            if "createdAt" not in customer or not customer["createdAt"]:
                customer["createdAt"] = datetime.now().isoformat()
            elif isinstance(customer["createdAt"], datetime):
                customer["createdAt"] = customer["createdAt"].isoformat()

            customer["totalInvoiced"] = float(customer.get("totalInvoiced", 0.0))
            customer["outstandingBalance"] = float(customer.get("outstandingBalance", 0.0))

            self._data["customers"].insert(0, customer)
            self._save()
            return customer

    def update_customer(self, customer_id: str, updates: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        with self._lock:
            for i, cust in enumerate(self._data.get("customers", [])):
                if cust.get("id") == customer_id:
                    updated = {**cust, **{k: v for k, v in updates.items() if v is not None}}
                    self._data["customers"][i] = updated
                    self._save()
                    return updated
            return None

    def delete_customer(self, customer_id: str) -> bool:
        with self._lock:
            initial_len = len(self._data.get("customers", []))
            self._data["customers"] = [
                c for c in self._data.get("customers", []) if c.get("id") != customer_id
            ]
            if len(self._data["customers"]) < initial_len:
                self._save()
                return True
            return False

    # ==================== Suppliers ====================

    def get_all_suppliers(self) -> List[Dict[str, Any]]:
        with self._lock:
            return list(self._data.get("suppliers", []))

    def get_supplier_by_id(self, supplier_id: str) -> Optional[Dict[str, Any]]:
        with self._lock:
            for supp in self._data.get("suppliers", []):
                if supp.get("id") == supplier_id:
                    return supp
            return None

    def add_supplier(self, supplier: Dict[str, Any]) -> Dict[str, Any]:
        with self._lock:
            if "createdAt" not in supplier or not supplier["createdAt"]:
                supplier["createdAt"] = datetime.now().isoformat()
            elif isinstance(supplier["createdAt"], datetime):
                supplier["createdAt"] = supplier["createdAt"].isoformat()

            supplier["totalBilled"] = float(supplier.get("totalBilled", 0.0))
            supplier["outstandingPayable"] = float(supplier.get("outstandingPayable", 0.0))

            self._data["suppliers"].insert(0, supplier)
            self._save()
            return supplier

    def update_supplier(self, supplier_id: str, updates: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        with self._lock:
            for i, supp in enumerate(self._data.get("suppliers", [])):
                if supp.get("id") == supplier_id:
                    updated = {**supp, **{k: v for k, v in updates.items() if v is not None}}
                    self._data["suppliers"][i] = updated
                    self._save()
                    return updated
            return None

    def delete_supplier(self, supplier_id: str) -> bool:
        with self._lock:
            initial_len = len(self._data.get("suppliers", []))
            self._data["suppliers"] = [
                s for s in self._data.get("suppliers", []) if s.get("id") != supplier_id
            ]
            if len(self._data["suppliers"]) < initial_len:
                self._save()
                return True
            return False

    # ==================== Transactions ====================

    def get_all_transactions(self) -> List[Dict[str, Any]]:
        with self._lock:
            return list(self._data.get("transactions", []))

    def get_transaction_by_id(self, transaction_id: str) -> Optional[Dict[str, Any]]:
        with self._lock:
            for tx in self._data.get("transactions", []):
                if tx.get("id") == transaction_id:
                    return tx
            return None

    def add_transaction(self, tx: Dict[str, Any]) -> Dict[str, Any]:
        with self._lock:
            if "date" in tx and isinstance(tx["date"], datetime):
                tx["date"] = tx["date"].isoformat()

            # Insert transaction
            self._data["transactions"].insert(0, tx)

            # Auto-sync Customer balance
            cust_id = tx.get("customerId")
            if cust_id:
                for i, cust in enumerate(self._data.get("customers", [])):
                    if cust.get("id") == cust_id:
                        amount = float(tx.get("amount", 0.0))
                        total_inv = float(cust.get("totalInvoiced", 0.0)) + amount
                        out_bal = float(cust.get("outstandingBalance", 0.0))
                        if tx.get("type") == "receivable":
                            out_bal += amount
                        self._data["customers"][i]["totalInvoiced"] = total_inv
                        self._data["customers"][i]["outstandingBalance"] = out_bal
                        break

            # Auto-sync Supplier balance
            supp_id = tx.get("supplierId")
            if supp_id:
                for i, supp in enumerate(self._data.get("suppliers", [])):
                    if supp.get("id") == supp_id:
                        amount = float(tx.get("amount", 0.0))
                        total_bill = float(supp.get("totalBilled", 0.0)) + amount
                        out_pay = float(supp.get("outstandingPayable", 0.0))
                        if tx.get("type") == "payable":
                            out_pay += amount
                        self._data["suppliers"][i]["totalBilled"] = total_bill
                        self._data["suppliers"][i]["outstandingPayable"] = out_pay
                        break

            self._save()
            return tx

    def update_transaction(self, transaction_id: str, updates: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        with self._lock:
            if "date" in updates and isinstance(updates["date"], datetime):
                updates["date"] = updates["date"].isoformat()

            for i, tx in enumerate(self._data.get("transactions", [])):
                if tx.get("id") == transaction_id:
                    updated = {**tx, **{k: v for k, v in updates.items() if v is not None}}
                    self._data["transactions"][i] = updated
                    self._save()
                    return updated
            return None

    def delete_transaction(self, transaction_id: str) -> bool:
        with self._lock:
            initial_len = len(self._data.get("transactions", []))
            self._data["transactions"] = [
                t for t in self._data.get("transactions", []) if t.get("id") != transaction_id
            ]
            if len(self._data["transactions"]) < initial_len:
                self._save()
                return True
            return False

    # ==================== Categories & Profiles ====================

    def get_categories(self, profile: Optional[str] = None) -> Dict[str, Any]:
        with self._lock:
            cats = self._data.get("categories", {})
            if profile and profile in cats:
                return {profile: cats[profile]}
            return cats

    def get_profiles(self) -> List[Dict[str, Any]]:
        with self._lock:
            return list(self._data.get("profiles", []))


# Global store singleton instance
db_store = JsonStore()
