import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/crowd_repository.dart';
import 'crowd_models.dart';

final businessCrowdProvider =
    AsyncNotifierProvider.autoDispose.family<BusinessCrowdController, BusinessCrowdStatus, String>(
  (arg) => BusinessCrowdController(arg),
);

class BusinessCrowdController extends AsyncNotifier<BusinessCrowdStatus> {
  BusinessCrowdController(this.businessId);
  final String businessId;

  @override
  Future<BusinessCrowdStatus> build() async {
    return ref.read(crowdRepositoryProvider).fetchBusinessCrowd(businessId);
  }

  Future<void> refresh({bool force = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(crowdRepositoryProvider).fetchBusinessCrowd(businessId);
    });
  }

  Future<void> submitPresence(String crowd) async {
    await ref.read(crowdRepositoryProvider).submitPresence(
          businessId: businessId,
          crowd: crowd,
        );
    await refresh(force: true);
  }
}
