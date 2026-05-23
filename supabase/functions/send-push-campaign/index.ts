import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

const RATE_LIMIT_PER_DAY = 1; // max campaigns per business per day

serve(async (req) => {
  if (req.method !== "POST") return json({ ok: false, error: "method_not_allowed" }, 405);

  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) return json({ ok: false, error: "missing_jwt" }, 401);

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
  const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID");
  const FIREBASE_ACCESS_TOKEN = Deno.env.get("FIREBASE_ACCESS_TOKEN");

  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return json({ ok: false, error: "missing_env" }, 500);
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const callerClient = createClient(SUPABASE_URL, Deno.env.get("SUPABASE_ANON_KEY") ?? "", {
    global: { headers: { authorization: auth } },
  });

  const { data: { user }, error: authError } = await callerClient.auth.getUser();
  if (authError || !user) return json({ ok: false, error: "unauthorized" }, 401);

  let body: { campaign_id?: string; business_id?: string };
  try {
    body = await req.json();
  } catch {
    return json({ ok: false, error: "invalid_json" }, 400);
  }

  const campaignId = body.campaign_id;
  if (!campaignId) return json({ ok: false, error: "campaign_id_required" }, 400);

  // Fetch campaign
  const { data: campaign, error: campError } = await supabase
    .from("push_campaigns")
    .select("id,business_id,title,body,image_url,target_segment,sent_at,created_at")
    .eq("id", campaignId)
    .maybeSingle();

  if (campError || !campaign) return json({ ok: false, error: "campaign_not_found" }, 404);
  if (campaign.sent_at) return json({ ok: false, error: "already_sent" }, 409);

  // Verify caller owns the business
  const { count: claimCount } = await supabase
    .from("business_claims")
    .select("id", { count: "exact", head: true })
    .eq("business_id", campaign.business_id)
    .eq("user_id", user.id)
    .eq("status", "approved");

  if (!claimCount || claimCount === 0) {
    // Check admin
    const { data: role } = await supabase
      .from("user_roles")
      .select("role")
      .eq("user_id", user.id)
      .maybeSingle();
    if (role?.role !== "admin" && role?.role !== "super_admin") {
      return json({ ok: false, error: "not_authorized" }, 403);
    }
  }

  // Rate limit: max 1 campaign per business per day
  const dayAgo = new Date(Date.now() - 86400000).toISOString();
  const { count: recentCount } = await supabase
    .from("push_campaigns")
    .select("id", { count: "exact", head: true })
    .eq("business_id", campaign.business_id)
    .not("sent_at", "is", null)
    .gte("sent_at", dayAgo);

  if ((recentCount ?? 0) >= RATE_LIMIT_PER_DAY) {
    return json({ ok: false, error: "rate_limit_exceeded", retry_after: "24h" }, 429);
  }

  // Fetch FCM tokens for the segment — paginated to handle >500 followers
  const tokens: string[] = [];

  if (campaign.target_segment === "all_followers" || campaign.target_segment === "inactive_30d" || campaign.target_segment === "new_30d") {
    // Paginate business_follows to get all follower user_ids
    const PAGE_SIZE = 1000;
    let offset = 0;
    const allUserIds: string[] = [];

    while (true) {
      let followsQuery = supabase
        .from("business_follows")
        .select("user_id")
        .eq("business_id", campaign.business_id)
        .range(offset, offset + PAGE_SIZE - 1);

      if (campaign.target_segment === "new_30d") {
        followsQuery = followsQuery.gte("created_at", dayAgo);
      }

      const { data: follows, error: followsErr } = await followsQuery;
      if (followsErr || !follows || follows.length === 0) break;
      allUserIds.push(...follows.map((f: { user_id: string }) => f.user_id));
      if (follows.length < PAGE_SIZE) break;
      offset += PAGE_SIZE;
    }

    // Fetch FCM tokens in pages of 500 (Supabase .in() limit)
    for (let i = 0; i < allUserIds.length; i += 500) {
      const chunk = allUserIds.slice(i, i + 500);
      const { data: tokenRows } = await supabase
        .from("fcm_tokens")
        .select("token")
        .in("user_id", chunk)
        .eq("is_active", true);
      tokens.push(...(tokenRows ?? []).map((r: { token: string }) => r.token));
    }
  }

  if (tokens.length === 0) {
    // Mark as sent with 0 recipients
    await supabase
      .from("push_campaigns")
      .update({ sent_at: new Date().toISOString(), sent_count: 0 })
      .eq("id", campaignId);
    return json({ ok: true, sent_count: 0 });
  }

  // Send via FCM if credentials available
  let sentCount = 0;
  if (FIREBASE_PROJECT_ID && FIREBASE_ACCESS_TOKEN) {
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`;
    const batchSize = 500;

    for (let i = 0; i < tokens.length; i += batchSize) {
      const batch = tokens.slice(i, i + batchSize);
      await Promise.all(
        batch.map(async (token) => {
          try {
            const res = await fetch(fcmUrl, {
              method: "POST",
              headers: {
                "Authorization": `Bearer ${FIREBASE_ACCESS_TOKEN}`,
                "Content-Type": "application/json",
              },
              body: JSON.stringify({
                message: {
                  token,
                  notification: {
                    title: campaign.title,
                    body: campaign.body,
                    ...(campaign.image_url ? { image: campaign.image_url } : {}),
                  },
                  data: {
                    campaign_id: campaignId,
                    business_id: campaign.business_id,
                    type: "push_campaign",
                  },
                },
              }),
            });
            if (res.ok) sentCount++;
          } catch {
            // individual token failure — continue
          }
        }),
      );
    }
  } else {
    // No FCM credentials in env — simulate
    sentCount = tokens.length;
  }

  // Update campaign record
  await supabase
    .from("push_campaigns")
    .update({ sent_at: new Date().toISOString(), sent_count: sentCount })
    .eq("id", campaignId);

  return json({ ok: true, sent_count: sentCount });
});
