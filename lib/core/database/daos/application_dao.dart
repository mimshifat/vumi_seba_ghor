import 'package:drift/drift.dart';

import '../../../features/applications/domain/models/application_with_financials.dart';
import '../../utils/bengali_digits.dart';
import '../app_database.dart';
import '../tables/applications_table.dart';
import '../tables/expenses_table.dart';
import '../tables/payments_table.dart';
import '../tables/status_history_table.dart';

part 'application_dao.g.dart';

@DriftAccessor(tables: [
  Applications,
  StatusHistory,
  Payments,
  Expenses,
])
class ApplicationDao extends DatabaseAccessor<AppDatabase>
    with _$ApplicationDaoMixin {
  ApplicationDao(super.db);

  /// ফিল্টার ও সার্চসহ সকল আবেদনের স্ট্রিম (রিয়েক্টিভ ওয়াচ)।
  Stream<List<Application>> watchApplications({
    String? status,
    String? workType,
    String? officeId,
    String? mouza,
    bool? isMarkedAsPaid,
    String? search,
    bool includeDeleted = false,
  }) {
    return _buildApplicationsQuery(
      status: status,
      workType: workType,
      officeId: officeId,
      mouza: mouza,
      isMarkedAsPaid: isMarkedAsPaid,
      search: search,
      includeDeleted: includeDeleted,
    ).watch();
  }

  /// ফিল্টার ও সার্চসহ আবেদনের তালিকা সংগ্রহ (Future)।
  Future<List<Application>> getApplications({
    String? status,
    String? workType,
    String? officeId,
    String? mouza,
    bool? isMarkedAsPaid,
    String? search,
    bool includeDeleted = false,
  }) {
    return _buildApplicationsQuery(
      status: status,
      workType: workType,
      officeId: officeId,
      mouza: mouza,
      isMarkedAsPaid: isMarkedAsPaid,
      search: search,
      includeDeleted: includeDeleted,
    ).get();
  }

  SimpleSelectStatement<$ApplicationsTable, Application>
      _buildApplicationsQuery({
    String? status,
    String? workType,
    String? officeId,
    String? mouza,
    bool? isMarkedAsPaid,
    String? search,
    bool includeDeleted = false,
  }) {
    final query = select(applications);

    query.where((tbl) {
      final predicates = <Expression<bool>>[];

      if (!includeDeleted) {
        predicates.add(tbl.deletedAt.isNull());
      }

      if (status != null && status.isNotEmpty) {
        predicates.add(tbl.status.equals(status));
      }

      if (workType != null && workType.isNotEmpty) {
        predicates.add(tbl.workType.equals(workType));
      }

      if (officeId != null && officeId.isNotEmpty) {
        predicates.add(tbl.officeId.equals(officeId));
      }

      if (mouza != null && mouza.isNotEmpty) {
        predicates.add(tbl.mouza.equals(mouza));
      }

      if (isMarkedAsPaid != null) {
        predicates.add(tbl.isMarkedAsPaid.equals(isMarkedAsPaid ? 1 : 0));
      }

      if (search != null && search.trim().isNotEmpty) {
        final rawTerm = search.trim();
        final enTerm = BengaliDigits.toEnglish(rawTerm);
        final bnTerm = BengaliDigits.toBengali(rawTerm);

        final searchPredicates = <Expression<bool>>[
          tbl.applicantName.contains(rawTerm),
          tbl.applicantPhone.contains(enTerm),
          tbl.applicantPhone.contains(bnTerm),
          tbl.applicantPhone.contains(rawTerm),
        ];

        searchPredicates.add(tbl.mouza.contains(rawTerm));
        searchPredicates.add(tbl.appNumber.contains(enTerm));
        searchPredicates.add(tbl.appNumber.contains(rawTerm));
        searchPredicates.add(tbl.caseNumber.contains(enTerm));
        searchPredicates.add(tbl.caseNumber.contains(rawTerm));

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

    query.orderBy([
      (t) => OrderingTerm(
          expression: t.applicationDate, mode: OrderingMode.desc),
      (t) =>
          OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
    ]);

    return query;
  }

  /// নির্দিষ্ট আইডি অনুযায়ী একক আবেদন খোঁজা।
  Future<Application?> getApplicationById(String id,
      {bool includeDeleted = false}) {
    final query = select(applications)..where((tbl) => tbl.id.equals(id));
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// নির্দিষ্ট আইডি অনুযায়ী একক আবেদনের স্ট্রিম।
  Stream<Application?> watchApplicationById(String id) {
    final query = select(applications)
      ..where((tbl) => tbl.id.equals(id) & tbl.deletedAt.isNull());
    return query.watchSingleOrNull();
  }

  /// আবেদন ও তার মোট আর্থিক হিসাবসহ রিয়েক্টিভ ওয়াচ স্ট্রিম
  Stream<List<ApplicationWithFinancials>> watchApplicationsWithFinancials({
    bool includeDeleted = false,
  }) {
    final deletedClause = includeDeleted ? '1=1' : 'a.deleted_at IS NULL';
    final sql = '''
      SELECT 
        a.id,
        a.applicant_id,
        a.applicant_name,
        a.applicant_phone,
        a.applicant_address,
        a.reference_id,
        a.reference_name,
        a.office_id,
        a.office_name,
        a.mouza,
        a.app_number,
        a.case_number,
        a.work_type,
        a.application_date,
        a.status,
        a.agreed_amount,
        a.is_marked_as_paid,
        a.notes,
        a.created_at,
        a.updated_at,
        a.deleted_at,
        COALESCE((SELECT SUM(p.amount) FROM payments p WHERE p.application_id = a.id AND p.deleted_at IS NULL), 0) AS total_received,
        COALESCE((SELECT SUM(e.amount) FROM expenses e WHERE e.application_id = a.id AND e.deleted_at IS NULL AND e.is_general = 0), 0) AS total_expense
      FROM applications a
      WHERE $deletedClause
      ORDER BY a.application_date DESC, a.created_at DESC;
    ''';

    return customSelect(
      sql,
      readsFrom: {applications, payments, expenses},
    ).watch().map((rows) {
      return rows.map((row) {
        final app = applications.map(row.data);
        final received = row.read<int>('total_received');
        final expense = row.read<int>('total_expense');
        return ApplicationWithFinancials(
          application: app,
          totalReceivedPaisa: received,
          totalExpensePaisa: expense,
        );
      }).toList();
    });
  }

  /// আবেদন ও তার মোট আর্থিক হিসাবসহ সংগ্রহ (Future)
  Future<List<ApplicationWithFinancials>> getApplicationsWithFinancials({
    bool includeDeleted = false,
  }) async {
    final deletedClause = includeDeleted ? '1=1' : 'a.deleted_at IS NULL';
    final sql = '''
      SELECT 
        a.id,
        a.applicant_id,
        a.applicant_name,
        a.applicant_phone,
        a.applicant_address,
        a.reference_id,
        a.reference_name,
        a.office_id,
        a.office_name,
        a.mouza,
        a.app_number,
        a.case_number,
        a.work_type,
        a.application_date,
        a.status,
        a.agreed_amount,
        a.is_marked_as_paid,
        a.notes,
        a.created_at,
        a.updated_at,
        a.deleted_at,
        COALESCE((SELECT SUM(p.amount) FROM payments p WHERE p.application_id = a.id AND p.deleted_at IS NULL), 0) AS total_received,
        COALESCE((SELECT SUM(e.amount) FROM expenses e WHERE e.application_id = a.id AND e.deleted_at IS NULL AND e.is_general = 0), 0) AS total_expense
      FROM applications a
      WHERE $deletedClause
      ORDER BY a.application_date DESC, a.created_at DESC;
    ''';

    final rows = await customSelect(
      sql,
      readsFrom: {applications, payments, expenses},
    ).get();

    return rows.map((row) {
      final app = applications.map(row.data);
      final received = row.read<int>('total_received');
      final expense = row.read<int>('total_expense');
      return ApplicationWithFinancials(
        application: app,
        totalReceivedPaisa: received,
        totalExpensePaisa: expense,
      );
    }).toList();
  }

  /// নির্দিষ্ট আবেদনের সম্পূর্ণ আর্থিক হিসেবসহ তথ্য
  Future<ApplicationWithFinancials?> getApplicationWithFinancialsById(
      String id) async {
    final sql = '''
      SELECT 
        a.id,
        a.applicant_id,
        a.applicant_name,
        a.applicant_phone,
        a.applicant_address,
        a.reference_id,
        a.reference_name,
        a.office_id,
        a.office_name,
        a.mouza,
        a.app_number,
        a.case_number,
        a.work_type,
        a.application_date,
        a.status,
        a.agreed_amount,
        a.is_marked_as_paid,
        a.notes,
        a.created_at,
        a.updated_at,
        a.deleted_at,
        COALESCE((SELECT SUM(p.amount) FROM payments p WHERE p.application_id = a.id AND p.deleted_at IS NULL), 0) AS total_received,
        COALESCE((SELECT SUM(e.amount) FROM expenses e WHERE e.application_id = a.id AND e.deleted_at IS NULL AND e.is_general = 0), 0) AS total_expense
      FROM applications a
      WHERE a.id = ?
      LIMIT 1;
    ''';

    final rows = await customSelect(
      sql,
      variables: [Variable.withString(id)],
      readsFrom: {applications, payments, expenses},
    ).get();

    if (rows.isEmpty) return null;
    final row = rows.first;
    return ApplicationWithFinancials(
      application: applications.map(row.data),
      totalReceivedPaisa: row.read<int>('total_received'),
      totalExpensePaisa: row.read<int>('total_expense'),
    );
  }

  /// নতুন আবেদন সংযোজন।
  Future<int> insertApplication(ApplicationsCompanion companion) {
    return into(applications).insert(companion);
  }

  /// আবেদন আপডেট।
  Future<bool> updateApplication(ApplicationsCompanion companion) {
    return update(applications).replace(companion);
  }

  /// সফট ডিলিট: `deletedAt` এ বর্তমান টাইমস্ট্যাম্প বসিয়ে নিষ্ক্রিয় করা।
  Future<int> softDeleteApplication(String id, {int? timestamp}) {
    final now = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    return (update(applications)..where((tbl) => tbl.id.equals(id))).write(
      ApplicationsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// সফট ডিলিট হওয়া আবেদন পুনরুদ্ধার (Undo / Restore)।
  Future<int> restoreApplication(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(applications)..where((tbl) => tbl.id.equals(id))).write(
      ApplicationsCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  /// বকেয়া মওকুফ ও নিষ্পত্তি চিহ্নিতকরণ ('Mark as Paid')।
  Future<int> markAsPaid(String id, bool paid) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(applications)..where((tbl) => tbl.id.equals(id))).write(
      ApplicationsCompanion(
        isMarkedAsPaid: Value(paid ? 1 : 0),
        updatedAt: Value(now),
      ),
    );
  }

  /// ডুপ্লিকেট আবেদন নম্বর পরীক্ষা।
  ///
  /// একই অফিসে একই আবেদন নম্বর ইতিমধ্যে কোনো সক্রিয় আবেদনে থাকলে সত্য ফেরত দেয়।
  Future<bool> isDuplicateAppNumber(
    String appNumber, {
    String? excludeId,
    String? officeId,
  }) async {
    final query = select(applications)
      ..where((tbl) {
        var expr = tbl.appNumber.equals(appNumber) & tbl.deletedAt.isNull();
        if (excludeId != null) {
          expr = expr & tbl.id.isNotValue(excludeId);
        }
        if (officeId != null) {
          expr = expr & tbl.officeId.equals(officeId);
        }
        return expr;
      });

    final count = await query.get().then((rows) => rows.length);
    return count > 0;
  }

  /// প্রতিটি অবস্থার সক্রিয় আবেদন সংখ্যা এগ্রিগেশন।
  Future<Map<String, int>> countByStatus() async {
    final result = <String, int>{};
    final rows = await (select(applications)
          ..where((tbl) => tbl.deletedAt.isNull()))
        .get();

    for (final row in rows) {
      result[row.status] = (result[row.status] ?? 0) + 1;
    }
    return result;
  }

  /// আবেদনের অবস্থা পরিবর্তনের ইতিহাস দেখা।
  Stream<List<StatusHistoryData>> watchStatusHistory(String applicationId) {
    final query = select(statusHistory)
      ..where((tbl) =>
          tbl.applicationId.equals(applicationId) & tbl.deletedAt.isNull())
      ..orderBy([
        (t) =>
            OrderingTerm(expression: t.changedAt, mode: OrderingMode.desc),
      ]);
    return query.watch();
  }

  /// আবেদনের অবস্থা পরিবর্তনের ইতিহাস সংগ্রহ (Future)।
  Future<List<StatusHistoryData>> getStatusHistory(String applicationId) {
    final query = select(statusHistory)
      ..where((tbl) =>
          tbl.applicationId.equals(applicationId) & tbl.deletedAt.isNull())
      ..orderBy([
        (t) =>
            OrderingTerm(expression: t.changedAt, mode: OrderingMode.desc),
      ]);
    return query.get();
  }

  /// অবস্থা পরিবর্তনের নতুন ইতিহাস রেকর্ড করা।
  Future<int> insertStatusHistory(StatusHistoryCompanion companion) {
    return into(statusHistory).insert(companion);
  }
}

