# ENX Money 💰 — REST API Backend Server

A high-performance **FastAPI** backend server for the **ENX Money** platform with a **JSON File Database Persistence Engine**, automated customer/supplier balance synchronization, dynamic financial analytics, and CSV/JSON report exports.

---

## 📁 Architecture Overview

```
server/
├── data/
│   └── data.json              # 💾 Primary JSON Database & Seed Store
├── exports/                   # 📄 Auto-generated CSV / JSON reports
├── config.json                # ⚙️ Server host, port, cors, and storage configuration
├── config.py                  # 🐍 Configuration loader
├── main.py                    # 🚀 FastAPI application & router mounter
├── run_server.py              # ▶️ Executable runner script
├── requirements.txt           # 📦 Pinned Python dependencies
├── test_server.py             # 🧪 Automated test suite
├── models/                    # 📋 Pydantic schemas & enums
│   ├── enums.py               # (ProfileType, TransactionType, DateFilterOption, PaymentMode)
│   ├── enterprise.py          # Enterprise models
│   ├── customer.py            # Customer models & balance tracking
│   ├── supplier.py            # Supplier models & payable tracking
│   ├── transaction.py         # Transaction models & GST calculation
│   └── analytics.py           # KPI, Daily trend, Category breakdown
├── services/                  # 🧠 Business logic & storage layer
│   ├── json_store.py          # Thread-safe atomic JSON file database engine
│   ├── analytics_service.py   # Real-time financial KPI & chart calculations
│   └── report_service.py      # CSV and JSON report generation
├── routers/                   # 🌐 API Route Controllers
│   ├── enterprises.py         # /api/enterprises (CRUD)
│   ├── customers.py           # /api/customers (CRUD + transaction history)
│   ├── suppliers.py           # /api/suppliers (CRUD + transaction history)
│   ├── transactions.py        # /api/transactions (CRUD + multi-filter)
│   ├── analytics.py           # /api/analytics (KPIs, Trends, Categories)
│   ├── reports.py             # /api/reports (CSV & JSON exports)
│   └── data_management.py     # /api/data (raw, status, seed, reset)
└── utils/                     # 🛠️ Helpers
    ├── date_helpers.py        # Financial Year, Weekly, Monthly boundaries
    └── serializers.py         # JSON serialization & custom encoders
```

---

## ⚡ Quick Start

### 1. Install Dependencies
```bash
pip install -r requirements.txt
```

### 2. Run the Server
```bash
python run_server.py
```
Or with `uvicorn` directly:
```bash
uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```

### 3. Interactive API Documentation
- **Swagger UI**: [`http://127.0.0.1:8000/docs`](http://127.0.0.1:8000/docs)
- **ReDoc**: [`http://127.0.0.1:8000/redoc`](http://127.0.0.1:8000/redoc)
- **OpenAPI JSON**: [`http://127.0.0.1:8000/openapi.json`](http://127.0.0.1:8000/openapi.json)

---

## 🧪 Run Automated Tests
```bash
python test_server.py
```

---

## 📊 API Endpoints Reference

### 1. Enterprises (`/api/enterprises`)
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/enterprises` | List all enterprises |
| `GET` | `/api/enterprises/{id}` | Get enterprise details |
| `POST` | `/api/enterprises` | Create new enterprise |
| `PUT` | `/api/enterprises/{id}` | Update enterprise |
| `DELETE` | `/api/enterprises/{id}` | Delete enterprise |

### 2. Customers (`/api/customers`)
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/customers` | List all customers with balances |
| `GET` | `/api/customers/{id}` | Get customer by ID |
| `GET` | `/api/customers/{id}/transactions` | Get transactions for customer |
| `POST` | `/api/customers` | Create customer |
| `PUT` | `/api/customers/{id}` | Update customer |
| `DELETE` | `/api/customers/{id}` | Delete customer |

### 3. Suppliers (`/api/suppliers`)
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/suppliers` | List all suppliers with payables |
| `GET` | `/api/suppliers/{id}` | Get supplier by ID |
| `GET` | `/api/suppliers/{id}/transactions` | Get transactions for supplier |
| `POST` | `/api/suppliers` | Create supplier |
| `PUT` | `/api/suppliers/{id}` | Update supplier |
| `DELETE` | `/api/suppliers/{id}` | Delete supplier |

### 4. Transactions (`/api/transactions`)
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/transactions` | Query transactions with filters (`profile`, `filter_option`, `category`, `search`, `drill_down_type`) |
| `GET` | `/api/transactions/{id}` | Get transaction by ID |
| `POST` | `/api/transactions` | Create transaction & auto-sync balances |
| `PUT` | `/api/transactions/{id}` | Update transaction |
| `DELETE` | `/api/transactions/{id}` | Delete transaction |

### 5. Analytics (`/api/analytics`)
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/analytics/kpi` | Revenue, Expense, Net Profit, Receivables, Payables, GST, EMI |
| `GET` | `/api/analytics/daily-trend` | Daily trend points for chart rendering |
| `GET` | `/api/analytics/categories` | Category breakdown percentages & totals |

### 6. Reports (`/api/reports`)
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/reports/csv` | Download CSV transaction statement |
| `GET` | `/api/reports/json` | Full structured JSON financial report |
| `GET` | `/api/reports/categories` | Predefined category taxonomy |
| `GET` | `/api/reports/profiles` | Supported user profile types |

### 7. Database Store Management (`/api/data`)
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/data/status` | Storage health, file size, item counts |
| `GET` | `/api/data/raw` | Full raw JSON database document |
| `POST` | `/api/data/seed` | Repopulate default sample data |
| `POST` | `/api/data/reset` | Clear all data entries |
