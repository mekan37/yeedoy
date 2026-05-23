import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/core/kalite/surum_kapisi.dart';

void main() {
  test('allows release when all KPIs are within thresholds', () {
    const snapshot = ReleaseMetricsSnapshot(
      crashFreeRate: 0.998,
      jankRate: 0.009,
      startupP95Ms: 1800,
      homeTtiP95Ms: 1000,
      searchHitP95Ms: 220,
      searchMissP95Ms: 700,
      embedOpenP95Ms: 900,
    );

    final result = ReleaseGate.evaluate(snapshot);
    expect(result.allowRelease, isTrue);
    expect(result.requireRollback, isFalse);
    expect(result.reasons, isEmpty);
  });

  test('blocks release when crash-free drops below 99.7%', () {
    const snapshot = ReleaseMetricsSnapshot(
      crashFreeRate: 0.996,
      jankRate: 0.005,
      startupP95Ms: 1500,
      homeTtiP95Ms: 1000,
      searchHitP95Ms: 200,
      searchMissP95Ms: 700,
      embedOpenP95Ms: 900,
    );

    final result = ReleaseGate.evaluate(snapshot);
    expect(result.allowRelease, isFalse);
    expect(
      result.reasons.any((r) => r.contains('crash_free_below_threshold')),
      isTrue,
    );
  });

  test('blocks release when jank rate exceeds 1%', () {
    const snapshot = ReleaseMetricsSnapshot(
      crashFreeRate: 0.999,
      jankRate: 0.012,
      startupP95Ms: 1500,
      homeTtiP95Ms: 1000,
      searchHitP95Ms: 200,
      searchMissP95Ms: 700,
      embedOpenP95Ms: 900,
    );

    final result = ReleaseGate.evaluate(snapshot);
    expect(result.allowRelease, isFalse);
    expect(
      result.reasons.any((r) => r.contains('jank_rate_above_threshold')),
      isTrue,
    );
  });

  test('requires rollback when latency p95 exceeds SLO', () {
    const snapshot = ReleaseMetricsSnapshot(
      crashFreeRate: 0.999,
      jankRate: 0.005,
      startupP95Ms: 2200,
      homeTtiP95Ms: 1300,
      searchHitP95Ms: 350,
      searchMissP95Ms: 900,
      embedOpenP95Ms: 1900,
    );

    final result = ReleaseGate.evaluate(snapshot);
    expect(result.allowRelease, isFalse);
    expect(result.requireRollback, isTrue);
    expect(result.reasons, isNotEmpty);
  });
}

