import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/business_meal_card_providers_repository.dart';
import 'meal_card_provider_option.dart';

final allMealCardProvidersProvider =
    FutureProvider<List<MealCardProviderOption>>((ref) async {
      return ref
          .watch(businessMealCardProvidersRepositoryProvider)
          .listAllProviders();
    });

final businessMealCardProvidersProvider =
    FutureProvider.family<List<MealCardProviderOption>, String>((
      ref,
      businessId,
    ) async {
      return ref
          .watch(businessMealCardProvidersRepositoryProvider)
          .listBusinessProviders(businessId);
    });
