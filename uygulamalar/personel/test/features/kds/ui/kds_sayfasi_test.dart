import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:postgrest/postgrest.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yeedoy_personel/core/ag/supabase_saglayicisi.dart';
import 'package:yeedoy_personel/core/riverpod_uzantilari.dart';
import 'package:yeedoy_personel/features/kds/domain/kds_bildiricisi.dart';
import 'package:yeedoy_personel/features/kds/ui/kds_sayfasi.dart';
import 'package:yeedoy_personel/features/kimlik/domain/kimlik_bildiricisi.dart';
import 'package:yeedoy_personel/features/kimlik/domain/kimlik_durum.dart';
import 'package:yeedoy_personel/features/masa_siparisleri/domain/masa_siparisi_modeli.dart';
import 'package:yeedoy_shared_ui_components/yeedoy_shared_ui_components.dart';

// ---------------------------------------------------------------------------
// Fake client
// ---------------------------------------------------------------------------

class _FakeRpcClient extends Fake implements SupabaseClient {
  @override
  PostgrestFilterBuilder<T> rpc<T>(String fn, {Object? params, get = false}) {
    return _SyncBuilder<T>(null);
  }
}

class _SyncBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  final T? _v;
  _SyncBuilder(this._v);

  @override
  Future<U> then<U>(FutureOr<U> Function(T v) f, {Function? onError}) =>
      Future<T>.value(_v as T).then(f, onError: onError);

  @override
  Future<T> catchError(Function f, {bool Function(Object)? test}) =>
      Future<T>.value(_v as T).catchError(f, test: test ?? (_) => true);

  @override
  Future<T> whenComplete(FutureOr<void> Function() f) =>
      Future<T>.value(_v as T).whenComplete(f);

  @override
  Future<T> timeout(Duration t, {FutureOr<T> Function()? onTimeout}) =>
      Future<T>.value(_v as T).timeout(t, onTimeout: onTimeout);

  @override
  Stream<T> asStream() => Future<T>.value(_v as T).asStream();
}

// ---------------------------------------------------------------------------
// Stub KimlikBildiricisi
// ---------------------------------------------------------------------------

class _StubKimlikBildiricisi extends KimlikBildiricisi {
  final KimlikDurum _d;
  _StubKimlikBildiricisi(this._d);

  @override
  Future<KimlikDurum> build() async => _d;
}

// ---------------------------------------------------------------------------
// Stub KdsBildiricisi
// ---------------------------------------------------------------------------

class _StubKdsBildiricisi extends KdsBildiricisi {
  final List<MasaSiparisi> _ilkSiparisler;
  bool siparisHazirCagrildi = false;
  String? sonHazirId;

  _StubKdsBildiricisi(this._ilkSiparisler);

  @override
  Future<List<MasaSiparisi>> build() async => _ilkSiparisler;

  @override
  Future<void> siparisHazir(String id) async {
    siparisHazirCagrildi = true;
    sonHazirId = id;
    state = AsyncData(
      (state.valueOrNull ?? []).where((s) => s.id != id).toList(),
    );
  }

  @override
  Future<void> siparisKabulEt(String id) async {
    state = AsyncData(
      (state.valueOrNull ?? [])
          .map((s) => s.id == id ? s.copyWith(durum: 'seen') : s)
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Yardımcılar
// ---------------------------------------------------------------------------

User _stubUser() => User(
      id: 'u1',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );

KimlikGirilmis _kimlik() => KimlikGirilmis(
      user: _stubUser(),
      isletmeId: 'biz-1',
      isletmeAdi: 'Test İşletmesi',
    );

MasaSiparisi _siparis(String id, String durum) => MasaSiparisi(
      id: id,
      masaNo: '3',
      durum: durum,
      kalemler: const [SiparisKalem(urunAdi: 'Köfte', adet: 1)],
      olusturuldu: DateTime(2026, 5, 25),
    );

ThemeData _theme() => ThemeData(
      extensions: const <ThemeExtension<dynamic>>[
        AppTokens(
          space4: 4,
          space8: 8,
          space12: 12,
          space16: 16,
          space20: 20,
          space24: 24,
          radius12: 12,
          radius16: 16,
          radius20: 20,
          radius24: 24,
          elevation1: 1,
          elevation2: 6,
          elevation3: 12,
          minHitTarget: 44,
          fast: Duration(milliseconds: 150),
          medium: Duration(milliseconds: 180),
          slow: Duration(milliseconds: 220),
        ),
      ],
    );

Future<_StubKdsBildiricisi> _pumpKds(
  WidgetTester tester, {
  List<MasaSiparisi>? siparisler,
}) async {
  // Geniş ekran — yan yana sütun görünümü (>= 600)
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final stub = _StubKdsBildiricisi(siparisler ?? []);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supabaseProvider.overrideWithValue(_FakeRpcClient()),
        kimlikProvider.overrideWith(() => _StubKimlikBildiricisi(_kimlik())),
        kdsProvider.overrideWith(() => stub),
      ],
      child: MaterialApp(theme: _theme(), home: const KdsSayfasi()),
    ),
  );

