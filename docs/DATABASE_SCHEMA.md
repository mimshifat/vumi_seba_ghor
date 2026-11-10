# রজব ভূমি সেবা ঘর — Database Schema Specification

> **Status:** Production-Ready & Enterprise Audit Standard (Soft Delete & Historical Snapshot Preserved)  
> **Engine:** SQLite 3 via `drift` (Dart ORM)  
> **Currency Precision:** Integer-based Paisa (৳1 = 100 Paisa; ৳7,000 = 700000)  
> **Primary Key Standard:** UUID v4 (String / TEXT) for conflict-free offline operation  
> **Deletion Standard:** **Zero Hard Deletes (কখনো হার্ড ডিলিট হবে না)** — All deletions are Soft Deletes (`deleted_at INTEGER NULL`) with Frozen Historical Snapshots.

---

## 1. Architectural Principles: Zero Hard Delete & Snapshot Isolation

### 1.1 The Golden Rule of Business & Accounting Integrity
1. **কখনই হার্ড ডিলিট (Physical DELETE) নয়:**  
   ডেটাবেজ থেকে কোনো রেকর্ড কখনো মুছে ফেলা হবে না। যে কোনো ডিলিট অ্যাকশনে উক্ত রেকর্ডে `deleted_at = Unix Epoch Timestamp` বসে যাবে।
2. **হিসাব ও ক্যালকুলেশনে শূন্য প্রভাব (Calculation Immunity):**  
   কোনো রেফারেন্স ব্যক্তি, গ্রাহক বা ক্যাটাগরি মুছে ফেলা হলেও অতীত চুক্তির মোট আয়, আদায়, খরচ বা বকেয়া হিসাবে **১ পয়সারও কোনো পরিবর্তন বা গরমিল হবে না**।
3. **ঐতিহাসিক স্ন্যাপশট (Historical Snapshot Preservation):**  
   প্রতিটি আবেদনে (`applications` টেবিলে) রেফারেন্সের নাম (`reference_name`), গ্রাহকের নাম ও মোবাইল (`applicant_name`, `applicant_phone`, `applicant_address`), এবং অফিসের নাম (`office_name`) স্বাধীন স্ন্যাপশট কলাম হিসেবে সরাসরি সংরক্ষিত থাকবে।  
   *উদাহরণ:* আপনি যদি রেফারেন্স খাতা থেকে একজন রেফারেন্স ব্যক্তিকে ডিলিটও করে দেন:
   - নতুন আবেদনের রেফারেন্স সিলেক্টরে তাকে আর দেখাবে না (`WHERE deleted_at IS NULL`)।
   - কিন্তু তার আনীত পূর্বের সকল ফাইলে **রেফারেন্স ব্যক্তির নাম ও তথ্য সম্পূর্ণ অক্ষতভাবে প্রদর্শিত হবে**।
4. **ক্যাশ ড্রয়ার ও ভাউচার অপরিবর্তনশীলতা (Cashbook Audit Trail):**  
   দোকানের ক্যাশ ড্রয়ারে যে টাকা প্রবেশ করেছে (`payments`) বা বের হয়েছে (`expenses`), কোনো ফাইল বা আইটেম ডিলিট হলেও অতীতের ক্যাশ বইয়ের ব্যালেন্স কখনো বিকৃত হবে না।

---

## 2. Entity-Relationship & Schema Diagram

