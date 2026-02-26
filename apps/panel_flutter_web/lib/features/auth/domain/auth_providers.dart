import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_provider.dart';
import '../../taste_twin/data/taste_twin_repository.dart';
import '../../taste_twin/domain/taste_twin_models.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseProvider);

  // Ilk state??Ti ka?irmamak i?in controller
  final controller = StreamController<AuthState>();

  // mevcut session state (app a?ili?Y)
  controller.add(
    AuthState(
      AuthChangeEvent.initialSession,
      client.auth.currentSession,
    ),
  );

  final sub = client.auth.onAuthStateChange.listen(controller.add);

  ref.onDispose(() async {
    await sub.cancel();
    await controller.close();
  });

  return controller.stream;
});

final sessionProvider = Provider<Session?>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.asData?.value.session;
});

final userProvider = Provider<User?>((ref) {
  return ref.watch(sessionProvider)?.user;
});

class _EnsureProfileStore {
  String? lastUserId;
}

final _ensureProfileStoreProvider = Provider<_EnsureProfileStore>((ref) {
  return _EnsureProfileStore();
});

final ensureMyProfileProvider = Provider<void>((ref) {
  ref.listen(authStateProvider, (prev, next) async {
    final user = next.asData?.value.session?.user;
    if (user == null) return;
    final store = ref.read(_ensureProfileStoreProvider);
    if (store.lastUserId == user.id) return;
    store.lastUserId = user.id;

    final profileRepo = ref.read(tasteTwinRepositoryProvider);
    PublicProfile? publicProfile;
    try {
      publicProfile = await profileRepo.getUserPublicProfile(user.id);
    } catch (_) {
      publicProfile = null;
    }
    final existingName = publicProfile?.displayName ?? '';
    final fallback = user.email?.split('@').first ?? 'Kullanıcı';
    final displayName = existingName.trim().isNotEmpty ? existingName : fallback;
    final avatarUrl =
        (publicProfile?.avatarUrl.isNotEmpty == true) ? publicProfile!.avatarUrl : '';

    await profileRepo.ensureMyProfile(
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  });
});





