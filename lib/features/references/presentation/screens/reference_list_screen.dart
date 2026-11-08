import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/demo_reference_store.dart';
import '../widgets/reference_card.dart';

class ReferenceListScreen extends StatefulWidget {
  const ReferenceListScreen({super.key});

  @override
  State<ReferenceListScreen> createState() => _ReferenceListScreenState();
}

class _ReferenceListScreenState extends State<ReferenceListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DemoReference> get _filteredReferences {
    final query = _searchQuery.trim().toLowerCase();
    final list = DemoStore.references.where((ref) {
      if (query.isEmpty) return true;
      final matchName = ref.name.toLowerCase().contains(query);
      final matchPhone = ref.phone.contains(query);
      final matchAddress = ref.address?.toLowerCase().contains(query) ?? false;
      return matchName || matchPhone || matchAddress;
    }).toList();

    // Sort by total applications descending
    list.sort((a, b) {
      final aCount = ReferenceHelper.getApplicationsForReference(a.id, a.name).length;
      final bCount = ReferenceHelper.getApplicationsForReference(b.id, b.name).length;
      return bCount.compareTo(aCount);
    });

    return list;
  }

  int get _totalReferredApplications {
    int total = 0;
    for (final ref in DemoStore.references) {
      total += ReferenceHelper.getApplicationsForReference(ref.id, ref.name).length;
    }
    return total;
  }

  void _showAddReferenceSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.base,
          right: AppSpacing.base,
          top: AppSpacing.base,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.base,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.slate300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'নতুন রেফারেন্স ব্যক্তি যোগ করুন',
                style: AppTypography.headingSmall.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'রেফারেন্স ব্যক্তির তথ্য সংরক্ষণ করুন (আবেদনকারী থেকে পৃথক):',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.base),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  label: AppFieldLabel.inline(label: 'রেফারেন্স ব্যক্তির নাম', isRequired: true),
                  hintText: 'যেমন: করিম মিয়া',
                  prefixIcon: Icon(Icons.person_outline, size: 18),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  label: AppFieldLabel.inline(label: 'মোবাইল নম্বর', isRequired: true),
                  hintText: '০১৭১১২২৩৩৪8',
                  prefixIcon: Icon(Icons.phone_android, size: 18),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'ঠিকানা',
                  hintText: 'গ্রাম/এলাকা, থানা, জেলা',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'নোট বা মন্তব্য',
                  hintText: 'পরিচিতি বা কাজের বিবরণ',
                  prefixIcon: Icon(Icons.notes, size: 18),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('বাতিল'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        final name = nameController.text.trim();
                        final phone = phoneController.text.trim();
                        if (name.isEmpty || phone.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('নাম এবং মোবাইল নম্বর আবশ্যক'),
                              backgroundColor: AppColors.rose,
                            ),
                          );
                          return;
                        }

                        final newRef = DemoReference(
                          id: 'ref-${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          phone: phone,
                          address: addressController.text.trim().isNotEmpty
                              ? addressController.text.trim()
                              : null,
                          notes: notesController.text.trim().isNotEmpty
                              ? notesController.text.trim()
                              : null,
                        );

                        setState(() {
                          DemoStore.references.insert(0, newRef);
                        });

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('রেফারেন্স "$name" সফলভাবে সংরক্ষিত হয়েছে'),
                            backgroundColor: AppColors.emerald,
                          ),
                        );
                      },
                      child: const Text('সংরক্ষণ করুন'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredReferences;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('রেফারেন্স খাতা'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReferenceSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('নতুন রেফারেন্স'),
      ),
      body: Column(
        children: [
          // Summary Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryBox(
                        title: 'মোট রেফারেন্স ব্যক্তি',
                        value: '${BengaliDigits.toBengali(DemoStore.references.length.toString())} জন',
                        icon: Icons.groups_outlined,
                        color: AppColors.primary,
                        bgColor: AppColors.primarySurface,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildSummaryBox(
                        title: 'মোট আনীত আবেদন',
                        value: '${BengaliDigits.toBengali(_totalReferredApplications.toString())} টি',
                        icon: Icons.folder_shared_outlined,
                        color: AppColors.emerald,
                        bgColor: const Color(0xFFECFDF5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'রেফারেন্স ব্যক্তির নাম, মোবাইল বা ঠিকানা খুঁজুন...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.slate400),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    filled: true,
                    fillColor: AppColors.slate50,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Reference List
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(
                    icon: Icons.search_off,
                    title: _searchQuery.isNotEmpty ? 'কোনো রেফারেন্স পাওয়া যায়নি' : 'রেফারেন্স খাতা খালি',
                    message: _searchQuery.isNotEmpty
                        ? '"$_searchQuery" এর সাথে কোনো রেফারেন্স ব্যক্তির মিল নেই।'
                        : 'এখনও কোনো রেফারেন্স ব্যক্তি যোগ করা হয়নি। নিচে বোতাম চেপে যোগ করুন।',
                    actionText: _searchQuery.isNotEmpty ? null : 'নতুন রেফারেন্স যোগ করুন',
                    onAction: _searchQuery.isNotEmpty ? null : _showAddReferenceSheet,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, idx) {
                      final ref = filtered[idx];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ReferenceCard(
                          reference: ref,
                          onRefresh: () => setState(() {}),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

