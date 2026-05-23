import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../kimlik/domain/kimlik_saglayicilari.dart';
import '../data/profil_deposu.dart';
import 'basari.dart';

final myAchievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return const [];
  return ref.read(profileRepositoryProvider).fetchMyAchievements();
});


