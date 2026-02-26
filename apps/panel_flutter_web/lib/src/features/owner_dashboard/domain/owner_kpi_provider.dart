import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_error_mapper.dart';
import '../../../../core/network/supabase_provider.dart';

class OwnerKpiSummary {
  const OwnerKpiSummary({
    required this.businessViews,
    required this.outboundClicks,
    required this.directionsClicks,
    required this.searchImpressions,
  });

  final int businessViews;
  final int outboundClicks;
  final int directionsClicks;
  final int searchImpressions;

  factory OwnerKpiSummary.fromMap(Map<String, dynamic> map) {
    return OwnerKpiSummary(
      businessViews: _asInt(map['business_views']),
      outboundClicks: _asInt(map['outbound_clicks']),
      directionsClicks: _asInt(map['directions_clicks']),
      searchImpressions: _asInt(map['search_impressions']),
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse((v ?? '').toString()) ?? 0;
  }
}

final ownerKpiSummaryProvider =
    FutureProvider.family<OwnerKpiSummary?, String?>((ref, businessId) async {
      if (businessId == null || businessId.trim().isEmpty) return null;
      final client = ref.watch(supabaseProvider);
      try {
        final res = await client.rpc(
          'owner_kpi_summary_v1',
          params: {'p_business_id': businessId, 'p_days': 30},
        );
        if (res is Map) {
          return OwnerKpiSummary.fromMap(res.cast<String, dynamic>());
        }
        if (res is List && res.isNotEmpty && res.first is Map) {
          return OwnerKpiSummary.fromMap(
            (res.first as Map).cast<String, dynamic>(),
          );
        }
        return const OwnerKpiSummary(
          businessViews: 0,
          outboundClicks: 0,
          directionsClicks: 0,
          searchImpressions: 0,
        );
      } catch (e) {
        throw Exception(AppErrorMapper.message(e));
      }
    });
