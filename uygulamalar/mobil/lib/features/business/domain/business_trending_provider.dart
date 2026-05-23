import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/business_trending_repository.dart';
import 'business_trending_item.dart';

final businessTrendingItemsProvider =
    FutureProvider.family<List<BusinessTrendingItem>, String>((ref, businessId) async {
  return ref.watch(businessTrendingRepositoryProvider).listTrendingItems(
        businessId: businessId,
        limit: 6,
      );
});
