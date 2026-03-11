enum AdminSearchCategory {
  business,
  user,
  report,
  submission,
  claim,
  menuItem;

  static AdminSearchCategory fromWire(String value) => switch (value) {
    'business' => AdminSearchCategory.business,
    'user' => AdminSearchCategory.user,
    'report' => AdminSearchCategory.report,
    'submission' => AdminSearchCategory.submission,
    'claim' => AdminSearchCategory.claim,
    'menu_item' => AdminSearchCategory.menuItem,
    _ => AdminSearchCategory.business,
  };
}

class AdminSearchResult {
  const AdminSearchResult({
    required this.category,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.searchToken,
    required this.createdAt,
    required this.meta,
    required this.score,
  });

  final AdminSearchCategory category;
  final String id;
  final String title;
  final String subtitle;
  final String searchToken;
  final DateTime? createdAt;
  final Map<String, dynamic> meta;
  final int score;

  factory AdminSearchResult.fromMap(Map<String, dynamic> map) {
    return AdminSearchResult(
      category: AdminSearchCategory.fromWire(
        (map['category'] ?? '').toString(),
      ),
      id: (map['item_id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      subtitle: (map['subtitle'] ?? '').toString(),
      searchToken: (map['search_token'] ?? '').toString(),
      createdAt: _parseDate(map['created_at']),
      meta: (map['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
      score: _parseInt(map['score']),
    );
  }

  String get routeQueryToken {
    final token = searchToken.trim();
    if (token.isNotEmpty) return token;
    return title.trim().isNotEmpty ? title.trim() : id;
  }
}

DateTime? _parseDate(Object? value) {
  if (value is DateTime) return value;
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

int _parseInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? 0;
}
