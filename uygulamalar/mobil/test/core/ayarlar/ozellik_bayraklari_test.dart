import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/core/config/feature_flags.dart';

void main() {
  group('FeatureFlagsState', () {
    test('uses static defaults when local override is missing', () {
      final state = FeatureFlagsState.empty();
      expect(state.enableLabs, FeatureFlags.enableLabs);
      expect(state.enableQrAutoCheckin, FeatureFlags.enableQrAutoCheckin);
      expect(state.enableQrAutoCheckin, isFalse);
      expect(state.hasExperimentalNavigation, isFalse);
    });

    test('prefers local override values', () {
      const state = FeatureFlagsState(
        localFlags: {
          'enableLabs': true,
          'enableQrAutoCheckin': true,
        },
      );
      expect(state.enableLabs, isTrue);
      expect(state.enableQrAutoCheckin, isTrue);
      expect(state.hasExperimentalNavigation, isTrue);
    });
  });
}
