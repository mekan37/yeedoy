import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService(this.client);
  final SupabaseClient client;

  Future<void> signInWithEmail(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await client.auth.signOut(scope: SignOutScope.global);
  }
}
