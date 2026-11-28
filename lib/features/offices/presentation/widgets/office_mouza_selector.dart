import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/widgets/app_dialog_action_row.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../providers/office_providers.dart';

/// ভূমি অফিস ও তার অধীনস্থ মৌজা নির্বাচনের সমন্বিত উইজেট।
///
/// ব্যবহারকারী যখন কোনো ভূমি অফিস নির্বাচন করেন, তখন সংশ্লিষ্ট অফিসের
/// অধীনস্থ সকল প্রমিত ও কাস্টম মৌজা ড্রপডাউনে লোড হয় এবং অফিস ও মৌজা
/// উভয় ড্রপডাউনের ভেতরেই সার্চ করে সহজেই নির্বাচন করা যায়।
class OfficeMouzaSelector extends ConsumerStatefulWidget {
  final String? selectedOffice;
  final ValueChanged<String>? onOfficeChanged;
  final TextEditingController mouzaController;
  final bool isRequiredOffice;
  final bool isRequiredMouza;

  const OfficeMouzaSelector({
    super.key,
    required this.selectedOffice,
    required this.onOfficeChanged,
    required this.mouzaController,
    this.isRequiredOffice = true,
    this.isRequiredMouza = false,
  });

  @override
  ConsumerState<OfficeMouzaSelector> createState() => _OfficeMouzaSelectorState();
}

