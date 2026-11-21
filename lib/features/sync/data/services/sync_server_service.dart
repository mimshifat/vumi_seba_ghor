import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/app_database.dart';
import '../../../backup/data/repositories/backup_repository.dart';
import '../../domain/models/sync_result.dart';
import 'sync_discovery_service.dart';

/// পিসির ব্যাকগ্রাউন্ড লোকাল রিসিভার সার্ভার (HttpServer + UDP Broadcaster)।
class SyncServerService {
  static SyncServerService? currentRunningInstance;

  final BackupRepository _backupRepo;
  final SyncDiscoveryService _discoveryService;

  HttpServer? _httpServer;
  bool _isRunning = false;
  String _currentIp = '127.0.0.1';
  List<String> _availableIps = [];
  int _port = 8765;
  String _pin = '1234';
  DateTime? _lastSyncTime;

  final _syncEventsController = StreamController<SyncResult>.broadcast();

  SyncServerService(
    this._backupRepo, {
    SyncDiscoveryService? discoveryService,
  }) : _discoveryService = discoveryService ?? SyncDiscoveryService();

  bool get isRunning => _isRunning;
  String get currentIp => _currentIp;
  List<String> get availableIps => _availableIps;
  int get port => _port;
  String get pin => _pin;
  DateTime? get lastSyncTime => _lastSyncTime;
  Stream<SyncResult> get syncEventsStream => _syncEventsController.stream;

  void setPin(String newPin) {
    if (newPin.trim().length >= 4) {
      _pin = newPin.trim();
      if (_isRunning) {
        _discoveryService.startBroadcasting(
          ip: _currentIp,
          port: _port,
          deviceName: _getDeviceName(),
          pin: _pin,
        );
      }
    }
  }

  String _getDeviceName() {
    if (Platform.isWindows) return 'রজব কম্পিউটার (Windows PC)';
    if (Platform.isAndroid) return 'রজব মোবাইল (Android Phone)';
    if (Platform.isMacOS) return 'রজব ম্যাক (Mac)';
    if (Platform.isLinux) return 'রজব লিনাক্স (Linux PC)';
    return 'রজব সেবা ঘর';
  }

