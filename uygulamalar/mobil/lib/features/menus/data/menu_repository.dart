import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/request_cache.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/monitoring/app_telemetry.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/storage/local_db/local_db_models.dart';
import '../../../core/storage/local_db/local_db_provider.dart';
import '../../../core/storage/local_db/local_db_store.dart';
import '../../../core/storage/offline_cache_prefs.dart';
import '../../../core/storage/offline_mutation_idempotency.dart';
import '../domain/menu_models.dart';
import 'menu_price_repository.dart';
import 'menu_rpc_utils.dart';

// B42 (mimari denetim): bu sınıf eskiden 1246 satır, 8 sorumluluk (menü
// ağacı okuma + foto + fiyat oylama/önerisi + çevrimdışı flush + fiş
// gönderimi + katalog arama) barındıran bir god-class'tı. Artık yalnızca
// menü ağacı okuma (menü/bölüm/ürün + offline snapshot cache) sorumlu;
// fotoğraf → MenuItemPhotoRepository, fiyat → MenuPriceRepository, yemek
// kataloğu araması → zaten var olan (ve fiilen kullanılan) ayrı
// FoodCatalogRepository'ye taşındı. Geriye kalan tek çapraz bağımlılık:
// _getMenuItemsV1 (eski API fallback yolu), ürünleri fiyat durumuyla
// zenginleştirmek için MenuPriceRepository.getMenuItemPriceStatusMap'i
// kullanıyor.
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return MenuRepository(
    client,
    ref.watch(appTelemetryProvider),
    ref.watch(requestCacheProvider),
    ref.watch(localDbStoreProvider),
    ref.watch(menuPriceRepositoryProvider),
  );
});

class MenuRepository {
  MenuRepository(
    this.client,
    this._telemetry,
    RequestCache requestCache,
    this._localDb,
    this._priceRepository,
  ) : _cache = requestCache.scope(_cacheScope);
  final SupabaseClient client;
  final AppTelemetry _telemetry;
  final RequestCacheScope _cache;
  final LocalDbStore _localDb;
  final MenuPriceRepository _priceRepository;

  static const String _cacheScope = 'menus';
  static const Duration _menuTtl = Duration(minutes: 5);
  static const Duration _offlineSnapshotTtl = Duration(days: 7);

  void clearReadCache() {
    _cache.invalidatePrefix('');
  }

