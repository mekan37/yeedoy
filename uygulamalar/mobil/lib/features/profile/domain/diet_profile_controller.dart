import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_providers.dart';
import '../data/diet_profile_repository.dart';
import 'diet_profile.dart';

final dietProfileProvider =
    AsyncNotifierProvider<DietProfileController, DietProfile?>(DietProfileController.new);

class DietProfileController extends AsyncNotifier<DietProfile?> {
  @override
  Future<DietProfile?> build() async {
    final user = ref.read(userProvider);
    if (user == null) return null;
    return ref.read(dietProfileRepositoryProvider).fetchMyDietProfile();
  }

  Future<void> refresh() async {
    final user = ref.read(userProvider);
    if (user == null) {
      state = const AsyncValue.data(null);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(dietProfileRepositoryProvider).fetchMyDietProfile();
    });
  }

  Future<DietProfile> save(DietProfile profile) async {
    state = const AsyncLoading();
    final updated = await ref.read(dietProfileRepositoryProvider).upsertMyDietProfile(profile);
    state = AsyncValue.data(updated);
    return updated;
  }
}
