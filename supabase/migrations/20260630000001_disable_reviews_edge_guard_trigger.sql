-- TERK EDİLDİ (2026-07-23) — BU MIGRATION'I DEPLOY ETMEYİN.
-- anti-spam-guard ve write-gatekeeper edge functions'ları o zamandan beri
-- production'a deploy edildi ve enforce_reviews_edge_guard_v1 canlıda zaten
-- consume_edge_guard_event_v1'i aktif çağırıyor (guard çalışıyor). Bu dosya
-- hiçbir zaman remote'a uygulanmadı (yerel migration history'de "local-only"
-- kaldı) ve artık uygulanmamalı — uygulanırsa çalışan anti-spam korumasını
-- no-op'a çevirip REGRESYON yaratır. Dosya sadece tarihsel bağlam için
-- tutuluyor, silinmedi.
--
-- Orijinal (artık geçersiz) not:
-- Edge functions (anti-spam-guard, write-gatekeeper) are not yet deployed.
-- The trigger trg_reviews_edge_guard_v1 blocks every review INSERT because
-- consume_edge_guard_event_v1 finds no matching edge_rate_limit_events row.
-- Replace the trigger function with a no-op until edge functions are live.

CREATE OR REPLACE FUNCTION public.enforce_reviews_edge_guard_v1()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
begin
  -- Edge guard is soft-disabled: edge functions not yet deployed.
  -- Re-enable by calling consume_edge_guard_event_v1 here once anti-spam-guard is live.
  return new;
end;
$$;

COMMENT ON FUNCTION public.enforce_reviews_edge_guard_v1() IS
  'SOFT-DISABLED: edge functions not deployed. Restore consume_edge_guard_event_v1 call when anti-spam-guard is live.';