```
┌───────────────────────────┐     ┌──────────────────────────────────────────────┐     ┌───────────────────────────┐
│          persons          │     │                 applications                 │     │          offices          │
├───────────────────────────┤     ├──────────────────────────────────────────────┤     ├───────────────────────────┤
│ id (PK TEXT)              │◄────│ applicant_id (FK TEXT NULL)                  │     │ id (PK TEXT)              │
│ name (TEXT NOT NULL)      │     │ applicant_name (TEXT NOT NULL - Snapshot)    │     │ name (TEXT NOT NULL)      │
│ phone (TEXT NOT NULL)     │     │ applicant_phone (TEXT NOT NULL - Snapshot)   │     │ created_at (INTEGER)      │
│ address (TEXT NULL)       │     │ applicant_address (TEXT NULL - Snapshot)     │     │ updated_at (INTEGER)      │
│ photo (BLOB NULL)         │     │ reference_id (FK TEXT NULL)─┬────────────────┤     │ deleted_at (INTEGER NULL) │
│ notes (TEXT NULL)         │     │ reference_name (TEXT NULL - Snapshot)        │     └───────────────────────────┘
│ created_at (INTEGER)      │     │ office_id (FK TEXT NULL)                     │
│ updated_at (INTEGER)      │     │ office_name (TEXT NOT NULL - Snapshot)       │  ┌───────────────────────────┐
│ deleted_at (INTEGER NULL) │     │ mouza (TEXT NULL)                            │  │        references         │
└───────────────────────────┘     │ app_number (TEXT NULL)                       │  ├───────────────────────────┤
                                  │ case_number (TEXT NULL)                      │  │ id (PK TEXT)              │
                                  │ work_type (TEXT NOT NULL)                    │  │ name (TEXT NOT NULL)      │
                                  │ application_date (INTEGER)                   │  │ phone (TEXT NOT NULL)     │
                                  │ status (TEXT NOT NULL)                       │  │ address (TEXT NULL)       │
                                  │ agreed_amount (INTEGER)                      │  │ photo (BLOB NULL)         │
                                  │ is_marked_as_paid (INTEGER)                  │  │ notes (TEXT NULL)         │
                                  │ notes (TEXT NULL)                            │  │ created_at (INTEGER)      │
                                  │ created_at (INTEGER)                         │  │ updated_at (INTEGER)      │
                                  │ updated_at (INTEGER)                         │  │ deleted_at (INTEGER NULL) │
                                  │ deleted_at (INTEGER NULL)                    │  └───────────────────────────┘
                                  └──────────────────────┬───────────────────────┘
                                                         │
                     ┌───────────────────────────────────┼───────────────────────────────────┐
                     │                                   │                                   │
      ┌──────────────┴──────────────┐     ┌──────────────┴──────────────┐     ┌──────────────┴──────────────┐
      │          payments           │     │          expenses           │     │          documents          │
      ├─────────────────────────────┤     ├─────────────────────────────┤     ├─────────────────────────────┤
      │ id (PK TEXT)                │     │ id (PK TEXT)                │     │ id (PK TEXT)                │
      │ application_id (FK TEXT)    │     │ application_id (FK NULL)    │     │ application_id (FK TEXT)    │
      │ amount (INTEGER)            │     │ amount (INTEGER)            │     │ file_name (TEXT NOT NULL)   │
      │ date (INTEGER)              │     │ category (TEXT NOT NULL)    │     │ file_type (TEXT NOT NULL)   │
      │ method (TEXT NOT NULL)      │     │ date (INTEGER)              │     │ file_data (BLOB NOT NULL)   │
      │ note (TEXT NULL)            │     │ is_general (INTEGER)        │     │ file_size (TEXT NOT NULL)   │
      │ status_history_id (FK NULL) │     │ note (TEXT NULL)            │     │ created_at (INTEGER)        │
      │ status_name (TEXT NULL)     │     │ status_history_id (FK NULL) │     │ deleted_at (INTEGER NULL)   │
      │ is_status_fee (INTEGER)     │     │ status_name (TEXT NULL)     │     └─────────────────────────────┘
      │ created_at (INTEGER)        │     │ is_status_exp (INTEGER)     │
      │ deleted_at (INTEGER NULL)   │     │ created_at (INTEGER)        │
      └─────────────────────────────┘     │ deleted_at (INTEGER NULL)   │
                                          └─────────────────────────────┘
                     ┌────────────────────────────┐
                     │       status_history       │
                     ├────────────────────────────┤
                     │ id (PK TEXT)               │
                     │ application_id (FK TEXT)   │
                     │ prev_status (TEXT NOT NULL)│
                     │ new_status (TEXT NOT NULL) │
                     │ changed_at (INTEGER)       │
                     │ note (TEXT NULL)           │
                     └────────────────────────────┘

┌─────────────────────────┐     ┌───────────────────────────────────┐     ┌─────────────────────────┐
│   independent_incomes   │     │               tasks               │     │      shop_settings      │
├─────────────────────────┤     ├───────────────────────────────────┤     ├─────────────────────────┤
│ id (PK TEXT)            │     │ id (PK TEXT)                      │     │ key (PK TEXT)           │
│ category (TEXT NOT NULL)│     │ title (TEXT NOT NULL)             │     │ value (TEXT NOT NULL)   │
│ amount (INTEGER)        │     │ description (TEXT NULL)           │     │ updated_at (INTEGER)    │
│ date (INTEGER)          │     │ due_date (INTEGER NOT NULL)       │     └─────────────────────────┘
│ payment_method (TEXT)   │     │ due_time (TEXT NULL)              │
│ customer_name (TEXT)    │     │ priority (TEXT NOT NULL)          │
│ note (TEXT NULL)        │     │ status (TEXT NOT NULL)            │
│ created_at (INTEGER)    │     │ category (TEXT NOT NULL)          │
│ deleted_at (INT NULL)   │     │ application_id (FK TEXT NULL)     │
└─────────────────────────┘     │ completed_at (INTEGER NULL)       │
                                │ created_at (INTEGER)              │
                                │ updated_at (INTEGER)              │
                                │ deleted_at (INTEGER NULL)         │
                                └───────────────────────────────────┘

┌───────────────────────────┐     ┌───────────────────────────┐     ┌───────────────────────────┐
│        work_types         │     │    expense_categories     │     │     income_categories     │
├───────────────────────────┤     ├───────────────────────────┤     ├───────────────────────────┤
│ id (PK TEXT)              │     │ id (PK TEXT)              │     │ id (PK TEXT)              │
│ name (TEXT NOT NULL)      │     │ name (TEXT NOT NULL)      │     │ name (TEXT NOT NULL)      │
│ is_default (INTEGER)      │     │ is_general (INTEGER)      │     │ is_default (INTEGER)      │
│ created_at (INTEGER)      │     │ is_default (INTEGER)      │     │ created_at (INTEGER)      │
│ deleted_at (INTEGER NULL) │     │ created_at (INTEGER)      │     │ deleted_at (INTEGER NULL) │
└───────────────────────────┘     │ deleted_at (INTEGER NULL) │     └───────────────────────────┘
                                  └───────────────────────────┘
```

