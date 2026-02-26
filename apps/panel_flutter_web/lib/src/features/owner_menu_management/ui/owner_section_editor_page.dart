import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/errors/app_error_mapper.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../data/owner_menu_repository.dart';
import '../domain/owner_menu_controller.dart';
import '../domain/owner_menu_models.dart';
import 'widgets/item_editor_sheet.dart';
import 'widgets/item_list_tile.dart';
import 'owner_menu_error_mapper.dart';
import '../../../shared/cache/invalidate_helpers.dart';
import '../../../ui/components/app_scaffold.dart';

class OwnerSectionEditorPage extends ConsumerStatefulWidget {
  const OwnerSectionEditorPage({
    super.key,
    required this.menu,
    required this.section,
  });

  final OwnerMenu menu;
  final OwnerMenuSection section;

  @override
  ConsumerState<OwnerSectionEditorPage> createState() =>
      _OwnerSectionEditorPageState();
}

class _OwnerSectionEditorPageState
    extends ConsumerState<OwnerSectionEditorPage> {
  OwnerSectionKey get _key =>
      OwnerSectionKey(widget.menu.id, widget.section.id);
  bool _bulkUpdating = false;

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(ownerSectionItemsProvider(_key));
    final controller = ref.read(ownerSectionItemsProvider(_key).notifier);
    return AppScaffold(
      appBar: AppBar(
        title: Text(widget.section.title),
        actions: [
          IconButton(
            onPressed: () => controller.refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => controller.refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                Text(
                  context.l10n.ownerProducts,
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: st.items.isEmpty || _bulkUpdating
                      ? null
                      : () => _openBulkPriceSheet(st.items),
                  icon: const Icon(Icons.tune),
                  label: Text(
                    _bulkUpdating
                        ? context.l10n.ownerApplying
                        : context.l10n.ownerBulkPrice,
                  ),
                ),
                TextButton.icon(
                  onPressed: _bulkUpdating ? null : _openCsvImportSheet,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(context.l10n.ownerCsvImport),
                ),
                TextButton.icon(
                  onPressed: _openCreateItem,
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.ownerAddItem),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (st.error != null)
              _ErrorBox(
                message: AppErrorMapper.message(st.error),
                onRetry: controller.refresh,
              ),
            if (st.isLoading && st.items.isEmpty)
              const _ItemsSkeleton()
            else if (!st.isLoading && st.items.isEmpty)
              _EmptyBox(message: context.l10n.ownerProductNotFound)
            else
              Column(
                children: [
                  for (final item in st.items) ...[
                    ItemListTile(
                      item: item,
                      onEdit: () => _openEditItem(item),
                      onArchive: () => _archiveItem(item),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (st.isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (st.hasMore && !st.isLoadingMore)
                    TextButton(
                      onPressed: () => controller.loadMore(),
                      child: Text(context.l10n.ownerLoadMore),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateItem() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ItemEditorSheet(
        title: context.l10n.ownerAddItem,
        onSave: (payload) async {
          await ref
              .read(ownerSectionItemsProvider(_key).notifier)
              .createItem(
                name: payload.name,
                description: payload.description,
                priceCents: payload.priceCents,
                currency: payload.currency,
                catalogItemId: payload.catalogItemId,
              );
          if (!mounted) return;
          Navigator.pop(context, true);
        },
      ),
    );
    if (ok == true) {
      invalidateSection(
        ref,
        menuId: widget.menu.id,
        sectionId: widget.section.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.ownerItemAdded)));
      }
    }
  }

  Future<void> _openEditItem(OwnerMenuItem item) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ItemEditorSheet(
        title: context.l10n.ownerEditItem,
        initial: item,
        onArchive: () async {
          Navigator.pop(context, false);
          await _archiveItem(item);
        },
        onSave: (payload) async {
          await ref
              .read(ownerSectionItemsProvider(_key).notifier)
              .updateItem(
                itemId: item.id,
                name: payload.name,
                description: payload.description,
                priceCents: payload.priceCents,
                currency: payload.currency,
                catalogItemId: payload.catalogItemId,
              );
          if (!mounted) return;
          Navigator.pop(context, true);
        },
      ),
    );
    if (ok == true) {
      invalidateItem(ref, itemId: item.id, sectionId: widget.section.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.ownerItemUpdated)));
      }
    }
  }

  Future<void> _archiveItem(OwnerMenuItem item) async {
    final ok = await _confirm(context, context.l10n.ownerArchiveItemConfirm);
    if (!ok) return;
    try {
      await ref
          .read(ownerSectionItemsProvider(_key).notifier)
          .archiveItem(itemId: item.id);
      invalidateItem(ref, itemId: item.id, sectionId: widget.section.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.ownerItemArchived)));
      }
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _openBulkPriceSheet(List<OwnerMenuItem> items) async {
    final amountCtrl = TextEditingController();
    var mode = 'percent';
    var direction = 'increase';
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
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
                  Text(
                    context.l10n.ownerBulkPriceUpdate,
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: mode,
                    decoration: InputDecoration(
                      labelText: context.l10n.ownerMethod,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'percent',
                        child: Text(context.l10n.ownerPercent),
                      ),
                      DropdownMenuItem(
                        value: 'fixed',
                        child: Text(context.l10n.ownerFixedAmountTl),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setModalState(() => mode = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: direction,
                    decoration: InputDecoration(
                      labelText: context.l10n.ownerOperation,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'increase',
                        child: Text(context.l10n.ownerIncrease),
                      ),
                      DropdownMenuItem(
                        value: 'decrease',
                        child: Text(context.l10n.ownerDecrease),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setModalState(() => direction = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: mode == 'percent'
                          ? context.l10n.ownerValuePercent
                          : context.l10n.ownerValueTl,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(context.l10n.apply),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (ok != true) return;
    final raw = double.tryParse(amountCtrl.text.replaceAll(',', '.'));
    amountCtrl.dispose();
    if (raw == null || raw <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ownerEnterValidValue)),
      );
      return;
    }

    setState(() => _bulkUpdating = true);
    var changed = 0;
    try {
      final controller = ref.read(ownerSectionItemsProvider(_key).notifier);
      for (final item in items) {
        final current = item.priceCents ?? 0;
        final next = _nextPriceCents(
          current: current,
          value: raw,
          mode: mode,
          direction: direction,
        );
        if (next == current) continue;
        await controller.updateItem(
          itemId: item.id,
          name: item.name,
          description: item.description,
          priceCents: next,
          currency: item.currency,
          catalogItemId: item.catalogItemId,
        );
        changed++;
      }
      invalidateSection(
        ref,
        menuId: widget.menu.id,
        sectionId: widget.section.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ownerUpdatedItemPrices(changed))),
      );
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _bulkUpdating = false);
    }
  }

  Future<void> _openCsvImportSheet() async {
    final csvCtrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        var picking = false;
        return StatefulBuilder(
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
                  Text(
                    context.l10n.ownerCsvImport,
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.ownerCsvFormatHint,
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: picking
                        ? null
                        : () async {
                            setModalState(() => picking = true);
                            final text = await _pickCsvTextFromFile();
                            if (text != null && text.trim().isNotEmpty) {
                              csvCtrl.text = text;
                            }
                            setModalState(() => picking = false);
                          },
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      picking
                          ? context.l10n.ownerSelecting
                          : context.l10n.ownerSelectFile,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: csvCtrl,
                    minLines: 8,
                    maxLines: 12,
                    decoration: InputDecoration(
                      hintText: context.l10n.ownerCsvExample,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(context.l10n.ownerImportContent),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (ok != true) {
      csvCtrl.dispose();
      return;
    }
    final rows = _parseCsvRows(csvCtrl.text);
    csvCtrl.dispose();
    if (rows.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.ownerNoValidRows)));
      return;
    }

    await _importCsvRows(rows);
  }

  Future<String?> _pickCsvTextFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'txt'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;
      final bytes = result.files.first.bytes;
      if (bytes == null || bytes.isEmpty) return null;
      return String.fromCharCodes(bytes);
    } catch (_) {
      return null;
    }
  }

  Future<void> _importCsvRows(List<_CsvImportRow> rows) async {
    setState(() => _bulkUpdating = true);
    var success = 0;
    var failed = 0;
    try {
      final repo = ref.read(ownerMenuRepositoryProvider);
      for (final row in rows) {
        try {
          await repo.createItem(
            sectionId: widget.section.id,
            name: row.name,
            description: row.description,
            priceCents: row.priceCents,
            currency: row.currency,
          );
          success++;
        } catch (_) {
          failed++;
        }
      }
      await ref.read(ownerSectionItemsProvider(_key).notifier).refresh();
      invalidateSection(
        ref,
        menuId: widget.menu.id,
        sectionId: widget.section.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failed == 0
                ? context.l10n.ownerImportedItems(success)
                : context.l10n.ownerImportedItemsWithSkipped(success, failed),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _bulkUpdating = false);
    }
  }

  List<_CsvImportRow> _parseCsvRows(String raw) {
    final rows = <_CsvImportRow>[];
    final lines = raw
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (lines.isEmpty) return rows;

    final start = _looksLikeHeader(lines.first) ? 1 : 0;
    for (var i = start; i < lines.length; i++) {
      final line = lines[i];
      final delimiter = line.contains(';') ? ';' : ',';
      final cells = _splitCsvLine(
        line,
        delimiter,
      ).map((e) => e.trim().replaceAll('"', '')).toList();
      if (cells.isEmpty || cells.first.isEmpty) continue;
      final name = cells[0];
      final priceText = cells.length > 1 ? cells[1] : '';
      int? priceCents;
      if (priceText.isNotEmpty) {
        final parsed = double.tryParse(priceText.replaceAll(',', '.'));
        if (parsed != null && parsed > 0) {
          priceCents = (parsed * 100).round();
        }
      }
      final description = cells.length > 2 ? cells[2] : '';
      final currency = cells.length > 3 && cells[3].trim().isNotEmpty
          ? cells[3].trim().toUpperCase()
          : 'TRY';
      rows.add(
        _CsvImportRow(
          name: name,
          description: description,
          priceCents: priceCents,
          currency: currency,
        ),
      );
    }
    return rows;
  }

  bool _looksLikeHeader(String line) {
    final normalized = line.toLowerCase();
    return normalized.contains('name') ||
        normalized.contains('ad') ||
        normalized.contains('fiyat') ||
        normalized.contains('price');
  }

  List<String> _splitCsvLine(String line, String delimiter) {
    final out = <String>[];
    final sb = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
        continue;
      }
      if (!inQuotes && ch == delimiter) {
        out.add(sb.toString());
        sb.clear();
        continue;
      }
      sb.write(ch);
    }
    out.add(sb.toString());
    return out;
  }

  int _nextPriceCents({
    required int current,
    required double value,
    required String mode,
    required String direction,
  }) {
    if (current <= 0) return current;
    final sign = direction == 'decrease' ? -1.0 : 1.0;
    if (mode == 'fixed') {
      final delta = (value * 100).round();
      return (current + (sign * delta).round()).clamp(1, 99999999);
    }
    final ratio = value / 100.0;
    final delta = (current * ratio).round();
    return (current + (sign * delta).round()).clamp(1, 99999999);
  }

  void _showError(Object error) {
    final msg = ownerMenuErrorMessage(
      error,
      fallback: AppErrorMapper.message(error),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}

class _CsvImportRow {
  _CsvImportRow({
    required this.name,
    required this.description,
    required this.priceCents,
    required this.currency,
  });

  final String name;
  final String description;
  final int? priceCents;
  final String currency;
}

class _ItemsSkeleton extends StatelessWidget {
  const _ItemsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: _SkeletonCard(),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 10, color: AppColors.card),
            const SizedBox(height: 6),
            Container(height: 10, width: 160, color: AppColors.card),
          ],
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(message, style: const TextStyle(color: AppColors.muted)),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }
}

Future<bool> _confirm(BuildContext context, String message) async {
  final l10n = context.l10n;
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.l10n.ownerAreYouSure),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(context.l10n.ownerConfirm),
        ),
      ],
    ),
  );
  return res ?? false;
}
