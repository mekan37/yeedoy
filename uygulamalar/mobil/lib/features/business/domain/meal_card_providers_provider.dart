import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/meal_card_providers_repository.dart';
import 'meal_card_provider_option.dart';

final allMealCardProvidersProvider =
    FutureProvider<List<MealCardProviderOption>>((ref) async {
      return ref.watch(mealCardProvidersRepositoryProvider).listAllProviders();
    });

final businessMealCardProvidersProvider =
    FutureProvider.autoDispose.family<List<MealCardProviderOption>, String>((
      ref,
      businessId,
    ) async {
      return ref
          .watch(mealCardProvidersRepositoryProvider)
          .listBusinessProviders(businessId);
    });
