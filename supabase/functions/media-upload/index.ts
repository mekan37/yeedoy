import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
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

function parseImageDimensions(bytes: Uint8Array, mime: string): { width: number; height: number } | null {
  if (mime === "image/png") {
    if (bytes.length < 24) return null;
    if (bytes[0] !== 0x89 || bytes[1] !== 0x50 || bytes[2] !== 0x4e || bytes[3] !== 0x47) return null;
    const dv = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
    return { width: dv.getUint32(16, false), height: dv.getUint32(20, false) };
  }
  if (mime === "image/webp") {
    if (bytes.length < 30) return null;
    const riff = String.fromCharCode(...bytes.slice(0, 4));
    const webp = String.fromCharCode(...bytes.slice(8, 12));
    if (riff !== "RIFF" || webp !== "WEBP") return null;
    const chunk = String.fromCharCode(...bytes.slice(12, 16));
    const dv = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
    if (chunk === "VP8X") {
      return {
        width: 1 + (bytes[24] | (bytes[25] << 8) | (bytes[26] << 16)),
        height: 1 + (bytes[27] | (bytes[28] << 8) | (bytes[29] << 16)),
      };
    }
    if (chunk === "VP8 " && bytes[23] === 0x9d && bytes[24] === 0x01 && bytes[25] === 0x2a) {
      return {
        width: dv.getUint16(26, true) & 0x3fff,
        height: dv.getUint16(28, true) & 0x3fff,
      };
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
        return {
          height: (bytes[i + 5] << 8) + bytes[i + 6],
          width: (bytes[i + 7] << 8) + bytes[i + 8],
        };
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
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    return json({ ok: false, error: "missing_supabase_env" }, 500);
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: auth } },
  });

  const { data: isAdmin, error: adminErr } = await supabase.rpc("is_admin");
  if (adminErr) return json({ ok: false, error: "admin_check_failed", detail: adminErr.message }, 500);
  if (!isAdmin) return json({ ok: false, error: "not_admin" }, 403);

  const WP_BASE = Deno.env.get("WP_BASE_URL");
  const WP_USER = Deno.env.get("WP_USERNAME");
  const WP_APP_PASS = Deno.env.get("WP_APP_PASSWORD");
  if (!WP_BASE || !WP_USER || !WP_APP_PASS) return json({ ok: false, error: "missing_wp_env" }, 500);

  const form = await req.formData();
  const file = form.get("file");
  const title = (form.get("title") as string | null) ?? "yeedoy_upload";

  if (!(file instanceof File)) return json({ ok: false, error: "file_required" }, 400);
  const maxBytes = 5 * 1024 * 1024;
  if (file.size > maxBytes) return json({ ok: false, error: "photo_size_limit_exceeded", max_bytes: maxBytes }, 413);
  const allowedMime = ["image/jpeg", "image/png", "image/webp"];
  if (!allowedMime.includes(file.type)) return json({ ok: false, error: "unsupported_image_type" }, 400);
  const bytes = new Uint8Array(await file.arrayBuffer());
  const dims = parseImageDimensions(bytes, file.type);
  if (!dims) return json({ ok: false, error: "invalid_image_data" }, 400);
  const maxDimension = 4096;
  if (dims.width > maxDimension || dims.height > maxDimension) {
    return json({ ok: false, error: "image_dimensions_exceeded", max_dimension: maxDimension }, 400);
  }
  const ext = inferExt(file.type);
  if (!ext) return json({ ok: false, error: "unsupported_image_type" }, 400);
  const safeFilename = `${crypto.randomUUID()}.${ext}`;

  const url = `${WP_BASE.replace(/\/$/, "")}/wp-json/wp/v2/media`;
  const basic = btoa(`${WP_USER}:${WP_APP_PASS}`);

  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Authorization": `Basic ${basic}`,
      "Content-Disposition": `attachment; filename="${safeFilename}"`,
      "Content-Type": file.type || "application/octet-stream",
    },
    body: bytes.buffer,
  });

  if (!res.ok) {
    // Sanitize: do not forward upstream error details to clients (info leakage)
    console.error(`media-upload: upstream error ${res.status}`);
    return json({ ok: false, error: "media_upload_failed" }, 500);
  }

  const media = await res.json();
  const sourceUrl = media?.source_url ?? null;
  const sizes = media?.media_details?.sizes ?? {};
  const largeUrl = sizes?.large?.source_url ?? sizes?.medium_large?.source_url ?? sourceUrl;
  const thumbUrl = sizes?.thumbnail?.source_url ?? sourceUrl;

  return json({
    ok: true,
    url: sourceUrl,
    url_large: largeUrl,
    url_thumb: thumbUrl,
    width: media?.media_details?.width ?? null,
    height: media?.media_details?.height ?? null,
    wp_id: media?.id ?? null,
    title,
  });
});
