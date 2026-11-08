# PUKU.md — রজব ভূমি সেবা ঘর
## Shared Project Memory & Engineering Instructions

> **This is the single authoritative engineering reference for all agents, developers, and AI team members.**
> Every specialist must read and comply with this document before writing any code or making any decisions.
> When in doubt, consult this document. When this document conflicts with any other file, this document wins (unless explicitly overridden by the Team Leader).

---

## 1. Project Overview

**Application Name:** রজব ভূমি সেবা ঘর (Rojob Bhumi Seba Ghor)
**Package Name:** `bhumi_kajer_hisab`
**Version:** 1.0.0+1
**Platform:** Android (Flutter/Dart)
**Target User:** A local land services professional in Bangladesh managing customer applications, government filings, finances, and tasks from a physical shop.
**Developer:** Md Mim Shifat (mimshifat5@gmail.com)

**Business Purpose:**
The application tracks:
- Land service applications (ই-নামজারি, জমাভাগ, খতিয়ান সংশোধন, etc.)
- Customer payments and due tracking
- Step-by-step government process expenses
- Actual realized income per file
- Independent shop income (printing, photocopying, deed typing)
- General shop overhead expenses
- Tasks and hearing reminders
- Document storage per application

---

## 2. Confirmed Application Requirements

### 2.1 Non-Negotiable Platform Constraints
- **Flutter + Dart only.** No other languages in the application layer.
- **Android application.** iOS, Web, Desktop are out of scope.
- **Fully offline.** No network calls, no REST API, no WebSocket, no server-side logic.
- **Single user, single device.** No multi-user, no multi-device sync.
- **Existing frontend UI must be preserved.** Do not redesign, remove, or restructure existing screens.

### 2.2 Non-Negotiable Backend Constraints
- **SQLite only** (via Drift ORM). No Firebase, Supabase, Realm, Hive, or any cloud database.
- **No cloud synchronization now or ever.** Telegram backup is optional and must be fully independent.
- **All data stays on the device.** No external data transmission except optional Telegram backup.

---

## 3. Confirmed Architecture

### 3.1 Technology Stack (Confirmed)
| Concern | Choice | Status |
|---|---|---|
| **State Management** | Riverpod v2 (flutter_riverpod ^2.5.1) | In pubspec.yaml — USE THIS |
| **Routing** | GoRouter (go_router ^14.2.0) | In pubspec.yaml — integrate when connecting UI |
| **Database** | Drift (SQLite ORM) | Planned — NOT yet in pubspec.yaml |
| **Charts** | fl_chart ^0.68.0 | In pubspec.yaml |
| **File Picking** | file_picker ^8.0.5 | In pubspec.yaml |
| **Internationalization** | intl ^0.20.2 | In pubspec.yaml |
| **UUID** | uuid ^4.4.0 | In pubspec.yaml |
| **Bengali Font** | Bundled Noto Sans Bengali | In assets/fonts/ |

### 3.2 Packages Requiring Addition (Phase 1)
These packages are documented in `docs/PROJECT_PLAN.md` as planned but are **not yet in pubspec.yaml**:
- `drift` + `drift_flutter` — SQLite ORM
- `sqlite3_flutter_libs` — Native SQLite
- `path_provider` + `path` — File paths
- `flutter_local_notifications` — Task reminders
- `flutter_secure_storage` — Secure key storage (Telegram token, encryption key)
- `encrypt` — AES-256 backup encryption

> **IMPORTANT:** Do not add packages until the Flutter Architect approves and the Team Leader assigns the task. Add packages one phase at a time. Do not add all at once.

### 3.3 Project Structure (Confirmed Feature-Based Architecture)
```
lib/
├── main.dart               — Entry point (ProviderScope)
├── app.dart                — MaterialApp with Bengali locale
├── core/
│   ├── constants/          — Colors, Typography, Spacing, Strings
│   ├── theme/              — AppTheme
│   ├── utils/              — Money class, BengaliDigits, validators, extensions
│   ├── demo/               — Demo data (to be replaced by real database layer)
│   └── widgets/            — Shared reusable widgets
├── features/
│   ├── dashboard/          — DashboardScreen
│   ├── applications/       — Application CRUD, Status, Detail
│   ├── persons/            — Person management
│   ├── references/         — Reference person management
│   ├── offices/            — Office management
│   ├── finance/            — Payments, Income, Expenses, Reports
│   ├── tasks/              — Task & Reminder management
│   ├── documents/          — Document attachment & viewer
│   ├── reports/            — Analytics & Business Intelligence
│   ├── backup/             — Backup & Restore
│   └── settings/           — Category management, Shop profile
```

