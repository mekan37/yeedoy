import '../../../core/security/route_sanitizer.dart';

String resolveNotificationTargetPath({
  required String type,
  required Map<String, dynamic> data,
}) {
  final businessId = sanitizeUuid((data['business_id'] ?? '').toString());
  final menuItemId = sanitizeUuid((data['menu_item_id'] ?? '').toString());

  switch (type) {
    case 'price_suggestion_result':
    case 'price_verification_result':
    case 'favorite_price_changed':
    case 'owner_new_price_suggestion':
      if (businessId != null && menuItemId != null) {
        return '/b/$businessId/menu-item/$menuItemId';
      }
      if (businessId != null) return '/b/$businessId';
      return '/inbox';
    case 'review_reply':
    case 'owner_new_review':
      if (businessId != null) return '/b/$businessId/reviews';
      return '/inbox';
    case 'favorite_revisit_reminder':
    case 'friend_checkin':
      if (businessId != null) return '/b/$businessId';
      return '/discover';
    case 'owner_business_reported':
      if (businessId != null) return '/b/$businessId';
      return '/discover';
    case 'claim_result':
    case 'achievement_unlocked':
      return '/profile';
    case 'report_result':
      return '/inbox';
    case 'nearby_trending':
    case 'owner_daily_summary':
      return '/discover';
    default:
      if (businessId != null) return '/b/$businessId';
      return '/inbox';
  }
}

String? resolvePushTapRoute(Map<String, dynamic> data) {
  final explicitTarget = sanitizeInternalRedirect(
    (data['target_path'] ?? data['targetPath'] ?? '').toString(),
  );
  if (explicitTarget != null) return explicitTarget;

  final type = (data['type'] ?? '').toString();
  final fallback = resolveNotificationTargetPath(type: type, data: data);
  return sanitizeInternalRedirect(fallback);
}
