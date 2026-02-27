import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/media/app_network_image.dart';
import '../../../core/network/supabase_provider.dart';
import '../../auth/domain/auth_providers.dart';
import '../data/admin_reports_repository.dart';
import '../domain/admin_models.dart';
import '../domain/admin_new_items_controller.dart';
import '../domain/admin_reports_controller.dart';
import 'keyboard/admin_keyboard_shortcuts.dart';
import 'web_download.dart';
import 'widgets/admin_new_items_banner.dart';
import '../../../shared/ui/design_system.dart';

class AdminReportsPage extends ConsumerStatefulWidget {
  const AdminReportsPage({super.key});

  @override
  ConsumerState<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends ConsumerState<AdminReportsPage> {
  final searchCtrl = TextEditingController();
  final searchFocus = FocusNode();
  final bulkNoteCtrl = TextEditingController();
  final scrollCtrl = ScrollController();
  String bulkStatus = '';
  bool exporting = false;
  bool moderationToolsLoading = false;
  int duplicatePhotoGroups = 0;
  int copiedMenuGroups = 0;

  @override
  void initState() {
    super.initState();
    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels >=
          scrollCtrl.position.maxScrollExtent - 300) {
        ref.read(adminReportsControllerProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    searchFocus.dispose();
    bulkNoteCtrl.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(adminReportsControllerProvider);
    final controller = ref.read(adminReportsControllerProvider.notifier);
    final user = ref.watch(userProvider);
    final allSelected =
        st.items.isNotEmpty &&
        st.items.every((r) => st.selectedIds.contains(r.id));
    final newItems = ref.watch(adminNewItemsProvider).reportsNew;
    final reasonCounts = <String, int>{};
    for (final item in st.items) {
      final key = item.reason.trim().isEmpty ? 'diÄŸer' : item.reason.trim();
      reasonCounts[key] = (reasonCounts[key] ?? 0) + 1;
    }
    final sortedReasons = reasonCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AdminKeyboardShortcuts(
      enabled: st.selectedIds.isEmpty,
      onNext: () => controller.next(),
      onPrev: () => controller.prev(),
      onToggleModal: () => _toggleDetail(st),
      onCloseModal: _closeDetail,
      onFocusSearch: () => searchFocus.requestFocus(),
      onAssignToggle: () => _toggleAssign(st, user?.id),
      onAction: (key) => _handleAction(st, key),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Raporlar',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: exporting ? null : () => _exportCsv(st),
                  icon: const Icon(Icons.download),
                  label: Text(
                    exporting ? 'Ä°ndiriliyor...' : 'CSV DÄ±ÅŸa Aktar',
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    final ok = await ref
                        .read(adminReportsControllerProvider.notifier)
                        .refresh(force: true);
                    if (!context.mounted) return;
                    if (ok) {
                      ref.read(adminNewItemsProvider.notifier).clearReports();
                    }
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    focusNode: searchFocus,
                    onChanged: (v) => ref
                        .read(adminReportsControllerProvider.notifier)
                        .setQuery(v.trim()),
                    decoration: const InputDecoration(
                      hintText: 'Ara (id, reason, detay)',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    AppFilterChip(
                      label: 'SLA',
                      selected: st.slaOnly,
                      onTap: () => ref
                          .read(adminReportsControllerProvider.notifier)
                          .setSlaOnly(!st.slaOnly),
                    ),
                    AppFilterChip(
                      label: 'TÃ¼mÃ¼',
                      selected: st.statusFilter.isEmpty,
                      onTap: () => ref
                          .read(adminReportsControllerProvider.notifier)
                          .setStatusFilter(''),
                    ),
                    AppFilterChip(
                      label: 'AÃ§Ä±k',
                      selected: st.statusFilter == 'acik',
                      onTap: () => ref
                          .read(adminReportsControllerProvider.notifier)
                          .setStatusFilter('acik'),
                    ),
                    AppFilterChip(
                      label: 'Ä°nceleniyor',
                      selected: st.statusFilter == 'inceleniyor',
                      onTap: () => ref
                          .read(adminReportsControllerProvider.notifier)
                          .setStatusFilter('inceleniyor'),
                    ),
                    AppFilterChip(
                      label: 'KapandÄ±',
                      selected: st.statusFilter == 'kapandi',
                      onTap: () => ref
                          .read(adminReportsControllerProvider.notifier)
                          .setStatusFilter('kapandi'),
                    ),
                    AppFilterChip(
                      label: 'Reddedildi',
                      selected: st.statusFilter == 'reddedildi',
                      onTap: () => ref
                          .read(adminReportsControllerProvider.notifier)
                          .setStatusFilter('reddedildi'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                AppFilterChip(
                  label: 'TÃ¼mÃ¼',
                  selected: st.assignedFilter.isEmpty,
                  onTap: () => ref
                      .read(adminReportsControllerProvider.notifier)
                      .setAssignedFilter(''),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'BoÅŸta',
                  selected: st.assignedFilter == 'unassigned',
                  onTap: () => ref
                      .read(adminReportsControllerProvider.notifier)
                      .setAssignedFilter('unassigned'),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'Benim',
                  selected: st.assignedFilter == 'me',
                  onTap: () => ref
                      .read(adminReportsControllerProvider.notifier)
                      .setAssignedFilter('me'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (sortedReasons.isNotEmpty) ...[
              _ReasonSummaryCard(items: sortedReasons),
              const SizedBox(height: 12),
            ],
            _ModerationToolsCard(
              loading: moderationToolsLoading,
              duplicatePhotoGroups: duplicatePhotoGroups,
              copiedMenuGroups: copiedMenuGroups,
              onRun: _runModerationScans,
            ),
            const SizedBox(height: 12),

            AdminNewItemsBanner(
              count: newItems,
              label: 'Yeni kayÄ±tlar var',
              onRefresh: () async {
                final ok = await ref
                    .read(adminReportsControllerProvider.notifier)
                    .refresh(force: true);
                if (!context.mounted) return;
                if (ok) {
                  ref.read(adminNewItemsProvider.notifier).clearReports();
                }
              },
            ),
            if (newItems > 0) const SizedBox(height: 10),

            _BulkBar(
              selectedCount: st.selectedIds.length,
              bulkStatus: bulkStatus,
              onStatusChanged: (v) => setState(() => bulkStatus = v),
              noteCtrl: bulkNoteCtrl,
              onClear: () => ref
                  .read(adminReportsControllerProvider.notifier)
                  .clearSelection(),
              onApply: st.selectedIds.isEmpty || bulkStatus.isEmpty
                  ? null
                  : () async {
                      try {
                        await ref
                            .read(adminReportsControllerProvider.notifier)
                            .bulkUpdateStatus(
                              status: bulkStatus,
                              adminNote: bulkNoteCtrl.text.trim(),
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('GÃ¼ncellendi.')),
                          );
                        }
                        setState(() => bulkStatus = '');
                        bulkNoteCtrl.clear();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppErrorMapper.message(e))),
                          );
                        }
                      }
                    },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: st.selectedIndex == null
                      ? null
                      : () => _selectSameReporter(st),
                  icon: const Icon(Icons.group_work_outlined),
                  label: const Text('AynÄ± HesabÄ± SeÃ§'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: st.selectedIds.isEmpty || user?.id == null
                      ? null
                      : () => _assignSelectedToMe(st, user!.id),
                  icon: const Icon(Icons.assignment_ind_outlined),
                  label: const Text('SeÃ§ili KayÄ±tlarÄ± Bana Ata'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: st.selectedIds.isEmpty
                      ? null
                      : () => _closeSelectedAsSpam(st),
                  icon: const Icon(Icons.block_outlined),
                  label: const Text('Spam DalgasÄ±nÄ± Kapat'),
                ),
              ],
            ),
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
                              DataColumn(
                                label: Checkbox(
                                  value: allSelected,
                                  onChanged: (v) => ref
                                      .read(
                                        adminReportsControllerProvider.notifier,
                                      )
                                      .selectAllVisible(v ?? false),
                                ),
                              ),
                              const DataColumn(label: Text('ID')),
                              const DataColumn(label: Text('Sebep')),
                              const DataColumn(label: Text('Ã–ncelik')),
                              const DataColumn(label: Text('Durum')),
                              const DataColumn(label: Text('Atanan')),
                              const DataColumn(label: Text('OluÅŸturulma')),
                              const DataColumn(label: Text('YaÅŸ')),
                              const DataColumn(label: Text('Foto')),
                              const DataColumn(label: Text('')),
                            ],
                            rows: [
                              for (var i = 0; i < st.items.length; i++)
                                DataRow(
                                  color: _rowColor(
                                    st.selectedIndex == i,
                                    st.items[i].slaBreached,
                                  ),
                                  selected: st.selectedIds.contains(
                                    st.items[i].id,
                                  ),
                                  onSelectChanged: (_) => _openDetails(
                                    context,
                                    st.items[i],
                                    index: i,
                                  ),
                                  cells: [
                                    DataCell(
                                      Checkbox(
                                        value: st.selectedIds.contains(
                                          st.items[i].id,
                                        ),
                                        onChanged: (v) => ref
                                            .read(
                                              adminReportsControllerProvider
                                                  .notifier,
                                            )
                                            .toggleSelection(
                                              st.items[i].id,
                                              v ?? false,
                                            ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          if (st.items[i].slaBreached) ...[
                                            const AppSlaBadge(),
                                            const SizedBox(width: 6),
                                          ],
                                          Text(_short(st.items[i].id)),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text(st.items[i].reason)),
                                    DataCell(
                                      AppPriorityBadge(
                                        score: _reportPriority(st.items[i]),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          Text(st.items[i].status),
                                          if (st.items[i].autoModerated) ...[
                                            const SizedBox(width: 6),
                                            Tooltip(
                                              message:
                                                  'Otomatik moderasyon uygulandÄ±',
                                              child: const AppAutoBadge(),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        _assignedLabel(
                                          st.items[i].assignedTo,
                                          user?.id,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(_fmtDate(st.items[i].createdAt)),
                                    ),
                                    DataCell(
                                      Text(_fmtHours(st.items[i].ageHours)),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          if ((st.items[i].menuItemPhotoId ??
                                                  '')
                                              .isNotEmpty)
                                            IconButton(
                                              onPressed: () =>
                                                  _openReportedMenuPhoto(
                                                    context,
                                                    ref,
                                                    st
                                                        .items[i]
                                                        .menuItemPhotoId!,
                                                  ),
                                              tooltip: 'MenÃ¼ fotoÄŸrafÄ±',
                                              icon: const Icon(
                                                Icons.photo_outlined,
                                                size: 18,
                                              ),
                                            ),
                                          if ((st.items[i].targetType ?? '') ==
                                                  'business_media' &&
                                              (st.items[i].targetId ?? '')
                                                  .isNotEmpty)
                                            IconButton(
                                              onPressed: () =>
                                                  _openReportedBusinessMedia(
                                                    context,
                                                    ref,
                                                    st.items[i].targetId!,
                                                  ),
                                              tooltip: 'Mekan fotoÄŸrafÄ±',
                                              icon: const Icon(
                                                Icons.storefront_outlined,
                                                size: 18,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      TextButton(
                                        onPressed: () => _openDetails(
                                          context,
                                          st.items[i],
                                          index: i,
                                        ),
                                        child: const Text('Detay'),
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
                            child: Center(child: Text('Kayit bulunamadi.')),
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
      ),
    );
  }

  Future<void> _exportCsv(AdminReportsState st) async {
    setState(() => exporting = true);
    try {
      final repo = ref.read(adminReportsRepositoryProvider);
      final csv = await repo.exportCsv(
        status: st.statusFilter,
        query: st.query,
      );
      final filename = 'reports_${_stamp()}.csv';
      if (!mounted) return;
      downloadCsv(filename, csv);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    } finally {
      if (mounted) {
        setState(() => exporting = false);
      }
    }
  }

  Future<void> _openDetails(
    BuildContext context,
    AdminReportItem item, {
    int? index,
  }) async {
    final controller = ref.read(adminReportsControllerProvider.notifier);
    if (index != null) {
      controller.selectIndex(index);
    }
    controller.openDetail();
    final userId = ref.read(userProvider)?.id;
    final noteCtrl = TextEditingController(text: item.adminNote ?? '');
    var status = item.status;
    var loading = false;
    var applyingRules = false;

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
                    text: 'Bu kayit SLA aÃ§tÄ±: ${_fmtHours(item.ageHours)}',
                  ),
                const Text(
                  'Rapor DetayÄ±',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Text('ID: ${item.id}'),
                if ((item.businessId ?? '').isNotEmpty)
                  Text('Ä°ÅŸletme: ${item.businessId}'),
                if ((item.reviewId ?? '').isNotEmpty)
                  Text('Ä°nceleme: ${item.reviewId}'),
                if ((item.menuItemPhotoId ?? '').isNotEmpty)
                  Text('MenÃ¼ FotoÄŸrafÄ±: ${item.menuItemPhotoId}'),
                if ((item.targetType ?? '').isNotEmpty)
                  Text('Hedef: ${item.targetType} / ${item.targetId ?? '-'}'),
                if ((item.menuItemPhotoId ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: () => _openReportedMenuPhoto(
                      context,
                      ref,
                      item.menuItemPhotoId!,
                    ),
                    icon: const Icon(Icons.photo_outlined),
                    label: const Text('FotoÄŸrafÄ± AÃ§'),
                  ),
                  const SizedBox(height: 6),
                  _ShadowInfo(
                    label: 'MenÃ¼ FotoÄŸrafÄ±',
                    future: _fetchMenuPhotoShadow(ref, item.menuItemPhotoId!),
                  ),
                ],
                if ((item.targetType ?? '') == 'business_media' &&
                    (item.targetId ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: () => _openReportedBusinessMedia(
                      context,
                      ref,
                      item.targetId!,
                    ),
                    icon: const Icon(Icons.photo_outlined),
                    label: const Text('FotoÄŸrafÄ± AÃ§'),
                  ),
                  const SizedBox(height: 6),
                  _ShadowInfo(
                    label: 'Mekan FotoÄŸrafÄ±',
                    future: _fetchBusinessMediaShadow(ref, item.targetId!),
                  ),
                ],
                const SizedBox(height: 6),
                Text('Sebep: ${item.reason}'),
                if ((item.details ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Detay: ${item.details}'),
                ],
                const SizedBox(height: 10),
                Text('Atanan: ${_assignedLabel(item.assignedTo, userId)}'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey(status),
                  initialValue: status,
                  items: const [
                    DropdownMenuItem(value: 'acik', child: Text('AÃ§Ä±k')),
                    DropdownMenuItem(
                      value: 'inceleniyor',
                      child: Text('Ä°nceleniyor'),
                    ),
                    DropdownMenuItem(value: 'kapandi', child: Text('KapandÄ±')),
                    DropdownMenuItem(
                      value: 'reddedildi',
                      child: Text('Reddedildi'),
                    ),
                  ],
                  onChanged: loading
                      ? null
                      : (v) => setModalState(() => status = v ?? status),
                  decoration: const InputDecoration(labelText: 'Durum'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Admin Notu (opsiyonel)',
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _reportDecisionTemplates
                      .map(
                        (template) => ActionChip(
                          label: Text(template),
                          onPressed: () {
                            noteCtrl.text = template;
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Otomatik Kurallar',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: loading || applyingRules
                        ? null
                        : () async {
                            setModalState(() => applyingRules = true);
                            try {
                              final applied = await ref
                                  .read(adminReportsControllerProvider.notifier)
                                  .applyRules(item.id);
                              if (!context.mounted) return;
                              if (applied) {
                                ref
                                    .read(adminNewItemsProvider.notifier)
                                    .clearReports();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Otomatik kural uygulandÄ±.'),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Uygun otomatik kural bulunamadÄ±',
                                    ),
                                  ),
                                );
                                setModalState(() => applyingRules = false);
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppErrorMapper.message(e)),
                                ),
                              );
                              setModalState(() => applyingRules = false);
                            }
                          },
                    icon: const Icon(Icons.auto_fix_high),
                    label: Text(
                      applyingRules ? 'UygulanÄ±yor...' : 'KurallarÄ± Uygula',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (userId != null &&
                        (item.assignedTo == null ||
                            item.assignedTo != userId)) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: loading
                              ? null
                              : () async {
                                  setModalState(() => loading = true);
                                  try {
                                    await ref
                                        .read(
                                          adminReportsControllerProvider
                                              .notifier,
                                        )
                                        .assignToMe(item.id, adminId: userId);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Ãœzerine alÄ±ndÄ±.'),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppErrorMapper.message(e),
                                          ),
                                        ),
                                      );
                                    }
                                    setModalState(() => loading = false);
                                  }
                                },
                          child: Text(loading ? 'Ä°ÅŸleniyor...' : 'Bana Ata'),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (item.assignedTo != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: loading
                              ? null
                              : () async {
                                  setModalState(() => loading = true);
                                  try {
                                    await ref
                                        .read(
                                          adminReportsControllerProvider
                                              .notifier,
                                        )
                                        .unassign(item.id);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Atama kaldÄ±rÄ±ldÄ±.'),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppErrorMapper.message(e),
                                          ),
                                        ),
                                      );
                                    }
                                    setModalState(() => loading = false);
                                  }
                                },
                          child: Text(
                            loading ? 'Ä°ÅŸleniyor...' : 'AtamayÄ± KaldÄ±r',
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading
                        ? null
                        : () async {
                            setModalState(() => loading = true);
                            try {
                              await ref
                                  .read(adminReportsControllerProvider.notifier)
                                  .updateStatus(
                                    reportId: item.id,
                                    status: status,
                                    adminNote: noteCtrl.text.trim(),
                                  );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('GÃ¼ncellendi.'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppErrorMapper.message(e)),
                                  ),
                                );
                              }
                              setModalState(() => loading = false);
                            }
                          },
                    child: Text(loading ? 'Kaydediliyor...' : 'Kaydet'),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      controller.closeDetail();
    });
  }

  void _closeDetail() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    ref.read(adminReportsControllerProvider.notifier).closeDetail();
  }

  void _toggleDetail(AdminReportsState st) {
    if (st.isDetailOpen) {
      _closeDetail();
      return;
    }
    if (st.selectedIndex == null || st.selectedIndex! >= st.items.length) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('SatÄ±r seÃ§')));
      return;
    }
    final item = st.items[st.selectedIndex!];
    _openDetails(context, item, index: st.selectedIndex);
  }

