import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/core/ag/baglanti_kurtarma_servisi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectivityRestoreService', () {
    test('triggers replay when connectivity is restored', () async {
      final events = <ConnectivityRestoreEvent>[];
      final restoredTriggers = <String>[];
      var online = false;
      final service = ConnectivityRestoreService(
        probeOnline: () async => online,
        onConnectivityRestored: (trigger) async {
          restoredTriggers.add(trigger);
        },
        reportConnectivityEvent: (event) async {
          events.add(event);
        },
      );

      await service.probeNow(trigger: 'initial');
      online = true;
      await service.probeNow(trigger: 'resume');

      expect(restoredTriggers, <String>['resume']);
      expect(events, hasLength(1));
      expect(events.single.online, isTrue);
      expect(events.single.restored, isTrue);
      expect(events.single.trigger, 'resume');
    });

    test('reports connectivity loss without replay', () async {
      final events = <ConnectivityRestoreEvent>[];
      final restoredTriggers = <String>[];
      var online = true;
      final service = ConnectivityRestoreService(
        probeOnline: () async => online,
        onConnectivityRestored: (trigger) async {
          restoredTriggers.add(trigger);
        },
        reportConnectivityEvent: (event) async {
          events.add(event);
        },
      );

      await service.probeNow(trigger: 'initial');
      online = false;
      await service.probeNow(trigger: 'heartbeat');

      expect(restoredTriggers, isEmpty);
      expect(events, hasLength(1));
      expect(events.single.online, isFalse);
      expect(events.single.restored, isFalse);
      expect(events.single.trigger, 'heartbeat');
    });
  });
}
