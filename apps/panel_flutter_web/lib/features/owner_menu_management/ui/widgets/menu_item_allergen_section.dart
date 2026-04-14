import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/network/supabase_provider.dart';
import '../../domain/allergen_models.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

final _allergensProvider =
    FutureProvider.family<List<MenuItemAllergen>, String>(
  (ref, itemId) async {
    final client = ref.watch(supabaseProvider);
    final res = await client
        .from('menu_item_allergens')
        .select('allergen, risk_level')
        .eq('item_id', itemId);
    return (res as List)
        .map((m) => MenuItemAllergen.fromMap(m as Map<String, dynamic>))
        .toList();
  },
);

// ─── Section widget ───────────────────────────────────────────────────────────

class MenuItemAllergenSection extends ConsumerStatefulWidget {
  const MenuItemAllergenSection({
    super.key,
    required this.itemId,
    required this.itemName,
    this.description,
  });

  final String itemId;
  final String itemName;
  final String? description;

  @override
  ConsumerState<MenuItemAllergenSection> createState() =>
      _MenuItemAllergenSectionState();
}

class _MenuItemAllergenSectionState
    extends ConsumerState<MenuItemAllergenSection> {
  bool _loading = false;
  bool _editMode = false;
  String? _error;

  // Local edit state: type → risk (null = not present)
  Map<AllergenType, AllergenRisk> _editMap = {};

  void _enterEdit(List<MenuItemAllergen> current) {
    _editMap = {for (final a in current) a.type: a.risk};
    setState(() => _editMode = true);
  }

  void _tapAllergen(AllergenType type) {
    setState(() {
      final current = _editMap[type];
      if (current == null) {
        _editMap[type] = AllergenRisk.contains;
      } else if (current == AllergenRisk.contains) {
        _editMap[type] = AllergenRisk.mayContain;
      } else {
        _editMap.remove(type);
      }
    });
  }

  Future<void> _saveEdit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = ref.read(supabaseProvider);
      final params = _editMap.entries
          .map((e) => {
                'allergen': e.key.code,
                'risk_level': e.value.code,
                'detected_by': 'manual',
              })
          .toList();
      final res = await client.rpc(
        'owner_upsert_menu_item_allergens_v1',
        params: {
          'p_item_id': widget.itemId,
          'p_allergens': params,
        },
      );
      final data = res as Map<String, dynamic>?;
      if (data?['ok'] != true) {
        throw Exception(data?['error'] ?? 'save_failed');
      }
      ref.invalidate(_allergensProvider(widget.itemId));
      if (mounted) setState(() => _editMode = false);
    } catch (e) {
      if (mounted) setState(() => _error = 'Hata: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _autoDetect() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = ref.read(supabaseProvider);
      final estRes = await client.functions.invoke(
        'ai-allergen-detect',
        body: {
          'item_name': widget.itemName,
          if (widget.description != null && widget.description!.isNotEmpty)
            'description': widget.description,
        },
      );
      final estData = estRes.data as Map<String, dynamic>?;
      if (estData == null || estData['ok'] != true) {
        throw Exception(estData?['error'] ?? 'detection_failed');
      }

      final detected = (estData['allergens'] as List? ?? [])
          .map((m) => MenuItemAllergen.fromMap(m as Map<String, dynamic>))
          .toList();

      // Save to DB
      final params = detected
          .map((a) => {
                'allergen': a.type.code,
                'risk_level': a.risk.code,
                'detected_by': 'ai',
              })
          .toList();
      final saveRes = await client.rpc(
        'owner_upsert_menu_item_allergens_v1',
        params: {
          'p_item_id': widget.itemId,
          'p_allergens': params,
        },
      );
      final saveData = saveRes as Map<String, dynamic>?;
      if (saveData?['ok'] != true) {
        throw Exception(saveData?['error'] ?? 'save_failed');
      }

      ref.invalidate(_allergensProvider(widget.itemId));
    } catch (e) {
      if (mounted) setState(() => _error = 'Hata: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allergensAsync = ref.watch(_allergensProvider(widget.itemId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Alerjenler',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                if (!_editMode) ...[
                  TextButton.icon(
                    onPressed: _loading
                        ? null
                        : () => allergensAsync.whenData(_enterEdit),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Düzenle'),
                  ),
                  TextButton.icon(
                    onPressed: _loading ? null : _autoDetect,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome_outlined, size: 16),
                    label: Text(_loading ? 'Tespit ediliyor…' : 'AI ile Tespit'),
                  ),
                ] else ...[
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() => _editMode = false),
                    child: const Text('İptal'),
                  ),
                  FilledButton(
                    onPressed: _loading ? null : _saveEdit,
                    child: _loading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Kaydet'),
                  ),
                ],
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(
                _error!,
                style:
                    const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ],
            const SizedBox(height: 8),
            if (_editMode)
              _AllergenEditGrid(
                selected: _editMap,
                onTap: _tapAllergen,
              )
            else
              allergensAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (err, st) => const Text(
                  'Alerjenler yüklenemedi',
                  style:
                      TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                data: (allergens) {
                  if (allergens.isEmpty) {
                    return const Text(
                      'Henüz alerjen tanımlanmadı.',
                      style:
                          TextStyle(color: AppColors.muted, fontSize: 12),
                    );
                  }
                  return _AllergenDisplay(allergens: allergens);
                },
              ),
            if (_editMode) ...[
              const SizedBox(height: 8),
              const Text(
                'Dokunma: Yok → İçeriyor → İçerebilir → Yok',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Read-only display ────────────────────────────────────────────────────────

class _AllergenDisplay extends StatelessWidget {
  const _AllergenDisplay({required this.allergens});
  final List<MenuItemAllergen> allergens;

  @override
  Widget build(BuildContext context) {
    // Sort: contains first, then may_contain
    final sorted = [...allergens]..sort(
        (a, b) => a.risk.index.compareTo(b.risk.index),
      );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sorted.map((a) => _AllergenChip(allergen: a)).toList(),
    );
  }
}

class _AllergenChip extends StatelessWidget {
  const _AllergenChip({required this.allergen});
  final MenuItemAllergen allergen;

  @override
  Widget build(BuildContext context) {
    final isContains = allergen.risk == AllergenRisk.contains;
    final borderColor = isContains
        ? const Color(0xFFDC2626)
        : const Color(0xFFD97706);
    final bgColor = isContains
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFFFFBEB);
    final labelColor = isContains
        ? const Color(0xFFDC2626)
        : const Color(0xFFD97706);

    return Tooltip(
      message:
          '${allergen.type.trName} — ${allergen.risk.trLabel}',
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              allergen.type.iconAsset,
              width: 22,
              height: 22,
              errorBuilder: (ctx, err, st) =>
                  const Icon(Icons.warning_amber, size: 22),
            ),
            const SizedBox(width: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allergen.type.trName,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700),
                ),
                Text(
                  allergen.risk.trLabel,
                  style: TextStyle(fontSize: 10, color: labelColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Edit grid ────────────────────────────────────────────────────────────────

class _AllergenEditGrid extends StatelessWidget {
  const _AllergenEditGrid({
    required this.selected,
    required this.onTap,
  });

  final Map<AllergenType, AllergenRisk> selected;
  final void Function(AllergenType) onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AllergenType.values
          .map((type) => _EditChip(
                type: type,
                risk: selected[type],
                onTap: () => onTap(type),
              ))
          .toList(),
    );
  }
}

class _EditChip extends StatelessWidget {
  const _EditChip({
    required this.type,
    required this.risk,
    required this.onTap,
  });

  final AllergenType type;
  final AllergenRisk? risk;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final Color bgColor;
    final Color iconTint;

    if (risk == AllergenRisk.contains) {
      borderColor = const Color(0xFFDC2626);
      bgColor = const Color(0xFFFEF2F2);
      iconTint = Colors.black;
    } else if (risk == AllergenRisk.mayContain) {
      borderColor = const Color(0xFFD97706);
      bgColor = const Color(0xFFFFFBEB);
      iconTint = Colors.black;
    } else {
      borderColor = const Color(0xFFE2E8F0);
      bgColor = const Color(0xFFF8FAFC);
      iconTint = Colors.black38;
    }

    return Tooltip(
      message: risk == null
          ? '${type.trName} — Yok (dokunarak ekle)'
          : '${type.trName} — ${risk!.trLabel}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColorFiltered(
                colorFilter: risk == null
                    ? const ColorFilter.matrix([
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0,      0,      0,      0.4, 0,
                      ])
                    : const ColorFilter.mode(
                        Colors.transparent, BlendMode.dst),
                child: Image.asset(
                  type.iconAsset,
                  width: 22,
                  height: 22,
                  errorBuilder: (ctx, err, st) => Icon(
                    Icons.warning_amber,
                    size: 22,
                    color: iconTint,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                type.trName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: risk == null ? Colors.black38 : Colors.black87,
                ),
              ),
              if (risk != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: borderColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    risk!.trLabel,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: borderColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
