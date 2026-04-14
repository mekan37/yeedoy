import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
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
  const bytes = Array.from(new Uint8Array(digest));
  return bytes.map((b) => b.toString(16).padStart(2, "0")).join("");
}

function inferExt(mime: string): string | null {
  switch (mime) {
    case "image/jpeg":
      return "jpg";
    case "image/png":
      return "png";
    case "image/webp":
      return "webp";
    default:
      return null;
  }
}

function isTrue(value: string): boolean {
  const v = value.trim().toLowerCase();
  return v === "1" || v === "true" || v === "yes" || v === "on";
}

function parseImageDimensions(bytes: Uint8Array, mime: string): { width: number; height: number } | null {
  if (mime === "image/png") {
    if (bytes.length < 24) return null;
    if (bytes[0] !== 0x89 || bytes[1] !== 0x50 || bytes[2] !== 0x4e || bytes[3] !== 0x47) return null;
    const dv = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
    const width = dv.getUint32(16, false);
    const height = dv.getUint32(20, false);
    return { width, height };
  }

  if (mime === "image/webp") {
    if (bytes.length < 30) return null;
    const riff = String.fromCharCode(...bytes.slice(0, 4));
    const webp = String.fromCharCode(...bytes.slice(8, 12));
    if (riff !== "RIFF" || webp !== "WEBP") return null;
    const chunk = String.fromCharCode(...bytes.slice(12, 16));
    const dv = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
    if (chunk === "VP8X" && bytes.length >= 30) {
      const width = 1 + (bytes[24] | (bytes[25] << 8) | (bytes[26] << 16));
      const height = 1 + (bytes[27] | (bytes[28] << 8) | (bytes[29] << 16));
      return { width, height };
    }
    if (chunk === "VP8 " && bytes.length >= 30) {
      const start = 20;
      if (bytes[start + 3] === 0x9d && bytes[start + 4] === 0x01 && bytes[start + 5] === 0x2a) {
        const width = dv.getUint16(start + 6, true) & 0x3fff;
        const height = dv.getUint16(start + 8, true) & 0x3fff;
        return { width, height };
      }
    }
    return null;
  }

  if (mime === "image/jpeg") {
    if (bytes.length < 4 || bytes[0] !== 0xff || bytes[1] !== 0xd8) return null;
    let i = 2;
    while (i + 9 < bytes.length) {
      if (bytes[i] !== 0xff) {
        i += 1;
        continue;
      }
      const marker = bytes[i + 1];
      if (marker === 0xd8 || marker === 0xd9) {
        i += 2;
        continue;
      }
      const len = (bytes[i + 2] << 8) + bytes[i + 3];
      if (len < 2 || i + 1 + len >= bytes.length) break;
      const isSof = (marker >= 0xc0 && marker <= 0xc3) || (marker >= 0xc5 && marker <= 0xc7) ||
        (marker >= 0xc9 && marker <= 0xcb) || (marker >= 0xcd && marker <= 0xcf);
      if (isSof) {
        const height = (bytes[i + 5] << 8) + bytes[i + 6];
        const width = (bytes[i + 7] << 8) + bytes[i + 8];
        return { width, height };
      }
      i += 2 + len;
    }
  }

  return null;
}

