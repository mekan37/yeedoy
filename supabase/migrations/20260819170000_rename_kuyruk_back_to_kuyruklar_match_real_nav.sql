-- Gerçek (main checkout'taki commitlenmemiş, şimdi uzlaştırılan) kenar çubuğu
-- '/yonetici/kuyruklar' (çoğul, zengin implementasyon) kullanıyor —
-- '/yonetici/kuyruk' (tekil) eski/artık kullanılmayan bir sayfa.
-- Önceki düzeltmede yanlışlıkla tekil isme çevrilmişti, geri alınıyor.
ALTER TYPE public.admin_permission_key RENAME VALUE 'page:kuyruk' TO 'page:kuyruklar';

UPDATE public.admin_roles
SET permissions = array_remove(array_remove(array_remove(array_remove(
  permissions,
  'page:arama'::public.admin_permission_key),
  'page:itirazlar-claims'::public.admin_permission_key),
  'page:denetim-kaydi'::public.admin_permission_key),
  'page:toplu-islemler'::public.admin_permission_key)
WHERE is_system = true;
