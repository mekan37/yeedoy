import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/discovery_repository.dart';
import 'nearby_campaign.dart';

typedef NearbyCampaignsParams = ({
  double? lat,
  double? lng,
  int radiusKm,
  String? city,
  String? district,
  int limit,
});

final nearbyCampaignsProvider =
    FutureProvider.autoDispose.family<List<NearbyCampaign>, NearbyCampaignsParams>((
      ref,
      params,
    ) async {
      return ref
          .read(discoveryRepositoryProvider)
          .fetchNearbyCampaigns(
            lat: params.lat,
            lng: params.lng,
            radiusKm: params.radiusKm,
            city: params.city,
            district: params.district,
            limit: params.limit,
          );
    });

