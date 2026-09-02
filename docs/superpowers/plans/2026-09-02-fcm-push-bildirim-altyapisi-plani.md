# FCM Push Bildirim Altyapısı Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `public.notifications` tablosuna düşen HER satır (regional_recommendation dahil tüm mevcut bildirim tipleri) için gerçek bir FCM push bildirimi göndermek — şu an sadece uygulama içi gelen kutusuna düşüyorlar, kilit ekranında hiçbir şey çıkmıyor.

**Architecture:** `notifications` tablosuna `AFTER INSERT` trigger'ı, Supabase Vault'ta saklanan bir service_role anahtarıyla `pg_net.http_post` üzerinden yeni bir `send-push` Edge Function'ını asenkron çağırır. Edge function, Firebase servis hesabı bilgileriyle (zaten Supabase secrets'ta) Google OAuth2 access_token alır, kullanıcının `user_devices` tablosundaki tüm cihaz token'larına FCM HTTP v1 API ile paralel push gönderir, geçersiz (UNREGISTERED/NOT_FOUND) token'ları siler.

**Tech Stack:** Postgres/plpgsql (trigger, pg_net), Supabase Edge Function (Deno, Web Crypto RS256 imzalama), Firebase Cloud Messaging HTTP v1 API.

**Spec:** `docs/superpowers/specs/2026-09-02-fcm-push-bildirim-altyapisi-design.md`

**Zaten tamamlanmış ön koşullar (bu plandan önce, manuel olarak yapıldı — tekrar yapılmasına gerek yok):**
- Firebase Cloud Messaging API (V1) `yeedoy` Firebase projesinde etkin doğrulandı.
- Yeni bir Admin SDK servis hesabı anahtarı üretildi; `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` olarak Supabase secrets'a taşındı (proje: `wvofyimbjndxtxitsjpd`).
- Supabase Vault'a `push_trigger_service_role_key` adıyla projenin service_role JWT'si kaydedildi (id: `be04068f-5ea4-4979-9244-62a101cf070b`) — trigger bunu `vault.decrypted_secrets` üzerinden okuyacak.

---

## Dosya Yapısı

**Yeni:**
- `supabase/migrations/20260902######_enable_pg_net_and_push_trigger.sql` — `pg_net` extension + trigger fonksiyonu + trigger
- `supabase/functions/send-push/index.ts` — Edge Function

**Değiştirilecek:**
- `supabase/config.toml` — `send-push` fonksiyon girdisi

---

### Task 1: `pg_net` extension + push trigger

