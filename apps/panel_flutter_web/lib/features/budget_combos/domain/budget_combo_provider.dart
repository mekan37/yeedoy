import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_provider.dart';
import '../data/budget_combos_repository.dart';
import 'budget_combo_models.dart';

final budgetCombosRepositoryProvider = Provider<BudgetCombosRepository>((ref) {
  return BudgetCombosRepository(ref.watch(supabaseProvider));
});

final budgetCombosProvider =
    FutureProvider.family<List<BudgetComboResult>, BudgetComboQuery>((ref, query) async {
  return ref.read(budgetCombosRepositoryProvider).getCombos(query);
});
