import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_db/default_local_db_store.dart';
import 'local_db/local_db_models.dart';
import 'local_db/local_db_store.dart';

enum OfflineMutationQueueKind {
  verifyVotePrice,
  verifySuggestPrice,
  reportBusiness,
  reportReview,
  reportMenuPhoto,
  reviewCreate,
  businessSuggestion,
}

enum OfflineMutationQueueStatus { pending, retrying }

enum OfflineMutationRetryCategory { network, auth, rateLimit, server, unknown }

class OfflineMutationRetryPolicy {
  const OfflineMutationRetryPolicy({
    required this.category,
    required this.baseDelay,
    required this.maxDelay,
  });

  final OfflineMutationRetryCategory category;
  final Duration baseDelay;
  final Duration maxDelay;
}

extension OfflineMutationQueueKindX on OfflineMutationQueueKind {
  String get family {
    return switch (this) {
      OfflineMutationQueueKind.verifyVotePrice => 'verify',
      OfflineMutationQueueKind.verifySuggestPrice => 'verify',
      OfflineMutationQueueKind.reportBusiness => 'submission',
      OfflineMutationQueueKind.reportReview => 'submission',
      OfflineMutationQueueKind.reportMenuPhoto => 'submission',
      OfflineMutationQueueKind.reviewCreate => 'submission',
      OfflineMutationQueueKind.businessSuggestion => 'submission',
    };
  }
}

class OfflineMutationQueueItem {
  const OfflineMutationQueueItem({
    required this.id,
    required this.kind,
    required this.createdAt,
    required this.payload,
    this.status = OfflineMutationQueueStatus.pending,
    this.retryCount = 0,
    this.lastError,
    this.nextRetryAt,
    this.lastAttemptAt,
  });

  final String id;
  final OfflineMutationQueueKind kind;
  final DateTime createdAt;
  final Map<String, dynamic> payload;
  final OfflineMutationQueueStatus status;
  final int retryCount;
  final String? lastError;
  final DateTime? nextRetryAt;
  final DateTime? lastAttemptAt;

  bool isReady(DateTime now) {
    final retryAt = nextRetryAt;
    if (retryAt == null) return true;
    return !retryAt.isAfter(now);
  }

  OfflineMutationQueueItem copyWith({
    OfflineMutationQueueKind? kind,
    DateTime? createdAt,
    Map<String, dynamic>? payload,
    OfflineMutationQueueStatus? status,
    int? retryCount,
    String? lastError,
    DateTime? nextRetryAt,
    DateTime? lastAttemptAt,
  }) {
    return OfflineMutationQueueItem(
      id: id,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      nextRetryAt: nextRetryAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    );
  }

  Map<String, dynamic> toPayloadMap() {
    return <String, dynamic>{
      'kind': kind.name,
      'family': kind.family,
      'created_at': createdAt.toUtc().toIso8601String(),
      'payload': payload,
      'status': status.name,
      'retry_count': retryCount,
      'last_error': lastError,
      'next_retry_at': nextRetryAt?.toUtc().toIso8601String(),
      'last_attempt_at': lastAttemptAt?.toUtc().toIso8601String(),
      'type': 'offline_mutation',
    };
  }

  factory OfflineMutationQueueItem.fromRecord(LocalDbRecord record) {
    final map = record.payload;
    final kindRaw = (map['kind'] ?? '').toString();
    final kind = OfflineMutationQueueKind.values.firstWhere(
      (value) => value.name == kindRaw,
      orElse: () => OfflineMutationQueueKind.reportBusiness,
    );
    final payloadRaw = map['payload'];
    final payload = payloadRaw is Map
        ? payloadRaw.cast<String, dynamic>()
        : <String, dynamic>{};
    final createdAt = DateTime.tryParse(
          (map['created_at'] ?? '').toString(),
        )?.toUtc() ??
        record.updatedAt.toUtc();
    final statusRaw = (map['status'] ?? '').toString();
    final status = OfflineMutationQueueStatus.values.firstWhere(
      (value) => value.name == statusRaw,
      orElse: () => OfflineMutationQueueStatus.pending,
    );
    final retryCount = _asInt(map['retry_count']) ?? 0;
    final lastErrorText = (map['last_error'] ?? '').toString().trim();
    final nextRetryAt = DateTime.tryParse(
      (map['next_retry_at'] ?? '').toString(),
    )?.toUtc();
    final lastAttemptAt = DateTime.tryParse(
      (map['last_attempt_at'] ?? '').toString(),
    )?.toUtc();
    return OfflineMutationQueueItem(
      id: record.id,
      kind: kind,
      createdAt: createdAt,
      payload: payload,
      status: status,
      retryCount: retryCount,
      lastError: lastErrorText.isEmpty ? null : lastErrorText,
      nextRetryAt: nextRetryAt,
      lastAttemptAt: lastAttemptAt,
    );
  }
}

