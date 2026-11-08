# Technical Decisions — রজব ভূমি সেবা ঘর

> **This is the living log of significant technical decisions.**
> Every decision includes: what was decided, why, alternatives considered, and who made the decision.
> New decisions must be appended here, not inserted into existing entries.

---

## Decision Log

### TD-001: SQLite via Drift ORM (not raw sqflite)
**Date:** Pre-project  
**Status:** Confirmed  
**Decision:** Use `drift` (formerly `moor`) as the SQLite ORM instead of raw `sqflite`.  
**Rationale:**
- Type-safe SQL queries with compile-time verification
- Built-in migration system with schema versioning
- DAO (Data Access Object) pattern for clean separation of concerns
- WAL mode support
- Transaction API
- Code generation reduces boilerplate
**Alternatives Considered:** Raw `sqflite`, `isar`, `objectbox`, Firebase Firestore  
**Why Not Alternatives:** `sqflite` lacks type safety and migrations; `isar`/`objectbox` are not SQL-based; Firebase violates the offline-only constraint.  
**Decision Maker:** Project plan (documented in `docs/PROJECT_PLAN.md`)

---

### TD-002: Riverpod v2 for State Management (not Provider/BLoC)
**Date:** Pre-project  
**Status:** Confirmed  
**Decision:** Use `flutter_riverpod ^2.5.1` for all state management.  
**Rationale:**
- Type-safe, compile-time verified providers
- Excellent offline-first patterns (AsyncNotifier, FutureProvider, StreamProvider)
- Less boilerplate than BLoC
- More structured than vanilla Provider
- Already in `pubspec.yaml` and `ProviderScope` is in `main.dart`  
**Alternatives Considered:** `provider`, `flutter_bloc`, `get`, `mobx`  
**Why Not Alternatives:** Less type safety, more boilerplate, or no compile-time verification.  
**Decision Maker:** Project plan

---

### TD-003: Integer-Based Money Storage (Paisa)
**Date:** Pre-project  
**Status:** Confirmed — IMMUTABLE  
**Decision:** All monetary values stored as `INTEGER` (paisa). ৳1 = 100 paisa. ৳7,000 = 700000. A custom `Money` class wraps the integer.  
**Rationale:**
- Eliminates floating-point rounding errors (e.g., ৳0.1 + ৳0.2 ≠ ৳0.3 in IEEE 754)
- Financial accounting requires exact integer arithmetic
- SQLite `INTEGER` is safer than `REAL` for monetary data
**Alternatives Considered:** `double` storage, `Decimal` library, string storage  
**Why Not Alternatives:** `double` causes rounding errors; `Decimal` adds complexity; string requires parsing.  
**Decision Maker:** Project plan + implemented in `lib/core/utils/money.dart`

---

### TD-004: UUID v4 Text Primary Keys
**Date:** Pre-project  
**Status:** Confirmed  
**Decision:** All table primary keys are `TEXT` containing UUID v4 strings.  
**Rationale:**
- Conflict-free offline operation (no auto-increment collisions if two devices are ever merged)
- UUID generation requires no database round-trip
- Compatible with SQLite `TEXT` type efficiently
**Alternatives Considered:** Auto-increment INTEGER  
**Why Not Auto-increment:** Cannot be safely used offline for potential future multi-device scenarios.  
**Decision Maker:** Project plan

---

### TD-005: Zero Hard Deletes (Soft Delete Pattern)
**Date:** Pre-project  
**Status:** Confirmed — IMMUTABLE  
**Decision:** No physical `DELETE` SQL on business data. All "deletions" set `deleted_at = Unix epoch milliseconds INTEGER`. NULL means active.  
**Rationale:**
- Financial audit trail — deleted records remain in history
- Snapshot integrity — deleted reference persons still appear in historical applications
- Easy recovery — `UPDATE SET deleted_at = NULL` restores a record
- Cashbook audit — no historical financial record can silently disappear
**Alternatives Considered:** Physical delete, archive tables  
**Why Not Physical Delete:** Destroys audit trail and breaks financial calculations retroactively.  
**Decision Maker:** Project plan + documented in `docs/DATABASE_SCHEMA.md`

---

### TD-006: Snapshot Columns in Applications Table
**Date:** Pre-project  
**Status:** Confirmed — IMMUTABLE  
**Decision:** The `applications` table stores denormalized snapshot copies of `applicant_name`, `applicant_phone`, `applicant_address`, `reference_name`, and `office_name` as immutable columns written at application creation time.  
**Rationale:**
- If a customer is deleted (soft-deleted), historical applications still show correct name/phone
- If an office is renamed, historical applications still show the original office name
- Historical financial reports remain accurate regardless of master data changes
- Preserves the integrity of printed receipts and reports
**Alternatives Considered:** Always JOIN to master tables (persons, references, offices)  
**Why Not Pure JOIN:** JOIN results change when master records are deleted or modified, breaking historical accuracy.  
**Decision Maker:** Project plan

---

### TD-007: GoRouter for Navigation (Planned — Not Yet Wired)
**Date:** Pre-project  
**Status:** In pubspec.yaml, not yet implemented  
**Decision:** Use `go_router ^14.2.0` for declarative navigation.  
**Rationale:**
- Declarative route definitions
- Deep link support (for future notification deep links from hearing tasks)
- Official Flutter package
- Clean URL-based navigation model
**Current State:** `app.dart` uses `MaterialApp` with `home: MainShellScreen()`. GoRouter will be wired in Phase 7 (UI Integration) to minimize frontend disruption during backend development.  
**Decision Maker:** Project plan

---

