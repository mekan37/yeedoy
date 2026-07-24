import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/colors.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/storage/offline_cache_prefs.dart';
import '../../../core/storage/favorite_collections_prefs.dart';
import '../data/favorites_repository.dart';
import '../data/collection_social_repository.dart';
import '../data/collection_share_repository.dart';
import '../../../features/shared/ui/design_system.dart';
import '../../../features/shared/ui/components/quick_login_sheet.dart';
import '../../auth/domain/auth_providers.dart';
import '../../discovery/domain/business_card.dart';
import '../../favorites/domain/favorites_controller.dart';
import '../../favorites/domain/favorite_status_provider.dart';
import '../../profile/domain/creator_profile_provider.dart';
import '../../shared/ui/category_chip.dart';
import '../../../features/shared/ui/components/vertical_business_card.dart';
import '../../../core/utils/greeting_utils.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({
    super.key,
    this.sharedBusinessIds = const <String>[],
    this.sharedCollectionName,
    this.sharedCollectionSlug,
    this.nearbyMode = false,
  });

  final List<String> sharedBusinessIds;
  final String? sharedCollectionName;
  final String? sharedCollectionSlug;
  final bool nearbyMode;

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  final qCtrl = TextEditingController();
  final scrollCtrl = ScrollController();
  Timer? _searchDebounce;
  String _query = '';
  String category = '';
  bool _collectionsLoading = true;
  List<FavoriteCollection> _collections = const <FavoriteCollection>[];
  String _selectedCollectionId = '';
  bool _socialLoading = true;
  bool _sharedEngagementBumped = false;
  Map<String, CollectionSocialState> _social = {};
  bool _sharedLoading = false;
  List<BusinessCardModel> _sharedItems = const <BusinessCardModel>[];
  List<String> _sharedIds = const <String>[];
  String? _sharedName;
  bool _locLoading = false;
  Position? _pos;
  DateTime? _favoritesCachedAt;
  bool _openOnly = false;
  bool _nearbySort = false;
  bool _showCollectionsPanel = false;

  final categories = const [
    'Kafe',
    'Restoran',
    'Tatlıcı',
    'Kahvaltı',
    'Balık / Et',
    'Mekan',
  ];

  bool get _isSharedMode =>
      widget.sharedBusinessIds.isNotEmpty ||
      (widget.sharedCollectionSlug?.isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels >=
          scrollCtrl.position.maxScrollExtent - 300) {
        ref.read(favoritesControllerProvider.notifier).loadMore();
      }
    });
    _loadCollections();
    _loadSocial();
    _loadFavoritesCacheMeta();
    if (_isSharedMode) {
      _sharedIds = widget.sharedBusinessIds;
      _sharedName = widget.sharedCollectionName;
      _loadSharedItems();
    }
    if (widget.nearbyMode) {
      _loadLocation();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    qCtrl.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final st = ref.watch(favoritesControllerProvider);
    final favIds = ref.watch(favoriteIdsProvider);
    final q = _query;
    final creatorAsync = ref.watch(creatorProfileProvider);
    final isCreator = creatorAsync.asData?.value.isCreator ?? false;

    var items = _isSharedMode ? _sharedItems : st.items;
    if (_selectedCollectionId.isNotEmpty && !_isSharedMode) {
      FavoriteCollection? col;
      for (final item in _collections) {
        if (item.id == _selectedCollectionId) {
          col = item;
          break;
        }
      }
      final ids = (col?.businessIds ?? const <String>[]).toSet();
      items = items.where((e) => ids.contains(e.id)).toList();
    }

    var filtered = items.where((b) {
      final okCat = category.isEmpty || b.category == category;
      final okOpen = !_openOnly || b.isOpenNow == true;
      final okQ =
          q.isEmpty ||
          b.name.toLowerCase().contains(q) ||
          (b.address ?? '').toLowerCase().contains(q) ||
          (b.district ?? '').toLowerCase().contains(q);
      return okCat && okOpen && okQ;
    }).toList();

    if ((widget.nearbyMode || _nearbySort) && _pos != null) {
      filtered.sort((a, b) {
        final da = _distanceKm(a, _pos!);
        final db = _distanceKm(b, _pos!);
        return da.compareTo(db);
      });
    }

    final tokens = AppTokens.of(context);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await ref.read(favoritesControllerProvider.notifier).refresh();
          await _loadCollections();
          await _loadSocial();
          await _loadFavoritesCacheMeta();
          if (_isSharedMode) await _loadSharedItems();
          if (widget.nearbyMode || _nearbySort) await _loadLocation();
        },
        child: CustomScrollView(
          controller: scrollCtrl,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverList.list(
                children: [
            const _FavoritesHeader(),
            if (!_isSharedMode && st.items.isNotEmpty) ...[
              _FavoritesCountBanner(count: st.items.length),
              SizedBox(height: tokens.space12),
            ],
            if (_showStaleBadge(_favoritesCachedAt)) ...[
              _OfflineStaleBadge(updatedAt: _favoritesCachedAt!),
              SizedBox(height: tokens.space12),
            ],
            if (_isSharedMode) ...[
              _sharedCollectionPanel(),
              SizedBox(height: tokens.space12),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qCtrl,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: t.favoritesSearchHint,
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                if (!_isSharedMode) ...[
                  SizedBox(width: tokens.space8),
                  Material(
                    color: _showCollectionsPanel
                        ? AppColors.primarySoft
                        : AppColors.cardAlt,
                    borderRadius: BorderRadius.circular(tokens.radius12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(tokens.radius12),
                      onTap: () => setState(
                        () => _showCollectionsPanel = !_showCollectionsPanel,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Icon(
                          Icons.tune,
                          color: _showCollectionsPanel
                              ? AppColors.primary
                              : AppColors.textStrong,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: tokens.space8),
            if (widget.nearbyMode) _nearbyBanner(),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  CategoryChip(
                    label: t.all,
                    selected: category.isEmpty && !_openOnly && !_nearbySort,
                    onTap: () => setState(() {
                      category = '';
                      _openOnly = false;
                      _nearbySort = false;
                    }),
                  ),
                  const SizedBox(width: 8),
                  CategoryChip(
                    label: '🟢 ${t.mapFilterOpen}',
                    selected: _openOnly,
                    onTap: () => setState(() => _openOnly = !_openOnly),
                  ),
                  const SizedBox(width: 8),
                  CategoryChip(
                    label: t.nearbyShort,
                    selected: _nearbySort,
                    leading: Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: _nearbySort ? AppColors.primary : AppColors.muted,
                    ),
                    onTap: () {
                      final next = !_nearbySort;
                      setState(() => _nearbySort = next);
                      if (next && _pos == null) _loadLocation();
                    },
                  ),
                  const SizedBox(width: 8),
                  for (final c in categories) ...[
                    CategoryChip(
                      label: _localizedCategoryLabel(context, c),
                      selected: category == c,
                      leading: Icon(
                        _categoryIcon(c),
                        size: 14,
                        color: category == c ? AppColors.primary : AppColors.muted,
                      ),
                      onTap: () => setState(() => category = c),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            if (!_isSharedMode && _showCollectionsPanel) ...[
              SizedBox(height: tokens.space12),
              _collectionsSection(isCreator: isCreator),
              if (isCreator) _creatorCollectionPanel(),
            ],
            SizedBox(height: tokens.space12),
            if (!_isSharedMode && st.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  AppErrorMapper.message(st.error),
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            ],
              ),
            ),
            if ((_isSharedMode && _sharedLoading) ||
                (!_isSharedMode && st.isLoading && st.items.isEmpty))
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.list(
                  children: const [_FavoritesSkeleton()],
                ),
              )
            else if (filtered.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.list(
                  children: const [
                    Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: _EmptyFavs(),
                    ),
                  ],
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final b = filtered[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: tokens.space12),
                      child: VerticalBusinessCard(
                        key: ValueKey('fav_${b.id}'),
                        item: _pos == null
                            ? b
                            : b.copyWith(distanceKm: _distanceKm(b, _pos!)),
                        imageAsset: categoryImageAsset(b.category),
                        ratingLabel: businessRatingLabel(b),
                        isFavorite: favIds.contains(b.id),
                        onTap: () => context.go('/b/${b.id}'),
                        onFavoriteTap: () async {
                          try {
                            await ref
                                .read(favoritesControllerProvider.notifier)
                                .toggleFavorite(b.id);
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppErrorMapper.message(e)),
                              ),
                            );
                          }
                        },
                        topRightExtra: _isSharedMode
                            ? null
                            : Material(
                                color: Colors.white.withValues(alpha: 0.92),
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => _openCollectionPicker(b),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.folder_copy_outlined,
                                      color: AppColors.muted,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList.list(
                children: [
                  if (!_isSharedMode && st.isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String c) {
    return switch (c) {
      'Kafe' => Icons.local_cafe_rounded,
      'Restoran' => Icons.restaurant_rounded,
      'Tatlıcı' => Icons.cake_rounded,
      'Kahvaltı' => Icons.free_breakfast_rounded,
      'Balık / Et' => Icons.set_meal_rounded,
      'Mekan' => Icons.location_on_rounded,
      _ => Icons.restaurant_rounded,
    };
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() => _query = value.trim().toLowerCase());
    });
  }

  String _localizedCategoryLabel(BuildContext context, String raw) {
    final t = AppLocalizations.of(context);
    return switch (raw.toLowerCase()) {
      'kafe' || 'cafe' => t.discoveryFilterCafe,
      'restoran' || 'restaurant' => t.discoveryFilterRestaurant,
      'tatlıcı' || 'tatli' || 'dessert' => t.discoveryFilterDessertPastry,
      'kahvaltı' || 'kahvalti' || 'breakfast' => t.discoveryFilterBreakfast,
      'balık / et' ||
      'balik / et' ||
      'fish / meat' => t.discoveryFilterFishMeat,
      'mekan' || 'venue' => t.discoveryFilterVenue,
      _ => raw,
    };
  }

  Widget _nearbyBanner() {
    final t = AppLocalizations.of(context);
    final text = _locLoading
        ? t.favoritesNearbyLoadingLocation
        : (_pos == null
              ? t.favoritesNearbyFallbackOrdering
              : t.favoritesNearbySortedByDistance);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          children: [
            const Icon(Icons.near_me_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: const TextStyle(color: AppColors.muted)),
            ),
            if (_pos == null)
              TextButton(onPressed: _loadLocation, child: Text(t.retry)),
          ],
        ),
      ),
    );
  }

  Widget _collectionsSection({required bool isCreator}) {
    final t = AppLocalizations.of(context);
    if (_collectionsLoading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.favoritesCollectionsTitle,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
              IconButton(
                tooltip: t.favoritesCreateCollectionTooltip,
                onPressed: _createCollection,
                icon: const Icon(Icons.create_new_folder_outlined),
              ),
              if (_selectedCollectionId.isNotEmpty) ...[
                IconButton(
                  tooltip: t.favoritesShareCollectionTooltip,
                  onPressed: _shareSelectedCollection,
                  icon: const Icon(Icons.share_outlined),
                ),
                IconButton(
                  tooltip: t.favoritesDeleteCollectionTooltip,
                  onPressed: _deleteSelectedCollection,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                CategoryChip(
                  label: t.all,
                  selected: _selectedCollectionId.isEmpty,
                  onTap: () => setState(() => _selectedCollectionId = ''),
                ),
                const SizedBox(width: 8),
                for (final col in _collections) ...[
                  CategoryChip(
                    label: '${col.name} (${col.businessIds.length})',
                    selected: _selectedCollectionId == col.id,
                    onTap: () {
                      setState(() => _selectedCollectionId = col.id);
                      _loadSocial();
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          if (isCreator && _selectedCollectionId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _CreatorBadgesRow(
                isSponsored:
                    _selectedCollection()?.isSponsored == true &&
                    _selectedCollection()?.isPublic == true,
                isPublic: _selectedCollection()?.isPublic == true,
                followers: _collectionFollowers(_selectedCollection()),
                engagement: _collectionEngagement(_selectedCollection()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _creatorCollectionPanel() {
    final t = AppLocalizations.of(context);
    final col = _selectedCollection();
    if (col == null) {
      return AppCard(
        child: Row(
          children: [
            const Icon(Icons.auto_awesome_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.favoritesCreatorSelectCollectionHint,
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          ],
        ),
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.favoritesCreatorCollectionTitle,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            t.favoritesCreatorCollectionSubtitle,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: col.isPublic,
            title: Text(t.favoritesPublishAction),
            subtitle: Text(
              col.isPublic
                  ? t.favoritesPublishVisibleSubtitle
                  : t.favoritesPublishPrivateSubtitle,
            ),
            onChanged: (value) => _togglePublishCollection(col, value),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCollections() async {
    setState(() => _collectionsLoading = true);
    final loaded = await FavoriteCollectionsPrefs.load();
    if (!mounted) return;
    setState(() {
      _collectionsLoading = false;
      _collections = loaded;
      if (_selectedCollectionId.isNotEmpty &&
          !_collections.any((e) => e.id == _selectedCollectionId)) {
        _selectedCollectionId = '';
      }
    });
  }

  Future<void> _loadSocial() async {
    setState(() => _socialLoading = true);
    final keys = <String>{};
    if (_isSharedMode) {
      keys.add(_sharedCollectionKey());
    }
    if (_selectedCollectionId.isNotEmpty) {
      final col = _selectedCollection();
      if (col != null) keys.add(_collectionKey(col));
    }
    final loaded = await ref
        .read(collectionSocialRepositoryProvider)
        .getStats(keys.toList());
    if (!mounted) return;
    setState(() {
      _socialLoading = false;
      _social = loaded;
    });
  }

  Future<void> _loadFavoritesCacheMeta() async {
    final value = await OfflineCachePrefs.loadFavoriteBusinessesCachedAt();
    if (!mounted) return;
    setState(() => _favoritesCachedAt = value);
  }

  Future<void> _loadSharedItems() async {
    setState(() => _sharedLoading = true);
    try {
      var ids = _sharedIds;
      var name = _sharedName;
      final slug = widget.sharedCollectionSlug ?? '';
      if (slug.isNotEmpty && ids.isEmpty) {
        final share = await ref
            .read(collectionShareRepositoryProvider)
            .fetchBySlug(slug);
        ids = share?.businessIds ?? const <String>[];
        name = share?.name ?? name;
        _sharedIds = ids;
        _sharedName = name;
      }
      final items = await ref
          .read(favoritesRepositoryProvider)
          .fetchBusinessesByIds(ids);
      if (!mounted) return;
      setState(() => _sharedItems = items);
      if (!_sharedEngagementBumped) {
        await _bumpSharedEngagement();
      }
    } finally {
      if (mounted) setState(() => _sharedLoading = false);
    }
  }

  Future<void> _loadLocation() async {
    setState(() => _locLoading = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _pos = pos);
    } catch (_) {
      // no-op
    } finally {
      if (mounted) setState(() => _locLoading = false);
    }
  }

  Widget _sharedCollectionPanel() {
    final t = AppLocalizations.of(context);
    final key = _sharedCollectionKey();
    final social = _social[key];
    final followers = social?.followers ?? 0;
    final engagement = social?.engagement ?? 0;
    final isFollowing = social?.isFollowing ?? false;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _sharedName ??
                widget.sharedCollectionName ??
                t.favoritesSharedCollectionTitle,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            t.favoritesFollowCollectionHint,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _socialLoading
                    ? null
                    : () => _toggleFollow(key, isFollowing),
                icon: Icon(
                  isFollowing ? Icons.check_circle_outline : Icons.add_circle,
                ),
                label: Text(
                  isFollowing
                      ? t.favoritesFollowingAction
                      : t.favoritesFollowAction,
                ),
              ),
              const Spacer(),
              _InfoChip(
                text: t.favoritesFollowersChip(followers),
                color: AppColors.header,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                text: t.favoritesEngagementChip(engagement),
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _createCollection() async {
    final t = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.favoritesNewCollectionTitle),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: t.favoritesCollectionNameExample,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.vazgec),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.favoritesCreateAction),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final name = ctrl.text.trim();
    if (name.isEmpty) return;
    final now = DateTime.now();
    final collection = FavoriteCollection(
      id: '${now.microsecondsSinceEpoch}',
      name: name,
      businessIds: const <String>[],
      createdAtIso: now.toIso8601String(),
      isPublic: false,
      isSponsored: false,
      followersCount: 0,
      engagementCount: 0,
    );
    final next = [..._collections, collection];
    await FavoriteCollectionsPrefs.save(next);
    if (!mounted) return;
    setState(() {
      _collections = next;
      _selectedCollectionId = collection.id;
    });
  }

  Future<void> _deleteSelectedCollection() async {
    final t = AppLocalizations.of(context);
    if (_selectedCollectionId.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.favoritesDeleteCollectionConfirmTitle),
        content: Text(t.favoritesDeleteCollectionConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.vazgec),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.sil),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final next = _collections
        .where((e) => e.id != _selectedCollectionId)
        .toList();
    await FavoriteCollectionsPrefs.save(next);
    if (!mounted) return;
    setState(() {
      _collections = next;
      _selectedCollectionId = '';
    });
  }

  Future<void> _openCollectionPicker(BusinessCardModel business) async {
    final t = AppLocalizations.of(context);
    final selected = _collections.map((e) => e.id).where((id) {
      final col = _collections.firstWhere((c) => c.id == id);
      return col.businessIds.contains(business.id);
    }).toSet();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.favoritesBusinessCollectionsTitle(business.name),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  if (_collections.isEmpty)
                    Text(
                      t.favoritesNoCollectionYet,
                      style: TextStyle(color: AppColors.muted),
                    )
                  else
                    ..._collections.map((col) {
                      return CheckboxListTile(
                        dense: true,
                        value: selected.contains(col.id),
                        title: Text(col.name),
                        onChanged: (v) {
                          setModalState(() {
                            if (v == true) {
                              selected.add(col.id);
                            } else {
                              selected.remove(col.id);
                            }
                          });
                        },
                      );
                    }),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _createCollection();
                          if (mounted) _openCollectionPicker(business);
                        },
                        child: Text(t.favoritesNewCollectionAction),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () async {
                          final next = _collections.map((col) {
                            final ids = col.businessIds.toSet();
                            if (selected.contains(col.id)) {
                              ids.add(business.id);
                            } else {
                              ids.remove(business.id);
                            }
                            return col.copyWith(businessIds: ids.toList());
                          }).toList();
                          await FavoriteCollectionsPrefs.save(next);
                          if (!mounted) return;
                          setState(() => _collections = next);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                        },
                        child: Text(t.save),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _shareSelectedCollection() async {
    final t = AppLocalizations.of(context);
    FavoriteCollection? col;
    for (final item in _collections) {
      if (item.id == _selectedCollectionId) {
        col = item;
        break;
      }
    }
    if (col == null || col.businessIds.isEmpty) return;
    final origin = Uri.base.origin.startsWith('http')
        ? Uri.base.origin
        : AppConfig.webBaseUrl;
    Uri uri;
    final user = ref.read(userProvider);
    if (user == null) {
      uri = Uri.parse('$origin/favorites').replace(
        queryParameters: {
          'ids': col.businessIds.join(','),
          'cname': col.name,
          'nearby': '1',
        },
      );
    } else {
      final slug = await ref
          .read(collectionShareRepositoryProvider)
          .upsertShare(
            collectionKey: _collectionKey(col),
            name: col.name,
            businessIds: col.businessIds,
          );
      if (slug.isEmpty) {
        uri = Uri.parse('$origin/favorites').replace(
          queryParameters: {
            'ids': col.businessIds.join(','),
            'cname': col.name,
            'nearby': '1',
          },
        );
      } else {
        uri = Uri.parse('$origin/c/$slug');
      }
    }
    final disclosure = col.isPublic
        ? (col.isSponsored
              ? t.favoritesDisclosureSponsored
              : t.favoritesDisclosureOrganic)
        : t.favoritesDisclosurePrivate;
    await _bumpEngagement(_collectionKey(col), delta: 1);
    await SharePlus.instance.share(
      ShareParams(
        text: t.favoritesShareText(col.name, uri.toString(), disclosure),
      ),
    );
  }

  String _collectionKey(FavoriteCollection col) => 'own:${col.id}';

  String _sharedCollectionKey() {
    final slug = widget.sharedCollectionSlug ?? '';
    if (slug.isNotEmpty) return 'shared:slug:$slug';
    final ids = _sharedIds.join(',');
    final name = _sharedName ?? widget.sharedCollectionName ?? 'collection';
    return 'shared:$name:$ids';
  }

  Future<void> _toggleFollow(String key, bool current) async {
    final user = ref.read(userProvider);
    if (user == null) {
      await showQuickLoginSheet(context);
      return;
    }
    final next = await ref
        .read(collectionSocialRepositoryProvider)
        .toggleFollow(key);
    if (!mounted) return;
    setState(() {
      _social = {
        ..._social,
        key: CollectionSocialState(
          followers: next.followers,
          engagement: _social[key]?.engagement ?? 0,
          isFollowing: next.isFollowing,
        ),
      };
    });
  }

  Future<void> _bumpSharedEngagement() async {
    final key = _sharedCollectionKey();
    _sharedEngagementBumped = true;
    await _bumpEngagement(key, delta: 1);
  }

  Future<void> _bumpEngagement(String key, {int delta = 1}) async {
    final engagement = await ref
        .read(collectionSocialRepositoryProvider)
        .bumpEngagement(key, delta: delta);
    if (!mounted) return;
    setState(() {
      final prev = _social[key];
      _social = {
        ..._social,
        key: CollectionSocialState(
          followers: prev?.followers ?? 0,
          engagement: engagement,
          isFollowing: prev?.isFollowing ?? false,
        ),
      };
    });
  }

  FavoriteCollection? _selectedCollection() {
    if (_selectedCollectionId.isEmpty) return null;
    for (final item in _collections) {
      if (item.id == _selectedCollectionId) return item;
    }
    return null;
  }

  int _collectionFollowers(FavoriteCollection? col) {
    if (col == null) return 0;
    final social = _social[_collectionKey(col)];
    if (social != null && social.followers > 0) return social.followers;
    if (col.followersCount > 0) return col.followersCount;
    final base = col.businessIds.length * 4;
    return base < 8 ? 8 : base;
  }

  int _collectionEngagement(FavoriteCollection? col) {
    if (col == null) return 0;
    final social = _social[_collectionKey(col)];
    if (social != null && social.engagement > 0) return social.engagement;
    if (col.engagementCount > 0) return col.engagementCount;
    final base = col.businessIds.length * 2;
    return base < 5 ? 5 : base;
  }

  Future<void> _togglePublishCollection(
    FavoriteCollection col,
    bool value,
  ) async {
    if (!value) {
      final next = _collections.map((e) {
        return e.id == col.id ? e.copyWith(isPublic: false) : e;
      }).toList();
      await FavoriteCollectionsPrefs.save(next);
      if (!mounted) return;
      setState(() => _collections = next);
      return;
    }
    final isSponsored = await _askAdDisclosure();
    if (isSponsored == null) return;
    final next = _collections.map((e) {
      if (e.id != col.id) return e;
      return e.copyWith(
        isPublic: true,
        isSponsored: isSponsored,
        followersCount: e.followersCount > 0
            ? e.followersCount
            : _collectionFollowers(e),
        engagementCount: e.engagementCount > 0
            ? e.engagementCount
            : _collectionEngagement(e),
      );
    }).toList();
    await FavoriteCollectionsPrefs.save(next);
    if (!mounted) return;
    setState(() => _collections = next);
  }

  Future<bool?> _askAdDisclosure() {
    final t = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(t.favoritesAdDisclosureTitle),
          content: Text(t.favoritesAdDisclosureBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.favoritesDisclosureOrganic),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t.favoritesDisclosureSponsored),
            ),
          ],
        );
      },
    );
  }

  double _distanceKm(BusinessCardModel item, Position pos) {
    if (item.lat == null || item.lng == null) return 9999;
    final meters = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      item.lat!,
      item.lng!,
    );
    return meters / 1000.0;
  }
}

bool _showStaleBadge(DateTime? value) {
  if (value == null) return false;
  return DateTime.now().difference(value).inDays >= 2;
}

class _OfflineStaleBadge extends StatelessWidget {
  const _OfflineStaleBadge({required this.updatedAt});

  final DateTime updatedAt;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final days = DateTime.now().difference(updatedAt).inDays;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t.favoritesCacheStaleMessage(days),
              style: const TextStyle(color: AppColors.textStrong, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatorBadgesRow extends StatelessWidget {
  const _CreatorBadgesRow({
    required this.isPublic,
    required this.isSponsored,
    required this.followers,
    required this.engagement,
  });

  final bool isPublic;
  final bool isSponsored;
  final int followers;
  final int engagement;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (!isPublic) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _InfoChip(
          text: isSponsored
              ? t.favoritesDisclosureSponsored
              : t.favoritesDisclosureOrganic,
          color: isSponsored ? AppColors.warning : AppColors.primary,
        ),
        _InfoChip(
          text: t.favoritesFollowersChip(followers),
          color: AppColors.header,
        ),
        _InfoChip(
          text: t.favoritesEngagementChip(engagement),
          color: AppColors.success,
        ),
      ],
    );
  }
}

class _FavoritesHeader extends StatelessWidget {
  const _FavoritesHeader();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timeBasedGreeting(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t.favorites,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesCountBanner extends StatelessWidget {
  const _FavoritesCountBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space16,
        vertical: tokens.space12,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(tokens.radius16),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite, color: AppColors.primary, size: 20),
          SizedBox(width: tokens.space8),
          Expanded(
            child: Text(
              t.favoritesCountBanner(count),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppChip(label: text, color: color, filled: true);
  }
}

class _FavoritesSkeleton extends StatelessWidget {
  const _FavoritesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(6, (i) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: AppSkeletonCard(lines: 2),
        );
      }),
    );
  }
}

class _EmptyFavs extends StatelessWidget {
  const _EmptyFavs();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppEmptyState(
      icon: Icons.star_border,
      title: t.emptyTitle,
      description: t.emptyRegionDescription,
    );
  }
}
