import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../data/admin_suspended_claims_repository.dart';
import '../domain/admin_models.dart';
import '../domain/admin_new_items_controller.dart';
import '../domain/admin_suspended_claims_controller.dart';
import 'web_download.dart';
import 'widgets/admin_new_items_banner.dart';
import '../../../shared/ui/design_system.dart';

class AdminSuspendedClaimsPage extends ConsumerStatefulWidget {
  const AdminSuspendedClaimsPage({super.key});

  @override
  ConsumerState<AdminSuspendedClaimsPage> createState() =>
      _AdminSuspendedClaimsPageState();
}

class _AdminSuspendedClaimsPageState
    extends ConsumerState<AdminSuspendedClaimsPage> {
  final scrollCtrl = ScrollController();
  bool exporting = false;

  @override
  void initState() {
    super.initState();
    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels >=
          scrollCtrl.position.maxScrollExtent - 300) {
        ref.read(adminSuspendedClaimsControllerProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(adminSuspendedClaimsControllerProvider);
    final controller = ref.read(
      adminSuspendedClaimsControllerProvider.notifier,
    );
    final newItems = ref.watch(adminNewItemsProvider).suspendedClaimsNew;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelPageHeader(
            padding: EdgeInsets.zero,
            title: Text(l10n.adminSuspendedClaimsTitle),
            actions: [
              OutlinedButton.icon(
                onPressed: exporting ? null : () => _exportCsv(st),
                icon: const Icon(Icons.download),
                label: Text(
                  exporting
                      ? l10n.adminCommonDownloading
                      : l10n.adminCommonExportCsv,
                ),
              ),
              IconButton(
                onPressed: () async {
                  final ok = await controller.refresh(force: true);
                  if (!context.mounted) return;
                  if (ok) {
                    ref
                        .read(adminNewItemsProvider.notifier)
                        .clearSuspendedClaims();
                  }
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Wrap(
                spacing: 8,
                children: [
                  AppFilterChip(
                    label: l10n.pending,
                    selected: st.statusFilter == 'pending',
                    onTap: () => controller.setStatusFilter('pending'),
                  ),
                  AppFilterChip(
                    label: l10n.approved,
                    selected: st.statusFilter == 'approved',
                    onTap: () => controller.setStatusFilter('approved'),
                  ),
                  AppFilterChip(
                    label: l10n.rejected,
                    selected: st.statusFilter == 'rejected',
                    onTap: () => controller.setStatusFilter('rejected'),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              AppFilterChip(
                label: 'SLA',
                selected: st.slaOnly,
                onTap: () => controller.setSlaOnly(!st.slaOnly),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AdminNewItemsBanner(
            count: newItems,
            label: l10n.adminCommonNewRecordsAvailable,
            onRefresh: () async {
              final ok = await controller.refresh(force: true);
              if (!context.mounted) return;
              if (ok) {
                ref.read(adminNewItemsProvider.notifier).clearSuspendedClaims();
              }
            },
          ),
          if (newItems > 0) const SizedBox(height: 10),
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
                            DataColumn(label: Text(l10n.adminCommonAge)),
                            DataColumn(label: Text(l10n.businessLabel)),
                            DataColumn(
                              label: Text(l10n.adminSuspendedClaimsAmountColumn),
                            ),
                            DataColumn(
                              label: Text(
                                l10n.adminSuspendedClaimsClaimantColumn,
                              ),
                            ),
                            DataColumn(label: Text('SLA')),
                            DataColumn(label: Text('')),
                          ],
                          rows: [
                            for (var i = 0; i < st.items.length; i++)
                              DataRow(
                                color: _rowColor(st.items[i].slaBreached),
                                onSelectChanged: (_) =>
                                    _openDetails(context, st.items[i]),
                                cells: [
                                  DataCell(
                                    Text(_ageLabel(st.items[i].ageHours)),
                                  ),
                                  DataCell(Text(st.items[i].businessName)),
                                  DataCell(
                                    Text(_formatPrice(st.items[i].amountCents)),
                                  ),
                                  DataCell(Text(st.items[i].claimantName)),
                                  DataCell(
                                    st.items[i].slaBreached
                                        ? const AppSlaBadge()
                                        : const Text('-'),
                                  ),
                                  DataCell(
                                    TextButton(
                                      onPressed: () =>
                                          _openDetails(context, st.items[i]),
                                      child: Text(l10n.adminCommonDetails),
                                    ),
                                  ),
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

  Future<void> _exportCsv(AdminSuspendedClaimsState st) async {
    setState(() => exporting = true);
    try {
      final repo = ref.read(adminSuspendedClaimsRepositoryProvider);
      final csv = await repo.exportCsv(
        status: st.statusFilter,
        slaOnly: st.slaOnly,
      );
      final filename = 'suspended_claims_${_stamp()}.csv';
      if (!mounted) return;
      downloadCsv(filename, csv);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Future<void> _openDetails(
    BuildContext context,
    AdminSuspendedClaimItem item,
  ) async {
    final l10n = context.l10n;
    final controller = ref.read(
      adminSuspendedClaimsControllerProvider.notifier,
    );
    controller.openDetail();
    final noteCtrl = TextEditingController(text: item.note);
    var loading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.slaBreached)
                  AppSlaBanner(
                    text: l10n.adminSuspendedClaimsSlaExceeded(
                      _ageLabel(item.ageHours),
                    ),
                  ),
                Text(
                  l10n.adminSuspendedClaimsDetailTitle,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Text('ID: ${item.id}'),
                Text('${l10n.businessLabel}: ${item.businessName}'),
                Text(
                  '${l10n.adminSuspendedClaimsAmountColumn}: ${_formatPrice(item.amountCents)}',
                ),
                Text(
                  '${l10n.adminSuspendedClaimsClaimantColumn}: ${item.claimantName} (${item.claimantId})',
                ),
                if (item.mealMessage.isNotEmpty)
                  Text(
                    '${l10n.adminSuspendedClaimsMealLabel}: ${item.mealMessage}',
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.adminSuspendedClaimsRejectNoteOptional,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: loading
                            ? null
                            : () async {
                                final ok = await _confirm(
                                  ctx,
                                  l10n.adminSuspendedClaimsApproveConfirm,
                                );
                                if (!ok) return;
                                setModalState(() => loading = true);
                                try {
                                  await ref
                                      .read(
                                        adminSuspendedClaimsControllerProvider
                                            .notifier,
                                      )
                                      .approve(item.id);
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.approved)),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppErrorMapper.message(e)),
                                    ),
                                  );
                                  setModalState(() => loading = false);
                                }
                              },
                        child: Text(
                          loading
                              ? l10n.adminCommonProcessing
                              : l10n.approved,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: loading
                            ? null
                            : () async {
                                final ok = await _confirm(
                                  ctx,
                                  l10n.adminSuspendedClaimsRejectConfirm,
                                );
                                if (!ok) return;
                                setModalState(() => loading = true);
                                try {
                                  await ref
                                      .read(
                                        adminSuspendedClaimsControllerProvider
                                            .notifier,
                                      )
                                      .reject(
                                        claimId: item.id,
                                        note: noteCtrl.text.trim(),
                                      );
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.rejected)),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppErrorMapper.message(e)),
                                    ),
                                  );
                                  setModalState(() => loading = false);
                                }
                              },
                        child: Text(
                          loading
                              ? l10n.adminCommonProcessing
                              : l10n.rejected,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go('/b/${item.businessId}'),
                  child: Text(l10n.adminPriceSuggestionsGoToBusiness),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      controller.closeDetail();
      noteCtrl.dispose();
    });
  }
}

WidgetStateProperty<Color?> _rowColor(bool slaBreached) =>
    appAdminSlaRowColor(slaBreached);

String _ageLabel(double hours) {
  if (hours >= 24) {
    final days = hours / 24.0;
    return '${days.toStringAsFixed(1)}d';
  }
  return '${hours.toStringAsFixed(1)}h';
}

String _formatPrice(int? cents) {
  if (cents == null) return '—';
  final value = cents / 100.0;
  final text = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  return '₺$text';
}

Future<bool> _confirm(BuildContext context, String message) async {
  final l10n = context.l10n;
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.adminCommonConfirmTitle),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.apply),
        ),
      ],
    ),
  );
  return res ?? false;
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