  Future<List<BusinessMenu>> fetchBusinessMenus(String businessId) async {
    final key = 'business_menus|$businessId';
    final fresh = _cache.getFresh<List<BusinessMenu>>(key, ttl: _menuTtl);
    if (fresh != null) return fresh;
    try {
      final res = await _telemetry.traceRpc<dynamic>(
        operation: 'get_business_menus',
        run: () => client.rpc(
          'get_business_menus_v1',
          params: {'p_business_id': businessId},
        ),
        sampleRate: 0.2,
      );
      final rows = (res as List?) ?? const [];
      final menus = rows
          .whereType<Map>()
          .map((row) => BusinessMenu.fromMap(row.cast<String, dynamic>()))
          .toList();
      _cache.set(key, menus);
      await _writeMenuSnapshot(key, <String, dynamic>{
        'type': 'business_menus',
        'menus': menus.map((menu) => menu.toMap()).toList(),
      });
      await OfflineCachePrefs.saveBusinessMenus(businessId, menus);
      return menus;
    } catch (e) {
      final stale = _cache.getStale<List<BusinessMenu>>(key);
      if (stale != null) return stale;
      final local = await _readBusinessMenusSnapshot(key);
      if (local != null) return local;
      final cached = await OfflineCachePrefs.loadBusinessMenus(businessId);
      if (cached != null) return cached;
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<Map<String, dynamic>> fetchPublicMenuShare(String menuId) async {
    try {
      final res = await client.rpc(
        'public_menu_share_view_v1',
        params: {'p_menu_id': menuId},
      );
      if (res is Map) return res.cast<String, dynamic>();
      if (res is List && res.isNotEmpty && res.first is Map) {
        return (res.first as Map).cast<String, dynamic>();
      }
      return {'menu': null, 'sections': []};
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<Map<String, dynamic>?> fetchBusinessMini(String businessId) async {
    try {
      final res = await client
          .from('businesses')
          .select('id,name,logo_url')
          .eq('id', businessId)
          .maybeSingle();
      if (res == null) return null;
      return (res as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  Future<List<MenuSection>> fetchMenuSections(String menuId) async {
    final key = 'menu_sections|$menuId';
    final fresh = _cache.getFresh<List<MenuSection>>(key, ttl: _menuTtl);
    if (fresh != null) return fresh;
    try {
      final res = await _telemetry.traceRpc<dynamic>(
        operation: 'get_menu_sections',
        run: () =>
            client.rpc('get_menu_sections_v1', params: {'p_menu_id': menuId}),
        sampleRate: 0.2,
      );
      final rows = (res as List?) ?? const [];
      final sections = rows
          .whereType<Map>()
          .map((row) => MenuSection.fromMap(row.cast<String, dynamic>()))
          .toList();
      _cache.set(key, sections);
      await _writeMenuSnapshot(key, <String, dynamic>{
        'type': 'menu_sections',
        'sections': sections.map((section) => section.toMap()).toList(),
      });
      await OfflineCachePrefs.saveMenuSections(menuId, sections);
      return sections;
    } catch (e) {
      final stale = _cache.getStale<List<MenuSection>>(key);
      if (stale != null) return stale;
      final local = await _readMenuSectionsSnapshot(key);
      if (local != null) return local;
      final cached = await OfflineCachePrefs.loadMenuSections(menuId);
      if (cached != null) return cached;
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<MenuItem>> fetchMenuItems(
    String menuId, {
    List<MenuSection>? sections,
    bool allowV1Fallback = true,
  }) async {
    if (menuId.isEmpty) return const [];
    final key = 'menu_items|$menuId';
    final fresh = _cache.getFresh<List<MenuItem>>(key, ttl: _menuTtl);
    if (fresh != null) return fresh;
    try {
      final items = await _telemetry.traceRpc<List<MenuItem>>(
        operation: 'get_menu_items_by_sections_v1',
        run: () => _getMenuItemsV2(menuId, sections: sections),
        sampleRate: 0.2,
      );
      _cache.set(key, items);
      await _writeMenuSnapshot(key, <String, dynamic>{
        'type': 'menu_items',
        'items': items.map((item) => item.toMap()).toList(),
      });
      await OfflineCachePrefs.saveMenuItems(menuId, items);
      final hasSuspiciousDuplicates = _hasDuplicatedItemIds(items);
      final hasNoSectionBinding =
          (sections?.isNotEmpty ?? false) &&
          items.isNotEmpty &&
          items.every((item) => (item.sectionId ?? '').trim().isEmpty);
      if ((items.isNotEmpty &&
              !hasSuspiciousDuplicates &&
              !hasNoSectionBinding) ||
          !allowV1Fallback) {
        return items;
      }
    } catch (e) {
      if (!allowV1Fallback) {
        throw Exception(AppErrorMapper.message(e));
      }
    }

    try {
      final items = await _telemetry.traceRpc<List<MenuItem>>(
        operation: 'get_menu_items_v1_fallback',
        run: () => _getMenuItemsV1(menuId),
        sampleRate: 0.2,
      );
      _cache.set(key, items);
      await _writeMenuSnapshot(key, <String, dynamic>{
        'type': 'menu_items',
        'items': items.map((item) => item.toMap()).toList(),
      });
      await OfflineCachePrefs.saveMenuItems(menuId, items);
      return items;
    } catch (e) {
      final stale = _cache.getStale<List<MenuItem>>(key);
      if (stale != null) return stale;
      final local = await _readMenuItemsSnapshot(key);
      if (local != null) return local;
      final cached = await OfflineCachePrefs.loadMenuItems(menuId);
      if (cached != null) return cached;
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> submitSuggestion({
    required String businessId,
    required String? menuItemId,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final token = await createOfflineMutationIdempotencyToken(
        action: 'menu_item_suggestion_$action',
        payload: {
          'business_id': businessId,
          'menu_item_id': menuItemId,
          'action': action,
          'payload': payload,
        },
      );
      dynamic res;
      try {
        res = await client.rpc(
          'submit_menu_item_suggestion_v2',
          params: {
            'p_business_id': businessId,
            'p_menu_item_id': menuItemId,
            'p_action': action,
            'p_payload': payload,
            'p_idempotency_key': token.idempotencyKey,
          },
        );
      } catch (e) {
        if (!isMissingRpcError(e, 'submit_menu_item_suggestion_v2')) {
          rethrow;
        }
        res = await client.rpc(
          'submit_menu_item_suggestion_v1',
          params: {
            'p_business_id': businessId,
            'p_menu_item_id': menuItemId,
            'p_action': action,
            'p_payload': payload,
          },
        );
      }
      ensureOkResponse(res, fallbackError: 'menu_item_suggestion_failed');
      _cache.invalidatePrefix('menu_items|');
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<MenuItem>> _getMenuItemsV2(
    String menuId, {
    List<MenuSection>? sections,
    int limit = 200,
    int offset = 0,
  }) async {
    final resolvedSections = sections ?? await fetchMenuSections(menuId);
    final sectionIds = resolvedSections
        .map((section) => section.id)
        .where((id) => id.isNotEmpty)
        .toList();
    if (sectionIds.isEmpty) return const [];

    // Bölüm başına ayrı RPC (N+1) yerine tek batched çağrı (B17) — bölüm
    // başına limit/offset semantiği sunucu tarafında row_number() ile
    // korunuyor.
    final res = await client.rpc(
      'get_menu_items_by_sections_v1',
      params: {
        'p_section_ids': sectionIds,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    final rows = (res as List?) ?? const [];
    final items = rows
        .whereType<Map>()
        .map((row) => MenuItem.fromMap(row.cast<String, dynamic>()))
        .toList();
    if (items.isEmpty) return items;
    final byId = <String, MenuItem>{};
    for (final item in items) {
      final id = item.id.trim();
      if (id.isEmpty) continue;
      byId[id] = byId[id] ?? item;
    }
    return byId.values.toList(growable: false);
  }

  Future<List<MenuItem>> _getMenuItemsV1(String menuId) async {
    final res = await client.rpc(
      'get_menu_items_v1',
      params: {'p_menu_id': menuId},
    );
    final rows = (res as List?) ?? const [];
    final items = rows
        .whereType<Map>()
        .map((row) => MenuItem.fromMap(row.cast<String, dynamic>()))
        .toList();
    if (items.isEmpty) return items;

    final ids = items
        .map((item) => item.id)
        .where((id) => id.isNotEmpty)
        .toList();
    if (ids.isEmpty) return items;

    final statusMap = await _priceRepository.getMenuItemPriceStatusMap(ids);
    if (statusMap.isEmpty) return items;

    return items.map((item) {
      final status = statusMap[item.id];
      if (status == null) return item;
      return item.copyWith(
        priceStatus: status.priceStatus,
        total30d: status.total30d,
      );
    }).toList();
  }

  Future<void> _writeMenuSnapshot(String id, Map<String, dynamic> payload) {
    return _localDb.upsert(
      bucket: LocalDbBucket.menuSnapshot,
      id: id,
      payload: payload,
      expiresAt: DateTime.now().toUtc().add(_offlineSnapshotTtl),
    );
  }

  Future<List<BusinessMenu>?> _readBusinessMenusSnapshot(String id) async {
    final record = await _localDb.read(
      LocalDbBucket.menuSnapshot,
      id,
      allowExpired: true,
    );
    final menus = record?.payload['menus'];
    if (menus is! List) return null;
    return menus
        .whereType<Map>()
        .map((row) => BusinessMenu.fromMap(row.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<List<MenuSection>?> _readMenuSectionsSnapshot(String id) async {
    final record = await _localDb.read(
      LocalDbBucket.menuSnapshot,
      id,
      allowExpired: true,
    );
    final sections = record?.payload['sections'];
    if (sections is! List) return null;
    return sections
        .whereType<Map>()
        .map((row) => MenuSection.fromMap(row.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<List<MenuItem>?> _readMenuItemsSnapshot(String id) async {
    final record = await _localDb.read(
      LocalDbBucket.menuSnapshot,
      id,
      allowExpired: true,
    );
    final items = record?.payload['items'];
    if (items is! List) return null;
    return items
        .whereType<Map>()
        .map((row) => MenuItem.fromMap(row.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<MenuItemPriceBenchmark?> fetchCategoryPriceBenchmark({
    required String itemName,
    required String city,
    String? excludeBusinessId,
  }) async {
    if (itemName.trim().isEmpty || city.trim().isEmpty) return null;
    try {
      final res = await client.rpc(
        'get_category_price_benchmark_v1',
        params: {
          'p_item_name': itemName.trim(),
          'p_city': city.trim(),
          'p_exclude_business_id': excludeBusinessId,
        },
      );
      final rows = (res as List?) ?? const [];
      if (rows.isEmpty) return null;
      final row = rows.first;
      if (row is! Map) return null;
      final m = row.cast<String, dynamic>();
      final avg = (m['avg_price_cents'] as num?)?.toInt() ?? 0;
      if (avg <= 0) return null;
      return MenuItemPriceBenchmark(
        avgPriceCents: avg,
        minPriceCents: (m['min_price_cents'] as num?)?.toInt() ?? avg,
        maxPriceCents: (m['max_price_cents'] as num?)?.toInt() ?? avg,
        sampleCount: (m['sample_count'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}

bool _hasDuplicatedItemIds(List<MenuItem> items) {
  if (items.length < 2) return false;
  final ids = <String>{};
  for (final item in items) {
    final id = item.id.trim();
    if (id.isEmpty) continue;
    if (!ids.add(id)) return true;
  }
  return false;
}
