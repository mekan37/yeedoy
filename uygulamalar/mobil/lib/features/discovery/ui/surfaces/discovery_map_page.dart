part of '../discovery_page.dart';

/// Default map center used until the user's location or business results
/// are available. Centered on Adana (Yeedoy's primary launch market).
const LatLng _kDiscoveryMapDefaultCenter = LatLng(37.0, 35.3213);

/// Full-screen OSM-based map view of Discovery, reachable via
/// `/discover?view=map` (see [DiscoveryPage.build]).
class _DiscoveryMapPage extends ConsumerStatefulWidget {
  const _DiscoveryMapPage();

  @override
  ConsumerState<_DiscoveryMapPage> createState() => _DiscoveryMapPageState();
}

class _DiscoveryMapPageState extends ConsumerState<_DiscoveryMapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();
  String? _selectedBusinessId;
  bool _recentering = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _recenter() async {
    if (_recentering) return;
    setState(() => _recentering = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await ref
          .read(discoverySearchProvider.notifier)
          .setUserLocation(lat: pos.latitude, lng: pos.longitude);
      _mapController.move(LatLng(pos.latitude, pos.longitude), 15);
    } catch (_) {
      // Konum alınamazsa sessizce yok say; harita varsayılan merkezde kalır.
    } finally {
      if (mounted) setState(() => _recentering = false);
    }
  }

  Future<void> _showPriceTierSheet(
    BuildContext context,
    DiscoverySearchState st,
  ) async {
    final t = AppLocalizations.of(context);
    final options = <(DiscoveryPriceTier, String)>[
      (DiscoveryPriceTier.any, t.priceTierAny),
      (DiscoveryPriceTier.budget, t.priceTierBudget),
      (DiscoveryPriceTier.medium, t.priceTierMedium),
      (DiscoveryPriceTier.premium, t.priceTierPremium),
    ];
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (tier, label) in options)
                ListTile(
                  title: Text(label),
                  trailing: st.priceTier == tier
                      ? const Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    ref
                        .read(discoverySearchProvider.notifier)
                        .setFilters(priceTier: tier);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    final st = ref.watch(discoverySearchProvider);

    final markerItems = st.items
        .where((b) => b.lat != null && b.lng != null)
        .toList();

    BusinessCardModel? selected;
    if (_selectedBusinessId != null) {
      for (final item in markerItems) {
        if (item.id == _selectedBusinessId) {
          selected = item;
          break;
        }
      }
    }
    selected ??= markerItems.isNotEmpty ? markerItems.first : null;

    final center = selected != null
        ? LatLng(selected.lat!, selected.lng!)
        : (st.userLat != null && st.userLng != null)
            ? LatLng(st.userLat!, st.userLng!)
            : _kDiscoveryMapDefaultCenter;

    final markers = <Marker>[
      for (final item in markerItems)
        Marker(
          point: LatLng(item.lat!, item.lng!),
          width: item.id == selected?.id ? 56 : 40,
          height: item.id == selected?.id ? 56 : 40,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => setState(() => _selectedBusinessId = item.id),
            child: _MapPin(highlighted: item.id == selected?.id),
          ),
        ),
    ];

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.space16,
              0,
              tokens.space16,
              tokens.space12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _DiscoveryTopBar(),
                _DiscoveryGreetingHeader(subtitle: t.mapGreetingSubtitle),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardAlt,
                    borderRadius: BorderRadius.circular(tokens.radius20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onChanged: (query) {
                      ref.read(discoverySearchProvider.notifier).setQuery(query);
                    },
                    onSubmitted: (query) {
                      ref
                          .read(discoverySearchProvider.notifier)
                          .setQuery(query, withDebounce: false);
                    },
                    decoration: InputDecoration(
                      hintText: t.mapSearchHint,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.muted,
                      ),
                      suffixIcon: IconButton(
                        tooltip: t.filters,
                        onPressed: () => _showPriceTierSheet(context, st),
                        icon: const Icon(Icons.tune_rounded),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                SizedBox(height: tokens.space12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _PremiumFilterChip(
                        label: t.mapFilterOpen,
                        icon: Icons.access_time_filled_rounded,
                        selected: st.openNow,
                        filledPrimary: true,
                        onTap: () {
                          ref
                              .read(discoverySearchProvider.notifier)
                              .setFilters(openNow: !st.openNow);
                        },
                      ),
                      SizedBox(width: tokens.space8),
                      _PremiumFilterChip(
                        label: t.nearbyShort,
                        icon: Icons.near_me_rounded,
                        selected: st.mode == DiscoveryMode.nearby,
                        filledPrimary: true,
                        onTap: () {
                          ref
                              .read(discoverySearchProvider.notifier)
                              .setMode(
                                st.mode == DiscoveryMode.nearby
                                    ? DiscoveryMode.text
                                    : DiscoveryMode.nearby,
                              );
                        },
                      ),
                      for (final cat in discoveryHomeCategories.where(
                        (c) => c.id == 'kebap' || c.id == 'tatli',
                      )) ...[
                        SizedBox(width: tokens.space8),
                        _PremiumFilterChip(
                          label: _homeCategoryTitle(context, cat.titleKey),
                          icon: Icons.restaurant_rounded,
                          selected: st.query == cat.searchTerm,
                          filledPrimary: false,
                          onTap: () {
                            final next = st.query == cat.searchTerm
                                ? ''
                                : cat.searchTerm;
                            _searchCtrl.text = next;
                            ref
                                .read(discoverySearchProvider.notifier)
                                .setQuery(next, withDebounce: false);
                          },
                        ),
                      ],
                      SizedBox(width: tokens.space8),
                      _PremiumFilterChip(
                        label: t.mapFilterPrice,
                        icon: Icons.payments_outlined,
                        selected: st.priceTier != DiscoveryPriceTier.any,
                        filledPrimary: false,
                        onTap: () => _showPriceTierSheet(context, st),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 14,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.yeedoy.app',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
              Positioned(
                left: tokens.space12,
                bottom: tokens.space12,
                child: ColoredBox(
                  color: AppColors.card.withValues(alpha: 0.85),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Text(
                      t.mapAttribution,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: tokens.space16,
                top: tokens.space16,
                child: Column(
                  children: [
                    _MapRoundButton(
                      icon: Icons.layers_outlined,
                      tooltip: t.mapLayersTooltip,
                      onTap: () {},
                    ),
                    SizedBox(height: tokens.space8),
                    _MapRoundButton(
                      icon: Icons.my_location_rounded,
                      tooltip: t.mapRecenterTooltip,
                      onTap: _recenter,
                      loading: _recentering,
                    ),
                  ],
                ),
              ),
              if (selected != null)
                Positioned(
                  left: tokens.space16,
                  right: tokens.space16,
                  bottom: tokens.space16,
                  child: BusinessTile(
                    name: selected.name,
                    category: selected.category,
                    subtitle:
                        '${selected.district ?? ''}  ${selected.city ?? ''}'
                            .trim(),
                    distanceKm: selected.distanceKm,
                    qualityScore: selected.qualityScore,
                    isOpenNow: selected.isOpenNow,
                    medianPriceCents: selected.medianPriceCents,
                    priceLevel: selected.priceLevel,
                    onTap: () => context.go('/b/${selected!.id}'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapRoundButton extends StatelessWidget {
  const _MapRoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        tooltip: tooltip,
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, color: AppColors.textStrong),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.highlighted});

  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? AppColors.primary : AppColors.danger;
    final size = highlighted ? 56.0 : 40.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          if (highlighted)
            Positioned(
              top: 4,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          Icon(
            Icons.location_on,
            color: color,
            size: highlighted ? 40 : 32,
          ),
          Positioned(
            top: highlighted ? 9 : 6,
            child: Icon(
              Icons.restaurant_rounded,
              color: AppColors.onPrimary,
              size: highlighted ? 16 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
