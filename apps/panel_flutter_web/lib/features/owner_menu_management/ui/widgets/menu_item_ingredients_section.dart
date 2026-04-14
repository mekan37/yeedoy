import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/network/supabase_provider.dart';
import '../../domain/ingredient_models.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

final _ingredientDataProvider =
    FutureProvider.family<MenuItemIngredientData, String>(
  (ref, itemId) async {
    final client = ref.watch(supabaseProvider);

    final ingredRes = await client
        .from('menu_item_ingredients')
        .select('name, confidence, category')
        .eq('item_id', itemId)
        .order('sort_order');

    final dietRes = await client
        .from('menu_item_diet_tags')
        .select('is_vegan, is_vegetarian, is_gluten_free, is_dairy_free, detected_by')
        .eq('item_id', itemId)
        .maybeSingle();

    final ingredients = (ingredRes as List)
        .map((m) => MenuItemIngredient.fromMap(m as Map<String, dynamic>))
        .toList();

    final diet = dietRes == null
        ? null
        : MenuItemDietTags.fromMap(dietRes);

    return MenuItemIngredientData(ingredients: ingredients, diet: diet);
  },
);

// ─── Section ─────────────────────────────────────────────────────────────────

class MenuItemIngredientsSection extends ConsumerStatefulWidget {
  const MenuItemIngredientsSection({
    super.key,
    required this.itemId,
    required this.itemName,
    this.description,
  });

  final String itemId;
  final String itemName;
  final String? description;

  @override
  ConsumerState<MenuItemIngredientsSection> createState() =>
      _MenuItemIngredientsSectionState();
}

class _MenuItemIngredientsSectionState
    extends ConsumerState<MenuItemIngredientsSection> {
  bool _loading = false;
  String? _error;

  Future<void> _detect() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = ref.read(supabaseProvider);

      final estRes = await client.functions.invoke(
        'ai-ingredient-detect',
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

      final saveRes = await client.rpc(
        'owner_upsert_menu_item_ingredients_v1',
        params: {
          'p_item_id': widget.itemId,
          'p_ingredients': estData['ingredients'] ?? [],
          'p_diet': estData['diet'] ?? {},
          'p_detected_by': 'ai',
        },
      );
      final saveData = saveRes as Map<String, dynamic>?;
      if (saveData?['ok'] != true) {
        throw Exception(saveData?['error'] ?? 'save_failed');
      }

      ref.invalidate(_ingredientDataProvider(widget.itemId));
    } catch (e) {
      if (mounted) setState(() => _error = 'Hata: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(_ingredientDataProvider(widget.itemId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.restaurant_menu_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'İçerik & Diyet',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                TextButton.icon(
                  onPressed: _loading ? null : _detect,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_outlined, size: 16),
                  label:
                      Text(_loading ? 'Analiz ediliyor…' : 'AI ile Analiz'),
                ),
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
            dataAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (err, st) => const Text(
                'İçerik bilgisi yüklenemedi',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              data: (data) {
                if (data.ingredients.isEmpty && data.diet == null) {
                  return const Text(
                    'Henüz içerik analizi yapılmadı.',
                    style:
                        TextStyle(color: AppColors.muted, fontSize: 12),
                  );
                }
                return _IngredientDisplay(data: data);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Display ─────────────────────────────────────────────────────────────────

class _IngredientDisplay extends StatelessWidget {
  const _IngredientDisplay({required this.data});
  final MenuItemIngredientData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.diet != null) ...[
          _DietTagsRow(diet: data.diet!),
          const SizedBox(height: 12),
        ],
        if (data.ingredients.isNotEmpty) _IngredientList(
          ingredients: data.ingredients,
        ),
      ],
    );
  }
}

// ─── Diet tags ────────────────────────────────────────────────────────────────

class _DietTagsRow extends StatelessWidget {
  const _DietTagsRow({required this.diet});
  final MenuItemDietTags diet;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _DietBadge(label: 'Vegan', value: diet.isVegan),
        _DietBadge(label: 'Vejeteryan', value: diet.isVegetarian),
        _DietBadge(label: 'Glutensiz', value: diet.isGlutenFree),
        _DietBadge(label: 'Sütsüz', value: diet.isDairyFree),
      ],
    );
  }
}

class _DietBadge extends StatelessWidget {
  const _DietBadge({required this.label, required this.value});
  final String label;
  final bool? value;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final IconData icon;

    if (value == true) {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF16A34A);
      icon = Icons.check_circle_outline_rounded;
    } else if (value == false) {
      bg = const Color(0xFFFEF2F2);
      fg = const Color(0xFFDC2626);
      icon = Icons.cancel_outlined;
    } else {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF94A3B8);
      icon = Icons.help_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ingredient list ──────────────────────────────────────────────────────────

class _IngredientList extends StatefulWidget {
  const _IngredientList({required this.ingredients});
  final List<MenuItemIngredient> ingredients;

  @override
  State<_IngredientList> createState() => _IngredientListState();
}

class _IngredientListState extends State<_IngredientList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Group: certain first, then likely, then uncertain
    final certain = widget.ingredients
        .where((i) => i.confidence == IngredientConfidence.certain)
        .toList();
    final likely = widget.ingredients
        .where((i) => i.confidence == IngredientConfidence.likely)
        .toList();
    final uncertain = widget.ingredients
        .where((i) => i.confidence == IngredientConfidence.uncertain)
        .toList();

    // Collapsed view: show only certain ingredients
    final displayed =
        _expanded ? widget.ingredients : certain;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'İçerik Listesi',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${widget.ingredients.length} malzeme',
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: displayed
              .map((i) => _IngredientChip(ingredient: i))
              .toList(),
        ),
        if (!_expanded && (likely.isNotEmpty || uncertain.isNotEmpty)) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _expanded = true),
            child: Text(
              '+ ${likely.length + uncertain.length} '
              'daha göster (muhtemel & belirsiz)',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        if (_expanded) ...[
          if (likely.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Muhtemelen içeriyor',
              style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFFD97706),
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: likely
                  .map((i) => _IngredientChip(ingredient: i))
                  .toList(),
            ),
          ],
          if (uncertain.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Belirsiz',
              style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: uncertain
                  .map((i) => _IngredientChip(ingredient: i))
                  .toList(),
            ),
          ],
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _expanded = false),
            child: const Text(
              'Daha az göster',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 6),
        const Text(
          'AI tahminidir — tarife göre değişebilir.',
          style: TextStyle(
              fontSize: 10, color: AppColors.muted, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}

class _IngredientChip extends StatelessWidget {
  const _IngredientChip({required this.ingredient});
  final MenuItemIngredient ingredient;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String prefix;

    switch (ingredient.confidence) {
      case IngredientConfidence.certain:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF1E293B);
        prefix = '';
      case IngredientConfidence.likely:
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        prefix = '~';
      case IngredientConfidence.uncertain:
        bg = const Color(0xFFF8FAFC);
        fg = const Color(0xFF94A3B8);
        prefix = '?';
    }

    return Tooltip(
      message:
          '${ingredient.category.trName} — ${ingredient.confidence.trLabel}',
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: fg.withValues(alpha: 0.25),
            style: ingredient.confidence == IngredientConfidence.uncertain
                ? BorderStyle.solid
                : BorderStyle.solid,
          ),
        ),
        child: Text(
          '$prefix${ingredient.name}',
          style: TextStyle(
            fontSize: 12,
            color: fg,
            fontWeight: ingredient.confidence == IngredientConfidence.certain
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
