import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analitik/uygulama_olaylari.dart';
import '../analitik/analitik_istemcisi.dart';
import '../analitik/analitik_deposu.dart';
import 'alarm_kurallari.dart';
import 'hata_siniflandirmasi.dart';
import 'istek_izi.dart';
import '../performans/performans_esikleri.dart';

final appTelemetryProvider = Provider<AppTelemetry>((ref) {
  return AppTelemetry(ref.watch(analyticsRepositoryProvider));
});

class AppTelemetry {
  AppTelemetry(this._analytics);

  final AnalyticsRepository _analytics;
  final Random _random = Random();

  Future<T> traceRpc<T>({
    required String operation,
    required Future<T> Function() run,
    Map<String, dynamic>? meta,
    double sampleRate = 1,
  }) async {
    final requestId = createRequestId(prefix: 'rpc');
    final watch = Stopwatch()..start();
    try {
      final data = await run();
      watch.stop();
      _logPerf(
        operation: operation,
        elapsedMs: watch.elapsedMilliseconds,
        ok: true,
        meta: {'request_id': requestId, ...?meta},
        sampleRate: sampleRate,
      );
      return data;
    } catch (error, stack) {
      watch.stop();
      _logPerf(
        operation: operation,
        elapsedMs: watch.elapsedMilliseconds,
        ok: false,
        meta: {'request_id': requestId, ...?meta},
        sampleRate: sampleRate,
      );
      unawaited(
        reportError(
          error,
          stack,
          source: operation,
          extraMeta: {'request_id': requestId},
        ),
      );
      rethrow;
    }
  }

  Future<void> logStartup(
    Duration elapsed, {
    StartupType type = StartupType.cold,
  }) async {
    final clientId = await getAnalyticsClientId();
    final elapsedMs = elapsed.inMilliseconds;
    final budgetMs = startupBudgetMs(type);
    await _analytics.logEvent(
      eventName: 'perf_startup',
      source: 'app',
      clientId: clientId,
      meta: {
        'startup_ms': elapsedMs,
        'startup_type': type.name,
        'slo_budget_ms': budgetMs,
        'slo_ok': elapsedMs <= budgetMs,
      },
    );
    await _analytics.logEvent(
      eventName: AppEvents.appStartMs,
      source: 'app',
      clientId: clientId,
      meta: {
        'value': elapsedMs,
        'startup_type': type.name,
        'slo_budget_ms': budgetMs,
      },
    );
  }

  Future<void> logHomeTti(Duration elapsed) async {
    final clientId = await getAnalyticsClientId();
    final elapsedMs = elapsed.inMilliseconds;
    await _analytics.logEvent(
      eventName: 'perf_home_tti',
      source: 'discover',
      clientId: clientId,
      meta: {
        'home_tti_ms': elapsedMs,
        'slo_budget_ms': PerfSlo.homeTtiP95Ms,
        'slo_ok': elapsedMs <= PerfSlo.homeTtiP95Ms,
      },
    );
    await _analytics.logEvent(
      eventName: AppEvents.homeTtiMs,
      source: 'discover',
      clientId: clientId,
      meta: {'value': elapsedMs, 'slo_budget_ms': PerfSlo.homeTtiP95Ms},
    );
  }

  Future<void> logSearchLatency({
    required Duration elapsed,
    required SearchCacheType cacheType,
    String surface = 'discover_search',
  }) async {
    final clientId = await getAnalyticsClientId();
    final elapsedMs = elapsed.inMilliseconds;
    final budgetMs = searchBudgetMs(cacheType);
    await _analytics.logEvent(
      eventName: 'perf_search',
      source: surface,
      clientId: clientId,
      meta: {
        'search_ms': elapsedMs,
        'cache_type': cacheType.name,
        'slo_budget_ms': budgetMs,
        'slo_ok': elapsedMs <= budgetMs,
      },
    );
    await _analytics.logEvent(
      eventName: AppEvents.searchLatencyMs,
      source: surface,
      clientId: clientId,
      meta: {
        'value': elapsedMs,
        'cache_type': cacheType.name,
        'slo_budget_ms': budgetMs,
      },
    );
  }

