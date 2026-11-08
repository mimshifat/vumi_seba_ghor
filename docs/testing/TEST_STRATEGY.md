# Test Strategy — রজব ভূমি সেবা ঘর

> **This is the testing standards reference for all QA and development work.**
> See `PUKU.md` Section 15 for the brief version. This document elaborates with full test plans.

---

## 1. Testing Philosophy

1. **Tests are not optional.** Every feature requires tests.
2. **Tests verify behavior, not implementation.** Test what the code does, not how it does it.
3. **Financial tests use hand-verified expected values.** Never compute expected values programmatically from the same code you are testing.
4. **QA executes tests. QA does not assume.** `flutter test` must be run and output reported.
5. **Regressions block merging.** All 41 baseline tests must pass after every change.
6. **Edge cases matter most in financial software.** Zero, negative, and maximum values must be tested.

---

## 2. Test Organization

```
test/
├── unit/                   — Pure Dart logic tests (no Flutter widget tree)
│   ├── money_test.dart                   — Money class (EXISTS)
│   ├── bengali_digits_test.dart          — Bengali digit conversion (EXISTS)
│   ├── financial_management_test.dart    — Financial scenarios (EXISTS)
│   ├── financial_ui_widget_test.dart     — UI widget financial calculations (EXISTS)
│   ├── task_management_test.dart         — Task management (EXISTS)
│   ├── reference_test.dart               — Reference management (EXISTS)
│   ├── field_label_indicator_test.dart   — Form label standards (EXISTS)
│   ├── database_schema_test.dart         — Schema and integrity (TO CREATE)
│   ├── repository_test.dart              — Repository operations (TO CREATE)
│   ├── financial_calculations_test.dart  — Extended financial tests (TO CREATE)
│   ├── validation_test.dart              — Input validation (TO CREATE)
│   └── business_rules_test.dart          — Business rule enforcement (TO CREATE)
├── widget/                 — Flutter widget rendering tests
│   ├── widget_test.dart                  — Basic widget smoke test (EXISTS)
│   ├── application_card_test.dart        — ApplicationCard widget (TO CREATE)
│   ├── money_field_test.dart             — MoneyField widget (TO CREATE)
│   ├── status_badge_test.dart            — StatusBadge widget (TO CREATE)
│   ├── dialog_action_row_test.dart       — AppDialogActionRow (TO CREATE)
│   └── form_validation_test.dart         — Form validation UI (TO CREATE)
└── integration/            — Full workflow tests (require database)
    ├── application_creation_test.dart    — Application creation flow (TO CREATE)
    ├── payment_flow_test.dart            — Payment receipt flow (TO CREATE)
    ├── financial_totals_test.dart        — Global financial calculations (TO CREATE)
    ├── soft_delete_test.dart             — Soft delete and snapshot integrity (TO CREATE)
    └── backup_restore_test.dart          — Backup and restore cycle (TO CREATE)
```

---

## 3. Unit Test Plans

### 3.1 Money Class (`test/unit/money_test.dart`)
Existing tests cover basic arithmetic. Required additions:

| Test | Expected Result |
|---|---|
| `Money.fromPaisa(0).isZero` | `true` |
| `Money.fromPaisa(100).inTaka` | `1` |
| `Money.fromTaka(7000).paisa` | `700000` |
| `Money.fromPaisa(700000) + Money.fromPaisa(300000)` | `Money.fromPaisa(1000000)` |
| `Money.fromPaisa(700000) - Money.fromPaisa(300000)` | `Money.fromPaisa(400000)` |
| `Money.fromPaisa(700000) * 2` | `Money.fromPaisa(1400000)` |
| `Money.fromPaisa(0).isPositive` | `false` |
| `Money.fromPaisa(-1).isNegative` | `true` |
| `Money.fromPaisa(100000000).formatBengali()` | `'৳১০,০০,০০০'` |
| `Money.parse('৭,০০০').paisa` | `700000` |
| `Money.parse('7000').paisa` | `700000` |
| `Money.parse('').paisa` | `0` |
| Negative net income: `Money.fromPaisa(500000) - Money.fromPaisa(600000)` | `Money.fromPaisa(-100000)` |
| Very large: `Money.fromTaka(10000000).paisa` | `1000000000` (no overflow) |

### 3.2 Financial Calculations (`test/unit/financial_calculations_test.dart`)
Test these exact 8 scenarios (use `DemoApplication`-like structures, then port to real model):

**Scenario 1: Full payment, no expenses**
```
agreed_amount = ৳8,000 (800000 paisa)
total_received = ৳8,000 (800000 paisa)
application_expenses = ৳0
Expected: actual_realized_income = ৳8,000 (800000)
Expected: effective_due = ৳0 (0)
Expected: is_marked_as_paid not needed
```

