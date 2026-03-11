import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/discovery/domain/discovery_feed_composer.dart';

void main() {
  group('Discovery feed ad composer', () {
    test('default policy produces no insertion under threshold', () {
      final points = buildDiscoveryAdInsertionPoints(totalBusinesses: 7);
      expect(points, isEmpty);
    });

    test('default policy inserts first ad at 8th business', () {
      final points = buildDiscoveryAdInsertionPoints(totalBusinesses: 8);
      expect(points, [8]);
    });

    test('default policy inserts ads at 8 and 16 then caps at max 2', () {
      final points = buildDiscoveryAdInsertionPoints(totalBusinesses: 40);
      expect(points, [8, 16]);
    });

    test('shouldInsertDiscoveryAdAfterBusiness respects max ad count', () {
      expect(
        shouldInsertDiscoveryAdAfterBusiness(
          businessCountShown: 8,
          adsShown: 0,
        ),
        isTrue,
      );
      expect(
        shouldInsertDiscoveryAdAfterBusiness(
          businessCountShown: 16,
          adsShown: 1,
        ),
        isTrue,
      );
      expect(
        shouldInsertDiscoveryAdAfterBusiness(
          businessCountShown: 24,
          adsShown: 2,
        ),
        isFalse,
      );
    });
  });
}
