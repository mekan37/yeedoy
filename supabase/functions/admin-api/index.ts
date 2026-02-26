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

type AdminAction = "apply_user_safety_action" | "rpc_write";

type AdminRequest = {
  action?: AdminAction;
  reason?: string;
  payload?: Record<string, unknown>;
  request_id?: string;
};

function text(value: unknown): string {
  return String(value ?? "").trim();
}

function asInt(value: unknown, fallback: number): number {
  const parsed = Number.parseInt(String(value ?? ""), 10);
  return Number.isFinite(parsed) ? parsed : fallback;
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

const ALLOWED_WRITE_RPCS = new Set<string>([
  "admin_assign_report_v1",
  "admin_unassign_report_v1",
  "admin_update_report_v2",
  "admin_bulk_update_reports_status_v2",
  "apply_auto_moderation_rules_v1",
  "admin_assign_owner_claim_v1",
  "admin_unassign_owner_claim_v1",
  "admin_decide_owner_claim_v1",
  "admin_bulk_decide_owner_claims_v1",
  "admin_assign_business_suggestion_v1",
  "admin_unassign_business_suggestion_v1",
  "admin_approve_business_suggestion_v1",
  "admin_reject_business_suggestion_v1",
  "admin_bulk_reject_business_suggestions_v1",
  "admin_link_suggestion_to_business_v1",
  "admin_approve_suspended_claim_v1",
  "admin_reject_suspended_claim_v1",
  "admin_bulk_replace_text_v1",
  "admin_create_incident_update_v1",
  "admin_approve_business_submission_v1",
  "admin_reject_business_submission_v1",
  "admin_update_business_v1",
  "admin_merge_businesses_v1",
  "log_admin_action_v1",
  "admin_approve_price_suggestion_v1",
  "admin_reject_price_suggestion_v1",
  "admin_upsert_sponsorship_package_v1",
  "admin_create_sponsorship_v1",
  "admin_set_sponsorship_status_v1",
  "admin_update_sponsorship_lead_status_v1",
  "admin_set_business_verified_v1",
  "admin_decide_moderation_appeal_v1",
]);

const COMMUNITY_MOD_ALLOWED_RPCS = new Set<string>([
  "admin_assign_report_v1",
  "admin_unassign_report_v1",
  "admin_update_report_v2",
  "admin_bulk_update_reports_status_v2",
  "apply_auto_moderation_rules_v1",
  "admin_decide_moderation_appeal_v1",
]);

serve(async (req) => {
  const headerRequestId = text(req.headers.get("x-request-id"));
  const requestId = headerRequestId || crypto.randomUUID();

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

  const role = String(
    (userRes.user.app_metadata?.role ?? userRes.user.user_metadata?.role ?? "user"),
  ).toLowerCase();
  if (role !== "admin" && role !== "community_mod") {
    return json({ ok: false, error: "forbidden_role" }, 403, requestId);
  }

  const body = (await req.json().catch(() => ({}))) as AdminRequest;
  const effectiveRequestId = text(body.request_id) || requestId;
  const action = body.action;
  const reason = text(body.reason);
  const payload = body.payload ?? {};

  const ipSalt = Deno.env.get("EDGE_RATE_LIMIT_SALT") ?? "yeedoy_default_salt";
  const ipHash = await sha256Hex(`${ipSalt}:${readClientIp(req)}`);
  const { data: deniedIp } = await adminClient.rpc("is_edge_ip_denied_v1", {
    p_ip_hash: ipHash,
  });
  if (deniedIp === true) {
    await adminClient.from("admin_audit_log").insert({
      action: "admin_api.ip_denied",
      target_table: "edge_ip_denylist",
      target_id: ipHash,
      meta: {
        actor_id: userRes.user.id,
        actor_role: role,
        source: "admin-api",
        request_id: effectiveRequestId,
      },
    });
    return json({ ok: false, error: "denied_ip_reputation" }, 403, effectiveRequestId);
  }

  if (!action) return json({ ok: false, error: "missing_action" }, 400, effectiveRequestId);
  if (!reason || reason.length < 3) return json({ ok: false, error: "reason_required" }, 400, effectiveRequestId);

  if (action === "apply_user_safety_action") {
    if (role !== "admin") {
      return json({ ok: false, error: "forbidden_role" }, 403, effectiveRequestId);
    }

    const userId = text(payload.user_id);
    const safetyAction = text(payload.safety_action);
    const minutes = Math.max(1, asInt(payload.minutes, 60));

    if (!userId) return json({ ok: false, error: "missing_user_id" }, 400, effectiveRequestId);
    if (!safetyAction) return json({ ok: false, error: "missing_safety_action" }, 400, effectiveRequestId);

    const { data, error } = await userClient.rpc("admin_apply_user_safety_action_v1", {
      p_user_id: userId,
      p_action: safetyAction,
      p_minutes: minutes,
      p_reason: reason,
    });
    if (error) return json({ ok: false, error: "admin_rpc_failed", detail: error.message }, 500, effectiveRequestId);
    if (data && typeof data === "object" && (data as Record<string, unknown>).ok !== true) {
      return json(data, 400, effectiveRequestId);
    }

    return json({ ok: true }, 200, effectiveRequestId);
  }

  if (action === "rpc_write") {
    const rpcName = text(payload.rpc);
    const targetType = text(payload.target_type);
    const targetId = text(payload.target_id);
    const params = (payload.params && typeof payload.params === "object")
      ? payload.params as Record<string, unknown>
      : {};

    if (!rpcName) return json({ ok: false, error: "missing_rpc" }, 400, effectiveRequestId);
    if (!ALLOWED_WRITE_RPCS.has(rpcName)) {
      return json({ ok: false, error: "rpc_not_allowed" }, 403, effectiveRequestId);
    }
    if (role === "community_mod" && !COMMUNITY_MOD_ALLOWED_RPCS.has(rpcName)) {
      return json({ ok: false, error: "rpc_forbidden_for_role" }, 403, effectiveRequestId);
    }

    const { data, error } = await userClient.rpc(rpcName, params);
    if (error) return json({ ok: false, error: "admin_rpc_failed", detail: error.message }, 500, effectiveRequestId);

    await adminClient.from("admin_audit_log").insert({
      action: `admin.rpc.${rpcName}`,
      target_table: targetType || "admin_rpc",
      target_id: targetId || rpcName,
      meta: {
        actor_id: userRes.user.id,
        actor_role: role,
        source: "admin-api",
        reason,
        rpc: rpcName,
        request_id: effectiveRequestId,
      },
    });

    return json({ ok: true, data }, 200, effectiveRequestId);
  }

  return json({ ok: false, error: "unsupported_action" }, 400, effectiveRequestId);
});

