-- pg_net: Postgres'ten asenkron HTTP çağrısı yapabilmek için (trigger → edge function).
CREATE EXTENSION IF NOT EXISTS pg_net;

-- notifications tablosuna düşen HER satır için send-push edge function'ını tetikler.
-- Vault'ta 'push_trigger_service_role_key' kaydı yoksa (örn. henüz kurulmamış bir
-- ortamda) sessizce no-op yapar — notifications INSERT akışı ASLA kırılmaz.
CREATE OR REPLACE FUNCTION public.trg_notify_push_v1()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_service_role_key text;
BEGIN
  SELECT decrypted_secret INTO v_service_role_key
  FROM vault.decrypted_secrets
  WHERE name = 'push_trigger_service_role_key'
  LIMIT 1;

  IF v_service_role_key IS NULL THEN
    RETURN NEW;
  END IF;

  PERFORM net.http_post(
    url := 'https://wvofyimbjndxtxitsjpd.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_service_role_key
    ),
    body := jsonb_build_object('notification_id', NEW.id)
  );

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.trg_notify_push_v1 IS
  'notifications AFTER INSERT trigger: pg_net ile send-push edge function''ını asenkron tetikler. Vault kaydı eksikse no-op (push altyapısı kurulu değilse notifications akışı kırılmaz).';

DROP TRIGGER IF EXISTS trg_notifications_push ON public.notifications;
CREATE TRIGGER trg_notifications_push
  AFTER INSERT ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION public.trg_notify_push_v1();
