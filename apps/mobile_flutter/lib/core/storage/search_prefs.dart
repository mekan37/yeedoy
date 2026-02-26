import 'package:shared_preferences/shared_preferences.dart';

class SearchPrefs {
  const SearchPrefs._();

  static const _recentQueriesKey = 'discovery_recent_queries_v1';
  static const _maxItems = 8;

  static Future<List<String>> readRecentQueries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_recentQueriesKey) ?? const <String>[];
    final out = <String>[];
    for (final query in raw) {
      final value = query.trim();
      if (value.isEmpty) continue;
      if (out.contains(value)) continue;
      out.add(value);
      if (out.length >= _maxItems) break;
    }
    return out;
  }

  static Future<void> saveRecentQueries(List<String> queries) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = <String>[];
    for (final query in queries) {
      final value = query.trim();
      if (value.isEmpty) continue;
      if (normalized.contains(value)) continue;
      normalized.add(value);
      if (normalized.length >= _maxItems) break;
    }
    await prefs.setStringList(_recentQueriesKey, normalized);
  }

  static Future<List<String>> pushQuery(String query) async {
    final value = query.trim();
    if (value.isEmpty) return readRecentQueries();
    final current = await readRecentQueries();
    final next = <String>[value, ...current.where((e) => e != value)];
    await saveRecentQueries(next);
    return readRecentQueries();
  }

  static Future<List<String>> removeQuery(String query) async {
    final value = query.trim();
    final current = await readRecentQueries();
    final next = current.where((e) => e != value).toList();
    await saveRecentQueries(next);
    return next;
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentQueriesKey);
  }
}