**Files:**
- Create: `supabase/migrations/20260902######_enable_pg_net_and_push_trigger.sql` (gerçek dosya adı `mcp__supabase__apply_migration` aracının ürettiği timestamp'e göre olacak — plandaki `######` yerine aracın kendi ürettiği ismi kullan)

- [ ] **Step 1: Migration dosyasını yaz**

```sql
-- pg_net: Postgres'ten asenkron HTTP çağrısı yapabilmek için (trigger → edge function).
CREATE EXTENSION IF NOT EXISTS pg_net;

-- notifications tablosuna düşen HER satır için send-push edge function'ını tetikler.
-- Vault'ta 'push_trigger_service_role_key' kaydı yoksa (örn. henüz kurulmamış bir
-- ortamda) sessizce no-op yapar — notifications INSERT akışı ASLA kırılmaz.
CREATE OR REPLACE FUNCTION public.trg_notify_push_v1()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_service_role_key text;
BEGIN
  SELECT decrypted_secret INTO v_service_role_key
  FROM vault.decrypted_secrets
  WHERE name = 'push_trigger_service_role_key'
  LIMIT 1;

  IF v_service_role_key IS NULL THEN
    RETURN NEW;
  END IF;

  PERFORM net.http_post(
    url := 'https://wvofyimbjndxtxitsjpd.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_service_role_key
    ),
    body := jsonb_build_object('notification_id', NEW.id)
  );

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.trg_notify_push_v1 IS
  'notifications AFTER INSERT trigger: pg_net ile send-push edge function''ını asenkron tetikler. Vault kaydı eksikse no-op (push altyapısı kurulu değilse notifications akışı kırılmaz).';

DROP TRIGGER IF EXISTS trg_notifications_push ON public.notifications;
CREATE TRIGGER trg_notifications_push
  AFTER INSERT ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION public.trg_notify_push_v1();
```

- [ ] **Step 2: Migration'ı uygula**

`mcp__supabase__apply_migration` — `name: "enable_pg_net_and_push_trigger"`.

- [ ] **Step 3: Doğrula**

```sql
SELECT extname FROM pg_extension WHERE extname = 'pg_net';
SELECT tgname FROM pg_trigger WHERE tgname = 'trg_notifications_push';
```
Beklenen: ikisi de 1'er satır döner.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/*_enable_pg_net_and_push_trigger.sql
git commit -m "feat(supabase): pg_net etkinleştirildi, notifications INSERT'te send-push edge function'ını tetikleyen trigger eklendi"
```

---

### Task 2: `send-push` Edge Function

**Files:**
- Create: `supabase/functions/send-push/index.ts`
- Modify: `supabase/config.toml`

Bu edge function, eski (silinmiş) `uygulamalar/web/src/lib/push/fcm-client.ts`'nin JWT/OAuth2 mantığının Deno/Web Crypto'ya taşınmış hâlidir. Node'un `crypto.createSign` yerine `crypto.subtle.sign` kullanılır; RS256 imzalama mantığı ve FCM HTTP v1 çağrı şekli birebir korunur.

- [ ] **Step 1: Edge function dosyasını yaz**

```typescript
// supabase/functions/send-push/index.ts
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function base64UrlEncode(bytes: Uint8Array): string {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "");
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

async function getAccessToken(clientEmail: string, privateKeyPem: string): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64UrlEncode(
    new TextEncoder().encode(JSON.stringify({ alg: "RS256", typ: "JWT" })),
  );
  const payload = base64UrlEncode(
    new TextEncoder().encode(
      JSON.stringify({
        iss: clientEmail,
        sub: clientEmail,
        aud: "https://oauth2.googleapis.com/token",
        iat: now,
        exp: now + 3600,
        scope: "https://www.googleapis.com/auth/firebase.messaging",
      }),
    ),
  );
  const signingInput = `${header}.${payload}`;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKeyPem),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signingInput),
  );
  const jwt = `${signingInput}.${base64UrlEncode(new Uint8Array(signature))}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const data = (await res.json()) as { access_token?: string };
  if (!data.access_token) {
    throw new Error("fcm: oauth token exchange returned no access_token");
  }
  return data.access_token;
}

serve(async (req) => {
  if (req.method !== "POST") return json({ ok: false, error: "method_not_allowed" }, 405);

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
  const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return json({ ok: false, error: "missing_supabase_env" }, 500);
  }

  // Bu fonksiyon sadece notifications trigger'ı tarafından çağrılmalı — genel
  // bir authenticated kullanıcı kendi JWT'siyle çağırıp başka bir notification_id
  // için push tetikleyemesin diye özellikle service_role eşleşmesi aranıyor
  // (verify_jwt=true zaten "bir Supabase JWT" ister ama rolü ayırt etmez).
  const auth = req.headers.get("authorization") ?? "";
  if (auth !== `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`) {
    return json({ ok: false, error: "forbidden" }, 403);
  }

  let notificationId: string | null = null;
  try {
    const body = await req.json();
    notificationId = typeof body?.notification_id === "string" ? body.notification_id : null;
  } catch {
    return json({ ok: false, error: "invalid_json" }, 400);
  }
  if (!notificationId) return json({ ok: false, error: "notification_id_required" }, 400);

  const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  const { data: notification, error: notifErr } = await admin
    .from("notifications")
    .select("id,user_id,title,body")
    .eq("id", notificationId)
    .maybeSingle();
  if (notifErr || !notification) {
    return json({ ok: false, error: "notification_not_found" }, 404);
  }

  const projectId = Deno.env.get("FIREBASE_PROJECT_ID")?.trim();
  const clientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL")?.trim();
  const privateKey = Deno.env.get("FIREBASE_PRIVATE_KEY")?.replace(/\\n/g, "\n").trim();
  if (!projectId || !clientEmail || !privateKey) {
    // Zarif bozulma: secret'lar eksikse (örn. yerel dev) uygulama içi bildirim
    // kutusu zaten dolu — push sadece bonus katman, hata fırlatılmaz.
    return json({ ok: true, provider_not_configured: true });
  }

  const { data: devices, error: devicesErr } = await admin
    .from("user_devices")
    .select("id,fcm_token")
    .eq("user_id", notification.user_id);
  if (devicesErr) {
    return json({ ok: false, error: "devices_lookup_failed", detail: devicesErr.message }, 500);
  }
  if (!devices || devices.length === 0) {
    return json({ ok: true, success_count: 0, failure_count: 0 });
  }

  let accessToken: string;
  try {
    accessToken = await getAccessToken(clientEmail, privateKey);
  } catch (err) {
    return json(
      { ok: false, error: "oauth_failed", detail: err instanceof Error ? err.message : "unknown" },
      502,
    );
  }

  const endpoint = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  let successCount = 0;
  let failureCount = 0;
  const staleDeviceIds: string[] = [];

  await Promise.all(
    devices.map(async (device) => {
      try {
        const res = await fetch(endpoint, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: device.fcm_token,
              notification: { title: notification.title, body: notification.body },
            },
          }),
        });

        if (res.ok) {
          successCount++;
          return;
        }

        failureCount++;
        if (res.status === 404) {
          const errBody = (await res.json().catch(() => null)) as
            | { error?: { status?: string } }
            | null;
          const status = errBody?.error?.status;
          if (status === "UNREGISTERED" || status === "NOT_FOUND") {
            staleDeviceIds.push(device.id);
          }
        }
      } catch {
        failureCount++;
      }
    }),
  );

  if (staleDeviceIds.length > 0) {
    await admin.from("user_devices").delete().in("id", staleDeviceIds);
  }

  return json({
    ok: true,
    success_count: successCount,
    failure_count: failureCount,
    stale_removed: staleDeviceIds.length,
  });
});
```

