import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../kimlik/domain/kimlik_saglayicilari.dart';
import '../data/profil_deposu.dart';

final myReputationScoreProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return 0;
  return ref.read(profileRepositoryProvider).fetchMyReputationScore();
});


