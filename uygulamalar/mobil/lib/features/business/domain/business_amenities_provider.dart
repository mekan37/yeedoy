import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/business_amenities_repository.dart';
import 'business_amenity.dart';

final businessAmenitiesProvider =
    FutureProvider.autoDispose.family<List<BusinessAmenity>, String>((ref, businessId) async {
  return ref.watch(businessAmenitiesRepositoryProvider).listBusinessAmenities(businessId);
});
