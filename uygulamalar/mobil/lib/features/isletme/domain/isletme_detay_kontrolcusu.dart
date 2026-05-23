import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/isletme_detay_deposu.dart';
import 'isletme_detay.dart';

final businessDetailProvider =
    AsyncNotifierProvider.family<
      BusinessDetailController,
      BusinessDetail,
      String
    >(BusinessDetailController.new);

class BusinessDetailController extends AsyncNotifier<BusinessDetail> {
  BusinessDetailController(this.businessId);
  final String businessId;

  @override
  Future<BusinessDetail> build() async {
    final swr = await ref
        .read(businessDetailRepositoryProvider)
        .getBusinessDetailSWR(businessId);
    if (swr.refresh != null) {
      swr.refresh!.then((fresh) {
        final current = state.asData?.value;
        if (current == null ||
            current.stats.id != fresh.stats.id ||
            current.stats.avgRating != fresh.stats.avgRating ||
            current.latestReviews.length != fresh.latestReviews.length) {
          state = AsyncData(fresh);
        }
      });
    }
    return swr.data;
  }

  Future<void> refresh({bool force = false}) async {
    final previous = state.asData?.value;
    if (!force && previous != null) {
      state = AsyncData(previous);
    } else {
      state = const AsyncLoading();
    }
    state = await AsyncValue.guard(() {
      return ref
          .read(businessDetailRepositoryProvider)
          .fetchBusinessDetail(businessId, force: force);
    });
  }
}

