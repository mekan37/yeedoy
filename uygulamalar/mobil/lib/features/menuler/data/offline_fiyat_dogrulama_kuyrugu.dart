import '../../../core/depolama/offline_mutation_idempotency.dart';
import '../../../core/depolama/cevrimdisi_degisim_kuyrugu.dart';

enum OfflineVerifyActionType { votePrice, suggestPrice }

class OfflineVerifyQueueItem {
  const OfflineVerifyQueueItem({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.payload,
    this.retryCount = 0,
    this.lastError,
    this.nextRetryAt,
  });

  final String id;
  final OfflineVerifyActionType type;
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

  factory OfflineVerifyQueueItem.fromMap(Map<String, dynamic> map) {
    final typeRaw = (map['type'] ?? '').toString();
    final type = OfflineVerifyActionType.values.firstWhere(
      (value) => value.name == typeRaw,
      orElse: () => OfflineVerifyActionType.votePrice,
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
    return OfflineVerifyQueueItem(
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

class OfflineVerifyQueueStore {
  static const Set<OfflineMutationQueueKind> _kinds = <OfflineMutationQueueKind>{
    OfflineMutationQueueKind.verifyVotePrice,
    OfflineMutationQueueKind.verifySuggestPrice,
  };

  static Future<List<OfflineVerifyQueueItem>> readAll() async {
    final items = await OfflineMutationQueueStore.readAll(kinds: _kinds);
    return items.map(_fromMutationItem).toList(growable: false);
  }

  static Future<List<OfflineVerifyQueueItem>> readReady({
    int limit = 100,
  }) async {
    final items = await OfflineMutationQueueStore.readReady(
      kinds: _kinds,
      limit: limit,
    );
    return items.map(_fromMutationItem).toList(growable: false);
  }

  static Future<void> enqueue(
    OfflineVerifyActionType type,
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

  static Future<void> replaceAll(List<OfflineVerifyQueueItem> items) async {
    await OfflineMutationQueueStore.replaceKinds(
      kinds: _kinds,
      items: items.map(_toMutationItem).toList(growable: false),
    );
  }

  static Future<void> remove(String id) {
    return OfflineMutationQueueStore.remove(id);
  }

  static Future<void> markRetry(
    OfflineVerifyQueueItem item, {
    required Object error,
  }) {
    return OfflineMutationQueueStore.markRetry(
      _toMutationItem(item),
      error: error,
    );
  }

  static OfflineVerifyQueueItem _fromMutationItem(
    OfflineMutationQueueItem item,
  ) {
    return OfflineVerifyQueueItem(
      id: item.id,
      type: item.kind == OfflineMutationQueueKind.verifySuggestPrice
          ? OfflineVerifyActionType.suggestPrice
          : OfflineVerifyActionType.votePrice,
      createdAt: item.createdAt.toLocal(),
      payload: item.payload,
      retryCount: item.retryCount,
      lastError: item.lastError,
      nextRetryAt: item.nextRetryAt?.toLocal(),
    );
  }

  static OfflineMutationQueueItem _toMutationItem(OfflineVerifyQueueItem item) {
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

  static OfflineMutationQueueKind _kindFor(OfflineVerifyActionType type) {
    return switch (type) {
      OfflineVerifyActionType.votePrice =>
        OfflineMutationQueueKind.verifyVotePrice,
      OfflineVerifyActionType.suggestPrice =>
        OfflineMutationQueueKind.verifySuggestPrice,
    };
  }
}

class OfflineQueuedException implements Exception {
  const OfflineQueuedException([this.code = 'offline_queued']);

  final String code;

  @override
  String toString() => 'Exception: $code';
}
