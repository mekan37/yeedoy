import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../app/theme/colors.dart';
import '../../../core/analytics/app_events.dart';
import '../../../core/config/dev_overrides.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/config/product_guardrails.dart';
import '../../../core/quality/golden_paths.dart';
import '../../../core/quality/release_gate.dart';
import '../../../features/shared/ui/components/app_card.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../../../features/shared/ui/components/app_section_header.dart';

class DeveloperToolsPage extends ConsumerWidget {
  const DeveloperToolsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(featureFlagsProvider);
    final overrides = ref.watch(devOverridesProvider);
    final envRows = const [
      'SUPABASE_URL',
      'SUPABASE_ANON_KEY',
      'STORAGE_BUCKET_PUBLIC',
      'BASE_URL_WEB_NEXT',
      'BASE_URL_PANEL',
      'DEV_TOOLS_ENABLED',
    ].map((k) {
      final value = dotenv.env[k];
      final ok = (value ?? '').trim().isNotEmpty;
      final preview = ok ? '${value!.substring(0, value.length > 8 ? 8 : value.length)}...' : '(missing)';
      return (k, ok, preview);
    }).toList();
    final release = ReleaseGate.evaluate(
      const ReleaseMetricsSnapshot(
        crashFreeRate: 0.998,
        jankRate: 0.008,
        startupP95Ms: 1150,
        homeTtiP95Ms: 980,
        searchHitP95Ms: 220,
        searchMissP95Ms: 610,
      ),
    );

    final emitted = <String>[
      AppEvents.homeView,
      AppEvents.categoryClick,
      AppEvents.businessOpen,
      AppEvents.menuOpen,
      AppEvents.verifyPriceSubmit,
    ];

    final homeGolden = GoldenPaths.containsAll(
      requiredEvents: GoldenPaths.homeToVerifySuccess,
      emittedEvents: emitted,
    );

    return AppScaffold(
      appBar: AppBar(title: const Text('Developer Tools')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppSectionHeader(title: 'Release Checklist'),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv('Allow release', release.allowRelease ? 'Yes' : 'No'),
                _kv(
                  'Require rollback',
                  release.requireRollback ? 'Yes' : 'No',
                ),
                _kv('Reasons', release.reasons.isEmpty ? 'None' : release.reasons.join(', ')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const AppSectionHeader(title: 'Golden Paths'),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv('Home > Verify path', homeGolden ? 'OK' : 'Missing events'),
                const SizedBox(height: 6),
                for (final e in GoldenPaths.homeToVerifySuccess)
                  Text('• $e', style: const TextStyle(color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const AppSectionHeader(title: 'Feature Flags'),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                for (final def in featureFlagDefs)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(def.label),
                    subtitle: Text(def.description),
                    value: flags.localFlags[def.flag] ?? def.defaultValue,
                    onChanged: (v) => ref
                        .read(featureFlagsProvider.notifier)
                        .setFlag(def.flag, v),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const AppSectionHeader(title: 'Dev Overrides'),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv('Test user', overrides.testUserId ?? '-'),
                _kv('Test city', overrides.testCity ?? '-'),
                _kv('Test district', overrides.testDistrict ?? '-'),
                _kv(
                  'Sponsored trust threshold',
                  ProductGuardrails.minSponsoredTrustScore.toStringAsFixed(2),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () =>
                      ref.read(devOverridesProvider.notifier).clearAll(),
                  child: const Text('Reset overrides'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const AppSectionHeader(title: 'Environment Check'),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final row in envRows)
                  _kv(row.$1, row.$2 ? 'ok (${row.$3})' : row.$3),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const AppSectionHeader(title: 'Analytics Event Catalog'),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('• home_view'),
                Text('• category_click'),
                Text('• search_submit'),
                Text('• business_open'),
                Text('• menu_open'),
                Text('• verify_price_submit'),
                Text('• review_submit'),
                Text('• achievement_unlock'),
                Text('• notification_open'),
                Text('• app_start_ms'),
                Text('• home_tti_ms'),
                Text('• search_latency_ms'),
                Text('• frame_jank_rate'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(key, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
