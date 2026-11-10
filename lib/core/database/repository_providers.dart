import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/applications/data/repositories/application_repository.dart';
import '../../features/applications/data/repositories/proposal_print_repository.dart';
import '../../features/backup/data/repositories/backup_repository.dart';
import '../../features/finance/data/repositories/finance_repository.dart';
import '../../features/offices/data/repositories/office_repository.dart';
import '../../features/persons/data/repositories/person_repository.dart';
import '../../features/references/data/repositories/reference_repository.dart';
import '../../features/settings/data/repositories/category_repository.dart';
import '../../features/settings/data/repositories/shop_settings_repository.dart';
import '../../features/tasks/data/repositories/task_repository.dart';
import 'database_provider.dart';

export '../../features/applications/data/repositories/application_repository.dart';
export '../../features/applications/data/repositories/proposal_print_repository.dart';
export '../../features/backup/data/repositories/backup_repository.dart';
export '../../features/finance/data/repositories/finance_repository.dart';
export '../../features/offices/data/repositories/office_repository.dart';
export '../../features/persons/data/repositories/person_repository.dart';
export '../../features/references/data/repositories/reference_repository.dart';
export '../../features/settings/data/repositories/category_repository.dart';
export '../../features/settings/data/repositories/shop_settings_repository.dart';
export '../../features/tasks/data/repositories/task_repository.dart';

/// আবেদন রিপোজিটরি প্রোভাইডার
final applicationRepositoryProvider = Provider<ApplicationRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ApplicationRepository(db);
});

/// প্রস্তাব প্রেরণ PDF প্রিন্ট ব্যাচ রিপোজিটরি প্রোভাইডার
final proposalPrintRepositoryProvider = Provider<ProposalPrintRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ProposalPrintRepository(db);
});

/// অর্থ ও ক্যাশবই রিপোজিটরি প্রোভাইডার
final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return FinanceRepository(db);
});

/// গ্রাহক রিপোজিটরি প্রোভাইডার
final personRepositoryProvider = Provider<PersonRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PersonRepository(db);
});

/// রেফারেন্স ব্যক্তি রিপোজিটরি প্রোভাইডার
final referenceRepositoryProvider = Provider<ReferenceRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ReferenceRepository(db);
});

/// কাজ ও শুনানি রিপোজিটরি প্রোভাইডার
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TaskRepository(db);
});

/// ভূমি অফিস রিপোজিটরি প্রোভাইডার
final officeRepositoryProvider = Provider<OfficeRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return OfficeRepository(db);
});

/// খাত ও ক্যাটাগরি রিপোজিটরি প্রোভাইডার
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CategoryRepository(db);
});

/// দোকান সেটিংস রিপোজিটরি প্রোভাইডার
final shopSettingsRepositoryProvider = Provider<ShopSettingsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ShopSettingsRepository(db);
});

/// ব্যাকআপ ও রিস্টোর রিপোজিটরি প্রোভাইডার
final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return BackupRepository(db);
});

