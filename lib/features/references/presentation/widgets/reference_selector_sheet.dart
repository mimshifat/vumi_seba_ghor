import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../providers/reference_providers.dart';

class ReferenceSelectorSheet extends ConsumerStatefulWidget {
  final DemoReference? initialReference;
  final ValueChanged<DemoReference?> onSelected;

  const ReferenceSelectorSheet({
    super.key,
    this.initialReference,
    required this.onSelected,
  });

  static Future<DemoReference?> show(
    BuildContext context, {
    DemoReference? initialReference,
  }) {
    return showModalBottomSheet<DemoReference>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ReferenceSelectorSheet(
        initialReference: initialReference,
        onSelected: (ref) => Navigator.of(ctx).pop(ref),
      ),
    );
  }

  @override
  ConsumerState<ReferenceSelectorSheet> createState() =>
      _ReferenceSelectorSheetState();
}

class _ReferenceSelectorSheetState
    extends ConsumerState<ReferenceSelectorSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isCreatingNew = false;

  final _newNameController = TextEditingController();
  final _newPhoneController = TextEditingController();
  final _newAddressController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _newNameController.dispose();
    _newPhoneController.dispose();
    _newAddressController.dispose();
    super.dispose();
  }

  Future<void> _saveAndSelectNewReference() async {
    final name = _newNameController.text.trim();
    final phone = _newPhoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('নাম এবং মোবাইল নম্বর আবশ্যক'),
          backgroundColor: AppColors.rose,
        ),
      );
      return;
    }

    try {
      final created = await ref
          .read(referenceControllerProvider.notifier)
          .createReference(
            name: name,
            phone: phone,
            address: _newAddressController.text.trim().isNotEmpty
                ? _newAddressController.text.trim()
                : null,
          );

      if (created != null) {
        final demo = DemoReference(
          id: created.id,
          name: created.name,
          phone: created.phone,
          address: created.address,
        );
        widget.onSelected(demo);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.rose,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final referencesAsync = ref.watch(referencesStreamProvider);
    final allReferences = referencesAsync.valueOrNull ?? const [];

    final query = _searchQuery.trim().toLowerCase();
    final filtered = allReferences.where((r) {
      if (query.isEmpty) return true;
      return r.name.toLowerCase().contains(query) ||
          r.phone.contains(query) ||
          (r.address?.toLowerCase().contains(query) ?? false);
    }).map((r) => DemoReference(
          id: r.id,
          name: r.name,
          phone: r.phone,
          address: r.address,
          notes: r.notes,
        )).toList();

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.base,
        right: AppSpacing.base,
        top: AppSpacing.base,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.base,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isCreatingNew
                    ? 'নতুন রেফারেন্স যোগ করুন'
                    : 'রেফারেন্স ব্যক্তি নির্বাচন',
                style: AppTypography.headingSmall
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              TextButton.icon(
                icon: Icon(
                  _isCreatingNew ? Icons.list_alt : Icons.add_circle_outline,
                  size: 17,
                  color: AppColors.primary,
                ),
                label: Text(
                  _isCreatingNew ? 'তালিকা দেখুন' : '+ নতুন রেফারেন্স',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.primary),
                ),
                onPressed: () {
                  setState(() => _isCreatingNew = !_isCreatingNew);
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          if (_isCreatingNew)
            _buildCreateInlineForm()
          else ...[
            // Search Input
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'নাম, মোবাইল বা ঠিকানা দিয়ে খুঁজুন...',
                prefixIcon: const Icon(Icons.search,
                    size: 20, color: AppColors.slate400),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: AppColors.slate50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Option to clear selection
            if (widget.initialReference != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: InkWell(
                  onTap: () => widget.onSelected(null),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: const Color(0xFFFECDD3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.close, size: 16, color: AppColors.rose),
                        const SizedBox(width: 8),
                        Text(
                          'কোনো রেফারেন্স ব্যক্তি নেই (মুছে ফেলুন)',
                          style: AppTypography.labelMedium
                              .copyWith(color: AppColors.rose),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // List of References
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_off_outlined,
                                size: 36, color: AppColors.slate300),
                            const SizedBox(height: 8),
                            const Text(
                              'কোনো রেফারেন্স পাওয়া যায়নি',
                              style: AppTypography.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('এই নামে নতুন তৈরি করুন'),
                              onPressed: () {
                                _newNameController.text = _searchQuery;
                                setState(() => _isCreatingNew = true);
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: AppColors.slate100),
                      itemBuilder: (ctx, idx) {
                        final item = filtered[idx];
                        final isSelected =
                            widget.initialReference?.id == item.id;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          leading: _buildAvatar(item),
                          title: Text(
                            item.name,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '${BengaliDigits.toBengali(item.phone)}${item.address != null ? ' • ${item.address}' : ''}',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: AppColors.primary, size: 20)
                              : null,
                          onTap: () => widget.onSelected(item),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(DemoReference r) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primarySurface,
      child: Text(
        r.name.isNotEmpty ? r.name.characters.first : '?',
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildCreateInlineForm() {
    return Column(
      children: [
        TextField(
          controller: _newNameController,
          autofocus: true,
          decoration: const InputDecoration(
            label: AppFieldLabel.inline(
                label: 'রেফারেন্স ব্যক্তির নাম', isRequired: true),
            hintText: 'যেমন: কামাল হোসেন মেম্বার',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _newPhoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            label: AppFieldLabel.inline(
                label: 'মোবাইল নম্বর', isRequired: true),
            hintText: '০১৮১২৩৪৫৬৭৮',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _newAddressController,
          decoration: const InputDecoration(
            labelText: 'ঠিকানা / এলাকা (ঐচ্ছিক)',
            hintText: 'যেমন: ভাটপাড়া, সাভার',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          onPressed: _saveAndSelectNewReference,
          child: const Text('সংরক্ষণ ও নির্বাচন করুন'),
        ),
      ],
    );
  }
}
