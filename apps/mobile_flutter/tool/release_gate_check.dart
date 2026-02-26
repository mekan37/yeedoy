import 'dart:convert';
import 'dart:io';

import 'package:yeedoy/core/quality/release_gate.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/release_gate_check.dart <metrics.json>',
    );
    exitCode = 64;
    return;
  }

  final path = args.first;
  final file = File(path);
  if (!await file.exists()) {
    stderr.writeln('Metrics file not found: $path');
    exitCode = 66;
    return;
  }

  final raw = await file.readAsString();
  final json = jsonDecode(raw);
  if (json is! Map<String, dynamic>) {
    stderr.writeln('Invalid JSON payload: expected object');
    exitCode = 65;
    return;
  }

  final metrics = ReleaseMetricsSnapshot(
    crashFreeRate: (json['crash_free_rate'] as num?)?.toDouble() ?? 0,
    jankRate: (json['jank_rate'] as num?)?.toDouble() ?? 1,
    startupP95Ms: (json['startup_p95_ms'] as num?)?.toInt() ?? 999999,
    homeTtiP95Ms: (json['home_tti_p95_ms'] as num?)?.toInt() ?? 999999,
    searchHitP95Ms: (json['search_hit_p95_ms'] as num?)?.toInt() ?? 999999,
    searchMissP95Ms: (json['search_miss_p95_ms'] as num?)?.toInt() ?? 999999,
  );

  final result = ReleaseGate.evaluate(metrics);
  final securityResult = _evaluateSecurity(json);
  final releaseOpsResult = _evaluateReleaseOps(json);
  final blockedBySecurity = securityResult.isNotEmpty;
  final blockedByReleaseOps = releaseOpsResult.reasons.isNotEmpty;

  if (result.allowRelease && !blockedBySecurity && !blockedByReleaseOps) {
    stdout.writeln('RELEASE_GATE: PASS');
    if (releaseOpsResult.nextStagePercent != null) {
      stdout.writeln(
        'ACTION: ROLLOUT_NEXT_STAGE_${releaseOpsResult.nextStagePercent}',
      );
    }
    return;
  }

  stdout.writeln('RELEASE_GATE: BLOCK');
  for (final reason in result.reasons) {
    stdout.writeln('- $reason');
  }
  if (result.requireRollback) {
    stdout.writeln('ACTION: ROLLBACK_RECOMMENDED');
  }
  for (final reason in securityResult) {
    stdout.writeln('- security_$reason');
  }
  for (final reason in releaseOpsResult.reasons) {
    stdout.writeln('- release_ops_$reason');
  }
  if (releaseOpsResult.requireAutoRollback) {
    stdout.writeln('ACTION: AUTO_ROLLBACK_TRIGGER');
  }
  exitCode = 1;
}

class _ReleaseOpsResult {
  const _ReleaseOpsResult({
    required this.reasons,
    required this.requireAutoRollback,
    required this.nextStagePercent,
  });

  final List<String> reasons;
  final bool requireAutoRollback;
  final int? nextStagePercent;
}

_ReleaseOpsResult _evaluateReleaseOps(Map<String, dynamic> json) {
  final reasons = <String>[];
  var requireAutoRollback = false;

  final releaseOps = (json['release_ops'] is Map<String, dynamic>)
      ? (json['release_ops'] as Map<String, dynamic>)
      : <String, dynamic>{};

  bool readBool(String key) => releaseOps[key] == true;
  int readInt(String key, int fallback) =>
      (releaseOps[key] as num?)?.toInt() ?? fallback;
  double readDouble(String key, double fallback) =>
      (releaseOps[key] as num?)?.toDouble() ?? fallback;

  if (!readBool('backend_feature_flags')) {
    reasons.add('backend_feature_flags_missing');
  }
  if (!readBool('kill_switch_ready')) {
    reasons.add('kill_switch_missing');
  }
  if (!readBool('api_versioning_enforced')) {
    reasons.add('api_versioning_missing');
  }

  final currentPercent = readInt('current_rollout_percent', 100);
  final stagesRaw =
      (releaseOps['stages'] as List?)
          ?.map((e) => int.tryParse(e.toString()) ?? -1)
          .where((e) => e >= 0 && e <= 100)
          .toList() ??
      const <int>[1, 5, 20, 100];
  final stages = stagesRaw.isEmpty ? const <int>[1, 5, 20, 100] : stagesRaw;
  final nextStage = stages.firstWhere(
    (stage) => stage > currentPercent,
    orElse: () => currentPercent,
  );
  final hasNextStage = nextStage > currentPercent;

  final crashFree = readDouble('crash_free_rate', 1);
  final jankRate = readDouble('jank_rate', 0);
  final homeTtiP95Ms = readInt('home_tti_p95_ms', 0);
  final edge429Rate = readDouble('edge_429_rate', 0);

  final healthyCanary =
      crashFree >= 0.997 &&
      jankRate <= 0.01 &&
      homeTtiP95Ms <= 1200 &&
      edge429Rate <= 0.03;

  if (!healthyCanary) {
    reasons.add('canary_unhealthy');
    requireAutoRollback = currentPercent > 1;
  }

  final nextStagePercent = (healthyCanary && hasNextStage) ? nextStage : null;

  return _ReleaseOpsResult(
    reasons: reasons,
    requireAutoRollback: requireAutoRollback,
    nextStagePercent: nextStagePercent,
  );
}

List<String> _evaluateSecurity(Map<String, dynamic> json) {
  final reasons = <String>[];
  final security = (json['security'] is Map<String, dynamic>)
      ? (json['security'] as Map<String, dynamic>)
      : <String, dynamic>{};

  bool readBool(String key) {
    final value = security[key];
    return value == true;
  }

  if (!readBool('zero_trust_write')) {
    reasons.add('zero_trust_write_missing');
  }
  if (!readBool('waf_ip_reputation')) {
    reasons.add('waf_ip_reputation_missing');
  }
  if (!readBool('device_fingerprint_soft')) {
    reasons.add('device_fingerprint_soft_missing');
  }
  if (!readBool('pii_minimized')) {
    reasons.add('pii_minimized_missing');
  }
  if (!readBool('security_review_checklist_done')) {
    reasons.add('security_review_not_completed');
  }
  return reasons;
}

