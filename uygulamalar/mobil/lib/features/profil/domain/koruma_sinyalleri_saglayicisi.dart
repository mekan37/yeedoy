import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../kimlik/domain/kimlik_saglayicilari.dart';
import '../data/profil_deposu.dart';
import 'kullanici_koruma_sinyalleri.dart';

final myMoatSignalsProvider = FutureProvider<UserMoatSignals?>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return null;
  return ref.read(profileRepositoryProvider).fetchMyMoatSignals();
});


