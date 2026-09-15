-- `public.menus` hiçbir migration'da `external_url` kolonuna sahip
-- olmamış — ama app/sahip/menuler/menu-islemleri.ts'teki
-- createExternalMenu/updateExternalMenuUrl "Dış menü bağlantısı ekle"
-- özelliği baştan beri bu kolona insert/update yapmaya çalışıyordu.
-- Her çağrı "column does not exist" ile patlıyordu; jenerik
-- `if (error) redirect(...hata=create_failed)` bu hatayı kullanıcıya
-- görünmez kılıyordu. `as any`/tip-örtme temizliği sırasında,
-- veri-tanimlari.ts gerçek şemayı doğru yansıtınca ortaya çıktı
-- (tsc "external_url does not exist" dedi — önceki gevşek `any` tabanlı
-- kod bunu gizliyordu).
alter table "public"."menus"
  add column if not exists "external_url" text;
