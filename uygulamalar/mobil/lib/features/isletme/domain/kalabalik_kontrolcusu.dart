import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/kalabalik_deposu.dart';
import 'kalabalik_modelleri.dart';

final businessCrowdProvider =
    AsyncNotifierProvider.family<BusinessCrowdController, BusinessCrowdStatus, String>(
  BusinessCrowdController.new,
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

