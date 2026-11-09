import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/money.dart';

/// নির্দিষ্ট আবেদনের আর্থিক সারাংশ
class ApplicationFinancials {
  final String applicationId;
  final int agreedPaisa;
  final int receivedPaisa;
  final int expensePaisa;
  final bool isMarkedAsPaid;

  const ApplicationFinancials({
    required this.applicationId,
    required this.agreedPaisa,
    required this.receivedPaisa,
    required this.expensePaisa,
    required this.isMarkedAsPaid,
  });

  Money get agreed => Money.fromPaisa(agreedPaisa);
  Money get received => Money.fromPaisa(receivedPaisa);
  Money get expense => Money.fromPaisa(expensePaisa);

  /// প্রকৃত ইনকাম (Golden rule §1.2): মোট আদায় - মোট কাজের খরচ
  Money get actualIncome => Money.fromPaisa(receivedPaisa - expensePaisa);

  /// সম্ভাব্য ইনকাম (চুক্তির ভিত্তিতে): চুক্তির টাকা - কাজের খরচ
  Money get estimatedIncome => Money.fromPaisa(agreedPaisa - expensePaisa);

  /// কার্যকর বকেয়া ('Mark as Paid' হলে ০)
  Money get effectiveDue => isMarkedAsPaid
      ? Money.zero
      : Money.fromPaisa((agreedPaisa - receivedPaisa).clamp(0, double.maxFinite.toInt()));

  /// কাঁচা বকেয়া
  Money get rawDue => Money.fromPaisa((agreedPaisa - receivedPaisa).clamp(0, double.maxFinite.toInt()));
}

/// আর্থিক হিসাব, অডিট ও ক্যাশবই রিপোজিটরি (BACKEND_MASTER_PLAN.md §1.2, §5)
class FinanceRepository {
  final AppDatabase _db;
  final Uuid _uuid;

  FinanceRepository(this._db, [Uuid? uuid]) : _uuid = uuid ?? const Uuid();

  // -------------------------------------------------------------
  // ১. পেমেন্ট (Payments)
  // -------------------------------------------------------------

