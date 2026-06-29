import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_providers.dart';
import '../data/profile_repository.dart';
import 'contribution_history.dart';

final contributionHistoryProvider =
    FutureProvider.autoDispose<ContributionHistory>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) {
    return ContributionHistory(
      menuSuggestionsCount: 0,
      priceVerificationsCount: 0,
      businessSuggestionsCount: 0,
      recentItems: const [],
    );
  }
  return ref.read(profileRepositoryProvider).fetchMyContributionHistory();
});
