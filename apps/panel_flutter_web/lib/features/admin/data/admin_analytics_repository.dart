import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/admin_growth_models.dart';
import '../domain/admin_kpi_models.dart';

final adminAnalyticsRepositoryProvider = Provider<AdminAnalyticsRepository>((
  ref,
) {
  final client = ref.watch(supabaseProvider);
  return AdminAnalyticsRepository(client);
});

class AdminAnalyticsRepository {
  AdminAnalyticsRepository(this.client);
  final SupabaseClient client;

  Future<List<AdminGrowthDay>> getGrowth({
    int days = 30,
    String? businessId,
  }) async {
    try {
      final res = await client.rpc(
        'analytics_growth_v1',
        params: {'p_days': days, 'p_business_id': businessId},
      );
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map((row) => AdminGrowthDay.fromMap(row.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<AdminKpiSummary> getKpiSummary({int days = 30}) async {
    try {
      final res = await client.rpc(
        'admin_kpi_summary_v1',
        params: {'p_days': days},
      );
      if (res is Map) {
        return AdminKpiSummary.fromMap(res.cast<String, dynamic>());
      }
      if (res is List && res.isNotEmpty && res.first is Map) {
        return AdminKpiSummary.fromMap(
          (res.first as Map).cast<String, dynamic>(),
        );
      }
      return const AdminKpiSummary(
        dau: 0,
        dauPrev: 0,
        wau: 0,
        wauPrev: 0,
        discoveryImpressions: 0,
        discoveryImpressionsPrev: 0,
        discoveryClicks: 0,
        discoveryClicksPrev: 0,
        discoveryCtr: 0,
        discoveryCtrPrev: 0,
        businessViews: 0,
        businessViewsPrev: 0,
        menuViews: 0,
        menuViewsPrev: 0,
        menuViewRate: 0,
        menuViewRatePrev: 0,
        priceSuggestions: 0,
        priceSuggestionsPrev: 0,
        priceVerificationRate: 0,
        priceVerificationRatePrev: 0,
        reportsAvgResolutionMinutes: 0,
        reportsAvgResolutionMinutesPrev: 0,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
