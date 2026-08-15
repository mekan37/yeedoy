# CRM v2 — Etiket Bazlı Toplu E-posta Kampanyası — Design Doc

## Bağlam

CRM v1'in "Kapsam Dışı" bölümünde bırakılan dört bağımsız alt-özellikten üçü tamamlandı: not/etiket ekleme (`docs/superpowers/specs/2026-08-11-crm-v2-not-etiket-design.md`), arama/filtre, zincir-çapında birleşik görünüm (`docs/superpowers/specs/2026-08-13-crm-v2-zincir-capinda-gorunum-design.md`). Bu doküman dördüncü ve son alt-projeyi (**toplu e-posta/kampanya**) kapsıyor.

Bu özellik daha önce bir kez inşa edilmişti (commit `b7917449`, "connect email campaign delivery": Resend entegrasyonu, `is_subscribed_email` onay filtresi, HMAC imzalı kişisel abonelik-iptal linki, 3/saat rate limit). Sonra genel bir MVP-kapsam-daraltma temizliğinde (`6523c12a`, "disable campaign and push tracking leaks" — aynı sweep sadakat'i de kill-switch'e almıştı, sadakat sonradan Ağustos'ta geri getirildi) route sadece `410 feature_disabled` döndüren bir stub'a indirgendi. Bu, bir güvenlik olayı değil, zamanlama kararıydı; CRM v1'in kendi tasarım belgesi zaten e-postayı "ayrı bir faz" olarak öngörüyordu.

**Önemli:** Abonelik-iptal altyapısının tamamı hâlâ canlı ve test edilmiş durumda (`app/(genel)/abonelik-iptal/page.tsx`, `src/lib/email/unsubscribe-token.ts` + `test/lib/unsubscribe-token.test.ts`) — sadece gönderim tarafı (`resend-client.ts`, `get-opted-in-emails.ts`) silinmişti. Bu doküman bu ikisini yeniden kurmak yerine, alıcı çözümlemesini bu oturumda kurulan zincir-çapında görünüm RPC desenine taşıyor (bkz. Mimari).

`RESEND_API_KEY` / `EMAIL_FROM` / `UNSUBSCRIBE_HMAC_SECRET` production'da tanımlı değil — kullanıcı kendi Resend hesabından key'i Vercel'e ekleyecek, kod ortam değişkeni yokken fail-safe/fail-closed davranır (bkz. Hata Durumları).

## Hedefler

- Owner, `/sahip/pazarlama/kampanyalar` üzerinden mevcut 3 sabit segmentin (`all_followers`, `new_30d`, `inactive_30d`) yanında, kendi CRM etiketlerinden birini (`VIP`, `Şikayetçi` vb.) seçip o etikete sahip müşterilere e-posta gönderebilsin.
- Gönderim gerçekten çalışsın (Resend API üzerinden) — mevcut kampanya ekranı bugün sadece bir kayıt oluşturuyor, hiçbir yere göndermiyor.
- Her e-postada yasal olarak zorunlu, kişiye özgü, çalışan bir abonelik-iptal linki bulunsun (6563 sayılı Kanun md. 9/3).
- İki ayrı onay sinyali doğru şekilde birlikte uygulansın: platform geneli pazarlama izni (`user_profiles.marketing_email_opt_in`) her segment için zorunlu taban filtre; işletme takip aboneliği (`business_follows.is_subscribed_email`) sadece takipçi-bazlı 3 segment için ek filtre.

## Kapsam Dışı (v2.4, YAGNI)

- Zamanlanmış gönderim (`scheduled_at` ileri tarihli) — sadece "şimdi gönder". Kolon zaten var, cron eklenmiyor.
- Zincir-çapında etiket birleştirme — etiketler zaten `business_id` bazlı (not/etiket faz kararı), kampanya hedeflemesi de aynı kapsamda kalır; owner kampanyayı hangi şubeden başlatıyorsa o şubenin etiketli müşterilerine gider.
- Açılma/tıklama takibi (open/click tracking) — `email_campaigns.opened_count` kolonu var ama v1'de doldurulmuyor (eski implementasyonda da yoktu); takip pikseli eklemek ayrı bir gizlilik/hukuk değerlendirmesi gerektirir.
- E-posta şablon editörü/zengin metin — düz `<p>` sarmalı metin, mevcut formun aynısı.
- `estimate_email_segment_v1`/yeni RPC dışında yeni bir segment türü (örn. "X TL üzeri harcayan") — sadece mevcut 3 sabit + etiket.

## Veri Modeli

Yeni tablo yok. `email_campaigns.target_segment` zaten serbest metin — yeni bir konvansiyon eklenir:

```
target_segment = 'all_followers' | 'new_30d' | 'inactive_30d'   -- mevcut, business_follows bazlı
target_segment = 'tag:<etiket-metni>'                            -- yeni, customer_tags bazlı
```

Şema migration'ı gerekmiyor.

## RPC Yüzeyi

**Yeni:**

```
get_email_campaign_recipients_v1(p_business_id uuid, p_target_segment text)
  RETURNS jsonb   -- [{ user_id, email, display_name }]
```

- `has_business_permission_v1(p_business_id, 'menu_write')` kontrolü (CRM'deki diğer tüm RPC'lerle aynı desen).
- `p_target_segment` `tag:` ile başlıyorsa → o `business_id`'de o etikete sahip (`customer_tags`) kullanıcıları CRM müşteri evreninden (yorum/rezervasyon/takip/sadakat — `get_business_customers_v1`'deki aynı `UNION`) çözer.
- Aksi halde → mevcut `business_follows` bazlı 3 segment mantığı (eski `estimate_email_segment_v1`'in WHERE'i).
- **Her iki dalda da** `user_profiles.marketing_email_opt_in = true` zorunlu taban filtre; takipçi-bazlı dalda ek olarak `business_follows.is_subscribed_email = true`.
- E-posta adresi `auth.users.email`'den `SECURITY DEFINER` yetkisiyle okunur (fonksiyon içinden, servis-rolü Node tarafına hiç çıkmaz — eski implementasyonun `auth.admin.listUsers()` + service-role client bağımlılığının yerini alır, sayfalama sınırı da ortadan kalkar).