---

## 3. Detailed Table Specifications with Snapshots

### 3.1 `applications` (মূল আবেদন তালিকা — স্ন্যাপশট সমন্বিত)

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | TEXT | PRIMARY KEY | UUID string |
| `applicant_id` | TEXT | NULL, REFERENCES `persons(id)` ON DELETE SET NULL | Linked applicant person ID |
| `applicant_name` | TEXT | NOT NULL | **Snapshot:** নাম (গ্রাহক ডিলিট হলেও ফাইলে স্থায়ী) |
| `applicant_phone` | TEXT | NOT NULL | **Snapshot:** ফোন (গ্রাহক ডিলিট হলেও ফাইলে স্থায়ী) |
| `applicant_address` | TEXT | NULL | **Snapshot:** ঠিকানা |
| `reference_id` | TEXT | NULL, REFERENCES `references(id)` ON DELETE SET NULL | Linked reference person ID |
| `reference_name` | TEXT | NULL | **Snapshot:** রেফারেন্স ব্যক্তির নাম (রেফারেন্স খাতা থেকে ব্যক্তি ডিলিট হলেও ফাইলে স্থায়ী) |
| `office_id` | TEXT | NULL, REFERENCES `offices(id)` ON DELETE SET NULL | Linked office ID |
| `office_name` | TEXT | NOT NULL | **Snapshot:** অফিসের নাম |
| `mouza` | TEXT | NULL | মৌজার নাম |
| `app_number` | TEXT | NULL | অনলাইন আবেদন নম্বর |
| `case_number` | TEXT | NULL | নামজারি/আদালত কেস নম্বর |
| `work_type` | TEXT | NOT NULL | কাজের ধরন |
| `application_date` | INTEGER | NOT NULL | Unix epoch timestamp (milliseconds) |
| `status` | TEXT | NOT NULL | বর্তমান অবস্থা |
| `agreed_amount` | INTEGER | NOT NULL | চুক্তিকৃত সার্ভিস ফি (পয়সায়) |
| `is_marked_as_paid` | INTEGER | NOT NULL DEFAULT 0 | ১ = বকেয়া মওকুফ/পরিশোধিত চিহ্নিত, ০ = স্বাভাবিক |
| `notes` | TEXT | NULL | বিশেষ নোট |
| `created_at` | INTEGER | NOT NULL | তৈরির সময় |
| `updated_at` | INTEGER | NOT NULL | হালনাগাদের সময় |
| `deleted_at` | INTEGER | NULL | সফট ডিলিট টাইমস্ট্যাম্প (নাল থাকলে সক্রিয়) |

