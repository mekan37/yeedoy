import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_providers.dart';
import '../data/profile_repo.dart';
import 'profile_progress.dart';

final myProfileProgressProvider = FutureProvider<ProfileProgress?>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return null;
  return ref.read(profileRepoProvider).getMyProfileProgress();
});
