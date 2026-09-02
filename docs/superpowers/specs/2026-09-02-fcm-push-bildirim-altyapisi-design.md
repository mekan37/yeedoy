# FCM Push Bildirim Altyapısı — Design

**Bağlam:** Yöresel Yemek Önerisi Faz 1 (`docs/superpowers/plans/2026-08-31-yoresel-yemek-onerisi-faz1-temel.md`) tamamlandı — `notifications` tablosuna doğru satırlar düşüyor ama gerçek FCM push (kilit ekranı bildirimi) hiçbir bildirim tipi için çalışmıyor. Araştırma sırasında ortaya çıktı ki bu, sadece regional_recommendation'a özgü bir eksiklik değil: **hiçbir** bildirim tipi (review_reply, price_suggestion_result, favorite_revisit_reminder, owner_new_review, regional_recommendation vb.) gerçek push göndermiyor. Daha önce bir push-kampanya sistemi (`fcm-client.ts`, `push-dispatch`, `send-push-campaign` edge function'ları) vardı ama 29 Ağustos 2026'da bilerek "MVP kapsamı dışı" olarak kill-switch edildi (commit `2003c985`) — hiç deploy edilmemiş, sıfır çağıranı olan ölü kod olarak silindi. Bu plan, genel amaçlı (tüm bildirim tiplerini kapsayan) bir push gönderim altyapısını sıfırdan (ama eski, kanıtlanmış FCM v1 JWT/OAuth2 mantığını yeniden kullanarak) kurar.

**Ön koşul zaten tamamlandı:** Firebase Cloud Messaging API (V1) `yeedoy` projesinde etkin doğrulandı; yeni bir Admin SDK servis hesabı anahtarı üretildi ve `FIREBASE_PROJECT_ID` / `FIREBASE_CLIENT_EMAIL` / `FIREBASE_PRIVATE_KEY` olarak Supabase secrets'a taşındı (içeriği hiçbir zaman görüntülenmedi, yerel indirilen dosya silindi).

## Mimari

```
INSERT INTO public.notifications (...)
  │
  ▼ AFTER INSERT trigger (her satır için)
trg_notify_push_v1()
  │  vault.decrypted_secrets'tan service_role key + edge function URL'i okur
  ▼ pg_net.http_post(...)  — asenkron, transaction'ı bloklamaz
Edge Function: send-push
  │  1. notification_id ile public.notifications + public.user_devices'ı sorgular
  │  2. Firebase secrets eksikse: no-op, log, 200 dön (zarif bozulma)
  │  3. JWT (RS256, service account) → Google OAuth2 access_token
  │  4. Her aktif cihaz token'ı için FCM HTTP v1'e paralel POST
  │  5. UNREGISTERED/NOT_FOUND dönen token'ları user_devices'tan siler
  ▼
Firebase Cloud Messaging → kullanıcının cihazı (kilit ekranı bildirimi)
```

## Bileşenler

### 1. Veritabanı: trigger + Vault kaydı

**Yeni migration** — `notifications` tablosuna `AFTER INSERT FOR EACH ROW` trigger'ı ekler. Trigger fonksiyonu:
- `vault.decrypted_secrets`'tan `service_role_key` ve edge function base URL'ini okur (ikisi de migration'dan önce, ayrı bir adımda `select vault.create_secret(...)` ile elle/CLI üzerinden eklenir — **migration dosyasına asla düz metin service_role key yazılmaz**, bu proje için kritik bir güvenlik kuralı).
- `pg_net.http_post` ile `send-push` edge function'ını `{ "notification_id": NEW.id }` gövdesiyle, `Authorization: Bearer <service_role_key>` header'ıyla çağırır.
- Vault kaydı yoksa (henüz kurulmamışsa) trigger sessizce no-op yapar — geliştirme/test ortamlarında push altyapısı kurulu değilse `notifications` INSERT'i asla kırılmaz.

### 2. Edge Function: `supabase/functions/send-push/index.ts`

Eski `fcm-client.ts`'nin mantığı Deno'ya taşınır (Node'un `crypto.createSign` yerine Web Crypto `crypto.subtle.sign` ile RS256 imzalama):
- `service_role` client ile `notification_id`'den bildirim satırını ve `user_devices` üzerinden o kullanıcının tüm `(fcm_token, platform)` çiftlerini çeker.
- Firebase secret'ları eksikse (`FIREBASE_PROJECT_ID`/`CLIENT_EMAIL`/`PRIVATE_KEY`) `{ provider_not_configured: true }` ile 200 döner — hata fırlatmaz.
- JWT oluşturup Google OAuth2'den access_token alır (1 saat geçerli, her çağrıda taze alınır — v1'de cache'lenmez, YAGNI).
- Her token için `POST https://fcm.googleapis.com/v1/projects/{project_id}/messages:send` — `notification.title`/`notification.body` doğrudan `notifications` satırından.
- Yanıt `UNREGISTERED` veya `NOT_FOUND` ise o `user_devices` satırını siler (geçersiz token temizliği).
- `verify_jwt: true` (projedeki diğer tüm edge function'larla aynı konvansiyon) — sadece geçerli bir Supabase JWT (service_role dahil) ile çağrılabilir, anonim herkese açık değil.

### 3. Test/doğrulama

- Migration sonrası: gerçek bir test kullanıcısına sahte bir `user_devices` satırı (geçersiz ama biçimi doğru bir FCM token) eklenip `notifications`'a manuel bir satır INSERT edilerek uçtan uca tetiklenir; `net._http_response` tablosundan pg_net çağrısının gittiği, edge function loglarından FCM'in `UNREGISTERED` dediği ve `user_devices` satırının silindiği doğrulanır (gerçek bir cihaza push düşürmeden tüm boru hattı test edilmiş olur).
- Gerçek bir cihaza push düşürme testi, kullanıcı kendi telefonuyla mobil uygulamayı açıp token kaydettikten sonra manuel olarak yapılabilir (bu plan bunu bir adım olarak içerir ama otomatikleştirilemez).

## Hata Yönetimi

- Firebase secret'ları eksik/geçersiz → sessizce no-op, `notifications` akışı asla etkilenmez.
- pg_net HTTP hatası (edge function ulaşılamıyor) → trigger zaten asenkron olduğu için ana INSERT'i etkilemez; pg_net'in kendi `net._http_response` tablosunda hata görülebilir ama uygulama seviyesinde otomatik retry v1 kapsamında yok.
- FCM 401/403 (kimlik doğrulama hatası) → log'lanır, o çağrı için `failure`, token silinmez (geçici bir sorun olabilir, sadece `UNREGISTERED`/`NOT_FOUND` kalıcı kabul edilir).

## Kapsam Dışı (bilerek)

- Web push (ayrı, hâlâ kill-switch'li bir özellik — bu plan mobil Android/iOS'u kapsar).
- Uygulama seviyesinde retry/kuyruk mekanizması.
- Bildirim tipine göre özelleştirilmiş push içeriği/görseli (mevcut `title`/`body` aynen kullanılır).
- Push kampanya (admin toplu gönderim) özelliğinin geri getirilmesi — bu, ayrı, bilinçli bir kill-switch kararıydı ve bu planın parçası değil.
