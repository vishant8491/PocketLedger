# PocketLedger Manual QA Protocol

This protocol provides manual testing instructions for physical Android devices and emulators.

---

## 1. Setup & Initial Environment Preparation

1. **Prerequisites**:
   - Android Device or Android Emulator running Android 8.0 (API Level 26) or newer.
   - APK installed via `flutter run --release` or `adb install app-release.apk`.
2. **Clean State Guarantee**:
   - Go to Android Settings -> Apps -> PocketLedger -> Storage -> Clear Storage & Cache.
   - Launch PocketLedger.

---

## 2. Test Cases & Execution Steps

### TC-01: Onboarding Choice - Explore Demo
- **Purpose**: Verify demo seeding creates consistent sample data across 3 full months.
- **Steps**:
  1. Launch app on clean install. Verify `OnboardingScreen` appears with two cards: "Start Empty" and "Explore Demo".
  2. Tap **Explore Demo**.
- **Expected Result**:
  - App transitions to `HomeScreen` (Dashboard tab).
  - Total Net Worth displays a non-zero positive sum in Indian Rupees (e.g., `₹ 1,24,500`).
  - Income, Expenses, and Net Savings cards show populated values for the current month.
  - Recent transactions list displays at least 5 populated items.
  - Restarting the app does NOT show the onboarding screen again.

### TC-02: Onboarding Choice - Start Empty
- **Purpose**: Verify clean initialization without demo records.
- **Steps**:
  1. Clear app data and launch app.
  2. Tap **Start Empty**.
- **Expected Result**:
  - Dashboard displays Total Net Worth: `₹ 0`.
  - Default accounts "Cash" and "Primary Bank" exist with ₹0 balances.
  - Transactions list displays `EmptyStateView` with message "No Transactions Yet".
  - Budgets and Insights tabs show empty states.

### TC-03: Create & Validate Accounts
- **Purpose**: Ensure all account types can be created and opening balances calculate properly.
- **Steps**:
  1. From Dashboard, tap **Accounts** (top card or via Settings).
  2. Tap the floating action button (**+**).
  3. Enter Account Name: `HDFC Salary Bank`.
  4. Select Type: `Bank`.
  5. Enter Opening Balance: `10000` (₹10,000).
  6. Tap **Save Account**.
- **Expected Result**:
  - Modal dismisses.
  - New account card appears with Bank icon and balance `₹ 10,000`.
  - Total Net Worth at the top increases by `₹ 10,000`.

### TC-04: Prevent Deletion of Referenced Accounts
- **Purpose**: Ensure referential integrity is preserved.
- **Steps**:
  1. Record an expense of ₹500 from `HDFC Salary Bank`.
  2. Tap on `HDFC Salary Bank` to open `AccountDetailScreen`.
  3. Tap the top-right menu (three dots) -> **Delete Account**.
- **Expected Result**:
  - Alert dialog appears: *"Cannot Delete Account: This account contains active transactions. Transfer or delete them before removing this account."*
  - Account is NOT deleted.
  - Database references remain completely intact.

### TC-05: Record Income & Expense Transactions
- **Purpose**: Verify input validation and aggregate calculation.
- **Steps**:
  1. Tap the bottom **+** FAB to open `TransactionFormScreen`.
  2. Leave amount blank and tap **Save Transaction**.
     - *Expected*: Error banner displays: *"Enter a valid amount greater than ₹0"*.
  3. Enter Amount: `5000` (₹5,000).
  4. Select Type: `Income`.
  5. Select Account: `HDFC Salary Bank`.
  6. Select Category: `Salary`.
  7. Tap **Save Transaction**.
  8. Repeat for Expense: Amount `1500` (₹1,500), Category `Groceries`, Account `HDFC Salary Bank`.
- **Expected Result**:
  - Income card reflects +₹5,000.
  - Expense card reflects +₹1,500.
  - Net Savings shows +₹3,500 in green emerald text.
  - Account balance shows `₹ 13,500` (`10000 + 5000 - 1500`).

### TC-06: Atomic Transfers & Invariant Balance
- **Purpose**: Verify transfer isolation from income/expense and atomic balance transfer.
- **Steps**:
  1. Create a second account: `Wallet Cash`, opening balance `₹ 2,000`.
  2. Open Transaction Form. Select Type: **Transfer**.
  3. Verify Source Account: `HDFC Salary Bank`.
  4. Select Destination Account: `Wallet Cash`.
  5. Enter Amount: `3000` (₹3,000).
  6. Tap **Save Transaction**.
- **Expected Result**:
  - `HDFC Salary Bank` balance reduces to `₹ 10,500` (`13500 - 3000`).
  - `Wallet Cash` balance increases to `₹ 5,000` (`2000 + 3000`).
  - Total Net Worth across accounts remains unchanged at `₹ 15,500` (`10500 + 5000`).
  - Dashboard Monthly Income remains `₹ 5,000` (Transfer NOT added).
  - Dashboard Monthly Expense remains `₹ 1,500` (Transfer NOT added).

### TC-07: Unsaved Changes Back Navigation (PopScope)
- **Purpose**: Verify user is alerted before losing entered data without infinite pop loops.
- **Steps**:
  1. Tap FAB (+) to open Transaction Form.
  2. Type Amount `999` and Note `Test draft`.
  3. Tap the Android system back button or top-left back arrow.
