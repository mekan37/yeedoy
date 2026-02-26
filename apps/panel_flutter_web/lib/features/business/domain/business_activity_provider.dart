import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../src/data/repositories/business_activity_repository.dart';
import 'business_activity.dart';

final businessActivityProvider =
    FutureProvider.family<List<BusinessActivityItem>, String>((ref, businessId) async {
  return ref.watch(businessActivityRepositoryProvider).listBusinessActivity(
        businessId: businessId,
        limit: 8,
      );
});
