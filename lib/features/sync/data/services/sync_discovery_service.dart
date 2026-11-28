import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/models/sync_device_info.dart';

/// ওয়াই-ফাই বা হটস্পট লোকাল নেটওয়ার্কে ডিভাইস অত্যন্ত দ্রুত ও নির্ভরযোগ্যভাবে খোঁজার সার্ভিস।
///
/// ৩-স্তরের আল্ট্রা-ফাস্ট ডিসকভারি কৌশল:
///   ১. UDP Broadcast (255.255.255.255 + Directed Subnet .255)
///   ২. Android Hotspot Gateway Direct Unicast (ফোন .1 এ থাকলে সরাসরি পিসি থেকে বিযকন)
///   ৩. Parallel Fast Subnet Scan Fallback (Router AP Isolation থাকলে ব্যাচে দ্রুত পোর্ট স্ক্যান)
class SyncDiscoveryService {
  static const int discoveryPort = 8766;
  static const int syncPort = 8765;
  static const String probeMessage = 'ROJOB_DISCOVER_PROBE';

  RawDatagramSocket? _broadcastSocket;
  RawDatagramSocket? _listenSocket;
  Timer? _beaconTimer;
  Timer? _probeTimer;
  Timer? _subnetScanTimer;

  final _discoveredDevicesController =
      StreamController<List<SyncDeviceInfo>>.broadcast();
  final Map<String, SyncDeviceInfo> _discoveredMap = {};

  Stream<List<SyncDeviceInfo>> get discoveredDevicesStream =>
      _discoveredDevicesController.stream;

  List<SyncDeviceInfo> get currentDiscoveredDevices =>
      _discoveredMap.values.toList();

  // ----------------------------------------------------------------
  // PC সার্ভার মোড: বিযকন পাঠানো ও প্রবের উত্তর দেওয়া
  // ----------------------------------------------------------------

