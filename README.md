# PocketLedger — Offline Personal Finance Manager

An offline-first, privacy-focused personal finance Android application built with **Flutter**, **Provider**, and **SQLite**. Designed as a production-grade portfolio project with clean architecture, zero cloud dependencies, and mathematically precise money calculations.

---

## 🌟 Key Features

- **Multi-Account Management**: Track balances across Cash, Bank Accounts, and Digital Wallets.
- **Integer Paise Architecture**: Stores and calculates all amounts in integer paise (1 INR = 100 paise), eliminating IEEE-754 floating-point rounding errors.
- **Atomic Double-Entry Transfers**: Inter-account transfers insert and update linked debit/credit pairs atomically via SQLite transactions without inflating income or expense totals.
- **Monthly Category Budgets**: Visual budget progress with clamped indicators [0%..100%], early warning states (>=80%), and one-tap copy from previous months.
- **Spending Analytics & Insights**: Interactive Donut chart for category distributions, Bar chart for daily expenditure spikes, and month-over-month cash flow comparisons with division-by-zero protection.
- **Real-Time Search & Filtering**: Instant full-text search across notes, category names, and accounts with multi-criteria filters (Type, Account, Category, Sort order).
- **Secure CSV Export**: Exports transaction logs to RFC-4180 CSV with built-in defenses against CSV Formula Injection (CWE-1236).
- **Theme Customization**: Native Material 3 theming supporting System, Light, and Dark modes persisted locally in SQLite.
- **Zero Cloud & Strictly Offline**: No login, no Firebase, no tracking, and no external API calls. Your financial data never leaves your device.

---

## 🛠️ Technology Stack

| Component | Technology | Rationale |
| :--- | :--- | :--- |
| **Framework** | Flutter (Dart 3.x) | High-performance, cross-platform UI framework with native canvas rendering. |
| **State Management** | `provider` (`ChangeNotifier`) | Lightweight, readable, and predictable state orchestration across decoupled screens. |
| **Local Database** | `sqflite` (SQLite) | Embedded, zero-configuration relational database with ACID guarantees and foreign keys. |
| **Charts & Visuals** | `fl_chart` | Interactive, customizable vector charts for financial trends and breakdowns. |
| **Data Sharing** | `share_plus` & `path_provider` | Native Android share sheet integration for CSV report export. |
| **Date & Currency** | `intl` | Standardized Indian Rupee (INR / ₹) number grouping and calendar math. |

---

## 🚀 Getting Started & Running the Project

### Prerequisites
- Flutter SDK (3.22+ recommended)
- Android Studio / Android SDK (Platform 34+, Android 8.0+ device or emulator)
- Java 17 or 21

### Run Locally
```bash
# 1. Clone repository and navigate to project root
cd PocketLedger

# 2. Install dependencies
flutter pub get

# 3. Analyze code quality
flutter analyze

# 4. Run automated test suite
flutter test

# 5. Launch on connected Android device or emulator
flutter run
```

### Standalone Logic Verification (Pure Dart)
To verify financial arithmetic, transfer invariants, budget clamping, and security logic without a Flutter installation:
```bash
dart run test/run_all_unit_verifications.dart
```

---

## 📖 In-Depth Project Documentation

Detailed technical documentation is provided in the [`docs/`](file:///c:/documentsOfMine/PocketLedger/docs/) directory:

- [**Code Walkthrough & Architecture Guide**](file:///c:/documentsOfMine/PocketLedger/docs/CODE_WALKTHROUGH.md) — File structure, app startup, button-to-database data flow, `setState` vs `Provider`, integer paise architecture, schema design, and step-by-step tutorial on adding new fields.
- [**QA Coverage Matrix**](file:///c:/documentsOfMine/PocketLedger/docs/QA_COVERAGE_MATRIX.md) — Comprehensive feature matrix covering entry points, expected behaviors, automated tests, and validation results.
- [**QA & Code Review Report**](file:///c:/documentsOfMine/PocketLedger/docs/QA_REPORT.md) — Senior engineer code review findings, defect remediations (PopScope infinite loops, transfer hydration, date boundaries, formula injection), and test results.
- [**Manual QA Protocol**](file:///c:/documentsOfMine/PocketLedger/docs/MANUAL_QA.md) — 14 step-by-step test cases for physical devices and emulators with setup and teardown instructions.

---

## 🔒 Security & Edge Case Defenses

- **CWE-1236 Formula Injection**: User notes starting with `=`, `+`, `-`, `@`, `\t`, or `\r` (even after whitespace) are automatically escaped with a leading `'` before CSV generation.
- **Referential Integrity**: Account deletions are guarded by SQLite query checks; accounts with existing transactions cannot be deleted. Categories with transactions or budgets are safely archived rather than deleted.
- **Safe Date Querying**: All monthly queries use strict half-open intervals (`>= startOfMonth AND < startOfNextMonth`), preventing microsecond omission bugs on month boundaries.

---

## 📌 Project Limitations & Non-Goals

1. **Single Currency**: Currently restricted to Indian Rupee (INR / ₹). Multi-currency conversion is outside the scope of this personal ledger.
2. **Offline Only**: No cloud synchronization, user authentication, or backend servers.
3. **No Code Generation**: Uses pure Dart classes and SQL strings rather than heavy code-generation libraries (e.g. Drift/Freezed), ensuring complete readability and beginner-friendly maintainability.
