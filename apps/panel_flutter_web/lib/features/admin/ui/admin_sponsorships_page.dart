import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../data/admin_monetization_repository.dart';
import '../domain/admin_models.dart';
import '../domain/admin_sponsorship_packages_controller.dart';
import '../domain/admin_sponsorships_controller.dart';
import 'monetization/admin_sponsorship_form.dart';
import 'web_download.dart';

class AdminSponsorshipsPage extends ConsumerStatefulWidget {
  const AdminSponsorshipsPage({super.key});

  @override
  ConsumerState<AdminSponsorshipsPage> createState() =>
      _AdminSponsorshipsPageState();
}

class _AdminSponsorshipsPageState extends ConsumerState<AdminSponsorshipsPage> {
  final scrollCtrl = ScrollController();
  bool exporting = false;
  late Future<AdminSponsorshipSummary?> _summaryFuture;
  late Future<List<AdminSponsorshipInventorySurface>> _inventoryFuture;

  @override
  void initState() {
    super.initState();
    _refreshReporting();
    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels >=
          scrollCtrl.position.maxScrollExtent - 300) {
        ref.read(adminSponsorshipsControllerProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    scrollCtrl.dispose();
    super.dispose();
  }

  void _refreshReporting() {
    final repo = ref.read(adminMonetizationRepositoryProvider);
    _summaryFuture = repo.getSummary();
    _inventoryFuture = repo.listInventory();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(adminSponsorshipsControllerProvider);
    final l10n = context.l10n;
    final packages = ref
        .watch(adminSponsorshipPackagesControllerProvider)
        .items;
    final packagesById = {for (final p in packages) p.id: p};

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.adminSponsorshipsTitle,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: exporting ? null : () => _exportCsv(st),
                icon: const Icon(Icons.download),
                label: Text(
                  exporting
                      ? l10n.adminCommonDownloading
                      : l10n.adminCommonExportCsv,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => const AdminSponsorshipCreateSheet(),
                  );
                  if (!mounted) return;
                  setState(_refreshReporting);
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.adminSponsorshipsNewAction),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(_refreshReporting);
                  ref
                      .read(adminSponsorshipsControllerProvider.notifier)
                      .refresh();
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _reportingOverview(),
          const SizedBox(height: 12),
          _filters(st),
          const SizedBox(height: 12),
          if (st.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                AppErrorMapper.message(st.error),
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          Expanded(
            child: st.isLoading && st.items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    controller: scrollCtrl,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text(l10n.businessLabel)),
                            DataColumn(
                              label: Text(l10n.adminSponsorshipsSurfaceColumn),
                            ),
                            DataColumn(
                              label: Text(l10n.adminSponsorshipsStatusColumn),
                            ),
                            DataColumn(
                              label: Text(l10n.adminSponsorshipsDateRangeColumn),
                            ),
                            DataColumn(
                              label: Text(l10n.adminSponsorshipsPackageColumn),
                            ),
                            DataColumn(
                              label: Text(l10n.adminSponsorshipsQuotaColumn),
                            ),
                            DataColumn(
                              label: Text(l10n.adminSponsorshipsCreatedAtColumn),
                            ),
                            DataColumn(label: Text('')),
                          ],
                          rows: [
                            for (final item in st.items)
                              DataRow(
                                cells: [
                                  DataCell(Text(item.businessName)),
                                  DataCell(Text(_surfaceLabel(context, item.surface))),
                                  DataCell(Text(_statusLabel(context, item.status))),
                                  DataCell(
                                    Text(_range(context, item.startsAt, item.endsAt)),
                                  ),
                                  DataCell(
                                    Text(
                                      packagesById[item.packageId]?.name ??
                                          item.packageId,
                                    ),
                                  ),
                                  DataCell(
                                    Text(_caps(context, item.dailyCap, item.totalCap)),
                                  ),
                                  DataCell(Text(_fmtDate(item.createdAt))),
                                  DataCell(_actions(item)),
                                ],
                              ),
                          ],
                        ),
                      ),
                      if (!st.isLoading && st.items.isEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: Center(
                            child: Text(l10n.adminCommonNoRecordsFound),
                          ),
                        ),
                      if (st.isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filters(AdminSponsorshipsState st) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Wrap(spacing: 8, children: [])],
    );
  }

  Widget _reportingOverview() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.adminSponsorshipsOverviewTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.adminSponsorshipsOverviewDescription,
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        FutureBuilder<AdminSponsorshipSummary?>(
          future: _summaryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(minHeight: 6),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  AppErrorMapper.message(snapshot.error),
                  style: const TextStyle(color: AppColors.danger),
                ),
              );
            }
            final summary = snapshot.data;
            if (summary == null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.adminCommonNoRecordsFound,
                  style: const TextStyle(color: AppColors.muted),
                ),
              );
            }
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricCard(
                  label: l10n.adminSponsorshipsMetricActive,
                  value: '${summary.activeSponsorships}',
                ),
                _MetricCard(
                  label: l10n.adminSponsorshipsMetricPending,
                  value: '${summary.pendingSponsorships}',
                ),
                _MetricCard(
                  label: l10n.adminSponsorshipsMetricOpenLeads,
                  value: '${summary.openLeads}',
                ),
                _MetricCard(
                  label: l10n.adminSponsorshipsMetricImpressions30d,
                  value: '${summary.impressions30d}',
                ),
                _MetricCard(
                  label: l10n.adminSponsorshipsMetricUniqueUsers30d,
                  value: '${summary.uniqueUsers30d}',
                ),
                _MetricCard(
                  label: l10n.adminSponsorshipsMetricEstimatedRevenue,
                  value: _formatMoneyCents(
                    summary.estimatedActiveRevenueCents,
                    'TRY',
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          l10n.adminSponsorshipsInventoryTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.adminSponsorshipsInventoryDescription,
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<AdminSponsorshipInventorySurface>>(
          future: _inventoryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(minHeight: 6),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  AppErrorMapper.message(snapshot.error),
                  style: const TextStyle(color: AppColors.danger),
                ),
              );
            }
            final items = snapshot.data ?? const [];
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.adminCommonNoRecordsFound,
                  style: const TextStyle(color: AppColors.muted),
                ),
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text(l10n.adminSponsorshipsSurfaceColumn)),
                  DataColumn(
                    label: Text(l10n.adminSponsorshipsInventoryPackagesColumn),
                  ),
                  DataColumn(
                    label: Text(l10n.adminSponsorshipsInventoryUnitsColumn),
                  ),
                  DataColumn(
                    label: Text(l10n.adminSponsorshipsMetricOpenLeads),
                  ),
                  DataColumn(
                    label: Text(l10n.adminSponsorshipsInventoryDemandColumn),
                  ),
                  DataColumn(
                    label: Text(
                      l10n.adminSponsorshipsInventoryPerformanceColumn,
                    ),
                  ),
                  DataColumn(
                    label: Text(l10n.adminSponsorshipsMetricEstimatedRevenue),
                  ),
                ],
                rows: [
                  for (final item in items)
                    DataRow(
                      cells: [
                        DataCell(Text(_surfaceLabel(context, item.surface))),
                        DataCell(
                          Text(
                            l10n.adminSponsorshipsInventoryPackagesValue(
                              item.activePackages,
                              item.totalPackages,
                              item.inventoryLimit,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            l10n.adminSponsorshipsInventoryUnitsValue(
                              item.liveUnits,
                              item.openInventorySlots,
                            ),
                          ),
                        ),
                        DataCell(Text('${item.openLeads}')),
                        DataCell(
                          Text(
                            l10n.adminSponsorshipsInventoryDemandValue(
                              item.pendingSponsorships,
                              item.openLeads,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            l10n.adminSponsorshipsInventoryPerformanceValue(
                              item.impressions30d,
                              item.uniqueUsers30d,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatMoneyCents(
                              item.estimatedActiveRevenueCents,
                              'TRY',
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _actions(AdminSponsorshipItem item) {
    final l10n = context.l10n;
    return Row(
      children: [
        OutlinedButton(
          onPressed: () => _setStatus(item.id, 'active'),
          child: Text(l10n.adminSponsorshipsActivateAction),
        ),
        const SizedBox(width: 6),
        OutlinedButton(
          onPressed: () => _setStatus(item.id, 'paused'),
          child: Text(l10n.adminSponsorshipsPauseAction),
        ),
        const SizedBox(width: 6),
        TextButton(
          onPressed: () => _setStatus(item.id, 'ended'),
          child: Text(l10n.adminSponsorshipsEndAction),
        ),
      ],
    );
  }

  Future<void> _setStatus(String id, String status) async {
    try {
      await ref
          .read(adminMonetizationRepositoryProvider)
          .setSponsorshipStatus(sponsorshipId: id, status: status);
      setState(_refreshReporting);
      ref.read(adminSponsorshipsControllerProvider.notifier).refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _exportCsv(AdminSponsorshipsState st) async {
    setState(() => exporting = true);
    try {
      final repo = ref.read(adminMonetizationRepositoryProvider);
      final rows = <AdminSponsorshipItem>[];
      var offset = 0;
      const limit = 200;
      while (true) {
        final batch = await repo.listSponsorships(
          status: st.statusFilter,
          surface: st.surfaceFilter,
          limit: limit,
          offset: offset,
        );
        rows.addAll(batch);
        if (batch.length < limit) break;
        offset += limit;
      }

      final csv = _buildCsv(rows);
      downloadCsv('sponsorships_${_stamp()}.csv', csv);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }
}

String _caps(BuildContext context, int? daily, int? total) {
  final d = daily == null ? '-' : daily.toString();
  final t = total == null ? '-' : total.toString();
  return context.l10n.adminSponsorshipsQuotaValue(d, t);
}

String _range(BuildContext context, DateTime? s, DateTime? e) {
  if (s == null && e == null) return '-';
  final ss = s == null ? context.l10n.adminSponsorshipsInfinity : _fmtDate(s);
  final ee = e == null ? context.l10n.adminSponsorshipsInfinity : _fmtDate(e);
  return context.l10n.adminSponsorshipsDateRangeValue(ss, ee);
}

String _statusLabel(BuildContext context, String status) {
  final l10n = context.l10n;
  switch (status) {
    case 'active':
      return l10n.adminSponsorshipsStatusActive;
    case 'paused':
      return l10n.adminSponsorshipsStatusPaused;
    case 'ended':
      return l10n.adminSponsorshipsStatusEnded;
    default:
      return status;
  }
}

String _surfaceLabel(BuildContext context, String surface) {
  final l10n = context.l10n;
  switch (surface) {
    case 'discovery':
      return l10n.adminSponsorshipPackagesSurfaceDiscovery;
    case 'business_page':
      return l10n.adminSponsorshipPackagesSurfaceBusinessPage;
    case 'verified':
      return l10n.adminSponsorshipPackagesSurfaceVerified;
    case 'stories':
      return l10n.adminSponsorshipPackagesSurfaceStories;
    case 'premium':
      return l10n.adminSponsorshipPackagesSurfacePremium;
    default:
      return surface;
  }
}

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

String _formatMoneyCents(int amount, String currencyCode) {
  final whole = amount / 100;
  return '${whole.toStringAsFixed(2)} $currencyCode';
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

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
          Text(label, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

String _csvEscape(String v) {
  final s = v.replaceAll('"', '""');
  return '"$s"';
}

String _buildCsv(List<AdminSponsorshipItem> rows) {
  final buf = StringBuffer();
  buf.writeln(
    [
      'id',
      'status',
      'surface',
      'created_at',
      'business_id',
      'business_name',
      'city',
      'district',
      'package_id',
      'starts_at',
      'ends_at',
      'daily_cap',
      'total_cap',
      'source',
      'created_by',
    ].join(','),
  );
  for (final r in rows) {
    buf.writeln(
      [
        _csvEscape(r.id),
        _csvEscape(r.status),
        _csvEscape(r.surface),
        _csvEscape(r.createdAt.toIso8601String()),
        _csvEscape(r.businessId),
        _csvEscape(r.businessName),
        _csvEscape(r.city ?? ''),
        _csvEscape(r.district ?? ''),
        _csvEscape(r.packageId),
        _csvEscape(r.startsAt?.toIso8601String() ?? ''),
        _csvEscape(r.endsAt?.toIso8601String() ?? ''),
        _csvEscape(r.dailyCap?.toString() ?? ''),
        _csvEscape(r.totalCap?.toString() ?? ''),
        _csvEscape(r.source),
        _csvEscape(r.createdBy ?? ''),
      ].join(','),
    );
  }
  return buf.toString();
}

String _stamp() {
  final now = DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  final hh = now.hour.toString().padLeft(2, '0');
  final mm = now.minute.toString().padLeft(2, '0');
  return '$y$m${d}_$hh$mm';
}
