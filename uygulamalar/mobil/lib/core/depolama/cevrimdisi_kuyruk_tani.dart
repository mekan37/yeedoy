import 'cevrimdisi_degisim_kuyrugu.dart';

class OfflineQueueErrorBucket {
  const OfflineQueueErrorBucket({
    required this.message,
    required this.count,
  });

  final String message;
  final int count;
}

class OfflineQueueDiagnosticItem {
  const OfflineQueueDiagnosticItem({
    required this.id,
    required this.label,
    required this.target,
    required this.status,
    required this.retryCount,
    required this.readyNow,
    required this.createdAt,
    required this.kind,
    this.retryCategory,
    this.operatorAction,
    this.detail,
    this.lastError,
    this.nextRetryAt,
    this.lastAttemptAt,
  });

  final String id;
  final String label;
  final String target;
  final String? detail;
  final OfflineMutationQueueKind kind;
  final OfflineMutationQueueStatus status;
  final int retryCount;
  final bool readyNow;
  final String? lastError;
  final DateTime createdAt;
  final OfflineMutationRetryCategory? retryCategory;
  final String? operatorAction;
  final DateTime? nextRetryAt;
  final DateTime? lastAttemptAt;
}

class OfflineQueueDiagnosticsSummary {
  const OfflineQueueDiagnosticsSummary({
    required this.total,
    required this.verifyCount,
    required this.submissionCount,
    required this.pendingCount,
    required this.retryingCount,
    required this.readyCount,
    required this.blockedCount,
    required this.visibleItems,
    required this.errorBuckets,
    this.oldestCreatedAt,
    this.nextRetryAt,
  });

  final int total;
  final int verifyCount;
  final int submissionCount;
  final int pendingCount;
  final int retryingCount;
  final int readyCount;
  final int blockedCount;
  final DateTime? oldestCreatedAt;
  final DateTime? nextRetryAt;
  final List<OfflineQueueDiagnosticItem> visibleItems;
  final List<OfflineQueueErrorBucket> errorBuckets;
}

class OfflineQueuePolicyRule {
  const OfflineQueuePolicyRule({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}

const List<OfflineQueuePolicyRule> offlineQueuePolicyRules =
    <OfflineQueuePolicyRule>[
      OfflineQueuePolicyRule(
        title: 'Retry',
        description:
            'Network, auth, rate-limit and transient server failures stay queued with backoff.',
      ),
      OfflineQueuePolicyRule(
        title: 'Resolve',
        description:
            'Duplicate, already-processed and cooldown conflicts are treated as already applied.',
      ),
      OfflineQueuePolicyRule(
        title: 'Drop',
        description:
            'Invalid payloads and permanent rejections are removed and require a fresh user action.',
      ),
    ];

OfflineQueueDiagnosticsSummary buildOfflineQueueDiagnosticsSummary(
  List<OfflineMutationQueueItem> items, {
  DateTime? now,
  int maxVisibleItems = 6,
  int maxErrorBuckets = 3,
}) {
  final pivot = (now ?? DateTime.now()).toUtc();
  final verifyCount = items.where((item) => item.kind.family == 'verify').length;
  final retryingCount = items
      .where((item) => item.status == OfflineMutationQueueStatus.retrying)
      .length;
  final readyCount = items.where((item) => item.isReady(pivot)).length;
  final errors = <String, int>{};
  final nextRetryItems = items.where((item) => item.nextRetryAt != null).toList()
    ..sort((a, b) => a.nextRetryAt!.compareTo(b.nextRetryAt!));
  final visibleItems = items.toList()
    ..sort((a, b) {
      final severity = _sortPriority(b, pivot).compareTo(_sortPriority(a, pivot));
      if (severity != 0) return severity;
      final nextRetryCompare = _compareNullableDateTimes(
        a.nextRetryAt,
        b.nextRetryAt,
      );
      if (nextRetryCompare != 0) return nextRetryCompare;
      return a.createdAt.compareTo(b.createdAt);
    });

  for (final item in items) {
    final lastError = (item.lastError ?? '').trim();
    if (lastError.isEmpty) continue;
    errors.update(lastError, (value) => value + 1, ifAbsent: () => 1);
  }

  final errorBuckets = errors.entries.toList()
    ..sort((a, b) {
      final countCompare = b.value.compareTo(a.value);
      if (countCompare != 0) return countCompare;
      return a.key.compareTo(b.key);
    });

  return OfflineQueueDiagnosticsSummary(
    total: items.length,
    verifyCount: verifyCount,
    submissionCount: items.length - verifyCount,
    pendingCount: items.length - retryingCount,
    retryingCount: retryingCount,
    readyCount: readyCount,
    blockedCount: items.length - readyCount,
    oldestCreatedAt: items.isEmpty
        ? null
        : (items.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt)))
            .first
            .createdAt,
    nextRetryAt: nextRetryItems.isEmpty ? null : nextRetryItems.first.nextRetryAt,
    visibleItems: visibleItems
        .take(maxVisibleItems)
        .map((item) => _toDiagnosticItem(item, pivot))
        .toList(growable: false),
    errorBuckets: errorBuckets
        .take(maxErrorBuckets)
        .map(
          (entry) => OfflineQueueErrorBucket(
            message: entry.key,
            count: entry.value,
          ),
        )
        .toList(growable: false),
  );
}

