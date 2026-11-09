import 'package:drift/drift.dart';

import '../../utils/money.dart';
import '../app_database.dart';
import '../tables/applications_table.dart';
import '../tables/expenses_table.dart';
import '../tables/independent_incomes_table.dart';
import '../tables/payments_table.dart';
import '../tables/status_history_table.dart';

part 'finance_dao.g.dart';

/// সামগ্রিক আর্থিক হিসাবের স্ন্যাপশট (100% Strict Accounting Rules - BACKEND_MASTER_PLAN.md §1.2)
class ShopFinancialOverview {
  /// আবেদনের মোট আদায়কৃত টাকা (পয়সায়)
  final int totalApplicationReceived;

  /// মোট স্বতন্ত্র/স্বাধীন আয় (পয়সায়)
  final int totalIndependentIncome;

  /// আবেদনের মোট সরাসরি কাজের খরচ (পয়সায়)
  final int totalApplicationExpense;

  /// দোকানের মোট সাধারণ পরিচালন খরচ (পয়সায়)
  final int totalGeneralExpense;

  /// চুক্তিকৃত মোট চুক্তিমূল্য ভলিউম (পয়সায়)
  final int totalAgreedVolume;

  /// মোট কার্যকর বকেয়া (পয়সায়, 'Mark as Paid' সমন্বিত)
  final int totalEffectiveDue;

  const ShopFinancialOverview({
    required this.totalApplicationReceived,
    required this.totalIndependentIncome,
    required this.totalApplicationExpense,
    required this.totalGeneralExpense,
    required this.totalAgreedVolume,
    required this.totalEffectiveDue,
  });

  /// মোট সংগৃহীত ক্যাশ আয়
  Money get totalCashIncome =>
      Money.fromPaisa(totalApplicationReceived + totalIndependentIncome);

  /// মোট খরচ (কাজের খরচ + সাধারণ খরচ)
  Money get totalCashExpense =>
      Money.fromPaisa(totalApplicationExpense + totalGeneralExpense);

  /// দোকানের সামগ্রিক প্রকৃত নিট ইনকাম (Realized Net Income):
  /// (মোট আদায় + স্বতন্ত্র আয়) - (কাজের খরচ + সাধারণ খরচ)
  Money get netRealizedIncome =>
      Money.fromPaisa((totalApplicationReceived + totalIndependentIncome) -
          (totalApplicationExpense + totalGeneralExpense));

  Money get agreedVolume => Money.fromPaisa(totalAgreedVolume);
  Money get effectiveDue => Money.fromPaisa(totalEffectiveDue);
}