enum OfflineMutationFailureDisposition { retry, resolve, drop }

class OfflineMutationFailureDecision {
  const OfflineMutationFailureDecision({
    required this.disposition,
    required this.reason,
  });

  final OfflineMutationFailureDisposition disposition;
  final String reason;
}

OfflineMutationFailureDecision classifyOfflineMutationError(Object error) {
  final text = error.toString().toLowerCase();
  if (_isRetryableMutationError(text)) {
    return const OfflineMutationFailureDecision(
      disposition: OfflineMutationFailureDisposition.retry,
      reason: 'retryable',
    );
  }
  if (_isConflictResolvedError(text)) {
    return const OfflineMutationFailureDecision(
      disposition: OfflineMutationFailureDisposition.resolve,
      reason: 'conflict_resolved',
    );
  }
  return const OfflineMutationFailureDecision(
    disposition: OfflineMutationFailureDisposition.drop,
    reason: 'permanent_rejection',
  );
}

class OfflineMutationQueueStore {
  static const _legacyVerifyQueueKey = 'offline_verify_queue_v1';
  static const _legacySubmissionQueueKey = 'offline_submission_queue_v1';
  static const _legacyMigrationKey = 'offline_mutation_queue_migrated_v1';
  static const _verifyMaxItems = 200;
  static const _submissionMaxItems = 300;

  static LocalDbStore? _debugStore;
  static LocalDbStore? _defaultStore;
  static Future<void>? _legacyMigrationFuture;

  @visibleForTesting
  static Future<void> setStoreForTesting(LocalDbStore? store) async {
    _debugStore = store;
    _defaultStore = null;
    _legacyMigrationFuture = null;
    resetDefaultLocalDbStoreForTesting();
    if (store != null) {
      await store.initialize();
    }
  }

  static Future<void> enqueue({
    required OfflineMutationQueueKind kind,
    required Map<String, dynamic> payload,
    String? id,
    DateTime? createdAt,
  }) async {
    final store = await _store();
    final now = (createdAt ?? DateTime.now()).toUtc();
    final normalizedId = (id ?? '').trim();
    final payloadId = (payload['idempotency_key'] ?? '').toString().trim();
    final item = OfflineMutationQueueItem(
      id: normalizedId.isEmpty
          ? (payloadId.isEmpty
                ? '${now.microsecondsSinceEpoch}_${kind.name}'
                : payloadId)
          : normalizedId,
      kind: kind,
      createdAt: now,
      payload: Map<String, dynamic>.from(payload),
    );
    await _writeItem(store, item);
    await _trimFamily(store, family: kind.family);
  }

