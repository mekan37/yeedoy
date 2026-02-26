import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

type QueueRow = {
  id: string;
  bucket: string;
  path: string;
  attempts: number;
};

function toSafeErrorMessage(error: unknown): string {
  if (!error) return "unknown_error";
  if (typeof error === "string") return error.slice(0, 500);
  if (typeof error === "object" && error !== null) {
    const message = String(
      (error as { message?: unknown }).message ??
        (error as { error?: unknown }).error ??
        JSON.stringify(error),
    );
    return message.slice(0, 500);
  }
  return String(error).slice(0, 500);
}

function isNotFoundError(error: unknown): boolean {
  const message = toSafeErrorMessage(error).toLowerCase();
  return message.includes("not found") || message.includes("no such object");
}

serve(async (req) => {
  if (req.method !== "POST") {
    return json({ ok: false, error: "method_not_allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return json({ ok: false, error: "missing_supabase_env" }, 500);
  }

  const client = createClient(supabaseUrl, serviceRoleKey);

  const body = (await req.json().catch(() => ({}))) as { limit?: number };
  const requestedLimit = Number(body.limit ?? 200);
  const limit = Number.isFinite(requestedLimit)
    ? Math.max(1, Math.min(200, Math.floor(requestedLimit)))
    : 200;

  const { data, error } = await client
    .from("storage_deletion_queue")
    .select("id,bucket,path,attempts")
    .is("processed_at", null)
    .lt("attempts", 5)
    .order("scheduled_at", { ascending: true })
    .limit(limit);

  if (error) {
    return json({ ok: false, error: "queue_fetch_failed", detail: error.message }, 500);
  }

  const rows = (data ?? []) as QueueRow[];
  let processed = 0;
  let failed = 0;
  let skipped = 0;

  for (const row of rows) {
    const bucket = String(row.bucket ?? "").trim();
    const path = String(row.path ?? "").trim();
    if (!bucket || !path) {
      const errMsg = "invalid_queue_row";
      await client
        .from("storage_deletion_queue")
        .update({
          attempts: (row.attempts ?? 0) + 1,
          last_error: errMsg,
        })
        .eq("id", row.id)
        .is("processed_at", null);
      failed += 1;
      continue;
    }

    const { error: removeError } = await client.storage.from(bucket).remove([path]);
    const removableNotFound = removeError ? isNotFoundError(removeError) : false;

    if (!removeError || removableNotFound) {
      const { error: doneError } = await client
        .from("storage_deletion_queue")
        .update({
          processed_at: new Date().toISOString(),
          last_error: null,
        })
        .eq("id", row.id)
        .is("processed_at", null);
      if (doneError) {
        failed += 1;
      } else {
        processed += 1;
      }
      continue;
    }

    const errMsg = toSafeErrorMessage(removeError);
    const { error: updateError } = await client
      .from("storage_deletion_queue")
      .update({
        attempts: (row.attempts ?? 0) + 1,
        last_error: errMsg,
      })
      .eq("id", row.id)
      .is("processed_at", null);
    if (updateError) {
      failed += 1;
    } else {
      skipped += 1;
    }
  }

  console.log(
    `[purge-temp-uploads] fetched=${rows.length} processed=${processed} failed=${failed} skipped=${skipped}`,
  );

  return json({
    ok: true,
    fetched: rows.length,
    processed,
    failed,
    skipped,
    limit,
  });
});
