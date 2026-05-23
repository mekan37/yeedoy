import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/core/medya/uygulama_gorsel_onbellek_yonetici.dart';

void main() {
  group('AppImageCacheManager', () {
    test('returns compact policy values', () {
      final policy = AppImageCacheManager.policyForProfile(
        AppImageCacheProfile.compact,
      );
      expect(policy.maxObjects, 220);
      expect(policy.stalePeriod, const Duration(days: 10));
    });

    test('returns balanced policy values', () {
      final policy = AppImageCacheManager.policyForProfile(
        AppImageCacheProfile.balanced,
      );
      expect(policy.maxObjects, 400);
      expect(policy.stalePeriod, const Duration(days: 14));
    });

    test('returns aggressive policy values', () {
      final policy = AppImageCacheManager.policyForProfile(
        AppImageCacheProfile.aggressive,
      );
      expect(policy.maxObjects, 650);
      expect(policy.stalePeriod, const Duration(days: 21));
    });
  });
}