  static Future<List<OfflineMutationQueueItem>> readAll({
    Set<OfflineMutationQueueKind>? kinds,
    int limit = 500,
  }) async {
    final store = await _store();
    final records = await store.list(
      LocalDbBucket.offlineMutationQueue,
      limit: limit,
      allowExpired: true,
    );
    final allowedKinds = kinds;
    final items = records
        .map(OfflineMutationQueueItem.fromRecord)
        .where((item) => allowedKinds == null || allowedKinds.contains(item.kind))
        .toList(growable: false)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  static Future<List<OfflineMutationQueueItem>> readReady({
    Set<OfflineMutationQueueKind>? kinds,
    int limit = 100,
    DateTime? now,
  }) async {
    final pivot = (now ?? DateTime.now()).toUtc();
    final items = await readAll(kinds: kinds, limit: 1000);
    return items
        .where((item) => item.isReady(pivot))
        .take(limit)
        .toList(growable: false);
  }

  static Future<void> remove(String id) async {
    final store = await _store();
    await store.remove(LocalDbBucket.offlineMutationQueue, id);
  }

  static Future<void> markRetry(
    OfflineMutationQueueItem item, {
    required Object error,
    DateTime? now,
  }) async {
    final store = await _store();
    final pivot = (now ?? DateTime.now()).toUtc();
    final nextRetryCount = item.retryCount + 1;
    final policy = resolveOfflineMutationRetryPolicy(item.kind, error);
    final updated = item.copyWith(
      status: OfflineMutationQueueStatus.retrying,
      retryCount: nextRetryCount,
      lastError: _normalizeError(error),
      nextRetryAt: pivot.add(_retryBackoff(policy, nextRetryCount)),
      lastAttemptAt: pivot,
    );
    await _writeItem(store, updated);
  }

  static Future<void> replaceKinds({
    required Set<OfflineMutationQueueKind> kinds,
    required List<OfflineMutationQueueItem> items,
  }) async {
    final store = await _store();
    final existing = await readAll(kinds: kinds, limit: 2000);
    for (final item in existing) {
      await store.remove(LocalDbBucket.offlineMutationQueue, item.id);
    }
    for (final item in items) {
      await _writeItem(store, item);
    }
  }

  static Future<int> count({
    Set<OfflineMutationQueueKind>? kinds,
  }) async {
    final items = await readAll(kinds: kinds, limit: 2000);
    return items.length;
  }

  static Future<LocalDbStore> _store() async {
    final store = _debugStore ?? (_defaultStore ??= createDefaultLocalDbStore());
    await store.initialize();
    await (_legacyMigrationFuture ??= _migrateLegacyQueues(store));
    return store;
  }

  static Future<void> _writeItem(
    LocalDbStore store,
    OfflineMutationQueueItem item,
  ) {
    return store.upsert(
      bucket: LocalDbBucket.offlineMutationQueue,
      id: item.id,
      payload: item.toPayloadMap(),
    );
  }

  static Future<void> _trimFamily(
    LocalDbStore store, {
    required String family,
  }) async {
    final maxItems = family == 'verify' ? _verifyMaxItems : _submissionMaxItems;
    final records = await store.list(
      LocalDbBucket.offlineMutationQueue,
      limit: 2000,
      allowExpired: true,
    );
    final existing = records
        .map(OfflineMutationQueueItem.fromRecord)
        .toList(growable: false);
    final familyItems = existing.where((item) => item.kind.family == family).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (familyItems.length <= maxItems) return;
    final overflow = familyItems.take(familyItems.length - maxItems);
    for (final item in overflow) {
      await store.remove(LocalDbBucket.offlineMutationQueue, item.id);
    }
  }

  static Future<void> _migrateLegacyQueues(LocalDbStore store) async {
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool(_legacyMigrationKey) ?? false;
    if (migrated) return;

    await _migrateLegacyVerifyQueue(store, prefs);
    await _migrateLegacySubmissionQueue(store, prefs);

    await prefs.remove(_legacyVerifyQueueKey);
    await prefs.remove(_legacySubmissionQueueKey);
    await prefs.setBool(_legacyMigrationKey, true);
  }

  static Future<void> _migrateLegacyVerifyQueue(
    LocalDbStore store,
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_legacyVerifyQueueKey);
    if (raw == null || raw.trim().isEmpty) return;
    final decoded = _decodeLegacyList(raw);
    for (final entry in decoded) {
      final typeRaw = (entry['type'] ?? '').toString();
      final kind = switch (typeRaw) {
        'votePrice' => OfflineMutationQueueKind.verifyVotePrice,
        'suggestPrice' => OfflineMutationQueueKind.verifySuggestPrice,
        _ => OfflineMutationQueueKind.verifyVotePrice,
      };
      final item = OfflineMutationQueueItem(
        id: (entry['id'] ?? '').toString(),
        kind: kind,
        createdAt: DateTime.tryParse(
              (entry['created_at'] ?? '').toString(),
            )?.toUtc() ??
            DateTime.now().toUtc(),
        payload: _mapPayload(entry['payload']),
      );
      await _writeItem(store, item);
    }
    await _trimFamily(store, family: 'verify');
  }

