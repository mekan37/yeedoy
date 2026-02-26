import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../src/data/repositories/business_amenities_repository.dart';
import 'business_amenity.dart';

final allAmenitiesProvider = FutureProvider<List<BusinessAmenity>>((ref) async {
  return ref.watch(businessAmenitiesRepositoryProvider).listAllAmenities();
});

final businessAmenitiesProvider =
    FutureProvider.family<List<BusinessAmenity>, String>((ref, businessId) async {
  return ref.watch(businessAmenitiesRepositoryProvider).listBusinessAmenities(businessId);
});
