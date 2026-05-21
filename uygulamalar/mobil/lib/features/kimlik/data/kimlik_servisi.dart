import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService(this.client);
  final SupabaseClient client;

  // ── Email / Password ──────────────────────────────────────────────────────

  Future<void> signInWithEmail(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return client.auth.signUp(email: email, password: password);
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  //
  // Gereksinimler:
  //  1. Firebase konsolunda SHA-1 fingerprint ekli olmalı.
  //  2. Firebase konsolunda Google Sign-In etkin olmalı.
  //  3. Supabase Auth → Providers → Google etkin + Client ID/Secret girilmiş olmalı.

  Future<AuthResponse> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException('Google girişi iptal edildi.');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw const AuthException(
        'Google\'dan kimlik jetonu alınamadı. Firebase SHA-1 ayarını kontrol edin.',
      );
    }

    return client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
  }

  // ── Apple Sign-In ─────────────────────────────────────────────────────────
  //
  // Tarayıcı tabanlı OAuth akışı kullanır (native SDK gerektirmez).
  // Supabase Auth → Providers → Apple etkin + Service ID girilmiş olmalı.

  Future<void> signInWithApple() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.supabase.yeedoy://login-callback',
    );
  }

  // ── Telefon OTP ───────────────────────────────────────────────────────────
  //
  // Gereksinimler:
  //  1. Supabase Auth → Providers → Phone etkin olmalı.
  //  2. SMS sağlayıcısı (Twilio / MessageBird) yapılandırılmış olmalı.

  /// Telefon numarasına OTP gönderir.
  /// [phone] E.164 formatında olmalı: +90XXXXXXXXXX
  Future<void> sendPhoneOtp(String phone) async {
    await client.auth.signInWithOtp(phone: phone);
  }

  /// Gelen OTP kodunu doğrular ve oturum açar.
  Future<AuthResponse> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    return client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  // ── Şifre sıfırlama (e-posta ile link) ───────────────────────────────────

  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.yeedoy://reset-callback',
    );
  }

  // ── Şifre güncelleme (giriş yapıktan sonra) ───────────────────────────────

  Future<void> updatePassword(String newPassword) async {
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // ── E-posta değiştirme ────────────────────────────────────────────────────

  Future<void> updateEmail(String newEmail) async {
    await client.auth.updateUser(UserAttributes(email: newEmail));
  }

  // ── Çıkış ─────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await client.auth.signOut(scope: SignOutScope.global);
  }
}