Each feature follows the pattern:
```
features/<feature>/
├── data/
│   ├── models/             — Dart model classes
│   └── daos/               — Drift DAOs (database access objects)
├── presentation/
│   ├── screens/            — Flutter screens
│   └── widgets/            — Feature-specific widgets
└── providers/              — Riverpod providers
```

---

## 4. Existing UI Preservation Rules

> **CRITICAL: These rules are absolute. No exceptions.**

1. **Never delete, rename, or restructure existing screen files** in `lib/features/*/presentation/screens/`.
2. **Never delete, rename, or restructure existing widget files** in `lib/core/widgets/` or `lib/features/*/presentation/widgets/`.
3. **Never modify existing UI layout, colors, fonts, or spacing.**
4. **The existing `demo_data.dart` models define the UI contract.** The database models must match the data shape that the UI already consumes.
5. **Replace demo data with real data by adding providers** — not by modifying screen code, unless the screen explicitly needs wiring to a provider.
6. **The 5-tab navigation structure is fixed:** Dashboard → Applications → Finance → Analytics → Menu.
7. **Bengali text and formatting are fixed.** Do not change user-facing strings.
8. **Color system is fixed.** `AppColors` values must not be changed.
9. **`Money` class is fixed.** Do not replace or alter it. Always use `Money.fromPaisa(int)` for database reads.

---

## 5. Database Design Rules

### 5.1 Core Principles
1. **Zero Hard Deletes.** Every table has `deleted_at INTEGER NULL`. Deletion sets this timestamp. Physical DELETE SQL is forbidden.
2. **Soft Delete Filter.** All queries for active records must include `WHERE deleted_at IS NULL`.
3. **Historical Snapshots.** The `applications` table stores `applicant_name`, `applicant_phone`, `applicant_address`, `reference_name`, and `office_name` as independent snapshot columns. These never change once recorded, even if the linked person/reference/office is deleted.
4. **UUID Primary Keys.** All primary keys are TEXT (UUID v4) for conflict-free offline operation.
5. **Integer Timestamps.** All timestamps are Unix epoch milliseconds stored as INTEGER.
6. **Foreign Key Enforcement.** `PRAGMA foreign_keys = ON` must be set on every database connection. Use `ON DELETE SET NULL` for nullable FKs (not CASCADE DELETE).
7. **WAL Mode.** `PRAGMA journal_mode = WAL` must be set for performance and backup safety.

### 5.2 Confirmed Table List
| Table | Purpose |
|---|---|
| `applications` | Core application records with snapshots |
| `persons` | Customer/applicant persons |
| `references` | Reference persons |
| `offices` | Land offices |
| `payments` | Application payment installments |
| `expenses` | Application-specific and general shop expenses |
| `independent_incomes` | Non-application income entries |
| `status_history` | Application status change log |
| `documents` | Binary document storage (BLOB) |
| `tasks` | Tasks and reminders |
| `work_types` | Customizable work type categories |
| `expense_categories` | Customizable expense categories |
| `income_categories` | Customizable independent income categories |
| `shop_settings` | Key-value store for shop profile and settings |

### 5.3 Migration Rules
1. Use Drift's built-in migration system. Never write raw migration SQL outside the Drift schema.
2. Every schema change requires a schema version increment.
3. Migrations must be tested before merging.
4. Never destroy user data in a migration.

---

## 6. Financial Business Rules

> **These rules are law. No deviation is permitted.**

### 6.1 Core Financial Separation
The system strictly separates four categories of financial activity:
1. **Application income** — Payments received from customers tied to a specific application (`payments` table). This includes installments and status-transition fee receipts.
2. **Independent income** — Non-application revenue: printing, photocopying, deed typing, computer services (`independent_incomes` table). Never mixed with application payments.
3. **Application expense** — Money spent on a specific file: government fees, field survey costs, travel, photocopying for that file (`expenses` WHERE `is_general = 0`). These reduce the file's realized income.
4. **General shop expense** — Overhead costs: rent, electricity, broadband, stationery (`expenses` WHERE `is_general = 1`). These do NOT reduce per-file income.

