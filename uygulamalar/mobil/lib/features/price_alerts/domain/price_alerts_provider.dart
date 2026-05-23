import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/price_alerts_repository.dart';
import 'price_alert_models.dart';

class PriceAlertsParams {
  const PriceAlertsParams({this.limit = 20, this.offset = 0});
  final int limit;
  final int offset;
}

class AlertEventsParams {
  const AlertEventsParams({this.limit = 20, this.offset = 0});
  final int limit;
  final int offset;
}

final myPriceAlertsProvider =
    FutureProvider.family<List<PriceAlert>, PriceAlertsParams>((ref, params) async {
  final repo = ref.watch(priceAlertsRepositoryProvider);
  return repo.listMyAlerts(limit: params.limit, offset: params.offset);
});

final myAlertEventsProvider =
    FutureProvider.family<List<AlertEventItem>, AlertEventsParams>((ref, params) async {
  final repo = ref.watch(priceAlertsRepositoryProvider);
  final events = await repo.listMyAlertEvents(
    limit: params.limit,
    offset: params.offset,
  );
  if (events.isEmpty) return const [];

  final businessIds = events.map((e) => e.businessId).toSet().toList();
  final menuItemIds = events
      .map((e) => e.menuItemId)
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();
  final alertIds = events.map((e) => e.alertId).toSet().toList();

  final businessMap = await repo.fetchBusinessesByIds(businessIds);
  final menuItemMap = await repo.fetchMenuItemNames(menuItemIds);
  final alertMetaMap = await repo.fetchAlertMeta(alertIds);

  return [
    for (final event in events)
      AlertEventItem(
        event: event,
        businessName:
            (businessMap[event.businessId]?['name'] ?? 'İşletme').toString(),
        businessCity: (businessMap[event.businessId]?['city'] ?? '').toString(),
        businessDistrict: (businessMap[event.businessId]?['district'] ?? '').toString(),
        menuItemName: event.menuItemId == null ? null : menuItemMap[event.menuItemId],
        alertQuery: alertMetaMap[event.alertId]?.query,
        alertMaxPriceCents: alertMetaMap[event.alertId]?.maxPriceCents,
        alertCity: alertMetaMap[event.alertId]?.city,
        alertDistrict: alertMetaMap[event.alertId]?.district,
      ),
  ];
});


