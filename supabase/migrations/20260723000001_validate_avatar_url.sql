-- ensure_my_profile_v1, p_avatar_url'i hiçbir doğrulama yapmadan kaydediyordu.
-- Herhangi bir authenticated kullanıcı (RPC anon+authenticated'e GRANT'lı)
-- avatar_url'ini keyfi bir dış URL'ye (örn. üçüncü taraf tracking pixel)
-- ayarlayabiliyordu — <img src> script çalıştırmadığı için XSS değil, ama
-- avatarı görüntüleyen herkesin (owner panel yorumlar sayfası dahil) IP/UA
-- bilgisini sızdırabilecek bir deanonymization riski.
--
-- Hem web (app/(kimlik)/profil/avatar-yukleme.tsx) hem mobil
-- (features/profile/data/profile_repository.dart) avatarları aynı yere
-- yüklüyor: menu-media bucket'ının storage/v1/object/public/menu-media/
-- user-avatars/ öneki altına. Doğrulama bu deseni zorunlu kılıyor —
-- upsertItem'daki (menu-islemleri.ts) http/https protokol kontrolünden
-- daha sıkı, çünkü sadece protokol kontrolü tracking-pixel riskini kapatmaz.
CREATE OR REPLACE FUNCTION "public"."ensure_my_profile_v1"("p_display_name" "text" DEFAULT NULL::"text", "p_avatar_url" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_name text;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_avatar_url is not null
     and p_avatar_url !~ '^https?://[^/]+/storage/v1/object/public/menu-media/user-avatars/'
  then
    return jsonb_build_object('ok', false, 'error', 'invalid_avatar_url');
  end if;

  v_name := nullif(trim(coalesce(p_display_name,'')), '');
  if v_name is null then
    v_name := 'Kullanıcı';
  end if;

  insert into public.user_profiles(user_id, display_name, avatar_url)
  values (auth.uid(), v_name, p_avatar_url)
  on conflict (user_id) do update
    set display_name = coalesce(excluded.display_name, public.user_profiles.display_name),
        avatar_url = coalesce(excluded.avatar_url, public.user_profiles.avatar_url),
        updated_at = now();

  return jsonb_build_object('ok', true);
end;
$$;

COMMENT ON FUNCTION public.ensure_my_profile_v1 IS 'Kullanıcı profilini oluşturur/günceller — avatar_url artık menu-media/user-avatars public storage desenine sabitleniyor. Called by: web app/(kimlik)/profil, mobile profile_repository.dart.';