### 6.2 Per-Application Financial Calculations
```
agreed_amount          = Total service fee agreed with customer
total_received         = SUM(payments.amount WHERE application_id = X AND deleted_at IS NULL)
raw_due                = agreed_amount - total_received
effective_due          = is_marked_as_paid ? 0 : raw_due
application_expenses   = SUM(expenses.amount WHERE application_id = X AND is_general = 0 AND deleted_at IS NULL)
actual_realized_income = total_received - application_expenses
```

### 6.3 Global Financial Calculations
```
total_app_income         = SUM(payments.amount WHERE deleted_at IS NULL)
total_independent_income = SUM(independent_incomes.amount WHERE deleted_at IS NULL)
grand_total_income       = total_app_income + total_independent_income

total_app_expense        = SUM(expenses.amount WHERE is_general = 0 AND deleted_at IS NULL)
total_general_expense    = SUM(expenses.amount WHERE is_general = 1 AND deleted_at IS NULL)
grand_total_expense      = total_app_expense + total_general_expense

net_business_income      = grand_total_income - grand_total_expense
total_outstanding_due    = SUM(effective_due) WHERE is_marked_as_paid = 0 AND raw_due > 0
```

### 6.4 Accounting Principles
1. **Cash-basis only.** `agreed_amount` is never counted as revenue. Only money actually received counts.
2. **Government pass-through fees** are application expenses. They reduce per-file realized income.
3. **Mark as Paid flag (`is_marked_as_paid`):** When set, `effective_due = 0` while `raw_due` remains unchanged for audit. This handles fee waivers and partial settlements without distorting history.
4. **Status-linked transactions:** Payments and expenses created during status transitions retain `status_history_id` and `status_name` for full audit trail.

### 6.5 Application Income Entry Rules
- Application income is ONLY entered through:
  - `PaymentFormScreen` (installment payments)
  - `StatusChangeDialog` (fee collection during status transitions)
- The `IncomeFormScreen` is EXCLUSIVELY for independent non-application income.
- **Never create a payment record from `IncomeFormScreen`.** This is enforced by the UI and must be enforced by the backend.

---

## 7. Money Storage Standards

> **CRITICAL: Violations of these rules introduce financial calculation bugs.**

1. **All monetary values are stored as INTEGER (paisa).** ৳1 = 100 paisa. ৳7,000 = 700000.
2. **Never use `double` or `float` for financial storage or calculation.** `double` arithmetic causes rounding errors in accounting systems.
3. **Always use the `Money` class** (located at `lib/core/utils/money.dart`) for all monetary values in models, providers, and UI.
4. **Database reads:** Use `Money.fromPaisa(intValue)` to construct `Money` from database INTEGER columns.
5. **Database writes:** Use `money.paisa` (the raw integer) when inserting or updating database records.
6. **Input parsing:** Use `Money.parse(stringValue)` for user text input. Use `Money.fromTaka(takaValue)` for hard-coded amounts.
7. **Display:** Use `money.formatBengali()` for Bengali display, `money.formatEnglish()` for English.
8. **Never store taka fractions.** Always store and work in paisa (integer).

---

## 8. Validation Standards

### 8.1 Required Field Validation
- All required fields must have clear Bengali error messages.
- Use the standard validator pattern with `FormKey.currentState!.validate()`.
- Error border: Rose-500 (`#F43F5E`).
- Error text: 12sp Bengali below the field.

### 8.2 Standard Bengali Error Messages
| Field | Required Message |
|---|---|
| আবেদনকারীর নাম | `'আবেদনকারীর নাম আবশ্যক'` |
| মোবাইল নম্বর | `'মোবাইল নম্বর আবশ্যক'` / `'সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন'` |
| ভূমি অফিস | `'ভূমি অফিস নির্বাচন আবশ্যক'` |
| কাজের ধরন | `'কাজের ধরন নির্বাচন আবশ্যক'` |
| চুক্তির সার্ভিস ফি | `'চুক্তির সার্ভিস ফি উল্লেখ করুন'` |
| আয়ের পরিমাণ | `'আয়ের পরিমাণ উল্লেখ করুন'` |
| খরচের পরিমাণ | `'খরচের পরিমাণ উল্লেখ করুন'` |
| খরচের খাত | `'খরচের খাত নির্বাচন করুন'` |

