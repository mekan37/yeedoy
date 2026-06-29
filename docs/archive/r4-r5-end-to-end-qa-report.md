# R-4 / R-5 Uçtan Uca QA Doğrulama Raporu

Tarih: 2026-06-18  
Kapsam: R-4 IP metadata minimizasyonu ve R-5 pazarlama e-posta opt-in / unsubscribe teknik akışları  
Yöntem: Önceki legal/uygulama raporları okundu, istenen migration/Flutter/Web/Edge dosyaları statik olarak doğrulandı, production'a bağlanılmadı.

Bu rapor hukuki metin değildir. KVKK/Gizlilik/Kullanım Şartları final metni yazılmamıştır.

## Doğrulanan kapsam

Okunan raporlar:

- `docs/legal/legal-data-inventory.md`
- `docs/legal/legal-preflight-report.md`
- `docs/legal/critical-privacy-gaps-report.md`
- `docs/legal/r4-ip-metadata-decision-plan.md`
- `docs/legal/r4-ip-metadata-implementation-report.md`
- `docs/legal/r4-ip-metadata-verification-report.md`
- `docs/legal/r5-marketing-optin-data-model-decision.md`
- `docs/legal/r5-marketing-optin-db-implementation-report.md`
- `docs/legal/r5-marketing-optin-db-verification-report.md`
- `docs/legal/r5-unsubscribe-web-edge-decision-plan.md`
- `docs/legal/r5-unsubscribe-web-edge-implementation-report.md`
- `docs/legal/r5-unsubscribe-security-verification-report.md`
- `docs/legal/r5-email-filter-token-hardening-report.md`
- `docs/legal/r5-flutter-marketing-optin-implementation-report.md`

Doğrulanan teknik dosyalar:

- `supabase/migrations/20260619000001_remove_ip_metadata_from_policy_acceptances.sql`
- `supabase/migrations/20260620000001_user_profiles_marketing_email_opt_in.sql`
- `supabase/migrations/20260620000002_r5_marketing_email_rpcs.sql`
- `uygulamalar/mobil/lib/features/legal/ui/legal_acceptance_page.dart`
- `uygulamalar/mobil/lib/features/notifications/ui/notification_preferences_page.dart`
- `uygulamalar/mobil/lib/features/notifications/data/notification_preferences_repository.dart`
- `uygulamalar/mobil/lib/features/notifications/domain/notification_preferences_models.dart`
- `uygulamalar/mobil/lib/features/notifications/domain/notification_preferences_provider.dart`
- `uygulamalar/web/src/lib/email/unsubscribe-token.ts`
- `uygulamalar/web/src/lib/email/get-opted-in-emails.ts`
- `uygulamalar/web/src/lib/email/resend-client.ts`
- `uygulamalar/web/app/(genel)/abonelik-iptal/page.tsx`
- `uygulamalar/web/app/(kimlik)/bildirim-ayarlari/page.tsx`
- `uygulamalar/web/app/(kimlik)/bildirim-ayarlari/pazarlama-email-toggle.tsx`
- `uygulamalar/web/app/sunucu/sahip/eposta-kampanya/route.ts`
- `supabase/functions/send-email-campaign/index.ts`

## R-4 QA sonucu

Sonuç: Statik QA geçti. Production/local dinamik DB doğrulaması bekliyor.

- `capture_request_metadata_v1()` yeniden tanımlanmış ve yürütülen fonksiyon gövdesinde `request_ip_v1()`, `request_header_v1()`, `ip_address` veya `user_agent` otomatik doldurma bloğu kalmamış.
- `user_id`, `accepted_at`, `submitted_at`, `requested_at` doldurma mantığı korunmuş.
- `user_policy_acceptances` ve `business_policy_acceptances` için mevcut `ip_address` / `user_agent` değerleri `UPDATE ... SET ... = NULL` ile temizleniyor.
- Sütunlar `DROP COLUMN` ile kaldırılmamış; nullable bırakılmış.
- `privacy_requests` ve `account_deletion_requests` migration tarafından güncellenmiyor. Önceki R-4 karar raporundaki düzeltmeye göre bu tablolarda IP/UA sütunu zaten yok.
- `request_ip_v1()` ve `request_header_v1()` silinmemiş. `admin_audit_log` ve `capture_request_meta_v1()` akışı migration tarafından hedeflenmiyor.
- RLS, view, index veya audit policy değişikliği yok.