@DriftAccessor(tables: [
  Payments,
  Expenses,
  IndependentIncomes,
  Applications,
  StatusHistory,
])
class FinanceDao extends DatabaseAccessor<AppDatabase>
    with _$FinanceDaoMixin {
  FinanceDao(super.db);

  // -------------------------------------------------------------
  // ১. পেমেন্ট (Payments)
  // -------------------------------------------------------------

  /// নির্দিষ্ট আবেদনের সক্রিয় পেমেন্ট স্ট্রিম
  Stream<List<Payment>> watchPaymentsForApplication(String applicationId) {
    return (select(payments)
          ..where((tbl) =>
              tbl.applicationId.equals(applicationId) & tbl.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  /// নির্দিষ্ট আবেদনের সক্রিয় পেমেন্ট সংগ্রহ (Future)
  Future<List<Payment>> getPaymentsForApplication(String applicationId) {
    return (select(payments)
          ..where((tbl) =>
              tbl.applicationId.equals(applicationId) & tbl.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// নির্দিষ্ট আবেদনের মোট গৃহীত অর্থ (পয়সায়)
  Future<int> getTotalReceivedForApplication(String applicationId) async {
    final amountCol = payments.amount.sum();
    final query = selectOnly(payments)
      ..addColumns([amountCol])
      ..where(payments.applicationId.equals(applicationId) &
          payments.deletedAt.isNull());

    final row = await query.getSingle();
    return row.read(amountCol) ?? 0;
  }

  /// নতুন পেমেন্ট সংযোজন
  Future<int> insertPayment(PaymentsCompanion companion) {
    return into(payments).insert(companion);
  }

  /// পেমেন্ট সফট ডিলিট (ক্যাশ ট্রেইল অক্ষত রেখে)
  Future<int> softDeletePayment(String id, {int? timestamp}) {
    final now = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    return (update(payments)..where((tbl) => tbl.id.equals(id))).write(
      PaymentsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// সফট ডিলিট পেমেন্ট পুনরুদ্ধার
  Future<int> restorePayment(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(payments)..where((tbl) => tbl.id.equals(id))).write(
      PaymentsCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  // -------------------------------------------------------------
  // ২. খরচ (Expenses)
  // -------------------------------------------------------------

  /// নির্দিষ্ট আবেদনের সক্রিয় কাজের খরচের স্ট্রিম
  Stream<List<Expense>> watchExpensesForApplication(String applicationId) {
    return (select(expenses)
          ..where((tbl) =>
              tbl.applicationId.equals(applicationId) &
              tbl.isGeneral.equals(0) &
              tbl.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  /// নির্দিষ্ট আবেদনের সক্রিয় কাজের খরচ সংগ্রহ (Future)
  Future<List<Expense>> getExpensesForApplication(String applicationId) {
    return (select(expenses)
          ..where((tbl) =>
              tbl.applicationId.equals(applicationId) &
              tbl.isGeneral.equals(0) &
              tbl.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// নির্দিষ্ট আবেদনের মোট কাজের খরচ (পয়সায়)
  Future<int> getTotalExpenseForApplication(String applicationId) async {
    final amountCol = expenses.amount.sum();
    final query = selectOnly(expenses)
      ..addColumns([amountCol])
      ..where(expenses.applicationId.equals(applicationId) &
          expenses.isGeneral.equals(0) &
          expenses.deletedAt.isNull());

    final row = await query.getSingle();
    return row.read(amountCol) ?? 0;
  }

  /// দোকানের সাধারণ খরচের স্ট্রিম
  Stream<List<Expense>> watchGeneralExpenses({
    int? startDate,
    int? endDate,
    String? category,
  }) {
    final query = select(expenses)
      ..where((tbl) {
        var expr = tbl.isGeneral.equals(1) &
            tbl.applicationId.isNull() &
            tbl.deletedAt.isNull();
        if (startDate != null) {
          expr = expr & tbl.date.isBiggerOrEqualValue(startDate);
        }
        if (endDate != null) {
          expr = expr & tbl.date.isSmallerOrEqualValue(endDate);
        }
        if (category != null && category.isNotEmpty) {
          expr = expr & tbl.category.equals(category);
        }
        return expr;
      })
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    return query.watch();
  }

  /// নতুন খরচ সংযোজন
  Future<int> insertExpense(ExpensesCompanion companion) {
    return into(expenses).insert(companion);
  }

  /// খরচ সফট ডিলিট
  Future<int> softDeleteExpense(String id, {int? timestamp}) {
    final now = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    return (update(expenses)..where((tbl) => tbl.id.equals(id))).write(
      ExpensesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// সফট ডিলিট খরচ পুনরুদ্ধার
  Future<int> restoreExpense(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(expenses)..where((tbl) => tbl.id.equals(id))).write(
      ExpensesCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  // -------------------------------------------------------------
  // ৩. স্বতন্ত্র আয় (Independent Incomes)
  // -------------------------------------------------------------

  /// স্বতন্ত্র আয়ের স্ট্রিম
  Stream<List<IndependentIncome>> watchIndependentIncomes({
    int? startDate,
    int? endDate,
    String? category,
  }) {
    final query = select(independentIncomes)
      ..where((tbl) {
        var expr = tbl.deletedAt.isNull();
        if (startDate != null) {
          expr = expr & tbl.date.isBiggerOrEqualValue(startDate);
        }
        if (endDate != null) {
          expr = expr & tbl.date.isSmallerOrEqualValue(endDate);
        }
        if (category != null && category.isNotEmpty) {
          expr = expr & tbl.category.equals(category);
        }
        return expr;
      })
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    return query.watch();
  }

  /// নতুন স্বতন্ত্র আয় সংযোজন
  Future<int> insertIndependentIncome(
      IndependentIncomesCompanion companion) {
    return into(independentIncomes).insert(companion);
  }

  /// স্বতন্ত্র আয় সফট ডিলিট
  Future<int> softDeleteIndependentIncome(String id, {int? timestamp}) {
    final now = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    return (update(independentIncomes)..where((tbl) => tbl.id.equals(id))).write(
      IndependentIncomesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// সফট ডিলিট স্বতন্ত্র আয় পুনরুদ্ধার
  Future<int> restoreIndependentIncome(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(independentIncomes)..where((tbl) => tbl.id.equals(id))).write(
      IndependentIncomesCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  // -------------------------------------------------------------
  // ৪. সেন্ট্রালাইজড লেনদেন ভিউ (Unified Transactions View)
  // -------------------------------------------------------------

  /// ৬-সোর্স একীভূত লেনদেন স্ট্রিম
  Stream<List<UnifiedTransactionsViewData>> watchUnifiedTransactions({
    int? startDate,
    int? endDate,
    String? type,
    String? source,
    String? search,
  }) {
    return _filterUnifiedTransactions(
      db.select(db.unifiedTransactionsView),
      startDate: startDate,
      endDate: endDate,
      type: type,
      source: source,
      search: search,
    ).watch();
  }

  /// ৬-সোর্স একীভূত লেনদেন সংগ্রহ (Future)
  Future<List<UnifiedTransactionsViewData>> getUnifiedTransactions({
    int? startDate,
    int? endDate,
    String? type,
    String? source,
    String? search,
  }) {
    return _filterUnifiedTransactions(
      db.select(db.unifiedTransactionsView),
      startDate: startDate,
      endDate: endDate,
      type: type,
      source: source,
      search: search,
    ).get();
  }

  SimpleSelectStatement<UnifiedTransactionsView, UnifiedTransactionsViewData>
      _filterUnifiedTransactions(
    SimpleSelectStatement<UnifiedTransactionsView, UnifiedTransactionsViewData>
        query, {
    int? startDate,
    int? endDate,
    String? type,
    String? source,
    String? search,
  }) {
    query.where((tbl) {
      final predicates = <Expression<bool>>[];

      if (startDate != null) {
        predicates.add(tbl.date.isBiggerOrEqualValue(startDate));
      }
      if (endDate != null) {
        predicates.add(tbl.date.isSmallerOrEqualValue(endDate));
      }
      if (type != null && type.isNotEmpty) {
        predicates.add(tbl.type.equals(type));
      }
      if (source != null && source.isNotEmpty) {
        predicates.add(tbl.source.equals(source));
      }
      if (search != null && search.trim().isNotEmpty) {
        final term = search.trim();
        final searchPredicates = <Expression<bool>>[
          tbl.category.contains(term),
        ];
        searchPredicates.add(tbl.applicationTitle.contains(term));
        searchPredicates.add(tbl.applicantName.contains(term));
        searchPredicates.add(tbl.customerName.contains(term));
        searchPredicates.add(tbl.note.contains(term));

        Expression<bool>? combined;
        for (final p in searchPredicates) {
          combined = combined == null ? p : (combined | p);
        }
        if (combined != null) {
          predicates.add(combined);
        }
      }

      return predicates.isEmpty
          ? const Constant(true)
          : Expression.and(predicates);
    });

    query.orderBy([(t) => OrderingTerm.desc(t.date)]);
    return query;
  }

  // -------------------------------------------------------------
  // ৫. সামগ্রিক আর্থিক হিসাব এগ্রিগেশন (Overview Stats)
  // -------------------------------------------------------------

  /// নির্দিষ্ট সময়ের সম্পূর্ণ সঠিক আর্থিক হিসাব নিরূপণ
  Future<ShopFinancialOverview> getOverallFinancialStats({
    int? startDate,
    int? endDate,
  }) async {
    // ১. আবেদনের মোট আদায়
    final payAmountCol = payments.amount.sum();
    final payQuery = selectOnly(payments)
      ..addColumns([payAmountCol])
      ..where(payments.deletedAt.isNull());
    if (startDate != null) {
      payQuery.where(payments.date.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      payQuery.where(payments.date.isSmallerOrEqualValue(endDate));
    }
    final totalAppReceived = (await payQuery.getSingle()).read(payAmountCol) ?? 0;

    // ২. মোট স্বতন্ত্র আয়
    final indAmountCol = independentIncomes.amount.sum();
    final indQuery = selectOnly(independentIncomes)
      ..addColumns([indAmountCol])
      ..where(independentIncomes.deletedAt.isNull());
    if (startDate != null) {
      indQuery.where(independentIncomes.date.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      indQuery.where(independentIncomes.date.isSmallerOrEqualValue(endDate));
    }
    final totalIndIncome = (await indQuery.getSingle()).read(indAmountCol) ?? 0;

    // ৩. আবেদনের মোট কাজের খরচ
    final appExpCol = expenses.amount.sum();
    final appExpQuery = selectOnly(expenses)
      ..addColumns([appExpCol])
      ..where(expenses.isGeneral.equals(0) &
          expenses.applicationId.isNotNull() &
          expenses.deletedAt.isNull());
    if (startDate != null) {
      appExpQuery.where(expenses.date.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      appExpQuery.where(expenses.date.isSmallerOrEqualValue(endDate));
    }
    final totalAppExpense = (await appExpQuery.getSingle()).read(appExpCol) ?? 0;

    // ৪. দোকানের মোট সাধারণ খরচ
    final genExpCol = expenses.amount.sum();
    final genExpQuery = selectOnly(expenses)
      ..addColumns([genExpCol])
      ..where(expenses.isGeneral.equals(1) &
          expenses.applicationId.isNull() &
          expenses.deletedAt.isNull());
    if (startDate != null) {
      genExpQuery.where(expenses.date.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      genExpQuery.where(expenses.date.isSmallerOrEqualValue(endDate));
    }
    final totalGenExpense = (await genExpQuery.getSingle()).read(genExpCol) ?? 0;

    // ৫. চুক্তিমূল্য ও বকেয়া হিসাব (সক্রিয় আবেদনসমূহ)
    final activeApps = await (select(applications)
          ..where((tbl) => tbl.deletedAt.isNull()))
        .get();

    int totalAgreed = 0;
    int totalEffectiveDue = 0;

    for (final app in activeApps) {
      totalAgreed += app.agreedAmount;

      if (app.isMarkedAsPaid == 1) {
        // নিয়ম ২: বকেয়া মওকুফ ও নিষ্পত্তি চিহ্নিত ফাইলে কার্যকর বকেয়া = ০
        continue;
      }

      // আবেদনের মোট আদায়
      final received = await getTotalReceivedForApplication(app.id);
      final due = app.agreedAmount - received;
      if (due > 0) {
        totalEffectiveDue += due;
      }
    }

    return ShopFinancialOverview(
      totalApplicationReceived: totalAppReceived,
      totalIndependentIncome: totalIndIncome,
      totalApplicationExpense: totalAppExpense,
      totalGeneralExpense: totalGenExpense,
      totalAgreedVolume: totalAgreed,
      totalEffectiveDue: totalEffectiveDue,
    );
  }
}
