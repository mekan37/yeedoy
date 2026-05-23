import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ag/supabase_saglayicisi.dart';

/// Bugün bu işletmeye check-in yapıldı mı?
final checkinTodayProvider =
    FutureProvider.family<bool, String>((ref, businessId) async {
  if (businessId.isEmpty) return false;
  final client = ref.watch(supabaseProvider);
  try {
    final res = await client.rpc('get_my_checkin_today_v1', params: {
      'p_business_id': businessId,
    });
    if (res is Map) {
      return (res as Map<String, dynamic>)['checked_in'] == true;
    }
    return false;
  } catch (_) {
    return false;
  }
});

/// Son check-in bilgisi: streak + total
final checkinStatsProvider =
    FutureProvider.family<CheckinStats, String>((ref, businessId) async {
  if (businessId.isEmpty) return const CheckinStats();
  final client = ref.watch(supabaseProvider);
  try {
    final res = await client.rpc('get_checkin_stats_v1', params: {
      'p_business_id': businessId,
    });
    if (res is Map) {
      final data = res as Map<String, dynamic>;
      return CheckinStats(
        streakDays: (data['streak_days'] as int?) ?? 0,
        totalCheckins: (data['total_checkins'] as int?) ?? 0,
        pointsEarned: (data['points_earned'] as int?) ?? 0,
        nextMilestone: (data['next_milestone'] as int?) ?? 5,
      );
    }
  } catch (_) {}
  return const CheckinStats();
});

/// Check-in submit sonucu
class CheckinResult {
  const CheckinResult({
    this.ok = false,
    this.error,
    this.streakDays = 0,
    this.pointsEarned = 0,
    this.totalCheckins = 0,
    this.nextMilestone = 5,
    this.newBadge,
  });

  final bool ok;
  final String? error;
  final int streakDays;
  final int pointsEarned;
  final int totalCheckins;
  final int nextMilestone;
  final String? newBadge;
}

/// Check-in istatistikleri
class CheckinStats {
  const CheckinStats({
    this.streakDays = 0,
    this.totalCheckins = 0,
    this.pointsEarned = 0,
    this.nextMilestone = 5,
  });

  final int streakDays;
  final int totalCheckins;
  final int pointsEarned;
  final int nextMilestone;
}

/// Check-in submit controller — optimistic update ile
final checkinControllerProvider =
    AsyncNotifierProvider.family<CheckinController, bool, String>(
  CheckinController.new,
);

class CheckinController extends AsyncNotifier<bool> {
  CheckinController(this.businessId);
  final String businessId;

  @override
  Future<bool> build() async {
    if (businessId.isEmpty) return false;
    final client = ref.read(supabaseProvider);
    try {
      final res = await client.rpc('get_my_checkin_today_v1', params: {
        'p_business_id': businessId,
      });
      if (res is Map) {
        return (res as Map<String, dynamic>)['checked_in'] == true;
      }
    } catch (_) {}
    return false;
  }

  /// Check-in yap. Gerçek streak + puan bilgisi ile döner.
  Future<CheckinResult> submitCheckin({String? note}) async {
    final prev = state.value ?? false;
    state = const AsyncLoading();
    try {
      final client = ref.read(supabaseProvider);
      final res = await client.rpc('submit_checkin_v1', params: {
        'p_business_id': businessId,
        'p_note': note,
      });
      final data = res as Map<String, dynamic>;
      if (data['ok'] == true) {
        state = const AsyncValue.data(true);
        return CheckinResult(
          ok: true,
          streakDays: (data['streak_days'] as int?) ?? 1,
          pointsEarned: (data['points_earned'] as int?) ?? 10,
          totalCheckins: (data['total_checkins'] as int?) ?? 1,
          nextMilestone: (data['next_milestone'] as int?) ?? 5,
          newBadge: data['new_badge'] as String?,
        );
      }
      state = AsyncValue.data(prev);
      return CheckinResult(ok: false, error: data['error']?.toString());
    } catch (e) {
      state = AsyncValue.data(prev);
      return CheckinResult(ok: false, error: e.toString());
    }
  }
}
