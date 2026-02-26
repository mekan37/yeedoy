import '../analytics/app_events.dart';

class GoldenPaths {
  const GoldenPaths._();

  static const homeToVerifySuccess = <String>[
    AppEvents.homeView,
    AppEvents.businessOpen,
    AppEvents.menuOpen,
    AppEvents.verifyPriceSubmit,
  ];

  static const loginRequiredFlow = <String>[
    AppEvents.businessOpen,
    AppEvents.menuOpen,
    AppEvents.reviewSubmit,
  ];

  static const offlineFallback = <String>[AppEvents.homeView];

  static bool containsAll({
    required List<String> requiredEvents,
    required Iterable<String> emittedEvents,
  }) {
    final emitted = emittedEvents.toSet();
    for (final event in requiredEvents) {
      if (!emitted.contains(event)) return false;
    }
    return true;
  }
}