  /// কিস্তি বা ফি বাবদ টাকা জমা গ্রহণ
  Future<Payment> addPayment({
    String? id,
    required String applicationId,
    required int amountPaisa,
    DateTime? date,
    String method = 'নগদ',
    String? note,
    bool isStatusFee = false,
    String? statusHistoryId,
    String? statusName,
    bool allowOverpayment = true,
  }) async {
    try {
      if (amountPaisa <= 0) {
        throw AppFailure.invalidAmount('জমার পরিমাণ শূন্যের বেশি হতে হবে।');
      }

      final app = await _db.applicationDao.getApplicationById(applicationId);
      if (app == null) {
        throw AppFailure.custom('সংশ্লিষ্ট আবেদনটি খুঁজে পাওয়া যায়নি।');
      }

      // অতিরিক্ত আদায়ের সতর্কতা চেক
      final totalReceived =
          await _db.financeDao.getTotalReceivedForApplication(applicationId);
      final remainingDue = app.agreedAmount - totalReceived;

      if (!allowOverpayment && amountPaisa > remainingDue && remainingDue > 0) {
        throw AppFailure.overpaymentWarning();
      }

      final paymentId = id ?? _uuid.v4();
      final now = DateTime.now().millisecondsSinceEpoch;
      final payDate = date?.millisecondsSinceEpoch ?? now;

      await _db.financeDao.insertPayment(
        PaymentsCompanion.insert(
          id: paymentId,
          applicationId: applicationId,
          amount: amountPaisa,
          date: payDate,
          method: method.trim().isNotEmpty ? method.trim() : 'নগদ',
          note: Value(note?.trim()),
          statusHistoryId: Value(statusHistoryId),
          statusName: Value(statusName),
          isStatusFee: Value(isStatusFee ? 1 : 0),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final row = await (_db.select(_db.payments)
            ..where((tbl) => tbl.id.equals(paymentId)))
          .getSingle();
      return row;
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// পেমেন্ট সফট ডিলিট
  Future<void> deletePayment(String id) async {
    try {
      await _db.financeDao.softDeletePayment(id);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// পেমেন্ট পুনরুদ্ধার
  Future<void> restorePayment(String id) async {
    try {
      await _db.financeDao.restorePayment(id);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// নির্দিষ্ট আবেদনের পেমেন্ট স্ট্রিম
  Stream<List<Payment>> watchPaymentsForApplication(String applicationId) {
    return _db.financeDao.watchPaymentsForApplication(applicationId);
  }

  /// নির্দিষ্ট আবেদনের পেমেন্ট তালিকা সংগ্রহ (Future)
  Future<List<Payment>> getPaymentsForApplication(String applicationId) async {
    try {
      return await _db.financeDao.getPaymentsForApplication(applicationId);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  // -------------------------------------------------------------
  // ২. খরচ (Expenses) — কঠোর বিভাজন (BACKEND_MASTER_PLAN.md §1.2 নিয়ম ৪)
  // -------------------------------------------------------------

  /// ফাইলের সরাসরি কাজের খরচ যোগ (আবেদন সংশ্লিষ্ট)
  Future<Expense> addApplicationExpense({
    String? id,
    required String applicationId,
    required int amountPaisa,
    required String category,
    DateTime? date,
    String? note,
    String? statusHistoryId,
    String? statusName,
    bool isStatusExpense = false,
  }) async {
    try {
      if (amountPaisa <= 0) {
        throw AppFailure.invalidAmount('খরচের পরিমাণ শূন্যের বেশি হতে হবে।');
      }

      final cleanCategory = category.trim();
      if (cleanCategory.isEmpty) {
        throw AppFailure.requiredField('খরচের খাত নির্বাচন');
      }

      final app = await _db.applicationDao.getApplicationById(applicationId);
      if (app == null) {
        throw AppFailure.custom('সংশ্লিষ্ট আবেদনটি খুঁজে পাওয়া যায়নি।');
      }

      final expenseId = id ?? _uuid.v4();
      final now = DateTime.now().millisecondsSinceEpoch;
      final expDate = date?.millisecondsSinceEpoch ?? now;

      await _db.financeDao.insertExpense(
        ExpensesCompanion.insert(
          id: expenseId,
          applicationId: Value(applicationId),
          amount: amountPaisa,
          category: cleanCategory,
          date: expDate,
          isGeneral: const Value(0), // ফাইলের খরচ
          note: Value(note?.trim()),
          statusHistoryId: Value(statusHistoryId),
          statusName: Value(statusName),
          isStatusExp: Value(isStatusExpense ? 1 : 0),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final row = await (_db.select(_db.expenses)
            ..where((tbl) => tbl.id.equals(expenseId)))
          .getSingle();
      return row;
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// দোকানের সাধারণ পরিচালন খরচ যোগ (দোকান ভাড়া, নাস্তা, কারেন্ট বিল)
  Future<Expense> addGeneralExpense({
    String? id,
    required int amountPaisa,
    required String category,
    DateTime? date,
    String? note,
  }) async {
    try {
      if (amountPaisa <= 0) {
        throw AppFailure.invalidAmount('খরচের পরিমাণ শূন্যের বেশি হতে হবে।');
      }

      final cleanCategory = category.trim();
      if (cleanCategory.isEmpty) {
        throw AppFailure.requiredField('খরচের খাত নির্বাচন');
      }

      final expenseId = id ?? _uuid.v4();
      final now = DateTime.now().millisecondsSinceEpoch;
      final expDate = date?.millisecondsSinceEpoch ?? now;

      await _db.financeDao.insertExpense(
        ExpensesCompanion.insert(
          id: expenseId,
          applicationId: const Value(null), // সাধারণ খরচে আবেদন থাকবে না
          amount: amountPaisa,
          category: cleanCategory,
          date: expDate,
          isGeneral: const Value(1), // সাধারণ খরচ
          note: Value(note?.trim()),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final row = await (_db.select(_db.expenses)
            ..where((tbl) => tbl.id.equals(expenseId)))
          .getSingle();
      return row;
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// খরচ সফট ডিলিট
  Future<void> deleteExpense(String id) async {
    try {
      await _db.financeDao.softDeleteExpense(id);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// খরচ পুনরুদ্ধার
  Future<void> restoreExpense(String id) async {
    try {
      await _db.financeDao.restoreExpense(id);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// নির্দিষ্ট আবেদনের খরচের স্ট্রিম
  Stream<List<Expense>> watchExpensesForApplication(String applicationId) {
    return _db.financeDao.watchExpensesForApplication(applicationId);
  }

  /// নির্দিষ্ট আবেদনের কাজের খরচের তালিকা সংগ্রহ (Future)
  Future<List<Expense>> getExpensesForApplication(String applicationId) async {
    try {
      return await _db.financeDao.getExpensesForApplication(applicationId);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// দোকানের সাধারণ খরচের স্ট্রিম
  Stream<List<Expense>> watchGeneralExpenses({
    int? startDate,
    int? endDate,
    String? category,
  }) {
    return _db.financeDao.watchGeneralExpenses(
      startDate: startDate,
      endDate: endDate,
      category: category,
    );
  }

  // -------------------------------------------------------------
  // ৩. স্বতন্ত্র আয় (Independent Incomes)
  // -------------------------------------------------------------

  /// স্বতন্ত্র দোকান আয় সংযোজন (টাইপিং, ফটোকপি, প্রিন্টিং)
  Future<IndependentIncome> addIndependentIncome({
    String? id,
    required String category,
    required int amountPaisa,
    DateTime? date,
    String paymentMethod = 'নগদ',
    String? customerName,
    String? note,
  }) async {
    try {
      if (amountPaisa <= 0) {
        throw AppFailure.invalidAmount('আয়ের পরিমাণ শূন্যের বেশি হতে হবে।');
      }

      final cleanCategory = category.trim();
      if (cleanCategory.isEmpty) {
        throw AppFailure.requiredField('আয়ের খাত নির্বাচন');
      }

      final incomeId = id ?? _uuid.v4();
      final now = DateTime.now().millisecondsSinceEpoch;
      final incomeDate = date?.millisecondsSinceEpoch ?? now;

      await _db.financeDao.insertIndependentIncome(
        IndependentIncomesCompanion.insert(
          id: incomeId,
          category: cleanCategory,
          amount: amountPaisa,
          date: incomeDate,
          paymentMethod: paymentMethod.trim().isNotEmpty
              ? paymentMethod.trim()
              : 'নগদ',
          customerName: Value(customerName?.trim()),
          note: Value(note?.trim()),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final row = await (_db.select(_db.independentIncomes)
            ..where((tbl) => tbl.id.equals(incomeId)))
          .getSingle();
      return row;
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// স্বতন্ত্র আয় সফট ডিলিট
  Future<void> deleteIndependentIncome(String id) async {
    try {
      await _db.financeDao.softDeleteIndependentIncome(id);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// স্বতন্ত্র আয় পুনরুদ্ধার
  Future<void> restoreIndependentIncome(String id) async {
    try {
      await _db.financeDao.restoreIndependentIncome(id);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// স্বতন্ত্র আয়ের স্ট্রিম
  Stream<List<IndependentIncome>> watchIndependentIncomes({
    int? startDate,
    int? endDate,
    String? category,
  }) {
    return _db.financeDao.watchIndependentIncomes(
      startDate: startDate,
      endDate: endDate,
      category: category,
    );
  }

  // -------------------------------------------------------------
  // ৪. একীভূত ক্যাশবই ও ভিউ (Unified Transactions)
  // -------------------------------------------------------------

  /// সেন্ট্রালাইজড লেনদেন ওয়াচ স্ট্রিম
  Stream<List<UnifiedTransactionsViewData>> watchUnifiedTransactions({
    int? startDate,
    int? endDate,
    String? type,
    String? source,
    String? search,
  }) {
    return _db.financeDao.watchUnifiedTransactions(
      startDate: startDate,
      endDate: endDate,
      type: type,
      source: source,
      search: search,
    );
  }

  /// সেন্ট্রালাইজড লেনদেন তালিকা সংগ্রহ (Future)
  Future<List<UnifiedTransactionsViewData>> getUnifiedTransactions({
    int? startDate,
    int? endDate,
    String? type,
    String? source,
    String? search,
  }) async {
    try {
      return await _db.financeDao.getUnifiedTransactions(
        startDate: startDate,
        endDate: endDate,
        type: type,
        source: source,
        search: search,
      );
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  // -------------------------------------------------------------
  // ৫. আর্থিক হিসাব ও সারাংশ (Financial Overview)
  // -------------------------------------------------------------

  /// নির্দিষ্ট আবেদনের আর্থিক হিসাব (আদায়, কাজের খরচ, প্রকৃত ইনকাম, বকেয়া)
  Future<ApplicationFinancials> getApplicationFinancials(
      String applicationId) async {
    try {
      final app = await _db.applicationDao.getApplicationById(applicationId);
      if (app == null) {
        throw AppFailure.custom('আবেদনটি খুঁজে পাওয়া যায়নি।');
      }

      final received =
          await _db.financeDao.getTotalReceivedForApplication(applicationId);
      final expense =
          await _db.financeDao.getTotalExpenseForApplication(applicationId);

      return ApplicationFinancials(
        applicationId: applicationId,
        agreedPaisa: app.agreedAmount,
        receivedPaisa: received,
        expensePaisa: expense,
        isMarkedAsPaid: app.isMarkedAsPaid == 1,
      );
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// দোকানের সামগ্রিক নিট ইনকাম ও আর্থিক হিসাব (Realized Net Income)
  Future<ShopFinancialOverview> getShopFinancialOverview({
    int? startDate,
    int? endDate,
  }) async {
    try {
      return await _db.financeDao.getOverallFinancialStats(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }
}

