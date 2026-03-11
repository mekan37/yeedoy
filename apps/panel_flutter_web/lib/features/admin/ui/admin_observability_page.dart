import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/monitoring/alert_rules.dart';
import '../../../core/monitoring/request_trace.dart';
import '../../../core/perf/perf_slo.dart';
import '../../../core/storage/dev_overrides_prefs.dart';
import '../../../core/storage/feature_flags_prefs.dart';
import '../../../core/storage/offline_cache_prefs.dart';
import '../../../core/storage/product_guardrails_prefs.dart';
import '../../../shared/ui/design_system.dart';
import '../data/admin_observability_repository.dart';
import '../domain/admin_offline_mutation_alert_settings.dart';
import '../domain/admin_offline_mutation_alerts.dart';
import '../domain/admin_observability_models.dart';

class AdminObservabilityPage extends ConsumerStatefulWidget {
  const AdminObservabilityPage({super.key});

  @override
  ConsumerState<AdminObservabilityPage> createState() =>
      _AdminObservabilityPageState();
}

class _AdminObservabilityPageState
    extends ConsumerState<AdminObservabilityPage> {
  static const List<int> _offlineWindows = <int>[6, 24, 72];
  static const int _offlineOutcomeLimit = 120;

  late Future<_PrefsSnapshot> _prefsFuture;
  late Future<List<AdminOfflineMutationOutcome>> _offlineOutcomesFuture;
  final _crashFreeCtrl = TextEditingController(text: '0.997');
  final _homeTtiCtrl = TextEditingController(text: '1300');
  final _edge429CurrentCtrl = TextEditingController(text: '44');
  final _edge429BaselineCtrl = TextEditingController(text: '16');
  final _minSignalCtrl = TextEditingController();
  final _retryWarnCtrl = TextEditingController();
  final _retryAlarmCtrl = TextEditingController();
  final _dropWarnCtrl = TextEditingController();
  final _dropAlarmCtrl = TextEditingController();
  final _attentionWarnCtrl = TextEditingController();
  final _authAlarmCtrl = TextEditingController();
  final _serverAlarmCtrl = TextEditingController();
  final _rateLimitWarnCtrl = TextEditingController();
  final _warningWindowsCtrl = TextEditingController();
  final _alarmWindowsCtrl = TextEditingController();

  String _requestId = createRequestId(prefix: 'obs');
  int _offlineHours = 24;
  String? _lastOfflineHealthAlertSignature;
  AdminOfflineMutationAlertSettings _offlineAlertSettings =
      AdminOfflineMutationAlertSettings.defaults();
  bool _offlineAlertSettingsLoaded = false;
  bool _savingOfflineAlertSettings = false;

  @override
  void initState() {
    super.initState();
    _prefsFuture = _loadPrefs();
    _offlineOutcomesFuture = _loadOfflineOutcomes();
    unawaited(_loadOfflineAlertSettings());
  }

  @override
  void dispose() {
    _crashFreeCtrl.dispose();
    _homeTtiCtrl.dispose();
    _edge429CurrentCtrl.dispose();
    _edge429BaselineCtrl.dispose();
    _minSignalCtrl.dispose();
    _retryWarnCtrl.dispose();
    _retryAlarmCtrl.dispose();
    _dropWarnCtrl.dispose();
    _dropAlarmCtrl.dispose();
    _attentionWarnCtrl.dispose();
    _authAlarmCtrl.dispose();
    _serverAlarmCtrl.dispose();
    _rateLimitWarnCtrl.dispose();
    _warningWindowsCtrl.dispose();
    _alarmWindowsCtrl.dispose();
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

  Future<List<AdminOfflineMutationOutcome>> _loadOfflineOutcomes() {
    return ref
        .read(adminObservabilityRepositoryProvider)
        .listOfflineMutationOutcomes(
          hours: _offlineHours * 2,
          limit: _offlineOutcomeLimit * 2,
        );
  }

  Future<void> _loadOfflineAlertSettings() async {
    try {
      final settings = await ref
          .read(adminObservabilityRepositoryProvider)
          .getOfflineMutationAlertSettings();
      if (!mounted) return;
      setState(() {
        _offlineAlertSettings = settings;
        _offlineAlertSettingsLoaded = true;
        _syncOfflineAlertSettingsControllers(settings);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _offlineAlertSettings = AdminOfflineMutationAlertSettings.defaults();
        _offlineAlertSettingsLoaded = true;
        _syncOfflineAlertSettingsControllers(_offlineAlertSettings);
      });
    }
  }

  void _syncOfflineAlertSettingsControllers(
    AdminOfflineMutationAlertSettings settings,
  ) {
    _syncController(_minSignalCtrl, '${settings.minSignalCount}');
    _syncController(
      _retryWarnCtrl,
      settings.retryRateWarningThreshold.toStringAsFixed(2),
    );
    _syncController(
      _retryAlarmCtrl,
      settings.retryRateAlarmThreshold.toStringAsFixed(2),
    );
    _syncController(
      _dropWarnCtrl,
      settings.dropRateWarningThreshold.toStringAsFixed(2),
    );
    _syncController(
      _dropAlarmCtrl,
      settings.dropRateAlarmThreshold.toStringAsFixed(2),
    );
    _syncController(_attentionWarnCtrl, '${settings.attentionWarningCount}');
    _syncController(_authAlarmCtrl, '${settings.authAlarmCount}');
    _syncController(_serverAlarmCtrl, '${settings.serverAlarmCount}');
    _syncController(
      _rateLimitWarnCtrl,
      '${settings.rateLimitWarningCount}',
    );
    _syncController(
      _warningWindowsCtrl,
      '${settings.warningEscalationWindows}',
    );
    _syncController(_alarmWindowsCtrl, '${settings.alarmEscalationWindows}');
  }

  void _syncController(TextEditingController ctrl, String nextValue) {
    if (ctrl.text == nextValue) return;
    ctrl.text = nextValue;
    ctrl.selection = TextSelection.fromPosition(
      TextPosition(offset: ctrl.text.length),
    );
  }

  Future<void> _saveOfflineAlertSettings(BuildContext context) async {
    final next = _readOfflineAlertSettingsDraft();
    if (next == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid offline alert thresholds.')),
      );
      return;
    }
    setState(() => _savingOfflineAlertSettings = true);
    try {
      final saved = await ref
          .read(adminObservabilityRepositoryProvider)
          .saveOfflineMutationAlertSettings(next);
      if (!context.mounted) return;
      setState(() {
        _offlineAlertSettings = saved;
        _syncOfflineAlertSettingsControllers(saved);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline alert thresholds saved.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _savingOfflineAlertSettings = false);
      }
    }
  }

  AdminOfflineMutationAlertSettings? _readOfflineAlertSettingsDraft() {
    final minSignal = _readInt(_minSignalCtrl, -1);
    final attentionWarn = _readInt(_attentionWarnCtrl, -1);
    final authAlarm = _readInt(_authAlarmCtrl, -1);
    final serverAlarm = _readInt(_serverAlarmCtrl, -1);
    final rateLimitWarn = _readInt(_rateLimitWarnCtrl, -1);
    final warningWindows = _readInt(_warningWindowsCtrl, -1);
    final alarmWindows = _readInt(_alarmWindowsCtrl, -1);
    final retryWarn = _readDouble(_retryWarnCtrl, -1);
    final retryAlarm = _readDouble(_retryAlarmCtrl, -1);
    final dropWarn = _readDouble(_dropWarnCtrl, -1);
    final dropAlarm = _readDouble(_dropAlarmCtrl, -1);
    if (minSignal < 1 ||
        attentionWarn < 1 ||
        authAlarm < 1 ||
        serverAlarm < 1 ||
        rateLimitWarn < 1 ||
        warningWindows < 1 ||
        alarmWindows < 1 ||
        retryWarn < 0 ||
        retryAlarm < retryWarn ||
        retryAlarm > 1 ||
        dropWarn < 0 ||
        dropAlarm < dropWarn ||
        dropAlarm > 1) {
      return null;
    }
    return AdminOfflineMutationAlertSettings(
      minSignalCount: minSignal,
      retryRateWarningThreshold: retryWarn,
      retryRateAlarmThreshold: retryAlarm,
      dropRateWarningThreshold: dropWarn,
      dropRateAlarmThreshold: dropAlarm,
      attentionWarningCount: attentionWarn,
      authAlarmCount: authAlarm,
      serverAlarmCount: serverAlarm,
      rateLimitWarningCount: rateLimitWarn,
      warningEscalationWindows: warningWindows,
      alarmEscalationWindows: alarmWindows,
    );
  }

  void _resetOfflineAlertSettings() {
    final defaults = AdminOfflineMutationAlertSettings.defaults();
    setState(() {
      _offlineAlertSettings = defaults;
      _syncOfflineAlertSettingsControllers(defaults);
    });
  }

  void _refreshPrefs() {
    setState(() {
      _prefsFuture = _loadPrefs();
      _offlineOutcomesFuture = _loadOfflineOutcomes();
    });
    unawaited(_loadOfflineAlertSettings());
  }

  void _generateRequestId() {
    setState(() {
      _requestId = createRequestId(prefix: 'obs');
    });
  }

  void _setOfflineHours(int hours) {
    if (_offlineHours == hours) return;
    setState(() {
      _offlineHours = hours;
      _offlineOutcomesFuture = _loadOfflineOutcomes();
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
    final l10n = context.l10n;
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
            title: l10n.adminObservabilityTitle,
            subtitle: Text(
              l10n.adminObservabilitySubtitle,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            trailing: IconButton(
              onPressed: _refreshPrefs,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.yenile,
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.adminObservabilityRequestTraceTitle,
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  l10n.adminObservabilityRequestIdValue(_requestId),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  l10n.adminObservabilityHeadersValue(jsonEncode(headers)),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  l10n.adminObservabilityPayloadValue(jsonEncode(payload)),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _generateRequestId,
                  icon: const Icon(Icons.vpn_key_outlined),
                  label: Text(l10n.adminObservabilityGenerateRequestId),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.adminObservabilityPerfTitle,
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.adminObservabilityPerfSummary,
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statusChip(
                      context,
                      l10n.adminObservabilityCrashFreeLabel,
                      !crashAlert,
                    ),
                    _statusChip(
                      context,
                      l10n.adminObservabilityHomeTtiLabel,
                      !homeTtiAlert,
                    ),
                    _statusChip(
                      context,
                      l10n.adminObservabilityEdgeSpikeLabel,
                      !edge429Alert,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _crashFreeCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.adminObservabilityCrashFreeInput,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _homeTtiCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.adminObservabilityHomeTtiInput,
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
                        decoration: InputDecoration(
                          labelText: l10n.adminObservabilityEdgeCurrentInput,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _edge429BaselineCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.adminObservabilityEdgeBaselineInput,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.adminObservabilityConstantsSummary(
                    PerfSlo.coldStartP95Ms,
                    PerfSlo.warmStartP95Ms,
                    PerfSlo.homeTtiP95Ms,
                    PerfSlo.searchCacheHitP95Ms,
                    PerfSlo.searchCacheMissP95Ms,
                  ),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline alert calibration',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tune replay warning/alarm thresholds and escalation persistence without a deploy.',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                if (!_offlineAlertSettingsLoaded)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minSignalCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Min signal count',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _attentionWarnCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Attention warning count',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _retryWarnCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Retry warning threshold',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _retryAlarmCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Retry alarm threshold',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _dropWarnCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Drop warning threshold',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _dropAlarmCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Drop alarm threshold',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _authAlarmCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Auth hotspot count',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _serverAlarmCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Server hotspot count',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _rateLimitWarnCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Rate-limit warning count',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _warningWindowsCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Warning escalation windows',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _alarmWindowsCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Alarm escalation windows',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: _savingOfflineAlertSettings
                            ? null
                            : () => _saveOfflineAlertSettings(context),
                        child: Text(
                          _savingOfflineAlertSettings
                              ? 'Saving...'
                              : 'Save calibration',
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _savingOfflineAlertSettings
                            ? null
                            : _resetOfflineAlertSettings,
                        child: const Text('Reset defaults'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: FutureBuilder<List<AdminOfflineMutationOutcome>>(
              future: _offlineOutcomesFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offline mutation outcomes',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Recent replay outcomes from mobile offline queues.',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${snap.error}',
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ],
                  );
                }
                final allItems =
                    snap.data ?? const <AdminOfflineMutationOutcome>[];
                final now = DateTime.now().toUtc();
                final currentWindowStart = now.subtract(
                  Duration(hours: _offlineHours),
                );
                final previousWindowStart = currentWindowStart.subtract(
                  Duration(hours: _offlineHours),
                );
                final items = allItems
                    .where(
                      (item) => !item.createdAt.toUtc().isBefore(
                        currentWindowStart,
                      ),
                    )
                    .toList(growable: false);
                final previousItems = allItems
                    .where(
                      (item) =>
                          item.createdAt.toUtc().isBefore(currentWindowStart) &&
                          !item.createdAt.toUtc().isBefore(previousWindowStart),
                    )
                    .toList(growable: false);
                final healthSummary =
                    AdminOfflineMutationHealthSummary.fromItems(
                      items,
                      settings: _offlineAlertSettings,
                    );
                final previousSummary =
                    AdminOfflineMutationHealthSummary.fromItems(
                      previousItems,
                      settings: _offlineAlertSettings,
                    );
                final escalationDecision =
                    AdminOfflineMutationEscalationDecision.evaluate(
                      current: healthSummary,
                      previous: previousSummary,
                      settings: _offlineAlertSettings,
                    );
                _maybeEmitOfflineHealthAlert(
                  healthSummary,
                  escalationDecision,
                );
                final dispositionCounts = _countBy(
                  items.map((item) => item.disposition),
                );
                final kindCounts = _countBy(items.map((item) => item.kind));
                final sourceCounts = _countBy(items.map((item) => item.source));
                final retryCounts = _countBy(
                  items
                      .map((item) => item.retryCategory)
                      .whereType<String>()
                      .where((value) => value.isNotEmpty),
                );
                final attentionItems = items
                    .where(
                      (item) =>
                          item.disposition == 'retry' ||
                          item.disposition == 'drop',
                    )
                    .take(8)
                    .toList(growable: false);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Offline mutation outcomes',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tracks success, retry, resolve and drop decisions emitted by mobile queue replay.',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _refreshPrefs,
                          tooltip: 'Refresh offline outcomes',
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _offlineWindows
                          .map(
                            (hours) => ChoiceChip(
                              label: Text('$hours h'),
                              selected: hours == _offlineHours,
                              onSelected: (_) => _setOfflineHours(hours),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 10),
                    if (items.isEmpty)
                      Text(
                        'No offline mutation outcome events recorded in the last $_offlineHours hours.',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      )
                    else ...[
                      _buildOfflineHealthSummary(
                        healthSummary,
                        previousSummary,
                        escalationDecision,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...dispositionCounts.entries.map(
                            (entry) => _summaryChip(
                              label: entry.key,
                              value: '${entry.value}',
                              color: _dispositionColor(entry.key),
                            ),
                          ),
                          _summaryChip(
                            label: 'Kinds',
                            value: '${kindCounts.length}',
                            color: AppColors.info,
                          ),
                          _summaryChip(
                            label: 'Sources',
                            value: '${sourceCounts.length}',
                            color: AppColors.info,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (retryCounts.isNotEmpty) ...[
                        Text(
                          'Top retry categories',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: retryCounts.entries
                              .map(
                                (entry) => _summaryChip(
                                  label: entry.key,
                                  value: '${entry.value}',
                                  color: AppColors.warning,
                                ),
                              )
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        'Attention items',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      if (attentionItems.isEmpty)
                        Text(
                          'No retry or drop items in the selected window.',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        )
                      else
                        ...attentionItems.map(_buildOfflineOutcomeTile),
                      const SizedBox(height: 12),
                      Text(
                        'Recent events',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      ...items.take(12).map(_buildOfflineOutcomeTile),
                    ],
                  ],
                );
              },
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
                    l10n.adminObservabilityPrefsReadError('${snap.error}'),
                    style: const TextStyle(color: AppColors.danger),
                  );
                }
                final data = snap.data;
                if (data == null) {
                  return Text(l10n.adminObservabilityPrefsEmpty);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.adminObservabilityPrefsExplorerTitle,
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

  Widget _statusChip(BuildContext context, String label, bool ok) {
    final l10n = context.l10n;
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
        l10n.adminObservabilityStatusChip(
          label,
          ok
              ? l10n.adminObservabilityStatusOk
              : l10n.adminObservabilityStatusAlarm,
        ),
        style: TextStyle(
          color: ok ? AppColors.success : AppColors.danger,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _summaryChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildOfflineHealthSummary(
    AdminOfflineMutationHealthSummary summary,
    AdminOfflineMutationHealthSummary previousSummary,
    AdminOfflineMutationEscalationDecision escalationDecision,
  ) {
    final color = _healthSeverityColor(summary.severity);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.summaryLine,
                      style: const TextStyle(
                        color: AppColors.textStrong,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _summaryChip(
                label: 'Status',
                value: summary.statusLabel,
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Thresholds: retry ${_formatThreshold(_offlineAlertSettings.retryRateWarningThreshold)}/${_formatThreshold(_offlineAlertSettings.retryRateAlarmThreshold)}, drop ${_formatThreshold(_offlineAlertSettings.dropRateWarningThreshold)}/${_formatThreshold(_offlineAlertSettings.dropRateAlarmThreshold)}, auth hotspot >= ${_offlineAlertSettings.authAlarmCount}, server hotspot >= ${_offlineAlertSettings.serverAlarmCount}.',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            'Previous window: ${previousSummary.statusLabel} | Retry ${_formatThreshold(previousSummary.retryRate)} | Drop ${_formatThreshold(previousSummary.dropRate)}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ...summary.reasons.map(
            (reason) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $reason',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _escalationColor(
                escalationDecision.level,
              ).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _escalationColor(
                  escalationDecision.level,
                ).withValues(alpha: 0.24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Escalation: ${escalationDecision.label}',
                  style: TextStyle(
                    color: _escalationColor(escalationDecision.level),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Target: ${escalationDecision.target}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  escalationDecision.reason,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _maybeEmitOfflineHealthAlert(
    AdminOfflineMutationHealthSummary summary,
    AdminOfflineMutationEscalationDecision escalationDecision,
  ) {
    if (summary.severity == AdminOfflineMutationHealthSeverity.ok) {
      return;
    }
    final signature = [
      _offlineHours,
      summary.severity.name,
      summary.totalCount,
      summary.retryCount,
      summary.dropCount,
      summary.attentionCount,
    ].join('|');
    if (_lastOfflineHealthAlertSignature == signature) {
      return;
    }
    _lastOfflineHealthAlertSignature = signature;
    unawaited(
      logObservabilityAlert(
        ref,
        alertType: summary.severity == AdminOfflineMutationHealthSeverity.alarm
            ? 'offline_mutation_health_alarm'
            : 'offline_mutation_health_warning',
        source: 'admin_observability',
        meta: {
          'window_hours': _offlineHours,
          'severity': summary.severity.name,
          'total_count': summary.totalCount,
          'retry_count': summary.retryCount,
          'drop_count': summary.dropCount,
          'attention_count': summary.attentionCount,
          'retry_rate': double.parse(summary.retryRate.toStringAsFixed(4)),
          'drop_rate': double.parse(summary.dropRate.toStringAsFixed(4)),
          'low_signal': summary.lowSignal,
          'escalation_level': escalationDecision.level.name,
          'escalation_target': escalationDecision.target,
          'escalation_required': escalationDecision.shouldEscalate,
        },
      ),
    );
  }

  String _formatThreshold(double value) {
    return '${(value * 100).toStringAsFixed(0)}%';
  }

  Color _escalationColor(AdminOfflineMutationEscalationLevel level) {
    switch (level) {
      case AdminOfflineMutationEscalationLevel.none:
        return AppColors.success;
      case AdminOfflineMutationEscalationLevel.opsWatch:
        return AppColors.info;
      case AdminOfflineMutationEscalationLevel.opsAction:
        return AppColors.warning;
      case AdminOfflineMutationEscalationLevel.incident:
        return AppColors.danger;
    }
  }

  Widget _buildOfflineOutcomeTile(AdminOfflineMutationOutcome item) {
    final timestamp = DateFormat('dd MMM HH:mm').format(item.createdAt.toLocal());
    final retryLabel = item.retryCategory ?? 'n/a';
    final detail = item.detail ?? 'No detail';
    final userLabel = item.userId == null
        ? 'anon'
        : item.userId!.substring(0, math.min(8, item.userId!.length));
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '$timestamp  ${item.kind}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              _summaryChip(
                label: item.disposition,
                value: '${item.retryCount}',
                color: _dispositionColor(item.disposition),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Source: ${item.source} | Retry category: $retryLabel | User: $userLabel',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            'Suggested action: ${_suggestedAction(item)}',
            style: const TextStyle(
              color: AppColors.textStrong,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _dispositionColor(String disposition) {
    switch (disposition) {
      case 'success':
        return AppColors.success;
      case 'resolve':
        return AppColors.info;
      case 'retry':
        return AppColors.warning;
      case 'drop':
        return AppColors.danger;
      default:
        return AppColors.muted;
    }
  }

  Color _healthSeverityColor(AdminOfflineMutationHealthSeverity severity) {
    switch (severity) {
      case AdminOfflineMutationHealthSeverity.alarm:
        return AppColors.danger;
      case AdminOfflineMutationHealthSeverity.warning:
        return AppColors.warning;
      case AdminOfflineMutationHealthSeverity.ok:
        return AppColors.success;
    }
  }

  String _suggestedAction(AdminOfflineMutationOutcome item) {
    switch (item.disposition) {
      case 'success':
      case 'resolve':
        return 'No operator action required.';
      case 'retry':
        switch (item.retryCategory) {
          case 'network':
            return 'Check connectivity and wait for the next replay window.';
          case 'auth':
            return 'Refresh session state before forcing another replay.';
          case 'rate_limit':
            return 'Respect cooldown and avoid repeated manual retries.';
          case 'server':
            return 'Inspect backend logs or RPC health before replay.';
          default:
            return 'Monitor the next scheduled replay attempt.';
        }
      case 'drop':
        return 'Inspect payload integrity or contract drift before re-queueing.';
      default:
        return 'Review the event detail and recent adjacent outcomes.';
    }
  }

  Map<String, int> _countBy(Iterable<String> values) {
    final counts = <String, int>{};
    for (final value in values) {
      final normalized = value.trim().isEmpty ? 'unknown' : value.trim();
      counts.update(normalized, (current) => current + 1, ifAbsent: () => 1);
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map<String, int>.fromEntries(entries);
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
