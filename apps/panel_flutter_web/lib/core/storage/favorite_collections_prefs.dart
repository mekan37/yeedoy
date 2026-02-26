import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class FavoriteCollection {
  const FavoriteCollection({
    required this.id,
    required this.name,
    required this.businessIds,
    required this.createdAtIso,
    this.isPublic = false,
    this.isSponsored = false,
    this.followersCount = 0,
    this.engagementCount = 0,
  });

  final String id;
  final String name;
  final List<String> businessIds;
  final String createdAtIso;
  final bool isPublic;
  final bool isSponsored;
  final int followersCount;
  final int engagementCount;

  FavoriteCollection copyWith({
    String? id,
    String? name,
    List<String>? businessIds,
    String? createdAtIso,
    bool? isPublic,
    bool? isSponsored,
    int? followersCount,
    int? engagementCount,
  }) {
    return FavoriteCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      businessIds: businessIds ?? this.businessIds,
      createdAtIso: createdAtIso ?? this.createdAtIso,
      isPublic: isPublic ?? this.isPublic,
      isSponsored: isSponsored ?? this.isSponsored,
      followersCount: followersCount ?? this.followersCount,
      engagementCount: engagementCount ?? this.engagementCount,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'business_ids': businessIds,
    'created_at': createdAtIso,
    'is_public': isPublic,
    'is_sponsored': isSponsored,
    'followers_count': followersCount,
    'engagement_count': engagementCount,
  };

  factory FavoriteCollection.fromMap(Map<String, dynamic> map) {
    final ids =
        (map['business_ids'] as List?)?.map((e) => '$e').toList() ??
        const <String>[];
    return FavoriteCollection(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      businessIds: ids,
      createdAtIso: (map['created_at'] ?? '').toString(),
      isPublic: map['is_public'] == true,
      isSponsored: map['is_sponsored'] == true,
      followersCount: (map['followers_count'] ?? 0) is int
          ? (map['followers_count'] as int)
          : int.tryParse('${map['followers_count'] ?? 0}') ?? 0,
      engagementCount: (map['engagement_count'] ?? 0) is int
          ? (map['engagement_count'] as int)
          : int.tryParse('${map['engagement_count'] ?? 0}') ?? 0,
    );
  }
}

class FavoriteCollectionsPrefs {
  FavoriteCollectionsPrefs._();

  static const _key = 'favorite_collections_v1';

  static Future<List<FavoriteCollection>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return const <FavoriteCollection>[];
    try {
      final list = (jsonDecode(raw) as List).whereType<Map>().toList();
      return list
          .map((e) => FavoriteCollection.fromMap(e.cast<String, dynamic>()))
          .where((e) => e.id.isNotEmpty && e.name.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return const <FavoriteCollection>[];
    }
  }

  static Future<void> save(List<FavoriteCollection> collections) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(collections.map((e) => e.toMap()).toList());
    await prefs.setString(_key, raw);
  }
}
