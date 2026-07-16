-- menu-media: Menü görselleri (ürün fotoğrafları, kapak vb.)
-- Supabase Storage image transform ile otomatik WebP/boyut optimizasyonu

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'menu-media',
  'menu-media',
  true,
  5242880,   -- 5 MB
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif', 'image/avif']
)
ON CONFLICT (id) DO NOTHING;

-- Herkes okuyabilir (menü görselleri herkese açık)
CREATE POLICY "menu_media_public_read"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'menu-media');

-- Giriş yapmış kullanıcılar yükleyebilir
CREATE POLICY "menu_media_auth_insert"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'menu-media');

-- Giriş yapmış kullanıcılar güncelleyebilir
CREATE POLICY "menu_media_auth_update"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'menu-media');

-- Giriş yapmış kullanıcılar silebilir
CREATE POLICY "menu_media_auth_delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'menu-media');
