import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/onbellek/istek_onbellegi.dart';
import '../../../core/ag/supabase_saglayicisi.dart';
import '../data/butce_kombinasyonlari_deposu.dart';
import 'butce_kombinasyon_modelleri.dart';

final budgetCombosRepositoryProvider = Provider<BudgetCombosRepository>((ref) {
  return BudgetCombosRepository(
    ref.watch(supabaseProvider),
    ref.watch(requestCacheProvider),
  );
});

final budgetCombosProvider =
    FutureProvider.family<List<BudgetComboResult>, BudgetComboQuery>((ref, query) async {
  return ref.read(budgetCombosRepositoryProvider).fetchCombos(query);
});

