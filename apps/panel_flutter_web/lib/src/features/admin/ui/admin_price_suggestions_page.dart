import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/errors/app_error_mapper.dart';
import '../../../../features/auth/domain/auth_providers.dart';
import '../data/admin_price_suggestions_repository.dart';
import '../domain/admin_models.dart';
import '../domain/admin_new_items_controller.dart';
import '../domain/admin_price_suggestions_controller.dart';
import 'web_download.dart';
import 'widgets/admin_new_items_banner.dart';
import '../../../ui/design_system.dart';

class AdminPriceSuggestionsPage extends ConsumerStatefulWidget {
  const AdminPriceSuggestionsPage({super.key});

  @override
  ConsumerState<AdminPriceSuggestionsPage> createState() =>
      _AdminPriceSuggestionsPageState();
}

class _AdminPriceSuggestionsPageState
    extends ConsumerState<AdminPriceSuggestionsPage> {
  final scrollCtrl = ScrollController();
  bool exporting = false;

  @override
  void initState() {
    super.initState();
    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels >=
          scrollCtrl.position.maxScrollExtent - 300) {
        ref.read(adminPriceSuggestionsControllerProvider.notifier).loadMore();
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
    final st = ref.watch(adminPriceSuggestionsControllerProvider);
    final controller = ref.read(
      adminPriceSuggestionsControllerProvider.notifier,
    );
    final newItems = ref.watch(adminNewItemsProvider).priceSuggestionsNew;
    final user = ref.watch(userProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Fiyat Önerileri',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: exporting ? null : () => _exportCsv(st),
                icon: const Icon(Icons.download),
                label: Text(exporting ? 'İndiriliyor...' : 'CSV Dışa Aktar'),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  final ok = await controller.refresh(force: true);
                  if (!context.mounted) return;
                  if (ok) {
                    ref
                        .read(adminNewItemsProvider.notifier)
                        .clearPriceSuggestions();
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
                    label: 'Aç',
                    selected: st.statusFilter == 'pending',
                    onTap: () => controller.setStatusFilter('pending'),
                  ),
                  AppFilterChip(
                    label: 'Onaylandı',
                    selected: st.statusFilter == 'approved',
                    onTap: () => controller.setStatusFilter('approved'),
                  ),
                  AppFilterChip(
                    label: 'Reddedildi',
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
          Row(
            children: [
              AppFilterChip(
                label: 'Tümü',
                selected: st.assignedFilter.isEmpty,
                onTap: () => controller.setAssignedFilter(''),
              ),
              const SizedBox(width: 8),
              AppFilterChip(
                label: 'Boşta',
                selected: st.assignedFilter == 'unassigned',
                onTap: () => controller.setAssignedFilter('unassigned'),
              ),
              const SizedBox(width: 8),
              AppFilterChip(
                label: 'Benim',
                selected: st.assignedFilter == 'me',
                onTap: () => controller.setAssignedFilter('me'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AdminNewItemsBanner(
            count: newItems,
            label: 'Yeni kayıtlar var',
            onRefresh: () async {
              final ok = await controller.refresh(force: true);
              if (!context.mounted) return;
              if (ok) {
                ref
                    .read(adminNewItemsProvider.notifier)
                    .clearPriceSuggestions();
              }
            },
          ),
          if (newItems > 0) const SizedBox(height: 10),
          if (st.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppErrorMapper.message(st.error),
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => controller.refresh(force: true),
                    child: const Text('Tekrar dene'),
                  ),
                ],
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
                          columns: const [
                            DataColumn(label: Text('Yaş')),
                            DataColumn(label: Text('İşletme')),
                            DataColumn(label: Text('Öğe')),
                            DataColumn(label: Text('Öncelik')),
                            DataColumn(label: Text('Mevcut')),
                            DataColumn(label: Text('Önerilen')),
                            DataColumn(label: Text('Atanan')),
                            DataColumn(label: Text('SLA')),
                            DataColumn(label: Text('')),
                          ],
                          rows: [
                            for (final item in st.items)
                              DataRow(
                                color: _rowColor(item.slaBreached),
                                onSelectChanged: (_) =>
                                    _openDetails(context, item),
                                cells: [
                                  DataCell(Text(_ageLabel(item.ageHours))),
                                  DataCell(Text(item.businessName)),
                                  DataCell(Text(item.menuItemName)),
                                  DataCell(
                                    AppPriorityBadge(
                                      score: _priceSuggestionPriority(item),
                                    ),
                                  ),
                                  DataCell(
                                    Text(_formatPrice(item.currentPriceCents)),
                                  ),
                                  DataCell(
                                    Text(
                                      _formatPrice(item.suggestedPriceCents),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      _assignedLabel(item.assignedTo, user?.id),
                                    ),
                                  ),
                                  DataCell(
                                    item.slaBreached
                                        ? const AppSlaBadge()
                                        : const Text('-'),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        TextButton(
                                          onPressed: () =>
                                              _openDetails(context, item),
                                          child: const Text('Detay'),
                                        ),
                                        TextButton(
                                          onPressed: () => _approveQuick(item),
                                          child: const Text('Onayla'),
                                        ),
                                        TextButton(
                                          onPressed: () => _rejectQuick(item),
                                          child: const Text('Reddet'),
                                        ),
                                      ],
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
    );
  }

  Future<void> _openDetails(
    BuildContext context,
    AdminMenuPriceSuggestionItem item,
  ) async {
    final noteCtrl = TextEditingController();
    var loading = false;
    var canReject = false;

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
                  AppSlaBanner(text: 'SLA asildi: ${_ageLabel(item.ageHours)}'),
                const Text(
                  'Fiyat Önerisi Detay',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Text('İşletme: ${item.businessName}'),
                if ((item.city ?? '').isNotEmpty ||
                    (item.district ?? '').isNotEmpty)
                  Text(
                    'Konum: ${(item.city ?? '-')} / ${(item.district ?? '-')}',
                  ),
                Text('Öğe: ${item.menuItemName}'),
                Text('Mevcut: ${_formatPrice(item.currentPriceCents)}'),
                Text('Önerilen: ${_formatPrice(item.suggestedPriceCents)}'),
                Text('Para Birimi: ${item.currency}'),
                if (item.createdBy.isNotEmpty)
                  Text('Oluşturan: ${item.createdBy}'),
                const SizedBox(height: 8),
                const Text(
                  'Meta',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _metaJsonLike(item),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Reddetme notu (en az 3 karakter)',
                  ),
                  onChanged: (value) {
                    final next = value.trim().length >= 3;
                    if (next == canReject) return;
                    setModalState(() => canReject = next);
                  },
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
                                  'Onaylanacak mı?',
                                );
                                if (!ok) return;
                                setModalState(() => loading = true);
                                try {
                                  await ref
                                      .read(
                                        adminPriceSuggestionsControllerProvider
                                            .notifier,
                                      )
                                      .approve(item.id);
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Onaylandı.')),
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
                        child: Text(loading ? 'İşleniyor...' : 'Onayla'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: loading || !canReject
                            ? null
                            : () async {
                                final ok = await _confirm(
                                  ctx,
                                  'Reddetmek istiyor musun?',
                                );
                                if (!ok) return;
                                setModalState(() => loading = true);
                                try {
                                  await ref
                                      .read(
                                        adminPriceSuggestionsControllerProvider
                                            .notifier,
                                      )
                                      .reject(
                                        suggestionId: item.id,
                                        note: noteCtrl.text.trim(),
                                      );
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Reddedildi.'),
                                    ),
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
                        child: Text(loading ? 'İşleniyor...' : 'Reddet'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => context.go('/b/${item.businessId}'),
                      child: const Text('İşletme sayfasına git'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => context.go(
                        '/b/${item.businessId}/menu-item/${item.menuItemId}',
                      ),
                      child: const Text('Öğe sayfasına git'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() => noteCtrl.dispose());
  }

  Future<void> _exportCsv(AdminPriceSuggestionsState st) async {
    setState(() => exporting = true);
    try {
      final repo = ref.read(adminPriceSuggestionsRepositoryProvider);
      final csv = await repo.exportCsv(
        status: st.statusFilter,
        slaOnly: st.slaOnly,
        assigned: st.assignedFilter,
      );
      final filename = 'price_suggestions_${_stamp()}.csv';
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

  Future<void> _approveQuick(AdminMenuPriceSuggestionItem item) async {
    final ok = await _confirm(context, 'Onaylanacak mı?');
    if (!ok) return;
    try {
      await ref
          .read(adminPriceSuggestionsControllerProvider.notifier)
          .approve(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Onaylandı.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _rejectQuick(AdminMenuPriceSuggestionItem item) async {
    final noteCtrl = TextEditingController();
    var canSubmit = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            title: const Text('Reddet'),
            content: TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reddetme notu (en az 3 karakter)',
              ),
              onChanged: (value) {
                final next = value.trim().length >= 3;
                if (next == canSubmit) return;
                setModalState(() => canSubmit = next);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: canSubmit ? () => Navigator.pop(ctx, true) : null,
                child: const Text('Reddet'),
              ),
            ],
          );
        },
      ),
    );
    if (!mounted) return;
    if (ok != true) return;
    try {
      await ref
          .read(adminPriceSuggestionsControllerProvider.notifier)
          .reject(suggestionId: item.id, note: noteCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reddedildi.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    } finally {
      noteCtrl.dispose();
    }
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

String _assignedLabel(String? assignedTo, String? userId) {
  if (assignedTo == null || assignedTo.isEmpty) return 'Boş';
  if (userId != null && assignedTo == userId) return 'Ben';
  return 'Başka admin';
}

String _formatPrice(int? cents) {
  if (cents == null) return '—';
  final value = cents / 100.0;
  final text = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  return 'â‚º$text';
}

Future<bool> _confirm(BuildContext context, String message) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Emin misin?'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Onayla'),
        ),
      ],
    ),
  );
  return res ?? false;
}

String _metaJsonLike(AdminMenuPriceSuggestionItem item) {
  final city = item.city ?? '';
  final district = item.district ?? '';
  return '{\n'
      '  "suggestion_id": "${item.id}",\n'
      '  "business_id": "${item.businessId}",\n'
      '  "menu_item_id": "${item.menuItemId}",\n'
      '  "created_by": "${item.createdBy}",\n'
      '  "status": "${item.status}",\n'
      '  "city": "$city",\n'
      '  "district": "$district"\n'
      '}';
}

int _priceSuggestionPriority(AdminMenuPriceSuggestionItem item) {
  var score = 0;
  if (item.slaBreached) score += 70;
  if (item.ageHours >= 24) score += 20;
  final delta = (item.suggestedPriceCents - item.currentPriceCents).abs();
  if (delta >= 1000) score += 15;
  if (item.status == 'pending') score += 10;
  return score;
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
