import 'package:flutter_test/flutter_test.dart';
import 'package:bhumi_kajer_hisab/features/sync/domain/models/sync_device_info.dart';
import 'package:bhumi_kajer_hisab/features/sync/domain/models/sync_result.dart';

void main() {
  group('Local Sync Models & Discovery Beacons', () {
    test('SyncDeviceInfo serialization and deserialization works accurately', () {
      final now = DateTime.now();
      final device = SyncDeviceInfo(
        ip: '192.168.0.105',
        port: 8765,
        deviceName: 'রজব কম্পিউটার',
        pin: '1234',
        os: 'windows',
        lastSeen: now,
      );

      final json = device.toJson();
      final reconstituted = SyncDeviceInfo.fromJson(json);

      expect(reconstituted.ip, '192.168.0.105');
      expect(reconstituted.port, 8765);
      expect(reconstituted.deviceName, 'রজব কম্পিউটার');
      expect(reconstituted.pin, '1234');
      expect(reconstituted.os, 'windows');
      expect(reconstituted.lastSeen.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('SyncDeviceInfo beacon message encoding and decoding', () {
      final device = SyncDeviceInfo(
        ip: '192.168.1.50',
        port: 8765,
        deviceName: 'দোকানের ল্যাপটপ',
        pin: '8899',
        os: 'windows',
        lastSeen: DateTime.now(),
      );

      final beacon = device.toBeaconMessage();
      final parsed = SyncDeviceInfo.fromBeaconMessage(beacon);

      expect(parsed, isNotNull);
      expect(parsed!.ip, '192.168.1.50');
      expect(parsed.deviceName, 'দোকানের ল্যাপটপ');
      expect(parsed.pin, '8899');
    });

    test('SyncResult handles success and failure states properly', () {
      final success = SyncResult.success(bytesTransferred: 2048);
      expect(success.isSuccess, isTrue);
      expect(success.bytesTransferred, 2048);

      final failure = SyncResult.failure('সংযোগ ব্যর্থ হয়েছে');
      expect(failure.isSuccess, isFalse);
      expect(failure.message, 'সংযোগ ব্যর্থ হয়েছে');
    });
  });
}
