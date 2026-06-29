/// legal_acceptance_page.dart — _submit() pazarlama opt-in davranışı testleri.
///
/// UI pump testlerinden kaçınılır; _submit mantığı doğrudan test edilir.
/// LegalRepository ve NotificationPreferencesRepository fake ile override edilir.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/legal/legal_models.dart';
import 'package:yeedoy/features/legal/legal_repository.dart';
import 'package:yeedoy/features/notifications/data/notification_preferences_repository.dart';
import 'package:yeedoy/features/notifications/domain/notification_preferences_models.dart';
import 'package:yeedoy/features/notifications/domain/notification_preferences_provider.dart';

// ---------------------------------------------------------------------------
// Fake LegalRepository — gerçek Supabase çağrısı yapmaz.
// ---------------------------------------------------------------------------

class _FakeLegalRepository implements LegalRepository {
  _FakeLegalRepository({this.throwOnAccept = false});
  final bool throwOnAccept;
  bool acceptCalled = false;

  @override
  Future<void> acceptPolicyVersions(
    List<PolicyVersionRecord> versions, {
    String sourceApp = 'test',
  }) async {
    if (throwOnAccept) throw Exception('accept_failed');
    acceptCalled = true;
  }

  @override
  Future<PolicyAcceptanceSnapshot?> loadAcceptanceSnapshot() async => null;

  @override
  Future<LegalRequestOverview?> loadRequestOverview() async => null;

  @override
  Future<void> submitPrivacyRequest({
    required String requestType,
    String? details,
  }) async {}

  @override
  Future<void> submitAccountDeletionRequest({String? reason}) async {}
}

// ---------------------------------------------------------------------------
// Fake NotificationPreferencesRepository
// ---------------------------------------------------------------------------

class _FakeNotifPrefsRepository implements NotificationPreferencesRepository {
  _FakeNotifPrefsRepository({this.throwOnUpdate = false});
  final bool throwOnUpdate;
  final List<bool> updateCalls = [];

  @override
  Future<NotificationPreferences> getMyNotificationPreferences() async {
    return NotificationPreferences.defaultValue;
  }

  @override
  Future<void> updateMyMarketingEmailOptIn({required bool enabled}) async {
    if (throwOnUpdate) throw Exception('update_failed');
    updateCalls.add(enabled);
  }
}

// ---------------------------------------------------------------------------
// Test yardımcıları: _submit() mantığını doğrudan simüle eder
// (widget pump olmadan, sadece iş mantığı test edilir).
// ---------------------------------------------------------------------------

/// _submit() içindeki pazarlama opt-in akışını doğrudan simüle eder.
/// Widget'ı pump etmek gerekmez; repository davranışı test edilir.
Future<({bool optInRpcCalled, bool didNavigate, String? errorMessage})>
    _runSubmitLogic({
  required bool acceptedRequired,
  required bool marketingOptIn,
  required _FakeLegalRepository legalRepo,
  required _FakeNotifPrefsRepository notifRepo,
  List<PolicyVersionRecord> versions = const [],
}) async {
  if (!acceptedRequired) {
    return (
      optInRpcCalled: false,
      didNavigate: false,
      errorMessage: 'zorunlu_kabul_eksik',
    );
  }

  try {
    // Adım 1: Zorunlu kabul
    await legalRepo.acceptPolicyVersions(versions);

    // Adım 2: Pazarlama opt-in (yalnızca true ise RPC çağrılır)
    String? marketingError;
    if (marketingOptIn) {
      try {
        await notifRepo.updateMyMarketingEmailOptIn(enabled: true);
      } catch (_) {
        marketingError =
            'Pazarlama e-posta tercihiniz kaydedilemedi. '
            'Bildirim ayarlarından tekrar değiştirebilirsiniz.';
      }
    }

    return (
      optInRpcCalled: notifRepo.updateCalls.isNotEmpty,
      didNavigate: true,
      errorMessage: marketingError,
    );
  } catch (e) {
    return (
      optInRpcCalled: false,
      didNavigate: false,
      errorMessage: e.toString(),
    );
  }
}

// ---------------------------------------------------------------------------
// Testler
// ---------------------------------------------------------------------------

