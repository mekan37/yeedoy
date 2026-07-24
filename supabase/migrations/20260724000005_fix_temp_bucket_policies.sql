-- temp storage bucket: iki sorun vardı.
--
-- 1) SELECT: temp_public_read ve temp_read_all, ikisi de koşulsuz + PUBLIC role
--    (kimliksiz ziyaretçi dahil) — herkes moderasyon bekleyen (status='pending',
--    bkz. temp_uploads tablosu) kullanıcı fotoğraflarını LİSTELEYİP indirebiliyordu.
--    İkisi de silinip, temp_delete_auth ile AYNI desende (sahiplik VEYA admin)
--    tek bir policy ile değiştirildi.
--
-- 2) INSERT/DELETE: temp_auth_insert (koşulsuz) ve temp_auth_delete (koşulsuz),
--    aynı role için temp_insert_auth (uzantı kontrollü) ve temp_delete_auth
--    (sahiplik kontrollü) ile ÇAKIŞIYORDU — RLS policy'leri permissive/OR
--    olduğu için koşulsuz olanlar kazanıyor, doğru kontrollü olanları anlamsız
--    kılıyordu. Koşulsuz olan ikisi silindi, kontrollü olanlar (temp_insert_auth,
--    temp_delete_auth) korundu.
--
-- NOT: storage.buckets.temp hâlâ public=true — bu, tam olarak dosya path'i
-- bilinen bir isteğin RLS'ten bağımsız çalışabileceği anlamına gelir (Supabase
-- public bucket davranışı). Bunu private'a çevirmek, uygulamanın bu path'leri
-- nasıl gösterdiğini (public URL vs signed URL) değiştirmeyi gerektirir — bu
-- migration'ın kapsamı dışında bırakıldı, ayrı bir karar gerektiriyor.

DROP POLICY IF EXISTS temp_public_read ON storage.objects;
DROP POLICY IF EXISTS temp_read_all ON storage.objects;
DROP POLICY IF EXISTS temp_auth_insert ON storage.objects;
DROP POLICY IF EXISTS temp_auth_delete ON storage.objects;

CREATE POLICY temp_read_owner_or_admin ON storage.objects
  FOR SELECT
  TO authenticated
  USING (bucket_id = 'temp' AND (owner_id = (auth.uid())::text OR is_admin()));
