import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/suspended_meal_repository.dart';
import 'suspended_meal_models.dart';

final suspendedMealsProvider =
    AsyncNotifierProvider.family<SuspendedMealsController, List<SuspendedMeal>, String>(
  SuspendedMealsController.new,
);

class SuspendedMealsController extends AsyncNotifier<List<SuspendedMeal>> {
  SuspendedMealsController(this.businessId);
  final String businessId;

  @override
  Future<List<SuspendedMeal>> build() async {
    return ref.read(suspendedMealRepositoryProvider).listActive(businessId);
  }

  Future<void> refresh({bool force = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(suspendedMealRepositoryProvider).listActive(businessId);
    });
  }

  Future<void> create({
    required int amountCents,
    required String currency,
    required String message,
  }) async {
    await ref.read(suspendedMealRepositoryProvider).create(
          businessId: businessId,
          amountCents: amountCents,
          currency: currency,
          message: message,
        );
    await refresh(force: true);
  }

  Future<void> claim({
    required String mealId,
    required String note,
  }) async {
    await ref.read(suspendedMealRepositoryProvider).claim(
          mealId: mealId,
          note: note,
        );
    await refresh(force: true);
  }
}
