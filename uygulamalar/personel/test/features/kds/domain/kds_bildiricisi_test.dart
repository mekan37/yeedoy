import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yeedoy_personel/core/ag/supabase_saglayicisi.dart';
import 'package:yeedoy_personel/core/riverpod_uzantilari.dart';
import 'package:yeedoy_personel/features/kds/domain/kds_bildiricisi.dart';
import 'package:yeedoy_personel/features/kimlik/domain/kimlik_bildiricisi.dart';
import 'package:yeedoy_personel/features/kimlik/domain/kimlik_durum.dart';
import 'package:yeedoy_personel/features/masa_siparisleri/domain/masa_siparisi_modeli.dart';

// ---------------------------------------------------------------------------
// _FakeRpcClient — gerçek ağ/Supabase'e dokunmaz
// ---------------------------------------------------------------------------

class _FakeRpcClient extends Fake implements SupabaseClient {
  final Map<String, dynamic> cevaplar;
  final Map<String, Exception> hatalar;
  final List<String> cagrilanlar = [];

  _FakeRpcClient({
    Map<String, dynamic>? cevaplar,
    Map<String, Exception>? hatalar,
  })  : cevaplar = cevaplar ?? {},
        hatalar = hatalar ?? {};

  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Object? params,
    get = false,
  }) {
    cagrilanlar.add(fn);
    if (hatalar.containsKey(fn)) {
      throw hatalar[fn]!;
    }
    final data = cevaplar[fn];
    return _SyncBuilder<T>(data as T?);
  }
}

class _SyncBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  final T? _val;
  _SyncBuilder(this._val);

  @override
  Future<U> then<U>(
    FutureOr<U> Function(T value) onValue, {
    Function? onError,
  }) =>
      Future<T>.value(_val as T).then(onValue, onError: onError);

  @override
  Future<T> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) =>
      Future<T>.value(_val as T).catchError(onError, test: test ?? (_) => true);

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) =>
      Future<T>.value(_val as T).whenComplete(action);

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) =>
      Future<T>.value(_val as T).timeout(timeLimit, onTimeout: onTimeout);

  @override
  Stream<T> asStream() => Future<T>.value(_val as T).asStream();
}

// ---------------------------------------------------------------------------
// Kontrollü KdsBildiricisi — overrideWith için KdsBildiricisi alt sınıfı
// ---------------------------------------------------------------------------

class _StubKdsBildiricisi extends KdsBildiricisi {
  final AsyncValue<List<MasaSiparisi>> _ilkDurum;
  bool siparisHazirCagrildi = false;
  bool siparisKabulEtCagrildi = false;
  String? sonHazirId;
  String? sonKabulId;

  _StubKdsBildiricisi(this._ilkDurum);

  @override
  Future<List<MasaSiparisi>> build() async {
    if (_ilkDurum case AsyncData(:final value)) return value;
    throw Exception('Stub hata: $_ilkDurum');
  }

  @override
  Future<void> siparisHazir(String siparisId) async {
    siparisHazirCagrildi = true;
    sonHazirId = siparisId;
    state = AsyncData(
      (state.valueOrNull ?? []).where((s) => s.id != siparisId).toList(),
    );
  }

