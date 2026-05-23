import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../kimlik/domain/kimlik_saglayicilari.dart';
import '../data/profil_deposu.dart';
import 'profil_ilerleme.dart';

final myProfileProgressProvider = FutureProvider<ProfileProgress?>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return null;
  return ref.read(profileRepositoryProvider).fetchMyProfileProgress();
});


