import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

type DispatchPayload = {
  notification_id?: string;
  user_id?: string;
  limit?: number;
};

const ALLOWED_PUSH_TYPES = new Set<string>([
  "price_changed",
  "comment_reply",
  "achievement_unlocked",
  "owner_new_review",
  "favorite_revisit_reminder",
  "friend_checkin",
  "loyalty_reward_unlocked",
  "loyalty_points_earned",
  "menu_updated",
  "business_hours_changed",
]);

function isInvalidFcmTokenError(raw: string): boolean {
  const text = raw.toLowerCase();
  return text.includes("unregistered") ||
    text.includes("registration token is not a valid fcm registration token") ||
    text.includes("invalid registration token") ||
    (text.includes("invalid_argument") && text.includes("token"));
}

/**
 * Dispatch notification rows to FCM devices.
 * Trigger source can call:
 *  - POST /functions/v1/push-dispatch with { notification_id }
 *  - POST /functions/v1/push-dispatch with { user_id } for latest unread rows
 *  - POST /functions/v1/push-dispatch with {} to process queued jobs
 */
serve(async (req) => {
  if (req.method !== "POST") {
    return json({ ok: false, error: "method_not_allowed" }, 405);
  }

  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) {
    return json({ ok: false, error: "missing_jwt" }, 401);
  }

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
  const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
  const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID");
  const FIREBASE_ACCESS_TOKEN = Deno.env.get("FIREBASE_ACCESS_TOKEN");

  if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !SUPABASE_SERVICE_ROLE_KEY) {
    return json({ ok: false, error: "missing_supabase_env" }, 500);
  }
  if (!FIREBASE_PROJECT_ID || !FIREBASE_ACCESS_TOKEN) {
    return json({ ok: false, error: "missing_firebase_env" }, 500);
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: auth } },
  });

  const { data: userRes, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userRes?.user) {
    return json({ ok: false, error: "not_authenticated" }, 401);
  }
  const requesterId = userRes.user.id;
  const { data: isAdminRaw } = await userClient.rpc("is_admin");
  const isAdmin = isAdminRaw === true || (isAdminRaw && isAdminRaw.is_admin === true);

  const body = (await req.json().catch(() => ({}))) as DispatchPayload;

  let notifications: Array<Record<string, unknown>> = [];
  const queuedJobByNotification = new Map<string, string>();
  if (body.notification_id) {
    const { data, error } = await supabase
      .from("notifications")
      .select("id,user_id,type,title,body,data")
      .eq("id", body.notification_id)
      .limit(1);
    if (error) return json({ ok: false, error: "notifications_fetch_failed", detail: error.message }, 500);
    if (!isAdmin && (data?.[0]?.user_id ?? "") !== requesterId) {
      return json({ ok: false, error: "forbidden" }, 403);
    }
    notifications = data ?? [];
  } else if (body.user_id) {
    if (!isAdmin && body.user_id !== requesterId) {
      return json({ ok: false, error: "forbidden" }, 403);
    }
    const { data, error } = await supabase
      .from("notifications")
      .select("id,user_id,type,title,body,data")
      .eq("user_id", body.user_id)
      .eq("is_read", false)
      .order("created_at", { ascending: false })
      .limit(5);
    if (error) return json({ ok: false, error: "notifications_fetch_failed", detail: error.message }, 500);
    notifications = data ?? [];
  } else {
    if (!isAdmin) {
      return json({ ok: false, error: "forbidden" }, 403);
    }
    const limit = Math.max(1, Math.min(50, Number(body.limit ?? 20)));
    const { data, error } = await supabase.rpc("dequeue_notification_dispatch_jobs_v1", {
      p_limit: limit,
    });
    if (error) {
      return json({ ok: false, error: "dequeue_failed", detail: error.message }, 500);
    }
    const rows = (data ?? []) as Array<Record<string, unknown>>;
    notifications = rows.map((r) => ({
      id: r.notification_id,
      user_id: r.user_id,
      type: r.type,
      title: r.title,
      body: r.body,
      data: r.data,
    }));
    for (const row of rows) {
      queuedJobByNotification.set(
        String(row.notification_id ?? ""),
        String(row.job_id ?? ""),
      );
    }
  }

  const sent: Array<Record<string, unknown>> = [];
  const skipped: Array<Record<string, unknown>> = [];

  for (const n of notifications) {
    const userId = String(n.user_id ?? "");
    const notificationId = String(n.id ?? "");
    const notificationType = String(n.type ?? "");
    const jobId = queuedJobByNotification.get(notificationId);
    if (!ALLOWED_PUSH_TYPES.has(notificationType)) {
      skipped.push({
        id: n.id,
        reason: "push_type_not_allowed",
        type: notificationType,
      });
      if (jobId) {
        await supabase.rpc("complete_notification_dispatch_job_v1", {
          p_job_id: jobId,
          p_success: true,
          p_error: null,
        });
      }
      continue;
    }
    if (!userId) {
      skipped.push({ id: n.id, reason: "missing_user_id" });
      if (jobId) {
        await supabase.rpc("complete_notification_dispatch_job_v1", {
          p_job_id: jobId,
          p_success: false,
          p_error: "missing_user_id",
        });
      }
      continue;
    }

    const { data: devices, error: devicesErr } = await supabase
      .from("user_devices")
      .select("id,fcm_token,platform,last_seen_at")
      .eq("user_id", userId)
      .order("last_seen_at", { ascending: false })
      .limit(20);
    if (devicesErr) {
      skipped.push({ id: n.id, reason: "device_query_failed", detail: devicesErr.message });
      if (jobId) {
        await supabase.rpc("complete_notification_dispatch_job_v1", {
          p_job_id: jobId,
          p_success: false,
          p_error: devicesErr.message,
        });
      }
      continue;
    }
    if (!devices || devices.length === 0) {
      skipped.push({ id: n.id, reason: "no_device" });
      if (jobId) {
        await supabase.rpc("complete_notification_dispatch_job_v1", {
          p_job_id: jobId,
          p_success: true,
          p_error: null,
        });
      }
      continue;
    }

    let sentAtLeastOnce = false;
    let lastError: string | null = null;
    for (const d of devices) {
      const token = String(d.fcm_token ?? "");
      if (!token) continue;

      // Build FCM data payload — include routing fields so Flutter can
      // deep-link without a network round-trip on push tap.
      const notifData = (n.data ?? {}) as Record<string, unknown>;
      const fcmData: Record<string, string> = {
        notification_id: String(n.id ?? ""),
        type: notificationType,
      };
      for (const key of [
        "business_id",
        "menu_item_id",
        "menu_id",
        "review_id",
        "target_path",
        "savings_cents",
        "matched_price_cents",
        "previous_price_cents",
      ]) {
        const val = notifData[key];
        if (val !== undefined && val !== null) {
          fcmData[key] = String(val);
        }
      }

      const endpoint = `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`;
      const res = await fetch(endpoint, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${FIREBASE_ACCESS_TOKEN}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token,
            notification: {
              title: String(n.title ?? "Bildirim"),
              body: String(n.body ?? ""),
            },
            data: fcmData,
          },
        }),
      });

      if (!res.ok) {
        const text = await res.text();
        lastError = text.slice(0, 300);
        if (isInvalidFcmTokenError(text)) {
          await supabase
            .from("user_devices")
            .delete()
            .eq("id", String(d.id ?? ""))
            .eq("user_id", userId);
        }
        skipped.push({
          id: n.id,
          device_id: d.id,
          reason: "fcm_send_failed",
          status: res.status,
          detail: text.slice(0, 300),
        });
        continue;
      }

      const payload = await res.json().catch(() => ({}));
      sentAtLeastOnce = true;
      sent.push({
        id: n.id,
        device_id: d.id,
        platform: d.platform,
        fcm_name: payload?.name ?? null,
      });
    }
    if (jobId) {
      await supabase.rpc("complete_notification_dispatch_job_v1", {
        p_job_id: jobId,
        p_success: sentAtLeastOnce,
        p_error: sentAtLeastOnce ? null : (lastError ?? "no_delivery"),
      });
    }
  }

  return json({
    ok: true,
    notification_count: notifications.length,
    sent_count: sent.length,
    skipped_count: skipped.length,
    sent,
    skipped,
  });
});
