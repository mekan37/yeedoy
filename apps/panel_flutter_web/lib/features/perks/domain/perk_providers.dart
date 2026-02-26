import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/perk_repository.dart';
import 'perk_models.dart';

final businessPerksProvider =
    FutureProvider.family<List<BusinessPerk>, String>((ref, businessId) async {
  return ref.watch(perkRepositoryProvider).getActivePerks(businessId);
});

final ownerPerksProvider =
    FutureProvider.family<List<BusinessPerk>, String>((ref, businessId) async {
  return ref.watch(perkRepositoryProvider).listOwnerPerks(businessId);
});
