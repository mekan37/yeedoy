import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/core/depolama/cevrimdisi_esitleme_servisi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineSyncService', () {
    test('flushes queues and prunes snapshots', () async {
      var verifyCalls = 0;
      var submissionCalls = 0;
      var pruneCalls = 0;
      final service = OfflineSyncService(
        flushVerifyQueue: ({int maxItems = 20}) async {
          verifyCalls += 1;
          return 2;
        },
        flushSubmissionQueue: ({int maxItems = 25}) async {
          submissionCalls += 1;
          return 3;
        },
        pruneSnapshots: () async {
          pruneCalls += 1;
          return 1;
        },
        canFlushSubmissionQueue: () => true,
        reportSyncResult: (_) async {},
        reportSyncError: (error, stackTrace, reason) async {},
        now: () => DateTime.utc(2026, 3, 6, 10, 0, 0),
      );

      final result = await service.syncNow(reason: 'manual');

      expect(result.skipped, isFalse);
      expect(result.verifySent, 2);
      expect(result.submissionSent, 3);
      expect(result.prunedRecords, 1);
      expect(verifyCalls, 1);
      expect(submissionCalls, 1);
      expect(pruneCalls, 1);
    });

    test('respects retry backoff window', () async {
      var now = DateTime.utc(2026, 3, 6, 10, 0, 0);
      var verifyCalls = 0;
      final service = OfflineSyncService(
        flushVerifyQueue: ({int maxItems = 20}) async {
          verifyCalls += 1;
          return 0;
        },
        flushSubmissionQueue: ({int maxItems = 25}) async => 0,
        pruneSnapshots: () async => 0,
        canFlushSubmissionQueue: () => true,
        reportSyncResult: (_) async {},
        reportSyncError: (error, stackTrace, reason) async {},
        now: () => now,
      );

      final first = await service.syncNow(reason: 'first');
      now = now.add(const Duration(seconds: 5));
      final second = await service.syncNow(reason: 'second');
      now = now.add(const Duration(seconds: 25));
      final third = await service.syncNow(reason: 'third');

      expect(first.skipped, isFalse);
      expect(second.skipped, isTrue);
      expect(third.skipped, isFalse);
      expect(verifyCalls, 2);
    });
  });
}
