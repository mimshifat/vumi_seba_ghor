import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/models/sync_device_info.dart';

/// ওয়াই-ফাই বা হটস্পট লোকাল নেটওয়ার্কে ডিভাইস স্বয়ংক্রিয়ভাবে খোঁজার সার্ভিস (UDP Discovery)।
class SyncDiscoveryService {
  static const int discoveryPort = 8766;
  static const String probeMessage = 'ROJOB_DISCOVER_PROBE';

  RawDatagramSocket? _broadcastSocket;
  RawDatagramSocket? _listenSocket;
  Timer? _beaconTimer;

  final _discoveredDevicesController =
      StreamController<List<SyncDeviceInfo>>.broadcast();
  final Map<String, SyncDeviceInfo> _discoveredMap = {};

  Stream<List<SyncDeviceInfo>> get discoveredDevicesStream =>
      _discoveredDevicesController.stream;

  List<SyncDeviceInfo> get currentDiscoveredDevices =>
      _discoveredMap.values.toList();

  /// পিসির জন্য: লোকাল নেটওয়ার্কে বিযকন পাঠানো ও প্রব রিকোয়েস্টের উত্তর দেওয়া
  Future<void> startBroadcasting({
    required String ip,
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

      // ইনকামিং প্রোবের উত্তর শোনার লিসেনার
      _broadcastSocket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final dg = _broadcastSocket?.receive();
          if (dg == null) return;

          try {
            final receivedText = utf8.decode(dg.data).trim();
            if (receivedText == probeMessage) {
              final info = SyncDeviceInfo(
                ip: ip,
                port: port,
                deviceName: deviceName,
                pin: pin,
                os: Platform.operatingSystem,
                lastSeen: DateTime.now(),
              );
              final replyBytes = utf8.encode(info.toBeaconMessage());
              _broadcastSocket?.send(replyBytes, dg.address, dg.port);
            }
          } catch (_) {}
        }
      });

      // প্রতি ২ সেকেন্ড পর পর লোকাল সাবনেটে বিযকন পাঠানো
      _beaconTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (_broadcastSocket == null) return;
        try {
          final info = SyncDeviceInfo(
            ip: ip,
            port: port,
            deviceName: deviceName,
            pin: pin,
            os: Platform.operatingSystem,
            lastSeen: DateTime.now(),
          );
          final bytes = utf8.encode(info.toBeaconMessage());
          _broadcastSocket?.send(
            bytes,
            InternetAddress('255.255.255.255'),
            discoveryPort,
          );
        } catch (_) {}
      });
    } catch (_) {
      // যদি পোর্ট বাইন্ডে সমস্যা হয়, সাইক্লিক ফেইলিউর আটকানো
    }
  }

  /// ফোনের জন্য: লোকাল নেটওয়ার্কে কম্পিউটার খোঁজা
  Future<void> startListening() async {
    await stop();
    _discoveredMap.clear();
    _discoveredDevicesController.add([]);

    try {
      _listenSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0, // যেকোনো ফাঁকা পোর্ট
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

      // লোকাল নেটওয়ার্কে প্রোব পাঠানো
      sendProbe();
      _beaconTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        sendProbe();
        _pruneOldDevices();
      });
    } catch (_) {}
  }

  /// লোকাল নেটওয়ার্কে প্রোব রিকোয়েস্ট পাঠানো
  void sendProbe() {
    if (_listenSocket == null) return;
    try {
      final probeBytes = utf8.encode(probeMessage);
      _listenSocket?.send(
        probeBytes,
        InternetAddress('255.255.255.255'),
        discoveryPort,
      );
    } catch (_) {}
  }

  /// পুরনো ইনঅ্যাক্টিভ ডিভাইস তালিকা থেকে বাদ দেওয়া
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

  /// সার্ভিস বন্ধ করা ও সকেট মেমোরি ক্লিন করা
  Future<void> stop() async {
    _beaconTimer?.cancel();
    _beaconTimer = null;

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
