import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/core/depolama/cevrimdisi_degisim_kuyrugu.dart';
import 'package:yeedoy/core/depolama/cevrimdisi_kuyruk_tani.dart';

void main() {
  group('buildOfflineQueueDiagnosticsSummary', () {
    test('summarizes queue health and error buckets', () {
      final now = DateTime.utc(2026, 3, 7, 12, 0);
      final summary = buildOfflineQueueDiagnosticsSummary(
        <OfflineMutationQueueItem>[
          OfflineMutationQueueItem(
            id: 'verify_1',
            kind: OfflineMutationQueueKind.verifyVotePrice,
            createdAt: DateTime.utc(2026, 3, 7, 11, 50),
            payload: const {'menu_item_id': 'm1', 'vote': 1},
          ),
          OfflineMutationQueueItem(
            id: 'submission_1',
            kind: OfflineMutationQueueKind.reportBusiness,
            createdAt: DateTime.utc(2026, 3, 7, 11, 40),
            payload: const {'business_id': 'b1', 'reason': 'wrong_info'},
            status: OfflineMutationQueueStatus.retrying,
            retryCount: 2,
            lastError: '429 rate limit',
            nextRetryAt: DateTime.utc(2026, 3, 7, 12, 5),
            lastAttemptAt: DateTime.utc(2026, 3, 7, 11, 59),
          ),
          OfflineMutationQueueItem(
            id: 'submission_2',
            kind: OfflineMutationQueueKind.businessSuggestion,
            createdAt: DateTime.utc(2026, 3, 7, 11, 45),
            payload: const {
              'name': 'Cafe X',
              'category': 'cafe',
              'city': 'Istanbul',
            },
            status: OfflineMutationQueueStatus.retrying,
            retryCount: 1,
            lastError: '429 rate limit',
            nextRetryAt: DateTime.utc(2026, 3, 7, 11, 58),
          ),
        ],
        now: now,
      );

      expect(summary.total, 3);
      expect(summary.verifyCount, 1);
      expect(summary.submissionCount, 2);
      expect(summary.retryingCount, 2);
      expect(summary.pendingCount, 1);
      expect(summary.readyCount, 2);
      expect(summary.blockedCount, 1);
      expect(summary.nextRetryAt, DateTime.utc(2026, 3, 7, 11, 58));
      expect(summary.errorBuckets, hasLength(1));
      expect(summary.errorBuckets.single.message, '429 rate limit');
      expect(summary.errorBuckets.single.count, 2);
      expect(
        summary.visibleItems.first.operatorAction,
        'Do not force flush; wait for the next retry window.',
      );
    });

    test('prioritizes retrying items and derives human labels', () {
      final summary = buildOfflineQueueDiagnosticsSummary(
        <OfflineMutationQueueItem>[
          OfflineMutationQueueItem(
            id: 'submission_1',
            kind: OfflineMutationQueueKind.reportBusiness,
            createdAt: DateTime.utc(2026, 3, 7, 11, 40),
            payload: const {'business_id': 'b1', 'reason': 'wrong_info'},
            status: OfflineMutationQueueStatus.retrying,
            retryCount: 3,
            lastError: 'SocketException',
            nextRetryAt: DateTime.utc(2026, 3, 7, 12, 10),
          ),
          OfflineMutationQueueItem(
            id: 'verify_1',
            kind: OfflineMutationQueueKind.verifySuggestPrice,
            createdAt: DateTime.utc(2026, 3, 7, 11, 41),
            payload: const {
              'menu_item_id': 'm1',
              'suggested_price_cents': 19500,
              'currency': 'TRY',
            },
          ),
        ],
        now: DateTime.utc(2026, 3, 7, 12, 0),
      );

      expect(summary.visibleItems, hasLength(2));
      expect(summary.visibleItems.first.label, 'Business report');
      expect(summary.visibleItems.first.target, 'business:b1');
      expect(summary.visibleItems.first.detail, 'reason=wrong_info');
      expect(
        summary.visibleItems.first.operatorAction,
        'Wait for connectivity restore or retry after network recovers.',
      );
      expect(summary.visibleItems.last.label, 'Price suggestion');
      expect(summary.visibleItems.last.target, 'menu:m1');
      expect(summary.visibleItems.last.detail, '19500 TRY');
    });
  });
}