  static Future<void> _migrateLegacySubmissionQueue(
    LocalDbStore store,
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_legacySubmissionQueueKey);
    if (raw == null || raw.trim().isEmpty) return;
    final decoded = _decodeLegacyList(raw);
    for (final entry in decoded) {
      final typeRaw = (entry['type'] ?? '').toString();
      final kind = switch (typeRaw) {
        'reportBusiness' => OfflineMutationQueueKind.reportBusiness,
        'reportReview' => OfflineMutationQueueKind.reportReview,
        'reportMenuPhoto' => OfflineMutationQueueKind.reportMenuPhoto,
        'reviewCreate' => OfflineMutationQueueKind.reviewCreate,
        'businessSuggestion' => OfflineMutationQueueKind.businessSuggestion,
        _ => OfflineMutationQueueKind.reportBusiness,
      };
      final item = OfflineMutationQueueItem(
        id: (entry['id'] ?? '').toString(),
        kind: kind,
        createdAt: DateTime.tryParse(
              (entry['created_at'] ?? '').toString(),
            )?.toUtc() ??
            DateTime.now().toUtc(),
        payload: _mapPayload(entry['payload']),
      );
      await _writeItem(store, item);
    }
    await _trimFamily(store, family: 'submission');
  }

  static List<Map<String, dynamic>> _decodeLegacyList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <Map<String, dynamic>>[];
      return decoded
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList(growable: false);
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  static Map<String, dynamic> _mapPayload(Object? payload) {
    if (payload is Map) {
      return payload.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }
}

String _normalizeError(Object error) {
  final text = error.toString().trim();
  if (text.length <= 180) return text;
  return text.substring(0, 180);
}

OfflineMutationRetryPolicy resolveOfflineMutationRetryPolicy(
  OfflineMutationQueueKind kind,
  Object error,
) {
  final category = classifyOfflineMutationRetryCategory(error);
  switch (category) {
    case OfflineMutationRetryCategory.network:
      return switch (kind) {
        OfflineMutationQueueKind.verifyVotePrice => const OfflineMutationRetryPolicy(
          category: OfflineMutationRetryCategory.network,
          baseDelay: Duration(seconds: 15),
          maxDelay: Duration(minutes: 15),
        ),
        OfflineMutationQueueKind.verifySuggestPrice =>
          const OfflineMutationRetryPolicy(
            category: OfflineMutationRetryCategory.network,
            baseDelay: Duration(seconds: 30),
            maxDelay: Duration(minutes: 30),
          ),
        _ => const OfflineMutationRetryPolicy(
          category: OfflineMutationRetryCategory.network,
          baseDelay: Duration(minutes: 1),
          maxDelay: Duration(minutes: 45),
        ),
      };
    case OfflineMutationRetryCategory.auth:
      return switch (kind) {
        OfflineMutationQueueKind.verifyVotePrice => const OfflineMutationRetryPolicy(
          category: OfflineMutationRetryCategory.auth,
          baseDelay: Duration(minutes: 2),
          maxDelay: Duration(minutes: 30),
        ),
        OfflineMutationQueueKind.verifySuggestPrice =>
          const OfflineMutationRetryPolicy(
            category: OfflineMutationRetryCategory.auth,
            baseDelay: Duration(minutes: 3),
            maxDelay: Duration(minutes: 45),
          ),
        _ => const OfflineMutationRetryPolicy(
          category: OfflineMutationRetryCategory.auth,
          baseDelay: Duration(minutes: 5),
          maxDelay: Duration(hours: 2),
        ),
      };
    case OfflineMutationRetryCategory.rateLimit:
      return switch (kind) {
        OfflineMutationQueueKind.verifyVotePrice => const OfflineMutationRetryPolicy(
          category: OfflineMutationRetryCategory.rateLimit,
          baseDelay: Duration(minutes: 10),
          maxDelay: Duration(hours: 2),
        ),
        OfflineMutationQueueKind.verifySuggestPrice =>
          const OfflineMutationRetryPolicy(
            category: OfflineMutationRetryCategory.rateLimit,
            baseDelay: Duration(minutes: 15),
            maxDelay: Duration(hours: 4),
          ),
        _ => const OfflineMutationRetryPolicy(
          category: OfflineMutationRetryCategory.rateLimit,
          baseDelay: Duration(minutes: 20),
          maxDelay: Duration(hours: 6),
        ),
      };
    case OfflineMutationRetryCategory.server:
      return switch (kind) {
        OfflineMutationQueueKind.verifyVotePrice => const OfflineMutationRetryPolicy(
          category: OfflineMutationRetryCategory.server,
          baseDelay: Duration(minutes: 1),
          maxDelay: Duration(minutes: 30),
        ),
        OfflineMutationQueueKind.verifySuggestPrice =>
          const OfflineMutationRetryPolicy(
            category: OfflineMutationRetryCategory.server,
            baseDelay: Duration(minutes: 2),
            maxDelay: Duration(minutes: 45),
          ),
        _ => const OfflineMutationRetryPolicy(
          category: OfflineMutationRetryCategory.server,
          baseDelay: Duration(minutes: 3),
          maxDelay: Duration(hours: 2),
        ),
      };
    case OfflineMutationRetryCategory.unknown:
      return const OfflineMutationRetryPolicy(
        category: OfflineMutationRetryCategory.unknown,
        baseDelay: Duration(minutes: 1),
        maxDelay: Duration(hours: 1),
      );
  }
}

