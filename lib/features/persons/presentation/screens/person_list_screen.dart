import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/widgets/app_floating_button.dart';
import '../../../../core/widgets/empty_state.dart';
import 'person_create_edit_screen.dart';
import 'person_detail_screen.dart';

class PersonListScreen extends StatefulWidget {
  const PersonListScreen({super.key});

  @override
  State<PersonListScreen> createState() => _PersonListScreenState();
}

class _PersonListScreenState extends State<PersonListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DemoPerson> get _filteredPersons {
    if (_searchQuery.isEmpty) return DemoStore.persons;
    final q = _searchQuery.toLowerCase();
    return DemoStore.persons.where((p) {
      return p.name.toLowerCase().contains(q) || p.phone.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredPersons;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('গ্রাহক ও ব্যক্তি তালিকা'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: AppColors.primary),
            tooltip: 'নতুন ব্যক্তি',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const PersonCreateEditScreen()),
              ).then((_) => setState(() {}));
            },
          ),
        ],
      ),
      floatingActionButton: AppFloatingButton(
        label: 'নতুন ব্যক্তি',
        icon: Icons.person_add,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const PersonCreateEditScreen()),
          ).then((_) => setState(() {}));
        },
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'ব্যক্তির নাম বা মোবাইল নম্বর দিয়ে খুঁজুন...',
                prefixIcon: const Icon(Icons.search, color: AppColors.slate400),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const Divider(),

          // Person count info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'মোট সংরক্ষিত ব্যক্তি: ${BengaliDigits.toBengali(list.length)} জন',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

          // List
          Expanded(
            child: list.isEmpty
                ? const EmptyState(
                    icon: Icons.person_off_outlined,
                    title: 'কোনো ব্যক্তি পাওয়া যায়নি',
                    message: 'অন্য নামে বা নম্বরে খুঁজে দেখুন।',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, 80),
                    itemCount: list.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (ctx, i) {
                      final p = list[i];
                      final hasDue = p.totalDue.isPositive;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => PersonDetailScreen(person: p),
                              ),
                            ).then((_) => setState(() {}));
                          },
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.base),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.primarySurface,
                                  child: Text(
                                    p.name.substring(0, 1),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: AppTypography.headingSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        BengaliDigits.toBengali(p.phone),
                                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.slate100,
                                              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                                            ),
                                            child: Text(
                                              'আবেদন: ${BengaliDigits.toBengali(p.applicationCount)} টি',
                                              style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                            ),
                                          ),
                                          if (hasDue) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.roseSurface,
                                                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                                              ),
                                              child: Text(
                                                'বকেয়া: ${p.totalDue.formatBengali()}',
                                                style: AppTypography.bodySmall.copyWith(
                                                  color: AppColors.rose,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.phone_in_talk, color: AppColors.emerald, size: 20),
                                  tooltip: 'কল করুন',
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${p.phone} নম্বরে কল করা হচ্ছে...')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