  Future<void> _toggleAssign(AdminReportsState st, String? userId) async {
    if (userId == null) return;
    if (st.selectedIndex == null || st.selectedIndex! >= st.items.length) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('SatÄ±r seÃ§')));
      return;
    }
    final item = st.items[st.selectedIndex!];
    try {
      final controller = ref.read(adminReportsControllerProvider.notifier);
      if (item.assignedTo == userId) {
        await controller.unassign(item.id);
      } else {
        await controller.assignToMe(item.id, adminId: userId);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _handleAction(AdminReportsState st, String key) async {
    if (st.selectedIndex == null || st.selectedIndex! >= st.items.length) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('SatÄ±r seÃ§')));
      return;
    }
    final item = st.items[st.selectedIndex!];
    String? status;
    if (key == 'I') status = 'inceleniyor';
    if (key == 'C') status = 'kapandi';
    if (key == 'R') status = 'reddedildi';
    if (status == null) return;
    try {
      await ref
          .read(adminReportsControllerProvider.notifier)
          .updateStatus(reportId: item.id, status: status);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _selectSameReporter(AdminReportsState st) async {
    if (st.selectedIndex == null || st.selectedIndex! >= st.items.length) {
      return;
    }
    final seed = st.items[st.selectedIndex!];
    final reporterId = (seed.reporterId ?? '').trim();
    if (reporterId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu kayÄ±tta reporter bilgisi yok.')),
      );
      return;
    }
    final ids = st.items
        .where((r) => (r.reporterId ?? '').trim() == reporterId)
        .map((r) => r.id)
        .toSet();
    for (final itemId in ids) {
      ref
          .read(adminReportsControllerProvider.notifier)
          .toggleSelection(itemId, true);
    }
  }

  Future<void> _closeSelectedAsSpam(AdminReportsState st) async {
    try {
      await ref
          .read(adminReportsControllerProvider.notifier)
          .bulkUpdateStatus(
            status: 'kapandi',
            adminNote: 'Toplu: spam dalgasÄ± nedeniyle kapatÄ±ldÄ±',
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SeÃ§ili raporlar kapatÄ±ldÄ±.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _assignSelectedToMe(AdminReportsState st, String adminId) async {
    final controller = ref.read(adminReportsControllerProvider.notifier);
    final selected = st.items
        .where((r) => st.selectedIds.contains(r.id))
        .toList();
    if (selected.isEmpty) return;
    var assigned = 0;
    for (final item in selected) {
      try {
        await controller.assignToMe(item.id, adminId: adminId);
        assigned++;
      } catch (_) {
        // Continue with the rest.
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$assigned rapor sana atandÄ±.')));
  }

  Future<void> _runModerationScans() async {
    setState(() => moderationToolsLoading = true);
    try {
      final client = ref.read(supabaseProvider);
      final photoGroups = await _detectDuplicatePhotos(client);
      final menuGroups = await _detectCopiedMenus(client);
      if (!mounted) return;
      setState(() {
        duplicatePhotoGroups = photoGroups;
        copiedMenuGroups = menuGroups;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tarama tamamlandÄ±. Benzer foto grup: $photoGroups, menÃ¼ kopya grup: $menuGroups',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    } finally {
      if (mounted) {
        setState(() => moderationToolsLoading = false);
      }
    }
  }
}

Future<int> _detectDuplicatePhotos(dynamic client) async {
  final res = await client
      .from('menu_item_photos')
      .select('id,business_id,url')
      .order('created_at', ascending: false)
      .limit(1200);
  final rows = (res as List?) ?? const [];
  final groups = <String, Set<String>>{};
  for (final row in rows.whereType<Map>()) {
    final map = row.cast<String, dynamic>();
    final businessId = (map['business_id'] ?? '').toString();
    final url = (map['url'] ?? '').toString();
    if (businessId.isEmpty || url.isEmpty) continue;
    final sig = _photoSignature(url);
    if (sig.isEmpty) continue;
    groups.putIfAbsent(sig, () => <String>{}).add(businessId);
  }
  return groups.values.where((bids) => bids.length >= 2).length;
}

Future<int> _detectCopiedMenus(dynamic client) async {
  final res = await client
      .from('menu_items')
      .select('id,business_id,name,price_cents,status')
      .eq('status', 'published')
      .order('updated_at', ascending: false)
      .limit(2000);
  final rows = (res as List?) ?? const [];
  final groups = <String, Set<String>>{};
  for (final row in rows.whereType<Map>()) {
    final map = row.cast<String, dynamic>();
    final businessId = (map['business_id'] ?? '').toString();
    final name = (map['name'] ?? '').toString().trim().toLowerCase();
    final price = (map['price_cents'] ?? '').toString();
    if (businessId.isEmpty || name.isEmpty || price.isEmpty) continue;
    final sig = '$name|$price';
    groups.putIfAbsent(sig, () => <String>{}).add(businessId);
  }
  return groups.values.where((bids) => bids.length >= 3).length;
}

String _photoSignature(String url) {
  final clean = url.split('?').first;
  final file = clean.split('/').isNotEmpty ? clean.split('/').last : clean;
  final base = file.toLowerCase().replaceAll(
    RegExp(r'\.(jpg|jpeg|png|webp)$'),
    '',
  );
  final compact = base.replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (compact.length < 6) return '';
  return compact;
}

class _ReasonSummaryCard extends StatelessWidget {
  const _ReasonSummaryCard({required this.items});

  final List<MapEntry<String, int>> items;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (sum, e) => sum + e.value);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sebep DaÄŸÄ±lÄ±mÄ± ($total)',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in items.take(8))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${e.key}: ${e.value}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModerationToolsCard extends StatelessWidget {
  const _ModerationToolsCard({
    required this.loading,
    required this.duplicatePhotoGroups,
    required this.copiedMenuGroups,
    required this.onRun,
  });

  final bool loading;
  final int duplicatePhotoGroups;
  final int copiedMenuGroups;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Moderasyon: Benzer foto grup $duplicatePhotoGroups, Kopya menÃ¼ grup $copiedMenuGroups',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: loading ? null : onRun,
            icon: loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_fix_high_outlined),
            label: Text(loading ? 'TarÄ±yor...' : 'Tara'),
          ),
        ],
      ),
    );
  }
}

