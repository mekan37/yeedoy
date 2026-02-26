import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/budget_combo_models.dart';

class BudgetCombosRepository {
  BudgetCombosRepository(this.client);

  final SupabaseClient client;

  Future<List<BudgetComboResult>> getCombos(BudgetComboQuery query) async {
    final data = await client.rpc('get_budget_combos_v1', params: {
      'p_city': query.city,
      'p_district': query.district,
      'p_party_size': query.partySize,
      'p_budget_total_cents': query.budgetTotalCents,
      'p_category': query.category,
      'p_limit': query.limit,
    });
    final list = (data as List?)?.cast<Map<String, dynamic>>() ?? const [];
    return list.map(BudgetComboResult.fromMap).toList();
  }
}