### 8.3 Business Rule Validation
- **Phone numbers:** 11-digit Bangladeshi format. Accept both Bengali and English digits.
- **Monetary amounts:** Must be positive integers. Zero amount must be explicitly rejected where non-zero is required.
- **Duplicate payment prevention:** Check for duplicate transaction IDs before inserting. Never insert twice.
- **Application number uniqueness:** Warn (do not block) on duplicate application numbers.

---

## 9. Exception Handling Standards

1. **Never silently swallow exceptions.** Every `catch` block must either:
   - Log the error clearly (for debugging), AND
   - Present a user-visible error state or SnackBar.
2. **Database exceptions** must be caught at the repository layer and converted to typed result objects (`Result<T>` pattern or similar).
3. **Show Bengali error messages** to users. Never show raw exception stack traces.
4. **Riverpod `AsyncError` state** must be handled in every `AsyncValue` consumer with an `error` builder.
5. **Never crash the app** on recoverable errors (network timeout for Telegram backup, file picker cancellation, etc.).

---

## 10. Database Transaction Rules

1. **Atomic operations.** Any operation that writes to multiple tables must be wrapped in a single database transaction (`transaction(() async { ... })`).
2. **Status change + expense creation** must be atomic: either both succeed or neither does.
3. **Payment creation + application update** must be atomic.
4. **Backup operations** must not leave the database in a partially modified state.
5. **Never use transactions for read-only operations.**
6. **Rollback on failure.** If any step in a transaction throws, the entire transaction rolls back.

---

## 11. Data Integrity Requirements

1. **Referential integrity** via `PRAGMA foreign_keys = ON`. Never disable this.
2. **Soft delete propagation:** Deleting a person sets `persons.deleted_at`. It does NOT modify any application record.
3. **Snapshot columns are immutable.** Once written, `applicant_name`, `applicant_phone`, `reference_name`, and `office_name` in `applications` are never updated, even if the linked record changes.
4. **Financial records are immutable.** Payments and expenses are never modified after creation. Corrections are made via soft-delete + new entry.
5. **Calculation immunity:** Soft-deleted records are excluded from all financial calculations.

---

## 12. Migration Requirements

1. The initial schema version is `1`.
2. Every schema change increments the version by 1.
3. Migrations are written in Drift's `MigrationStrategy`.
4. Migrations must be tested with both fresh install and upgrade scenarios.
5. No destructive migrations (DROP TABLE, DROP COLUMN) on existing production data.
6. All new columns must have DEFAULT values or be nullable.

---

## 13. Document Storage Rules

1. **Documents stored as BLOBs** in the `documents` table (`file_data BLOB NOT NULL`).
2. **Maximum recommended document size:** 5MB per file. Warn user if exceeded.
3. **Supported types:** `pdf` and `image` (JPEG, PNG).
4. **`file_type` column:** Store `'pdf'` or `'image'` as a string enum.
5. **`file_name` column:** Store the original filename for display.
6. **`file_size` column:** Store the human-readable size string (e.g., `"2.3 MB"`).
7. **Retrieval:** Documents are loaded lazily — do not load all BLOBs at once into memory.
8. **Documents are included in backup.** Since they are in SQLite, they are part of the backup file automatically.

---

## 14. Backup and Restore Requirements

### 14.1 Backup Process
1. Execute `PRAGMA wal_checkpoint(TRUNCATE)` to flush WAL.
2. Use Drift's online backup API or close DB briefly.
3. Copy DB file to a temporary path.
4. Validate copy: `PRAGMA integrity_check`.
5. Optionally encrypt with AES-256-CBC (key from `flutter_secure_storage`).
6. Export to phone Downloads folder (offline backup).
7. Optionally upload to Telegram via Bot API (cloud backup).

### 14.2 Restore Process
1. User selects backup file via `file_picker`.
2. Decrypt if encrypted.
3. Validate: `PRAGMA integrity_check`.
4. Close current DB connection.
5. Replace DB file.
6. Reopen and verify schema version.
7. Present success confirmation.

### 14.3 Safety Rules
- **Never replace the live database without validation.**
- **Always confirm with user before restore** (data loss warning).
- **Never store Telegram bot token in plain text.** Use `flutter_secure_storage`.
- **Telegram backup is optional.** The app must function fully without it.

---

## 15. Testing Standards

### 15.1 Test Organization
```
test/
├── unit/                   — Pure Dart unit tests
├── widget/                 — Flutter widget tests
└── integration/            — Full workflow integration tests
```