  /// লোকাল আইপি অ্যাড্রেস শনাক্ত করা (ভার্চুয়াল অ্যাডাপ্টার বাদ দিয়ে রিয়েল ওয়াই-ফাই প্রাধান্য দেওয়া)
  Future<List<String>> getLocalIpAddresses() async {
    final candidateIps = <Map<String, dynamic>>[];
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      for (final interface in interfaces) {
        final ifaceName = interface.name.toLowerCase();
        // ভার্চুয়াল অ্যাডাপ্টার (WSL, VirtualBox, VMware, Docker, ইত্যাদি) শনাক্ত
        final isVirtual = ifaceName.contains('virtual') ||
            ifaceName.contains('vbox') ||
            ifaceName.contains('vmware') ||
            ifaceName.contains('veth') ||
            ifaceName.contains('hyper-v') ||
            ifaceName.contains('docker') ||
            ifaceName.contains('tap') ||
            ifaceName.contains('wsl');

        // আসল ওয়াই-ফাই বা হটস্পট ইন্টারফেস
        final isWifi = ifaceName.contains('wi-fi') ||
            ifaceName.contains('wifi') ||
            ifaceName.contains('wireless') ||
            ifaceName.contains('wlan');

        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            candidateIps.add({
              'ip': addr.address,
              'isVirtual': isVirtual,
              'isWifi': isWifi,
            });
          }
        }
      }

      // প্রায়োরিটি স্কোরিং: রিয়েল ওয়াই-ফাই > সাধারণ লোকাল সাবনেট > ভার্চুয়াল
      candidateIps.sort((a, b) {
        final aVirt = a['isVirtual'] as bool;
        final bVirt = b['isVirtual'] as bool;
        if (aVirt != bVirt) return aVirt ? 1 : -1; // নন-ভার্চুয়াল আগে

        final aWifi = a['isWifi'] as bool;
        final bWifi = b['isWifi'] as bool;
        if (aWifi != bWifi) return aWifi ? -1 : 1; // ওয়াই-ফাই আগে

        final aIp = a['ip'] as String;
        final bIp = b['ip'] as String;
        if (aIp.startsWith('192.168.') && !bIp.startsWith('192.168.')) return -1;
        if (!aIp.startsWith('192.168.') && bIp.startsWith('192.168.')) return 1;
        if (aIp.startsWith('10.') && !bIp.startsWith('10.')) return -1;
        if (!aIp.startsWith('10.') && bIp.startsWith('10.')) return 1;
        return aIp.compareTo(bIp);
      });
    } catch (_) {}

    return candidateIps.map((e) => e['ip'] as String).toList();
  }

  /// সার্ভার চালু করা (পোর্ট ব্যস্ত থাকলে অল্টারনেট পোর্টে অটো-ফলব্যাক)
  Future<bool> startServer({
    int port = 8765,
    String? pin,
    required void Function(AppDatabase newDb) onDatabaseReopened,
  }) async {
    await stopServer();

    if (pin != null && pin.trim().length >= 4) {
      _pin = pin.trim();
    }

    _availableIps = await getLocalIpAddresses();
    _currentIp = _availableIps.isNotEmpty ? _availableIps.first : '127.0.0.1';

    // মূল পোর্ট বা অল্টারনেট পোর্টে বাইন্ড করার চেষ্টা
    final portsToTry = [port, 8767, 8769, 8771];
    HttpServer? server;

    for (final tryPort in portsToTry) {
      try {
        server = await HttpServer.bind(
          InternetAddress.anyIPv4,
          tryPort,
          shared: true,
        );
        _port = tryPort;
        break;
      } catch (_) {
        // পোর্ট ব্যস্ত থাকলে পরবর্তী পোর্টে চেষ্টা
      }
    }

    if (server == null) {
      _isRunning = false;
      return false;
    }

    try {
      _httpServer = server;
      _isRunning = true;
      currentRunningInstance = this;

      // লোকাল নেটওয়ার্কে বিযকন পাঠানো শুরু করা
      _discoveryService.startBroadcasting(
        ip: _currentIp,
        port: _port,
        deviceName: _getDeviceName(),
        pin: _pin,
      );

      // এইচটিটিপি রিকোয়েস্ট হ্যান্ডলিং
      _httpServer?.listen(
        (HttpRequest request) => _handleRequest(request, onDatabaseReopened),
        onError: (err) {
          _isRunning = false;
        },
      );

      return true;
    } catch (e) {
      _isRunning = false;
      return false;
    }
  }

  /// রিকোয়েস্ট প্রসেসিং
  Future<void> _handleRequest(
    HttpRequest request,
    void Function(AppDatabase newDb) onDatabaseReopened,
  ) async {
    final response = request.response;
    response.headers.contentType = ContentType.json;
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers.add('Access-Control-Allow-Headers', '*');
    response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');

    if (request.method == 'OPTIONS') {
      response.statusCode = HttpStatus.ok;
      await response.close();
      return;
    }

    final path = request.uri.path;

    // ১. হেলথ চেক এন্ডপয়েন্ট
    if (path == '/health' || path == '/status') {
      response.statusCode = HttpStatus.ok;
      response.write(jsonEncode({
        'status': 'ready',
        'name': _getDeviceName(),
        'os': Platform.operatingSystem,
        'app': 'rojob_bhumi_seba',
      }));
      await response.close();
      return;
    }

    // ২. ডেটা পুশ এন্ডপয়েন্ট (ফোন থেকে ব্যাকআপ রিসিভ)
    if (path == '/sync-push' && request.method == 'POST') {
      // সিকিউরিটি পিন যাচাই
      final clientPin = request.headers.value('x-sync-pin')?.trim() ?? '';
      if (clientPin != _pin) {
        response.statusCode = HttpStatus.unauthorized;
        response.write(jsonEncode({
          'success': false,
          'message': 'ভুল সিকিউরিটি পিন। পিসির স্ক্রিনে দেখানো পিন দিন।',
        }));
        await response.close();
        return;
      }

      File? tempFile;
      IOSink? sink;
      try {
        final tempDir = await getTemporaryDirectory();
        final fileName =
            'rojob_incoming_sync_${DateTime.now().millisecondsSinceEpoch}.sqlite';
        tempFile = File(p.join(tempDir.path, fileName));

        // বাইনারি ডেটা সেভ করা
        sink = tempFile.openWrite();
        await for (final chunk in request) {
          sink.add(chunk);
        }
        await sink.flush();
        await sink.close();
        sink = null;

        final fileSize = await tempFile.length();
        if (fileSize < 1024) {
          throw Exception('প্রাপ্ত ফাইলের সাইজ অসম্পূর্ণ বা অস্বাভাবিক।');
        }

        // আইসোলেটে ভ্যালিডেশন
        final validation =
            await _backupRepo.validateBackupFile(tempFile.path);
        if (!validation.isValid) {
          throw Exception(
              'ডেটাবেজ ফাইলটি বৈধ নয়: ${validation.errorMessage ?? 'স্কিমা অসঙ্গতি'}');
        }

        // নিরাপদ রিস্টোর ও লাইভ ডেটাবেজ সোয়াপ
        await _backupRepo.restoreBackup(
          tempFile.path,
          onDatabaseReopened: onDatabaseReopened,
          preserveCurrentSettings: false, // ফোনের সমস্ত সেটিংস ও ডেটা সরাসরি আসবে
        );

        _lastSyncTime = DateTime.now();
        final successResult = SyncResult.success(
          message: 'ফোন থেকে সমস্ত তথ্য পিসিতে সফলভাবে আপডেট হয়েছে!',
          bytesTransferred: fileSize,
        );
        _syncEventsController.add(successResult);

        response.statusCode = HttpStatus.ok;
        response.write(jsonEncode({
          'success': true,
          'message': successResult.message,
          'bytes': fileSize,
          'timestamp': _lastSyncTime!.toIso8601String(),
        }));
      } catch (e) {
        final failResult = SyncResult.failure(e.toString());
        _syncEventsController.add(failResult);

        response.statusCode = HttpStatus.badRequest;
        response.write(jsonEncode({
          'success': false,
          'message': e.toString(),
        }));
      } finally {
        if (sink != null) {
          try {
            await sink.close();
          } catch (_) {}
        }
        if (tempFile != null && tempFile.existsSync()) {
          try {
            tempFile.deleteSync();
          } catch (_) {}
        }
        await response.close();
      }
      return;
    }

    // অন্য কোনো পাথে 404
    response.statusCode = HttpStatus.notFound;
    response.write(jsonEncode({'error': 'Not found'}));
    await response.close();
  }

  /// সার্ভার বন্ধ করা
  Future<void> stopServer() async {
    _isRunning = false;
    if (currentRunningInstance == this) {
      currentRunningInstance = null;
    }
    await _discoveryService.stop();
    try {
      await _httpServer?.close(force: true);
    } catch (_) {}
    _httpServer = null;
  }

  void dispose() {
    stopServer();
    _discoveryService.dispose();
    _syncEventsController.close();
  }
}
