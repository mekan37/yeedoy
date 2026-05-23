import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ogun_karti_saglayicilari_deposu.dart';
import 'ogun_karti_saglayici_secenegi.dart';

final allMealCardProvidersProvider =
    FutureProvider<List<MealCardProviderOption>>((ref) async {
      return ref.watch(mealCardProvidersRepositoryProvider).listAllProviders();
    });

final businessMealCardProvidersProvider =
    FutureProvider.family<List<MealCardProviderOption>, String>((
      ref,
      businessId,
    ) async {
      return ref
          .watch(mealCardProvidersRepositoryProvider)
          .listBusinessProviders(businessId);
    });


