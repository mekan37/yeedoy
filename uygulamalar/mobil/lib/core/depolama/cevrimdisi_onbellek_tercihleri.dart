import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/isletme/domain/isletme.dart';
import '../../features/menuler/domain/menu_modelleri.dart';
import '../../features/isletme/domain/isletme_detay.dart';

class OfflineCachePrefs {
  static const _recentBusinessIdsKey = 'recent_business_ids_v1';
  static const _favoritesIdsKey = 'cached_favorite_ids_v1';
  static const _favoritesBusinessesKey = 'cached_favorite_businesses_v1';
  static const _categoriesSnapshotKey = 'cached_categories_snapshot_v1';
  static const _maxRecent = 20;
  static const _metaCachedAtField = 'cached_at';

  static String _businessKey(String id) => 'cached_business_$id';
  static String _businessDetailKey(String id, int limit) =>
      'cached_business_detail_${id}_$limit';
  static String _businessMenusKey(String businessId) =>
      'cached_business_menus_$businessId';
  static String _menuSectionsKey(String menuId) =>
      'cached_menu_sections_$menuId';
  static String _menuItemsKey(String menuId) => 'cached_menu_items_$menuId';
  static String _discoveryFeedKey(String cacheId) =>
      'cached_discovery_feed_$cacheId';
  static String _metaKey(String key) => '${key}_meta';

  static Future<void> saveRecentBusiness(Business business) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_recentBusinessIdsKey) ?? const <String>[];
    final next = <String>[business.id, ...ids.where((e) => e != business.id)];
    final trimmed = next.length > _maxRecent
        ? next.sublist(0, _maxRecent)
        : next;
    await prefs.setStringList(_recentBusinessIdsKey, trimmed);
    await _saveJson(_businessKey(business.id), business.toMap());
  }

  static Future<List<String>> getRecentBusinessIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentBusinessIdsKey) ?? const <String>[];
  }

  static Future<List<Business>> loadRecentBusinesses() async {
    final ids = await getRecentBusinessIds();
    if (ids.isEmpty) return const <Business>[];
    final prefs = await SharedPreferences.getInstance();
    final items = <Business>[];
    for (final id in ids) {
      final raw = prefs.getString(_businessKey(id));
      if (raw == null || raw.trim().isEmpty) continue;
      try {
        final map = (jsonDecode(raw) as Map).cast<String, dynamic>();
        items.add(Business.fromMap(map));
      } catch (_) {}
    }
    return items;
  }

  static Future<Business?> loadBusiness(String id) async {
    final map = await _loadJson(_businessKey(id));
    if (map is! Map) return null;
    try {
      return Business.fromMap(map.cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveBusinessDetail({
    required String businessId,
    required int latestLimit,
    required BusinessDetail detail,
  }) async {
    await _saveJson(
      _businessDetailKey(businessId, latestLimit),
      detail.toJson(),
    );
  }

  static Future<BusinessDetail?> loadBusinessDetail({
    required String businessId,
    required int latestLimit,
  }) async {
    final map = await _loadJson(_businessDetailKey(businessId, latestLimit));
    if (map == null) return null;
    try {
      return BusinessDetail.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveBusinessMenus(
    String businessId,
    List<BusinessMenu> menus,
  ) async {
    final payload = menus.map((e) => e.toMap()).toList();
    await _saveJson(_businessMenusKey(businessId), payload);
  }

  static Future<List<BusinessMenu>?> loadBusinessMenus(
    String businessId,
  ) async {
    final map = await _loadJson(_businessMenusKey(businessId));
    if (map is! List) return null;
    final items = map.whereType<Map>().map((e) {
      return BusinessMenu.fromMap(e.cast<String, dynamic>());
    }).toList();
    return items;
  }

  static Future<void> saveMenuSections(
    String menuId,
    List<MenuSection> sections,
  ) async {
    final payload = sections.map((e) => e.toMap()).toList();
    await _saveJson(_menuSectionsKey(menuId), payload);
  }

  static Future<List<MenuSection>?> loadMenuSections(String menuId) async {
    final map = await _loadJson(_menuSectionsKey(menuId));
    if (map is! List) return null;
    return map.whereType<Map>().map((e) {
      return MenuSection.fromMap(e.cast<String, dynamic>());
    }).toList();
  }

  static Future<void> saveMenuItems(String menuId, List<MenuItem> items) async {
    final payload = items.map((e) => e.toMap()).toList();
    await _saveJson(_menuItemsKey(menuId), payload);
  }

  static Future<List<MenuItem>?> loadMenuItems(String menuId) async {
    final map = await _loadJson(_menuItemsKey(menuId));
    if (map is! List) return null;
    return map.whereType<Map>().map((e) {
      return MenuItem.fromMap(e.cast<String, dynamic>());
    }).toList();
  }

  static Future<DateTime?> loadMenuItemsCachedAt(String menuId) async {
    return _loadCachedAt(_menuItemsKey(menuId));
  }

  static String _offlineSavedKey(String menuId) =>
      'offline_saved_menu_$menuId';

  static Future<void> markMenuSavedForOffline(String menuId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_offlineSavedKey(menuId), true);
  }

  static Future<bool> isMenuSavedForOffline(String menuId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_offlineSavedKey(menuId)) ?? false;
  }

  static Future<void> saveDiscoveryFeed(
    String cacheId,
    List<Map<String, dynamic>> rows,
  ) async {
    await _saveJson(_discoveryFeedKey(cacheId), rows);
  }

  static Future<List<Map<String, dynamic>>?> loadDiscoveryFeed(
    String cacheId,
  ) async {
    final map = await _loadJson(_discoveryFeedKey(cacheId));
    if (map is! List) return null;
    return map.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  static Future<void> saveFavoriteIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesIdsKey, ids);
  }

  static Future<List<String>> loadFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesIdsKey) ?? const <String>[];
  }

  static Future<void> saveFavoriteBusinesses(
    List<Map<String, dynamic>> rows,
  ) async {
    await _saveJson(_favoritesBusinessesKey, rows);
  }

  static Future<List<Map<String, dynamic>>?> loadFavoriteBusinesses() async {
    final map = await _loadJson(_favoritesBusinessesKey);
    if (map is! List) return null;
    return map.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  static Future<DateTime?> loadFavoriteBusinessesCachedAt() async {
    return _loadCachedAt(_favoritesBusinessesKey);
  }

  static Future<void> saveCategoriesSnapshot(List<String> categories) async {
    final normalized = categories
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    await _saveJson(_categoriesSnapshotKey, normalized);
  }

  static Future<List<String>> loadCategoriesSnapshot() async {
    final map = await _loadJson(_categoriesSnapshotKey);
    if (map is! List) return const <String>[];
    return map
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static Future<void> _saveJson(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(value);
    final savedAt = DateTime.now().toUtc().toIso8601String();
    await Future.wait([
      prefs.setString(key, raw),
      prefs.setString(_metaKey(key), jsonEncode({_metaCachedAtField: savedAt})),
    ]);
  }

  static Future<dynamic> _loadJson(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<DateTime?> _loadCachedAt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_metaKey(key));
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final map = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final value = map[_metaCachedAtField]?.toString() ?? '';
      if (value.trim().isEmpty) return null;
      return DateTime.tryParse(value)?.toLocal();
    } catch (_) {
      return null;
    }
  }
}



