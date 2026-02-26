import '../perf/perf_slo.dart';

class ReleaseMetricsSnapshot {
  const ReleaseMetricsSnapshot({
    required this.crashFreeRate,
    required this.jankRate,
    required this.startupP95Ms,
    required this.homeTtiP95Ms,
    required this.searchHitP95Ms,
    required this.searchMissP95Ms,
  });

  final double crashFreeRate;
  final double jankRate;
  final int startupP95Ms;
  final int homeTtiP95Ms;
  final int searchHitP95Ms;
  final int searchMissP95Ms;
}

class ReleaseGateResult {
  const ReleaseGateResult({
    required this.allowRelease,
    required this.requireRollback,
    required this.reasons,
  });

  final bool allowRelease;
  final bool requireRollback;
  final List<String> reasons;
}

class ReleaseGate {
  const ReleaseGate._();

  static const double minCrashFreeRate = 0.998;

  static ReleaseGateResult evaluate(ReleaseMetricsSnapshot metrics) {
    final reasons = <String>[];
    var requireRollback = false;

    if (metrics.crashFreeRate < minCrashFreeRate) {
      reasons.add(
        'crash_free_below_threshold: ${metrics.crashFreeRate.toStringAsFixed(4)} < ${minCrashFreeRate.toStringAsFixed(4)}',
      );
    }

    if (metrics.jankRate > PerfSlo.maxJankRate) {
      reasons.add(
        'jank_rate_above_threshold: ${metrics.jankRate.toStringAsFixed(4)} > ${PerfSlo.maxJankRate.toStringAsFixed(4)}',
      );
    }

    if (metrics.startupP95Ms > PerfSlo.coldStartP95Ms) {
      requireRollback = true;
      reasons.add(
        'startup_p95_above_slo: ${metrics.startupP95Ms} > ${PerfSlo.coldStartP95Ms}',
      );
    }
    if (metrics.homeTtiP95Ms > PerfSlo.homeTtiP95Ms) {
      requireRollback = true;
      reasons.add(
        'home_tti_p95_above_slo: ${metrics.homeTtiP95Ms} > ${PerfSlo.homeTtiP95Ms}',
      );
    }
    if (metrics.searchHitP95Ms > PerfSlo.searchCacheHitP95Ms) {
      requireRollback = true;
      reasons.add(
        'search_hit_p95_above_slo: ${metrics.searchHitP95Ms} > ${PerfSlo.searchCacheHitP95Ms}',
      );
    }
    if (metrics.searchMissP95Ms > PerfSlo.searchCacheMissP95Ms) {
      requireRollback = true;
      reasons.add(
        'search_miss_p95_above_slo: ${metrics.searchMissP95Ms} > ${PerfSlo.searchCacheMissP95Ms}',
      );
    }

    return ReleaseGateResult(
      allowRelease: reasons.isEmpty,
      requireRollback: requireRollback,
      reasons: reasons,
    );
  }
}
