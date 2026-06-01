import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeedoy/core/storage/local_db/shared_prefs_local_db_store.dart';
import 'package:yeedoy/core/storage/offline_mutation_queue.dart';
import 'package:yeedoy/core/storage/offline_submission_queue.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await OfflineMutationQueueStore.setStoreForTesting(
      SharedPrefsLocalDbStore(),
    );
  });

  tearDown(() async {
    await OfflineMutationQueueStore.setStoreForTesting(null);
  });

  group('OfflineSubmissionQueueStore', () {
    test('enqueue + readAll roundtrip', () async {
      await OfflineSubmissionQueueStore.enqueue(
        OfflineSubmissionType.reviewCreate,
        {'business_id': 'b1', 'rating': 5, 'content': 'great'},
      );
      await OfflineSubmissionQueueStore.enqueue(
        OfflineSubmissionType.businessSuggestion,
        {'name': 'Cafe X', 'category': 'cafe'},
      );

      final items = await OfflineSubmissionQueueStore.readAll();
      expect(items.length, 2);
      expect(items.first.type, OfflineSubmissionType.reviewCreate);
      expect(items.last.type, OfflineSubmissionType.businessSuggestion);
    });

    test('deduplicates same logical payload via idempotency key', () async {
      await OfflineSubmissionQueueStore.enqueue(
        OfflineSubmissionType.reportBusiness,
        {'business_id': 'b1', 'reason': 'wrong_info'},
      );
      await OfflineSubmissionQueueStore.enqueue(
        OfflineSubmissionType.reportBusiness,
        {'business_id': 'b1', 'reason': 'wrong_info'},
      );

      final items = await OfflineSubmissionQueueStore.readAll();

      expect(items, hasLength(1));
      expect(items.single.payload['idempotency_key'], isNotNull);
    });
  });

  group('flushOfflineSubmissionQueueWithDispatcher', () {
    test('removes items when dispatch succeeds', () async {
      await OfflineSubmissionQueueStore.enqueue(
        OfflineSubmissionType.reportBusiness,
        {'business_id': 'b1', 'reason': 'wrong_info'},
      );
      await OfflineSubmissionQueueStore.enqueue(
        OfflineSubmissionType.reportReview,
        {'review_id': 'r1', 'reason': 'spam'},
      );

      final dispatched = <OfflineSubmissionType>[];
      final sent = await flushOfflineSubmissionQueueWithDispatcher(
        dispatch: (item) async {
          dispatched.add(item.type);
        },
      );

      expect(sent, 2);
      expect(dispatched, [
        OfflineSubmissionType.reportBusiness,
        OfflineSubmissionType.reportReview,
      ]);
      expect(await OfflineSubmissionQueueStore.readAll(), isEmpty);
    });

    test(
      'keeps current and remaining items when offline error occurs',
      () async {
        await OfflineSubmissionQueueStore.enqueue(
          OfflineSubmissionType.reportBusiness,
          {'business_id': 'b1', 'reason': 'wrong_info'},
        );
        await OfflineSubmissionQueueStore.enqueue(
          OfflineSubmissionType.businessSuggestion,
          {'name': 'Cafe X', 'category': 'cafe'},
        );

        final sent = await flushOfflineSubmissionQueueWithDispatcher(
          dispatch: (item) async {
            if (item.type == OfflineSubmissionType.reportBusiness) {
              throw Exception('SocketException: failed host lookup');
            }
          },
        );

        final remaining = await OfflineSubmissionQueueStore.readAll();
        expect(sent, 0);
        expect(remaining.length, 2);
        expect(remaining.first.type, OfflineSubmissionType.reportBusiness);
        expect(remaining.last.type, OfflineSubmissionType.businessSuggestion);
        expect(remaining.first.retryCount, 1);
        expect(remaining.first.nextRetryAt, isNotNull);
      },
    );

    test('drops non-offline failing item and continues', () async {
      await OfflineSubmissionQueueStore.enqueue(
        OfflineSubmissionType.reportBusiness,
        {'business_id': 'b1', 'reason': 'wrong_info'},
      );
      await OfflineSubmissionQueueStore.enqueue(
        OfflineSubmissionType.reviewCreate,
        {'business_id': 'b1', 'rating': 4, 'content': 'nice'},
      );

      final sent = await flushOfflineSubmissionQueueWithDispatcher(
        dispatch: (item) async {
          if (item.type == OfflineSubmissionType.reportBusiness) {
            throw Exception('validation_failed');
          }
        },
      );

      expect(sent, 1);
      expect(await OfflineSubmissionQueueStore.readAll(), isEmpty);
    });

    test('resolves duplicate/conflict failures without keeping item', () async {
      await OfflineSubmissionQueueStore.enqueue(
        OfflineSubmissionType.reportBusiness,
        {'business_id': 'b1', 'reason': 'wrong_info'},
      );

      final sent = await flushOfflineSubmissionQueueWithDispatcher(
        dispatch: (item) async {
          throw Exception('duplicate key value violates unique constraint');
        },
      );

      expect(sent, 1);
      expect(await OfflineSubmissionQueueStore.readAll(), isEmpty);
    });
  });
}
