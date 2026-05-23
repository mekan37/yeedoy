import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'offline_mutation_idempotency.dart';
import 'cevrimdisi_degisim_kuyrugu.dart';

enum OfflineSubmissionType {
  reportBusiness,
  reportReview,
  reportMenuPhoto,
  reviewCreate,
  businessSuggestion,
}

class OfflineSubmissionQueueItem {
  const OfflineSubmissionQueueItem({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.payload,
    this.retryCount = 0,
    this.lastError,
    this.nextRetryAt,
  });

  final String id;
  final OfflineSubmissionType type;
  final DateTime createdAt;
  final Map<String, dynamic> payload;
  final int retryCount;
  final String? lastError;
  final DateTime? nextRetryAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'created_at': createdAt.toUtc().toIso8601String(),
      'payload': payload,
      'retry_count': retryCount,
      'last_error': lastError,
      'next_retry_at': nextRetryAt?.toUtc().toIso8601String(),
    };
  }

  factory OfflineSubmissionQueueItem.fromMap(Map<String, dynamic> map) {
    final typeRaw = (map['type'] ?? '').toString();
    final type = OfflineSubmissionType.values.firstWhere(
      (value) => value.name == typeRaw,
      orElse: () => OfflineSubmissionType.reportBusiness,
    );
    final payloadRaw = map['payload'];
    final payload = payloadRaw is Map
        ? payloadRaw.cast<String, dynamic>()
        : <String, dynamic>{};
    final createdAtText = (map['created_at'] ?? '').toString();
    final createdAt =
        DateTime.tryParse(createdAtText)?.toLocal() ?? DateTime.now().toLocal();
    final retryCount =
        int.tryParse((map['retry_count'] ?? '').toString()) ?? 0;
    final nextRetryAt = DateTime.tryParse(
      (map['next_retry_at'] ?? '').toString(),
    )?.toLocal();
    final lastErrorText = (map['last_error'] ?? '').toString().trim();
    return OfflineSubmissionQueueItem(
      id: (map['id'] ?? '').toString(),
      type: type,
      createdAt: createdAt,
      payload: payload,
      retryCount: retryCount,
      lastError: lastErrorText.isEmpty ? null : lastErrorText,
      nextRetryAt: nextRetryAt,
    );
  }
}

class OfflineSubmissionQueueStore {
  static const Set<OfflineMutationQueueKind> _kinds = <OfflineMutationQueueKind>{
    OfflineMutationQueueKind.reportBusiness,
    OfflineMutationQueueKind.reportReview,
    OfflineMutationQueueKind.reportMenuPhoto,
    OfflineMutationQueueKind.reviewCreate,
    OfflineMutationQueueKind.businessSuggestion,
  };

  static Future<List<OfflineSubmissionQueueItem>> readAll() async {
    final items = await OfflineMutationQueueStore.readAll(kinds: _kinds);
    return items.map(_fromMutationItem).toList(growable: false);
  }

  static Future<List<OfflineSubmissionQueueItem>> readReady({
    int limit = 100,
  }) async {
    final items = await OfflineMutationQueueStore.readReady(
      kinds: _kinds,
      limit: limit,
    );
    return items.map(_fromMutationItem).toList(growable: false);
  }

  static Future<void> enqueue(
    OfflineSubmissionType type,
    Map<String, dynamic> payload,
  ) async {
    final enriched = await attachOfflineMutationIdempotency(
      action: type.name,
      payload: payload,
      clientId: (payload['client_id'] ?? '').toString().trim().isEmpty
          ? null
          : (payload['client_id'] ?? '').toString().trim(),
    );
    await OfflineMutationQueueStore.enqueue(
      kind: _kindFor(type),
      payload: enriched,
    );
  }

  static Future<void> replaceAll(List<OfflineSubmissionQueueItem> items) async {
    await OfflineMutationQueueStore.replaceKinds(
      kinds: _kinds,
      items: items.map(_toMutationItem).toList(growable: false),
    );
  }

  static Future<void> remove(String id) {
    return OfflineMutationQueueStore.remove(id);
  }

  static Future<void> markRetry(
    OfflineSubmissionQueueItem item, {
    required Object error,
  }) {
    return OfflineMutationQueueStore.markRetry(
      _toMutationItem(item),
      error: error,
    );
  }
}

class OfflineSubmissionQueuedException implements Exception {
  const OfflineSubmissionQueuedException([
    this.code = 'offline_submission_queued',
  ]);

  final String code;

  @override
  String toString() => 'Exception: $code';
}

typedef OfflineSubmissionDispatcher =
    Future<void> Function(OfflineSubmissionQueueItem item);
