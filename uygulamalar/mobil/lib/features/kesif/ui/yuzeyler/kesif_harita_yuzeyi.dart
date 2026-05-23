part of '../kesif_sayfasi.dart';

class _DiscoveryMapSurface extends StatelessWidget {
  const _DiscoveryMapSurface({
    required this.items,
    required this.isNearby,
    required this.userLat,
    required this.userLng,
    required this.onUseNearby,
    required this.onOpenBusiness,
  });

  final List<BusinessCardModel> items;
  final bool isNearby;
  final double? userLat;
  final double? userLng;
  final VoidCallback onUseNearby;
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
    final nearest = _nearestItem(geoItems);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isNearby ? t.nearbyVerifiedSpots : t.openMapView,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (!isNearby)
                TextButton.icon(
                  onPressed: onUseNearby,
                  icon: const Icon(Icons.my_location_outlined, size: 18),
                  label: Text(t.nearbyKm(10)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 1.3,
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
                      Positioned.fill(
                        child: CustomPaint(painter: _DiscoveryMapGridPainter()),
                      ),
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
                      if (nearest != null)
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: _NearestBusinessPanel(
                            item: nearest,
                            onOpen: () => onOpenBusiness(nearest.id),
                            onDirections: () =>
                                _openDirectionsToBusiness(nearest),
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

  BusinessCardModel? _nearestItem(List<BusinessCardModel> items) {
    if (items.isEmpty) return null;
    final sorted = [...items];
    sorted.sort((a, b) {
      final ad = _distanceScore(a);
      final bd = _distanceScore(b);
      return ad.compareTo(bd);
    });
    return sorted.first;
  }

  double _distanceScore(BusinessCardModel item) {
    final explicit = item.distanceKm;
    if (explicit != null) return explicit;
    final lat = item.lat;
    final lng = item.lng;
    final originLat = userLat;
    final originLng = userLng;
    if (lat == null || lng == null || originLat == null || originLng == null) {
      return double.infinity;
    }
    return _haversineKm(originLat, originLng, lat, lng);
  }

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const earthKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _degToRad(double value) => value * math.pi / 180;

  Future<void> _openDirectionsToBusiness(BusinessCardModel item) async {
    final lat = item.lat;
    final lng = item.lng;
    if (lat == null || lng == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _DiscoveryMapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final x = size.width * i / 4;
      final y = size.height * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NearestBusinessPanel extends StatelessWidget {
  const _NearestBusinessPanel({
    required this.item,
    required this.onOpen,
    required this.onDirections,
  });

  final BusinessCardModel item;
  final VoidCallback onOpen;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final distance = item.distanceKm;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.near_me_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textStrong,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (distance != null)
                    Text(
                      distance < 1
                          ? '${(distance * 1000).round()} m'
                          : '${distance.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: onDirections,
            icon: const Icon(Icons.directions_outlined, size: 18),
            label: Text(t.businessHeaderDirectionsAction),
          ),
        ],
      ),
    );
  }
}
