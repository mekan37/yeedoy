import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../app/theme/colors.dart';
import '../../../core/analytics/app_events.dart';
import '../../../core/config/dev_overrides.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/config/product_guardrails.dart';
import '../../../core/quality/golden_paths.dart';
import '../../../core/quality/release_gate.dart';
import '../../../core/storage/local_db/local_db_models.dart';
import '../../../core/storage/local_db/local_db_provider.dart';
import '../../../core/storage/offline_mutation_queue.dart';
import '../../../core/storage/offline_queue_diagnostics.dart';
import '../../../core/storage/offline_submission_queue.dart';
import '../../notifications/domain/notification_target_path_resolver.dart';
import '../../notifications/domain/push_notification_service.dart';
import '../../menus/data/menu_repository.dart';
import '../../../features/shared/ui/components/app_card.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../../../features/shared/ui/components/app_section_header.dart';

final offlineQueueDiagnosticsProvider =
    FutureProvider<OfflineQueueDiagnosticsSummary>((ref) async {
      final items = await OfflineMutationQueueStore.readAll(limit: 300);
      return buildOfflineQueueDiagnosticsSummary(items);
});

typedef _LocalDbSnapshotCounts =
    ({int discoveryFeed, int businessSnapshot, int menuSnapshot, int total});

final localDbSnapshotCountsProvider = FutureProvider<_LocalDbSnapshotCounts>((
  ref,
) async {
  final store = ref.read(localDbStoreProvider);
  final discovery = await store.list(
    LocalDbBucket.discoveryFeed,
    limit: 500,
    allowExpired: true,
  );
  final business = await store.list(
    LocalDbBucket.businessSnapshot,
    limit: 500,
    allowExpired: true,
  );
  final menu = await store.list(
    LocalDbBucket.menuSnapshot,
    limit: 500,
    allowExpired: true,
  );
  return (
    discoveryFeed: discovery.length,
    businessSnapshot: business.length,
    menuSnapshot: menu.length,
    total: discovery.length + business.length + menu.length,
  );
});

const _devToolsBusinessId = '11111111-1111-4111-8111-111111111111';
const _devToolsMenuItemId = '33333333-3333-4333-8333-333333333333';

class DeveloperToolsPage extends ConsumerWidget {
  const DeveloperToolsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(featureFlagsProvider);
    final overrides = ref.watch(devOverridesProvider);
    String? safeEnvValue(String key) {
      try {
        return dotenv.env[key];
      } catch (_) {
        return null;
      }
    }

