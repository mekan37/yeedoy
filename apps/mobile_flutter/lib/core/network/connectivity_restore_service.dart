import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../monitoring/app_telemetry.dart';
import '../storage/offline_sync_service.dart';

class ConnectivityRestoreEvent {
  const ConnectivityRestoreEvent({
    required this.online,
    required this.restored,
    required this.trigger,
  });

  final bool online;
  final bool restored;
  final String trigger;
}

class ConnectivityRestoreService with WidgetsBindingObserver {
  ConnectivityRestoreService({
    required Future<bool> Function() probeOnline,
    required Future<void> Function(String trigger) onConnectivityRestored,
    required Future<void> Function(ConnectivityRestoreEvent event)
    reportConnectivityEvent,
    Duration probeInterval = const Duration(seconds: 45),
  }) : _probeOnline = probeOnline,
       _onConnectivityRestored = onConnectivityRestored,
       _reportConnectivityEvent = reportConnectivityEvent,
       _probeInterval = probeInterval;

  final Future<bool> Function() _probeOnline;
  final Future<void> Function(String trigger) _onConnectivityRestored;
  final Future<void> Function(ConnectivityRestoreEvent event)
  _reportConnectivityEvent;
  final Duration _probeInterval;

  Timer? _timer;
  bool? _lastOnline;
  bool _started = false;
  bool _probing = false;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(
      _probeInterval,
      (_) => unawaited(probeNow(trigger: 'heartbeat')),
    );
    unawaited(probeNow(trigger: 'start'));
  }

  void stop() {
    if (!_started) return;
    _started = false;
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  Future<void> probeNow({String trigger = 'manual'}) async {
    if (_probing) return;
    _probing = true;
    try {
      final online = await _probeOnline();
      final restored = _lastOnline == false && online;
      final changed = _lastOnline != null && _lastOnline != online;
      _lastOnline = online;

      if (restored) {
        await _onConnectivityRestored(trigger);
      }
      if (restored || changed) {
        await _reportConnectivityEvent(
          ConnectivityRestoreEvent(
            online: online,
            restored: restored,
            trigger: trigger,
          ),
        );
      }
    } finally {
      _probing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(probeNow(trigger: 'resume'));
  }
}

final connectivityRestoreServiceProvider = Provider<ConnectivityRestoreService>((
  ref,
) {
  return ConnectivityRestoreService(
    probeOnline: () => _probeSupabaseReachability(),
    onConnectivityRestored: (trigger) async {
      final result = await ref.read(offlineSyncServiceProvider).syncNow(
        reason: 'connectivity_restore',
        ignoreBackoff: true,
      );
      await ref.read(appTelemetryProvider).logConnectivityRestore(
        trigger: trigger,
        replayWork: result.totalWork,
      );
    },
    reportConnectivityEvent: (event) {
      if (event.restored) {
        return Future<void>.value();
      }
      return ref.read(appTelemetryProvider).logConnectivityStateChange(
        trigger: event.trigger,
        online: event.online,
      );
    },
  );
});

final connectivityRestoreLifecycleProvider = Provider<void>((ref) {
  final service = ref.read(connectivityRestoreServiceProvider);
  service.start();
  ref.onDispose(service.stop);
});

Future<bool> _probeSupabaseReachability() async {
  final baseUrl = (dotenv.env['SUPABASE_URL'] ?? '').trim();
  if (baseUrl.isEmpty) return true;

  final probeUri = Uri.parse('$baseUrl/auth/v1/settings');
  try {
    final response = await http
        .get(probeUri, headers: const <String, String>{'x-yeedoy-probe': '1'})
        .timeout(const Duration(seconds: 4));
    return response.statusCode < 500;
  } catch (_) {
    return false;
  }
}
