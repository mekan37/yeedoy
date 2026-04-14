import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../../domain/variant_group_models.dart';
import '../../domain/variant_groups_provider.dart';

// ─── Section ─────────────────────────────────────────────────────────────────

class MenuItemVariantGroupsSection extends ConsumerWidget {
  const MenuItemVariantGroupsSection({super.key, required this.itemId});
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(variantGroupsProvider(itemId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.tune_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Varyantlar & Seçenekler',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      _showAddGroupSheet(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Grup Ekle'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            groupsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (err, st) => Text(
                'Varyantlar yüklenemedi: $err',
                style: const TextStyle(
                    color: AppColors.danger, fontSize: 12),
              ),
              data: (groups) {
                if (groups.isEmpty) {
                  return const _EmptyState();
                }
                return Column(
                  children: groups
                      .map((g) => _GroupCard(
                            group: g,
                            itemId: itemId,
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddGroupSheet(
      BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _AddGroupSheet(itemId: itemId),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Henüz varyant grubu eklenmedi.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: VariantGroupType.values
              .map((t) => _TypeHintChip(type: t))
              .toList(),
        ),
      ],
    );
  }
}

class _TypeHintChip extends StatelessWidget {
  const _TypeHintChip({required this.type});
  final VariantGroupType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 13, color: AppColors.muted),
          const SizedBox(width: 4),
          Text(
            type.trName,
            style: const TextStyle(
                fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

// ─── Group card ───────────────────────────────────────────────────────────────

class _GroupCard extends ConsumerStatefulWidget {
  const _GroupCard({required this.group, required this.itemId});
  final VariantGroup group;
  final String itemId;

  @override
  ConsumerState<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends ConsumerState<_GroupCard> {
  bool _busy = false;

  Future<void> _deleteGroup() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Grubu sil?'),
        content: Text(
            '"${widget.group.name}" grubu ve tüm seçenekleri silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(variantGroupsProvider(widget.itemId).notifier)
          .deleteGroup(widget.group.id);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Group header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(g.groupType.icon,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      Row(
                        children: [
                          _MetaBadge(
                            label: g.selection.trLabel,
                            color: const Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 4),
                          if (g.isRequired)
                            const _MetaBadge(
                              label: 'Zorunlu',
                              color: Color(0xFFDC2626),
                            )
                          else
                            const _MetaBadge(
                              label: 'İsteğe bağlı',
                              color: Color(0xFF94A3B8),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: AppColors.danger),
                    tooltip: 'Grubu sil',
                    onPressed: _deleteGroup,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Options
          if (g.options.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              child: Text(
                'Henüz seçenek yok',
                style: TextStyle(
                    color: AppColors.muted, fontSize: 12),
              ),
            )
          else
            ...g.options.map(
              (o) => _OptionRow(
                option: o,
                itemId: widget.itemId,
                selection: g.selection,
              ),
            ),
          // Add option row
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: TextButton.icon(
              onPressed: () => _showAddOptionSheet(context),
              icon: const Icon(Icons.add, size: 15),
              label: const Text('Seçenek Ekle', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddOptionSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _AddOptionSheet(
        groupId: widget.group.id,
        itemId: widget.itemId,
        existingCount: widget.group.options.length,
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─── Option row ───────────────────────────────────────────────────────────────

class _OptionRow extends ConsumerStatefulWidget {
  const _OptionRow({
    required this.option,
    required this.itemId,
    required this.selection,
  });

  final VariantOption option;
  final String itemId;
  final VariantSelection selection;

  @override
  ConsumerState<_OptionRow> createState() => _OptionRowState();
}

class _OptionRowState extends ConsumerState<_OptionRow> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.option;
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Icon(
          widget.selection == VariantSelection.single
              ? (o.isDefault
                  ? Icons.radio_button_checked_outlined
                  : Icons.radio_button_unchecked_outlined)
              : (o.isDefault
                  ? Icons.check_box_outlined
                  : Icons.check_box_outline_blank),
          size: 18,
          color: o.isDefault ? AppColors.primary : AppColors.muted,
        ),
        title: Text(
          o.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                o.isDefault ? FontWeight.w700 : FontWeight.w400,
            color: o.isAvailable ? Colors.black87 : AppColors.muted,
            decoration:
                o.isAvailable ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: o.priceModifierCents != 0
            ? Text(
                o.priceLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: o.priceModifierCents > 0
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                  fontWeight: FontWeight.w600,
                ),
              )
            : Text(
                'Ücretsiz',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.muted),
              ),
        trailing: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Wrap(
                spacing: 0,
                children: [
                  IconButton(
                    icon: Icon(
                      o.isAvailable
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 16,
                    ),
                    tooltip:
                        o.isAvailable ? 'Pasife al' : 'Aktife al',
                    onPressed: _toggleAvail,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 16, color: AppColors.danger),
                    tooltip: 'Sil',
                    onPressed: _delete,
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _toggleAvail() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(variantGroupsProvider(widget.itemId).notifier)
          .toggleOptionAvailability(widget.option);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(variantGroupsProvider(widget.itemId).notifier)
          .deleteOption(widget.option.id);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

// ─── Add Group bottom sheet ───────────────────────────────────────────────────

class _AddGroupSheet extends ConsumerStatefulWidget {
  const _AddGroupSheet({required this.itemId});
  final String itemId;

  @override
  ConsumerState<_AddGroupSheet> createState() => _AddGroupSheetState();
}

class _AddGroupSheetState extends ConsumerState<_AddGroupSheet> {
  VariantGroupType _type = VariantGroupType.portion;
  late final TextEditingController _nameCtrl;
  VariantSelection _selection = VariantSelection.single;
  bool _required = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: VariantGroupType.portion.trName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _selectType(VariantGroupType t) {
    setState(() {
      _type = t;
      _nameCtrl.text = t.trName;
      _selection = t.defaultMultiple
          ? VariantSelection.multiple
          : VariantSelection.single;
      _required = t.defaultRequired;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 4,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yeni Varyant Grubu',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 12),
          // Type selector
          const Text(
            'Grup Türü',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: VariantGroupType.values
                .map((t) => _TypeButton(
                      type: t,
                      selected: _type == t,
                      onTap: () => _selectType(t),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          // Name
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Grup Adı',
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          // Selection type
          const Text(
            'Seçim Türü',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _SelectionChip(
                label: 'Tekil seçim',
                selected: _selection == VariantSelection.single,
                onTap: () =>
                    setState(() => _selection = VariantSelection.single),
              ),
              const SizedBox(width: 8),
              _SelectionChip(
                label: 'Çoklu seçim',
                selected: _selection == VariantSelection.multiple,
                onTap: () =>
                    setState(() => _selection = VariantSelection.multiple),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _required,
            onChanged: (v) => setState(() => _required = v),
            title: const Text('Zorunlu seçim',
                style: TextStyle(fontSize: 13)),
            subtitle: const Text(
              'Müşteri sipariş verirken seçmek zorunda kalır',
              style: TextStyle(fontSize: 11),
            ),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _create,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Grup Oluştur'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(variantGroupsProvider(widget.itemId).notifier)
          .createGroup(
            name: name,
            groupType: _type,
            selection: _selection,
            isRequired: _required,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final VariantGroupType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type.icon,
              size: 15,
              color: selected ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(width: 5),
            Text(
              type.trName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.primary
                    : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionChip extends StatelessWidget {
  const _SelectionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                selected ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

// ─── Add Option bottom sheet ──────────────────────────────────────────────────

class _AddOptionSheet extends ConsumerStatefulWidget {
  const _AddOptionSheet({
    required this.groupId,
    required this.itemId,
    required this.existingCount,
  });

  final String groupId;
  final String itemId;
  final int existingCount;

  @override
  ConsumerState<_AddOptionSheet> createState() => _AddOptionSheetState();
}

class _AddOptionSheetState extends ConsumerState<_AddOptionSheet> {
  final _labelCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '0');
  bool _isDefault = false;
  bool _saving = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 4,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seçenek Ekle',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _labelCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Seçenek Adı (ör: Orta Porsiyon)',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _priceCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(signed: true, decimal: true),
            decoration: const InputDecoration(
              labelText: 'Fiyat Farkı (₺)',
              helperText: '0 = ücretsiz  |  +10 = 10₺ ek  |  -5 = 5₺ indirim',
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _isDefault,
            onChanged: (v) => setState(() => _isDefault = v),
            title: const Text('Varsayılan seçenek',
                style: TextStyle(fontSize: 13)),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _add,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Ekle'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _add() async {
    final label = _labelCtrl.text.trim();
    if (label.isEmpty) return;
    final priceDouble =
        double.tryParse(_priceCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    final priceCents = (priceDouble * 100).round();

    setState(() => _saving = true);
    try {
      await ref
          .read(variantGroupsProvider(widget.itemId).notifier)
          .createOption(
            groupId: widget.groupId,
            label: label,
            priceModifierCents: priceCents,
            isDefault: _isDefault,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
