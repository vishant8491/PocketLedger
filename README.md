# PocketLedger — Offline Personal Finance Manager

An offline-first, privacy-focused personal finance manager built with **Flutter**, **Provider**, and **SQLite**. Designed as a production-grade portfolio project with clean architecture, zero cloud dependencies, mathematically precise money calculations, and native support for both **Android** and **Modern Mobile Web**.

---

## 🌟 Key Features

- **Multi-Account Management**: Track balances across Cash, Bank Accounts, and Digital Wallets.
- **Integer Paise Architecture**: Stores and calculates all amounts in integer paise (1 INR = 100 paise), eliminating IEEE-754 floating-point rounding errors.
- **Atomic Double-Entry Transfers**: Inter-account transfers insert and update linked debit/credit pairs atomically via SQLite transactions without inflating income or expense totals.
- **Monthly Category Budgets**: Visual budget progress with clamped indicators [0%..100%], early warning states (>=80%), and one-tap copy from previous months.
- **Spending Analytics & Insights**: Interactive Donut chart for category distributions, Bar chart for daily expenditure spikes, and month-over-month cash flow comparisons with division-by-zero protection.
- **Real-Time Search & Filtering**: Instant full-text search across notes, category names, and accounts with multi-criteria filters (Type, Account, Category, Sort order).
- **Secure CSV Export**: Exports transaction logs to RFC-4180 CSV with built-in defenses against CSV Formula Injection (CWE-1236). Triggers the Android Share Sheet on mobile and direct Blob download on Web.
- **Theme Customization**: Native Material 3 theming supporting System, Light, and Dark modes persisted locally in SQLite.
- **Zero Cloud & Strictly Offline**: No login, no Firebase, no tracking, and no external API calls. Your financial data never leaves your device or browser.
- **Cross-Platform Storage**: Uses native SQLite on Android and persistent IndexedDB-backed WASM SQLite (`sqflite_common_ffi_web`) on Web.

---

## 🛠️ Technology Stack

| Component | Technology | Rationale |
| :--- | :--- | :--- |
| **Framework** | Flutter (Dart 3.x) | High-performance, cross-platform UI framework with native canvas and WebAssembly/CanvasKit rendering. |
| **State Management** | `provider` (`ChangeNotifier`) | Lightweight, readable, and predictable state orchestration across decoupled screens. |
| **Android Database** | `sqflite` (SQLite) | Embedded, zero-configuration relational database with ACID guarantees and foreign keys. |
| **Web Database** | `sqflite_common_ffi_web` | SQLite 3.x compiled to WebAssembly (`sqlite3.wasm`) running inside a Web Worker and persisted to browser IndexedDB. |
| **Charts & Visuals** | `fl_chart` | Interactive, customizable vector charts for financial trends and breakdowns. |
| **Data Sharing** | `share_plus` & `path_provider` | Native Android share sheet on mobile; direct browser download fallback on Web. |
| **Date & Currency** | `intl` | Standardized Indian Rupee (INR / ₹) number grouping and calendar math. |

---

## 🚀 Getting Started & Running the Project

### Prerequisites
- **Flutter SDK**: 3.22+ (tested on Flutter 3.47 / Dart 3.13)
- **Android Studio / Android SDK**: Platform 34/35+ (Android 8.0+ device or emulator)
- **Java**: OpenJDK 17 or 21+

### 1. Web Setup & Run
PocketLedger runs in any modern mobile or desktop web browser with persistent local storage.
```bash
# 1. Install dependencies
flutter pub get

# 2. Setup Web SQLite WASM & worker assets (creates sqlite3.wasm & sqflite_sw.js in web/)
dart run sqflite_common_ffi_web:setup

# 3. Launch in Chrome
flutter run -d chrome

# 4. Build optimized Web release
flutter build web --release
```

### 2. Android Setup & Build
The Android configuration is fully migrated to modern declarative Gradle Kotlin DSL (`.kts`), Android Gradle Plugin 9.1.0, and Gradle 9.3.1.
```bash
# 1. Check code quality
flutter analyze

# 2. Run automated test suite
flutter test

# 3. Build Android debug APK
flutter build apk --debug
```

### 3. Standalone Logic Verification (Pure Dart)
To verify financial arithmetic, transfer invariants, budget clamping, and security logic without a Flutter installation:
```bash
dart run test/run_all_unit_verifications.dart
```

---

## 🌐 Web Storage & Privacy Notice

- **Local Persistence**: On Web, SQLite data is stored locally in the browser's IndexedDB. Refreshing or reopening the browser preserves your ledger.
- **Separate Data**: Browser data is 100% separate from Android device data. There is no cloud sync or backend service.
- **Site Data Clearing**: Clearing browser site data or cookies removes the local web ledger.
- **Private Browsing**: Incognito or private browsing modes may restrict persistent storage across sessions.
- **No Cross-Device Sync**: As an offline-first app, data does not sync between multiple devices or browsers.

---

## 📖 In-Depth Project Documentation

Detailed technical documentation is provided in the [`docs/`](docs/) directory:

- [**Web Verification & Platform Report**](docs/WEB_VERIFICATION.md) — Comprehensive report of web database architecture, CSV export, responsive design, and automated test results.
- [**Code Walkthrough & Architecture Guide**](docs/CODE_WALKTHROUGH.md) — File structure, app startup, button-to-database data flow, `setState` vs `Provider`, integer paise architecture, schema design, and tutorial on adding new fields.
- [**QA Coverage Matrix**](docs/QA_COVERAGE_MATRIX.md) — Comprehensive feature matrix covering entry points, expected behaviors, automated tests, and validation results.
- [**QA & Code Review Report**](docs/QA_REPORT.md) — Senior engineer code review findings, defect remediations, and test results.
- [**Manual QA Protocol**](docs/MANUAL_QA.md) — Step-by-step test cases for physical devices and emulators.

---

## 🔒 Security & Edge Case Defenses

- **CWE-1236 Formula Injection**: User notes starting with `=`, `+`, `-`, `@`, `\t`, or `\r` (even after whitespace) are automatically escaped with a leading `'` before CSV generation.
- **Referential Integrity**: Account deletions are guarded by SQLite query checks; accounts with existing transactions cannot be deleted. Categories with transactions or budgets are safely archived rather than deleted.
- **Safe Date Querying**: All monthly queries use strict half-open intervals (`>= startOfMonth AND < startOfNextMonth`), preventing microsecond omission bugs on month boundaries.

---

## 📌 Project Limitations & Non-Goals

1. **Single Currency**: Currently restricted to Indian Rupee (INR / ₹). Multi-currency conversion is outside the scope of this personal ledger.
2. **Offline Only**: No cloud synchronization, user authentication, or backend servers.
3. **No Code Generation**: Uses pure Dart classes and SQL strings rather than heavy code-generation libraries (e.g. Drift/Freezed), ensuring complete readability and maintainability.
