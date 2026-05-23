import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/isletme_yeni_urunler_deposu.dart';
import 'isletme_yeni_urun.dart';

final businessNewItemsProvider =
    FutureProvider.family<List<BusinessNewItem>, String>((ref, businessId) async {
  return ref.watch(businessNewItemsRepositoryProvider).listNewItems(
        businessId: businessId,
        limit: 6,
      );
});

