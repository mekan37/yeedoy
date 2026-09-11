-- collections tablosunda hiç var olmayan bir 'description' sütununa yazmaya
-- çalışan bozuk bir route (app/sunucu/koleksiyonlar/route.ts) bulundu:
--   - create_collection_v1 gerçek imzası (p_title, p_is_public) idi, route
--     onu (p_name, p_description) ile çağırıyordu -> RPC HER ZAMAN hata veriyordu.
--   - RPC hatasında devreye giren "fallback" doğrudan insert de var olmayan
--     `name`/`description` sütunlarına yazmaya çalışıyordu -> O DA HER ZAMAN
--     hata veriyordu.
-- Sonuç: "Yeni Koleksiyon" özelliği canlıda tamamen bozuktu (her istek 500
-- dönüyordu), ama audit bunu yalnızca "RPC hatası sessizce fallback'e düşüyor"
-- (mimari/okunabilirlik) bulgusu olarak işaretlemişti. Asıl kök neden burada
-- düzeltiliyor: description sütunu eklendi, RPC gerçek şemaya göre güncellendi.

ALTER TABLE public.collections ADD COLUMN IF NOT EXISTS description text;

CREATE OR REPLACE FUNCTION public.create_collection_v1(
  p_title text,
  p_is_public boolean DEFAULT false,
  p_description text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
declare
  v_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  if length(trim(coalesce(p_title, ''))) = 0 then
    return jsonb_build_object('ok', false, 'code', 'invalid_input');
  end if;

  insert into public.collections (user_id, title, is_public, description)
  values (auth.uid(), trim(p_title), coalesce(p_is_public, false), nullif(trim(coalesce(p_description, '')), ''))
  returning id into v_id;

  return jsonb_build_object('ok', true, 'id', v_id, 'title', p_title);
end;
$$;

-- Mevcut GRANT'lar korunuyor (anon/authenticated/service_role) — anon çağrısı
-- zaten auth.uid() IS NULL kontrolüyle no-op'a düşüyor.
GRANT ALL ON FUNCTION public.create_collection_v1(text, boolean, text) TO anon;
GRANT ALL ON FUNCTION public.create_collection_v1(text, boolean, text) TO authenticated;
GRANT ALL ON FUNCTION public.create_collection_v1(text, boolean, text) TO service_role;

COMMENT ON FUNCTION public.create_collection_v1(text, boolean, text) IS
  'Kullanıcı için yeni bir koleksiyon oluşturur. Called by: app/sunucu/koleksiyonlar/route.ts.';

-- CREATE OR REPLACE FUNCTION üstteki gibi bir sondaki parametre eklendiğinde
-- Postgres'te mevcut fonksiyonun yerine geçmez, farklı arity nedeniyle YENİ
-- bir overload oluşturur. Eski 2 parametreli sürümü (hiçbir çağıran onu tek
-- başına kullanmıyor — tek çağıran her zaman p_description geçiyor) burada
-- açıkça düşürüyoruz ki iki overload aynı anda yaşamasın.
DROP FUNCTION IF EXISTS public.create_collection_v1(text, boolean);
