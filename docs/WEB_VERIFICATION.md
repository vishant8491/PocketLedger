# PocketLedger Web Verification & Platform Architecture Report

## 1. Executive Summary
PocketLedger has been adapted for modern Flutter Web execution without modifying or degrading the existing Android SQLite architecture, data integrity, or financial calculation rules. The platform differences are isolated behind clean conditional facades (`database_init_helper.dart` and `csv_export_helper.dart`).

---

## 2. Platform Architecture & Separation

### 2.1 Storage & Persistence
- **Android**: Continues to use native SQLite via `sqflite` with parameterized queries and atomic transfer transactions inside `getDatabasesPath()`.
- **Web**: Uses `sqflite_common_ffi_web` backed by `sqlite3.wasm` and `sqflite_sw.js` (Web Worker). All database operations persist directly into the browser's **IndexedDB** virtual file system under the `pocket_ledger.db` key.
- **Data Isolation**: Browser data is 100% separate from Android device data. There is no cloud sync or backend; data is strictly local to the user's browser.
- **Browser Storage Restrictions**: 
  - Clearing browser site data / cookies removes the local IndexedDB database.
  - Private / Incognito windows may restrict IndexedDB persistence across sessions depending on the browser vendor.
  - The application provides a persistent error notice card with a retry option if browser storage initialization is restricted.

### 2.2 CSV Export & Sharing
- **Android**: Exports RFC-4180 compliant CSV to a cached file using `path_provider` and opens the native Android Share Sheet via `SharePlus`.
- **Web**: `dart:io` and `path_provider` are bypassed using conditional imports. On web, CSV data is encoded as an in-memory `XFile.fromData` and shared via `navigator.share` (when supported), with an automatic fallback that triggers a direct browser blob download anchor (`text/csv;charset=utf-8`).

### 2.3 UI & Mobile-First Responsiveness
- **Layout**: Fluid layout responsive across 360–430px logical pixel widths (standard Android/iOS mobile viewports) up to desktop resolutions.
- **Top Bar Actions**: Resolved the previous UI overlap where the Settings FAB was rendered over the Dashboard's Manage Accounts action icon. Both actions are now unified in standard Material `AppBar.actions` with consistent spacing and touch target sizing.
- **Branding**: Configured `web/index.html` and `web/manifest.json` with "PocketLedger - Personal Finance", emerald and navy color branding, and PWA standalone configuration.

---

## 3. Executed Automated Checks

| Test Suite | Command | Result | Details |
|---|---|---|---|
| **Unit & Widget Tests** | `flutter test` | **PASS (20/20)** | Verified money arithmetic, currency formatting, half-open date boundaries, budget calculations, transfers exclusion, and transaction form validation. |
| **Standalone Logic Fixtures** | `dart test/run_all_unit_verifications.dart` | **PASS (9/9)** | Verified paise precision, Indian numbering format, balance calculation, CSV formula injection defense, and 99 Crore boundary. |
| **Code Analysis** | `flutter analyze` | **PASS (0 errors)** | Zero syntax, typing, or compilation errors across native and web source code. |
| **Release Web Compilation** | `flutter build web --release` | **PASS (Exit 0)** | Compiled release JavaScript bundle in `build/web` with wasm dry run pass and icon tree shaking. |
| **Asset HTTP Probe** | Python HTTP Server Probe | **PASS (All 200)** | Verified `/index.html`, `/manifest.json`, `/sqflite_sw.js`, `/sqlite3.wasm`, `/main.dart.js`, and `/flutter_bootstrap.js` load successfully with valid headers. |
| **Android APK Build** | `flutter build apk --debug` | **PASS (Exit 0)** | Built `app-debug.apk` with AGP 9.1.0, Gradle 9.3.1, Kotlin 2.4.0, and SDK 35. |

---

## 4. Manual Web Verification Workflow Checklist

When previewing or testing the web demo in a browser:

1. **First Launch (Start Empty / Demo)**:
   - Launch `build/web`. Verify the Onboarding screen displays "Start Empty" and "Explore Demo" options.
   - Choose "Explore Demo" to seed 3 months of synthetic data, or "Start Empty" to configure fresh accounts.
2. **Account Management**:
   - Navigate to Accounts (via Dashboard top-right icon).
   - Create a Cash and Bank account with initial opening balances.
3. **Transaction Entry & Balances**:
   - Add an Expense transaction (e.g. ₹500 for Dining).
   - Add an Income transaction (e.g. ₹50,000 for Salary).
   - Add a Transfer between accounts. Verify net worth excludes transfers while individual account balances update atomically.
4. **Persistence Test**:
   - Hard-refresh the browser tab (F5 / Ctrl+R / Cmd+R).
   - Confirm that the database re-opens from IndexedDB with all accounts, transactions, and balances intact.
5. **Budget Monitoring**:
   - Set a monthly budget on a category. Verify progress bar and alert thresholds (80% warning / 100% exceeded).
6. **CSV Export**:
   - Open Settings -> Export Transactions (CSV).
   - Verify the browser downloads `PocketLedger_Export_<timestamp>.csv` or opens the Web Share dialog.
   - Inspect the CSV file in a text editor to confirm formula injection defense (`'` prefix on formula triggers) and RFC-4180 quotes.
7. **Theme Persistence**:
   - Switch between System, Light, and Dark themes. Refresh browser and verify theme selection persists.
8. **Factory Reset**:
   - Go to Settings -> Clear All Data.
   - Confirm double-prompt dialog. Verify database is purged and app resets to Onboarding cleanly.