R-4 kalan üretim öncesi koşullar:

- `20260619000001` production'a uygulanmadan önce baseline sayıları alınmalı.
- Migration uygulandıktan sonra policy acceptance tablolarında dolu IP/UA kalmadığı doğrulanmalı.
- `capture_request_metadata_v1()` fonksiyon gövdesinde IP/UA kodu kalmadığı DB üzerinden doğrulanmalı.
- `admin_audit_log` akışı ayrıca manuel smoke test edilmeli.
- Hukukçu, IP'siz kabul ispatının yeterliliğini onaylamalı.

## R-5 DB/RPC QA sonucu

Sonuç: Statik QA geçti. Production/local dinamik DB doğrulaması bekliyor.

- `user_profiles.marketing_email_opt_in boolean NOT NULL DEFAULT false` olarak eklenmiş. Mevcut kullanıcılar otomatik opt-in yapılmıyor.
- `user_profiles.marketing_email_opted_in_at timestamptz NULL` olarak eklenmiş.
- `update_my_marketing_email_opt_in_v1(true)` global izni `true`, `marketing_email_opted_in_at = now()` ve `updated_at = now()` yapıyor.
- `update_my_marketing_email_opt_in_v1(false)` global izni `false`, `marketing_email_opted_in_at = NULL` ve `updated_at = now()` yapıyor.
- `get_my_notification_preferences_v1()` yalnızca çağıran kullanıcının `user_profiles` kaydını okuyor; kayıt yoksa `false/null` dönüyor.
- `update_business_follow_email_subscription_v1()` yalnızca `business_follows.is_subscribed_email` alanını, `auth.uid()` kullanıcısının kendi takip satırında güncelliyor.
- `update_business_follow_email_subscription_v1()` `user_profiles.marketing_email_opt_in` alanına dokunmuyor.
- `business_follows_update_own` UPDATE RLS policy eklenmiş: `USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid())`.
- Başka kullanıcının izinlerini değiştirmeyi engelleyen iki katman var: RLS policy ve RPC içinde `WHERE user_id = v_uid`.

Not edilen DB/RPC riski:

- `marketing_email_opted_in_at` opt-out sırasında `NULL` oluyor. Son opt-in zamanı tutuluyor, opt-out geçmişi ayrı bir audit log olarak tutulmuyor. Hukukçu bunun ispat yükümlülüğü için yeterli olup olmadığını değerlendirmeli.
- `profiles_read USING(true)` mevcutsa `marketing_email_opt_in` alanı public profil okuması kapsamında görünebilir. Bu sprint kapsamı dışında bırakılmış düşük/orta gizlilik riski olarak takip edilmeli.

## R-5 Flutter QA sonucu

Sonuç: Kod ve canlı hedef testler geçti.

- `legal_acceptance_page.dart` içinde `_marketingOptIn == true` ise `NotificationPreferencesRepository.updateMyMarketingEmailOptIn(enabled: true)` çağrılıyor.
- `_marketingOptIn == false` ise RPC çağrılmıyor; backend default `false` korunuyor.
- Zorunlu yasal kabul `acceptPolicyVersions()` başarısız olursa akış ilerlemiyor.
- Pazarlama RPC hatası `_saveMarketingOptIn()` içinde yakalanıyor, SnackBar gösteriliyor ve zorunlu yasal kabul akışı haksız yere bozulmuyor.
- `notification_preferences_page.dart` backend state'i `notificationPreferencesProvider` üzerinden okuyor.
- Toggle true/false değerleri `update_my_marketing_email_opt_in_v1` RPC'sine yazılıyor.
- Hata durumunda optimistic state rollback yapılıyor ve UI SnackBar ile kullanıcıya bilgi veriyor.
- `SharedPreferences` pazarlama e-posta izni için source-of-truth değil.
- `business_follows.is_subscribed_email` global izin olarak kullanılmıyor.

