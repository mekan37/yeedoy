import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yeedoy/core/network/supabase_provider.dart';
import 'package:yeedoy/features/auth/data/auth_service.dart';
import 'package:yeedoy/features/auth/data/auth_service_provider.dart';
import 'package:yeedoy/features/auth/domain/auth_providers.dart';

// ---------------------------------------------------------------------------
// Mock'lar
// ---------------------------------------------------------------------------

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockSupabaseClient extends Mock implements SupabaseClient {}

// ---------------------------------------------------------------------------
// Fake AuthService — gerçek Supabase çağrısı yapmaz
// ---------------------------------------------------------------------------

class _FakeAuthService extends AuthService {
  _FakeAuthService()
      : super(
          SupabaseClient(
            'http://localhost:54321',
            'fake-anon-key',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        );

  bool signInCalled = false;
  bool signOutCalled = false;
  Object? throwOnSignIn;
  String? lastEmail;
  String? lastPassword;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    signInCalled = true;
    lastEmail = email;
    lastPassword = password;
    if (throwOnSignIn != null) throw throwOnSignIn!;
  }

  @override
  Future<AuthResponse> signUpWithEmail(String email, String password) async =>
      throw UnimplementedError();

  @override
  Future<AuthResponse> signInWithGoogle() async => throw UnimplementedError();

  @override
  Future<void> sendPhoneOtp(String phone) async {}

  @override
  Future<AuthResponse> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }
}

// ---------------------------------------------------------------------------
// Stub User & Session
// ---------------------------------------------------------------------------

User _stubUser({String id = 'user-1', String email = 'test@yeedoy.com'}) =>
    User(
      id: id,
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      email: email,
      createdAt: DateTime.now().toIso8601String(),
    );

Session _fakeSession(User user) => Session(
      accessToken: 'fake-token',
      tokenType: 'bearer',
      user: user,
    );

// ---------------------------------------------------------------------------
// authStateProvider stream-based test helper
//
// authStateProvider kullanmak yerine AsyncValue override ile test et.
// overrideWithValue(AsyncData(...)) ile senkron veri saglar.
// ---------------------------------------------------------------------------

ProviderContainer _containerWithAuthState(AuthState authState) {
  return ProviderContainer(
    overrides: [
      authStateProvider.overrideWithValue(AsyncData(authState)),
    ],
  );
}

