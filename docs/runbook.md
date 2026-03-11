# Runbook

Tarih: 2026-03-02

Bu dokuman:

- smoke checklist
- incident response
- release gunu dogrulama adimlari

icin source-of-truth'tur.

Env, domain ve deploy modeli icin tek kaynak:

- `docs/deploy.md`

## 0. Release Smoke

### Mobile Flutter

Build:

1. `cd apps/mobile_flutter`
2. `flutter pub get`
3. `flutter analyze`
4. `flutter test`
5. `flutter test integration_test/golden_paths_integration_test.dart`
6. `flutter build apk --release -t lib/main_mobile.dart`

Canli write smoke (opt-in):

1. `flutter test integration_test/live_write_smoke_integration_test.dart --dart-define=RUN_LIVE_WRITE_SMOKE=true --dart-define=LIVE_SUPABASE_URL=https://<project>.supabase.co --dart-define=LIVE_SUPABASE_ANON_KEY=<anon> --dart-define=LIVE_SMOKE_EMAIL=<email> --dart-define=LIVE_SMOKE_PASSWORD=<password> --dart-define=LIVE_SMOKE_BUSINESS_ID=<business_uuid> --dart-define=LIVE_SMOKE_MENU_ITEM_ID=<menu_item_uuid>`

Smoke:

1. Cold start sonrasi onboarding gorunmeli veya daha once tamamlandiysa kesif akisina gecmeli.
2. `/owner*` ve `/admin*` mobile icinde panel handoff yuzeyine gitmeli.
3. Auth gerektiren `/favorites`, `/profile`, `/inbox`, `/group-requests` istekleri login'e dusmeli.
4. `discover -> business -> menu -> item` zinciri kirik olmamali.
5. Review/report/favorites akislarinda kritik write semantigi bozulmamis olmali.
6. QR / deep-link parse akisi mobil route'a veya guvenli fallback'e inmeli.
7. `set_favorite_v2` ve `set_menu_item_price_vote_v2` RPC'leri ilgili ortamda mevcut olmali; legacy fallback ancak gecis amacli kalmali.

Not:

- Mobile release go/no-go icin tek kaynak `docs/mobile_release_checklist.md` dosyasidir.

## 0A. Mobile Offline Queue Recovery

Belirti:

- `/dev-tools` icindeki `Offline Queues` kartinda `Retrying` veya `Blocked until retry` sayisi birikiyor
- `Top retry reasons` tek bir hata etrafinda yigilma gosteriyor
- `Attention items` listesinde ayni write tekrar tekrar bekliyor

Kontrol sirasi:

1. `SocketException`, `timeout`, `failed host lookup`
   - baglanti geri gelmeden manuel flush zorlama
   - connectivity restore veya app resume sonrasi otomatik replay'i bekle
2. `jwt`, `401`, `403`, `auth session`
   - oturumu yenile
   - gerekiyorsa tekrar login ol
   - sonra `Flush verify queue` veya `Flush submission queue`
3. `429`, `rate limit`
   - flush spam yapma
   - `Next retry` alanindaki pencereyi bekle
   - ayni item icin tekrar queue olusup olusmadigini kontrol et
4. `500`, `503`, `service unavailable`
   - backend sagligini kontrol et
   - incident yoksa sonraki backoff penceresini bekle
5. Kalici payload/validation hatalari
   - payload ve RPC kontratini incele
   - runbook disinda manuel queue zorlamasi yapma

Conflict policy:

1. `duplicate`, `already processed`, `same_business_cooldown`, `price_suggestion_same_item_cooldown` benzeri durumlar auto-resolve edilir; item kuyruktan cikar.
2. malformed payload veya kalici validation reddi auto-drop edilir; kullanicidan yeni write gerekir.
3. `offline_mutation_outcome` event'i replay sonucunu `success|retry|resolve|drop` olarak gostermelidir.
4. Panel `/admin/observability` icindeki `Offline mutation outcomes` karti ayni pencere icin disposition ve retry-category dagilimini gostermelidir.
5. Health summary karti paneldeki runtime calibration degerlerini uygulamalidir; varsayilan profil retry warning `>=15%`, retry alarm `>=35%`, drop warning `>=8%`, drop alarm `>=15%`, auth/server hotspot `>=3` seklindedir.
6. Alarm/warning kartinda escalation hedefi (`ops_watch`, `ops_triage`, `auth_session_owner`, `backend_oncall`, `ops_incident`) gorunmelidir.
7. Yeni mobile write yuzeyi eklenirse `tool/offline_write_guard_check.dart` registry'si guncellenmeden merge edilmemelidir.

Beklenen backoff siniflari:

1. `verify vote` network: `15s` baslangic, `15m` cap
2. `price suggestion` network: `30s` baslangic, `30m` cap
3. `submission` network: `1m` baslangic, `45m` cap
4. auth kaynakli retry: `2m-5m` baslangic bandi, aksiyona gore `30m-2h` cap
5. rate-limit kaynakli retry: `10m-20m` baslangic bandi, aksiyona gore `2h-6h` cap
6. server kaynakli retry: `1m-3m` baslangic bandi, aksiyona gore `30m-2h` cap

### Panel Flutter Web

Build:

1. `cd apps/panel_flutter_web`
2. `flutter pub get`
3. `flutter gen-l10n`
4. `flutter analyze`
5. `flutter test`
6. `flutter build web --release --dart-define=DEV_TOOLS_ENABLED=false --target lib/main_web_owner.dart`
7. `flutter build web --release --dart-define=DEV_TOOLS_ENABLED=false --target lib/main_web_admin.dart`

Smoke:

1. Unauthorized `/owner` istegi login ekranina gitmeli.
2. Yetkisiz `/admin/*` istegi `/forbidden` ekranina dusmeli.
3. `/owner`, `/owner/businesses`, `/owner/menus` ekranlarinda secili isletme context bar gorunmeli.
4. `/owner/menus` icinden `Dijital Menu & QR` aksiyonu yeni sekmede acilmali.
5. `/admin/reports` icinde filter, sort, pagination ve bulk actions calismali.
6. `/admin/business-submissions` icinde filter, saved view, pagination ve approve/reject calismali.

### Web Next

Build:

1. `npm --prefix apps/web_next run typecheck`
2. `npm --prefix apps/web_next run lint`
3. `npm --prefix apps/web_next run build`
4. `npm --prefix apps/web_next run test:unit`
5. `npm --prefix apps/web_next run test:e2e`
6. `npm --prefix apps/web_next run test:e2e:live`
7. `npm --prefix apps/web_next run lighthouse:mobile`

Smoke:

1. Owner panelden `QR Menu Olustur` akisi `POST /auth/panel-handoff` uzerinden `/qr/:businessId` sayfasina inmeli.
2. `/m/:publicSlugOrId`, `/m/:publicSlugOrId/c/:categoryId`, `/m/:publicSlugOrId/i/:itemId` dogru veriyle acilmali.
3. `public_slug` mevcutsa legacy `/m/:businessId` istegi canonical slug path'ine redirect etmelidir.
4. `/qr/:businessId` icinde PNG/SVG indirme ve link kopyalama calismali.
5. `/q/:shortCode` final olarak `/m/:publicSlugOrId?src=qr&lang=tr` zincirinde sonlanmali.
6. `/api/track` eventleri sessiz hata vermeden kabul edilmeli.
7. HTML source icinde metadata ve JSON-LD gorunmeli.
8. Rate limit beklentileri:
   - `/api/track` spam isteginde `429`
   - `/qr/*` icin rate limit aktif
   - `/auth/panel-handoff` icin rate limit ve origin kontrolu aktif
9. `robots.txt` ve `sitemap.xml` 200 donmeli.
10. Public menu canonical URL'leri normalize edilmeli; bozuk `lang/theme` parametresi canonical route'a redirect etmelidir.

## 1. Panel -> QR Acilmiyor

Belirti:

- Panelde `Dijital Menu & QR` tiklanir ama `web_next` QR Studio acilmaz.

