# রজব ভূমি সেবা ঘর — Complete Development Plan

## 1. Project Summary

| Item | Detail |
|---|---|
| **App Name** | রজব ভূমি সেবা ঘর |
| **Platform** | Android (Flutter) |
| **Architecture** | Offline-first, single-user, no backend |
| **Language** | Dart / Flutter 3.41.x |
| **Database** | SQLite (via `drift` — formerly `moor`) |
| **Target User** | A land services professional managing applications, customers, finances, and tasks from a local shop |

---

## 2. Requirements Analysis

### 2.1 Core Business Workflow & Package Contract Model

The user operates a local land services shop in Bangladesh (রজব ভূমি সেবা ঘর). Customers visit the shop requesting land-related services (e-Mutation / ই-নামজারি, partition / জমাভাগ, correction / খতিয়ান সংশোধন, etc.). 

**Primary Operating Model — এককালীন প্যাকেজ চুক্তি ও প্রকৃত ইনকাম ট্র্যাকিং (All-inclusive Package Deal & Realized Income Tracking):**
- In most cases, the shopkeeper agrees on a total package fee with the customer upfront (e.g., ৳৮,০০০ or ৳১০,০০০) including all government fees, field expenses, and service charges.
- The customer often pays the entire contracted fee all at once (or in 1-2 installments).
- As processing progresses through official channels (Union Land Office, AC Land Office, Field Surveyors), the shopkeeper spends money at various steps from their cash in hand (govt online application fee ৳৭০, field inquiry/survey costs, hearing travel/clerk costs, DCR & khatian fee ৳১,১০০).
- **Core App Objective:** Track all incremental step-by-step expenses against the file, so that upon completion the user sees exactly how much actual service income they earned from the file (`প্রকৃত ইনকাম = মোট আদায় – মোট কাজের খরচ`).
  * *Important Accounting Principle:* If a contract is ৳8,000, but customer actually pays ৳7,500 and ৳3,000 is spent on file steps, the realized income is strictly $৳৭,৫০০ - ৳৩,০০০ = \mathbf{৳৪,৫০০}$ (never ৳5,000). Uncollected money is tracked as due.

**Workflow Steps:**
1. Collects customer info and records agreed package fee (and immediate full/partial payment).
2. Submits the actual application through official portals (`mutation.land.gov.bd`).
3. Records application details in **this app** for end-to-end tracking.
4. Manages payments received (single full payment or multiple installments).
5. Updates stage-based statuses via an interactive dialog with **instant stage expense recording** (e.g., quick ৳৭০ for application, ৳১,১০০ for DCR, ৳৩০০ for hearing).
6. Records ad-hoc file expenses anytime (photocopies, deeds, conveyance) with dedicated "+ খরচ লিখুন" action.
7. Tracks expenses strictly categorizing **specific application expenses** vs **general shop overhead expenses**.
8. Records **independent non-application income** (other services, computer typing, printing, personal business) completely isolated from application service payments.
9. Manages hearing dates with automatic task and reminder creation.
10. Reviews net income, outstanding dues, and cashflow analytics across all files.

**Key Financial Separation Principles:**
1. **Application-related income:** Tied to an application (contract installments, advance, or full payment).
2. **Other independent income:** Standalone revenue not requiring any application and never mixed with application contracts.
3. **Application-related expenses:** Directly spent on a specific file (govt fees, challan, copying, travel, status stage expenses) deducting directly to determine the file's realized income.
4. **General shop expenses:** Overhead costs (shop rent, electricity, broadband internet, stationery) with no application link.
5. **Cash-based accounting & net income clarity:** The system prominently displays `প্রকৃত ইনকাম` (`receivedAmount - expenseAmount`) at both the detail level and in financial ledgers.

### 2.2 Feature Summary

| # | Feature | Priority |
|---|---|---|
| 1 | Application (আবেদন ও মৌজা) Management | Critical |
| 2 | Person (আবেদনকারী গ্রাহক) Management | Critical |
| 3 | Reference (রেফারেন্স ব্যক্তি ও খাতা) Management | Critical |
| 4 | Office (অফিস) Management | High |
| 5 | Financial Management (পেমেন্ট, খরচ, ইনকাম) | Critical |
| 6 | Application Status & History | Critical |
| 7 | Document/PDF Attachment | High |
| 8 | Task Management (কাজ) | High |
| 9 | Dashboard | High |
| 10 | Search, Filter & Sort | Critical |
| 11 | Reports & Analytics | Medium-High |
| 12 | Offline & Cloud Backup (ফোনে ব্যাকআপ এক্সপোর্ট/ইমপোর্ট ও টেলিগ্রাম ক্লাউড) | High |
| 13 | Category & Shop Management (কাজের ধরন, খরচের খাত ও দোকান পরিচিতি) | Medium |

---

## 3. Technical Architecture

### 3.1 Stack Decisions

| Concern | Choice | Rationale |
|---|---|---|
| **State Management** | Riverpod (v2) | Type-safe, testable, scalable, excellent for offline-first apps. Avoids boilerplate of BLoC while being more structured than Provider. |
| **Routing** | GoRouter | Declarative, deep-link support, clean URL-based navigation, official Flutter package. |
| **Database** | Drift (SQLite) | Type-safe SQL, compile-time query verification, migrations, transactions, WAL mode support, DAOs. Superior to raw sqflite for a data-heavy app. |
| **PDF Viewing** | pdfx or syncfusion_flutter_pdfviewer (free tier) | In-app PDF preview without external apps. |
| **File Picking** | file_picker | Cross-platform file selection for PDFs and images. |
| **Local Notifications** | flutter_local_notifications | Mature, well-maintained, supports scheduled notifications. |
| **Charts** | fl_chart | Lightweight, customizable, no platform dependencies. |
| **Secure Storage** | flutter_secure_storage | For Telegram bot token and encryption keys. |
| **Encryption** | encrypt (AES) | For backup file encryption before Telegram upload. |
| **Date/Time** | intl | Formatting, localization, Bengali date display. |
| **Bengali Font** | Bundled Noto Sans Bengali | Offline Bengali rendering guaranteed. |
| **Image Handling** | image_picker + image compression | Camera/gallery capture with size optimization. |
| **HTTP (Telegram only)** | dio | Reliable HTTP client for Telegram Bot API backup/restore. |
| **Path Management** | path_provider + path | Standard file system access. |
| **UUID** | uuid | Unique application IDs. |
| **Share/Export** | share_plus, printing | PDF export for reports. |

