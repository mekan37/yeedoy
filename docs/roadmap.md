# Yol Haritasi (Onceliklendirilmis)

Bu liste koddan gorulen aktif aciklara dayanir.

## Tamamlananlar

Tamamlanan turlerin ayrintili tarihsel kaydi bu dosyada tutulmaz. Release ve kapanis snapshot'lari icin:

- `docs/archive/history/release_index.md`

Bu dosya yalnizca acik ve siradaki islere odaklanir.

## P1 (Kisa Vade)

1. ~~Panel login -> Next login geri donus UX'ini tek adima indir~~ — Tamamlandi. `owner_businesses_page.dart` ve `admin_businesses_page.dart` icindeki `submitPostRedirect` cagrisi `target: '_blank'` aldı; QR Studio yeni sekmede acilir, panel sekmesi yerinde kalir. `owner_menus_page.dart` zaten duzelmisti.
2. ~~QR yetki hatalarinda daha acik owner/admin mesajlari ekle~~ — Tamamlandi. `app/forbidden/route.ts` 403 HTML sayfasi mevcuttu; "This business can only be opened by its owner or an admin account with management access." mesajini iceriyor. Mesajlar su an yalnizca Ingilizcedir; Turkce destek eklenirse bu madde tekrar acilabilir.
3. ~~Gercek production business verileriyle smoke testi release checklist'ine gore per-release uygula~~ — Tamamlandi. `.github/workflows/web_release_smoke.yml` eklendi; `workflow_dispatch` ile production Supabase karşısında `npm run test:e2e:live` kosturuyor. Calistirmak icin gerekli GitHub secretlari: `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `NEXT_PUBLIC_SITE_URL`, `NEXT_PUBLIC_PANEL_URL`, `PLAYWRIGHT_SMOKE_BUSINESS_ID`.

## P2 (Orta Vade)

1. ~~Canonical slug smoke ve legacy UUID redirect health-check'ini release pipeline'a zorunlu hale getir~~ — Tamamlandi. `m/[slug]/page.tsx` icindeki `hasLegacyBusinessPath` UUID → canonical slug redirect'ini uygular; `public-menu-live.spec.ts` bunu canli veriyle test eder; `web_release_smoke.yml` per-release otomatik olarak calistirir.
2. ~~Analytics eventlerini panelde okunabilir hale getiren hafif raporlama ekrani olustur~~ — Tamamlandi. `admin_growth_page.dart` `/admin/growth` route'unda mevcuttu; DAU/WAU, QR scan, menu view, price suggestion ve discovery metriklerini gosteriyor. Admin shell navigasyonuna bagli.
3. ~~Public menu icin cache invalidation stratejisini deployment pipeline ile standardize et~~ — Tamamlandi. `POST /api/revalidate` route'u mevcut; `appConfig.revalidateSecret()` eksik metodundan kaynaklanan TypeScript hatasi duzeltildi, `REVALIDATE_SECRET` `.env.example`'a eklendi, `deploy.md` icine ornek curl komutu ve deployment pipeline entegrasyon talimati yazildi.

## Guncel Aciklar

1. ~~Panel login'den Next QR sayfasina donus hala handoff aksiyonu ile oluyor; tek adimli otomatik geri donus UX'i yok.~~ — Kapatildi (yeni sekme acilisi).
2. ~~`NEXT_PUBLIC_PANEL_URL` yanlis set edilirse login geri donus CTA'si hatali domaine bakabilir.~~ — `validate-panel-url.mjs` release smoke oncesinde bunu yakalar ve `web_release_smoke.yml`'e entegre edildi.
3. ~~Web Next e2e kapsami eksik.~~ — `public-menu.spec.ts`'e bilinmeyen slug 404, gecersiz external redirect fallback ve valid internal redirect korunmasi testleri eklendi. Auth guard testi (QR redirect → login) canli data gerektirdiginden live smoke kapsaminda kalmaktadir.
4. ~~Panel browser smoke minimal.~~ — `panel-smoke.spec.cjs`'e 7 eksik admin route eklendi: `admin/business-submissions`, `admin/price-suggestions`, `admin/claims`, `admin/group-requests`, `admin/b2b-exports`, `admin/monetization`, `admin/growth`. Toplam test sayisi 32 → 39.
5. ~~Admin liste ekranlarinda virtual table ve pagination standardi ilerledi; ana acik artik buyuk olcude `queue` tarafinda.~~ — Queue sayfasinda `_page` / `_totalCount` / `_rowsPerPage` tabanli server-side pagination mevcut. Kalan borcun tumu dusuk etkilidir.

## Kalan Acik Isler

### iOS / Android Release Hazirlik (mobile_ci_ios_readiness.md)

1. `GoogleService-Info.plist` yonetimi netlesmeli — repo disi CI secret/artifact mi yoksa FlutterFire options-only mod mu?
2. GitHub iOS secretlari girilmeli: `IOS_APPLE_TEAM_ID`, `IOS_DISTRIBUTION_CERTIFICATE_P12_BASE64`, `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD`, `IOS_PROVISIONING_PROFILE_BASE64`
3. `ios_release_dry_run` job'u gercek Apple signing assetleri ile calistirilmali — IPA artifact kaniti alinmali
4. Gercek iOS cihazda deep-link ve push-tap smoke yapilmali
5. GitHub Android secretlari girilmeli: `ANDROID_RELEASE_KEYSTORE_BASE64`, `ANDROID_RELEASE_STORE_PASSWORD`, `ANDROID_RELEASE_KEY_ALIAS`, `ANDROID_RELEASE_KEY_PASSWORD`
6. TestFlight upload / dagitim adimi ayri workflow veya operator runbook'u ile tanimlanmali

### Panel Placeholder'lar (panel_placeholders.md)

7. `assets/brand` klasorune production logo, lockup ve export varyantlari eklenmeli
8. `lib/core/privacy` klasorune KVKK/GDPR policy helper'lari, consent state ve data deletion workflow'lari yazilmali

### Dusuk Oncelik

9. `packages/ui_tokens` paketi: web Next tarafinda artik birincil kaynak degil — amac netlesmeli veya arsivlenmeli
10. Batch moderation UI: RPC izi var (`admin_bulk_decide_v1` veya benzeri), tam UI yok
11. Analytics event metadata kalitesi: write aninda zorunlu metadata setini sertlestir
12. Analytics permalink: filtre durumunu paylasilabilir URL'e baglayan ozellik

## Son Notlar

- `apps/web_next` public menu `?theme=minimal|bold|elegant` destekler.
- `/q/[code]` edge route handler olarak calisir ve redirect hazirlama suresini loglar.
- Semantik public route `/m/[publicSlugOrId]` olup canonical hedef `public_slug` tercih eder; mevcut App Router klasor yolu `apps/web_next/app/(public)/m/[slug]/...` seklindedir.
- Public menu item kartlari, sticky category bar ve detail sheet motion/refinement turu tamamlanmistir.

## Referans

- mevcut durum ve kod kaniti: `docs/vision_status.md`
- tarihsel release kayitlari: `docs/archive/history/release_index.md`
