-- Web tarafındaki rate limiter (src/lib/oran-siniri.ts) süreç-içi bir Map
-- kullanıyordu — serverless'te (Vercel Fluid Compute) her instance kendi
-- sayacını tutuyor, gerçek limit "limit × aktif instance sayısı"na
-- gevşiyordu. Bu, atomik UPSERT ile race-condition-safe paylaşılan bir
-- sayaç sağlıyor; tüm instance'lar aynı satırı günceller.

CREATE TABLE IF NOT EXISTS public.rate_limit_counters (
  key       text PRIMARY KEY,
  count     integer NOT NULL DEFAULT 1,
  reset_at  timestamptz NOT NULL
);

-- Süresi dolmuş satırların düzenli temizliği için — tabloyu doğrudan
-- sorgulayan yok (yalnızca RPC üzerinden erişim), bu index yalnızca
-- olası bir temizlik cron'u için.
CREATE INDEX IF NOT EXISTS rate_limit_counters_reset_at_idx
  ON public.rate_limit_counters (reset_at);

ALTER TABLE public.rate_limit_counters ENABLE ROW LEVEL SECURITY;
-- Hiçbir policy eklenmiyor — tablo yalnızca aşağıdaki SECURITY DEFINER
-- RPC üzerinden erişilebilir (RLS'i bypass eder), doğrudan PostgREST
-- erişimi (anon/authenticated) tamamen kapalı kalıyor.

CREATE OR REPLACE FUNCTION public.rate_limit_check_v1(
  p_key text,
  p_limit integer,
  p_window_ms integer
)
RETURNS TABLE(ok boolean, remaining integer, reset_at timestamptz)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_now timestamptz := clock_timestamp();
  v_count integer;
  v_reset_at timestamptz;
BEGIN
  INSERT INTO public.rate_limit_counters AS c (key, count, reset_at)
  VALUES (p_key, 1, v_now + make_interval(secs => p_window_ms / 1000.0))
  ON CONFLICT (key) DO UPDATE SET
    count = CASE
      WHEN c.reset_at <= v_now THEN 1
      ELSE c.count + 1
    END,
    reset_at = CASE
      WHEN c.reset_at <= v_now THEN v_now + make_interval(secs => p_window_ms / 1000.0)
      ELSE c.reset_at
    END
  RETURNING c.count, c.reset_at INTO v_count, v_reset_at;

  RETURN QUERY SELECT (v_count <= p_limit), GREATEST(p_limit - v_count, 0), v_reset_at;
END;
$$;

REVOKE ALL ON FUNCTION public.rate_limit_check_v1(text, integer, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.rate_limit_check_v1(text, integer, integer) TO anon;
GRANT EXECUTE ON FUNCTION public.rate_limit_check_v1(text, integer, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rate_limit_check_v1(text, integer, integer) TO service_role;

COMMENT ON FUNCTION public.rate_limit_check_v1(text, integer, integer) IS
  'Paylaşılan (serverless-instance''ler arası) rate-limit sayacı — atomik UPSERT ile race-condition-safe. Called by: src/lib/oran-siniri.ts.';

-- Süresi dolmuş satırların birikmesini önlemek için basit bir temizlik
-- fonksiyonu — bir cron job'a bağlanabilir, ama zorunlu değil (tablo
-- anahtar başına tek satır tuttuğu için doğal olarak sınırlı büyür).
CREATE OR REPLACE FUNCTION public.rate_limit_cleanup_v1()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  DELETE FROM public.rate_limit_counters WHERE reset_at < now() - interval '1 day';
$$;

REVOKE ALL ON FUNCTION public.rate_limit_cleanup_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.rate_limit_cleanup_v1() TO service_role;

COMMENT ON FUNCTION public.rate_limit_cleanup_v1() IS
  'Süresi dolmuş rate-limit sayaçlarını siler. Bir cron job''a bağlanabilir (zorunlu değil).';