**Scenario 2: Full payment, with expenses**
```
agreed_amount = ৳8,000 (800000)
total_received = ৳8,000 (800000)
application_expenses = ৳1,170 (117000)
Expected: actual_realized_income = ৳6,830 (683000)
Expected: effective_due = ৳0
```

**Scenario 3: Partial payment, no expenses**
```
agreed_amount = ৳8,000 (800000)
total_received = ৳5,000 (500000)
application_expenses = ৳0
Expected: actual_realized_income = ৳5,000 (500000)
Expected: raw_due = ৳3,000 (300000)
Expected: effective_due = ৳3,000 (300000) [is_marked_as_paid = false]
```

**Scenario 4: Partial payment, with expenses**
```
agreed_amount = ৳8,000 (800000)
total_received = ৳7,500 (750000)
application_expenses = ৳3,000 (300000)
Expected: actual_realized_income = ৳4,500 (450000)
Expected: raw_due = ৳500 (50000)
Expected: effective_due = ৳500 (50000)
```

**Scenario 5: Mark as paid (fee waiver)**
```
agreed_amount = ৳7,000 (700000)
total_received = ৳6,500 (650000)
is_marked_as_paid = true
Expected: effective_due = ৳0 (0)
Expected: raw_due = ৳500 (50000) [preserved for audit]
Expected: actual_realized_income = ৳6,500 (650000)
```

**Scenario 6: Zero agreed amount**
```
agreed_amount = ৳0 (0)
total_received = ৳0 (0)
application_expenses = ৳0
Expected: actual_realized_income = ৳0
Expected: effective_due = ৳0
```

**Scenario 7: Expenses exceed received amount (negative income)**
```
agreed_amount = ৳5,000 (500000)
total_received = ৳2,000 (200000)
application_expenses = ৳3,000 (300000)
Expected: actual_realized_income = -৳1,000 (-100000 paisa)
Expected: effective_due = ৳3,000 (300000)
```

**Scenario 8: Multiple status-linked transactions**
```
agreed_amount = ৳10,000 (1000000)
payments = [৳3,000 (300000), ৳4,000 (400000, status: শুনানি), ৳3,000 (300000)]
expenses = [৳70 (7000, status: আবেদন), ৳300 (30000, status: শুনানি), ৳1,100 (110000, status: ডিসিআর)]
Expected: total_received = ৳10,000 (1000000)
Expected: application_expenses = ৳1,470 (147000)
Expected: actual_realized_income = ৳8,530 (853000)
Expected: effective_due = ৳0
```

### 3.3 Database Schema Tests (`test/unit/database_schema_test.dart`)
Using an in-memory Drift database:

```dart
// Test table existence
test('all 14 tables exist after initialization', () async {
  final db = AppDatabase.forTesting();
  // Query sqlite_master for each table name
  for (final tableName in AppDatabase.allTableNames) {
    final exists = await db.tableExists(tableName);
    expect(exists, true, reason: 'Table $tableName should exist');
  }
});

// Test WAL mode
test('WAL mode is enabled', () async {
  final mode = await db.getJournalMode();
  expect(mode, 'wal');
});

// Test foreign key enforcement
test('foreign key enforcement is active', () async {
  final fkEnabled = await db.getForeignKeysEnabled();
  expect(fkEnabled, 1);
});

// Test soft delete integrity
test('soft-deleted records excluded from active queries', () async {
  final person = await db.personsDao.createPerson(name: 'টেস্ট', phone: '01700000001');
  await db.personsDao.softDeletePerson(person.id);
  final activePersons = await db.personsDao.getActivePersons();
  expect(activePersons.where((p) => p.id == person.id), isEmpty);
});

// Test snapshot integrity
test('applicant snapshot preserved after person soft-deleted', () async {
  final person = await db.personsDao.createPerson(name: 'রহিম', phone: '01700000001');
  final app = await db.applicationsDao.createApplication(applicantId: person.id, applicantName: 'রহিম', ...);
  await db.personsDao.softDeletePerson(person.id);
  final savedApp = await db.applicationsDao.getApplication(app.id);
  expect(savedApp?.applicantName, 'রহিম'); // Snapshot preserved
});
```

