# Dokuman Temizlik ve Konsolidasyon Kaydi

## 2026-02-26 ve 2026-02-27 Onceki Kayitlar

Bu tarihlerdeki onceki kayitlar korunmustur; asagida bugunku guncellemeler listelenir.

## 2026-03-04 (Docs Cleanup)

- `docs/release_smoke_checklist.md`
  - Islem: Silindi.
  - Neden: `dagitim.md` ve `operasyon-kilavuzu.md` ile ayni release/smoke akislarini tekrar ediyordu.
  - Yeni hedef: `docs/operasyon-kilavuzu.md`

- `docs/security_env_cleanup_plan.md`
  - Islem: Silindi.
  - Neden: Tek seferlik env hijyeni plani tamamlanmis durumdaydi; ayri belge olarak yasamasi gereksizdi.
  - Yeni hedef: `docs/dagitim.md`

- `docs/cleanup_decision_matrix.md`
  - Islem: Silindi.
  - Neden: Temizlik kararlarinin arsiv kaydi `temizlik-kaydi.md` icinde tutuldugu icin ayri matris dosyasi cift kaynak olusturuyordu.
  - Yeni hedef: `docs/arsiv/gecmis/temizlik-kaydi.md`

- `docs/panel_perf.md`
  - Islem: Guncellendi.
  - Neden: `panel_scale.md` ile tekrar eden runtime/olcek notlari azaltildi.
  - Yeni hedef: `docs/panel_scale.md`

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

- `docs/veri-modeli.md`
  - Islem: Yeniden yazildi.
  - Amac: tablo/RPC setini migration + uygulama sorgularina gore guncellemek.

- `docs/qr-sistemi.md`
  - Islem: Yeniden yazildi.
  - Amac: QR olusturma, redirect ve public render akisini gercek implementasyonla belgelemek.

- `docs/setup.md`
  - Islem: Yeniden yazildi.
  - Amac: calistirma/test gerceklerini ve mevcut env riskini netlestirmek.

- `docs/module_visibility_matrix.md`
  - Islem: Yeniden yazildi.
  - Amac: route bazli gorunurluk + redirect/placeholder durumlarini guncellemek.

- `docs/yol-haritasi.md`, `docs/wip.md`
  - Islem: Yeniden yazildi.
  - Amac: P0/P1/P2 is listesi ve aciklari kod kanitlariyla cikarmak.

- `docs/security_env_cleanup_plan.md`
  - Islem: Guncellendi.
  - Amac: `uygulamalar/web/.env.example` icindeki key regresyonunu acikca kayda almak.

- `docs/cleanup_decision_matrix.md`, `docs/devtools.md`, `docs/dagitim.md`
  - Islem: Guncellendi.
  - Amac: dokumanlar arasi tutarlilik ve encoding temizligi.

Not:
- Bu turda dosya silinmedi; odak dokuman dogrulugu ve konsolidasyonudur.

## 2026-02-27 (P0 Uygulama - Devam)

- `uygulamalar/mobil/lib/l10n/app_en.arb`
  - Islem: Mojibake karakterler duzeltildi.
- `uygulamalar/mobil/lib/l10n/app_tr.arb`
  - Islem: Mojibake karakterler duzeltildi.
- `uygulamalar/mobil/lib/l10n/app_localizations_en.dart`
  - Islem: `flutter gen-l10n` ile yeniden uretildi.
- `uygulamalar/mobil/lib/l10n/app_localizations_tr.dart`
  - Islem: `flutter gen-l10n` ile yeniden uretildi.
- `tools/ceviri-denetimi.mjs`
  - Islem: Mojibake marker kontrolu eklendi.
- `uygulamalar/web/uygulama/(public)/isletme/[slug]/page.tsx`
  - Islem: Public menuye seffaflik ozeti kartlari eklendi (son guncelleme, confidence, 90 gun trend).
- `docs/vision_status.md`, `docs/yol-haritasi.md`, `docs/wip.md`, `docs/security_env_cleanup_plan.md`
  - Islem: P0 durumuna gore guncellendi.

