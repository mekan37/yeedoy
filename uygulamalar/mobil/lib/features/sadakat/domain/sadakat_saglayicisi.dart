import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_provider.dart';

class LoyaltyStatus {
  LoyaltyStatus({
    required this.isActive,
    required this.points,
    required this.rewardThresholdPts,
    required this.progressPct,
    required this.checkinPoints,
    required this.reviewPoints,
    this.rewardType,
    this.rewardValue,
  });

  final bool isActive;
  final int points;
  final int rewardThresholdPts;
  final int progressPct;
  final int checkinPoints;
  final int reviewPoints;
  final String? rewardType;
  final int? rewardValue;

  factory LoyaltyStatus.fromMap(Map<String, dynamic> m) => LoyaltyStatus(
        isActive: m['is_active'] == true,
        points: (m['points'] as num?)?.toInt() ?? 0,
        rewardThresholdPts: (m['reward_threshold_pts'] as num?)?.toInt() ?? 0,
        progressPct: (m['progress_pct'] as num?)?.toInt() ?? 0,
        checkinPoints: (m['checkin_points'] as num?)?.toInt() ?? 0,
        reviewPoints: (m['review_points'] as num?)?.toInt() ?? 0,
        rewardType: m['reward_type'] as String?,
        rewardValue: (m['reward_value'] as num?)?.toInt(),
      );
}

final loyaltyStatusProvider =
    FutureProvider.autoDispose.family<LoyaltyStatus?, String>(
  (ref, businessId) async {
    final client = ref.watch(supabaseProvider);
    if (client.auth.currentUser == null) return null;
    final res = await client.rpc(
      'get_loyalty_status_v1',
      params: {'p_business_id': businessId},
    );
    if (res == null) return null;
    final map = res as Map<String, dynamic>;
    final status = LoyaltyStatus.fromMap(map);
    return status.isActive ? status : null;
  },
);

enum LoyaltyTier { bronz, gumus, altin, platin }

extension LoyaltyTierX on LoyaltyTier {
  String get label => switch (this) {
    LoyaltyTier.bronz  => 'Bronz',
    LoyaltyTier.gumus  => 'Gümüş',
    LoyaltyTier.altin  => 'Altın',
    LoyaltyTier.platin => 'Platin',
  };

  int get thresholdPts => switch (this) {
    LoyaltyTier.bronz  => 0,
    LoyaltyTier.gumus  => 500,
    LoyaltyTier.altin  => 1500,
    LoyaltyTier.platin => 5000,
  };

  int get nextThreshold => switch (this) {
    LoyaltyTier.bronz  => 500,
    LoyaltyTier.gumus  => 1500,
    LoyaltyTier.altin  => 5000,
    LoyaltyTier.platin => 5000,
  };

  static LoyaltyTier fromLifetimePoints(int pts) {
    if (pts >= 5000) return LoyaltyTier.platin;
    if (pts >= 1500) return LoyaltyTier.altin;
    if (pts >= 500)  return LoyaltyTier.gumus;
    return LoyaltyTier.bronz;
  }
}

class LoyaltyCard {
  LoyaltyCard({
    required this.businessId,
    required this.businessName,
    this.logoUrl,
    required this.points,
    required this.lifetimePoints,
    required this.rewardThresholdPts,
    required this.rewardType,
    required this.rewardValue,
    required this.progressPct,
  });

  final String businessId;
  final String businessName;
  final String? logoUrl;
  final int points;
  final int lifetimePoints;
  final int rewardThresholdPts;
  final String rewardType;
  final int rewardValue;
  final int progressPct;

  LoyaltyTier get tier => LoyaltyTierX.fromLifetimePoints(lifetimePoints);

  factory LoyaltyCard.fromMap(Map<String, dynamic> m) => LoyaltyCard(
        businessId: (m['business_id'] ?? '').toString(),
        businessName: (m['business_name'] ?? '').toString(),
        logoUrl: m['logo_url'] as String?,
        points: (m['points'] as num?)?.toInt() ?? 0,
        lifetimePoints: (m['lifetime_points'] as num?)?.toInt() ?? 0,
        rewardThresholdPts: (m['reward_threshold_pts'] as num?)?.toInt() ?? 500,
        rewardType: (m['reward_type'] as String?) ?? 'discount_pct',
        rewardValue: (m['reward_value'] as num?)?.toInt() ?? 10,
        progressPct: (m['progress_pct'] as num?)?.toInt() ?? 0,
      );
}

final myLoyaltyCardsProvider = FutureProvider.autoDispose<List<LoyaltyCard>>((ref) async {
  final client = ref.watch(supabaseProvider);
  if (client.auth.currentUser == null) return const [];

  final res = await client.rpc('get_my_loyalty_cards_v1');
  if (res == null) return const [];
  final list = res as List;
  return list.cast<Map<String, dynamic>>().map(LoyaltyCard.fromMap).toList();
});
