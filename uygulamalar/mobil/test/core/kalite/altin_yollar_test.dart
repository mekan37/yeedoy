import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/core/analitik/uygulama_olaylari.dart';
import 'package:yeedoy/core/kalite/altin_yollar.dart';

void main() {
  group('Golden path coverage', () {
    test('Home -> Business -> Menu -> Verify Price -> Success', () {
      final emitted = <String>[
        AppEvents.homeView,
        AppEvents.categoryClick,
        AppEvents.businessOpen,
        AppEvents.menuOpen,
        AppEvents.verifyPriceSubmit,
      ];

      final ok = GoldenPaths.containsAll(
        requiredEvents: GoldenPaths.homeToVerifySuccess,
        emittedEvents: emitted,
      );
      expect(ok, isTrue);
    });

    test('Login required flow contains review submit milestone', () {
      final emitted = <String>[
        AppEvents.businessOpen,
        AppEvents.menuOpen,
        AppEvents.reviewSubmit,
      ];

      final ok = GoldenPaths.containsAll(
        requiredEvents: GoldenPaths.loginRequiredFlow,
        emittedEvents: emitted,
      );
      expect(ok, isTrue);
    });

    test('Offline fallback still emits home view baseline', () {
      final emitted = <String>[AppEvents.homeView];

      final ok = GoldenPaths.containsAll(
        requiredEvents: GoldenPaths.offlineFallback,
        emittedEvents: emitted,
      );
      expect(ok, isTrue);
    });
  });
}

