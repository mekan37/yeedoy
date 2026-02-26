import 'package:shared_preferences/shared_preferences.dart';

class FeedMutePrefs {
  static const _mutedBusinessIdsKey = 'feed_muted_business_ids_v1';
  static const _mutedBusinessesKey = 'feed_muted_businesses_v2';
  static const _mutedCategoriesKey = 'feed_muted_categories_v1';

  static Future<Set<String>> getMutedBusinessIds() async {
    final map = await getMutedBusinesses();
    if (map.isNotEmpty) return map.keys.toSet();
    final prefs = await SharedPreferences.getInstance();
    final legacy =
        prefs.getStringList(_mutedBusinessIdsKey) ?? const <String>[];
    return legacy.where((e) => e.trim().isNotEmpty).toSet();
  }

  static Future<void> saveMutedBusinessIds(Set<String> ids) async {
    await saveMutedBusinesses({for (final id in ids) id: id});
  }

  static Future<Map<String, String>> getMutedBusinesses() async {
    final prefs = await SharedPreferences.getInstance();
    final rows = prefs.getStringList(_mutedBusinessesKey) ?? const <String>[];
    final map = <String, String>{};
    for (final row in rows) {
      final idx = row.indexOf('||');
      if (idx <= 0) continue;
      final id = row.substring(0, idx).trim();
      final name = row.substring(idx + 2).trim();
      if (id.isEmpty) continue;
      map[id] = name.isEmpty ? id : name;
    }
    return map;
  }

  static Future<void> saveMutedBusinesses(Map<String, String> items) async {
    final prefs = await SharedPreferences.getInstance();
    final rows = items.entries.map((e) => '${e.key}||${e.value}').toList()
      ..sort();
    await prefs.setStringList(_mutedBusinessesKey, rows);
    await prefs.setStringList(
      _mutedBusinessIdsKey,
      items.keys.toList()..sort(),
    );
  }

  static Future<Set<String>> getMutedCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final rows = prefs.getStringList(_mutedCategoriesKey) ?? const <String>[];
    return rows.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
  }

  static Future<void> saveMutedCategories(Set<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final rows = categories.map((e) => e.trim()).where((e) => e.isNotEmpty);
    await prefs.setStringList(_mutedCategoriesKey, rows.toList()..sort());
  }
}
