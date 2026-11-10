import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
/// - ভিন্ন আবেদনকারীর অ্যাকাউন্টে ঢুকলে পূর্বের সেশন/কুকি স্বয়ংক্রিয়ভাবে পরিষ্কার করে (অ্যাপ রি-স্টার্টের পরও)।
/// - লগইন পেজ লোড হলে সংরক্ষিত মোবাইল নম্বর (১০ ডিজিট) ও পাসওয়ার্ড অটো-ফিল করে।
/// - লগইনের পর ফাইল আপলোড, স্ট্রিমিং HTTP/Blob/Data PDF ডাউনলোড, প্রিন্ট, পপআপ ও পেমেন্ট গেটওয়ে সাপোর্ট করে।
/// - WebView রেন্ডারার ক্র্যাশ, ধীর সার্ভার, SSL/HTTP ত্রুটি এবং ব্যাক বাটন হ্যাং থেকে নিরাপদ পুনরুদ্ধার দেয়।
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

  static const int _maxDownloadBytes = 50 * 1024 * 1024;
  static const int _maxDbAttachmentBytes = 15 * 1024 * 1024;
  static const Duration _sessionClearTimeout = Duration(seconds: 3);
  static const Duration _pageLoadWatchdogDuration = Duration(seconds: 20);
  static const Duration _totalDownloadTimeout = Duration(seconds: 90);
  static const Duration _blobFetchTimeout = Duration(seconds: 25);

  /// সর্বশেষ কোন নম্বরে পোর্টাল সেশন চালু ছিল তা ইন-মেমোরি এবং ডিস্কে ট্র্যাক করে,
  /// যাতে অ্যাপ বন্ধ করে চালু করলেও ভিন্ন আবেদনকারীর সেশন মিশে না যায়।
  static String? _lastActiveAccountKey;

  InAppWebViewController? _webViewController;
  Timer? _loadWatchdogTimer;
  int _webViewInstanceKey = 0;

  double _progress = 0;
  String _currentUrl = '';
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isDesktopMode = false;
  bool _autofillDoneForCurrentLoginPage = false;
  bool _isAutofilling = false;
  bool _isDownloading = false;
  bool _isPopupOpen = false;
  bool _sessionPrepared = false;
  bool _switchedAccountCleared = false;
  bool _renderProcessCrashed = false;
  bool _webViewUnavailable = false;
  bool _showSlowLoadBanner = false;
  bool _isDisposed = false;
  String? _pageErrorMessage;

  bool get _hasCredentials =>
      (widget.portalPhone != null && widget.portalPhone!.trim().isNotEmpty) ||
      (widget.portalPassword != null && widget.portalPassword!.trim().isNotEmpty);

  bool get _canControlWebView =>
      !_isDisposed &&
      mounted &&
      !_renderProcessCrashed &&
      !_webViewUnavailable &&
      _webViewController != null;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
    _prepareSession();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _loadWatchdogTimer?.cancel();
    _loadWatchdogTimer = null;
    _webViewController = null;
    super.dispose();
  }

  Future<File?> _getAccountMarkerFile() async {
    try {
      final dir = await getApplicationSupportDirectory()
          .timeout(const Duration(seconds: 2));
      return File(p.join(dir.path, 'last_portal_account.txt'));
    } catch (_) {
      return null;
    }
  }

  Future<String?> _readPersistedAccountKey() async {
    if (_lastActiveAccountKey != null) return _lastActiveAccountKey;
    try {
      final file = await _getAccountMarkerFile();
      if (file != null && await file.exists()) {
        final raw = (await file.readAsString()).trim();
        if (raw.isNotEmpty) {
          _lastActiveAccountKey = raw;
          return raw;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _writePersistedAccountKey(String key) async {
    _lastActiveAccountKey = key;
    try {
      final file = await _getAccountMarkerFile();
      if (file != null) {
        await file.writeAsString(key, flush: true);
      }
    } catch (_) {}
  }

  Future<void> _clearPersistedAccountKey() async {
    _lastActiveAccountKey = null;
    try {
      final file = await _getAccountMarkerFile();
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<void> _clearWebStorageAndCookiesSafely() async {
    try {
      await Future.wait([
        CookieManager.instance().deleteAllCookies(),
        WebStorageManager.instance().deleteAllData(),
      ]).timeout(_sessionClearTimeout);
    } catch (_) {}
  }

  Future<void> _prepareSession() async {
    try {
      if (kIsWeb ||
          !(Platform.isAndroid ||
              Platform.isIOS ||
              Platform.isMacOS ||
              Platform.isWindows)) {
        _webViewUnavailable = true;
        return;
      }

      // Android System WebView অক্ষম বা অনুপলব্ধ হলে আগেই নিরাপদে শনাক্ত করা।
      if (Platform.isAndroid) {
        try {
          await InAppWebViewController.getDefaultUserAgent()
              .timeout(const Duration(seconds: 2));
        } on MissingPluginException {
          _webViewUnavailable = true;
          return;
        } on PlatformException {
          _webViewUnavailable = true;
          return;
        } catch (_) {
          // টাইমআউট হলে WebView মাউন্ট করার সুযোগ দেওয়া হয়।
        }
      }

      final currentKey =
          LandPortalHelper.toTenDigitPortalMobile(widget.portalPhone ?? '');
      final previousKey = await _readPersistedAccountKey();

      final shouldClearPreviousSession = previousKey != null &&
          (currentKey.isEmpty || previousKey != currentKey);

      if (shouldClearPreviousSession) {
        await _clearWebStorageAndCookiesSafely();
        _switchedAccountCleared = true;
      }

      if (currentKey.isNotEmpty) {
        await _writePersistedAccountKey(currentKey);
      } else if (shouldClearPreviousSession) {
        await _clearPersistedAccountKey();
      }
    } catch (_) {
      // সেশন প্রিপেয়ার ব্যর্থ হলেও স্ক্রিন কখনো ইনফিনিট স্পিনারে আটকাবে না।
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _sessionPrepared = true);
      }
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
      useOnRenderProcessGone: true,
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

  void _startLoadWatchdog() {
    _loadWatchdogTimer?.cancel();
    _loadWatchdogTimer = Timer(_pageLoadWatchdogDuration, () {
      if (!mounted || _isDisposed) return;
      if (_progress < 0.95 && _pageErrorMessage == null && !_renderProcessCrashed) {
        setState(() => _showSlowLoadBanner = true);
      }
    });
  }

  void _stopLoadWatchdog() {
    _loadWatchdogTimer?.cancel();
    _loadWatchdogTimer = null;
    if (_showSlowLoadBanner && mounted && !_isDisposed) {
      setState(() => _showSlowLoadBanner = false);
    }
  }

  Future<void> _updateNavState() async {
    final ctrl = _webViewController;
    if (ctrl == null || !_canControlWebView) return;
    try {
      final back = await ctrl
          .canGoBack()
          .timeout(const Duration(milliseconds: 500), onTimeout: () => false);
      final forward = await ctrl
          .canGoForward()
          .timeout(const Duration(milliseconds: 500), onTimeout: () => false);
      if (!mounted || _isDisposed) return;
      setState(() {
        _canGoBack = back;
        _canGoForward = forward;
      });
    } catch (_) {}
  }

  Future<void> _runAutofill({bool manual = false}) async {
    if (_isAutofilling || !_canControlWebView || !_hasCredentials) return;
    final ctrl = _webViewController;
    if (ctrl == null) return;

    _isAutofilling = true;
    final script = LandPortalHelper.buildLsgAutofillScript(
      mobile: widget.portalPhone ?? '',
      password: widget.portalPassword ?? '',
      onlyIfEmpty: !manual,
    );

    try {
      var result = await ctrl
          .evaluateJavascript(source: script)
          .timeout(const Duration(seconds: 4));
      if (!mounted || _isDisposed) return;

      var parsed = _parseAutofillResult(result);

      // স্লো নেটওয়ার্কে বা রেডিও বাটন ক্লিকের পর DOM দেরিতে রেন্ডার হলে সর্বোচ্চ ২ বার রিট্রাই।
      if (!manual &&
          parsed?['mobileFilled'] != true &&
          parsed?['passwordFilled'] != true) {
        for (final delayMs in const [500, 700]) {
          await Future.delayed(Duration(milliseconds: delayMs));
          if (!_canControlWebView) return;
          final currentCtrl = _webViewController;
          if (currentCtrl == null) return;
          result = await currentCtrl
              .evaluateJavascript(source: script)
              .timeout(const Duration(seconds: 4));
          if (!mounted || _isDisposed) return;
          parsed = _parseAutofillResult(result);
          if (parsed?['mobileFilled'] == true ||
              parsed?['passwordFilled'] == true) {
            break;
          }
        }
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
        _showSnack(msg, color: AppColors.emerald, seconds: 3);
      } else if (manual) {
        _showSnack(
          'এই পেজে লগইন ইনপুট ফিল্ড পাওয়া যায়নি।',
          color: AppColors.amber,
        );
      }
    } catch (_) {
      if (manual && mounted && !_isDisposed) {
        _showSnack(
          'অটো-ফিল চালানো যায়নি। উপরে চাবি আইকন থেকে কপি করে ব্যবহার করুন।',
          color: AppColors.rose,
        );
      }
    } finally {
      _isAutofilling = false;
    }
  }

  Map<String, dynamic>? _parseAutofillResult(dynamic result) {
    try {
      if (result is String && result.trim().isNotEmpty) {
        final decoded = jsonDecode(result);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } else if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
    } catch (_) {}
    return null;
  }

  void _showSnack(
    String message, {
    Color? color,
    int seconds = 3,
  }) {
    if (!mounted || _isDisposed) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: seconds),
      ),
    );
  }

  Future<void> _reloadOrRecoverWebView() async {
    if (!mounted || _isDisposed) return;
    if (_renderProcessCrashed) {
      setState(() {
        _renderProcessCrashed = false;
        _pageErrorMessage = null;
        _showSlowLoadBanner = false;
        _progress = 0;
        _webViewController = null;
        _webViewInstanceKey++;
      });
      return;
    }

    setState(() {
      _pageErrorMessage = null;
      _showSlowLoadBanner = false;
    });

    final ctrl = _webViewController;
    if (ctrl == null) {
      setState(() => _webViewInstanceKey++);
      return;
    }

    try {
      await ctrl.reload().timeout(const Duration(seconds: 4));
    } catch (_) {
      if (mounted && !_isDisposed) {
        setState(() {
          _webViewController = null;
          _webViewInstanceKey++;
        });
      }
    }
  }

  Future<void> _toggleDesktopMode() async {
    final nextMode = !_isDesktopMode;
    setState(() => _isDesktopMode = nextMode);
    final ctrl = _webViewController;
    if (ctrl == null || !_canControlWebView) return;
    try {
      await ctrl.setSettings(settings: _buildSettings());
      if (!_canControlWebView) return;
      await ctrl.reload();
    } catch (_) {
      await _reloadOrRecoverWebView();
    }
  }

  Future<void> _clearSessionAndReloadLogin() async {
    await _clearWebStorageAndCookiesSafely();
    _autofillDoneForCurrentLoginPage = false;
    if (!_canControlWebView) return;
    try {
      await _webViewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri(LandPortalHelper.lsgLoginUrl)),
      );
      _showSnack('পূর্বের সেশন পরিষ্কার করা হয়েছে।');
    } catch (_) {
      await _reloadOrRecoverWebView();
    }
  }

  Future<File> _prepareTempShareFile(String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final shareDir = Directory(p.join(tempDir.path, 'portal_downloads'));
    if (!await shareDir.exists()) {
      await shareDir.create(recursive: true);
    }
    return File(p.join(shareDir.path, fileName));
  }

  Future<File> _uniqueFileAsync(Directory dir, String fileName) async {
    var candidate = File(p.join(dir.path, fileName));
    if (!await candidate.exists()) return candidate;
    final base = p.basenameWithoutExtension(fileName);
    final ext = p.extension(fileName);
    var counter = 1;
    while (await candidate.exists()) {
      candidate = File(p.join(dir.path, '${base}_$counter$ext'));
      counter++;
    }
    return candidate;
  }

  Future<void> _handleDownload(
    DownloadStartRequest request, {
    InAppWebViewController? sourceController,
  }) async {
    if (_isDownloading || !mounted || _isDisposed) return;
    setState(() => _isDownloading = true);

    try {
      final urlStr = request.url.toString();
      final parsedUri = Uri.tryParse(urlStr);
      final scheme = parsedUri?.scheme.toLowerCase() ?? '';
      String? headerFileName;
      late final File tempDownloadFile;
      var fileSizeBytes = 0;

      if (scheme == 'data') {
        final bytes = UriData.fromUri(Uri.parse(urlStr)).contentAsBytes();
        if (bytes.isEmpty) {
          throw Exception('খালি ফাইল পাওয়া গেছে।');
        }
        if (bytes.length > _maxDownloadBytes) {
          throw Exception('ফাইলটি ৫০ MB-এর চেয়ে বড় হওয়ায় ইন-অ্যাপে ডাউনলোড করা যাচ্ছে না।');
        }
        fileSizeBytes = bytes.length;
        final rawName = request.suggestedFilename?.trim().isNotEmpty == true
            ? request.suggestedFilename!.trim()
            : '';
        final mime = request.mimeType?.toLowerCase() ?? '';
        final fileName = LandPortalHelper.sanitizeFileName(
          rawName,
          fallbackExtension: _guessExtensionFromMime(mime),
        );
        tempDownloadFile = await _prepareTempShareFile(fileName);
        await tempDownloadFile.writeAsBytes(bytes, flush: true);
      } else if (scheme == 'blob') {
        final ctrl = sourceController ?? _webViewController;
        Uint8List? blobBytes;
        if (ctrl != null) {
          final res = await ctrl
              .callAsyncJavaScript(
                functionBody: '''
                  const response = await fetch(blobUrl);
                  const blob = await response.blob();
                  if (blob.size > maxBytes) {
                    return 'ERR_TOO_LARGE:' + blob.size;
                  }
                  return await new Promise((resolve, reject) => {
                    const reader = new FileReader();
                    reader.onloadend = () => resolve(reader.result);
                    reader.onerror = reject;
                    reader.readAsDataURL(blob);
                  });
                ''',
                arguments: {
                  'blobUrl': urlStr,
                  'maxBytes': _maxDownloadBytes,
                },
              )
              .timeout(_blobFetchTimeout);

          final dataUrl = res?.value?.toString();
          if (dataUrl != null) {
            if (dataUrl.startsWith('ERR_TOO_LARGE:')) {
              throw Exception('ফাইলটি ৫০ MB-এর চেয়ে বড় হওয়ায় ইন-অ্যাপে পড়া যাচ্ছে না।');
            }
            if (dataUrl.contains(',')) {
              if (dataUrl.toLowerCase().startsWith('data:text/html')) {
                throw Exception(
                  'সেশন শেষ হয়ে গেছে বা ফাইলটি পাওয়া যায়নি (পুনরায় লগইন করে চেষ্টা করুন)।',
                );
              }
              blobBytes = base64Decode(dataUrl.split(',').last);
            }
          }
        }
        if (blobBytes == null || blobBytes.isEmpty) {
          throw Exception('Blob ফাইল পড়া যায়নি।');
        }
        fileSizeBytes = blobBytes.length;
        final rawName = request.suggestedFilename?.trim().isNotEmpty == true
            ? request.suggestedFilename!.trim()
            : '';
        final mime = request.mimeType?.toLowerCase() ?? '';
        final fileName = LandPortalHelper.sanitizeFileName(
          rawName,
          fallbackExtension: _guessExtensionFromMime(mime),
        );
        tempDownloadFile = await _prepareTempShareFile(fileName);
        await tempDownloadFile.writeAsBytes(blobBytes, flush: true);
      } else {
        if (parsedUri == null ||
            (scheme != 'http' && scheme != 'https')) {
          throw Exception('অসমর্থিত ডাউনলোড লিংক।');
        }

        final cookies = await CookieManager.instance()
            .getCookies(url: request.url)
            .timeout(const Duration(seconds: 3), onTimeout: () => const []);
        final cookieHeader = cookies
            .map((c) => '${c.name}=${c.value}')
            .where((s) => s.length > 1)
            .join('; ');

        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 20);
        IOSink? sink;
        File? streamingTempFile;
        try {
          final httpReq = await client
              .getUrl(parsedUri)
              .timeout(const Duration(seconds: 20));
          if (cookieHeader.isNotEmpty) {
            httpReq.headers.set(HttpHeaders.cookieHeader, cookieHeader);
          }
          if (_currentUrl.isNotEmpty) {
            httpReq.headers.set(HttpHeaders.refererHeader, _currentUrl);
          }
          if (request.userAgent != null && request.userAgent!.isNotEmpty) {
            httpReq.headers.set(HttpHeaders.userAgentHeader, request.userAgent!);
          }

          final httpRes =
              await httpReq.close().timeout(const Duration(seconds: 45));

          if (httpRes.statusCode >= 400) {
            throw Exception('সার্ভার ত্রুটি (${httpRes.statusCode})');
          }

          final respMime =
              httpRes.headers.contentType?.mimeType.toLowerCase() ?? '';
          final expectedMime = request.mimeType?.toLowerCase() ?? '';
          if (respMime == 'text/html' && !expectedMime.contains('html')) {
            throw Exception(
              'সেশন শেষ হয়ে গেছে বা ফাইলটি পাওয়া যায়নি (পুনরায় লগইন করে চেষ্টা করুন)।',
            );
          }

          if (httpRes.contentLength > _maxDownloadBytes) {
            throw Exception('ফাইলটি ৫০ MB-এর চেয়ে বড়। Chrome দিয়ে ডাউনলোড করুন।');
          }

          headerFileName =
              LandPortalHelper.extractFileNameFromContentDisposition(
            httpRes.headers.value('content-disposition'),
          );

          final rawName = (headerFileName != null && headerFileName.isNotEmpty)
              ? headerFileName
              : (request.suggestedFilename?.trim().isNotEmpty == true
                  ? request.suggestedFilename!.trim()
                  : (parsedUri.pathSegments.lastOrNull ?? ''));
          final mime = request.mimeType?.toLowerCase() ?? respMime;
          final fileName = LandPortalHelper.sanitizeFileName(
            rawName,
            fallbackExtension: _guessExtensionFromMime(mime),
          );

          streamingTempFile = await _prepareTempShareFile(fileName);
          sink = streamingTempFile.openWrite();

          await (() async {
            await for (final data
                in httpRes.timeout(const Duration(seconds: 45))) {
              fileSizeBytes += data.length;
              if (fileSizeBytes > _maxDownloadBytes) {
                throw Exception(
                  'ফাইলটি ৫০ MB সীমা অতিক্রম করেছে। Chrome দিয়ে ডাউনলোড করুন।',
                );
              }
              sink!.add(data);
            }
            await sink!.flush();
          })()
              .timeout(_totalDownloadTimeout);

          tempDownloadFile = streamingTempFile;
        } catch (_) {
          try {
            await sink?.close();
          } catch (_) {}
          try {
            if (streamingTempFile != null && await streamingTempFile.exists()) {
              await streamingTempFile.delete();
            }
          } catch (_) {}
          rethrow;
        } finally {
          try {
            await sink?.close();
          } catch (_) {}
          client.close();
        }
      }

      if (fileSizeBytes <= 0 || !await tempDownloadFile.exists()) {
        throw Exception('খালি ফাইল পাওয়া গেছে।');
      }

      final fileName = p.basename(tempDownloadFile.path);
      final mime = request.mimeType?.toLowerCase() ?? '';
      final resolvedMime = _resolveMimeType(fileName, mime);

      // সরাসরি ফোনের পাবলিক Download ফোল্ডারে সেভ করার চেষ্টা (filePath দিয়ে, যাতে Binder/RAM চাপ না পড়ে)।
      String savedLocationLabel = 'Download/$fileName';
      var savedToPublicDownloads = false;
      if (Platform.isAndroid) {
        try {
          final res = await _downloadChannel.invokeMethod<dynamic>(
            'saveToDownloads',
            {
              'fileName': fileName,
              'mimeType': resolvedMime,
              'filePath': tempDownloadFile.path,
            },
          ).timeout(const Duration(seconds: 25));
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
        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }
        final fallbackFile = await _uniqueFileAsync(exportDir, fileName);
        await tempDownloadFile.copy(fallbackFile.path);
        savedLocationLabel = fallbackFile.path;
      }

      if (!mounted || _isDisposed) return;
      _showDownloadedFileDialog(
        tempDownloadFile,
        fileName,
        fileSizeBytes,
        savedLocationLabel: savedLocationLabel,
        savedToPublicDownloads: savedToPublicDownloads,
      );
    } on TimeoutException {
      _showSnack(
        'ডাউনলোড টাইমআউট হয়েছে। ইন্টারনেট যাচাই করে আবার চেষ্টা করুন।',
        color: AppColors.rose,
      );
    } catch (e) {
      _showSnack('ডাউনলোড ব্যর্থ হয়েছে: $e', color: AppColors.rose);
    } finally {
      if (mounted && !_isDisposed) setState(() => _isDownloading = false);
    }
  }

  String _guessExtensionFromMime(String mime) {
    if (mime.contains('png')) return 'png';
    if (mime.contains('jpeg') || mime.contains('jpg')) return 'jpg';
    return 'pdf';
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

  void _showDownloadedFileDialog(
    File shareFile,
    String fileName,
    int fileSizeBytes, {
    required String savedLocationLabel,
    required bool savedToPublicDownloads,
  }) {
    final sizeStr = fileSizeBytes >= 1024 * 1024
        ? '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '${(fileSizeBytes / 1024).ceil()} KB';
    final ext = p.extension(fileName).toLowerCase().replaceAll('.', '');
    final fileType = ext == 'pdf' ? 'pdf' : 'image';
    final canAttachToDb = fileSizeBytes <= _maxDbAttachmentBytes;

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
                try {
                  final bytes = await shareFile.readAsBytes();
                  await ref
                      .read(applicationControllerProvider.notifier)
                      .addDocument(
                        applicationId: widget.applicationId!,
                        fileName: fileName,
                        fileType: fileType,
                        fileData: bytes,
                        fileSize: sizeStr,
                      );
                  _showSnack(
                    '"$fileName" আবেদনের ডকুমেন্টে যুক্ত হয়েছে।',
                    color: AppColors.emerald,
                  );
                } catch (e) {
                  _showSnack(
                    'ডকুমেন্ট যুক্ত করা যায়নি: $e',
                    color: AppColors.rose,
                  );
                }
              },
            ),
          OutlinedButton.icon(
            icon: const Icon(Icons.share_outlined, size: 16),
            label: const Text('খুলুন / শেয়ার'),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await SharePlus.instance.share(
                  ShareParams(
                    files: [XFile(shareFile.path)],
                    text: fileName,
                  ),
                );
              } catch (e) {
                _showSnack('ফাইল শেয়ার করা যায়নি: $e', color: AppColors.rose);
              }
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
    final urlStr = uri.toString();
    final scheme = uri.scheme.toLowerCase();
    if (LandPortalHelper.isInternalWebScheme(scheme)) {
      return NavigationActionPolicy.ALLOW;
    }

    try {
      final parsed = Uri.tryParse(urlStr);
      if (parsed != null) {
        final launched = await launchUrl(
          parsed,
          mode: LaunchMode.externalApplication,
        );
        if (launched) {
          return NavigationActionPolicy.CANCEL;
        }
      }
    } catch (_) {}

    // `intent://` লিংকের জন্য fallback HTTPS/HTTP URL থাকলে সেটি লোড করার চেষ্টা।
    final fallbackUrl = LandPortalHelper.extractIntentFallbackUrl(urlStr);
    if (fallbackUrl != null && _canControlWebView) {
      try {
        await _webViewController?.loadUrl(
          urlRequest: URLRequest(url: WebUri(fallbackUrl)),
        );
      } catch (_) {}
    }
    return NavigationActionPolicy.CANCEL;
  }

  Future<void> _openPopupWindow(CreateWindowAction action) async {
    if (!mounted || _isDisposed || _isPopupOpen) return;
    _isPopupOpen = true;
    InAppWebViewController? popupCtrl;
    try {
      await showDialog(
        context: context,
        builder: (ctx) {
          final availableHeight =
              (MediaQuery.sizeOf(ctx).height -
                      MediaQuery.viewInsetsOf(ctx).bottom) *
                  0.82;
          return Dialog(
            insetPadding: const EdgeInsets.all(12),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: SizedBox(
              height: availableHeight.clamp(240.0, 760.0),
              child: Column(
                children: [
                  Container(
                    color: AppColors.primarySurface,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                          onPressed: () async {
                            try {
                              await popupCtrl?.printCurrentPage();
                            } catch (_) {}
                          },
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
                      onPermissionRequest: (_, request) async =>
                          PermissionResponse(
                        resources: request.resources,
                        action: PermissionResponseAction.GRANT,
                      ),
                      onRenderProcessGone: (_, __) {
                        popupCtrl = null;
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      onCloseWindow: (_) {
                        popupCtrl = null;
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      popupCtrl = null;
      _isPopupOpen = false;
    }
  }

  Widget _buildSlowLoadBanner() {
    return Material(
      color: AppColors.amberSurface,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.hourglass_bottom_rounded,
                size: 18, color: AppColors.amberDark),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'সার্ভার থেকে সাড়া পেতে দেরি হচ্ছে...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.amberDark,
                ),
              ),
            ),
            TextButton(
              onPressed: _reloadOrRecoverWebView,
              child: const Text('রিলোড', style: TextStyle(fontSize: 12)),
            ),
            TextButton(
              onPressed: () {
                AppLauncher.launchWeb(
                  context,
                  _currentUrl.isNotEmpty ? _currentUrl : widget.initialUrl,
                );
              },
              child: const Text('Chrome', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay({bool unavailableOnly = false}) {
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
            child: Icon(
              unavailableOnly
                  ? Icons.web_asset_off_rounded
                  : Icons.wifi_off_rounded,
              size: 36,
              color: AppColors.rose,
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            unavailableOnly
                ? 'ইন-অ্যাপ ব্রাউজার চালু করা যায়নি'
                : 'পোর্টাল লোড করা যায়নি',
            style: AppTypography.headingSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            unavailableOnly
                ? 'এই ডিভাইসে Android System WebView অক্ষম বা অনুপলব্ধ। নিচের বাটন থেকে Chrome-এ খুলুন (উপরে চাবি আইকন থেকে নম্বর ও পাসওয়ার্ড কপি করতে পারবেন)।'
                : (_pageErrorMessage ??
                    'আপনার ইন্টারনেট সংযোগ অথবা সরকারি সার্ভার সাময়িকভাবে অনুপলব্ধ হতে পারে।'),
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (!unavailableOnly)
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('আবার চেষ্টা করুন'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _reloadOrRecoverWebView,
                ),
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

  Future<void> _handleBackNavigation() async {
    final ctrl = _webViewController;
    if (ctrl != null && _canControlWebView) {
      try {
        final canBack = await ctrl
            .canGoBack()
            .timeout(const Duration(milliseconds: 500));
        if (canBack) {
          await ctrl.goBack().timeout(const Duration(milliseconds: 800));
          await _updateNavState();
          return;
        }
      } catch (_) {}
    }
    if (mounted && !_isDisposed) {
      Navigator.of(context).pop();
    }
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
        await _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0.5,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'বন্ধ করুন',
            onPressed: () => Navigator.of(context).pop(),
          ),
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
                    await _reloadOrRecoverWebView();
                  case 'print':
                    try {
                      await _webViewController?.printCurrentPage();
                    } catch (_) {
                      _showSnack('প্রিন্ট চালু করা যায়নি।', color: AppColors.rose);
                    }
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
            : _webViewUnavailable
                ? _buildErrorOverlay(unavailableOnly: true)
                : Column(
                    children: [
                      if (_showSlowLoadBanner) _buildSlowLoadBanner(),
                      Expanded(
                        child: Stack(
                          children: [
                            if (!_renderProcessCrashed)
                              InAppWebView(
                                key: ValueKey(_webViewInstanceKey),
                                initialUrlRequest: URLRequest(
                                  url: WebUri(widget.initialUrl),
                                ),
                                initialSettings: _buildSettings(),
                                onWebViewCreated: (controller) {
                                  if (_isDisposed) return;
                                  _webViewController = controller;
                                },
                                onLoadStart: (controller, url) {
                                  final urlStr = url?.toString() ?? '';
                                  _startLoadWatchdog();
                                  if (mounted && !_isDisposed) {
                                    setState(() {
                                      _currentUrl = urlStr;
                                      _pageErrorMessage = null;
                                      _showSlowLoadBanner = false;
                                      if (urlStr.contains('/login')) {
                                        _autofillDoneForCurrentLoginPage = false;
                                      }
                                    });
                                  }
                                  _updateNavState();
                                },
                                onProgressChanged: (controller, progress) {
                                  if (progress >= 95) {
                                    _stopLoadWatchdog();
                                  }
                                  if (mounted && !_isDisposed) {
                                    setState(() => _progress = progress / 100.0);
                                  }
                                },
                                onLoadStop: (controller, url) async {
                                  _stopLoadWatchdog();
                                  final urlStr = url?.toString() ?? '';
                                  if (mounted && !_isDisposed) {
                                    setState(() => _currentUrl = urlStr);
                                  }
                                  await _updateNavState();
                                  if (!mounted || _isDisposed) return;

                                  if (urlStr.contains('/login') &&
                                      !_autofillDoneForCurrentLoginPage &&
                                      _hasCredentials) {
                                    await Future.delayed(
                                      const Duration(milliseconds: 300),
                                    );
                                    if (!mounted || _isDisposed) return;
                                    await _runAutofill();
                                  }
                                },
                                onReceivedError: (controller, request, error) {
                                  if ((request.isForMainFrame ?? false) &&
                                      error.type !=
                                          WebResourceErrorType.CANCELLED &&
                                      mounted &&
                                      !_isDisposed) {
                                    _stopLoadWatchdog();
                                    setState(() {
                                      _pageErrorMessage =
                                          error.description.isNotEmpty
                                              ? error.description
                                              : 'ওয়েবপেজ লোড করতে সমস্যা হয়েছে।';
                                    });
                                  }
                                },
                                onReceivedHttpError:
                                    (controller, request, errorResponse) {
                                  final code = errorResponse.statusCode ?? 0;
                                  if ((request.isForMainFrame ?? false) &&
                                      code >= 500 &&
                                      mounted &&
                                      !_isDisposed) {
                                    _stopLoadWatchdog();
                                    setState(() {
                                      _pageErrorMessage =
                                          'সরকারি সার্ভার সাময়িকভাবে ব্যস্ত বা অনুপলব্ধ (HTTP $code)। কিছুক্ষণ পর আবার চেষ্টা করুন।';
                                    });
                                  }
                                },
                                onReceivedServerTrustAuthRequest:
                                    (controller, challenge) async {
                                  if (mounted && !_isDisposed) {
                                    _stopLoadWatchdog();
                                    setState(() {
                                      _pageErrorMessage =
                                          'সার্ভারের নিরাপত্তা সনদ (SSL) যাচাই করা যায়নি। ফোনের তারিখ/সময় ঠিক আছে কি না দেখুন অথবা Chrome-এ খুলুন।';
                                    });
                                  }
                                  return ServerTrustAuthResponse(
                                    action: ServerTrustAuthResponseAction.CANCEL,
                                  );
                                },
                                onRenderProcessGone: (controller, detail) {
                                  _stopLoadWatchdog();
                                  _webViewController = null;
                                  if (mounted && !_isDisposed) {
                                    setState(() {
                                      _renderProcessCrashed = true;
                                      _pageErrorMessage =
                                          'ব্রাউজার পেজটি মেমোরির কারণে বন্ধ হয়ে গেছে। আবার চেষ্টা করুন বা Chrome-এ খুলুন।';
                                    });
                                  }
                                },
                                onWebContentProcessDidTerminate: (controller) {
                                  _stopLoadWatchdog();
                                  _webViewController = null;
                                  if (mounted && !_isDisposed) {
                                    setState(() {
                                      _renderProcessCrashed = true;
                                      _pageErrorMessage =
                                          'ব্রাউজার পেজটি মেমোরির কারণে বন্ধ হয়ে গেছে। আবার চেষ্টা করুন।';
                                    });
                                  }
                                },
                                onRenderProcessUnresponsive:
                                    (controller, url) async {
                                  if (mounted && !_isDisposed) {
                                    setState(() => _showSlowLoadBanner = true);
                                  }
                                  return null;
                                },
                                onPermissionRequest:
                                    (controller, request) async =>
                                        PermissionResponse(
                                  resources: request.resources,
                                  action: PermissionResponseAction.GRANT,
                                ),
                                onDownloadStartRequest: (controller, req) async {
                                  await _handleDownload(
                                    req,
                                    sourceController: controller,
                                  );
                                },
                                onPrintRequest:
                                    (controller, url, printJobController) async {
                                  return false;
                                },
                                onCreateWindow:
                                    (controller, createWindowAction) async {
                                  if (!mounted || _isDisposed) return false;
                                  final targetUrl =
                                      createWindowAction.request.url;
                                  if (createWindowAction.windowId > 0) {
                                    // showDialog-এ await করলে onCreateWindow আটকে গিয়ে ডেডলক হয়;
                                    // তাই ডায়ালগ অ্যাসিঙ্ক্রোনাসভাবে চালু করে তাৎক্ষণিক true রিটার্ন করা হয়।
                                    unawaited(
                                      _openPopupWindow(createWindowAction),
                                    );
                                    return true;
                                  }
                                  if (targetUrl != null) {
                                    try {
                                      await controller.loadUrl(
                                        urlRequest: createWindowAction.request,
                                      );
                                      return true;
                                    } catch (_) {}
                                  }
                                  return false;
                                },
                                shouldOverrideUrlLoading: (_, nav) =>
                                    _handleOverrideUrlLoading(nav),
                              ),
                            if (_pageErrorMessage != null ||
                                _renderProcessCrashed)
                              _buildErrorOverlay(),
                          ],
                        ),
                      ),
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
                          try {
                            await _webViewController?.goBack();
                            await _updateNavState();
                          } catch (_) {}
                        }
                      : null,
                  tooltip: 'পেছনে',
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  onPressed: _canGoForward
                      ? () async {
                          try {
                            await _webViewController?.goForward();
                            await _updateNavState();
                          } catch (_) {}
                        }
                      : null,
                  tooltip: 'সামনে',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: _reloadOrRecoverWebView,
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
