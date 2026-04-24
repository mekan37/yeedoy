import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../data/owner_menu_repository.dart';
import '../domain/owner_menu_controller.dart';
import '../domain/owner_menu_models.dart';
import 'widgets/item_editor_sheet.dart';
import 'widgets/item_list_tile.dart';
import 'owner_menu_error_mapper.dart';
import '../../../shared/cache/invalidate_helpers.dart';
import '../../../shared/ui/components/app_scaffold.dart';

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

  // Hızlı ekleme satırı
  final _quickNameCtrl = TextEditingController();
  final _quickPriceCtrl = TextEditingController();
  bool _quickAdding = false;

  @override
  void dispose() {
    _quickNameCtrl.dispose();
    _quickPriceCtrl.dispose();
    super.dispose();
  }

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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // ── OCR / Hızlı İşlemler Kartı ──────────────────────────────
            _QuickActionsCard(
              bulkUpdating: _bulkUpdating,
              hasItems: st.items.isNotEmpty,
              onOcr: _openBulkImport,
              onCsv: _bulkUpdating ? null : _openCsvImportSheet,
              onBulkPrice: st.items.isEmpty || _bulkUpdating
                  ? null
                  : () => _openBulkPriceSheet(st.items),
            ),
            const SizedBox(height: 12),

            // ── Hızlı ürün ekleme satırı ────────────────────────────────
            _QuickAddRow(
              nameCtrl: _quickNameCtrl,
              priceCtrl: _quickPriceCtrl,
              adding: _quickAdding,
              onAdd: _quickAddItem,
            ),
            const SizedBox(height: 12),

            // ── Ürün başlığı + Detaylı Ekle butonu ──────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.restaurant_menu,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.ownerProducts,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openCreateItem,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(context.l10n.ownerAddItem),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Hata / Yükleme / Liste ───────────────────────────────────
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

  // ── Hızlı ekle (sadece ad + fiyat, oluştur → edit sheet aç) ────────────────
  Future<void> _quickAddItem() async {
    final name = _quickNameCtrl.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ownerItemNameMin2)),
      );
      return;
    }
    int? priceCents;
    final priceText = _quickPriceCtrl.text.trim();
    if (priceText.isNotEmpty) {
      final parsed = double.tryParse(priceText.replaceAll(',', '.'));
      if (parsed != null && parsed > 0) {
        priceCents = (parsed * 100).round();
      }
    }
    setState(() => _quickAdding = true);
    try {
      final newId = await ref
          .read(ownerSectionItemsProvider(_key).notifier)
          .createItem(name: name, priceCents: priceCents);
      invalidateSection(
        ref,
        menuId: widget.menu.id,
        sectionId: widget.section.id,
      );
      _quickNameCtrl.clear();
      _quickPriceCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.ownerItemAdded)));

      // Yeni oluşturulan ürünü bul → edit sheet aç (fotoğraf / AI eklemek için)
      if (newId != null && newId.isNotEmpty) {
        final items = ref.read(ownerSectionItemsProvider(_key)).items;
        final created = items.where((i) => i.id == newId).firstOrNull;
        if (created != null && mounted) {
          await _openEditItem(created);
        }
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _quickAdding = false);
    }
  }

  // ── Detaylı oluştur → kaydet → edit sheet aç ────────────────────────────────
  Future<void> _openCreateItem() async {
    String? newItemId;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ItemEditorSheet(
        title: context.l10n.ownerAddItem,
        onSave: (payload) async {
          newItemId = await ref
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
      // Oluşturulan ürünü otomatik edit sheet'te aç (fotoğraf / AI)
      if (newItemId != null && newItemId!.isNotEmpty && mounted) {
        final items = ref.read(ownerSectionItemsProvider(_key)).items;
        final created = items.where((i) => i.id == newItemId).firstOrNull;
        if (created != null && mounted) {
          await _openEditItem(created);
        }
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

  Future<void> _openBulkImport() async {
    // Bulk import (OCR / PDF / fotoğraftan menü okuma)
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _BulkImportPickerSheet(
        sectionId: widget.section.id,
        menuId: widget.menu.id,
        onCsvImport: _openCsvImportSheet,
      ),
    );
    if (ok == true && mounted) {
      ref.read(ownerSectionItemsProvider(_key).notifier).refresh();
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
                    style: const TextStyle(fontWeight: FontWeight.w900),
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
      final ctrl = ref.read(ownerSectionItemsProvider(_key).notifier);
      for (final item in items) {
        final current = item.priceCents ?? 0;
        final next = _nextPriceCents(
          current: current,
          value: raw,
          mode: mode,
          direction: direction,
        );
        if (next == current) continue;
        await ctrl.updateItem(
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
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.ownerCsvFormatHint,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
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
      final cells = _splitCsvLine(line, delimiter)
          .map((e) => e.trim().replaceAll('"', ''))
          .toList();
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
      context.l10n,
      error,
      fallback: AppErrorMapper.message(error),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}

// ── Hızlı İşlemler Kartı ────────────────────────────────────────────────────

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.bulkUpdating,
    required this.hasItems,
    required this.onOcr,
    required this.onCsv,
    required this.onBulkPrice,
  });

  final bool bulkUpdating;
  final bool hasItems;
  final VoidCallback onOcr;
  final VoidCallback? onCsv;
  final VoidCallback? onBulkPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.bolt, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hızlı İşlemler',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textStrong,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Menü fotoğrafından içe aktar veya toplu düzenle',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionTile(
                icon: Icons.document_scanner_outlined,
                label: 'Fotoğraftan / PDF\nOCR ile Aktar',
                color: AppColors.primary,
                onTap: onOcr,
              ),
              _ActionTile(
                icon: Icons.upload_file_outlined,
                label: 'CSV / Excel\nDosya Aktar',
                color: AppColors.info,
                onTap: onCsv ?? onOcr,
                disabled: onCsv == null,
              ),
              if (hasItems)
                _ActionTile(
                  icon: Icons.price_change_outlined,
                  label: 'Toplu Fiyat\nGüncelle',
                  color: AppColors.warning,
                  onTap: onBulkPrice ?? () {},
                  disabled: onBulkPrice == null || bulkUpdating,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: disabled
              ? AppColors.card
              : Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: disabled
                ? AppColors.border
                : color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: disabled ? AppColors.muted : color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: disabled ? AppColors.muted : AppColors.textStrong,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hızlı ekleme satırı ─────────────────────────────────────────────────────

class _QuickAddRow extends StatelessWidget {
  const _QuickAddRow({
    required this.nameCtrl,
    required this.priceCtrl,
    required this.adding,
    required this.onAdd,
  });

  final TextEditingController nameCtrl;
  final TextEditingController priceCtrl;
  final bool adding;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hızlı Ürün Ekle',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: nameCtrl,
                  enabled: !adding,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Ürün adı (örn: Adana Kebap)',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: priceCtrl,
                  enabled: !adding,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onAdd(),
                  decoration: const InputDecoration(
                    hintText: 'Fiyat (₺)',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 42,
                child: FilledButton(
                  onPressed: adding ? null : onAdd,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: adding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '↵ Kaydedildikten sonra fotoğraf ve AI görseli ekleyebilirsiniz',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Bulk import picker sheet (OCR vurgusu) ───────────────────────────────────

class _BulkImportPickerSheet extends StatelessWidget {
  const _BulkImportPickerSheet({
    required this.sectionId,
    required this.menuId,
    required this.onCsvImport,
  });

  final String sectionId;
  final String menuId;
  final VoidCallback onCsvImport;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Menüyü İçe Aktar',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Aşağıdaki yöntemlerden birini seçin',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _ImportOption(
              icon: Icons.document_scanner_outlined,
              color: AppColors.primary,
              title: 'Fotoğraf / PDF\'den Oku (OCR)',
              subtitle:
                  'Menü fotoğrafı veya PDF yükleyin, ürünler otomatik tanınsın',
              onTap: () {
                Navigator.pop(context, false);
                // Bulk import sheet açılır — parent zaten BulkMenuImportSheet'i açıyor
                onCsvImport();
              },
            ),
            const SizedBox(height: 8),
            _ImportOption(
              icon: Icons.table_chart_outlined,
              color: AppColors.info,
              title: 'CSV / Excel Dosyası',
              subtitle: 'ad, fiyat, açıklama sütunlarını otomatik tanır',
              onTap: () {
                Navigator.pop(context, false);
                onCsvImport();
              },
            ),
            const SizedBox(height: 8),
            _ImportOption(
              icon: Icons.close,
              color: AppColors.muted,
              title: 'Vazgeç',
              subtitle: '',
              onTap: () => Navigator.pop(context, false),
              muted: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportOption extends StatelessWidget {
  const _ImportOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.muted = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: muted ? AppColors.bg : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: muted
                ? AppColors.border
                : color.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: muted ? AppColors.muted : AppColors.textStrong,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (!muted)
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.muted,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Yardımcılar ─────────────────────────────────────────────────────────────

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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 10, color: AppColors.border),
          const SizedBox(height: 6),
          Container(height: 10, width: 160, color: AppColors.border),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(
            Icons.restaurant_menu,
            size: 40,
            color: AppColors.border,
          ),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 4),
          const Text(
            'Yukarıdaki hızlı ekleme satırını kullanın',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
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
