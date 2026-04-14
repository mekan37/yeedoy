import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_provider.dart';
import 'variant_group_models.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

final variantGroupsProvider =
    AsyncNotifierProvider.family<VariantGroupsNotifier, List<VariantGroup>, String>(
  VariantGroupsNotifier.new,
);

class VariantGroupsNotifier extends AsyncNotifier<List<VariantGroup>> {
  VariantGroupsNotifier(this.itemId);
  final String itemId;

  @override
  Future<List<VariantGroup>> build() => _fetch();

  Future<List<VariantGroup>> _fetch() async {
    final client = ref.read(supabaseProvider);

    final groupsRes = await client
        .from('menu_item_variant_groups')
        .select()
        .eq('item_id', itemId)
        .order('sort_order');

    final groups = groupsRes as List;
    if (groups.isEmpty) return [];

    final groupIds = groups.map((g) => g['id'].toString()).toList();

    final optionsRes = await client
        .from('menu_item_variant_options')
        .select()
        .inFilter('group_id', groupIds)
        .order('sort_order');

    final optionsByGroup = <String, List<VariantOption>>{};
    for (final o in (optionsRes as List)) {
      final opt = VariantOption.fromMap(o as Map<String, dynamic>);
      optionsByGroup.putIfAbsent(opt.groupId, () => []).add(opt);
    }

    return groups.map((g) {
      final gMap = g as Map<String, dynamic>;
      final gId = gMap['id'].toString();
      return VariantGroup.fromMap(gMap, optionsByGroup[gId] ?? []);
    }).toList();
  }

  // ── Group operations ────────────────────────────────────────────────────────

  Future<void> createGroup({
    required String name,
    required VariantGroupType groupType,
    required VariantSelection selection,
    required bool isRequired,
  }) async {
    final client = ref.read(supabaseProvider);
    final current = state.when(
        data: (v) => v, loading: () => <VariantGroup>[], error: (err, st) => <VariantGroup>[]);
    final res = await client.rpc('owner_upsert_variant_group_v1', params: {
      'p_item_id': itemId,
      'p_name': name,
      'p_group_type': groupType.code,
      'p_selection': selection.code,
      'p_is_required': isRequired,
      'p_sort_order': current.length,
    });
    _checkRpc(res);
    ref.invalidateSelf();
  }

  Future<void> deleteGroup(String groupId) async {
    final client = ref.read(supabaseProvider);
    final res = await client.rpc('owner_delete_variant_group_v1', params: {
      'p_group_id': groupId,
    });
    _checkRpc(res);
    ref.invalidateSelf();
  }

  // ── Option operations ───────────────────────────────────────────────────────

  Future<void> createOption({
    required String groupId,
    required String label,
    required int priceModifierCents,
    required bool isDefault,
  }) async {
    final client = ref.read(supabaseProvider);
    final groups = state.when(
        data: (v) => v, loading: () => <VariantGroup>[], error: (err, st) => <VariantGroup>[]);
    final group = groups.where((g) => g.id == groupId).firstOrNull;
    final res = await client.rpc('owner_upsert_variant_option_v1', params: {
      'p_group_id': groupId,
      'p_label': label,
      'p_price_modifier_cents': priceModifierCents,
      'p_is_default': isDefault,
      'p_is_available': true,
      'p_sort_order': group?.options.length ?? 0,
    });
    _checkRpc(res);
    ref.invalidateSelf();
  }

  Future<void> deleteOption(String optionId) async {
    final client = ref.read(supabaseProvider);
    final res = await client.rpc('owner_delete_variant_option_v1', params: {
      'p_option_id': optionId,
    });
    _checkRpc(res);
    ref.invalidateSelf();
  }

  Future<void> toggleOptionAvailability(VariantOption option) async {
    final client = ref.read(supabaseProvider);
    final res = await client.rpc('owner_upsert_variant_option_v1', params: {
      'p_group_id': option.groupId,
      'p_option_id': option.id,
      'p_label': option.label,
      'p_price_modifier_cents': option.priceModifierCents,
      'p_is_default': option.isDefault,
      'p_is_available': !option.isAvailable,
      'p_sort_order': option.sortOrder,
    });
    _checkRpc(res);
    ref.invalidateSelf();
  }

  void _checkRpc(dynamic res) {
    final data = res as Map<String, dynamic>?;
    if (data?['ok'] != true) {
      throw Exception(data?['error'] ?? 'rpc_failed');
    }
  }
}
