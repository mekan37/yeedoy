import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/core/analytics/analytics_repository.dart';

void main() {
  group('AnalyticsRepository', () {
    test('sends event immediately when rpc succeeds', () async {
      final calls = <Map<String, dynamic>>[];
      final repo = AnalyticsRepository.forTest(
        rpc: (fn, {params}) async {
          calls.add((params ?? <String, dynamic>{}).cast<String, dynamic>());
          return {'ok': true};
        },
      );

      final ok = await repo.logEvent(
        eventName: 'home_view',
        businessId: 'b1',
        menuId: 'm1',
      );

      expect(ok, isTrue);
      expect(repo.pendingEvents, 0);
      expect(calls.length, 1);
      expect(calls.first['p_event_name'], 'home_view');
    });

    test('queues failed event and flushes later', () async {
      var callCount = 0;
      final repo = AnalyticsRepository.forTest(
        rpc: (fn, {params}) async {
          callCount += 1;
          if (callCount == 1) {
            throw Exception('network offline');
          }
          return {'ok': true};
        },
      );

      final ok = await repo.logEvent(eventName: 'menu_open');
      expect(ok, isFalse);
      expect(repo.pendingEvents, 1);

      await repo.flushNow();

      expect(callCount, 2);
      expect(repo.pendingEvents, 0);
    });

    test('drops oldest events when queue limit is exceeded', () async {
      var fail = true;
      final sent = <String>[];
      final repo = AnalyticsRepository.forTest(
        maxQueueSize: 2,
        rpc: (fn, {params}) async {
          final name = (params?['p_event_name'] ?? '').toString();
          if (fail) return {'ok': false};
          sent.add(name);
          return {'ok': true};
        },
      );

      await repo.logEvent(eventName: 'e1');
      await repo.logEvent(eventName: 'e2');
      await repo.logEvent(eventName: 'e3');

      expect(repo.pendingEvents, 2);
      expect(repo.droppedEvents, 1);

      fail = false;
      await repo.flushNow();

      expect(repo.pendingEvents, 0);
      expect(sent, ['e2', 'e3']);
    });

    test('drops event after max retry attempts', () async {
      final repo = AnalyticsRepository.forTest(
        maxAttempts: 2,
        rpc: (fn, {params}) async => throw Exception('still offline'),
      );

      await repo.logEvent(eventName: 'retry_me');
      expect(repo.pendingEvents, 1);

      await repo.flushNow();
      expect(repo.pendingEvents, 1);

      await repo.flushNow();
      expect(repo.pendingEvents, 0);
    });

    test('merges default meta fields and preserves explicit user_id', () async {
      Map<String, dynamic>? captured;
      final repo = AnalyticsRepository.forTest(
        devUserId: 'dev_user',
        currentUserId: () => 'real_user',
        rpc: (fn, {params}) async {
          captured = (params ?? <String, dynamic>{}).cast<String, dynamic>();
          return {'ok': true};
        },
      );

      await repo.logEvent(
        eventName: 'business_open',
        businessId: 'biz_1',
        menuId: 'menu_1',
        meta: {'user_id': 'meta_user', 'source_variant': 'A'},
      );

      final meta = (captured?['p_meta'] as Map).cast<String, dynamic>();
      expect(meta['user_id'], 'meta_user');
      expect(meta['business_id'], 'biz_1');
      expect(meta['menu_id'], 'menu_1');
      expect(meta['source_variant'], 'A');
    });
  });
}
