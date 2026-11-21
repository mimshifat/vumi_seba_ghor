import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/bengali_digits.dart';
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
    // পিসিতে ডিফল্টভাবে রিসিভার মোড, মোবাইলে সেন্ডার মোড
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

  void _switchMode(bool receiverMode) {
    setState(() {
      _isReceiverMode = receiverMode;
    });
    if (_isReceiverMode) {
      ref.read(syncDiscoveryServiceProvider).stop();
      _startPcServer();
    } else {
      ref.read(syncServerControllerProvider.notifier).stopServer();
      _startPhoneDiscovery();
    }
  }

  // পিসিতে ডেটা পাঠানো শুরু করা
  Future<void> _handleSendData() async {
    final ip = _selectedDevice?.ip ?? _ipController.text.trim();
    final pin = _selectedDevice?.pin.isNotEmpty == true
        ? _selectedDevice!.pin
        : _pinController.text.trim();

    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('অনুগ্রহ করে পিসির আইপি অ্যাড্রেস নির্বাচন করুন বা লিখুন'),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('পিসির স্ক্রিনে দেখানো ৪ সংখ্যার পিন দিন'),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = await ref.read(syncClientControllerProvider.notifier).sendData(
          ip: ip,
          port: _selectedDevice?.port ?? 8765,
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
              'সিঙ্ক সফল হয়েছে!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
            Icon(Icons.error_outline_rounded, color: AppColors.rose, size: 24),
            SizedBox(width: 8),
            Text('সিঙ্ক সম্পন্ন হয়নি',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13.5, height: 1.4),
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
        title: const Text('পিসি সিকিউরিটি পিন পরিবর্তন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ফোন থেকে ডেটা পাঠানোর সময় এই পিনটি দিয়ে অনুমতি নিশ্চিত করা হয়।',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: '৪ সংখ্যার পিন',
              controller: pinEditCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          AppDialogActionRow(
            confirmText: 'সংরক্ষণ',
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
        title: const Text('লোকাল ওয়াই-ফাই সিঙ্ক'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.slate200,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _switchMode(false),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isReceiverMode
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        boxShadow: !_isReceiverMode
                            ? [
                                BoxShadow(
                                  color: Colors.black.withAlpha(20),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone_android_rounded,
                            size: 18,
                            color: !_isReceiverMode
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'মোবাইল (ডেটা পাঠান)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: !_isReceiverMode
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: !_isReceiverMode
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _switchMode(true),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isReceiverMode
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        boxShadow: _isReceiverMode
                            ? [
                                BoxShadow(
                                  color: Colors.black.withAlpha(20),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.laptop_chromebook_rounded,
                            size: 18,
                            color: _isReceiverMode
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'কম্পিউটার (ডেটা গ্রহণ)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _isReceiverMode
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _isReceiverMode
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                          ? 'ফোন থেকে ডেটা গ্রহণের জন্য প্রস্তুত'
                          : 'রিসিভার সার্ভার বন্ধ আছে',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      serverState.isRunning
                          ? 'লোকাল ওয়াই-ফাই সংযোগ সক্রিয় (পোর্ট: ${BengaliDigits.toBengali(serverState.port.toString())})'
                          : 'সার্ভার চালু করতে পাশের সুইচে চাপ দিন',
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
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'ফোনের অ্যাপ এই তথ্যগুলো দিয়ে সরাসরি এই কম্পিউটারে ডেটা পাঠাবে:',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
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
                          const Text('লোকাল আইপি (IP Address)',
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
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      tooltip: 'আইপি কপি করুন',
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: serverState.currentIp));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('আইপি কপি করা হয়েছে'),
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
                          const Text('সিকিউরিটি পিন (PIN)',
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
                      tooltip: 'পিন পরিবর্তন',
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
                  Icon(Icons.info_outline_rounded,
                      color: Color(0xFF1D4ED8), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'কীভাবে ব্যবহার করবেন?',
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
                'আপনার ফোন এবং এই কম্পিউটার একই ওয়াই-ফাই অথবা ফোনের হটস্পটে কানেক্ট করুন (ইন্টারনেট না থাকলেও চলবে)।',
              ),
              _buildStepItem(
                '২',
                'ফোনের অ্যাপ ওপেন করে "পিসিতে ডেটা পাঠান" বাটনে চাপ দিন।',
              ),
              _buildStepItem(
                '৩',
                'ফোনের স্ক্রিনে এই কম্পিউটার দেখতে পেয়ে "পাঠান" চাপলেই সাথে সাথে পিসিতে সব ডেটা আপডেট হয়ে যাবে।',
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
                        'সর্বশেষ সিঙ্ক সম্পন্ন হয়েছে',
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
                    'আশেপাশের কম্পিউটার (লোকাল ওয়াই-ফাই)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'কম্পিউটার খোঁজা হচ্ছে...',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'পিসিতে অ্যাপ খোলা আছে কিনা এবং একই ওয়াই-ফাই বা হটস্পটে আছেন কিনা যাচাই করুন।\n(💡 টিপ: রাউটারে সংযোগ না পেলে ফোনের Hotspot চালু করে পিসিতে যুক্ত করুন)',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11.5,
                          height: 1.4,
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
                                  Text(
                                    'আইপি: ${device.ip}  •  পিন: ${device.pin}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.primary, size: 22),
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
                      ? 'ম্যানুয়াল আইপি ইনপুট লুকান'
                      : 'কম্পিউটার খুঁজে না পেলে? ম্যানুয়াল আইপি লিখুন',
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
                const Text('পিসির সংযোগ তথ্য লিখুন',
                    style:
                        TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'পিসির আইপি অ্যাড্রেস (IP Address)',
                  hint: 'যেমন: 192.168.0.105',
                  controller: _ipController,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: '৪ সংখ্যার সিকিউরিটি পিন',
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
            text: 'পিসিতে সমস্ত ডেটা পাঠান',
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
                  size: 18, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'নোট: এই বাটন চাপলে আপনার ফোনের সকল কাস্টমার, আবেদন, জমা-খরচের পূর্ণাঙ্গ ও নিরাপদ তথ্য পিসিতে প্রতিস্থাপিত হবে। পিসিতে আগের কোনো অসম্পূর্ণ তথ্য থাকলে তা দূর হয়ে ফোনের মতো হুবহু হয়ে যাবে।',
                  style: TextStyle(
                      fontSize: 11.5,
                      height: 1.4,
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF3B82F6),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 12, height: 1.4, color: Color(0xFF1E3A8A)),
            ),
          ),
        ],
      ),
    );
  }
}
