import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../main.dart';
import '../../../backup/presentation/providers/backup_providers.dart';
import '../../data/services/sync_client_service.dart';
import '../../data/services/sync_discovery_service.dart';
import '../../data/services/sync_server_service.dart';
import '../../domain/models/sync_device_info.dart';
import '../../domain/models/sync_result.dart';

/// ডিসকভারি সার্ভিস প্রোভাইডার
final syncDiscoveryServiceProvider = Provider<SyncDiscoveryService>((ref) {
  final service = SyncDiscoveryService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// লোকাল নেটওয়ার্কে খুঁজে পাওয়া পিসির স্ট্রিম
final discoveredPcsStreamProvider =
    StreamProvider<List<SyncDeviceInfo>>((ref) {
  final discovery = ref.watch(syncDiscoveryServiceProvider);
  return discovery.discoveredDevicesStream;
});

/// সার্ভার সার্ভিস প্রোভাইডার
final syncServerServiceProvider = Provider<SyncServerService>((ref) {
  if (SyncServerService.currentRunningInstance != null) {
    return SyncServerService.currentRunningInstance!;
  }
  final backupRepo = ref.watch(backupRepositoryProvider);
  final discovery = ref.watch(syncDiscoveryServiceProvider);
  final service = SyncServerService(backupRepo, discoveryService: discovery);
  ref.onDispose(() => service.dispose());
  return service;
});

/// ক্লায়েন্ট সার্ভিস প্রোভাইডার
final syncClientServiceProvider = Provider<SyncClientService>((ref) {
  final backupRepo = ref.watch(backupRepositoryProvider);
  return SyncClientService(backupRepo);
});

/// পিসি সার্ভার স্টেট মডেল
class SyncServerUiState {
  final bool isRunning;
  final String currentIp;
  final List<String> availableIps;
  final int port;
  final String pin;
  final DateTime? lastSyncTime;
  final SyncResult? lastResult;

  const SyncServerUiState({
    required this.isRunning,
    required this.currentIp,
    required this.availableIps,
    required this.port,
    required this.pin,
    this.lastSyncTime,
    this.lastResult,
  });

  SyncServerUiState copyWith({
    bool? isRunning,
    String? currentIp,
    List<String>? availableIps,
    int? port,
    String? pin,
    DateTime? lastSyncTime,
    SyncResult? lastResult,
  }) {
    return SyncServerUiState(
      isRunning: isRunning ?? this.isRunning,
      currentIp: currentIp ?? this.currentIp,
      availableIps: availableIps ?? this.availableIps,
      port: port ?? this.port,
      pin: pin ?? this.pin,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}

/// পিসি সার্ভার স্টেট নোটিফায়ার
class SyncServerController extends StateNotifier<SyncServerUiState> {
  final SyncServerService _serverService;

  SyncServerController(this._serverService)
      : super(SyncServerUiState(
          isRunning: _serverService.isRunning,
          currentIp: _serverService.currentIp,
          availableIps: _serverService.availableIps,
          port: _serverService.port,
          pin: _serverService.pin,
          lastSyncTime: _serverService.lastSyncTime,
        )) {
    // সিঙ্ক ইভেন্ট শোনার লিসেনার
    _serverService.syncEventsStream.listen((result) {
      state = state.copyWith(
        lastSyncTime: _serverService.lastSyncTime,
        lastResult: result,
      );
    });
  }

  /// সার্ভার স্টার্ট করা
  Future<bool> startServer({
    int port = 8765,
    String? pin,
    void Function(AppDatabase newDb)? onDatabaseReopened,
  }) async {
    final success = await _serverService.startServer(
      port: port,
      pin: pin,
      onDatabaseReopened: onDatabaseReopened ??
          (newDb) {
            rootAppKey.currentState?.replaceDatabase(newDb);
          },
    );

    state = state.copyWith(
      isRunning: _serverService.isRunning,
      currentIp: _serverService.currentIp,
      availableIps: _serverService.availableIps,
      port: _serverService.port,
      pin: _serverService.pin,
    );

    return success;
  }

  /// সার্ভার বন্ধ করা
  Future<void> stopServer() async {
    await _serverService.stopServer();
    state = state.copyWith(isRunning: false);
  }

  /// পিন পরিবর্তন করা
  void updatePin(String newPin) {
    _serverService.setPin(newPin);
    state = state.copyWith(pin: _serverService.pin);
  }
}

final syncServerControllerProvider =
    StateNotifierProvider<SyncServerController, SyncServerUiState>((ref) {
  final serverService = ref.watch(syncServerServiceProvider);
  return SyncServerController(serverService);
});

/// ফোন ক্লায়েন্ট স্টেট মডেল
class SyncClientUiState {
  final bool isSending;
  final String statusMessage;
  final SyncResult? lastResult;

  const SyncClientUiState({
    this.isSending = false,
    this.statusMessage = '',
    this.lastResult,
  });

  SyncClientUiState copyWith({
    bool? isSending,
    String? statusMessage,
    SyncResult? lastResult,
  }) {
    return SyncClientUiState(
      isSending: isSending ?? this.isSending,
      statusMessage: statusMessage ?? this.statusMessage,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}

/// ফোন ক্লায়েন্ট স্টেট নোটিফায়ার
class SyncClientController extends StateNotifier<SyncClientUiState> {
  final SyncClientService _clientService;

  SyncClientController(this._clientService) : super(const SyncClientUiState());

  Future<SyncResult> sendData({
    required String ip,
    List<String> allIps = const [],
    required int port,
    required String pin,
  }) async {
    state = state.copyWith(
      isSending: true,
      statusMessage: 'প্রস্তুত হচ্ছে...',
      lastResult: null,
    );

    final result = await _clientService.sendDataToPc(
      ip: ip,
      allIps: allIps,
      port: port,
      pin: pin,
      onProgress: (msg) {
        state = state.copyWith(statusMessage: msg);
      },
    );

    state = state.copyWith(
      isSending: false,
      statusMessage: '',
      lastResult: result,
    );

    return result;
  }
}

final syncClientControllerProvider =
    StateNotifierProvider<SyncClientController, SyncClientUiState>((ref) {
  final clientService = ref.watch(syncClientServiceProvider);
  return SyncClientController(clientService);
});
