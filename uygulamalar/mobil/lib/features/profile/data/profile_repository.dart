import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';
import '../domain/achievement.dart';
import '../domain/contribution_history.dart';
import '../domain/profile_progress.dart';
import '../domain/profile_stats.dart';
import '../domain/user_moat_signals.dart';
import '../domain/weekly_missions.dart';
import 'profile_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseProvider));
});

class ProfileRepository {
  ProfileRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<Profile?> fetchMyProfile() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return null;

    try {
      final row = await _supabase
          .from('user_profiles')
          .select('user_id,display_name,social_links,language_code,birth_date,gender')
          .eq('user_id', uid)
          .single();
      final data = (row as Map).cast<String, dynamic>();
      final displayName = (data['display_name'] ?? '').toString().trim();
      final parts = displayName
          .split(RegExp(r'\s+'))
          .where((e) => e.isNotEmpty)
          .toList();
      final firstName = parts.isNotEmpty ? parts.first : '';
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      final socialRaw = data['social_links'];
      final socialLinks = <String, String>{};
      if (socialRaw is Map) {
        for (final entry in socialRaw.entries) {
          final key = entry.key.toString().trim();
          final value = entry.value?.toString().trim() ?? '';
          if (key.isEmpty || value.isEmpty) continue;
          socialLinks[key] = value;
        }
      }
      return Profile(
        id: (data['user_id'] ?? uid).toString(),
        firstName: firstName,
        lastName: lastName,
        displayName: displayName.isEmpty ? null : displayName,
        languageCode: data['language_code']?.toString(),
        socialLinks: socialLinks,
        birthDate: data['birth_date'] != null
            ? DateTime.tryParse(data['birth_date'].toString())
            : null,
        gender: data['gender']?.toString(),
      );
    } on PostgrestException catch (e) {
      // No row found => return null, anything else rethrow.
      if (e.code == 'PGRST116' ||
          (e.message).toLowerCase().contains('0 rows')) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> upsertMyProfile(Profile p) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('auth_required');
    }

    final normalizedLinks = <String, String>{};
    for (final entry in p.socialLinks.entries) {
      final key = entry.key.trim();
      if (key.isEmpty) continue;
      final normalized = normalizeSocialUrl(entry.value);
      if (normalized == null || normalized.isEmpty) continue;
      normalizedLinks[key] = normalized;
    }

