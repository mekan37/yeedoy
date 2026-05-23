part of '../discovery_page.dart';

class _DiscoveryMapSurface extends StatelessWidget {
  const _DiscoveryMapSurface({
    required this.items,
    required this.onOpenBusiness,
  });

  final List<BusinessCardModel> items;
  final ValueChanged<String> onOpenBusiness;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final geoItems = items
        .where((b) => b.lat != null && b.lng != null)
        .toList();
    if (geoItems.isEmpty) {
      return AppEmptyState(
        icon: Icons.map_outlined,
        title: t.noLocationDataForMap,
        description: t.mapDataMissingUseList,
      );
    }

    final minLat = geoItems.map((e) => e.lat!).reduce(math.min);
    final maxLat = geoItems.map((e) => e.lat!).reduce(math.max);
    final minLng = geoItems.map((e) => e.lng!).reduce(math.min);
    final maxLng = geoItems.map((e) => e.lng!).reduce(math.max);
    final latSpan = math.max(maxLat - minLat, 0.001);
    final lngSpan = math.max(maxLng - minLng, 0.001);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.openMapView,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 1.6,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: LayoutBuilder(
                builder: (context, c) {
                  return Stack(
                    children: [
                      for (final b in geoItems.take(40))
                        Positioned(
                          left:
                              (((b.lng! - minLng) / lngSpan) *
                                      (c.maxWidth - 28))
                                  .clamp(6, c.maxWidth - 28),
                          top:
                              (((maxLat - b.lat!) / latSpan) *
                                      (c.maxHeight - 28))
                                  .clamp(6, c.maxHeight - 28),
                          child: GestureDetector(
                            onTap: () => onOpenBusiness(b.id),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.place,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.mapHintTapPins,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