class _BulkBar extends StatelessWidget {
  const _BulkBar({
    required this.selectedCount,
    required this.bulkStatus,
    required this.onStatusChanged,
    required this.noteCtrl,
    required this.onClear,
    required this.onApply,
  });

  final int selectedCount;
  final String bulkStatus;
  final ValueChanged<String> onStatusChanged;
  final TextEditingController noteCtrl;
  final VoidCallback onClear;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'SeÃ§ili: $selectedCount',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String>(
            key: ValueKey(bulkStatus),
            initialValue: bulkStatus.isEmpty ? null : bulkStatus,
            items: const [
              DropdownMenuItem(value: 'acik', child: Text('AÃ§Ä±k')),
              DropdownMenuItem(
                value: 'inceleniyor',
                child: Text('Ä°nceleniyor'),
              ),
              DropdownMenuItem(value: 'kapandi', child: Text('KapandÄ±')),
              DropdownMenuItem(value: 'reddedildi', child: Text('Reddedildi')),
            ],
            onChanged: (v) => onStatusChanged(v ?? ''),
            decoration: const InputDecoration(labelText: 'Durum'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Admin Notu (opsiyonel)',
            ),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton(onPressed: onClear, child: const Text('Temizle')),
        const SizedBox(width: 8),
        FilledButton(onPressed: onApply, child: const Text('Uygula')),
      ],
    );
  }
}