### 3.2 Project Structure (Feature-Based)

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   ├── app_spacing.dart
│   │   ├── app_strings.dart        # All Bengali strings
│   │   └── app_constants.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── theme_extensions.dart
│   ├── router/
│   │   └── app_router.dart
│   ├── database/
│   │   ├── app_database.dart
│   │   ├── app_database.g.dart
│   │   └── migrations.dart
│   ├── utils/
│   │   ├── money.dart              # Integer-based money type
│   │   ├── date_utils.dart
│   │   ├── validators.dart
│   │   └── extensions.dart
│   └── widgets/                    # Shared reusable widgets
│       ├── app_bar.dart
│       ├── app_button.dart
│       ├── app_text_field.dart
│       ├── app_search_bar.dart
│       ├── money_field.dart
│       ├── date_picker_field.dart
│       ├── status_badge.dart
│       ├── summary_card.dart
│       ├── empty_state.dart
│       ├── loading_state.dart
│       ├── error_state.dart
│       ├── filter_bottom_sheet.dart
│       ├── confirm_dialog.dart
│       ├── person_selector.dart
│       ├── office_selector.dart
│       └── ...
├── features/
│   ├── dashboard/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   └── dashboard_screen.dart
│   │   │   └── widgets/
│   │   │       ├── stats_overview.dart
│   │   │       ├── financial_summary.dart
│   │   │       ├── recent_applications.dart
│   │   │       ├── today_tasks.dart
│   │   │       └── quick_actions.dart
│   │   └── providers/
│   │       └── dashboard_provider.dart
│   ├── applications/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── application_model.dart
│   │   │   │   └── status_history_model.dart
│   │   │   └── daos/
│   │   │       └── application_dao.dart
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── application_list_screen.dart
│   │   │   │   ├── application_create_screen.dart
│   │   │   │   ├── application_detail_screen.dart
│   │   │   │   └── application_edit_screen.dart
│   │   │   └── widgets/
│   │   │       ├── application_card.dart
│   │   │       ├── application_filter.dart
│   │   │       ├── status_history_timeline.dart
│   │   │       ├── status_change_dialog.dart
│   │   │       └── ...
│   │   └── providers/
│   │       ├── application_provider.dart
│   │       └── application_filter_provider.dart
│   ├── persons/
│   │   ├── data/
│   │   ├── presentation/
│   │   └── providers/
│   ├── references/
│   │   ├── data/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── reference_list_screen.dart
│   │   │   │   └── reference_detail_screen.dart
│   │   │   └── widgets/
│   │   │       ├── reference_card.dart
│   │   │       ├── reference_stats_row.dart
│   │   │       └── reference_selector_sheet.dart
│   │   └── providers/
│   ├── offices/
│   │   ├── data/
│   │   ├── presentation/
│   │   └── providers/
│   ├── finance/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── payment_model.dart
│   │   │   │   ├── expense_model.dart
│   │   │   │   ├── income_model.dart             # Independent income model
│   │   │   │   ├── transaction_model.dart        # Unified transaction view model
│   │   │   │   └── financial_summary_model.dart
│   │   │   └── daos/
│   │   │       └── finance_dao.dart
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── financial_overview_screen.dart # Two primary action buttons, KPI cards, chart, dues
│   │   │   │   ├── payment_form_screen.dart      # Application installment payment
│   │   │   │   ├── income_form_screen.dart       # Dedicated independent income entry
│   │   │   │   ├── expense_form_screen.dart      # Specific work vs general shop expenses
│   │   │   │   ├── transaction_history_screen.dart # Multi-criteria filterable ledger
│   │   │   │   └── due_management_screen.dart    # Outstanding due tracker & reminder calls
│   │   │   └── widgets/
│   │   └── providers/
│   ├── tasks/
│   │   ├── data/
│   │   ├── presentation/
│   │   └── providers/
│   ├── documents/
│   │   ├── data/
│   │   ├── presentation/
│   │   └── providers/
│   ├── reports/
│   │   ├── presentation/
│   │   └── providers/
│   ├── backup/
│   │   ├── data/
│   │   ├── presentation/
│   │   └── providers/
│   └── settings/
│       ├── presentation/
│       └── providers/
├── l10n/                           # Localization if needed
└── gen/                            # Generated files
```

### 3.3 Database Schema (Production-Aligned with Zero Hard Delete & Historical Snapshots)

```
┌───────────────────────────┐     ┌──────────────────────────────────────────────┐     ┌───────────────────────────┐
│          persons          │     │                 applications                 │     │          offices          │
├───────────────────────────┤     ├──────────────────────────────────────────────┤     ├───────────────────────────┤
│ id (TEXT PK UUID)         │◄────│ applicant_id (TEXT FK NULL)                  │     │ id (TEXT PK UUID)         │
│ name (TEXT NOT NULL)      │     │ applicant_name (TEXT NOT NULL - Snapshot)    │     │ name (TEXT NOT NULL)      │
│ phone (TEXT NOT NULL)     │     │ applicant_phone (TEXT NOT NULL - Snapshot)   │     │ created_at (INTEGER DT)   │
│ address (TEXT NULL)       │     │ applicant_address (TEXT NULL - Snapshot)     │     │ updated_at (INTEGER DT)   │
│ photo (BLOB NULL)         │     │ reference_id (FK TEXT NULL)─┬────────────────┤     │ deleted_at (INTEGER NULL) │
│ notes (TEXT NULL)         │     │ reference_name (TEXT NULL - Snapshot)        │     └───────────────────────────┘
│ created_at (INTEGER DT)   │     │ office_id (TEXT FK NULL)                     │
│ updated_at (INTEGER DT)   │     │ office_name (TEXT NOT NULL - Snapshot)       │  ┌───────────────────────────┐
│ deleted_at (INTEGER NULL) │     │ mouza (TEXT NULL)                            │  │        references         │
└───────────────────────────┘     │ app_number (TEXT NULL)                       │  ├───────────────────────────┤
                                  │ case_number (TEXT NULL)                      │  │ id (TEXT PK UUID)         │
                                  │ work_type (TEXT NOT NULL)                    │  │ name (TEXT NOT NULL)      │
                                  │ application_date (INT DT)                    │  │ phone (TEXT NOT NULL)     │
                                  │ status (TEXT NOT NULL)                       │  │ address (TEXT NULL)       │
                                  │ agreed_amount (INT Paisa)                    │  │ photo (BLOB NULL)         │
                                  │ is_marked_as_paid (BOOL)                     │  │ notes (TEXT NULL)         │
                                  │ notes (TEXT NULL)                            │  │ created_at (INTEGER DT)   │
                                  │ created_at (INTEGER DT)                      │  │ updated_at (INTEGER DT)   │
                                  │ updated_at (INTEGER DT)                      │  │ deleted_at (INTEGER NULL) │
                                  │ deleted_at (INTEGER NULL)                    │  └───────────────────────────┘
                                  └──────────────────────┬───────────────────────┘
                                                         │
                     ┌───────────────────────────────────┼───────────────────────────────────┐
                     │                                   │                                   │
      ┌──────────────┴──────────────┐     ┌──────────────┴──────────────┐     ┌──────────────┴──────────────┐
      │          payments           │     │          expenses           │     │          documents          │
      ├─────────────────────────────┤     ├─────────────────────────────┤     ├─────────────────────────────┤
      │ id (TEXT PK UUID)           │     │ id (TEXT PK UUID)           │     │ id (TEXT PK UUID)           │
      │ application_id (TEXT FK)    │     │ application_id (TEXT NULL)  │     │ application_id (TEXT FK)    │
      │ amount (INT Paisa)          │     │ amount (INT Paisa)          │     │ file_name (TEXT NOT NULL)   │
      │ date (INTEGER DT)           │     │ category (TEXT NOT NULL)    │     │ file_type (TEXT NOT NULL)   │
      │ method (TEXT NOT NULL)      │     │ date (INTEGER DT)           │     │ file_data (BLOB NOT NULL)   │
      │ note (TEXT NULL)            │     │ is_general (BOOL NOT NULL)  │     │ file_size (TEXT NOT NULL)   │
      │ status_history_id (TEXT FK) │     │ note (TEXT NULL)            │     │ created_at (INTEGER DT)     │
      │ status_name (TEXT NULL)     │     │ status_history_id (TEXT FK) │     │ deleted_at (INTEGER NULL)   │
      │ is_status_fee (BOOL)        │     │ status_name (TEXT NULL)     │     └─────────────────────────────┘
      │ created_at (INTEGER DT)     │     │ is_status_exp (BOOL)        │
      │ deleted_at (INTEGER NULL)   │     │ created_at (INTEGER DT)     │
      └─────────────────────────────┘     │ deleted_at (INTEGER NULL)   │
                                          └─────────────────────────────┘
                     ┌────────────────────────────┐
                     │       status_history       │
                     ├────────────────────────────┤
                     │ id (TEXT PK UUID)          │
                     │ application_id (TEXT FK)   │
                     │ prev_status (TEXT NOT NULL)│
                     │ new_status (TEXT NOT NULL) │
                     │ changed_at (INTEGER DT)    │
                     │ note (TEXT NULL)           │
                     └────────────────────────────┘

