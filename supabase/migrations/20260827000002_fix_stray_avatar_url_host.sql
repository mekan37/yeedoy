-- Yorumlarda kullanıcı avatarları hiç görünmüyordu. Kök neden: user_profiles.avatar_url
-- eski (artık kullanılmayan) Supabase projesinin storage host'unu içeriyordu. Bu host
-- proxy.ts'nin img-src CSP allowlist'inde yok (sadece appConfig.supabaseUrl() host'u
-- izinli), bu yüzden tarayıcı görseli sessizce engelliyordu — dosyanın kendisi doğru
-- (production) bucket'ta zaten mevcuttu, sadece kayıtlı URL'nin host'u yanlıştı.
--
-- ensure_my_profile_v1'in avatar_url validasyonu (20260723000001_validate_avatar_url.sql)
-- sadece path desenini kontrol ediyor, host'u pin'lemiyor — bu yüzden yanlış host'lu bir
-- değer hiç reddedilmeden kaydedilebilmiş. Güncel avatar-yukleme.tsx zaten
-- appConfig.supabaseUrl() (doğru env) ile getPublicUrl() çağırıyor, yani bu ileriye dönük
-- tekrarlanan bir upload bug'ı değil — mevcut satırlardaki yanlış host'u düzeltiyoruz.
UPDATE public.user_profiles
SET avatar_url = regexp_replace(
  avatar_url,
  '^https?://[^/]+(/storage/v1/object/public/menu-media/user-avatars/.*)$',
  'https://wvofyimbjndxtxitsjpd.supabase.co\1'
)
WHERE avatar_url ~ '^https?://[^/]+/storage/v1/object/public/menu-media/user-avatars/'
  AND avatar_url NOT LIKE 'https://wvofyimbjndxtxitsjpd.supabase.co/%';
