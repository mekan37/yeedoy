import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/business_new_items_repository.dart';
import 'business_new_item.dart';

final businessNewItemsProvider =
    FutureProvider.family<List<BusinessNewItem>, String>((ref, businessId) async {
  return ref.watch(businessNewItemsRepositoryProvider).listNewItems(
        businessId: businessId,
        limit: 6,
      );
});
