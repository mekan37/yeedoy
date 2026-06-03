// ignore_for_file: avoid_print
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeedoy/core/privacy/data/consent_provider.dart';
import 'package:yeedoy/core/privacy/domain/consent_repository.dart';
import 'package:yeedoy/core/privacy/domain/consent_state.dart';

// ---------------------------------------------------------------------------
// Fake ConsentRepository — SharedPreferences gerektirmez.
// ---------------------------------------------------------------------------

class _FakeConsentRepository implements ConsentRepository {
  ConsentState _stored = const ConsentState();

  @override
  Future<ConsentState> load() async => _stored;

  @override
  Future<void> save(ConsentState state) async => _stored = state;

  @override
  Future<void> clear() async => _stored = const ConsentState();
}

// ---------------------------------------------------------------------------
// Yardımcılar
// ---------------------------------------------------------------------------

ProviderContainer _container(_FakeConsentRepository repo) {
  final container = ProviderContainer(
    overrides: [
      consentRepositoryProvider.overrideWithValue(repo),
    ],
  );
  return container;
}

// ---------------------------------------------------------------------------
// Testler
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  // -------------------------------------------------------------------------
  // T1: İlk açılışta consent yoksa hasDecided false döner
  // -------------------------------------------------------------------------
  group('T1 — İlk açılış', () {
    test('ConsentNotifier başlangıçta hasDecided false döner', () async {
      final repo = _FakeConsentRepository();
      final container = _container(repo);
      addTearDown(container.dispose);

      // _init() async olduğundan kısa bekle
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final state = container.read(consentNotifierProvider);
      expect(state.hasDecided, isFalse,
          reason: 'Hiçbir onay verilmemişken hasDecided false olmalı');
      expect(state.analytics, ConsentStatus.unknown);
      expect(state.marketing, ConsentStatus.unknown);
    });

    test('allGranted başlangıçta false', () async {
      final repo = _FakeConsentRepository();
      final container = _container(repo);
      addTearDown(container.dispose);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      final state = container.read(consentNotifierProvider);
      expect(state.allGranted, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // T2: grantAll() sonrası hasDecided true, tüm izinler granted
  // -------------------------------------------------------------------------
  group('T2 — grantAll() kalıcılığı', () {
    test('grantAll() sonrası hasDecided true', () async {
      final repo = _FakeConsentRepository();
      final container = _container(repo);
      addTearDown(container.dispose);

      await container.read(consentNotifierProvider.notifier).grantAll();

      final state = container.read(consentNotifierProvider);
      expect(state.hasDecided, isTrue);
      expect(state.allGranted, isTrue);
    });

    test('grantAll() sonrası analytics ve marketing granted', () async {
      final repo = _FakeConsentRepository();
      final container = _container(repo);
      addTearDown(container.dispose);

      await container.read(consentNotifierProvider.notifier).grantAll();

      final state = container.read(consentNotifierProvider);
      expect(state.analytics, ConsentStatus.granted);
      expect(state.marketing, ConsentStatus.granted);
      expect(state.dataRetention, ConsentStatus.granted);
    });

    test('grantAll() sonrası repository\'de persist edildi', () async {
      final repo = _FakeConsentRepository();
      final container = _container(repo);
      addTearDown(container.dispose);

      await container.read(consentNotifierProvider.notifier).grantAll();

      final loaded = await repo.load();
      expect(loaded.analytics, ConsentStatus.granted);
      expect(loaded.marketing, ConsentStatus.granted);
    });

    test('grantAll() sonrası consentedAt null değil', () async {
      final repo = _FakeConsentRepository();
      final container = _container(repo);
      addTearDown(container.dispose);

      await container.read(consentNotifierProvider.notifier).grantAll();

      final state = container.read(consentNotifierProvider);
      expect(state.consentedAt, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // T3: grantAll() → clearAll() → hasDecided false (tekrar consent gerekir)
  // -------------------------------------------------------------------------
  group('T3 — clearAll() KVKK sıfırlama', () {
    test('grantAll() ardından clearAll() hasDecided false yapar', () async {
      final repo = _FakeConsentRepository();
      final container = _container(repo);
      addTearDown(container.dispose);

      await container.read(consentNotifierProvider.notifier).grantAll();
      await container.read(consentNotifierProvider.notifier).clearAll();

      final state = container.read(consentNotifierProvider);
      expect(state.hasDecided, isFalse);
      expect(state.analytics, ConsentStatus.unknown);
      expect(state.marketing, ConsentStatus.unknown);
    });

    test('clearAll() sonrası repository\'de de temizlendi', () async {
      final repo = _FakeConsentRepository();
      final container = _container(repo);
      addTearDown(container.dispose);

      await container.read(consentNotifierProvider.notifier).grantAll();
      await container.read(consentNotifierProvider.notifier).clearAll();

      final loaded = await repo.load();
      expect(loaded.hasDecided, isFalse);
    });

    test('clearAll() sonrası load() tekrar unknown döner', () async {
      final repo = _FakeConsentRepository();
      final container = _container(repo);
      addTearDown(container.dispose);

      await container.read(consentNotifierProvider.notifier).grantAll();
      await container.read(consentNotifierProvider.notifier).clearAll();
      await container.read(consentNotifierProvider.notifier).load();

      final state = container.read(consentNotifierProvider);
      expect(state.analytics, ConsentStatus.unknown);
    });
  });

  // -------------------------------------------------------------------------
  // T4: deny() sonrası hasDecided true — ikinci çağrıda değişmez
  // -------------------------------------------------------------------------
  group('T4 — deny() döngü koruması', () {
    test('deny() sonrası hasDecided true (karar verilmiş)', () async {
      final repo = _FakeConsentRepository();
      final container = _container(repo);
      addTearDown(container.dispose);

      await container.read(consentNotifierProvider.notifier).deny();

      final state = container.read(consentNotifierProvider);
      expect(state.hasDecided, isTrue,
          reason: 'deny() de bir karar, hasDecided true olmalı');
    });

    test('deny() sonrası analytics ve marketing denied', () async {
      final repo = _FakeConsentRepository();
      final container = _container(repo);
      addTearDown(container.dispose);

      await container.read(consentNotifierProvider.notifier).deny();

      final state = container.read(consentNotifierProvider);
      expect(state.analytics, ConsentStatus.denied);
      expect(state.marketing, ConsentStatus.denied);
    });

    test('deny() sonrası dataRetention granted (KVKK zorunlu)', () async {
      final repo = _FakeConsentRepository();
      final container = _container(repo);
      addTearDown(container.dispose);

      await container.read(consentNotifierProvider.notifier).deny();

      final state = container.read(consentNotifierProvider);
      expect(state.dataRetention, ConsentStatus.granted,
          reason: 'KVKK madde 7 gereği dataRetention zorunlu kabul edilir');
    });

    test('deny() ikinci çağrısında state aynı kalır — döngü yok', () async {
      final repo = _FakeConsentRepository();
      final container = _container(repo);
      addTearDown(container.dispose);

      await container.read(consentNotifierProvider.notifier).deny();
      final firstState = container.read(consentNotifierProvider);

      await container.read(consentNotifierProvider.notifier).deny();
      final secondState = container.read(consentNotifierProvider);

      expect(secondState.analytics, firstState.analytics);
      expect(secondState.marketing, firstState.marketing);
      expect(secondState.hasDecided, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // T5: grantAnalyticsOnly() — pazarlama reddedilir
  // -------------------------------------------------------------------------
  group('T5 — grantAnalyticsOnly()', () {
    test('analytics granted, marketing denied', () async {
      final repo = _FakeConsentRepository();
      final container = _container(repo);
      addTearDown(container.dispose);

      await container
          .read(consentNotifierProvider.notifier)
          .grantAnalyticsOnly();

      final state = container.read(consentNotifierProvider);
      expect(state.analytics, ConsentStatus.granted);
      expect(state.marketing, ConsentStatus.denied);
      expect(state.hasDecided, isTrue);
      expect(state.allGranted, isFalse,
          reason: 'Marketing denied olduğundan allGranted false kalmalı');
    });
  });

  // -------------------------------------------------------------------------
  // T6: ConsentState model testleri
  // -------------------------------------------------------------------------
  group('T6 — ConsentState model', () {
    test('copyWith yalnızca belirtilen alanı günceller', () {
      const original = ConsentState(
        analytics: ConsentStatus.granted,
        marketing: ConsentStatus.denied,
      );
      final copy = original.copyWith(marketing: ConsentStatus.granted);

      expect(copy.analytics, ConsentStatus.granted);
      expect(copy.marketing, ConsentStatus.granted);
    });

    test('toJson → fromJson round-trip', () {
      const state = ConsentState(
        analytics: ConsentStatus.granted,
        marketing: ConsentStatus.denied,
        dataRetention: ConsentStatus.granted,
      );
      final json = state.toJson();
      final restored = ConsentState.fromJson(json);

      expect(restored.analytics, state.analytics);
      expect(restored.marketing, state.marketing);
      expect(restored.dataRetention, state.dataRetention);
    });

    test('fromJson bilinmeyen string → unknown', () {
      final state = ConsentState.fromJson({
        'analytics': 'bogus',
        'marketing': null,
        'dataRetention': 'granted',
      });
      expect(state.analytics, ConsentStatus.unknown);
      expect(state.marketing, ConsentStatus.unknown);
      expect(state.dataRetention, ConsentStatus.granted);
    });
  });
}