┌─────────────────────────┐     ┌───────────────────────────────────┐     ┌─────────────────────────┐
│   independent_incomes   │     │               tasks               │     │      shop_settings      │
├─────────────────────────┤     ├───────────────────────────────────┤     ├─────────────────────────┤
│ id (TEXT PK UUID)       │     │ id (TEXT PK UUID)                 │     │ key (TEXT PK)           │
│ category (TEXT NOT NULL)│     │ title (TEXT NOT NULL)             │     │ value (TEXT NOT NULL)   │
│ amount (INT Paisa)      │     │ description (TEXT NULL)           │     │ updated_at (INTEGER DT) │
│ date (INTEGER DT)       │     │ due_date (INTEGER DT NOT NULL)    │     └─────────────────────────┘
│ payment_method (TEXT)   │     │ due_time (TEXT NULL)              │
│ customer_name (TEXT)    │     │ priority (TEXT NOT NULL)          │
│ note (TEXT NULL)        │     │ status (TEXT NOT NULL)            │
│ created_at (INTEGER DT) │     │ category (TEXT NOT NULL)          │
│ deleted_at (INT NULL)   │     │ application_id (TEXT FK NULL)     │
└─────────────────────────┘     │ completed_at (INTEGER DT NULL)    │
                                │ created_at (INTEGER DT)           │
                                │ updated_at (INTEGER DT)           │
                                │ deleted_at (INTEGER NULL)         │
                                └───────────────────────────────────┘

┌───────────────────────────┐     ┌───────────────────────────┐     ┌───────────────────────────┐
│        work_types         │     │    expense_categories     │     │     income_categories     │
├───────────────────────────┤     ├───────────────────────────┤     ├───────────────────────────┤
│ id (TEXT PK UUID)         │     │ id (TEXT PK UUID)         │     │ id (TEXT PK UUID)         │
│ name (TEXT NOT NULL)      │     │ name (TEXT NOT NULL)      │     │ name (TEXT NOT NULL)      │
│ is_default (BOOL)         │     │ is_general (BOOL NOT NULL)│     │ is_default (BOOL)         │
│ created_at (INTEGER DT)   │     │ is_default (BOOL NOT NULL)│     │ created_at (INTEGER DT)   │
│ deleted_at (INTEGER NULL) │     │ created_at (INTEGER DT)   │     │ deleted_at (INTEGER NULL) │
└───────────────────────────┘     │ deleted_at (INTEGER NULL) │     └───────────────────────────┘
                                  └───────────────────────────┘