### 15.2 Required Test Coverage
| Module | Required Tests |
|---|---|
| `Money` class | All arithmetic operations, edge cases (zero, negative, large values), `formatBengali`, `formatEnglish`, `fromPaisa`, `fromTaka`, `parse` |
| Financial calculations | All 8 documented financial scenarios from `docs/PROJECT_PLAN.md` |
| Database schema | Table creation, index creation, FK enforcement, soft delete |
| Repository layer | CRUD operations for every entity |
| Business rules | Duplicate payment prevention, snapshot preservation, `is_marked_as_paid` logic |
| Validation | Each required field validator, phone number format |
| Backup/Restore | File copy, integrity check, encrypt/decrypt cycle |

### 15.3 Test Execution Rules
- **QA must actually run tests** (`flutter test`) and report real output.
- **Never claim a test passed without executing it.**
- **All 41 existing tests must continue passing** after any change.
- **Failing tests block merging.** No exceptions.
- Run `flutter analyze` before every commit. Zero issues required.

---

## 16. Code Quality Standards

1. **Dart style:** Follow `flutter_lints` rules as defined in `analysis_options.yaml`.
2. **No unused imports.** `flutter analyze` must report zero issues.
3. **No `print()` statements** in production code. Use proper logging.
4. **Bengali strings:** All user-facing strings must be in Bengali. No English text visible to users.
5. **No hardcoded colors.** Always use `AppColors.*`.
6. **No hardcoded font sizes.** Always use `AppTypography.*`.
7. **No hardcoded spacing.** Always use `AppSpacing.*`.
8. **Const constructors** wherever possible.
9. **Named parameters** for all constructors with more than 2 parameters.
10. **Private methods** prefixed with `_`. Private classes in separate files only when file would exceed ~300 lines.
11. **Comments in English.** Code comments and documentation in English. User-facing strings in Bengali.

---

## 17. Security Standards

1. **Never commit credentials.** No passwords, API keys, bot tokens, or encryption keys in source code.
2. **Never commit `*.db`, `*.sqlite`, or backup files.**
3. **Telegram bot token** stored in `flutter_secure_storage` only.
4. **Encryption keys** stored in `flutter_secure_storage` only.
5. **No logging of financial data** in debug or release builds.
6. **Privacy-first Dashboard:** The Dashboard screen opens with no monetary figures visible by default (existing UI behavior must be preserved).

---

## 18. Performance Standards

1. **Paginate large lists.** Application list, transaction history, and task list must use pagination or lazy loading when records exceed 100 items.
2. **Do not load document BLOBs eagerly.** Load document binary data only when the user opens a document.
3. **Database queries must use indexes.** All `WHERE` clauses on commonly filtered columns must have corresponding indexes defined in the schema.
4. **Riverpod providers must use `keepAlive` appropriately.** Do not keep large data providers alive when not needed.
5. **Avoid rebuilding the entire widget tree.** Use `Consumer`, `select`, or `ref.watch` on specific provider fields.
6. **WAL mode** must be active for database performance during read/write concurrency.

---

## 19. Agent Responsibilities

| Agent | Role | File Ownership |
|---|---|---|
| **Puku (Team Leader)** | Coordinate, assign, review, approve, deliver | All files (read + approve) |
| **flutter-architect** | Design, analyze, document architecture and DB schema | `docs/architecture/*`, `lib/core/database/*` (design only) |
| **feature-developer-a** | Implement persons, applications, status, documents | `lib/features/persons/*`, `lib/features/applications/*`, `lib/features/documents/*`, `lib/features/offices/*`, `lib/features/references/*` |
| **feature-developer-b** | Implement finance, reports, dashboard | `lib/features/finance/*`, `lib/features/reports/*`, `lib/features/dashboard/*`, `lib/features/backup/*`, `lib/features/settings/*`, `lib/features/tasks/*` |
| **qa-engineer** | Write and execute tests | `test/*` only |
| **code-reviewer** | Review code quality and correctness | Read-only across all files |

---

## 20. Developer File Ownership

### Feature Developer A — Exclusive Ownership
- `lib/features/persons/`
- `lib/features/applications/`
- `lib/features/documents/`
- `lib/features/offices/`
- `lib/features/references/`

### Feature Developer B — Exclusive Ownership
- `lib/features/finance/`
- `lib/features/reports/`
- `lib/features/dashboard/`
- `lib/features/backup/`
- `lib/features/settings/`
- `lib/features/tasks/`

