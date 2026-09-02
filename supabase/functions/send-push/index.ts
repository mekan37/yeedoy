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
