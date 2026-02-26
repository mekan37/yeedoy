import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';
import '../domain/achievement.dart';
import '../domain/contribution_history.dart';
import '../domain/daily_micro_task.dart';
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

  Future<Profile?> getMyProfile() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return null;

    try {
      final row = await _supabase
          .from('user_profiles')
          .select('user_id,display_name')
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
      return Profile(
        id: (data['user_id'] ?? uid).toString(),
        firstName: firstName,
        lastName: lastName,
        displayName: displayName.isEmpty ? null : displayName,
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
    }, onConflict: 'user_id');
  }

  Future<ProfileStats> getMyStats() async {
    final res = await _supabase.rpc('get_my_profile_stats');
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
    );
  }

  Future<int> getMyReputationScore() async {
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

  Future<WeeklyMissions> getMyWeeklyMissions() async {
    final res = await _supabase.rpc('get_my_weekly_missions');
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

  Future<ContributionHistory> getMyContributionHistory({int limit = 12}) async {
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

  Future<List<Achievement>> getMyAchievements() async {
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

  Future<ProfileProgress> getMyProfileProgress() async {
    dynamic res;
    try {
      res = await _supabase.rpc('get_my_profile_progress_v1');
    } catch (_) {
      final achievements = await getMyAchievements();
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

  Future<DailyMicroTask?> getMyDailyMicroTask() async {
    final res = await _supabase.rpc('get_my_daily_micro_task_v1');
    if (res is List && res.isNotEmpty && res.first is Map) {
      return DailyMicroTask.fromMap((res.first as Map).cast<String, dynamic>());
    }
    if (res is Map<String, dynamic>) {
      return DailyMicroTask.fromMap(res);
    }
    return null;
  }

  Future<UserMoatSignals> getMyMoatSignals() async {
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
