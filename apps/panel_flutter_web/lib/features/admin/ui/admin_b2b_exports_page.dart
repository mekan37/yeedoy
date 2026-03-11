import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../data/admin_b2b_exports_repository.dart';
import '../domain/admin_b2b_export_catalog.dart';
import 'web_download.dart';

class AdminB2bExportsPage extends ConsumerStatefulWidget {
  const AdminB2bExportsPage({super.key});

  @override
  ConsumerState<AdminB2bExportsPage> createState() =>
      _AdminB2bExportsPageState();
}

class _AdminB2bExportsPageState extends ConsumerState<AdminB2bExportsPage> {
  int _days = 30;
  late final Map<AdminB2bExportKind, bool> _loadingByKind = {
    for (final spec in adminB2bExportCatalog) spec.kind: false,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text(
            l10n.adminB2bExportsTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.adminB2bExportsSubtitle,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InsightChip(label: l10n.adminB2bExportsPriceIndexChip),
              _InsightChip(label: l10n.adminB2bExportsRegionalTrendChip),
              _InsightChip(label: l10n.adminB2bExportsMenuInflationChip),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SummaryCard(
                title: l10n.adminB2bExportsLaneInternalOps,
                count: _countLane(AdminB2bProductLane.internalOps),
              ),
              _SummaryCard(
                title: l10n.adminB2bExportsLanePremiumCandidate,
                count: _countLane(
                  AdminB2bProductLane.premiumAnalyticsCandidate,
                ),
              ),
              _SummaryCard(
                title: l10n.adminB2bExportsLaneExternalCandidate,
                count: _countLane(AdminB2bProductLane.externalMarketCandidate),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _GovernanceCard(
            title: l10n.adminB2bExportsGovernanceTitle,
            description: l10n.adminB2bExportsGovernanceDescription,
            items: [
              l10n.adminB2bExportsGovernanceAnonymousRule,
              l10n.adminB2bExportsGovernanceRestrictedRule,
              l10n.adminB2bExportsGovernanceContractRule,
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l10n.adminB2bExportsPeriodLabel),
              DropdownButton<int>(
                value: _days,
                items: [
                  DropdownMenuItem(
                    value: 7,
                    child: Text(l10n.adminB2bExportsDayOption(7)),
                  ),
                  DropdownMenuItem(
                    value: 30,
                    child: Text(l10n.adminB2bExportsDayOption(30)),
                  ),
                  DropdownMenuItem(
                    value: 90,
                    child: Text(l10n.adminB2bExportsDayOption(90)),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _days = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final spec in adminB2bExportCatalog) ...[
            _ExportCard(
              title: _exportTitle(context, spec.kind),
              description: _exportDescription(context, spec.kind),
              loading: _loadingByKind[spec.kind] ?? false,
              statusLabel: _statusLabel(context, spec.status),
              statusColor: _statusColor(spec.status),
              metadata: [
                _ExportMetadata(
                  label: l10n.adminB2bExportsLaneLabel,
                  value: _laneLabel(context, spec.productLane),
                ),
                _ExportMetadata(
                  label: l10n.adminB2bExportsPrivacyLabel,
                  value: _privacyLabel(context, spec.privacyClass),
                ),
                _ExportMetadata(
                  label: l10n.adminB2bExportsFreshnessLabel,
                  value: _freshnessLabel(context, spec.freshness),
                ),
              ],
              onExport: () => _export(spec),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  int _countLane(AdminB2bProductLane lane) {
    return adminB2bExportCatalog.where((spec) => spec.productLane == lane).length;
  }

  Future<void> _export(AdminB2bExportSpec spec) async {
    setState(() => _loadingByKind[spec.kind] = true);
    try {
      final csv = await ref.read(adminB2bExportsRepositoryProvider).exportCsv(
        kind: spec.kind,
        days: _days,
        anomalyThresholdPct: 40,
      );
      if (!mounted) return;
      downloadCsv('${spec.filenamePrefix}_${_stamp()}.csv', csv);
    } catch (e) {
      _snackError(e);
    } finally {
      if (mounted) {
        setState(() => _loadingByKind[spec.kind] = false);
      }
    }
  }

  void _snackError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(error))));
  }

  String _stamp() {
    final now = DateTime.now().toUtc();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({
    required this.title,
    required this.description,
    required this.loading,
    required this.statusLabel,
    required this.statusColor,
    required this.metadata,
    required this.onExport,
  });

  final String title;
  final String description;
  final bool loading;
  final String statusLabel;
  final Color statusColor;
  final List<_ExportMetadata> metadata;
  final Future<void> Function() onExport;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusChip(label: statusLabel, color: statusColor),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in metadata)
                  _MetaChip(label: item.label, value: item.value),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: loading ? null : onExport,
              icon: const Icon(Icons.download_outlined),
              label: Text(
                loading
                    ? context.l10n.adminB2bExportsPreparingAction
                    : context.l10n.adminB2bExportsDownloadCsvAction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _GovernanceCard extends StatelessWidget {
  const _GovernanceCard({
    required this.title,
    required this.description,
    required this.items,
  });

  final String title;
  final String description;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 10),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: AppColors.textStrong, fontSize: 12),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textStrong,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ExportMetadata {
  const _ExportMetadata({required this.label, required this.value});

  final String label;
  final String value;
}

String _exportTitle(BuildContext context, AdminB2bExportKind kind) {
  final l10n = context.l10n;
  return switch (kind) {
    AdminB2bExportKind.anonymousTrends =>
      l10n.adminB2bExportsAnonymousTrendsTitle,
    AdminB2bExportKind.regionalPriceIndex =>
      l10n.adminB2bExportsRegionalPriceIndexTitle,
    AdminB2bExportKind.menuInflation => l10n.adminB2bExportsMenuInflationTitle,
    AdminB2bExportKind.priceAnomalies =>
      l10n.adminB2bExportsPriceAnomaliesTitle,
  };
}

String _exportDescription(BuildContext context, AdminB2bExportKind kind) {
  final l10n = context.l10n;
  return switch (kind) {
    AdminB2bExportKind.anonymousTrends =>
      l10n.adminB2bExportsAnonymousTrendsDescription,
    AdminB2bExportKind.regionalPriceIndex =>
      l10n.adminB2bExportsRegionalPriceIndexDescription,
    AdminB2bExportKind.menuInflation =>
      l10n.adminB2bExportsMenuInflationDescription,
    AdminB2bExportKind.priceAnomalies =>
      l10n.adminB2bExportsPriceAnomaliesDescription,
  };
}

String _laneLabel(BuildContext context, AdminB2bProductLane lane) {
  final l10n = context.l10n;
  return switch (lane) {
    AdminB2bProductLane.internalOps => l10n.adminB2bExportsLaneInternalOps,
    AdminB2bProductLane.premiumAnalyticsCandidate =>
      l10n.adminB2bExportsLanePremiumCandidate,
    AdminB2bProductLane.externalMarketCandidate =>
      l10n.adminB2bExportsLaneExternalCandidate,
  };
}

String _privacyLabel(BuildContext context, AdminB2bPrivacyClass privacyClass) {
  final l10n = context.l10n;
  return switch (privacyClass) {
    AdminB2bPrivacyClass.anonymousAggregate =>
      l10n.adminB2bExportsPrivacyAnonymousAggregate,
    AdminB2bPrivacyClass.restrictedAggregate =>
      l10n.adminB2bExportsPrivacyRestrictedAggregate,
    AdminB2bPrivacyClass.contractOnly =>
      l10n.adminB2bExportsPrivacyContractOnly,
  };
}

String _freshnessLabel(BuildContext context, AdminB2bFreshness freshness) {
  final l10n = context.l10n;
  return switch (freshness) {
    AdminB2bFreshness.dailySeries =>
      l10n.adminB2bExportsFreshnessDailySeries,
    AdminB2bFreshness.rollingWindow =>
      l10n.adminB2bExportsFreshnessRollingWindow,
  };
}

String _statusLabel(BuildContext context, AdminB2bExportStatus status) {
  final l10n = context.l10n;
  return switch (status) {
    AdminB2bExportStatus.internalReady =>
      l10n.adminB2bExportsStatusInternalReady,
    AdminB2bExportStatus.premiumCandidate =>
      l10n.adminB2bExportsStatusPremiumCandidate,
    AdminB2bExportStatus.externalCandidate =>
      l10n.adminB2bExportsStatusExternalCandidate,
  };
}

Color _statusColor(AdminB2bExportStatus status) {
  return switch (status) {
    AdminB2bExportStatus.internalReady => AppColors.success,
    AdminB2bExportStatus.premiumCandidate => AppColors.info,
    AdminB2bExportStatus.externalCandidate => AppColors.warning,
  };
}