typedef OfflineMutationOutcomeReporter =
    Future<void> Function({
      required OfflineMutationQueueKind kind,
      required String disposition,
      OfflineMutationRetryCategory? retryCategory,
      required int retryCount,
      String? detail,
    });

Future<int> flushOfflineSubmissionQueue(
  SupabaseClient client, {
  int maxItems = 25,
  OfflineMutationOutcomeReporter? reportOutcome,
}) {
  return flushOfflineSubmissionQueueWithDispatcher(
    maxItems: maxItems,
    reportOutcome: reportOutcome,
    dispatch: (item) => _dispatchOfflineSubmission(client, item),
  );
}

@visibleForTesting
Future<int> flushOfflineSubmissionQueueWithDispatcher({
  required OfflineSubmissionDispatcher dispatch,
  int maxItems = 25,
  OfflineMutationOutcomeReporter? reportOutcome,
}) async {
  final queue = await OfflineSubmissionQueueStore.readReady(limit: maxItems);
  if (queue.isEmpty) return 0;

  var sent = 0;

  for (final item in queue) {
    try {
      await dispatch(item);
      await OfflineSubmissionQueueStore.remove(item.id);
      if (reportOutcome != null) {
        await reportOutcome(
          kind: _kindFor(item.type),
          disposition: 'success',
          retryCount: item.retryCount,
        );
      }
      sent += 1;
    } catch (e) {
      final decision = classifyOfflineMutationError(e);
      if (decision.disposition == OfflineMutationFailureDisposition.retry) {
        await OfflineSubmissionQueueStore.markRetry(item, error: e);
        if (reportOutcome != null) {
          await reportOutcome(
            kind: _kindFor(item.type),
            disposition: 'retry',
            retryCategory: classifyOfflineMutationRetryCategory(e),
            retryCount: item.retryCount + 1,
            detail: decision.reason,
          );
        }
        break;
      }
      await OfflineSubmissionQueueStore.remove(item.id);
      if (decision.disposition == OfflineMutationFailureDisposition.resolve) {
        if (reportOutcome != null) {
          await reportOutcome(
            kind: _kindFor(item.type),
            disposition: 'resolve',
            retryCategory: classifyOfflineMutationRetryCategory(e),
            retryCount: item.retryCount,
            detail: decision.reason,
          );
        }
        sent += 1;
      } else if (reportOutcome != null) {
        await reportOutcome(
          kind: _kindFor(item.type),
          disposition: 'drop',
          retryCategory: classifyOfflineMutationRetryCategory(e),
          retryCount: item.retryCount,
          detail: decision.reason,
        );
      }
      continue;
    }
  }

  return sent;
}

Future<void> _dispatchOfflineSubmission(
  SupabaseClient client,
  OfflineSubmissionQueueItem item,
) async {
  final payload = item.payload;
  switch (item.type) {
    case OfflineSubmissionType.reportBusiness:
      final businessId = (payload['business_id'] ?? '').toString();
      final reason = (payload['reason'] ?? '').toString();
      if (businessId.isEmpty || reason.isEmpty) {
        throw const FormatException('invalid_report_business_payload');
      }
      await _submitReport(
        client,
        params: {
          'p_business_id': businessId,
          'p_reason': reason,
          'p_details': _normalizeNullable(payload['details']),
          'p_idempotency_key': _normalizeNullable(payload['idempotency_key']),
        },
      );
      return;
    case OfflineSubmissionType.reportReview:
      final reviewId = (payload['review_id'] ?? '').toString();
      final reason = (payload['reason'] ?? '').toString();
      if (reviewId.isEmpty || reason.isEmpty) {
        throw const FormatException('invalid_report_review_payload');
      }
      await _submitReport(
        client,
        params: {
          'p_review_id': reviewId,
          'p_reason': reason,
          'p_details': _normalizeNullable(payload['details']),
          'p_idempotency_key': _normalizeNullable(payload['idempotency_key']),
        },
      );
      return;
    case OfflineSubmissionType.reportMenuPhoto:
      final photoId = (payload['menu_item_photo_id'] ?? '').toString();
      final reason = (payload['reason'] ?? '').toString();
      if (photoId.isEmpty || reason.isEmpty) {
        throw const FormatException('invalid_report_photo_payload');
      }
      await _submitReport(
        client,
        params: {
          'p_menu_item_photo_id': photoId,
          'p_reason': reason,
          'p_details': _normalizeNullable(payload['details']),
          'p_idempotency_key': _normalizeNullable(payload['idempotency_key']),
        },
      );
      return;
    case OfflineSubmissionType.reviewCreate:
      final businessId = (payload['business_id'] ?? '').toString();
      final content = (payload['content'] ?? '').toString();
      final rating = _asInt(payload['rating']) ?? 0;
      if (businessId.isEmpty || content.isEmpty || rating <= 0) {
        throw const FormatException('invalid_review_create_payload');
      }
      await client.rpc(
        'submit_review_v2',
        params: {
          'p_business_id': businessId,
          'p_rating': rating,
          'p_title': _normalizeNullable(payload['title']),
          'p_content': content,
          'p_idempotency_key': _normalizeNullable(payload['idempotency_key']),
        },
      );
      return;
    case OfflineSubmissionType.businessSuggestion:
      final name = (payload['name'] ?? '').toString().trim();
      final category = (payload['category'] ?? '').toString().trim();
      if (name.isEmpty || category.isEmpty) {
        throw const FormatException('invalid_business_suggestion_payload');
      }
      final res = await client.rpc(
        'submit_business_suggestion_v2',
        params: {
          'p_name': name,
          'p_category': category,
          'p_city': _normalizeNullable(payload['city']),
          'p_district': _normalizeNullable(payload['district']),
          'p_address': _normalizeNullable(payload['address']),
          'p_phone': _normalizeNullable(payload['phone']),
          'p_website': _normalizeNullable(payload['website']),
          'p_notes': _normalizeNullable(payload['notes']),
          'p_idempotency_key': _normalizeNullable(payload['idempotency_key']),
        },
      );
      if (res is Map && res['ok'] == true) return;
      if (res is List && res.isNotEmpty && res.first is Map) {
        final first = (res.first as Map);
        if (first['ok'] == true) return;
      }
      throw Exception('business_suggestion_sync_failed');
  }
}

