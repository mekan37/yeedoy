import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google UMP (User Messaging Platform) tabanlı reklam onayı — B12.
///
/// Önceki durum: AdMob başlatılır başlatılmaz reklamlar hiçbir onay
/// kontrolü olmadan yükleniyordu. Bu, EEA/UK gibi bölgelerdeki kullanıcılar
/// için kişiselleştirilmiş reklam öncesi rıza almayı GDPR/KVKK'nın
/// gerektirdiği bir adımı atlıyordu.
///
/// [ensureConsent] uygulama açılışında bir kez çağrılır: kullanıcı EEA/UK
/// dışındaysa ya da onay zaten verilmişse hiçbir UI göstermeden hemen
/// tamamlanır; onay gerekiyorsa UMP'nin kendi native onay formunu gösterir.
/// Reklam yükleyen kod (ör. [NativeAdController]) [waitUntilReady]'yi
/// bekleyip yalnızca `true` dönerse (`canRequestAds()`) reklam isteği
/// göndermelidir — akış hiç tamamlanmasa/hata verse bile reklam
/// yüklenmeyerek güvenli tarafta kalınır (fail-closed, fail-open değil).
class AdsConsentService {
  AdsConsentService._();
  static final AdsConsentService instance = AdsConsentService._();

  Completer<bool>? _readyCompleter;

  /// Onay akışını başlatır (idempotent — birden fazla çağrılırsa aynı
  /// sonucu paylaşır). Uygulama açılışını bloklamaması için fire-and-forget
  /// çağrılmalı; sonucu bekleyen taraf [waitUntilReady] kullanmalı.
  void ensureConsent() {
    if (_readyCompleter != null) return;
    final completer = Completer<bool>();
    _readyCompleter = completer;

    final params = ConsentRequestParameters(
      consentDebugSettings: kDebugMode
          ? ConsentDebugSettings(
              debugGeography: DebugGeography.debugGeographyEea,
            )
          : null,
    );

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
          // formError olsa bile devam et — nihai karar her zaman
          // canRequestAds() ile veriliyor (fail-closed).
          final ok = await ConsentInformation.instance.canRequestAds();
          if (!completer.isCompleted) completer.complete(ok);
        });
      },
      (error) async {
        // Onay bilgisi güncellenemedi (ör. ağ hatası) — SDK'nın önceki
        // oturumdan önbelleklediği son bilinen durumu kullan.
        final ok = await ConsentInformation.instance.canRequestAds();
        if (!completer.isCompleted) completer.complete(ok);
      },
    );
  }

  /// Onay akışı tamamlanana kadar bekler, reklam istenip
  /// istenemeyeceğini döner. [ensureConsent] hiç çağrılmadıysa (beklenmeyen
  /// bir çağrı sırası) `false` döner — reklam isteği göndermez.
  Future<bool> waitUntilReady() {
    final completer = _readyCompleter;
    if (completer == null) return Future.value(false);
    return completer.future;
  }
}