```

**Key Schema Decisions (Zero Hard Delete & Snapshot Isolation):**

- **Zero Hard Deletes (`deleted_at INTEGER NULL`):** কোনো রেকর্ড কখনো ফিজিক্যালি ডেটাবেজ থেকে মোছা হবে না। ডিলিট অ্যাকশন কেবল সফট ডিলিট টাইমস্ট্যাম্প বসাবে।
- **Historical Snapshot Preservation:** `applications` টেবিলে `reference_name`, `applicant_name`, `applicant_phone`, `applicant_address` এবং `office_name` স্বাধীন কলাম হিসেবে স্থায়ীভাবে সংরক্ষিত থাকবে। যদি রেফারেন্স ব্যক্তি বা গ্রাহককে তার প্রোফাইল লিস্ট থেকে মুছেও ফেলা হয়, তবু আবেদনের ফাইলে ও ডিটেইল স্ক্রিনে রেফারেন্স ব্যক্তির নাম ও সকল হিসাব অবিকল এবং নির্ভুল থাকবে।
- **Calculation Immunity:** যেকোনো আইটেম ডিলিট হলেও পূর্বের ফিন্যান্সিয়াল হিসাব বা ক্যাশ ব্যালেন্সে কোনো গরমিল হবে না।
- **Money stored as integers** (paisa/smallest unit) to avoid floating-point errors. ৳7,000 = 700000 in storage.
- **`is_marked_as_paid` in `applications`:** Crucial business requirement added during UI development. When a customer pays partial money (e.g. ৳6,500 of ৳7,000) and the rest ৳500 is waived or settled, this boolean flag ensures outstanding dues drop to ৳0 while preserving the raw difference for historical audit.
- **`category` & `completed_at` in `tasks`:** Extended to support the 6 business task categories (`⚖️ শুনানি`, `📄 কাগজপত্র`, `💰 ফি/তাগাদা`, `🏛️ অফিস জমা`, `📦 ডেলিভারি`, `📌 সাধারণ`) and exact completion timestamps.
- **Dedicated Independent Income table (`independent_incomes`)** ensures non-application revenue (printing, computer services, photocopying, deed typing) is completely isolated from application contracts.
- **Status history linkage (`status_history_id` & `status_name`):** Payments and expenses generated during a status transition (e.g., govt application fee ৳৭০, hearing expense ৳৩০০, DCR fee ৳১,১০০) retain a foreign key to `status_history` and store the `status_name` for instant audit trail.
- **Documents stored as BLOBs** inside SQLite so phone backups and Telegram snapshots are fully self-contained.
- **`is_general` flag on expenses** clearly separates file-specific work expenses (which directly reduce that file's net income) from shop overheads.
- **`shop_settings` table:** Key-value persistence for shop profile and backup configurations.
- **Foreign keys enforced** with `PRAGMA foreign_keys = ON` and `ON DELETE SET NULL` for parent relationships to prevent cascade deletions.
- **WAL mode enabled** for concurrent access and clean backup snapshots.

### 3.4 Financial Architecture

```
Per Application:
  agreed_amount             = Total service fee agreed with customer
  total_received            = SUM(payments WHERE application_id = X)  [includes contract installments & status fees]
  raw_due                   = agreed_amount - total_received
  effective_due             = is_marked_as_paid ? 0 : raw_due
  application_expenses      = SUM(expenses WHERE application_id = X AND is_general = false)  [includes work costs & status expenses]
  estimated_income          = agreed_amount - application_expenses
  actual_realized_income    = total_received - application_expenses

Global Financial Totals:
  total_app_income          = SUM(all application payments & status fee receipts)
  total_independent_income  = SUM(all independent non-application incomes)
  grand_total_income        = total_app_income + total_independent_income

  total_app_expense         = SUM(all file-specific work expenses & status expenses)
  total_general_expense     = SUM(all shop overhead expenses: rent, electricity, net, etc.)
  grand_total_expense       = total_app_expense + total_general_expense

  net_business_income       = grand_total_income - grand_total_expense
  total_outstanding_due     = SUM(effective_due) for all applications where is_marked_as_paid = false AND raw_due > 0
