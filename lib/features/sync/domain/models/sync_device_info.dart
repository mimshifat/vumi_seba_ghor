import 'dart:convert';

/// লোকাল নেটওয়ার্কে আবিষ্কৃত বা সংযুক্ত ডিভাইসের তথ্য।
class SyncDeviceInfo {
  final String ip;
  final int port;
  final String deviceName;
  final String pin;
  final String os;
  final DateTime lastSeen;

  const SyncDeviceInfo({
    required this.ip,
    required this.port,
    required this.deviceName,
    required this.pin,
    required this.os,
    required this.lastSeen,
  });

  Map<String, dynamic> toJson() => {
        'ip': ip,
        'port': port,
        'name': deviceName,
        'pin': pin,
        'os': os,
        'timestamp': lastSeen.millisecondsSinceEpoch,
      };

  factory SyncDeviceInfo.fromJson(Map<String, dynamic> json) => SyncDeviceInfo(
        ip: json['ip'] as String? ?? '',
        port: json['port'] as int? ?? 8765,
        deviceName: json['name'] as String? ?? 'অজানা ডিভাইস',
        pin: json['pin'] as String? ?? '',
        os: json['os'] as String? ?? 'unknown',
        lastSeen: DateTime.fromMillisecondsSinceEpoch(
          json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        ),
      );

  String toBeaconMessage() => jsonEncode({
        'app': 'rojob_sync',
        'ip': ip,
        'port': port,
        'name': deviceName,
        'pin': pin,
        'os': os,
        'timestamp': lastSeen.millisecondsSinceEpoch,
      });

  static SyncDeviceInfo? fromBeaconMessage(String message) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      if (data['app'] != 'rojob_sync') return null;
      return SyncDeviceInfo.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncDeviceInfo &&
          runtimeType == other.runtimeType &&
          ip == other.ip &&
          port == other.port;

  @override
  int get hashCode => ip.hashCode ^ port.hashCode;
}
