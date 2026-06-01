import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../discovery/data/discovery_repository.dart';
import '../../discovery/domain/business_card.dart';

typedef SponsoredBusinessesParams = ({
  String surface,
  String? city,
  String? district,
  String? category,
  int limit,
});

SponsoredBusinessesParams sponsoredDiscoveryParams({
  required String city,
  required String district,
  String? category,
  int limit = 2,
}) {
  return (
    surface: 'discovery',
    city: city,
    district: district,
    category: category,
    limit: limit,
  );
}

final sponsoredBusinessesProvider =
    FutureProvider.autoDispose.family<List<BusinessCardModel>, SponsoredBusinessesParams>((
      ref,
      params,
    ) async {
      return ref
          .watch(discoveryRepositoryProvider)
          .fetchSponsoredBusinesses(
            surface: params.surface,
            city: params.city,
            district: params.district,
            category: params.category,
            limit: params.limit,
          );
    });