OfflineMutationRetryCategory classifyOfflineMutationRetryCategory(Object error) {
  final category = _retryCategoryFromText(error.toString().toLowerCase());
  return category ?? OfflineMutationRetryCategory.unknown;
}

Duration _retryBackoff(
  OfflineMutationRetryPolicy policy,
  int retryCount,
) {
  final exponent = math.max(0, retryCount - 1);
  final seconds = math.min(
    policy.baseDelay.inSeconds * math.pow(2, exponent).toInt(),
    policy.maxDelay.inSeconds,
  );
  return Duration(seconds: seconds);
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString());
}

bool _isRetryableMutationError(String text) {
  return _retryCategoryFromText(text) != null;
}

bool _isConflictResolvedError(String text) {
  return text.contains('duplicate') ||
      text.contains('already exists') ||
      text.contains('already processed') ||
      text.contains('already submitted') ||
      text.contains('already reported') ||
      text.contains('same_business_cooldown') ||
      text.contains('price_suggestion_same_item_cooldown') ||
      text.contains('price_suggestion_daily_rate_limited') ||
      text.contains('rate_limited_24h') ||
      text.contains('23505') ||
      text.contains('conflict');
}

OfflineMutationRetryCategory? _retryCategoryFromText(String text) {
  if (text.contains('socketexception') ||
      text.contains('clientexception') ||
      text.contains('failed host lookup') ||
      text.contains('connection closed before full header was received') ||
      text.contains('network is unreachable') ||
      text.contains('connection refused') ||
      text.contains('timed out') ||
      text.contains('timeout')) {
    return OfflineMutationRetryCategory.network;
  }
  if (text.contains('jwt') ||
      text.contains('not authenticated') ||
      text.contains('auth session') ||
      text.contains('401') ||
      text.contains('403')) {
    return OfflineMutationRetryCategory.auth;
  }
  if (text.contains('429') ||
      text.contains('rate limit') ||
      text.contains('temporarily unavailable')) {
    return OfflineMutationRetryCategory.rateLimit;
  }
  if (text.contains('service unavailable') ||
      text.contains('503') ||
      text.contains('500')) {
    return OfflineMutationRetryCategory.server;
  }
  return null;
}