  // Provider'ların çözülmesi için birkaç frame
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }

  return stub;
}

// ---------------------------------------------------------------------------
// Testler
// ---------------------------------------------------------------------------

void main() {
  group('KdsSayfasi — widget testleri', () {
    testWidgets('bos liste — mutfak temiz mesaji gosteriliyor', (tester) async {
      await _pumpKds(tester, siparisler: []);
      expect(find.text('Mutfak temiz'), findsOneWidget);
    });

    testWidgets('bekleyen siparisler listede goruluyor', (tester) async {
      await _pumpKds(tester, siparisler: [
        _siparis('order-1', 'pending'),
        _siparis('order-2', 'seen'),
      ]);

      // Tablet görünümünde "Yeni Siparişler" başlığı
      expect(find.text('Yeni Siparişler'), findsOneWidget);
      expect(find.text('Hazırlanıyor'), findsWidgets);
    });

    testWidgets('Hazir butonu tiklaninca siparisHazir cagriliyor', (tester) async {
      final stub = await _pumpKds(tester, siparisler: [
        _siparis('order-seen', 'seen'),
      ]);

      // "Hazır" buton metnini bul
      final hazirBtn = find.text('Hazır');
      if (hazirBtn.evaluate().isNotEmpty) {
        await tester.tap(hazirBtn.first);
        await tester.pump();
        expect(stub.siparisHazirCagrildi, isTrue);
        expect(stub.sonHazirId, 'order-seen');
      } else {
        // Scroll ile ara
        await tester.scrollUntilVisible(
          find.text('Hazır'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Hazır').first);
        await tester.pump();
        expect(stub.siparisHazirCagrildi, isTrue);
      }
    });

    testWidgets('hata durumu — Tekrar Dene butonu gosteriliyor', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Doğrudan AsyncError durumu ile başla
      final stub = _StubKdsBildiricisi([]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseProvider.overrideWithValue(_FakeRpcClient()),
            kimlikProvider.overrideWith(() => _StubKimlikBildiricisi(_kimlik())),
            kdsProvider.overrideWith(() => stub),
          ],
          child: MaterialApp(theme: _theme(), home: const KdsSayfasi()),
        ),
      );

      // Provider yüklendi
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }

      // Error state set et
      stub.state = AsyncError(Exception('Ağ hatası'), StackTrace.empty);
      await tester.pump();

      expect(find.text('Tekrar Dene'), findsOneWidget);
    });

    testWidgets('yukleniyor durumu — scaffold render ediliyor', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final completer = Completer<List<MasaSiparisi>>();
      // Asla tamamlanmayacak stub — loading state simüle eder
      final stub = _LoadingKdsBildiricisi(completer.future);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseProvider.overrideWithValue(_FakeRpcClient()),
            kimlikProvider.overrideWith(() => _StubKimlikBildiricisi(_kimlik())),
            kdsProvider.overrideWith(() => stub),
          ],
          child: MaterialApp(theme: _theme(), home: const KdsSayfasi()),
        ),
      );

      await tester.pump();

      // Scaffold render edildi
      expect(find.byType(Scaffold), findsOneWidget);
      // AppBar başlığı var
      expect(find.text('Mutfak Ekranı'), findsOneWidget);

      completer.complete([]);
    });
  });
}

// Asenkron yükleme simüle eden stub
class _LoadingKdsBildiricisi extends KdsBildiricisi {
  final Future<List<MasaSiparisi>> _gelecek;
  _LoadingKdsBildiricisi(this._gelecek);

  @override
  Future<List<MasaSiparisi>> build() => _gelecek;
}
