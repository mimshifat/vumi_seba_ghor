import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../../core/widgets/app_text_field.dart';

class TaskCreateEditScreen extends StatefulWidget {
  final DemoTask? task;

  const TaskCreateEditScreen({super.key, this.task});

  @override
  State<TaskCreateEditScreen> createState() => _TaskCreateEditScreenState();
}

class _TaskCreateEditScreenState extends State<TaskCreateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _timeController;

  late DateTime _dueDate;
  late String _priority;
  late String _status;
  String? _selectedAppId;

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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;

    String? applicantName;
    if (_selectedAppId != null) {
      try {
        applicantName = DemoStore.applications.firstWhere((a) => a.id == _selectedAppId).applicantName;
      } catch (_) {}
    }

    if (_isEditing) {
      final updated = widget.task!.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        dueDate: _dueDate,
        dueTime: _timeController.text.trim().isNotEmpty ? _timeController.text.trim() : null,
        priority: _priority,
        status: _status,
        relatedApplicationId: _selectedAppId,
        relatedApplicantName: applicantName,
        completedAt: _status == 'সম্পন্ন' ? (widget.task!.completedAt ?? DateTime.now()) : null,
      );

      final idx = DemoStore.tasks.indexWhere((t) => t.id == widget.task!.id);
      if (idx != -1) DemoStore.tasks[idx] = updated;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কাজের তথ্য হালনাগাদ করা হয়েছে।'), backgroundColor: AppColors.emerald),
      );
      Navigator.pop(context, updated);
    } else {
      final newTask = DemoTask(
        id: 'tsk-${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        dueDate: _dueDate,
        dueTime: _timeController.text.trim().isNotEmpty ? _timeController.text.trim() : null,
        priority: _priority,
        status: _status,
        relatedApplicationId: _selectedAppId,
        relatedApplicantName: applicantName,
        completedAt: _status == 'সম্পন্ন' ? DateTime.now() : null,
      );

      DemoStore.tasks.insert(0, newTask);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('নতুন কাজ সফলভাবে তৈরি করা হয়েছে!'), backgroundColor: AppColors.emerald),
      );
      Navigator.pop(context, newTask);
    }
  }

  void _selectApplicationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filteredApps = DemoStore.applications.where((a) {
              if (searchQuery.isEmpty) return true;
              final q = searchQuery.toLowerCase();
              return a.applicantName.toLowerCase().contains(q) ||
                  a.applicantPhone.contains(q) ||
                  (a.caseNumber?.toLowerCase().contains(q) ?? false) ||
                  (a.appNumber?.toLowerCase().contains(q) ?? false) ||
                  (a.mouza?.toLowerCase().contains(q) ?? false);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.slate300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'আবেদন ফাইল নির্বাচন করুন',
                          style: AppTypography.headingSmall.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'নাম, মোবাইল বা কেস নম্বর দিয়ে খুঁজুন...',
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.slate400),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        filled: true,
                        fillColor: AppColors.slate50,
                      ),
                      onChanged: (val) => setModalState(() => searchQuery = val),
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
                      child: const Icon(Icons.link_off, color: AppColors.slate600, size: 20),
                    ),
                    title: const Text('কোনো আবেদন ফাইল যুক্ত নয়'),
                    subtitle: const Text('স্বতন্ত্র কাজের জন্য কোনো ফাইল নির্বাচন করবেন না'),
                    onTap: () {
                      setState(() => _selectedAppId = null);
                      Navigator.pop(ctx);
                    },
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredApps.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final app = filteredApps[i];
                        final isSelected = app.id == _selectedAppId;
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: AppColors.primarySurface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              app.applicantName.isNotEmpty ? app.applicantName[0] : 'আ',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  app.applicantName,
                                  style: AppTypography.titleMedium.copyWith(fontSize: 14.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  app.workType,
                                  style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontSize: 10.5),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'মৌজা: ${app.mouza} • কেস: ${app.caseNumber ?? app.appNumber ?? 'নির্ধারিত নয়'}',
                            style: AppTypography.bodySmall.copyWith(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppColors.primary)
                              : const Icon(Icons.chevron_right, color: AppColors.slate400),
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
    DemoApplication? linkedApp;
    if (_selectedAppId != null) {
      try {
        linkedApp = DemoStore.applications.firstWhere((a) => a.id == _selectedAppId);
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'কাজের তথ্য সম্পাদনা' : 'নতুন কাজ / রিমাইন্ডার'),
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
                    hint: 'যেমন: বিদ্যুৎ বিল পরিশোধ, শুনানিতে যাওয়া বা বাজার করা',
                    controller: _titleController,
                    isRequired: true,
                    validator: (v) => v == null || v.trim().isEmpty ? 'শিরোনাম আবশ্যক' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Priority Selector
                  const AppFieldLabel(
                    label: 'অগ্রাধিকার',
                    isRequired: true,
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  Row(
                    children: [
                      _buildPriorityChip('সাধারণ', Icons.flag_outlined, AppColors.slate700),
                      const SizedBox(width: AppSpacing.sm),
                      _buildPriorityChip('জরুরি', Icons.priority_high, AppColors.rose),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Status Selector
                  const AppFieldLabel(
                    label: 'কাজের অবস্থা',
                    isRequired: true,
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  Row(
                    children: [
                      _buildStatusChip('করতে হবে', Icons.schedule_outlined, AppColors.amberDark, AppColors.amberSurface),
                      const SizedBox(width: AppSpacing.sm),
                      _buildStatusChip('চলমান', Icons.autorenew_rounded, AppColors.primary, AppColors.primarySurface),
                      const SizedBox(width: AppSpacing.sm),
                      _buildStatusChip('সম্পন্ন', Icons.check_circle_outline, AppColors.emeraldDark, AppColors.emeraldSurface),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Due Date
                  const AppFieldLabel(
                    label: 'তারিখ',
                    isRequired: true,
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            BengaliDigits.toBengali('${_dueDate.day}/${_dueDate.month}/${_dueDate.year}'),
                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const Spacer(),
                          Text(
                            _getDateLabel(_dueDate),
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.primary,
                              backgroundColor: AppColors.primarySurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Quick Date Shortcuts
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickDateChip('আজ', DateTime.now()),
                        const SizedBox(width: 6),
                        _buildQuickDateChip('আগামীকাল', DateTime.now().add(const Duration(days: 1))),
                        const SizedBox(width: 6),
                        _buildQuickDateChip('৩ দিন পর', DateTime.now().add(const Duration(days: 3))),
                        const SizedBox(width: 6),
                        _buildQuickDateChip('১ সপ্তাহ পর', DateTime.now().add(const Duration(days: 7))),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Time
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'সময়',
                          hint: 'যেমন: বেলা ১১:০০',
                          controller: _timeController,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            final h = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
                            final m = picked.minute.toString().padLeft(2, '0');
                            final p = picked.period == DayPeriod.am ? 'সকাল' : (picked.hour < 15 ? 'দুপুর' : (picked.hour < 18 ? 'বিকাল' : 'রাত'));
                            setState(() {
                              _timeController.text = '$p ${BengaliDigits.toBengali(h)}:${BengaliDigits.toBengali(m)}';
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        child: Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: AppColors.primaryLight),
                          ),
                          child: const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickTimeChip('সকাল ১০:০০'),
                        const SizedBox(width: 6),
                        _buildQuickTimeChip('সকাল ১১:০০'),
                        const SizedBox(width: 6),
                        _buildQuickTimeChip('দুপুর ১২:০০'),
                        const SizedBox(width: 6),
                        _buildQuickTimeChip('বিকাল ০৩:৩০'),
                        const SizedBox(width: 6),
                        _buildQuickTimeChip('সন্ধ্যা ০৬:০০'),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Related Application Selector (Optional)
                  const AppFieldLabel(
                    label: 'সংশ্লিষ্ট আবেদন',
                    isRequired: false,
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  if (linkedApp != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.primaryLight),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.description, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  linkedApp.applicantName,
                                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  '${linkedApp.workType} • ${linkedApp.mouza} (${linkedApp.caseNumber ?? linkedApp.appNumber ?? 'কেস'})',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.rose, size: 20),
                            tooltip: 'বাতিল করুন',
                            onPressed: () => setState(() => _selectedAppId = null),
                          ),
                        ],
                      ),
                    )
                  else
                    InkWell(
                      onTap: _selectApplicationModal,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline, color: AppColors.slate500, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'ব্যক্তিগত কাজ (নির্দিষ্ট কোনো ফাইল লিঙ্ক নেই)',
                                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                              ),
                              child: Text(
                                '+ ফাইল লিঙ্ক',
                                style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: AppSpacing.lg),

                  // Description
                  AppTextField(
                    label: 'কাজের বিস্তারিত বিবরণ',
                    hint: 'অতিরিক্ত তথ্য, কী কী কাগজ নিতে হবে ইত্যাদি...',
                    controller: _descController,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              text: _isEditing ? 'পরিবর্তন সংরক্ষণ করুন' : 'কাজ সংরক্ষণ করুন',
              icon: Icons.check,
              onPressed: _saveTask,
            ),
          ],
        ),
      ),
    );
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'আজকের কাজ';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'আগামীকাল';
    }
    return '';
  }

  Widget _buildQuickDateChip(String label, DateTime targetDate) {
    final isSelected = _dueDate.year == targetDate.year &&
        _dueDate.month == targetDate.month &&
        _dueDate.day == targetDate.day;
    return InkWell(
      onTap: () => setState(() => _dueDate = targetDate),
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.slate100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTimeChip(String timeStr) {
    final isSelected = _timeController.text == timeStr;
    return InkWell(
      onTap: () => setState(() => _timeController.text = timeStr),
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.slate100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          timeStr,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String label, IconData icon, Color color) {
    final isSelected = _priority == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _priority = label),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : AppColors.slate100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: isSelected ? color : AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? color : AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12.5,
                  fontFamily: AppTypography.fontFamily,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, IconData icon, Color color, Color bgColor) {
    final isSelected = _status == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _status = label),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? bgColor : AppColors.slate100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: isSelected ? color : AppColors.border, width: isSelected ? 1.5 : 1.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: isSelected ? color : AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                  fontFamily: AppTypography.fontFamily,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
