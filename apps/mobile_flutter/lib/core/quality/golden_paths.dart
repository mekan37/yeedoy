import '../analytics/app_events.dart';

class GoldenPaths {
  static const List<String> homeToVerifySuccess = <String>[
    AppEvents.homeView,
    AppEvents.categoryClick,
    AppEvents.businessOpen,
    AppEvents.menuOpen,
    AppEvents.verifyPriceSubmit,
  ];

  static const List<String> loginRequiredFlow = <String>[
    AppEvents.businessOpen,
    AppEvents.menuOpen,
    AppEvents.reviewSubmit,
  ];

  static const List<String> offlineFallback = <String>[
    AppEvents.homeView,
  ];

  static bool containsAll({
    required List<String> requiredEvents,
    required List<String> emittedEvents,
  }) {
    final emitted = emittedEvents.toSet();
    for (final event in requiredEvents) {
      if (!emitted.contains(event)) return false;
    }
    return true;
  }
}
