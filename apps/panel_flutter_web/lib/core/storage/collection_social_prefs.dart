import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CollectionSocialState {
  const CollectionSocialState({
    required this.followers,
    required this.engagement,
    required this.isFollowing,
  });

  final int followers;
  final int engagement;
  final bool isFollowing;

  CollectionSocialState copyWith({
    int? followers,
    int? engagement,
    bool? isFollowing,
  }) {
    return CollectionSocialState(
      followers: followers ?? this.followers,
      engagement: engagement ?? this.engagement,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  Map<String, dynamic> toMap() => {
    'followers': followers,
    'engagement': engagement,
    'is_following': isFollowing,
  };

  factory CollectionSocialState.fromMap(Map<String, dynamic> map) {
    return CollectionSocialState(
      followers: (map['followers'] as num?)?.toInt() ?? 0,
      engagement: (map['engagement'] as num?)?.toInt() ?? 0,
      isFollowing: map['is_following'] == true,
    );
  }
}

class CollectionSocialPrefs {
  CollectionSocialPrefs._();

  static const _key = 'collection_social_v1';

  static Future<Map<String, CollectionSocialState>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map;
      final result = <String, CollectionSocialState>{};
      decoded.forEach((key, value) {
        if (value is Map) {
          result['$key'] = CollectionSocialState.fromMap(
            value.cast<String, dynamic>(),
          );
        }
      });
      return result;
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveAll(Map<String, CollectionSocialState> data) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(
      data.map((key, value) => MapEntry(key, value.toMap())),
    );
    await prefs.setString(_key, raw);
  }
}
