import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/notifications/domain/notification_target_path_resolver.dart';

void main() {
  const businessId = '11111111-1111-4111-8111-111111111111';
  const menuItemId = '33333333-3333-4333-8333-333333333333';

  group('resolveNotificationTargetPath', () {
    test('returns menu item route for price notifications', () {
      final route = resolveNotificationTargetPath(
        type: 'price_verification_result',
        data: const {'business_id': businessId, 'menu_item_id': menuItemId},
      );
      expect(route, '/b/$businessId/menu-item/$menuItemId');
    });

    test('falls back to inbox when ids are invalid', () {
      final route = resolveNotificationTargetPath(
        type: 'price_verification_result',
        data: const {'business_id': 'not-a-uuid', 'menu_item_id': menuItemId},
      );
      expect(route, '/inbox');
    });

    test('returns reviews route for review reply', () {
      final route = resolveNotificationTargetPath(
        type: 'review_reply',
        data: const {'business_id': businessId},
      );
      expect(route, '/b/$businessId/reviews');
    });
  });

  group('resolvePushTapRoute', () {
    test('uses explicit target_path when safe', () {
      final route = resolvePushTapRoute(const {'target_path': '/profile'});
      expect(route, '/profile');
    });

    test('rejects unsafe external target_path and falls back', () {
      final route = resolvePushTapRoute(const {
        'type': 'owner_business_reported',
        'target_path': 'https://evil.example/phish',
        'business_id': businessId,
      });
      expect(route, '/b/$businessId');
    });
  });
}
