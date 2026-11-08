# Business Rules — রজব ভূমি সেবা ঘর

> **Authoritative business rules reference.**
> Every agent, developer, and reviewer must comply with these rules.
> Source of truth: `PUKU.md` (this document elaborates on those rules with examples).

---

## 1. Application Management Rules

### 1.1 Application Creation
- An application MUST have: applicant name, applicant phone, work type, office name, application date, and agreed amount.
- The application number (`app_number`) is required and must be checked for duplicates.
- An application may optionally have: applicant address, mouza, case number, reference person, initial payment, documents, and notes.
- Initial status is always `'আবেদন'` (Application Created) on creation.
- Snapshot columns (`applicant_name`, `applicant_phone`, `applicant_address`, `reference_name`, `office_name`) must be written at creation time and never changed afterward.

### 1.2 Application Editing
- Editing is allowed for: applicant info, reference person, mouza, work type, office, agreed amount, notes.
- **When editing applicant info:** Update snapshot columns (`applicant_name`, `applicant_phone`, `applicant_address`) in the application record too. (Exception to the immutability rule — edits before the first status change may update snapshots with user acknowledgment.)
- **Agreed amount changes:** Allowed, but financial history remains unchanged. The new agreed amount affects future due calculations only.
- **Never allow editing:** Status, payment history, expense history (these have dedicated workflows).

### 1.3 Application Deletion
- Soft delete only. Set `deleted_at = now.millisecondsSinceEpoch`.
- Soft-deleted applications must NOT appear in lists, search, or financial calculations.
- Payments, expenses, documents, and status history linked to a soft-deleted application remain in the database (preserving financial audit trail) but are excluded from active calculations via `JOIN` with `applications WHERE deleted_at IS NULL`.

---

## 2. Status Management Rules

### 2.1 Valid Status Values
The 10 valid statuses in Bengali (do not add, remove, or translate these):
1. `আবেদন` — Initial status
2. `প্রস্তাব প্রেরণ` — Proposal sent
3. `শুনানি` — Hearing scheduled
4. `মঞ্জুর` — Approved
5. `ডিসিআর প্রস্তুত` — DCR ready
6. `সম্পন্ন` — Completed
7. `অপেক্ষমাণ` — Waiting (exception)
8. `আপত্তি` — Objection raised (exception)
9. `সংশোধন প্রয়োজন` — Correction needed (exception)
10. `নামঞ্জুর` — Rejected (exception)

### 2.2 Status Change Transaction
Every status change must:
1. Create a `status_history` record with `prev_status`, `new_status`, `changed_at`, and optional `note`.
2. Update `applications.status` to the new status.
3. Update `applications.updated_at`.
4. If a payment amount was entered in the `StatusChangeDialog`:
   - Create a `payments` record linked to the application.
   - Set `is_status_fee = 1`, `status_history_id = newStatusHistoryId`, `status_name = newStatus`.
5. If an expense amount was entered:
   - Create an `expenses` record linked to the application with `is_general = 0`.
   - Set `is_status_exp = 1`, `status_history_id = newStatusHistoryId`, `status_name = newStatus`.
6. All of the above in a single atomic database transaction.

### 2.3 Automatic Task Creation for Hearing
- When status changes to `'শুনানি'` and a hearing date is provided:
  - Automatically create a `tasks` record:
    - `title`: `'শুনানি — [applicant_name]'`
    - `category`: `'শুনানি'`
    - `due_date`: hearing date
    - `due_time`: hearing time (if provided)
    - `application_id`: application ID
    - `status`: `'করতে হবে'`
    - `priority`: `'জরুরি'`

### 2.4 Government Fee Suggestions
These are UI suggestions only — the backend must accept any amount:
- Application submission: ৳70 (7000 paisa)
- Hearing: ৳300 (30000 paisa)
- DCR preparation: ৳1,100 (110000 paisa)

---

## 3. Financial Rules

### 3.1 Income Separation (CRITICAL BUSINESS RULE)
Application income and independent income are ALWAYS separate:

