import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/kesif/domain/isletme_karti.dart';
import 'package:yeedoy/features/kesif/domain/ana_akis.dart';

void main() {
  group('API contract - discovery', () {
    test('home_feed_v1 payload parses with required sections', () {
      final payload = <String, dynamic>{
        'near_open_businesses': [
          {
            'id': 'b1',
            'name': 'Test Lokanta',
            'category': 'Lokanta',
            'distance_km': 0.8,
            'is_open_now': true,
          },
        ],
        'top_categories': [
          {
            'category': 'Kebap',
            'item_count': 12,
            'median_price_cents': 22000,
            'currency': 'TRY',
          },
        ],
        'trending_top_views': [
          {
            'id': 'b2',
            'name': 'View Place',
            'category': 'Cafe',
            'views_count': 88,
          },
        ],
        'trending_price_changes': [
          {
            'id': 'b3',
            'name': 'Price Place',
            'category': 'Doner',
            'price_changes_count': 7,
          },
        ],
        'trending_night_favorites': [
          {
            'id': 'b4',
            'name': 'Night Place',
            'category': 'Fast Food',
            'favorites_count': 15,
          },
        ],
        'generated_at': '2026-02-13T12:00:00Z',
      };

      final data = HomeFeedData.fromMap(payload);
      expect(data.nearOpenBusinesses, hasLength(1));
      expect(data.topCategories, hasLength(1));
      expect(data.topViews.first.metric, 88);
      expect(data.priceChanges.first.metric, 7);
      expect(data.nightFavorites.first.metric, 15);
      expect(data.generatedAt, isNotNull);
    });

    test('search_businesses_v1 item contract parses', () {
      final json = <String, dynamic>{
        'id': 'x1',
        'name': 'Search Place',
        'category': 'Cafe',
        'city': 'Ankara',
        'district': 'Yenimahalle',
        'distance_km': 1.2,
        'quality_score': 4.2,
        'avg_rating': 4.5,
        'trust_score': 0.89,
        'median_price_cents': 18000,
        'is_open_now': true,
        'meal_card_providers': [
          {
            'provider_id': 'meal-1',
            'key': 'multinet',
            'name': 'MultiNet',
            'asset_name': 'meal_card_multinet.png',
            'sort_order': 10,
          },
        ],
      };

      final model = BusinessCardModel.fromMap(json);
      expect(model.id, 'x1');
      expect(model.name, 'Search Place');
      expect(model.category, 'Cafe');
      expect(model.city, 'Ankara');
      expect(model.isOpenNow, isTrue);
      expect(model.medianPriceCents, 18000);
      expect(model.mealCardProviders, hasLength(1));
      expect(model.mealCardProviders.first.key, 'multinet');
    });
  });
}


