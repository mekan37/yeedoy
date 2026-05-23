import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../kimlik/domain/kimlik_saglayicilari.dart';
import '../data/profil_deposu.dart';
import 'profil_istatistikleri.dart';

final myProfileStatsProvider = FutureProvider<ProfileStats>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) {
    return ProfileStats(
      reviewsCount: 0,
      helpfulReceived: 0,
      favoritesCount: 0,
      contributionScore: 0,
      visitsCount: 0,
    );
  }
  return ref.read(profileRepositoryProvider).fetchMyStats();
});


