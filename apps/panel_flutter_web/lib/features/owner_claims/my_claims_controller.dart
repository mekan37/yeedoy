import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/owner_claim_repository.dart';
import '../../domain/models/owner_claim.dart';

final myClaimsProvider =
    AsyncNotifierProvider<MyClaimsController, List<OwnerClaimItem>>(
      MyClaimsController.new,
    );

class MyClaimsController extends AsyncNotifier<List<OwnerClaimItem>> {
  @override
  Future<List<OwnerClaimItem>> build() async {
    return _load();
  }

  Future<List<OwnerClaimItem>> _load() async {
    final repo = ref.read(ownerClaimRepositoryProvider);
    final claims = await repo.fetchMyClaims();
    if (claims.isEmpty) return [];
    final ids = claims.map((c) => c.businessId).toSet().toList();
    final names = await repo.fetchBusinessNamesByIds(ids);
    return claims
        .map(
          (c) => OwnerClaimItem(
            claim: c,
            businessName: names[c.businessId] ?? 'İşletme',
          ),
        )
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}