### Shared — Only with Team Leader Approval
- `lib/core/database/` — Architect designs, Team Leader assigns developer to implement
- `lib/core/constants/` — Requires Team Leader approval for any change
- `lib/core/utils/` — Requires Team Leader approval for any change
- `lib/core/widgets/` — Requires Team Leader approval for any change
- `pubspec.yaml` — Only modified with Team Leader approval and Architect sign-off
- `analysis_options.yaml` — Only modified with Team Leader approval

---

## 21. Team Collaboration Workflow

### Standard Feature Delivery Process
1. **Team Leader** receives feature request and creates task breakdown.
2. **Team Leader** consults `flutter-architect` for design questions (read-only analysis).
3. **Team Leader** assigns scoped, bounded task to the responsible developer.
4. **Developer** implements the feature on a feature branch.
5. **Developer** runs `flutter analyze` and `flutter test`. Must be zero issues and all tests passing.
6. **Team Leader** assigns `qa-engineer` to write and execute tests for the feature.
7. **Team Leader** assigns `code-reviewer` to review the implementation.
8. **If CHANGES REQUIRED:** Team Leader returns findings to the responsible developer.
9. **Developer** implements corrections.
10. **QA** re-runs tests to verify corrections.
11. **Code Reviewer** issues final APPROVED or APPROVED WITH MINOR OBSERVATIONS.
12. **Team Leader** prepares GitHub delivery.
13. **Team Leader** reports completion to user and awaits merge approval.

### Conflict Prevention
- **Developers may never modify each other's owned files** without explicit Team Leader approval.
- **Shared files** require Team Leader coordination before modification. No simultaneous edits.
- **If a developer needs a shared component** (e.g., a new widget in `lib/core/widgets/`), they request it from the Team Leader, who assigns it as a separate sub-task.

---

## 22. Documentation Update Rules

1. **After each completed feature:** Update `docs/DEVELOPMENT_PROGRESS.md` with what was implemented and test results.
2. **Architecture changes:** Update `docs/architecture/SYSTEM_ARCHITECTURE.md`.
3. **New technical decisions:** Add to `docs/architecture/TECHNICAL_DECISIONS.md`.
4. **New business rules discovered:** Add to `docs/requirements/BUSINESS_RULES.md`.
5. **Never overwrite existing documentation.** Append or update specific sections only.
6. **Preserve the existing docs:** `README.md`, `docs/PROJECT_PLAN.md`, `docs/DATABASE_SCHEMA.md`, `docs/UI_UX_GUIDELINES.md`, `docs/DEVELOPMENT_PROGRESS.md` must not be deleted or replaced wholesale.

---

## 23. GitHub Branch and Commit Conventions

### Branch Naming
```
feature/<short-description>     — New features
fix/<short-description>         — Bug fixes
chore/<short-description>       — Build, dependencies, documentation
db/<short-description>          — Database schema changes
test/<short-description>        — Test-only changes
```

### Commit Message Format
```
<type>(<scope>): <short description in English>

<optional body explaining why, not what>
```
Types: `feat`, `fix`, `chore`, `test`, `docs`, `refactor`, `perf`
Examples:
- `feat(applications): implement application repository with Drift`
- `fix(finance): correct due calculation when is_marked_as_paid is true`
- `test(money): add edge case tests for negative money values`
- `chore(deps): add drift and drift_flutter to pubspec.yaml`

### Git Safety Rules
- **`main` branch must remain stable and passing** at all times.
- **Never force push** to any branch.
- **Never push directly to `main`.** Always use feature branches.
- **Never merge without user approval.**
- **Never commit `*.db`, `*.sqlite`, backup files, or personal documents.**
- **Never commit Telegram tokens, encryption keys, or any credentials.**
- **Run `flutter analyze` and `flutter test` before every commit.**

---

## 24. Feature Acceptance Criteria

A feature is considered complete when ALL of the following are satisfied:

1. ✅ Implementation follows the approved architecture.
2. ✅ All unit tests for the feature pass.
3. ✅ All existing 41 tests still pass (no regressions).
4. ✅ `flutter analyze` reports zero issues.
5. ✅ QA Engineer has actually executed the tests and confirmed results.
6. ✅ Code Reviewer has issued APPROVED or APPROVED WITH MINOR OBSERVATIONS.
7. ✅ All CHANGES REQUIRED findings from Code Reviewer have been addressed.
8. ✅ Documentation has been updated (`DEVELOPMENT_PROGRESS.md`).
9. ✅ Feature branch is clean and ready for review.
10. ✅ Team Leader has confirmed the feature with the user.

