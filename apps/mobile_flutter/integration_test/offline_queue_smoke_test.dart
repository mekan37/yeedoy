// Integration smoke test for the offline mutation queue.
//
// Uses the production OfflineMutationQueueStore (which relies on
// SharedPreferences internally). Validates enqueue, readAll, readReady,
// remove, and retry-category semantics without a live Supabase connection.
//
// Run with:
//   flutter test integration_test/offline_queue_smoke_test.dart
//   flutter drive --target=integration_test/offline_queue_smoke_test.dart
//
// CI: add to mobile_quality.yml under "offline queue smoke" step.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:yeedoy/core/storage/offline_mutation_queue.dart';
import 'package:yeedoy/core/storage/offline_queue_diagnostics.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineMutationQueueStore smoke', () {
    // Clean state before each test by removing all items written.
    final writtenIds = <String>[];

    tearDown(() async {
      for (final id in writtenIds) {
        await OfflineMutationQueueStore.remove(id);
      }
      writtenIds.clear();
    });

    test('enqueue → readAll returns the item', () async {
      await OfflineMutationQueueStore.enqueue(
        kind: OfflineMutationQueueKind.reviewCreate,
        payload: {'business_id': 'biz-smoke-1', 'rating': 5, 'content': 'smoke test'},
      );

      final all = await OfflineMutationQueueStore.readAll(
        kinds: {OfflineMutationQueueKind.reviewCreate},
      );
      final match = all.where((i) =>
        i.payload['business_id'] == 'biz-smoke-1');
      expect(match, isNotEmpty, reason: 'enqueued item should appear in readAll');
      writtenIds.add(match.first.id);
    });

    test('item starts as pending with zero retryCount', () async {
      await OfflineMutationQueueStore.enqueue(
        kind: OfflineMutationQueueKind.verifyVotePrice,
        payload: {'menu_item_id': 'mi-smoke-1', 'vote': true},
      );
      final all = await OfflineMutationQueueStore.readAll(
        kinds: {OfflineMutationQueueKind.verifyVotePrice},
      );
      final match = all.where((i) => i.payload['menu_item_id'] == 'mi-smoke-1');
      expect(match, isNotEmpty);
      final item = match.first;
      expect(item.status, OfflineMutationQueueStatus.pending);
      expect(item.retryCount, equals(0));
      writtenIds.add(item.id);
    });

    test('readReady returns item with no nextRetryAt', () async {
      await OfflineMutationQueueStore.enqueue(
        kind: OfflineMutationQueueKind.reportBusiness,
        payload: {'business_id': 'biz-smoke-2', 'reason': 'spam'},
      );
      final ready = await OfflineMutationQueueStore.readReady(
        kinds: {OfflineMutationQueueKind.reportBusiness},
      );
      final match = ready.where((i) => i.payload['business_id'] == 'biz-smoke-2');
      expect(match, isNotEmpty, reason: 'item without delay should be ready immediately');
      writtenIds.add(match.first.id);
    });

    test('remove deletes item from queue', () async {
      await OfflineMutationQueueStore.enqueue(
        kind: OfflineMutationQueueKind.businessSuggestion,
        payload: {'name': 'Smoke Test Cafe'},
      );
      final before = await OfflineMutationQueueStore.readAll(
        kinds: {OfflineMutationQueueKind.businessSuggestion},
      );
      final match = before.where((i) => i.payload['name'] == 'Smoke Test Cafe');
      expect(match, isNotEmpty);

      final id = match.first.id;
      await OfflineMutationQueueStore.remove(id);

      final after = await OfflineMutationQueueStore.readAll(
        kinds: {OfflineMutationQueueKind.businessSuggestion},
      );
      expect(after.where((i) => i.id == id), isEmpty,
          reason: 'removed item should not appear in readAll');
    });

    test('isReady respects nextRetryAt', () {
      final now = DateTime.now().toUtc();
      final pendingItem = OfflineMutationQueueItem(
        id: 'ready-test',
        kind: OfflineMutationQueueKind.reviewCreate,
        createdAt: now,
        payload: const {},
      );
      expect(pendingItem.isReady(now), isTrue);

      final futureItem = OfflineMutationQueueItem(
        id: 'blocked-test',
        kind: OfflineMutationQueueKind.reviewCreate,
        createdAt: now,
        payload: const {},
        nextRetryAt: now.add(const Duration(hours: 1)),
      );
      expect(futureItem.isReady(now), isFalse,
          reason: 'item with future nextRetryAt should not be ready');
    });

    test('kind.family classifies verify vs submission', () {
      expect(OfflineMutationQueueKind.verifyVotePrice.family, 'verify');
      expect(OfflineMutationQueueKind.verifySuggestPrice.family, 'verify');
      expect(OfflineMutationQueueKind.reviewCreate.family, 'submission');
      expect(OfflineMutationQueueKind.reportBusiness.family, 'submission');
      expect(OfflineMutationQueueKind.reportReview.family, 'submission');
      expect(OfflineMutationQueueKind.businessSuggestion.family, 'submission');
    });

    test('diagnostics summary counts correctly', () async {
      await OfflineMutationQueueStore.enqueue(
        kind: OfflineMutationQueueKind.verifyVotePrice,
        payload: {'menu_item_id': 'mi-diag-1', 'vote': true},
      );
      await OfflineMutationQueueStore.enqueue(
        kind: OfflineMutationQueueKind.reviewCreate,
        payload: {'business_id': 'biz-diag-1', 'rating': 3, 'content': 'diag'},
      );

      final all = await OfflineMutationQueueStore.readAll();
      final diagItems = all.where((i) =>
        (i.payload['menu_item_id'] == 'mi-diag-1') ||
        (i.payload['business_id'] == 'biz-diag-1')).toList();
      writtenIds.addAll(diagItems.map((i) => i.id));

      final summary = buildOfflineQueueDiagnosticsSummary(diagItems);
      expect(summary.total, equals(2));
      expect(summary.verifyCount, equals(1));
      expect(summary.submissionCount, equals(1));
      expect(summary.pendingCount, equals(2));
    });
  });
}