**Indexes:**
- `CREATE INDEX idx_applications_active ON applications(deleted_at) WHERE deleted_at IS NULL;`
- `CREATE INDEX idx_applications_applicant ON applications(applicant_id);`
- `CREATE INDEX idx_applications_reference ON applications(reference_id);`
- `CREATE INDEX idx_applications_status ON applications(status);`
- `CREATE INDEX idx_applications_date ON applications(application_date DESC);`

---

### 3.2 `references` (রেফারেন্স ব্যক্তি খাতা — সফট ডিলিট)

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | TEXT | PRIMARY KEY | UUID string |
| `name` | TEXT | NOT NULL | রেফারেন্স ব্যক্তির নাম |
| `phone` | TEXT | NOT NULL | মোবাইল নম্বর |
| `address` | TEXT | NULL | ঠিকানা |
| `photo` | BLOB | NULL | ছবি বাইনারি |
| `notes` | TEXT | NULL | নোট |
| `created_at` | INTEGER | NOT NULL | তৈরির সময় |
| `updated_at` | INTEGER | NOT NULL | হালনাগাদের সময় |
| `deleted_at` | INTEGER | NULL | সফট ডিলিট টাইমস্ট্যাম্প |

> [!IMPORTANT]
> রেফারেন্স খাতা থেকে কোনো রেফারেন্স ব্যক্তিকে ডিলিট করলে `deleted_at` সেট হবে। তিনি নতুন আবেদনের সিলেক্টরে আসবেন না, কিন্তু **পূর্বে তার রেফারেন্সে হওয়া সকল আবেদনে তার নাম (`reference_name`) ও হিসাব অবিকল আগের মতোই প্রদর্শিত হবে**।

---

### 3.3 `persons` (গ্রাহক খাতা — সফট ডিলিট)

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | TEXT | PRIMARY KEY | UUID string |
| `name` | TEXT | NOT NULL | গ্রাহকের নাম |
| `phone` | TEXT | NOT NULL | মোবাইল নম্বর |
| `address` | TEXT | NULL | ঠিকানা |
| `photo` | BLOB | NULL | ছবি বাইনারি |
| `notes` | TEXT | NULL | নোট |
| `created_at` | INTEGER | NOT NULL | তৈরির সময় |
| `updated_at` | INTEGER | NOT NULL | হালনাগাদের সময় |
| `deleted_at` | INTEGER | NULL | সফট ডিলিট টাইমস্ট্যাম্প |

---

### 3.4 `offices` (ভূমি অফিস — সফট ডিলিট)

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | TEXT | PRIMARY KEY | UUID string |
| `name` | TEXT | NOT NULL | অফিসের নাম |
| `created_at` | INTEGER | NOT NULL | তৈরির সময় |
| `updated_at` | INTEGER | NOT NULL | হালনাগাদের সময় |
| `deleted_at` | INTEGER | NULL | সফট ডিলিট টাইমস্ট্যাম্প |

---

