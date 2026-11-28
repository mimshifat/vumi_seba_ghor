import 'dart:convert';

/// লোকাল নেটওয়ার্কে আবিষ্কৃত বা সংযুক্ত ডিভাইসের তথ্য।
class SyncDeviceInfo {
  final String ip;
  final List<String> allIps; // পিসির সব IP অ্যাড্রেস (মাল্টি-অ্যাডাপ্টার সাপোর্ট)
  final int port;
  final String deviceName;
  final String pin;
  final String os;
  final DateTime lastSeen;

  const SyncDeviceInfo({
    required this.ip,
    this.allIps = const [],
    required this.port,
    required this.deviceName,
    required this.pin,
    required this.os,
    required this.lastSeen,
  });

  /// সব available IP-র list (primary IP সহ, duplicate বাদ দিয়ে)
  List<String> get allAvailableIps {
    final result = <String>[ip];
    for (final extra in allIps) {
      if (extra.isNotEmpty && !result.contains(extra)) {
        result.add(extra);
      }
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
        'ip': ip,
        'allIps': allIps,
        'port': port,
        'name': deviceName,
        'pin': pin,
        'os': os,
        'timestamp': lastSeen.millisecondsSinceEpoch,
      };

  factory SyncDeviceInfo.fromJson(Map<String, dynamic> json) => SyncDeviceInfo(
        ip: json['ip'] as String? ?? '',
        allIps: (json['allIps'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .where((e) => e.isNotEmpty)
                .toList() ??
            [],
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
        'allIps': allIps,
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
