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
  static const double minCrashFreeRate = 0.997;
  static const double maxJankRate = 0.01;
  static const int maxStartupP95Ms = 2000;
  static const int maxHomeTtiP95Ms = 1200;
  static const int maxSearchHitP95Ms = 300;
  static const int maxSearchMissP95Ms = 800;

  static ReleaseGateResult evaluate(ReleaseMetricsSnapshot snapshot) {
    final reasons = <String>[];
    var requireRollback = false;

    if (snapshot.crashFreeRate < minCrashFreeRate) {
      reasons.add(
        'crash_free_below_threshold:${snapshot.crashFreeRate.toStringAsFixed(4)}<$minCrashFreeRate',
      );
    }
    if (snapshot.jankRate > maxJankRate) {
      reasons.add(
        'jank_rate_above_threshold:${snapshot.jankRate.toStringAsFixed(4)}>$maxJankRate',
      );
    }

    if (snapshot.startupP95Ms > maxStartupP95Ms) {
      reasons.add(
        'startup_p95_above_slo:${snapshot.startupP95Ms}>$maxStartupP95Ms',
      );
      requireRollback = true;
    }
    if (snapshot.homeTtiP95Ms > maxHomeTtiP95Ms) {
      reasons.add(
        'home_tti_p95_above_slo:${snapshot.homeTtiP95Ms}>$maxHomeTtiP95Ms',
      );
      requireRollback = true;
    }
    if (snapshot.searchHitP95Ms > maxSearchHitP95Ms) {
      reasons.add(
        'search_hit_p95_above_slo:${snapshot.searchHitP95Ms}>$maxSearchHitP95Ms',
      );
      requireRollback = true;
    }
    if (snapshot.searchMissP95Ms > maxSearchMissP95Ms) {
      reasons.add(
        'search_miss_p95_above_slo:${snapshot.searchMissP95Ms}>$maxSearchMissP95Ms',
      );
      requireRollback = true;
    }

    return ReleaseGateResult(
      allowRelease: reasons.isEmpty,
      requireRollback: requireRollback,
      reasons: reasons,
    );
  }
}
