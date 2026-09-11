import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';

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
    final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

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
    return client.auth.verifyOTP(phone: phone, token: token, type: OtpType.sms);
  }

  // ── Şifre sıfırlama (e-posta ile link) ───────────────────────────────────

  Future<void> resetPassword(String email) async {
    // B33: eskiden doğrulanmamış özel URL şeması (io.supabase.yeedoy://)
    // kullanılıyordu — cihazdaki başka bir uygulama aynı şemayı kayıt
    // ettirip linki ele geçirebilirdi. Artık App Links/Universal Links ile
    // doğrulanan gerçek yeedoy.com domaini kullanılıyor (bkz.
    // android/app/src/main/AndroidManifest.xml'deki https intent-filter'ı,
    // ios/Runner/Runner.entitlements'taki associated-domains ve
    // web/public/.well-known/{assetlinks.json,apple-app-site-association}).
    // Uygulama yüklüyse ve doğrulama geçtiyse link doğrudan uygulamayı açar;
    // aksi halde web'deki /sifre-sifirlama sayfasına düşer.
    await client.auth.resetPasswordForEmail(
      email,
      redirectTo: '${AppConfig.webBaseUrl}/sifre-sifirlama',
    );
  }

  // ── Şifre güncelleme (giriş yapıktan sonra) ───────────────────────────────

  /// Kullanıcının şifre ile giriş yapabilen bir e-posta identity'si var mı
  /// (yalnızca Google ile giriş yapmış bir kullanıcının henüz şifresi
  /// yoktur — bu durumda reauth istenmez, ilk şifre "belirleme" akışı
  /// bozulmaz).
  bool get hasPasswordIdentity =>
      (client.auth.currentUser?.identities ?? const []).any(
        (identity) => identity.provider == 'email',
      );

  /// Şifre/e-posta gibi hassas değişikliklerden önce mevcut şifreyi
  /// doğrular. Supabase, oturum açıkken updateUser() için mevcut şifreyi
  /// sormaz — bu, cihaza fiziksel/oturum erişimi olan birinin şifreyi
  /// bilmeden hesabı ele geçirmesine izin verirdi (B11). signInWithPassword
  /// ile sessiz bir doğrulama yapılır; yanlışsa AuthException fırlatılır.
  Future<void> verifyCurrentPassword(String currentPassword) async {
    final email = client.auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      throw const AuthException('Mevcut şifre doğrulanamadı.');
    }
    await client.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // ── E-posta değiştirme ────────────────────────────────────────────────────

  Future<void> updateEmail(String newEmail) async {
    await client.auth.updateUser(UserAttributes(email: newEmail));
  }

  // ── Telefon numarası değiştirme ───────────────────────────────────────────

  /// Telefon numarasını değiştirmek için OTP gönderir.
  /// Supabase → Authentication → Providers → Phone etkin olmalı.
  Future<void> requestPhoneChange(String phone) async {
    await client.auth.updateUser(UserAttributes(phone: phone));
  }

  /// Telefon numarası değişikliğini OTP kodu ile doğrular.
  Future<void> verifyPhoneChange({
    required String phone,
    required String token,
  }) async {
    await client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.phoneChange,
    );
  }

  // ── Çıkış ─────────────────────────────────────────────────────────────────

  /// Düşük seviyeli Supabase çağrısı. UI kodu bunu DOĞRUDAN çağırmamalı —
  /// push cihaz kaydını sunucudan silme ve yerel önbellek/kuyruk temizliği
  /// gibi oturum kapanış adımlarını atlar. Bunun yerine
  /// `ref.read(sessionCleanupServiceProvider).signOut()` kullanın
  /// (bkz. core/session/session_cleanup_service.dart).
  Future<void> signOut() async {
    await client.auth.signOut(scope: SignOutScope.global);
  }
}
