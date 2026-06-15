import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/discovery/domain/nearby_campaign.dart';

void main() {
  group('NearbyCampaign.fromMap', () {
    test('parses discount/category/featured/saved fields', () {
      final campaign = NearbyCampaign.fromMap({
        'story_id': 'story-1',
        'business_id': 'b1',
        'business_name': 'Test Cafe',
        'media_url': 'https://example.com/img.jpg',
        'expires_at': '2026-06-14T10:00:00Z',
        'discount_percent': 25,
        'category': 'tatli',
        'is_featured': true,
        'is_saved': true,
      });

      expect(campaign.storyId, 'story-1');
      expect(campaign.discountPercent, 25);
      expect(campaign.category, 'tatli');
      expect(campaign.isFeatured, isTrue);
      expect(campaign.isSaved, isTrue);
    });

    test('defaults new fields when absent', () {
      final campaign = NearbyCampaign.fromMap({
        'story_id': 'story-2',
        'business_id': 'b1',
        'business_name': 'Test Cafe',
        'media_url': 'https://example.com/img.jpg',
        'expires_at': '2026-06-14T10:00:00Z',
      });

      expect(campaign.discountPercent, isNull);
      expect(campaign.category, isNull);
      expect(campaign.isFeatured, isFalse);
      expect(campaign.isSaved, isFalse);
    });
  });

  group('NearbyCampaign.copyWith', () {
    test('overrides isSaved without mutating other fields', () {
      final campaign = NearbyCampaign.fromMap({
        'story_id': 'story-1',
        'business_id': 'b1',
        'business_name': 'Test Cafe',
        'media_url': 'https://example.com/img.jpg',
        'expires_at': '2026-06-14T10:00:00Z',
        'is_saved': false,
      });

      final updated = campaign.copyWith(isSaved: true);

      expect(updated.isSaved, isTrue);
      expect(updated.storyId, campaign.storyId);
      expect(updated.businessName, campaign.businessName);
    });
  });

  group('applyCampaignFilter', () {
    final now = DateTime.utc(2026, 6, 13, 12, 0, 0);

    NearbyCampaign campaign({
      String storyId = 's',
      DateTime? expiresAt,
      String? category,
      int? discountPercent,
    }) {
      return NearbyCampaign.fromMap({
        'story_id': storyId,
        'business_id': 'b1',
        'business_name': 'Test Cafe',
        'media_url': 'https://example.com/img.jpg',
        'expires_at': (expiresAt ?? now.add(const Duration(days: 2)))
            .toIso8601String(),
        'category': category,
        'discount_percent': discountPercent,
      });
    }

    test('all returns every item', () {
      final items = [campaign(storyId: 'a'), campaign(storyId: 'b')];
      expect(applyCampaignFilter(items, CampaignFilter.all, now: now), items);
    });

    test('soon keeps items expiring within 24 hours', () {
      final soon = campaign(
        storyId: 'soon',
        expiresAt: now.add(const Duration(hours: 5)),
      );
      final later = campaign(
        storyId: 'later',
        expiresAt: now.add(const Duration(days: 3)),
      );
      final result = applyCampaignFilter(
        [soon, later],
        CampaignFilter.soon,
        now: now,
      );
      expect(result, [soon]);
    });

    test('today keeps items expiring on the same calendar date', () {
      final today = campaign(
        storyId: 'today',
        expiresAt: DateTime.utc(2026, 6, 13, 23, 0, 0),
      );
      final tomorrow = campaign(
        storyId: 'tomorrow',
        expiresAt: DateTime.utc(2026, 6, 14, 1, 0, 0),
      );
      final result = applyCampaignFilter(
        [today, tomorrow],
        CampaignFilter.today,
        now: now,
      );
      expect(result, [today]);
    });

    test('food keeps category == yemek', () {
      final food = campaign(storyId: 'food', category: 'yemek');
      final dessert = campaign(storyId: 'dessert', category: 'tatli');
      final result = applyCampaignFilter(
        [food, dessert],
        CampaignFilter.food,
        now: now,
      );
      expect(result, [food]);
    });

    test('dessert keeps category == tatli', () {
      final food = campaign(storyId: 'food', category: 'yemek');
      final dessert = campaign(storyId: 'dessert', category: 'tatli');
      final result = applyCampaignFilter(
        [food, dessert],
        CampaignFilter.dessert,
        now: now,
      );
      expect(result, [dessert]);
    });

    test('discount20 keeps discountPercent >= 20', () {
      final big = campaign(storyId: 'big', discountPercent: 25);
      final small = campaign(storyId: 'small', discountPercent: 10);
      final none = campaign(storyId: 'none');
      final result = applyCampaignFilter(
        [big, small, none],
        CampaignFilter.discount20,
        now: now,
      );
      expect(result, [big]);
    });
  });
}