---

## 25. Production-Readiness Requirements

The application is production-ready when:

1. ✅ All planned phases (Phase 1–9) are complete.
2. ✅ All business rules are correctly implemented and tested.
3. ✅ All 28 existing screens are connected to real database data (no demo data remaining).
4. ✅ All financial calculations are verified accurate with integration tests.
5. ✅ Backup and restore works correctly, including integrity validation.
6. ✅ All edge cases are handled with appropriate user feedback.
7. ✅ No `flutter analyze` issues.
8. ✅ Full test suite passes with meaningful coverage.
9. ✅ Release build (`flutter build apk --release`) compiles without errors.
10. ✅ App has been tested on a physical Android device.
11. ✅ No demo/test data is shipped in the release build.
12. ✅ All documentation is up to date.

---

## Appendix A: Current Project State (as of initial audit)

### What Exists (Completed)
- ✅ Complete Flutter project structure
- ✅ All 28 navigable UI screens implemented with demo data
- ✅ Design system: `AppColors`, `AppTypography`, `AppSpacing`, `AppTheme`
- ✅ `Money` class (integer-based, Bengali formatting)
- ✅ `BengaliDigits` utility
- ✅ All core widgets: `AppButton`, `AppTextField`, `MoneyField`, `StatusBadge`, `SummaryCard`, `EmptyState`, `ConfirmDialog`, `FilterBottomSheet`, `AppSearchBar`, `AppDialogActionRow`, etc.
- ✅ 5-tab navigation shell (using `IndexedStack`)
- ✅ `MaterialApp` with Bengali locale and Riverpod `ProviderScope`
- ✅ 41 tests passing (unit + widget tests for Money, BengaliDigits, financial scenarios, task management, UI widgets, reference management)
- ✅ `flutter analyze`: Zero issues
- ✅ `docs/PROJECT_PLAN.md` — Comprehensive architecture plan
- ✅ `docs/DATABASE_SCHEMA.md` — Full production-ready schema
- ✅ `docs/UI_UX_GUIDELINES.md` — Complete UI guidelines
- ✅ `docs/DEVELOPMENT_PROGRESS.md` — Phase tracking

### What Does NOT Exist Yet (Backend Pending)
- ❌ Drift package not in `pubspec.yaml`
- ❌ No `lib/core/database/app_database.dart`
- ❌ No real database DAOs or repositories
- ❌ No Riverpod providers connected to real data
- ❌ All screens use `demo_data.dart` (in-memory fake data)
- ❌ No real persistence — data is lost on app restart
- ❌ GoRouter not wired (using direct `Navigator` push in screens)
- ❌ No `path_provider`, `flutter_secure_storage`, `encrypt` packages
- ❌ No backup implementation
- ❌ No Telegram integration

### Discrepancies Between Documentation and Implementation
1. `app.dart` uses `MaterialApp` with direct `home: MainShellScreen()` — GoRouter is not wired yet despite being in `pubspec.yaml`.
2. `pubspec.yaml` does not contain `drift`, `path_provider`, `flutter_local_notifications`, `flutter_secure_storage`, or `encrypt` — these are planned but not added.
3. `docs/DEVELOPMENT_PROGRESS.md` refers to 34 tests passing; `README.md` says 41 tests. Actual current state needs verification via `flutter test`.
4. `docs/PROJECT_PLAN.md` references planned `lib/core/router/app_router.dart` — this file does not exist yet.
5. `docs/DATABASE_SCHEMA.md` has uncommitted status in git — added to `.gitignore` or just untracked.

### Open Questions (Unresolved)
1. Should GoRouter be integrated before or after the database layer? (Recommend: after, to minimize UI disruption.)
2. Should Drift use generated code (`drift_dev`) or the new `drift_flutter` approach? (Recommend: standard `drift_dev` with build_runner.)
3. What is the minimum Android API level target? (Not specified in existing docs.)
4. Is Telegram backup required for Phase 1 or can it be deferred to Phase 8?
5. Should `flutter_local_notifications` be used for task reminders in Phase 2 or deferred?

