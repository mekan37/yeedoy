import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_error_mapper.dart';
import '../../../../core/network/supabase_provider.dart';

class OwnerMoatSummary {
  const OwnerMoatSummary({
    required this.businessTrustScore,
    required this.menuFreshnessScore,
    required this.priceAccuracyScore,
    required this.contributionTrustScore,
    required this.uniqueValidators,
    required this.lastPriceVerificationAt,
    required this.evidenceRate,
    required this.contributionQualityRate,
    required this.menuViewsToday,
    required this.districtRank,
  });

  final int businessTrustScore;
  final int menuFreshnessScore;
  final int priceAccuracyScore;
  final int contributionTrustScore;

  final int uniqueValidators;
  final DateTime? lastPriceVerificationAt;
  final double evidenceRate;
  final double contributionQualityRate;
  final int menuViewsToday;
  final int? districtRank;
}

final ownerMoatSummaryProvider =
    FutureProvider.family<OwnerMoatSummary?, String?>((ref, businessId) async {
      if (businessId == null || businessId.trim().isEmpty) return null;
      final client = ref.watch(supabaseProvider);

      try {
        final qualityRes = await client.rpc(
          'get_business_quality_score_v1',
          params: {'p_business_id': businessId},
        );
        final qualityScore = _asInt(_pickMapValue(qualityRes, ['score']));

        final priceTrustRes = await client.rpc(
          'get_business_price_trust_v1',
          params: {'p_business_id': businessId},
        );
        final verifiedCount = _asInt(
          _pickMapValue(priceTrustRes, ['verified_count']),
        );
        final totalCount = _asInt(
          _pickMapValue(priceTrustRes, ['total_count']),
        );
        final lastVerifiedAt = _asDate(
          _pickMapValue(priceTrustRes, ['last_verified_at']),
        );
        final priceAccuracy = totalCount > 0
            ? ((verifiedCount / totalCount) * 100).round().clamp(0, 100)
            : 0;

        final menusRes = await client
            .from('menus')
            .select('updated_at')
            .eq('business_id', businessId)
            .eq('status', 'published')
            .order('updated_at', ascending: false)
            .limit(1);
        final menuLastUpdatedAt = menusRes.isNotEmpty
            ? _asDate((menusRes.first as Map)['updated_at'])
            : null;
        final menuFreshness = _menuFreshnessScore(menuLastUpdatedAt);

        final suggestions = await _loadPriceSuggestionSignals(
          client,
          businessId,
        );
        final uniqueValidators = suggestions.uniqueValidators;
        final evidenceRate = suggestions.evidenceRate;
        final contributionQualityRate = suggestions.approvedRate;

        final activityRes = await client.rpc(
          'get_business_activity_v1',
          params: {'p_business_id': businessId, 'p_limit': 12},
        );
        final activityRows = (activityRes as List?) ?? const [];
        final activitySignals = _extractActivitySignals(activityRows);

        final contributionTrust =
            ((contributionQualityRate * 60) +
                    (evidenceRate * 20) +
                    (_normalizeCount(uniqueValidators, max: 8) * 20))
                .round()
                .clamp(0, 100);

        final businessTrust =
            ((qualityScore * 0.40) +
                    (menuFreshness * 0.25) +
                    (priceAccuracy * 0.25) +
                    (contributionTrust * 0.10))
                .round()
                .clamp(0, 100);

        return OwnerMoatSummary(
          businessTrustScore: businessTrust,
          menuFreshnessScore: menuFreshness,
          priceAccuracyScore: priceAccuracy,
          contributionTrustScore: contributionTrust,
          uniqueValidators: uniqueValidators,
          lastPriceVerificationAt: lastVerifiedAt,
          evidenceRate: evidenceRate,
          contributionQualityRate: contributionQualityRate,
          menuViewsToday: activitySignals.menuViewsToday,
          districtRank: activitySignals.districtRank,
        );
      } catch (e) {
        throw Exception(AppErrorMapper.message(e));
      }
    });