```

**Accounting Rules:**
1. **Cash-Basis Principle:** Unpaid service fees are NEVER counted as revenue. Agreed service fee is an expectation; only money actually received in hand/account counts as income.
2. **Pass-Through / Government Fees:** Government fees (e.g. DCR fee, court fee, online challan) are tracked as application expenses. They are deducted directly from customer payments to determine the file's actual service income without distorting business revenue.
3. **Single Source of Truth:** Every payment is recorded only once in `payments`, every expense only in `expenses`, and every independent income only in `independent_incomes`. Global ledger aggregates these dynamically with zero duplication.

### 3.5 Money Type

A custom `Money` class wrapping `int` (paisa):
- Constructor from taka: `Money.fromTaka(7000)` → stores `700000`
- Display: `money.toTakaString()` → `"৳৭,০০০"`
- Arithmetic: `+`, `-`, `*` all integer-safe
- Comparison operators
- JSON/SQLite serialization

### 3.6 Backup & Data Safety Strategy

1. **অফলাইন সম্পূর্ণ ফোন ব্যাকআপ (Full Offline Phone Export):**
   - `PRAGMA wal_checkpoint(TRUNCATE)` দিয়ে WAL ফ্ল্যাশ করে `VACUUM INTO` দিয়ে নিরাপদ, আনফ্র্যাগমেন্টেড একক `.db` ফাইল হিসেবে ডাউনলোড বা ডকুমেন্ট ফোল্ডারে সেভ।
   - সম্পূর্ণ ডেটাবেজ (সকল তথ্য ও সংযুক্ত খতিয়ান/দলিলের পিডিএফ সহ) ১০০% সংরক্ষিত থাকে।
   - **স্টোরেজ প্রুনিং:** স্টোরেজ ফাঁকা রাখতে সর্বদা সর্বশেষ ৫টি ব্যাকআপ ফাইল রেখে অতিরিক্ত পুরনো ব্যাকআপ স্বয়ংক্রিয়ভাবে মুছে ফেলা হয়।

2. **টেলিগ্রাম ক্লাউড ব্যাকআপ (হালকা ও টোকেন-সুরক্ষিত - Lightweight Telegram Backup):**
   - **টোকেন পৃথকীকরণ (App-Private File):** বট টোকেন ও চ্যাট আইডি SQLite ডাটাবেজে রাখা হয় না। এগুলো অ্যাপের নিজস্ব প্রাইভেট ফাইল স্টোরেজে (`TelegramConfigStore`) সংরক্ষিত থাকে। ফলে ব্যাকআপ ফাইল এক্সপোর্ট বা অন্য কোথাও পাঠালেও বটের কোনো গোপন তথ্য ডেটাবেজে ফাঁস হয় না।
   - **টেলিগ্রাম ফাইল সাইজ সীমা:** টেলিগ্রাম বট এপিআই প্রতি একক ফাইলে সর্বোচ্চ ৫০ MB আপলোড সাপোর্ট করে (তবে মোট ক্লাউড স্টোরেজ আনলিমিটেড)।
   - **পিডিএফ বাইনারি ব্লব ছাঁটাই:** টেলিগ্রামের ৫০ MB সীমা ও ধীরগতির মোবাইল ডাটার সুরক্ষায় টেম্পোরারি ব্যাকআপ ফাইলে `UPDATE documents SET file_data = zeroblob(0)` চালানো হয়।
   - **SQLite VACUUM কম্প্যাকশন:** খালি হওয়া বাইনারি পৃষ্ঠাগুলোকে `VACUUM;` চালিয়ে ডিস্কে রিলিজ করা হয়, যার ফলে ব্যাকআপ ফাইলের আকার কয়েকশো মেগাবাইট থেকে নেমে মাত্র ২০০–৫০০ কিলোবাইটে চলে আসে।
   - **জিরো-র্যাম মেমোরি সেফ স্ট্রিমিং:** র্যামে পুরো ফাইল লোড না করে `request.addStream(file.openRead())` দিয়ে সরাসরি ডিস্ক থেকে স্ট্রিম আপলোড করা হয়।
   - **দৈনিক অটো-ব্যাকআপ (Everyday Background Auto-Backup):** অ্যাপ ওপেন হলে ব্যাকগ্রাউন্ডে নীরবে আজকের দিনের ব্যাকআপ সম্পন্ন হয় (আইডিমপোটেন্ট: দিনে সর্বোচ্চ একবার)।

3. **জিরো ডাটা লস রিস্টোর ও ভুল রিস্টোর প্রটেকশন (Zero Data Loss Restore & Pre-Restore Archiving):**
   - ব্যাকগ্রাউন্ড আইসোলেটে (`Isolate.run`) `PRAGMA integrity_check` ও `PRAGMA quick_check` যাচাই।
   - ফাইল পিকার ফিল্টারিং: শুধুমাত্র বৈধ `.db` ও `.sqlite` ফাইল বাছাই করার কঠোর ফিল্টার।
   - **সেফটি আর্কাইভ কপি:** রিস্টোরের আগে বর্তমান লাইভ ডাটার একটি স্থায়ী টাইমস্ট্যাম্পযুক্ত সেফটি কপি (`rojob_bhumi_pre_restore_[timestamp].sqlite`) সংরক্ষিত রাখা হয়, যাতে ইউজার ভুল করে পুরানো ব্যাকআপ রিস্টোর করে ফেললেও বর্তমান ডেটা উদ্ধার করা যায়।
   - ফাইল সোয়াপ ব্যর্থ হলে স্বয়ংক্রিয় রোলব্যাক ও কানেকশন রিকভারি।
   - রিস্টোরকৃত ফাইলে পুরনো কোনো টেলিগ্রাম টোকেন থাকলে তা স্বয়ংক্রিয়ভাবে মুছে ফেলা হয়।

---

## 4. Design Direction

### 4.1 Visual Identity (Modern Fintech & SaaS Palette)

| Element | Decision |
|---|---|
| **Primary Color** | Modern Indigo (`#4F46E5`) — Confident, premium, vibrant fintech vibe |
| **Primary Dark** | Deep Indigo (`#3730A3`) — For headers, focus states |
| **Primary Light** | Soft Indigo (`#EEF2FF` / `#E0E7FF`) — Light tint containers, badges |
| **Secondary (Success/Income)** | Vibrant Emerald (`#10B981`) — Income, profit, positive outcomes |
| **Accent / Warning / Due** | Warm Rose (`#F43F5E`) & Golden Amber (`#F59E0B`) — Dues, urgency, alerts |
| **Background** | Slate Off-White (`#F8FAFC`) — Crisp, modern canvas |
| **Surface** | Clean Pure White (`#FFFFFF`) — Cards with soft border/subtle shadow |
| **Surface Variant** | Soft Slate (`#F1F5F9`) — Section containers, chips |
| **Border** | Subtle Slate Border (`#E2E8F0`) |
| **Text Primary** | Deep Slate (`#0F172A`) — High legibility |
| **Text Secondary** | Medium Slate (`#475569`) |
| **Text Tertiary** | Muted Slate (`#94A3B8`) |
| **Success** | Emerald (`#10B981`) |
| **Warning** | Amber (`#F59E0B`) |
| **Error / Urgent** | Rose (`#F43F5E`) |
| **Info** | Sky Blue (`#0284C7`) |

### 4.2 Status Colors (Vibrant & Distinguishable)

| Status | Bengali | Workflow Group | Color | Hex |
|---|---|---|---|---|
| আবেদন | Application | Happy Flow (1) | Sky Blue | `#0284C7` |
| প্রস্তাব প্রেরণ | Proposal Sent | Happy Flow (2) | Indigo | `#6366F1` |
| শুনানি | Hearing | Happy Flow (3) | Violet | `#8B5CF6` |
| মঞ্জুর | Approved (পাস) | Happy Flow (4) | Emerald | `#10B981` |
| ডিসিআর প্রস্তুত | DCR Issued (DCR) | Happy Flow (5) | Cyan | `#06B6D4` |
| সম্পন্ন | Completed | Happy Flow (6) | Green | `#16A34A` |
| অপেক্ষমাণ | Waiting | Exception | Amber | `#F59E0B` |
| আপত্তি | Objection | Exception | Orange | `#EA580C` |
| সংশোধন প্রয়োজন | Correction Needed | Exception | Rose | `#F43F5E` |
| নামঞ্জুর | Rejected (বাতিল) | Exception | Slate | `#64748B` |

### 4.3 Typography (Crisp Bengali Scale)

| Style | Font | Size | Weight |
|---|---|---|---|
| Display Large | Noto Sans Bengali | 30sp | Bold (700) |
| Heading Large | Noto Sans Bengali | 24sp | Bold (700) |
| Heading Medium | Noto Sans Bengali | 20sp | SemiBold (600) |
| Heading Small | Noto Sans Bengali | 17.5sp | SemiBold (600) |
| Title Medium | Noto Sans Bengali | 16sp | Medium (500) |
| Body Large | Noto Sans Bengali | 16sp | Regular (400) |
| Body Medium | Noto Sans Bengali | 14.5sp | Regular (400) |
| Body Small | Noto Sans Bengali | 13sp | Regular (400) |
| Label Medium | Noto Sans Bengali | 13sp | SemiBold (600) |
| Bottom Nav Active | Noto Sans Bengali | 12.5sp | Bold (700) |
| Bottom Nav Inactive | Noto Sans Bengali | 11.5sp | Medium (500) |
| Money Display | Noto Sans Bengali | 28sp | Bold (700) |
| Money Medium | Noto Sans Bengali | 19sp | Bold (700) |
| Money Small | Noto Sans Bengali | 15sp | SemiBold (600) |

