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

final profileRepoProvider = Provider<ProfileRepo>((ref) {
  return ProfileRepo(ref.watch(supabaseProvider));
});

class ProfileRepo {
  ProfileRepo(this.client);
  final SupabaseClient client;

  Future<ProfileStats> getMyStats() async {
    final res = await client.rpc('get_my_profile_stats');
    // rpc result bazen List dönebilir (table returns)
    if (res is List && res.isNotEmpty) {
      return ProfileStats.fromMap(res.first as Map<String, dynamic>);
    }
    if (res is Map<String, dynamic>) {
      return ProfileStats.fromMap(res);
    }
    // bo?Y gelirse
    return ProfileStats(
      reviewsCount: 0,
      helpfulReceived: 0,
      favoritesCount: 0,
      contributionScore: 0,
      visitsCount: 0,
    );
  }

  Future<int> getMyReputationScore() async {
    final res = await client.rpc('get_my_reputation_score_v1');
    if (res is num) return res.toInt();
    if (res is Map<String, dynamic>) {
      final v = res['score'] ?? res['reputation_score'];
      return (v as num?)?.toInt() ?? 0;
    }
    if (res is List && res.isNotEmpty) {
      final row = res.first;
      if (row is Map<String, dynamic>) {
        final v = row['score'] ?? row['reputation_score'];
        return (v as num?)?.toInt() ?? 0;
      }
      if (row is num) return row.toInt();
    }
    return 0;
  }

  Future<WeeklyMissions> getMyWeeklyMissions() async {
    final res = await client.rpc('get_my_weekly_missions');
    if (res is List && res.isNotEmpty) {
      return WeeklyMissions.fromMap(res.first as Map<String, dynamic>);
    }
    if (res is Map<String, dynamic>) {
      return WeeklyMissions.fromMap(res);
    }
    // fallback
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
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      return ContributionHistory(
        menuSuggestionsCount: 0,
        priceVerificationsCount: 0,
        businessSuggestionsCount: 0,
        recentItems: const [],
      );
    }

    final menuTask = client
        .from('menu_item_suggestions')
        .select('id,action,status,created_at,payload')
        .eq('created_by', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    final priceTask = client
        .from('menu_item_price_suggestions')
        .select('id,status,created_at,suggested_price_cents')
        .eq('created_by', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    final businessTask = client
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
      final title = (payload['name'] ?? payload['title'] ?? 'Menu katkisi')
          .toString();
      items.add(
        ContributionHistoryItem(
          type: 'menu',
          title: title.trim().isEmpty ? 'Menu katkisi' : title,
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
      res = await client.rpc('get_my_achievements_v2');
    } catch (_) {
      res = await client.rpc('get_my_achievements_v1');
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
      res = await client.rpc('get_my_profile_progress_v1');
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
    final res = await client.rpc('get_my_daily_micro_task_v1');
    if (res is List && res.isNotEmpty && res.first is Map) {
      return DailyMicroTask.fromMap((res.first as Map).cast<String, dynamic>());
    }
    if (res is Map<String, dynamic>) {
      return DailyMicroTask.fromMap(res);
    }
    return null;
  }

  Future<UserMoatSignals> getMyMoatSignals() async {
    final trustRes = await client.rpc('get_my_trust_graph_v1');
    final segmentRes = await client.rpc('get_my_behavior_segment_v1');
    final silentRes = await client.rpc('get_my_silent_quality_score_v1');

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
