import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_provider.dart';

class LoyaltyCard {
  LoyaltyCard({
    required this.programId,
    required this.mode,
    required this.businessName,
    this.logoUrl,
    required this.progress,
    required this.rewardThreshold,
    required this.rewardDesc,
  });

  final String programId;
  final String mode; // 'stamp' | 'points'
  final String businessName;
  final String? logoUrl;
  final int progress;
  final int rewardThreshold;
  final String rewardDesc;

  double get progressRatio =>
      rewardThreshold > 0 ? (progress / rewardThreshold).clamp(0.0, 1.0) : 0.0;

  factory LoyaltyCard.fromMap(Map<String, dynamic> m) => LoyaltyCard(
        programId: (m['program_id'] ?? '').toString(),
        mode: (m['mode'] as String?) ?? 'stamp',
        businessName: (m['business_name'] ?? '').toString(),
        logoUrl: m['logo_url'] as String?,
        progress: (m['progress'] as num?)?.toInt() ?? 0,
        rewardThreshold: (m['reward_threshold'] as num?)?.toInt() ?? 1,
        rewardDesc: (m['reward_desc'] as String?) ?? '',
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

/// Müşterinin owner'a gösterip taratacağı QR kodunun içeriği — düz metin
/// olarak kendi user id'si (web `/sadakat` sayfasıyla aynı format,
/// `scan_loyalty_qr_v1(business_id, user_id)` bunu doğrudan bekliyor).
final myLoyaltyQrDataProvider = Provider.autoDispose<String?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client.auth.currentUser?.id;
});
