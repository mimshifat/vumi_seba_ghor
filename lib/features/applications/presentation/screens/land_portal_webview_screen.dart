import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/app_launcher.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../backup/data/repositories/backup_repository.dart';
import '../../data/services/land_portal_helper.dart';
import '../providers/application_providers.dart';

/// ভূমি পোর্টাল (`lsg-land-owner.land.gov.bd`) ইন-অ্যাপ ব্রাউজার ও অটো-ফিল স্ক্রিন।
///
/// - ভিন্ন আবেদনকারীর অ্যাকাউন্টে ঢুকলে পূর্বের সেশন/কুকি স্বয়ংক্রিয়ভাবে পরিষ্কার করে।
/// - লগইন পেজ লোড হলে সংরক্ষিত মোবাইল নম্বর (১০ ডিজিট) ও পাসওয়ার্ড অটো-ফিল করে।
/// - লগইনের পর ফাইল আপলোড, HTTP/Blob/Data PDF ডাউনলোড, প্রিন্ট, পপআপ ও পেমেন্ট গেটওয়ে সাপোর্ট করে।
class LandPortalWebViewScreen extends ConsumerStatefulWidget {
  final String initialUrl;
  final String? portalPhone;
  final String? portalPassword;
  final String? applicationId;
  final String? applicantName;

  const LandPortalWebViewScreen({
    super.key,
    this.initialUrl = LandPortalHelper.lsgLoginUrl,
    this.portalPhone,
    this.portalPassword,
    this.applicationId,
    this.applicantName,
  });

  @override
  ConsumerState<LandPortalWebViewScreen> createState() =>
      _LandPortalWebViewScreenState();
}