**Genişletilen:**

```
estimate_email_segment_v1(p_business_id, p_segment)
```

- Aynı `tag:` önekini tanır, aynı çift-filtre mantığını uygular (gönderilecek gerçek sayı ile önizleme sayısı tutarlı olsun diye).

**Yeni (dropdown veri kaynağı):**

```
list_customer_tags_v1(p_business_id uuid)
  RETURNS text[]   -- o business_id'deki distinct customer_tags.tag değerleri
```

- `customer_tags` tablosunda client'a doğrudan SELECT GRANT'ı yok (not/etiket fazının kararı), bu yüzden form'daki etiket dropdown'ı bu küçük RPC'yi çağırır. Aynı `has_business_permission_v1(p_business_id, 'menu_write')` kontrolü.

## Akışlar

**Düzeltme (implementasyon planı öncesi doğrulandı):** `/sahip/pazarlama/kampanyalar` + `kampanya-formu.tsx`, `email_campaigns` ile **ilgisiz, tamamen ayrı bir özellik** — indirim/promosyon duyuruları (`campaigns` tablosu, `owner_upsert_campaign_v1` RPC'si, `title`/`type`/`discount_percent`/`starts_at`/`ends_at` alanları). E-posta kampanyası için bugün **hiçbir owner-facing UI yok** — `create_email_campaign_v1`/`list_email_campaigns_v1`/`estimate_email_segment_v1` RPC'lerini hiçbir frontend dosyası çağırmıyor (repo genelinde doğrulandı, yalnızca üretilen tip dosyalarında geçiyor). Aşağıdaki akış ve UI bölümü buna göre güncellendi.

1. Owner, **yeni** `/sahip/pazarlama/eposta-kampanyalari` sayfasını açar (mevcut `/sahip/pazarlama/kampanyalar`'dan bağımsız, ayrı bir nav girişi).
2. Segment dropdown'ında 3 sabit seçeneğin (`all_followers`/`new_30d`/`inactive_30d`) altında, `list_customer_tags_v1` ile o işletmenin mevcut `customer_tags` etiketleri listelenir ("Etiket: VIP" gibi).
3. Segment seçilince `estimate_email_segment_v1` çağrılır, tahmini alıcı sayısı gösterilir; 0 ise gönder butonu pasif.
4. Owner konu+içerik yazıp "Gönder"e basar → **yeniden etkinleştirilen** `/sunucu/sahip/eposta-kampanya` route handler'ı auth+sahiplik+rate limit (3/saat) kontrolünden geçer → `create_email_campaign_v1` ile kampanya kaydı oluşturulur → `get_email_campaign_recipients_v1` çağrılır → her alıcı için `generateUnsubscribeToken(userId, businessId, 'biz')` ile kişisel link üretilir → Resend'e batch'ler halinde (50'li) gönderilir → kampanya satırı `sent_count`/`sent_at` ile güncellenir.
5. Sayfa, `list_email_campaigns_v1` ile geçmiş kampanyaları (konu, segment, gönderim tarihi, alıcı sayısı) listeler.
6. Alıcı e-postadaki "Abonelikten çık" linkine tıklarsa, zaten canlı olan `/abonelik-iptal` akışı `business_follows.is_subscribed_email = false` yapar (mevcut davranış, dokunulmuyor).

## UI

- **Yeni sayfa:** `/sahip/pazarlama/eposta-kampanyalari` — kampanya formu (konu, içerik, segment `<select>` + dinamik etiketler, tahmini alıcı sayısı, gönder butonu) + geçmiş kampanyalar listesi. Mevcut `/sahip/pazarlama/kampanyalar` (indirim duyuruları) sayfasına **dokunulmuyor** — ayrı, paralel bir özellik.
- Owner panel navigasyonuna "E-posta Kampanyaları" girişi eklenir (Pazarlama bölümü altında, Sadakat/Kampanyalar'ın yanına).

## Hata Durumları

- **Segmentte 0 alıcı** → gönder butonu pasif, "Bu segmentte e-posta izni olan kimse yok" mesajı.
- **`RESEND_API_KEY` yok** → `provider_not_configured: true`, kampanya `sent_count: 0` ile işaretlenir, owner'a net bir uyarı gösterilir (sessiz başarısızlık yok).
- **`UNSUBSCRIBE_HMAC_SECRET` yok** → gönderim tamamen durdurulur, kampanya `status: failed` (fail-closed — 6563 md. 9/3 gereği iptal linksiz ticari e-posta gidemez). Bu, eski implementasyonun davranışının aynısı, değiştirilmiyor.

## Güvenlik ve Uyumluluk

- `get_email_campaign_recipients_v1` ve `list_customer_tags_v1`: `SECURITY DEFINER` + üçlü REVOKE deseni (`REVOKE ALL FROM PUBLIC` + `REVOKE EXECUTE FROM anon` + `GRANT EXECUTE TO authenticated`), production'da `has_function_privilege()` ile doğrudan doğrulanacak — bu oturumda zincir-çapında görünümde bulunan "Supabase yeni fonksiyonlara anon'a varsayılan EXECUTE veriyor" boşluğu baştan kapatılıyor.
- Rate limit: 3 kampanya/saat/kullanıcı (mevcut `oran-siniri.ts`, eski implementasyondan aynen taşınır).
- E-posta adresleri hiçbir yerde loglanmaz (eski `resend-client.ts`/`get-opted-in-emails.ts`'deki disiplin korunur) — sadece sayaç loglanır.
- **Çift onay filtresi düzeltmesi:** eski implementasyonun route yorumu "çift filtre" iddia ediyordu ama gerçek kod sadece `is_subscribed_email` kontrol ediyordu, `marketing_email_opt_in` hiç yoktu. Yeni RPC bu boşluğu kapatıyor — her segment tipi için taban filtre olarak zorunlu.
- Abonelik-iptal token'ı (`unsubscribe-token.ts`) HMAC-SHA256 imzalı, süresi dolan/kurcalanan/yanlış tip token'lar reddediliyor — bu altyapıya dokunulmuyor, aynen kullanılıyor.
