import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/analytics_client.dart';
import '../analytics/app_events.dart';
import '../analytics/analytics_repository.dart';
import '../network/supabase_provider.dart';

enum GrowthExperiment { homeCategoryLayout, verifyPriceCtaPlacement }

class GrowthExperiments {
  const GrowthExperiments({
    required this.subjectId,
    required this.remoteConfig,
  });

  final String subjectId;
  final Map<String, dynamic> remoteConfig;

  String variantOf(GrowthExperiment experiment) {
    final key = _key(experiment);
    final raw = remoteConfig[key];
    if (raw is! Map<String, dynamic>) {
      return _defaultVariant(experiment);
    }
    final enabled = raw['enabled'] == true;
    if (!enabled) return _defaultVariant(experiment);
    final variants =
        (raw['variants'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    if (variants.isEmpty) return _defaultVariant(experiment);
    final bucket = _stableBucket('$subjectId:$key');
    var cumulative = 0;
    for (final entry in variants.entries) {
      final pct = (entry.value as num?)?.toInt() ?? 0;
      if (pct <= 0) continue;
      cumulative += pct;
      if (bucket < cumulative) return entry.key;
    }
    return _defaultVariant(experiment);
  }

  static String _key(GrowthExperiment experiment) {
    switch (experiment) {
      case GrowthExperiment.homeCategoryLayout:
        return 'home_category_layout';
      case GrowthExperiment.verifyPriceCtaPlacement:
        return 'verify_price_cta_placement';
    }
  }

  static String _defaultVariant(GrowthExperiment experiment) {
    switch (experiment) {
      case GrowthExperiment.homeCategoryLayout:
        return 'horizontal';
      case GrowthExperiment.verifyPriceCtaPlacement:
        return 'bottom';
    }
  }

  static int _stableBucket(String input) {
    var hash = 2166136261;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash % 100;
  }
}

final growthExperimentsProvider = FutureProvider<GrowthExperiments>((
  ref,
) async {
  final client = ref.watch(supabaseProvider);
  final userId = client.auth.currentUser?.id;
  final clientId = await getAnalyticsClientId();
  final subject = (userId ?? clientId).trim();

  var config = <String, dynamic>{};
  try {
    final res = await client.rpc(
      'get_runtime_experiments_v1',
      params: {'p_user_id': userId},
    );
    if (res is Map) {
      config = res.cast<String, dynamic>();
    }
  } catch (_) {
    // Backend override is optional.
  }

  return GrowthExperiments(subjectId: subject, remoteConfig: config);
});

Future<void> logExperimentExposure(
  AnalyticsRepository analytics, {
  required GrowthExperiment experiment,
  required String variant,
  String? source,
}) async {
  final clientId = await getAnalyticsClientId();
  await analytics.logEvent(
    eventName: AppEvents.experimentExposure,
    source: source,
    clientId: clientId,
    meta: {'experiment': experiment.name, 'variant': variant},
  );
}
