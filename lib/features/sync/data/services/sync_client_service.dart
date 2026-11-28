import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../../core/utils/bengali_digits.dart';
import '../../../backup/data/repositories/backup_repository.dart';
import '../../domain/models/sync_device_info.dart';
import '../../domain/models/sync_result.dart';

/// ফোন থেকে পিসিতে লোকাল নেটওয়ার্কে ডেটা পাঠানোর ক্লায়েন্ট সার্ভিস।
///
/// সাধারণ ব্যবহারকারীদের জন্য সহজবোধ্য বাংলা বার্তা ও দ্রুততম সংযোগ ব্যবস্থাপনা।
class SyncClientService {
  final BackupRepository _backupRepo;

  SyncClientService(this._backupRepo);

  // ----------------------------------------------------------------
  // সংযোগ যাচাই ও সঠিক আইপি নির্বাচন
  // ----------------------------------------------------------------

  /// একটি নির্দিষ্ট আইপিতে দ্রুত এইচটিটিপি হেলথ চেক
  Future<bool> _checkSingleIp(String ip, int port,
      {Duration timeout = const Duration(milliseconds: 1200)}) async {
    final client = HttpClient();
    client.connectionTimeout = timeout;
    try {
      final uri = Uri.parse('http://$ip:$port/health');
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(timeout);
      return response.statusCode == HttpStatus.ok;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  /// পিসির সব আইপিতে প্যারালাল চেক — যেটি সবার আগে রেসপন্স করে সেটি নির্বাচিত (Fastest Wins)
  Future<String?> findReachableIp({
    required List<String> ips,
    required int port,
  }) async {
    if (ips.isEmpty) return null;

    // রাউন্ড ১: সবগুলো আইপিতে একসাথে পরীক্ষা
    final hit1 = await _parallelFastCheck(ips, port,
        timeout: const Duration(milliseconds: 1200));
    if (hit1 != null) return hit1;

    // রাউন্ড ২: ধীরগতির কম্পিউটারের জন্য ৫০০ms বিরতি দিয়ে পুনরায় চেষ্টা
    await Future.delayed(const Duration(milliseconds: 500));
    final hit2 = await _parallelFastCheck(ips, port,
        timeout: const Duration(seconds: 2));
    if (hit2 != null) return hit2;

    return null;
  }

  Future<String?> _parallelFastCheck(List<String> ips, int port,
      {required Duration timeout}) async {
    final completer = Completer<String?>();
    var remaining = ips.length;

    for (final ip in ips) {
      _checkSingleIp(ip, port, timeout: timeout).then((ok) {
        if (ok && !completer.isCompleted) {
          completer.complete(ip);
        }
        remaining--;
        if (remaining == 0 && !completer.isCompleted) {
          completer.complete(null);
        }
      }).catchError((_) {
        remaining--;
        if (remaining == 0 && !completer.isCompleted) {
          completer.complete(null);
        }
      });
    }

    return completer.future;
  }

  /// ফাস্ট সাবনেট স্ক্যান: যদি পিসির আইপি পরিবর্তন হয়ে থাকে বা ব্রডকাস্ট মিস হয়
  Future<String?> _fastSubnetScan(int port) async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final myIp = addr.address;
          if (!myIp.startsWith('192.168.') &&
              !myIp.startsWith('10.') &&
              !myIp.startsWith('172.')) {
            continue;
          }

          final parts = myIp.split('.');
          if (parts.length != 4) continue;
          final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';

          // সবচেয়ে সম্ভাব্য আইপি রেঞ্জগুলো আগে দেখা
          final candidateHosts = <int>[
            ...List.generate(30, (i) => i + 2), // 2 to 31 (হটস্পট)
            ...List.generate(50, (i) => i + 100), // 100 to 149 (রাউটার)
            ...List.generate(68, (i) => i + 32), // 32 to 99
            ...List.generate(105, (i) => i + 150), // 150 to 254
          ];

          const batchSize = 32;
          for (var i = 0; i < candidateHosts.length; i += batchSize) {
            final end = (i + batchSize < candidateHosts.length)
                ? i + batchSize
                : candidateHosts.length;
            final batch = candidateHosts.sublist(i, end);

            final results = await Future.wait(batch.map((host) async {
              final candidateIp = '$prefix.$host';
              if (candidateIp == myIp) return null;
              try {
                final socket = await Socket.connect(
                  candidateIp,
                  port,
                  timeout: const Duration(milliseconds: 350),
                );
                await socket.close();
                final isAlive = await _checkSingleIp(candidateIp, port,
                    timeout: const Duration(seconds: 1));
                return isAlive ? candidateIp : null;
              } catch (_) {
                return null;
              }
            }));

            final found = results.whereType<String>().firstOrNull;
            if (found != null) return found;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// পিসির সাথে সংযোগ যাচাই করা (সিঙ্গেল আইপি)
  Future<bool> checkPcConnection({required String ip, required int port}) {
    return _checkSingleIp(ip, port);
  }

  // ----------------------------------------------------------------
  // ডেটা স্থানান্তর (Send Data)
  // ----------------------------------------------------------------

  /// ফোন থেকে SyncDeviceInfo দিয়ে সরাসরি পাঠানো
  Future<SyncResult> sendDataToPcFromDevice({
    required SyncDeviceInfo device,
    void Function(String message)? onProgress,
  }) {
    return sendDataToPc(
      ip: device.ip,
      allIps: device.allAvailableIps,
      port: device.port,
      pin: device.pin,
      onProgress: onProgress,
    );
  }

  /// ফোন থেকে সমস্ত তথ্য পিসিতে দ্রুত ও নির্ভরযোগ্যভাবে পাঠানো
  Future<SyncResult> sendDataToPc({
    required String ip,
    List<String> allIps = const [],
    required int port,
    required String pin,
    void Function(String message)? onProgress,
  }) async {
    File? exportedBackup;

    // সব ক্যান্ডিডেট আইপি একত্রিত করা (ডুপ্লিকেট ছাড়া)
    final ipsToTry = <String>[ip];
    for (final extra in allIps) {
      if (extra.isNotEmpty && !ipsToTry.contains(extra)) {
        ipsToTry.add(extra);
      }
    }

    try {
      // ১. পিসির সাথে যোগাযোগ স্থাপন
      onProgress?.call('কম্পিউটারের সাথে সংযোগ স্থাপন করা হচ্ছে...');

      String? reachableIp = await findReachableIp(ips: ipsToTry, port: port);

      // ২. পরিচিত আইপিতে না পেলে দ্রুত নেটওয়ার্কে খোঁজা
      if (reachableIp == null) {
        onProgress?.call('নেটওয়ার্কে কম্পিউটারটি খোঁজা হচ্ছে...');
        reachableIp = await _fastSubnetScan(port);
      }

      if (reachableIp == null) {
        return SyncResult.failure(
          'কম্পিউটারের সাথে সংযোগ পাওয়া যায়নি!\n\n'
          'সহজে সমাধান করতে এই বিষয়গুলো দেখে নিন:\n'
          '১. কম্পিউটারে "রজব" অ্যাপের "ডেটা গ্রহণ" স্ক্রিনটি খোলা আছে কিনা নিশ্চিত করুন।\n'
          '২. সবচেয়ে সহজ ও নির্ভরযোগ্য উপায়: ফোনের হটস্পট (Hotspot) চালু করে কম্পিউটারটি তাতে যুক্ত করুন।\n'
          '৩. অথবা নিশ্চিত করুন ফোন এবং কম্পিউটার একই ওয়াই-ফাই রাউটারে কানেক্ট আছে।\n'
          '৪. কম্পিউটারে অ্যাপ ওপেন করার সময় Windows Firewall থেকে কোনো অনুমতি চাওয়া হলে "Allow" বা সম্মতি দিন।',
        );
      }

      final uri = Uri.parse('http://$reachableIp:$port/sync-push');

      // ৩. ফোনের ডেটাবেজ প্রস্তুতকরণ
      onProgress?.call('ফোনের সমস্ত হিসাব ও আবেদন গুছিয়ে প্রস্তুত করা হচ্ছে...');
      exportedBackup = await _backupRepo.exportBackup();
      if (!exportedBackup.existsSync()) {
        return SyncResult.failure('ফোনের তথ্যের ব্যাকআপ ফাইল তৈরি করা সম্ভব হয়নি। মেমোরি খালি আছে কিনা দেখুন।');
      }

      final fileSize = await exportedBackup.length();
      final sizeFormatted =
          '${BengaliDigits.toBengali((fileSize / (1024 * 1024)).toStringAsFixed(2))} মেগাবাইট';

      // ৪. এইচটিটিপি বাইনারি পুশ
      onProgress?.call('কম্পিউটারে তথ্য পাঠানো হচ্ছে ($sizeFormatted)...');

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);
      try {
        final request = await client.postUrl(uri);
        request.headers.contentType = ContentType.binary;
        request.headers.add('x-sync-pin', pin.trim());
        request.contentLength = fileSize;

        await exportedBackup.openRead().pipe(request);
        
        onProgress?.call('কম্পিউটারে তথ্য সংরক্ষণ ও প্রতিস্থাপন করা হচ্ছে...');
        final response =
            await request.close().timeout(const Duration(seconds: 90));

        final responseBody = await response.transform(utf8.decoder).join();
        Map<String, dynamic> responseJson = {};
        try {
          responseJson = jsonDecode(responseBody) as Map<String, dynamic>;
        } catch (_) {}

        if (response.statusCode == HttpStatus.ok) {
          onProgress?.call('আলহামদুলিল্লাহ! সফলভাবে কম্পিউটার আপডেট হয়েছে!');
          return SyncResult.success(
            message: 'ফোন থেকে সমস্ত আবেদন, জমা ও খরচের তথ্য সফলভাবে কম্পিউটারে হালনাগাদ হয়েছে!',
            bytesTransferred: fileSize,
          );
        } else if (response.statusCode == HttpStatus.unauthorized) {
          return SyncResult.failure(
            'ভুল সিকিউরিটি পিন!\n\n'
            'কম্পিউটারের স্ক্রিনে দেখানো ৪ সংখ্যার পিন কোডটি মিলিয়ে দেখে পুনরায় চেষ্টা করুন (সাধারণত ১২৩৪ থাকে)।',
          );
        } else {
          final errorMsg = responseJson['message'] as String? ??
              'কম্পিউটারে তথ্য প্রতিস্থাপন করার সময় ত্রুটি হয়েছে।';
          return SyncResult.failure(errorMsg);
        }
      } finally {
        client.close();
      }
    } on SocketException catch (_) {
      return SyncResult.failure(
        'কম্পিউটারের সাথে সংযোগ করা যায়নি!\n\n'
        'সহজ করণীয়:\n'
        '• নিশ্চিত করুন ফোন ও কম্পিউটার একই ওয়াই-ফাই অথবা ফোনের হটস্পটে যুক্ত আছে।\n'
        '• কম্পিউটারে অ্যাপটি খোলা রেখে স্ক্রিন সচল রাখুন।\n'
        '• যদি রাউটারে সমস্যা হয়, তবে ফোনের Hotspot চালু করে পিসিতে ওয়াই-ফাই কানেক্ট করা সবচেয়ে নির্ভরযোগ্য ও দ্রুত কাজ করে।',
      );
    } on TimeoutException catch (_) {
      return SyncResult.failure(
        'তথ্য পাঠাতে নির্ধারিত সময়ের চেয়ে বেশি সময় লেগেছে।\n\n'
        'ধীরগতির কম্পিউটারে তথ্য সংরক্ষণ করতে একটু সময় লাগতে পারে। অনুগ্রহ করে আরও একবার "পাঠান" বাটনে চাপ দিন।',
      );
    } catch (e) {
      return SyncResult.failure('সিঙ্ক সম্পন্ন হতে পারেনি: $e');
    } finally {
      if (exportedBackup != null && exportedBackup.existsSync()) {
        try {
          exportedBackup.deleteSync();
        } catch (_) {}
      }
    }
  }
}
