# Development Roadmap — রজব ভূমি সেবা ঘর

> **Created:** 2026-11-08
> **Status:** Phases 0 & 1 Complete. Backend development begins at Phase 2 (renamed Phase 1 for clarity).

---

## Roadmap Overview

| Phase | Name | Status | Owner | Blocking |
|---|---|---|---|---|
| **Phase 0** | Project Foundation & Design System | ✅ Complete | — | — |
| **Phase 1** | Complete Navigable UI Prototype (28 screens) | ✅ Complete | — | — |
| **Phase 2** | Complete Project Audit & Environment Setup | ✅ Complete | Antigravity | — |
| **Phase 3** | Database Foundation | ⏳ Next | flutter-architect + feature-developer-a | Phase 2 |
| **Phase 4** | Core Business Modules (Persons, Applications, Status) | ⏳ Scheduled | feature-developer-a | Phase 3 |
| **Phase 5** | Financial System | ⏳ Scheduled | feature-developer-b | Phase 3, Phase 4 |
| **Phase 6** | Supporting Modules (Documents, Tasks, Reminders) | ⏳ Scheduled | Both developers | Phase 4, Phase 5 |
| **Phase 7** | Reports & Dashboard | ⏳ Scheduled | feature-developer-b | Phase 5, Phase 6 |
| **Phase 8** | Validation & Reliability | ⏳ Scheduled | Both developers | Phase 7 |
| **Phase 9** | Existing UI Integration (wire all screens to real data) | ⏳ Scheduled | Both developers | Phase 8 |
| **Phase 10** | Full Quality Assurance | ⏳ Scheduled | qa-engineer | Phase 9 |
| **Phase 11** | Production Readiness (Backup, Performance, Release) | ⏳ Scheduled | Both developers | Phase 10 |

---

## Phase 2 — Complete Project Audit & Environment Setup
**Status:** ✅ Complete (this session)
**Owner:** Antigravity IDE preparation

### Deliverables (All Completed)
- [x] Full project inspection and documentation review
- [x] `PUKU.md` — Root project memory and engineering instructions
- [x] `.puku/agents/flutter-architect.agent.md`
- [x] `.puku/agents/feature-developer-a.agent.md`
- [x] `.puku/agents/feature-developer-b.agent.md`
- [x] `.puku/agents/qa-engineer.agent.md`
- [x] `.puku/agents/code-reviewer.agent.md`
- [x] `docs/architecture/SYSTEM_ARCHITECTURE.md`
- [x] `docs/architecture/TECHNICAL_DECISIONS.md`
- [x] `docs/requirements/BUSINESS_RULES.md`
- [x] `docs/testing/TEST_STRATEGY.md`
- [x] `docs/ROADMAP.md` (this file)

### Open Items Requiring User Decision
See `docs/architecture/TECHNICAL_DECISIONS.md` (OTQ-001 through OTQ-005) and `docs/requirements/BUSINESS_RULES.md` (BRQ-001 through BRQ-005).

---

## Phase 3 — Database Foundation
**Status:** ⏳ Next
**Primary Owner:** flutter-architect (design), feature-developer-a (implementation)
**Blocking:** Must complete before any feature implementation

### Prerequisites
- [ ] User confirms GoRouter integration timing (OTQ-001)
- [ ] User confirms Drift approach: `drift_dev` + `build_runner` (OTQ-002)

### Tasks
#### 3.1 Package Integration
- [ ] Add `drift` and `drift_flutter` to `pubspec.yaml`
- [ ] Add `drift_dev` to `dev_dependencies`
- [ ] Add `build_runner` to `dev_dependencies`
- [ ] Add `path_provider` and `path` to `pubspec.yaml`
- [ ] Run `flutter pub get`
- [ ] Verify `flutter analyze` still passes

#### 3.2 Database Schema Implementation (flutter-architect designs, developer implements)
- [ ] Create `lib/core/database/app_database.dart` — Drift AppDatabase class
- [ ] Define all 14 Drift Table classes
- [ ] Define all indexes
- [ ] Define `unified_transactions_view` SQL view
- [ ] Set `PRAGMA foreign_keys = ON` and `PRAGMA journal_mode = WAL`
- [ ] Implement schema version 1 migration strategy
- [ ] Run `flutter pub run build_runner build` to generate `app_database.g.dart`
- [ ] Create `lib/core/database/database_provider.dart` — Riverpod provider for AppDatabase