Future<void> _submitReport(
  SupabaseClient client, {
  required Map<String, dynamic> params,
}) async {
  final res = await client.rpc('submit_report_v2', params: params);
  if (res is Map && res['ok'] == true) return;
  if (res is List && res.isNotEmpty && res.first is Map) {
    final first = (res.first as Map);
    if (first['ok'] == true) return;
  }
  throw Exception('report_sync_failed');
}

Object? _normalizeNullable(Object? value) {
  final text = (value ?? '').toString().trim();
  return text.isEmpty ? null : text;
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString());
}

bool isLikelyOfflineError(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('socketexception') ||
      text.contains('clientexception') ||
      text.contains('failed host lookup') ||
      text.contains('connection closed before full header was received') ||
      text.contains('network is unreachable') ||
      text.contains('connection refused') ||
      text.contains('timed out') ||
      text.contains('timeout');
}

OfflineSubmissionQueueItem _fromMutationItem(OfflineMutationQueueItem item) {
  return OfflineSubmissionQueueItem(
    id: item.id,
    type: switch (item.kind) {
      OfflineMutationQueueKind.reportBusiness =>
        OfflineSubmissionType.reportBusiness,
      OfflineMutationQueueKind.reportReview => OfflineSubmissionType.reportReview,
      OfflineMutationQueueKind.reportMenuPhoto =>
        OfflineSubmissionType.reportMenuPhoto,
      OfflineMutationQueueKind.reviewCreate => OfflineSubmissionType.reviewCreate,
      OfflineMutationQueueKind.businessSuggestion =>
        OfflineSubmissionType.businessSuggestion,
      _ => OfflineSubmissionType.reportBusiness,
    },
    createdAt: item.createdAt.toLocal(),
    payload: item.payload,
    retryCount: item.retryCount,
    lastError: item.lastError,
    nextRetryAt: item.nextRetryAt?.toLocal(),
  );
}

OfflineMutationQueueItem _toMutationItem(OfflineSubmissionQueueItem item) {
  return OfflineMutationQueueItem(
    id: item.id,
    kind: _kindFor(item.type),
    createdAt: item.createdAt.toUtc(),
    payload: item.payload,
    retryCount: item.retryCount,
    lastError: item.lastError,
    nextRetryAt: item.nextRetryAt?.toUtc(),
    status: item.retryCount > 0
        ? OfflineMutationQueueStatus.retrying
        : OfflineMutationQueueStatus.pending,
  );
}

OfflineMutationQueueKind _kindFor(OfflineSubmissionType type) {
  return switch (type) {
    OfflineSubmissionType.reportBusiness =>
      OfflineMutationQueueKind.reportBusiness,
    OfflineSubmissionType.reportReview => OfflineMutationQueueKind.reportReview,
    OfflineSubmissionType.reportMenuPhoto =>
      OfflineMutationQueueKind.reportMenuPhoto,
    OfflineSubmissionType.reviewCreate => OfflineMutationQueueKind.reviewCreate,
    OfflineSubmissionType.businessSuggestion =>
      OfflineMutationQueueKind.businessSuggestion,
  };
}