  Future<void> startBroadcasting({
    required String ip,
    List<String> allIps = const [],
    required int port,
    required String deviceName,
    required String pin,
  }) async {
    await stop();

    try {
      _broadcastSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        discoveryPort,
        reuseAddress: true,
      );
      _broadcastSocket?.broadcastEnabled = true;

      // ইনকামিং প্রোবের সরাসরি ইউনিকাস্ট উত্তর
      _broadcastSocket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final dg = _broadcastSocket?.receive();
          if (dg == null) return;
          try {
            final receivedText = utf8.decode(dg.data).trim();
            if (receivedText == probeMessage) {
              final info = _buildDeviceInfo(ip, allIps, port, deviceName, pin);
              final replyBytes = utf8.encode(info.toBeaconMessage());
              // ফোনে সরাসরি ইউনিকাস্ট উত্তর পাঠানো
              _broadcastSocket?.send(replyBytes, dg.address, dg.port);
              // অতিরিক্ত সুরক্ষায় স্ট্যান্ডার্ড ডিসকভারি পোর্টেও পাঠানো
              if (dg.port != discoveryPort) {
                _broadcastSocket?.send(replyBytes, dg.address, discoveryPort);
              }
            }
          } catch (_) {}
        }
      });

      // তাত্ক্ষণিক দ্রুত বিযকন বার্স্ট (0ms, 250ms, 500ms)
      _sendBeaconAllTargets(ip, allIps, port, deviceName, pin);
      Future.delayed(const Duration(milliseconds: 250), () {
        _sendBeaconAllTargets(ip, allIps, port, deviceName, pin);
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        _sendBeaconAllTargets(ip, allIps, port, deviceName, pin);
      });

      // এরপর প্রতি ১ সেকেন্ডে নিয়মিত মাল্টি-টার্গেট বিযকন
      _beaconTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _sendBeaconAllTargets(ip, allIps, port, deviceName, pin);
      });
    } catch (_) {}
  }

  /// সব ধরণের নেটওয়ার্কে (ওয়াই-ফাই রাউটার ও মোবাইল হটস্পট) বিযকন ডেলিভারি
  void _sendBeaconAllTargets(String ip, List<String> allIps, int port,
      String deviceName, String pin) {
    if (_broadcastSocket == null) return;
    try {
      final info = _buildDeviceInfo(ip, allIps, port, deviceName, pin);
      final bytes = utf8.encode(info.toBeaconMessage());

      // ১. ইউনিভার্সাল গ্লোবাল ব্রডকাস্ট
      _broadcastSocket?.send(
        bytes,
        InternetAddress('255.255.255.255'),
        discoveryPort,
      );

      final candidateIps = <String>{ip, ...allIps};
      for (final aIp in candidateIps) {
        final parts = aIp.split('.');
        if (parts.length == 4) {
          final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';

          // ২. ডিরেক্টেড সাবনেট ব্রডকাস্ট (রাউটারে অত্যন্ত কার্যকর)
          final subnetBcast = '$prefix.255';
          _broadcastSocket?.send(
            bytes,
            InternetAddress(subnetBcast),
            discoveryPort,
          );

          // ৩. মোবাইল হটস্পট গেটওয়ে ইউনিকাস্ট (অ্যান্ড্রয়েড ফোন সাধারণত .১ এ থাকে)
          // ফোন যদি হটস্পট চালায়, ফোন নিজেই .১ এ থাকে। ইউনিকাস্ট প্যাকেট ফিল্টার হয় না!
          final gatewayIp = '$prefix.1';
          if (gatewayIp != aIp) {
            _broadcastSocket?.send(
              bytes,
              InternetAddress(gatewayIp),
              discoveryPort,
            );
          }
        }
      }
    } catch (_) {}
  }

  SyncDeviceInfo _buildDeviceInfo(String ip, List<String> allIps, int port,
      String deviceName, String pin) {
    return SyncDeviceInfo(
      ip: ip,
      allIps: allIps,
      port: port,
      deviceName: deviceName,
      pin: pin,
      os: Platform.operatingSystem,
      lastSeen: DateTime.now(),
    );
  }

  // ----------------------------------------------------------------
  // মোবাইল ক্লায়েন্ট মোড: কম্পিউটার খোঁজা
  // ----------------------------------------------------------------

  Future<void> startListening() async {
    await stop();
    _discoveredMap.clear();
    _discoveredDevicesController.add([]);

    try {
      _listenSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
      );
      _listenSocket?.broadcastEnabled = true;

      _listenSocket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final dg = _listenSocket?.receive();
          if (dg == null) return;
          try {
            final text = utf8.decode(dg.data);
            final device = SyncDeviceInfo.fromBeaconMessage(text);
            if (device != null) {
              _discoveredMap[device.ip] = device;
              _pruneOldDevices();
              _discoveredDevicesController.add(_discoveredMap.values.toList());
            }
          } catch (_) {}
        }
      });

      // দ্রুত প্রোব বার্স্ট (0ms, 250ms, 500ms)
      sendProbe();
      Future.delayed(const Duration(milliseconds: 250), sendProbe);
      Future.delayed(const Duration(milliseconds: 500), sendProbe);

      // নিয়মিত প্রোব প্রতি ১ সেকেন্ডে
      _probeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        sendProbe();
        _pruneOldDevices();
      });

      // রাউটারে যদি AP Isolation চালু থাকে বা UDP ব্রডকাস্ট আটকে যায়:
      // মাত্র ১.৫ সেকেন্ডের মধ্যে কোনো ডিভাইস না পেলে ব্যাকগ্রাউন্ডে ফাস্ট সাবনেট স্ক্যান চালু
      _subnetScanTimer = Timer(const Duration(milliseconds: 1500), () async {
        if (_discoveredMap.isEmpty) {
          await _runFastSubnetScan();
        }
      });
    } catch (_) {}
  }

  /// লোকাল সাবনেট ও ব্রডকাস্টে প্রোব রিকোয়েস্ট পাঠানো
  void sendProbe() {
    if (_listenSocket == null) return;
    try {
      final probeBytes = utf8.encode(probeMessage);

      // ১. ইউনিভার্সাল ব্রডকাস্ট
      _listenSocket?.send(
        probeBytes,
        InternetAddress('255.255.255.255'),
        discoveryPort,
      );

      // ২. নিজের সব সক্রিয় ইন্টারফেসে সাবনেট ব্রডকাস্ট
      _sendDirectedProbes(probeBytes);
    } catch (_) {}
  }

  Future<void> _sendDirectedProbes(List<int> probeBytes) async {
    try {
      final myIps = await _getOwnIps();
      for (final myIp in myIps) {
        final parts = myIp.split('.');
        if (parts.length == 4) {
          final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';
          // সাবনেট ব্রডকাস্ট
          _listenSocket?.send(
            probeBytes,
            InternetAddress('$prefix.255'),
            discoveryPort,
          );

          // ফোন যদি হটস্পট হয় (১৯২.১৬৮.৪৩.১), ক্লায়েন্ট পিসির সম্ভাব্য আইপিগুলোতেও প্রোব
          if (myIp == '192.168.43.1') {
            for (final hostPart in [2, 3, 4, 5, 100, 101, 102, 105, 110]) {
              _listenSocket?.send(
                probeBytes,
                InternetAddress('$prefix.$hostPart'),
                discoveryPort,
              );
            }
          }
        }
      }
    } catch (_) {}
  }

  /// ফাস্ট প্যারালাল সাবনেট স্ক্যান (Router AP Isolation বাইপাস)
  /// ব্যাচ ভিত্তিক (৩২টি করে) সংযোগ পরীক্ষা — ফোন যাতে কোনোভাবেই না হ্যাং করে
  Future<void> _runFastSubnetScan() async {
    try {
      final myIps = await _getOwnIps();
      if (myIps.isEmpty) return;

      for (final myIp in myIps) {
        if (_discoveredMap.isNotEmpty) break;

        final parts = myIp.split('.');
        if (parts.length != 4) continue;
        final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';

        // প্রায়োরিটি আইপি রেঞ্জ আগে স্ক্যান (হটস্পট ও রাউটার ডিএইচসিপি পুল)
        final priorityHosts = <int>[
          ...List.generate(30, (i) => i + 2), // 2 to 31
          ...List.generate(50, (i) => i + 100), // 100 to 149
          ...List.generate(68, (i) => i + 32), // 32 to 99
          ...List.generate(105, (i) => i + 150), // 150 to 254
        ];

        const batchSize = 32;
        for (var i = 0; i < priorityHosts.length; i += batchSize) {
          if (_discoveredMap.isNotEmpty) break;

          final end = (i + batchSize < priorityHosts.length)
              ? i + batchSize
              : priorityHosts.length;
          final batch = priorityHosts.sublist(i, end);

          await Future.wait(batch.map((host) async {
            final candidateIp = '$prefix.$host';
            if (candidateIp == myIp) return;

            try {
              final socket = await Socket.connect(
                candidateIp,
                syncPort,
                timeout: const Duration(milliseconds: 350),
              );
              await socket.close();

              // পোর্ট খোলা পেলে সাথে সাথে হেলথ চেক করে পিসির নাম ও পিন সংগ্রহ
              final pcInfo = await _fetchPcInfoFromHttp(candidateIp, syncPort);
              if (pcInfo != null) {
                _discoveredMap[candidateIp] = pcInfo;
                _discoveredDevicesController.add(_discoveredMap.values.toList());
              }
            } catch (_) {}
          }));
        }
      }
    } catch (_) {}
  }

  /// সরাসরি এইচটিটিপি থেকে পিসির বিবরণ সংগ্রহ করা
  Future<SyncDeviceInfo?> _fetchPcInfoFromHttp(String ip, int port) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 2);
    try {
      final uri = Uri.parse('http://$ip:$port/health');
      final req = await client.getUrl(uri);
      final resp = await req.close().timeout(const Duration(seconds: 2));
      if (resp.statusCode == HttpStatus.ok) {
        final body = await resp.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        if (json['app'] == 'rojob_bhumi_seba') {
          return SyncDeviceInfo(
            ip: ip,
            allIps: (json['ips'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [ip],
            port: port,
            deviceName: json['name'] as String? ?? 'রজব কম্পিউটার',
            pin: json['pin'] as String? ?? '',
            os: json['os'] as String? ?? 'windows',
            lastSeen: DateTime.now(),
          );
        }
      }
    } catch (_) {} finally {
      client.close();
    }
    return null;
  }

  Future<List<String>> _getOwnIps() async {
    final ips = <String>[];
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final a = addr.address;
          if (!addr.isLoopback &&
              (a.startsWith('192.168.') ||
                  a.startsWith('10.') ||
                  a.startsWith('172.'))) {
            ips.add(a);
          }
        }
      }
    } catch (_) {}
    return ips;
  }

  void _pruneOldDevices() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    for (final entry in _discoveredMap.entries) {
      if (now.difference(entry.value.lastSeen).inSeconds > 10) {
        keysToRemove.add(entry.key);
      }
    }
    if (keysToRemove.isNotEmpty) {
      for (final key in keysToRemove) {
        _discoveredMap.remove(key);
      }
      _discoveredDevicesController.add(_discoveredMap.values.toList());
    }
  }

  Future<void> stop() async {
    _beaconTimer?.cancel();
    _beaconTimer = null;
    _probeTimer?.cancel();
    _probeTimer = null;
    _subnetScanTimer?.cancel();
    _subnetScanTimer = null;

    try {
      _broadcastSocket?.close();
    } catch (_) {}
    _broadcastSocket = null;

    try {
      _listenSocket?.close();
    } catch (_) {}
    _listenSocket = null;
  }

  void dispose() {
    stop();
    _discoveredDevicesController.close();
  }
}