#### 3.3 Repository Foundation
- [ ] Create base repository pattern class (optional, for shared patterns)
- [ ] Define DAO interfaces for each entity

#### 3.4 Database Tests
- [ ] `test/unit/database_schema_test.dart` — All 14 tables exist, WAL mode, FK enforcement
- [ ] `test/unit/database_soft_delete_test.dart` — Soft delete and active record filtering
- [ ] `flutter test` — All baseline 41 tests + new DB tests pass
- [ ] `flutter analyze` — Zero issues

### Acceptance Criteria
- AppDatabase initializes without errors on a fresh install
- All 14 tables are created with correct schema
- WAL mode is active (`PRAGMA journal_mode = WAL` returns `'wal'`)
- Foreign key enforcement is active
- All existing 41 tests still pass
- New database tests pass
- `flutter analyze` zero issues

---

## Phase 4 — Core Business Modules
**Status:** ⏳ Scheduled
**Primary Owner:** feature-developer-a
**Dependency:** Phase 3 complete

### Tasks

#### 4.1 Offices Module
- [ ] `OfficeDao` — CRUD with soft delete
- [ ] `OfficeRepository` — Business logic
- [ ] `OfficeProvider` — Riverpod providers
- [ ] Default office seeding (seed on first run if `offices` is empty)
- [ ] Tests: CRUD, soft delete, exclusion of deleted from active list

#### 4.2 Work Types & Categories
- [ ] `WorkTypeDao` — CRUD with soft delete
- [ ] `WorkTypeRepository`
- [ ] `WorkTypeProvider`
- [ ] Default seeding: `ই-নামজারি`, `জমাভাগ`, `খতিয়ান সংশোধন`, `নামজারি`, `পর্চা`
- [ ] `ExpenseCategoryDao`, `IncomeCategoryDao` — CRUD with soft delete
- [ ] Default seeding for expense and income categories

#### 4.3 Persons Module
- [ ] `PersonDao` — CRUD with soft delete
- [ ] `PersonRepository` — Business logic (search, pagination)
- [ ] `PersonProvider` — Riverpod providers (list, detail, search)
- [ ] Tests: soft delete with snapshot preservation

#### 4.4 References Module
- [ ] `ReferenceDao` — CRUD with soft delete
- [ ] `ReferenceRepository` — With financial summary calculation
- [ ] `ReferenceProvider`
- [ ] Tests: soft delete, reference financial summary accuracy

#### 4.5 Applications Module
- [ ] `ApplicationDao` — CRUD, search, filter, soft delete
- [ ] `StatusHistoryDao` — Insert, list by application
- [ ] `ApplicationRepository` — Full business logic:
  - Create application (with snapshots)
  - Atomic status change (status_history + application update + optional payment/expense)
  - Application listing with filters (status, work type, office, due status)
  - Application search
  - Application financial summary calculation
- [ ] `ApplicationProvider` — Riverpod providers (list, detail, filter state)
- [ ] Tests: creation, snapshot integrity, status change atomicity, financial calculations

### Acceptance Criteria
- All CRUD operations work correctly with soft delete
- Application creation correctly writes all snapshot columns
- Status change is atomic (all-or-nothing)
- Status-linked payments and expenses are linked correctly
- Financial calculations match the formulas in PUKU.md Section 6
- All new tests pass; all 41 baseline tests still pass

---

## Phase 5 — Financial System
**Status:** ⏳ Scheduled
**Primary Owner:** feature-developer-b
**Dependency:** Phase 3 complete, Phase 4 (Applications) in progress

### Tasks

#### 5.1 Payments Module
- [ ] `PaymentDao` — Insert, list by application, soft delete
- [ ] `PaymentRepository` — Business logic with duplicate prevention
- [ ] `PaymentProvider`
- [ ] Tests: payment creation, duplicate prevention, `is_marked_as_paid` logic

#### 5.2 Independent Income Module
- [ ] `IndependentIncomeDao` — Insert, list, filter by date/category, soft delete
- [ ] `IndependentIncomeRepository`
- [ ] `IndependentIncomeProvider`
- [ ] Tests: isolation from application payments, date filtering

