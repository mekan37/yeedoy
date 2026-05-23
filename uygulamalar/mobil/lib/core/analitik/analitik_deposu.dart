import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../ayarlar/gelistirme_istisnalar.dart';
import '../ag/supabase_saglayicisi.dart';

typedef _AnalyticsRpc =
    Future<dynamic> Function(String fn, {Map<String, dynamic>? params});
typedef _CurrentUserId = String? Function();

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  final overrides = ref.watch(devOverridesProvider);
  final deposu = AnalyticsRepository(
    client,
    devUserId: overrides.testUserId,
  );
  ref.onDispose(deposu.dispose);
  return deposu;
});

class AnalyticsRepository {
  AnalyticsRepository(
    SupabaseClient client, {
    String? devUserId,
    int maxQueueSize = 200,
    int maxBatchSize = 16,
    int maxAttempts = 4,
    Duration retryBaseDelay = const Duration(seconds: 2),
    Duration maxRetryDelay = const Duration(minutes: 1),
    DateTime Function()? now,
    Random? random,
  }) : this._(
         rpc: (fn, {params}) => client.rpc(fn, params: params),
         currentUserId: () => client.auth.currentUser?.id,
         devUserId: devUserId,
         maxQueueSize: maxQueueSize,
         maxBatchSize: maxBatchSize,
         maxAttempts: maxAttempts,
         retryBaseDelay: retryBaseDelay,
         maxRetryDelay: maxRetryDelay,
         now: now ?? DateTime.now,
         random: random ?? Random(),
       );

  @visibleForTesting
  AnalyticsRepository.forTest({
    required Future<dynamic> Function(String fn, {Map<String, dynamic>? params})
    rpc,
    String? Function()? currentUserId,
    String? devUserId,
    int maxQueueSize = 200,
    int maxBatchSize = 16,
    int maxAttempts = 4,
    Duration retryBaseDelay = const Duration(seconds: 2),
    Duration maxRetryDelay = const Duration(minutes: 1),
    DateTime Function()? now,
    Random? random,
  }) : this._(
         rpc: rpc,
         currentUserId: currentUserId ?? _nullUserId,
         devUserId: devUserId,
         maxQueueSize: maxQueueSize,
         maxBatchSize: maxBatchSize,
         maxAttempts: maxAttempts,
         retryBaseDelay: retryBaseDelay,
         maxRetryDelay: maxRetryDelay,
         now: now ?? DateTime.now,
         random: random ?? Random(1),
       );

  AnalyticsRepository._({
    required _AnalyticsRpc rpc,
    required _CurrentUserId currentUserId,
    required this.devUserId,
    required int maxQueueSize,
    required int maxBatchSize,
    required int maxAttempts,
    required Duration retryBaseDelay,
    required Duration maxRetryDelay,
    required DateTime Function() now,
    required Random random,
  }) : _rpc = rpc,
       _currentUserId = currentUserId,
       _maxQueueSize = maxQueueSize,
       _maxBatchSize = maxBatchSize,
       _maxAttempts = maxAttempts,
       _retryBaseDelay = retryBaseDelay,
       _maxRetryDelay = maxRetryDelay,
       _now = now,
       _random = random;

  final _AnalyticsRpc _rpc;
  final _CurrentUserId _currentUserId;
  final String? devUserId;

  final int _maxQueueSize;
  final int _maxBatchSize;
  final int _maxAttempts;
  final Duration _retryBaseDelay;
  final Duration _maxRetryDelay;
  final DateTime Function() _now;
  final Random _random;

  final List<_QueuedAnalyticsEvent> _queue = <_QueuedAnalyticsEvent>[];
  Future<void> _flushChain = Future<void>.value();
  Timer? _flushTimer;
  DateTime? _nextFlushAt;
  bool _disposed = false;
  int _droppedEvents = 0;

  @visibleForTesting
  int get pendingEvents => _queue.length;

  @visibleForTesting
  int get droppedEvents => _droppedEvents;

  Future<bool> logEvent({
    required String eventName,
    String? businessId,
    String? menuId,
    String? source,
    String? clientId,
    Map<String, dynamic>? meta,
  }) async {
    final payload = _AnalyticsPayload(
      eventName: eventName,
      businessId: businessId,
      menuId: menuId,
      source: source,
      clientId: clientId,
      meta: _buildMeta(meta, businessId: businessId, menuId: menuId),
    );

    final sent = await _send(payload);
    if (sent) return true;

    _enqueue(_QueuedAnalyticsEvent(payload: payload, nextAttemptAt: _now()));
    _scheduleFlush(_retryBaseDelay);
    return false;
  }

  @visibleForTesting
  Future<void> flushNow({bool ignoreBackoff = true}) async {
    _flushTimer?.cancel();
    _flushTimer = null;
    _nextFlushAt = null;
    _flushChain = _flushChain.then((_) => _flushReady(force: ignoreBackoff));
    await _flushChain;
  }

