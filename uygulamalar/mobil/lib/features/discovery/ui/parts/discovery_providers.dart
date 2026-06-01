part of '../discovery_page.dart';

final regionalPriceIndexProvider =
    FutureProvider.autoDispose.family<
      List<RegionalPriceIndexItem>,
      ({String city, String district})
    >((ref, params) {
      return ref
          .watch(discoveryRepositoryProvider)
          .fetchRegionalPriceIndex(
            city: params.city,
            district: params.district,
            limit: 10,
          );
    });

final priceAnomaliesProvider =
    FutureProvider.autoDispose.family<
      List<PriceAnomalyItem>,
      ({String city, String district})
    >((ref, params) {
      return ref
          .watch(discoveryRepositoryProvider)
          .fetchPriceAnomalies(
            city: params.city,
            district: params.district,
            days: 30,
            minChangePct: 40,
            limit: 8,
          );
    });

final homeFeedProvider =
    FutureProvider.autoDispose.family<
      HomeFeedData,
      ({String city, String district, String? neighborhood})
    >((ref, params) {
      return ref
          .watch(discoveryRepositoryProvider)
          .fetchHomeFeed(
            city: params.city,
            district: params.district,
            neighborhood: params.neighborhood,
          );
    });
