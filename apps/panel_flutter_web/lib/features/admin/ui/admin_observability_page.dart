import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../../../core/monitoring/alert_rules.dart';
import '../../../core/monitoring/request_trace.dart';
import '../../../core/perf/perf_slo.dart';
import '../../../core/storage/dev_overrides_prefs.dart';
import '../../../core/storage/feature_flags_prefs.dart';
import '../../../core/storage/offline_cache_prefs.dart';
import '../../../core/storage/product_guardrails_prefs.dart';
import '../../../shared/ui/design_system.dart';

class AdminObservabilityPage extends StatefulWidget {
  const AdminObservabilityPage({super.key});

  @override
  State<AdminObservabilityPage> createState() => _AdminObservabilityPageState();
}

class _AdminObservabilityPageState extends State<AdminObservabilityPage> {
  late Future<_PrefsSnapshot> _prefsFuture;
  final _crashFreeCtrl = TextEditingController(text: '0.997');
  final _homeTtiCtrl = TextEditingController(text: '1300');
  final _edge429CurrentCtrl = TextEditingController(text: '44');
  final _edge429BaselineCtrl = TextEditingController(text: '16');

  String _requestId = createRequestId(prefix: 'obs');

  @override
  void initState() {
    super.initState();
    _prefsFuture = _loadPrefs();
  }

  @override
  void dispose() {
    _crashFreeCtrl.dispose();
    _homeTtiCtrl.dispose();
    _edge429CurrentCtrl.dispose();
    _edge429BaselineCtrl.dispose();
    super.dispose();
  }

  Future<_PrefsSnapshot> _loadPrefs() async {
    final featureFlags = await FeatureFlagsPrefs.readAll();
    final (testUserId, testCity, testDistrict) = await DevOverridesPrefs.read();
    final guardrails = await ProductGuardrailsPrefs.read();
    final favoriteIds = await OfflineCachePrefs.loadFavoriteIds();
    final recentBusinessIds = await OfflineCachePrefs.getRecentBusinessIds();
    final categories = await OfflineCachePrefs.loadCategoriesSnapshot();
    final favoriteCachedAt = await OfflineCachePrefs
        .loadFavoriteBusinessesCachedAt();

    return _PrefsSnapshot(
      featureFlags: featureFlags,
      testUserId: testUserId,
      testCity: testCity,
      testDistrict: testDistrict,
      guardrails: guardrails,
      favoriteIdsCount: favoriteIds.length,
      recentBusinessesCount: recentBusinessIds.length,
      categoriesCount: categories.length,
      favoriteCachedAt: favoriteCachedAt,
    );
  }

  void _refreshPrefs() {
    setState(() {
      _prefsFuture = _loadPrefs();
    });
  }

  void _generateRequestId() {
    setState(() {
      _requestId = createRequestId(prefix: 'obs');
    });
  }

  double _readDouble(TextEditingController ctrl, double fallback) {
    return double.tryParse(ctrl.text.replaceAll(',', '.').trim()) ?? fallback;
  }

  int _readInt(TextEditingController ctrl, int fallback) {
    return int.tryParse(ctrl.text.trim()) ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final crashFreeRate = _readDouble(_crashFreeCtrl, 1.0);
    final homeTtiMs = _readInt(_homeTtiCtrl, 0);
    final edge429Current = _readInt(_edge429CurrentCtrl, 0);
    final edge429Baseline = _readInt(_edge429BaselineCtrl, 0);

    final crashAlert = AlertRules.shouldAlertCrashFree(crashFreeRate);
    final homeTtiAlert = AlertRules.shouldAlertHomeTtiP95(homeTtiMs);
    final edge429Alert = AlertRules.shouldAlertEdge429Spike(
      currentWindow429Count: edge429Current,
      baselineWindow429Count: edge429Baseline,
    );

    final headers = traceHeaders(_requestId);
    final payload = withRequestTrace(
      <String, Object?>{
        'surface': 'admin_observability',
        'action': 'debug_preview',
      },
      requestId: _requestId,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Observability',
            subtitle: const Text(
              'Request trace, performans hedefleri ve local prefs gorunurlugu.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            trailing: IconButton(
              onPressed: _refreshPrefs,
              icon: const Icon(Icons.refresh),
              tooltip: 'Yenile',
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Request Trace',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'request_id: $_requestId',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'headers: ${jsonEncode(headers)}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'payload: ${jsonEncode(payload)}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _generateRequestId,
                  icon: const Icon(Icons.vpn_key_outlined),
                  label: const Text('Yeni request_id uret'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Perf SLO ve Alarm Simulasyonu',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'SLO: cold<=2000ms, warm<=800ms, home_tti<=1200ms, jank<=1%',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statusChip('Crash-free', !crashAlert),
                    _statusChip('Home TTI p95', !homeTtiAlert),
                    _statusChip('Edge 429 spike', !edge429Alert),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _crashFreeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Crash-free rate (0-1)',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _homeTtiCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Home TTI p95 (ms)',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _edge429CurrentCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Edge 429 current',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _edge429BaselineCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Edge 429 baseline',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Sabitler: startup(cold=${PerfSlo.coldStartP95Ms}, warm=${PerfSlo.warmStartP95Ms}) '
                  'home_tti=${PerfSlo.homeTtiP95Ms}, '
                  'search_hit=${PerfSlo.searchCacheHitP95Ms}, '
                  'search_miss=${PerfSlo.searchCacheMissP95Ms}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: FutureBuilder<_PrefsSnapshot>(
              future: _prefsFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Text(
                    'Prefs okunamadi: ${snap.error}',
                    style: const TextStyle(color: AppColors.danger),
                  );
                }
                final data = snap.data;
                if (data == null) {
                  return const Text('Prefs verisi yok.');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prefs Explorer',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      jsonEncode({
                        'feature_flags': data.featureFlags,
                        'dev_overrides': {
                          'test_user_id': data.testUserId,
                          'test_city': data.testCity,
                          'test_district': data.testDistrict,
                        },
                        'product_guardrails': data.guardrails,
                        'offline_cache': {
                          'favorite_ids_count': data.favoriteIdsCount,
                          'recent_businesses_count': data.recentBusinessesCount,
                          'categories_count': data.categoriesCount,
                          'favorite_cached_at':
                              data.favoriteCachedAt?.toIso8601String(),
                        },
                      }),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, bool ok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ok ? AppColors.success.withValues(alpha: 0.12) : AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: ok
              ? AppColors.success.withValues(alpha: 0.35)
              : AppColors.danger.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        '$label: ${ok ? 'OK' : 'ALARM'}',
        style: TextStyle(
          color: ok ? AppColors.success : AppColors.danger,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PrefsSnapshot {
  const _PrefsSnapshot({
    required this.featureFlags,
    required this.testUserId,
    required this.testCity,
    required this.testDistrict,
    required this.guardrails,
    required this.favoriteIdsCount,
    required this.recentBusinessesCount,
    required this.categoriesCount,
    required this.favoriteCachedAt,
  });

  final Map<String, bool> featureFlags;
  final String? testUserId;
  final String? testCity;
  final String? testDistrict;
  final Map<String, Object?> guardrails;
  final int favoriteIdsCount;
  final int recentBusinessesCount;
  final int categoriesCount;
  final DateTime? favoriteCachedAt;
}
