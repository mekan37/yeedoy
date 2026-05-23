import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ayricalik_deposu.dart';
import 'ayricalik_modelleri.dart';

final businessPerksProvider =
    FutureProvider.family<List<BusinessPerk>, String>((ref, businessId) async {
  return ref.watch(perkRepositoryProvider).fetchActivePerks(businessId);
});