### 3.5 `payments` (জমা ও কিস্তি — আর্থিক অডিট ট্রেইল)

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | TEXT | PRIMARY KEY | UUID string |
| `application_id` | TEXT | NOT NULL, REFERENCES `applications(id)` | সংশ্লিষ্ট আবেদন |
| `amount` | INTEGER | NOT NULL | টাকার পরিমাণ (পয়সায়) |
| `date` | INTEGER | NOT NULL | প্রাপ্তির তারিখ |
| `method` | TEXT | NOT NULL | নগদ, বিকাশ, ব্যাংক |
| `note` | TEXT | NULL | রসিদ নোট |
| `status_history_id`| TEXT | NULL, REFERENCES `status_history(id)` | স্ট্যাটাস রূপান্তর লিংক |
| `status_name` | TEXT | NULL | যে ধাপে টাকা গৃহীত হয়েছিল |
| `is_status_fee` | INTEGER | NOT NULL DEFAULT 0 | ১ = স্ট্যাটাস ডায়ালগের মাধ্যমে আদায় |
| `created_at` | INTEGER | NOT NULL | তৈরির সময় |
| `deleted_at` | INTEGER | NULL | সফট ডিলিট (ভুল এন্ট্রি রিভার্সাল অডিট) |

---

### 3.6 `expenses` (খরচ — অডিট ট্রেইল)

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | TEXT | PRIMARY KEY | UUID string |
| `application_id` | TEXT | NULL, REFERENCES `applications(id)` | আবেদন খরচ হলে আইডি; সাধারণ দোকান খরচ হলে NULL |
| `amount` | INTEGER | NOT NULL | টাকার পরিমাণ (পয়সায়) |
| `category` | TEXT | NOT NULL | খরচের খাত |
| `date` | INTEGER | NOT NULL | খরচের তারিখ |
| `is_general` | INTEGER | NOT NULL DEFAULT 0 | ০ = ফাইলের খরচ; ১ = দোকানের খরচ |
| `note` | TEXT | NULL | ভাউচার নোট |
| `status_history_id`| TEXT | NULL, REFERENCES `status_history(id)` | স্ট্যাটাস রূপান্তর লিংক |
| `status_name` | TEXT | NULL | যে ধাপে খরচ হয়েছিল |
| `is_status_exp` | INTEGER | NOT NULL DEFAULT 0 | ১ = স্ট্যাটাস পরিবর্তন ডায়ালগ থেকে তৈরি |
| `created_at` | INTEGER | NOT NULL | তৈরির সময় |
| `deleted_at` | INTEGER | NULL | সফট ডিলিট |

---

### 3.7 `independent_incomes` (স্বতন্ত্র দোকান আয়)

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | TEXT | PRIMARY KEY | UUID string |
| `category` | TEXT | NOT NULL | কম্পিউটার, ফটোকপি, ইত্যাদি |
| `amount` | INTEGER | NOT NULL | টাকার পরিমাণ (পয়সায়) |
| `date` | INTEGER | NOT NULL | আয়ের তারিখ |
| `payment_method` | TEXT | NOT NULL | নগদ, বিকাশ |
| `customer_name` | TEXT | NULL | সেবাগ্রহীতার নাম |
| `note` | TEXT | NULL | নোট |
| `created_at` | INTEGER | NOT NULL | তৈরির সময় |
| `deleted_at` | INTEGER | NULL | সফট ডিলিট |

---

### 3.8 `tasks` (করণীয় কাজ ও শুনানি)

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | TEXT | PRIMARY KEY | UUID string |
| `title` | TEXT | NOT NULL | কাজের নাম |
| `description` | TEXT | NULL | বিস্তারিত বিবরণ |
| `due_date` | INTEGER | NOT NULL | তারিখ (মিডনাইট ইপক) |
| `due_time` | TEXT | NULL | প্রদর্শনের সময় (যেমন: সকাল ১০:০০) |
| `priority` | TEXT | NOT NULL DEFAULT 'সাধারণ' | 'জরুরি' বা 'সাধারণ' |
| `status` | TEXT | NOT NULL DEFAULT 'করতে হবে' | 'করতে হবে', 'চলমান', 'সম্পন্ন' |
| `category` | TEXT | NOT NULL DEFAULT 'সাধারণ' | ৬টি ক্যাটাগরি |
| `application_id` | TEXT | NULL, REFERENCES `applications(id)` | সংযুক্ত আবেদন |
| `completed_at` | INTEGER | NULL | কাজ শেষ করার সময় |
| `created_at` | INTEGER | NOT NULL | তৈরির সময় |
| `updated_at` | INTEGER | NOT NULL | হালনাগাদের সময় |
| `deleted_at` | INTEGER | NULL | সফট ডিলিট |