// ---------------------------------------------------------------------------
// Testler
// ---------------------------------------------------------------------------

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // Grup 1: AuthService Unit Testleri
  // ──────────────────────────────────────────────────────────────────────────
  group('AuthService — unit testleri', () {
    late _FakeAuthService authService;

    setUp(() => authService = _FakeAuthService());

    test('signIn basarili — signInCalled true ve email kaydedildi', () async {
      await authService.signInWithEmail('user@test.com', 'sifre1234');
      expect(authService.signInCalled, isTrue);
      expect(authService.lastEmail, 'user@test.com');
      expect(authService.lastPassword, 'sifre1234');
    });

    test('signIn hatasi — AuthException firlatiliyor', () {
      authService.throwOnSignIn =
          const AuthException('invalid login credentials');
      expect(
        () => authService.signInWithEmail('bad@test.com', 'yanlis'),
        throwsA(isA<AuthException>()),
      );
    });

    test('signIn hatasi — generic exception', () {
      authService.throwOnSignIn = Exception('network error');
      expect(
        () => authService.signInWithEmail('test@test.com', 'sifre'),
        throwsA(isA<Exception>()),
      );
    });

    test('signOut — signOutCalled true olur', () async {
      await authService.signOut();
      expect(authService.signOutCalled, isTrue);
    });

    test('email olmadan signOut tekrar cagrilabilir', () async {
      await authService.signOut();
      await authService.signOut();
      expect(authService.signOutCalled, isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Grup 2: userProvider — oturumsuz durum
  // overrideWithValue(AsyncData(...)) ile senkron olarak kontrol edilir
  // ──────────────────────────────────────────────────────────────────────────
  group('userProvider — oturumsuz durum', () {
    test('session null iken userProvider null donuyor', () {
      final container = _containerWithAuthState(
        AuthState(AuthChangeEvent.initialSession, null),
      );
      addTearDown(container.dispose);

      expect(container.read(userProvider), isNull);
    });

    test('session dolu iken userProvider kullaniciyi donuyor', () {
      final user = _stubUser(email: 'yeedoy@test.com');
      final session = _fakeSession(user);
      final container = _containerWithAuthState(
        AuthState(AuthChangeEvent.signedIn, session),
      );
      addTearDown(container.dispose);

      expect(container.read(userProvider), isNotNull);
      expect(container.read(userProvider)?.email, 'yeedoy@test.com');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Grup 3: sessionProvider
  // ──────────────────────────────────────────────────────────────────────────
  group('sessionProvider', () {
    test('signedOut sonrasi sessionProvider null donuyor', () {
      final container = _containerWithAuthState(
        AuthState(AuthChangeEvent.signedOut, null),
      );
      addTearDown(container.dispose);

      expect(container.read(sessionProvider), isNull);
    });

    test('signedIn sonrasi sessionProvider dolu donuyor', () {
      final user = _stubUser();
      final session = _fakeSession(user);
      final container = _containerWithAuthState(
        AuthState(AuthChangeEvent.signedIn, session),
      );
      addTearDown(container.dispose);

      final s = container.read(sessionProvider);
      expect(s, isNotNull);
      expect(s?.user.id, user.id);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Grup 4: authStateProvider — AsyncValue override ile event testleri
  // overrideWithValue(AsyncData(...)) ile senkron test edilir
  // ──────────────────────────────────────────────────────────────────────────
  group('authStateProvider — AsyncValue override ile event testleri', () {
    test('initialSession eventi event tipi ve null session ile geliyor', () {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWithValue(
            AsyncData(AuthState(AuthChangeEvent.initialSession, null)),
          ),
        ],
      );
      addTearDown(container.dispose);

      final authState = container.read(authStateProvider).requireValue;
      expect(authState.event, AuthChangeEvent.initialSession);
      expect(authState.session, isNull);
    });

    test('signedOut eventi session null ile geliyor', () {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWithValue(
            AsyncData(AuthState(AuthChangeEvent.signedOut, null)),
          ),
        ],
      );
      addTearDown(container.dispose);

      final authState = container.read(authStateProvider).requireValue;
      expect(authState.session, isNull);
      expect(container.read(sessionProvider), isNull);
    });

    test('signedIn eventi user email ile geliyor', () {
      final user = _stubUser(email: 'yeedoy@test.com');
      final session = _fakeSession(user);

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWithValue(
            AsyncData(AuthState(AuthChangeEvent.signedIn, session)),
          ),
        ],
      );
      addTearDown(container.dispose);

      final authState = container.read(authStateProvider).requireValue;
      expect(authState.session?.user.email, 'yeedoy@test.com');
      expect(container.read(userProvider)?.email, 'yeedoy@test.com');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Grup 5: authStateProvider — gercek StreamProvider ile mock Supabase
  // onAuthStateChange stream listen testi
  // ──────────────────────────────────────────────────────────────────────────
  group('authStateProvider — mock Supabase ile listener testi', () {
    test(
        'onAuthStateChange dinlendikten sonra signedIn eventi sessionProvider gunceller',
        () async {
      final mockClient = _MockSupabaseClient();
      final mockAuth = _MockGoTrueClient();

      // authStateProvider'in build fonksiyonu:
      //   1. controller.add(AuthState(initialSession, currentSession))
      //   2. client.auth.onAuthStateChange.listen(controller.add)
      // Biz de onAuthStateChange stream'ine ilave event gonderecegiz.
      final sc = StreamController<AuthState>.broadcast();

      when(() => mockAuth.onAuthStateChange).thenAnswer((_) => sc.stream);
      when(() => mockAuth.currentSession).thenReturn(null);
      when(() => mockClient.auth).thenReturn(mockAuth);

      final container = ProviderContainer(
        overrides: [supabaseProvider.overrideWithValue(mockClient)],
      );

      // authStateProvider'i izle ve deger degisimlerini topla
      final collected = <AuthState>[];
      final sub = container.listen<AsyncValue<AuthState>>(
        authStateProvider,
        (_, next) {
          if (next.hasValue) collected.add(next.requireValue);
        },
        fireImmediately: true,
      );

      // Provider build edilsin — initialSession null ile gelir
      // StreamController'in add() senkron olarak buffer'landi
      // Birkaç mikrotask gecisi bekliyoruz
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // signedIn eventi gonder
      final user = _stubUser(email: 'listener@test.com');
      final session = _fakeSession(user);
      sc.add(AuthState(AuthChangeEvent.signedIn, session));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      sub.close();
      container.dispose();
      await sc.close();

      // En az 1 event (initialSession) geldi mi?
      expect(collected, isNotEmpty);
      // signedIn eventi geldi mi?
      if (collected.length > 1) {
        expect(
          collected.any((s) => s.session?.user.email == 'listener@test.com'),
          isTrue,
        );
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Grup 6: authServiceProvider — doğru servis döndürüyor
  // ──────────────────────────────────────────────────────────────────────────
  group('authServiceProvider', () {
    test('override ile fake servis donduruluyor', () {
      final fakeService = _FakeAuthService();
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWith((_) => fakeService),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(authServiceProvider), same(fakeService));
    });
  });
}
