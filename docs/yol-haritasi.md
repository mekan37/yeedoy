# Yol Haritasi (Onceliklendirilmis)

Bu liste koddan gorulen aktif aciklara dayanir.

## Tamamlananlar

Tamamlanan turlerin ayrintili tarihsel kaydi bu dosyada tutulmaz. Release ve kapanis snapshot'lari icin:

- `docs/arsiv/gecmis/surum-indeksi.md`

Bu dosya yalnizca acik ve siradaki islere odaklanir.

## P1 (Kisa Vade)

1. ~~Eski devir/env izlerini temizle~~ — Tamamlandi (2026-06-01). `panel-adresi-denetimi.mjs` zaten NEXT_PUBLIC_PANEL_URL yoksa sessizce gecisiyor; CI'da referans yok.
2. ~~Eski panel devir rotasini kullanan Lighthouse/live-smoke helper'larini guncelle~~ — Tamamlandi. `web_release_smoke.yml` eski panel URL akisini kullanmiyor.

## P2 (Orta Vade)

1. ~~Canonical slug smoke ve legacy UUID redirect health-check'ini release pipeline'a zorunlu hale getir~~ — Tamamlandi.
2. Owner/admin analytics raporlarinda filtre state'ini URL'e yazma standardini tamamla.
3. ~~Public menu icin cache invalidation stratejisini deployment pipeline ile standardize et~~ — Tamamlandi.

## Guncel Aciklar

1. Web Next e2e kapsami owner/admin write smoke'lari icin genisletilmeli.
2. Queue ve batch moderation UI derinligi dusuk etkili borc olarak duruyor.
3. Admin/owner analytics permalink standardi tum rapor ekranlarinda ayni degil.

## Kalan Acik Isler

### iOS / Android Release Hazirlik (mobil-ci-ios-hazirlik.md)

**Not:** KVKK consent akisi (8. madde) 2026-06-01 tamamlandi.

1. `GoogleService-Info.plist` yonetimi netlesmeli — repo disi CI secret/artifact mi yoksa FlutterFire options-only mod mu?
2. GitHub iOS secretlari girilmeli: `IOS_APPLE_TEAM_ID`, `IOS_DISTRIBUTION_CERTIFICATE_P12_BASE64`, `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD`, `IOS_PROVISIONING_PROFILE_BASE64`
3. `ios_release_dry_run` job'u gercek Apple signing assetleri ile calistirilmali — IPA artifact kaniti alinmali
4. Gercek iOS cihazda deep-link ve push-tap smoke yapilmali
5. GitHub Android secretlari girilmeli: `ANDROID_RELEASE_KEYSTORE_BASE64`, `ANDROID_RELEASE_STORE_PASSWORD`, `ANDROID_RELEASE_KEY_ALIAS`, `ANDROID_RELEASE_KEY_PASSWORD`
6. TestFlight upload / dagitim adimi ayri workflow veya operator runbook'u ile tanimlanmali

### Urun Hazirlik Notlari

7. `assets/brand` klasorune production logo, lockup ve export varyantlari eklenmeli
8. ~~`lib/core/privacy` klasorune KVKK/GDPR policy helper'lari, consent state ve data deletion workflow'lari yazilmali~~ — Tamamlandi (2026-06-01). `ConsentState`, `ConsentRepository`, `ConsentNotifier`, `showConsentBottomSheet`, `ConsentGuard` implement edildi; `SplashPage` ve `OnboardingPage` entegre edildi.

### Dusuk Oncelik

9. `packages/ui_tokens` paketi: web Next tarafinda artik birincil kaynak degil — amac netlesmeli veya arsivlenmeli
10. Batch moderation UI: RPC izi var (`admin_bulk_decide_v1` veya benzeri), tam UI yok
11. Analytics event metadata kalitesi: write aninda zorunlu metadata setini sertlestir
12. Analytics permalink: filtre durumunu paylasilabilir URL'e baglayan ozellik

## Son Notlar

- `uygulamalar/web` public menu `?theme=minimal|bold|elegant` destekler.
- `/kod/[code]` edge route handler olarak calisir ve redirect hazirlama suresini loglar.
- Semantik public route `/m/[publicSlugOrId]` olup canonical hedef `public_slug` tercih eder.
- Public menu item kartlari, sticky category bar ve detail sheet motion/refinement turu tamamlanmistir.
- SEO altyapisi (schema, sitemap, hub sayfalar, OG image) 2026-06-01 tamamlandi.
- Sponsorluk Vitrin paketi (490 TL/ay) remote DB'ye eklendi, owner panel aktif (2026-06-01).
- Fiyat Endeksi public sayfa + CSV API: `/fiyat-endeksi` ve `/sunucu/fiyat-endeksi-raporu` (2026-06-01).
- Growth Loop MVPs web+mobil: WhatsApp paylaşım butonları, QR CTA, rozet paylaşımı (2026-06-01).

## Referans

- tarihsel release kayitlari: `docs/arsiv/gecmis/surum-indeksi.md`
