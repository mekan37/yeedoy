import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy_shared_models/yeedoy_shared_models.dart';

void main() {
  group('BusinessAmenity.fromMap', () {
    test('prefers amenity_id over id', () {
      final amenity = BusinessAmenity.fromMap({
        'amenity_id': 'a-1',
        'id': 'ignored',
        'key': 'wifi',
        'label': 'Ücretsiz Wi-Fi',
        'icon': 'wifi',
      });

      expect(amenity.id, 'a-1');
    });

    test('falls back to id when amenity_id is absent', () {
      final amenity = BusinessAmenity.fromMap({
        'id': 'a-2',
        'key': 'parking',
        'label': 'Otopark',
        'icon': 'local_parking',
      });

      expect(amenity.id, 'a-2');
    });

    test('defaults missing fields to empty strings', () {
      final amenity = BusinessAmenity.fromMap(const {});

      expect(amenity.id, '');
      expect(amenity.key, '');
      expect(amenity.label, '');
      expect(amenity.icon, '');
    });
  });

  group('equality', () {
    test('two amenities with identical fields are equal', () {
      final a = BusinessAmenity(id: '1', key: 'wifi', label: 'Wi-Fi', icon: 'wifi');
      final b = BusinessAmenity(id: '1', key: 'wifi', label: 'Wi-Fi', icon: 'wifi');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('amenities with different keys are not equal', () {
      final a = BusinessAmenity(id: '1', key: 'wifi', label: 'Wi-Fi', icon: 'wifi');
      final b = BusinessAmenity(id: '1', key: 'parking', label: 'Wi-Fi', icon: 'wifi');

      expect(a, isNot(b));
    });
  });
}