---

### 3.9 `documents` (সংযুক্ত ফাইল — ১০০% হার্ড ডিলিট পলিসি)

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | TEXT | PRIMARY KEY | UUID string |
| `application_id` | TEXT | NOT NULL, REFERENCES `applications(id)` | সংযুক্ত আবেদন |
| `file_name` | TEXT | NOT NULL | ফাইলের নাম |
| `file_type` | TEXT | NOT NULL | 'pdf' বা 'image' |
| `file_data` | BLOB | NOT NULL | বাইনারি ডেটা |
| `file_size` | TEXT | NOT NULL | ফাইলের সাইজ স্ট্রিং |
| `created_at` | INTEGER | NOT NULL | আপলোডের সময় |
| `updated_at` | INTEGER | NOT NULL | হালনাগাদের সময় |

> **ফাইল হার্ড ডিলিট পলিসি (Physical Delete Only):** ফাইল ও পিডিএফ সাইজে ভারী (BLOB) হওয়ায় কোনো ফাইল মুছে দিলে তা কখনোই সফট ডিলিট হবে না; ফাইল ডিলিট করার সাথে সাথেই ডেটাবেজ স্টোরেজ থেকে তা স্থায়ীভাবে **হার্ড ডিলিট (Physical SQL DELETE)** হয়ে যাবে। এমনকি কোনো আবেদন সফট ডিলিট হলেও তার সাথে যুক্ত সকল ফাইল ও পিডিএফ পার্জ (Hard Delete) করে ডেটাবেজ হালকা রাখা হয়।

---

### 3.10 কাস্টমাইজযোগ্য ক্যাটাগরি টেবিলসমূহ (`work_types`, `expense_categories`, `income_categories`)
- প্রতিটিতে `deleted_at INTEGER NULL` যুক্ত।
- ব্যবহারকারী সেটিংস থেকে কোনো ক্যাটাগরি "মুছে" দিলে সেটি নিস্ক্রিয় হবে, কিন্তু অতীত লেনদেনে সেই ক্যাটাগরির নাম অক্ষত থাকবে।

---

## 4. অপরিবর্তনশীল সেন্ট্রালাইজড ট্রানজ্যাকশন ভিউ (`unified_transactions_view`)

সক্রিয় লেনদেনের জন্য সেন্ট্রালাইজড ভিউ স্বয়ংক্রিয়ভাবে `deleted_at IS NULL` ফিল্টার নিশ্চিত করে:

