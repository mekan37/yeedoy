import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/isletme_trend_deposu.dart';
import 'isletme_trend_ogesi.dart';

final businessTrendingItemsProvider =
    FutureProvider.family<List<BusinessTrendingItem>, String>((ref, businessId) async {
  return ref.watch(businessTrendingRepositoryProvider).listTrendingItems(
        businessId: businessId,
        limit: 6,
      );
});

