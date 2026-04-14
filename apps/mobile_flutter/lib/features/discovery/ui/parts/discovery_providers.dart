part of '../discovery_page.dart';

final regionalPriceIndexProvider =
    FutureProvider.family<
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
    FutureProvider.family<
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
    FutureProvider.family<
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
