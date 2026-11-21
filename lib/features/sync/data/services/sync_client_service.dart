import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../../core/utils/bengali_digits.dart';
import '../../../backup/data/repositories/backup_repository.dart';
import '../../domain/models/sync_result.dart';

/// ফোন থেকে পিসিতে লোকাল নেটওয়ার্কে ডেটা পাঠানোর ক্লায়েন্ট সার্ভিস।
class SyncClientService {
  final BackupRepository _backupRepo;

  SyncClientService(this._backupRepo);

  /// পিসির সাথে সংযোগ যাচাই করা (Health Check)
  Future<bool> checkPcConnection({
    required String ip,
    required int port,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 4);

    try {
      final uri = Uri.parse('http://$ip:$port/health');
      final request = await client.getUrl(uri);
      final response = await request.close();
      return response.statusCode == HttpStatus.ok;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  /// ফোন থেকে সমস্ত তথ্য পিসিতে পাঠানো ও পিসির ডেটাবেজ আপডেট সম্পন্ন করা
  Future<SyncResult> sendDataToPc({
    required String ip,
    required int port,
    required String pin,
    void Function(String message)? onProgress,
  }) async {
    File? exportedBackup;
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 6);

    try {
      // ১. পিসির সাথে লোকাল সংযোগ যাচাই
      onProgress?.call('পিসির সাথে লোকাল নেটওয়ার্ক সংযোগ যাচাই করা হচ্ছে...');
      final uri = Uri.parse('http://$ip:$port/sync-push');

      // ২. ফোনের লাইভ ডেটাবেজের ফ্রেশ ও নিরাপদ স্ন্যাপশট এক্সপোর্ট
      onProgress?.call('ফোনের সমস্ত তথ্যের নিরাপদ ব্যাকআপ প্রস্তুত হচ্ছে...');
      exportedBackup = await _backupRepo.exportBackup();
      if (!exportedBackup.existsSync()) {
        return SyncResult.failure('ফোনের ব্যাকআপ ফাইল তৈরি করা সম্ভব হয়নি।');
      }

      final fileSize = await exportedBackup.length();
      final sizeFormatted =
          '${BengaliDigits.toBengali((fileSize / (1024 * 1024)).toStringAsFixed(2))} মেগাবাইট';

      // ৩. পিসিতে ফাইল পাঠানো
      onProgress?.call('পিসিতে ডেটা পাঠানো হচ্ছে ($sizeFormatted)...');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.binary;
      request.headers.add('x-sync-pin', pin.trim());
      request.contentLength = fileSize;

      await exportedBackup.openRead().pipe(request);
      final response =
          await request.close().timeout(const Duration(seconds: 45));

      final responseBody = await response.transform(utf8.decoder).join();
      Map<String, dynamic> responseJson = {};
      try {
        responseJson = jsonDecode(responseBody) as Map<String, dynamic>;
      } catch (_) {}

      // ৪. রেসপন্স যাচাই
      if (response.statusCode == HttpStatus.ok) {
        onProgress?.call('পিসিতে সফলভাবে সব ডেটা আপডেট সম্পন্ন হয়েছে!');
        return SyncResult.success(
          message: responseJson['message'] as String? ??
              'ফোন থেকে ডেটা সফলভাবে পিসিতে আপডেট হয়েছে!',
          bytesTransferred: fileSize,
        );
      } else if (response.statusCode == HttpStatus.unauthorized) {
        return SyncResult.failure(
          'ভুল সিকিউরিটি পিন! পিসির স্ক্রিনে দেখানো ৪ সংখ্যার সঠিক পিনটি দিন।',
        );
      } else {
        final errorMsg = responseJson['message'] as String? ??
            'পিসিতে ডেটাবেজ সোয়াপ করার সময় ত্রুটি হয়েছে।';
        return SyncResult.failure(errorMsg);
      }
    } on SocketException catch (_) {
      return SyncResult.failure(
        'পিসির সাথে সংযোগ করা যায়নি!\n\n১. নিশ্চিত করুন ফোন ও কম্পিউটার একই ওয়াই-ফাই বা হটস্পটে সংযুক্ত।\n২. পিসিতে অ্যাপ খোলা আছে এবং লোকাল সিঙ্ক স্ক্রিনটি চালু আছে।\n৩. যদি রাউটারে সমস্যা হয়, ফোনের হটস্পট (Hotspot) চালু করে পিসিতে ওয়াই-ফাই কানেক্ট করুন।\n৪. উইন্ডোজ পিসিতে Firewall অনুমতি বা Private Network নিশ্চিত করুন।',
      );
    } on TimeoutException catch (_) {
      return SyncResult.failure(
        'পিসিতে ডেটা পাঠানোর সময় টাইম-আউট হয়েছে। নেটওয়ার্ক চেক করে আবার চেষ্টা করুন।',
      );
    } catch (e) {
      return SyncResult.failure('সিঙ্ক ব্যর্থ হয়েছে: $e');
    } finally {
      client.close();
      if (exportedBackup != null && exportedBackup.existsSync()) {
        try {
          exportedBackup.deleteSync();
        } catch (_) {}
      }
    }
  }
}
