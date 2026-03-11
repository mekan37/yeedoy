class DiscoveryAdPlacementPolicy {
  const DiscoveryAdPlacementPolicy({
    required this.minBusinessCountBeforeFirstAd,
    required this.repeatEveryBusinessCount,
    required this.maxAdsPerFeed,
  });

  final int minBusinessCountBeforeFirstAd;
  final int repeatEveryBusinessCount;
  final int maxAdsPerFeed;
}

const defaultDiscoveryAdPlacementPolicy = DiscoveryAdPlacementPolicy(
  minBusinessCountBeforeFirstAd: 8,
  repeatEveryBusinessCount: 8,
  maxAdsPerFeed: 2,
);

bool shouldInsertDiscoveryAdAfterBusiness({
  required int businessCountShown,
  required int adsShown,
  DiscoveryAdPlacementPolicy policy = defaultDiscoveryAdPlacementPolicy,
}) {
  if (adsShown >= policy.maxAdsPerFeed) return false;
  if (businessCountShown < policy.minBusinessCountBeforeFirstAd) return false;
  if (businessCountShown == policy.minBusinessCountBeforeFirstAd) return true;
  final delta = businessCountShown - policy.minBusinessCountBeforeFirstAd;
  return delta % policy.repeatEveryBusinessCount == 0;
}

List<int> buildDiscoveryAdInsertionPoints({
  required int totalBusinesses,
  DiscoveryAdPlacementPolicy policy = defaultDiscoveryAdPlacementPolicy,
}) {
  final points = <int>[];
  var adsShown = 0;
  for (
    var businessCount = 1;
    businessCount <= totalBusinesses;
    businessCount++
  ) {
    if (!shouldInsertDiscoveryAdAfterBusiness(
      businessCountShown: businessCount,
      adsShown: adsShown,
      policy: policy,
    )) {
      continue;
    }
    points.add(businessCount);
    adsShown += 1;
    if (adsShown >= policy.maxAdsPerFeed) break;
  }
  return points;
}
