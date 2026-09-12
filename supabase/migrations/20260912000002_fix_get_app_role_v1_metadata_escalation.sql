-- P0: get_app_role_v1() istemci tarafından yazılabilen user_metadata.role'e
-- fallback yapıyordu. Herhangi bir kayıtlı kullanıcı
-- supabase.auth.updateUser({ data: { role: 'community_mod' } }) çağrısıyla
-- kendi JWT'sine bu rolü yazdırıp is_admin_or_community_mod_v1() üzerinden
-- moderasyon RPC'lerine ve tüm şikayet/itiraz PII'sine erişebiliyordu.
--
-- Doğrulandı: hiçbir kod yolu (web/mobil) user_metadata.role'ü meşru bir
-- şekilde yazmıyor — yalnızca app_metadata.role (yalnızca service_role
-- tarafından yazılabilir) kullanılıyor. Fallback güvenlik amaçlı değil,
-- yanlışlıkla eklenmiş bir zafiyetti.

CREATE OR REPLACE FUNCTION "public"."get_app_role_v1"() RETURNS "text"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_claim jsonb := auth.jwt();
  v_role text;
begin
  v_role := lower(
    coalesce(
      v_claim -> 'app_metadata' ->> 'role',
      'user'
    )
  );

  if v_role not in ('user', 'owner', 'community_mod', 'admin') then
    v_role := 'user';
  end if;
  return v_role;
end;
$$;
