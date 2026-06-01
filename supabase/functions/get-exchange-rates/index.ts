import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ALLOWED_ORIGINS = [
  "https://yeedoy.com",
  "https://panel.yeedoy.com",
  "http://localhost:3000",
  "http://localhost:3001",
];

function corsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get("origin") ?? "";
  const headers: Record<string, string> = {
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type",
    "Vary": "Origin",
  };
  if (ALLOWED_ORIGINS.includes(origin)) {
    headers["Access-Control-Allow-Origin"] = origin;
  }
  // Non-allowed origins receive no Access-Control-Allow-Origin header
  return headers;
}

function json(data: unknown, status = 200, req?: Request) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...(req ? corsHeaders(req) : {}),
    },
  });
}

const STALE_HOURS = 8; // refresh rates if older than 8 hours

// ─── TCMB XML parser (ForexSelling per currency) ─────────────────────────────

function parseForexSelling(xml: string, currencyCode: string): number | null {
  // Find the <Currency> block matching CurrencyCode="USD" etc.
  const blockRx = new RegExp(
    `CurrencyCode="${currencyCode}"[\\s\\S]*?</Currency>`,
  );
  const block = xml.match(blockRx);
  if (!block) return null;
  const rateMatch = block[0].match(/<ForexSelling>([\d.]+)<\/ForexSelling>/);
  return rateMatch ? parseFloat(rateMatch[1]) : null;
}

async function fetchTcmb(): Promise<{ USD: number; EUR: number } | null> {
  try {
    const res = await fetch("https://www.tcmb.gov.tr/kurlar/today.xml", {
      signal: AbortSignal.timeout(10_000),
      headers: { "User-Agent": "Yeedoy/1.0" },
    });
    if (!res.ok) return null;
    const xml = await res.text();
    const usd = parseForexSelling(xml, "USD");
    const eur = parseForexSelling(xml, "EUR");
    if (!usd || !eur) return null;
    return { USD: usd, EUR: eur };
  } catch {
    return null;
  }
}

// ─── Handler ─────────────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders(req) });
  }

  const respond = (data: unknown, status = 200) => json(data, status, req);

  // POST requires auth (triggers a TCMB refresh + DB upsert).
  // GET is a read-only cache read — allowed without auth for backward compatibility.
  if (req.method === "POST") {
    const exchangeCronSecret = Deno.env.get("EXCHANGE_CRON_SECRET");
    const authHeader = req.headers.get("Authorization") ?? "";
    if (exchangeCronSecret && authHeader !== `Bearer ${exchangeCronSecret}`) {
      return respond({ ok: false, error: "unauthorized" }, 401);
    }
  }

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
  const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!SUPABASE_URL || !SERVICE_ROLE) {
    return respond({ ok: false, error: "missing_env" }, 500);
  }

  const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE);

  // ── 1. Check DB cache ─────────────────────────────────────────────────────

  const { data: cached } = await adminClient
    .from("exchange_rates")
    .select("currency, try_rate, fetched_at")
    .in("currency", ["USD", "EUR"]);

  if (cached && cached.length === 2) {
    const oldest = cached.reduce((a, b) =>
      new Date(a.fetched_at) < new Date(b.fetched_at) ? a : b
    );
    const ageHours =
      (Date.now() - new Date(oldest.fetched_at).getTime()) / 3_600_000;

    if (ageHours < STALE_HOURS) {
      const rates: Record<string, number> = {};
      for (const row of cached) rates[row.currency] = parseFloat(row.try_rate);
      return respond({
        ok: true,
        source: "cache",
        fetched_at: oldest.fetched_at,
        rates,
      });
    }
  }

  // ── 2. Fetch from TCMB ────────────────────────────────────────────────────

  const fresh = await fetchTcmb();

  if (!fresh) {
    // TCMB unreachable — return last known rates (weekend/holiday)
    if (cached && cached.length > 0) {
      const rates: Record<string, number> = {};
      for (const row of cached) rates[row.currency] = parseFloat(row.try_rate);
      const oldest = cached.reduce((a, b) =>
        new Date(a.fetched_at) < new Date(b.fetched_at) ? a : b
      );
      return respond({
        ok: true,
        source: "cache_stale",
        fetched_at: oldest.fetched_at,
        rates,
      });
    }
    return respond({ ok: false, error: "tcmb_unavailable" }, 503);
  }

  // ── 3. Store in DB ────────────────────────────────────────────────────────

  const now = new Date().toISOString();
  await adminClient.from("exchange_rates").upsert([
    { currency: "USD", try_rate: fresh.USD, fetched_at: now },
    { currency: "EUR", try_rate: fresh.EUR, fetched_at: now },
  ]);

  return respond({
    ok: true,
    source: "tcmb",
    fetched_at: now,
    rates: { USD: fresh.USD, EUR: fresh.EUR },
  });
});
