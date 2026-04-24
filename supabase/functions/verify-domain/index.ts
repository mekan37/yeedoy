import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

/**
 * Verify a custom domain by checking for the DNS TXT record.
 *
 * Expects a POST body: { business_id: string, domain: string }
 * Must be called by an authenticated user who owns the business.
 *
 * Steps:
 *  1. Look up the pending custom_domains row for this business.
 *  2. Query Cloudflare DNS-over-HTTPS for the TXT record on the domain.
 *  3. If the expected token is found, set verified_at = now() and is_active = true.
 */
serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return json({ error: "unauthorized" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });

  let body: { business_id?: string; domain?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "invalid_json" }, 400);
  }

  const { business_id, domain } = body;
  if (!business_id || !domain) {
    return json({ error: "missing_fields" }, 400);
  }

  // Fetch expected TXT token from the database
  const { data: row, error: dbError } = await supabase
    .from("custom_domains")
    .select("dns_txt_token, verified_at")
    .eq("business_id", business_id)
    .eq("domain", domain.toLowerCase().trim())
    .maybeSingle();

  if (dbError || !row) {
    return json({ error: "domain_not_found" }, 404);
  }

  if (row.verified_at) {
    return json({ verified: true, already_verified: true });
  }

  // Query Cloudflare DNS-over-HTTPS for TXT records
  const dnsUrl = `https://cloudflare-dns.com/dns-query?name=${encodeURIComponent(domain)}&type=TXT`;
  let txtRecords: string[] = [];
  try {
    const dnsRes = await fetch(dnsUrl, {
      headers: { Accept: "application/dns-json" },
    });
    if (dnsRes.ok) {
      const dnsJson = await dnsRes.json() as {
        Answer?: Array<{ type: number; data: string }>;
      };
      txtRecords = (dnsJson.Answer ?? [])
        .filter((a) => a.type === 16) // TXT record type
        .map((a) => a.data.replace(/^"|"$/g, "")); // strip surrounding quotes
    }
  } catch {
    return json({ error: "dns_lookup_failed" }, 502);
  }

  const expectedToken = row.dns_txt_token as string;
  const found = txtRecords.some((r) => r.includes(expectedToken));

  if (!found) {
    return json({
      verified: false,
      error: "txt_record_not_found",
      expected: expectedToken,
      found_records: txtRecords,
    });
  }

  // Mark as verified
  const { error: updateError } = await supabase
    .from("custom_domains")
    .update({ verified_at: new Date().toISOString(), is_active: true })
    .eq("business_id", business_id)
    .eq("domain", domain.toLowerCase().trim());

  if (updateError) {
    return json({ error: "update_failed" }, 500);
  }

  return json({ verified: true });
});