#### 5.3 Expenses Module
- [ ] `ExpenseDao` — Insert, list (by application, by type), soft delete
- [ ] `ExpenseRepository` — Application expense vs general expense separation
- [ ] `ExpenseProvider`
- [ ] Tests: `is_general` flag, file expense impact on realized income

#### 5.4 Unified Transaction View & Repository
- [ ] Implement `unified_transactions_view` in Drift
- [ ] `TransactionRepository` — Multi-criteria filtering (type, date, category, application)
- [ ] `TransactionProvider`
- [ ] Tests: view returns all 6 transaction sources; date and category filtering; soft delete exclusion

#### 5.5 Financial Summary Repository
- [ ] `FinancialSummaryRepository` — All global financial calculations
- [ ] `FinancialSummaryProvider` — With date filter support
- [ ] `DueManagementRepository` — Active dues list with sorting
- [ ] Tests: all 8 financial scenarios pass; global totals accurate; due management correct

### Acceptance Criteria
- All 8 financial scenarios produce exactly correct results (hand-verified)
- No `double` arithmetic anywhere in financial code
- Independent income is never confused with application payments
- Soft-deleted records excluded from all calculations
- Date filtering works correctly for all periods

---

## Phase 6 — Supporting Modules
**Status:** ⏳ Scheduled
**Owner:** feature-developer-a (Documents), feature-developer-b (Tasks)
**Dependency:** Phase 4 (Applications), Phase 5 (Finance)

### Tasks

#### 6.1 Documents Module (feature-developer-a)
- [ ] `DocumentDao` — Insert, list by application, get file data, soft delete
- [ ] `DocumentRepository` — Size validation, file type validation
- [ ] `DocumentProvider`
- [ ] Tests: BLOB storage, lazy loading, soft delete, size warning

#### 6.2 Tasks Module (feature-developer-b)
- [ ] `TaskDao` — CRUD with soft delete and status updates
- [ ] `TaskRepository` — Today's tasks filter, priority sorting, search
- [ ] `TaskProvider`
- [ ] Tests: today filter, completed_at timestamp, category enum validation

#### 6.3 Shop Settings Module (feature-developer-b)
- [ ] `ShopSettingsDao` — Key-value get/set
- [ ] `ShopSettingsRepository`
- [ ] `ShopSettingsProvider`
- [ ] Default seeding: shop name `রজব ভূমি সেবা ঘর`

### Acceptance Criteria
- Documents stored and retrieved correctly as BLOBs
- Documents load lazily (not all at once)
- Task today filter works correctly with timezone awareness
- Shop settings persist across app restarts

---

## Phase 7 — Reports & Dashboard
**Status:** ⏳ Scheduled
**Primary Owner:** feature-developer-b
**Dependency:** Phase 5, Phase 6 complete

### Tasks
- [ ] `DashboardProvider` — Today's hearing tasks, pipeline counters, recent applications, search
- [ ] `AnalyticsDashboardRepository` — KPI calculations, trend data, work type breakdown, pipeline funnel
- [ ] `AnalyticsDashboardProvider`
- [ ] Connect `DashboardScreen` to real providers
- [ ] Connect `ReportsScreen` to real providers

### Acceptance Criteria
- Dashboard shows real data (no demo data)
- Analytics KPIs are accurate and consistent with financial totals
- Charts render correctly with real database data
- Dashboard respects privacy-first design (no monetary figures visible on open)

---

## Phase 8 — Validation, Anti-Hang & Reliability
**Status:** ⏳ Scheduled
**Owner:** Both developers
**Dependency:** Phases 4–7 complete

### Tasks
- [ ] Review all form validators and ensure Bengali error messages match standards
- [ ] Database transaction safety audit: all multi-table operations in transactions
- [ ] Error state audit: all screens handle AsyncError state with user-friendly UI
- [ ] Global Crash Boundary: register `PlatformDispatcher.instance.onError` and `FlutterError.onError` in `main.dart` with user-friendly Bengali retry card via `ErrorWidget.builder`
- [ ] Anti-Hang audit: verify all heavy computations (>16ms) use `compute()` / `Isolate.run()`
- [ ] Memory Leak audit: verify all controllers, listeners, and subscriptions are cancelled in `dispose()`
- [ ] BLOB separation audit: verify document list queries never fetch `file_data` (BLOB)
- [ ] Edge case handling: empty lists, zero amounts, very large amounts
- [ ] Concurrency: ensure WAL mode handles concurrent reads without table locks
- [ ] Input sanitization: defensive parsing (`tryParse`, null-safety, array bounds)
- [ ] Memory: verify no memory leaks from unclosed Riverpod providers