Not:
- `uygulamalar/web/.env.example` dosyasi bu turda kullanici tercihiyle degistirilmedi.

## 2026-02-27 (P1 Baslangic - Panel Web Girisi)

- `uygulamalar/panel_flutter_web/lib/uygulama/yonlendirici.dart`
  - Islem: Web initial route `/` olarak guncellendi; `/isletme-giris` ve `/isletme-kayit` route'lari eklendi.
  - Ek: Panel route'larina auth yoksa business login'e yonlendirme eklendi.
- `uygulamalar/panel_flutter_web/lib/features/marketing/ui/web_home_page.dart`
  - Islem: Panel landing sayfasi eklendi (uygulama tanitimi + store linkleri + Next linki + isletme aksiyonlari).
- `uygulamalar/panel_flutter_web/lib/features/auth/ui/business_login_page.dart`
  - Islem: Isletme giris ekrani eklendi; role'e gore `/owner` veya `/admin` yonlendirmesi eklendi.
- `uygulamalar/panel_flutter_web/lib/features/auth/ui/business_register_page.dart`
  - Islem: Isletme kayit ekrani eklendi.
- `uygulamalar/web/.env.example`
  - Islem: Placeholder formatina cekildi (`your-project`, `your_anon_key`, `your_service_role_key`).
- `docs/vision_status.md`, `docs/yol-haritasi.md`, `docs/wip.md`
  - Islem: P1 durumuna gore guncellendi.

## 2026-02-27 (Bagimlilik Temizligi - Mobile/Panel)

- `uygulamalar/mobil/pubspec.yaml`
  - Islem: Kullanilmayan bagimliliklar kaldirildi (`file_picker`, `pdf`, `qr_flutter`).
- `uygulamalar/mobil/pubspec.lock`
  - Islem: `flutter pub get` sonrasi lock dosyasi guncellendi.
- `uygulamalar/mobil`
  - Dogrulama: `flutter analyze` temiz.
- `uygulamalar/panel_flutter_web`
  - Dogrulama: `flutter analyze` temiz.

## 2026-02-27 (Panel Web Amaç Daraltma - Acil)

- `uygulamalar/panel_flutter_web/lib/uygulama/yonlendirici.dart`
  - Islem: Router panel-web amacina daraltildi.
  - Kaldirilan route gruplari: mobil kesif/en-iyilerluluk/menü paylasim route'lari (`/kesif`, `/akis`, `/favoriler`, `/profil`, `/gelen-kutusu`, `/isletme/*`, `/menu/*`, `/karsilastir`, `/liderler`, vb).
  - Korunan route gruplari: landing (`/`), isletme auth (`/isletme-giris`, `/isletme-kayit`), owner panel (`/owner/*`), admin panel (`/admin/*`), `legal`.
- `uygulamalar/panel_flutter_web/package.json`
  - Islem: Varsayilan `dev` ve `build` target'i `main_web_owner.dart` olacak sekilde guncellendi.
  - Ek: `dev:admin` ve `build:admin` scriptleri eklendi.
- `docs/setup.md`
  - Islem: Panel calistirma bolumu yeni varsayilan akisa gore guncellendi.

## 2026-02-27 (Panel Web Amaç Daraltma - Fiziksel Temizlik)

- `uygulamalar/panel_flutter_web/lib/uygulama_girisi.dart`
  - Islem: Panel reposu icinden mobil entrypoint kaldirildi.
- `uygulamalar/panel_flutter_web/lib/mobil_giris.dart`
  - Islem: Panel reposu icinden mobil bootstrap wrapper kaldirildi.
- `uygulamalar/panel_flutter_web/lib/app_mobile/mobile_app.dart`
  - Islem: Mobil app wrapper kaldirildi.
- `uygulamalar/panel_flutter_web/lib/main_web_order.dart`
  - Islem: Kullanilmayan web-order placeholder entrypoint kaldirildi.
- `uygulamalar/panel_flutter_web/lib/web_order/web_order_app.dart`
  - Islem: Kullanilmayan web-order placeholder app kaldirildi.