String _short(String id) => id.length > 8 ? '${id.substring(0, 8)}...' : id;

int _reportPriority(AdminReportItem item) {
  var score = 0;
  if (item.slaBreached) score += 70;
  if (item.ageHours >= 48) score += 25;
  if (item.reason.toLowerCase().contains('spam')) score += 20;
  if ((item.reporterId ?? '').isEmpty) score += 10;
  return score;
}

WidgetStateProperty<Color?> _rowColor(bool active, bool slaBreached) =>
    appAdminRowColor(active: active, slaBreached: slaBreached);

String _assignedLabel(String? assignedTo, String? userId) {
  if (assignedTo == null || assignedTo.isEmpty) return 'BoÅŸ';
  if (userId != null && assignedTo == userId) return 'Ben';
  return 'BaÅŸka admin';
}

String _fmtHours(double v) => '${v.toStringAsFixed(1)}saat';

const List<String> _reportDecisionTemplates = <String>[
  'Ihlal teyit edildi, gerekli islem uygulandi.',
  'Kanit yetersiz, rapor kapatildi.',
  'Ek bilgi gerekiyor, kayit inceleniyor.',
];

Future<void> _openReportedMenuPhoto(
  BuildContext context,
  WidgetRef ref,
  String photoId,
) async {
  try {
    final res = await ref
        .read(supabaseProvider)
        .from('menu_item_photos')
        .select('url,url_large,url_thumb')
        .eq('id', photoId)
        .maybeSingle();
    if (res == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('FotoÄŸraf bulunamadÄ±')));
      }
      return;
    }
    final map = res.cast<String, dynamic>();
    final url = (map['url_large'] ?? map['url_thumb'] ?? map['url'] ?? '')
        .toString();
    if (url.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('FotoÄŸraf bulunamadÄ±')));
      }
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: AppNetworkImage(
                url: url,
                variant: AppImageVariant.medium,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }
}

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
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