### 3.4 Validation Tests (`test/unit/validation_test.dart`)
```dart
test('11-digit phone accepted', () {
  expect(PhoneValidator.validate('01700000001'), isNull); // null = no error
});
test('10-digit phone rejected', () {
  expect(PhoneValidator.validate('0170000000'), isNotNull);
});
test('Bengali phone digits accepted', () {
  expect(PhoneValidator.validate('০১৭০০০০০০০১'), isNull);
});
test('empty name rejected with correct message', () {
  expect(NameValidator.validate(''), 'আবেদনকারীর নাম আবশ্যক');
});
test('zero amount rejected', () {
  expect(MoneyValidator.validatePositive(Money.zero), isNotNull);
});
```

---

## 4. Widget Test Plans

### 4.1 `AppDialogActionRow` (`test/widget/dialog_action_row_test.dart`)
```dart
test('renders cancel and confirm buttons horizontally', () async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppDialogActionRow(
          onCancel: () {},
          onConfirm: () {},
          confirmLabel: 'নিশ্চিত করুন',
        ),
      ),
    ),
  );
  // Both buttons must be in the same row (similar Y coordinate)
  final cancelFinder = find.text('বাতিল');
  final confirmFinder = find.text('নিশ্চিত করুন');
  expect(cancelFinder, findsOneWidget);
  expect(confirmFinder, findsOneWidget);
  final cancelBox = tester.getRect(cancelFinder);
  final confirmBox = tester.getRect(confirmFinder);
  expect((cancelBox.top - confirmBox.top).abs(), lessThan(5)); // Same row
});
```

### 4.2 `StatusBadge` (`test/widget/status_badge_test.dart`)
Test each of the 10 statuses renders with the correct color.

### 4.3 `MoneyField` (`test/widget/money_field_test.dart`)
Test Bengali digit input, English digit input, and formatted display.

---

## 5. Integration Test Plans

### 5.1 Application Creation Integration Test
```
Setup: Empty in-memory database
Action: Call ApplicationRepository.createApplication(...)
Assert:
  - applications table has 1 record
  - applicant_name snapshot is correct
  - office_name snapshot is correct
  - status = 'আবেদন'
  - If initial payment provided: payments table has 1 record
  - financial_summary.total_outstanding_due = initial agreed_amount - initial_payment
```

### 5.2 Payment Flow Integration Test
```
Setup: Application with agreed_amount = ৳8,000, no payments
Action 1: PaymentRepository.createPayment(amount: ৳3,000)
Assert: effective_due = ৳5,000, actual_realized_income = ৳3,000

Action 2: PaymentRepository.createPayment(amount: ৳5,000)
Assert: effective_due = ৳0, actual_realized_income = ৳8,000

Action 3: (MarkAsPaid when partial) Set is_marked_as_paid = true
Assert: effective_due = ৳0, raw_due still preserved
```

### 5.3 Global Financial Totals Test
```
Setup: Empty database
Action: Create 2 applications with payments and expenses + 1 independent income + 1 general expense
Assert:
  - grand_total_income = sum(app_payments) + sum(independent_incomes) [INTEGER arithmetic]
  - grand_total_expense = sum(app_expenses) + sum(general_expenses)
  - net_business_income = grand_total_income - grand_total_expense
  - No floating-point rounding (all calculations must be exact)
```

---

## 6. Edge Case Test List

| Scenario | Expected Behavior |
|---|---|
| Zero amount payment submitted | Reject with error: `'পরিমাণ ০ হতে পারে না'` |
| Payment amount > agreed_amount | Accept (overpayment), raw_due becomes negative, show it correctly |
| Agreed amount = 0 | Application created; realized income = 0 - expenses = negative if any |
| Application with no payments, deleted | Payments remain in DB for audit, excluded from active calculations |
| Bengali digits in money field | Parse correctly: `'৭,০০০'` → 700000 paisa |
| Very large amount: ৳1,00,00,000 | No integer overflow (1,000,000,000 paisa < `Int64.max`) |
| Empty application list | EmptyState widget renders without error |
| All applications soft-deleted | Financial totals = zero, EmptyState renders |
| Reference person deleted | reference_name in applications unchanged |
| Person deleted | applicant_name in applications unchanged |
| `flutter test` with no test database | Integration tests use in-memory DB |

---

## 7. Test Execution Commands

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/money_test.dart

# Run with verbose output
flutter test --reporter=expanded

# Run with coverage (requires lcov on system)
flutter test --coverage

# Run only widget tests
flutter test test/widget/

# Run only integration tests
flutter test test/integration/

# Check static analysis (must be zero issues)
flutter analyze
```

---

## 8. Continuous Quality Standard

Before every commit to any branch:
```bash
flutter analyze   # Must: zero issues
flutter test      # Must: all tests passing, no skips, no failures
```

The QA Engineer must run both and report exact output in every QA report.