- `uygulamalar/panel_flutter_web/lib/web_order/routes/web_order_routes.dart`
  - Islem: Web-order placeholder route sabitleri kaldirildi.
- `uygulamalar/panel_flutter_web/README.md`
  - Islem: Varsayilan calistirma/build hedefleri owner merkezli yeni panele gore guncellendi.
- `docs/apps.md`, `docs/architecture.md`, `docs/module_visibility_matrix.md`, `docs/cleanup_decision_matrix.md`, `docs/wip.md`
  - Islem: Silinen placeholder yapilar ve yeni panel kapsamiyla tutarli hale getirildi.

## 2026-02-27 (Panel Web Kod Ayrimi - Mobil/Kesif Cikarimi)

- `uygulamalar/panel_flutter_web/lib/` altinda, `main_web.dart`, `main_web_owner.dart`, `main_web_admin.dart` import grafina girmeyen 199 adet `.dart` dosya kaldirildi.
  - Islem kapsaminda mobil/kesif/en-iyilerluluk odakli ekranlar ve bagli katmanlar panelden temizlendi.
  - Korunan kapsam: web landing + business auth + owner/admin panel akislari.
- `uygulamalar/panel_flutter_web/test/core/growth/ab_experiments_test.dart`
  - Islem: Silinen quality/growth modullerine bagli oldugu icin kaldirildi.
- `uygulamalar/panel_flutter_web/test/core/quality/golden_paths_test.dart`
  - Islem: Silinen quality modullerine bagli oldugu icin kaldirildi.
- `uygulamalar/panel_flutter_web/test/core/quality/release_gate_test.dart`
  - Islem: Silinen quality modullerine bagli oldugu icin kaldirildi.
- `uygulamalar/panel_flutter_web/tool/release_gate_check.dart`
  - Islem: Silinen quality modullerine bagli oldugu icin kaldirildi.
- Dogrulama:
  - `uygulamalar/panel_flutter_web` icinde `flutter analyze` temiz.

## 2026-02-27 (P2 Tamamlama - Observability ve Artifact Temizligi)

- `uygulamalar/panel_flutter_web/lib/features/admin/ui/admin_observability_page.dart`
  - Islem: Yeni tani ekrani eklendi (request trace + perf SLO + prefs explorer).
- `uygulamalar/panel_flutter_web/lib/uygulama/yonlendirici.dart`
  - Islem: `/admin/observability` route'u eklendi.
- `uygulamalar/panel_flutter_web/lib/features/admin/ui/admin_shell.dart`
  - Islem: Sol menüye `Observability` girdisi eklendi.
- `qr_menu_next/`
  - Islem: Kaldirildi.
  - Gerekce: Sadece artifact (`.next`, `node_modules`), aktif kod baglantisi yok.
- `packages/shared/`
  - Islem: Kaldirildi.
  - Gerekce: Dogrudan import/kullanim izi yok; aktif schema kaynaklari `uygulamalar/web/src/shared/schemas/*` altinda.
- `node/`
  - Islem: Kaldirildi.
  - Gerekce: Sadece tarih damgali build/node_modules/dart_tool artifact klasorleri iceriyordu (`node_modules_20260217_145653`, `build_20260217_145653`, `.dart_tool_20260217_145653`); aktif kod referansi yok.
- Dokuman guncellemeleri:
  - `docs/vision_status.md`
  - `docs/cleanup_decision_matrix.md`
  - `docs/wip.md`
  - `docs/yol-haritasi.md`
  - `docs/apps.md`
  - `docs/module_visibility_matrix.md`

## 2026-02-27 (Cross-Platform Script Konsolidasyonu)

- `tools/calisma-alani-islemleri.mjs`
  - Islem: Yeni eklendi.
  - Icerik: `clean`, `build-owner`, `build-admin`, `build-next`, `build-all` komutlarini Node.js ile merkezi yonetir.
- `package.json` (repo root)
  - Islem: PowerShell tabanli `clean`/`build:*` scriptleri Node helper'a tasindi.
- `docs/setup.md`, `docs/dagitim.md`, `docs/yol-haritasi.md`, `docs/vision_status.md`, `docs/wip.md`
  - Islem: Yeni script davranisina gore guncellendi.

