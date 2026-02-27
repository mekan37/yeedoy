# Dokuman Temizlik ve Konsolidasyon Kaydi

## 2026-02-26 ve 2026-02-27 Onceki Kayitlar

Bu tarihlerdeki onceki kayitlar korunmustur; asagida bugunku guncellemeler listelenir.

## 2026-02-27 (Vizyon Uyumu Turu)

- `docs/vision_status.md`
  - Islem: Yeni olusturuldu.
  - Amac: "Yeedoy vizyonuna ne kadar yakiniz" sorusunu kod kanitlariyla cevaplamak.

- `docs/product.md`
  - Islem: Yeniden yazildi.
  - Amac: Urun tanimini QR menuden daha genis (fiyat seffafligi + topluluk) sekilde, kod tabanina gore netlestirmek.

- `docs/apps.md`
  - Islem: Yeniden yazildi.
  - Amac: 3 app sorumluluklarini ve kismi/placeholder alanlari netlestirmek.

- `docs/architecture.md`
  - Islem: Yeniden yazildi.
  - Amac: istemci-backend yetki akisi + QR akisini tek yerde toplamak.

- `docs/data-model.md`
  - Islem: Yeniden yazildi.
  - Amac: tablo/RPC setini migration + uygulama sorgularina gore guncellemek.

- `docs/qr-system.md`
  - Islem: Yeniden yazildi.
  - Amac: QR olusturma, redirect ve public render akisini gercek implementasyonla belgelemek.

- `docs/setup.md`
  - Islem: Yeniden yazildi.
  - Amac: calistirma/test gerceklerini ve mevcut env riskini netlestirmek.

- `docs/module_visibility_matrix.md`
  - Islem: Yeniden yazildi.
  - Amac: route bazli gorunurluk + redirect/placeholder durumlarini guncellemek.

- `docs/roadmap.md`, `docs/wip.md`
  - Islem: Yeniden yazildi.
  - Amac: P0/P1/P2 is listesi ve aciklari kod kanitlariyla cikarmak.

- `docs/security_env_cleanup_plan.md`
  - Islem: Guncellendi.
  - Amac: `apps/web_next/.env.example` icindeki key regresyonunu acikca kayda almak.

- `docs/cleanup_decision_matrix.md`, `docs/devtools.md`, `docs/deploy.md`
  - Islem: Guncellendi.
  - Amac: dokumanlar arasi tutarlilik ve encoding temizligi.

Not:
- Bu turda dosya silinmedi; odak dokuman dogrulugu ve konsolidasyonudur.

## 2026-02-27 (P0 Uygulama - Devam)

- `apps/mobile_flutter/lib/l10n/app_en.arb`
  - Islem: Mojibake karakterler duzeltildi.
- `apps/mobile_flutter/lib/l10n/app_tr.arb`
  - Islem: Mojibake karakterler duzeltildi.
- `apps/mobile_flutter/lib/l10n/app_localizations_en.dart`
  - Islem: `flutter gen-l10n` ile yeniden uretildi.
- `apps/mobile_flutter/lib/l10n/app_localizations_tr.dart`
  - Islem: `flutter gen-l10n` ile yeniden uretildi.
- `tools/l10n_audit.mjs`
  - Islem: Mojibake marker kontrolu eklendi.
- `apps/web_next/app/(public)/b/[slug]/page.tsx`
  - Islem: Public menuye seffaflik ozeti kartlari eklendi (son guncelleme, confidence, 90 gun trend).
- `docs/vision_status.md`, `docs/roadmap.md`, `docs/wip.md`, `docs/security_env_cleanup_plan.md`
  - Islem: P0 durumuna gore guncellendi.

Not:
- `apps/web_next/.env.example` dosyasi bu turda kullanici tercihiyle degistirilmedi.

## 2026-02-27 (P1 Baslangic - Panel Web Girisi)

- `apps/panel_flutter_web/lib/app/router.dart`
  - Islem: Web initial route `/` olarak guncellendi; `/isletme-giris` ve `/isletme-kayit` route'lari eklendi.
  - Ek: Panel route'larina auth yoksa business login'e yonlendirme eklendi.
- `apps/panel_flutter_web/lib/features/marketing/ui/web_home_page.dart`
  - Islem: Panel landing sayfasi eklendi (uygulama tanitimi + store linkleri + Next linki + isletme aksiyonlari).
- `apps/panel_flutter_web/lib/features/auth/ui/business_login_page.dart`
  - Islem: Isletme giris ekrani eklendi; role'e gore `/owner` veya `/admin` yonlendirmesi eklendi.