Canlı çalıştırılan doğrulama:

```bash
flutter analyze lib/features/notifications/data/notification_preferences_repository.dart \
  lib/features/notifications/domain/notification_preferences_models.dart \
  lib/features/notifications/domain/notification_preferences_provider.dart \
  lib/features/notifications/ui/notification_preferences_page.dart \
  lib/features/legal/ui/legal_acceptance_page.dart
```

Sonuç: `No issues found`.

```bash
flutter test test/features/notifications/domain/notification_preferences_test.dart \
  test/features/legal/legal_acceptance_marketing_test.dart
```

Sonuç: `27/27 All tests passed`.

## R-5 Web/Edge QA sonucu

Sonuç: Statik QA büyük ölçüde geçti. Web bağımlılıkları eksik olduğu için canlı web test/typecheck çalıştırılamadı.

- `/abonelik-iptal?token=...` route'u `(genel)` altında ve login istemiyor.
- Public unsubscribe route yalnızca opt-out yazıyor; hiçbir kod yolu `true` yazmıyor.
- `mkt` token sadece `user_profiles.marketing_email_opt_in = false`, `marketing_email_opted_in_at = null` yapıyor.
- `biz` token sadece `business_follows.is_subscribed_email = false` yapıyor.
- Token geçersizse, süresi dolmuşsa veya secret yoksa DB update yapılmıyor.
- `UNSUBSCRIBE_HMAC_SECRET` client bundle'a taşınmıyor; token üretim/doğrulama server-side.
- Service role kullanımı server component / server helper / edge function tarafında kalıyor; `NEXT_PUBLIC_` service role kullanımı yok.
- `/bildirim-ayarlari` global pazarlama iznini gösterip yönetiyor.
- Push bildirim tercihleri ile e-posta pazarlama izni ayrı section'larda tutuluyor.

Önemli nüans:

- Web `/bildirim-ayarlari/pazarlama-email-toggle.tsx` global pazarlama iznini RPC yerine browser Supabase client ile doğrudan `user_profiles` update ederek yönetiyor. RLS `profiles_update_own` doğruysa kullanıcı yalnızca kendi satırını günceller; ancak DB raporlarında önerilen "RPC üzerinden yönetim" standardından sapıyor. Güvenlik açısından kritik bulgu değil, ama üretim öncesi tercihen RPC ile hizalanması değerlendirilmeli.

## E-posta gönderim QA sonucu

Sonuç: Statik QA geçti; staging/production dinamik gönderim testi bekliyor.

- Next.js kampanya yolu (`app/sunucu/sahip/eposta-kampanya/route.ts`) `getOptedInEmails()` kullanıyor.
- `get-opted-in-emails.ts` çift filtre uyguluyor:
  - `business_follows.is_subscribed_email = true`
  - `user_profiles.marketing_email_opt_in = true`
- Supabase Edge Function `send-email-campaign/index.ts` aynı çift filtreyi uyguluyor.
- Opt-out yapan kullanıcıya e-posta gidebilecek ana kod yolu statik olarak kapatılmış görünüyor.
- Eski kampanya alıcı sorgusundaki `follower_id` ve `profiles!inner(email)` referansları `send-email-campaign/index.ts` içinde kalmamış. Aramada görünen `follower_id` referansları `user_follows` sosyal takip bağlamında, e-posta kampanya alıcı sorgusunda değil.
- Her alıcı için bireysel `biz` unsubscribe token üretiliyor.
- Eski `/settings/notifications` linki kaynak kodda bulunmadı; üretim unsubscribe yolu `/abonelik-iptal?token=...`.
- `UNSUBSCRIBE_HMAC_SECRET` yoksa Next.js kampanya route'u ve Edge Function fail-closed davranıyor; kampanya `failed` işaretleniyor ve linksiz e-posta gönderilmiyor.

Kalan e-posta gönderim riskleri:

- `auth.admin.listUsers({ page: 1, perPage: limit })` alıcı e-postası eşleştirmesinde ölçek riski taşıyor. 200+ / çok büyük kullanıcı havuzlarında istenen kullanıcı ilk sayfada olmayabilir.
- `RESEND_API_KEY` eksikse Next.js wrapper `provider_not_configured` döndürüyor; e-posta gönderimi yapılmıyor. Bu yasal risk değil ama staging testinde açıkça doğrulanmalı.

## Test sonuçları

Canlı çalıştırılan:

- Flutter analyze: geçti.
- Flutter hedef testleri: 27/27 geçti.

Raporlanan ve statik doğrulanan:

- Web unsubscribe token test dosyası 27 test içeriyor.
- Node/Deno HMAC cross-implementation grubu test dosyasında mevcut.
- Token testleri `generateUnsubscribeToken`, `verifyUnsubscribeToken`, invalid token, expired token, secret yokluğu, URL-safe çıktı ve Deno-style token doğrulamasını kapsıyor.

Çalıştırılamayan:

- `npm --prefix uygulamalar/web run test:unit -- test/lib/unsubscribe-token.test.ts` çalıştırılamadı: `vitest` binary bulunamadı.
- `npm --prefix uygulamalar/web run typecheck` çalıştırılamadı: `tsc` binary bulunamadı.
- Kontrol: `uygulamalar/web/node_modules/.bin/vitest` ve `uygulamalar/web/node_modules/.bin/tsc` yok. `node_modules` klasörü mevcut ama gerekli binary'ler kurulu değil.
- Local Supabase/Docker testleri çalıştırılmadı; production bağlantısı yapılmadı.
- `/abonelik-iptal` gerçek DB opt-out E2E testi çalıştırılmadı.
- Edge Function local serve / Deno runtime testi çalıştırılmadı.

## Kalan riskler

- R-4 ve R-5 migration'ları production'a uygulanmamış durumda. Kod hazır olsa da production veritabanı davranışı henüz değişmiş sayılmaz.
- Local Supabase/Docker testleri çalışmadığı için trigger/RPC davranışları sadece statik analizle doğrulandı.
- `UNSUBSCRIBE_HMAC_SECRET` hem Next.js hem Supabase Edge Function ortamında aynı değerle tanımlanmazsa unsubscribe sistemi çalışmaz; fail-closed nedeniyle e-posta gönderimi durmalıdır.
- Web test/typecheck canlı çalıştırılamadı; web bağımlılık kurulumu veya CI sonucu production öncesi zorunlu kontrol olmalı.
- Web `/bildirim-ayarlari` toggle'ı RPC yerine doğrudan tablo update ediyor. RLS'e dayanıyor; güvenli görünse de mimari standartla uyum için ayrıca değerlendirilmeli.
- İşletme bazlı abonelik yönetimi `/bildirim-ayarlari` içinde tam liste/toggle olarak yok; unsubscribe linki ve ayrı takip akışı ile kapatma mümkün, ama UX eksikliği devam ediyor.
- Çoklu instance production ortamında in-memory rate limit merkezi değildir.
- `marketing_email_opted_in_at` opt-out geçmişini saklamıyor; hukukçu ispat yeterliliğini değerlendirmeli.

## Production öncesi zorunlu kontrol listesi

