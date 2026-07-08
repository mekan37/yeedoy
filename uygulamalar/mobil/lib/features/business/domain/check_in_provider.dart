import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/check_in_repository.dart';

/// Provider: bugün bu işletmeye check-in yapılmış mı? (bool)
/// Notifier, check-in sonrasında state'i günceller.
final checkInNotifierProvider =
    AsyncNotifierProvider.autoDispose.family<CheckInNotifier, bool, String>(
  (businessId) => CheckInNotifier(businessId),
);

class CheckInNotifier extends AsyncNotifier<bool> {
  CheckInNotifier(this.businessId);
  final String businessId;

  @override
  Future<bool> build() async {
    return ref.read(checkInRepositoryProvider).hasCheckedInToday(businessId);
  }

  Future<CheckInResult> checkIn() async {
    final repo = ref.read(checkInRepositoryProvider);
    final result = await repo.submitCheckIn(businessId);
    if (result == CheckInResult.success) {
      state = const AsyncData(true);
    }
    return result;
  }
}
