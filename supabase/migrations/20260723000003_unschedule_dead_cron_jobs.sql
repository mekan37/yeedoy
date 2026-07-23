-- İki pg_cron job'ı production'da sürekli hata veriyordu:
--
-- 1. scheduled-menu-activation (*/15 * * * *): menus.active_from/active_to
--    "time without time zone" kolonu (günlük saat aralığı) ile timestamptz
--    karşılaştırıyordu ("operator does not exist: time without time zone
--    <= timestamp with time zone"). Bu özellik (draft->published->archived
--    zamanlamalı geçiş) hiçbir owner UI'ından tetiklenmiyor — menü
--    aktivasyonu artık tamamen manuel set_active_menu_v1 ile yapılıyor;
--    active_from/active_to alıp yazan owner_create_menu_v1/owner_update_menu_v1
--    RPC'leri hiçbir app kodundan çağrılmıyor. Özellik terk edilmiş.
--
-- 2. loyalty-automations-daily (0 9 * * *): run_loyalty_automations_v1()
--    var olmayan loyalty_programs.points_per_review/birthday_bonus_pts
--    kolonlarına erişiyordu. Puan-bazlı sadakat tasarımı (20260424000007),
--    20260507000008_sadakat_karti.sql'in kendi yorumunda da belirtildiği gibi
--    damga-kartı sistemiyle MVP kapsamı dışına alınmış; ilgili owner sayfası
--    (app/sahip/pazarlama/otomasyonlar) zaten redirect stub'ı.
--
-- Fonksiyonlar siliniyor değil, sadece zamanlanmış çalıştırma iptal
-- ediliyor (düşük risk, geri alınabilir).

select cron.unschedule('scheduled-menu-activation')
where exists (select 1 from cron.job where jobname = 'scheduled-menu-activation');

select cron.unschedule('loyalty-automations-daily')
where exists (select 1 from cron.job where jobname = 'loyalty-automations-daily');

COMMENT ON FUNCTION public.scheduled_menu_activation() IS
  'KULLANILMIYOR (20260723000003): zamanlamalı menü aktivasyonu set_active_menu_v1 manuel akışıyla değiştirildi, cron unschedule edildi.';
COMMENT ON FUNCTION public.run_loyalty_automations_v1() IS
  'KULLANILMIYOR (20260723000003): puan-bazlı sadakat tasarımı MVP kapsamı dışı, var olmayan kolonlara erişiyordu, cron unschedule edildi.';