- `apps/panel_flutter_web/lib/features/auth/ui/business_register_page.dart`
  - Islem: Isletme kayit ekrani eklendi.
- `apps/web_next/.env.example`
  - Islem: Placeholder formatina cekildi (`your-project`, `your_anon_key`, `your_service_role_key`).
- `docs/vision_status.md`, `docs/roadmap.md`, `docs/wip.md`
  - Islem: P1 durumuna gore guncellendi.

## 2026-02-27 (Bagimlilik Temizligi - Mobile/Panel)

- `apps/mobile_flutter/pubspec.yaml`
  - Islem: Kullanilmayan bagimliliklar kaldirildi (`file_picker`, `pdf`, `qr_flutter`).
- `apps/mobile_flutter/pubspec.lock`
  - Islem: `flutter pub get` sonrasi lock dosyasi guncellendi.
- `apps/mobile_flutter`
  - Dogrulama: `flutter analyze` temiz.
- `apps/panel_flutter_web`
  - Dogrulama: `flutter analyze` temiz.

## 2026-02-27 (Panel Web Amaç Daraltma - Acil)

- `apps/panel_flutter_web/lib/app/router.dart`
  - Islem: Router panel-web amacina daraltildi.
  - Kaldirilan route gruplari: mobil kesif/topluluk/menü paylasim route'lari (`/discover`, `/feed`, `/favorites`, `/profile`, `/inbox`, `/b/*`, `/menu/*`, `/compare`, `/heroes`, vb).
  - Korunan route gruplari: landing (`/`), isletme auth (`/isletme-giris`, `/isletme-kayit`), owner panel (`/owner/*`), admin panel (`/admin/*`), `legal`.
- `apps/panel_flutter_web/package.json`
  - Islem: Varsayilan `dev` ve `build` target'i `main_web_owner.dart` olacak sekilde guncellendi.
  - Ek: `dev:admin` ve `build:admin` scriptleri eklendi.
- `docs/setup.md`
  - Islem: Panel calistirma bolumu yeni varsayilan akisa gore guncellendi.

## 2026-02-27 (Panel Web Amaç Daraltma - Fiziksel Temizlik)

- `apps/panel_flutter_web/lib/main.dart`
  - Islem: Panel reposu icinden mobil entrypoint kaldirildi.
- `apps/panel_flutter_web/lib/main_mobile.dart`
  - Islem: Panel reposu icinden mobil bootstrap wrapper kaldirildi.
- `apps/panel_flutter_web/lib/app_mobile/mobile_app.dart`
  - Islem: Mobil app wrapper kaldirildi.
- `apps/panel_flutter_web/lib/main_web_order.dart`
  - Islem: Kullanilmayan web-order placeholder entrypoint kaldirildi.
- `apps/panel_flutter_web/lib/web_order/web_order_app.dart`
  - Islem: Kullanilmayan web-order placeholder app kaldirildi.
- `apps/panel_flutter_web/lib/web_order/routes/web_order_routes.dart`
  - Islem: Web-order placeholder route sabitleri kaldirildi.
- `apps/panel_flutter_web/README.md`
  - Islem: Varsayilan calistirma/build hedefleri owner merkezli yeni panele gore guncellendi.
- `docs/apps.md`, `docs/architecture.md`, `docs/module_visibility_matrix.md`, `docs/cleanup_decision_matrix.md`, `docs/wip.md`
  - Islem: Silinen placeholder yapilar ve yeni panel kapsamiyla tutarli hale getirildi.

## 2026-02-27 (Panel Web Kod Ayrimi - Mobil/Kesif Cikarimi)

- `apps/panel_flutter_web/lib/` altinda, `main_web.dart`, `main_web_owner.dart`, `main_web_admin.dart` import grafina girmeyen 199 adet `.dart` dosya kaldirildi.
  - Islem kapsaminda mobil/kesif/topluluk odakli ekranlar ve bagli katmanlar panelden temizlendi.
  - Korunan kapsam: web landing + business auth + owner/admin panel akislari.
- `apps/panel_flutter_web/test/core/growth/ab_experiments_test.dart`
  - Islem: Silinen quality/growth modullerine bagli oldugu icin kaldirildi.
- `apps/panel_flutter_web/test/core/quality/golden_paths_test.dart`
  - Islem: Silinen quality modullerine bagli oldugu icin kaldirildi.
- `apps/panel_flutter_web/test/core/quality/release_gate_test.dart`
  - Islem: Silinen quality modullerine bagli oldugu icin kaldirildi.
