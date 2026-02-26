import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CreatorProfile {
  const CreatorProfile({
    required this.isCreator,
    this.displayName,
    this.bio,
    this.adDisclosureRequired = true,
  });

  final bool isCreator;
  final String? displayName;
  final String? bio;
  final bool adDisclosureRequired;

  CreatorProfile copyWith({
    bool? isCreator,
    String? displayName,
    String? bio,
    bool? adDisclosureRequired,
  }) {
    return CreatorProfile(
      isCreator: isCreator ?? this.isCreator,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      adDisclosureRequired: adDisclosureRequired ?? this.adDisclosureRequired,
    );
  }

  Map<String, dynamic> toMap() => {
    'is_creator': isCreator,
    'display_name': displayName,
    'bio': bio,
    'ad_disclosure_required': adDisclosureRequired,
  };

  factory CreatorProfile.fromMap(Map<String, dynamic> map) {
    return CreatorProfile(
      isCreator: map['is_creator'] == true,
      displayName: map['display_name']?.toString(),
      bio: map['bio']?.toString(),
      adDisclosureRequired: map['ad_disclosure_required'] == null
          ? true
          : map['ad_disclosure_required'] == true,
    );
  }
}

class CreatorProfilePrefs {
  CreatorProfilePrefs._();

  static const _key = 'creator_profile_v1';

  static Future<CreatorProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) {
      return const CreatorProfile(isCreator: false);
    }
    try {
      final map = jsonDecode(raw) as Map;
      return CreatorProfile.fromMap(map.cast<String, dynamic>());
    } catch (_) {
      return const CreatorProfile(isCreator: false);
    }
  }

  static Future<void> save(CreatorProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(profile.toMap());
    await prefs.setString(_key, raw);
  }
}
