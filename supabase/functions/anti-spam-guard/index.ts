import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

type Rule = {
  windowSeconds: number;
  userLimit: number;
  ipLimit: number;
  scopeWindowSeconds?: number;
  scopeUserLimit?: number;
  newUserDays?: number;
  newUserLimit?: number;
};

const RULES: Record<string, Rule> = {
  review_submit: {
    windowSeconds: 24 * 60 * 60,
    userLimit: 10,
    ipLimit: 30,
    scopeWindowSeconds: 24 * 60 * 60,
    scopeUserLimit: 1,
    newUserDays: 7,
    newUserLimit: 3,
  },
  price_verify: {
    windowSeconds: 60,
    userLimit: 6,
    ipLimit: 20,
    scopeWindowSeconds: 10 * 60,
    scopeUserLimit: 1,
  },
  photo_upload: {
    windowSeconds: 24 * 60 * 60,
    userLimit: 20,
    ipLimit: 60,
  },
  report_submit: {
    windowSeconds: 60 * 60,
    userLimit: 12,
    ipLimit: 40,
    scopeWindowSeconds: 24 * 60 * 60,
    scopeUserLimit: 1,
  },
};

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
  const bytes = Array.from(new Uint8Array(digest));
  return bytes.map((b) => b.toString(16).padStart(2, "0")).join("");
}

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
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !SUPABASE_SERVICE_ROLE_KEY) {
    return json({ ok: false, error: "missing_supabase_env" }, 500);
  }

  const jwtClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: auth } },
  });
  const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  const { data: userRes, error: userErr } = await jwtClient.auth.getUser();
  if (userErr || !userRes?.user) {
    return json({ ok: false, error: "not_authenticated" }, 401);
  }
  const userId = userRes.user.id;

  const body = (await req.json().catch(() => ({}))) as {
    action?: string;
    scope?: string;
    dryRun?: boolean;
  };

  const action = (body.action ?? "").trim();
  const scope = (body.scope ?? "").trim() || null;
  const dryRun = body.dryRun === true;

  const rule = RULES[action];
  if (!rule) {
    return json({ ok: false, error: "unknown_action" }, 400);
  }

  const rawIp = readClientIp(req);
  const ipSalt = Deno.env.get("EDGE_RATE_LIMIT_SALT") ?? "yeedoy_default_salt";
  const ipHash = await sha256Hex(`${ipSalt}:${rawIp}`);

  const now = new Date();
  const windowStart = new Date(now.getTime() - rule.windowSeconds * 1000).toISOString();

  let userWindowLimit = rule.userLimit;
  if ((rule.newUserDays ?? 0) > 0 && (rule.newUserLimit ?? 0) > 0) {
    const { data: profile } = await adminClient
      .from("user_profiles")
      .select("created_at")
      .eq("user_id", userId)
      .maybeSingle();
    const createdAt = profile?.created_at ? new Date(profile.created_at) : null;
    if (createdAt) {
      const ageMs = now.getTime() - createdAt.getTime();
      const ageDays = ageMs / (24 * 60 * 60 * 1000);
      if (ageDays <= (rule.newUserDays ?? 0)) {
        userWindowLimit = Math.min(userWindowLimit, rule.newUserLimit ?? userWindowLimit);
      }
    }
  }

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

  const currentUserCount = userCount ?? 0;
  const currentIpCount = ipCount ?? 0;

  if (currentUserCount >= userWindowLimit) {
    return json({
      ok: false,
      error: "rate_limited_user",
      action,
      window_seconds: rule.windowSeconds,
      retry_after_seconds: rule.windowSeconds,
      remaining: 0,
    }, 429);
  }

  if (currentIpCount >= rule.ipLimit) {
    return json({
      ok: false,
      error: "rate_limited_ip",
      action,
      window_seconds: rule.windowSeconds,
      retry_after_seconds: rule.windowSeconds,
      remaining: 0,
    }, 429);
  }

  if (scope && (rule.scopeWindowSeconds ?? 0) > 0 && (rule.scopeUserLimit ?? 0) > 0) {
    const scopeStart = new Date(now.getTime() - (rule.scopeWindowSeconds ?? 0) * 1000).toISOString();
    const { count: scopeCount } = await adminClient
      .from("edge_rate_limit_events")
      .select("id", { count: "exact", head: true })
      .eq("action", action)
      .eq("user_id", userId)
      .eq("scope", scope)
      .gte("created_at", scopeStart);
    if ((scopeCount ?? 0) >= (rule.scopeUserLimit ?? 0)) {
      return json({
        ok: false,
        error: "rate_limited_scope",
        action,
        window_seconds: rule.scopeWindowSeconds,
        retry_after_seconds: rule.scopeWindowSeconds,
        remaining: 0,
      }, 429);
    }
  }

  if (!dryRun) {
    const { error: insertErr } = await adminClient.from("edge_rate_limit_events").insert({
      action,
      user_id: userId,
      ip_hash: ipHash,
      scope,
    });
    if (insertErr) {
      return json({ ok: false, error: "rate_limit_insert_failed", detail: insertErr.message }, 500);
    }

    const cleanupBefore = new Date(now.getTime() - 14 * 24 * 60 * 60 * 1000).toISOString();
    await adminClient
      .from("edge_rate_limit_events")
      .delete()
      .lt("created_at", cleanupBefore);
  }

  return json({
    ok: true,
    action,
    window_seconds: rule.windowSeconds,
    remaining: Math.max(0, userWindowLimit - currentUserCount - (dryRun ? 0 : 1)),
  });
});