### 4.4 Spacing System (4px base)

| Token | Value |
|---|---|
| xs | 4px |
| sm | 8px |
| md | 12px |
| base | 16px |
| lg | 20px |
| xl | 24px |
| 2xl | 32px |
| 3xl | 40px |
| 4xl | 48px |

### 4.5 Component Dimensions

| Component | Spec |
|---|---|
| Border Radius (cards) | 12px |
| Border Radius (buttons) | 8px |
| Border Radius (inputs) | 8px |
| Border Radius (chips/badges) | 16px (pill) |
| Card Elevation | 1-2 (subtle) |
| Button Height | 48px |
| Input Height | 52px |
| App Bar Height | 56px |
| FAB Size | 56px |
| Icon Size (default) | 24px |
| Icon Size (small) | 20px |
| Touch Target Min | 44px |

### 4.6 Navigation

**Bottom Navigation Bar** with 5 primary destinations:
1. **ড্যাশবোর্ড** (Dashboard) — Home/Dashboard icon (Privacy-first operational landing)
2. **আবেদন** (Applications) — Description/document icon
3. **হিসাব** (Finance) — Account balance/wallet icon (Live cashflow ledger)
4. **বিশ্লেষণ** (Analytics) — Analytics/chart icon (Interactive Business Intelligence Dashboard)
5. **মেনু** (Menu) — Grid view/menu icon (Records management & cloud backup)

**Reasoning:** Placing **বিশ্লেষণ (Analytics)** as a dedicated 4th tab separates live transactional ledger management from strategic business intelligence and trends analysis, eliminates duplicate report sub-screens, and keeps the 5th tab (মেনু) cleanly focused on records and data backup.

---

## 5. Screen Inventory

### 5.1 Complete Screen List (28 Screens)

| # | Screen | Description |
|---|---|---|
| 1 | Dashboard | Privacy-first operational view (search, quick actions, hearing schedule, pipeline, recent apps, task notification badge) |
| 2 | Application List | Searchable, filterable list of all applications with multi-filter sheet, mouza badge, left status accent border, and 3-column financial summary inset |
| 3 | Application Create | Modern 3-Step Wizard (Client info + address + auto-fill, Work & Office + mouza, Agreement + summary card + reference + docs) with strict per-step validation |
| 4 | Application Detail | Modernized tabbed detail view (Info with call shortcut & reference link, Connected vertical Progress Timeline, Finance with Hero Net Profit banner & 2x2 grid, Documents with file badges) |
| 5 | Application Edit | Edit existing application information including address, reference person and mouza |
| 6 | Person List | All saved applicant persons with search & call shortcuts |
| 7 | Person Create/Edit | Add or edit an applicant person |
| 8 | Person Detail | Person profile + their applications (as applicant) + financial ledger |
| 9 | Office Management | Land offices list with add/edit/delete |
| 10 | Financial Overview | Live monthly income, expense, profit with clean cashflow charts, dues list & dual FABs |
| 11 | Payment Form | Record a payment with one-click full due settlement and mark-as-paid option |
| 12 | Income Form | Record independent/shop service income (computer, printing, deeds) |
| 13 | Expense Form | Record an expense (application-specific or shop general) |
| 14 | Transaction History | All payments, independent incomes, and expenses with multi-criteria filters |
| 15 | Due Management | Outstanding dues list, phone shortcuts, mark as paid action, and direct PDF report download |
| 16 | Task List | All tasks with 5 status tabs (Today, To-do, In-progress, Done, All), priority chips, and 1-tap checkbox |
| 17 | Task Create/Edit | Add or edit a task with 6 categories, shortcuts, and application linkage |
| 18 | Task Detail | Task details with 3-step directional status stepper & linked application shortcut |
| 19 | Analytics Dashboard | Interactive visual dashboard with period filters, 4 executive KPIs, multi-month revenue curve, work-type donut chart, pipeline funnel, office metrics & business insights |
| 20 | Report Detail | Category drill-down with detailed data tables and statistics |
| 21 | Document Viewer | PDF/image preview screen with share action |
| 22 | Backup & Restore | Local phone export/import (.db in Downloads) & Telegram bot snapshot backup |
| 23 | Category Management | Work types & expense categories (work-specific vs general shop) management |
| 24 | Reference List | Dedicated reference ledger with search, total stats banner, status chips, and call shortcuts |
| 25 | Reference Detail | Complete reference profile (photo, name, phone, address, notes), financial totals, and application history |
| 26 | More Menu | Simplified 2-section management hub (Daily Records including Reference ledger + System Backup & clean developer footer) |
| 27 | Status Change Dialog | Quick status selector with BD land workflow steps, hearing scheduling & instant stage expense/fee recording |
| 28 | Main Shell | 5-tab production navigation container (Dashboard, Applications, Finance, Analytics, Menu) |

### 5.2 Key Dialogs & Bottom Sheets

| Component | Usage |
|---|---|
| Status Change Dialog | Select new status + optional note |
| Filter Bottom Sheet | Multi-criteria filter for applications |
| Person Selector | Search and select or create an applicant person |
| Reference Selector Sheet | Search and select or create a reference person inline |
| Office Selector | Select or add an office |
| Work Type Selector | Select or add a work type |
| Payment Method Selector | Choose payment method |
| Date Range Picker | Custom date range for filters/reports |
| Delete Confirmation | Confirm destructive actions |
| Backup Progress | Upload progress indicator |
| Restore Confirmation | Warning before restore |

---

## 6. Navigation Map

