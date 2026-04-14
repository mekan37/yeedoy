import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_analytics_repository.dart';
import 'admin_kpi_models.dart';

final adminKpiSummaryProvider = FutureProvider<AdminKpiSummary>((ref) async {
  final repo = ref.watch(adminAnalyticsRepositoryProvider);
  return repo.fetchKpiSummary(days: 30);
});