  void dispose() {
    _disposed = true;
    _flushTimer?.cancel();
    _flushTimer = null;
    _nextFlushAt = null;
  }

  Map<String, dynamic> _buildMeta(
    Map<String, dynamic>? meta, {
    String? businessId,
    String? menuId,
  }) {
    final nextMeta = <String, dynamic>{};
    if (meta != null) nextMeta.addAll(meta);

    final overrideUser = (devUserId ?? '').trim();
    final userId = overrideUser.isNotEmpty ? overrideUser : _currentUserId();
    if (userId != null && userId.trim().isNotEmpty) {
      nextMeta.putIfAbsent('user_id', () => userId);
    }
    if (businessId != null && businessId.isNotEmpty) {
      nextMeta.putIfAbsent('business_id', () => businessId);
    }
    if (menuId != null && menuId.isNotEmpty) {
      nextMeta.putIfAbsent('menu_id', () => menuId);
    }
    return nextMeta;
  }

  Future<bool> _send(_AnalyticsPayload payload) async {
    try {
      final res = await _rpc('log_event_v1', params: payload.toRpcParams());
      if (res is Map && res['ok'] == true) return true;
      if (res is List && res.isNotEmpty && res.first is Map) {
        final m = res.first as Map;
        return m['ok'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _enqueue(_QueuedAnalyticsEvent event) {
    if (_disposed) return;
    if (_queue.length >= _maxQueueSize) {
      _queue.removeAt(0);
      _droppedEvents += 1;
    }
    _queue.add(event);
  }

  void _scheduleFlush(Duration delay) {
    if (_disposed || _queue.isEmpty) return;
    final now = _now();
    final nextAt = now.add(delay.isNegative ? Duration.zero : delay);

    if (_nextFlushAt != null && _nextFlushAt!.isBefore(nextAt)) {
      return;
    }

    _flushTimer?.cancel();
    _nextFlushAt = nextAt;
    final wait = nextAt.isBefore(now) ? Duration.zero : nextAt.difference(now);
    _flushTimer = Timer(wait, _startFlush);
  }

  void _startFlush() {
    _flushTimer = null;
    _nextFlushAt = null;
    _flushChain = _flushChain.then((_) => _flushReady(force: false));
  }

  Future<void> _flushReady({required bool force}) async {
    if (_disposed || _queue.isEmpty) return;

    final now = _now();
    final ready = <_QueuedAnalyticsEvent>[];
    for (final event in _queue) {
      if (force || !event.nextAttemptAt.isAfter(now)) {
        ready.add(event);
      }
      if (ready.length >= _maxBatchSize) break;
    }

    if (ready.isEmpty) {
      _scheduleNextFlush();
      return;
    }

    for (final event in ready) {
      final ok = await _send(event.payload);
      if (ok) {
        _queue.remove(event);
        continue;
      }

      event.attempts += 1;
      if (event.attempts >= _maxAttempts) {
        _queue.remove(event);
        continue;
      }
      event.nextAttemptAt = _now().add(_backoffForAttempt(event.attempts));
    }

    _scheduleNextFlush();
  }

  void _scheduleNextFlush() {
    if (_disposed || _queue.isEmpty) return;
    final now = _now();
    DateTime nextAt = _queue.first.nextAttemptAt;
    for (final event in _queue.skip(1)) {
      if (event.nextAttemptAt.isBefore(nextAt)) {
        nextAt = event.nextAttemptAt;
      }
    }
    final delay = nextAt.isBefore(now) ? Duration.zero : nextAt.difference(now);
    _scheduleFlush(delay);
  }

  Duration _backoffForAttempt(int attempt) {
    final safeAttempt = attempt <= 0 ? 1 : attempt;
    final factor = 1 << (safeAttempt - 1);
    final baseMs = _retryBaseDelay.inMilliseconds * factor;
    final cappedMs = min(baseMs, _maxRetryDelay.inMilliseconds);
    final jitter = _random.nextInt(350);
    return Duration(milliseconds: cappedMs + jitter);
  }
}

String? _nullUserId() => null;

class _AnalyticsPayload {
  const _AnalyticsPayload({
    required this.eventName,
    required this.businessId,
    required this.menuId,
    required this.source,
    required this.clientId,
    required this.meta,
  });

  final String eventName;
  final String? businessId;
  final String? menuId;
  final String? source;
  final String? clientId;
  final Map<String, dynamic> meta;

  Map<String, dynamic> toRpcParams() {
    return {
      'p_event_name': eventName,
      'p_business_id': businessId,
      'p_menu_id': menuId,
      'p_source': source,
      'p_client_id': clientId,
      'p_meta': meta,
    };
  }
}

class _QueuedAnalyticsEvent {
  _QueuedAnalyticsEvent({required this.payload, required this.nextAttemptAt});

  final _AnalyticsPayload payload;
  DateTime nextAttemptAt;
  int attempts = 0;
}
