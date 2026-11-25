import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/repository_providers.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/utils/case_number_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/attachment_picker_sheet.dart';
import '../../../../core/widgets/full_screen_image_viewer.dart';
import '../../../applications/presentation/providers/application_providers.dart';
import '../providers/task_providers.dart';

class TaskCreateEditScreen extends ConsumerStatefulWidget {
  final DemoTask? task;

  const TaskCreateEditScreen({super.key, this.task});

  @override
  ConsumerState<TaskCreateEditScreen> createState() =>
      _TaskCreateEditScreenState();
}

class _TaskCreateEditScreenState extends ConsumerState<TaskCreateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _timeController;

  late DateTime _dueDate;
  late String _priority;
  late String _status;
  String? _selectedAppId;

  final List<PickedAttachment> _newImages = [];
  List<TaskAttachment> _existingImages = [];
  final List<String> _removedExistingImageIds = [];
  bool _isLoadingImages = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _timeController = TextEditingController(text: t?.dueTime ?? '');
    _dueDate = t?.dueDate ?? DateTime.now();
    _priority = t?.priority ?? 'সাধারণ';
    _status = t?.status ?? 'করতে হবে';
    _selectedAppId = t?.relatedApplicationId;

    if (_isEditing) {
      _loadExistingImages();
    }
  }

  Future<void> _loadExistingImages() async {
    setState(() => _isLoadingImages = true);
    try {
      final images = await ref
          .read(taskRepositoryProvider)
          .getTaskAttachments(widget.task!.id);
      if (mounted) {
        setState(() {
          _existingImages = images;
          _isLoadingImages = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingImages = false);
    }
  }

  Future<void> _pickImages() async {
    final picked = await AttachmentPickerSheet.pickMultiple(
      context,
      includeFileManager: false,
      title: 'কাজের ছবি যুক্ত করুন',
      subtitle: 'ক্যামেরা অথবা গ্যালারি থেকে ছবি নির্বাচন করুন',
    );
    if (picked.isNotEmpty && mounted) {
      setState(() {
        _newImages.addAll(picked);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (_isEditing) {
        final taskId = widget.task!.id;
        await ref.read(taskControllerProvider.notifier).updateTask(
              id: taskId,
              title: _titleController.text.trim(),
              description: _descController.text.trim().isNotEmpty
                  ? _descController.text.trim()
                  : null,
              dueDate: _dueDate,
              dueTime: _timeController.text.trim().isNotEmpty
                  ? _timeController.text.trim()
                  : null,
              priority: _priority,
              status: _status,
              category: 'সাধারণ',
              applicationId: _selectedAppId,
            );

        // Delete removed existing attachments
        for (final id in _removedExistingImageIds) {
          await ref.read(taskControllerProvider.notifier).deleteTaskAttachment(
                id: id,
                taskId: taskId,
              );
        }

        // Add new image attachments
        for (final img in _newImages) {
          await ref.read(taskControllerProvider.notifier).addTaskAttachment(
                taskId: taskId,
                fileName: img.fileName,
                fileData: img.bytes,
                fileSize: img.fileSize,
              );
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('কাজের তথ্য হালনাগাদ করা হয়েছে।'),
              backgroundColor: AppColors.emerald),
        );
        Navigator.pop(context);
      } else {
        final created = await ref.read(taskControllerProvider.notifier).createTask(
              title: _titleController.text.trim(),
              description: _descController.text.trim().isNotEmpty
                  ? _descController.text.trim()
                  : null,
              dueDate: _dueDate,
              dueTime: _timeController.text.trim().isNotEmpty
                  ? _timeController.text.trim()
                  : null,
              priority: _priority,
              status: _status,
              category: 'সাধারণ',
              applicationId: _selectedAppId,
            );

        if (created != null) {
          for (final img in _newImages) {
            await ref.read(taskControllerProvider.notifier).addTaskAttachment(
                  taskId: created.id,
                  fileName: img.fileName,
                  fileData: img.bytes,
                  fileSize: img.fileSize,
                );
          }
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('নতুন কাজ সফলভাবে তৈরি করা হয়েছে!'),
              backgroundColor: AppColors.emerald),
        );
        Navigator.pop(context);
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

  void _showApplicationSelector(List<DemoApplication> apps) {
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filteredApps = apps.where((a) {
              if (searchQuery.trim().isEmpty) return true;
              final q = searchQuery.toLowerCase();
              final enQ = BengaliDigits.toEnglish(q);
              final bnQ = BengaliDigits.toBengali(q);
              return a.applicantName.toLowerCase().contains(q) ||
                  a.applicantPhone.contains(q) ||
                  a.applicantPhone.contains(enQ) ||
                  (a.caseNumber?.toLowerCase().contains(q) ?? false) ||
                  (a.caseNumber?.contains(enQ) ?? false) ||
                  (a.caseNumber?.contains(bnQ) ?? false) ||
                  (a.appNumber?.toLowerCase().contains(q) ?? false);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.slate300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'সংশ্লিষ্ট আবেদন নির্বাচন করুন',
                    style: AppTypography.headingSmall
                        .copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'নাম, মোবাইল বা কেস নম্বর দিয়ে খুঁজুন...',
                        prefixIcon: const Icon(Icons.search,
                            size: 20, color: AppColors.slate400),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        filled: true,
                        fillColor: AppColors.slate50,
                      ),
                      onChanged: (val) =>
                          setModalState(() => searchQuery = val),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.link_off,
                          color: AppColors.slate600, size: 20),
                    ),
                    title: const Text('কোনো আবেদন ফাইল যুক্ত নয়'),
                    subtitle: const Text(
                        'স্বতন্ত্র কাজের জন্য কোনো ফাইল নির্বাচন করবেন না'),
                    onTap: () {
                      setState(() => _selectedAppId = null);
                      Navigator.pop(ctx);
                    },
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: filteredApps.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final app = filteredApps[i];
                        final isSelected = app.id == _selectedAppId;
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: AppColors.primarySurface,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              app.applicantName.isNotEmpty
                                  ? app.applicantName[0]
                                  : 'আ',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  app.applicantName,
                                  style: AppTypography.titleMedium.copyWith(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  app.workType,
                                  style: AppTypography.labelMedium.copyWith(
                                      color: AppColors.primary, fontSize: 10.5),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'মৌজা: ${app.mouza} • কেস: ${(app.caseNumber != null && app.caseNumber!.trim().isNotEmpty) ? CaseNumberFormatter.formatDisplay(app.caseNumber) : (app.appNumber ?? 'নির্ধারিত নয়')}',
                            style: AppTypography.bodySmall.copyWith(
                                fontSize: 11.5,
                                color: AppColors.textSecondary),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: AppColors.primary)
                              : const Icon(Icons.chevron_right,
                                  color: AppColors.slate400),
                          onTap: () {
                            setState(() => _selectedAppId = app.id);
                            Navigator.pop(ctx);
                          },
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
  }

  @override
  Widget build(BuildContext context) {
    final allAppsAsync = ref.watch(applicationsWithFinancialsStreamProvider);
    final allApps = allAppsAsync.valueOrNull ?? const [];
    final demoApps = allApps.map((a) => a.toDemoApplication()).toList();

    DemoApplication? linkedApp;
    if (_selectedAppId != null) {
      linkedApp =
          demoApps.where((a) => a.id == _selectedAppId).firstOrNull;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
            _isEditing ? 'কাজের তথ্য সম্পাদনা' : 'নতুন কাজ / রিমাইন্ডার'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.base),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(15, 23, 42, 0.03),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  AppTextField(
                    label: 'কাজের শিরোনাম',
                    hint:
                        'যেমন: বিদ্যুৎ বিল পরিশোধ, শুনানিতে যাওয়া বা বাজার করা',
                    controller: _titleController,
                    isRequired: true,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'শিরোনাম আবশ্যক'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Description
                  AppTextField(
                    label: 'কাজের বিস্তারিত বিবরণ',
                    hint: 'প্রয়োজনীয় কাগজপত্র, করণীয় বা বিস্তারিত নোট...',
                    controller: _descController,
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.base),

            // Date, Time, Priority
            Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Due Date
                  const AppFieldLabel(label: 'তারিখ', isRequired: true),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) setState(() => _dueDate = picked);
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(
                            BengaliDigits.toBengali(
                                '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}'),
                            style: AppTypography.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Due Time
                  const AppFieldLabel(label: 'সময়'),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        final formatted =
                            '${BengaliDigits.toBengali(picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod)}:${BengaliDigits.toBengali(picked.minute.toString().padLeft(2, '0'))} ${picked.period == DayPeriod.am ? 'সকাল' : 'বিকাল'}';
                        setState(() => _timeController.text = formatted);
                      }
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(
                            _timeController.text.isNotEmpty
                                ? _timeController.text
                                : 'সময় নির্ধারণ করুন...',
                            style: AppTypography.bodyMedium.copyWith(
                              color: _timeController.text.isNotEmpty
                                  ? AppColors.textPrimary
                                  : AppColors.slate400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Priority
                  const AppFieldLabel(label: 'অগ্রাধিকার', isRequired: true),
                  const SizedBox(height: 8),
                  Row(
                    children: ['সাধারণ', 'মাঝারি', 'জরুরি'].map((p) {
                      final isSelected = _priority == p;
                      Color pColor = p == 'জরুরি'
                          ? AppColors.rose
                          : (p == 'মাঝারি'
                              ? const Color(0xFFF59E0B)
                              : AppColors.primary);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => setState(() => _priority = p),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? pColor.withValues(alpha: 0.12)
                                    : AppColors.slate50,
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd),
                                border: Border.all(
                                  color: isSelected
                                      ? pColor
                                      : AppColors.border,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Text(
                                p,
                                style: TextStyle(
                                  color: isSelected
                                      ? pColor
                                      : AppColors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Status
                  const AppFieldLabel(label: 'কাজের অবস্থা', isRequired: true),
                  const SizedBox(height: 8),
                  Row(
                    children: ['করতে হবে', 'চলমান', 'সম্পন্ন'].map((st) {
                      final isSelected = _status == st;
                      Color sColor = st == 'সম্পন্ন'
                          ? AppColors.emerald
                          : (st == 'চলমান'
                              ? const Color(0xFF4338CA)
                              : AppColors.textSecondary);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => setState(() => _status = st),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? sColor.withValues(alpha: 0.12)
                                    : AppColors.slate50,
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd),
                                border: Border.all(
                                  color: isSelected
                                      ? sColor
                                      : AppColors.border,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Text(
                                st,
                                style: TextStyle(
                                  color: isSelected
                                      ? sColor
                                      : AppColors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.base),

            // Linked Application Card
            Container(
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
                      const AppFieldLabel(label: 'সংশ্লিষ্ট আবেদন'),
                      TextButton.icon(
                        icon: const Icon(Icons.link, size: 14),
                        label: Text(
                            linkedApp == null ? 'ফাইল যুক্ত করুন' : 'পরিবর্তন'),
                        style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact),
                        onPressed: () => _showApplicationSelector(demoApps),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (linkedApp != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.folder_open_rounded,
                                color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  linkedApp.applicantName,
                                  style: AppTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${linkedApp.workType} • মৌজা: ${linkedApp.mouza}',
                                  style: AppTypography.bodySmall.copyWith(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                size: 18, color: AppColors.rose),
                            onPressed: () =>
                                setState(() => _selectedAppId = null),
                            tooltip: 'মুছে ফেলুন',
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.link_off,
                              size: 16, color: AppColors.slate400),
                          SizedBox(width: 8),
                          Text(
                            'কোনো আবেদন ফাইল যুক্ত নেই',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.slate500),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.base),

            // Pictures / Attachments Card
            _buildPictureAttachmentsCard(),

            const SizedBox(height: AppSpacing.xl),

            AppButton(
              text: _isEditing ? 'হালনাগাদ সংরক্ষণ করুন' : 'কাজ যুক্ত করুন',
              icon: Icons.check,
              onPressed: _saveTask,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPictureAttachmentsCard() {
    final totalImages = _existingImages.length + _newImages.length;

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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.add_a_photo_outlined,
                        size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    totalImages > 0
                        ? 'সংযুক্ত ছবিসমূহ (${BengaliDigits.toBengali(totalImages)}টি)'
                        : 'কাজের ছবি / ডকুমেন্টস',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                ],
              ),
              if (totalImages > 0)
                TextButton.icon(
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                  label: const Text('আরও ছবি', style: TextStyle(fontSize: 12.5)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: _pickImages,
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (_isLoadingImages)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (totalImages == 0)
            InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              onTap: _pickImages,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.primarySurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ছবি যুক্ত করুন (ক্যামেরা বা গ্যালারি)',
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'প্রয়োজনীয় কাগজপত্র বা রসিদের ছবি তুলে রাখুন',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_a_photo_outlined, size: 14),
                      label:
                          const Text('ছবি বাছুন', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Existing images list
            ..._existingImages.map((img) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    // Clickable image thumbnail with zoom preview
                    GestureDetector(
                      onTap: () {
                        FullScreenImageViewer.open(
                          context,
                          imageBytes: img.fileData,
                          title: img.fileName,
                          subtitle: BengaliDigits.toBengali(img.fileSize),
                        );
                      },
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                            child: Image.memory(
                              img.fileData,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              cacheWidth: 150,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                              ),
                            ),
                            child: const Icon(Icons.zoom_in_rounded,
                                size: 12, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          FullScreenImageViewer.open(
                            context,
                            imageBytes: img.fileData,
                            title: img.fileName,
                            subtitle: BengaliDigits.toBengali(img.fileSize),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              img.fileName,
                              style: AppTypography.titleMedium.copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  BengaliDigits.toBengali(img.fileSize),
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySurface,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'বড় করে দেখুন',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: AppColors.rose),
                      tooltip: 'ছবিটি সরান',
                      onPressed: () {
                        setState(() {
                          _removedExistingImageIds.add(img.id);
                          _existingImages.removeWhere((i) => i.id == img.id);
                        });
                      },
                    ),
                  ],
                ),
              );
            }),

            // Newly picked images list
            ..._newImages.asMap().entries.map((entry) {
              final idx = entry.key;
              final img = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    // Clickable image thumbnail with zoom preview
                    GestureDetector(
                      onTap: () {
                        FullScreenImageViewer.open(
                          context,
                          imageBytes: img.bytes,
                          title: img.fileName,
                          subtitle: BengaliDigits.toBengali(img.fileSize),
                        );
                      },
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                            child: Image.memory(
                              img.bytes,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              cacheWidth: 150,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                              ),
                            ),
                            child: const Icon(Icons.zoom_in_rounded,
                                size: 12, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          FullScreenImageViewer.open(
                            context,
                            imageBytes: img.bytes,
                            title: img.fileName,
                            subtitle: BengaliDigits.toBengali(img.fileSize),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              img.fileName,
                              style: AppTypography.titleMedium.copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  BengaliDigits.toBengali(img.fileSize),
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySurface,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'বড় করে দেখুন',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 20, color: AppColors.rose),
                      tooltip: 'ছবিটি সরান',
                      onPressed: () {
                        setState(() {
                          _newImages.removeAt(idx);
                        });
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
