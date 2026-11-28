import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog_action_row.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/models/sync_device_info.dart';
import '../providers/sync_providers.dart';

class LocalSyncScreen extends ConsumerStatefulWidget {
  final bool? initialIsReceiverMode;

  const LocalSyncScreen({super.key, this.initialIsReceiverMode});

  @override
  ConsumerState<LocalSyncScreen> createState() => _LocalSyncScreenState();
}

class _LocalSyncScreenState extends ConsumerState<LocalSyncScreen> {
  late bool _isReceiverMode;
  final _ipController = TextEditingController();
  final _pinController = TextEditingController(text: '1234');
  SyncDeviceInfo? _selectedDevice;
  bool _showManualIpInput = false;

  @override
  void initState() {
    super.initState();
    // পিসিতে স্থায়ীভাবে রিসিভার মোড, মোবাইলে স্থায়ীভাবে সেন্ডার মোড (ডেটা শুধু ফোন থেকে পিসিতে যাবে)
    _isReceiverMode = widget.initialIsReceiverMode ??
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMode();
    });
  }

  void _initMode() {
    if (_isReceiverMode) {
      _startPcServer();
    } else {
      _startPhoneDiscovery();
    }
  }

  void _startPcServer() {
    ref.read(syncServerControllerProvider.notifier).startServer();
  }

  void _startPhoneDiscovery() {
    ref.read(syncDiscoveryServiceProvider).startListening();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // পিসিতে ডেটা পাঠানো শুরু করা
  Future<void> _handleSendData() async {
    final pcs = ref.read(discoveredPcsStreamProvider).valueOrNull ?? const [];
    final targetDevice = _selectedDevice ?? (pcs.isNotEmpty ? pcs.first : null);
    final ip = targetDevice?.ip ?? _ipController.text.trim();
    final pin = targetDevice?.pin.isNotEmpty == true
        ? targetDevice!.pin
        : _pinController.text.trim();

    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'কোনো কম্পিউটার নির্বাচন করা হয়নি। অনুগ্রহ করে নিচের তালিকা থেকে আপনার কম্পিউটারটি বেছে নিন অথবা ঠিকানা লিখুন।',
          ),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'কম্পিউটারের স্ক্রিনে দেখানো ৪ সংখ্যার পিন কোড দিন (যেমন: ১২৩৪)',
          ),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = await ref.read(syncClientControllerProvider.notifier).sendData(
          ip: ip,
          allIps: targetDevice?.allAvailableIps ?? [],
          port: targetDevice?.port ?? 8765,
          pin: pin,
        );

    if (!mounted) return;

    if (result.isSuccess) {
      _showSuccessDialog(result.message);
    } else {
      _showErrorDialog(result.message);
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.emeraldSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.emerald, size: 54),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'তথ্য স্থানান্তর সফল হয়েছে!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            AppButton(
              text: 'ঠিক আছে',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.rose, size: 24),
            SizedBox(width: 8),
            Text(
              'তথ্য পাঠানো যায়নি',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, height: 1.45),
        ),
        actions: [
          AppDialogActionRow(
            confirmText: 'বুঝেছি',
            onConfirm: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog(String currentPin) {
    final pinEditCtrl = TextEditingController(text: currentPin);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: const Text('কম্পিউটারের নিরাপত্তা পিন পরিবর্তন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'মোবাইল থেকে যখনই তথ্য পাঠানো হবে, নিরাপত্তার স্বার্থে এই পিন কোডটি স্বয়ংক্রিয়ভাবে মিলিয়ে নেওয়া হয়।',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.35),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: '৪ সংখ্যার পিন কোড',
              hint: 'যেমন: ১২৩৪',
              controller: pinEditCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          AppDialogActionRow(
            confirmText: 'সংরক্ষণ করুন',
            onConfirm: () {
              final newPin = pinEditCtrl.text.trim();
              if (newPin.length >= 4) {
                ref
                    .read(syncServerControllerProvider.notifier)
                    .updatePin(newPin);
                Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isReceiverMode
                  ? 'ফোন থেকে ডেটা গ্রহণ (কম্পিউটার)'
                  : 'পিসিতে ডেটা পাঠান (সিঙ্ক)',
              style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              _isReceiverMode
                  ? 'একমুখী সিঙ্ক • ফোন ➔ কম্পিউটার'
                  : 'একমুখী সিঙ্ক • ইন্টারনেট ছাড়াই সরাসরি ফোন থেকে পিসিতে',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: _isReceiverMode ? _buildReceiverView() : _buildSenderView(),
    );
  }

  // -------------------------------------------------------------
  // পিসি রিসিভার ভিউ (PC Receiver View)
  // -------------------------------------------------------------
  Widget _buildReceiverView() {
    final serverState = ref.watch(syncServerControllerProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.base),
      children: [
        // ১. সার্ভার স্ট্যাটাস কার্ড
        Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: serverState.isRunning
                  ? AppColors.emerald.withAlpha(100)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: serverState.isRunning
                      ? AppColors.emeraldSurface
                      : AppColors.slate100,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  serverState.isRunning
                      ? Icons.wifi_tethering_rounded
                      : Icons.wifi_tethering_off_rounded,
                  color: serverState.isRunning
                      ? AppColors.emerald
                      : AppColors.textMuted,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serverState.isRunning
                          ? 'মোবাইল থেকে তথ্য গ্রহণের জন্য প্রস্তুত'
                          : 'রিসিভার সাময়িকভাবে বন্ধ আছে',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      serverState.isRunning
                          ? 'মোবাইল থেকে "পাঠান" বাটনে চাপ দিলেই তথ্য চলে আসবে'
                          : 'চালু করতে পাশের সুইচে ক্লিক করুন',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: serverState.isRunning,
                activeThumbColor: AppColors.emerald,
                onChanged: (val) {
                  if (val) {
                    ref
                        .read(syncServerControllerProvider.notifier)
                        .startServer();
                  } else {
                    ref.read(syncServerControllerProvider.notifier).stopServer();
                  }
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.base),

        // একমুখী নীতি ব্যানার
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: Color(0xFF15803D), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'একমুখী নীতি: সব তথ্য কেবল মোবাইল থেকে এই কম্পিউটারে আসবে। কম্পিউটার থেকে কোনো ডেটা ফোনে যাবে না বা ফোনের ডেটা নষ্ট হওয়ার সুযোগ নেই।',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF166534),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.base),

        // ২. সংযোগ তথ্য কার্ড (আইপি ও পিন)
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
              const Text(
                'এই কম্পিউটারের সংযোগ তথ্য',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'মোবাইলের অ্যাপে সাধারণত এই তথ্যগুলো আপনা-আপনি বসে যায় (না পেলে মিলিয়ে নিন):',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
              ),
              const SizedBox(height: AppSpacing.md),

              // আইপি অ্যাড্রেস রো
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.router_rounded,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('কম্পিউটারের নেটওয়ার্ক ঠিকানা (আইপি)',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          Text(
                            serverState.currentIp,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (serverState.availableIps.length > 1) ...[
                            const SizedBox(height: 4),
                            Text(
                              'অন্যান্য: ${serverState.availableIps.where((ip) => ip != serverState.currentIp).join(", ")}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      tooltip: 'ঠিকানা কপি করুন',
                      onPressed: () {
                        final allIps = serverState.availableIps.isNotEmpty
                            ? serverState.availableIps.join(', ')
                            : serverState.currentIp;
                        Clipboard.setData(ClipboardData(text: allIps));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ঠিকানা কপি করা হয়েছে'),
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // পিন কোড রো
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded,
                        color: AppColors.amberDark, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('নিরাপত্তা পিন কোড (PIN)',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          Text(
                            serverState.pin,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'পিন পরিবর্তন করুন',
                      onPressed: () => _showChangePinDialog(serverState.pin),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.base),

        // ৩. নির্দেশিকা কার্ড
        Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      color: Color(0xFF1D4ED8), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'সহজে ব্যবহারের ৩টি নিয়ম',
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildStepItem(
                '১',
                'সবচেয়ে সহজ ও দ্রুত উপায়: আপনার ফোনের Hotspot চালু করে কম্পিউটারকে তাতে যুক্ত করুন (অথবা দুটোই একই ওয়াই-ফাই রাউটারে রাখুন)।',
              ),
              _buildStepItem(
                '২',
                'ফোনের রজব অ্যাপে গিয়ে "পিসিতে ডেটা পাঠান" বাটনে চাপ দিন।',
              ),
              _buildStepItem(
                '৩',
                'ফোনের স্ক্রিনে এই কম্পিউটার দেখতে পেয়ে "পাঠান" চাপলেই নিমেষেই সব আবেদন ও হিসাব এখানে যুক্ত হয়ে যাবে।',
              ),
              _buildStepItem(
                '💡',
                'পরামর্শ: কম্পিউটারে প্রথমবার অ্যাপ চালুর সময় কোনো অনুমতি (Firewall Alert) চাওয়া হলে "Allow access" বা সম্মতি দিন।',
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.base),

        // ৪. সর্বশেষ সিঙ্কের অবস্থা
        if (serverState.lastSyncTime != null)
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.emeraldSurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.emeraldLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.task_alt_rounded,
                    color: AppColors.emerald, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'সর্বশেষ সফল সিঙ্ক সম্পন্ন হয়েছে',
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.emeraldDark),
                      ),
                      Text(
                        'সময়: ${DateFormat('h:mm a, d MMM yyyy').format(serverState.lastSyncTime!)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // -------------------------------------------------------------
  // মোবাইল সেন্ডার ভিউ (Mobile Sender View)
  // -------------------------------------------------------------
  Widget _buildSenderView() {
    final discoveredPcsAsync = ref.watch(discoveredPcsStreamProvider);
    final clientState = ref.watch(syncClientControllerProvider);
    final pcs = discoveredPcsAsync.valueOrNull ?? const [];

    // কোনো ডিভাইস আগে নির্বাচিত না থাকলে এবং তালিকা পেলে স্বয়ংক্রিয়ভাবে ১মটি সিলেক্ট করা
    if (_selectedDevice == null && pcs.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedDevice == null && pcs.isNotEmpty) {
          setState(() {
            _selectedDevice = pcs.first;
            _ipController.text = pcs.first.ip;
            if (pcs.first.pin.isNotEmpty) {
              _pinController.text = pcs.first.pin;
            }
          });
        }
      });
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.base),
      children: [
        // ১. অটো ডিটেকশন সেকশন
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
                  const Text(
                    'কাছের কম্পিউটারসমূহ',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'পুনরায় খুঁজুন',
                    onPressed: () {
                      ref.read(syncDiscoveryServiceProvider).sendProbe();
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (pcs.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'কম্পিউটার খোঁজা হচ্ছে...',
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'সহজে কানেক্ট করার উপায়:\n'
                        '১. আপনার ফোনের Hotspot চালু করে পিসিতে ওয়াই-ফাই কানেক্ট করুন (সবচেয়ে দ্রুত ও সহজ!)\n'
                        '২. অথবা ফোন ও কম্পিউটার একই ওয়াই-ফাই রাউটারে রাখুন\n'
                        '৩. কম্পিউটারেও রজব অ্যাপের "ডেটা গ্রহণ" স্ক্রিনটি খুলে রাখুন',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11.5,
                          height: 1.45,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: pcs.map((device) {
                    final isSelected = _selectedDevice?.ip == device.ip;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDevice = device;
                          _ipController.text = device.ip;
                          if (device.pin.isNotEmpty) {
                            _pinController.text = device.pin;
                          }
                        });
                      },
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primarySurface
                              : AppColors.slate50,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.slate200,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.slate200,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.desktop_windows_rounded,
                                size: 20,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.deviceName,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ঠিকানা: ${device.ip}  •  পিন: ${device.pin.isNotEmpty ? device.pin : '১২৩৪'}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check, size: 14, color: Colors.white),
                                    SizedBox(width: 3),
                                    Text(
                                      'নির্বাচিত',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.base),

        // ২. ম্যানুয়াল আইপি অপশন (টগল)
        InkWell(
          onTap: () {
            setState(() {
              _showManualIpInput = !_showManualIpInput;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _showManualIpInput
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _showManualIpInput
                      ? 'ম্যানুয়াল ঠিকানা ইনপুট লুকান'
                      : 'কম্পিউটার খুঁজে না পেলে? নিজে ঠিকানা লিখতে চাপুন',
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),

        if (_showManualIpInput) ...[
          const SizedBox(height: AppSpacing.sm),
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
                const Text('কম্পিউটারের সংযোগ তথ্য লিখুন',
                    style:
                        TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'কম্পিউটারের নেটওয়ার্ক ঠিকানা (আইপি)',
                  hint: 'পিসির স্ক্রিনে দেখানো ঠিকানা, যেমন: 192.168.0.105',
                  controller: _ipController,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: '৪ সংখ্যার নিরাপত্তা পিন (PIN)',
                  hint: 'যেমন: 1234',
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.lg),

        // ৩. মূল পুশ বাটন ও প্রগ্রেস
        if (clientState.isSending) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.primary.withAlpha(80)),
            ),
            child: Column(
              children: [
                const LinearProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  clientState.statusMessage,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary),
                ),
              ],
            ),
          ),
        ] else ...[
          AppButton(
            text: 'কম্পিউটারে সমস্ত তথ্য পাঠান',
            height: 48,
            onPressed: _handleSendData,
          ),
        ],

        const SizedBox(height: AppSpacing.lg),

        // ৪. তথ্য নোট
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.slate200),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined,
                  size: 20, color: AppColors.textSecondary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'শতভাগ নিরাপদ: আপনার ফোনের সমস্ত কাস্টমার, আবেদন, জমা-খরচের হালনাগাদ তথ্য কম্পিউটারে যুক্ত হবে। ফোনই তথ্যের একমাত্র মূল উৎস—কম্পিউটার থেকে কোনো তথ্য কখনো ফোনে আসবে না, ফলে ফোনের হিসাবের কোনো ক্ষতি হবে না।',
                  style: TextStyle(
                      fontSize: 11.5,
                      height: 1.45,
                      color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF3B82F6),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 12.5, height: 1.4, color: Color(0xFF1E3A8A)),
            ),
          ),
        ],
      ),
    );
  }
}
