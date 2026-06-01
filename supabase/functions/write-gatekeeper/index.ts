import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(data: unknown, status = 200, requestId?: string) {
  const payload = requestId && data && typeof data === "object" && !Array.isArray(data)
    ? { ...(data as Record<string, unknown>), request_id: requestId }
    : data;
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...(requestId ? { "x-request-id": requestId } : {}),
    },
  });
}

type WriteAction =
  | "review_vote_set"
  | "review_vote_remove"
  | "visit_add"
  | "visit_remove"
  | "menu_photo_delete"
  | "owner_price_suggestion_approve"
  | "owner_price_suggestion_reject";

type WriteRequest = {
  action?: WriteAction;
  payload?: Record<string, unknown>;
  request_id?: string;
};

type RateRule = {
  windowSeconds: number;
  userLimit: number;
  scopeWindowSeconds: number;
  scopeUserLimit: number;
};

const RATE_RULES: Record<WriteAction, RateRule> = {
  review_vote_set: { windowSeconds: 60, userLimit: 30, scopeWindowSeconds: 30, scopeUserLimit: 5 },
  review_vote_remove: { windowSeconds: 60, userLimit: 30, scopeWindowSeconds: 30, scopeUserLimit: 5 },
  visit_add: { windowSeconds: 60, userLimit: 20, scopeWindowSeconds: 60, scopeUserLimit: 3 },
  visit_remove: { windowSeconds: 60, userLimit: 20, scopeWindowSeconds: 60, scopeUserLimit: 3 },
  menu_photo_delete: { windowSeconds: 60, userLimit: 20, scopeWindowSeconds: 60, scopeUserLimit: 3 },
  owner_price_suggestion_approve: { windowSeconds: 60, userLimit: 12, scopeWindowSeconds: 3600, scopeUserLimit: 1 },
  owner_price_suggestion_reject: { windowSeconds: 60, userLimit: 12, scopeWindowSeconds: 3600, scopeUserLimit: 1 },
};

function asNonEmptyString(value: unknown): string | null {
  const text = String(value ?? "").trim();
  return text.length > 0 ? text : null;
}

function readClientIp(req: Request): string {
  const forwarded = req.headers.get("x-forwarded-for") ?? "";
  if (forwarded.trim().length > 0) {
    const first = forwarded.split(",")[0]?.trim();
    if (first) return first;
  }
  const cf = req.headers.get("cf-connecting-ip");
  if (cf?.trim()) return cf.trim();
  const real = req.headers.get("x-real-ip");
  if (real?.trim()) return real.trim();
  return "unknown";
}

