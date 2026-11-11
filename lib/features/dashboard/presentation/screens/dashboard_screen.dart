import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../applications/data/services/land_portal_helper.dart';
import '../../../applications/presentation/providers/application_providers.dart';
import '../../../applications/presentation/screens/application_create_screen.dart';
import '../../../applications/presentation/screens/application_list_screen.dart';
import '../../../applications/presentation/screens/land_portal_webview_screen.dart';
import '../../../applications/presentation/widgets/application_card.dart';
import '../../../backup/presentation/screens/backup_restore_screen.dart';
import '../../../offices/presentation/screens/office_management_screen.dart';
import '../../../persons/presentation/screens/person_list_screen.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../../tasks/presentation/screens/task_create_edit_screen.dart';
import '../../../tasks/presentation/screens/task_list_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isNavigatingToTasks = false;

  void _openTasks() async {
    if (_isNavigatingToTasks) return;
    _isNavigatingToTasks = true;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => const TaskListScreen()),
    );
    _isNavigatingToTasks = false;
  }

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(applicationsWithFinancialsStreamProvider);
    final todayTasksAsync = ref.watch(todayTasksCountProvider);
    final todayTasksCount = todayTasksAsync.valueOrNull ?? 0;

    final apps = appsAsync.valueOrNull ?? const [];
    final totalCount = apps.length;

    final ongoingCount = apps
        .where((a) =>
            a.application.status != 'সম্পন্ন' &&
            a.application.status != 'নামঞ্জুর' &&
            a.application.status != 'বাতিল')
        .length;
    final hearingCount =
        apps.where((a) => a.application.status == 'শুনানি').length;
    final passedCount = apps
        .where((a) =>
            a.application.status == 'মঞ্জুর' ||
            a.application.status == 'ডিসিআর প্রস্তুত' ||
            a.application.status == 'পাশ' ||
            a.application.status == 'PER')
        .length;
    final completedCount =
        apps.where((a) => a.application.status == 'সম্পন্ন').length;

    final recentApplications =
        apps.take(4).map((a) => a.toDemoApplication()).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(15, 23, 42, 0.05),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Image.asset(
                  'assets/images/app_logo.jpeg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'রজব ভূমি সেবা ঘর',
                  style: AppTypography.headingSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                Text(
                  BengaliDigits.toBengali(
                    'আজ: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  ),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.language_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            tooltip: 'ভূমি পোর্টাল (LSG)',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const LandPortalWebViewScreen(
                    initialUrl: LandPortalHelper.lsgLoginUrl,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.cloud_done_outlined,
                color: AppColors.emerald, size: 22),
            tooltip: 'ব্যাকআপ স্ট্যাটাস',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (ctx) => const BackupRestoreScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: IconButton(
              tooltip:
                  'আজকের কাজ (${BengaliDigits.toBengali(todayTasksCount)})',
              onPressed: _openTasks,
              icon: Badge(
                isLabelVisible: todayTasksCount > 0,
                label: Text(
                  BengaliDigits.toBengali(todayTasksCount),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: AppColors.rose,
                child: const Icon(Icons.notifications_none_outlined, size: 24),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(applicationsWithFinancialsStreamProvider);
          ref.invalidate(todayTasksCountProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.xl),
          children: [
            // Instant Search Box - Jump to file directly
            _buildInstantSearchBar(),

            const SizedBox(height: AppSpacing.base),

            // Operational Quick Actions Bar
            _buildQuickActions(),

            const SizedBox(height: AppSpacing.base),

            // Application Pipeline Status (Counts ONLY - Zero Money)
            _buildApplicationStatusGrid(
              totalCount: totalCount,
              ongoingCount: ongoingCount,
              hearingCount: hearingCount,
              passedCount: passedCount,
              completedCount: completedCount,
            ),

            const SizedBox(height: AppSpacing.base),

            // Recent Applications Section (Zero Money displayed)
            _buildRecentApplicationsSection(
              recentApplications: recentApplications,
              totalCount: totalCount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstantSearchBar() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onNavigateTab?.call(1);
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(15, 23, 42, 0.03),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 20, color: AppColors.slate400),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'গ্রাহক নাম, মোবাইল বা কেস নম্বর দিয়ে ফাইল খুঁজুন...',
                  style:
                      AppTypography.bodyMedium.copyWith(color: AppColors.slate400),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: Text(
                  'খুঁজুন',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.primary, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickActionBtn(
            icon: Icons.post_add,
            label: 'নতুন আবেদন',
            color: AppColors.primary,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (ctx) => const ApplicationCreateScreen()),
              );
            },
          ),
          _buildQuickActionBtn(
            icon: Icons.add_task,
            label: 'নতুন কাজ',
            color: const Color(0xFF8B5CF6),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (ctx) => const TaskCreateEditScreen()),
              );
            },
          ),
          _buildQuickActionBtn(
            icon: Icons.people_outline,
            label: 'গ্রাহক খাতা',
            color: AppColors.emerald,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const PersonListScreen()),
              );
            },
          ),
          _buildQuickActionBtn(
            icon: Icons.account_balance_outlined,
            label: 'অফিস সমূহ',
            color: AppColors.slate600,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (ctx) => const OfficeManagementScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationStatusGrid({
    required int totalCount,
    required int ongoingCount,
    required int hearingCount,
    required int passedCount,
    required int completedCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ফাইলের বর্তমান অবস্থা',
                style: AppTypography.headingSmall
                    .copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
              ),
              Text(
                'মোট ${BengaliDigits.toBengali(totalCount)} টি ফাইল',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _buildPipelineStatusItem(
                label: 'চলমান',
                count: ongoingCount,
                color: AppColors.primary,
                status: null,
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildPipelineStatusItem(
                label: 'শুনানি',
                count: hearingCount,
                color: const Color(0xFF8B5CF6),
                status: 'শুনানি',
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildPipelineStatusItem(
                label: 'অনুমোদিত',
                count: passedCount,
                color: AppColors.emerald,
                status: 'মঞ্জুর',
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildPipelineStatusItem(
                label: 'সম্পন্ন',
                count: completedCount,
                color: const Color(0xFF16A34A),
                status: 'সম্পন্ন',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStatusItem({
    required String label,
    required int count,
    required Color color,
    required String? status,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) =>
                  ApplicationListScreen(initialStatusFilter: status),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text(
                BengaliDigits.toBengali(count),
                style: AppTypography.headingMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentApplicationsSection({
    required List<DemoApplication> recentApplications,
    required int totalCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'সাম্প্রতিক ফাইলের অগ্রগতি',
              style: AppTypography.headingSmall
                  .copyWith(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            InkWell(
              onTap: () => widget.onNavigateTab?.call(1),
              child: Text(
                'সকল আবেদন (${BengaliDigits.toBengali(totalCount)})',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Render with showFinancials: false -> Zero Money on Home!
        ...recentApplications.map((app) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.base),
              child: ApplicationCard(
                application: app,
                showFinancials: false,
                onRefresh: () {
                  ref.invalidate(applicationsWithFinancialsStreamProvider);
                },
              ),
            )),
      ],
    );
  }
}
