-- Canlı Supabase Güvenlik & Bütünlük Denetimi P1: menu_item_photos_insert_authed
-- politikası yalnızca "giriş yapmış olmak" kontrol ediyordu — url, status,
-- is_hidden, up_votes, created_by hiçbiri kısıtlı değildi, menu_item_id↔
-- business_id tutarlılığı da kontrol edilmiyordu. Saldırgan doğrudan
-- PostgREST'e status='approved', is_hidden=false, up_votes=999999,
-- created_by=<masum kullanıcı> ile INSERT atıp ~42.000 halka açık işletme
-- sayfasının galerisine moderasyonsuz içerik enjekte edebiliyordu.
--
-- Gerçek yazma yolu doğrulandı: mobil istemci (menu_repository.dart)
-- yalnızca add_menu_item_photo_v1 RPC'sini çağırıyor — bu RPC zaten
-- SECURITY DEFINER (RLS'i bypass eder), business_id'yi kendi çözüyor,
-- status='pending'/is_hidden=false'u sabit yazıyor, rate-limit ve
-- shadow-ban kontrolü yapıyor. Web tarafında hiç INSERT call-site'ı yok
-- (yalnızca okuma). Yani ham tablo INSERT'i hiçbir meşru akış tarafından
-- kullanılmıyor — artifact'ın menu_feedback için önerdiği aynı desenle
-- (WITH CHECK(false), yazma RPC'ye taşınmış) kapatılıyor.
drop policy if exists menu_item_photos_insert_authed on public.menu_item_photos;

create policy menu_item_photos_insert_denied
  on public.menu_item_photos for insert
  to public
  with check (false);
