-- Owner ilk kez onaylandığında (owner_claims approved) panele girişte bir kez
-- Başlangıç Rehberi'ne yönlendirilsin, sonraki tüm açılışlarda doğrudan Genel
-- Bakış'a gitsin. Mevcut (bu migration'dan önce zaten onaylanmış) sahipler
-- geri dönük olarak "görüldü" işaretlenir ki beklenmedik şekilde
-- yönlendirilmesinler — bu bayrak yalnızca bundan sonra yeni onaylanacak
-- sahipler için NULL kalır.

ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS owner_onboarding_redirected_at timestamptz;

UPDATE public.user_profiles up
SET owner_onboarding_redirected_at = now()
WHERE owner_onboarding_redirected_at IS NULL
  AND EXISTS (
    SELECT 1 FROM public.owner_claims oc
    WHERE oc.user_id = up.user_id AND oc.status = 'approved'
  );

COMMENT ON COLUMN public.user_profiles.owner_onboarding_redirected_at IS
  'Sahip panelinde Başlangıç Rehberi''ne bir kerelik otomatik yönlendirmenin ne zaman '
  'yapıldığını tutar. NULL ise ve kullanıcı onaylı bir owner_claims sahibiyse, '
  'gösterge panosuna ilk girişte bir kez /sahip/baslangic''a yönlendirilir. '
  'Called by: app/sahip/gosterge-panosu/page.tsx.';
