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
      final updated = DemoTask(
        id: widget.task!.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        dueDate: _dueDate,
        dueTime: _timeController.text.trim().isNotEmpty ? _timeController.text.trim() : null,
        priority: _priority,
        status: _status,
        relatedApplicationId: _selectedAppId,
        relatedApplicantName: applicantName,
      );

      final idx = DemoStore.tasks.indexWhere((t) => t.id == widget.task!.id);
      if (idx != -1) DemoStore.tasks[idx] = updated;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('টাস্ক হালনাগাদ করা হয়েছে।'), backgroundColor: AppColors.emerald),
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
      );

      DemoStore.tasks.insert(0, newTask);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('নতুন কাজ যোগ করা হয়েছে!'), backgroundColor: AppColors.emerald),
      );
      Navigator.pop(context, newTask);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label: 'কাজের শিরোনাম',
                    hint: 'যেমন: রহিম উদ্দিনের শুনানিতে যাওয়া বা খতিয়ান সংগ্রহ',
                    controller: _titleController,
                    isRequired: true,
                    validator: (v) => v == null || v.trim().isEmpty ? 'শিরোনাম আবশ্যক' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'কাজের বিস্তারিত বিবরণ',
                    hint: 'অতিরিক্ত তথ্য, কী কী কাগজ নিতে হবে ইত্যাদি...',
                    controller: _descController,
                    maxLines: 2,
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

                  // Due Date & Time
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      BengaliDigits.toBengali('${_dueDate.day}/${_dueDate.month}/${_dueDate.year}'),
                                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppTextField(
                          label: 'সময়',
                          hint: 'যেমন: বেলা ১১:০০',
                          controller: _timeController,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Related Application Dropdown (Optional)
                  const AppFieldLabel(
                    label: 'সংশ্লিষ্ট আবেদন',
                    isRequired: false,
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedAppId,
                        isExpanded: true,
                        hint: const Text('কোনো নির্দিষ্ট আবেদন যুক্ত নেই'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('কোনো নির্দিষ্ট আবেদন যুক্ত নেই'),
                          ),
                          ...DemoStore.applications.map((a) {
                            return DropdownMenuItem<String?>(
                              value: a.id,
                              child: Text('${a.applicantName} (${a.workType})'),
                            );
                          }),
                        ],
                        onChanged: (val) => setState(() => _selectedAppId = val),
                      ),
                    ),
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
}

