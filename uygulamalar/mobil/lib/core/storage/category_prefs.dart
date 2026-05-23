import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CategoryPrefs {
  static const String _tapCountsKey = 'discovery_category_tap_counts_v1';

  static Future<Map<String, int>> readTapCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tapCountsKey);
    if (raw == null || raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      final out = <String, int>{};
      for (final entry in decoded.entries) {
        final key = entry.key.toString().trim();
        if (key.isEmpty) continue;
        final value = (entry.value as num?)?.toInt() ?? 0;
        out[key] = value;
      }
      return out;
    } catch (_) {
      return const {};
    }
  }

  static Future<void> bumpTapCount(String slug) async {
    final key = slug.trim();
    if (key.isEmpty) return;
    final counts = await readTapCounts();
    counts[key] = (counts[key] ?? 0) + 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tapCountsKey, jsonEncode(counts));
  }
}