---

## Phase 9 — Existing UI Integration & Zero-Freeze Virtualization
**Status:** ⏳ Scheduled
**Owner:** Both developers
**Dependency:** Phases 4–8 complete

### Tasks
- [ ] Connect all 28 screens to real Riverpod providers (replace `demo_data.dart` usage)
- [ ] Implement database pagination (`LIMIT 25 OFFSET`) and infinite scroll for applications, transactions, persons, and tasks
- [ ] Ensure strict list virtualization with `ListView.builder` / slivers (no unbounded `SingleChildScrollView + Column`)
- [ ] Implement GoRouter (if decided in OTQ-001)
- [ ] Add loading states to all screens that load data (non-blocking shimmer & progress bars)
- [ ] Add empty states to all list screens
- [ ] Add error states with retry buttons to all screens
- [ ] Verify all forms submit to real database
- [ ] Remove all `demo_data.dart` imports from production code
- [ ] Verify all navigation works correctly

### Acceptance Criteria
- Zero uses of `demo_data.dart` in production screens
- All 28 screens show real database data
- Loading, empty, and error states render correctly
- All form submissions persist to database

---

## Phase 10 — Full Quality Assurance
**Status:** ⏳ Scheduled
**Owner:** qa-engineer
**Dependency:** Phase 9 complete

### Tasks
- [ ] Full unit test suite execution and reporting
- [ ] Widget test suite execution
- [ ] Integration test suite execution
- [ ] Financial calculation verification (all 8 scenarios with real data)
- [ ] Edge case testing (all scenarios from `docs/testing/TEST_STRATEGY.md`)
- [ ] Regression test: all 41 baseline tests still passing
- [ ] Performance: measure list loading times with 100+ records
- [ ] `flutter analyze` — Zero issues

---

## Phase 11 — Production Readiness
**Status:** ⏳ Scheduled
**Owner:** feature-developer-b (Backup), Both developers (final fixes)
**Dependency:** Phase 10 complete

### Tasks
- [ ] Backup implementation (local export to Downloads folder)
- [ ] Restore implementation (from local file via `file_picker`)
- [ ] Optional: Telegram cloud backup implementation
- [ ] Database integrity check on startup
- [ ] Release build test: `flutter build apk --release`
- [ ] Install on physical Android device and smoke test
- [ ] Final documentation update (all docs up to date)
- [ ] `docs/DEVELOPMENT_PROGRESS.md` updated with complete status
- [ ] Git: clean commit history, meaningful commit messages
- [ ] User review and approval

### Production Acceptance Criteria
- Release APK builds without errors
- App installs and runs on physical Android device
- All 28 screens work correctly with real data
- Financial calculations verified correct on device
- Backup exports and restores successfully
- No demo data in release build
- All documentation up to date
- User has reviewed and approved

---

## GitHub Delivery Process

### Per-Feature Delivery
```bash
# 1. Create feature branch
git checkout -b feature/<name>

# 2. Implement feature
# ... (developer work) ...

# 3. Run checks
flutter analyze     # Must: zero issues
flutter test        # Must: all tests pass

# 4. Stage and commit
git add .
git commit -m "feat(<scope>): <description>"

# 5. Push branch
git push origin feature/<name>

# 6. Wait for user approval before merge
# Never merge to main without user approval
```

### Branch Naming Convention
- `feature/database-foundation` — Phase 3
- `feature/persons-module` — Phase 4 (persons)
- `feature/applications-module` — Phase 4 (applications)
- `feature/payments-module` — Phase 5
- `feature/independent-income-module` — Phase 5
- `feature/expenses-module` — Phase 5
- `feature/documents-module` — Phase 6
- `feature/tasks-module` — Phase 6
- `feature/reports-dashboard` — Phase 7
- `feature/ui-integration` — Phase 9
- `feature/backup-restore` — Phase 11

