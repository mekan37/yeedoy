import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../monitoring/app_telemetry.dart';
import '../../features/auth/domain/auth_providers.dart';
import '../../features/menus/data/menu_repository.dart';
import '../network/supabase_provider.dart';
import 'local_db/local_db_provider.dart';
import 'offline_mutation_queue.dart';
import 'offline_submission_queue.dart';

class OfflineSyncResult {
  const OfflineSyncResult({
    required this.verifySent,
    required this.submissionSent,
    required this.prunedRecords,
    required this.reason,
    this.skipped = false,
  });

  final int verifySent;
  final int submissionSent;
  final int prunedRecords;
  final String reason;
  final bool skipped;

  int get totalWork => verifySent + submissionSent + prunedRecords;
}

class OfflineSyncService with WidgetsBindingObserver {
  OfflineSyncService({
    required Future<int> Function({int maxItems}) flushVerifyQueue,
    required Future<int> Function({int maxItems}) flushSubmissionQueue,
    required Future<int> Function() pruneSnapshots,
    required bool Function() canFlushSubmissionQueue,
    required Future<void> Function(OfflineSyncResult result) reportSyncResult,
    required Future<void> Function(
      Object error,
      StackTrace stackTrace,
      String reason,
    )
    reportSyncError,
    DateTime Function()? now,
    Duration minInterval = const Duration(seconds: 20),
  }) : _flushVerifyQueue = flushVerifyQueue,
       _flushSubmissionQueue = flushSubmissionQueue,
       _pruneSnapshots = pruneSnapshots,
       _canFlushSubmissionQueue = canFlushSubmissionQueue,
       _reportSyncResult = reportSyncResult,
       _reportSyncError = reportSyncError,
       _now = now ?? DateTime.now,
       _minInterval = minInterval;

  final Future<int> Function({int maxItems}) _flushVerifyQueue;
  final Future<int> Function({int maxItems}) _flushSubmissionQueue;
  final Future<int> Function() _pruneSnapshots;
  final bool Function() _canFlushSubmissionQueue;
  final Future<void> Function(OfflineSyncResult result) _reportSyncResult;
  final Future<void> Function(Object error, StackTrace stackTrace, String reason)
  _reportSyncError;
  final DateTime Function() _now;
  final Duration _minInterval;

  DateTime? _lastAttemptAt;
  bool _started = false;
  bool _syncing = false;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    unawaited(syncNow(reason: 'start'));
  }

  void stop() {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
  }

  Future<OfflineSyncResult> syncNow({
    String reason = 'manual',
    bool ignoreBackoff = false,
  }) async {
    final current = _now();
    if (_syncing) {
      final result = OfflineSyncResult(
        verifySent: 0,
        submissionSent: 0,
        prunedRecords: 0,
        reason: reason,
        skipped: true,
      );
      unawaited(_reportSyncResult(result));
      return result;
    }
    if (!ignoreBackoff && _lastAttemptAt != null) {
      final age = current.difference(_lastAttemptAt!);
      if (age < _minInterval) {
        final result = OfflineSyncResult(
          verifySent: 0,
          submissionSent: 0,
          prunedRecords: 0,
          reason: reason,
          skipped: true,
        );
        unawaited(_reportSyncResult(result));
        return result;
      }
    }

    _syncing = true;
    _lastAttemptAt = current;
    try {
      final verifySent = await _flushVerifyQueue(maxItems: 20);
      final submissionSent = _canFlushSubmissionQueue()
          ? await _flushSubmissionQueue(maxItems: 25)
          : 0;
      final prunedRecords = await _pruneSnapshots();
      final result = OfflineSyncResult(
        verifySent: verifySent,
        submissionSent: submissionSent,
        prunedRecords: prunedRecords,
        reason: reason,
      );
      unawaited(_reportSyncResult(result));
      return result;
    } catch (error, stackTrace) {
      unawaited(_reportSyncError(error, stackTrace, reason));
      rethrow;
    } finally {
      _syncing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(syncNow(reason: 'resume'));
  }
}

final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService(
    flushVerifyQueue: ({int maxItems = 20}) {
      return ref.read(menuRepositoryProvider).flushOfflineVerifyQueue(
        maxItems: maxItems,
      );
    },
    flushSubmissionQueue: ({int maxItems = 25}) {
      return flushOfflineSubmissionQueue(
        ref.read(supabaseProvider),
        maxItems: maxItems,
        reportOutcome: ({
          required OfflineMutationQueueKind kind,
          required String disposition,
          OfflineMutationRetryCategory? retryCategory,
          required int retryCount,
          String? detail,
        }) {
          return ref.read(appTelemetryProvider).logOfflineMutationOutcome(
            kind: kind.name,
            disposition: disposition,
            source: 'offline_submission_replay',
            retryCategory: retryCategory?.name,
            retryCount: retryCount,
            detail: detail,
          );
        },
      );
    },
    pruneSnapshots: () {
      return ref.read(localDbStoreProvider).pruneExpired();
    },
    canFlushSubmissionQueue: () => ref.read(sessionProvider) != null,
    reportSyncResult: (result) {
      return ref.read(appTelemetryProvider).logOfflineSync(
        reason: result.reason,
        verifySent: result.verifySent,
        submissionSent: result.submissionSent,
        prunedRecords: result.prunedRecords,
        skipped: result.skipped,
      );
    },
    reportSyncError: (error, stackTrace, reason) {
      return ref.read(appTelemetryProvider).reportError(
        error,
        stackTrace,
        source: 'offline_sync_$reason',
      );
    },
  );
});

final offlineSyncLifecycleProvider = Provider<void>((ref) {
  final service = ref.read(offlineSyncServiceProvider);
  service.start();
  ref.listen(sessionProvider, (previous, next) {
    if (previous == null && next != null) {
      unawaited(service.syncNow(reason: 'session_restore', ignoreBackoff: true));
    }
  });
  ref.onDispose(service.stop);
});
