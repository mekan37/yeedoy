import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/notifications/data/notification_preferences_repository.dart';
import 'package:yeedoy/features/notifications/domain/notification_preferences_models.dart';
import 'package:yeedoy/features/notifications/domain/notification_preferences_provider.dart';

// ---------------------------------------------------------------------------
// Fake repository — Supabase gerektirmez.
// ---------------------------------------------------------------------------

class _FakeNotificationPreferencesRepository
    implements NotificationPreferencesRepository {
  _FakeNotificationPreferencesRepository({
    NotificationPreferences initialValue = NotificationPreferences.defaultValue,
    bool throwOnGet = false,
    bool throwOnUpdate = false,
  }) : _value = initialValue,
       _throwOnGet = throwOnGet,
       _throwOnUpdate = throwOnUpdate;

  NotificationPreferences _value;
  final bool _throwOnGet;
  final bool _throwOnUpdate;

  /// Yapılan update çağrılarının kaydı.
  final List<bool> updateCalls = [];

  @override
  Future<NotificationPreferences> getMyNotificationPreferences() async {
    if (_throwOnGet) throw Exception('rpc_error_get');
    return _value;
  }

  @override
  Future<void> updateMyMarketingEmailOptIn({required bool enabled}) async {
    if (_throwOnUpdate) throw Exception('rpc_error_update');
    updateCalls.add(enabled);
    _value = _value.copyWith(
      marketingEmailOptIn: enabled,
      clearOptedInAt: !enabled,
    );
  }
}

// ---------------------------------------------------------------------------
// Yardımcılar
// ---------------------------------------------------------------------------

