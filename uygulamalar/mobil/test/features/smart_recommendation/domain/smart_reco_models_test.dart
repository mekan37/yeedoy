import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/smart_recommendation/domain/smart_reco_models.dart';

void main() {
  group('SmartRecoQuery equality', () {
    test('two queries with same values are equal', () {
      const a = SmartRecoQuery(
        city: 'İstanbul',
        district: 'Kadıköy',
        partySize: 3,
        budgetMaxCents: 60000,
      );
      const b = SmartRecoQuery(
        city: 'İstanbul',
        district: 'Kadıköy',
        partySize: 3,
        budgetMaxCents: 60000,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('queries with different partySize are not equal', () {
      const a = SmartRecoQuery(
        city: 'İstanbul',
        district: 'Kadıköy',
        partySize: 2,
        budgetMaxCents: 60000,
      );
      const b = SmartRecoQuery(
        city: 'İstanbul',
        district: 'Kadıköy',
        partySize: 4,
        budgetMaxCents: 60000,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('SmartRecommendation.fromMap', () {
    test('parses all fields when present', () {
      final map = <String, dynamic>{
        'business_id': 'abc-123',
        'business_name': 'Test Lokanta',
        'image_url': 'bucket/img.jpg',
        'cuisine': 'Türk',
        'rating': 4.5,
        'review_count': 120,
        'distance_km': 1.2,
        'estimated_minutes': 15,
        'total_cents': 45000,
        'original_total_cents': 50000,
        'discount_pct': 10,
      };
      final r = SmartRecommendation.fromMap(map);
      expect(r.businessId, 'abc-123');
      expect(r.businessName, 'Test Lokanta');
      expect(r.imageUrl, 'bucket/img.jpg');
      expect(r.cuisine, 'Türk');
      expect(r.rating, 4.5);
      expect(r.reviewCount, 120);
      expect(r.distanceKm, 1.2);
      expect(r.estimatedMinutes, 15);
      expect(r.totalCents, 45000);
      expect(r.originalTotalCents, 50000);
      expect(r.discountPct, 10);
    });

    test('handles null optional fields gracefully', () {
      final map = <String, dynamic>{
        'business_id': 'abc-456',
        'business_name': 'Minimal',
        'total_cents': 30000,
      };
      final r = SmartRecommendation.fromMap(map);
      expect(r.imageUrl, isNull);
      expect(r.cuisine, isNull);
      expect(r.rating, isNull);
      expect(r.reviewCount, isNull);
      expect(r.distanceKm, isNull);
      expect(r.estimatedMinutes, isNull);
      expect(r.originalTotalCents, isNull);
      expect(r.discountPct, isNull);
    });

    test('coerces int rating to double', () {
      final map = <String, dynamic>{
        'business_id': 'x',
        'business_name': 'y',
        'total_cents': 10000,
        'rating': 4,
      };
      final r = SmartRecommendation.fromMap(map);
      expect(r.rating, 4.0);
    });

    test('coerces int distance_km to double', () {
      final map = <String, dynamic>{
        'business_id': 'x',
        'business_name': 'y',
        'total_cents': 10000,
        'distance_km': 2,
      };
      final r = SmartRecommendation.fromMap(map);
      expect(r.distanceKm, 2.0);
    });
  });
}