- [ ] `20260619000001_remove_ip_metadata_from_policy_acceptances.sql` production'a uygulanmalı.
- [ ] R-4 migration öncesi `user_policy_acceptances` / `business_policy_acceptances` IP/UA baseline sayıları kaydedilmeli.
- [ ] R-4 migration sonrası IP/UA dolu kayıt sayısının 0 olduğu doğrulanmalı.
- [ ] R-4 migration sonrası `capture_request_metadata_v1()` gövdesinde IP/UA kodu kalmadığı doğrulanmalı.
- [ ] `admin_audit_log` akışı manuel smoke test edilmeli.
- [ ] `20260620000001_user_profiles_marketing_email_opt_in.sql` production'a uygulanmalı.
- [ ] `20260620000002_r5_marketing_email_rpcs.sql` production'a uygulanmalı.
- [ ] R-5 migration sonrası `marketing_email_opt_in DEFAULT false` ve mevcut kullanıcıların opt-in yapılmadığı doğrulanmalı.
- [ ] `get_my_notification_preferences_v1`, `update_my_marketing_email_opt_in_v1(true/false)`, `update_business_follow_email_subscription_v1(true/false)` authenticated kullanıcıyla test edilmeli.
- [ ] Başka kullanıcının takip/izin satırının değiştirilemediği iki kullanıcıyla manuel test edilmeli.
- [ ] `UNSUBSCRIBE_HMAC_SECRET` Next.js production ortamına eklenmeli.
- [ ] `UNSUBSCRIBE_HMAC_SECRET` Supabase Edge Function secrets içine aynı değerle eklenmeli.
- [ ] `SITE_URL` Supabase Edge Function secrets içine doğru production URL ile eklenmeli.
- [ ] Web `node_modules`/CI bağımlılıkları tamamlanmalı; `npm --prefix uygulamalar/web run typecheck` çalışmalı.
- [ ] Web unsubscribe token testleri canlı çalıştırılmalı.
- [ ] Staging ortamında gerçek `biz` token ile `/abonelik-iptal` opt-out testi yapılmalı.
- [ ] Staging ortamında legal kabul ekranında `_marketingOptIn=true/false` iki yol da DB'de doğrulanmalı.
- [ ] Staging ortamında Flutter `notification_preferences_page.dart` toggle true/false DB'de doğrulanmalı.
- [ ] Staging ortamında kampanya e-postası gönderilip her alıcının kişisel unsubscribe URL aldığı doğrulanmalı.
- [ ] Migration'lar ve secrets tamamlanmadan e-posta kampanyası production'da canlıya alınmamalı.

## Hukukçuya sorulacak sorular

- IP'siz politika kabul ispatı (`user_id + policy_version_id + accepted_at + source_app`) KVKK açısından yeterli mi?
- Policy acceptance tablolarında IP/UA sütunlarının fiziksel olarak kalıp NULL bırakılması kabul edilebilir mi, yoksa ileride DROP isteniyor mu?
- `marketing_email_opted_in_at` opt-out sırasında NULL yapılırken ayrı opt-out geçmişi tutulmaması ispat yükümlülüğü için yeterli mi?
- Global `marketing_email_opt_in` ve işletme bazlı `is_subscribed_email` için mevcut çift filtre (`AND`) hukuki metinlerde nasıl anlatılmalı?
- İşletme bazlı kampanyalarda global izin + işletme aboneliği birlikte aranması yeterli mi, yoksa her işletme için açık rıza metni/audit geçmişi ayrıca tutulmalı mı?
- Yurt dışı aktarım / DPA durumları (Supabase, Resend, Google/Firebase, Sentry) final KVKK/Gizlilik metinlerinden önce onaylandı mı?
- Ret hakkı linkinin 30 gün süreli stateless token olması yeterli mi, yoksa süresiz veya daha uzun süreli unsubscribe linki tercih edilmeli mi?

## Nihai karar

**B) Hukuki metin yazımına geçilebilir, ancak production öncesi bloklayıcılar kapatılmalı.**

Gerekçe:

- R-4 ve R-5 için kod/migration tasarımı statik QA'da teknik olarak tutarlı görünüyor.
- Flutter hedef analyze/test canlı geçti.
- Web/Edge statik doğrulamada unsubscribe, çift filtre ve fail-closed davranışları uygulanmış görünüyor.
- Ancak production'a geçiş için migration'lar uygulanmamış, secrets tanımlanmamış, local/staging DB testleri yapılmamış ve web test/typecheck bu makinede bağımlılık eksikliği nedeniyle çalıştırılamamıştır.

Bu nedenle final hukuki metin yazımına teknik zemin açısından başlanabilir; fakat production yayını ve e-posta kampanyalarının canlıya alınması yukarıdaki zorunlu kontrol listesi kapanmadan yapılmamalıdır.
