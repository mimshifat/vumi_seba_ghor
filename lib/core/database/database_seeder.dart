import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../demo/demo_data.dart';

/// ডেমো ডেটাকে ডেটাবেজে বসানোর সহায়ক।
class DatabaseSeeder {
  const DatabaseSeeder._();

  /// ডেটাবেজ এখনো ফাঁকা কিনা যাচাই করে।
  ///
  /// খালি থাকলে কেবল তখনই সিড ডেটা ঢোকানো হয়, যাতে ব্যবহারকারীর
  /// আসল ডেটা কখনোই ওভাররাইট না হয়।
  static Future<bool> isEmpty(AppDatabase db) async {
    final count = await db.applications.count().getSingle();
    return count == 0;
  }

  /// সিস্টেমের আবশ্যকীয় মৌলিক সেটিংস ও ক্যাটাগরি সিড করে (কোনো ডেমো আবেদন বা ব্যক্তি ছাড়া)।
  static Future<void> seedEssentialDefaults(AppDatabase db) async {
    const uuid = Uuid();
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction(() async {
      // ১. কাজের ধরন (যদি না থাকে)
      final wtCount = await db.workTypes.count().getSingle();
      if (wtCount == 0) {
        for (final workType in DemoStore.workTypes) {
          await db.into(db.workTypes).insert(
                WorkTypesCompanion.insert(
                  id: uuid.v4(),
                  name: workType,
                  isDefault: const Value(1),
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        }
      }

      // ২. খরচের খাতসমূহ (যদি না থাকে)
      final ecCount = await db.expenseCategories.count().getSingle();
      if (ecCount == 0) {
        for (final category in DemoStore.applicationExpenseCategories) {
          await db.into(db.expenseCategories).insert(
                ExpenseCategoriesCompanion.insert(
                  id: uuid.v4(),
                  name: category,
                  isGeneral: const Value(0),
                  isDefault: const Value(1),
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        }
        for (final category in DemoStore.generalExpenseCategories) {
          await db.into(db.expenseCategories).insert(
                ExpenseCategoriesCompanion.insert(
                  id: uuid.v4(),
                  name: category,
                  isGeneral: const Value(1),
                  isDefault: const Value(1),
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        }
      }

      // ৩. আয়ের খাতসমূহ (যদি না থাকে)
      final icCount = await db.incomeCategories.count().getSingle();
      if (icCount == 0) {
        for (final category in DemoStore.incomeCategories) {
          await db.into(db.incomeCategories).insert(
                IncomeCategoriesCompanion.insert(
                  id: uuid.v4(),
                  name: category,
                  isDefault: const Value(1),
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        }
      }

      // ৪. ভূমি অফিসসমূহ (যদি না থাকে)
      final officeCount = await db.offices.count().getSingle();
      if (officeCount == 0) {
        for (final office in DemoStore.offices) {
          await db.into(db.offices).insert(
                OfficesCompanion.insert(
                  id: uuid.v4(),
                  name: office.name,
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        }
      }

      // ৫. শপ সেটিংস (যদি না থাকে)
      final settingsCount = await db.shopSettings.count().getSingle();
      if (settingsCount == 0) {
        for (final entry in {
          'shop_name': 'রজব ভূমি সেবা ঘর',
          'proprietor_name': '',
          'shop_phone': '',
          'shop_address': '',
        }.entries) {
          await db.into(db.shopSettings).insert(
                ShopSettingsCompanion.insert(
                  settingKey: entry.key,
                  value: entry.value,
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        }
      }
    });
  }

  /// সমস্ত ডেমো বা পরীক্ষামূলক ব্যবসায়িক ডেটা মুছে ফেলা (আবেদন, ব্যক্তি, রেফারেন্স, কাজ, লেনদেন)
  static Future<void> clearAllDemoData(AppDatabase db) async {
    await db.transaction(() async {
      await db.delete(db.documents).go();
      await db.delete(db.tasks).go();
      await db.delete(db.payments).go();
      await db.delete(db.expenses).go();
      await db.delete(db.statusHistory).go();
      await db.delete(db.applications).go();
      await db.delete(db.persons).go();
      await db.delete(db.references).go();
      await db.delete(db.independentIncomes).go();
    });
  }

  /// ডেমো ডেটা ডেটাবেজে বসায় — একটি একক ট্রানজ্যাকশনে।
  ///
  /// যাতে কোনো একটি রেকর্ড ব্যর্থ হলে পুরো সিড রোলব্যাক হয় এবং
  /// ডেটাবেজ অর্ধেক লেখা অবস্থায় থাকে না।
  ///
  /// প্রাইমারি কী সবসময় UUID v4 (BACKEND_MASTER_PLAN.md)। ডেমো আইডিগুলো
  /// (`p-1`, `pay-1`) শুধু ডেমো স্টোরের ভেতরে রেফারেন্সের জন্য ব্যবহৃত,
  /// তাই এখানে একটি মেমোাইজড ম্যাপিং তৈরি করে তার বদলে UUID বসানো হয়।
  static Future<void> seed(AppDatabase db) async {
    const uuid = Uuid();
    final now = DateTime.now().millisecondsSinceEpoch;

    // ডেমো আইডি → UUID v4 ম্যাপিং। একই ডেমো আইডি সবসময় একই UUID-তে
    // রূপান্তরিত হয়, যাতে সম্পর্কগুলো অক্ষত থাকে।
    final ids = <String, String>{};
    String idOf(String demoId) =>
        ids.putIfAbsent(demoId, () => uuid.v4());

    // অফিসের নাম থেকে তার ডেমো আইডি বের করার সহায়ক।
    String? officeIdFor(String officeName) {
      for (final office in DemoStore.offices) {
        if (office.name == officeName) return idOf(office.id);
      }
      return null;
    }

    await db.transaction(() async {
      // --- ভূমি অফিস ---
      for (final office in DemoStore.offices) {
        await db.into(db.offices).insert(
              OfficesCompanion.insert(
                id: idOf(office.id),
                name: office.name,
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      // --- রেফারেন্স ব্যক্তি ---
      for (final reference in DemoStore.references) {
        await db.into(db.references).insert(
              ReferencesCompanion.insert(
                id: idOf(reference.id),
                name: reference.name,
                phone: reference.phone,
                address: Value(reference.address),
                notes: Value(reference.notes),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      // --- গ্রাহক ব্যক্তি ---
      for (final person in DemoStore.persons) {
        await db.into(db.persons).insert(
              PersonsCompanion.insert(
                id: idOf(person.id),
                name: person.name,
                phone: person.phone,
                address: Value(person.address),
                notes: Value(person.notes),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      // --- কাজের ধরন ---
      for (final workType in DemoStore.workTypes) {
        await db.into(db.workTypes).insert(
              WorkTypesCompanion.insert(
                id: idOf('wt-$workType'),
                name: workType,
                isDefault: const Value(1),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      // --- খরচের খাত (আবেদন ও সাধারণ) ---
      for (final category in DemoStore.applicationExpenseCategories) {
        await db.into(db.expenseCategories).insert(
              ExpenseCategoriesCompanion.insert(
                id: idOf('ec-app-$category'),
                name: category,
                isGeneral: const Value(0),
                isDefault: const Value(1),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
      for (final category in DemoStore.generalExpenseCategories) {
        await db.into(db.expenseCategories).insert(
              ExpenseCategoriesCompanion.insert(
                id: idOf('ec-gen-$category'),
                name: category,
                isGeneral: const Value(1),
                isDefault: const Value(1),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      // --- স্বতন্ত্র আয়ের খাত ---
      for (final category in DemoStore.incomeCategories) {
        await db.into(db.incomeCategories).insert(
              IncomeCategoriesCompanion.insert(
                id: idOf('ic-$category'),
                name: category,
                isDefault: const Value(1),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      // --- দোকানের সেটিংস ---
      for (final entry in {
        'shop_name': DemoStore.shopName,
        'proprietor_name': DemoStore.proprietorName,
        'shop_phone': DemoStore.shopPhone,
        'shop_address': DemoStore.shopAddress,
      }.entries) {
        await db.into(db.shopSettings).insert(
              ShopSettingsCompanion.insert(
                settingKey: entry.key,
                value: entry.value,
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      // --- আবেদন ও তার সাথে যুক্ত লেনদেন ---
      for (final app in DemoStore.applications) {
        final applicationId = idOf(app.id);

        await db.into(db.applications).insert(
              ApplicationsCompanion.insert(
                id: applicationId,
                applicantId: Value(idOf(app.applicantId)),
                applicantName: app.applicantName,
                applicantPhone: app.applicantPhone,
                applicantAddress: Value(app.applicantAddress),
                referenceId: Value(
                  app.referencePersonId == null
                      ? null
                      : idOf(app.referencePersonId!),
                ),
                referenceName: Value(app.referencePersonName),
                officeId: Value(officeIdFor(app.officeName)),
                officeName: app.officeName,
                mouza: Value(app.mouza),
                appNumber: Value(app.appNumber),
                caseNumber: Value(app.caseNumber),
                workType: app.workType,
                applicationDate: app.applicationDate.millisecondsSinceEpoch,
                status: app.status,
                agreedAmount: app.agreedAmount.paisa,
                isMarkedAsPaid: Value(app.isMarkedAsPaid ? 1 : 0),
                notes: Value(app.notes),
                createdAt: now,
                updatedAt: now,
              ),
            );

        // স্ট্যাটাস ইতিহাস আগে বসে যায়, কারণ পেমেন্ট ও খরচ এগুলোর
        // সাথে যুক্ত (status_history_id)।
        for (final history in app.statusHistory) {
          await db.into(db.statusHistory).insert(
                StatusHistoryCompanion.insert(
                  id: idOf(history.id),
                  applicationId: applicationId,
                  // প্রথম এন্ট্রিতে কোনো পূর্বের অবস্থা নেই — খালি
                  // স্ট্রিংয়ের বদলে NULL লেখা হয়।
                  prevStatus: Value(
                    history.prevStatus.trim().isEmpty
                        ? null
                        : history.prevStatus,
                  ),
                  newStatus: history.newStatus,
                  changedAt: history.changedAt.millisecondsSinceEpoch,
                  note: Value(history.note),
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        }

        for (final payment in app.payments) {
          await db.into(db.payments).insert(
                PaymentsCompanion.insert(
                  id: idOf(payment.id),
                  applicationId: applicationId,
                  amount: payment.amount.paisa,
                  date: payment.date.millisecondsSinceEpoch,
                  method: payment.method,
                  note: Value(payment.note),
                  statusHistoryId: Value(
                    payment.statusHistoryId == null
                        ? null
                        : idOf(payment.statusHistoryId!),
                  ),
                  statusName: Value(payment.statusName),
                  isStatusFee: Value(payment.isStatusFee ? 1 : 0),
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        }

        for (final expense in app.expenses) {
          await db.into(db.expenses).insert(
                ExpensesCompanion.insert(
                  id: idOf(expense.id),
                  applicationId: Value(
                    expense.applicationId == null
                        ? null
                        : idOf(expense.applicationId!),
                  ),
                  amount: expense.amount.paisa,
                  category: expense.category,
                  date: expense.date.millisecondsSinceEpoch,
                  isGeneral: Value(expense.isGeneral ? 1 : 0),
                  note: Value(expense.note),
                  statusHistoryId: Value(
                    expense.statusHistoryId == null
                        ? null
                        : idOf(expense.statusHistoryId!),
                  ),
                  statusName: Value(expense.statusName),
                  isStatusExp: Value(expense.isStatusExpense ? 1 : 0),
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        }
      }

      // --- স্বতন্ত্র আয় ---
      for (final income in DemoStore.independentIncomes) {
        await db.into(db.independentIncomes).insert(
              IndependentIncomesCompanion.insert(
                id: idOf(income.id),
                category: income.category,
                amount: income.amount.paisa,
                date: income.date.millisecondsSinceEpoch,
                paymentMethod: income.paymentMethod,
                customerName: Value(income.customerName),
                note: Value(income.note),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      // --- দোকানের সাধারণ খরচ ---
      for (final expense in DemoStore.generalExpenses) {
        await db.into(db.expenses).insert(
              ExpensesCompanion.insert(
                id: idOf(expense.id),
                amount: expense.amount.paisa,
                category: expense.category,
                date: expense.date.millisecondsSinceEpoch,
                isGeneral: const Value(1),
                note: Value(expense.note),
                statusHistoryId: Value(
                  expense.statusHistoryId == null
                      ? null
                      : idOf(expense.statusHistoryId!),
                ),
                statusName: Value(expense.statusName),
                isStatusExp: Value(expense.isStatusExpense ? 1 : 0),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      // --- করণীয় কাজ ---
      for (final task in DemoStore.tasks) {
        await db.into(db.tasks).insert(
              TasksCompanion.insert(
                id: idOf(task.id),
                title: task.title,
                description: Value(task.description),
                dueDate: task.dueDate.millisecondsSinceEpoch,
                dueTime: Value(task.dueTime),
                priority: Value(task.priority),
                status: Value(task.status),
                category: Value(task.category),
                applicationId: Value(
                  task.relatedApplicationId == null
                      ? null
                      : idOf(task.relatedApplicationId!),
                ),
                completedAt: Value(task.completedAt?.millisecondsSinceEpoch),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    });
  }
}