  Future<void> logBusinessOpenLatency({
    required Duration elapsed,
    String source = 'business_page',
    String? businessId,
  }) async {
    final clientId = await getAnalyticsClientId();
    final elapsedMs = elapsed.inMilliseconds;
    await _analytics.logEvent(
      eventName: AppEvents.businessOpenMs,
      source: source,
      businessId: businessId,
      clientId: clientId,
      meta: {'value': elapsedMs},
    );
  }

  Future<void> logEmbedOpenLatency({
    required Duration elapsed,
    required String provider,
    required bool fallbackUsed,
    String source = 'embed_viewer',
  }) async {
    final clientId = await getAnalyticsClientId();
    final elapsedMs = elapsed.inMilliseconds;
    await _analytics.logEvent(
      eventName: 'perf_embed_open',
      source: source,
      clientId: clientId,
      meta: {
        'embed_open_ms': elapsedMs,
        'provider': provider,
        'fallback_used': fallbackUsed,
        'slo_budget_ms': PerfSlo.embedOpenP95Ms,
        'slo_ok': elapsedMs <= PerfSlo.embedOpenP95Ms,
      },
    );
    await _analytics.logEvent(
      eventName: AppEvents.embedOpenMs,
      source: source,
      clientId: clientId,
      meta: {
        'value': elapsedMs,
        'provider': provider,
        'fallback_used': fallbackUsed,
        'slo_budget_ms': PerfSlo.embedOpenP95Ms,
      },
    );
  }

  Future<void> logFrameWindow({
    required int sampledFrames,
    required int jankyFrames,
    required int severeFrames,
  }) async {
    if (sampledFrames <= 0) return;
    final clientId = await getAnalyticsClientId();
    final jankRate = jankyFrames / sampledFrames;
    await _analytics.logEvent(
      eventName: 'perf_frames',
      source: 'app',
      clientId: clientId,
      meta: {
        'sampled_frames': sampledFrames,
        'janky_frames': jankyFrames,
        'severe_frames': severeFrames,
        'jank_rate': double.parse(jankRate.toStringAsFixed(4)),
        'frame_budget_ms': PerfSlo.frameBudgetMs,
        'slo_max_jank_rate': PerfSlo.maxJankRate,
        'slo_ok': jankRate <= PerfSlo.maxJankRate,
      },
    );
    await _analytics.logEvent(
      eventName: AppEvents.frameJankRate,
      source: 'app',
      clientId: clientId,
      meta: {
        'value': double.parse(jankRate.toStringAsFixed(4)),
        'sampled_frames': sampledFrames,
        'severe_frames': severeFrames,
      },
    );
  }

  Future<void> logOfflineSync({
    required String reason,
    required int verifySent,
    required int submissionSent,
    required int prunedRecords,
    required bool skipped,
  }) async {
    final clientId = await getAnalyticsClientId();
    final totalWork = verifySent + submissionSent + prunedRecords;
    await _analytics.logEvent(
      eventName: 'offline_sync',
      source: 'offline',
      clientId: clientId,
      meta: {
        'reason': reason,
        'verify_sent': verifySent,
        'submission_sent': submissionSent,
        'pruned_records': prunedRecords,
        'total_work': totalWork,
        'skipped': skipped,
      },
    );
    await _analytics.logEvent(
      eventName: AppEvents.offlineSyncRun,
      source: 'offline',
      clientId: clientId,
      meta: {
        'reason': reason,
        'value': totalWork,
        'verify_sent': verifySent,
        'submission_sent': submissionSent,
        'pruned_records': prunedRecords,
        'skipped': skipped,
      },
    );
  }