## 2026-02-27 (Domain/ENV Dokumani Tamamlama)

- `docs/dagitim.md`
  - Islem: `Domain ve ENV Sozlesmesi` bolumu eklendi.
  - Kapsam: Panel runtime `.env`, panel `--dart-define`, Next runtime env ve route redirect/domain baglama modeli.
- `docs/wip.md`
  - Islem: `panel_flutter_web` production domain/env dokumani acigi kapatildi.
- `docs/vision_status.md`, `docs/yol-haritasi.md`
  - Islem: Yeni dokuman durumuna gore vizyon ve yol haritasi notlari guncellendi.

## 2026-02-27 (P1 Tamamlama - E2E, Web Seffaflik ve Panel Test Iskeleti)

- `uygulamalar/web/uygulama/(public)/isletme/[slug]/page.tsx`
  - Islem: Public menuye item bazli fiyat gecmisi + son kanit kayitlari paneli eklendi.
- `uygulamalar/web/playwright.config.ts`
  - Islem: Playwright e2e konfigurasyonu eklendi.
- `uygulamalar/web/e2e/auth-and-routing.spec.ts`
  - Islem: Login render ve admin redirect smoke testleri eklendi.
- `uygulamalar/web/package.json`
  - Islem: `test:e2e`, `test:e2e:headed` scriptleri eklendi; `test:unit` komutu dogrudan vitest binary ile calisacak sekilde netlestirildi.
- `package.json` (repo root)
  - Islem: `test:web` ve `test:smoke:web` komutlari, Windows ortaminda daha stabil calismasi icin `cd uygulamalar/web && npm run ...` formatina alindi.
- `uygulamalar/panel_flutter_web/integration_test/app_smoke_test.dart`
  - Islem: Panel icin integration_test iskeleti eklendi.
- `uygulamalar/panel_flutter_web/pubspec.yaml`
  - Islem: Kullanilmayan bagimliliklar kaldirildi; `integration_test` dev dependency olarak eklendi.
- `uygulamalar/panel_flutter_web/package.json`
  - Islem: `test` ve `test:integration` scriptleri eklendi.
- `docs/wip.md`, `docs/vision_status.md`, `docs/yol-haritasi.md`, `docs/setup.md`
  - Islem: Yeni test ve seffaflik durumuna gore dokumanlar guncellendi.

## 2026-02-27 (Panel Integration Test Dogrulama - Windows)

- `uygulamalar/panel_flutter_web/package.json`
  - Islem: `test:integration` komutu `flutter test integration_test -d windows` olarak netlestirildi.
- `uygulamalar/panel_flutter_web/integration_test/app_smoke_test.dart`
  - Dogrulama: Windows cihazda basarili calisti.
- `docs/wip.md`, `docs/setup.md`, `docs/vision_status.md`
  - Islem: Panel integration testinin calisma durumu "eksik"ten "dogrulandi"ya cekildi.

## 2026-03-04 (Docs Scope Hardening)

- `docs/perf.md`
  - Islem: web tarafi performans raporu daha net isimle tasindi.
  - Yeni hedef: `docs/web_next_perf.md`
- `docs/dagitim.md`
  - Islem: belge siniri sertlestirildi; smoke ve incident adimlari bu dosyadan cikarildi.
- `docs/operasyon-kilavuzu.md`
  - Islem: smoke, incident ve release dogrulama kaynagi olarak netlestirildi.
- `docs/panel_scale.md`
  - Islem: cache key ve invalidation ornekleri eklendi.

## 2026-03-09 (Panel Smoke Migration)

- `uygulamalar/panel_flutter_web/e2e/panel-smoke.spec.cjs`
  - Islem: Panel smoke hattı Playwright browser suite'e tasindi.
  - Kapsam: owner shell, owner businesses, owner business submissions, owner menus, owner trash, owner onboarding, owner requests, owner suspended, owner activity, owner growth, owner growth lead submit, owner team, owner price suggestions, admin login redirect, admin search, admin queue, admin reports, admin businesses, admin receipt submissions, admin observability.
  - Aksiyon kapsami: owner commerce links save, owner menus create, owner requests offer sheet, owner team invite, owner price suggestion approve, admin queue assign, admin reports assign, admin observability calibration save.