```sql
CREATE VIEW unified_transactions_view AS
-- ১. আবেদন কিস্তি জমা
SELECT 
  p.id AS id,
  'income' AS type,
  'applicationPayment' AS source,
  p.amount AS amount,
  p.date AS date,
  'আবেদন কিস্তি জমা' AS category,
  p.application_id AS application_id,
  a.work_type || ' - ' || a.applicant_name AS application_title,
  a.applicant_name AS applicant_name,
  NULL AS customer_name,
  p.method AS payment_method,
  p.status_history_id AS status_history_id,
  p.status_name AS status_name,
  p.note AS note
FROM payments p
JOIN applications a ON p.application_id = a.id
WHERE p.deleted_at IS NULL AND a.deleted_at IS NULL AND p.is_status_fee = 0

UNION ALL

-- ২. অবস্থা পরিবর্তন ফি
SELECT 
  p.id AS id,
  'income' AS type,
  'statusIncome' AS source,
  p.amount AS amount,
  p.date AS date,
  'অবস্থা পরিবর্তন ফি' AS category,
  p.application_id AS application_id,
  a.work_type || ' - ' || a.applicant_name AS application_title,
  a.applicant_name AS applicant_name,
  NULL AS customer_name,
  p.method AS payment_method,
  p.status_history_id AS status_history_id,
  p.status_name AS status_name,
  p.note AS note
FROM payments p
JOIN applications a ON p.application_id = a.id
WHERE p.deleted_at IS NULL AND a.deleted_at IS NULL AND p.is_status_fee = 1

UNION ALL

-- ৩. স্বতন্ত্র স্বাধীন আয়
SELECT 
  i.id AS id,
  'income' AS type,
  'independentIncome' AS source,
  i.amount AS amount,
  i.date AS date,
  i.category AS category,
  NULL AS application_id,
  NULL AS application_title,
  NULL AS applicant_name,
  i.customer_name AS customer_name,
  i.payment_method AS payment_method,
  NULL AS status_history_id,
  NULL AS status_name,
  i.note AS note
FROM independent_incomes i
WHERE i.deleted_at IS NULL

UNION ALL

-- ৪. অবস্থা পরিবর্তন খরচ
SELECT 
  e.id AS id,
  'expense' AS type,
  'statusExpense' AS source,
  e.amount AS amount,
  e.date AS date,
  e.category AS category,
  e.application_id AS application_id,
  a.work_type || ' - ' || a.applicant_name AS application_title,
  a.applicant_name AS applicant_name,
  NULL AS customer_name,
  NULL AS payment_method,
  e.status_history_id AS status_history_id,
  e.status_name AS status_name,
  e.note AS note
FROM expenses e
JOIN applications a ON e.application_id = a.id
WHERE e.deleted_at IS NULL AND a.deleted_at IS NULL AND e.is_status_exp = 1

UNION ALL

-- ৫. ফাইলের কাজের খরচ
SELECT 
  e.id AS id,
  'expense' AS type,
  'applicationExpense' AS source,
  e.amount AS amount,
  e.date AS date,
  e.category AS category,
  e.application_id AS application_id,
  a.work_type || ' - ' || a.applicant_name AS application_title,
  a.applicant_name AS applicant_name,
  NULL AS customer_name,
  NULL AS payment_method,
  e.status_history_id AS status_history_id,
  e.status_name AS status_name,
  e.note AS note
FROM expenses e
JOIN applications a ON e.application_id = a.id
WHERE e.deleted_at IS NULL AND a.deleted_at IS NULL AND e.is_status_exp = 0 AND e.is_general = 0

UNION ALL

-- ৬. দোকানের সাধারণ খরচ
SELECT 
  e.id AS id,
  'expense' AS type,
  'generalExpense' AS source,
  e.amount AS amount,
  e.date AS date,
  e.category AS category,
  NULL AS application_id,
  NULL AS application_title,
  NULL AS applicant_name,
  NULL AS customer_name,
  NULL AS payment_method,
  NULL AS status_history_id,
  NULL AS status_name,
  e.note AS note
FROM expenses e
WHERE e.deleted_at IS NULL AND e.is_general = 1;
```

---

## 5. গ্যারান্টি ও নিরাপত্তা নীতি (Guarantees & Audit Invariants)

1. **রেফারেন্স ব্যক্তি ডিলিটের নিরাপত্তা:**  
   রেফারেন্স তালিকা থেকে ব্যক্তি ডিলিট হলেও `applications.reference_name` অপরিবর্তিত থাকে এবং আবেদন স্ক্রিনে রেফারেন্স ব্যক্তির নাম স্বাভাবিকভাবেই দৃশ্যমান থাকে।
2. **গ্রাহক ডিলিটের নিরাপত্তা:**  
   গ্রাহক ডিলিট হলেও আবেদনের `applicant_name`, `applicant_phone` ও `applicant_address` অক্ষত থাকবে।
3. **আর্থিক সাম্যাবস্থা ও ক্যাশ খাতা:**  
   ক্যাশ লেনদেনের ইতিহাস কখনো হার্ড ডিলিট হয় না। কোনো ভুল এন্ট্রি মুছে দিতে হলে তা সফট ডিলিট হবে এবং অডিটে সংরক্ষিত থাকবে।
