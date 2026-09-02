-- trg_notify_push_v1: önceki sürüm sadece "Vault kaydı eksik" durumunu ele alıyordu.
-- vault.decrypted_secrets'a erişim hatası (izin sorunu, vault şeması olmayan bir ortam)
-- veya net.http_post'un herhangi bir nedenle hata vermesi (bozuk pg_net durumu, imza
-- uyuşmazlığı vb.) yakalanmıyordu — bu SECURITY DEFINER trigger'da exception bloğu
-- olmadığı için böyle bir hata tüm INSERT'i keserdi. public.notifications tablosuna
-- yorum yanıtları, fiyat önerileri, sadakat otomasyonları, kampanya yayınları, yöresel
-- öneriler gibi düzinelerce alakasız özellik yazıyor; push altyapısındaki tek bir
-- yanlış yapılandırma hepsini aynı anda sessizce kırabilirdi. Bu migration tüm
-- gövdeyi bir exception bloğuna alarak "notifications akışı ASLA kırılmaz" garantisini
-- gerçek hale getiriyor ve iki ayrı RAISE WARNING ile (secret eksik / exception yakalandı)
-- push kırılmalarını Postgres loglarında görünür kılıyor.
CREATE OR REPLACE FUNCTION public.trg_notify_push_v1()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_service_role_key text;
BEGIN
  BEGIN
    SELECT decrypted_secret INTO v_service_role_key
    FROM vault.decrypted_secrets
    WHERE name = 'push_trigger_service_role_key'
    LIMIT 1;

    IF v_service_role_key IS NULL THEN
      RAISE WARNING 'trg_notify_push_v1: push_trigger_service_role_key not found in vault, skipping push for notification %', NEW.id;
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
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'trg_notify_push_v1: failed to dispatch push for notification % — %', NEW.id, SQLERRM;
  END;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.trg_notify_push_v1 IS
  'notifications AFTER INSERT trigger: pg_net ile send-push edge function''ını asenkron tetikler. Tüm hata türleri (Vault kaydı eksik, vault/pg_net erişim sorunu, vb.) içeride yakalanır ve RAISE WARNING ile loglanır — notifications INSERT''i hiçbir koşulda kırılmaz. notifications tablosuna yazan diğer tüm özellikler (yorum yanıtları, fiyat önerileri, sadakat, kampanyalar, yöresel öneriler vb.) bu garantiye güvenir.';
