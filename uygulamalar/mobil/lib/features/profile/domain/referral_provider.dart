import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/referral_repository.dart';

final referralStatsProvider = FutureProvider.autoDispose<ReferralStats>((ref) {
  return ref.watch(referralRepositoryProvider).fetchMyStats();
});
