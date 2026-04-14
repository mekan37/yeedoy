import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/network/supabase_provider.dart';
import '../../domain/nutrition_models.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final _nutritionProvider = FutureProvider.family<MenuItemNutrition?, String>(
  (ref, itemId) async {
    final client = ref.watch(supabaseProvider);
    final res = await client
        .from('menu_item_nutrition')
        .select()
        .eq('item_id', itemId)
        .maybeSingle();
    if (res == null) return null;
    return MenuItemNutrition.fromMap(res);
  },
);

// ─── Section widget ───────────────────────────────────────────────────────────

class MenuItemNutritionSection extends ConsumerStatefulWidget {
  const MenuItemNutritionSection({
    super.key,
    required this.itemId,
    required this.itemName,
    this.description,
  });

  final String itemId;
  final String itemName;
  final String? description;

  @override
  ConsumerState<MenuItemNutritionSection> createState() =>
      _MenuItemNutritionSectionState();
}

class _MenuItemNutritionSectionState
    extends ConsumerState<MenuItemNutritionSection> {
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final nutritionAsync = ref.watch(_nutritionProvider(widget.itemId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Besin Değerleri',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                TextButton.icon(
                  onPressed: _loading ? null : _estimate,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_outlined, size: 16),
                  label: Text(_loading ? 'Hesaplanıyor…' : 'AI ile Hesapla'),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ],
            const SizedBox(height: 4),
            nutritionAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (err, st) => const Text(
                'Besin değerleri yüklenemedi',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              data: (nutrition) {
                if (nutrition == null) {
                  return const Text(
                    'Henüz besin değeri hesaplanmadı.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  );
                }
                return _NutritionDisplay(nutrition: nutrition);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _estimate() async {
    setState(() {
      _loading = true;
      _error = null; // ignore: unnecessary_underscores
    });
    try {
      final client = ref.read(supabaseProvider);

      // Step 1: AI estimate via Edge Function
      final estRes = await client.functions.invoke(
        'ai-nutrition-estimate',
        body: {
          'item_name': widget.itemName,
          if (widget.description != null && widget.description!.isNotEmpty)
            'description': widget.description,
        },
      );
      final estData = estRes.data as Map<String, dynamic>?;
      if (estData == null || estData['ok'] != true) {
        throw Exception(estData?['error'] ?? 'estimation_failed');
      }

      // Step 2: Save to DB via RPC
      final saveRes = await client.rpc(
        'owner_upsert_menu_item_nutrition_v1',
        params: {
          'p_item_id': widget.itemId,
          'p_calorie_min': estData['calorie_min'],
          'p_calorie_max': estData['calorie_max'],
          'p_protein_min_g': estData['protein_min_g'],
          'p_protein_max_g': estData['protein_max_g'],
          'p_fat_min_g': estData['fat_min_g'],
          'p_fat_max_g': estData['fat_max_g'],
          'p_carbs_min_g': estData['carbs_min_g'],
          'p_carbs_max_g': estData['carbs_max_g'],
          'p_serving_est_g': estData['serving_est_g'],
          'p_source': estData['source'] ?? 'ai_estimated',
          if (estData['usda_fdc_ids'] != null)
            'p_usda_fdc_ids': estData['usda_fdc_ids'],
        },
      );
      final saveData = saveRes as Map<String, dynamic>?;
      if (saveData?['ok'] != true) {
        throw Exception(saveData?['error'] ?? 'save_failed');
      }

      // Refresh
      ref.invalidate(_nutritionProvider(widget.itemId));
    } catch (e) {
      if (mounted) setState(() => _error = 'Hata: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── Display ─────────────────────────────────────────────────────────────────

class _NutritionDisplay extends StatelessWidget {
  const _NutritionDisplay({required this.nutrition});
  final MenuItemNutrition nutrition;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "yaklaşık" badge — zorunlu
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.info_outline, size: 12, color: Color(0xFFEA580C)),
              SizedBox(width: 4),
              Text(
                'yaklaşık tahmini değerler',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFFEA580C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Serving size
        if (nutrition.servingEstG > 0) ...[
          Text(
            'Porsiyon: ~${nutrition.servingEstG}g',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
        ],
        // Grid of 4 values
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _NutrientChip(
              label: 'Kalori',
              unit: 'kcal',
              min: nutrition.calorieMin.toDouble(),
              max: nutrition.calorieMax.toDouble(),
              decimals: 0,
              color: const Color(0xFFDC2626),
            ),
            _NutrientChip(
              label: 'Protein',
              unit: 'g',
              min: nutrition.proteinMinG,
              max: nutrition.proteinMaxG,
              color: const Color(0xFF2563EB),
            ),
            _NutrientChip(
              label: 'Yağ',
              unit: 'g',
              min: nutrition.fatMinG,
              max: nutrition.fatMaxG,
              color: const Color(0xFFD97706),
            ),
            _NutrientChip(
              label: 'Karbonhidrat',
              unit: 'g',
              min: nutrition.carbsMinG,
              max: nutrition.carbsMaxG,
              color: const Color(0xFF16A34A),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Kaynak: ${nutrition.source == 'usda+ai' ? 'USDA + AI tahmini' : 'AI tahmini'}',
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _NutrientChip extends StatelessWidget {
  const _NutrientChip({
    required this.label,
    required this.unit,
    required this.min,
    required this.max,
    required this.color,
    this.decimals = 1,
  });

  final String label;
  final String unit;
  final double min;
  final double max;
  final Color color;
  final int decimals;

  String _fmt(double v) =>
      decimals == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '~${_fmt(min)}–${_fmt(max)} $unit',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