class _LandPortalWebViewScreenState
    extends ConsumerState<LandPortalWebViewScreen> {
  static const MethodChannel _downloadChannel =
      MethodChannel('com.rojob.bhumi_kajer_hisab/downloads');

  static const String _desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

  /// সর্বশেষ কোন নম্বরে পোর্টাল সেশন চালু ছিল তা ট্র্যাক করে, যাতে ভিন্ন
  /// আবেদনকারীর ফাইল খুললে আগের ব্যক্তির সেশন মিশে না যায়।
  static String? _lastActiveAccountKey;

  InAppWebViewController? _webViewController;
  double _progress = 0;
  String _currentUrl = '';
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isDesktopMode = false;
  bool _autofillDoneForCurrentLoginPage = false;
  bool _isDownloading = false;
  bool _sessionPrepared = false;
  bool _switchedAccountCleared = false;
  String? _pageErrorMessage;

  bool get _hasCredentials =>
      (widget.portalPhone != null && widget.portalPhone!.trim().isNotEmpty) ||
      (widget.portalPassword != null && widget.portalPassword!.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
    _prepareSession();
  }

  Future<void> _prepareSession() async {
    final currentKey =
        LandPortalHelper.toTenDigitPortalMobile(widget.portalPhone ?? '');
    if (currentKey.isNotEmpty &&
        _lastActiveAccountKey != null &&
        _lastActiveAccountKey != currentKey) {
      try {
        await CookieManager.instance().deleteAllCookies();
        await WebStorageManager.instance().deleteAllData();
        _switchedAccountCleared = true;
      } catch (_) {}
    }
    if (currentKey.isNotEmpty) {
      _lastActiveAccountKey = currentKey;
    }
    if (mounted) {
      setState(() => _sessionPrepared = true);
    }
  }

  InAppWebViewSettings _buildSettings() {
    return InAppWebViewSettings(
      javaScriptEnabled: true,
      domStorageEnabled: true,
      useOnDownloadStart: true,
      supportMultipleWindows: true,
      javaScriptCanOpenWindowsAutomatically: true,
      useShouldOverrideUrlLoading: true,
      allowFileAccess: true,
      allowContentAccess: true,
      builtInZoomControls: true,
      displayZoomControls: false,
      preferredContentMode: _isDesktopMode
          ? UserPreferredContentMode.DESKTOP
          : UserPreferredContentMode.MOBILE,
      userAgent: _isDesktopMode ? _desktopUserAgent : null,
    );
  }

  Future<void> _updateNavState() async {
    final ctrl = _webViewController;
    if (ctrl == null || !mounted) return;
    final back = await ctrl.canGoBack();
    final forward = await ctrl.canGoForward();
    if (!mounted) return;
    setState(() {
      _canGoBack = back;
      _canGoForward = forward;
    });
  }

  Future<void> _runAutofill({bool manual = false}) async {
    final ctrl = _webViewController;
    if (ctrl == null || !_hasCredentials) return;

    final script = LandPortalHelper.buildLsgAutofillScript(
      mobile: widget.portalPhone ?? '',
      password: widget.portalPassword ?? '',
      onlyIfEmpty: !manual,
    );

    try {
      var result = await ctrl.evaluateJavascript(source: script);
      if (!mounted) return;

      var parsed = _parseAutofillResult(result);

      // স্লো নেটওয়ার্কে DOM দেরিতে রেন্ডার হলে একবার স্বয়ংক্রিয় রিট্রাই।
      if (!manual &&
          parsed?['mobileFilled'] != true &&
          parsed?['passwordFilled'] != true) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        result = await ctrl.evaluateJavascript(source: script);
        if (!mounted) return;
        parsed = _parseAutofillResult(result);
      }

      final mobileFilled = parsed?['mobileFilled'] == true;
      final passwordFilled = parsed?['passwordFilled'] == true;

      if (mobileFilled || passwordFilled) {
        _autofillDoneForCurrentLoginPage = true;
        final String baseMsg;
        if (mobileFilled && passwordFilled) {
          baseMsg = 'নম্বর ও পাসওয়ার্ড অটো-ফিল হয়েছে — ক্যাপচা দিয়ে লগইন করুন।';
        } else if (mobileFilled) {
          baseMsg = 'লগইন নম্বর অটো-ফিল হয়েছে — পাসওয়ার্ড ও ক্যাপচা দিয়ে লগইন করুন।';
        } else {
          baseMsg = 'পাসওয়ার্ড অটো-ফিল হয়েছে — নম্বর ও ক্যাপচা দিয়ে লগইন করুন।';
        }
        final msg = _switchedAccountCleared
            ? 'নতুন অ্যাকাউন্টের জন্য $baseMsg'
            : baseMsg;
        _switchedAccountCleared = false;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.emerald,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (manual) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('এই পেজে লগইন ইনপুট ফিল্ড পাওয়া যায়নি।'),
            backgroundColor: AppColors.amber,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (manual && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('অটো-ফিল চালানো যায়নি। ম্যানুয়ালি কপি করে ব্যবহার করুন।'),
            backgroundColor: AppColors.rose,
          ),
        );
      }
    }
  }

  Map<String, dynamic>? _parseAutofillResult(dynamic result) {
    if (result is String && result.trim().isNotEmpty) {
      final decoded = jsonDecode(result);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } else if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    return null;
  }

  Future<void> _toggleDesktopMode() async {
    final nextMode = !_isDesktopMode;
    setState(() => _isDesktopMode = nextMode);
    final ctrl = _webViewController;
    if (ctrl != null) {
      await ctrl.setSettings(settings: _buildSettings());
      await ctrl.reload();
    }
  }

  Future<void> _clearSessionAndReloadLogin() async {
    try {
      await CookieManager.instance().deleteAllCookies();
      await WebStorageManager.instance().deleteAllData();
    } catch (_) {}
    _autofillDoneForCurrentLoginPage = false;
    await _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(LandPortalHelper.lsgLoginUrl)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('পূর্বের সেশন পরিষ্কার করা হয়েছে।'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleDownload(
    DownloadStartRequest request, {
    InAppWebViewController? sourceController,
  }) async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final urlStr = request.url.toString();
      final scheme = Uri.tryParse(urlStr)?.scheme.toLowerCase() ?? '';
      Uint8List bytes;
      String? headerFileName;

      if (scheme == 'data') {
        bytes = UriData.fromUri(Uri.parse(urlStr)).contentAsBytes();
      } else if (scheme == 'blob') {
        final ctrl = sourceController ?? _webViewController;
        Uint8List? blobBytes;
        if (ctrl != null) {
          final res = await ctrl.callAsyncJavaScript(
            functionBody: '''
              const response = await fetch(blobUrl);
              const blob = await response.blob();
              return await new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.onloadend = () => resolve(reader.result);
                reader.onerror = reject;
                reader.readAsDataURL(blob);
              });
            ''',
            arguments: {'blobUrl': urlStr},
          );
          final dataUrl = res?.value?.toString();
          if (dataUrl != null && dataUrl.contains(',')) {
            if (dataUrl.toLowerCase().startsWith('data:text/html')) {
              throw Exception(
                'সেশন শেষ হয়ে গেছে বা ফাইলটি পাওয়া যায়নি (পুনরায় লগইন করে চেষ্টা করুন)।',
              );
            }
            blobBytes = base64Decode(dataUrl.split(',').last);
          }
        }
        if (blobBytes == null || blobBytes.isEmpty) {
          throw Exception('Blob ফাইল পড়া যায়নি।');
        }
        bytes = blobBytes;
      } else {
        final cookies = await CookieManager.instance().getCookies(url: request.url);
        final cookieHeader = cookies
            .map((c) => '${c.name}=${c.value}')
            .where((s) => s.length > 1)
            .join('; ');

        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 20);
        try {
          final httpReq = await client.getUrl(Uri.parse(urlStr));
          if (cookieHeader.isNotEmpty) {
            httpReq.headers.set(HttpHeaders.cookieHeader, cookieHeader);
          }
          if (_currentUrl.isNotEmpty) {
            httpReq.headers.set(HttpHeaders.refererHeader, _currentUrl);
          }
          if (request.userAgent != null && request.userAgent!.isNotEmpty) {
            httpReq.headers.set(HttpHeaders.userAgentHeader, request.userAgent!);
          }
          final httpRes = await httpReq.close().timeout(const Duration(seconds: 45));

          if (httpRes.statusCode >= 400) {
            throw Exception('সার্ভার ত্রুটি (${httpRes.statusCode})');
          }

          final respMime = httpRes.headers.contentType?.mimeType.toLowerCase() ?? '';
          final expectedMime = request.mimeType?.toLowerCase() ?? '';
          if (respMime == 'text/html' && !expectedMime.contains('html')) {
            throw Exception(
              'সেশন শেষ হয়ে গেছে বা ফাইলটি পাওয়া যায়নি (পুনরায় লগইন করে চেষ্টা করুন)।',
            );
          }

          headerFileName = LandPortalHelper.extractFileNameFromContentDisposition(
            httpRes.headers.value('content-disposition'),
          );

          final chunks = <int>[];
          await for (final data in httpRes.timeout(const Duration(seconds: 45))) {
            chunks.addAll(data);
          }
          bytes = Uint8List.fromList(chunks);
        } finally {
          client.close();
        }
      }

      if (bytes.isEmpty) {
        throw Exception('খালি ফাইল পাওয়া গেছে।');
      }

      final rawName = (headerFileName != null && headerFileName.isNotEmpty)
          ? headerFileName
          : (request.suggestedFilename?.trim().isNotEmpty == true
              ? request.suggestedFilename!.trim()
              : (Uri.tryParse(urlStr)?.pathSegments.lastOrNull ?? ''));

      final mime = request.mimeType?.toLowerCase() ?? '';
      final fallbackExt = mime.contains('png')
          ? 'png'
          : (mime.contains('jpeg') || mime.contains('jpg') ? 'jpg' : 'pdf');
      final fileName = LandPortalHelper.sanitizeFileName(
        rawName,
        fallbackExtension: fallbackExt,
      );
      final resolvedMime = _resolveMimeType(fileName, mime);

      // শেয়ার/খোলার জন্য একটি টেম্প কপি রাখা হয়।
      final tempDir = await getTemporaryDirectory();
      final shareDir = Directory(p.join(tempDir.path, 'portal_downloads'));
      if (!shareDir.existsSync()) {
        shareDir.createSync(recursive: true);
      }
      final shareFile = File(p.join(shareDir.path, fileName));
      await shareFile.writeAsBytes(bytes, flush: true);

      // সরাসরি ফোনের পাবলিক Download ফোল্ডারে সেভ করার চেষ্টা (MediaStore API 29+ / Public Downloads)।
      String savedLocationLabel = 'Download/$fileName';
      var savedToPublicDownloads = false;
      if (Platform.isAndroid) {
        try {
          final res = await _downloadChannel.invokeMethod<dynamic>(
            'saveToDownloads',
            {
              'fileName': fileName,
              'mimeType': resolvedMime,
              'bytes': bytes,
            },
          );
          if (res is Map && res['savedToPublicDownloads'] == true) {
            savedToPublicDownloads = true;
            final displayPath = res['displayPath']?.toString();
            if (displayPath != null && displayPath.isNotEmpty) {
              savedLocationLabel = displayPath;
            }
          }
        } catch (_) {}
      }

      if (!savedToPublicDownloads) {
        final exportDir = await BackupRepository.getExportDirectory();
        if (!exportDir.existsSync()) {
          exportDir.createSync(recursive: true);
        }
        final fallbackFile = _uniqueFile(exportDir, fileName);
        await fallbackFile.writeAsBytes(bytes, flush: true);
        savedLocationLabel = fallbackFile.path;
      }

      if (!mounted) return;
      _showDownloadedFileDialog(
        shareFile,
        fileName,
        bytes,
        savedLocationLabel: savedLocationLabel,
        savedToPublicDownloads: savedToPublicDownloads,
      );
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ডাউনলোড টাইমআউট হয়েছে। ইন্টারনেট যাচাই করে আবার চেষ্টা করুন।'),
          backgroundColor: AppColors.rose,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ডাউনলোড ব্যর্থ হয়েছে: $e'),
          backgroundColor: AppColors.rose,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  String _resolveMimeType(String fileName, String rawMime) {
    if (rawMime.isNotEmpty && rawMime != 'application/octet-stream') {
      return rawMime;
    }
    final ext = p.extension(fileName).toLowerCase();
    switch (ext) {
      case '.pdf':
        return 'application/pdf';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  File _uniqueFile(Directory dir, String fileName) {
    var candidate = File(p.join(dir.path, fileName));
    if (!candidate.existsSync()) return candidate;
    final base = p.basenameWithoutExtension(fileName);
    final ext = p.extension(fileName);
    var counter = 1;
    while (candidate.existsSync()) {
      candidate = File(p.join(dir.path, '${base}_$counter$ext'));
      counter++;
    }
    return candidate;
  }

  void _showDownloadedFileDialog(
    File shareFile,
    String fileName,
    Uint8List bytes, {
    required String savedLocationLabel,
    required bool savedToPublicDownloads,
  }) {
    final sizeStr = bytes.length >= 1024 * 1024
        ? '${(bytes.length / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '${(bytes.length / 1024).ceil()} KB';
    final ext = p.extension(fileName).toLowerCase().replaceAll('.', '');
    final fileType = ext == 'pdf' ? 'pdf' : 'image';
    final canAttachToDb = bytes.length <= 15 * 1024 * 1024;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: const Row(
          children: [
            Icon(Icons.download_done_rounded, color: AppColors.emerald),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'ডাউনলোড সম্পন্ন',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          savedToPublicDownloads
              ? '$fileName ($sizeStr)\nফোনের Download ফোল্ডারে সংরক্ষিত হয়েছে ($savedLocationLabel)।'
              : '$fileName ($sizeStr)\nসংরক্ষিত হয়েছে:\n$savedLocationLabel',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          if (widget.applicationId != null && canAttachToDb)
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_file_rounded, size: 16),
              label: const Text('আবেদনে যোগ করুন'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await ref
                    .read(applicationControllerProvider.notifier)
                    .addDocument(
                      applicationId: widget.applicationId!,
                      fileName: fileName,
                      fileType: fileType,
                      fileData: bytes,
                      fileSize: sizeStr,
                    );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"$fileName" আবেদনের ডকুমেন্টে যুক্ত হয়েছে।'),
                    backgroundColor: AppColors.emerald,
                  ),
                );
              },
            ),
          OutlinedButton.icon(
            icon: const Icon(Icons.share_outlined, size: 16),
            label: const Text('খুলুন / শেয়ার'),
            onPressed: () async {
              Navigator.pop(ctx);
              await SharePlus.instance.share(
                ShareParams(
                  files: [XFile(shareFile.path)],
                  text: fileName,
                ),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বন্ধ করুন'),
          ),
        ],
      ),
    );
  }

  void _showCredentialsSheet() {
    final rawPhone = widget.portalPhone ?? '';
    final tenDigit = LandPortalHelper.toTenDigitPortalMobile(rawPhone);
    final password = widget.portalPassword ?? '';
    var showPass = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.key_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'পোর্টাল লগইন তথ্য',
                      style: AppTypography.headingSmall
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('লগইন মোবাইল নম্বর (১০ ডিজিট)'),
                  subtitle: Text(
                    tenDigit.isNotEmpty
                        ? tenDigit
                        : (rawPhone.isNotEmpty ? rawPhone : 'দেওয়া হয়নি'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
                    onPressed: tenDigit.isEmpty && rawPhone.isEmpty
                        ? null
                        : () => AppLauncher.copyToClipboard(
                              context,
                              tenDigit.isNotEmpty ? tenDigit : rawPhone,
                              successMessage: 'লগইন নম্বর কপি করা হয়েছে',
                            ),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('পাসওয়ার্ড'),
                  subtitle: Text(
                    password.isEmpty
                        ? 'দেওয়া হয়নি'
                        : (showPass ? password : '•' * password.length),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (password.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            showPass
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () =>
                              setModalState(() => showPass = !showPass),
                        ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded,
                            color: AppColors.primary),
                        onPressed: password.isEmpty
                            ? null
                            : () => AppLauncher.copyToClipboard(
                                  context,
                                  password,
                                  successMessage: 'পাসওয়ার্ড কপি করা হয়েছে',
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                    label: const Text('পুনরায় অটো-ফিল করুন'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _runAutofill(manual: true);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<NavigationActionPolicy> _handleOverrideUrlLoading(
    NavigationAction navigationAction,
  ) async {
    final uri = navigationAction.request.url;
    if (uri == null) return NavigationActionPolicy.ALLOW;
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'http' ||
        scheme == 'https' ||
        scheme == 'about' ||
        scheme == 'blob' ||
        scheme == 'data') {
      return NavigationActionPolicy.ALLOW;
    }
    try {
      await launchUrl(
        Uri.parse(uri.toString()),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
    return NavigationActionPolicy.CANCEL;
  }

  Future<void> _openPopupWindow(CreateWindowAction action) async {
    InAppWebViewController? popupCtrl;
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.82,
          child: Column(
            children: [
              Container(
                color: AppColors.primarySurface,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.open_in_new_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'পোর্টাল পপআপ / প্রিন্ট',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.print_outlined, size: 19),
                      tooltip: 'প্রিন্ট / PDF',
                      onPressed: () => popupCtrl?.printCurrentPage(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: InAppWebView(
                  windowId: action.windowId,
                  initialSettings: _buildSettings(),
                  onWebViewCreated: (c) => popupCtrl = c,
                  onDownloadStartRequest: (c, req) =>
                      _handleDownload(req, sourceController: c),
                  onPrintRequest: (_, __, ___) async => false,
                  shouldOverrideUrlLoading: (_, nav) =>
                      _handleOverrideUrlLoading(nav),
                  onCloseWindow: (_) {
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppSpacing.xl),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.roseSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              size: 36,
              color: AppColors.rose,
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            'পোর্টাল লোড করা যায়নি',
            style: AppTypography.headingSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _pageErrorMessage ??
                'আপনার ইন্টারনেট সংযোগ অথবা সরকারি সার্ভার সাময়িকভাবে অনুপলব্ধ হতে পারে।',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('আবার চেষ্টা করুন'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  setState(() => _pageErrorMessage = null);
                  _webViewController?.reload();
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                label: const Text('Chrome-এ খুলুন'),
                onPressed: () {
                  AppLauncher.launchWeb(
                    context,
                    _currentUrl.isNotEmpty ? _currentUrl : widget.initialUrl,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hostLabel = Uri.tryParse(_currentUrl)?.host ?? 'land.gov.bd';
    final subtitleText = widget.applicantName != null &&
            widget.applicantName!.trim().isNotEmpty
        ? '${widget.applicantName!} • $hostLabel'
        : hostLabel;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ctrl = _webViewController;
        if (ctrl != null && await ctrl.canGoBack()) {
          await ctrl.goBack();
          await _updateNavState();
        } else if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0.5,
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ভূমি পোর্টাল (LSG)',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
              ),
              Text(
                subtitleText,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            if (_hasCredentials)
              IconButton(
                icon: const Icon(Icons.key_rounded, color: AppColors.primary),
                tooltip: 'লগইন তথ্য দেখুন / কপি করুন',
                onPressed: _showCredentialsSheet,
              ),
            if (_isDownloading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'autofill':
                    await _runAutofill(manual: true);
                  case 'reload':
                    setState(() => _pageErrorMessage = null);
                    await _webViewController?.reload();
                  case 'print':
                    await _webViewController?.printCurrentPage();
                  case 'desktop':
                    await _toggleDesktopMode();
                  case 'clear_session':
                    await _clearSessionAndReloadLogin();
                  case 'chrome':
                    if (!context.mounted) return;
                    await AppLauncher.launchWeb(
                      context,
                      _currentUrl.isNotEmpty ? _currentUrl : widget.initialUrl,
                    );
                }
              },
              itemBuilder: (ctx) => [
                if (_hasCredentials)
                  const PopupMenuItem(
                    value: 'autofill',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.auto_fix_high_rounded,
                          color: AppColors.primary),
                      title: Text('নম্বর ও পাসওয়ার্ড অটো-ফিল'),
                    ),
                  ),
                const PopupMenuItem(
                  value: 'reload',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.refresh_rounded),
                    title: Text('পুনরায় লোড করুন'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'print',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.print_outlined),
                    title: Text('পেজ প্রিন্ট / PDF সেভ'),
                  ),
                ),
                PopupMenuItem(
                  value: 'desktop',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _isDesktopMode
                          ? Icons.phone_android_rounded
                          : Icons.desktop_windows_rounded,
                    ),
                    title: Text(
                      _isDesktopMode ? 'মোবাইল ভিউ চালু করুন' : 'ডেস্কটপ ভিউ চালু করুন',
                    ),
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_session',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.logout_rounded, color: AppColors.amber),
                    title: Text('লগআউট / নতুন অ্যাকাউন্ট'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'chrome',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.open_in_browser_rounded),
                    title: Text('Chrome-এ খুলুন'),
                  ),
                ),
              ],
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: _progress > 0 && _progress < 1.0
                ? LinearProgressIndicator(
                    value: _progress,
                    minHeight: 3,
                    backgroundColor: AppColors.slate100,
                    color: AppColors.primary,
                  )
                : const SizedBox(height: 3),
          ),
        ),
        body: !_sessionPrepared
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
                    initialSettings: _buildSettings(),
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                    },
                    onLoadStart: (controller, url) {
                      final urlStr = url?.toString() ?? '';
                      if (mounted) {
                        setState(() {
                          _currentUrl = urlStr;
                          _pageErrorMessage = null;
                          if (urlStr.contains('/login')) {
                            _autofillDoneForCurrentLoginPage = false;
                          }
                        });
                      }
                      _updateNavState();
                    },
                    onProgressChanged: (controller, progress) {
                      if (mounted) {
                        setState(() => _progress = progress / 100.0);
                      }
                    },
                    onLoadStop: (controller, url) async {
                      final urlStr = url?.toString() ?? '';
                      if (mounted) {
                        setState(() => _currentUrl = urlStr);
                      }
                      await _updateNavState();

                      if (urlStr.contains('/login') &&
                          !_autofillDoneForCurrentLoginPage &&
                          _hasCredentials) {
                        await Future.delayed(const Duration(milliseconds: 300));
                        await _runAutofill();
                      }
                    },
                    onReceivedError: (controller, request, error) {
                      if ((request.isForMainFrame ?? false) &&
                          error.type != WebResourceErrorType.CANCELLED &&
                          mounted) {
                        setState(() {
                          _pageErrorMessage = error.description.isNotEmpty
                              ? error.description
                              : 'ওয়েবপেজ লোড করতে সমস্যা হয়েছে।';
                        });
                      }
                    },
                    onDownloadStartRequest: (controller, req) async {
                      await _handleDownload(req, sourceController: controller);
                    },
                    onPrintRequest: (controller, url, printJobController) async {
                      return false;
                    },
                    onCreateWindow: (controller, createWindowAction) async {
                      final targetUrl = createWindowAction.request.url;
                      if (createWindowAction.windowId > 0) {
                        await _openPopupWindow(createWindowAction);
                        return true;
                      }
                      if (targetUrl != null) {
                        await controller.loadUrl(
                          urlRequest: createWindowAction.request,
                        );
                        return true;
                      }
                      return false;
                    },
                    shouldOverrideUrlLoading: (_, nav) =>
                        _handleOverrideUrlLoading(nav),
                  ),
                  if (_pageErrorMessage != null) _buildErrorOverlay(),
                ],
              ),
        bottomNavigationBar: SafeArea(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  onPressed: _canGoBack
                      ? () async {
                          await _webViewController?.goBack();
                          await _updateNavState();
                        }
                      : null,
                  tooltip: 'পেছনে',
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  onPressed: _canGoForward
                      ? () async {
                          await _webViewController?.goForward();
                          await _updateNavState();
                        }
                      : null,
                  tooltip: 'সামনে',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: () {
                    setState(() => _pageErrorMessage = null);
                    _webViewController?.reload();
                  },
                  tooltip: 'রিফ্রেশ',
                ),
                const Spacer(),
                if (_hasCredentials)
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                    label: Text(
                      widget.portalPhone != null &&
                              widget.portalPhone!.trim().isNotEmpty
                          ? BengaliDigits.toBengali(
                              LandPortalHelper.toTenDigitPortalMobile(
                                widget.portalPhone!,
                              ),
                            )
                          : 'অটো-ফিল',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => _runAutofill(manual: true),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