serve(async (req) => {
  if (req.method !== "POST") return json({ ok: false, error: "method_not_allowed" }, 405);

  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) return json({ ok: false, error: "missing_jwt" }, 401);

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
  const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
  const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !SUPABASE_SERVICE_ROLE_KEY) {
    return json({ ok: false, error: "missing_supabase_env" }, 500);
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: auth } },
  });
  const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  const { data: userRes, error: userErr } = await supabase.auth.getUser();
  if (userErr || !userRes?.user) return json({ ok: false, error: "not_authenticated" }, 401);
  const userId = userRes.user.id;

  const { data: rl, error: rlErr } = await supabase.rpc("consume_rate_limit_v1", {
    p_action: "media_upload",
    p_daily_limit: 10,
  });
  if (rlErr) return json({ ok: false, error: "rate_limit_failed", detail: rlErr.message }, 500);
  if (!rl?.ok) return json({ ok: false, error: rl?.error ?? "rate_limited" }, 429);

  const form = await req.formData();
  const file = form.get("file");
  const businessIdRaw = String(form.get("business_id") ?? "").trim();
  const menuItemIdRaw = String(form.get("menu_item_id") ?? "").trim();
  const critical = isTrue(String(form.get("critical") ?? ""));

  if (!(file instanceof File)) return json({ ok: false, error: "file_required" }, 400);

  const maxBytes = 5 * 1024 * 1024;
  if (file.size > maxBytes) {
    return json({ ok: false, error: "photo_size_limit_exceeded", max_bytes: maxBytes }, 413);
  }

  const allowedMime = ["image/jpeg", "image/png", "image/webp"];
  if (!allowedMime.includes(file.type)) {
    return json({ ok: false, error: "unsupported_image_type" }, 400);
  }

  const bytes = new Uint8Array(await file.arrayBuffer());
  const dims = parseImageDimensions(bytes, file.type);
  if (!dims) {
    return json({ ok: false, error: "invalid_image_data" }, 400);
  }
  const maxDimension = 4096;
  if (dims.width > maxDimension || dims.height > maxDimension) {
    return json({ ok: false, error: "image_dimensions_exceeded", max_dimension: maxDimension }, 400);
  }

  const rawIp = readClientIp(req);
  const ipSalt = Deno.env.get("EDGE_RATE_LIMIT_SALT") ?? "yeedoy_default_salt";
  const ipHash = await sha256Hex(`${ipSalt}:${rawIp}`);
  const windowStart = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();

  const [{ count: userCount }, { count: ipCount }] = await Promise.all([
    adminClient
      .from("edge_rate_limit_events")
      .select("id", { count: "exact", head: true })
      .eq("action", "photo_upload")
      .eq("user_id", userId)
      .gte("created_at", windowStart),
    adminClient
      .from("edge_rate_limit_events")
      .select("id", { count: "exact", head: true })
      .eq("action", "photo_upload")
      .eq("ip_hash", ipHash)
      .gte("created_at", windowStart),
  ]);

  if ((userCount ?? 0) >= 20) return json({ ok: false, error: "rate_limited_user" }, 429);
  if ((ipCount ?? 0) >= 60) return json({ ok: false, error: "rate_limited_ip" }, 429);

  const { error: insertLimitErr } = await adminClient.from("edge_rate_limit_events").insert({
    action: "photo_upload",
    user_id: userId,
    ip_hash: ipHash,
    scope: businessIdRaw || null,
  });
  if (insertLimitErr) {
    return json({ ok: false, error: "rate_limit_insert_failed", detail: insertLimitErr.message }, 500);
  }

  let businessPath = /^[0-9a-fA-F-]{36}$/.test(businessIdRaw) ? businessIdRaw : "";
  if (!businessPath && /^[0-9a-fA-F-]{36}$/.test(menuItemIdRaw)) {
    const { data: menuItem, error: menuErr } = await adminClient
      .from("menu_items")
      .select("business_id")
      .eq("id", menuItemIdRaw)
      .maybeSingle();
    if (!menuErr && menuItem?.business_id) {
      businessPath = String(menuItem.business_id);
    }
  }
  if (!businessPath) businessPath = "unknown";

  const bucket = critical ? "menu-media-private" : "menu-media";
  const ext = inferExt(file.type);
  if (!ext) return json({ ok: false, error: "unsupported_image_type" }, 400);

  const now = new Date();
  const yyyy = String(now.getUTCFullYear()).padStart(4, "0");
  const mm = String(now.getUTCMonth() + 1).padStart(2, "0");
  const prefix = critical ? "critical/business" : "business";
  const objectPath = `${prefix}/${businessPath}/${yyyy}/${mm}/${crypto.randomUUID()}.${ext}`;

  const { error: uploadErr } = await adminClient.storage
    .from(bucket)
    .upload(objectPath, bytes, { contentType: file.type, upsert: false });
  if (uploadErr) {
    return json({ ok: false, error: "storage_upload_failed", detail: uploadErr.message }, 500);
  }

  let url = "";
  let urlLarge = "";
  let urlThumb = "";
  let signedExpiresIn: number | null = null;

  if (critical) {
    const expiresIn = 60 * 60 * 24 * 7;
    const { data: signed, error: signedErr } = await adminClient.storage
      .from(bucket)
      .createSignedUrl(objectPath, expiresIn);
    if (signedErr || !signed?.signedUrl) {
      return json({
        ok: false,
        error: "signed_url_failed",
        detail: signedErr?.message ?? "missing_signed_url",
      }, 500);
    }
    signedExpiresIn = expiresIn;
    url = signed.signedUrl;
    urlLarge = signed.signedUrl;
    urlThumb = signed.signedUrl;
  } else {
    const { data: pub } = adminClient.storage.from(bucket).getPublicUrl(objectPath);
    url = pub.publicUrl;
    urlLarge = pub.publicUrl;
    urlThumb = pub.publicUrl;
  }

  return json({
    ok: true,
    provider: "supabase_storage",
    bucket,
    path: objectPath,
    url,
    url_large: urlLarge,
    url_thumb: urlThumb,
    width: dims.width,
    height: dims.height,
    is_signed: critical,
    signed_expires_in: signedExpiresIn,
    remaining: rl?.remaining ?? null,
  });
});
