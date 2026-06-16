import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/business/domain/business.dart';

void main() {
  group('Business.fromMap', () {
    test('reads priceLevel from price_level key', () {
      final map = {
        'id': 'b1',
        'name': 'Test',
        'category': 'Restoran',
        'price_level': 'mid',
      };
      final business = Business.fromMap(map);
      expect(business.priceLevel, 'mid');
    });

    test('priceLevel is null when price_level key is absent', () {
      final map = {
        'id': 'b2',
        'name': 'Test',
        'category': 'Restoran',
      };
      final business = Business.fromMap(map);
      expect(business.priceLevel, isNull);
    });
  });
}