OfflineQueueDiagnosticItem _toDiagnosticItem(
  OfflineMutationQueueItem item,
  DateTime now,
) {
  return OfflineQueueDiagnosticItem(
    id: item.id,
    label: _labelForKind(item.kind),
    target: _targetFor(item),
    detail: _detailFor(item),
    kind: item.kind,
    status: item.status,
    retryCount: item.retryCount,
    readyNow: item.isReady(now),
    lastError: item.lastError,
    createdAt: item.createdAt,
    retryCategory: _retryCategoryFor(item.lastError),
    operatorAction: _operatorActionFor(item.lastError),
    nextRetryAt: item.nextRetryAt,
    lastAttemptAt: item.lastAttemptAt,
  );
}

String _labelForKind(OfflineMutationQueueKind kind) {
  return switch (kind) {
    OfflineMutationQueueKind.verifyVotePrice => 'Price vote',
    OfflineMutationQueueKind.verifySuggestPrice => 'Price suggestion',
    OfflineMutationQueueKind.reportBusiness => 'Business report',
    OfflineMutationQueueKind.reportReview => 'Review report',
    OfflineMutationQueueKind.reportMenuPhoto => 'Menu photo report',
    OfflineMutationQueueKind.reviewCreate => 'Review submit',
    OfflineMutationQueueKind.businessSuggestion => 'Business suggestion',
  };
}

String _targetFor(OfflineMutationQueueItem item) {
  final payload = item.payload;
  switch (item.kind) {
    case OfflineMutationQueueKind.verifyVotePrice:
    case OfflineMutationQueueKind.verifySuggestPrice:
      return _valueOrFallback(payload['menu_item_id'], item.id, prefix: 'menu');
    case OfflineMutationQueueKind.reportBusiness:
    case OfflineMutationQueueKind.reviewCreate:
      return _valueOrFallback(payload['business_id'], item.id, prefix: 'business');
    case OfflineMutationQueueKind.reportReview:
      return _valueOrFallback(payload['review_id'], item.id, prefix: 'review');
    case OfflineMutationQueueKind.reportMenuPhoto:
      return _valueOrFallback(
        payload['menu_item_photo_id'],
        item.id,
        prefix: 'photo',
      );
    case OfflineMutationQueueKind.businessSuggestion:
      final name = (payload['name'] ?? '').toString().trim();
      if (name.isNotEmpty) return name;
      return _valueOrFallback(payload['category'], item.id, prefix: 'suggestion');
  }
}

String? _detailFor(OfflineMutationQueueItem item) {
  final payload = item.payload;
  switch (item.kind) {
    case OfflineMutationQueueKind.verifyVotePrice:
      return 'vote=${payload['vote'] ?? '-'}';
    case OfflineMutationQueueKind.verifySuggestPrice:
      final cents = (payload['suggested_price_cents'] ?? '').toString().trim();
      final currency = (payload['currency'] ?? 'TRY').toString().trim();
      if (cents.isEmpty) return null;
      return '$cents $currency';
    case OfflineMutationQueueKind.reportBusiness:
    case OfflineMutationQueueKind.reportReview:
    case OfflineMutationQueueKind.reportMenuPhoto:
      final reason = (payload['reason'] ?? '').toString().trim();
      return reason.isEmpty ? null : 'reason=$reason';
    case OfflineMutationQueueKind.reviewCreate:
      final rating = (payload['rating'] ?? '').toString().trim();
      return rating.isEmpty ? null : 'rating=$rating';
    case OfflineMutationQueueKind.businessSuggestion:
      final category = (payload['category'] ?? '').toString().trim();
      final city = (payload['city'] ?? '').toString().trim();
      final district = (payload['district'] ?? '').toString().trim();
      final location = [district, city].where((value) => value.isNotEmpty).join(', ');
      if (category.isEmpty && location.isEmpty) return null;
      if (category.isEmpty) return location;
      if (location.isEmpty) return category;
      return '$category • $location';
  }
}

String _valueOrFallback(Object? value, String fallback, {required String prefix}) {
  final text = (value ?? '').toString().trim();
  if (text.isNotEmpty) return '$prefix:$text';
  return '$prefix:$fallback';
}

int _sortPriority(OfflineMutationQueueItem item, DateTime now) {
  var score = item.status == OfflineMutationQueueStatus.retrying ? 100 : 0;
  score += item.isReady(now) ? 10 : 0;
  score += item.retryCount;
  return score;
}

int _compareNullableDateTimes(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

OfflineMutationRetryCategory? _retryCategoryFor(String? error) {
  final text = (error ?? '').trim();
  if (text.isEmpty) return null;
  final category = classifyOfflineMutationRetryCategory(Exception(text));
  if (category == OfflineMutationRetryCategory.unknown) return null;
  return category;
}

String? _operatorActionFor(String? error) {
  final category = _retryCategoryFor(error);
  return switch (category) {
    OfflineMutationRetryCategory.network =>
      'Wait for connectivity restore or retry after network recovers.',
    OfflineMutationRetryCategory.auth =>
      'Re-authenticate this session before manual flush.',
    OfflineMutationRetryCategory.rateLimit =>
      'Do not force flush; wait for the next retry window.',
    OfflineMutationRetryCategory.server =>
      'Check backend health before retrying.',
    OfflineMutationRetryCategory.unknown || null =>
      null,
  };
}