**Application income** (`payments` table):
- Tied to a specific application (`application_id NOT NULL`)
- Recorded via `PaymentFormScreen` or `StatusChangeDialog`
- Contributes to `total_received` for the application
- Included in `total_app_income` for global calculations

**Independent income** (`independent_incomes` table):
- Never has an `application_id`
- Recorded ONLY via `IncomeFormScreen`
- Categories: computer services, photocopying, deed typing, printing, other
- Contributes to `total_independent_income` for global calculations
- **Never reduces any application's realized income**

### 3.2 Expense Separation (CRITICAL BUSINESS RULE)
Two types of expenses with fundamentally different financial impact:

**Application expense** (`expenses` WHERE `is_general = 0`):
- Tied to a specific application (`application_id NOT NULL`)
- Directly reduces that application's `actual_realized_income`
- Examples: government fees, field survey costs, travel, photocopying for file, challan
- May be linked to a status change (`is_status_exp = 1`)

**General shop expense** (`expenses` WHERE `is_general = 1`):
- Shop overhead — no application link (`application_id NULL`)
- Does NOT reduce any individual application's income
- Contributes to `total_general_expense` for global net income
- Examples: shop rent, electricity, broadband, stationery, salary

### 3.3 Mark as Paid Rule
When `is_marked_as_paid = 1`:
- `effective_due = 0` (no outstanding due displayed anywhere)
- `raw_due = agreed_amount - total_received` (preserved for audit — never modified)
- Financial summaries show `effective_due = 0` for this application
- `actual_realized_income` is not affected by mark-as-paid (still = received - expenses)
- The flag can be reversed (`is_marked_as_paid = 0`) to restore the outstanding due

### 3.4 Duplicate Payment Prevention
- Use Drift's upsert/unique constraints carefully.
- If a payment with the same amount is submitted on the same date for the same application, present a confirmation dialog before inserting.
- Never silently reject a payment — either insert it with confirmation or show an error.

---

## 4. Person and Reference Management Rules

### 4.1 Person (Applicant Customer) Rules
- A person can be an applicant in multiple applications.
- Soft-deleting a person:
  - Sets `persons.deleted_at`
  - Does NOT modify any `applications` record
  - The snapshot columns (`applicant_name`, `applicant_phone`, `applicant_address`) in existing applications remain intact
  - The soft-deleted person does NOT appear in person selectors for new applications
  - `Person Detail` screen should still show historical applications they were linked to

### 4.2 Reference Person Rules
- A reference person can be linked to multiple applications.
- Soft-deleting a reference person:
  - Sets `references.deleted_at`
  - Does NOT modify any `applications.reference_id` or `applications.reference_name`
  - Deleted reference persons do NOT appear in the reference selector for new applications
  - Existing applications still display the `reference_name` snapshot correctly

### 4.3 Reference Financial Summary
The `ReferenceDetailScreen` displays:
- Total agreed amount of all applications where `reference_id = this person's id`
- Total received of all those applications
- Total due of all those applications
These calculations must exclude soft-deleted applications.

---

## 5. Document Rules

### 5.1 Storage
- Documents stored as BLOBs in `documents.file_data`
- Supported: PDF (`file_type = 'pdf'`), images (`file_type = 'image'`)
- Warn user if single file exceeds 5MB; consider blocking at 10MB
- Load lazily — never preload all documents for a list

### 5.2 Deletion
- Soft delete only. Set `documents.deleted_at = now`.
- Soft-deleted documents do NOT appear in the Documents tab.
- Soft-deleted documents ARE still included in the database backup (for potential recovery).

---

## 6. Task Rules

### 6.1 Task Categories (Exactly 6 — Do Not Change)
1. `শুনানি` — Hearing/court attendance
2. `কাগজপত্র` — Document collection/preparation
3. `ফি/তাগাদা` — Fee payment/due follow-up
4. `অফিস জমা` — Office submission
5. `ডেলিভারি` — Document delivery to customer
6. `সাধারণ` — General task

### 6.2 Task Status Flow
`করতে হবে` → `চলমান` → `সম্পন্ন`

Completion sets `completed_at = now.millisecondsSinceEpoch`.