- **Expected Result**:
  - Dialog appears: *"Discard Changes? You have unsaved changes in this transaction. Do you want to discard them?"*
  - Tap **Keep Editing**: Dialog closes, user remains on form with inputs preserved.
  - Tap back again -> Tap **Discard**: Form dismisses cleanly to the previous screen.

### TC-08: Budget Limit Clamping & Warnings
- **Purpose**: Verify progress bar stays within [0.0, 1.0] and warning colors trigger accurately.
- **Steps**:
  1. Go to **Budgets** tab.
  2. Tap FAB (+). Select Category: `Groceries`, Limit: `2000` (₹2,000). Save.
  3. Note that current spending is ₹1,500.
     - *Expected*: Progress bar shows `75%` spent in amber warning color (`remaining: ₹500`).
  4. Record an additional expense of `₹ 1,000` in `Groceries` (Total spent: ₹2,500).
  5. Return to Budgets tab.
- **Expected Result**:
  - Status changes to bold red: *"₹ 500 over budget"*.
  - Progress bar is fully filled at 100% (never overflows UI boundaries).
  - Dashboard displays an alert banner under Budget Warnings.

### TC-09: Copy Budgets from Previous Month
- **Purpose**: Test bulk duplication without violating unique database constraints.
- **Steps**:
  1. On Budgets tab, use the month selector to navigate to next month (e.g., November).
  2. Verify list is empty.
  3. Tap **Copy from Previous Month**.
- **Expected Result**:
  - Toast / SnackBar displays: *"Successfully copied X budget(s) from previous month"*.
  - `Groceries` budget is duplicated with ₹2,000 limit and ₹0 spent.
  - Tapping "Copy from Previous Month" again does NOT create duplicate records (0 duplicate inserts).

### TC-10: Search, Filtering, and Sorting
- **Purpose**: Ensure real-time filtering updates transactions without stale data.
- **Steps**:
  1. Go to **Transactions** tab.
  2. Type "Groceries" into the search bar.
     - *Expected*: Only Groceries transactions are listed. Daily headers recalculate to match visible rows.
  3. Clear the search text by tapping (X).
     - *Expected*: All transactions return.
  4. Tap Filter icon: Select Type -> `Expense only`.
     - *Expected*: Income and Transfers are hidden.
  5. Select Sort -> `Amount: High to Low`.
     - *Expected*: Highest expense appears at the top.

### TC-11: Insights & Charts Division-by-Zero Safety
- **Purpose**: Verify charts do not crash when income or expenses are zero.
- **Steps**:
  1. Navigate to a future month with no transactions (e.g., December).
  2. Tap **Insights** tab.
- **Expected Result**:
  - Friendly empty state displays: *"No Spending Data Yet: Record expenses or income for this month to generate analytical breakdowns"*.
  - No crash, no red screen of death (`NaN` or `Infinity`).

### TC-12: CSV Export & Formula Injection Prevention
- **Purpose**: Test data portability and spreadsheet security.
- **Steps**:
  1. Record a transaction with Note: `=cmd|' /C calc'!A0`.
  2. Go to **Settings** -> Tap **Export Transactions (CSV)**.
  3. Share to Google Drive or save locally.
  4. Open the CSV file in a text editor or spreadsheet app.
- **Expected Result**:
  - The note column contains: `"'=cmd|' /C calc'!A0"` (prefixed with `'`).
  - Spreadsheet software treats the cell as literal text rather than executing a formula.
  - Amounts and dates format consistently.

### TC-13: Theme Persistence
- **Purpose**: Verify theme toggle works dynamically and persists across app restarts.
- **Steps**:
  1. Go to **Settings** -> Select Theme Mode: **Dark Mode**.
  2. Verify all screens immediately transition to high-contrast dark theme.
  3. Force-close PocketLedger from the Android Recent Apps switcher.
  4. Relaunch PocketLedger.
- **Expected Result**:
  - App launches directly into Dark Mode without flashing white.

### TC-14: Factory Reset (Clear All Data)
- **Purpose**: Verify complete local database cleanup.
- **Steps**:
  1. Go to **Settings** -> Tap **Clear All Data**.
  2. Tap "Proceed" on the first confirmation warning dialog.
  3. Tap "Erase Everything" on the second destructive warning dialog.
- **Expected Result**:
  - App clears SQLite tables (`accounts`, `categories`, `transactions`, `budgets`, `app_preferences`).
  - App navigates back to `OnboardingScreen`.
  - Selecting "Start Empty" confirms 0 leftover records.

---

## 3. Physical Device Specific Checks

| Check | Tool / Requirement | Expected Behavior |
| :--- | :--- | :--- |
| **Android Share Sheet** | Physical Android Phone | Tapping "Export CSV" opens native Android intent chooser (Gmail, Drive, WhatsApp, Files). Dismissing the share sheet returns cleanly to PocketLedger without crashing. |
| **Keyboard Avoidance** | Physical Small Phone (< 5.5") | Opening the numeric keyboard in `TransactionFormScreen` scrolls form fields automatically; Save button remains accessible without overflow warnings. |
| **System Font Scaling** | Android Accessibility -> Font Size: Largest | Text scales gracefully without clipping transaction amounts or card titles. |
