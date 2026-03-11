import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/admin_b2b_export_catalog.dart';

final adminB2bExportsRepositoryProvider = Provider<AdminB2bExportsRepository>((
  ref,
) {
  final client = ref.watch(supabaseProvider);
  return AdminB2bExportsRepository(client);
});

class AdminB2bExportsRepository {
  AdminB2bExportsRepository(this.client);

  final SupabaseClient client;

  Future<String> exportCsv({
    required AdminB2bExportKind kind,
    int days = 30,
    double anomalyThresholdPct = 40,
  }) {
    return switch (kind) {
      AdminB2bExportKind.anonymousTrends => exportAnonymousTrendsCsv(days: days),
      AdminB2bExportKind.regionalPriceIndex => exportRegionalPriceIndexCsv(
          days: days,
        ),
      AdminB2bExportKind.menuInflation => exportMenuInflationCsv(days: days),
      AdminB2bExportKind.priceAnomalies => exportPriceAnomaliesCsv(
          days: days,
          thresholdPct: anomalyThresholdPct,
        ),
    };
  }

  Future<String> exportAnonymousTrendsCsv({int days = 30}) async {
    try {
      final res = await client.rpc(
        'admin_export_anonymous_trends_csv_v1',
        params: {'p_days': days},
      );
      return (res ?? '').toString();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<String> exportRegionalPriceIndexCsv({int days = 30}) async {
    try {
      final res = await client.rpc(
        'admin_export_regional_price_index_csv_v1',
        params: {'p_days': days},
      );
      return (res ?? '').toString();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<String> exportMenuInflationCsv({int days = 30}) async {
    try {
      final res = await client.rpc(
        'admin_export_menu_inflation_csv_v1',
        params: {'p_days': days},
      );
      return (res ?? '').toString();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<String> exportPriceAnomaliesCsv({
    int days = 30,
    double thresholdPct = 40,
  }) async {
    try {
      final res = await client.rpc(
        'admin_export_price_anomalies_csv_v1',
        params: {'p_days': days, 'p_threshold_pct': thresholdPct},
      );
      return (res ?? '').toString();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