- [ ] **Step 2: `config.toml`'a fonksiyon girdisini ekle**

`supabase/config.toml` içindeki `[functions.media-upload-user]` bloğunun hemen altına:

```toml
[functions.send-push]
enabled = true
verify_jwt = true
entrypoint = "./functions/send-push/index.ts"
```

- [ ] **Step 3: Edge function'ı deploy et**

`mcp__supabase__deploy_edge_function` aracıyla `name: "send-push"`, `entrypoint_path: "supabase/functions/send-push/index.ts"`.

- [ ] **Step 4: Deploy'u doğrula**

`mcp__supabase__list_edge_functions` çıktısında `send-push`'ın `status: "ACTIVE"` olduğunu doğrula.

- [ ] **Step 5: Commit**

```bash
git add supabase/functions/send-push supabase/config.toml
git commit -m "feat(supabase): send-push edge function eklendi ve deploy edildi (FCM HTTP v1)"
```

---

### Task 3: Uçtan uca doğrulama (gerçek cihaza push göndermeden)

**Files:** Yok (sadece doğrulama)

- [ ] **Step 1: Sahte ama biçimi doğru bir test cihazı ekle**

```sql
-- Gerçek bir test kullanıcısı kullan (örn. kullanici1@yeedoy.test → d1d1d1d1-d1d1-d1d1-d1d1-d1d1d1d1d1d1)
insert into public.user_devices (user_id, fcm_token, platform, app_version, last_seen_at)
values (
  'd1d1d1d1-d1d1-d1d1-d1d1-d1d1d1d1d1d1',
  'fake-test-token-' || gen_random_uuid()::text,
  'android',
  '1.0.0+1',
  now()
)
returning id;
```

Dönen `id`'yi bir sonraki adımda temizlik için not al.

- [ ] **Step 2: Bir bildirim satırı ekleyip trigger'ı tetikle**

```sql
insert into public.notifications (user_id, type, title, body, data)
values (
  'd1d1d1d1-d1d1-d1d1-d1d1-d1d1d1d1d1d1',
  'test_push_e2e',
  'Test Bildirimi',
  'Faz 2 uçtan uca doğrulama',
  '{}'::jsonb
)
returning id;
```

- [ ] **Step 3: pg_net'in çağrıyı yaptığını doğrula**

```sql
select id, status_code, created
from net._http_response
order by created desc
limit 3;
```

Beklenen: en üstteki satır birkaç saniye içinde belirir, `status_code` 200 veya 403/404/502 gibi bir HTTP kodu taşır (sahte token FCM tarafından reddedilse de edge function'ın kendisi çalışıp yanıt döndüğünü kanıtlar — `status_code`'un `null`/timeout olmaması önemli, spesifik değer önemli değil).

- [ ] **Step 4: Edge function loglarından çalıştığını doğrula**

`mcp__supabase__query_logs` aracıyla `service: "edge-function"` için son loglara bak, `send-push` fonksiyonunun çalıştığını ve bir hata fırlatmadan (500 crash değil) yanıt döndürdüğünü doğrula.

- [ ] **Step 5: Sahte token'ın (muhtemelen) silindiğini doğrula**

```sql
select id from public.user_devices where fcm_token like 'fake-test-token-%';
```

Beklenen: Google'ın sahte token'a verdiği spesifik hataya bağlı olarak (UNREGISTERED/NOT_FOUND ise) satır silinmiş olabilir, ya da farklı bir hata koduysa (örn. INVALID_ARGUMENT) satır kalmış olabilir — her iki durum da kabul edilebilir, kritik olan Adım 3-4'teki "boru hattı gerçekten çalıştı" kanıtıdır. Eğer satır hâlâ duruyorsa elle temizle:

```sql
delete from public.user_devices where fcm_token like 'fake-test-token-%';
delete from public.notifications where type = 'test_push_e2e';
```

- [ ] **Step 6: Gerçek cihaz testi (manuel, kullanıcı tarafından)**

Bu adım otomatikleştirilemez — gerçek bir telefonda mobil uygulama açılıp bir kullanıcı hesabıyla girildiğinde `PushNotificationService.start()` gerçek bir FCM token'ı `user_devices`'a kaydeder. O kullanıcıya (örn. bir yorum yanıtı veya yöresel öneri tetikleyerek) bir `notifications` satırı düşürüldüğünde, telefonun kilit ekranında gerçek bir push bildirimi çıkmalı. Bu adımı kullanıcı kendi cihazında test etmeli.

- [ ] **Step 7: Sonuç özeti**

Bu adımda kod değişikliği yok — `git log --oneline -5` ile Task 1-2'nin commit edildiğini doğrula.