Kontrol sirasi:

1. `apps/panel_flutter_web` env:
   - `BASE_URL_WEB_NEXT` production host'a ayarli mi?
2. `web_next` env:
   - `NEXT_PUBLIC_SITE_URL`
   - `NEXT_PUBLIC_PANEL_URL`
3. `POST /auth/panel-handoff` response code:
   - `400` -> payload bozuk
   - `401` -> session set edilemedi
4. `redirect` query'si korunuyor mu?
5. `can_manage_business_v1(business_id)` dogru business icin `true` mu?

Log odagi:

- `app/auth/panel-handoff/route.ts`
- panel browser network kaydi

## 2. Upload 403

Belirti:

- `/api/media/upload` `403` doner.

Kontrol sirasi:

1. Kullanici authenticated mi?
2. `can_manage_business_v1(business_id)` sonucu `true` mu?
3. Request body icinde:
   - `businessId`
   - `type`
   - `file`
   alanlari var mi?
4. `SUPABASE_SERVICE_ROLE_KEY` server env'de mevcut mu?

Beklenen hata semantigi:

- no session -> `401`
- yetkisiz business -> `403`
- yanlis mime -> `400`
- 5MB ustu -> `400`

## 3. Analytics `invalid_event`

Belirti:

- `/api/track` response body icinde `{ ok: false, code: "invalid_event" }`

Kontrol sirasi:

1. `src/lib/analytics.ts` event mapping guncel mi?
2. `app/api/track/route.ts` RPC sonucu `{ ok: false }` icin hata uretiyor mu?
3. `log_event_v1` kabul ettigi event seti ile UI event alias'lari uyumlu mu?

Beklenen mapping:

- `page_view` -> `menu_link_opened`
- `category_view` -> `menu_view`
- `item_view` -> `menu_view`
- `item_click` -> `menu_view`
- `qr_scanned` -> `qr_scanned`

## 4. Perf Regression

Belirti:

- `first load JS` tekrar yukselir
- `minimal` Lighthouse Performance 95 altina iner

Kontrol sirasi:

1. `npm --prefix apps/web_next run build`
2. `npm --prefix apps/web_next run build:analyze`
3. `npm --prefix apps/web_next run lighthouse:mobile`

Analyzer odagi:

- `apps/web_next/.next/analyze/client.html`
- `apps/web_next/.next/analyze/nodejs.html`
- `apps/web_next/.next/analyze/edge.html`

En sik kok nedenler:

- Template registry veya schema zincirinin client initial chunk'a geri sizmasi
- Yeni client component'in lazy split olmamasi
- Gereksiz icon veya validation kutuphanesi import'u
- `qrcode` veya upload UI'nin ilk yuklemeye girmesi

## 5. Stale `.next` / Runtime Kacagi

Belirti:

- `/_document`
- `PageNotFoundError`
- `__webpack_modules__[moduleId] is not a function`

Kontrol sirasi:

1. `npm --prefix apps/web_next run build`
2. `apps/web_next/scripts/build.mjs` temiz build wrapper'inin calistigini dogrula
3. Eski artifact veya stale `next start` prosesi kalmadi mi kontrol et

## 6. Preview / Public Apply Sorunu

Belirti:

- QR Studio kayitli ayari gostermiyor
- `preview=1` beklenen template'i acmiyor
- save sonrasi public menu eski gorseli gosteriyor

Kontrol sirasi:

1. `business_menu_presentation_settings` satiri guncellendi mi?
2. `updated_at` degisti mi?
3. Public URL `?v=` cache-bust param'i tasiyor mu?
4. `revalidatePath('/m/:publicSlugOrId')` ve `revalidatePath('/qr/:businessId')` calisti mi?

## 7. Hedef Durum

Beklenen release durumu:

- `/m` first load JS: yaklasik `109 kB`
- `/qr` first load JS: yaklasik `109 kB`
- `minimal` Lighthouse Performance: `99`
- owner save/upload/apply: PASS
- unauthorized upload/settings write: `403`
