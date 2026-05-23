import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeedoy/core/depolama/yerel_db/paylasilan_tercihler_yerel_db_deposu.dart';
import 'package:yeedoy/core/depolama/cevrimdisi_degisim_kuyrugu.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await OfflineMutationQueueStore.setStoreForTesting(
      SharedPrefsLocalDbStore(),
    );
  });

  tearDown(() async {
    await OfflineMutationQueueStore.setStoreForTesting(null);
  });

  group('OfflineMutationQueueStore', () {
    test('migrates legacy queue payloads into unified local db bucket', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'offline_verify_queue_v1': jsonEncode([
          {
            'id': 'verify_1',
            'type': 'votePrice',
            'created_at': DateTime.utc(2026, 3, 7, 10).toIso8601String(),
            'payload': {'menu_item_id': 'm1', 'vote': 1},
          },
        ]),
        'offline_submission_queue_v1': jsonEncode([
          {
            'id': 'submission_1',
            'type': 'reviewCreate',
            'created_at': DateTime.utc(2026, 3, 7, 11).toIso8601String(),
            'payload': {'business_id': 'b1', 'rating': 5, 'content': 'great'},
          },
        ]),
      });
      await OfflineMutationQueueStore.setStoreForTesting(
        SharedPrefsLocalDbStore(),
      );

      final items = await OfflineMutationQueueStore.readAll(limit: 20);

      expect(items.map((item) => item.id), <String>[
        'verify_1',
        'submission_1',
      ]);
      expect(items.first.kind, OfflineMutationQueueKind.verifyVotePrice);
      expect(items.last.kind, OfflineMutationQueueKind.reviewCreate);
    });

    test('markRetry stores retry metadata and network backoff timestamp', () async {
      await OfflineMutationQueueStore.enqueue(
        kind: OfflineMutationQueueKind.verifySuggestPrice,
        payload: {'menu_item_id': 'm1', 'suggested_price_cents': 100},
        id: 'retry_1',
        createdAt: DateTime.utc(2026, 3, 7, 12),
      );

      final item = (await OfflineMutationQueueStore.readAll()).single;
      await OfflineMutationQueueStore.markRetry(
        item,
        error: Exception('SocketException: failed host lookup'),
        now: DateTime.utc(2026, 3, 7, 12, 0, 10),
      );

      final updated = (await OfflineMutationQueueStore.readAll()).single;
      expect(updated.retryCount, 1);
      expect(updated.status, OfflineMutationQueueStatus.retrying);
      expect(updated.lastError, contains('SocketException'));
      expect(updated.nextRetryAt, DateTime.utc(2026, 3, 7, 12, 0, 40));
    });

    test('uses slower backoff for auth and rate limit errors', () async {
      await OfflineMutationQueueStore.enqueue(
        kind: OfflineMutationQueueKind.reviewCreate,
        payload: {'business_id': 'b1', 'rating': 5, 'content': 'great'},
        id: 'submission_auth',
        createdAt: DateTime.utc(2026, 3, 7, 12),
      );
      await OfflineMutationQueueStore.enqueue(
        kind: OfflineMutationQueueKind.verifySuggestPrice,
        payload: {'menu_item_id': 'm1', 'suggested_price_cents': 100},
        id: 'verify_rate',
        createdAt: DateTime.utc(2026, 3, 7, 12, 1),
      );

      final items = await OfflineMutationQueueStore.readAll(limit: 10);
      final authItem = items.firstWhere((item) => item.id == 'submission_auth');
      final rateItem = items.firstWhere((item) => item.id == 'verify_rate');

      await OfflineMutationQueueStore.markRetry(
        authItem,
        error: Exception('401 auth session expired'),
        now: DateTime.utc(2026, 3, 7, 12, 0, 10),
      );
      await OfflineMutationQueueStore.markRetry(
        rateItem,
        error: Exception('429 rate limit'),
        now: DateTime.utc(2026, 3, 7, 12, 0, 10),
      );

      final updated = await OfflineMutationQueueStore.readAll(limit: 10);
      final updatedAuth = updated.firstWhere(
        (item) => item.id == 'submission_auth',
      );
      final updatedRate = updated.firstWhere((item) => item.id == 'verify_rate');

      expect(updatedAuth.nextRetryAt, DateTime.utc(2026, 3, 7, 12, 5, 10));
      expect(updatedRate.nextRetryAt, DateTime.utc(2026, 3, 7, 12, 15, 10));
    });

    test('classifies price suggestion cooldown errors as resolved conflicts', () {
      final sameItem = classifyOfflineMutationError(
        Exception('price_suggestion_same_item_cooldown'),
      );
      final dailyLimit = classifyOfflineMutationError(
        Exception('price_suggestion_daily_rate_limited'),
      );

      expect(
        sameItem.disposition,
        OfflineMutationFailureDisposition.resolve,
      );
      expect(
        dailyLimit.disposition,
        OfflineMutationFailureDisposition.resolve,
      );
    });
  });
}
