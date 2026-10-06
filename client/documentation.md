# ENX Money - Flutter Expense Tracker

Welcome to the **ENX Money** repository! This is a comprehensive, fully functional Flutter application for tracking expenses across both Business and Personal profiles.

This repository is optimized for GitHub (under 1 MB). The heavy `build/` and `.dart_tool/` directories have been intentionally removed so you can easily upload and share this code.

## 🚀 How to Run the Project

Since this is a clean repository, you will need to download the Flutter dependencies before running it for the first time.

1. **Clone the repository or download the folder.**
2. **Open a terminal** inside the project folder.
3. **Fetch packages** by running:
   ```bash
   flutter pub get
   ```
   *(This will automatically recreate the `.dart_tool` cache specifically for your computer.)*
4. **Run the app** on your desired device/emulator:
   ```bash
   flutter run
   ```

## ✨ Key Features

* **Multi-Profile System**: Easily switch between **Business Profile** (Enterprises, Customers, Suppliers) and **Personal Profile** (Personal Expense Management). Data is securely isolated between profiles.
* **Interactive Dashboard**: A beautiful, gradient-styled dashboard displaying key performance indicators (KPIs) like Total Revenue, Expenses, Net Profit, and Tax Payables.
* **Empty States & Clean Data**: No forced demo data! All sections start completely empty, allowing you to add your real data right from the start.
* **Beautiful Analytics**: See your money visually with interactive Trend Lines, Bar Charts, and Category Pie Charts.
* **Export Options**: Fully working capability to export your financial data and reports to both **PDF** and **Excel** formats!
* **Modern UI/UX**: Custom themed with the official ENX Money logo, deep navy, and electric blue gradient styling. Fully supports both Light and Dark modes.

## 📂 Project Structure

```text
lib/
├── core/
│   ├── theme/           # App styling, ENX brand colors (Navy & Blue), and fonts
│   └── utils/           # Helper classes for PDF and Excel generation
├── domain/
│   ├── models/          # Data models (Transactions, Customers, KPIs, etc.)
│   └── repositories/    # Provider State Management (TransactionRepository)
├── ui/
│   ├── core/            # Reusable widgets (Sidebar, EmptyState, KpiCard, DateFilter)
│   └── features/
│       ├── analytics/   # Charts and trends
│       ├── dashboard/   # Main KPI and recent transaction view
│       ├── entities/    # Customer, Enterprise, and Supplier management views
│       ├── custom_reports/ # Report Builder
│       └── transactions/# Add/edit transaction dialogs and ledgers
└── main.dart            # Application entry point and Navigation layout
```

## 🛠️ Technology Stack
* **Framework**: Flutter / Dart
* **State Management**: `provider` (Single `ChangeNotifier` pattern via `TransactionRepository`)
* **Charting**: `fl_chart`
* **Exporting**: `pdf`, `printing`, `share_plus`

---
*Created for ENX Money.*