Future<void> _openReportedBusinessMedia(
  BuildContext context,
  WidgetRef ref,
  String mediaId,
) async {
  try {
    final res = await ref
        .read(supabaseProvider)
        .from('business_media')
        .select('url,url_large,url_thumb')
        .eq('id', mediaId)
        .maybeSingle();
    if (res == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('FotoÄŸraf bulunamadÄ±')));
      }
      return;
    }
    final map = res.cast<String, dynamic>();
    final url = (map['url_large'] ?? map['url_thumb'] ?? map['url'] ?? '')
        .toString();
    if (url.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('FotoÄŸraf bulunamadÄ±')));
      }
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: AppNetworkImage(
                url: url,
                variant: AppImageVariant.medium,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.35),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }
}

Future<bool?> _fetchMenuPhotoShadow(WidgetRef ref, String photoId) async {
  final res = await ref
      .read(supabaseProvider)
      .from('menu_item_photos')
      .select('is_shadow')
      .eq('id', photoId)
      .maybeSingle();
  if (res == null) return null;
  return (res['is_shadow'] ?? false) == true;
}

Future<bool?> _fetchBusinessMediaShadow(WidgetRef ref, String mediaId) async {
  final res = await ref
      .read(supabaseProvider)
      .from('business_media')
      .select('is_shadow')
      .eq('id', mediaId)
      .maybeSingle();
  if (res == null) return null;
  return (res['is_shadow'] ?? false) == true;
}

class _ShadowInfo extends StatelessWidget {
  const _ShadowInfo({required this.label, required this.future});

  final String label;
  final Future<bool?> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text('$label Â· gÃ¶rÃ¼nÃ¼rlÃ¼k yÃ¼kleniyor...');
        }
        final value = snapshot.data;
        if (value == null) {
          return Text('$label Â· gÃ¶rÃ¼nÃ¼rlÃ¼k bilinmiyor');
        }
        return Text(
          value ? '$label Â· gÃ¶lge (gizli)' : '$label Â· normal (aÃ§Ä±k)',
        );
      },
    );
  }
}
