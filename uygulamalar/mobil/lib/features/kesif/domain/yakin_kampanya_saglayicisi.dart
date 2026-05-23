import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/kesif_deposu.dart';
import 'yakin_kampanya.dart';

typedef NearbyCampaignsParams = ({
  double? lat,
  double? lng,
  int radiusKm,
  String? city,
  String? district,
  int limit,
});

final nearbyCampaignsProvider =
    FutureProvider.family<List<NearbyCampaign>, NearbyCampaignsParams>((
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


