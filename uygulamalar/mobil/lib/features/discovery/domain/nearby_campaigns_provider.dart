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

class CampaignsFilterNotifier extends Notifier<CampaignFilter> {
  @override
  CampaignFilter build() => CampaignFilter.all;

  void setFilter(CampaignFilter filter) => state = filter;
}

final campaignsFilterProvider =
    NotifierProvider<CampaignsFilterNotifier, CampaignFilter>(
      CampaignsFilterNotifier.new,
    );

class CampaignsSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final campaignsSearchQueryProvider =
    NotifierProvider<CampaignsSearchQueryNotifier, String>(
      CampaignsSearchQueryNotifier.new,
    );

final nearbyCampaignsProvider = AsyncNotifierProvider.autoDispose
    .family<NearbyCampaignsNotifier, List<NearbyCampaign>, NearbyCampaignsParams>(
      (arg) => NearbyCampaignsNotifier(arg),
    );

class NearbyCampaignsNotifier extends AsyncNotifier<List<NearbyCampaign>> {
  NearbyCampaignsNotifier(this.params);

  final NearbyCampaignsParams params;

  @override
  Future<List<NearbyCampaign>> build() {
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
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> toggleSaved(String storyId) async {
    final current = state.value;
    if (current == null) return;

    NearbyCampaign? target;
    for (final c in current) {
      if (c.storyId == storyId) {
        target = c;
        break;
      }
    }
    if (target == null) return;

    final optimistic = toggleCampaignSavedInList(
      current,
      storyId,
      !target.isSaved,
    );
    state = AsyncData(optimistic);

    try {
      final saved = await ref
          .read(discoveryRepositoryProvider)
          .toggleSavedCampaign(storyId);
      state = AsyncData(toggleCampaignSavedInList(optimistic, storyId, saved));
    } catch (_) {
      await refresh();
      rethrow;
    }
  }
}