### TD-008: Bundled Noto Sans Bengali Font
**Date:** Pre-project  
**Status:** Confirmed — Implemented  
**Decision:** Bundle Noto Sans Bengali (Regular, Medium, SemiBold, Bold) in `assets/fonts/`. Do not use Google Fonts runtime fetching.  
**Rationale:**
- App must work fully offline
- Bengali text must render correctly without internet connection
- Consistent rendering across all Android versions
**Decision Maker:** Project plan

---

### TD-009: Telegram Backup is Optional
**Date:** 2026-11-08  
**Status:** Confirmed  
**Decision:** Telegram cloud backup is an optional feature. The app must function fully without it. Local phone backup (export to Downloads folder) is the primary backup mechanism.  
**Rationale:**
- Some users may not have a Telegram account
- Network connectivity should not be required for any core app function
- Telegram Bot API changes could break the feature
**Implementation Notes:**
- Telegram bot token stored in `flutter_secure_storage` only
- UI must clearly label Telegram backup as "optional / ঐচ্ছিক"
- If Telegram backup fails, local backup must still succeed independently
**Decision Maker:** Project plan + user requirements

---

### TD-010: Dashboard Privacy-First — No Money on Open
**Date:** Pre-project  
**Status:** Confirmed — UI Implemented  
**Decision:** The Dashboard screen (Tab 1) displays operational counters (application counts, task counts, pipeline status) but deliberately hides all monetary figures by default.  
**Rationale:**
- The app is used in a public-facing shop environment
- Financial figures should not be visible to customers looking at the screen
- User can navigate to the Finance tab (Tab 3) to see financial data
**Current State:** Dashboard UI already implements this. Backend providers must respect this by providing data that the Dashboard specifically excludes monetary amounts from.  
**Decision Maker:** Project plan + user requirements

---

### TD-011: Application Number Required in Step 2 (Wizard)
**Date:** Pre-project  
**Status:** Confirmed — UI Implemented  
**Decision:** Application number (`app_number`) is required in the application creation wizard Step 2, with duplicate checking validation.  
**Rationale:**
- The official government application number is a critical operational identifier
- Duplicate application numbers indicate a data entry error
**Current State:** UI wizard enforces this. Backend must implement duplicate-checking query.  
**Decision Maker:** Documented in `docs/DEVELOPMENT_PROGRESS.md`

---

### TD-012: Mandatory Pagination & UI Virtualization (Anti-Hang Architecture)
**Date:** 2026-11-08  
**Status:** Confirmed — Architecture Standard  
**Decision:** All lists (`applications`, `transactions`, `persons`, `tasks`, `expenses`) must be paginated at the database layer using `LIMIT 25 OFFSET (page * 25)` or keyset pagination, and rendered exclusively using virtualized Flutter widgets (`ListView.builder`, `SliverList`).  
**Rationale:**
- As the shop operates over months and years, records grow into thousands of items.
- Loading unbounded queries into memory causes severe jank, high RAM consumption, and eventually Out-Of-Memory (OOM) crashes on Android.
- Virtualization ensures only currently visible cards exist in memory.  
**Decision Maker:** Architecture & Engineering Directive

---

### TD-013: Background Isolate Execution for Heavy Operations (`compute` / `Isolate.run`)
**Date:** 2026-11-08  
**Status:** Confirmed — Architecture Standard  
**Decision:** Any task requiring intensive CPU processing (>16ms) must be offloaded to Dart background worker isolates via `compute()` or `Isolate.run()`.  
**Scope:**
- Multi-month/yearly financial ledger aggregation and KPI curve crunching
- PDF document generation and binary compilation
- Backup AES-256 encryption/decryption
- Database `PRAGMA integrity_check`
**Rationale:**
- The main UI thread must never drop below 60 FPS.
- Prevents Android OS "Application Not Responding" (ANR) warnings and freeze dialogs.  
**Decision Maker:** Architecture & Engineering Directive

---

## Open Technical Questions

The following questions require resolution before implementation begins. The Team Leader must present these to the user and document the decision here.

### OTQ-001: GoRouter Integration Timing
**Question:** Should GoRouter be wired before or after the database layer is implemented?  
**Options:**
- A) Wire GoRouter first (clean navigation before data) — risks UI disruption
- B) Wire GoRouter after database (preserve current working app) — defers navigation cleanup  
**Recommendation:** Option B — Wire in Phase 7 after all backend is implemented.  
**Status:** Pending user decision

### OTQ-002: Drift Code Generation Approach
**Question:** Should we use `drift_dev` with `build_runner` (traditional) or the newer `drift_flutter` auto-generation?  
**Options:**
- A) `drift_dev` + `build_runner` — explicit, well-documented, generates `.g.dart` files  
- B) `drift_flutter` — newer, less ceremony, automatic  
**Recommendation:** Option A — `drift_dev` + `build_runner` for maximum control and documentation alignment.  
**Status:** Pending user/architect decision

### OTQ-003: Minimum Android API Level
**Question:** What is the minimum Android API level (minSdkVersion) for this app?  
**Current:** Not explicitly defined in existing documentation.  
**Recommendation:** API 21 (Android 5.0) or API 24 (Android 7.0) based on Flutter defaults and SQLite cipher requirements.  
**Status:** Pending user decision

### OTQ-004: Local Notifications Timing
**Question:** Should `flutter_local_notifications` be added in Phase 2 (Database Foundation) or deferred to Phase 6 (Tasks & Reminders)?  
**Recommendation:** Defer to Phase 6 to keep Phase 1–2 focused on core database layer.  
**Status:** Pending user decision

### OTQ-005: Document Size Limit Enforcement
**Question:** The plan recommends warning users if a document exceeds 5MB. Should we enforce a hard limit (block) or just warn?  
**Recommendation:** Soft warning (allow but warn) for user experience; hard block at 10MB to prevent database bloat.  
**Status:** Pending user decision

