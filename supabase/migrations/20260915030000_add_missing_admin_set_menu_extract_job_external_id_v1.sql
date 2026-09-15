-- as any temizliği sırasında bulunan gizli bug: app/sunucu/yonetici/menu-analiz/baslat/route.ts
-- dosya-yükleme akışının SON adımında admin_set_menu_extract_job_external_id_v1'i
-- çağırıyor (dış extractor job'ının external_job_id'sini DB kaydına yazmak için)
-- ama bu fonksiyon hiçbir migration'da hiç tanımlanmamış — çağrı her zaman
-- "fonksiyon bulunamadı" ile hata veriyordu. Route bu RPC'nin dönüşünü/hatasını
-- kontrol etmediği için sessizce yutuluyordu: iş başarıyla başlıyor ama
-- admin_menu_extract_jobs.external_job_id hiçbir zaman yazılmıyordu — bu da
-- durum sorgulama/polling akışının (admin_get_menu_extract_job_v1 vb.) dış
-- job'ı hiç bulamamasına yol açmış olmalı.
create or replace function public.admin_set_menu_extract_job_external_id_v1(
  p_job_id uuid,
  p_external_job_id text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'unauthorized' using errcode = 'P0002';
  end if;

  update public.admin_menu_extract_jobs
  set external_job_id = p_external_job_id, updated_at = now()
  where id = p_job_id and status <> 'finished';

  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;
end;
$$;

revoke all on function public.admin_set_menu_extract_job_external_id_v1(uuid, text) from public;
grant execute on function public.admin_set_menu_extract_job_external_id_v1(uuid, text) to authenticated;
revoke execute on function public.admin_set_menu_extract_job_external_id_v1(uuid, text) from anon;
comment on function public.admin_set_menu_extract_job_external_id_v1 is
  'Admin: bir menü analiz işinin dış (extractor servisi) job ID''sini kaydeder. Called by: app/sunucu/yonetici/menu-analiz/baslat/route.ts.';