  Future<void> logOfflineMutationOutcome({
    required String kind,
    required String disposition,
    required String source,
    String? retryCategory,
    int? retryCount,
    String? detail,
  }) async {
    final clientId = await getAnalyticsClientId();
    final meta = <String, Object?>{
      'kind': kind,
      'disposition': disposition,
    };
    if (retryCategory != null) {
      meta['retry_category'] = retryCategory;
    }
    if (retryCount != null) {
      meta['retry_count'] = retryCount;
    }
    final normalizedDetail = (detail ?? '').trim();
    if (normalizedDetail.isNotEmpty) {
      meta['detail'] = normalizedDetail;
    }
    await _analytics.logEvent(
      eventName: AppEvents.offlineMutationOutcome,
      source: source,
      clientId: clientId,
      meta: meta,
    );
  }

  Future<void> logConnectivityRestore({
    required String trigger,
    required int replayWork,
  }) async {
    final clientId = await getAnalyticsClientId();
    await _analytics.logEvent(
      eventName: AppEvents.connectivityRestored,
      source: 'offline',
      clientId: clientId,
      meta: {
        'trigger': trigger,
        'replay_work': replayWork,
      },
    );
  }

  Future<void> logConnectivityStateChange({
    required String trigger,
    required bool online,
  }) async {
    final clientId = await getAnalyticsClientId();
    await _analytics.logEvent(
      eventName: AppEvents.connectivityStateChange,
      source: 'offline',
      clientId: clientId,
      meta: {
        'trigger': trigger,
        'online': online,
      },
    );
  }

  Future<void> reportError(
    Object error,
    StackTrace stack, {
    String source = 'app',
    Map<String, Object?>? extraMeta,
  }) async {
    final clientId = await getAnalyticsClientId();
    final message = error.toString();
    final taxonomy = classifyError(error);
    await _analytics.logEvent(
      eventName: 'app_error',
      source: source,
      clientId: clientId,
      meta: {
        'taxonomy': taxonomy.name,
        'error': message.substring(0, min(message.length, 300)),
        'stack': stack.toString().substring(
          0,
          min(stack.toString().length, 800),
        ),
        ...?extraMeta,
      },
    );
  }

  Future<void> evaluateAndAlert({
    required double crashFreeRate,
    required int homeTtiP95Ms,
    required int edge429CurrentCount,
    required int edge429BaselineCount,
  }) async {
    if (AlertRules.shouldAlertCrashFree(crashFreeRate)) {
      await _analytics.logEvent(
        eventName: AppEvents.observabilityAlert,
        source: 'alerting',
        meta: {
          'alert_type': 'crash_free_below_99_8',
          'crash_free_rate': crashFreeRate,
        },
      );
    }
    if (AlertRules.shouldAlertHomeTtiP95(homeTtiP95Ms)) {
      await _analytics.logEvent(
        eventName: AppEvents.observabilityAlert,
        source: 'alerting',
        meta: {
          'alert_type': 'home_tti_p95_above_target',
          'home_tti_p95_ms': homeTtiP95Ms,
          'threshold_ms': PerfSlo.homeTtiP95Ms,
        },
      );
    }
    if (AlertRules.shouldAlertEdge429Spike(
      currentWindow429Count: edge429CurrentCount,
      baselineWindow429Count: edge429BaselineCount,
    )) {
      await _analytics.logEvent(
        eventName: AppEvents.observabilityAlert,
        source: 'alerting',
        meta: {
          'alert_type': 'edge_429_spike',
          'current_429': edge429CurrentCount,
          'baseline_429': edge429BaselineCount,
        },
      );
    }
  }

  Future<void> _logPerf({
    required String operation,
    required int elapsedMs,
    required bool ok,
    required double sampleRate,
    Map<String, dynamic>? meta,
  }) async {
    final shouldSample = sampleRate >= 1 || _random.nextDouble() <= sampleRate;
    if (!shouldSample) return;
    final clientId = await getAnalyticsClientId();
    await _analytics.logEvent(
      eventName: 'perf_rpc',
      source: operation,
      clientId: clientId,
      meta: <String, dynamic>{
        'operation': operation,
        'elapsed_ms': elapsedMs,
        'ok': ok,
        ...?meta,
      },
    );
  }
}