- `uygulamalar/panel_flutter_web/playwright.config.cjs`
  - Islem: Smoke web-server modeli debug `flutter run` yerine derlenmis web artifact + static server olarak sertlestirildi.
- `uygulamalar/panel_flutter_web/lib/main_web_smoke.dart`
  - Islem: Smoke entrypoint'i `dotenv` + semantics + smoke harness akisina guncellendi.
- `uygulamalar/panel_flutter_web/lib/smoke/panel_smoke_harness.dart`
  - Islem: Fake owner/admin provider override'lari browser smoke icin tek yerde toplandi.
- `uygulamalar/panel_flutter_web/scripts/serve-smoke.cjs`
  - Islem: Flutter web SPA fallback'li static smoke server eklendi.
- `uygulamalar/panel_flutter_web/integration_test/app_smoke_test.dart`
  - Islem: Kaldirildi.
  - Neden: Web panel browser smoke icin `integration_test` yerine Playwright kullanimi standarda alindi.
- `uygulamalar/panel_flutter_web/pubspec.yaml`
  - Islem: `integration_test` dev dependency kaldirildi.
- `docs/test_strategy.md`, `docs/setup.md`, `docs/system_full_documentation.md`, `docs/arsiv/incelemeler/mobil-denetim-raporu.md`
  - Islem: Panel smoke modeli ve kalan riskler yeni browser suite'e gore guncellendi.

## 2026-03-10 (Panel/Web Doc Entry Points)

- `uygulamalar/panel_flutter_web/README.md`
  - Islem: Panel icin ilk app-bazli README eklendi.
  - Kapsam: owner/admin siniri, route omurgasi, QR/public handoff, Playwright smoke ve CI giris bilgileri.
- `uygulamalar/web/README.md`
  - Islem: Public route anlatimi canonical `public_slug` modeliyle hizalandi.
  - Islem: Tek kaynak belge referanslari eklendi.
- `docs/apps.md`, `docs/setup.md`, `docs/system_full_documentation.md`
  - Islem: Panel/web icin app-bazli giris belgeleri referanslandi.
  - Sonuc: 13.10 altindaki panel/web README drift'i kapatildi.

## 2026-03-10 (Panel Browser Smoke Hardening)

- `uygulamalar/panel_flutter_web/e2e/panel-smoke.spec.cjs`
  - Islem: Playwright browser smoke kapsami owner/admin cekirdek route ve secili write/modal akislarini kapsayacak sekilde genisletildi.
  - Kapsam: owner shell, owner businesses, owner business submissions, owner new business submit, owner menus, owner menu editor, owner trash, owner trash restore, owner onboarding, owner requests, owner suspended, owner activity, owner analytics, owner audit alias, owner growth, owner growth lead submit, owner team, owner price suggestions, admin dashboard, admin login redirect, admin search, admin queue, admin reports, admin businesses, admin receipt submissions, admin observability.
  - Aksiyon kapsami: owner commerce links save, owner menus create, owner requests offer sheet, owner team invite, owner price suggestion approve, admin queue assign, admin reports assign, admin observability calibration save.
- `uygulamalar/panel_flutter_web/lib/smoke/panel_smoke_harness.dart`
  - Islem: Yeni owner/admin route'lar ve aksiyonlar icin stateful fake deposu override'lari genisletildi.
- `docs/test_strategy.md`, `docs/system_full_documentation.md`, `docs/arsiv/incelemeler/mobil-denetim-raporu.md`, `uygulamalar/panel_flutter_web/README.md`
  - Islem: Panel browser smoke artik cekirdek release kapisi olarak anlatilacak sekilde guncellendi.
- Dogrulama:
  - `flutter analyze` (`uygulamalar/panel_flutter_web`) temiz.
  - `npm --prefix uygulamalar/panel_flutter_web run test:smoke` basariyla gecti (`30 passed`).