    final profile = p.copyWith(id: uid, socialLinks: normalizedLinks);
    final displayName =
        (profile.displayName ?? '${profile.firstName} ${profile.lastName}')
            .trim();
    await _supabase.from('user_profiles').upsert({
      'user_id': uid,
      'display_name': displayName.isEmpty ? 'Kullanici' : displayName,
      'social_links': normalizedLinks.isEmpty ? null : normalizedLinks,
    }, onConflict: 'user_id');
  }

  /// Sadece social_links kolonunu günceller; diğer alanları dokunmaz.
  Future<void> updateSocialLinks(Map<String, String> links) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    final existing = await _supabase
        .from('user_profiles')
        .select('display_name')
        .eq('user_id', uid)
        .maybeSingle();
    await _supabase.from('user_profiles').upsert({
      'user_id': uid,
      'display_name': (existing?['display_name'] as String?) ?? 'Kullanici',
      'social_links': links.isEmpty ? null : links,
    }, onConflict: 'user_id');
  }

  /// Sadece birth_date kolonunu günceller; diğer alanları dokunmaz.
  Future<void> updateBirthDate(DateTime? birthDate) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    final existing = await _supabase
        .from('user_profiles')
        .select('display_name')
        .eq('user_id', uid)
        .maybeSingle();
    await _supabase.from('user_profiles').upsert({
      'user_id': uid,
      'display_name': (existing?['display_name'] as String?) ?? 'Kullanici',
      'birth_date': birthDate?.toIso8601String().substring(0, 10),
    }, onConflict: 'user_id');
  }

  /// Sadece gender kolonunu günceller; diğer alanları dokunmaz.
  Future<void> updateGender(String? gender) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    final existing = await _supabase
        .from('user_profiles')
        .select('display_name')
        .eq('user_id', uid)
        .maybeSingle();
    await _supabase.from('user_profiles').upsert({
      'user_id': uid,
      'display_name': (existing?['display_name'] as String?) ?? 'Kullanici',
      'gender': gender,
    }, onConflict: 'user_id');
  }

  Future<void> updateLanguageCode(String? languageCode) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    final existing = await _supabase
        .from('user_profiles')
        .select('display_name')
        .eq('user_id', uid)
        .maybeSingle();

    await _supabase.from('user_profiles').upsert({
      'user_id': uid,
      'display_name': (existing?['display_name'] as String?) ?? 'Kullanici',
      'language_code': languageCode,
    }, onConflict: 'user_id');
  }

  Future<ProfileStats> fetchMyStats() async {
    final res = await _supabase.rpc('get_my_profile_stats_v1');
    if (res is List && res.isNotEmpty) {
      return ProfileStats.fromMap(res.first as Map<String, dynamic>);
    }
    if (res is Map<String, dynamic>) {
      return ProfileStats.fromMap(res);
    }
    return ProfileStats(
      reviewsCount: 0,
      helpfulReceived: 0,
      favoritesCount: 0,
      contributionScore: 0,
      visitsCount: 0,
      followersCount: 0,
    );
  }

  Future<int> fetchMyReputationScore() async {
    final res = await _supabase.rpc('get_my_reputation_score_v1');
    if (res is num) return res.toInt();
    if (res is Map<String, dynamic>) {
      final value = res['score'] ?? res['reputation_score'];
      return (value as num?)?.toInt() ?? 0;
    }
    if (res is List && res.isNotEmpty) {
      final row = res.first;
      if (row is Map<String, dynamic>) {
        final value = row['score'] ?? row['reputation_score'];
        return (value as num?)?.toInt() ?? 0;
      }
      if (row is num) return row.toInt();
    }
    return 0;
  }

  Future<WeeklyMissions> fetchMyWeeklyMissions() async {
    final res = await _supabase.rpc('get_my_weekly_missions_v1');
    if (res is List && res.isNotEmpty) {
      return WeeklyMissions.fromMap(res.first as Map<String, dynamic>);
    }
    if (res is Map<String, dynamic>) {
      return WeeklyMissions.fromMap(res);
    }
    return WeeklyMissions(
      weekStart: DateTime.now(),
      reviewsDone: 0,
      visitsDone: 0,
      votesDone: 0,
      reviewsGoal: 1,
      visitsGoal: 3,
      votesGoal: 3,
      completedCount: 0,
    );
  }

  Future<ContributionHistory> fetchMyContributionHistory({
    int limit = 12,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return ContributionHistory(
        menuSuggestionsCount: 0,
        priceVerificationsCount: 0,
        businessSuggestionsCount: 0,
        recentItems: const [],
      );
    }

    final menuTask = _supabase
        .from('menu_item_suggestions')
        .select('id,action,status,created_at,payload')
        .eq('created_by', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    final priceTask = _supabase
        .from('menu_item_price_suggestions')
        .select('id,status,created_at,suggested_price_cents')
        .eq('created_by', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    final businessTask = _supabase
        .from('business_suggestions')
        .select('id,name,status,created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    final results = await Future.wait([menuTask, priceTask, businessTask]);
    final menuRows = (results[0] as List?) ?? const [];
    final priceRows = (results[1] as List?) ?? const [];
    final businessRows = (results[2] as List?) ?? const [];

    final items = <ContributionHistoryItem>[];
    for (final row in menuRows.whereType<Map>()) {
      final map = row.cast<String, dynamic>();
      final payload =
          (map['payload'] as Map?)?.cast<String, dynamic>() ?? const {};
      final title = (payload['name'] ?? payload['title'] ?? 'Menü katkısı')
          .toString();
      items.add(
        ContributionHistoryItem(
          type: 'menu',
          title: title.trim().isEmpty ? 'Menü katkısı' : title,
          status: (map['status'] ?? 'pending').toString(),
          createdAt:
              DateTime.tryParse((map['created_at'] ?? '').toString()) ??
              DateTime.now(),
        ),
      );
    }
    for (final row in priceRows.whereType<Map>()) {
      final map = row.cast<String, dynamic>();
      final cents = (map['suggested_price_cents'] as num?)?.toInt();
      items.add(
        ContributionHistoryItem(
          type: 'price',
          title: cents == null
              ? 'Fiyat doğrulama'
              : 'Fiyat önerisi: ${cents ~/ 100} TL',
          status: (map['status'] ?? 'pending').toString(),
          createdAt:
              DateTime.tryParse((map['created_at'] ?? '').toString()) ??
              DateTime.now(),
        ),
      );
    }
    for (final row in businessRows.whereType<Map>()) {
      final map = row.cast<String, dynamic>();
      items.add(
        ContributionHistoryItem(
          type: 'business',
          title: (map['name'] ?? 'İşletme önerisi').toString(),
          status: (map['status'] ?? 'pending').toString(),
          createdAt:
              DateTime.tryParse((map['created_at'] ?? '').toString()) ??
              DateTime.now(),
        ),
      );
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ContributionHistory(
      menuSuggestionsCount: menuRows.length,
      priceVerificationsCount: priceRows.length,
      businessSuggestionsCount: businessRows.length,
      recentItems: items.take(limit).toList(),
    );
  }

  Future<List<Achievement>> fetchMyAchievements() async {
    dynamic res;
    try {
      res = await _supabase.rpc('get_my_achievements_v2');
    } catch (_) {
      res = await _supabase.rpc('get_my_achievements_v1');
    }
    final rows = (res as List?) ?? const [];
    return rows
        .whereType<Map>()
        .map((e) => Achievement.fromMap(e.cast<String, dynamic>()))
        .toList();
  }

  Future<ProfileProgress> fetchMyProfileProgress() async {
    dynamic res;
    try {
      res = await _supabase.rpc('get_my_profile_progress_v1');
    } catch (_) {
      final achievements = await fetchMyAchievements();
      final xp = achievements
          .where((e) => e.unlocked)
          .fold<int>(0, (sum, e) => sum + e.xp);
      return ProfileProgress(
        totalXp: xp,
        level: (xp ~/ 100) + 1,
        xpInLevel: xp % 100,
        nextLevelXp: 100,
        unlockedCount: achievements.where((e) => e.unlocked).length,
      );
    }
    if (res is List && res.isNotEmpty && res.first is Map) {
      return ProfileProgress.fromMap(
        (res.first as Map).cast<String, dynamic>(),
      );
    }
    if (res is Map) {
      return ProfileProgress.fromMap(res.cast<String, dynamic>());
    }
    return const ProfileProgress(
      totalXp: 0,
      level: 1,
      xpInLevel: 0,
      nextLevelXp: 100,
      unlockedCount: 0,
    );
  }

  /// Picks an image from gallery and uploads it as the user's avatar.
  /// Returns the public URL of the uploaded avatar, or null if cancelled/failed.
  Future<String?> pickAndUploadAvatar() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return null;

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final ext = file.path.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    final storagePath = 'user-avatars/$uid.$ext';

    await _supabase.storage
        .from('menu-media')
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(contentType: mime, upsert: true),
        );

    final publicUrl = _supabase.storage
        .from('menu-media')
        .getPublicUrl(storagePath);

    await _supabase.from('user_profiles').upsert({
      'user_id': uid,
      'avatar_url': publicUrl,
    }, onConflict: 'user_id');

    return publicUrl;
  }

  Future<UserMoatSignals> fetchMyMoatSignals() async {
    final trustRes = await _supabase.rpc('get_my_trust_graph_v1');
    final segmentRes = await _supabase.rpc('get_my_behavior_segment_v1');
    final silentRes = await _supabase.rpc('get_my_silent_quality_score_v1');

    Map<String, dynamic> asMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return value.cast<String, dynamic>();
      if (value is List && value.isNotEmpty) {
        final first = value.first;
        if (first is Map<String, dynamic>) return first;
        if (first is Map) return first.cast<String, dynamic>();
      }
      return const {};
    }

    return UserMoatSignals.fromMaps(
      trust: asMap(trustRes),
      segment: asMap(segmentRes),
      silent: asMap(silentRes),
    );
  }
}

String? normalizeSocialUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  Uri? uri = Uri.tryParse(trimmed);
  if (uri == null) return null;
  if (uri.scheme.isEmpty) {
    uri = Uri.tryParse('https://$trimmed');
    if (uri == null) return null;
  }
  if (uri.host.isEmpty) return null;

  final host = uri.host.toLowerCase();
  const allowedBestEffort = <String>{
    'instagram.com',
    'www.instagram.com',
    'youtube.com',
    'www.youtube.com',
    'youtu.be',
    'facebook.com',
    'www.facebook.com',
    'fb.watch',
  };

  // Best-effort allow list: do not hard reject unknown hosts.
  if (!allowedBestEffort.contains(host)) {
    return uri.toString();
  }
  return uri.toString();
}