4. **সহজ ডেটা রিকভারি:**  
   ভুলবশত কিছু ডিলিট হলে ডেটাবেজের ব্যাকএন্ড থেকে তা যে কোনো সময় এক ক্লিকে রিস্টোর করা সম্ভব (`deleted_at = NULL`)।

---

## 6. Phase 1 Implementation Notes (resolved decisions)

> Added after the Phase 1 implementation and an independent code review. These record the decisions taken where this document was silent or ambiguous. Where the implementation and this document differ, the notes below are the resolution.

### 11.1 `deleted_at` — every table, including `status_history` and `shop_settings`
Both tables **do** carry `deleted_at INTEGER NULL`, so the "every table has `deleted_at`" rule holds with **no exceptions**. `status_history` is an append-only audit log in practice, but the column is present for uniformity; `shop_settings` is a key-value store whose `deleted_at` is likewise always NULL.

### 11.2 `shop_settings` primary key
The primary key is the column **`key`** (`TEXT`), not a UUID. This is a **deliberate, documented exception** to the standard UUID primary keys rule — a key-value store needs the key itself to be the identifier. The column is emitted quoted in the generated DDL (`"key"`), so the SQLite keyword causes no problem. `setting_key` is the Dart-side name (`text().named('key')`).

### 11.3 `expenses` — the file/general classification is now a bijection
Two CHECK constraints together guarantee that **every** expense row is exactly one of the two kinds (BACKEND_MASTER_PLAN.md §1.2):

```sql
CHECK (is_general = 0 OR application_id IS NULL)    -- a general expense has no application
CHECK (is_general = 1 OR application_id IS NOT NULL) -- a file expense must have an application
```

Without the second constraint, a row with `is_general = 0` and `application_id IS NULL` was legal but appeared in **no** `unified_transactions_view` branch and in **no** per-file total — invisible money. It is now rejected at the database level.

### 11.4 `unified_transactions_view` — an *active* view, not an audit view
The view inner-joins `applications`, so the transactions of a soft-deleted application stay **in the database** (audit trail preserved, BUSINESS_RULES.md §1.3) but fall outside **active calculations**. This resolves open question NEW-1 in favour of *active*.

The double-count predicates are corrected:
- **Branch 4** (`statusExpense`) adds `AND e.is_general = 0` — a row flagged both status-linked and general is no longer counted twice.
- **Branch 6** (`generalExpense`) adds `AND e.application_id IS NULL` — a general expense is never attached to an application.

### 11.5 Schema creation order is explicit, not generator order
drift's generator emits the **triggers and the view before the tables** in `allSchemaEntities`, so `m.createAll()` fails with `no such table: main.applications`. `AppDatabase` therefore creates entities in an explicit order — **tables → indexes → views → triggers** — in both `onCreate` and `onUpgrade`.

### 11.6 `onUpgrade` is version-aware and starts empty
Phase 1 is schema version 1, so there is no upgrade path yet. `onUpgrade` is intentionally a no-op with a documented pattern (`if (from < 2) { ... }`) for future versions — each version needs its own step (`m.addColumn()`, `m.alterTable()`, `m.create()`). User data is never destroyed by a migration.

### 11.7 Integrity triggers
`lib/core/database/integrity_guards.drift` adds three `BEFORE UPDATE` triggers that `RAISE(ABORT)`:
- `applications_snapshot_immutable` — the five snapshot columns may never change.
- `payments_immutable` — a payment's amount, date, method, note, links and `created_at` may never change.
- `expenses_immutable` — an expense's amount, category, date, classification, note, links and `created_at` may never change.

Each trigger's comparison list **excludes** `deleted_at` and `updated_at`, so the legitimate soft-delete (`SET deleted_at = ?`) and the audit-timestamp update remain allowed. Corrections are made by soft-deleting the old row and inserting a new one.

### 11.8 Money storage
All monetary columns are `INTEGER` paisa. `Money.fromJson` parses string input with **integer-only** arithmetic and throws `FormatException` on malformed input rather than silently returning zero (BACKEND_MASTER_PLAN.md §1.2). `Money.operator*` accepts `int` only.

---