- `apps/panel_flutter_web/tool/release_gate_check.dart`
  - Islem: Silinen quality modullerine bagli oldugu icin kaldirildi.
- Dogrulama:
  - `apps/panel_flutter_web` icinde `flutter analyze` temiz.

## 2026-02-27 (P2 Tamamlama - Observability ve Artifact Temizligi)

- `apps/panel_flutter_web/lib/features/admin/ui/admin_observability_page.dart`
  - Islem: Yeni tani ekrani eklendi (request trace + perf SLO + prefs explorer).
- `apps/panel_flutter_web/lib/app/router.dart`
  - Islem: `/admin/observability` route'u eklendi.
- `apps/panel_flutter_web/lib/features/admin/ui/admin_shell.dart`
  - Islem: Sol menüye `Observability` girdisi eklendi.
- `qr_menu_next/`
  - Islem: Kaldirildi.
  - Gerekce: Sadece artifact (`.next`, `node_modules`), aktif kod baglantisi yok.
- `packages/shared/`
  - Islem: Kaldirildi.
  - Gerekce: Dogrudan import/kullanim izi yok; aktif schema kaynaklari `apps/web_next/src/shared/schemas/*` altinda.
- `node/`
  - Islem: Kaldirildi.
  - Gerekce: Sadece tarih damgali build/node_modules/dart_tool artifact klasorleri iceriyordu (`node_modules_20260217_145653`, `build_20260217_145653`, `.dart_tool_20260217_145653`); aktif kod referansi yok.
- Dokuman guncellemeleri:
  - `docs/vision_status.md`
  - `docs/cleanup_decision_matrix.md`
  - `docs/wip.md`
  - `docs/roadmap.md`
  - `docs/apps.md`
  - `docs/module_visibility_matrix.md`

## 2026-02-27 (Cross-Platform Script Konsolidasyonu)

- `tools/workspace_ops.mjs`
  - Islem: Yeni eklendi.
  - Icerik: `clean`, `build-owner`, `build-admin`, `build-next`, `build-all` komutlarini Node.js ile merkezi yonetir.
- `package.json` (repo root)
  - Islem: PowerShell tabanli `clean`/`build:*` scriptleri Node helper'a tasindi.
- `docs/setup.md`, `docs/deploy.md`, `docs/roadmap.md`, `docs/vision_status.md`, `docs/wip.md`
  - Islem: Yeni script davranisina gore guncellendi.

## 2026-02-27 (Domain/ENV Dokumani Tamamlama)

- `docs/deploy.md`
  - Islem: `Domain ve ENV Sozlesmesi` bolumu eklendi.
  - Kapsam: Panel runtime `.env`, panel `--dart-define`, Next runtime env ve route redirect/domain baglama modeli.
- `docs/wip.md`
  - Islem: `panel_flutter_web` production domain/env dokumani acigi kapatildi.
- `docs/vision_status.md`, `docs/roadmap.md`
  - Islem: Yeni dokuman durumuna gore vizyon ve yol haritasi notlari guncellendi.

## 2026-02-27 (P1 Tamamlama - E2E, Web Seffaflik ve Panel Test Iskeleti)

- `apps/web_next/app/(public)/b/[slug]/page.tsx`
  - Islem: Public menuye item bazli fiyat gecmisi + son kanit kayitlari paneli eklendi.
- `apps/web_next/playwright.config.ts`
  - Islem: Playwright e2e konfigurasyonu eklendi.
- `apps/web_next/e2e/auth-and-routing.spec.ts`
  - Islem: Login render ve admin redirect smoke testleri eklendi.
- `apps/web_next/package.json`
  - Islem: `test:e2e`, `test:e2e:headed` scriptleri eklendi; `test:unit` komutu dogrudan vitest binary ile calisacak sekilde netlestirildi.
- `apps/panel_flutter_web/integration_test/app_smoke_test.dart`
  - Islem: Panel icin integration_test iskeleti eklendi.
- `apps/panel_flutter_web/pubspec.yaml`
  - Islem: Kullanilmayan bagimliliklar kaldirildi; `integration_test` dev dependency olarak eklendi.
- `apps/panel_flutter_web/package.json`
  - Islem: `test` ve `test:integration` scriptleri eklendi.
- `docs/wip.md`, `docs/vision_status.md`, `docs/roadmap.md`, `docs/setup.md`
  - Islem: Yeni test ve seffaflik durumuna gore dokumanlar guncellendi.