class _PriceSuggestionSignals {
  const _PriceSuggestionSignals({
    required this.uniqueValidators,
    required this.evidenceRate,
    required this.approvedRate,
  });

  final int uniqueValidators;
  final double evidenceRate;
  final double approvedRate;
}

class _ActivitySignals {
  const _ActivitySignals({
    required this.menuViewsToday,
    required this.districtRank,
  });

  final int menuViewsToday;
  final int? districtRank;
}

Future<_PriceSuggestionSignals> _loadPriceSuggestionSignals(
  dynamic client,
  String businessId,
) async {
  List<dynamic> rows;
  try {
    rows = await client
        .from('menu_item_price_suggestions')
        .select('created_by,status,evidence_url,created_at')
        .eq('business_id', businessId)
        .limit(120);
  } catch (_) {
    rows = await client
        .from('menu_item_price_suggestions')
        .select('created_by,status,created_at')
        .eq('business_id', businessId)
        .limit(120);
  }

  if (rows.isEmpty) {
    return const _PriceSuggestionSignals(
      uniqueValidators: 0,
      evidenceRate: 0,
      approvedRate: 0,
    );
  }

  final validators = <String>{};
  var withEvidence = 0;
  var approved = 0;
  var reviewed = 0;
  for (final row in rows.whereType<Map>()) {
    final map = row.cast<String, dynamic>();
    final createdBy = (map['created_by'] ?? '').toString().trim();
    if (createdBy.isNotEmpty) validators.add(createdBy);

    final ev = (map['evidence_url'] ?? '').toString().trim();
    if (ev.isNotEmpty) withEvidence++;

    final status = (map['status'] ?? '').toString().trim();
    if (status == 'approved') {
      approved++;
      reviewed++;
    } else if (status == 'rejected') {
      reviewed++;
    }
  }

  return _PriceSuggestionSignals(
    uniqueValidators: validators.length,
    evidenceRate: rows.isEmpty ? 0 : (withEvidence / rows.length).clamp(0, 1),
    approvedRate: reviewed == 0 ? 0 : (approved / reviewed).clamp(0, 1),
  );
}

_ActivitySignals _extractActivitySignals(List<dynamic> rows) {
  int menuViewsToday = 0;
  int? districtRank;

  for (final row in rows.whereType<Map>()) {
    final map = row.cast<String, dynamic>();
    final type = (map['activity_type'] ?? map['type'] ?? '').toString();
    final meta = (map['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    if (menuViewsToday == 0 &&
        (type == 'menu_view' ||
            type == 'menu_views' ||
            type == 'menu_viewed')) {
      menuViewsToday = _asInt(
        meta['count_today'] ?? meta['today'] ?? meta['count'] ?? meta['views'],
      );
    }
    if (districtRank == null && type == 'district_rank') {
      districtRank = _asInt(meta['rank'] ?? meta['position']);
      if (districtRank == 0) districtRank = null;
    }
  }

  return _ActivitySignals(
    menuViewsToday: menuViewsToday,
    districtRank: districtRank,
  );
}

int _menuFreshnessScore(DateTime? lastUpdate) {
  if (lastUpdate == null) return 0;
  final days = DateTime.now().difference(lastUpdate).inDays;
  if (days <= 7) return 100;
  if (days <= 30) return 80;
  if (days <= 90) return 60;
  if (days <= 180) return 40;
  return 20;
}

double _normalizeCount(int value, {required int max}) {
  final safeMax = max <= 0 ? 1 : max;
  return (value.clamp(0, safeMax) / safeMax).toDouble();
}

dynamic _pickMapValue(dynamic data, List<String> keys) {
  Map<String, dynamic>? map;
  if (data is Map) {
    map = data.cast<String, dynamic>();
  } else if (data is List && data.isNotEmpty && data.first is Map) {
    map = (data.first as Map).cast<String, dynamic>();
  }
  if (map == null) return null;
  for (final key in keys) {
    if (map.containsKey(key)) return map[key];
  }
  return null;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? 0;
}

DateTime? _asDate(dynamic value) {
  final s = (value ?? '').toString();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}