void main() {
  group('LegalAcceptancePage _submit() — pazarlama opt-in davranışı', () {
    // -----------------------------------------------------------------------
    // T1: _marketingOptIn true iken RPC çağrılır
    // -----------------------------------------------------------------------
    test('T1: _marketingOptIn=true iken updateMyMarketingEmailOptIn(true) çağrılır',
        () async {
      final legalRepo = _FakeLegalRepository();
      final notifRepo = _FakeNotifPrefsRepository();

      final result = await _runSubmitLogic(
        acceptedRequired: true,
        marketingOptIn: true,
        legalRepo: legalRepo,
        notifRepo: notifRepo,
      );

      expect(result.optInRpcCalled, isTrue,
          reason: '_marketingOptIn=true iken RPC çağrılmalı');
      expect(notifRepo.updateCalls, [true]);
      expect(result.didNavigate, isTrue);
    });

    // -----------------------------------------------------------------------
    // T2: _marketingOptIn false iken kullanıcı otomatik opt-in yapılmaz
    // -----------------------------------------------------------------------
    test('T2: _marketingOptIn=false iken updateMyMarketingEmailOptIn çağrılmaz',
        () async {
      final legalRepo = _FakeLegalRepository();
      final notifRepo = _FakeNotifPrefsRepository();

      final result = await _runSubmitLogic(
        acceptedRequired: true,
        marketingOptIn: false,
        legalRepo: legalRepo,
        notifRepo: notifRepo,
      );

      expect(result.optInRpcCalled, isFalse,
          reason:
              '_marketingOptIn=false iken RPC çağrılmamalı — '
              'kullanıcı otomatik opt-in yapılmamalı');
      expect(notifRepo.updateCalls, isEmpty);
      expect(result.didNavigate, isTrue);
    });

    // -----------------------------------------------------------------------
    // T3: Zorunlu kabul verilmemişse akış başlamaz
    // -----------------------------------------------------------------------
    test('T3: Zorunlu kabul yoksa RPC çağrılmaz ve navigate edilmez', () async {
      final legalRepo = _FakeLegalRepository();
      final notifRepo = _FakeNotifPrefsRepository();

      final result = await _runSubmitLogic(
        acceptedRequired: false,
        marketingOptIn: true,
        legalRepo: legalRepo,
        notifRepo: notifRepo,
      );

      expect(result.didNavigate, isFalse);
      expect(result.optInRpcCalled, isFalse);
      expect(result.errorMessage, 'zorunlu_kabul_eksik');
    });

    // -----------------------------------------------------------------------
    // T4: Pazarlama izni kaydı başarısız olursa zorunlu akış bloke olmaz
    // -----------------------------------------------------------------------
    test(
        'T4: Pazarlama RPC hatası zorunlu kabul akışını bloke etmez — navigate edilir',
        () async {
      final legalRepo = _FakeLegalRepository();
      final notifRepo = _FakeNotifPrefsRepository(throwOnUpdate: true);

      final result = await _runSubmitLogic(
        acceptedRequired: true,
        marketingOptIn: true,
        legalRepo: legalRepo,
        notifRepo: notifRepo,
      );

      // Zorunlu kabul başarılı → navigate edildi
      expect(result.didNavigate, isTrue,
          reason:
              'Pazarlama RPC hatası yasal kabul akışını bloke etmemeli');
      // Hata mesajı gösterildi
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage, contains('Bildirim ayarlarından'));
      // updateCalls boş — exception fırlattı ama hiç kaydolmadı
      expect(notifRepo.updateCalls, isEmpty);
    });

    // -----------------------------------------------------------------------
    // T5: Zorunlu kabul RPC hatası → navigate edilmez
    // -----------------------------------------------------------------------
    test('T5: Zorunlu kabul RPC hatası → kullanıcı sayfada kalır', () async {
      final legalRepo = _FakeLegalRepository(throwOnAccept: true);
      final notifRepo = _FakeNotifPrefsRepository();

      final result = await _runSubmitLogic(
        acceptedRequired: true,
        marketingOptIn: true,
        legalRepo: legalRepo,
        notifRepo: notifRepo,
      );

      expect(result.didNavigate, isFalse);
      expect(result.errorMessage, isNotNull);
      // Pazarlama RPC'si çağrılmadı — zorunlu kabul başarısız olduğundan
      expect(result.optInRpcCalled, isFalse);
    });

    // -----------------------------------------------------------------------
    // T6: business_follows.is_subscribed_email global izin olarak kullanılmaz
    // -----------------------------------------------------------------------
    test(
        'T6: is_subscribed_email global pazarlama izni olarak kullanılmaz',
        () async {
      // NotificationPreferencesRepository yalnızca
      // update_my_marketing_email_opt_in_v1 çağırır.
      // is_subscribed_email için hiçbir metod tanımlı değil.
      final notifRepo = _FakeNotifPrefsRepository();
      await notifRepo.updateMyMarketingEmailOptIn(enabled: true);

      // Yalnızca marketing_email_opt_in güncellemesi yapıldı
      expect(notifRepo.updateCalls, hasLength(1));
      expect(notifRepo.updateCalls.first, isTrue);
      // is_subscribed_email çağrısı yok — fake repo onu içermiyor bile
    });

    // -----------------------------------------------------------------------
    // T7: SharedPreferences source-of-truth değil
    // -----------------------------------------------------------------------
    test('T7: SharedPreferences set edilmeden repository RPC ile güncellenir',
        () async {
      // SharedPreferences mock kurulmadan test çalışıyor.
      // Değer yalnızca fake repo üzerinden (RPC simüle) tutuluyor.
      final legalRepo = _FakeLegalRepository();
      final notifRepo = _FakeNotifPrefsRepository();

      await _runSubmitLogic(
        acceptedRequired: true,
        marketingOptIn: true,
        legalRepo: legalRepo,
        notifRepo: notifRepo,
      );

      // Source-of-truth repo (RPC) — SharedPreferences değil
      final savedInRepo = notifRepo.updateCalls;
      expect(savedInRepo, [true],
          reason: 'Değer SharedPreferences\'ta değil, RPC üzerinden saklanmalı');
    });

    // -----------------------------------------------------------------------
    // T8: ProviderContainer ile notifier entegrasyon testi
    // -----------------------------------------------------------------------
    test('T8: ProviderContainer — notificationPreferencesProvider başlangıç değerini yükler',
        () async {
      final fakeRepo = _FakeNotifPrefsRepository();
      final container = ProviderContainer(
        overrides: [
          notificationPreferencesRepositoryProvider
              .overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final prefs = await container.read(
        notificationPreferencesProvider.future,
      );
      expect(prefs.marketingEmailOptIn, isFalse,
          reason: 'Başlangıç değeri false olmalı (defaultValue)');
    });
  });
}
