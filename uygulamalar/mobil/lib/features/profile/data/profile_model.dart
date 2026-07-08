import '../../../core/privacy/name_masking.dart';

class Profile {
  const Profile({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.displayName,
    this.privacyMode = NamePrivacyMode.full,
    this.languageCode,
    this.socialLinks = const {},
    this.birthDate,
    this.gender,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? displayName;
  final NamePrivacyMode privacyMode;
  final String? languageCode;
  final Map<String, String> socialLinks;
  final DateTime? birthDate;
  final String? gender;

  Profile copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? displayName,
    NamePrivacyMode? privacyMode,
    String? languageCode,
    Map<String, String>? socialLinks,
    DateTime? birthDate,
    String? gender,
  }) {
    return Profile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      privacyMode: privacyMode ?? this.privacyMode,
      languageCode: languageCode ?? this.languageCode,
      socialLinks: socialLinks ?? this.socialLinks,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
    );
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    final socialRaw = map['social_links'];
    final socialLinks = <String, String>{};
    if (socialRaw is Map) {
      for (final entry in socialRaw.entries) {
        final key = entry.key.toString().trim();
        final value = entry.value?.toString().trim() ?? '';
        if (key.isEmpty || value.isEmpty) continue;
        socialLinks[key] = value;
      }
    }

    final firstName = (map['first_name'] ?? map['firstName'] ?? '')
        .toString()
        .trim();
    final lastName = (map['last_name'] ?? map['lastName'] ?? '')
        .toString()
        .trim();

    return Profile(
      id: (map['id'] ?? '').toString(),
      firstName: firstName,
      lastName: lastName,
      displayName: map['display_name']?.toString(),
      privacyMode: parsePrivacy(map['privacy_mode']?.toString()),
      languageCode: _normalizeLanguageCode(map['language_code']?.toString()),
      socialLinks: socialLinks,
      birthDate: map['birth_date'] != null
          ? DateTime.tryParse(map['birth_date'].toString())
          : null,
      gender: map['gender']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'display_name': (displayName ?? '').trim().isEmpty
          ? null
          : displayName!.trim(),
      'privacy_mode': privacyToDb(privacyMode),
      if (languageCode != null) 'language_code': languageCode,
      'social_links': socialLinks,
      if (birthDate != null)
        'birth_date': birthDate!.toIso8601String().substring(0, 10),
      if (gender != null) 'gender': gender,
    };
  }
}

String? _normalizeLanguageCode(String? value) {
  final code = (value ?? '').trim().toLowerCase();
  if (code == 'tr' || code == 'en') return code;
  return null;
}
