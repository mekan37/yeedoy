import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseProvider);
  final controller = StreamController<AuthState>();

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
