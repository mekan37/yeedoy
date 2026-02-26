import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/errors/app_error_mapper.dart';
import '../../../../features/auth/domain/auth_providers.dart';
import '../data/admin_claims_repository.dart';
import '../domain/admin_claims_controller.dart';
import '../domain/admin_models.dart';
import '../domain/admin_new_items_controller.dart';
import 'keyboard/admin_keyboard_shortcuts.dart';
import 'web_download.dart';
import 'widgets/admin_new_items_banner.dart';
import '../../../ui/design_system.dart';

class AdminClaimsPage extends ConsumerStatefulWidget {
  const AdminClaimsPage({super.key});

  @override
  ConsumerState<AdminClaimsPage> createState() => _AdminClaimsPageState();
}

class _AdminClaimsPageState extends ConsumerState<AdminClaimsPage> {
  final searchCtrl = TextEditingController();
  final searchFocus = FocusNode();
  final bulkNoteCtrl = TextEditingController();
  final scrollCtrl = ScrollController();
  String bulkDecision = '';
  bool exporting = false;

  @override
  void initState() {
    super.initState();
    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels >=
          scrollCtrl.position.maxScrollExtent - 300) {
        ref.read(adminClaimsControllerProvider.notifier).loadMore();
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
    final st = ref.watch(adminClaimsControllerProvider);
    final controller = ref.read(adminClaimsControllerProvider.notifier);
    final user = ref.watch(userProvider);
    final allSelected =
        st.items.isNotEmpty &&
        st.items.every((c) => st.selectedIds.contains(c.id));
    final newItems = ref.watch(adminNewItemsProvider).claimsNew;

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
                  'Sahiplik Talepleri',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: exporting ? null : () => _exportCsv(st),
                  icon: const Icon(Icons.download),
                  label: Text(
                    exporting ? 'Ã„Â°ndiriliyor...' : 'CSV DÃ„Â±Ã…Å¸a Aktar',
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    final ok = await ref
                        .read(adminClaimsControllerProvider.notifier)
                        .refresh(force: true);
                    if (!context.mounted) return;
                    if (ok) {
                      ref.read(adminNewItemsProvider.notifier).clearClaims();
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
                        .read(adminClaimsControllerProvider.notifier)
                        .setQuery(v.trim()),
                    decoration: const InputDecoration(
                      hintText: 'Ara (id, isim, telefon)',
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
                          .read(adminClaimsControllerProvider.notifier)
                          .setSlaOnly(!st.slaOnly),
                    ),
                    AppFilterChip(
                      label: 'TÃƒÂ¼mÃƒÂ¼',
                      selected: st.statusFilter.isEmpty,
                      onTap: () => ref
                          .read(adminClaimsControllerProvider.notifier)
                          .setStatusFilter(''),
                    ),
                    AppFilterChip(
                      label: 'Beklemede',
                      selected: st.statusFilter == 'pending',
                      onTap: () => ref
                          .read(adminClaimsControllerProvider.notifier)
                          .setStatusFilter('pending'),
                    ),
                    AppFilterChip(
                      label: 'OnaylandÃ„Â±',
                      selected: st.statusFilter == 'approved',
                      onTap: () => ref
                          .read(adminClaimsControllerProvider.notifier)
                          .setStatusFilter('approved'),
                    ),
                    AppFilterChip(
                      label: 'Reddedildi',
                      selected: st.statusFilter == 'rejected',
                      onTap: () => ref
                          .read(adminClaimsControllerProvider.notifier)
                          .setStatusFilter('rejected'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                AppFilterChip(
                  label: 'TÃƒÂ¼mÃƒÂ¼',
                  selected: st.assignedFilter.isEmpty,
                  onTap: () => ref
                      .read(adminClaimsControllerProvider.notifier)
                      .setAssignedFilter(''),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'BoÃ…Å¸ta',
                  selected: st.assignedFilter == 'unassigned',
                  onTap: () => ref
                      .read(adminClaimsControllerProvider.notifier)
                      .setAssignedFilter('unassigned'),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'Benim',
                  selected: st.assignedFilter == 'me',
                  onTap: () => ref
                      .read(adminClaimsControllerProvider.notifier)
                      .setAssignedFilter('me'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            AdminNewItemsBanner(
              count: newItems,
              label: 'Yeni kayÃ„Â±tlar var',
              onRefresh: () async {
                final ok = await ref
                    .read(adminClaimsControllerProvider.notifier)
                    .refresh(force: true);
                if (!context.mounted) return;
                if (ok) {
                  ref.read(adminNewItemsProvider.notifier).clearClaims();
                }
              },
            ),
            if (newItems > 0) const SizedBox(height: 10),

            _BulkBar(
              selectedCount: st.selectedIds.length,
              bulkDecision: bulkDecision,
              onDecisionChanged: (v) => setState(() => bulkDecision = v),
              noteCtrl: bulkNoteCtrl,
              onClear: () => ref
                  .read(adminClaimsControllerProvider.notifier)
                  .clearSelection(),
              onApply: st.selectedIds.isEmpty || bulkDecision.isEmpty
                  ? null
                  : () async {
                      try {
                        await ref
                            .read(adminClaimsControllerProvider.notifier)
                            .bulkDecide(
                              decision: bulkDecision,
                              note: bulkNoteCtrl.text.trim(),
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('GÃƒÂ¼ncellendi.')),
                          );
                        }
                        setState(() => bulkDecision = '');
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
                      : () => _selectSamePhone(st),
                  icon: const Icon(Icons.group_work_outlined),
                  label: const Text('AynÃ„Â± Telefonu SeÃƒÂ§'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: st.selectedIds.isEmpty || user?.id == null
                      ? null
                      : () => _assignSelectedToMe(st, user!.id),
                  icon: const Icon(Icons.assignment_ind_outlined),
                  label: const Text('SeÃƒÂ§ilileri Bana Ata'),
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
                                        adminClaimsControllerProvider.notifier,
                                      )
                                      .selectAllVisible(v ?? false),
                                ),
                              ),
                              const DataColumn(label: Text('ID')),
                              const DataColumn(label: Text('Ad Soyad')),
                              const DataColumn(label: Text('Oncelik')),
                              const DataColumn(label: Text('Durum')),
                              const DataColumn(label: Text('Atanan')),
                              const DataColumn(label: Text('OluÃ…Å¸turulma')),
                              const DataColumn(label: Text('YaÃ…Å¸')),
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
                                              adminClaimsControllerProvider
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
                                    DataCell(Text(st.items[i].fullName)),
                                    DataCell(
                                      AppPriorityBadge(
                                        score: _claimPriority(st.items[i]),
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
                                                  'Otomatik moderasyon uygulandÃ„Â±',
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
                                      Text(_fmtDays(st.items[i].ageDays)),
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

  Future<void> _exportCsv(AdminClaimsState st) async {
    setState(() => exporting = true);
    try {
      final repo = ref.read(adminClaimsRepositoryProvider);
      final csv = await repo.exportCsv(
        status: st.statusFilter,
        query: st.query,
      );
      final filename = 'claims_${_stamp()}.csv';
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
    AdminOwnerClaimItem item, {
    int? index,
  }) async {
    final controller = ref.read(adminClaimsControllerProvider.notifier);
    if (index != null) {
      controller.selectIndex(index);
    }
    controller.openDetail();
    final userId = ref.read(userProvider)?.id;
    final noteCtrl = TextEditingController(text: item.adminNote ?? '');
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
                    text:
                        'Bu kayÃ„Â±t SLA aÃƒÂ§tÃ„Â±: ${_fmtDays(item.ageDays)}',
                  ),
                const Text(
                  'KayÃ„Â±t DetayÃ„Â±',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Text('ID: ${item.id}'),
                if ((item.businessId ?? '').isNotEmpty)
                  Text('Ã„Â°Ã…Å¸letme: ${item.businessId}'),
                const SizedBox(height: 6),
                Text('Ad Soyad: ${item.fullName}'),
                Text('Telefon: ${item.phone}'),
                if ((item.evidenceUrl ?? '').isNotEmpty)
                  Text('KanÃ„Â±t: ${item.evidenceUrl}'),
                if ((item.note ?? '').isNotEmpty) Text('Not: ${item.note}'),
                const SizedBox(height: 10),
                Text('Atanan: ${_assignedLabel(item.assignedTo, userId)}'),
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
                  children: _claimDecisionTemplates
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
                                  .read(adminClaimsControllerProvider.notifier)
                                  .applyRules(item.id);
                              if (!context.mounted) return;
                              if (applied) {
                                ref
                                    .read(adminNewItemsProvider.notifier)
                                    .clearClaims();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Otomatik kural uygulandÃ„Â±.',
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Uygun otomatik kural bulunamadÃ„Â±',
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
                      applyingRules
                          ? 'UygulanÃ„Â±yor...'
                          : 'KurallarÃ„Â± Uygula',
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
                                          adminClaimsControllerProvider
                                              .notifier,
                                        )
                                        .assignToMe(item.id, adminId: userId);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Ã„Â°Ã…Å¸lem bitti.'),
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
                            loading ? 'Ã„Â°Ã…Å¸leniyor...' : 'Bana Ata',
                          ),
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
                                          adminClaimsControllerProvider
                                              .notifier,
                                        )
                                        .unassign(item.id);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Atama kaldÃ„Â±rÃ„Â±ldÃ„Â±.',
                                          ),
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
                            loading
                                ? 'Ã„Â°Ã…Å¸leniyor...'
                                : 'AtamayÃ„Â± KaldÃ„Â±r',
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: loading
                            ? null
                            : () async {
                                setModalState(() => loading = true);
                                try {
                                  await ref
                                      .read(
                                        adminClaimsControllerProvider.notifier,
                                      )
                                      .decide(
                                        claimId: item.id,
                                        decision: 'approved',
                                        note: noteCtrl.text.trim(),
                                      );
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('OnaylandÃ„Â±.'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                        child: Text(loading ? 'Ã„Â°Ã…Å¸leniyor...' : 'Onayla'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: loading
                            ? null
                            : () async {
                                setModalState(() => loading = true);
                                try {
                                  await ref
                                      .read(
                                        adminClaimsControllerProvider.notifier,
                                      )
                                      .decide(
                                        claimId: item.id,
                                        decision: 'rejected',
                                        note: noteCtrl.text.trim(),
                                      );
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Reddedildi.'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                        child: Text(loading ? 'Ã„Â°Ã…Å¸leniyor...' : 'Reddet'),
                      ),
                    ),
                  ],
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
    ref.read(adminClaimsControllerProvider.notifier).closeDetail();
  }

  void _toggleDetail(AdminClaimsState st) {
    if (st.isDetailOpen) {
      _closeDetail();
      return;
    }
    if (st.selectedIndex == null || st.selectedIndex! >= st.items.length) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('SatÃ„Â±r seÃƒÂ§')));
      return;
    }
    final item = st.items[st.selectedIndex!];
    _openDetails(context, item, index: st.selectedIndex);
  }

  Future<void> _toggleAssign(AdminClaimsState st, String? userId) async {
    if (userId == null) return;
    if (st.selectedIndex == null || st.selectedIndex! >= st.items.length) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('SatÃ„Â±r seÃƒÂ§')));
      return;
    }
    final item = st.items[st.selectedIndex!];
    try {
      final controller = ref.read(adminClaimsControllerProvider.notifier);
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

  Future<void> _handleAction(AdminClaimsState st, String key) async {
    if (st.selectedIndex == null || st.selectedIndex! >= st.items.length) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('SatÃ„Â±r seÃƒÂ§')));
      return;
    }
    final item = st.items[st.selectedIndex!];
    String? decision;
    if (key == 'P') decision = 'approved';
    if (key == 'R') decision = 'rejected';
    if (decision == null) return;
    try {
      await ref
          .read(adminClaimsControllerProvider.notifier)
          .decide(claimId: item.id, decision: decision);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _selectSamePhone(AdminClaimsState st) async {
    if (st.selectedIndex == null || st.selectedIndex! >= st.items.length) {
      return;
    }
    final seed = st.items[st.selectedIndex!];
    final phone = seed.phone.trim();
    if (phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu kayÃ„Â±tta telefon yok.')),
      );
      return;
    }
    final ids = st.items
        .where((c) => c.phone.trim() == phone)
        .map((c) => c.id)
        .toSet();
    for (final itemId in ids) {
      ref
          .read(adminClaimsControllerProvider.notifier)
          .toggleSelection(itemId, true);
    }
  }

  Future<void> _assignSelectedToMe(AdminClaimsState st, String adminId) async {
    final controller = ref.read(adminClaimsControllerProvider.notifier);
    final selected = st.items
        .where((c) => st.selectedIds.contains(c.id))
        .toList();
    if (selected.isEmpty) return;
    var assigned = 0;
    for (final item in selected) {
      try {
        await controller.assignToMe(item.id, adminId: adminId);
        assigned++;
      } catch (_) {
        // Keep processing the rest.
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$assigned talep sana atandÃ„Â±.')));
  }
}

class _BulkBar extends StatelessWidget {
  const _BulkBar({
    required this.selectedCount,
    required this.bulkDecision,
    required this.onDecisionChanged,
    required this.noteCtrl,
    required this.onClear,
    required this.onApply,
  });

  final int selectedCount;
  final String bulkDecision;
  final ValueChanged<String> onDecisionChanged;
  final TextEditingController noteCtrl;
  final VoidCallback onClear;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'SeÃƒÂ§ili: $selectedCount',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String>(
            key: ValueKey(bulkDecision),
            initialValue: bulkDecision.isEmpty ? null : bulkDecision,
            items: [
              DropdownMenuItem(value: 'approved', child: Text('Onayla')),
              DropdownMenuItem(value: 'rejected', child: Text('Reddet')),
            ],
            onChanged: (v) => onDecisionChanged(v ?? ''),
            decoration: const InputDecoration(labelText: 'Karar'),
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

WidgetStateProperty<Color?> _rowColor(bool active, bool slaBreached) =>
    appAdminRowColor(active: active, slaBreached: slaBreached);

String _assignedLabel(String? assignedTo, String? userId) {
  if (assignedTo == null || assignedTo.isEmpty) return 'BoÃ…Å¸';
  if (userId != null && assignedTo == userId) return 'Ben';
  return 'BaÃ…Å¸ka admin';
}

String _fmtDays(double v) => '${v.toStringAsFixed(1)}gÃƒÂ¼n';

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

int _claimPriority(AdminOwnerClaimItem item) {
  var score = 0;
  if (item.slaBreached) score += 70;
  if (item.ageDays >= 3) score += 20;
  if ((item.evidenceUrl ?? '').trim().isEmpty) score += 15;
  if (item.status == 'pending') score += 10;
  return score;
}

const List<String> _claimDecisionTemplates = <String>[
  'Belge ve bilgiler doÃ„Å¸rulandÃ„Â±, talep onaylandÃ„Â±.',
  'Dogrulama kriterleri saglanamadi, talep reddedildi.',
  'Ek belge gerekiyor, inceleme devam ediyor.',
];

String _stamp() {
  final now = DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  final hh = now.hour.toString().padLeft(2, '0');
  final mm = now.minute.toString().padLeft(2, '0');
  return '$y$m${d}_$hh$mm';
}
