import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/arama/sorgu_normalizlayici.dart';
import '../domain/yemek_katalogu_modelleri.dart';

class LocalFoodCatalogDataSource {
  const LocalFoodCatalogDataSource();

  static Future<List<_LocalCatalogEntry>>? _cache;

  Future<List<FoodCatalogHit>> search(String query, {int limit = 12}) async {
    final q = _norm(query);
    if (q.length < 2) return const [];
    final entries = await _loadEntries();

    final scored = <({int score, _LocalCatalogEntry entry})>[];
    for (final entry in entries) {
      final hay = entry.searchText;
      final score = _score(hay, q);
      if (score <= 0) continue;
      scored.add((score: score, entry: entry));
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.entry.name.compareTo(b.entry.name);
    });

    return scored
        .take(limit)
        .map(
          (s) => FoodCatalogHit(
            id: s.entry.id,
            name: s.entry.name,
            categoryName: s.entry.categoryName,
            categoryId: s.entry.categoryId,
          ),
        )
        .toList(growable: false);
  }

  static int _score(String hay, String q) {
    if (hay == q) return 120;
    if (hay.startsWith(q)) return 95;
    if (hay.contains(' $q')) return 80;
    if (hay.contains(q)) return 65;
    return 0;
  }

  Future<List<_LocalCatalogEntry>> _loadEntries() {
    return _cache ??= _parseAsset();
  }

  Future<List<_LocalCatalogEntry>> _parseAsset() async {
    final raw = await rootBundle.loadString('assets/json/yemek.v4.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final categories = (map['categories'] as List?) ?? const [];

    final out = <_LocalCatalogEntry>[];
    var seq = 1;
    for (final category in categories) {
      if (category is! Map) continue;
      final categoryMap = category.cast<String, dynamic>();
      final categoryName = _fixText(categoryMap['name']?.toString() ?? '');
      final categoryId = (categoryMap['id'] ?? '').toString();
      final items = (categoryMap['items'] as List?) ?? const [];
      for (final item in items) {
        if (item is! Map) continue;
        final itemMap = item.cast<String, dynamic>();
        final name = _fixText(itemMap['name']?.toString() ?? '');
        if (name.isEmpty) continue;
        final aliases = ((itemMap['aliases'] as List?) ?? const [])
            .map((e) => _fixText(e?.toString() ?? ''))
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
        final slug = _fixText(itemMap['slug']?.toString() ?? '');
        final combined = [name, ...aliases, slug].join(' ');
        out.add(
          _LocalCatalogEntry(
            id: seq++,
            name: name,
            categoryName: categoryName,
            categoryId: categoryId,
            searchText: _norm(combined),
          ),
        );
      }
    }
    return out;
  }
}

class _LocalCatalogEntry {
  const _LocalCatalogEntry({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.categoryId,
    required this.searchText,
  });

  final int id;
  final String name;
  final String categoryName;
  final String categoryId;
  final String searchText;
}

String _norm(String input) {
  final fixed = _fixText(input);
  final normalized = normalizeSearchQuery(fixed);
  if (normalized.isNotEmpty) return normalized;
  return fixed.trim().toLowerCase();
}

String _fixText(String input) {
  var value = input.trim();
  if (value.isEmpty) return value;
  if (value.contains('Ã') || value.contains('Ä') || value.contains('Å')) {
    try {
      value = utf8.decode(latin1.encode(value), allowMalformed: true);
    } catch (_) {}
  }
  return value;
}