    final envRows =
        const [
          'SUPABASE_URL',
          'SUPABASE_ANON_KEY',
          'STORAGE_BUCKET_PUBLIC',
          'BASE_URL_WEB_NEXT',
          'BASE_URL_PANEL',
          'DEV_TOOLS_ENABLED',
        ].map((k) {
          final value = safeEnvValue(k);
          final ok = (value ?? '').trim().isNotEmpty;
          final preview = ok
              ? '${value!.substring(0, value.length > 8 ? 8 : value.length)}...'
              : '(missing)';
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
        embedOpenP95Ms: 850,
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
                _kv('Require rollback', release.requireRollback ? 'Yes' : 'No'),
                _kv(
                  'Reasons',
                  release.reasons.isEmpty ? 'None' : release.reasons.join(', '),
                ),
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
          const AppSectionHeader(title: 'Offline Queues'),
          const SizedBox(height: 8),
          const _OfflineQueuesCard(),
          const SizedBox(height: 12),
          const AppSectionHeader(title: 'Offline Snapshots'),
          const SizedBox(height: 8),
          const _OfflineSnapshotsCard(),
          const SizedBox(height: 12),
          const AppSectionHeader(title: 'Push Payload Simulator'),
          const SizedBox(height: 8),
          const _PushPayloadSimulatorCard(),
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
                Text('• price_change_push_open'),
                Text('• comment_reply_push_open'),
                Text('• app_start_ms'),
                Text('• home_tti_ms'),
                Text('• search_latency_ms'),
                Text('• embed_open_ms'),
                Text('• frame_jank_rate'),
                Text('• offline_sync_run'),
                Text('• offline_mutation_outcome'),
                Text('• connectivity_restored'),
                Text('• connectivity_state_change'),
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
            child: Text(
              key,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _OfflineQueuesCard extends ConsumerStatefulWidget {
  const _OfflineQueuesCard();

  @override
  ConsumerState<_OfflineQueuesCard> createState() => _OfflineQueuesCardState();
}

class _OfflineQueuesCardState extends ConsumerState<_OfflineQueuesCard> {
  bool _flushingVerify = false;
  bool _flushingSubmission = false;

  @override
  Widget build(BuildContext context) {
    final diagnosticsAsync = ref.watch(offlineQueueDiagnosticsProvider);
    final diagnostics = diagnosticsAsync.asData?.value;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv(
            'Verify queue',
            _summaryText(
              diagnosticsAsync,
              diagnostics == null ? null : '${diagnostics.verifyCount}',
            ),
          ),
          _kv(
            'Submission queue',
            _summaryText(
              diagnosticsAsync,
              diagnostics == null ? null : '${diagnostics.submissionCount}',
            ),
          ),
          _kv(
            'Total queued',
            _summaryText(
              diagnosticsAsync,
              diagnostics == null ? null : '${diagnostics.total}',
            ),
          ),
          _kv(
            'Retrying',
            _summaryText(
              diagnosticsAsync,
              diagnostics == null ? null : '${diagnostics.retryingCount}',
            ),
          ),
          _kv(
            'Pending first-try',
            _summaryText(
              diagnosticsAsync,
              diagnostics == null ? null : '${diagnostics.pendingCount}',
            ),
          ),
          _kv(
            'Blocked until retry',
            _summaryText(
              diagnosticsAsync,
              diagnostics == null ? null : '${diagnostics.blockedCount}',
            ),
          ),
          _kv(
            'Ready now',
            _summaryText(
              diagnosticsAsync,
              diagnostics == null ? null : '${diagnostics.readyCount}',
            ),
          ),
          _kv(
            'Next retry',
            _summaryText(
              diagnosticsAsync,
              _formatDateTime(diagnostics?.nextRetryAt),
            ),
          ),
          _kv(
            'Oldest queued',
            _summaryText(
              diagnosticsAsync,
              _formatDateTime(diagnostics?.oldestCreatedAt),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _flushingVerify ? null : _flushVerifyQueue,
                  child: Text(
                    _flushingVerify
                        ? 'Flushing verify...'
                        : 'Flush verify queue',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _flushingSubmission ? null : _flushSubmissionQueue,
                  child: Text(
                    _flushingSubmission
                        ? 'Flushing submit...'
                        : 'Flush submission queue',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_flushingVerify || _flushingSubmission)
                  ? null
                  : _flushAllQueues,
              child: const Text('Flush all queues'),
            ),
          ),
          const SizedBox(height: 12),
          if (diagnosticsAsync.isLoading)
            const Text(
              'Loading queue diagnostics...',
              style: TextStyle(color: AppColors.muted),
            )
          else if (diagnosticsAsync.hasError)
            const Text(
              'Queue diagnostics could not be loaded.',
              style: TextStyle(color: AppColors.danger),
            )
          else if (diagnostics == null || diagnostics.total == 0)
            const Text(
              'No queued mutations.',
              style: TextStyle(color: AppColors.muted),
            )
          else ...[
            if (diagnostics.errorBuckets.isNotEmpty) ...[
              const Text(
                'Top retry reasons',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (final bucket in diagnostics.errorBuckets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• ${bucket.count}x ${bucket.message}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              const SizedBox(height: 8),
            ],
            const Text(
              'Conflict policy',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final rule in offlineQueuePolicyRules) ...[
              Text(
                '• ${rule.title}: ${rule.description}',
                style: const TextStyle(color: AppColors.muted),
              ),
              if (rule != offlineQueuePolicyRules.last)
                const SizedBox(height: 4),
            ],
            const SizedBox(height: 8),
            const Text(
              'Attention items',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final item in diagnostics.visibleItems) ...[
              _OfflineQueueItemTile(item: item),
              if (item != diagnostics.visibleItems.last) const SizedBox(height: 8),
            ],
          ],
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
            child: Text(
              key,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _summaryText(AsyncValue<dynamic> async, String? value) {
    return async.when(
      data: (_) => value ?? '-',
      loading: () => value == null ? 'loading...' : '$value (loading...)',
      error: (_, _) => value == null ? 'error' : '$value (error)',
    );
  }

  Future<void> _flushVerifyQueue() async {
    setState(() => _flushingVerify = true);
    try {
      final sent = await ref
          .read(menuRepositoryProvider)
          .flushOfflineVerifyQueue();
      _refreshCounts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verify queue flushed: $sent item(s) sent.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Verify queue flush failed: $e')));
    } finally {
      if (mounted) setState(() => _flushingVerify = false);
    }
  }

  Future<void> _flushSubmissionQueue() async {
    setState(() => _flushingSubmission = true);
    try {
      final client = ref.read(supabaseProvider);
      final sent = await flushOfflineSubmissionQueue(client);
      _refreshCounts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission queue flushed: $sent item(s) sent.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission queue flush failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _flushingSubmission = false);
    }
  }

  Future<void> _flushAllQueues() async {
    setState(() {
      _flushingVerify = true;
      _flushingSubmission = true;
    });
    try {
      final verifySent = await ref
          .read(menuRepositoryProvider)
          .flushOfflineVerifyQueue();
      final submissionSent = await flushOfflineSubmissionQueue(
        ref.read(supabaseProvider),
      );
      _refreshCounts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All queues flushed. verify=$verifySent, submission=$submissionSent',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Flush all failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _flushingVerify = false;
          _flushingSubmission = false;
        });
      }
    }
  }

  void _refreshCounts() {
    ref.invalidate(offlineQueueDiagnosticsProvider);
  }
}

class _OfflineQueueItemTile extends StatelessWidget {
  const _OfflineQueueItemTile({required this.item});

  final OfflineQueueDiagnosticItem item;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (item.status) {
      OfflineMutationQueueStatus.pending => AppColors.info,
      OfflineMutationQueueStatus.retrying => item.readyNow
          ? AppColors.warning
          : AppColors.danger,
    };
    final statusText = item.status == OfflineMutationQueueStatus.retrying
        ? (item.readyNow ? 'Retry ready' : 'Waiting retry')
        : 'Pending';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(item.target, style: const TextStyle(color: AppColors.muted)),
            if ((item.detail ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(item.detail!, style: const TextStyle(color: AppColors.muted)),
            ],
            const SizedBox(height: 8),
            _metaRow('Queued', _formatDateTime(item.createdAt)),
            _metaRow('Retries', '${item.retryCount}'),
            _metaRow('Last attempt', _formatDateTime(item.lastAttemptAt)),
            _metaRow('Next retry', _formatDateTime(item.nextRetryAt)),
            if ((item.operatorAction ?? '').trim().isNotEmpty)
              _metaRow('Suggested action', item.operatorAction!),
            if ((item.lastError ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Last error: ${item.lastError}',
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metaRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              key,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _OfflineSnapshotsCard extends ConsumerStatefulWidget {
  const _OfflineSnapshotsCard();

  @override
  ConsumerState<_OfflineSnapshotsCard> createState() =>
      _OfflineSnapshotsCardState();
}

class _OfflineSnapshotsCardState extends ConsumerState<_OfflineSnapshotsCard> {
  bool _pruning = false;

  @override
  Widget build(BuildContext context) {
    final countsAsync = ref.watch(localDbSnapshotCountsProvider);
    final counts = countsAsync.asData?.value;

    String valueFor(int? value) {
      return value == null ? '-' : '$value';
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv('Discovery feed', valueFor(counts?.discoveryFeed)),
          _kv('Business snapshots', valueFor(counts?.businessSnapshot)),
          _kv('Menu snapshots', valueFor(counts?.menuSnapshot)),
          _kv('Total stored', valueFor(counts?.total)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _pruning ? null : _pruneExpiredSnapshots,
              child: Text(
                _pruning ? 'Pruning snapshots...' : 'Prune expired snapshots',
              ),
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
            child: Text(
              key,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _pruneExpiredSnapshots() async {
    setState(() => _pruning = true);
    try {
      final removed = await ref.read(localDbStoreProvider).pruneExpired();
      ref.invalidate(localDbSnapshotCountsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Expired snapshots pruned: $removed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Snapshot prune failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _pruning = false);
    }
  }
}

class _PushPayloadSimulatorCard extends ConsumerWidget {
  const _PushPayloadSimulatorCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final samples = <_PushPayloadSample>[
      const _PushPayloadSample(
        label: 'Simulate price change push',
        actionLabel: 'Run price change sample',
        description: 'favorite_price_changed -> menu item detail route',
        payload: {
          'type': 'favorite_price_changed',
          'business_id': _devToolsBusinessId,
          'menu_item_id': _devToolsMenuItemId,
        },
      ),
      const _PushPayloadSample(
        label: 'Simulate review reply push',
        actionLabel: 'Run review reply sample',
        description: 'review_reply -> business reviews route',
        payload: {
          'type': 'review_reply',
          'business_id': _devToolsBusinessId,
        },
      ),
      const _PushPayloadSample(
        label: 'Simulate business alert push',
        actionLabel: 'Run business alert sample',
        description: 'owner_business_reported -> business detail route',
        payload: {
          'type': 'owner_business_reported',
          'business_id': _devToolsBusinessId,
        },
      ),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Routes are resolved with the same payload parser used by push taps.',
          ),
          const SizedBox(height: 12),
          for (final sample in samples) ...[
            _PushPayloadSampleTile(sample: sample),
            if (sample != samples.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}

class _PushPayloadSampleTile extends ConsumerWidget {
  const _PushPayloadSampleTile({required this.sample});

  final _PushPayloadSample sample;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetRoute = resolvePushTapRoute(sample.payload) ?? '(invalid)';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sample.label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              sample.description,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 6),
            Text('Target route: $targetRoute'),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () => ref
                    .read(pushNotificationServiceProvider)
                    .simulatePushPayload(sample.payload),
                child: Text(sample.actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PushPayloadSample {
  const _PushPayloadSample({
    required this.label,
    required this.actionLabel,
    required this.description,
    required this.payload,
  });

  final String label;
  final String actionLabel;
  final String description;
  final Map<String, dynamic> payload;
}