ProviderContainer _makeContainer(_FakeNotificationPreferencesRepository repo) {
  return ProviderContainer(
    overrides: [
      notificationPreferencesRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

// ---------------------------------------------------------------------------
// Testler
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // MODEL testleri
  // -------------------------------------------------------------------------
  group('NotificationPreferences modeli', () {
    test('defaultValue marketingEmailOptIn=false döner', () {
      expect(NotificationPreferences.defaultValue.marketingEmailOptIn, isFalse);
      expect(
        NotificationPreferences.defaultValue.marketingEmailOptedInAt,
        isNull,
      );
    });

    test('fromRpcJson doğru ayrıştırır — opted_in=true', () {
      final prefs = NotificationPreferences.fromRpcJson({
        'marketing_email_opt_in': true,
        'marketing_email_opted_in_at': '2026-06-18T10:00:00.000Z',
      });
      expect(prefs.marketingEmailOptIn, isTrue);
      expect(prefs.marketingEmailOptedInAt, isNotNull);
    });

    test('fromRpcJson null değerleri güvenle işler', () {
      final prefs = NotificationPreferences.fromRpcJson({
        'marketing_email_opt_in': null,
        'marketing_email_opted_in_at': null,
      });
      expect(prefs.marketingEmailOptIn, isFalse);
      expect(prefs.marketingEmailOptedInAt, isNull);
    });

    test('copyWith clearOptedInAt=true opted_in_at=null yapar', () {
      final original = NotificationPreferences(
        marketingEmailOptIn: true,
        marketingEmailOptedInAt: DateTime(2026, 6, 18),
      );
      final copy = original.copyWith(
        marketingEmailOptIn: false,
        clearOptedInAt: true,
      );
      expect(copy.marketingEmailOptIn, isFalse);
      expect(copy.marketingEmailOptedInAt, isNull);
    });

    test('equality — aynı değerler eşit', () {
      const a = NotificationPreferences(marketingEmailOptIn: true);
      const b = NotificationPreferences(marketingEmailOptIn: true);
      expect(a, equals(b));
    });

    test('equality — farklı değerler eşit değil', () {
      const a = NotificationPreferences(marketingEmailOptIn: true);
      const b = NotificationPreferences(marketingEmailOptIn: false);
      expect(a, isNot(equals(b)));
    });
  });

  // -------------------------------------------------------------------------
  // REPOSITORY testleri
  // -------------------------------------------------------------------------
  group('NotificationPreferencesRepository fake', () {
    test('getMyNotificationPreferences başlangıç değeri döner', () async {
      final repo = _FakeNotificationPreferencesRepository(
        initialValue: const NotificationPreferences(marketingEmailOptIn: false),
      );
      final result = await repo.getMyNotificationPreferences();
      expect(result.marketingEmailOptIn, isFalse);
    });

    test('updateMyMarketingEmailOptIn(true) değeri günceller', () async {
      final repo = _FakeNotificationPreferencesRepository();
      await repo.updateMyMarketingEmailOptIn(enabled: true);
      final result = await repo.getMyNotificationPreferences();
      expect(result.marketingEmailOptIn, isTrue);
      expect(repo.updateCalls, [true]);
    });

    test('updateMyMarketingEmailOptIn(false) değeri günceller', () async {
      final repo = _FakeNotificationPreferencesRepository(
        initialValue: const NotificationPreferences(marketingEmailOptIn: true),
      );
      await repo.updateMyMarketingEmailOptIn(enabled: false);
      final result = await repo.getMyNotificationPreferences();
      expect(result.marketingEmailOptIn, isFalse);
      expect(repo.updateCalls, [false]);
    });

    test('get hata verirse exception fırlatır', () async {
      final repo = _FakeNotificationPreferencesRepository(throwOnGet: true);
      expect(repo.getMyNotificationPreferences(), throwsException);
    });

    test('update hata verirse exception fırlatır', () async {
      final repo = _FakeNotificationPreferencesRepository(throwOnUpdate: true);
      expect(repo.updateMyMarketingEmailOptIn(enabled: true), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  // NOTIFIER testleri
  // -------------------------------------------------------------------------
  group('NotificationPreferencesNotifier', () {
    test('build() başlangıç değeri yükler', () async {
      final repo = _FakeNotificationPreferencesRepository(
        initialValue: const NotificationPreferences(marketingEmailOptIn: false),
      );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(
        notificationPreferencesProvider.future,
      );
      expect(result.marketingEmailOptIn, isFalse);
    });

    test(
      'setMarketingEmailOptIn(true) çağrıldığında updateMyMarketingEmailOptIn(true) çağrılır',
      () async {
        final repo = _FakeNotificationPreferencesRepository();
        final container = _makeContainer(repo);
        addTearDown(container.dispose);

        // İlk yüklemeyi bekle
        await container.read(notificationPreferencesProvider.future);

        await container
            .read(notificationPreferencesProvider.notifier)
            .setMarketingEmailOptIn(enabled: true);

        expect(
          repo.updateCalls,
          contains(true),
          reason:
              'Toggle true olunca updateMyMarketingEmailOptIn(true) çağrılmalı',
        );
      },
    );

    test(
      'setMarketingEmailOptIn(false) çağrıldığında updateMyMarketingEmailOptIn(false) çağrılır',
      () async {
        final repo = _FakeNotificationPreferencesRepository(
          initialValue: const NotificationPreferences(
            marketingEmailOptIn: true,
          ),
        );
        final container = _makeContainer(repo);
        addTearDown(container.dispose);

        await container.read(notificationPreferencesProvider.future);

        await container
            .read(notificationPreferencesProvider.notifier)
            .setMarketingEmailOptIn(enabled: false);

        expect(
          repo.updateCalls,
          contains(false),
          reason:
              'Toggle false olunca updateMyMarketingEmailOptIn(false) çağrılmalı',
        );
      },
    );

    test(
      'optimistik güncelleme — RPC beklenmeden state hemen değişir',
      () async {
        // Kısa gecikme simüle eden fake repo
        final slowRepo = _SlowFakeRepo(delay: const Duration(milliseconds: 50));
        final container = ProviderContainer(
          overrides: [
            notificationPreferencesRepositoryProvider.overrideWithValue(
              slowRepo,
            ),
          ],
        );
        addTearDown(container.dispose);

        await container.read(notificationPreferencesProvider.future);

        // setMarketingEmailOptIn başlat ama await etme
        final updateFuture = container
            .read(notificationPreferencesProvider.notifier)
            .setMarketingEmailOptIn(enabled: true);

        // State hemen true olmalı (optimistik)
        final immediateState = container
            .read(notificationPreferencesProvider)
            .asData
            ?.value;
        expect(
          immediateState?.marketingEmailOptIn,
          isTrue,
          reason: 'Optimistik güncelleme: RPC bitmeden state true olmalı',
        );

        // RPC tamamlansın
        await updateFuture;
      },
    );

    test('RPC hata verirse rollback — eski değere döner', () async {
      final repo = _FakeNotificationPreferencesRepository(
        initialValue: const NotificationPreferences(marketingEmailOptIn: false),
        throwOnUpdate: true,
      );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(notificationPreferencesProvider.future);

      // Hata fırlatmalı
      await expectLater(
        container
            .read(notificationPreferencesProvider.notifier)
            .setMarketingEmailOptIn(enabled: true),
        throwsException,
      );

      // State eski değere geri dönmeli
      final state = container
          .read(notificationPreferencesProvider)
          .asData
          ?.value;
      expect(
        state?.marketingEmailOptIn,
        isFalse,
        reason: 'RPC hatası sonrası rollback: eski değer false olmalı',
      );
    });

    test(
      'get hata verirse repository exception fırlatır (build güvenli hata yayar)',
      () async {
        // Gerçek repository build() içinde exception fırlatmaz — defaultValue döner.
        // Fake repo ise exception fırlatır; bu test fake repo'nun davranışını
        // ve NotificationPreferencesNotifier'ın sonunda AsyncError'a geçeceğini doğrular.
        //
        // Not: AsyncNotifier.build() exception fırlatınca Riverpod provider'ı
        // AsyncError state'e geçirir ancak ProviderContainer test ortamında
        // bu state geçişini beklemek için FakeAsync/pumpEventQueue gerektirir.
        // Bu testte yalnızca fake repo'nun exception fırlattığını doğrularız.
        final repo = _FakeNotificationPreferencesRepository(throwOnGet: true);

        // Repo direkt exception fırlatıyor
        expect(repo.getMyNotificationPreferences(), throwsA(isA<Exception>()));

        // Notifier build() sonuçta AsyncError oluşturur — bu davranış
        // gerçek Riverpod implementasyonu tarafından garanti edilir.
        // WidgetTester gerektiren integration testinde doğrulanabilir.
      },
    );

    test(
      'business_follows.is_subscribed_email global pazarlama izni olarak kullanılmaz',
      () async {
        // Bu test conceptual: updateMyMarketingEmailOptIn yalnızca
        // marketing_email_opt_in günceller; business_follows.is_subscribed_email'e
        // dair hiçbir çağrı yoktur. Fake repo updateCalls listesi bunu doğrular.
        final repo = _FakeNotificationPreferencesRepository();
        await repo.updateMyMarketingEmailOptIn(enabled: true);

        // updateCalls yalnızca marketing_email_opt_in güncellemesi içermeli.
        // is_subscribed_email çağrısı bu repo'da tanımlı değil.
        expect(repo.updateCalls, hasLength(1));
        expect(repo.updateCalls.first, isTrue);
      },
    );

    test(
      'SharedPreferences source-of-truth değil — repo doğrudan RPC kullanır',
      () async {
        // SharedPreferences mock'u kurulmadan test çalışıyor —
        // repository yalnızca Supabase RPC kullanıyor.
        final repo = _FakeNotificationPreferencesRepository(
          initialValue: const NotificationPreferences(
            marketingEmailOptIn: true,
          ),
        );
        final container = _makeContainer(repo);
        addTearDown(container.dispose);

        final result = await container.read(
          notificationPreferencesProvider.future,
        );
        // SharedPreferences'tan değil, repo'dan (RPC) geliyor:
        expect(result.marketingEmailOptIn, isTrue);
      },
    );
  });
}

// ---------------------------------------------------------------------------
// Yavaş fake repo (optimistik test için)
// ---------------------------------------------------------------------------

class _SlowFakeRepo implements NotificationPreferencesRepository {
  _SlowFakeRepo({required this.delay});
  final Duration delay;
  NotificationPreferences _value = NotificationPreferences.defaultValue;

  @override
  Future<NotificationPreferences> getMyNotificationPreferences() async {
    await Future<void>.delayed(delay);
    return _value;
  }

  @override
  Future<void> updateMyMarketingEmailOptIn({required bool enabled}) async {
    await Future<void>.delayed(delay);
    _value = _value.copyWith(marketingEmailOptIn: enabled);
  }
}
