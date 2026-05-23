import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * Enforces a per-user rate limit using the check_rate_limit_v1 RPC.
 * Throws a Response (429) if the user exceeds their quota.
 *
 * @param userId   authenticated user ID
 * @param fnName   edge function name (used as part of the bucket key)
 * @param max      max requests per window (default: 20)
 * @param window   Postgres interval string (default: '1 hour')
 */
export async function enforceRateLimit(
  userId: string,
  fnName: string,
  max = 20,
  window = "01:00:00",
): Promise<void> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) return; // fail open if env not set

  const admin = createClient(supabaseUrl, serviceKey);
  const key = `rl:${fnName}:${userId}`;

  const { data: allowed, error } = await admin.rpc("check_rate_limit_v1", {
    p_key: key,
    p_max: max,
    p_window: window,
  });

  if (error) return; // fail open on DB error

  if (!allowed) {
    throw new Response(
      JSON.stringify({ ok: false, error: "rate_limit_exceeded" }),
      {
        status: 429,
        headers: {
          "Content-Type": "application/json",
          "Retry-After": "3600",
        },
      },
    );
  }
}
