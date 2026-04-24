import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class InboxPrefs {
  static const _readIdsKey = 'inbox_read_ids_v1';
  static const _cachedItemsKey = 'inbox_cached_items_v1';

  static Future<Set<String>> getReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_readIdsKey) ?? const <String>[];
    return values.where((e) => e.trim().isNotEmpty).toSet();
  }

  static Future<void> saveReadIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_readIdsKey, ids.toList()..sort());
  }

  static Future<List<Map<String, dynamic>>> getCachedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cachedItemsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> cacheItems(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedItemsKey, jsonEncode(items.take(50).toList()));
  }
}
