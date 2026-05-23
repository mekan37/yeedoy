import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

const RATE_LIMIT_PER_DAY = 1; // max email campaigns per business per day
const RESEND_BATCH_DELAY_MS = 20; // ~50 emails/sec Resend rate limit

serve(async (req) => {
  if (req.method !== "POST") return json({ ok: false, error: "method_not_allowed" }, 405);

  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) return json({ ok: false, error: "missing_jwt" }, 401);

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
  const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");

  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return json({ ok: false, error: "missing_env" }, 500);
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const callerClient = createClient(SUPABASE_URL, Deno.env.get("SUPABASE_ANON_KEY") ?? "", {
    global: { headers: { authorization: auth } },
  });

  // Verify caller is authenticated
  const { data: { user }, error: authError } = await callerClient.auth.getUser();
  if (authError || !user) return json({ ok: false, error: "unauthorized" }, 401);

  const body = await req.json().catch(() => null);
  const campaignId: string | undefined = body?.campaign_id;
  if (!campaignId) return json({ ok: false, error: "missing_campaign_id" }, 400);

  // Fetch campaign and verify ownership
  const { data: campaign, error: campErr } = await supabase
    .from("email_campaigns")
    .select("id, business_id, subject, html_body, target_segment, sent_at")
    .eq("id", campaignId)
    .single();

  if (campErr || !campaign) return json({ ok: false, error: "campaign_not_found" }, 404);
  if (campaign.sent_at) return json({ ok: false, error: "already_sent" }, 409);

  // Verify caller owns the business
  const { count: ownerCount } = await supabase
    .from("business_claims")
    .select("id", { count: "exact", head: true })
    .eq("business_id", campaign.business_id)
    .eq("user_id", user.id)
    .eq("status", "approved");

  if (!ownerCount) return json({ ok: false, error: "not_authorized" }, 403);

  // Rate limit: 1 email campaign per business per day
  const dayStart = new Date();
  dayStart.setUTCHours(0, 0, 0, 0);

  const { count: sentToday } = await supabase
    .from("email_campaigns")
    .select("id", { count: "exact", head: true })
    .eq("business_id", campaign.business_id)
    .not("sent_at", "is", null)
    .gte("sent_at", dayStart.toISOString());

  if ((sentToday ?? 0) >= RATE_LIMIT_PER_DAY) {
    return json({ ok: false, error: "rate_limit_exceeded" }, 429);
  }

  // Fetch business info for sender display name
  const { data: business } = await supabase
    .from("businesses")
    .select("name")
    .eq("id", campaign.business_id)
    .single();

  const fromName = business?.name ?? "Yeedoy";
  const fromEmail = "noreply@yeedoy.com";

  // Fetch subscribed follower emails based on segment
  let followersQuery = supabase
    .from("business_follows")
    .select("follower_id, profiles!inner(email)")
    .eq("business_id", campaign.business_id)
    .eq("is_subscribed_email", true);

  if (campaign.target_segment === "new_30d") {
    const cutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
    followersQuery = followersQuery.gte("created_at", cutoff);
  } else if (campaign.target_segment === "inactive_30d") {
    const cutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
    followersQuery = followersQuery.lt("created_at", cutoff);
  }

  const { data: followers } = await followersQuery;
  const emails: string[] = (followers ?? [])
    .map((f: Record<string, unknown>) => {
      const profile = f["profiles"] as Record<string, unknown> | null;
      return profile?.["email"] as string | null;
    })
    .filter((e): e is string => !!e && e.includes("@"));

  if (emails.length === 0) {
    // Mark as sent with 0 count — no recipients
    await supabase
      .from("email_campaigns")
      .update({ sent_at: new Date().toISOString(), sent_count: 0 })
      .eq("id", campaignId);
    return json({ ok: true, sent_count: 0 });
  }

  // Append unsubscribe footer to html_body
  const unsubscribeNote = `
    <p style="margin-top:24px;font-size:12px;color:#888;text-align:center;">
      Bu e-postayı almak istemiyorsanız,
      <a href="https://yeedoy.com/settings/notifications" style="color:#7F1D1D;">
        aboneliğinizi iptal edebilirsiniz
      </a>.
    </p>`;
  const fullHtml = campaign.html_body + unsubscribeNote;

  let sentCount = 0;

  if (!RESEND_API_KEY) {
    // No Resend key — log and skip (dev/staging)
    console.warn("RESEND_API_KEY not set; skipping email send for", emails.length, "recipients");
    sentCount = emails.length;
  } else {
    // Send in batches (Resend supports batch endpoint)
    const BATCH_SIZE = 50;
    for (let i = 0; i < emails.length; i += BATCH_SIZE) {
      const batch = emails.slice(i, i + BATCH_SIZE);
      const messages = batch.map((to) => ({
        from: `${fromName} <${fromEmail}>`,
        to,
        subject: campaign.subject,
        html: fullHtml,
      }));

      const resp = await fetch("https://api.resend.com/emails/batch", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${RESEND_API_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(messages),
      });

      if (resp.ok) {
        sentCount += batch.length;
      } else {
        const errText = await resp.text();
        console.error("Resend batch error:", resp.status, errText);
      }

      // Respect Resend rate limit (~50/sec)
      if (i + BATCH_SIZE < emails.length) {
        await new Promise((r) => setTimeout(r, RESEND_BATCH_DELAY_MS));
      }
    }
  }

  // Update campaign record
  await supabase
    .from("email_campaigns")
    .update({ sent_at: new Date().toISOString(), sent_count: sentCount })
    .eq("id", campaignId);

  return json({ ok: true, sent_count: sentCount });
});