### 6.3 Dashboard "Today's Tasks"
Tasks shown on Dashboard are those where:
- `due_date` is today (compare date only, not time)
- `deleted_at IS NULL`
- `status IN ('করতে হবে', 'চলমান')` (not completed)

---

## 7. Category Management Rules

### 7.1 Work Types
- User-customizable list in `work_types` table.
- Soft delete only — deleting a work type does NOT affect existing applications that use that work type name (the name is stored as a snapshot `TEXT` in `applications.work_type`).
- Default seeded values: `ই-নামজারি`, `জমাভাগ`, `খতিয়ান সংশোধন`, `নামজারি`, `পর্চা`

### 7.2 Expense Categories
- Two groups: application-specific (`is_general = 0`) and general shop (`is_general = 1`).
- User-customizable in `expense_categories` table.
- Soft delete only — existing expense records retain their category name as a TEXT snapshot.
- Default application expense categories: `সরকারি ফি`, `ডিসিআর ফি`, `শুনানি খরচ`, `ফিল্ড সার্ভে`, `ফটোকপি`, `যাতায়াত`
- Default general expense categories: `দোকান ভাড়া`, `বিদ্যুৎ`, `ইন্টারনেট`, `স্টেশনারি`

### 7.3 Independent Income Categories
- User-customizable in `income_categories` table.
- Default values: `কম্পিউটার সেবা`, `ফটোকপি`, `দলিল টাইপিং`, `প্রিন্টিং`, `অন্যান্য`

---

## 8. Shop Settings Rules

The `shop_settings` table stores key-value pairs:

| Key | Description |
|---|---|
| `shop_name` | Shop name (default: `রজব ভূমি সেবা ঘর`) |
| `owner_name` | Owner name |
| `phone` | Contact phone |
| `address` | Shop address |
| `telegram_chat_id` | Telegram chat ID for backup (optional) |
| `backup_passphrase_hint` | Hint for the backup encryption passphrase |

The actual Telegram bot token and backup encryption passphrase are stored in `flutter_secure_storage`, NOT in `shop_settings`.

---

## 9. Data Integrity Invariants

These must ALWAYS be true in the database. Any code that could violate these is a critical bug:

1. **Financial balance:** `SUM(payments.amount WHERE application_id = X AND deleted_at IS NULL) = applications.total_received` (this is computed, not stored — but queries must produce consistent results)
2. **Snapshot immutability:** `applications.applicant_name` is never NULL after creation
3. **Soft delete consistency:** No record has `deleted_at` set to a future timestamp
4. **Status history integrity:** Every `status_history` record has a valid `application_id` referencing an existing (possibly soft-deleted) application
5. **Money non-negative:** `payments.amount > 0`, `expenses.amount > 0`, `independent_incomes.amount > 0` — all transaction amounts must be positive; negative income is expressed through the calculation formula, not negative amounts
6. **Status validity:** `applications.status` must be one of the 10 valid status values

---

## 10. Unresolved Business Questions

These questions require user clarification before implementation:

### BRQ-001: Application Number Uniqueness
**Question:** If a duplicate application number is detected, should the system:
- A) Block the submission (hard validation error), or
- B) Show a warning and allow the user to proceed (soft warning)
**Current UI:** Shows a warning (soft). Backend should match.  
**Status:** Assumed soft warning — pending user confirmation.

### BRQ-002: Maximum Payments Per Application
**Question:** Is there a business limit on the number of payment installments per application?  
**Status:** No limit assumed — pending user confirmation.

### BRQ-003: Status Reversion
**Question:** Can a status be changed backwards (e.g., from `'মঞ্জুর'` back to `'শুনানি'`)?  
**Status:** Yes, all status changes allowed in any direction — pending user confirmation.

### BRQ-004: Application Number Format
**Question:** Is there a specific format required for application numbers (numeric only, length, prefix)?  
**Status:** No format constraint assumed — free text — pending user confirmation.

### BRQ-005: Reference Commission Tracking
**Question:** The `ReferenceDetailScreen` shows financial totals for applications a reference person brought in. Is there a commission calculation for reference persons, or is this purely informational?  
**Status:** Informational only assumed — pending user confirmation.