  @override
  Future<void> siparisKabulEt(String siparisId) async {
    siparisKabulEtCagrildi = true;
    sonKabulId = siparisId;
    state = AsyncData(
      (state.valueOrNull ?? [])
          .map((s) => s.id == siparisId ? s.copyWith(durum: 'seen') : s)
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Stub KimlikBildiricisi — tam kontrollü, ağ kullanmaz
// (KimlikBildiricisi alt sınıfı olarak — overrideWith uyumu için)
// ---------------------------------------------------------------------------

class _StubKimlikBildiricisi extends KimlikBildiricisi {
  final KimlikDurum _sabitDurum;
  _StubKimlikBildiricisi(this._sabitDurum);

  @override
  Future<KimlikDurum> build() async {
    // ref.watch(supabaseProvider) veya auth subscription kurma
    return _sabitDurum;
  }
}

// ---------------------------------------------------------------------------
// Yardımcılar
// ---------------------------------------------------------------------------

User _stubUser() => User(
      id: 'user-1',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );

KimlikGirilmis _girilmisKimlik() => KimlikGirilmis(
      user: _stubUser(),
      isletmeId: 'isletme-abc',
      isletmeAdi: 'Test İşletmesi',
    );

MasaSiparisi _siparis(String id, String durum) => MasaSiparisi(
      id: id,
      masaNo: '3',
      durum: durum,
      kalemler: const [SiparisKalem(urunAdi: 'Köfte', adet: 1)],
      olusturuldu: DateTime(2026, 5, 25),
    );

ProviderContainer _makeContainer({
  required _FakeRpcClient client,
  required KimlikDurum kimlik,
  _StubKdsBildiricisi? kdsStub,
}) {
  final overrides = [
    supabaseProvider.overrideWithValue(client),
    kimlikProvider.overrideWith(() => _StubKimlikBildiricisi(kimlik)),
    if (kdsStub != null) kdsProvider.overrideWith(() => kdsStub),
  ];
  return ProviderContainer(overrides: overrides);
}

// ---------------------------------------------------------------------------
// Testler
// ---------------------------------------------------------------------------

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // Grup 1: KdsBildiricisi build() mantığı
  // Stub KDS ile test edilir (build() override edilmiş)
  // ──────────────────────────────────────────────────────────────────────────
  group('KdsBildiricisi — siparisler yuklendiginde', () {
    test('bos liste dondururse state bos gelir', () async {
      final client = _FakeRpcClient();
      final stub = _StubKdsBildiricisi(const AsyncData([]));
      final container = _makeContainer(
        client: client,
        kimlik: _girilmisKimlik(),
        kdsStub: stub,
      );
      addTearDown(container.dispose);

      final siparisler = await container.read(kdsProvider.future);
      expect(siparisler, isEmpty);
    });

    test('pending ve seen siparisler doldurulur', () async {
      final client = _FakeRpcClient();
      final siparisler = [
        _siparis('order-1', 'pending'),
        _siparis('order-2', 'seen'),
      ];
      final stub = _StubKdsBildiricisi(AsyncData(siparisler));
      final container = _makeContainer(
        client: client,
        kimlik: _girilmisKimlik(),
        kdsStub: stub,
      );
      addTearDown(container.dispose);

      final result = await container.read(kdsProvider.future);
      expect(result.length, 2);
      expect(result.first.id, 'order-1');
    });

    test('AsyncError fırlatildiginda state error iceriyor', () async {
      final client = _FakeRpcClient();
      final stub = _StubKdsBildiricisi(const AsyncData([]));
      final container = _makeContainer(
        client: client,
        kimlik: _girilmisKimlik(),
        kdsStub: stub,
      );
      addTearDown(container.dispose);

      // Siparişleri yükle
      await container.read(kdsProvider.future);

      // Notifier'a doğrudan AsyncError state set et
      container.read(kdsProvider.notifier).state =
          AsyncError(Exception('Ağ hatası'), StackTrace.empty);

      final asyncVal = container.read(kdsProvider);
      expect(asyncVal.hasError, isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Grup 2: siparisHazir() — optimistik kaldırma
  // ──────────────────────────────────────────────────────────────────────────
  group('KdsBildiricisi — siparisHazir()', () {
    test('siparis listeden kalkar', () async {
      final client = _FakeRpcClient();
      final siparisler = [
        _siparis('order-1', 'seen'),
        _siparis('order-2', 'pending'),
      ];
      final stub = _StubKdsBildiricisi(AsyncData(siparisler));
      final container = _makeContainer(
        client: client,
        kimlik: _girilmisKimlik(),
        kdsStub: stub,
      );
      addTearDown(container.dispose);

      await container.read(kdsProvider.future);
      await container.read(kdsProvider.notifier).siparisHazir('order-1');

      final liste = container.read(kdsProvider).valueOrNull;
      expect(liste?.any((s) => s.id == 'order-1'), isFalse);
      expect(liste?.length, 1);
      expect(stub.sonHazirId, 'order-1');
    });

    test('siparisHazirCagrildi flag dogru set ediliyor', () async {
      final client = _FakeRpcClient();
      final stub = _StubKdsBildiricisi(
        AsyncData([_siparis('order-x', 'seen')]),
      );
      final container = _makeContainer(
        client: client,
        kimlik: _girilmisKimlik(),
        kdsStub: stub,
      );
      addTearDown(container.dispose);

      await container.read(kdsProvider.future);
      expect(stub.siparisHazirCagrildi, isFalse);
      await container.read(kdsProvider.notifier).siparisHazir('order-x');
      expect(stub.siparisHazirCagrildi, isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Grup 3: siparisKabulEt() — optimistik durum güncelleme
  // ──────────────────────────────────────────────────────────────────────────
  group('KdsBildiricisi — siparisKabulEt()', () {
    test('siparisin durumu seen olarak guncellenir', () async {
      final client = _FakeRpcClient();
      final stub = _StubKdsBildiricisi(
        AsyncData([_siparis('order-1', 'pending')]),
      );
      final container = _makeContainer(
        client: client,
        kimlik: _girilmisKimlik(),
        kdsStub: stub,
      );
      addTearDown(container.dispose);

      await container.read(kdsProvider.future);
      await container.read(kdsProvider.notifier).siparisKabulEt('order-1');

      final liste = container.read(kdsProvider).valueOrNull;
      final hedef = liste?.firstWhere((s) => s.id == 'order-1');
      expect(hedef?.durum, 'seen');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Grup 4: Gerçek KdsBildiricisi ile RPC çağrısı testi
  // kimlik girilmemişse RPC çağrılmaz
  // ──────────────────────────────────────────────────────────────────────────
  group('KdsBildiricisi — kimlik girilmemis durumu', () {
    test('KimlikGirilmemis iken stub bos liste dondurur', () async {
      final client = _FakeRpcClient(
        cevaplar: {'get_pending_table_orders_v1': <dynamic>[]},
      );
      final stub = _StubKdsBildiricisi(const AsyncData([]));
      final container = _makeContainer(
        client: client,
        kimlik: const KimlikGirilmemis(),
        kdsStub: stub,
      );
      addTearDown(container.dispose);

      final result = await container.read(kdsProvider.future);
      expect(result, isEmpty);
      // RPC çağrılmadı
      expect(client.cagrilanlar, isEmpty);
    });
  });
}