```
App Launch
  └─ Bottom Navigation (5 Tabs)
      ├─ ১. ড্যাশবোর্ড (Dashboard)
      │   ├─ [instant search] → Application List (searched)
      │   ├─ [quick action: নতুন আবেদন] → Application Create
      │   ├─ [quick action: নতুন কাজ] → Task Create
      │   ├─ [quick action: গ্রাহক খাতা] → Person List
      │   ├─ [quick action: অফিস সমূহ] → Office Management
      │   ├─ [tap hearing/task] → Task Detail
      │   ├─ [tap pipeline counter] → Application List (filtered by status)
      │   ├─ [tap application] → Application Detail
      │   └─ [FAB: +] → Application Create
      │
      ├─ ২. আবেদন (Applications)
      │   ├─ [search/filter] → Filter Bottom Sheet
      │   ├─ [tap application] → Application Detail
      │   │   ├─ [edit] → Application Edit
      │   │   ├─ [change status] → Status Change Dialog
      │   │   ├─ [tap reference link] → Reference Detail
      │   │   ├─ [add payment] → Payment Form
      │   │   ├─ [add expense] → Expense Form
      │   │   ├─ [attach document] → File Picker
      │   │   └─ [view document] → Document Viewer
      │   └─ [FAB: +] → Application Create (with Reference Selector)
      │
      ├─ ৩. হিসাব (Finance)
      │   ├─ Financial Overview (default ledger view)
      │   │   ├─ [বকেয়া খাতা কার্ড] → Due Management Screen
      │   │   ├─ [আজকের জমা/খরচ কার্ড] → Transaction History Screen
      │   │   └─ [ব্যবসায়িক ট্রেন্ড লিঙ্ক] → Analytics Tab Screen
      │   ├─ [বকেয়া স্ক্রিনে PDF বোতাম] → বকেয়া তালিকার অফিসিয়াল PDF
      │   └─ [FAB: +] → Payment Form / Expense Form
      │
      ├─ ৪. বিশ্লেষণ (Analytics & Business Intelligence Dashboard)
      │   ├─ [পিরিয়ড ফিল্টার চিপস: চলতি মাস / ৩ মাস / বছর / সার্বিক]
      │   ├─ [৪টি এক্সিকিউটিভ কেপিআই সামারি কার্ড]
      │   ├─ [মাসভিত্তিক আয় ও মুনাফা প্রবৃদ্ধি ট্রেন্ড LineChart]
      │   ├─ [কাজের ধরনভিত্তিক বিভাজন ও ইন্টারেক্টিভ Donut Chart]
      │   ├─ [কাজের অগ্রগতি ও রূপান্তর পাইপলাইন ফানেল]
      │   ├─ [ভূমি অফিস ভিত্তিক কাজের চাপ ও রাজস্ব অনুপাত]
      │   └─ [অ্যাকশনেবল স্মার্ট ব্যবসায়িক অন্তর্দৃষ্টি ও পরামর্শ]
      │
      └─ ৫. মেনু (Menu)
          ├─ [দৈনিক ব্যবস্থাপনা ও খাতা]
          │   ├─ করণীয় কাজ ও রিমাইন্ডার → Task List
          │   ├─ গ্রাহক ও ব্যক্তি খাতা → Person List
          │   ├─ রেফারেন্স খাতা        → Reference List ──► Reference Detail
          │   └─ ভূমি অফিস তালিকা   → Office Management
          └─ [সিস্টেম ও ডেটা ব্যাকআপ]
              ├─ টেলিগ্রাম ক্লাউড ব্যাকআপ ও রিস্টোর → Backup & Restore Screen
              └─ সেটিংস ও কাস্টমাইজেশন → Settings Screen
```

### 6.1 Form Validation & Error Messaging Standard
To ensure data integrity and prevent accidental empty submissions in a fast-paced shop environment:
1. **Bengali Error Messages:** All required form inputs validate on submission or step navigation and display helpful Bengali messages (e.g. `'আবেদনকারীর নাম আবশ্যক'`, `'মোবাইল নম্বর আবশ্যক'`, `'চুক্তির সার্ভিস ফি উল্লেখ করুন'`).
2. **Visual Labels (`AppFieldLabel`):** Required fields have a red asterisk (` *`), while optional fields do NOT contain the redundant word `(ঐচ্ছিক)`.
3. **Step Gating in Multi-Step Wizard:** Step 1, Step 2, and Step 3 each validate their respective `GlobalKey<FormState>()` before enabling advancement (`_onNextStep()`), preventing the user from skipping mandatory data.
4. **Step 3 Review Summary Card:** Real-time review card at the top of the final step allows instant inspection of customer and work data with 1-click edit jumping before final save.
5. **Feedback Notifications:** Standardized emerald/rose SnackBar feedback confirms successful saves or indicates blocked actions.

---

## 7. Development Phases

### Phase 0: Project Foundation (Pre-Design)
- Create Flutter project
- Configure project structure
- Add all dependencies
- Set up design system (colors, typography, spacing, theme)
- Create base reusable widgets
- Bundle Bengali fonts
- **Duration: ~1 session**

### Phase 1: Complete UI Prototype (Design & Workflow Phase)
- All 28 screens with demo data
- Complete business workflow integration:
  - Application Details financial tab clean-up (standalone expense button removed)
  - Status change dialog with optional stage expense entry (automatically recorded as work expense)
  - Main financial screen redesign (two primary visible buttons, no floating "জমা নিন")
  - Dedicated independent income form (isolated from application payments)
  - Specific work vs general shop expense form with custom categories
  - Multi-criteria filterable transaction ledger with active filter removal chips and 1-click reset
  - Outstanding dues section with 1-click application navigation
- All navigation flows, dialogs, and bottom sheets
- Empty states, loading states
- 24 automated tests verifying all financial scenarios and UI rules
- **Duration: ~2-3 sessions**
- **⏸ CHECKPOINT: Wait for design approval**

### Phase 2: Database & Data Layer
- Drift database setup
- All table definitions (including `independent_incomes`, `income_categories`, and status linkage)
- DAOs
- Migrations framework
- Money type
- Seed data (default work types, expense categories, income categories, statuses)
- **Duration: ~1 session**

### Phase 3: Person & Office Management
- Person CRUD
- Office CRUD
- Connect UI to real data
- Person selector integration
- **Duration: ~1 session**

### Phase 4: Application Management
- Application CRUD
- Status management & history (with optional financial fee/expense recording)
- Application list with real search/filter/sort
- Application detail with tabs (clean financial ledger)
- Work type management
- **Duration: ~1-2 sessions**

