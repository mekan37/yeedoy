-- is_owner(): local ortamda eksik bulundu (bkz. proxy.ts middleware,
-- "/sahip/**" route guard'ı bunu çağırıyor: `supabase.rpc('is_owner')`).
-- Bu fonksiyon supabase/migrations/ altında hiç tanımlı değildi — production'da
-- var (REST üzerinden anon çağrısı 200/false döndü, "function not found" değil),
-- muhtemelen bir noktada Studio'dan elle oluşturulup migration'a hiç yazılmamış.
--
-- Semantik proxy.ts'teki yorumdan doğrudan alınıyor:
--   "Owner routes require at least one approved owner_claim."
-- is_admin() ile aynı desende (parametresiz, boolean, SET search_path, anon'a
-- da açık — anon/authenticated her ikisi de çağırabilmeli, owner_claim'i
-- olmayan biri için hata değil, sadece false dönmeli).

CREATE OR REPLACE FUNCTION public.is_owner()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.owner_claims
    WHERE user_id = auth.uid() AND status = 'approved'
  );
$$;

REVOKE ALL ON FUNCTION public.is_owner() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_owner() TO anon;
GRANT EXECUTE ON FUNCTION public.is_owner() TO authenticated;
COMMENT ON FUNCTION public.is_owner() IS
  'Çağıran kullanıcının en az bir onaylanmış (approved) owner_claim''i var mı kontrol eder. '
  'auth.uid() NULL ise (anon) false döner, hata fırlatmaz. '
  'Called by: uygulamalar/web/proxy.ts (guardPanelRoute, /sahip/** route guard).';