async function sha256Hex(input: string): Promise<string> {
  const encoded = new TextEncoder().encode(input);
  const digest = await crypto.subtle.digest("SHA-256", encoded);
  return Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

async function enforceRateLimit(
  adminClient: ReturnType<typeof createClient>,
  action: WriteAction,
  userId: string,
  ipHash: string,
  scope: string | null,
) {
  const rule = RATE_RULES[action];
  const now = Date.now();
  const windowStart = new Date(now - rule.windowSeconds * 1000).toISOString();
  const scopeStart = new Date(now - rule.scopeWindowSeconds * 1000).toISOString();

  const [{ count: userCount }, { count: ipCount }] = await Promise.all([
    adminClient
      .from("edge_rate_limit_events")
      .select("id", { count: "exact", head: true })
      .eq("action", action)
      .eq("user_id", userId)
      .gte("created_at", windowStart),
    adminClient
      .from("edge_rate_limit_events")
      .select("id", { count: "exact", head: true })
      .eq("action", action)
      .eq("ip_hash", ipHash)
      .gte("created_at", windowStart),
  ]);

  if ((userCount ?? 0) >= rule.userLimit) {
    return { ok: false, error: "rate_limited_user" as const };
  }
  if ((ipCount ?? 0) >= Math.max(rule.userLimit * 3, rule.userLimit + 20)) {
    return { ok: false, error: "rate_limited_ip" as const };
  }

  if (scope) {
    const { count: scopeCount } = await adminClient
      .from("edge_rate_limit_events")
      .select("id", { count: "exact", head: true })
      .eq("action", action)
      .eq("user_id", userId)
      .eq("scope", scope)
      .gte("created_at", scopeStart);
    if ((scopeCount ?? 0) >= rule.scopeUserLimit) {
      return { ok: false, error: "rate_limited_scope" as const };
    }
  }

  const { error: insertErr } = await adminClient.from("edge_rate_limit_events").insert({
    action,
    user_id: userId,
    ip_hash: ipHash,
    scope,
  });
  if (insertErr) {
    return { ok: false, error: "rate_limit_insert_failed" as const, detail: insertErr.message };
  }
  return { ok: true } as const;
}

async function writeAudit(
  adminClient: ReturnType<typeof createClient>,
  userId: string,
  action: string,
  targetTable: string,
  targetId: string,
  meta: Record<string, unknown>,
  requestId: string,
) {
  await adminClient.from("admin_audit_log").insert({
    action,
    target_table: targetTable,
    target_id: targetId,
    meta: {
      actor_id: userId,
      source: "edge_write_gatekeeper",
      request_id: requestId,
      ...meta,
    },
  });
}

async function recordRiskSignal(
  userClient: ReturnType<typeof createClient>,
  userId: string,
  signalKey: string,
  signalWeight: number,
  ipHash: string | null,
  meta: Record<string, unknown> = {},
) {
  try {
    await userClient.rpc("record_user_risk_signal_v1", {
      p_user_id: userId,
      p_signal_key: signalKey,
      p_signal_weight: signalWeight,
      p_ip_hash: ipHash,
      p_signal_meta: meta,
    });
  } catch (_err) {
    // no-op by design
  }
}

async function trackDeviceFingerprint(
  userClient: ReturnType<typeof createClient>,
  userId: string,
  req: Request,
  ipSalt: string,
) {
  const fp = req.headers.get("x-device-id") ??
    req.headers.get("x-device-fingerprint") ??
    req.headers.get("user-agent");
  const fingerprint = asNonEmptyString(fp);
  if (!fingerprint) return;
  try {
    const fpHash = await sha256Hex(`${ipSalt}:fp:${fingerprint}`);
    await userClient.rpc("record_user_device_fingerprint_v1", {
      p_user_id: userId,
      p_fingerprint: fpHash,
    });
  } catch (_err) {
    // no-op by design
  }
}

serve(async (req) => {
  const headerRequestId = asNonEmptyString(req.headers.get("x-request-id"));
  const requestId = headerRequestId ?? crypto.randomUUID();

  if (req.method !== "POST") {
    return json({ ok: false, error: "method_not_allowed" }, 405, requestId);
  }

  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) {
    return json({ ok: false, error: "missing_jwt" }, 401, requestId);
  }

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
  const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
  const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !SUPABASE_SERVICE_ROLE_KEY) {
    return json({ ok: false, error: "missing_supabase_env" }, 500, requestId);
  }

  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: auth } },
  });
  const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  const { data: userRes, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userRes?.user) {
    return json({ ok: false, error: "not_authenticated" }, 401, requestId);
  }
  const userId = userRes.user.id;
  const accountCreatedAt = asNonEmptyString(userRes.user.created_at);
  const role = String(
    (userRes.user.app_metadata?.role ?? userRes.user.user_metadata?.role ?? "user"),
  ).toLowerCase();
  const allowedRoles = new Set(["user", "owner", "admin"]);
  if (!allowedRoles.has(role)) {
    return json({ ok: false, error: "forbidden_role" }, 403, requestId);
  }

  const body = (await req.json().catch(() => ({}))) as WriteRequest;
  const bodyRequestId = asNonEmptyString(body.request_id);
  const effectiveRequestId = bodyRequestId ?? requestId;
  const action = body.action;
  const payload = body.payload ?? {};

  if (!action || !(action in RATE_RULES)) {
    return json({ ok: false, error: "invalid_action" }, 400, effectiveRequestId);
  }

  const ipSalt = Deno.env.get("EDGE_RATE_LIMIT_SALT") ?? "";
  const ipHash = await sha256Hex(`${ipSalt}:${readClientIp(req)}`);
  await trackDeviceFingerprint(userClient, userId, req, ipSalt);

  const { data: deniedIp } = await adminClient.rpc("is_edge_ip_denied_v1", {
    p_ip_hash: ipHash,
  });
  if (deniedIp === true) {
    await writeAudit(
      adminClient,
      userId,
      "edge.ip_denied",
      "edge_ip_denylist",
      ipHash,
      { role, action, deny_reason: "ip_reputation" },
      effectiveRequestId,
    );
    return json({ ok: false, error: "denied_ip_reputation" }, 403, effectiveRequestId);
  }

  const createdAt = accountCreatedAt ? Date.parse(accountCreatedAt) : NaN;
  if (!Number.isNaN(createdAt)) {
    const ageHours = (Date.now() - createdAt) / 3600000;
    if (ageHours <= 72) {
      await recordRiskSignal(userClient, userId, "new_account", 8, ipHash, {
        source: "write-gatekeeper",
        action,
        age_hours: Math.floor(ageHours),
      });
    }
  }

  if (action === "review_vote_set") {
    const reviewId = asNonEmptyString(payload.review_id);
    if (!reviewId) return json({ ok: false, error: "invalid_review_id" }, 400, effectiveRequestId);

    const rate = await enforceRateLimit(adminClient, action, userId, ipHash, reviewId);
    if (!rate.ok) {
      if (rate.error === "rate_limited_ip") {
        await recordRiskSignal(userClient, userId, "same_ip_burst", 12, ipHash, {
          source: "write-gatekeeper",
          action,
          scope: reviewId,
        });
      }
      return json(rate, 429, effectiveRequestId);
    }

    const { error } = await adminClient.from("review_votes").upsert({
      review_id: reviewId,
      user_id: userId,
      is_helpful: true,
    }, { onConflict: "review_id,user_id" });
    if (error) return json({ ok: false, error: "write_failed", detail: error.message }, 500, effectiveRequestId);

    await writeAudit(adminClient, userId, action, "review_votes", reviewId, { role }, effectiveRequestId);
    return json({ ok: true }, 200, effectiveRequestId);
  }

  if (action === "review_vote_remove") {
    const reviewId = asNonEmptyString(payload.review_id);
    if (!reviewId) return json({ ok: false, error: "invalid_review_id" }, 400, effectiveRequestId);

    const rate = await enforceRateLimit(adminClient, action, userId, ipHash, reviewId);
    if (!rate.ok) {
      if (rate.error === "rate_limited_ip") {
        await recordRiskSignal(userClient, userId, "same_ip_burst", 12, ipHash, {
          source: "write-gatekeeper",
          action,
          scope: reviewId,
        });
      }
      return json(rate, 429, effectiveRequestId);
    }

    const { error } = await adminClient
      .from("review_votes")
      .delete()
      .eq("review_id", reviewId)
      .eq("user_id", userId);
    if (error) return json({ ok: false, error: "write_failed", detail: error.message }, 500, effectiveRequestId);

    await writeAudit(adminClient, userId, action, "review_votes", reviewId, { role }, effectiveRequestId);
    return json({ ok: true }, 200, effectiveRequestId);
  }

  if (action === "visit_add") {
    const businessId = asNonEmptyString(payload.business_id);
    if (!businessId) return json({ ok: false, error: "invalid_business_id" }, 400, effectiveRequestId);

    const rate = await enforceRateLimit(adminClient, action, userId, ipHash, businessId);
    if (!rate.ok) {
      if (rate.error === "rate_limited_ip") {
        await recordRiskSignal(userClient, userId, "same_ip_burst", 12, ipHash, {
          source: "write-gatekeeper",
          action,
          scope: businessId,
        });
      }
      return json(rate, 429, effectiveRequestId);
    }

    const { error } = await adminClient.from("visits").upsert({
      user_id: userId,
      business_id: businessId,
    }, { onConflict: "user_id,business_id" });
    if (error) return json({ ok: false, error: "write_failed", detail: error.message }, 500, effectiveRequestId);

    await writeAudit(adminClient, userId, action, "visits", businessId, { role }, effectiveRequestId);
    return json({ ok: true }, 200, effectiveRequestId);
  }

  if (action === "visit_remove") {
    const businessId = asNonEmptyString(payload.business_id);
    if (!businessId) return json({ ok: false, error: "invalid_business_id" }, 400, effectiveRequestId);

    const rate = await enforceRateLimit(adminClient, action, userId, ipHash, businessId);
    if (!rate.ok) {
      if (rate.error === "rate_limited_ip") {
        await recordRiskSignal(userClient, userId, "same_ip_burst", 12, ipHash, {
          source: "write-gatekeeper",
          action,
          scope: businessId,
        });
      }
      return json(rate, 429, effectiveRequestId);
    }

    const { error } = await adminClient
      .from("visits")
      .delete()
      .eq("user_id", userId)
      .eq("business_id", businessId);
    if (error) return json({ ok: false, error: "write_failed", detail: error.message }, 500, effectiveRequestId);

    await writeAudit(adminClient, userId, action, "visits", businessId, { role }, effectiveRequestId);
    return json({ ok: true }, 200, effectiveRequestId);
  }

  if (action === "menu_photo_delete") {
    const photoId = asNonEmptyString(payload.photo_id);
    if (!photoId) return json({ ok: false, error: "invalid_photo_id" }, 400, effectiveRequestId);

    const { data: photo, error: photoErr } = await adminClient
      .from("menu_item_photos")
      .select("id,menu_item_id")
      .eq("id", photoId)
      .maybeSingle();
    if (photoErr) return json({ ok: false, error: "photo_lookup_failed", detail: photoErr.message }, 500, effectiveRequestId);
    if (!photo) return json({ ok: false, error: "photo_not_found" }, 404, effectiveRequestId);

    const menuItemId = asNonEmptyString(photo.menu_item_id);
    if (!menuItemId) return json({ ok: false, error: "invalid_photo_menu_item" }, 400, effectiveRequestId);

    const { data: menuItem, error: menuErr } = await adminClient
      .from("menu_items")
      .select("business_id")
      .eq("id", menuItemId)
      .maybeSingle();
    if (menuErr) return json({ ok: false, error: "menu_item_lookup_failed", detail: menuErr.message }, 500, effectiveRequestId);
    const businessId = asNonEmptyString(menuItem?.business_id);
    if (!businessId) return json({ ok: false, error: "business_not_found" }, 404, effectiveRequestId);

    const { data: isAdminRaw } = await userClient.rpc("is_admin");
    const isAdmin = isAdminRaw === true || (
      typeof isAdminRaw === "object" &&
      isAdminRaw !== null &&
      (isAdminRaw as Record<string, unknown>).is_admin === true
    );

    let canWrite = isAdmin;
    if (!canWrite) {
      try {
        const { data: canAccessRaw, error: canAccessErr } = await userClient.rpc(
          "can_access_business_v1",
          { p_business_id: businessId },
        );
        canWrite = !canAccessErr && canAccessRaw === true;
      } catch (_err) {
        canWrite = false;
      }
    }
    if (!canWrite) return json({ ok: false, error: "forbidden" }, 403, effectiveRequestId);

    const rate = await enforceRateLimit(adminClient, action, userId, ipHash, photoId);
    if (!rate.ok) {
      if (rate.error === "rate_limited_ip") {
        await recordRiskSignal(userClient, userId, "same_ip_burst", 12, ipHash, {
          source: "write-gatekeeper",
          action,
          scope: photoId,
        });
      }
      return json(rate, 429, effectiveRequestId);
    }

    const { error } = await adminClient
      .from("menu_item_photos")
      .delete()
      .eq("id", photoId);
    if (error) return json({ ok: false, error: "write_failed", detail: error.message }, 500, effectiveRequestId);

    await writeAudit(adminClient, userId, action, "menu_item_photos", photoId, {
      role,
      business_id: businessId,
      menu_item_id: menuItemId,
    }, effectiveRequestId);
    return json({ ok: true }, 200, effectiveRequestId);
  }

  if (action === "owner_price_suggestion_approve" || action === "owner_price_suggestion_reject") {
    const suggestionId = asNonEmptyString(payload.suggestion_id);
    if (!suggestionId) return json({ ok: false, error: "invalid_suggestion_id" }, 400, effectiveRequestId);
    if (role !== "owner" && role !== "admin") {
      return json({ ok: false, error: "forbidden_role" }, 403, effectiveRequestId);
    }

    const { data: suggestion, error: suggestionErr } = await adminClient
      .from("menu_item_price_suggestions")
      .select("id,menu_item_id")
      .eq("id", suggestionId)
      .maybeSingle();
    if (suggestionErr) {
      return json({ ok: false, error: "suggestion_lookup_failed", detail: suggestionErr.message }, 500, effectiveRequestId);
    }
    if (!suggestion) return json({ ok: false, error: "suggestion_not_found" }, 404, effectiveRequestId);

    const menuItemId = asNonEmptyString(suggestion.menu_item_id);
    if (!menuItemId) return json({ ok: false, error: "menu_item_not_found" }, 404, effectiveRequestId);
    const { data: menuItem, error: menuErr } = await adminClient
      .from("menu_items")
      .select("business_id")
      .eq("id", menuItemId)
      .maybeSingle();
    if (menuErr) return json({ ok: false, error: "menu_item_lookup_failed", detail: menuErr.message }, 500, effectiveRequestId);

    const businessId = asNonEmptyString(menuItem?.business_id);
    if (!businessId) return json({ ok: false, error: "business_not_found" }, 404, effectiveRequestId);

    let canWrite = role === "admin";
    if (!canWrite) {
      const { data: canAccessRaw, error: canAccessErr } = await userClient.rpc(
        "can_access_business_v1",
        { p_business_id: businessId },
      );
      canWrite = !canAccessErr && canAccessRaw === true;
    }
    if (!canWrite) return json({ ok: false, error: "forbidden" }, 403, effectiveRequestId);

    const rate = await enforceRateLimit(adminClient, action, userId, ipHash, suggestionId);
    if (!rate.ok) {
      if (rate.error === "rate_limited_ip") {
        await recordRiskSignal(userClient, userId, "same_ip_burst", 12, ipHash, {
          source: "write-gatekeeper",
          action,
          scope: suggestionId,
        });
      }
      return json(rate, 429, effectiveRequestId);
    }

    if (action === "owner_price_suggestion_approve") {
      const { error } = await userClient.rpc("owner_approve_price_suggestion_v1", {
        p_suggestion_id: suggestionId,
      });
      if (error) return json({ ok: false, error: "write_failed", detail: error.message }, 500, effectiveRequestId);
      await writeAudit(
        adminClient,
        userId,
        action,
        "menu_item_price_suggestions",
        suggestionId,
        { role, business_id: businessId },
        effectiveRequestId,
      );
      return json({ ok: true }, 200, effectiveRequestId);
    }

    const reason = asNonEmptyString(payload.reason);
    if (!reason || reason.length < 3) {
      return json({ ok: false, error: "invalid_reason" }, 400, effectiveRequestId);
    }
    const { error } = await userClient.rpc("owner_reject_price_suggestion_v1", {
      p_suggestion_id: suggestionId,
      p_reason: reason,
    });
    if (error) return json({ ok: false, error: "write_failed", detail: error.message }, 500, effectiveRequestId);
    await writeAudit(
      adminClient,
      userId,
      action,
      "menu_item_price_suggestions",
      suggestionId,
      { role, business_id: businessId, reason },
      effectiveRequestId,
    );
    return json({ ok: true }, 200, effectiveRequestId);
  }

  return json({ ok: false, error: "unsupported_action" }, 400, effectiveRequestId);
});