### Phase 5: Financial Management
- Payment CRUD (application contract installments & advance)
- Independent Income CRUD (non-application services & business income)
- Expense CRUD (application-specific work expenses + general shop overheads)
- Status-linked fee & expense transactions
- Centralized single-source-of-truth transaction repository with zero duplicates
- Precise integer-based Paisa financial calculations
- Financial overview dashboard with real data
- Multi-criteria transaction history with dynamic date/category/app filtering
- Due management with PDF list generation & direct customer call actions
- Interactive income vs expense charts
- **Duration: ~1-2 sessions**

### Phase 6: Documents & Tasks
- Document attachment (PDF/image as BLOB)
- Document preview
- Task CRUD
- Task notifications
- **Duration: ~1 session**

### Phase 7: Dashboard & Reports
- Dashboard with real aggregated data
- All report types
- Date range filtering
- PDF/Excel export
- **Duration: ~1 session**

### Phase 8: Offline & Cloud Backup & Restore
- Primary: Offline manual phone export (.db file to Downloads folder)
- Primary: Offline manual file picker import & restore flow with confirmation dialog
- Secondary: Telegram Bot cloud upload/export integration
- Database snapshot & AES encryption
- Scheduled backup reminder
- **Duration: ~1 session**

### Phase 9: Testing & QA
- Unit tests
- Database tests
- Financial calculation tests
- Widget tests
- Integration tests
- Bug fixes
- **Duration: ~1 session**

### Phase 10: Final Polish & Delivery
- Performance optimization
- Final QA pass
- Documentation updates
- Release APK build
- **Duration: ~1 session**

---

## 8. Key Technical Decisions

### 8.1 Why Drift over sqflite?

| Feature | sqflite | Drift |
|---|---|---|
| Type-safe queries | ❌ Raw SQL strings | ✅ Dart query builder |
| Compile-time checks | ❌ | ✅ |
| Auto-generated DAOs | ❌ | ✅ |
| Migration support | Manual | Built-in |
| Stream queries (reactive) | Manual | ✅ Built-in |
| Transaction support | Basic | Full |
| Testing | Manual setup | Built-in test utilities |

### 8.2 Why Riverpod over BLoC?

- Less boilerplate for a single-developer project
- Compile-time safety
- Excellent dependency injection
- Easy to test
- Natural fit with Drift's reactive streams
- No unnecessary event/state class proliferation

### 8.3 Why Documents in SQLite?

- Single-file backup captures everything
- No broken file references after restore
- Simplified file management
- Trade-off: Larger DB file, but acceptable for this use case (typical PDFs are 100KB-2MB, a few hundred applications is manageable)

### 8.4 Bengali Font Strategy

- Bundle **Noto Sans Bengali** (Regular, Medium, SemiBold, Bold) in `assets/fonts/`
- Set as default font family in theme
- No internet dependency for text rendering
- Bengali numerals (০১২৩৪৫৬৭৮৯) used in display where appropriate

---

## 9. Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Large DB from BLOB storage | Medium | Compress images before storing; limit file sizes; show storage usage in settings |
| Telegram upload size limit (50MB) | Medium | Monitor DB size; warn user; consider splitting if needed (unlikely for typical usage) |
| WAL corruption during backup | High | Checkpoint + validation before upload; never copy live WAL |
| Data loss during restore | High | Confirm dialog; keep current DB as rollback; validate before replacing |
| Bengali text rendering issues | Medium | Bundled fonts; test on multiple devices |
| Drift code generation complexity | Low | Well-documented; stable package |
| Telegram Bot token security | Medium | Store in flutter_secure_storage; document limitations; never hardcode |

---

## 10. Testing Strategy

### Unit Tests
- Money arithmetic and formatting
- Date utilities
- Validators
- Financial calculations (profit, due, totals)

### Database Tests
- CRUD for every table
- Foreign key constraints
- Cascade behavior
- Query filters and sorting
- Migration paths
- Transaction safety

### Widget Tests
- Form validation
- Status badge rendering
- Money display formatting
- Filter state management
- Empty/loading/error states

### Integration Tests
- Complete application lifecycle (create → payments → status changes → complete)
- Backup and restore roundtrip
- Search and filter accuracy
- Financial report accuracy

---

## 11. Documentation Plan

| Document | Contents |
|---|---|
| README.md | Project overview, setup, build instructions |
| docs/PROJECT_PLAN.md | This document |
| docs/ARCHITECTURE.md | Technical architecture, patterns, decisions |
| docs/DATABASE_SCHEMA.md | Complete schema with relationships |
| docs/UI_UX_GUIDELINES.md | Design system, component library, screen specs |
| docs/DEVELOPMENT_PROGRESS.md | Phase-by-phase progress tracking |
| docs/TESTING.md | Test plan, coverage, results |
| docs/BACKUP_AND_RESTORE.md | Telegram backup setup and usage guide |
| docs/CHANGELOG.md | Version history and changes |

---

## 12. Acceptance Criteria

The application is complete when:

- [ ] All 27 screens are implemented and functional
- [ ] All navigation flows work correctly
- [ ] Application CRUD with all fields (including mouza) works
- [ ] Reference person management (list, profile, aggregated stats, inline selector) works
- [ ] Status changes create history records
- [ ] Person and office management works
- [ ] Payment and expense recording works
- [ ] Financial calculations are accurate (integer math)
- [ ] Dashboard shows real aggregated data
- [ ] Search finds applications by name, phone, app number, case number
- [ ] Filters work for status, work type, office, date range
- [ ] Documents (PDF/images) attach, preview, and persist in SQLite
- [ ] Tasks can be created, edited, and completed
- [ ] Notifications fire for task reminders
- [ ] Reports generate with correct data
- [ ] Telegram backup uploads encrypted DB file (not ZIP)
- [ ] Restore downloads, decrypts, validates, and replaces DB
- [ ] App works fully offline
- [ ] Bengali text renders correctly with bundled fonts
- [ ] All critical tests pass
- [ ] Release APK builds successfully
- [ ] Documentation is complete and accurate

---

*Plan created: 2026-11-06*
*Status: APPROVED BY USER — PROCEEDING WITH PHASE 0 & PHASE 1 (COMPLETE DESIGN PROTOTYPE)*