class _OfficeMouzaSelectorState extends ConsumerState<OfficeMouzaSelector> {
  void _showAddOfficeDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('নতুন ভূমি অফিস যোগ করুন'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            label: AppFieldLabel.inline(label: 'অফিসের নাম', isRequired: true),
            hintText: 'যেমন: ইউনিয়ন ভূমি অফিস, বালিয়াডাঙ্গা',
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        actions: [
          AppDialogActionRow(
            confirmText: 'যোগ করুন',
            onConfirm: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              final text = controller.text.trim();
              if (text.isEmpty) return;
              try {
                final created = await ref
                    .read(officeControllerProvider.notifier)
                    .createOffice(name: text);
                if (created != null && widget.onOfficeChanged != null) {
                  widget.onOfficeChanged!(created.name);
                }
              } catch (_) {}
              if (!ctx.mounted) return;
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showAddMouzaDialog(String officeName) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('নতুন মৌজা যোগ করুন ($officeName)'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            label: AppFieldLabel.inline(label: 'মৌজার নাম', isRequired: true),
            hintText: 'যেমন: বাগবাড়ী (জে.এল নং ৪৫)',
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        actions: [
          AppDialogActionRow(
            confirmText: 'যুক্ত করুন',
            onConfirm: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              final text = controller.text.trim();
              if (text.isEmpty) return;
              try {
                await ref
                    .read(officeControllerProvider.notifier)
                    .addCustomMouza(
                      officeName: officeName,
                      mouzaName: text,
                    );
                widget.mouzaController.text = text;
                setState(() {});
              } catch (_) {}
              if (!ctx.mounted) return;
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openOfficeSearchSheet(
    List<String> officeList,
  ) async {
    FocusManager.instance.primaryFocus?.unfocus();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.width,
        maxWidth: MediaQuery.of(context).size.width,
      ),
      builder: (sheetCtx) {
        String query = '';
        final searchController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = query.trim().isEmpty
                ? officeList
                : officeList
                    .where((o) =>
                        o.toLowerCase().contains(query.trim().toLowerCase()))
                    .toList();

            return Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.78,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.slate300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ভূমি অফিস নির্বাচন করুন',
                          style: AppTypography.headingSmall
                              .copyWith(fontSize: 16),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            FocusScope.of(sheetCtx).unfocus();
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.pop(sheetCtx);
                            _showAddOfficeDialog();
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('নতুন অফিস'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchController,
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: 'অফিসের নাম দিয়ে সার্চ করুন...',
                        prefixIcon: const Icon(Icons.search,
                            size: 20, color: AppColors.primary),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  searchController.clear();
                                  setSheetState(() => query = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: AppColors.slate50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                      ),
                      onChanged: (val) => setSheetState(() => query = val),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'মোট ${BengaliDigits.toBengali(filtered.length.toString())}টি ভূমি অফিস',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.slate500),
                      ),
                    ),
                  ),
                  const Divider(height: 16),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.search_off,
                                      size: 40, color: AppColors.slate400),
                                  const SizedBox(height: 8),
                                  Text(
                                    '"$query" নামে কোনো অফিস পাওয়া যায়নি',
                                    style: AppTypography.bodyMedium
                                        .copyWith(color: AppColors.slate500),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (query.trim().isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        FocusScope.of(sheetCtx).unfocus();
                                        FocusManager.instance.primaryFocus?.unfocus();
                                        final newName = query.trim();
                                        final created = await ref
                                            .read(officeControllerProvider
                                                .notifier)
                                            .createOffice(name: newName);
                                        if (created != null &&
                                            widget.onOfficeChanged != null) {
                                          widget.onOfficeChanged!(created.name);
                                        }
                                        if (mounted) setState(() {});
                                        if (sheetCtx.mounted) {
                                          Navigator.pop(sheetCtx);
                                        }
                                      },
                                      icon: const Icon(Icons.add, size: 16),
                                      label: Text(
                                          '"$query" নতুন অফিস হিসেবে যুক্ত করুন'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(
                                height: 1, color: AppColors.slate100),
                            itemBuilder: (_, index) {
                              final off = filtered[index];
                              final isSelected = widget.selectedOffice == off;

                              return ListTile(
                                onTap: () {
                                  FocusScope.of(sheetCtx).unfocus();
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  widget.onOfficeChanged?.call(off);
                                  if (mounted) setState(() {});
                                  Navigator.pop(sheetCtx);
                                },
                                leading: Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.account_balance_outlined,
                                  size: 20,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.slate400,
                                ),
                                title: Text(
                                  off,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check,
                                        color: AppColors.primary, size: 18)
                                    : null,
                                tileColor: isSelected
                                    ? AppColors.primarySurface
                                    : null,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                dense: true,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (mounted) {
      FocusScope.of(context).unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        }
      });
    }
  }

  Future<void> _openMouzaSearchSheet(
    String? officeName,
    List<String> mouzas,
  ) async {
    FocusManager.instance.primaryFocus?.unfocus();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.width,
        maxWidth: MediaQuery.of(context).size.width,
      ),
      builder: (sheetCtx) {
        String query = '';
        final searchController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = query.trim().isEmpty
                ? mouzas
                : mouzas
                    .where((m) =>
                        m.toLowerCase().contains(query.trim().toLowerCase()))
                    .toList();

            return Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.78,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.slate300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'মৌজা নির্বাচন করুন',
                                style: AppTypography.headingSmall
                                    .copyWith(fontSize: 16),
                              ),
                              if (officeName != null)
                                Text(
                                  officeName,
                                  style: AppTypography.bodySmall
                                      .copyWith(color: AppColors.slate500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            if (officeName == null ||
                                officeName.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'নতুন মৌজা যুক্ত করার পূর্বে অনুগ্রহ করে প্রথমে অফিস নির্বাচন করুন।'),
                                  backgroundColor: AppColors.rose,
                                ),
                              );
                              return;
                            }
                            FocusScope.of(sheetCtx).unfocus();
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.pop(sheetCtx);
                            _showAddMouzaDialog(officeName);
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('নতুন মৌজা'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchController,
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: 'মৌজার নাম দিয়ে সার্চ করুন...',
                        prefixIcon: const Icon(Icons.search,
                            size: 20, color: AppColors.primary),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  searchController.clear();
                                  setSheetState(() => query = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: AppColors.slate50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                      ),
                      onChanged: (val) => setSheetState(() => query = val),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'মোট ${BengaliDigits.toBengali(filtered.length.toString())}টি মৌজা',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.slate500),
                        ),
                        if (widget.mouzaController.text.isNotEmpty)
                          InkWell(
                            onTap: () {
                              FocusScope.of(sheetCtx).unfocus();
                              FocusManager.instance.primaryFocus?.unfocus();
                              widget.mouzaController.clear();
                              if (mounted) setState(() {});
                              Navigator.pop(sheetCtx);
                            },
                            child: Text(
                              'সিলেকশন মুছুন',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.rose,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 16),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.search_off,
                                      size: 40, color: AppColors.slate400),
                                  const SizedBox(height: 8),
                                  Text(
                                    '"$query" নামে কোনো মৌজা পাওয়া যায়নি',
                                    style: AppTypography.bodyMedium
                                        .copyWith(color: AppColors.slate500),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (officeName != null &&
                                      query.trim().isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        FocusScope.of(sheetCtx).unfocus();
                                        FocusManager.instance.primaryFocus?.unfocus();
                                        final newName = query.trim();
                                        await ref
                                            .read(officeControllerProvider
                                                .notifier)
                                            .addCustomMouza(
                                              officeName: officeName,
                                              mouzaName: newName,
                                            );
                                        widget.mouzaController.text = newName;
                                        if (mounted) setState(() {});
                                        if (sheetCtx.mounted) {
                                          Navigator.pop(sheetCtx);
                                        }
                                      },
                                      icon: const Icon(Icons.add, size: 16),
                                      label: Text(
                                          '"$query" যুক্ত করে নির্বাচন করুন'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(
                                height: 1, color: AppColors.slate100),
                            itemBuilder: (_, index) {
                              final m = filtered[index];
                              final isSelected =
                                  widget.mouzaController.text.trim() == m;

                              return ListTile(
                                onTap: () {
                                  FocusScope.of(sheetCtx).unfocus();
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  widget.mouzaController.text = m;
                                  if (mounted) setState(() {});
                                  Navigator.pop(sheetCtx);
                                },
                                leading: Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.map_outlined,
                                  size: 20,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.slate400,
                                ),
                                title: Text(
                                  m,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check,
                                        color: AppColors.primary, size: 18)
                                    : null,
                                tileColor: isSelected
                                    ? AppColors.primarySurface
                                    : null,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                dense: true,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (mounted) {
      FocusScope.of(context).unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveOffices = ref
        .watch(officesStreamProvider)
        .valueOrNull
        ?.map((o) => o.name)
        .toList();

    final officeList = (liveOffices != null && liveOffices.isNotEmpty)
        ? liveOffices
        : DemoStore.offices.map((o) => o.name).toList();

    final currentOffice = widget.selectedOffice != null &&
            widget.selectedOffice!.isNotEmpty &&
            officeList.contains(widget.selectedOffice)
        ? widget.selectedOffice
        : (officeList.isNotEmpty ? officeList.first : null);

    final mouzas = currentOffice != null
        ? ref.watch(mouzasForOfficeProvider(currentOffice))
        : <String>[];

    final currentMouza = widget.mouzaController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ১. অফিসের নাম হেডার ও নির্বাচন ড্রপডাউন (সার্চ সহ)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppFieldLabel(
              label: 'অফিসের নাম',
              isRequired: widget.isRequiredOffice,
            ),
            InkWell(
              onTap: _showAddOfficeDialog,
              child: Text(
                '+ নতুন অফিস',
                style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        FormField<String>(
          key: ValueKey('office_field_$currentOffice'),
          validator: (_) {
            if (widget.isRequiredOffice &&
                (widget.selectedOffice == null ||
                    widget.selectedOffice!.trim().isEmpty)) {
              return 'ভূমি অফিস নির্বাচন আবশ্যক';
            }
            return null;
          },
          builder: (formState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _openOfficeSearchSheet(officeList),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: formState.hasError
                            ? AppColors.rose
                            : AppColors.border,
                        width: formState.hasError ? 1.2 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance_outlined,
                          size: 18,
                          color: AppColors.slate400,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            currentOffice != null && currentOffice.isNotEmpty
                                ? currentOffice
                                : 'ভূমি অফিস নির্বাচন করুন...',
                            style: AppTypography.bodyMedium.copyWith(
                              color: currentOffice != null &&
                                      currentOffice.isNotEmpty
                                  ? AppColors.textPrimary
                                  : AppColors.slate400,
                              fontWeight: currentOffice != null &&
                                      currentOffice.isNotEmpty
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                if (formState.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 12),
                    child: Text(
                      formState.errorText ?? '',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.rose,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),

        const SizedBox(height: AppSpacing.md),

        // ২. মৌজার নাম হেডার ও নির্বাচন ড্রপডাউন (সার্চ সহ)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppFieldLabel(
              label: 'মৌজার নাম',
              isRequired: widget.isRequiredMouza,
            ),
            InkWell(
              onTap: () {
                if (currentOffice == null || currentOffice.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'নতুন মৌজা যুক্ত করার পূর্বে অনুগ্রহ করে প্রথমে একটি অফিস নির্বাচন করুন।'),
                      backgroundColor: AppColors.rose,
                    ),
                  );
                  return;
                }
                _showAddMouzaDialog(currentOffice);
              },
              child: Text(
                '+ নতুন মৌজা',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs + 2),

        // মৌজা নির্বাচন ড্রপডাউন (ট্যাপ করলে ভেতরে সার্চ ও তালিকা খোলে)
        FormField<String>(
          key: ValueKey('mouza_field_${currentOffice}_$currentMouza'),
          validator: (_) {
            if (widget.isRequiredMouza &&
                widget.mouzaController.text.trim().isEmpty) {
              return 'মৌজা নির্বাচন আবশ্যক';
            }
            return null;
          },
          builder: (formState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _openMouzaSearchSheet(
                    currentOffice,
                    mouzas,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: formState.hasError
                            ? AppColors.rose
                            : AppColors.border,
                        width: formState.hasError ? 1.2 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.map_outlined,
                          size: 18,
                          color: AppColors.slate400,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            currentMouza.isNotEmpty
                                ? currentMouza
                                : 'মৌজা নির্বাচন করুন...',
                            style: AppTypography.bodyMedium.copyWith(
                              color: currentMouza.isNotEmpty
                                  ? AppColors.textPrimary
                                  : AppColors.slate400,
                              fontWeight: currentMouza.isNotEmpty
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (currentMouza.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              widget.mouzaController.clear();
                              setState(() {});
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.close,
                                  size: 18, color: AppColors.slate400),
                            ),
                          ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                if (formState.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 12),
                    child: Text(
                      formState.errorText ?? '',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.rose,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
