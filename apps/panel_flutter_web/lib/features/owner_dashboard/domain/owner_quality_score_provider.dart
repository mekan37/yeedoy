import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';

class OwnerQualityScore {
  const OwnerQualityScore({
    required this.score,
    required this.tips,
    required this.breakdown,
  });

  final int score;
  final List<String> tips;
  final Map<String, dynamic> breakdown;

  factory OwnerQualityScore.fromMap(Map<String, dynamic> map) {
    final tipsRaw = (map['tips'] as List?) ?? const [];
    return OwnerQualityScore(
      score: (map['score'] as num?)?.toInt() ?? 0,
      tips: tipsRaw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList(),
      breakdown: (map['breakdown'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}

final ownerQualityScoreProvider =
    FutureProvider.family<OwnerQualityScore?, String?>((ref, businessId) async {
  if (businessId == null || businessId.trim().isEmpty) return null;
  final client = ref.watch(supabaseProvider);
  try {
    final res = await client.rpc('get_business_quality_score_v1', params: {
      'p_business_id': businessId,
    });
    if (res is Map) {
      return OwnerQualityScore.fromMap(res.cast<String, dynamic>());
    }
    return null;
  } catch (e) {
    throw Exception(AppErrorMapper.message(e));
  }
});
